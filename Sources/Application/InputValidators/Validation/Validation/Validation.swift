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

/// Typed pendant to `AnyValidation`: holds the actual `Value` on success and
/// the typed `Error` on failure.
///
/// View models hold `Validation<Value, Error>` so they can extract the typed
/// value (e.g. `Address`, `Amount`) for forwarding to a use case. The view
/// layer projects to `AnyValidation` for display.
enum Validation<Value, Error: InputError> {
    /// Field validates. `remark` is an optional non-fatal note (rendered in mellow yellow).
    case valid(Value, remark: Error?)
    /// Field doesn't validate.
    case invalid(Invalid)

    /// Why a field is invalid.
    enum Invalid {
        /// Untouched / empty — render neutral grey, no error message.
        case empty
        /// Has a typed error.
        case error(Error)
    }
}

// MARK: - Convenience Getters

extension Validation {
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
