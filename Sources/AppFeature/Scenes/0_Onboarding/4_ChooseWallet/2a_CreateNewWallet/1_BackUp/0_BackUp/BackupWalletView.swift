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

/// Backup hub screen with two reveal options (private key / keystore) plus
/// a confirmation checkbox + done button (only shown in `.cancellable` mode).
public final class BackupWalletView: ScrollableStackViewOwner {
    /// "Back up your keys" header.
    private lazy var backUpLabel = UILabel()
    /// Body copy urging the user to record the keys safely.
    private lazy var urgeBackupLabel = UILabel()

    /// Private-key section label.
    private lazy var privateKeyLabel = UILabel()
    /// "Reveal" button — opens the password-gated reveal flow.
    private lazy var revealPrivateKeyButton = UIButton()
    /// Horizontal container around `revealPrivateKeyButton` so it doesn't fill width.
    private lazy var privateKeyButtonContainer = UIStackView(arrangedSubviews: [revealPrivateKeyButton, .spacer])
    /// Vertical group: label + button row.
    private lazy var privateKeyViews = UIStackView(arrangedSubviews: [privateKeyLabel, privateKeyButtonContainer])

    /// Keystore section label.
    private lazy var keystoreLabel = UILabel()
    /// Copies the keystore JSON to the pasteboard (and surfaces a toast).
    private lazy var copyKeystoreButton = UIButton()
    /// Opens the keystore-reveal modal.
    private lazy var revealKeystoreButton = UIButton()
    /// Horizontal pair of keystore buttons.
    private lazy var keystoreButtons = UIStackView(arrangedSubviews: [
        revealKeystoreButton,
        copyKeystoreButton,
        .spacer,
    ])
    /// Vertical group: label + button row.
    private lazy var keystoreViews = UIStackView(arrangedSubviews: [keystoreLabel, keystoreButtons])

    /// "I have securely backed up" — must be checked to enable Done.
    private lazy var haveSecurelyBackedUpCheckbox = CheckboxWithLabel()
    /// "Done" CTA — only visible in `.cancellable` mode (post-create context).
    private lazy var doneButton = UIButton()
    /// Vertical group hidden in `.dismissable` (Settings) mode.
    private lazy var haveSecurelyBackedUpViews = UIStackView(arrangedSubviews: [
        haveSecurelyBackedUpCheckbox,
        doneButton,
    ])

    // MARK: - StackViewStyling

    /// Vertical layout: header, body, key reveal sections, spacer, confirm group.
    public lazy var stackViewStyle: UIStackView.Style = [
        backUpLabel,
        urgeBackupLabel,
        privateKeyViews,
        keystoreViews,
        .spacer,
        haveSecurelyBackedUpViews,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override public func setup() {
        setupSubviews()
    }
}

extension BackupWalletView: ViewModelled {
    public typealias ViewModel = BackupWalletViewModel

    /// Binds visibility (Settings mode hides the confirm group) and the
    /// done-button enabled state (gated on the checkbox).
    public func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.isHaveSecurelyBackedUpViewsVisible --> haveSecurelyBackedUpViews.isVisibleBinder,
            viewModel.isDoneButtonEnabled --> doneButton.isEnabledBinder,
        ]
    }

    /// Surfaces all five user actions: copy keystore, reveal keystore,
    /// reveal private key, checkbox toggles, and done tap.
    public var inputFromView: InputFromView {
        InputFromView(
            copyKeystoreToPasteboardTrigger: copyKeystoreButton.tapPublisher,
            revealKeystoreTrigger: revealKeystoreButton.tapPublisher,
            revealPrivateKeyTrigger: revealPrivateKeyButton.tapPublisher,
            isUnderstandsRiskCheckboxChecked: haveSecurelyBackedUpCheckbox.isCheckedPublisher,
            doneTrigger: doneButton.tapPublisher
        )
    }
}

private extension BackupWalletView {
    /// Styling pass — sets all labels, buttons, and stack-view orientations.
    /// All three button widths are pinned to 136pt so they line up across rows.
    func setupSubviews() {
        backUpLabel.withStyle(.header) {
            $0.text(String(localized: .BackupWallet.backUpKeys))
        }

        urgeBackupLabel.withStyle(.body) {
            $0.text(String(localized: .BackupWallet.urgeBackup))
        }

        privateKeyLabel.withStyle(.checkbox) {
            $0.text(String(localized: .BackupWallet.privateKeyLabel))
        }

        revealPrivateKeyButton.withStyle(.hollow) {
            $0.title(String(localized: .BackupWallet.reveal))
        }

        privateKeyButtonContainer.withStyle(.horizontal)

        privateKeyViews.withStyle(.vertical)

        keystoreLabel.withStyle(.checkbox) {
            $0.text(String(localized: .BackupWallet.keystoreLabel))
        }

        copyKeystoreButton.withStyle(.hollow) {
            $0.title(String(localized: .BackupWallet.copy))
        }

        revealKeystoreButton.withStyle(.hollow) {
            $0.title(String(localized: .BackupWallet.reveal))
        }

        keystoreButtons.withStyle(.horizontal)

        keystoreViews.withStyle(.vertical)

        haveSecurelyBackedUpViews.withStyle(.vertical)

        haveSecurelyBackedUpCheckbox.withStyle(.default) {
            $0.text(String(localized: .BackupWallet.haveSecurelyBackedUp))
        }

        for item in [copyKeystoreButton, revealKeystoreButton, revealPrivateKeyButton] {
            item.width(136)
        }

        doneButton.withStyle(.primary) {
            $0.title(String(localized: .BackupWallet.done))
                .disabled()
        }
    }
}
