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
import SingleLineControllerCombine
import SingleLineControllerCore
import Zesame
import Validation

/// Outcome of step 3 of Send.
enum SignTransactionUserAction {
    /// Transaction successfully signed + broadcast — carries the network response.
    case sign(TransactionResponse)
    /// Wallet was unavailable when the screen tried to load it (e.g. user
    /// removed wallet in Settings while Send was open). The coordinator
    /// pops out of the Send flow gracefully rather than crash.
    case walletUnavailable
}

/// View model for step 3 of Send. Validates the password against the saved
/// keystore and (on tap) runs the sign+broadcast use case. Errors are tracked
/// so wrong-password feedback flips the floating-label field red.
final class SignTransactionViewModel: BaseViewModel<
    SignTransactionUserAction,
    SignTransactionViewModel.InputFromView,
    SignTransactionViewModel.Output
> {
    /// Use case that signs the payment with the keystore-derived private key and broadcasts.
    @Injected(\.sendTransactionUseCase) private var sendTransactionUseCase: SendTransactionUseCase
    /// Wallet source for the keystore.
    @Injected(\.walletStorageUseCase) private var walletStorageUseCase: WalletStorageUseCase
    /// Local-only password verification — used to gate the Sign button on
    /// "this password actually decrypts the keystore" instead of just
    /// "meets the structural minimum length". Saves the user a network
    /// round-trip + confusing error on a wrong password.
    @Injected(
        \.verifyEncryptionPasswordUseCase
    ) private var verifyEncryptionPasswordUseCase: VerifyEncryptionPasswordUseCase

    /// The payment to sign.
    private let payment: Payment

    /// Captures the payment to sign.
    init(paymentToSign: Payment) {
        payment = paymentToSign
    }

    /// Wires real-time password validation, the sign-tap (cancellable
    /// flatMapLatest), and the loading-spinner / error-tracker plumbing.
    ///
    /// If the wallet has been removed under us (Settings → Remove Wallet
    /// while a Send modal was open, OS-level Keychain wipe, etc.) we emit
    /// `.walletUnavailable` and return an inert output so the coordinator can
    /// pop the user out of Send instead of trapping. Defense in depth — Send
    /// should not normally be reachable without a wallet.
    override func transform(input: Input) -> Output {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        guard let _wallet = walletStorageUseCase.loadWallet() else {
            // Schedule the navigation pulse on the next runloop tick so the
            // coordinator's subscription is in place before we emit.
            input.fromController.viewDidLoad
                .first()
                .sink { _ in userDid(.walletUnavailable) }
                .store(in: &cancellables)
            return Output(
                isSignButtonEnabled: Just(false).eraseToAnyPublisher(),
                isSignButtonLoading: Just(false).eraseToAnyPublisher(),
                encryptionPasswordValidation: Just(.empty).eraseToAnyPublisher(),
                inputBecomeFirstResponder: Empty().eraseToAnyPublisher()
            )
        }
        let _payment = payment

        let errorTracker = ErrorTracker()
        let activityIndicator = ActivityIndicator()

        // MARK: - Validate input

        let validator = InputValidator()

        let encryptionPasswordValidationValue = input.fromView.encryptionPassword
            .map { validator.validateEncryptionPassword($0, for: _wallet) }

        let encryptionPassword = encryptionPasswordValidationValue.map { $0.value?.validPassword }.filterNil()

        // Live keystore-decrypt check, debounced so we don't kick off a fresh
        // KDF on every keystroke. `flatMapLatest` cancels any in-flight check
        // when a newer password lands. Failure → false (treat as "not yet
        // verified"); successful decrypt → true.
        //
        // The Sign button gates on this AND structural validity AND the
        // current password being non-empty so the button stays disabled
        // unless the user can actually sign.
        let verifyUseCase = verifyEncryptionPasswordUseCase
        let isPasswordVerified: AnyPublisher<Bool, Never> = encryptionPassword
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMapLatest { (password: String) -> AnyPublisher<Bool, Never> in
                verifyUseCase
                    .verify(password: password, forWallet: _wallet)
                    .replaceError(with: false)
                    .eraseToAnyPublisher()
            }
            .prepend(false)
            .eraseToAnyPublisher()

        [
            input.fromView.signAndSendTrigger
                .withLatestFrom(encryptionPassword)
                .flatMapLatest {
                    self.sendTransactionUseCase.sendTransaction(for: _payment, wallet: _wallet, encryptionPassword: $0)
                        .trackActivity(activityIndicator)
                        .trackError(errorTracker)
                        .replaceErrorWithEmpty()
                }
                .sink { userDid(.sign($0)) },
        ].forEach { $0.store(in: &cancellables) }

        let encryptionPasswordValidation = // map `editingChanged` to `editingDidBegin`
            input.fromView.encryptionPassword.mapToVoid().map { true }
            .merge(with: input.fromView.isEditingEncryptionPassword).withLatestFrom(encryptionPasswordValidationValue) {
                EditingValidation(isEditing: $0, validation: $1.validation)
            }.eagerValidLazyErrorTurnedToEmptyOnEdit(
                directlyDisplayErrorsTrackedBy: errorTracker
            ) {
                WalletEncryptionPassword.Error.incorrectPasswordErrorFrom(error: $0)
            }

        // Sign button needs BOTH structural validity AND a successful
        // local keystore decrypt. The combineLatest emits whenever either
        // input changes — RemoveDuplicates avoids redundant button repaints.
        let isSignButtonEnabled: AnyPublisher<Bool, Never> = encryptionPasswordValidation
            .map(\.isValid)
            .combineLatest(isPasswordVerified) { $0 && $1 }
            .removeDuplicates()
            .eraseToAnyPublisher()

        return Output(
            isSignButtonEnabled: isSignButtonEnabled,
            isSignButtonLoading: activityIndicator.asPublisher(),
            encryptionPasswordValidation: encryptionPasswordValidation,
            inputBecomeFirstResponder: input.fromController.viewDidAppear
        )
    }
}

extension SignTransactionViewModel {
    struct InputFromView {
        let encryptionPassword: AnyPublisher<String, Never>
        let isEditingEncryptionPassword: AnyPublisher<Bool, Never>
        let signAndSendTrigger: AnyPublisher<Void, Never>
    }

    struct Output {
        let isSignButtonEnabled: AnyPublisher<Bool, Never>
        let isSignButtonLoading: AnyPublisher<Bool, Never>
        let encryptionPasswordValidation: AnyPublisher<AnyValidation, Never>
        let inputBecomeFirstResponder: AnyPublisher<Void, Never>
    }

    struct InputValidator {
        func validateEncryptionPassword(_ password: String, for wallet: Wallet) -> EncryptionPasswordValidator
            .ValidationResult
        {
            let validator = EncryptionPasswordValidator(mode: WalletEncryptionPassword.modeFrom(wallet: wallet))
            return validator.validate(input: (password: password, confirmingPassword: password))
        }
    }
}
