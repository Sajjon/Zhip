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
import SingleLineControllerCore
import Validation
import Zesame

/// Validates a hex-encoded Zilliqa private-key string, producing a `PrivateKey`.
///
/// Used on the "restore wallet from private key" screen. Catches the obvious
/// length errors before doing the cryptographic check (which is more expensive).
public struct PrivateKeyValidator: InputValidator {
    /// Zilliqa private keys are 32 bytes = 64 hex chars.
    static let expectedLengthOfPrivateKey = 64
    public typealias Input = String
    public typealias Output = PrivateKey

    /// Validation failures surfaced to the user.
    public enum Error: InputError {
        /// Fewer than 64 hex chars submitted.
        case tooShort(lengthKeySubmitted: Int)
        /// More than 64 hex chars submitted.
        case tooLong(lengthKeySubmitted: Int)
        /// Right length, but `PrivateKey(rawRepresentation:)` rejected it.
        case badPrivateKey
    }

    /// Length-checks the hex string and then asks `PrivateKey` to parse it.
    /// Length errors short-circuit before the more expensive crypto check.
    public func validate(input: Input) -> Validation<Output, Error> {
        func validate(privateKeyHex: String) throws -> PrivateKey {
            let lengthKeySubmitted = privateKeyHex.count
            if lengthKeySubmitted < PrivateKeyValidator.expectedLengthOfPrivateKey {
                throw Error.tooShort(lengthKeySubmitted: lengthKeySubmitted)
            }

            if lengthKeySubmitted > PrivateKeyValidator.expectedLengthOfPrivateKey {
                throw Error.tooLong(lengthKeySubmitted: lengthKeySubmitted)
            }

            guard
                let privateKeyData = Data(validatingHex: privateKeyHex),
                let privateKey = try? PrivateKey(rawRepresentation: privateKeyData)
            else {
                throw Error.badPrivateKey
            }

            return privateKey
        }

        do {
            return try .valid(validate(privateKeyHex: input))
        } catch let privateError as Error {
            return .invalid(.error(privateError))
        } catch {
            incorrectImplementation("Address.Error should cover all errors")
        }
    }
}

public extension PrivateKeyValidator.Error {
    /// Localized message — the length cases include "missing N chars" / "excess N chars"
    /// hints to help the user spot a copy-paste truncation/duplication.
    var errorMessage: String {
        let expectedLength = PrivateKeyValidator.expectedLengthOfPrivateKey

        switch self {
        case let .tooShort(lengthKeySubmitted): return String(localized: .Errors.privateKeyTooShort(
                expected: expectedLength,
                missing: expectedLength - lengthKeySubmitted
            ))
        case let .tooLong(lengthKeySubmitted): return String(localized: .Errors.privateKeyTooLong(
                expected: expectedLength,
                excess: lengthKeySubmitted - expectedLength
            ))
        case .badPrivateKey: return String(localized: .Errors.privateKeyBad)
        }
    }
}
