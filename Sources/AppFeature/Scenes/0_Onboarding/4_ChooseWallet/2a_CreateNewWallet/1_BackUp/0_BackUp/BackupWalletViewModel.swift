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
import NanoViewControllerCombine
import NanoViewControllerController
import NanoViewControllerCore
import NanoViewControllerDIPrimitives
import UIKit
import Zesame

// MARK: - BackupWalletUserAction

/// Outcomes the backup hub surfaces to its parent coordinator.
public enum BackupWalletUserAction: Sendable {
    /// User dismissed (Settings mode) or cancelled (post-create mode).
    case cancelOrDismiss
    /// User confirmed they have backed up the wallet (only post-create).
    case backupWallet
    /// User tapped "Reveal private key" — coordinator presents the password gate.
    case revealPrivateKey
    /// User tapped "Reveal keystore" — coordinator presents the keystore modal.
    case revealKeystore
}

// MARK: - BackupWalletViewModel

/// View model for the backup hub. Drives two presentation contexts:
/// - `.cancellable` (post-create): cancel-X bar button + done CTA + checkbox.
/// - `.dismissable` (Settings revisit): done bar button + no CTA / checkbox.
public final class BackupWalletViewModel: BaseViewModel<
    BackupWalletUserAction,
    BackupWalletViewModel.InputFromView,
    BackupWalletViewModel.Output
> {
    /// System pasteboard wrapper — injected so tests can record copies.
    @Injected(\.pasteboard) private var pasteboard: Pasteboard

    /// Reactive wallet stream supplied by the coordinator.
    private let wallet: AnyPublisher<Wallet, Never>

    /// Whether the screen is being shown post-create (cancellable + done CTA)
    /// or as a Settings revisit (dismissable, no CTA).
    enum Mode: Int, Equatable {
        /// Settings revisit — done bar-button only.
        case dismissable
        /// Post-create — cancel-X bar-button + checkbox-gated done CTA.
        case cancellable
    }

    /// Captured presentation mode.
    private let mode: Mode

    /// Captures the wallet source + mode.
    init(wallet: AnyPublisher<Wallet, Never>, mode: Mode = .cancellable) {
        self.wallet = wallet
        self.mode = mode
    }

    /// Wires:
    /// - Mode-dependent bar button (done vs cancel).
    /// - Copy-keystore tap → pasteboard + toast.
    /// - Reveal taps → matching navigation steps.
    /// - Done tap *gated* on the "I've backed up" checkbox via `withLatestFrom`.
    override public func transform(input: Input) -> Output {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        let isUnderstandsRiskCheckboxChecked = input.fromView.isUnderstandsRiskCheckboxChecked

        // Bar-button setup depends on mode — Settings shows a "Done" button on
        // the right; post-create shows a cancel "X" on the left.
        switch mode {
        case .dismissable: input.fromController.rightBarButtonContentSubject.onBarButton(.done)
            input.fromController.rightBarButtonTrigger
                .sink { userDid(.cancelOrDismiss) }.store(in: &cancellables)
        case .cancellable:
            input.fromController.leftBarButtonContentSubject.onBarButton(.cancel)
            input.fromController.leftBarButtonTrigger
                .sink { userDid(.cancelOrDismiss) }.store(in: &cancellables)
        }

        [
            // Copy-keystore: pull the *current* wallet's JSON via withLatestFrom
            // so the value is fresh at click-time (not at subscribe-time).
            // The keystore is encrypted with the user's password but we still
            // cap its pasteboard residency at 60s so it doesn't sit
            // indefinitely (Universal Clipboard sync, clipboard managers, …).
            input.fromView.copyKeystoreToPasteboardTrigger.withLatestFrom(wallet.map(\.keystoreAsJSON)) { $1 }
                .sink { [pasteboard] (keystoreText: String) in
                    // pasteboard.copy is @MainActor (wraps UIPasteboard) — the
                    // Combine sink closure is @Sendable so we hop explicitly.
                    // Combine delivers values on the main runloop in
                    // SceneController so the assumption holds.
                    mainActorOnly {
                        pasteboard.copy(keystoreText, expiringAfter: SensitivePasteboard.expirationSeconds)
                        input.fromController.toastSubject.send(Toast(String(localized: .BackupWallet.copiedKeystore)))
                    }
                },

            input.fromView.revealKeystoreTrigger
                .sink { userDid(.revealKeystore) },

            input.fromView.revealPrivateKeyTrigger
                .sink { userDid(.revealPrivateKey) },

            // Done-tap guarded by the "I have backed up" checkbox: tap fires,
            // we sample the latest checkbox state, drop the event if false.
            input.fromView.doneTrigger.withLatestFrom(isUnderstandsRiskCheckboxChecked)
                .filter { $0 }.mapToVoid()
                .sink { userDid(.backupWallet) },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            // Confirm group only visible post-create — Settings hides it.
            isHaveSecurelyBackedUpViewsVisible: AnyPublisher<Mode, Never>.just(mode).map { $0 == .cancellable }
                .eraseToAnyPublisher(),
            isDoneButtonEnabled: isUnderstandsRiskCheckboxChecked
        )
    }
}

public extension BackupWalletViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires when the user taps "Copy keystore" — view-model handles pasteboard + toast.
        let copyKeystoreToPasteboardTrigger: AnyPublisher<Void, Never>
        /// Fires when the user taps "Reveal keystore" — coordinator presents modal.
        let revealKeystoreTrigger: AnyPublisher<Void, Never>
        /// Fires when the user taps "Reveal private key" — coordinator presents password gate.
        let revealPrivateKeyTrigger: AnyPublisher<Void, Never>
        /// Latest state of the "I have backed up" checkbox — gates the done button.
        let isUnderstandsRiskCheckboxChecked: AnyPublisher<Bool, Never>
        /// Fires when the user taps the "Done" CTA.
        let doneTrigger: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Drives `haveSecurelyBackedUpViews.isVisibleBinder` (false in Settings mode).
        let isHaveSecurelyBackedUpViewsVisible: AnyPublisher<Bool, Never>
        /// Drives `doneButton.isEnabledBinder` — true once the checkbox is checked.
        let isDoneButtonEnabled: AnyPublisher<Bool, Never>
    }
}

extension Wallet {
    /// Keystore as a pretty-printed JSON string for display + clipboard copy.
    var keystoreAsJSON: String {
        keystore.asPrettyPrintedJSONString
    }
}

extension Keystore {
    /// JSON-encodes the keystore with `.prettyPrinted` formatting and decodes
    /// to UTF-8. Crashes (`incorrectImplementation`) on either failure — both
    /// indicate a bug in `Keystore`'s `Codable` conformance.
    var asPrettyPrintedJSONString: String {
        guard let keystoreJSON = try? JSONEncoder(outputFormatting: .prettyPrinted).encode(self) else {
            incorrectImplementation("should be able to JSON encode a keystore")
        }
        guard let jsonString = String(data: keystoreJSON, encoding: .utf8) else {
            incorrectImplementation("Should be able to create JSON string from Data")
        }
        return jsonString
    }
}
