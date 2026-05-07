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
import NanoViewControllerCombine
import NanoViewControllerCore
import NanoViewControllerNavigation
import UIKit
import Zesame

/// Outcomes the backup sub-flow surfaces to its parent.
public enum BackupWalletCoordinatorNavigationStep: Sendable {
    /// User confirmed they have backed up their wallet.
    case backUp
    /// User cancelled out of the backup flow (only available in `.cancellable` mode).
    case cancel
}

/// Coordinator owning the keystore/private-key backup sub-flow.
///
/// Reused in two contexts:
/// 1. Right after wallet creation — `walletOverride` carries the freshly-created
///    wallet, `mode = .cancellable` (user can back out before persistence).
/// 2. From Settings → "Back up wallet" — `walletOverride == nil` so the wallet
///    is pulled from `WalletStorageUseCase`, `mode = .mustBackup` (no cancel
///    button because the wallet is already saved).
///
/// The flow root scene (`BackupWallet`) offers two reveal options
/// (keystore / private-key + address). Each is a separate sub-flow:
/// keystore is a single modal; private-key requires re-entering the password
/// (handled by `DecryptKeystoreCoordinator`).
public final class BackupWalletCoordinator: BaseCoordinator<BackupWalletCoordinatorNavigationStep> {
    /// Used as a fallback when `walletOverride` is nil (Settings entry point).
    @Injected(\.walletStorageUseCase) private var walletStorageUseCase: WalletStorageUseCase

    /// Optional wallet publisher injected by the create-flow — overrides the
    /// `walletStorageUseCase` lookup so the freshly-created wallet doesn't need
    /// a round-trip through persistence.
    private let walletOverride: AnyPublisher<Wallet, Never>?
    /// `.cancellable` (post-create) vs `.mustBackup` (Settings entry).
    private let mode: BackupWalletViewModel.Mode

    /// Resolved wallet stream — either the override or a fallback that pulls
    /// from secure storage. Lazy so the storage lookup isn't kicked off during
    /// init. If neither is available (e.g. wallet was removed under us while
    /// Settings → Backup was open), the publisher simply doesn't emit — and
    /// the next `viewWillAppear` from `BackupWalletViewModel` cancels gracefully
    /// rather than crashing. The previous `incorrectImplementation` trap was
    /// reachable on race conditions.
    private lazy var wallet: AnyPublisher<Wallet, Never> = walletOverride
        ?? walletStorageUseCase.wallet
        .compactMap { $0 }
        .replaceErrorWithEmpty()
        .eraseToAnyPublisher()

    /// Captures the wallet source + mode. Defaulting `wallet = nil` and
    /// `mode = .cancellable` lets the create-flow pass `wallet:` and Settings
    /// pass nothing.
    init(
        navigationController: UINavigationController,
        wallet: AnyPublisher<Wallet, Never>? = nil,
        mode: BackupWalletViewModel.Mode = .cancellable
    ) {
        walletOverride = wallet
        self.mode = mode
        super.init(navigationController: navigationController)
    }

    /// Begins at the backup hub scene that fans out to the two reveal flows.
    override public func start(didStart _: Completion? = nil) {
        toBackUpWallet()
    }
}

// MARK: Private

private extension BackupWalletCoordinator {
    /// Hub scene with two CTAs (reveal keystore / reveal private key) plus
    /// confirm + cancel. Each user action dispatches to a sub-flow or finishes.
    func toBackUpWallet() {
        let viewModel = BackupWalletViewModel(wallet: wallet, mode: mode)

        push(scene: BackupWallet.self, viewModel: viewModel) { [weak self] userDid in
            guard let self else { return }
            switch userDid {
            case .revealKeystore: toRevealKeystore()
            case .revealPrivateKey: toDecryptKeystoreToRevealKeyPair()
            case .cancelOrDismiss: cancel()
            case .backupWallet: finish()
            }
        }
    }

    /// Sub-flow for revealing the private key — gated behind a password
    /// re-prompt, owned by `DecryptKeystoreCoordinator`. Both terminal cases
    /// dismiss the modal; only the parent `BackupWallet` scene records the
    /// "I have backed up" toggle.
    func toDecryptKeystoreToRevealKeyPair() {
        presentModalCoordinator(makeCoordinator: {
            DecryptKeystoreCoordinator(navigationController: $0, wallet: wallet)
        }, navigationHandler: { userFinished, dismissModalFlow in
            switch userFinished {
            case .backingUpKeyPair: dismissModalFlow(true)
            case .dismiss: dismissModalFlow(true)
            }
        })
    }

    /// Sub-flow for revealing the keystore JSON — single modal, no password gate
    /// (the keystore is already encrypted with the user's password).
    func toRevealKeystore() {
        let viewModel = BackUpKeystoreViewModel(wallet: wallet)

        modallyPresent(scene: BackUpKeystore.self, viewModel: viewModel) { userDid, dismissScene in
            switch userDid {
            case .finished: dismissScene(true, nil)
            }
        }
    }

    /// Bubble `.cancel` to the parent (only reachable in `.cancellable` mode).
    func cancel() {
        navigator.next(.cancel)
    }

    /// Bubble `.backUp` to the parent — they confirmed they've recorded the backup.
    func finish() {
        let userFinished: NavigationStep = .backUp
        navigator.next(userFinished)
    }
}
