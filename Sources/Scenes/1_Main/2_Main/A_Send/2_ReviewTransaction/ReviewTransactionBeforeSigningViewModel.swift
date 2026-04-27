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
import Foundation
import SingleLineControllerCombine
import Zesame

/// Outcome of step 2 of Send.
enum ReviewTransactionBeforeSigningUserAction {
    /// User checked "I have reviewed" and tapped accept; payment forwarded to signing.
    case acceptPaymentProceedWithSigning(Payment)
}

/// View model for step 2 of Send. Displays the prepared payment in human-readable
/// form (formatted amounts, both legacy hex + bech32 recipient addresses) and
/// gates the accept CTA on the "I have reviewed" checkbox.
final class ReviewTransactionBeforeSigningViewModel: BaseViewModel<
    ReviewTransactionBeforeSigningUserAction,
    ReviewTransactionBeforeSigningViewModel.InputFromView,
    ReviewTransactionBeforeSigningViewModel.Output
> {
    /// The payment to display + forward.
    private let paymentToReview: Payment

    /// Captures the payment to display.
    init(paymentToReview: Payment) {
        self.paymentToReview = paymentToReview
    }

    /// Wires the accept-tap (carries `paymentToReview` upstream) and formats
    /// the four displayed values (recipient hex/bech32, amount, fee, total).
    override func transform(input: Input) -> Output {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        // MARK: - Validate input

        [
            input.fromView.hasReviewedNowProceedWithSigningTrigger.map { self.paymentToReview }
                .sink { userDid(.acceptPaymentProceedWithSigning($0)) },
        ].forEach { $0.store(in: &cancellables) }

        let payment = Just(paymentToReview).eraseToAnyPublisher()
        let recipientLegacyAddress = payment.map(\.recipient)
        let recipientBech32Address = payment.map { try? Bech32Address(ethStyleAddress: $0.recipient, network: network) }
            .filterNil()

        let amountFormatter = AmountFormatter()

        let amountToPay = payment.map { amountFormatter.format(
            amount: $0.amount,
            in: .zil,
            formatThousands: true,
            minFractionDigits: 2,
            showUnit: true
        ) }
        let paymentFee = payment.map { amountFormatter.format(
            amount: $0.transactionFee,
            in: .zil,
            formatThousands: false,
            minFractionDigits: 5,
            showUnit: true
        ) }
        // `totalCostInZil` is optional — if amount-overflow ever rejects the
        // arithmetic the user sees "—" instead of the app crashing on the
        // funds-display step. There is no transaction-correctness consequence:
        // the actual signing math runs in Zesame against the same `Payment`.
        let totalCost = payment.map { (payment: Payment) -> String in
            guard let total = payment.totalCostInZil else { return "—" }
            return amountFormatter.format(
                amount: total,
                in: .zil,
                formatThousands: true,
                minFractionDigits: 2,
                showUnit: true
            )
        }

        return Output(
            isHasReviewedNowProceedWithSigningButtonEnabled: input.fromView.isHasReviewedPaymentCheckboxChecked,
            recipientLegacyAddress: recipientLegacyAddress.map(\.asString).eraseToAnyPublisher(),
            recipientBech32Address: recipientBech32Address.map(\.asString).eraseToAnyPublisher(),
            amountToPay: amountToPay.eraseToAnyPublisher(),
            paymentFee: paymentFee.eraseToAnyPublisher(),
            totalCost: totalCost.eraseToAnyPublisher()
        )
    }
}

extension ReviewTransactionBeforeSigningViewModel {
    struct InputFromView {
        let isHasReviewedPaymentCheckboxChecked: AnyPublisher<Bool, Never>
        let hasReviewedNowProceedWithSigningTrigger: AnyPublisher<Void, Never>
    }

    struct Output {
        let isHasReviewedNowProceedWithSigningButtonEnabled: AnyPublisher<Bool, Never>
        let recipientLegacyAddress: AnyPublisher<String, Never>
        let recipientBech32Address: AnyPublisher<String, Never>
        let amountToPay: AnyPublisher<String, Never>
        let paymentFee: AnyPublisher<String, Never>
        let totalCost: AnyPublisher<String, Never>
    }
}

private extension Payment {
    var transactionFee: Qa {
        (try? Payment.estimatedTotalTransactionFee(gasPrice: gasPrice, gasLimit: gasLimit)) ?? gasPrice.asQa
    }

    /// Computed total. `Optional` (was a crashing `try!`) so a future
    /// tightening of `Amount` validation cannot crash the Send-review screen.
    var totalCostInZil: Amount? {
        if let estimatedTotal = try? Payment.estimatedTotalCostOfTransaction(
            amount: amount,
            gasPrice: gasPrice,
            gasLimit: gasLimit
        ) {
            return estimatedTotal
        } else {
            let totalInQa = amount.asQa + transactionFee
            return try? Amount(qa: totalInQa)
        }
    }
}
