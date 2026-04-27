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

import Foundation

/// Type-erased view-friendly variant of `Validation<Value, Error>`.
///
/// `Validation` carries the typed value/error; `AnyValidation` strips them
/// down to what the UI cares about: "is it valid", "is it empty", and (if
/// erroneous) the user-facing message string.
///
/// `FloatingLabelTextField.validationBinder` consumes this type to drive its
/// teal/red/grey color states.
enum AnyValidation {
    /// Field validates; an optional `withRemark` string can be displayed in mellow yellow.
    case valid(withRemark: String?)
    /// Field is empty (or "untouched" — neutral grey state, no error).
    case empty
    /// Field has an error to display, with a localized human-readable message.
    case errorMessage(String)

    /// Bridge from a typed `Validation<Value, Error>`. Loses the typed value
    /// but preserves error/remark messages.
    init(_ validation: Validation<some Any, some InputError>) {
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

extension AnyValidation {
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
    var validation: AnyValidation {
        self
    }
}
