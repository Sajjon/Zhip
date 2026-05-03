// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Type-erased view-friendly variant of `Validation<Value, Error>`.
///
/// `Validation` carries the typed value/error; `AnyValidation` strips them
/// down to what the UI cares about: "is it valid", "is it empty", and (if
/// erroneous) the user-facing message string.
///
/// `FloatingLabelTextField.validationBinder` consumes this type to drive its
/// teal/red/grey color states.
public enum AnyValidation: Sendable {
    /// Field validates; an optional `withRemark` string can be displayed in mellow yellow.
    case valid(withRemark: String?)
    /// Field is empty (or "untouched" — neutral grey state, no error).
    case empty
    /// Field has an error to display, with a localized human-readable message.
    case errorMessage(String)

    /// Bridge from a typed `Validation<Value, Error>`. Loses the typed value
    /// but preserves error/remark messages.
    public init(_ validation: Validation<some Any, some InputError>) {
        switch validation {
        case let .invalid(invalid):
            switch invalid {
            case .empty:
                self = .empty
            case let .error(error):
                self = .errorMessage(error.errorMessage)
            }
        case let .valid(_, maybeRemark):
            self = .valid(withRemark: maybeRemark?.errorMessage)
        }
    }
}

// MARK: - Convenience Getters

public extension AnyValidation {
    /// `true` for the `.valid` case (with or without a remark).
    var isValid: Bool {
        switch self {
        case .valid: true
        default: false
        }
    }

    /// `true` for the `.empty` case only.
    var isEmpty: Bool {
        switch self {
        case .empty: true
        default: false
        }
    }

    /// `true` for the `.errorMessage` case only.
    var isError: Bool {
        switch self {
        case .errorMessage: true
        default: false
        }
    }
}

// MARK: - ValidationConvertible

extension AnyValidation: ValidationConvertible {
    /// Identity conformance — `AnyValidation` already *is* the conversion target.
    public var validation: AnyValidation {
        self
    }
}
