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
import SingleLineControllerController
import SingleLineControllerSceneViews
import UIKit

/// Pincode chooser screen — N-digit pincode input + disclaimer + done CTA.
public final class ChoosePincodeView: ScrollableStackViewOwner {
    /// Custom N-digit pincode input view (digit boxes that auto-advance).
    private lazy var inputPincodeView = InputPincodeView()
    /// Disclaimer that the pincode only locks the app, not the wallet keystore.
    private lazy var pinOnlyLocksAppTextView = UITextView()
    /// Bottom done CTA — disabled until a complete pincode is entered.
    private lazy var doneButton = UIButton()

    /// Vertical layout: pincode input, disclaimer, done CTA, spacer.
    public lazy var stackViewStyle: UIStackView.Style = [
        inputPincodeView,
        pinOnlyLocksAppTextView,
        doneButton,
        .spacer,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override public func setup() {
        setupSubviews()
    }
}

extension ChoosePincodeView: ViewModelled {
    public typealias ViewModel = ChoosePincodeViewModel

    /// Surfaces the pincode publisher (`nil` while incomplete) and the done-tap.
    public var inputFromView: InputFromView {
        InputFromView(
            pincode: inputPincodeView.pincodePublisher,
            doneTrigger: doneButton.tapPublisher
        )
    }

    /// Binds focus + button-enabled state — view-model auto-focuses on
    /// `viewWillAppear` so the keyboard is up by the time the user sees the screen.
    public func populate(with viewModel: ChoosePincodeViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.inputBecomeFirstResponder --> inputPincodeView.becomeFirstResponderBinder,
            viewModel.isDoneButtonEnabled --> doneButton.isEnabledBinder,
        ]
    }
}

private extension ChoosePincodeView {
    /// Styling pass — disclaimer text view (non-scrollable, silver-grey),
    /// primary done button initially disabled.
    func setupSubviews() {
        pinOnlyLocksAppTextView.withStyle(.nonSelectable) {
            $0.text(String(localized: .ChoosePincode.pincodeOnlyLocksApp))
                .textColor(.silverGrey)
                .isScrollEnabled(false)
        }

        doneButton.withStyle(.primary) {
            $0.title(String(localized: .ChoosePincode.done))
                .disabled()
        }
    }
}
