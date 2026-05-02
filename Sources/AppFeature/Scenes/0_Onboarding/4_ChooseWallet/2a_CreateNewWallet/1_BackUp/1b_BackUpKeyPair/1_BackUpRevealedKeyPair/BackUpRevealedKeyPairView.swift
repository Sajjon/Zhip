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

/// Reveals the user's private key + uncompressed public key in titled
/// `TitledValueView`s with copy-to-pasteboard buttons next to each.
public final class BackUpRevealedKeyPairView: ScrollableStackViewOwner {
    /// Title-value pair for the private key (hex string).
    private lazy var privateKeyTextView = TitledValueView()
    /// Title-value pair for the uncompressed public key (hex string).
    private lazy var publicKeyUncompressedTextView = TitledValueView()
    /// Copies the private key hex to the pasteboard.
    private lazy var copyPrivateKeyButton = UIButton()
    /// Horizontal container so the copy button doesn't fill width.
    private lazy var copyPrivateKeyButtonContainer = UIStackView(arrangedSubviews: [copyPrivateKeyButton, .spacer])
    /// Copies the uncompressed public key hex to the pasteboard.
    private lazy var copyUncompressedPublicKeyButton = UIButton()
    /// Horizontal container so the copy button doesn't fill width.
    private lazy var copyPublicKeyButtonContainer = UIStackView(arrangedSubviews: [
        copyUncompressedPublicKeyButton,
        .spacer,
    ])

    /// Vertical layout: private key title-value + copy, public key title-value + copy, spacer.
    public lazy var stackViewStyle: UIStackView.Style = [
        privateKeyTextView,
        copyPrivateKeyButtonContainer,
        publicKeyUncompressedTextView,
        copyPublicKeyButtonContainer,
        .spacer,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override public func setup() {
        setupSubviews()
    }
}

extension BackUpRevealedKeyPairView: ViewModelled {
    public typealias ViewModel = BackUpRevealedKeyPairViewModel

    /// Routes the private/public key strings into their respective titled views.
    public func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.privateKey --> privateKeyTextView.valueBinder,
            viewModel.publicKeyUncompressed --> publicKeyUncompressedTextView.valueBinder,
        ]
    }

    /// Surfaces the two copy-button taps.
    public var inputFromView: InputFromView {
        InputFromView(
            copyPrivateKeyTrigger: copyPrivateKeyButton.tapPublisher,
            copyPublicKeyTrigger: copyUncompressedPublicKeyButton.tapPublisher
        )
    }
}

private extension BackUpRevealedKeyPairView {
    /// Styling pass — labels both `TitledValueView`s, configures hollow-style copy
    /// buttons (pinned to 136pt to match other backup screens), and hugs the
    /// private-key view vertically so it doesn't expand.
    func setupSubviews() {
        privateKeyTextView.withStyles {
            $0.text(String(localized: .BackUpRevealedKeyPair.privateKeyLabel))
        }

        privateKeyTextView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        copyPrivateKeyButton.withStyle(.hollow) {
            $0.title(String(localized: .BackUpRevealedKeyPair.copy))
        }

        copyPrivateKeyButtonContainer.withStyle(.horizontal)

        publicKeyUncompressedTextView.withStyles {
            $0.text(String(localized: .BackUpRevealedKeyPair.uncompressedPublicKey))
        }

        copyUncompressedPublicKeyButton.withStyle(.hollow) {
            $0.title(String(localized: .BackUpRevealedKeyPair.copy))
        }

        copyPublicKeyButtonContainer.withStyle(.horizontal)

        for item in [copyPrivateKeyButton, copyUncompressedPublicKeyButton] {
            item.width(136)
        }
    }
}
