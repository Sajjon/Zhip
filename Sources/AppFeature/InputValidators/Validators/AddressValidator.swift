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
import Validation
import Zesame

/// Validates a Zilliqa address string (bech32 or hex), producing a typed `Address`.
///
/// Used on the Send screen and the address-import screens. Falls back to the
/// `Zesame.Address(string:)` initializer for the heavy lifting and translates
/// the library's error vocabulary into our user-facing `Error` enum.
public struct AddressValidator: InputValidator {
    public typealias Input = String
    public typealias Output = Address
//    typealias Error = Address.Error

    /// Tries to construct an `Address`; on failure, maps the `Zesame.Address.Error`
    /// to our local `Error` so the floating-label field can render a localized message.
    public func validate(input: Input) -> Validation<Output, Error> {
        do {
            let address = try Address(string: input)
            return .valid(address)
        } catch let addressError as Address.Error {
            let mappedError = Error(fromAddressError: addressError)
            return .invalid(.error(mappedError))
        } catch {
            incorrectImplementation("Address.Error should cover all errors")
        }
    }
}

public extension AddressValidator {
    /// User-facing error enum. Each case maps to a localized string in
    /// `Errors.strings` via `errorMessage` below.
    enum Error: InputError {
        /// Length mismatch — address is too short or too long.
        case incorrectLength(expectedLength: Int, butGot: Int)
        /// Address parses but its checksum digit doesn't validate.
        case notChecksummed
        /// Input is neither a valid bech32 nor a valid hex string.
        case noBech32NorHexstring
    }
}

extension AddressValidator.Error {
    /// Translates `Zesame.Address.Error` to our user-facing error enum.
    /// Several `Zesame` cases collapse to `noBech32NorHexstring` because the
    /// distinction between "bad bech32 prefix" and "non-hex chars" is not
    /// useful for the user.
    init(fromAddressError: Zesame.Address.Error) {
        switch fromAddressError {
        case let .incorrectLength(expected, _, butGot): self = .incorrectLength(
                expectedLength: expected,
                butGot: butGot
            )
        case .notChecksummed: self = .notChecksummed
        case .bech32DataEmpty, .notHexadecimal: self = .noBech32NorHexstring
        case let .invalidBech32Address(bechError):
            switch bechError {
            case .checksumMismatch: self = .notChecksummed
            default: self = .noBech32NorHexstring
            }
        }
    }

    /// Localized error string rendered on the Send screen's address field.
    public var errorMessage: String {
        switch self {
        case .noBech32NorHexstring: String(localized: .Errors.addressInvalid)
        case let .incorrectLength(expected, incorrect):
            if incorrect > expected {
                String(localized: .Errors.addressTooLong(expectedLength: expected))
            } else {
                String(localized: .Errors.addressTooShort(expectedLength: expected))
            }
        case .notChecksummed: String(localized: .Errors.addressNotChecksummed)
        }
    }
}
