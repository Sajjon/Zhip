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
import SingleLineControllerController
import SingleLineControllerSceneViews

/// Wallet-removal confirmation — "are you sure" header + "I have backed up"
/// checkbox + confirm CTA gated on the checkbox.
final class ConfirmWalletRemovalView: ScrollableStackViewOwner {
    /// "Are you sure?" header label.
    private lazy var areYouSureLabel = UILabel()
    /// "I have backed up the wallet" checkbox — must be checked to enable confirm.
    private lazy var haveBackedUpWalletCheckbox = CheckboxWithLabel()
    /// Confirm CTA — destructive action, gated on the checkbox.
    private lazy var confirmButton = UIButton()

    /// Vertical layout: header, spacer, checkbox, CTA.
    lazy var stackViewStyle: UIStackView.Style = [
        areYouSureLabel,
        .spacer,
        haveBackedUpWalletCheckbox,
        confirmButton,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override func setup() {
        setupSubviews()
    }
}

extension ConfirmWalletRemovalView: ViewModelled {
    typealias ViewModel = ConfirmWalletRemovalViewModel

    /// Binds the confirm-button enabled state to the view-model.
    func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.isConfirmButtonEnabled --> confirmButton.isEnabledBinder,
        ]
    }

    /// Surfaces the confirm-tap and the checkbox state.
    var inputFromView: InputFromView {
        InputFromView(
            confirmTrigger: confirmButton.tapPublisher,
            isWalletBackedUpCheckboxChecked: haveBackedUpWalletCheckbox.isCheckedPublisher
        )
    }
}

private extension ConfirmWalletRemovalView {
    /// Styling pass — header label, default-styled checkbox, primary destructive button.
    func setupSubviews() {
        areYouSureLabel.withStyle(.header) {
            $0.text(String(localized: .ConfirmWalletRemoval.areYouSure))
        }

        haveBackedUpWalletCheckbox.withStyle(.default) {
            $0.text(String(localized: .ConfirmWalletRemoval.backUpWallet))
        }

        confirmButton.withStyle(.primary) {
            $0.title(String(localized: .ConfirmWalletRemoval.confirm))
                .disabled()
        }
    }
}
