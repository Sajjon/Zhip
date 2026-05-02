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

/// Hand-rolled `Publisher` backing `withLatestFrom`. See
/// `Sources/Extensions/Combine/Publisher+Extras.swift` in the original Zhip
/// tree for the full design rationale (Combine doesn't ship `withLatestFrom`,
/// `combineLatest` has the wrong trigger semantics, `merge` loses pairing).
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

    func receive<S: Subscriber>(subscriber: S)
        where S.Input == Result, S.Failure == Never
    {
        let subscription = Inner(
            downstream: subscriber,
            other: other,
            resultSelector: resultSelector
        )
        subscriber.receive(subscription: subscription)
        upstream.subscribe(subscription)
    }

    private final class Inner<Downstream: Subscriber>: Subscription, Subscriber
        where Downstream.Input == Result, Downstream.Failure == Never
    {
        typealias Input = Upstream.Output
        typealias Failure = Never

        private var downstream: Downstream?
        private var upstreamSubscription: Subscription?
        private var otherCancellable: AnyCancellable?
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
            otherCancellable = other.sink { [weak self] value in
                self?.latestOther = value
            }
        }

        func request(_ demand: Subscribers.Demand) {
            guard demand > .none else { return }
            pendingDemand += demand
            upstreamSubscription?.request(demand)
        }

        func cancel() {
            upstreamSubscription?.cancel()
            upstreamSubscription = nil
            otherCancellable?.cancel()
            otherCancellable = nil
            downstream = nil
            latestOther = nil
            pendingDemand = .none
        }

        func receive(subscription: Subscription) {
            upstreamSubscription = subscription
            if pendingDemand > .none {
                subscription.request(pendingDemand)
            }
        }

        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            guard
                let latestOther,
                let downstream
            else {
                return .none
            }
            return downstream.receive(resultSelector(input, latestOther))
        }

        func receive(completion: Subscribers.Completion<Never>) {
            downstream?.receive(completion: completion)
            cancel()
        }
    }
}

// MARK: - ifEmpty(switchTo:)

public extension Publisher where Failure == Never {
    /// Returns a publisher that mirrors `self` *unless* it completes without
    /// ever having emitted, in which case it switches to `replacement`.
    func ifEmpty(switchTo replacement: AnyPublisher<Output, Never>) -> some Publisher<Output, Never> {
        Deferred {
            var didEmit = false
            return self.handleEvents(receiveOutput: { _ in didEmit = true })
                .append(
                    Deferred {
                        didEmit ? AnyPublisher<Output, Never>.empty() : replacement
                    }
                )
                .eraseToAnyPublisher()
        }
    }
}
