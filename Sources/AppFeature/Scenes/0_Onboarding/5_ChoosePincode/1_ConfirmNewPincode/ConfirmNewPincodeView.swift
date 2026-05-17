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

/// Pincode confirmation screen — input + "I have backed up" checkbox + done CTA.
/// `isClearedOnValidInput: false` keeps the entered pincode visible on mismatch
/// so the user can see what they typed.
public final class ConfirmNewPincodeView: ScrollableStackViewOwner {
    /// Pincode re-entry input — preserves text on mismatch (vs. the chooser
    /// which clears on completion).
    private lazy var inputPincodeView = InputPincodeView(isClearedOnValidInput: false)
    /// "I have backed up the pincode" checkbox — must be checked to enable confirm.
    private lazy var haveBackedUpPincodeCheckbox = CheckboxWithLabel()
    /// Bottom CTA — gated on (pincode matches) && (checkbox checked).
    private lazy var confirmPincodeButton = UIButton()

    /// Vertical layout: pincode input, checkbox, CTA, spacer.
    public lazy var stackViewStyle: UIStackView.Style = [
        inputPincodeView,
        haveBackedUpPincodeCheckbox,
        confirmPincodeButton,
        .spacer,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override public func setup() {
        setupSubviews()
    }
}

extension ConfirmNewPincodeView: ViewModelled {
    public typealias ViewModel = ConfirmNewPincodeViewModel

    /// Surfaces the pincode publisher, checkbox state, and confirm-tap.
    public var inputFromView: InputFromView {
        InputFromView(
            pincode: inputPincodeView.pincodePublisher,
            isHaveBackedUpPincodeCheckboxChecked: haveBackedUpPincodeCheckbox.isCheckedPublisher,
            confirmedTrigger: confirmPincodeButton.tapPublisher
        )
    }

    /// Binds focus on appear, validation feedback (red box on mismatch),
    /// and the confirm-button enabled state.
    public func populate(with publishers: ConfirmNewPincodeViewModel.Publishers) -> [AnyCancellable] {
        [
            publishers.inputBecomeFirstResponder --> inputPincodeView.becomeFirstResponderBinder,
            publishers.pincodeValidation --> inputPincodeView.validationBinder,
            publishers.isConfirmPincodeEnabled --> confirmPincodeButton.isEnabledBinder,
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
