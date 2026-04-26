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
// The notable extra here is `ExpressibleByArrayLiteral` so a scene's
// `stackViewStyle` property can read like an array of subviews — see the
// `CreateNewWalletView.stackViewStyle` use site for how that lands.

extension UIEdgeInsets {
    /// Top/bottom-only insets — left/right zero. Common shape for vertical
    /// stack layouts that only need padding above/below.
    init(top: CGFloat, bottom: CGFloat) {
        self.init(top: top, left: 0, bottom: bottom, right: 0)
    }

    /// Uniform insets on all four sides.
    init(all margin: CGFloat) {
        self.init(top: margin, left: margin, bottom: margin, right: margin)
    }

    /// Symmetric vertical/horizontal insets — use when top == bottom and left == right.
    init(vertical: CGFloat = 0, horizontal: CGFloat = 0) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}

// MARK: - Style

extension UIStackView {
    /// Description of a stack view's layout — axis, alignment, distribution,
    /// spacing, margins, plus the initial set of arranged subviews.
    struct Style {
        /// Default spacing between arranged subviews (16pt) — matches the
        /// design system's vertical rhythm.
        static let defaultSpacing: CGFloat = 16
        /// Default outer margin (16pt) — matches the standard scene gutter.
        static let defaultMargin: CGFloat = 16

        var views: [UIView]?
        var axis: NSLayoutConstraint.Axis?
        var alignment: UIStackView.Alignment?
        var distribution: UIStackView.Distribution?
        var spacing: CGFloat?
        var layoutMargins: UIEdgeInsets?
        var isLayoutMarginsRelativeArrangement: Bool?

        /// Memberwise initialiser. Note that `spacing` and `layoutMargins`
        /// default to non-nil values (the project standards), so call sites
        /// must pass `0` / `.zero` explicitly to opt out.
        init(
            _ views: [UIView]? = nil,
            axis: NSLayoutConstraint.Axis? = nil,
            alignment: UIStackView.Alignment? = nil,
            distribution: UIStackView.Distribution? = nil,
            spacing: CGFloat? = defaultSpacing,
            layoutMargins: UIEdgeInsets? = UIEdgeInsets(all: defaultMargin),
            isLayoutMarginsRelativeArrangement: Bool? = nil
        ) {
            self.views = views
            self.axis = axis
            self.alignment = alignment
            self.distribution = distribution
            self.spacing = spacing
            self.layoutMargins = layoutMargins
            self.isLayoutMarginsRelativeArrangement = isLayoutMarginsRelativeArrangement
        }
    }
}

// MARK: Style + ExpressibleByArrayLiteral

/// Lets a scene's `stackViewStyle: UIStackView.Style` be written as an array
/// literal of subviews — so the layout reads top-to-bottom in source.
extension UIStackView.Style: ExpressibleByArrayLiteral {
    init(arrayLiteral views: UIView...) {
        self.init(views)
    }
}

extension UIEdgeInsets {
    /// `true` iff every edge is zero. Used by the stack-view styling code to
    /// decide whether `isLayoutMarginsRelativeArrangement` should default on.
    var isZero: Bool {
        top == 0 && bottom == 0 && left == 0 && right == 0
    }
}

// MARK: - Apply Style

extension UIStackView {
    /// Writes `style` to this stack view, substituting project-wide defaults
    /// for any nil attribute.
    ///
    /// Note the `views.reversed()` + `insertArrangedSubview(_, at: 0)` pattern:
    /// it preserves the order in `style.views` while inserting at the head,
    /// so this is safe to call even if the stack already has arranged subviews
    /// (those end up *after* the styled ones).
    func apply(style: Style) {
        if let views = style.views, !views.isEmpty {
            views.reversed().forEach { self.insertArrangedSubview($0, at: 0) }
        }
        axis = style.axis ?? .vertical
        alignment = style.alignment ?? .fill
        distribution = style.distribution ?? .fill
        spacing = style.spacing ?? 0
        if let layoutMargins = style.layoutMargins, !layoutMargins.isZero {
            self.layoutMargins = layoutMargins
            isLayoutMarginsRelativeArrangement = style.isLayoutMarginsRelativeArrangement ?? true
        } else {
            isLayoutMarginsRelativeArrangement = style.isLayoutMarginsRelativeArrangement ?? false
        }
    }

    /// Apply `style` (optionally customised) and return `self`. Same call-site
    /// shape as `UILabel.withStyle(_:customize:)`.
    @discardableResult
    func withStyle(
        _ style: UIStackView.Style,
        customize: ((UIStackView.Style) -> UIStackView.Style)? = nil
    ) -> UIStackView {
        translatesAutoresizingMaskIntoConstraints = false
        let style = customize?(style) ?? style
        apply(style: style)
        return self
    }
}

// MARK: - Style + Customizing

// Chainable single-field replacements. See UILabel+Styling.swift for pattern.

extension UIStackView.Style {
    /// Returns a copy of this style with `alignment` replaced.
    @discardableResult
    func alignment(_ alignment: UIStackView.Alignment) -> UIStackView.Style {
        var style = self
        style.alignment = alignment
        return style
    }

    /// Returns a copy of this style with `distribution` replaced.
    @discardableResult
    func distribution(_ distribution: UIStackView.Distribution) -> UIStackView.Style {
        var style = self
        style.distribution = distribution
        return style
    }

    /// Returns a copy of this style with `spacing` replaced.
    @discardableResult
    func spacing(_ spacing: CGFloat) -> UIStackView.Style {
        var style = self
        style.spacing = spacing
        return style
    }

    /// Returns a copy of this style with `layoutMargins` replaced.
    @discardableResult
    func layoutMargins(_ layoutMargins: UIEdgeInsets) -> UIStackView.Style {
        var style = self
        style.layoutMargins = layoutMargins
        return style
    }
}

// MARK: - Style Presets

extension UIStackView.Style {
    /// Empty default — vertical, default spacing/margins, no subviews yet.
    static var `default`: UIStackView.Style {
        UIStackView.Style([])
    }

    /// Vertical layout with zero outer margins (caller will pin to a parent
    /// view that already has its own margins / safe-area handling).
    static var vertical: UIStackView.Style {
        UIStackView.Style(
            layoutMargins: .zero
        )
    }

    /// Horizontal layout with subviews evenly spaced around their centres
    /// (`.equalCentering`). Used for evenly-spaced icon rows.
    static var horizontalEqualCentering: UIStackView.Style {
        UIStackView.Style(
            axis: .horizontal,
            alignment: .center,
            distribution: .equalCentering,
            spacing: 0,
            layoutMargins: .zero
        )
    }

    /// Plain horizontal layout — default alignment/distribution, zero margins.
    static var horizontal: UIStackView.Style {
        UIStackView.Style(
            axis: .horizontal,
            layoutMargins: .zero
        )
    }

    /// Horizontal layout where every subview gets equal width
    /// (`.fillEqually`). Used for tab bars, segmented controls, etc.
    static var horizontalFillingEqually: UIStackView.Style {
        UIStackView.Style(
            axis: .horizontal,
            distribution: .fillEqually,
            layoutMargins: .zero
        )
    }
}
