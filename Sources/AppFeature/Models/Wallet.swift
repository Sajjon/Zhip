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

import NanoViewControllerCore
import Zesame

/// App-side wrapper around `Zesame.Wallet` that additionally records *how* the wallet
/// entered the app (`Origin`).
///
/// The origin is critical because the encryption-password policy depends on it:
/// keystores have their own minimum-length rule (`Zesame.Keystore.minimumPasswordLength`)
/// while wallets generated locally or imported via private key follow this app's
/// stricter `.newOrRestorePrivateKey` policy. See `WalletEncryptionPassword.Mode`.
public struct Wallet: Codable {
    /// The underlying Zesame wallet (private key + keystore + address).
    public let wallet: Zesame.Wallet

    /// Provenance — drives the encryption-password mode used for this wallet.
    public let origin: Origin

    // MARK: Origin

    /// How a wallet came into existence inside this app.
    ///
    /// Encoded as a raw `Int` so the persisted value is stable across enum-case
    /// reordering — never reorder existing cases or change their raw values without
    /// a migration, since old keychain entries would deserialize to the wrong case.
    public enum Origin: Int, Codable {
        /// Wallet was generated fresh on this device (no external input).
        case generatedByThisApp
        /// Wallet was restored from a raw private-key string the user pasted in.
        case importedPrivateKey
        /// Wallet was restored from a JSON keystore file (with its own password).
        case importedKeystore
    }

    /// Errors surfaced when working with a `Wallet` value.
    public enum Error: Swift.Error {
        /// A required wallet was unexpectedly absent (e.g. expected-active-wallet lookup).
        case isNil
    }
}

public extension Wallet {
    /// Convenience pass-through to the underlying Zesame keystore.
    var keystore: Keystore {
        wallet.keystore
    }

    /// The wallet's address rendered in Zilliqa's Bech32 form (`zil1…`).
    ///
    /// The conversion is logically infallible — the underlying `wallet.address` is
    /// already valid, so `Bech32Address(ethStyleAddress:network:)` cannot reject it.
    /// We surface that invariant via `incorrectImplementation(_:)` rather than rethrow,
    /// so a future regression in Zesame would crash loudly with a clear message instead
    /// of silently propagating an impossible error up the call stack.
    var bech32Address: Bech32Address {
        do {
            return try Bech32Address(ethStyleAddress: wallet.address, network: network)
        } catch { incorrectImplementation("should work") }
    }

    /// The wallet's address rendered in the legacy (Ethereum-style) hex form.
    var legacyAddress: LegacyAddress {
        wallet.address
    }
}
