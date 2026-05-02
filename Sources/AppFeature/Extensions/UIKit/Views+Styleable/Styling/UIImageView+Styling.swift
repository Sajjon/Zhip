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

import UIKit

// Same Style/Apply/Customizing/Presets shape as `UILabel+Styling.swift`.
// See that file for the canonical doc walkthrough.

public extension UIImageView {
    /// Optional-keypath assignment helper — see `UIButton.setOptional(_:ifNotNil:)`.
    func setOptional<Attribute>(
        _ keyPath: ReferenceWritableKeyPath<UIImageView, Attribute?>,
        ifNotNil attribute: Attribute?
    ) {
        guard let attribute else { return }
        self[keyPath: keyPath] = attribute
    }

    /// Non-optional-keypath assignment helper — same semantics as `setOptional`.
    func set<Attribute>(_ keyPath: ReferenceWritableKeyPath<UIImageView, Attribute>, ifNotNil attribute: Attribute?) {
        guard let attribute else { return }
        self[keyPath: keyPath] = attribute
    }
}

// MARK: - Style

public extension UIImageView {
    /// Description of an image view's appearance — image, tint, content mode,
    /// clipping, and background colour.
    struct Style {
        public var image: UIImage?
        public var tintColor: UIColor?
        public var backgroundColor: UIColor?
        public var contentMode: UIView.ContentMode?
        public var clipsToBounds: Bool?

        /// Memberwise initialiser. Note: `backgroundColor` parameter is
        /// currently unused (typo — `_` underscored) but the *property* is
        /// still settable via the chainable `backgroundColor(_:)` mutator.
        public init(
            image: UIImage? = nil,
            contentMode: UIView.ContentMode? = nil,
            clipsToBounds: Bool? = nil,
            tintColor: UIColor? = nil,
            backgroundColor _: UIColor? = nil
        ) {
            self.image = image
            self.contentMode = contentMode
            self.clipsToBounds = clipsToBounds
            self.tintColor = tintColor
        }
    }
}

// MARK: - Apply Style

public extension UIImageView {
    /// Writes `style` to this image view, leaving any nil attribute untouched
    /// (so existing values persist when the style is partial).
    func apply(style: Style) {
        set(\.image, ifNotNil: style.image)
        set(\.contentMode, ifNotNil: style.contentMode)
        set(\.clipsToBounds, ifNotNil: style.clipsToBounds)
        set(\.tintColor, ifNotNil: style.tintColor)
        set(\.backgroundColor, ifNotNil: style.backgroundColor)
    }

    /// Apply `style` (optionally customised) and return `self`.
    /// See `UILabel.withStyle(_:customize:)` for the canonical pattern.
    @discardableResult
    func withStyle(
        _ style: UIImageView.Style,
        customize: ((UIImageView.Style) -> UIImageView.Style)? = nil
    ) -> UIImageView {
        translatesAutoresizingMaskIntoConstraints = false
        let style = customize?(style) ?? style
        apply(style: style)
        return self
    }
}

// MARK: - Style + Customizing

// Single-field replacement mutators. See UILabel+Styling.swift for the pattern.

public extension UIImageView.Style {
    /// Returns a copy with `image` replaced.
    @discardableResult
    func image(_ image: UIImage?) -> UIImageView.Style {
        var style = self
        style.image = image
        return style
    }

    /// Returns a copy with `contentMode` replaced.
    @discardableResult
    func contentMode(_ contentMode: UIView.ContentMode?) -> UIImageView.Style {
        var style = self
        style.contentMode = contentMode
        return style
    }

    /// Returns a copy with `backgroundColor` replaced.
    @discardableResult
    func backgroundColor(_ backgroundColor: UIColor) -> UIImageView.Style {
        var style = self
        style.backgroundColor = backgroundColor
        return style
    }
}

// MARK: - Style Presets

extension UIImageView.Style {
    /// Default — aspect-fit + clip. Used for in-content images that should
    /// preserve their aspect ratio inside a fixed frame.
    public static var `default`: UIImageView.Style {
        UIImageView.Style(
            contentMode: .scaleAspectFit,
            clipsToBounds: true
        )
    }

    /// Preset for a background image used in `UIView+MotionEffect` layered
    /// parallax: centred, no clipping, transparent background.
    static func background(image: UIImage) -> UIImageView.Style {
        .init(image: image, contentMode: .center, backgroundColor: .clear)
    }
}
