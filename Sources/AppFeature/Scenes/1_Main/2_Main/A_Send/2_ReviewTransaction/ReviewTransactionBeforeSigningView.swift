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
import NanoViewControllerCombine
import NanoViewControllerController
import NanoViewControllerSceneViews
import NanoViewControllerCore
import UIKit

/// Step 2 of Send — read-only summary of the prepared payment (recipient,
/// amount, gas, total) plus an "I have reviewed" checkbox + accept CTA.
public final class ReviewTransactionBeforeSigningView: ScrollableStackViewOwner {
    private lazy var recipientAddressesLabel = UILabel()
    private lazy var recipientLegacyAddressView = TitledValueView()
    private lazy var recipientBech32AddressView = TitledValueView()
    private lazy var recipientViewsStackView = UIStackView(arrangedSubviews: [
        recipientAddressesLabel,
        recipientLegacyAddressView,
        recipientBech32AddressView,
    ])

    private lazy var amountLabel = UILabel()
    private lazy var amountToSendView = TitledValueView()
    private lazy var transactionFeeView = TitledValueView()
    private lazy var totalCostOfTransactionView = TitledValueView()
    private lazy var amountViewsStackView = UIStackView(arrangedSubviews: [
        amountLabel,
        amountToSendView,
        transactionFeeView,
        totalCostOfTransactionView,
    ])

    private lazy var hasReviewedPaymentCheckBox = CheckboxWithLabel()
    private lazy var acceptPaymentProceedToSigningButton = UIButton()

    public lazy var stackViewStyle: UIStackView.Style = [
        recipientViewsStackView,
        amountViewsStackView,
        hasReviewedPaymentCheckBox,
        acceptPaymentProceedToSigningButton,
        .spacer,
    ]

    override public func setup() {
        setupSubviews()
    }
}

extension ReviewTransactionBeforeSigningView: ViewModelled {
    public typealias ViewModel = ReviewTransactionBeforeSigningViewModel

    public var inputFromView: InputFromView {
        InputFromView(
            isHasReviewedPaymentCheckboxChecked: hasReviewedPaymentCheckBox.isCheckedPublisher,
            hasReviewedNowProceedWithSigningTrigger: acceptPaymentProceedToSigningButton.tapPublisher
        )
    }

    public func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.isHasReviewedNowProceedWithSigningButtonEnabled --> acceptPaymentProceedToSigningButton
                .isEnabledBinder,
            viewModel.recipientBech32Address --> recipientBech32AddressView.valueBinder,
            viewModel.recipientLegacyAddress --> recipientLegacyAddressView.valueBinder,
            viewModel.amountToPay --> amountToSendView.valueBinder,
            viewModel.paymentFee --> transactionFeeView.valueBinder,
            viewModel.totalCost --> totalCostOfTransactionView.valueBinder,
        ]
    }
}

private extension ReviewTransactionBeforeSigningView {
    func setupSubviews() {
        func setup(
            titledValueView: TitledValueView,
            customizeTitleStyle: @escaping ((UILabel.Style) -> (UILabel.Style))
        ) {
            let titleStyle = UILabel.Style.body.font(UIFont.valueTitle)
            let valueStyle = UITextView.Style.nonSelectable
                .isScrollEnabled(false)
                .textAlignment(.natural)
                .textColor(.teal)
                .font(.value)

            let stackViewStyle = UIStackView.Style(
                spacing: -2,
                layoutMargins: .zero,
                isLayoutMarginsRelativeArrangement: false
            )

            titledValueView.withStyles(
                forTitle: titleStyle,
                forValue: valueStyle,
                forStackView: stackViewStyle,
                customizeTitleStyle: customizeTitleStyle
            )
        }

        let labelStyleForHeaders: UILabel.Style = .header
        let stackViewStyle: UIStackView.Style = .vertical

        // MARK: - Recipient views

        recipientAddressesLabel.withStyle(labelStyleForHeaders) {
            $0.text(String(localized: .ReviewTransaction.recipient))
        }

        setup(titledValueView: recipientLegacyAddressView) {
            $0.text(String(localized: .ReviewTransaction.addressLegacy))
        }

        setup(titledValueView: recipientBech32AddressView) {
            $0.text(String(localized: .ReviewTransaction.addressBech32))
        }

        recipientViewsStackView.withStyle(stackViewStyle)

        // MARK: - Amount views

        amountLabel.withStyle(labelStyleForHeaders) {
            $0.text(String(localized: .ReviewTransaction.amount))
        }

        setup(titledValueView: amountToSendView) {
            $0.text(String(localized: .ReviewTransaction.amountToSend))
        }

        setup(titledValueView: transactionFeeView) {
            $0.text(String(localized: .ReviewTransaction.transactionFee))
        }

        setup(titledValueView: totalCostOfTransactionView) {
            $0.text(String(localized: .ReviewTransaction.totalCost))
        }

        amountViewsStackView.withStyle(stackViewStyle)

        // MARK: Checkbox and button

        hasReviewedPaymentCheckBox.withStyle(.default) {
            $0.text(String(localized: .ReviewTransaction.hasReviewedPayment))
        }

        acceptPaymentProceedToSigningButton.withStyle(.primary) {
            $0.title(String(localized: .ReviewTransaction.proceedToSigning))
                .disabled()
        }
    }
}
