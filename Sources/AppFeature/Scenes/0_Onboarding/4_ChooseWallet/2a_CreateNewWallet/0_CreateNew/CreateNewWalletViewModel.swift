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
import NanoViewControllerController
import NanoViewControllerCore
import Validation
import Zesame

/// The encryption-password policy used for *all* password inputs on this screen.
///
/// `.newOrRestorePrivateKey` enforces the stricter minimum length used when a brand-new
/// wallet is being created (or when a wallet is being restored from a raw private key) —
/// distinct from the looser policy used when unlocking an already-saved wallet.
private let encryptionPasswordMode: WalletEncryptionPassword.Mode = .newOrRestorePrivateKey

// MARK: - CreateNewWalletUserAction

/// The set of outcomes the user can produce on the "create new wallet" screen.
///
/// Emitted to the parent coordinator (`CreateNewWalletCoordinator`) via the
/// `BaseViewModel.navigator` stepper so the coordinator can advance or dismiss the flow.
public enum CreateNewWalletUserAction: Sendable {
    /// User confirmed a valid password and a fresh `Wallet` was successfully generated.
    /// - Parameter Wallet: The newly created wallet, ready to be persisted by the coordinator.
    case createWallet(Wallet)
    /// User tapped the left bar-button (cancel) and wants to abandon wallet creation.
    case cancel
}

// MARK: - CreateNewWalletViewModel

/// View model backing `CreateNewWalletView`.
///
/// Responsibilities:
/// 1. Validate the chosen encryption password and its confirmation in real time.
/// 2. Gate the "continue" button on (valid password) AND (user checked the "I've backed it up" box).
/// 3. On tap of "continue", invoke `CreateWalletUseCase` to derive a wallet from the password
///    and forward the result through `navigator` as a `.createWallet(_:)` step.
/// 4. Forward the left bar-button tap as `.cancel`.
public final class CreateNewWalletViewModel: BaseViewModel<
    CreateNewWalletUserAction,
    CreateNewWalletViewModel.InputFromView,
    CreateNewWalletViewModel.Output
> {
    /// Use case that performs the (CPU-intensive) keystore derivation from a plaintext password.
    /// Resolved lazily via Factory so tests can register a fast in-memory fake.
    @Injected(\.createWalletUseCase) private var createWalletUseCase: CreateWalletUseCase

    /// Wires UI inputs and controller-lifecycle inputs to the reactive `Output` consumed by the view.
    ///
    /// All side-effecting subscriptions (navigation, `createWallet` use-case invocation) are
    /// eagerly stored in `cancellables` here; pure `Output` streams are returned and bound
    /// by the view in `populate(with:)`.
    override public func transform(input: Input) -> Output {
        /// Local helper that pushes a navigation step onto the `BaseViewModel` navigator.
        /// Kept as a nested function purely for readability of the call sites below.
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        let unconfirmedPassword = input.fromView.newEncryptionPassword
        let confirmingPassword = input.fromView.confirmedNewEncryptionPassword

        let validator = InputValidator()

        // Re-runs the cross-field validation every time *either* password field changes.
        // The result carries both the validity flag and (when valid) the derived
        // `WalletEncryptionPassword` value, which we extract later to feed the use case.
        let confirmEncryptionPasswordValidationValue: AnyPublisher<
            EncryptionPasswordValidator.ValidationResult,
            Never
        > =
            unconfirmedPassword.combineLatest(confirmingPassword)
                .map { (password: String, confirmPassword: String) in
                    validator.validateConfirmedEncryptionPassword(password, confirmedBy: confirmPassword)
                }.eraseToAnyPublisher()

        // The continue button needs BOTH a passing validation AND the explicit
        // "I have backed up my password" checkbox — losing the password is unrecoverable.
        let isContinueButtonEnabled: AnyPublisher<Bool, Never> = confirmEncryptionPasswordValidationValue
            .map(\.isValid)
            .combineLatest(input.fromView.isHaveBackedUpPasswordCheckboxChecked)
            .map { $0 && $1 }
            .eraseToAnyPublisher()

        // Tracks the in-flight wallet-creation work so the button can show a spinner.
        let activityIndicator = ActivityIndicator()

        [
            // Cancel button → propagate as `.cancel` navigation step.
            input.fromController.leftBarButtonTrigger
                .sink { userDid(.cancel) },

            // Continue button:
            //   1. snapshot the latest *valid* password (may be nil → filterNil drops it),
            //   2. flatMapLatest into the createWallet use case (cancels any prior in-flight),
            //   3. track activity for the spinner,
            //   4. swallow errors (UI surfaces them via toast elsewhere; we don't want
            //      a single failure to terminate the upstream tap pipeline),
            //   5. emit the resulting wallet as `.createWallet(_:)` to the coordinator.
            input.fromView.createWalletTrigger
                .withLatestFrom(confirmEncryptionPasswordValidationValue.map { $0.value?.validPassword }.filterNil()) {
                    $1
                }
                .flatMapLatest {
                    self.createWalletUseCase.createNewWallet(encryptionPassword: $0)
                        .trackActivity(activityIndicator)
                        .replaceErrorWithEmpty()
                }
                .sink { userDid(.createWallet($0)) },
        ].forEach { $0.store(in: &cancellables) }

        // We want to *show* the validation error message only after the user has either
        // typed something OR finished editing the field — never on the very first render
        // when the field is still pristine. Merging text-changes (`mapToVoid().map { true }`)
        // with the focus-change publisher gives us "the user has interacted with this field".
        let encryptionPasswordValidationTrigger = unconfirmedPassword.mapToVoid().map { true }
            .merge(with: input.fromView.isEditingNewEncryptionPassword).eraseToAnyPublisher()

        // Build the password-field validation:
        //   - trigger fires on each interaction,
        //   - withLatestFrom snapshots the current validator output,
        //   - `eagerValidLazyErrorTurnedToEmptyOnEdit` is the project-wide rule:
        //     show "valid" the moment it becomes valid, but suppress error states
        //     while the user is still actively editing (avoids angry red flashes
        //     mid-typing).
        let encryptionPasswordValidation: AnyPublisher<AnyValidation, Never> = encryptionPasswordValidationTrigger
            .withLatestFrom(
                unconfirmedPassword.map { validator.validateNewEncryptionPassword($0) }
            ) {
                EditingValidation(isEditing: $0, validation: $1.validation)
            }.eagerValidLazyErrorTurnedToEmptyOnEdit()

        // Same "user has interacted" trigger, but for the *confirm* field.
        // Comment kept for historical clarity: text-changes need to be lifted to
        // a `Bool=true` (treated as `editingDidBegin`) so they merge cleanly with
        // the actual focus-change boolean publisher.
        // map `editingChanged` to `editingDidBegin`
        let confirmEditingTrigger = confirmingPassword.mapToVoid().map { true }
            .merge(with: input.fromView.isEditingConfirmedEncryptionPassword)
            .eraseToAnyPublisher()

        // Confirm-field validation ALSO needs to re-run when the *first* password
        // field changes (because a previously-valid confirmation may now mismatch).
        // We combineLatest with `encryptionPasswordValidationTrigger` purely as a
        // re-evaluation pulse — the actual validation value comes from
        // `confirmEncryptionPasswordValidationValue` via withLatestFrom.
        // encryptionPasswordValidationTrigger used solely to trigger re-evaluation; value discarded
        let confirmEncryptionPasswordValidation: AnyPublisher<AnyValidation, Never> = confirmEditingTrigger
            .combineLatest(encryptionPasswordValidationTrigger)
            .withLatestFrom(confirmEncryptionPasswordValidationValue) {
                EditingValidation(isEditing: $0.0, validation: $1.validation)
            }.eagerValidLazyErrorTurnedToEmptyOnEdit()

        return Output(
            // Static placeholder text — wrapped in `Just` so the view can bind it
            // through the same `-->` operator pipeline as the dynamic outputs.
            // The minimum-length value is interpolated from the policy so the UI
            // stays in sync with `WalletEncryptionPassword.Mode` if it ever changes.
            encryptionPasswordPlaceholder: Just(String(localized: .CreateNewWallet
                    .encryptionPasswordField(minLength: WalletEncryptionPassword
                        .minimumLength(mode: encryptionPasswordMode))))
                .eraseToAnyPublisher(),
            encryptionPasswordValidation: encryptionPasswordValidation,
            confirmEncryptionPasswordValidation: confirmEncryptionPasswordValidation,
            isContinueButtonEnabled: isContinueButtonEnabled,
            isButtonLoading: activityIndicator.asPublisher()
        )
    }
}

public extension CreateNewWalletViewModel {
    /// Reactive inputs sourced from `CreateNewWalletView` (user interactions).
    ///
    /// All publishers are `Never`-failing per the project-wide convention — UI streams
    /// must not terminate the pipeline.
    struct InputFromView {
        /// Live text contents of the primary password field.
        let newEncryptionPassword: AnyPublisher<String, Never>
        /// `true` while the user is focused in the primary password field, `false` on resign.
        let isEditingNewEncryptionPassword: AnyPublisher<Bool, Never>
        /// Live text contents of the confirm-password field.
        let confirmedNewEncryptionPassword: AnyPublisher<String, Never>
        /// `true` while the user is focused in the confirm-password field, `false` on resign.
        let isEditingConfirmedEncryptionPassword: AnyPublisher<Bool, Never>

        /// Current checked state of the "I have backed up my password" checkbox.
        let isHaveBackedUpPasswordCheckboxChecked: AnyPublisher<Bool, Never>
        /// Fires once per tap of the "continue / create wallet" button.
        let createWalletTrigger: AnyPublisher<Void, Never>
    }

    /// Reactive outputs delivered to `CreateNewWalletView.populate(with:)` for one-way binding.
    struct Output {
        /// Fully-formatted placeholder text (with interpolated minimum length) for the password field.
        let encryptionPasswordPlaceholder: AnyPublisher<String, Never>
        /// Validation state to render on the primary password field (border colour, remark text, …).
        let encryptionPasswordValidation: AnyPublisher<AnyValidation, Never>
        /// Validation state to render on the confirm-password field (also reflects mismatch).
        let confirmEncryptionPasswordValidation: AnyPublisher<AnyValidation, Never>
        /// Drives the enabled/disabled state of the continue button.
        let isContinueButtonEnabled: AnyPublisher<Bool, Never>
        /// `true` while the wallet derivation is in flight; the button shows a spinner overlay.
        let isButtonLoading: AnyPublisher<Bool, Never>
    }

    /// Thin wrapper around `EncryptionPasswordValidator` that hides the policy mode
    /// from call sites and provides a clean single-field vs. confirmation API.
    ///
    /// The underlying validator is constructed per-call (it is cheap and stateless)
    /// to keep this struct itself a value type with no setup ceremony.
    internal struct InputValidator {
        /// Validates a single password against the new-wallet policy.
        ///
        /// Implementation note: the underlying validator expects a `(password, confirmation)`
        /// tuple; we pass the same value twice so that "confirmation matches" trivially holds
        /// and only the structural rules (length, charset, etc.) drive the result.
        func validateNewEncryptionPassword(_ password: String) -> EncryptionPasswordValidator.ValidationResult {
            let validator = EncryptionPasswordValidator(mode: encryptionPasswordMode)
            return validator.validate(input: (password, password))
        }

        /// Validates a `(password, confirming)` pair — both structural rules and "they match".
        ///
        /// - Parameters:
        ///   - password: The primary password value.
        ///   - confirming: The value typed in the confirm-password field.
        func validateConfirmedEncryptionPassword(
            _ password: String,
            confirmedBy confirming: String
        ) -> EncryptionPasswordValidator.ValidationResult {
            let validator = EncryptionPasswordValidator(mode: encryptionPasswordMode)
            return validator.validate(input: (password, confirming))
        }
    }
}
