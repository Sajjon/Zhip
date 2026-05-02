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

import NanoViewControllerCore
import UIKit

/// `UIButton` subclass that arranges an image **above** a label, instead of
/// `UIButton`'s built-in side-by-side layout. Used on the wallet-choice screen
/// (large icon over a label).
///
/// We can't use `UIButton`'s built-in `imageView`/`titleLabel` because their
/// auto-layout behaviour doesn't support vertical stacking. Instead we host
/// our own `UIImageView` + `UILabel` inside a stack view and `assert` that
/// the inherited slots are unused — see `layoutSubviews()`.
public final class ImageAboveLabelButton: UIButton {
    /// Custom label that replaces the inherited `titleLabel`.
    private lazy var customLabel = UILabel()
    /// Custom image view that replaces the inherited `imageView`.
    private lazy var customImageView = UIImageView()
    /// Vertical stack composing image + label.
    private lazy var stackView = UIStackView(arrangedSubviews: [customImageView, customLabel])

    /// Programmatic init.
    init() {
        super.init(frame: .zero)
        setup()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Make sure that we are not using the inbuilt label and imageview
    /// Asserts that the inherited UIButton title/image slots stay empty (they'd
    /// fight our stack view's layout) and that `setTitle(_:image:)` was called
    /// to populate the custom views.
    override public func layoutSubviews() {
        super.layoutSubviews()
        assert(titleLabel?.text == nil, "You should not use the default `titleLabel`, but rather `customLabel` view")
        assert(imageView?.image == nil, "You should not use the default `titleLabel`, but rather `customLabel` view")
        assert(customLabel.text != nil, "call `setTitle:image`")
        assert(customImageView.image != nil, "call `setTitle:image`")
    }
}

// MARK: - Internal

extension ImageAboveLabelButton {
    /// Single entry point for content. Setting title and image together makes
    /// the "both must be set" invariant easier to satisfy than two separate
    /// methods would.
    func setTitle(_ title: String, image: UIImage) {
        customLabel.withStyle(
            .init(
                text: title,
                textAlignment: .center,
                textColor: .white,
                font: UIFont.callToAction,
                numberOfLines: 1,
                backgroundColor: .clear
            )
        )

        customImageView.withStyle(.default) {
            $0.image(image).contentMode(.center)
        }
    }
}

// MARK: - Accessibility

// Forward all VoiceOver attributes to `customLabel` since the inherited
// `titleLabel` is intentionally unused. Without these overrides, VoiceOver
// would announce nothing because the system reads from the (empty) inherited
// label rather than our custom one.

public extension ImageAboveLabelButton {
    /// Forward to `customLabel` — see header comment.
    override var accessibilityLabel: String? {
        get { customLabel.accessibilityLabel }
        set { customLabel.accessibilityLabel = newValue }
    }

    /// Forward to `customLabel` — see header comment.
    override var accessibilityHint: String? {
        get { customLabel.accessibilityHint }
        set { customLabel.accessibilityHint = newValue }
    }

    /// Forward to `customLabel` — see header comment.
    override var accessibilityValue: String? {
        get { customLabel.accessibilityValue }
        set { customLabel.accessibilityValue = newValue }
    }
}

// MARK: - Private Setup

private extension ImageAboveLabelButton {
    /// Applies the primary button styling (without a fixed height — content
    /// drives sizing here), seats the stack view, and disables interaction
    /// on the inner views so taps route through the button itself.
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        withStyle(.primary) {
            $0.height(nil)
        }
        addSubview(stackView)
        stackView.edgesToSuperview()
        stackView.withStyle(.default) {
            $0.layoutMargins(UIEdgeInsets(top: 30, bottom: 20)).spacing(30)
        }

        [stackView, customLabel, customImageView].forEach { $0.isUserInteractionEnabled = false }
    }
}
