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
import Validation
import Zesame

/// Outcomes of the decrypt-to-reveal screen.
public enum DecryptKeystoreToRevealKeyPairUserAction: Sendable {
    /// User tapped the right "Done" bar-button — abort.
    case dismiss
    /// User entered a valid password and the use case successfully derived the `KeyPair`.
    case decryptKeystoreReavealing(keyPair: KeyPair)
}

/// View model for the password-gate that decrypts the keystore.
///
/// The actual scrypt/PBKDF2 work happens in `ExtractKeyPairUseCase` — this
/// view-model just orchestrates validation, activity tracking, and error handling.
public final class DecryptKeystoreToRevealKeyPairViewModel: BaseViewModel<
    DecryptKeystoreToRevealKeyPairUserAction,
    DecryptKeystoreToRevealKeyPairViewModel.InputFromView,
    DecryptKeystoreToRevealKeyPairViewModel.Publishers
> {
    /// Use case that performs the (CPU-intensive) keystore decryption.
    @Injected(\.extractKeyPairUseCase) private var extractKeyPairUseCase: ExtractKeyPairUseCase

    /// Reactive wallet stream supplied by the coordinator.
    private let wallet: AnyPublisher<Wallet, Never>

    /// Captures the wallet source.
    init(wallet: AnyPublisher<Wallet, Never>) {
        self.wallet = wallet
    }

    /// Wires validation, decryption, and lifecycle. Detail in inline comments below.
    override public func transform(input: Input) -> Output<Publishers, NavigationStep> {
        func userDid(_ step: NavigationStep) {
            navigator.next(step)
        }

        // Spinner + error tracker shared with the use-case call below so the
        // floating-label field flips to red on `incorrectPassword` and the
        // CTA shows a spinner during the (slow) scrypt decryption.
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()

        // MARK: - Validate input

        let validator = InputValidator()

        // Re-validate the password against the *current* wallet on every
        // keystroke. withLatestFrom samples wallet so we don't need to
        // re-evaluate the whole pipeline on wallet changes (there shouldn't be any).
        let encryptionPasswordValidationValue = input.fromView.encryptionPassword
            .withLatestFrom(wallet) { (password: $0, wallet: $1) }
            .map { validator.validateEncryptionPassword($0.password, for: $0.wallet) }
            .eraseToAnyPublisher()

        // Strip down to just the validated password string for use-case consumption.
        let encryptionPassword = encryptionPasswordValidationValue.map { $0.value?.validPassword }.filterNil()

        [
            input.fromController.rightBarButtonTrigger
                .sink { userDid(.dismiss) },

            input.fromView.revealTrigger
                .withLatestFrom(
                    wallet.combineLatest(encryptionPassword).eraseToAnyPublisher()
                ) { (_: Void, pair: (Wallet, String)) -> (wallet: Wallet, password: String) in
                    (wallet: pair.0, password: pair.1)
                }
                // flatMapLatest (not flatMap) so a second tap while the first
                // decryption is still running cancels the in-flight call —
                // the user expects only the most recent attempt to surface.
                .flatMapLatest { [weak self] input -> AnyPublisher<KeyPair, Never> in
                    guard let self else { return Empty().eraseToAnyPublisher() }
                    return extractKeyPairUseCase.extractKeyPairFrom(wallet: input.wallet, encryptedBy: input.password)
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker)
                        .replaceErrorWithEmpty()
                        .eraseToAnyPublisher()
                }
                .sink { userDid(.decryptKeystoreReavealing(keyPair: $0)) },
        ].forEach { $0.store(in: &cancellables) }

        // map `editingChanged` to `editingDidBegin`
        let encryptionPasswordEditingTrigger = input.fromView.encryptionPassword.mapToVoid().map { true }
            .merge(with: input.fromView.isEditingEncryptionPassword)
            .eraseToAnyPublisher()

        // The eager-valid/lazy-error pulse: red error only after the user
        // stops typing, but `incorrectPassword` (from the use-case via the
        // errorTracker) shows immediately because it's a server-side verdict
        // the user can't fix by typing more.
        let encryptionPasswordValidation = encryptionPasswordEditingTrigger
            .withLatestFrom(encryptionPasswordValidationValue) {
                EditingValidation(isEditing: $0, validation: $1.validation)
            }
            .eagerValidLazyErrorTurnedToEmptyOnEdit(
                directlyDisplayErrorsTrackedBy: errorTracker
            ) {
                WalletEncryptionPassword.Error.incorrectPasswordErrorFrom(error: $0, backingUpWalletJustCreated: true)
            }

        return Output(
            publishers: Publishers(
                encryptionPasswordValidation: encryptionPasswordValidation,
                isRevealButtonEnabled: encryptionPasswordValidationValue.map(\.isValid).eraseToAnyPublisher(),
                isRevealButtonLoading: activityIndicator.asPublisher()
            ),
            navigation: navigator.navigation
        )
    }
}

public extension DecryptKeystoreToRevealKeyPairViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Latest password text.
        let encryptionPassword: AnyPublisher<String, Never>
        /// `true` while the password field is the first responder.
        let isEditingEncryptionPassword: AnyPublisher<Bool, Never>
        /// Fires when the user taps "Reveal".
        let revealTrigger: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Publishers {
        /// Drives `encryptionPasswordField.validationBinder`.
        let encryptionPasswordValidation: AnyPublisher<AnyValidation, Never>
        /// Drives the reveal button's enabled state.
        let isRevealButtonEnabled: AnyPublisher<Bool, Never>
        /// Drives the reveal button's loading spinner during decryption.
        let isRevealButtonLoading: AnyPublisher<Bool, Never>
    }

    /// Validator that picks the right password-policy mode for the wallet
    /// (different rule sets for new wallets vs unlock).
    internal struct InputValidator {
        /// Runs the password through `EncryptionPasswordValidator` configured
        /// with the wallet's policy mode. Same string for both `password` and
        /// `confirmingPassword` because there's only one field on this screen.
        func validateEncryptionPassword(_ password: String, for wallet: Wallet) -> EncryptionPasswordValidator
            .ValidationResult
        {
            let validator = EncryptionPasswordValidator(mode: WalletEncryptionPassword.modeFrom(wallet: wallet))
            return validator.validate(input: (password: password, confirmingPassword: password))
        }
    }
}
