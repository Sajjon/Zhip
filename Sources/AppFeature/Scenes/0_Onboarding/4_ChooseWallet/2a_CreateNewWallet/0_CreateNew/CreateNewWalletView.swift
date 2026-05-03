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
import NanoViewControllerCombine
import NanoViewControllerController
import NanoViewControllerSceneViews
import NanoViewControllerCore
import UIKit

/// The "create new wallet" screen view — collects an encryption password (twice),
/// requires the user to acknowledge they have backed it up, and exposes a continue button.
///
/// This view is purely presentational: it owns its UIKit subviews and exposes
/// `inputFromView` (user interactions) and `populate(with:)` (output bindings) so that
/// `CreateNewWalletViewModel` can drive it through the project's reactive MVVM pattern.
public final class CreateNewWalletView: ScrollableStackViewOwner {
    /// "Choose a new password" title shown at the top of the screen.
    private lazy var headerLabel = UILabel()
    /// Body copy underneath the header explaining what the password protects.
    private lazy var subtitleLabel = UILabel()
    /// Primary password text field (secure entry).
    private lazy var encryptionPasswordField = FloatingLabelTextField()
    /// Confirmation password text field (secure entry); must match the primary field.
    private lazy var confirmEncryptionPasswordField = FloatingLabelTextField()
    /// Acknowledgement checkbox — must be checked before the continue button enables.
    /// Forces the user to assert they have backed up the password (which is unrecoverable).
    private lazy var haveBackedUpPasswordCheckbox = CheckboxWithLabel()
    /// Primary call-to-action button. Shows a spinner while wallet derivation is in flight.
    private lazy var continueButton = ButtonWithSpinner()

    // MARK: - StackViewStyling

    /// Vertical layout consumed by `ScrollableStackViewOwner`.
    ///
    /// `.spacer` between the password fields and the checkbox pushes the action elements
    /// to the bottom of the visible area on tall screens.
    public lazy var stackViewStyle: UIStackView.Style = [
        headerLabel,
        subtitleLabel,
        encryptionPasswordField,
        confirmEncryptionPasswordField,
        .spacer,
        haveBackedUpPasswordCheckbox,
        continueButton,
    ]

    /// `ScrollableStackViewOwner` lifecycle hook — invoked once after the stack view is composed.
    /// Forwarded to `setupSubviews()` to apply per-subview styling and localized text.
    override public func setup() {
        setupSubviews()
    }
}

// MARK: - ViewModelled

extension CreateNewWalletView: ViewModelled {
    /// Concrete view-model type the project's `SceneController` will instantiate and bind.
    public typealias ViewModel = CreateNewWalletViewModel

    /// Binds each of the view-model's `Output` publishers to the corresponding UI binder.
    ///
    /// The returned cancellables are owned by the `SceneController` for the screen's lifetime;
    /// returning them (rather than `.store(in:)`-ing here) keeps lifecycle ownership in one place.
    public func populate(with output: ViewModel.Output) -> [AnyCancellable] {
        [
            output.encryptionPasswordPlaceholder --> encryptionPasswordField.placeholderBinder,
            output.encryptionPasswordValidation --> encryptionPasswordField.validationBinder,
            output.confirmEncryptionPasswordValidation --> confirmEncryptionPasswordField.validationBinder,
            output.isContinueButtonEnabled --> continueButton.isEnabledBinder,
            output.isButtonLoading --> continueButton.isLoadingBinder,
        ]
    }

    /// Snapshots the current set of user-interaction publishers into the view-model's
    /// `InputFromView` struct.
    ///
    /// Note: `textPublisher.orEmpty` lifts `String?` to `String` (a `nil` value from
    /// `UITextField.text` is treated as an empty string for validation purposes).
    public var inputFromView: InputFromView {
        InputFromView(
            newEncryptionPassword: encryptionPasswordField.textPublisher.orEmpty,
            isEditingNewEncryptionPassword: encryptionPasswordField.isEditingPublisher,

            confirmedNewEncryptionPassword: confirmEncryptionPasswordField.textPublisher.orEmpty,
            isEditingConfirmedEncryptionPassword: confirmEncryptionPasswordField.isEditingPublisher,
            isHaveBackedUpPasswordCheckboxChecked: haveBackedUpPasswordCheckbox.isCheckedPublisher,
            createWalletTrigger: continueButton.tapPublisher
        )
    }
}

private extension CreateNewWalletView {
    /// Applies fixed (non-reactive) styling and localized text to each subview.
    ///
    /// Anything that *changes* at runtime (placeholder with the minimum-length number,
    /// validation state, button enablement, spinner state) is delivered reactively
    /// through `populate(with:)` instead of being set here.
    func setupSubviews() {
        headerLabel.withStyle(.header) {
            $0.text(String(localized: .CreateNewWallet.chooseNewPasswordTitle))
        }

        subtitleLabel.withStyle(.body) {
            $0.text(String(localized: .CreateNewWallet.chooseNewPasswordValue))
        }

        // Primary password field's placeholder is set reactively (it embeds the
        // minimum-length number), so only the secure-entry styling is applied here.
        encryptionPasswordField.withStyle(.password)

        confirmEncryptionPasswordField.withStyle(.password) {
            $0.placeholder(String(localized: .CreateNewWallet.confirmEncryptionPassword))
        }

        haveBackedUpPasswordCheckbox.withStyle(.default) {
            $0.text(String(localized: .CreateNewWallet.passwordIsBackedUp))
        }

        // Start disabled so the user cannot tap before validation has emitted at least
        // once; the reactive `isContinueButtonEnabled` binding takes over from there.
        continueButton.withStyle(.primary) {
            $0.title(String(localized: .CreateNewWallet.continueButton))
                .disabled()
        }
    }
}
