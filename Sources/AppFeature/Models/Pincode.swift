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

/// A fixed-length user-chosen pincode used to unlock the app.
///
/// The pincode has **no cryptographic role** — the wallet's private key is
/// protected by the user's `WalletEncryptionPassword`, not by this pincode. The
/// pincode only gates re-entry into the already-authenticated app session.
public struct Pincode: Equatable, Codable {
    /// The raw digits making up the pincode, in order. Guaranteed to be exactly
    /// `Pincode.length` digits once successfully constructed.
    public let digits: [Digit]

    /// Constructs a pincode from an ordered list of digits. Throws if the list is
    /// not exactly `Pincode.length` digits long.
    public init(digits: [Digit]) throws {
        if digits.count > Pincode.length { throw Error.pincodeTooLong }
        if digits.count < Pincode.length { throw Error.pincodeTooShort }
        self.digits = digits
    }
}

// MARK: Minimum length

extension Pincode {
    /// The enforced pincode length, in digits.
    public static let length: Int = 4
}

// MARK: - Error

extension Pincode {
    /// Construction failures surfaced from `Pincode.init(digits:)`.
    public enum Error: Swift.Error {
        /// Caller supplied more than `Pincode.length` digits.
        case pincodeTooLong

        /// Caller supplied fewer than `Pincode.length` digits.
        case pincodeTooShort
    }
}
