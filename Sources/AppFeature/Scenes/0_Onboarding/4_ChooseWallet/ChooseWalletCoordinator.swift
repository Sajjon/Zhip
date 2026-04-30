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

import Factory
import UIKit
import Zesame
import SingleLineControllerNavigation

/// Outbound navigation steps emitted by `ChooseWalletCoordinator` to its parent.
///
/// The "choose wallet" flow has only one terminal outcome — once a wallet has been
/// chosen (either freshly created or restored) and persisted, the parent coordinator
/// is told the flow is done.
public enum ChooseWalletCoordinatorNavigationStep {
    /// User has either created a new wallet or restored an existing one, the wallet
    /// has been saved to secure storage, and control should return to the onboarding
    /// flow's parent coordinator so it can advance to the next phase.
    case finishChoosingWallet
}

/// Coordinator owning the "choose wallet" sub-flow of onboarding.
///
/// Flow:
/// 1. Push `ChooseWallet` scene asking the user to either create or restore a wallet.
/// 2. On the user's choice, present a modal child coordinator (`CreateNewWalletCoordinator`
///    or `RestoreWalletCoordinator`) that owns its own navigation stack.
/// 3. When the child coordinator finishes with a `Wallet`, ensure it is
///    persisted (the create flow now persists immediately to survive an app
///    kill before backup; the restore flow persists here) and emit
///    `.finishChoosingWallet` upstream.
/// 4. If the child cancels, dismiss it and remain on step 1.
public final class ChooseWalletCoordinator: BaseCoordinator<ChooseWalletCoordinatorNavigationStep> {
    /// Persistence facet used to save the chosen wallet to the secure store.
    /// Resolved via Factory so tests can substitute an in-memory implementation.
    /// (Used only on the restore branch — the create flow persists immediately
    /// inside `CreateNewWalletCoordinator` to survive an app kill before
    /// backup confirmation.)
    @Injected(\.walletStorageUseCase) private var walletStorageUseCase: WalletStorageUseCase

    /// Entry point invoked by the parent coordinator. Kicks off the flow at step 1.
    /// - Parameter didStart: Optional completion (unused here; satisfies the base-class API).
    public override func start(didStart _: Completion? = nil) {
        toChooseWallet()
    }
}

// MARK: Private

private extension ChooseWalletCoordinator {
    /// Step 1 — push the "create or restore?" scene and dispatch on the user's choice.
    ///
    /// Uses `[weak self]` so a late navigation pulse arriving after the
    /// coordinator has been torn down (e.g. parent finished the flow first)
    /// is silently dropped instead of crashing.
    func toChooseWallet() {
        let viewModel = ChooseWalletViewModel()

        push(scene: ChooseWallet.self, viewModel: viewModel) { [weak self] userIntendsTo in
            switch userIntendsTo {
            case .createNewWallet: self?.toCreateNewWallet()
            case .restoreWallet: self?.toRestoreWallet()
            }
        }
    }

    /// Step 2a — present the create-wallet sub-flow modally.
    ///
    /// `dismissFlow(true)` is invoked unconditionally via `defer` so the modal is torn
    /// down whether the user finished or cancelled. Only on the `.create` branch do we
    /// then push the `Wallet` through `finishChoosing(wallet:persistFirst:)`. The
    /// wallet is *already* persisted by `CreateNewWalletCoordinator` immediately
    /// after creation (so an app kill before backup doesn't lose the random
    /// private key), so we skip the redundant save here — passing
    /// `persistFirst: false` keeps the call symmetric with the restore branch
    /// without double-writing the Keychain.
    func toCreateNewWallet() {
        presentModalCoordinator(
            makeCoordinator: { CreateNewWalletCoordinator(navigationController: $0) },
            navigationHandler: { [weak self] userDid, dismissFlow in
                defer { dismissFlow(true) }
                switch userDid {
                case let .create(wallet):
                    self?.finishChoosing(wallet: wallet, persistFirst: false)
                case .cancel: break
                }
            }
        )
    }

    /// Step 2b — present the restore-wallet sub-flow modally.
    ///
    /// Mirrors `toCreateNewWallet()`: the modal is dismissed unconditionally
    /// via `defer`, and only a successful `.finishedRestoring` branch
    /// advances the parent flow. Restore must persist here — the restore
    /// flow doesn't write the wallet itself.
    func toRestoreWallet() {
        presentModalCoordinator(
            makeCoordinator: { RestoreWalletCoordinator(navigationController: $0) },
            navigationHandler: { [weak self] userDid, dismissFlow in
                defer { dismissFlow(true) }
                switch userDid {
                case let .finishedRestoring(wallet):
                    self?.finishChoosing(wallet: wallet, persistFirst: true)
                case .cancel: break
                }
            }
        )
    }

    /// Step 3 — terminal action shared by both create and restore branches.
    ///
    /// Order matters: persistence (when needed) MUST happen before
    /// `.finishChoosingWallet` is emitted, or the next coordinator could
    /// observe a state where the wallet "exists" in flow but not on disk.
    /// - Parameters:
    ///   - wallet: The wallet the user produced.
    ///   - persistFirst: `true` for restore (we own the save), `false` for
    ///     create (the create coordinator already persisted on derivation).
    func finishChoosing(wallet: Wallet, persistFirst: Bool) {
        if persistFirst {
            walletStorageUseCase.save(wallet: wallet)
        }
        navigator.next(.finishChoosingWallet)
    }
}
