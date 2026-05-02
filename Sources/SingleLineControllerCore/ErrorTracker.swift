// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Foundation

/// Shared sink that captures errors from arbitrary publishers and re-publishes
/// them as a `Never`-failing stream — the dual of `ActivityIndicator` for the
/// error path.
///
/// Wrap a publisher with `.trackError(tracker)` to forward any failure into
/// the tracker without altering the upstream's `Failure` type. Subscribers
/// of `tracker.asPublisher()` then get a `Never`-failing stream of errors,
/// suitable for binding to validation labels / toast outputs.
public final class ErrorTracker {
    /// Internal subject that captured errors are pushed into. Exposed to
    /// other modules in the same package via `_subjectCompactMap` so the
    /// Validation sibling package can layer typed-error projections on top
    /// without breaking encapsulation.
    private let subject = PassthroughSubject<Error, Never>()

    /// Creates an empty tracker.
    public init() {}

    /// The full stream of captured errors as a `Never`-failing publisher.
    public func asPublisher() -> AnyPublisher<Error, Never> {
        subject.eraseToAnyPublisher()
    }

    /// Wraps `source` so each `.failure` completion is forwarded into this
    /// tracker. The returned publisher preserves `source`'s `Output`/`Failure`
    /// shape — handy as a transparent middle stage in a chain.
    public func track<P: Publisher>(from source: P) -> some Publisher<P.Output, P.Failure>
        where P.Failure: Error
    {
        source
            .handleEvents(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.subject.send(error)
                }
            })
    }

    /// Internal hook used by sibling packages (e.g. `Validation`) to project
    /// captured errors through a typed `compactMap` without exposing the raw
    /// subject. The closure receives every tracked error and returns the
    /// projected value — `nil` results are dropped.
    public func compactMap<T>(_ transform: @escaping (Swift.Error) -> T?) -> AnyPublisher<T, Never> {
        subject
            .compactMap(transform)
            .eraseToAnyPublisher()
    }
}

public extension Publisher {
    /// Threads any failure of this publisher through `tracker` without altering
    /// the upstream's `Output`/`Failure` types. The standard call-site form
    /// for capturing errors at the use-case boundary.
    func trackError(_ tracker: ErrorTracker) -> some Publisher<Output, Failure>
        where Failure: Error
    {
        tracker.track(from: self)
    }
}
