// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Foundation

/// Thread-safe in-flight tracker for asynchronous work.
///
/// Wrap a publisher with `.trackActivity(indicator)` to automatically flip
/// `indicator` to `true` when the publisher is subscribed and `false` when it
/// emits its first output / completes / cancels. Bind `indicator.asPublisher()`
/// to a UIButton's `isLoadingBinder` to drive spinner UI.
public final class ActivityIndicator {

    /// Serializes send writes to `subject` so concurrent trackers can't interleave
    /// start/stop calls and leave the indicator in a wrong state.
    private let lock = NSRecursiveLock()

    /// The internal backing subject. Exposed read-only as `asPublisher()`.
    private let subject = CurrentValueSubject<Bool, Never>(false)

    /// Creates an indicator in the "idle" state.
    public init() {}

    /// Returns a deduplicated publisher suitable for binding to button spinners.
    /// Idle/active transitions are de-bounced via `removeDuplicates`.
    public func asPublisher() -> AnyPublisher<Bool, Never> {
        subject.removeDuplicates().eraseToAnyPublisher()
    }
}

private extension ActivityIndicator {

    /// Emits `true` under lock.
    func start() {
        lock.lock(); subject.send(true); lock.unlock()
    }

    /// Emits `false` under lock.
    func stop() {
        lock.lock(); subject.send(false); lock.unlock()
    }

    /// Wraps `source` with the start/stop side-effects around its lifecycle. Called
    /// indirectly via `Publisher.trackActivity(_:)`.
    func track<P: Publisher>(_ source: P) -> some Publisher<P.Output, P.Failure> {
        source
            .handleEvents(
                receiveSubscription: { [weak self] _ in self?.start() },
                receiveOutput: { [weak self] _ in self?.stop() },
                receiveCompletion: { [weak self] _ in self?.stop() },
                receiveCancel: { [weak self] in self?.stop() }
            )
    }
}

public extension Publisher {

    /// Tracks this publisher's in-flight state on `indicator`. Use the resulting
    /// publisher in place of the original to get spinner-on-while-running UI for free.
    func trackActivity(_ indicator: ActivityIndicator) -> some Publisher<Output, Failure> {
        indicator.track(self)
    }
}

