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

/// Validates a pasted keystore JSON string, producing a typed `Keystore`.
///
/// Used on the "restore wallet from keystore" screen. Only validates the JSON
/// shape — the password isn't checked here (that happens later in
/// `RestoreWalletUseCase`); `incorrectPassword` is included to allow the
/// downstream use case to surface the same error type via `ErrorTracker`.
struct KeystoreValidator: InputValidator {
    typealias Input = String
    typealias Output = Keystore

    /// Validation failures surfaced to the user.
    enum Error: InputError {
        /// The input string couldn't be UTF-8 encoded into `Data` (impossible in practice).
        case stringToDataConversionFailed
        /// JSON decoding failed — either malformed JSON or wrong shape for `Keystore`.
        case badJSON(Swift.DecodingError)
        /// Password used to derive the keystore is wrong (surfaced from the
        /// downstream use case via `ErrorTracker`, not produced here).
        case incorrectPassword

        /// Adapts a `Zesame.Error.WalletImport` to our error type. Returns
        /// `nil` for any case other than `.incorrectPassword`.
        init?(walletImportError: Zesame.Error.WalletImport) {
            switch walletImportError {
            case .incorrectPassword: self = .incorrectPassword
            default: return nil
            }
        }

        /// Reflective adapter for arbitrary `Swift.Error` values arriving from
        /// the use case layer. Returns `nil` if the error isn't a wallet-import error.
        init?(error: Swift.Error) {
            guard
                let zesameError = error as? Zesame.Error,
                case let .walletImport(walletImportError) = zesameError
            else { return nil }
            self.init(walletImportError: walletImportError)
        }
    }

    /// Parses `input` as `Keystore` JSON. Catches `DecodingError`s and surfaces
    /// them as `.badJSON`; any other error indicates a logic bug.
    func validate(input: Input) -> Validation<Output, Error> {
        func validate() throws -> Keystore {
            guard let json = input.data(using: .utf8) else {
                throw Error.stringToDataConversionFailed
            }

            do {
                return try JSONDecoder().decode(Keystore.self, from: json)
            } catch let jsonDecoderError as Swift.DecodingError {
                throw Error.badJSON(jsonDecoderError)
            } catch {
                incorrectImplementation("DecodingError should cover all errors")
            }
        }

        do {
            return try .valid(validate())
        } catch let error as Error {
            return .invalid(.error(error))
        } catch {
            incorrectImplementation("All errors should have been covered")
        }
    }
}

extension KeystoreValidator.Error {
    /// Localized message rendered on the keystore-restore screen.
    /// `badJSON` and `stringToDataConversionFailed` collapse to the same
    /// "bad format" message because the user has nothing actionable to do
    /// with the difference.
    var errorMessage: String {
        switch self {
        case .badJSON, .stringToDataConversionFailed: String(localized: .Errors.keystoreBadFormat)
        case .incorrectPassword: String(localized: .Errors.keystoreIncorrectPassword)
        }
    }
}
