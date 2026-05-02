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

// The styling system at a glance:
//   1. `Style` is a value-type description of which attributes a label should have.
//      Every attribute is *optional* so a style can describe "text only" or "font
//      only" without having to specify every attribute.
//   2. `apply(style:)` writes the style to a label, falling back to project-wide
//      defaults for any nil attribute.
//   3. `withStyle(_:customize:)` is the call-site sugar — apply a preset and
//      optionally customise individual attributes inline.
//   4. The chainable mutators (`text`, `font`, …) return a copy so call sites
//      can compose declaratively (`.body.text("Hi").textColor(.red)`).
//   5. `Mergeable` lets two styles be combined (preset + override).
// The exact same pattern repeats for `UIButton`, `UIStackView`, `UIImageView`,
// `UITextView`, and `FloatingLabelTextField` — see those siblings for the
// concrete shape.

// MARK: - Style

public extension UILabel {
    /// Description of how a `UILabel` should be styled. Every attribute is optional;
    /// `apply(style:)` substitutes project-wide defaults for any nil.
    struct Style: Mergeable {
        /// Initial text, if any.
        public var text: String?
        /// Foreground colour. Defaults to `.defaultText` (white) when nil.
        public var textColor: UIColor?
        /// Horizontal alignment. Defaults to `.left` when nil.
        public var textAlignment: NSTextAlignment?
        /// Font face. Defaults to `UIFont.Label.body` when nil.
        public var font: UIFont?
        /// Maximum number of lines. Defaults to 1 (single-line) when nil.
        public var numberOfLines: Int?
        /// View backgroundColor. Defaults to `.clear` when nil.
        public let backgroundColor: UIColor?
        /// If non-nil, enables `adjustsFontSizeToFitWidth` and uses this as the
        /// `minimumScaleFactor`. Lets long titles shrink to fit on narrow screens.
        public var adjustsFontSizeMinimumScaleFactor: CGFloat?
        /// Memberwise initialiser — all parameters optional so call sites pass
        /// only the attributes they care about.
        public init(
            text: String? = nil,
            textAlignment: NSTextAlignment? = nil,
            textColor: UIColor? = nil,
            font: UIFont? = nil,
            numberOfLines: Int? = nil,
            backgroundColor: UIColor? = nil,
            adjustsFontSizeMinimumScaleFactor: CGFloat? = nil
        ) {
            self.text = text
            self.textColor = textColor
            self.textAlignment = textAlignment
            self.font = font
            self.numberOfLines = numberOfLines
            self.backgroundColor = backgroundColor
            self.adjustsFontSizeMinimumScaleFactor = adjustsFontSizeMinimumScaleFactor
        }
    }
}

// MARK: Apply Style

public extension UILabel {
    /// Writes `style` to this label, substituting project-wide defaults for any
    /// nil attribute. Mutates the receiver — for the chainable form use
    /// `withStyle(_:customize:)`.
    func apply(style: Style) {
        text = style.text
        font = style.font ?? UIFont.Label.body
        textColor = style.textColor ?? .defaultText
        numberOfLines = style.numberOfLines ?? 1
        textAlignment = style.textAlignment ?? .left
        backgroundColor = style.backgroundColor ?? .clear
        if let minimumScaleFactor = style.adjustsFontSizeMinimumScaleFactor {
            adjustsFontSizeToFitWidth = true
            self.minimumScaleFactor = minimumScaleFactor
        }
    }

    /// Idiomatic call-site form: apply `style`, optionally customised by
    /// `customize`. Also disables autoresizing-mask translation so the label
    /// is ready for Auto Layout. Returns `self` for fluent chaining.
    @discardableResult
    func withStyle(_ style: UILabel.Style, customize: ((UILabel.Style) -> UILabel.Style)? = nil) -> UILabel {
        translatesAutoresizingMaskIntoConstraints = false
        let style = customize?(style) ?? style
        apply(style: style)
        return self
    }
}

// MARK: - Style + Customizing

// The chainable mutators below all follow the same shape: copy, mutate one
// field, return. They make declarative styling read top-to-bottom at call sites
// like `.body.text("Hi").textColor(.red)`.

public extension UILabel.Style {
    /// Returns a copy of this style with `text` replaced.
    @discardableResult
    func text(_ text: String?) -> UILabel.Style {
        var style = self
        style.text = text
        return style
    }

    /// Returns a copy of this style with `font` replaced.
    @discardableResult
    func font(_ font: UIFont) -> UILabel.Style {
        var style = self
        style.font = font
        return style
    }

    /// Returns a copy of this style with `numberOfLines` replaced.
    /// Use `0` to allow unlimited (multi-line) text.
    @discardableResult
    func numberOfLines(_ numberOfLines: Int) -> UILabel.Style {
        var style = self
        style.numberOfLines = numberOfLines
        return style
    }

    /// Returns a copy of this style with `textAlignment` replaced.
    @discardableResult
    func textAlignment(_ textAlignment: NSTextAlignment) -> UILabel.Style {
        var style = self
        style.textAlignment = textAlignment
        return style
    }

    /// Returns a copy of this style with `textColor` replaced.
    @discardableResult
    func textColor(_ textColor: UIColor) -> UILabel.Style {
        var style = self
        style.textColor = textColor
        return style
    }

    /// Returns a copy of this style that auto-shrinks font size down to
    /// `minimumScaleFactor` to fit the available width.
    @discardableResult
    func minimumScaleFactor(_ minimumScaleFactor: CGFloat) -> UILabel.Style {
        var style = self
        style.adjustsFontSizeMinimumScaleFactor = minimumScaleFactor
        return style
    }
}

// MARK: - Style Presets

// Named presets the rest of the app references by name (`.header`, `.body`, …).
// Adding a new label role means adding a preset here, not configuring fonts at
// the call site.

public extension UILabel.Style {
    /// Hero/welcome label — large impression-scale font, single line.
    static var impression: UILabel.Style {
        UILabel.Style(
            font: UIFont.Label.impression
        )
    }

    /// Scene header — large bold font, multi-line allowed.
    static var header: UILabel.Style {
        UILabel.Style(
            font: UIFont.Label.header,
            numberOfLines: 0
        )
    }

    /// Title-weight label, single line.
    static var title: UILabel.Style {
        UILabel.Style(
            font: UIFont.title
        )
    }

    /// Body copy — regular weight, multi-line.
    static var body: UILabel.Style {
        UILabel.Style(
            font: UIFont.Label.body,
            numberOfLines: 0
        )
    }

    /// Checkbox label — same font as `.title`, multi-line for long copy.
    static var checkbox: UILabel.Style {
        UILabel.Style(
            font: UIFont.checkbox,
            numberOfLines: 0
        )
    }
}

// MARK: - Style + Merging

public extension UILabel.Style {
    /// `Mergeable` conformance — combines two styles attribute-by-attribute via
    /// the inner `merge(_:)` helper, which forwards to `mergeAttribute(other:path:mode:)`.
    /// Note: `text` and `adjustsFontSizeMinimumScaleFactor` are intentionally
    /// not merged here — they're considered per-instance overrides only.
    func merged(other: UILabel.Style, mode: MergeMode) -> UILabel.Style {
        func merge<T>(_ attributePath: KeyPath<UILabel.Style, T?>) -> T? {
            mergeAttribute(other: other, path: attributePath, mode: mode)
        }

        return UILabel.Style(
            textAlignment: merge(\.textAlignment),
            textColor: merge(\.textColor),
            font: merge(\.font),
            numberOfLines: merge(\.numberOfLines),
            backgroundColor: merge(\.backgroundColor)
        )
    }
}
