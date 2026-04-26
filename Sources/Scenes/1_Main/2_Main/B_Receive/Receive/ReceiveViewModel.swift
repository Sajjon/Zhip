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
import UIKit
import Zesame

// MARK: - ReceiveUserAction

/// Outcomes of the Receive screen.
enum ReceiveUserAction {
    /// User tapped the right "Done" bar-button.
    case finish
    /// User tapped "Request payment" — coordinator opens the share sheet.
    case requestTransaction(TransactionIntent)
}

// MARK: - ReceiveViewModel

/// View model for the Receive screen. Renders the wallet's bech32 address as a
/// QR code, handles the optional "request amount" field, and produces the
/// `TransactionIntent` consumed by the coordinator's share-sheet helper.
final class ReceiveViewModel: BaseViewModel<
    ReceiveUserAction,
    ReceiveViewModel.InputFromView,
    ReceiveViewModel.Output
> {
    /// Source of the wallet whose address is shown.
    @Injected(\.walletStorageUseCase) private var walletStorageUseCase: WalletStorageUseCase
    /// Pasteboard wrapper for the copy-address button.
    @Injected(\.pasteboard) private var pasteboard: Pasteboard
    /// QR-encoder for the address image.
    @Injected(\.qrCoder) private var qrCoder: QRCoding

    /// Wires the address QR generation, amount validation, copy-to-pasteboard
    /// behavior, and the request-payment hand-off to the coordinator.
    override func transform(input: Input) -> Output {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        let wallet = walletStorageUseCase.wallet.filterNil().replaceErrorWithEmpty()

        let validator = InputValidator()

        let amountValidationValue: AnyPublisher<AmountValidator<Amount>.ValidationResult, Never> = input.fromView.amountToReceive
            .map { validator.validateAmount($0) }.prepend(.valid(.amount(
                0,
                in: .zil
            ))).eraseToAnyPublisher()

        let amount = amountValidationValue.map(\.value).eraseToAnyPublisher()

        let amountValidationTrigger = input.fromView.didEndEditingAmount

        let amountValidation: AnyPublisher<AnyValidation, Never> = amountValidationTrigger
            .withLatestFrom(amountValidationValue)
            .onlyErrors()
            .merge(with: amountValidationValue.nonErrors())
            .eraseToAnyPublisher()

        let transactionToReceive: AnyPublisher<TransactionIntent, Never> = wallet
            .map { Address.bech32($0.bech32Address) }
            .combineLatest(amount.map { $0?.amount }.filterNil()) { TransactionIntent(to: $0, amount: $1) }
            .eraseToAnyPublisher()

        let qrImage: AnyPublisher<UIImage?, Never> = transactionToReceive.map { [qrCoder] in
            qrCoder.encode(transaction: $0, size: input.fromView.qrCodeImageHeight)
        }.eraseToAnyPublisher()

        let receivingAddress: AnyPublisher<String, Never> = wallet.map(\.bech32Address.asString).eraseToAnyPublisher()

        [
            input.fromController.rightBarButtonTrigger
                .sink { userDid(.finish) },

            input.fromView.copyMyAddressTrigger.withLatestFrom(receivingAddress)
                .sink { [pasteboard] in
                    pasteboard.copy($0)
                    input.fromController.toastSubject.send(Toast(String(localized: .Receive.copiedAddress)))
                },

            input.fromView.shareTrigger.withLatestFrom(transactionToReceive)
                .sink { userDid(.requestTransaction($0)) },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            receivingAddress: receivingAddress,
            amountPlaceholder: Just(String(localized: .Receive.requestAmountField(unit: Unit.zil.name))).eraseToAnyPublisher(),
            amountValidation: amountValidation,
            qrImage: qrImage
        )
    }
}

extension ReceiveViewModel {
    struct InputFromView {
        let qrCodeImageHeight: CGFloat
        let amountToReceive: AnyPublisher<String, Never>
        let didEndEditingAmount: AnyPublisher<Void, Never>
        let copyMyAddressTrigger: AnyPublisher<Void, Never>
        let shareTrigger: AnyPublisher<Void, Never>
    }

    struct Output {
        let receivingAddress: AnyPublisher<String, Never>
        let amountPlaceholder: AnyPublisher<String, Never>
        let amountValidation: AnyPublisher<AnyValidation, Never>
        let qrImage: AnyPublisher<UIImage?, Never>
    }

    struct InputValidator {
        private let zilAmountValidator = AmountValidator<Amount>()

        func validateAmount(_ amount: String) -> AmountValidator<Amount>.ValidationResult {
            zilAmountValidator.validate(input: (amount, Zesame.Unit.zil))
        }
    }
}
