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

/// Pincode-unlock screen — N-digit input + descriptive label. No CTA — entering
/// a matching pincode auto-unlocks (the view-model emits `.unlockApp` as soon
/// as the entered digits match).
final class UnlockAppWithPincodeView: ScrollableStackViewOwner {
    /// Custom N-digit pincode input view.
    private lazy var inputPincodeView = InputPincodeView()
    /// Body description / instruction label.
    private lazy var descriptionLabel = UILabel()

    /// Vertical layout: input, description, spacer.
    lazy var stackViewStyle: UIStackView.Style = [
        inputPincodeView,
        descriptionLabel,
        .spacer,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override func setup() {
        setupSubviews()
    }
}

extension UnlockAppWithPincodeView: ViewModelled {
    typealias ViewModel = UnlockAppWithPincodeViewModel

    /// Binds focus on appear + validation styling on the pincode input.
    func populate(with viewModel: UnlockAppWithPincodeViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.inputBecomeFirstResponder --> inputPincodeView.becomeFirstResponderBinder,
            viewModel.pincodeValidation --> inputPincodeView.validationBinder,
        ]
    }

    /// Surfaces only the pincode publisher.
    var inputFromView: InputFromView {
        InputFromView(
            pincode: inputPincodeView.pincodePublisher
        )
    }
}

private extension UnlockAppWithPincodeView {
    /// Styling pass — center-aligned body label.
    func setupSubviews() {
        descriptionLabel.withStyle(.body) {
            $0.text(String(localized: .UnlockApp.label)).textAlignment(.center)
        }
    }
}
