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
import Factory
import Foundation
import Zesame

/// Default implementation of `WalletStorageUseCase` — thin wrapper over
/// `SecurePersistence` for keychain-backed wallet reads and writes.
///
/// Caches the wallet in a `CurrentValueSubject` so subscribers don't pay
/// Keychain I/O + JSON-decode on every subscription. The subject is the
/// single source of truth for the reactive `wallet` publisher; `save` and
/// `deleteWallet` push through it.
public final class DefaultWalletStorageUseCase: WalletStorageUseCase {
    /// Keychain-backed secure store. Resolved via Factory so tests can register
    /// an in-memory `SecurePersistence` to keep the suite hermetic.
    @Injected(\.securePersistence) private var securePersistence: SecurePersistence

    /// In-memory cache for the persisted wallet. Lazily seeded from the
    /// Keychain on first access (one read per app session), then driven
    /// entirely by writes — `save` and `deleteWallet` push the new value
    /// through this subject.
    private lazy var walletSubject: CurrentValueSubject<Wallet?, Never> =
        CurrentValueSubject(securePersistence.wallet)

    /// No-op designated initializer — all dependencies are resolved through `@Injected`.
    init() {}

    /// Persists `wallet` to the secure store, replacing any previously saved
    /// wallet, and updates the cached subject so subscribers see the new value.
    public func save(wallet: Wallet) {
        securePersistence.save(wallet: wallet)
        walletSubject.send(wallet)
    }

    /// Removes the persisted wallet (if any) and notifies subscribers.
    public func deleteWallet() {
        securePersistence.deleteWallet()
        walletSubject.send(nil)
    }

    /// Returns the cached wallet — synchronous accessor used by sites that
    /// need the value immediately and don't want to subscribe.
    public func loadWallet() -> Wallet? {
        walletSubject.value
    }

    /// `true` iff a wallet is currently cached.
    public var hasConfiguredWallet: Bool {
        walletSubject.value != nil
    }

    /// Reactive cache: emits the current wallet immediately on subscribe and
    /// re-emits whenever `save` or `deleteWallet` is called. Single Keychain
    /// read at first access; everything else is in-memory.
    public var wallet: AnyPublisher<Wallet?, Never> {
        walletSubject.eraseToAnyPublisher()
    }
}
