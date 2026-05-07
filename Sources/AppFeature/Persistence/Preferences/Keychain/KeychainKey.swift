//
// MIT License
//
// Copyright (c) 2018-2026 Alexander Cyon (https://github.com/sajjon)
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

/// Key to sensitive values being store in Keychain, e.g. the cryptographically sensitive keystore file, containing an
/// encryption of your wallets private key.
public enum KeychainKey: String, KeyConvertible {
    /// JSON-encoded `Wallet` (which contains the encrypted-keystore JSON for the user's private key).
    case keystore
    /// JSON-encoded `Pincode`. The verbose name is intentional — it documents at the
    /// callsite that this PIN is *only* for app-level lock; it has nothing to do with the
    /// cryptographic key material in `keystore`.
    case pincodeProtectingAppThatHasNothingToDoWithCryptography
}

/// Abstraction of Keychain
///
/// Production code injects a `SecurePersistence` (i.e. a `KeyValueStore<KeychainKey>`)
/// resolved by `Container.shared.securePersistence`, which wraps `KeychainSwift`.
/// Tests register an in-memory replacement in `Tests/Helpers/TestStoreFactory.swift`.
public typealias SecurePersistence = KeyValueStore<KeychainKey>
