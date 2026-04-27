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

/// Looser password mode for keystore restore — the keystore is already
/// encrypted with whatever the user picked at creation time, so we don't enforce
/// the strict new-wallet minimum length here.
private let encryptionPasswordMode: WalletEncryptionPassword.Mode = .restoreKeystore

// MARK: - RestoreWalletViewModel

/// Reactive view-model for the keystore-restore sub-view. Not a `BaseViewModel`
/// because it's not a top-level scene — instead it exposes its `Output` directly
/// so the parent (`RestoreWalletView`) can re-export it.
final class RestoreWalletUsingKeystoreViewModel {
    /// Reactive bindings the embedding view installs.
    let output: Output

    /// Wires keystore + password publishers into validation streams + a final
    /// `KeyRestoration?` payload for the parent screen.
    init(inputFromView: InputFromView) {
        // MARK: - Validate input

        let validator = InputValidator()

        let encryptionPasswordValidationValue = inputFromView.encryptionPassword
            .map { validator.validateEncryptionPassword($0) }

        let keyStoreValidationValue = inputFromView.keystoreText.map { validator.validateKeystore($0) }

        let encryptionPassword = encryptionPasswordValidationValue.map { $0.value?.validPassword }

        // map `editingChanged` to `editingDidBegin`
        let encryptionPasswordEditingTrigger = inputFromView.encryptionPassword.mapToVoid().map { true }
            .merge(with: inputFromView.isEditingEncryptionPassword)
            .eraseToAnyPublisher()

        let encryptionPasswordValidation = encryptionPasswordEditingTrigger
            .withLatestFrom(encryptionPasswordValidationValue) {
                EditingValidation(isEditing: $0, validation: $1.validation)
            }
            .eagerValidLazyErrorTurnedToEmptyOnEdit()

        let keyRestoration: AnyPublisher<KeyRestoration?, Never> = keyStoreValidationValue.map(\.value)
            .combineLatest(encryptionPassword)
            .map { keystoreOpt, passwordOpt -> KeyRestoration? in
                guard let keystore = keystoreOpt, let password = passwordOpt else {
                    return nil
                }
                return KeyRestoration.keystore(keystore, password: password)
            }.eraseToAnyPublisher()

        let encryptionPasswordPlaceHolder = Just(String(localized: .RestoreWallet
                .keystoreEncryptionPasswordField(minLength: WalletEncryptionPassword
                    .minimumLength(mode: encryptionPasswordMode))))
            .eraseToAnyPublisher()

        let keystoreValidation = inputFromView.isEditingKeystore.withLatestFrom(keyStoreValidationValue) {
            EditingValidation(isEditing: $0, validation: $1.validation)
        }.eagerValidLazyErrorTurnedToEmptyOnEdit()

        let keystoreTextFieldPlaceholder: AnyPublisher<String, Never> = inputFromView.keystoreDidBeginEditing
            .map { "" }
            .removeDuplicates() // never changed, thus only emitted once, as wished
            .prepend("Paste your keystore here")
            .eraseToAnyPublisher()

        output = Output(
            keystoreTextFieldPlaceholder: keystoreTextFieldPlaceholder,
            encryptionPasswordPlaceholder: encryptionPasswordPlaceHolder,
            keyRestorationValidation: keystoreValidation,
            encryptionPasswordValidation: encryptionPasswordValidation,
            keyRestoration: keyRestoration
        )
    }
}

extension RestoreWalletUsingKeystoreViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires the first time the keystore textview becomes the first responder
        /// (used to clear the placeholder text).
        let keystoreDidBeginEditing: AnyPublisher<Void, Never>
        /// `true` while the keystore textview is the first responder.
        let isEditingKeystore: AnyPublisher<Bool, Never>
        /// The current keystore JSON text.
        let keystoreText: AnyPublisher<String, Never>
        /// The current encryption password text.
        let encryptionPassword: AnyPublisher<String, Never>
        /// `true` while the password field is the first responder.
        let isEditingEncryptionPassword: AnyPublisher<Bool, Never>
    }

    /// Reactive bindings the embedding view installs.
    struct Output {
        /// Drives the keystore textview's placeholder text (cleared on first edit).
        let keystoreTextFieldPlaceholder: AnyPublisher<String, Never>
        /// Drives the password field's placeholder (includes the min-length hint).
        let encryptionPasswordPlaceholder: AnyPublisher<String, Never>
        /// Drives the keystore textview's border color via `validationBorderBinder`.
        let keyRestorationValidation: AnyPublisher<AnyValidation, Never>
        /// Drives the password field's `validationBinder`.
        let encryptionPasswordValidation: AnyPublisher<AnyValidation, Never>
        /// `KeyRestoration.keystore(...)` payload, or `nil` when either field is invalid.
        /// Re-exported by the parent screen for the restore CTA.
        let keyRestoration: AnyPublisher<KeyRestoration?, Never>
    }

    /// Composes a `KeystoreValidator` with an `EncryptionPasswordValidator`
    /// so the view-model can validate both fields with one type.
    struct InputValidator {
        private let encryptionPasswordValidator = EncryptionPasswordValidator(mode: encryptionPasswordMode)

        private let keystoreValidator = KeystoreValidator()

        /// Validates the pasted keystore JSON.
        func validateKeystore(_ keystore: String) -> KeystoreValidator.ValidationResult {
            keystoreValidator.validate(input: keystore)
        }

        /// Validates the password against the looser keystore-restore policy.
        /// Same string for both `password` and `confirmingPassword` since
        /// the keystore-restore screen has only one password field.
        func validateEncryptionPassword(_ password: String) -> EncryptionPasswordValidator.ValidationResult {
            encryptionPasswordValidator.validate(input: (password: password, confirmingPassword: password))
        }
    }
}
