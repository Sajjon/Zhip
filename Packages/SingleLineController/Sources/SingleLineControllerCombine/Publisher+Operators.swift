// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit

// MARK: - sinkOnMain

public extension Publisher where Failure == Never {

    /// Subscribes and dispatches each value through the supplied scheduling
    /// closure before invoking `receiveValue`.
    ///
    /// In production the default `DispatchQueue.main.async` closure makes this
    /// equivalent to `.receive(on: DispatchQueue.main).sink { ... }`. Tests can
    /// pass `{ $0() }` to deliver values synchronously, which lets coordinator
    /// tests assert on side effects without pumping the runloop.
    ///
    /// (Previously this used `Container.shared.mainScheduler()` to resolve a
    /// scheduler from the consumer's DI container. The closure form drops the
    /// dependency on Factory entirely so the package stays DI-agnostic.)
    func sinkOnMain(
        schedule: @escaping (@escaping () -> Void) -> Void = { DispatchQueue.main.async(execute: $0) },
        _ receiveValue: @escaping (Output) -> Void
    ) -> AnyCancellable {
        sink { value in
            schedule { receiveValue(value) }
        }
    }
}

// MARK: - --> binding operator

infix operator -->

/// Binds a `Never`-failing publisher to a `Binder` — the write-only,
/// main-thread sink primitive used throughout `populate(with:)` implementations.
@discardableResult
public func --> <T>(publisher: AnyPublisher<T, Never>, binder: Binder<T>) -> AnyCancellable {
    publisher.receive(on: RunLoop.main).sink { binder.on($0) }
}

/// `-->` overload: binds a non-optional publisher into a `Binder` that accepts an
/// optional. Implicitly lifts the value to `.some(...)`.
@discardableResult
public func --> <T>(publisher: AnyPublisher<T, Never>, binder: Binder<T?>) -> AnyCancellable {
    publisher.receive(on: RunLoop.main).sink { binder.on($0) }
}

/// `-->` overload: binds an optional publisher into a `Binder` of the same
/// optional type.
@discardableResult
public func --> <T>(publisher: AnyPublisher<T?, Never>, binder: Binder<T?>) -> AnyCancellable {
    publisher.receive(on: RunLoop.main).sink { binder.on($0) }
}

/// `-->` overload: binds a string publisher directly into a `UILabel`'s `text`.
@discardableResult
public func --> (publisher: AnyPublisher<String, Never>, label: UILabel) -> AnyCancellable {
    publisher.receive(on: RunLoop.main).sink { [weak label] in label?.text = $0 }
}

/// `-->` overload: same as the `String` variant but for optional strings.
@discardableResult
public func --> (publisher: AnyPublisher<String?, Never>, label: UILabel) -> AnyCancellable {
    publisher.receive(on: RunLoop.main).sink { [weak label] in label?.text = $0 }
}

/// `-->` overload: binds a string publisher directly into a `UITextView`'s `text`.
@discardableResult
public func --> (publisher: AnyPublisher<String, Never>, textView: UITextView) -> AnyCancellable {
    publisher.receive(on: RunLoop.main).sink { [weak textView] in textView?.text = $0 }
}

/// `-->` overload: same as the `String` variant but for optional strings.
@discardableResult
public func --> (publisher: AnyPublisher<String?, Never>, textView: UITextView) -> AnyCancellable {
    publisher.receive(on: RunLoop.main).sink { [weak textView] in textView?.text = $0 }
}
