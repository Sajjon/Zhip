//
// MIT License
//
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

/// A pure function from a raw `Input` to a typed `Validation<Output, Error>`.
///
/// Implementations exist per input domain (`AddressValidator`,
/// `EncryptionPasswordValidator`, `GasLimitValidator`, …) and are composed in
/// `Sources/Scenes/.../*ViewModel.swift` via `InputValidator()` to derive the
/// reactive validation pulses bound to `FloatingLabelTextField.validationBinder`.
protocol InputValidator {
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

extension InputValidator {
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

extension InputValidator where Self: ValidationRulesOwner, Self.RuleInput == Input, Output == Input {
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

extension InputValidator where Input == Double, Output == Double {
    /// Convenience for validators that take `Double` but receive `String?`
    /// from a `UITextField`. Empty / non-numeric strings map to `.invalid(.empty)`.
    func validate(string: String?) -> ValidationResult {
        guard let input = string, let double = Double(input) else { return Validation.invalid(.empty) }
        return validate(input: double)
    }
}
