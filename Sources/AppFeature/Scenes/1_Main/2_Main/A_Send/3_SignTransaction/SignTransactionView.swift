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

/// Step 3 of Send — re-prompt for the keystore password and sign+broadcast on tap.
public final class SignTransactionView: ScrollableStackViewOwner {
    private lazy var confirmTransactionLabel = UILabel()
    private lazy var encryptionPasswordField = FloatingLabelTextField()
    private lazy var signButton = ButtonWithSpinner()

    public lazy var stackViewStyle: UIStackView.Style = [
        confirmTransactionLabel,
        encryptionPasswordField,
        signButton,
        .spacer,
    ]

    override public func setup() {
        setupSubviews()
    }
}

extension SignTransactionView: ViewModelled {
    public typealias ViewModel = SignTransactionViewModel

    public func populate(with publishers: ViewModel.Publishers) -> [AnyCancellable] {
        [
            publishers.inputBecomeFirstResponder --> encryptionPasswordField.becomeFirstResponderBinder,
            publishers.encryptionPasswordValidation --> encryptionPasswordField.validationBinder,
            publishers.isSignButtonEnabled --> signButton.isEnabledBinder,
            publishers.isSignButtonLoading --> signButton.isLoadingBinder,
        ]
    }

    public var inputFromView: ViewModel.InputFromView {
        SignTransactionViewModel.InputFromView(
            encryptionPassword: encryptionPasswordField.textPublisher.orEmpty,
            isEditingEncryptionPassword: encryptionPasswordField.isEditingPublisher,
            signAndSendTrigger: signButton.tapPublisher
        )
    }
}

private extension SignTransactionView {
    func setupSubviews() {
        confirmTransactionLabel.withStyle(.body) {
            $0.text(String(localized: .SignTransaction.confirmWithPassword))
        }

        encryptionPasswordField.withStyle(.password) {
            $0.placeholder(String(localized: .SignTransaction.encryptionPassword))
        }

        signButton.withStyle(.primary) {
            $0.title(String(localized: .SignTransaction.confirm))
                .disabled()
        }
    }
}
