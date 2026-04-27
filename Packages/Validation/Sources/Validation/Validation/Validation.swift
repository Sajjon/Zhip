// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Typed pendant to `AnyValidation`: holds the actual `Value` on success and
/// the typed `Error` on failure.
///
/// View models hold `Validation<Value, Error>` so they can extract the typed
/// value (e.g. `Address`, `Amount`) for forwarding to a use case. The view
/// layer projects to `AnyValidation` for display.
public enum Validation<Value, Error: InputError> {
    /// Field validates. `remark` is an optional non-fatal note (rendered in mellow yellow).
    case valid(Value, remark: Error?)
    /// Field doesn't validate.
    case invalid(Invalid)

    /// Why a field is invalid.
    public enum Invalid {
        /// Untouched / empty — render neutral grey, no error message.
        case empty
        /// Has a typed error.
        case error(Error)
    }
}

// MARK: - Convenience Getters

public extension Validation {
    /// Sugar for `.valid(value, remark: nil)`.
    static func valid(_ value: Value) -> Validation {
        .valid(value, remark: nil)
    }

    /// The typed value for the `.valid` case, `nil` otherwise.
    var value: Value? {
        switch self {
        case let .valid(value, _): value
        default: nil
        }
    }

    /// `true` iff `value != nil`.
    var isValid: Bool {
        value != nil
    }

    /// The typed error for the `.invalid(.error(_))` case, `nil` for `.valid` and `.empty`.
    var error: InputError? {
        guard case let .invalid(.error(error)) = self else { return nil }
        return error
    }

    /// `true` iff `error != nil`.
    var isError: Bool {
        error != nil
    }
}
