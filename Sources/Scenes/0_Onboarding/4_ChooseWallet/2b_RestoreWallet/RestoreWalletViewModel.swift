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
import SingleLineControllerCombine
import SingleLineControllerCore
import Zesame
import Validation

/// Navigation from RestoreWallet
enum RestoreWalletNavigation {
    /// User entered valid restore material + password and the use case
    /// successfully decrypted/derived the `Wallet`.
    case restoreWallet(Wallet)
}

// MARK: - RestoreWalletViewModel

/// View model for the wallet-restore screen. Switches between two restore
/// sub-modes (keystore JSON vs raw private key) based on the segmented control,
/// dispatches the resulting `KeyRestoration` payload to `RestoreWalletUseCase`,
/// and surfaces validation errors back to the UI via the `keystoreRestorationError`
/// publisher.
final class RestoreWalletViewModel: BaseViewModel<
    RestoreWalletNavigation,
    RestoreWalletViewModel.InputFromView,
    RestoreWalletViewModel.Output
> {
    /// Use case that decrypts the keystore or derives a wallet from a private key.
    @Injected(\.restoreWalletUseCase) private var restoreWalletUseCase: RestoreWalletUseCase

    /// Wires segment-driven payload selection, restore-button gating, and
    /// the (cancellable) restore use-case call. Detail in inline comments.
    override func transform(input: Input) -> Output {
        func userIntends(to intention: NavigationStep) {
            navigator.next(intention)
        }

        // Spinner shared between the in-flight use-case call and the CTA.
        let activityIndicator = ActivityIndicator()

        // Picks the active sub-view's payload stream based on the current segment.
        // flatMapLatest cancels the previous subscription on segment-change so
        // we don't keep listening to the hidden sub-view.
        let keyRestoration: AnyPublisher<KeyRestoration?, Never> = input.fromView.selectedSegment.flatMapLatest {
            switch $0 {
            case .keystore: input.fromView.keyRestorationUsingKeystore
            case .privateKey: input.fromView.keyRestorationUsingPrivateKey
            }
        }
        .eraseToAnyPublisher()

        // Localized header text follows the selected segment.
        let headerLabel: AnyPublisher<String, Never> = input.fromView.selectedSegment.map {
            switch $0 {
            case .keystore: String(localized: .RestoreWallet.restoreWithKeystore)
            case .privateKey: String(localized: .RestoreWallet.restoreWithPrivateKey)
            }
        }.eraseToAnyPublisher()

        // Captures errors from the use-case so the view can render them as
        // a typed `AnyValidation` (wrong-password / bad-format) on the keystore field.
        let errorTracker = ErrorTracker()

        [
            input.fromView.restoreTrigger.withLatestFrom(keyRestoration.filterNil()) { $1 }
                // flatMapLatest cancels any in-flight restore when the user taps again —
                // useful if scrypt is mid-decryption with the wrong password.
                .flatMapLatest { [weak self] restoration -> AnyPublisher<Wallet, Never> in
                    guard let self else { return Empty().eraseToAnyPublisher() }
                    return restoreWalletUseCase.restoreWallet(from: restoration)
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker)
                        .replaceErrorWithEmpty()
                        .eraseToAnyPublisher()
                }
                .sink { userIntends(to: .restoreWallet($0)) },
        ].forEach { $0.store(in: &cancellables) }

        // Funnel any tracked use-case error through the keystore-error mapper
        // so the view can flip the keystore field red and force-redirect the
        // segment. Sources the projection from `ErrorTracker.compactMap`
        // (the public hook in the SingleLineControllerCore package); the
        // legacy `asInputValidationErrors` shim was retired in the same move.
        let keystoreRestorationError: AnyPublisher<AnyValidation, Never> = errorTracker
            .compactMap { KeystoreValidator.Error(error: $0) }
            .map { AnyValidation.errorMessage($0.errorMessage) }
            .eraseToAnyPublisher()

        return Output(
            headerLabel: headerLabel,
            // Restore CTA enabled iff the active sub-view has produced a non-nil payload.
            isRestoreButtonEnabled: keyRestoration.map { $0 != nil }.eraseToAnyPublisher(),
            isRestoring: activityIndicator.asPublisher(),
            keystoreRestorationError: keystoreRestorationError
        )
    }
}

extension RestoreWalletViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Which restore method is selected.
        enum Segment: Int {
            /// Private-key restore (default).
            case privateKey
            /// Keystore JSON + password restore.
            case keystore
        }

        /// Which segment is currently active.
        let selectedSegment: AnyPublisher<Segment, Never>
        /// Payload stream from the private-key sub-view (`nil` while invalid).
        let keyRestorationUsingPrivateKey: AnyPublisher<KeyRestoration?, Never>
        /// Payload stream from the keystore sub-view (`nil` while invalid).
        let keyRestorationUsingKeystore: AnyPublisher<KeyRestoration?, Never>
        /// Fires when the user taps the restore CTA.
        let restoreTrigger: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Drives `headerLabel.textBinder` based on the selected segment.
        let headerLabel: AnyPublisher<String, Never>
        /// Drives `restoreWalletButton.isEnabledBinder`.
        let isRestoreButtonEnabled: AnyPublisher<Bool, Never>
        /// Drives `restoreWalletButton.isLoadingBinder` during decryption.
        let isRestoring: AnyPublisher<Bool, Never>
        /// Drives the composite keystore-error binder (red field + segment redirect).
        let keystoreRestorationError: AnyPublisher<AnyValidation, Never>
    }
}
