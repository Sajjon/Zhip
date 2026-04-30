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
import Validation
import SingleLineControllerController
import SingleLineControllerSceneViews

// MARK: - RestoreWithKeystoreView

/// Sub-view of the RestoreWallet screen for the "I have a keystore JSON +
/// password" restore method. Owns its own view-model.
public final class RestoreUsingKeystoreView: ScrollableStackViewOwner {
    typealias ViewModel = RestoreWalletUsingKeystoreViewModel

    /// Subscription bag for the view-model bindings.
    private var cancellables = Set<AnyCancellable>()

    /// Text view for pasted keystore JSON.
    private lazy var keystoreTextView = UITextView()
    /// Encryption password field (the password the keystore was encrypted with).
    private lazy var encryptionPasswordField = FloatingLabelTextField()

    /// Owned view-model — wires keystore + password publishers into validation
    /// streams and a `KeyRestoration` payload the parent surfaces upstream.
    private lazy var viewModel = ViewModel(
        inputFromView: ViewModel.InputFromView(
            keystoreDidBeginEditing: keystoreTextView.didBeginEditingPublisher,
            isEditingKeystore: keystoreTextView.isEditingPublisher,
            keystoreText: keystoreTextView.textPublisher.orEmpty.removeDuplicates().eraseToAnyPublisher(),
            encryptionPassword: encryptionPasswordField.textPublisher.orEmpty.removeDuplicates().eraseToAnyPublisher(),
            isEditingEncryptionPassword: encryptionPasswordField.isEditingPublisher
        )
    )

    /// Re-exported view-model output — the parent `RestoreWalletView` reads
    /// `keyRestoration` from here to build its own `inputFromView`.
    lazy var viewModelOutput = viewModel.output

    /// Vertical layout: keystore textview, password field.
    public lazy var stackViewStyle: UIStackView.Style = [
        keystoreTextView,
        encryptionPasswordField,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling + bindings.
    public override func setup() {
        setupSubviews()
        setupViewModelBinding()
    }

    /// Used by the parent's composite "wrong password" binder to flip the
    /// password field's validation state externally.
    func restorationErrorValidation(_ validation: AnyValidation) {
        encryptionPasswordField.applyValidation(validation)
    }
}

private extension RestoreUsingKeystoreView {
    /// Styling pass — secure password field, editable keystore textview with
    /// neutral-grey border (re-bordered by the validation binder).
    func setupSubviews() {
        encryptionPasswordField.withStyle(.password)
        keystoreTextView.withStyle(.editable)
        keystoreTextView.addBorderBy(validation: .empty)
    }

    /// Binds the four view-model outputs (keystore validation border, password
    /// validation, dynamic placeholders) into their respective fields.
    func setupViewModelBinding() {
        [
            viewModelOutput.keyRestorationValidation --> keystoreTextView.validationBorderBinder,
            viewModelOutput.encryptionPasswordValidation --> encryptionPasswordField.validationBinder,
            viewModelOutput.keystoreTextFieldPlaceholder --> keystoreTextView.textBinder,
            viewModelOutput.encryptionPasswordPlaceholder --> encryptionPasswordField.placeholderBinder,
        ].forEach { $0.store(in: &cancellables) }
    }
}

extension UITextView {
    /// Binder that paints the textview's border according to an `AnyValidation`
    /// (teal/red/grey) — the textview equivalent of `FloatingLabelTextField.validationBinder`.
    var validationBorderBinder: Binder<AnyValidation> {
        Binder(self) {
            $0.addBorderBy(validation: $1)
        }
    }
}

extension UITextView {
    /// Maps an `AnyValidation` to a `UIView.Border` and applies it. Color
    /// derives from `AnyValidation.Color` (teal/red/grey).
    func addBorderBy(validation: AnyValidation) {
        addBorder(UIView.Border.fromValidation(validation))
    }
}
