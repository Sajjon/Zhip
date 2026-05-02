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
import Zesame

/// A validated wallet-encryption password.
///
/// Construction enforces both **structural** rules (length per `Mode`) and
/// **confirmation** (the user typed the same value twice). Once you hold an
/// instance, `validPassword` is guaranteed to be a string that satisfies the
/// chosen `Mode` — call sites can use it without re-validating.
public struct WalletEncryptionPassword {
    /// The plaintext password the user supplied. Already known to satisfy the
    /// length rule of the `Mode` passed at init.
    public let validPassword: String

    /// Validates a `(password, confirm)` pair against the chosen `Mode` and stores
    /// the result on success.
    ///
    /// - Throws:
    ///   - `Error.passwordsDoesNotMatch` if the two inputs differ.
    ///   - `Error.passwordIsTooShort(mustAtLeastHaveLength:)` if shorter than `mode.minimumPasswordLength`.
    public init(password: String, confirm: String, mode: Mode) throws {
        let minLength = mode.minimumPasswordLength
        // Confirmation check first — saves the user from a "too short" message
        // when the real problem is a typo in one of the two fields.
        guard confirm == password else { throw Error.passwordsDoesNotMatch }
        guard password.count >= minLength else { throw Error.passwordIsTooShort(mustAtLeastHaveLength: minLength) }
        validPassword = password
    }
}

public extension WalletEncryptionPassword {
    /// The minimum number of characters required for a password under `mode`.
    static func minimumLength(mode: Mode) -> Int {
        mode.minimumPasswordLength
    }

    /// Returns the appropriate password `Mode` for the given wallet, derived from
    /// its `Origin`. (Wallets imported from a keystore use the keystore's own
    /// minimum-length rule; everything else uses the stricter app-side rule.)
    static func modeFrom(wallet: Wallet) -> WalletEncryptionPassword.Mode {
        wallet.passwordMode
    }

    /// Convenience — minimum password length for a specific wallet.
    static func minimumLengthForWallet(_ wallet: Wallet) -> Int {
        minimumLength(mode: wallet.passwordMode)
    }
}

// MARK: - Error

public extension WalletEncryptionPassword {
    /// Failure modes related to wallet-encryption passwords.
    enum Error: Swift.Error {
        /// The password and confirm-password fields did not match.
        case passwordsDoesNotMatch

        /// The supplied password was shorter than `mustAtLeastHaveLength` characters.
        case passwordIsTooShort(mustAtLeastHaveLength: Int)

        /// The password did not decrypt the wallet's keystore.
        ///
        /// `backingUpWalletJustCreated` is `true` when the failure happened during
        /// the immediately-after-creation backup screen — UX uses that to surface
        /// a friendlier "you literally just chose this password" message.
        case incorrectPassword(backingUpWalletJustCreated: Bool)

        /// Adapter: lift a `Zesame.Error.WalletImport` into our app-side error
        /// shape *if* it is an incorrect-password failure. Returns `nil` for any
        /// other variant so the caller can keep handling it as a generic error.
        static func incorrectPasswordErrorFrom(
            walletImportError: Zesame.Error.WalletImport,
            backingUpWalletJustCreated: Bool = false
        ) -> Error? {
            switch walletImportError {
            case .incorrectPassword: .incorrectPassword(backingUpWalletJustCreated: backingUpWalletJustCreated)
            default: nil
            }
        }

        /// Same as the typed adapter above, but takes a generic `Swift.Error`
        /// and unwraps it through the `Zesame.Error.walletImport(_:)` case.
        /// Returns `nil` if the input wasn't an incorrect-password failure
        /// (or wasn't a `Zesame.Error` at all).
        static func incorrectPasswordErrorFrom(error: Swift.Error, backingUpWalletJustCreated: Bool = false) -> Error? {
            guard
                let zesameError = error as? Zesame.Error,
                case let .walletImport(walletImportError) = zesameError
            else { return nil }

            return incorrectPasswordErrorFrom(
                walletImportError: walletImportError,
                backingUpWalletJustCreated: backingUpWalletJustCreated
            )
        }
    }
}

// MARK: - Mode

public extension WalletEncryptionPassword {
    /// Which length policy a password should be validated against.
    /// Different wallet origins have different minimum lengths.
    enum Mode: CaseIterable {
        /// Strict app-side policy used when generating a new wallet or restoring
        /// from a raw private key (8 chars min).
        case newOrRestorePrivateKey

        /// Looser policy delegated to `Zesame.Keystore.minimumPasswordLength`,
        /// used when restoring from an existing keystore (the keystore itself
        /// already encodes its password rule, so we honour that).
        case restoreKeystore
    }
}

public extension WalletEncryptionPassword.Mode {
    /// Minimum number of characters a password must have under this mode.
    var minimumPasswordLength: Int {
        switch self {
        case .newOrRestorePrivateKey: 8
        case .restoreKeystore: Zesame.Keystore.minimumPasswordLength
        }
    }
}

// MARK: Wallet.Origin -> Mode

private extension Wallet.Origin {
    /// Maps wallet provenance to the corresponding password policy.
    /// Kept `private` so the only public entry point is
    /// `WalletEncryptionPassword.modeFrom(wallet:)`.
    public var passwordMode: WalletEncryptionPassword.Mode {
        switch self {
        case .generatedByThisApp, .importedPrivateKey: .newOrRestorePrivateKey
        case .importedKeystore: .restoreKeystore
        }
    }
}

// MARK: Wallet -> Mode

private extension Wallet {
    /// Convenience: skip straight from a `Wallet` to its password mode without
    /// going through `wallet.origin.passwordMode` at every call site.
    public var passwordMode: WalletEncryptionPassword.Mode {
        origin.passwordMode
    }
}

/// Conformance only — equality is structural over `validPassword`.
extension WalletEncryptionPassword: Equatable {}
