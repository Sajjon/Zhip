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

/// Password-entry screen that decrypts the keystore to reveal the underlying
/// `KeyPair` (private key + address). One field, one CTA.
public final class DecryptKeystoreToRevealKeyPairView: ScrollableStackViewOwner {
    /// "Enter your password to reveal" body label.
    private lazy var decryptToRevealLabel = UILabel()
    /// Password field — secure entry, validated against the wallet's keystore.
    private lazy var encryptionPasswordField = FloatingLabelTextField()
    /// "Reveal" CTA — shows a spinner while the (CPU-intensive) decryption runs.
    private lazy var revealButton = ButtonWithSpinner()

    /// Vertical layout: label, field, spacer, CTA.
    public lazy var stackViewStyle = UIStackView.Style([
        decryptToRevealLabel,
        encryptionPasswordField,
        .spacer,
        revealButton,
    ], spacing: 20)

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override public func setup() {
        setupSubviews()
    }
}

extension DecryptKeystoreToRevealKeyPairView: ViewModelled {
    public typealias ViewModel = DecryptKeystoreToRevealKeyPairViewModel

    /// Binds validation feedback (color + remark), button loading spinner,
    /// and button enabled state to the password field + reveal button.
    public func populate(with publishers: ViewModel.Publishers) -> [AnyCancellable] {
        [
            publishers.encryptionPasswordValidation --> encryptionPasswordField.validationBinder,
            publishers.isRevealButtonLoading --> revealButton.isLoadingBinder,
            publishers.isRevealButtonEnabled --> revealButton.isEnabledBinder,
        ]
    }

    /// Surfaces the password text, the editing-state, and the reveal-button tap.
    public var inputFromView: InputFromView {
        InputFromView(
            encryptionPassword: encryptionPasswordField.textPublisher.orEmpty,
            isEditingEncryptionPassword: encryptionPasswordField.isEditingPublisher,
            revealTrigger: revealButton.tapPublisher
        )
    }
}

private extension DecryptKeystoreToRevealKeyPairView {
    /// Styling pass — body label, secure password field, primary reveal button.
    func setupSubviews() {
        decryptToRevealLabel.withStyle(.body) {
            $0.text(String(localized: .DecryptKeystore.decryptToReveal))
        }

        encryptionPasswordField.withStyle(.password) {
            $0.placeholder(String(localized: .DecryptKeystore.encryptionPassword))
        }

        revealButton.withStyle(.primary) {
            $0.title(String(localized: .DecryptKeystore.reveal))
                .disabled()
        }
    }
}
