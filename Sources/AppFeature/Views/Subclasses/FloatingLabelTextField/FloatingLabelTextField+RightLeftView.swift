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

import UIKit

extension FloatingLabelTextField {
    /// Which accessory slot a view is being installed into.
    enum Position {
        /// Trailing accessory (`rightView`).
        case right
        /// Leading accessory (`leftView`).
        case left
    }

    /// Installs an image button as a bottom-aligned accessory. Returns the
    /// constructed button so the caller can wire up tap handling.
    /// - Parameters:
    ///   - image: Glyph to render inside the button.
    ///   - position: `.right` (default) or `.left`.
    ///   - yOffset: Additional pixels to push the button up from the bottom edge.
    ///   - mode: When the accessory is visible — defaults to `.always`.
    func addBottomAlignedButton(
        image: UIImage,
        position: Position = .right,
        yOffset: CGFloat = 0,
        mode: UITextField.ViewMode = .always
    ) -> UIButton {
        addBottomAlignedButton(imageOrText: .image(image), position: position, yOffset: yOffset, mode: mode)
    }

    /// Same as the image variant but for a text-only button (e.g. "Paste").
    func addBottomAlignedButton(
        titled: String,
        position: Position = .right,
        yOffset: CGFloat = 0,
        mode: UITextField.ViewMode = .always
    ) -> UIButton {
        addBottomAlignedButton(imageOrText: .text(titled), position: position, yOffset: yOffset, mode: mode)
    }

    /// Internal worker shared by the image/text overloads. Builds a button,
    /// styles it appropriately for its content type, and forwards layout to
    /// `addBottomAligned(view:…)`. iOS 15+ uses `UIButton.Configuration`
    /// (the modern way to set content insets); older OSes fall back to the
    /// deprecated `contentEdgeInsets`.
    private func addBottomAlignedButton(
        imageOrText: ImageOrText,
        position: Position = .right,
        yOffset: CGFloat = 0,
        mode: UITextField.ViewMode = .always
    ) -> UIButton {
        let button = UIButton()
        var width: CGFloat?
        switch imageOrText {
        case let .image(image):
            button.withStyle(.image(image))
            // Use UIButton.Configuration on iOS 15+; fall back to contentEdgeInsets on earlier versions
            if #available(iOS 15.0, *) {
                var config = button.configuration ?? .plain()
                config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                button.configuration = config
            } else {
                button.contentEdgeInsets = .init(all: 10)
            }
            width = image.size.width
        case let .text(title):
            button.withStyle(.title(title))
            width = button.widthOfTitle()
        }

        button.setContentHuggingPriority(.required, for: .vertical)

        addBottomAligned(view: button, position: position, width: width, yOffset: yOffset, mode: mode)

        return button
    }

    /// Lower-level positioning primitive — installs an arbitrary `view` as
    /// either the leading or trailing accessory, bottom-aligned (so it lines
    /// up with the input baseline rather than the floating-label area above it).
    /// A wrapper container view is used so the supplied `view` can be sized
    /// independently from the text field's accessory rect.
    func addBottomAligned(
        view: UIView,
        position: Position = .right,
        width: CGFloat? = nil,
        yOffset: CGFloat = 0,
        mode: UITextField.ViewMode = .always
    ) {
        view.translatesAutoresizingMaskIntoConstraints = true
        let bottomAligningContainerView = UIView()
        let width = width ?? FloatingLabelTextField.rightViewWidth
        let height: CGFloat = 40
        let y: CGFloat = FloatingLabelTextField.textFieldHeight - height - yOffset
        view.frame = CGRect(x: 0, y: y, width: width, height: height)
        bottomAligningContainerView.addSubview(view)

        switch position {
        case .left:
            leftView = bottomAligningContainerView
            leftViewMode = mode
        case .right:
            rightView = bottomAligningContainerView
            rightViewMode = mode
        }
    }
}
