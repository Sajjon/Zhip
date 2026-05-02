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

import NanoViewControllerCombine
import NanoViewControllerController
import NanoViewControllerSceneViews
import UIKit

/// "Make sure you're alone" privacy gate shown right before the user is asked
/// to commit to a fresh wallet password. Has a single CTA — "I understand".
public final class EnsureThatYouAreNotBeingWatchedView: ScrollableStackViewOwner {
    /// Hero shield illustration.
    private lazy var imageView = UIImageView()
    /// "Security" header.
    private lazy var headerLabel = UILabel()
    /// Body copy explaining "make sure no one is looking over your shoulder".
    private lazy var makeSureAloneLabel = UILabel()
    /// "I understand" CTA — only input on the screen.
    private lazy var understandButton = UIButton()

    /// Vertical layout: hero, header, body, spacer pushing CTA to the bottom.
    public lazy var stackViewStyle: UIStackView.Style = [
        imageView,
        headerLabel,
        makeSureAloneLabel,
        .spacer,
        understandButton,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override public func setup() {
        setupSubviews()
    }
}

extension EnsureThatYouAreNotBeingWatchedView: ViewModelled {
    public typealias ViewModel = EnsureThatYouAreNotBeingWatchedViewModel

    /// Surfaces the single "understand" tap.
    public var inputFromView: InputFromView {
        InputFromView(
            understandTrigger: understandButton.tapPublisher
        )
    }
}

private extension EnsureThatYouAreNotBeingWatchedView {
    /// Styling pass — sets the shield hero, header, body and primary CTA.
    func setupSubviews() {
        imageView.withStyle(.default) {
            $0.image(UIImage(resource: .shield))
        }

        headerLabel.withStyle(.header) {
            $0.text(String(localized: .EnsurePrivacy.security))
        }

        makeSureAloneLabel.withStyle(.body) {
            $0.text(String(localized: .EnsurePrivacy.makeSureAlone))
        }

        understandButton.withStyle(.primary) {
            $0.title(String(localized: .EnsurePrivacy.understand))
        }
    }
}
