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
import Factory
import Foundation
import SingleLineControllerCombine
import UIKit
import WebKit

/// Scrollable Terms of Service screen with a "must scroll to bottom" gate
/// before the accept button enables.
final class TermsOfServiceView: ScrollableStackViewOwner {
    /// Hero analytics illustration at the top.
    private lazy var imageView = UIImageView()
    /// "Terms of Service" header.
    private lazy var headerLabel = UILabel()
    /// Renders the localized HTML (loaded via `Container.shared.htmlLoader`).
    private lazy var textView = UITextView()
    /// Bottom CTA — disabled until the user has scrolled the textView near the bottom.
    private lazy var acceptTermsButton = UIButton()

    // MARK: - StackViewStyling

    /// Stack of the four subviews above, in vertical order.
    lazy var stackViewStyle: UIStackView.Style = [
        imageView,
        headerLabel,
        textView,
        acceptTermsButton,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override func setup() {
        setupSubviews()
    }
}

extension TermsOfServiceView: ViewModelled {
    typealias ViewModel = TermsOfServiceViewModel

    /// Binds the view-model's two `Output` publishers to the accept button's visibility and enabled state.
    func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.isAcceptButtonVisible --> acceptTermsButton.isVisibleBinder,
            viewModel.isAcceptButtonEnabled --> acceptTermsButton.isEnabledBinder,
        ]
    }

    /// Surfaces "did scroll to bottom" (used to enable the accept button) and
    /// "did accept terms" (used to record acceptance and advance the flow).
    var inputFromView: InputFromView {
        InputFromView(
            didScrollToBottom: textView.didScrollNearBottomPublisher(),
            didAcceptTerms: acceptTermsButton.tapPublisher
        )
    }
}

private extension TermsOfServiceView {
    /// Styling pass — sets the hero image, header text, accept button (disabled
    /// initially) and loads the Terms HTML through the injected `HtmlLoader` so
    /// tests can substitute a stub.
    func setupSubviews() {
        imageView.withStyle(.default) {
            $0.image(UIImage(resource: .analyticsLarge))
        }

        headerLabel.withStyle(.header) {
            $0.text(String(localized: .TermsOfService.termsOfServiceLabel))
        }

        acceptTermsButton.withStyle(.primary) {
            $0.title(String(localized: .TermsOfService.accept))
                .disabled()
        }

        textView.withStyle(.nonSelectable)
        textView.backgroundColor = .clear
        textView.attributedText = Container.shared.htmlLoader().load(htmlFileName: "TermsOfService")
    }
}
