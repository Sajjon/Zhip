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

import SingleLineControllerCore
import Zesame

/// Validates a password + confirmation pair, producing a typed
/// `WalletEncryptionPassword` value the keystore-derivation use case can consume.
///
/// `mode` controls the minimum length rule (stricter for new wallets,
/// looser for the unlock screen of an already-saved wallet).
struct EncryptionPasswordValidator: InputValidator {
    typealias Input = (password: String, confirmingPassword: String)
    typealias Output = WalletEncryptionPassword
    typealias Error = WalletEncryptionPassword.Error

    /// The password-policy mode (new wallet vs unlock).
    private let mode: WalletEncryptionPassword.Mode

    /// Captures the policy mode for later validation calls.
    init(mode: WalletEncryptionPassword.Mode) {
        self.mode = mode
    }

    /// Tries to construct a `WalletEncryptionPassword`; on failure, surfaces
    /// the typed `WalletEncryptionPassword.Error` for floating-label rendering.
    func validate(input: Input) -> Validation<Output, Error> {
        let password = input.password
        let confirmingPassword = input.confirmingPassword
        do {
            return try .valid(WalletEncryptionPassword(password: password, confirm: confirmingPassword, mode: mode))
        } catch let passwordError as Error {
            return .invalid(.error(passwordError))
        } catch {
            incorrectImplementation("Address.Error should cover all errors")
        }
    }
}

/// `Zesame` error → `InputError` adapter so the password rule errors render as
/// localized strings in the floating-label field.
extension WalletEncryptionPassword.Error: InputError, Equatable {
    /// Localized message rendered for each validation failure.
    /// `incorrectPassword` has two variants because the copy differs between
    /// "you just created the wallet, here's the password you typed" (backup
    /// confirmation) and "unlock your existing wallet" (regular login).
    var errorMessage: String {
        switch self {
        case let .passwordIsTooShort(minLength): String(localized: .Errors.passwordTooShort(minLength: minLength))
        case .passwordsDoesNotMatch: String(localized: .Errors.passwordMismatch)
        case let .incorrectPassword(backingUpWalletJustCreated):
            if backingUpWalletJustCreated {
                String(localized: .Errors.passwordIncorrectDuringBackup)
            } else {
                String(localized: .Errors.passwordIncorrect)
            }
        }
    }

    /// Equality on the case only — associated values (e.g. minLength) don't
    /// affect whether two errors are "the same" for `Validation` equality.
    static func == (lhs: WalletEncryptionPassword.Error, rhs: WalletEncryptionPassword.Error) -> Bool {
        switch (lhs, rhs) {
        case (.passwordIsTooShort, passwordIsTooShort): true
        case (.passwordsDoesNotMatch, passwordsDoesNotMatch): true
        case (.incorrectPassword, incorrectPassword): true
        default: false
        }
    }
}
