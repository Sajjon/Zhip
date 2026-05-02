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

// Same Style/Apply/Customizing/Presets/Mergeable shape as `UILabel+Styling.swift`
// — see that file for the canonical doc walkthrough. Only the per-attribute
// fields and the presets differ here.

public extension UIButton {
    /// Optional-keypath assignment helper: writes `attribute` to `keyPath` only
    /// when `attribute` is non-nil. Lets style application skip attributes the
    /// caller didn't want to override.
    func setOptional<Attribute>(
        _ keyPath: ReferenceWritableKeyPath<UIButton, Attribute?>,
        ifNotNil attribute: Attribute?
    ) {
        guard let attribute else { return }
        self[keyPath: keyPath] = attribute
    }

    /// Non-optional-keypath variant — same semantics: write only if `attribute` is non-nil.
    func set<Attribute>(_ keyPath: ReferenceWritableKeyPath<UIButton, Attribute>, ifNotNil attribute: Attribute?) {
        guard let attribute else { return }
        self[keyPath: keyPath] = attribute
    }
}

public extension UIView {
    /// Corner rounding policy for a view. Currently only `.static(CGFloat)` is
    /// implemented — the enum exists so a future percentage/dynamic policy can
    /// be added without churning every call site.
    enum Rounding {
        /// Fixed corner radius in points.
        case `static`(CGFloat)

        /// Applies this rounding to `view`, also setting `masksToBounds` so the
        /// rounded corners actually clip the contents.
        public func apply(to view: UIView, maskToBounds: Bool = true) {
            switch self {
            case let .static(radius):
                view.layer.cornerRadius = radius
            }
            if maskToBounds {
                view.layer.masksToBounds = true
            }
        }
    }
}

public extension UIButton {
    /// Description of a button's appearance — text/image content, per-state
    /// foreground/background colours, font, optional border/rounding/height.
    /// Same nil-means-default convention as `UILabel.Style`.
    struct Style {
        /// Default tap-target height (64pt) — thumb-friendly hit area for
        /// primary buttons. Nested here so the memberwise init's default
        /// argument can reference it without a public top-level constant.
        public static let defaultHeight: CGFloat = 64

        fileprivate var titleNormal: String?
        fileprivate var imageNormal: UIImage?
        public var tintColor: UIColor?
        public var height: CGFloat?
        public let textColorNormal: UIColor?
        public let textColorDisabled: UIColor?
        public let colorNormal: UIColor?
        public let colorDisabled: UIColor?
        public let colorSelected: UIColor?
        public let font: UIFont?
        public var isEnabled: Bool?
        public let borderNormal: Border?
        public let cornerRounding: UIView.Rounding?

        /// Memberwise initialiser — every parameter optional so call sites
        /// only specify what they care to override.
        public init(
            titleNormal: String? = nil,
            imageNormal: UIImage? = nil,
            tintColor: UIColor? = UIColor.teal,
            height: CGFloat? = Self.defaultHeight,
            font: UIFont? = nil,
            textColorNormal: UIColor? = nil,
            textColorDisabled: UIColor? = nil,
            colorNormal: UIColor? = nil,
            colorDisabled: UIColor? = nil,
            colorSelected: UIColor? = nil,
            borderNormal: Border? = nil,
            isEnabled: Bool? = nil,
            cornerRounding: UIView.Rounding? = nil
        ) {
            self.titleNormal = titleNormal
            self.imageNormal = imageNormal
            self.tintColor = tintColor
            self.height = height
            self.textColorNormal = textColorNormal
            self.textColorDisabled = textColorDisabled
            self.colorNormal = colorNormal
            self.colorDisabled = colorDisabled
            self.colorSelected = colorSelected
            self.font = font
            self.isEnabled = isEnabled
            self.borderNormal = borderNormal
            self.cornerRounding = cornerRounding
        }
    }
}

public extension UIButton {
    /// Writes `style` to this button, substituting project-wide defaults for
    /// any nil attribute. Includes the per-state colour set (normal/disabled/selected).
    func apply(style: Style) {
        translatesAutoresizingMaskIntoConstraints = false
        if let height = style.height {
            self.height(height)
        }
        if let titleNormal = style.titleNormal {
            setTitle(titleNormal, for: .normal)
        }
        if let imageNormal = style.imageNormal {
            setImage(imageNormal, for: .normal)
        }
        set(\.tintColor, ifNotNil: style.tintColor)
        setTitleColor(style.textColorNormal ?? .defaultText, for: .normal)
        setTitleColor(style.textColorDisabled ?? .silverGrey, for: .disabled)
        titleLabel?.font = style.font ?? UIFont.button
        let colorNormal = style.colorNormal ?? .teal
        let colorDisabled = style.colorDisabled ?? .asphaltGrey
        // .selected falls back to .normal — most buttons don't distinguish a
        // selected state, so re-using .normal looks correct.
        let colorSelected = style.colorSelected ?? colorNormal
        setBackgroundColor(colorNormal, for: .normal)
        setBackgroundColor(colorDisabled, for: .disabled)
        setBackgroundColor(colorSelected, for: .selected)
        isEnabled = style.isEnabled ?? true
        if let borderNormal = style.borderNormal {
            addBorder(borderNormal)
        }

        if let cornerRounding = style.cornerRounding {
            cornerRounding.apply(to: self)
        }
    }

    /// Apply `style` and return `self`. Generic over `B: UIButton` so concrete
    /// subclasses (e.g. `ButtonWithSpinner`) keep their type at the call site
    /// without an explicit cast. Crashes loudly if the runtime cast fails —
    /// a programming error, not a recoverable condition.
    @discardableResult
    func withStyle<B: UIButton>(_ style: UIButton.Style, customize: ((UIButton.Style) -> UIButton.Style)? = nil) -> B {
        translatesAutoresizingMaskIntoConstraints = false
        let style = customize?(style) ?? style
        apply(style: style)
        guard let button = self as? B else { incorrectImplementation("Bad cast") }
        return button
    }
}

// MARK: - Style + Customizing

// Chainable mutators — each returns a copy with one field replaced.
// See UILabel+Styling.swift for the canonical pattern walkthrough.

public extension UIButton.Style {
    /// Returns a copy of this style with `isEnabled = false`.
    @discardableResult
    func disabled() -> UIButton.Style {
        var style = self
        style.isEnabled = false
        return style
    }

    /// Returns a copy of this style with the normal-state title replaced.
    @discardableResult
    func title(_ titleNormal: String) -> UIButton.Style {
        var style = self
        style.titleNormal = titleNormal
        return style
    }

    /// Returns a copy of this style with `height` replaced.
    /// Pass `nil` to drop the explicit height constraint and let the button
    /// size to its content.
    @discardableResult
    func height(_ height: CGFloat?) -> UIButton.Style {
        var style = self
        style.height = height
        return style
    }
}

// MARK: - Style Presets

public extension UIButton.Style {
    /// Solid-fill primary button — teal background, white text, 8pt corners.
    /// The default call-to-action style across the app.
    static var primary: UIButton.Style {
        UIButton.Style(
            textColorNormal: .white,
            textColorDisabled: .silverGrey,
            colorNormal: .teal,
            colorDisabled: .asphaltGrey,
            cornerRounding: .static(8)
        )
    }

    /// Text-only secondary button (no fill, teal text). Use for low-emphasis
    /// destructive or alternative actions.
    static var secondary: UIButton.Style {
        UIButton.Style(
            textColorNormal: .teal,
            colorNormal: .clear
        )
    }

    /// Outlined ("hollow") button — 1pt teal border, transparent fill,
    /// 44pt tap target. Mid-emphasis between `.primary` and `.secondary`.
    static var hollow: UIButton.Style {
        UIButton.Style(
            height: 44,
            textColorNormal: .teal,
            colorNormal: .clear,
            borderNormal: UIView.Border(color: .teal, width: 1),
            cornerRounding: .static(8)
        )
    }

    /// Icon-only button preset — image and no fill, sized to its content.
    internal static func image(_ image: UIImage) -> UIButton.Style {
        UIButton.Style(
            imageNormal: image,
            height: nil,
            font: .title,
            textColorNormal: .teal,
            colorNormal: .clear,
            cornerRounding: nil
        )
    }

    /// Text-only inline button preset — content-sized, teal text on transparent.
    internal static func title(_ title: String) -> UIButton.Style {
        UIButton.Style(
            titleNormal: title,
            height: nil,
            font: .title,
            textColorNormal: .teal,
            colorNormal: .clear,
            cornerRounding: nil
        )
    }
}
