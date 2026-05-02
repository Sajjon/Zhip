// MIT License — Copyright (c) 2018-2026 Open Zesame

import NanoViewControllerCore

/// A pure function from a raw `Input` to a typed `Validation<Output, Error>`.
///
/// Implementations exist per input domain (`AddressValidator`,
/// `EncryptionPasswordValidator`, `GasLimitValidator`, …) and are composed in
/// `Sources/Scenes/.../*ViewModel.swift` via `InputValidator()` to derive the
/// reactive validation pulses bound to `FloatingLabelTextField.validationBinder`.
public protocol InputValidator {
    /// Raw input shape — typically `String`, sometimes a tuple (e.g. password + confirmation).
    associatedtype Input
    /// Typed value returned on success (e.g. `Address`, `Amount`).
    associatedtype Output
    /// Validator-specific error type. Conforms to `InputError` so the view layer can render `errorMessage`.
    associatedtype Error: InputError

    /// Optional-input convenience that maps `nil` to `.invalid(.empty)`.
    func validate(input: Input?) -> Validation<Output, Error>
    /// Required core validator — must produce a `Validation` for any non-nil input.
    func validate(input: Input) -> Validation<Output, Error>
}

public extension InputValidator {
    /// Sugar for `Validation<Output, Error>` so call sites read `validator.ValidationResult`.
    typealias ValidationResult = Validation<Output, Error>

    /// Default `Input?` overload — empty fields produce `.invalid(.empty)` so the
    /// view can render the "untouched" gray styling rather than a real error.
    func validate(input: Input?) -> ValidationResult {
        guard let input else { return .invalid(.empty) }
        return validate(input: input)
    }

    /// Convenience constructor for an `.invalid(.error(...))` result.
    func error(_ error: Error) -> ValidationResult {
        .invalid(.error(error))
    }
}

public extension InputValidator where Self: ValidationRulesOwner, Self.RuleInput == Input, Output == Input {
    /// Default `validate` impl for validators that simply hand off to a
    /// `ValidationRuleSet` — runs the rules, returns `.valid(input)` if all
    /// pass, otherwise wraps the first failure in an `Error`.
    func validate(input: Input) -> ValidationResult {
        let validationResult = input.validate(rules: rules)
        switch validationResult {
        case .valid: return .valid(input)
        case let .invalid(errors):
            guard let inputError = errors.first as? Error
            else { incorrectImplementation("Expected error of type `Self.Error`") }
            return .invalid(.error(inputError))
        }
    }
}

// MARK: - String to Double

public extension InputValidator where Input == Double, Output == Double {
    /// Convenience for validators that take `Double` but receive `String?`
    /// from a `UITextField`. Empty / non-numeric strings map to `.invalid(.empty)`.
    func validate(string: String?) -> ValidationResult {
        guard let input = string, let double = Double(input) else { return Validation.invalid(.empty) }
        return validate(input: double)
    }
}
