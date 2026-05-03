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
import NanoViewControllerCombine
import NanoViewControllerCore
import NanoViewControllerNavigation
import UIKit
import Zesame

/// Outcomes the decrypt-keystore sub-flow surfaces to its parent.
public enum DecryptKeystoreCoordinatorNavigationStep: Sendable {
    /// User entered the password and finished viewing the revealed key pair.
    case backingUpKeyPair
    /// User dismissed without revealing.
    case dismiss
}

/// Coordinator owning the password-gated reveal of a wallet's private key + address.
///
/// Two-step flow:
/// 1. `DecryptKeystoreToRevealKeyPair` — re-enter password, derive `KeyPair`.
/// 2. `BackUpRevealedKeyPair` — display the revealed key pair (with copy/QR options).
///
/// Like `BackupWalletCoordinator`, the wallet source is either an injected
/// override (post-create) or a fallback to `WalletStorageUseCase` (Settings).
public final class DecryptKeystoreCoordinator: BaseCoordinator<DecryptKeystoreCoordinatorNavigationStep> {
    /// Used as a fallback when `walletOverride` is nil (Settings entry point).
    @Injected(\.walletStorageUseCase) private var walletStorageUseCase: WalletStorageUseCase

    /// Optional wallet publisher — overrides the storage lookup when supplied.
    private let walletOverride: AnyPublisher<Wallet, Never>?

    /// Resolved wallet stream (override or storage fallback). If neither is
    /// available — e.g. a race where the wallet was removed under us while
    /// this coordinator was being presented — the publisher simply doesn't
    /// emit; downstream `.flatMap`s wait for a wallet that never arrives, and
    /// the user can dismiss out of the modal cleanly. The previous
    /// `incorrectImplementation` trap was reachable on race conditions and
    /// crashed the app on a sensitive (private-key reveal) screen.
    private lazy var wallet: AnyPublisher<Wallet, Never> = walletOverride
        ?? walletStorageUseCase.wallet
        .compactMap { $0 }
        .replaceErrorWithEmpty()
        .eraseToAnyPublisher()

    /// Captures the wallet source.
    init(navigationController: UINavigationController, wallet: AnyPublisher<Wallet, Never>? = nil) {
        walletOverride = wallet
        super.init(navigationController: navigationController)
    }

    /// Begins at the password entry / decrypt screen.
    override public func start(didStart _: Completion? = nil) {
        toDecryptKeystore()
    }
}

// MARK: Private

private extension DecryptKeystoreCoordinator {
    /// Step 1 — password entry. On success, hands the derived `KeyPair` to
    /// the reveal screen.
    func toDecryptKeystore() {
        let viewModel = DecryptKeystoreToRevealKeyPairViewModel(wallet: wallet)

        push(scene: DecryptKeystoreToRevealKeyPair.self, viewModel: viewModel) { [weak self] userDid in
            switch userDid {
            case .dismiss: self?.dismiss()
            case let .decryptKeystoreReavealing(keyPair): self?.toBackUpRevealed(keyPair: keyPair)
            }
        }
    }

    /// Step 2 — display the revealed key pair. `.finish` advances to the parent.
    func toBackUpRevealed(keyPair: KeyPair) {
        let viewModel = BackUpRevealedKeyPairViewModel(keyPair: keyPair)

        push(scene: BackUpRevealedKeyPair.self, viewModel: viewModel) { [weak self] userDid in
            switch userDid {
            case .finish: self?.finish()
            }
        }
    }

    /// Bubble `.dismiss` to the parent so it can dismiss the modal.
    func dismiss() {
        navigator.next(.dismiss)
    }

    /// Bubble `.backingUpKeyPair` — user has finished the reveal flow.
    func finish() {
        let userFinished: NavigationStep = .backingUpKeyPair
        navigator.next(userFinished)
    }
}
