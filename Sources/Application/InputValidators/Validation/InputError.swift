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

/// Error protocol every per-validator `Error` enum conforms to so the view
/// layer can render a localized message without knowing the concrete type.
///
/// `isEqual(_:)` is needed because `Validation`'s `Equatable` conformance
/// has to compare typed errors through the existential without relying on
/// each error type also being `Equatable`.
public protocol InputError: Swift.Error, CustomStringConvertible {
    /// The localized, user-facing message rendered in the floating-label field.
    var errorMessage: String { get }
    /// Existential equality. Default is "always equal" — override per-error
    /// to compare associated values (see `WalletEncryptionPassword.Error`).
    func isEqual(_ error: InputError) -> Bool
}

public extension CustomStringConvertible where Self: InputError {
    /// Default `description` simply forwards to `errorMessage`.
    var description: String {
        errorMessage
    }
}

public extension InputError {
    /// Default impl — treat all values of the same case as equal. Concrete
    /// errors with associated values that matter for equality (e.g. password
    /// rule errors) should override.
    func isEqual(_: InputError) -> Bool {
        true
    }
}
