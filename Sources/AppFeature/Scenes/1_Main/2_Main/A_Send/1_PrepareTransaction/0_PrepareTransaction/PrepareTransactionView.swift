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
import UIKit
import Zesame
import SingleLineControllerController
import SingleLineControllerSceneViews

/// Step 1 of Send — recipient/amount/gas entry with QR-scan + max-amount conveniences,
/// plus pull-to-refresh on balance. The view-model handles validation, max-amount
/// calculation (balance - gas), and QR-scan pre-fill routing.
public final class PrepareTransactionView: ScrollableStackViewOwner, PullToRefreshCapable {
    private lazy var balanceTitleLabel = UILabel()
    private lazy var balanceValueLabel = UILabel()
    private lazy var balanceLabels = UIStackView(arrangedSubviews: [balanceTitleLabel, balanceValueLabel])
    private lazy var recipientAddressField = FloatingLabelTextField()
    private lazy var scanQRButton = recipientAddressField.addBottomAlignedButton(image: UIImage(resource: .cameraSmall))
    private lazy var amountToSendField = FloatingLabelTextField()
    private lazy var maxAmountButton = amountToSendField
        .addBottomAlignedButton(titled: String(localized: .PrepareTransaction.maxAmount))
    private lazy var gasMeasuredInSmallUnitsLabel = UILabel()

    private lazy var gasLimitField = FloatingLabelTextField()
    private lazy var gasPriceField = FloatingLabelTextField()
    private lazy var toReviewButton = UIButton()
    private lazy var costOfTransactionLabel = UILabel()

    // MARK: - StackViewStyling

    public lazy var stackViewStyle: UIStackView.Style = [
        balanceLabels,
        recipientAddressField,
        amountToSendField,
        gasLimitField,
        gasPriceField,
        costOfTransactionLabel,
        .spacer,
        toReviewButton,
    ]

    public override func setup() {
        setupSubviews()
        prefillValuesForDebugBuilds()
    }
}

// MARK: - SingleContentView

extension PrepareTransactionView: ViewModelled {
    public typealias ViewModel = PrepareTransactionViewModel

    public func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.refreshControlLastUpdatedTitle --> pullToRefreshTitleBinder,
            viewModel.isFetchingBalance --> isRefreshingBinder,
            viewModel.amountPlaceholder --> amountToSendField.placeholderBinder,
            viewModel.amount --> amountToSendField.textBinder,
            viewModel.recipient --> recipientAddressField.textBinder,
            viewModel.isReviewButtonEnabled --> toReviewButton.isEnabledBinder,
            viewModel.balance --> balanceValueLabel.textBinder,
            viewModel.recipientAddressValidation --> recipientAddressField.validationBinder,
            viewModel.amountValidation --> amountToSendField.validationBinder,

            viewModel.gasLimitMeasuredInLi --> gasLimitField.textBinder,
            viewModel.gasLimitPlaceholder --> gasLimitField.placeholderBinder,
            viewModel.gasLimitValidation --> gasLimitField.validationBinder,

            viewModel.gasPriceMeasuredInLi --> gasPriceField.textBinder,
            viewModel.gasPricePlaceholder --> gasPriceField.placeholderBinder,
            viewModel.gasPriceValidation --> gasPriceField.validationBinder,
            viewModel.costOfTransaction --> costOfTransactionLabel.textBinder,
        ]
    }

    public var inputFromView: InputFromView {
        InputFromView(
            pullToRefreshTrigger: pullToRefreshTriggerPublisher,
            scanQRTrigger: scanQRButton.tapPublisher,
            maxAmountTrigger: maxAmountButton.tapPublisher,
            toReviewTrigger: toReviewButton.tapPublisher,

            recipientAddress: recipientAddressField.textPublisher.orEmpty.dropFirst(1).eraseToAnyPublisher(),
            didEndEditingRecipientAddress: recipientAddressField.didEndEditingPublisher,

            amountToSend: amountToSendField.textPublisher.orEmpty.dropFirst(1).eraseToAnyPublisher(),
            didEndEditingAmount: amountToSendField.didEndEditingPublisher,

            gasLimit: gasLimitField.textPublisher.orEmpty.dropFirst(1).eraseToAnyPublisher(),
            didEndEditingGasLimit: gasLimitField.didEndEditingPublisher,

            gasPrice: gasPriceField.textPublisher.orEmpty.dropFirst(1).eraseToAnyPublisher(),
            didEndEditingGasPrice: gasPriceField.didEndEditingPublisher
        )
    }
}

// MARK: - Private

private extension PrepareTransactionView {
    func setupSubviews() {
        balanceTitleLabel.withStyle(.title) {
            $0.text(String(localized: .PrepareTransaction.balanceTitle))
        }

        balanceValueLabel.withStyle(.body) {
            $0.textAlignment(.right)
        }

        balanceLabels.withStyle(.horizontal)

        recipientAddressField.withStyle(.addressBech32OrHex) {
            $0.placeholder(String(localized: .PrepareTransaction.recipientField))
        }

        recipientAddressField.rightView = scanQRButton
        recipientAddressField.rightViewMode = .always

        amountToSendField.withStyle(.decimal)

        gasMeasuredInSmallUnitsLabel.withStyle(.body) {
            $0
                .text(String(localized: .PrepareTransaction
                        .gasInSmallUnits(unit: "\(Unit.li.name) (\(Unit.li.powerOf))")))
        }

        costOfTransactionLabel.withStyle(.body) {
            $0.textAlignment(.center)
        }

        gasLimitField.withStyle(.number)
        gasPriceField.withStyle(.number)

        toReviewButton.withStyle(.primary) {
            $0.title(String(localized: .PrepareTransaction.reviewPayment))
                .disabled()
        }
    }
}

// MARK: - Debug builds only

private extension PrepareTransactionView {
    func prefillValuesForDebugBuilds() {
        #if DEBUG
            recipientAddressField.text = "zil175grxdeqchwnc0qghj8qsh5vnqwww353msqj82"
            amountToSendField.text = Int.random(in: 1 ... 5).description
            gasLimitField.text = Int.random(in: 50 ... 100).description
            gasPriceField.text = Int.random(in: 1000 ... 2000).description

            Container.shared.clock().schedule(after: 0.3) { [weak self] in
                guard let self else { return }
                [
                    recipientAddressField,
                    amountToSendField,
                    gasLimitField,
                    gasPriceField,
                ].forEach {
                    $0.sendActions(for: .editingDidEnd)
                }
            }
        #endif
    }
}
