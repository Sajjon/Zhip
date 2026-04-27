// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Write-only wrapper that always applies values on the main thread.
///
/// A `Binder<Value>` wraps a writing closure that targets some UI object with a
/// weak reference so it can't extend the object's lifetime. The `-->` operator
/// (`Publisher+Operators.swift`) drives values into a binder; UIKit extensions
/// expose binders as properties (e.g. `UIControl.isEnabledBinder`,
/// `UIView.isVisibleBinder`).
public struct Binder<Value> {

    /// Thread-aware closure that applies a value to the wrapped object. Assigned
    /// once in `init` and never mutated.
    private let _binding: (Value) -> Void

    /// Creates a binder that writes `Value`s into `object` via `binding`.
    ///
    /// `object` is captured weakly. If the underlying object has been deallocated
    /// by the time a value arrives, the write is silently dropped. Writes from a
    /// background thread are dispatched to `DispatchQueue.main`.
    public init<Object: AnyObject>(
        _ object: Object,
        binding: @escaping (Object, Value) -> Void
    ) {
        _binding = { [weak object] value in
            guard let object else { return }
            if Thread.isMainThread {
                binding(object, value)
            } else {
                DispatchQueue.main.async { binding(object, value) }
            }
        }
    }

    /// Writes `value` through the wrapped binding on the main thread.
    public func on(_ value: Value) {
        _binding(value)
    }
}
