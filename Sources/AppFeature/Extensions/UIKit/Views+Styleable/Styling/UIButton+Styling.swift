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
        ///
        /// `@MainActor` because `view.layer` is `@MainActor`-isolated under the
        /// iOS 26 SDK. All call sites are already main-actor (UI styling only
        /// happens during view setup or `populate(with:)`), so this is a
        /// no-op annotation that just makes the isolation explicit.
        @MainActor
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
    /// Writes `style` to this button by building a `UIButton.Configuration`
    /// (iOS 15+ button styling API) plus a `configurationUpdateHandler` that
    /// swaps colours per state (normal/disabled/selected). Substitutes
    /// project-wide defaults for any nil attribute.
    ///
    /// Why `Configuration` instead of the legacy `setTitle` /
    /// `setBackgroundColor` per-state API: from iOS 15 on, Configuration is
    /// the only path that composes correctly with content insets, image
    /// padding, and (on iOS 26+) the Liquid Glass material system. Mixing
    /// legacy setters with Configuration produces undefined render order.
    func apply(style: Style) {
        translatesAutoresizingMaskIntoConstraints = false
        if let height = style.height {
            self.height(height)
        }
        set(\.tintColor, ifNotNil: style.tintColor)

        let palette = ResolvedPalette(style: style)
        configuration = makeConfiguration(style: style, palette: palette)
        configurationUpdateHandler = palette.makeUpdateHandler()

        isEnabled = style.isEnabled ?? true
    }

    /// Builds the initial `UIButton.Configuration` from `style`. Decoration-
    /// free `.plain()` base; fill/stroke/corner/image/title layered in
    /// explicitly so we don't fight system defaults.
    private func makeConfiguration(style: Style, palette: ResolvedPalette) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.image = style.imageNormal
        if let title = style.titleNormal {
            // attributedTitle (rather than `title` + a transformer) makes the
            // font/color baseline obvious; the update handler mutates the
            // foregroundColor per state.
            var container = AttributeContainer()
            container.font = palette.font
            container.foregroundColor = palette.textColorNormal
            configuration.attributedTitle = AttributedString(title, attributes: container)
        }
        if case let .static(radius) = style.cornerRounding {
            configuration.background.cornerRadius = radius
            // `.fixed` keeps the literal radius (overriding the capsule /
            // dynamic curve Configuration applies to bordered/filled styles
            // by default).
            configuration.cornerStyle = .fixed
        }
        if let border = style.borderNormal {
            configuration.background.strokeColor = UIColor(cgColor: border.color)
            configuration.background.strokeWidth = border.width
        }
        configuration.background.backgroundColor = palette.colorNormal
        return configuration
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

/// Per-state colour palette resolved from a `UIButton.Style`. Captured by
/// the configurationUpdateHandler so each state-change reads from a
/// pre-resolved value bag instead of re-reading the mutable `Style`.
private struct ResolvedPalette {
    let textColorNormal: UIColor
    let textColorDisabled: UIColor
    let colorNormal: UIColor
    let colorDisabled: UIColor
    let colorSelected: UIColor
    let font: UIFont

    init(style: UIButton.Style) {
        textColorNormal = style.textColorNormal ?? .defaultText
        textColorDisabled = style.textColorDisabled ?? .silverGrey
        colorNormal = style.colorNormal ?? .teal
        colorDisabled = style.colorDisabled ?? .asphaltGrey
        // .selected falls back to .normal — most buttons don't distinguish a
        // selected state, so re-using .normal looks correct.
        colorSelected = style.colorSelected ?? (style.colorNormal ?? .teal)
        font = style.font ?? UIFont.button
    }

    /// Returns a `configurationUpdateHandler` closure that swaps background
    /// + title colours per state. Configuration's built-in disabled tint
    /// doesn't honour our explicit `colorDisabled`/`textColorDisabled`, so
    /// we override via the standard handler hook.
    ///
    /// `.highlighted` is handled explicitly because the legacy
    /// `setBackgroundColor(_:for:)` API used to dim the background image
    /// automatically on press; Configuration does *not* — without an
    /// explicit branch, taps would have no visual feedback.
    ///
    /// `@MainActor` because the returned closure mutates `button.configuration`
    /// — which is `@MainActor`-isolated under the iOS 26 SDK. UIKit only
    /// ever invokes `configurationUpdateHandler` on the main actor, so this
    /// is the correct isolation contract.
    @MainActor
    func makeUpdateHandler() -> (UIButton) -> Void {
        { button in
            guard var c = button.configuration else { return }
            switch button.state {
            case .disabled:
                c.background.backgroundColor = colorDisabled
                if var attr = c.attributedTitle {
                    attr.foregroundColor = textColorDisabled
                    c.attributedTitle = attr
                }
            case .selected:
                c.background.backgroundColor = colorSelected
            case .highlighted:
                // 0.85 alpha matches UIKit's historical highlight darkening
                // — visible enough to register the touch, subtle enough not
                // to flash on quick taps.
                c.background.backgroundColor = colorNormal.withAlphaComponent(0.85)
                if var attr = c.attributedTitle {
                    attr.foregroundColor = textColorNormal
                    c.attributedTitle = attr
                }
            default:
                c.background.backgroundColor = colorNormal
                if var attr = c.attributedTitle {
                    attr.foregroundColor = textColorNormal
                    c.attributedTitle = attr
                }
            }
            button.configuration = c
        }
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
