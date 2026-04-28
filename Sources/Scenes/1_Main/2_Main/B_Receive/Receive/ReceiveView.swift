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
import UIKit
import Zesame
import SingleLineControllerController
import SingleLineControllerSceneViews

// MARK: - ReceiveView

/// Receive screen — QR code + address + optional amount-to-request field +
/// "Request payment" CTA that opens a system share sheet via the coordinator.
final class ReceiveView: ScrollableStackViewOwner {
    private lazy var qrImageView = UIImageView()
    private lazy var addressTitleLabel = UILabel()
    private lazy var addressValueTextView = UITextView()
    private lazy var copyMyAddressButton = UIButton()
    private lazy var addressAndCopyButton = UIStackView(arrangedSubviews: [addressValueTextView, copyMyAddressButton])
    private lazy var addressViews = UIStackView(arrangedSubviews: [addressTitleLabel, addressAndCopyButton])
    private lazy var requestingAmountField = FloatingLabelTextField()
    private lazy var requestPaymentButton = UIButton()

    // MARK: - StackViewStyling

    lazy var stackViewStyle = UIStackView.Style([
        qrImageView,
        addressViews,
        requestingAmountField,
        .spacer,
        requestPaymentButton,
    ])

    override func setup() {
        setupSubviews()
    }
}

// MARK: - SingleContentView

extension ReceiveView: ViewModelled {
    typealias ViewModel = ReceiveViewModel

    func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.receivingAddress --> addressValueTextView.textBinder,
            viewModel.amountPlaceholder --> requestingAmountField.placeholderBinder,
            viewModel.amountValidation --> requestingAmountField.validationBinder,
            viewModel.qrImage --> qrImageView.imageBinder,
        ]
    }

    var inputFromView: InputFromView {
        InputFromView(
            qrCodeImageHeight: 200,
            amountToReceive: requestingAmountField.textPublisher.orEmpty.dropFirst(1).eraseToAnyPublisher(),
            didEndEditingAmount: requestingAmountField.didEndEditingPublisher,
            copyMyAddressTrigger: copyMyAddressButton.tapPublisher,
            shareTrigger: requestPaymentButton.tapPublisher
        )
    }
}

private extension ReceiveView {
    func setupSubviews() {
        qrImageView.withStyle(.default)

        addressTitleLabel.withStyle(.title) {
            $0.text(String(localized: .Receive.myPublicAddress))
        }

        addressValueTextView.withStyle(.init(
            font: UIFont.Label.body,
            isEditable: false,
            isScrollEnabled: false,
            // UILabel and UITextView horizontal alignment differs, change inset: stackoverflow.com/a/45113744/1311272
            contentInset: UIEdgeInsets(top: 0, left: -5, bottom: 0, right: -5)
        )
        )

        copyMyAddressButton.withStyle(.title(String(localized: .Receive.copy)))
        copyMyAddressButton.setHugging(.required, for: .horizontal)

        addressAndCopyButton.withStyle(.horizontal)
        addressViews.withStyle(.default) {
            $0.layoutMargins(.zero)
        }

        requestingAmountField.withStyle(.decimal)

        requestPaymentButton.withStyle(.primary) {
            $0.title(String(localized: .Receive.requestPayment))
        }
    }
}
