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

/// Pincode confirmation screen — input + "I have backed up" checkbox + done CTA.
/// `isClearedOnValidInput: false` keeps the entered pincode visible on mismatch
/// so the user can see what they typed.
final class ConfirmNewPincodeView: ScrollableStackViewOwner {
    /// Pincode re-entry input — preserves text on mismatch (vs. the chooser
    /// which clears on completion).
    private lazy var inputPincodeView = InputPincodeView(isClearedOnValidInput: false)
    /// "I have backed up the pincode" checkbox — must be checked to enable confirm.
    private lazy var haveBackedUpPincodeCheckbox = CheckboxWithLabel()
    /// Bottom CTA — gated on (pincode matches) && (checkbox checked).
    private lazy var confirmPincodeButton = UIButton()

    /// Vertical layout: pincode input, checkbox, CTA, spacer.
    lazy var stackViewStyle: UIStackView.Style = [
        inputPincodeView,
        haveBackedUpPincodeCheckbox,
        confirmPincodeButton,
        .spacer,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override func setup() {
        setupSubviews()
    }
}

extension ConfirmNewPincodeView: ViewModelled {
    typealias ViewModel = ConfirmNewPincodeViewModel

    /// Surfaces the pincode publisher, checkbox state, and confirm-tap.
    var inputFromView: InputFromView {
        InputFromView(
            pincode: inputPincodeView.pincodePublisher,
            isHaveBackedUpPincodeCheckboxChecked: haveBackedUpPincodeCheckbox.isCheckedPublisher,
            confirmedTrigger: confirmPincodeButton.tapPublisher
        )
    }

    /// Binds focus on appear, validation feedback (red box on mismatch),
    /// and the confirm-button enabled state.
    func populate(with viewModel: ConfirmNewPincodeViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.inputBecomeFirstResponder --> inputPincodeView.becomeFirstResponderBinder,
            viewModel.pincodeValidation --> inputPincodeView.validationBinder,
            viewModel.isConfirmPincodeEnabled --> confirmPincodeButton.isEnabledBinder,
        ]
    }
}

private extension ConfirmNewPincodeView {
    /// Styling pass — backup-confirmation checkbox copy + primary done button.
    func setupSubviews() {
        haveBackedUpPincodeCheckbox.withStyle(.default) {
            $0.text(String(localized: .ConfirmNewPincode.pincodeIsBackedUp))
        }

        confirmPincodeButton.withStyle(.primary) {
            $0.title(String(localized: .ConfirmNewPincode.done))
                .disabled()
        }
    }
}
