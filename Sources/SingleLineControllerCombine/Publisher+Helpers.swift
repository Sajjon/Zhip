// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Foundation

// Sugar that mirrors RxSwift's free-function-style `Observable.combineLatest(_:_:)`
// and turns Combine's verbose static factories into one-liners.

// MARK: - AnyPublisher static constructors

public extension AnyPublisher where Failure == Never {
    /// Convenience over `Just(value).eraseToAnyPublisher()`.
    static func just(_ value: Output) -> AnyPublisher<Output, Never> {
        Just(value).eraseToAnyPublisher()
    }

    /// A publisher that completes immediately with no values.
    static func empty() -> AnyPublisher<Output, Never> {
        Empty<Output, Never>().eraseToAnyPublisher()
    }

    /// A publisher that never emits and never completes.
    static func never() -> AnyPublisher<Output, Never> {
        Empty<Output, Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    /// Variadic merge.
    static func merge(_ publishers: AnyPublisher<Output, Never>...) -> AnyPublisher<Output, Never> {
        Publishers.MergeMany(publishers).eraseToAnyPublisher()
    }

    /// Array overload of `merge`.
    static func merge(_ publishers: [AnyPublisher<Output, Never>]) -> AnyPublisher<Output, Never> {
        Publishers.MergeMany(publishers).eraseToAnyPublisher()
    }

    /// 2-publisher merge.
    static func merge(
        _ p1: some Publisher<Output, Never>,
        _ p2: some Publisher<Output, Never>
    ) -> AnyPublisher<Output, Never> {
        p1.merge(with: p2).eraseToAnyPublisher()
    }

    /// 3-publisher merge.
    static func merge(
        _ p1: some Publisher<Output, Never>,
        _ p2: some Publisher<Output, Never>,
        _ p3: some Publisher<Output, Never>
    ) -> AnyPublisher<Output, Never> {
        Publishers.Merge3(p1, p2, p3).eraseToAnyPublisher()
    }

    /// 4-publisher merge.
    static func merge(
        _ p1: some Publisher<Output, Never>,
        _ p2: some Publisher<Output, Never>,
        _ p3: some Publisher<Output, Never>,
        _ p4: some Publisher<Output, Never>
    ) -> AnyPublisher<Output, Never> {
        Publishers.Merge4(p1, p2, p3, p4).eraseToAnyPublisher()
    }
}

// MARK: - combineLatest free functions

public func combineLatest<A, B>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>
) -> AnyPublisher<(A, B), Never> {
    a.combineLatest(b).eraseToAnyPublisher()
}

// swiftlint:disable large_tuple
public func combineLatest<A, B, C>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>,
    _ c: some Publisher<C, Never>
) -> AnyPublisher<(A, B, C), Never> {
    a.combineLatest(b, c).eraseToAnyPublisher()
}

public func combineLatest<A, B, C, D>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>,
    _ c: some Publisher<C, Never>,
    _ d: some Publisher<D, Never>
) -> AnyPublisher<(A, B, C, D), Never> {
    a.combineLatest(b, c, d).eraseToAnyPublisher()
}

// swiftlint:enable large_tuple

public func combineLatest<A, B, R>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>,
    resultSelector: @escaping (A, B) -> R
) -> AnyPublisher<R, Never> {
    a.combineLatest(b, resultSelector).eraseToAnyPublisher()
}

public func combineLatest<A, B, C, R>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>,
    _ c: some Publisher<C, Never>,
    resultSelector: @escaping (A, B, C) -> R
) -> AnyPublisher<R, Never> {
    a.combineLatest(b, c, resultSelector).eraseToAnyPublisher()
}

// swiftlint:disable function_parameter_count
public func combineLatest<A, B, C, D, R>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>,
    _ c: some Publisher<C, Never>,
    _ d: some Publisher<D, Never>,
    resultSelector: @escaping (A, B, C, D) -> R
) -> AnyPublisher<R, Never> {
    Publishers.CombineLatest4(a, b, c, d)
        .map { resultSelector($0.0, $0.1, $0.2, $0.3) }
        .eraseToAnyPublisher()
}

public func combineLatest<A, B, C, D, E, R>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>,
    _ c: some Publisher<C, Never>,
    _ d: some Publisher<D, Never>,
    _ e: some Publisher<E, Never>,
    resultSelector: @escaping (A, B, C, D, E) -> R
) -> AnyPublisher<R, Never> {
    Publishers.CombineLatest4(a, b, c, d)
        .combineLatest(e)
        .map { tuple4, eVal in resultSelector(tuple4.0, tuple4.1, tuple4.2, tuple4.3, eVal) }
        .eraseToAnyPublisher()
}

// swiftlint:enable function_parameter_count

// MARK: - AnyPublisher.combineLatest(...) static overloads

public extension AnyPublisher where Failure == Never {
    static func combineLatest<A, B>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>
    ) -> AnyPublisher<(A, B), Never> {
        a.combineLatest(b).eraseToAnyPublisher()
    }

    // swiftlint:disable large_tuple
    static func combineLatest<A, B, C>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>,
        _ c: some Publisher<C, Never>
    ) -> AnyPublisher<(A, B, C), Never> {
        a.combineLatest(b, c).eraseToAnyPublisher()
    }

    static func combineLatest<A, B, C, D>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>,
        _ c: some Publisher<C, Never>,
        _ d: some Publisher<D, Never>
    ) -> AnyPublisher<(A, B, C, D), Never> {
        a.combineLatest(b, c, d).eraseToAnyPublisher()
    }

    // swiftlint:enable large_tuple

    static func combineLatest<A, B, R>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>,
        resultSelector: @escaping (A, B) -> R
    ) -> AnyPublisher<R, Never> {
        a.combineLatest(b, resultSelector).eraseToAnyPublisher()
    }

    static func combineLatest<A, B, C, R>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>,
        _ c: some Publisher<C, Never>,
        resultSelector: @escaping (A, B, C) -> R
    ) -> AnyPublisher<R, Never> {
        a.combineLatest(b, c, resultSelector).eraseToAnyPublisher()
    }

    // swiftlint:disable function_parameter_count
    static func combineLatest<A, B, C, D, R>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>,
        _ c: some Publisher<C, Never>,
        _ d: some Publisher<D, Never>,
        resultSelector: @escaping (A, B, C, D) -> R
    ) -> AnyPublisher<R, Never> {
        Publishers.CombineLatest4(a, b, c, d)
            .map { resultSelector($0.0, $0.1, $0.2, $0.3) }
            .eraseToAnyPublisher()
    }

    static func combineLatest<A, B, C, D, E, R>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>,
        _ c: some Publisher<C, Never>,
        _ d: some Publisher<D, Never>,
        _ e: some Publisher<E, Never>,
        resultSelector: @escaping (A, B, C, D, E) -> R
    ) -> AnyPublisher<R, Never> {
        Publishers.CombineLatest4(a, b, c, d)
            .combineLatest(e)
            .map { tuple4, eVal in resultSelector(tuple4.0, tuple4.1, tuple4.2, tuple4.3, eVal) }
            .eraseToAnyPublisher()
    }
    // swiftlint:enable function_parameter_count
}
