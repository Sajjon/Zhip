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

import Combine
import Factory
import Foundation
import Zesame

/// Default implementation of `WalletStorageUseCase` — thin wrapper over
/// `SecurePersistence` for keychain-backed wallet reads and writes.
final class DefaultWalletStorageUseCase: WalletStorageUseCase {

    /// Keychain-backed secure store. Resolved via Factory so tests can register
    /// an in-memory `SecurePersistence` to keep the suite hermetic.
    @Injected(\.securePersistence) private var securePersistence: SecurePersistence

    /// No-op designated initializer — all dependencies are resolved through `@Injected`.
    init() {}

    /// Persists `wallet` to the secure store, replacing any previously saved wallet.
    func save(wallet: Wallet) {
        securePersistence.save(wallet: wallet)
    }

    /// Removes the persisted wallet, if any.
    func deleteWallet() {
        securePersistence.deleteWallet()
    }

    /// Loads the persisted wallet, or `nil` if none exists.
    func loadWallet() -> Wallet? {
        securePersistence.wallet
    }

    /// `true` iff a wallet is currently persisted in the secure store.
    var hasConfiguredWallet: Bool {
        securePersistence.hasConfiguredWallet
    }
}
