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
import UIKit
import Zesame

/// Outcomes the create-new-wallet sub-flow surfaces to its parent
/// (`ChooseWalletCoordinator`).
enum CreateNewWalletCoordinatorNavigationStep {
    /// User completed all three steps (privacy gate → password → backup) and
    /// produced a `Wallet` ready to persist.
    case create(wallet: Wallet)
    /// User cancelled at some point during the flow.
    case cancel
}

/// Coordinator owning the linear "create a brand-new wallet" sub-flow:
///
/// 1. `EnsureThatYouAreNotBeingWatched` — privacy gate.
/// 2. `CreateNewWallet` — password entry + key derivation.
/// 3. `BackupWalletCoordinator` — show keystore + private key for backup.
///
/// Cancel at any step short-circuits to `.cancel`. A successful backup
/// completion advances to `.create(wallet:)`.
final class CreateNewWalletCoordinator: BaseCoordinator<CreateNewWalletCoordinatorNavigationStep> {

    /// Begins at step 1 — the privacy gate.
    override func start(didStart _: Completion? = nil) {
        toEnsureThatYouAreNotBeingWatched()
    }
}

// MARK: Private

private extension CreateNewWalletCoordinator {
    /// Step 1 — privacy gate. `.understand` advances to password entry,
    /// `.cancel` aborts the whole sub-flow.
    func toEnsureThatYouAreNotBeingWatched() {
        let viewModel = EnsureThatYouAreNotBeingWatchedViewModel()
        push(scene: EnsureThatYouAreNotBeingWatched.self, viewModel: viewModel) { [unowned self] userDid in
            switch userDid {
            case .understand: self.toCreateWallet()
            case .cancel: self.cancel()
            }
        }
    }

    /// Step 2 — password entry + keystore derivation. `.createWallet(wallet)`
    /// hands the freshly-derived wallet to the backup sub-coordinator.
    func toCreateWallet() {
        let viewModel = CreateNewWalletViewModel()

        push(scene: CreateNewWallet.self, viewModel: viewModel) { [unowned self] userDid in
            switch userDid {
            case let .createWallet(wallet): self.toBackupWallet(wallet: wallet)
            case .cancel: self.cancel()
            }
        }
    }

    /// Step 3 — hands off to `BackupWalletCoordinator` so the user can
    /// eyeball/save their keystore and private key. Wraps the wallet in a
    /// `Just` publisher because the backup coordinator's API is reactive
    /// (it can also receive a wallet that's still being decrypted).
    func toBackupWallet(wallet: Wallet) {
        start(
            coordinator: BackupWalletCoordinator(
                navigationController: navigationController,
                wallet: Just(wallet).eraseToAnyPublisher()
            )
        ) { [unowned self] userFinished in
            switch userFinished {
            case .cancel: self.cancel()
            case .backUp: self.toMain(wallet: wallet)
            }
        }
    }

    /// Bubble `.cancel` to the parent so it can dismiss the modal.
    func cancel() {
        navigator.next(.cancel)
    }

    /// Bubble the freshly-created wallet up to the parent for persistence.
    func toMain(wallet: Wallet) {
        navigator.next(.create(wallet: wallet))
    }
}
