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

// MARK: - Wallet

/// Typed conveniences for reading/writing the user's `Wallet` blob from `SecurePersistence`.
extension KeyValueStore where KeyType == KeychainKey {
    /// The persisted `Wallet`, or `nil` if none.
    ///
    /// Pure read — no side effects. The reinstall-wipe behaviour (iOS keeps
    /// the Keychain across uninstalls but clears UserDefaults; without a
    /// wipe a reinstalling user would inherit a wallet they no longer hold
    /// the encryption password for) lives in
    /// `wipeStaleKeychainOnReinstallIfNeeded(...)` in `Bootstrap.swift` and
    /// runs once at launch via `AppDelegate.application(_:didFinishLaunching…)`.
    var wallet: Wallet? {
        loadCodable(Wallet.self, for: .keystore)
    }

    /// `true` iff `wallet` resolves to a non-`nil` value.
    var hasConfiguredWallet: Bool {
        wallet != nil
    }

    /// Persists `wallet` (as JSON) under `KeychainKey.keystore`.
    func save(wallet: Wallet) {
        saveCodable(wallet, for: .keystore)
    }

    /// Removes the persisted wallet from the Keychain.
    func deleteWallet() {
        deleteValue(for: .keystore)
    }
}

/// Typed conveniences for reading/writing the app-lock `Pincode` from `SecurePersistence`.
extension KeyValueStore where KeyType == KeychainKey {
    /// The persisted app-lock pincode, or `nil` if the user hasn't set one.
    var pincode: Pincode? {
        loadCodable(Pincode.self, for: .pincodeProtectingAppThatHasNothingToDoWithCryptography)
    }

    /// `true` iff `pincode` resolves to a non-`nil` value.
    var hasConfiguredPincode: Bool {
        pincode != nil
    }

    /// Persists `pincode` (as JSON) under the pincode key.
    func save(pincode: Pincode) {
        saveCodable(pincode, for: .pincodeProtectingAppThatHasNothingToDoWithCryptography)
    }

    /// Removes the persisted pincode from the Keychain.
    func deletePincode() {
        deleteValue(for: .pincodeProtectingAppThatHasNothingToDoWithCryptography)
    }
}
