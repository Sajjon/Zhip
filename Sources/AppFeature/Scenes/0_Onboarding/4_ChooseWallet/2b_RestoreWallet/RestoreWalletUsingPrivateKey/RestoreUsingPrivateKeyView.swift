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

/// Sub-view of the RestoreWallet screen for the "I have a raw private key,
/// encrypt it with a new password" restore method.
public final class RestoreUsingPrivateKeyView: ScrollableStackViewOwner {
    typealias ViewModel = RestoreWalletUsingPrivateKeyViewModel

    /// Private-key entry field (secure by default; toggleable via the show button).
    private lazy var privateKeyField = FloatingLabelTextField()
    /// "Show"/"Hide" button overlaid bottom-right of the private-key field.
    private lazy var showPrivateKeyButton = privateKeyField
        .addBottomAlignedButton(titled: String(localized: .Generic.show))

    /// New encryption password (the user picks this — it'll encrypt the keystore).
    private lazy var encryptionPasswordField = FloatingLabelTextField()
    /// Confirm-the-password field — both must match for the restore CTA to enable.
    private lazy var confirmEncryptionPasswordField = FloatingLabelTextField()

    /// Subscription bag for the view-model bindings.
    private var cancellables = Set<AnyCancellable>()

    /// Owned view-model. Wires private key + new password + confirmation into a
    /// `KeyRestoration?` payload the parent screen surfaces upstream.
    private lazy var viewModel = ViewModel(
        inputFromView: ViewModel.InputFromView(
            privateKey: privateKeyField.textPublisher.orEmpty,
            isEditingPrivateKey: privateKeyField.isEditingPublisher,
            showPrivateKeyTrigger: showPrivateKeyButton.tapPublisher,
            newEncryptionPassword: encryptionPasswordField.textPublisher.orEmpty,
            isEditingNewEncryptionPassword: encryptionPasswordField.isEditingPublisher,
            confirmEncryptionPassword: confirmEncryptionPasswordField.textPublisher.orEmpty,
            isEditingConfirmedEncryptionPassword: confirmEncryptionPasswordField.isEditingPublisher
        )
    )

    /// Re-exported view-model output — the parent reads `keyRestoration` here.
    lazy var viewModelOutput = viewModel.output

    /// Vertical layout: private key, new password, confirm password, spacer.
    public lazy var stackViewStyle: UIStackView.Style = [
        privateKeyField,
        encryptionPasswordField,
        confirmEncryptionPasswordField,
        .spacer,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling + bindings.
    override public func setup() {
        setupSubviews()
        setupViewModelBinding()
    }
}

// MARK: - Private

private extension RestoreUsingPrivateKeyView {
    /// Styling pass — private-key field, two password fields with placeholders.
    func setupSubviews() {
        privateKeyField.withStyle(.privateKey) {
            $0.placeholder(String(localized: .RestoreWallet.privateKeyField))
        }

        encryptionPasswordField.withStyle(.password)

        confirmEncryptionPasswordField.withStyle(.password) {
            $0.placeholder(String(localized: .RestoreWallet.confirmEncryptionPassword))
        }
    }

    /// Binds all six view-model outputs (show-button title, secure-entry toggle,
    /// password placeholder, three validations) to their fields/buttons.
    func setupViewModelBinding() {
        let showPrivateKeyButtonTitleBinder = Binder<String>(showPrivateKeyButton) { button, title in
            button.setTitle(title, for: .normal)
        }
        [
            viewModelOutput.togglePrivateKeyVisibilityButtonTitle --> showPrivateKeyButtonTitleBinder,
            viewModelOutput.privateKeyFieldIsSecureTextEntry --> privateKeyField.isSecureTextEntryBinder,
            viewModelOutput.encryptionPasswordPlaceholder --> encryptionPasswordField.placeholderBinder,
            viewModelOutput.privateKeyValidation --> privateKeyField.validationBinder,
            viewModelOutput.encryptionPasswordValidation --> encryptionPasswordField.validationBinder,
            viewModelOutput.confirmEncryptionPasswordValidation --> confirmEncryptionPasswordField.validationBinder,
        ].forEach { $0.store(in: &cancellables) }
    }
}

extension UITextField {
    /// Binder that toggles `isSecureTextEntry` — used by the show/hide button on private-key fields.
    var isSecureTextEntryBinder: Binder<Bool> {
        Binder(self) {
            $0.isSecureTextEntry = $1
        }
    }
}
