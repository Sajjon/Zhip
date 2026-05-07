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

/// Keystore-reveal screen — pretty-printed JSON in a non-editable text view
/// plus a "Copy keystore" button.
public final class BackUpKeystoreView: ScrollableStackViewOwner {
    /// Read-only display of the pretty-printed keystore JSON.
    private lazy var keystoreTextView = UITextView()
    /// Copies the keystore JSON to the system pasteboard.
    private lazy var copyButton = UIButton()

    /// Vertical layout: text view on top, copy button below.
    public lazy var stackViewStyle: UIStackView.Style = [
        keystoreTextView,
        copyButton,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override public func setup() {
        setupSubviews()
    }
}

extension BackUpKeystoreView: ViewModelled {
    public typealias ViewModel = BackUpKeystoreViewModel

    /// Routes the JSON-encoded keystore string into the text view.
    public func populate(with viewModel: BackUpKeystoreViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.keystore --> keystoreTextView.textBinder,
        ]
    }

    /// Surfaces only the copy-button tap.
    public var inputFromView: InputFromView {
        InputFromView(
            copyTrigger: copyButton.tapPublisher
        )
    }
}

private extension BackUpKeystoreView {
    /// Styling pass — non-editable text view, primary copy button.
    func setupSubviews() {
        keystoreTextView.withStyle(.nonEditable) {
            $0.textAlignment(.left)
        }

        copyButton.withStyle(.primary) {
            $0.title(String(localized: .BackUpKeystore.copyKeystore))
        }
    }
}
