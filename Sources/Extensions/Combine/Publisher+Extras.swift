// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Foundation

// MARK: - replaceErrorWithEmpty

public extension Publisher {
    /// Swallow errors and return an empty publisher.
    func replaceErrorWithEmpty() -> some Publisher<Output, Never> {
        self.catch { _ in Empty<Output, Never>() }
    }
}

// MARK: - mapToVoid

public extension Publisher {
    /// Drops every value's payload, keeping only the *signal*. Use when the
    /// downstream cares only that a publisher emitted, not what.
    func mapToVoid() -> some Publisher<Void, Failure> {
        map { _ in () }
    }
}

// MARK: - filterNil

public extension Publisher {
    /// Filters out `nil` values from a publisher of optionals, narrowing the
    /// output type to `Wrapped`. Equivalent to RxSwift's `filterNil`.
    func filterNil<Wrapped>() -> some Publisher<Wrapped, Failure> where Output == Wrapped? {
        compactMap { $0 }
    }
}

// MARK: - orEmpty (String? → String)

public extension Publisher where Output == String? {
    /// Lifts an optional-string publisher to non-optional by replacing `nil`
    /// with the empty string. Used wherever a UI component (text field, label)
    /// reports `String?` but downstream wants a plain `String`.
    var orEmpty: AnyPublisher<String, Failure> {
        map { $0 ?? "" }.eraseToAnyPublisher()
    }
}

public extension AnyPublisher where Output == String?, Failure == Never {
    /// `Never`-failure-specialised variant of `orEmpty` that returns the
    /// concrete `AnyPublisher<String, Never>` shape used by `InputFromView`.
    var orEmpty: AnyPublisher<String, Never> {
        map { $0 ?? "" }.eraseToAnyPublisher()
    }
}

// MARK: - flatMapLatest

public extension Publisher where Failure == Never {
    /// Map to a new publisher and switch to the latest — cancels the previous inner publisher on a new value.
    func flatMapLatest<P: Publisher>(
        _ transform: @escaping (Output) -> P
    ) -> some Publisher<P.Output, Never> where P.Failure == Never {
        map(transform).switchToLatest()
    }
}

public extension Publisher {
    /// Failure-preserving variant of `flatMapLatest` — both upstream and inner
    /// publisher must share the same `Failure` type. Cancels the in-flight
    /// inner publisher whenever a new upstream value arrives.
    func flatMapLatest<P: Publisher>(
        _ transform: @escaping (Output) -> P
    ) -> some Publisher<P.Output, P.Failure> where P.Failure == Failure {
        map(transform).switchToLatest()
    }
}

// MARK: - withLatestFrom

public extension Publisher where Failure == Never {
    /// On each upstream emission, replace the value with the *latest* value from
    /// `other`. Drops upstream events that arrive before `other` has emitted at
    /// least once. RxSwift-equivalent: `withLatestFrom`.
    func withLatestFrom<Other: Publisher>(
        _ other: Other
    ) -> some Publisher<Other.Output, Never> where Other.Failure == Never {
        withLatestFrom(other) { $1 }
    }

    /// On each upstream emission, combine its value with the latest value from
    /// `other` using `resultSelector`. The trigger is the upstream — `other`
    /// emissions alone do not produce output.
    func withLatestFrom<Other: Publisher, Result>(
        _ other: Other,
        resultSelector: @escaping (Output, Other.Output) -> Result
    ) -> some Publisher<Result, Never> where Other.Failure == Never {
        WithLatestFromPublisher(upstream: self, other: other, resultSelector: resultSelector)
    }
}

/// Hand-rolled `Publisher` backing `withLatestFrom`.
///
/// Combine doesn't ship the operator natively; we need it because:
///   * `combineLatest` would *also* emit on `other` changes (wrong trigger), and
///   * `merge` loses the pairing semantics entirely.
///
/// The implementation eagerly subscribes to `other` so the latest value is always
/// available when the upstream fires — matching RxSwift's contract.
private struct WithLatestFromPublisher<
    Upstream: Publisher,
    Other: Publisher,
    Result
>: Publisher where Upstream.Failure == Never, Other.Failure == Never {
    typealias Output = Result
    typealias Failure = Never

    let upstream: Upstream
    let other: Other
    let resultSelector: (Upstream.Output, Other.Output) -> Result

    /// Constructs the inner subscription, hands it to the downstream subscriber,
    /// then subscribes the upstream to it. Order matters — the downstream must
    /// receive the subscription handle before any values can be delivered.
    func receive<S: Subscriber>(subscriber: S)
        where S.Input == Result, S.Failure == Never {
        let subscription = Inner(
            downstream: subscriber,
            other: other,
            resultSelector: resultSelector
        )
        subscriber.receive(subscription: subscription)
        upstream.subscribe(subscription)
    }

    /// Bridges the two roles needed by `withLatestFrom`: it is both a
    /// `Subscription` (handed to the downstream) and a `Subscriber` (subscribed
    /// to the upstream). The `other` publisher is consumed via a separate
    /// `AnyCancellable` whose only job is to keep `latestOther` up to date.
    private final class Inner<Downstream: Subscriber>: Subscription, Subscriber
    where Downstream.Input == Result, Downstream.Failure == Never {
        typealias Input = Upstream.Output
        typealias Failure = Never

        private var downstream: Downstream?
        private var upstreamSubscription: Subscription?
        private var otherCancellable: AnyCancellable?
        /// Most recent value seen from the secondary publisher — `nil` until
        /// `other` emits at least once, in which case upstream events are dropped.
        private var latestOther: Other.Output?
        private var pendingDemand: Subscribers.Demand = .none
        private let resultSelector: (Upstream.Output, Other.Output) -> Result

        init(
            downstream: Downstream,
            other: Other,
            resultSelector: @escaping (Upstream.Output, Other.Output) -> Result
        ) {
            self.downstream = downstream
            self.resultSelector = resultSelector
            // Eagerly subscribe to `other` so its latest value is captured even
            // before the upstream produces. `[weak self]` avoids a retain cycle
            // through the cancellable.
            self.otherCancellable = other.sink { [weak self] value in
                self?.latestOther = value
            }
        }

        /// Forward any demand to the upstream once it has been hooked up.
        /// Demand received before `receive(subscription:)` is buffered into
        /// `pendingDemand` and replayed.
        func request(_ demand: Subscribers.Demand) {
            guard demand > .none else { return }
            pendingDemand += demand
            upstreamSubscription?.request(demand)
        }

        /// Tear down both subscriptions and drop all references — called when
        /// the downstream cancels or completion has propagated.
        func cancel() {
            upstreamSubscription?.cancel()
            upstreamSubscription = nil
            otherCancellable?.cancel()
            otherCancellable = nil
            downstream = nil
            latestOther = nil
            pendingDemand = .none
        }

        /// Capture the upstream subscription handle and replay any buffered demand.
        func receive(subscription: Subscription) {
            upstreamSubscription = subscription
            if pendingDemand > .none {
                subscription.request(pendingDemand)
            }
        }

        /// Pair the upstream value with the latest `other` value (if any) and
        /// forward to the downstream. If `other` has not emitted yet, drop the
        /// upstream event and request no further demand for it.
        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard
                let latestOther,
                let downstream
            else {
                return .none
            }
            return downstream.receive(resultSelector(input, latestOther))
        }

        /// Forward completion downstream and tear ourselves down.
        func receive(completion: Subscribers.Completion<Never>) {
            downstream?.receive(completion: completion)
            cancel()
        }
    }
}

// MARK: - ifEmpty(switchTo:)

public extension Publisher where Failure == Never {
    /// Returns a publisher that mirrors `self` *unless* it completes without ever
    /// having emitted, in which case it switches to `replacement` instead.
    /// Useful for "show fallback content if the primary stream is empty".
    func ifEmpty(switchTo replacement: AnyPublisher<Output, Never>) -> some Publisher<Output, Never> {
        // Outer Deferred ensures each subscription gets its own `didEmit` state.
        Deferred {
            var didEmit = false
            return self.handleEvents(receiveOutput: { _ in didEmit = true })
                .append(
                    // Inner Deferred so the decision is made *at completion time*,
                    // not at composition time. By then `didEmit` reflects whether
                    // `self` produced any values.
                    Deferred {
                        didEmit ? AnyPublisher<Output, Never>.empty() : replacement
                    }
                )
                .eraseToAnyPublisher()
        }
    }
}
