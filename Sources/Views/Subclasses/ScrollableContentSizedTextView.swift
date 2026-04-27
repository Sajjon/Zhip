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

import SingleLineControllerCore
import UIKit

/// `UITextView` subclass that reports its `contentSize.height` as its
/// `intrinsicContentSize.height` so the surrounding stack view can size it
/// correctly without a hard-coded height.
///
/// The default `UITextView` always reports `noIntrinsicMetric` for height,
/// which forces parents to either give it an explicit constraint or leave it
/// scrolled. This subclass invalidates intrinsic size whenever the content
/// changes, letting Auto Layout grow the field naturally — useful for
/// long-form static copy (legal text, ECC warnings).
final class ScrollableContentSizedTextView: UITextView {
    /// Programmatic init.
    init() {
        super.init(frame: .zero, textContainer: nil)
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Invalidate intrinsic size whenever the text engine reports a new
    /// content size — triggers Auto Layout to ask for our new
    /// `intrinsicContentSize` and re-lay out the parent.
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    /// Width is left to Auto Layout; height tracks `contentSize.height`.
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
