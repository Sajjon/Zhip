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
import SingleLineControllerCombine
import Zesame
import Validation

/// Strict password mode — restoring from a raw private key means we're picking
/// a *new* keystore password, so we enforce the new-wallet minimum length.
private let encryptionPasswordMode = WalletEncryptionPassword.Mode.newOrRestorePrivateKey

// MARK: - RestoreWalletUsingPrivateKeyViewModel

/// Reactive view-model for the private-key-restore sub-view. Not a
/// `BaseViewModel` — exposes its `Output` directly so the parent can re-export it.
final class RestoreWalletUsingPrivateKeyViewModel {
    /// Reactive bindings the embedding view installs.
    let output: Output

    /// Wires private key + new password + confirmation publishers into
    /// validation streams + a `KeyRestoration?` payload + show/hide-toggle state.
    init(inputFromView: InputFromView) {
        let validator = InputValidator()

        let privateKeyValidationValue = inputFromView.privateKey.map { validator.validatePrivateKey($0) }
            .eraseToAnyPublisher()

        let unconfirmedPassword = inputFromView.newEncryptionPassword
        let confirmingPassword = inputFromView.confirmEncryptionPassword

        let confirmEncryptionPasswordValidationValue: AnyPublisher<
            EncryptionPasswordValidator.ValidationResult,
            Never
        > =
            unconfirmedPassword.combineLatest(confirmingPassword)
                .map {
                    validator.validateConfirmedEncryptionPassword($0.0, confirmedBy: $0.1)
                }.eraseToAnyPublisher()

        let encryptionPasswordPlaceHolder = Just(String(localized: .RestoreWallet
                .privateKeyEncryptionPasswordField(minLength: WalletEncryptionPassword
                    .minimumLength(mode: encryptionPasswordMode))))
            .eraseToAnyPublisher()

        let privateKeyFieldIsSecureTextEntry: AnyPublisher<Bool, Never> = inputFromView.showPrivateKeyTrigger
            .scan(true) { lastState, _ in
                !lastState
            }.eraseToAnyPublisher()

        let togglePrivateKeyVisibilityButtonTitle: AnyPublisher<String, Never> = privateKeyFieldIsSecureTextEntry.map {
            $0 ? String(localized: .Generic.show) : String(localized: .Generic.hide)
        }.eraseToAnyPublisher()

        let encryptionPasswordValidationTrigger: AnyPublisher<Bool, Never> = unconfirmedPassword.mapToVoid()
            .map { true }
            .merge(with: inputFromView.isEditingNewEncryptionPassword)
            .eraseToAnyPublisher()

        let encryptionPasswordValidation: AnyPublisher<AnyValidation, Never> = encryptionPasswordValidationTrigger
            .withLatestFrom(
                unconfirmedPassword.map { validator.validateNewEncryptionPassword($0) }.eraseToAnyPublisher()
            ) {
                EditingValidation(isEditing: $0, validation: $1.validation)
            }.eagerValidLazyErrorTurnedToEmptyOnEdit()

        // map `editingChanged` to `editingDidBegin`
        let confirmEditingTrigger = confirmingPassword.mapToVoid().map { true }
            .merge(with: inputFromView.isEditingConfirmedEncryptionPassword)
            .eraseToAnyPublisher()

        // encryptionPasswordValidationTrigger used solely to trigger re-evaluation; value discarded
        let confirmEncryptionPasswordValidation: AnyPublisher<AnyValidation, Never> = confirmEditingTrigger
            .combineLatest(encryptionPasswordValidationTrigger)
            .withLatestFrom(confirmEncryptionPasswordValidationValue) {
                EditingValidation(isEditing: $0.0, validation: $1.validation)
            }.eagerValidLazyErrorTurnedToEmptyOnEdit()

        let keyRestoration: AnyPublisher<KeyRestoration?, Never> = privateKeyValidationValue.map(\.value)
            .combineLatest(confirmEncryptionPasswordValidationValue.map(\.value))
            .map {
                guard let privateKey = $0.0, let newEncryptionPassword = $0.1?.validPassword else {
                    return nil
                }
                return KeyRestoration.privateKey(privateKey, encryptBy: newEncryptionPassword, kdf: .default)
            }.eraseToAnyPublisher()

        let privateKeyValidation: AnyPublisher<AnyValidation, Never> = inputFromView.isEditingPrivateKey
            .withLatestFrom(privateKeyValidationValue) {
                EditingValidation(isEditing: $0, validation: $1.validation)
            }.eagerValidLazyErrorTurnedToEmptyOnEdit()

        output = Output(
            togglePrivateKeyVisibilityButtonTitle: togglePrivateKeyVisibilityButtonTitle,
            privateKeyFieldIsSecureTextEntry: privateKeyFieldIsSecureTextEntry,
            privateKeyValidation: privateKeyValidation,
            encryptionPasswordPlaceholder: encryptionPasswordPlaceHolder,
            encryptionPasswordValidation: encryptionPasswordValidation,
            confirmEncryptionPasswordValidation: confirmEncryptionPasswordValidation,
            keyRestoration: keyRestoration
        )
    }
}

extension RestoreWalletUsingPrivateKeyViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Current private-key text.
        let privateKey: AnyPublisher<String, Never>
        /// `true` while the private-key field is the first responder.
        let isEditingPrivateKey: AnyPublisher<Bool, Never>
        /// Fires when the user taps the show/hide button.
        let showPrivateKeyTrigger: AnyPublisher<Void, Never>
        /// Current new-password text.
        let newEncryptionPassword: AnyPublisher<String, Never>
        /// `true` while the new-password field is the first responder.
        let isEditingNewEncryptionPassword: AnyPublisher<Bool, Never>
        /// Current confirm-password text.
        let confirmEncryptionPassword: AnyPublisher<String, Never>
        /// `true` while the confirm-password field is the first responder.
        let isEditingConfirmedEncryptionPassword: AnyPublisher<Bool, Never>
    }

    /// Reactive bindings the embedding view installs.
    struct Output {
        /// "Show"/"Hide" string for the toggle button — derived from secure-entry state.
        let togglePrivateKeyVisibilityButtonTitle: AnyPublisher<String, Never>
        /// Drives `privateKeyField.isSecureTextEntryBinder` — flips on each show-button tap.
        let privateKeyFieldIsSecureTextEntry: AnyPublisher<Bool, Never>
        /// Drives `privateKeyField.validationBinder`.
        let privateKeyValidation: AnyPublisher<AnyValidation, Never>
        /// Drives the new-password placeholder (includes the min-length hint).
        let encryptionPasswordPlaceholder: AnyPublisher<String, Never>
        /// Drives `encryptionPasswordField.validationBinder`.
        let encryptionPasswordValidation: AnyPublisher<AnyValidation, Never>
        /// Drives `confirmEncryptionPasswordField.validationBinder`.
        let confirmEncryptionPasswordValidation: AnyPublisher<AnyValidation, Never>
        /// `KeyRestoration.privateKey(...)` payload, or `nil` while any field is invalid.
        /// Re-exported by the parent screen for the restore CTA.
        let keyRestoration: AnyPublisher<KeyRestoration?, Never>
    }

    /// Composes a `PrivateKeyValidator` with `EncryptionPasswordValidator`
    /// instances configured for the strict new-wallet password policy.
    struct InputValidator {
        private let privateKeyValidator = PrivateKeyValidator()

        /// Validates the hex-encoded private key string.
        func validatePrivateKey(_ privateKey: String?) -> PrivateKeyValidator.ValidationResult {
            privateKeyValidator.validate(input: privateKey)
        }

        /// Validates only the password (without confirmation) — used to surface
        /// length errors as soon as the user types in the new-password field,
        /// before they touch the confirmation field.
        func validateNewEncryptionPassword(_ password: String) -> EncryptionPasswordValidator.ValidationResult {
            let validator = EncryptionPasswordValidator(mode: encryptionPasswordMode)
            return validator.validate(input: (password, password))
        }

        /// Cross-field check that both password and confirmation match (and pass
        /// the length rule). Used to gate the restore CTA.
        func validateConfirmedEncryptionPassword(
            _ password: String,
            confirmedBy confirming: String
        ) -> EncryptionPasswordValidator.ValidationResult {
            let validator = EncryptionPasswordValidator(mode: encryptionPasswordMode)
            return validator.validate(input: (password, confirming))
        }
    }
}
