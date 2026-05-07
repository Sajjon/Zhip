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

// Same Style/Apply/Customizing/Presets/Mergeable shape as
// `UILabel+Styling.swift` — see that file for the canonical doc walkthrough.

// MARK: - Style

public extension UITextView {
    /// Description of a `UITextView`'s appearance and behavior — text, fonts,
    /// colours, and editability/selectability flags.
    struct Style {
        public var text: String?
        public var textAlignment: NSTextAlignment?
        public var textColor: UIColor?
        public var backgroundColor: UIColor?
        public var font: UIFont?
        public var isEditable: Bool?
        public var isSelectable: Bool?
        public var contentInset: UIEdgeInsets?
        public var isScrollEnabled: Bool?

        /// Memberwise initialiser. `height` is intentionally underscored — it
        /// was an unused historical parameter, kept in the signature for source
        /// compatibility but no longer assigned to any property.
        public init(
            text: String? = nil,
            textAlignment: NSTextAlignment? = nil,
            height _: CGFloat? = nil,
            font: UIFont? = nil,
            textColor: UIColor? = nil,
            backgroundColor: UIColor? = nil,
            isEditable: Bool? = nil,
            isSelectable: Bool? = nil,
            isScrollEnabled: Bool? = nil,
            contentInset: UIEdgeInsets? = nil
        ) {
            self.text = text
            self.textAlignment = textAlignment
            self.textColor = textColor
            self.font = font
            self.isEditable = isEditable
            self.isSelectable = isSelectable
            self.isScrollEnabled = isScrollEnabled
            self.contentInset = contentInset
            self.backgroundColor = backgroundColor
        }
    }
}

// MARK: Apply Style

public extension UITextView {
    /// Writes `style` to this text view, substituting project-wide defaults
    /// for any nil attribute (left-aligned body font, white text, transparent
    /// background, fully editable/selectable/scrollable by default).
    func apply(style: UITextView.Style) {
        text = style.text
        textAlignment = style.textAlignment ?? .left
        font = style.font ?? UIFont.body
        textColor = style.textColor ?? .defaultText
        backgroundColor = style.backgroundColor ?? .clear
        isEditable = style.isEditable ?? true
        isSelectable = style.isSelectable ?? true
        isScrollEnabled = style.isScrollEnabled ?? true
        contentInset = style.contentInset ?? UIEdgeInsets.zero
    }

    /// Apply `style` (optionally customised) and return `self`.
    @discardableResult
    func withStyle(
        _ style: UITextView.Style,
        customize: ((UITextView.Style) -> UITextView.Style)? = nil
    ) -> UITextView {
        translatesAutoresizingMaskIntoConstraints = false
        let style = customize?(style) ?? style
        apply(style: style)
        return self
    }
}

// MARK: - Style + Customizing

// Single-field replacement mutators. See UILabel+Styling.swift for the pattern.

public extension UITextView.Style {
    /// Returns a copy with `text` replaced.
    @discardableResult
    func text(_ text: String?) -> UITextView.Style {
        var style = self
        style.text = text
        return style
    }

    /// Returns a copy with `font` replaced.
    @discardableResult
    func font(_ font: UIFont) -> UITextView.Style {
        var style = self
        style.font = font
        return style
    }

    /// Returns a copy with `textAlignment` replaced.
    @discardableResult
    func textAlignment(_ textAlignment: NSTextAlignment) -> UITextView.Style {
        var style = self
        style.textAlignment = textAlignment
        return style
    }

    /// Returns a copy with `textColor` replaced.
    @discardableResult
    func textColor(_ textColor: UIColor) -> UITextView.Style {
        var style = self
        style.textColor = textColor
        return style
    }

    /// Returns a copy with `isSelectable` replaced.
    @discardableResult
    func isSelectable(_ isSelectable: Bool) -> UITextView.Style {
        var style = self
        style.isSelectable = isSelectable
        return style
    }

    /// Returns a copy with `isScrollEnabled` replaced.
    @discardableResult
    func isScrollEnabled(_ isScrollEnabled: Bool) -> UITextView.Style {
        var style = self
        style.isScrollEnabled = isScrollEnabled
        return style
    }
}

// MARK: - Style Presets

public extension UITextView.Style {
    /// Read-only display — text is selectable (so users can copy) but not
    /// editable. Used for legal/long-form copy.
    static var nonEditable: UITextView.Style {
        UITextView.Style(
            isEditable: false
        )
    }

    /// Pure display — neither editable nor selectable, centre-aligned. Used
    /// for short status labels rendered as text views (e.g. for inline links).
    static var nonSelectable: UITextView.Style {
        UITextView.Style(
            textAlignment: .center,
            isEditable: false,
            isSelectable: false
        )
    }

    /// Free-form input — fully editable.
    static var editable: UITextView.Style {
        UITextView.Style(
            isEditable: true
        )
    }

    /// Centred header text in the header font, read-only.
    static var header: UITextView.Style {
        UITextView.Style(
            textAlignment: .center,
            font: UIFont.header,
            isEditable: false
        )
    }

    // Historical preset retained as commented-out reference. Keep in case the
    // welcome scene's text view ever needs an impression-scale variant again.
//    static var impression: UITextView.Style {
//        return UITextView.Style(
//            font: UIFont.impression,
//            isEditable: false
//        )
//    }
}

// MARK: - Style + Merging

extension UITextView.Style: Mergeable {
    /// Combines two text-view styles attribute-by-attribute. Same shape as the
    /// `UILabel.Style` merge — see `UILabel+Styling.swift` for the pattern.
    public func merged(other: UITextView.Style, mode: MergeMode) -> UITextView.Style {
        func merge<T>(_ attributePath: KeyPath<UITextView.Style, T?>) -> T? {
            mergeAttribute(other: other, path: attributePath, mode: mode)
        }

        return UITextView.Style(
            textAlignment: merge(\.textAlignment),
            font: merge(\.font),
            textColor: merge(\.textColor),
            backgroundColor: merge(\.backgroundColor),
            isEditable: merge(\.isEditable),
            isSelectable: merge(\.isSelectable),
            isScrollEnabled: merge(\.isScrollEnabled),
            contentInset: merge(\.contentInset)
        )
    }
}
