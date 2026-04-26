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
import Zesame

/// Outcome of step 3 of Send.
enum SignTransactionUserAction {
    /// Transaction successfully signed + broadcast — carries the network response.
    case sign(TransactionResponse)
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

    /// The payment to sign.
    private let payment: Payment

    /// Captures the payment to sign.
    init(paymentToSign: Payment) {
        payment = paymentToSign
    }

    /// Wires real-time password validation, the sign-tap (cancellable
    /// flatMapLatest), and the loading-spinner / error-tracker plumbing.
    override func transform(input: Input) -> Output {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        guard let _wallet = walletStorageUseCase.loadWallet() else { incorrectImplementation("Should have wallet") }
        let _payment = payment

        let errorTracker = ErrorTracker()
        let activityIndicator = ActivityIndicator()

        // MARK: - Validate input

        let validator = InputValidator()

        let encryptionPasswordValidationValue = input.fromView.encryptionPassword
            .map { validator.validateEncryptionPassword($0, for: _wallet) }

        let encryptionPassword = encryptionPasswordValidationValue.map { $0.value?.validPassword }.filterNil()

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
            input.fromView.encryptionPassword.mapToVoid().map { true }.merge(with: input.fromView.isEditingEncryptionPassword).eraseToAnyPublisher().withLatestFrom(encryptionPasswordValidationValue) {
            EditingValidation(isEditing: $0, validation: $1.validation)
        }.eagerValidLazyErrorTurnedToEmptyOnEdit(
            directlyDisplayErrorsTrackedBy: errorTracker
        ) {
            WalletEncryptionPassword.Error.incorrectPasswordErrorFrom(error: $0)
        }

        let isSignButtonEnabled: AnyPublisher<Bool, Never> = encryptionPasswordValidation.map(\.isValid).eraseToAnyPublisher()

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
