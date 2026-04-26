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

/// Default implementation of `RestoreWalletUseCase`.
final class DefaultRestoreWalletUseCase: RestoreWalletUseCase {

    /// Reactive Zesame façade — performs the actual wallet restoration.
    @Injected(\.zilliqaService) private var zilliqaService: ZilliqaServiceReactive

    /// No-op designated initializer — all dependencies are resolved through `@Injected`.
    init() {}

    /// Restores a wallet from the supplied `KeyRestoration` and tags the result with
    /// the matching `Wallet.Origin`. The origin tag is critical — it determines which
    /// `WalletEncryptionPassword.Mode` (and thus minimum-length policy) applies later
    /// when the user re-enters the password, e.g. for backup or transactions.
    func restoreWallet(from restoration: KeyRestoration) -> AnyPublisher<Wallet, Swift.Error> {
        // Map the input restoration variant to its provenance tag — keystore imports
        // get `.importedKeystore` (looser password rules from the keystore itself),
        // private-key imports get `.importedPrivateKey` (strict app-side rules).
        let origin: Wallet.Origin = switch restoration {
        case .keystore: .importedKeystore
        case .privateKey: .importedPrivateKey
        }
        return zilliqaService.restoreWallet(from: restoration)
            .map { Wallet(wallet: $0, origin: origin) }
            .mapError { $0 as Swift.Error }
            .eraseToAnyPublisher()
    }
}
