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

/// Conformance signals that a `UIViewController` (typically a `SceneController`)
/// wants its hosting navigation bar styled according to a particular `NavigationBarLayout`.
///
/// `AbstractController.viewWillAppear` checks for this conformance and pushes
/// the layout onto its `navigationController?.navigationBar` — so per-screen
/// styling (e.g. translucent vs opaque, hidden bar) lives on the controller
/// instance instead of in shared appearance proxies.
public protocol NavigationBarLayoutOwner {
    /// The styling the controller wants applied while it's on screen.
    var navigationBarLayout: NavigationBarLayout { get }
}

public extension UINavigationBar {
    /// Mutates this navigation bar to match `layout`. Used by `AbstractController`
    /// during view-will-appear so each scene can stamp its own bar styling.
    ///
    /// Returns the same `layout` to make chaining easy at call sites that want
    /// to remember what they applied.
    @discardableResult
    func applyLayout(_ layout: NavigationBarLayout) -> NavigationBarLayout {
        barStyle = layout.barStyle
        isTranslucent = layout.isTranslucent
        tintColor = layout.tintColor

        let navBarAppearance = UINavigationBarAppearance()
        // iOS 13+ requires us to choose between transparent and opaque
        // background configurations explicitly — the legacy
        // `setBackgroundImage` API is deprecated.
        if layout.isTranslucent, layout.backgroundColor == .clear {
            navBarAppearance.configureWithTransparentBackground()
        } else {
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.backgroundColor = layout.barTintColor
        }
        navBarAppearance.titleTextAttributes = layout.titleTextAttributes
        navBarAppearance.shadowColor = .clear

        // Stamp the appearance into all four metrics so the bar looks
        // consistent in both portrait and landscape, both standard and
        // scroll-edge states (matters on iPad and iOS 15+).
        standardAppearance = navBarAppearance
        scrollEdgeAppearance = navBarAppearance
        compactAppearance = navBarAppearance
        compactScrollEdgeAppearance = navBarAppearance

        return layout
    }
}

/// Per-screen navigation-bar styling. Applied in `applyLayout(_:)` above and
/// produced via the static factories (`.opaque`, `.translucent(...)`, `.hidden`).
public struct NavigationBarLayout: Equatable {
    /// Field-by-field equality (`UIImage` and dictionary equality not auto-synthesized).
    public static func == (lhs: NavigationBarLayout, rhs: NavigationBarLayout) -> Bool {
        lhs.visibility == rhs.visibility &&
            lhs.isTranslucent == rhs.isTranslucent &&
            lhs.tintColor == rhs.tintColor &&
            lhs.barTintColor == rhs.barTintColor &&
            lhs.backgroundColor == rhs.backgroundColor &&
            lhs.backgroundImage == rhs.backgroundImage &&
            lhs.shadowImage == rhs.shadowImage &&
            lhs.titleFont == rhs.titleFont &&
            lhs.titleColor == rhs.titleColor
    }

    /// Light vs dark bar style — controls the status bar foreground color.
    public let barStyle: UIBarStyle
    /// Whether the bar is hidden or visible (and whether the transition animates).
    public let visibility: Visibility
    /// Whether the bar background is translucent (allows content to bleed through).
    public let isTranslucent: Bool

    /// Tint applied to bar-button items and back chevron.
    public let tintColor: UIColor
    /// Bar background color in opaque mode.
    public let barTintColor: UIColor
    /// Background color (only honored when `isTranslucent == true`).
    public let backgroundColor: UIColor

    /// Background image (use empty `UIImage()` to clear).
    public let backgroundImage: UIImage
    /// 1pt shadow image under the bar (use empty `UIImage()` to clear).
    public let shadowImage: UIImage

    /// Title text font.
    public let titleFont: UIFont
    /// Title text color.
    public let titleColor: UIColor

    /// Convenience: the flattened `[font, color]` form expected by `UINavigationBarAppearance`.
    public var titleTextAttributes: [NSAttributedString.Key: Any] {
        [.font(titleFont), .color(titleColor)].attributes
    }

    /// Memberwise init with sensible defaults pulled from the `UINavigationBar`
    /// `default*` family. Pass `nil` to inherit the global default; pass an
    /// explicit value to override it for this layout only.
    public init(
        barStyle: UIBarStyle = UINavigationBar.defaultBarStyle,
        visibility: Visibility = .visible(animated: false),
        isTranslucent: Bool? = nil,
        barTintColor: UIColor? = nil,
        tintColor: UIColor? = nil,
        backgroundColor: UIColor? = nil,
        backgroundImage: UIImage? = nil,
        shadowImage: UIImage? = nil,
        titleFont: UIFont? = nil,
        titleColor: UIColor? = nil
    ) {
        self.barStyle = barStyle
        self.visibility = visibility
        self.isTranslucent = isTranslucent ?? UINavigationBar.defaultIsTranslucent

        self.barTintColor = barTintColor ?? UINavigationBar.defaultBarTintColor
        self.tintColor = tintColor ?? UINavigationBar.defaultTintColor
        self.backgroundColor = backgroundColor ?? UINavigationBar.defaultBackgroundColor

        self.backgroundImage = backgroundImage ?? UINavigationBar.defaultBackgroundImage
        self.shadowImage = shadowImage ?? UINavigationBar.defaultShadowImage

        self.titleFont = titleFont ?? UINavigationBar.defaultFont
        self.titleColor = titleColor ?? UINavigationBar.defaultTextColor
    }
}

public extension NavigationBarLayout {
    /// Whether the navigation bar is visible, plus whether the visibility
    /// transition itself should be animated.
    enum Visibility: Equatable {
        /// Bar should be hidden; `animated` controls the show/hide transition.
        case hidden(animated: Bool)
        /// Bar should be visible; `animated` controls the show/hide transition.
        case visible(animated: Bool)
        /// `true` for the `.hidden` case, `false` otherwise.
        var isHidden: Bool {
            switch self {
            case .hidden: true
            default: false
            }
        }

        /// Whether the show/hide transition should animate.
        var animated: Bool {
            switch self {
            case let .hidden(animated): animated
            case let .visible(animated): animated
            }
        }
    }
}

public extension NavigationBarLayout {
    /// App-wide fallback layout used by controllers that don't conform to `NavigationBarLayoutOwner`.
    static var `default`: NavigationBarLayout = .opaque

    /// Brand-default opaque bar (white text on dusky-blue background).
    static var opaque: NavigationBarLayout {
        NavigationBarLayout(
            isTranslucent: false
        )
    }

    /// Translucent bar with default tint/title colors. Use the function
    /// variant to override individual colors.
    static var translucent: NavigationBarLayout {
        translucent()
    }

    /// Translucent bar with optional tint/title color overrides — used by the
    /// onboarding flow where the bar floats over a hero image.
    static func translucent(tintColor: UIColor? = nil, titleColor: UIColor? = nil) -> NavigationBarLayout {
        NavigationBarLayout(
            isTranslucent: true,
            tintColor: tintColor,
            backgroundColor: .clear,
            titleColor: titleColor
        )
    }

    /// Hidden bar (no animation) — used by full-bleed screens like the splash.
    static var hidden: NavigationBarLayout {
        NavigationBarLayout(
            visibility: .hidden(animated: false)
        )
    }
}
