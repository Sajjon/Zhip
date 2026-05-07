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

import Combine
import Foundation
import Zesame

// MARK: - Narrow wallet use cases

/// Creates a brand-new wallet from a user-chosen encryption password.
public protocol CreateWalletUseCase: AnyObject {
    /// Generates a fresh wallet, encrypts it with `encryptionPassword`, and emits
    /// the resulting `Wallet` once on success.
    func createNewWallet(encryptionPassword: String) -> AnyPublisher<Wallet, Swift.Error>
}

/// Restores an existing wallet from user-provided keystore or private-key material.
public protocol RestoreWalletUseCase: AnyObject {
    /// Restores a wallet using the supplied `KeyRestoration` (either `.keystore` or
    /// `.privateKey`) and emits the resulting `Wallet` once on success.
    func restoreWallet(from restoration: KeyRestoration) -> AnyPublisher<Wallet, Swift.Error>
}

/// Reads and writes the user's wallet to secure persistent storage.
public protocol WalletStorageUseCase: AnyObject {
    /// Persists `wallet` to secure storage (replacing any previously saved wallet).
    func save(wallet: Wallet)

    /// Removes the currently-persisted wallet, if any.
    func deleteWallet()

    /// Loads the currently-persisted wallet synchronously, or `nil` if none exists.
    func loadWallet() -> Wallet?

    /// `true` if there is a wallet currently persisted in secure storage.
    var hasConfiguredWallet: Bool { get }

    /// Reactive view of the persisted wallet — emits the current value
    /// immediately on subscribe and re-emits whenever `save(wallet:)` or
    /// `deleteWallet()` is called.
    ///
    /// **Implementations should override the default extension** (which does
    /// `Just(loadWallet())`) with a long-lived `CurrentValueSubject` driven by
    /// writes. The default is correct but does Keychain I/O + JSON-decode on
    /// *every* subscription, and many ViewModel `transform(_:)` methods
    /// subscribe several times per scene. Only a no-state mock can safely
    /// keep the default.
    var wallet: AnyPublisher<Wallet?, Never> { get }
}

/// Verifies whether a user-provided password successfully decrypts a keystore.
public protocol VerifyEncryptionPasswordUseCase: AnyObject {
    /// Checks if the passed `password` was used to encrypt `keystore`. The resulting
    /// publisher emits `true`/`false` on the main queue.
    func verify(password: String, forKeystore keystore: Keystore) -> AnyPublisher<Bool, Swift.Error>
}

/// Extracts the raw `KeyPair` from a keystore (public + private key) when supplied
/// with the correct encryption password.
public protocol ExtractKeyPairUseCase: AnyObject {
    /// Decrypts `keystore` with `password` and emits the underlying `KeyPair`.
    func extractKeyPairFrom(keystore: Keystore, encryptedBy password: String) -> AnyPublisher<KeyPair, Swift.Error>
}

// MARK: - Convenience extensions

extension VerifyEncryptionPasswordUseCase {
    /// Convenience overload that verifies a password against the keystore embedded
    /// inside a `Wallet`.
    func verify(password: String, forWallet wallet: Wallet) -> AnyPublisher<Bool, Swift.Error> {
        verify(password: password, forKeystore: wallet.keystore)
    }
}

extension ExtractKeyPairUseCase {
    /// Convenience overload that extracts a key pair from the keystore inside a `Wallet`.
    func extractKeyPairFrom(wallet: Wallet, encryptedBy password: String) -> AnyPublisher<KeyPair, Swift.Error> {
        extractKeyPairFrom(keystore: wallet.keystore, encryptedBy: password)
    }
}

extension WalletStorageUseCase {
    /// Emits the currently-persisted wallet (or `nil`) as a one-shot publisher.
    var wallet: AnyPublisher<Wallet?, Never> {
        Just(loadWallet()).eraseToAnyPublisher()
    }
}
