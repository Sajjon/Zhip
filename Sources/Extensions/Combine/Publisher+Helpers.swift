// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Foundation

// Sugar that mirrors RxSwift's free-function-style `Observable.combineLatest(_:_:)`
// and turns Combine's verbose static factories into one-liners. Lets ViewModel
// `transform(input:)` bodies stay readable when juggling many publishers.

// MARK: - AnyPublisher static constructors

public extension AnyPublisher where Failure == Never {
    /// Convenience over `Just(value).eraseToAnyPublisher()`.
    static func just(_ value: Output) -> AnyPublisher<Output, Never> {
        Just(value).eraseToAnyPublisher()
    }

    /// A publisher that completes immediately with no values. Useful as the
    /// "neutral element" for merging or as a switched-to value in error paths.
    static func empty() -> AnyPublisher<Output, Never> {
        Empty<Output, Never>().eraseToAnyPublisher()
    }

    /// A publisher that never emits and never completes — keeps a chain alive
    /// indefinitely without producing any values.
    static func never() -> AnyPublisher<Output, Never> {
        Empty<Output, Never>(completeImmediately: false).eraseToAnyPublisher()
    }

    /// Variadic merge of any number of publishers — sugar over `MergeMany`.
    static func merge(_ publishers: AnyPublisher<Output, Never>...) -> AnyPublisher<Output, Never> {
        Publishers.MergeMany(publishers).eraseToAnyPublisher()
    }

    /// Array overload of `merge(_:)` for cases where the publisher list is
    /// constructed dynamically.
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

    /// 3-publisher merge — wraps `Publishers.Merge3`.
    static func merge(
        _ p1: some Publisher<Output, Never>,
        _ p2: some Publisher<Output, Never>,
        _ p3: some Publisher<Output, Never>
    ) -> AnyPublisher<Output, Never> {
        Publishers.Merge3(p1, p2, p3).eraseToAnyPublisher()
    }

    /// 4-publisher merge — wraps `Publishers.Merge4`.
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

/// Free-function `combineLatest` that emits a tuple — RxSwift-style sugar.
public func combineLatest<A, B>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>
) -> AnyPublisher<(A, B), Never> {
    a.combineLatest(b).eraseToAnyPublisher()
}

// swiftlint:disable large_tuple
/// 3-arity tuple `combineLatest`.
public func combineLatest<A, B, C>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>,
    _ c: some Publisher<C, Never>
) -> AnyPublisher<(A, B, C), Never> {
    a.combineLatest(b, c).eraseToAnyPublisher()
}

/// 4-arity tuple `combineLatest`.
public func combineLatest<A, B, C, D>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>,
    _ c: some Publisher<C, Never>,
    _ d: some Publisher<D, Never>
) -> AnyPublisher<(A, B, C, D), Never> {
    a.combineLatest(b, c, d).eraseToAnyPublisher()
}
// swiftlint:enable large_tuple

/// 2-arity `combineLatest` with a result selector — same shape as RxSwift.
public func combineLatest<A, B, R>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>,
    resultSelector: @escaping (A, B) -> R
) -> AnyPublisher<R, Never> {
    a.combineLatest(b, resultSelector).eraseToAnyPublisher()
}

/// 3-arity `combineLatest` with a result selector.
public func combineLatest<A, B, C, R>(
    _ a: some Publisher<A, Never>,
    _ b: some Publisher<B, Never>,
    _ c: some Publisher<C, Never>,
    resultSelector: @escaping (A, B, C) -> R
) -> AnyPublisher<R, Never> {
    a.combineLatest(b, c, resultSelector).eraseToAnyPublisher()
}

// swiftlint:disable function_parameter_count
/// 4-arity `combineLatest` with a result selector. Implemented in terms of
/// `Publishers.CombineLatest4` and a flattening `map` so the call site can
/// receive 4 separate parameters instead of a 4-tuple.
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

/// 5-arity `combineLatest` with a result selector. Implemented as a
/// `CombineLatest4` × the 5th publisher, then flattened — Combine doesn't
/// ship a `CombineLatest5`.
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

// Identical surface to the free-function `combineLatest` family above, but
// hung off `AnyPublisher` so call sites can write `AnyPublisher.combineLatest(a, b)`
// when name-shadowing or readability call for it.
public extension AnyPublisher where Failure == Never {
    /// 2-arity tuple — see free function of the same name.
    static func combineLatest<A, B>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>
    ) -> AnyPublisher<(A, B), Never> {
        a.combineLatest(b).eraseToAnyPublisher()
    }

    // swiftlint:disable large_tuple
    /// 3-arity tuple — see free function of the same name.
    static func combineLatest<A, B, C>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>,
        _ c: some Publisher<C, Never>
    ) -> AnyPublisher<(A, B, C), Never> {
        a.combineLatest(b, c).eraseToAnyPublisher()
    }

    /// 4-arity tuple — see free function of the same name.
    static func combineLatest<A, B, C, D>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>,
        _ c: some Publisher<C, Never>,
        _ d: some Publisher<D, Never>
    ) -> AnyPublisher<(A, B, C, D), Never> {
        a.combineLatest(b, c, d).eraseToAnyPublisher()
    }
    // swiftlint:enable large_tuple

    /// 2-arity with selector — see free function of the same name.
    static func combineLatest<A, B, R>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>,
        resultSelector: @escaping (A, B) -> R
    ) -> AnyPublisher<R, Never> {
        a.combineLatest(b, resultSelector).eraseToAnyPublisher()
    }

    /// 3-arity with selector — see free function of the same name.
    static func combineLatest<A, B, C, R>(
        _ a: some Publisher<A, Never>,
        _ b: some Publisher<B, Never>,
        _ c: some Publisher<C, Never>,
        resultSelector: @escaping (A, B, C) -> R
    ) -> AnyPublisher<R, Never> {
        a.combineLatest(b, c, resultSelector).eraseToAnyPublisher()
    }

    // swiftlint:disable function_parameter_count
    /// 4-arity with selector — see free function of the same name.
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

    /// 5-arity with selector — see free function of the same name.
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
