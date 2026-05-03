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

import NanoViewControllerNavigation
import UIKit
 import Zesame

/// Outcomes the restore-wallet sub-flow surfaces to its parent
/// (`ChooseWalletCoordinator`).
public enum RestoreWalletCoordinatorNavigationStep: @unchecked Sendable {
    /// User entered valid restore material (keystore or private key) + password
    /// and the use case successfully decrypted/derived the `Wallet`.
    case finishedRestoring(wallet: Wallet)
    /// User cancelled.
    case cancel
}

/// Coordinator owning the linear "restore wallet" sub-flow:
///
/// 1. `EnsureThatYouAreNotBeingWatched` — privacy gate.
/// 2. `RestoreWallet` — segmented chooser between keystore vs private-key restore,
///    each with its own embedded sub-view.
///
/// Cancel at the privacy gate aborts; `finishedRestoring` only fires once
/// the restore use case successfully resolves a wallet.
public final class RestoreWalletCoordinator: BaseCoordinator<RestoreWalletCoordinatorNavigationStep> {
    /// Begins at the privacy gate.
    override public func start(didStart _: Completion? = nil) {
        toEnsureThatYouAreNotBeingWatched()
    }
}

// MARK: - Private

private extension RestoreWalletCoordinator {
    /// Step 1 — privacy gate. `.understand` advances; `.cancel` aborts.
    func toEnsureThatYouAreNotBeingWatched() {
        let viewModel = EnsureThatYouAreNotBeingWatchedViewModel()
        push(scene: EnsureThatYouAreNotBeingWatched.self, viewModel: viewModel) { [weak self] userDid in
            switch userDid {
            case .understand: self?.toRestoreWallet()
            case .cancel: self?.cancel()
            }
        }
    }

    /// Step 2 — restore screen with segmented control. Forwards the resolved
    /// `Wallet` to the parent.
    func toRestoreWallet() {
        let viewModel = RestoreWalletViewModel()

        push(scene: RestoreWallet.self, viewModel: viewModel) { [weak self] userIntendsTo in
            switch userIntendsTo {
            case let .restoreWallet(wallet): self?.finishedRestoring(wallet: wallet)
            }
        }
    }

    /// Bubble the freshly-restored wallet up to the parent for persistence.
    func finishedRestoring(wallet: Wallet) {
        navigator.next(.finishedRestoring(wallet: wallet))
    }

    /// Bubble `.cancel` to the parent.
    func cancel() {
        navigator.next(.cancel)
    }
}
