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

/// Namespace for the app's one-time UIKit appearance configuration.
///
/// Called once from `bootstrap()` at launch. UIKit's `UIAppearance` proxy is
/// global and only affects views created *after* the configuration runs, so
/// this must execute before the first window is built.
@MainActor
public enum AppAppearance {
    /// Applies the app's default navigation/bar-button appearance.
    static func setupDefault() {
        setupAppearance()
    }
}

/// Top-level entry point that fans out to bar-button + navigation-bar setup.
@MainActor
private func setupAppearance() {
    setupNavigationBarAppearance()
    setupBarButtonItemAppearance()
}

/// Configures the global `UIBarButtonItem.appearance()` proxy and replaces
/// the default chevron used as the navigation back-button.
@MainActor
public func setupBarButtonItemAppearance() {
    UINavigationBar.appearance().backIndicatorImage = UIImage()
    UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage()
    UIBarButtonItem.appearance().attributeText([.font(.title), .color(.teal)], for: UIControl.State.all)
    replaceBackBarButtonImage()
}

/// Substitutes a custom chevron PNG for the system back-button.
/// Uses `stretchableImage(withLeftCapWidth:topCapHeight:)` so the asset
/// scales gracefully if iOS resizes it for different bar metrics.
@MainActor
private func replaceBackBarButtonImage() {
    let backImage = UIImage(resource: .chevronLeft)
    let stretched = backImage.stretchableImage(withLeftCapWidth: 15, topCapHeight: 30)
    UIBarButtonItem.appearance().setBackButtonBackgroundImage(stretched, for: .normal, barMetrics: .default)
}

/// Default styling tokens consumed by `NavigationBarLayout` and the global
/// `UINavigationBar.appearance()` proxy.
public extension UINavigationBar {
    /// Solid bar background color — the dusky-blue brand tone.
    static var defaultBarTintColor: UIColor {
        .dusk
    }

    /// Default background when the bar is *translucent*.
    static var defaultBackgroundColor: UIColor {
        .clear
    }

    /// Tint applied to bar-button items and back-arrow chrome.
    static var defaultTintColor: UIColor {
        .white
    }

    /// Title text color.
    static var defaultTextColor: UIColor {
        .white
    }

    /// Title text font (Barlow `.title`).
    static var defaultFont: UIFont {
        .title
    }

    /// Default to translucent so screens that supply a custom translucent
    /// appearance don't have to override this flag explicitly.
    static var defaultIsTranslucent: Bool {
        true
    }

    /// Default bar style — `.black` makes the status-bar foreground white.
    static var defaultBarStyle: UIBarStyle {
        .black
    }

    /// Empty image used to clear out the system background image.
    static var defaultBackgroundImage: UIImage {
        UIImage()
    }

    /// Empty image used to clear out the system 1-pt shadow under the bar.
    static var defaultShadowImage: UIImage {
        UIImage()
    }

    /// `[font, color]` rendered into the dictionary form `UINavigationBarAppearance` expects.
    static var defaultTitleTextAttributes: [NSAttributedString.Key: Any] {
        _defaultTitleTextAttributes.attributes
    }

    /// Default layer-shadow color — opaque black, modulated by `defaultLayerShadowOpacity`.
    static var defaultLayerShadowColor: CGColor {
        UIColor.black.cgColor
    }

    /// Default layer-shadow opacity (0.8 = mostly opaque).
    static var defaultLayerShadowOpacity: Float {
        0.8
    }

    /// Default layer-shadow offset (down-right by 5pt).
    static var defaultLayerShadowOffset: CGSize {
        CGSize(width: 5, height: 5)
    }

    /// Default layer-shadow blur radius.
    static var defaultLayerShadowRadius: CGFloat {
        5
    }

    /// Internal helper backing `defaultTitleTextAttributes` — kept as a `[TextAttribute]`
    /// so other call sites can mutate/extend the list before flattening to a dictionary.
    fileprivate static var _defaultTitleTextAttributes: [TextAttribute] {
        [.font(UINavigationBar.defaultFont), .color(UINavigationBar.defaultTextColor)]
    }
}

/// Compile-time-typed shadow toggle that drops a CALayer shadow under the
/// navigation bar. Reads always return `false` because the shadow itself is
/// stored on `CALayer` properties — this property is *write-only* in practice.
extension UINavigationBar {
    /// Setting `true` applies the default shadow constants from `UINavigationBar`.
    /// Setting `false` is a no-op (use `layer.shadowOpacity = 0` to remove).
    var shadow: Bool {
        get {
            false
        }
        set {
            if newValue {
                layer.shadowColor = UINavigationBar.defaultLayerShadowColor
                layer.shadowRadius = UINavigationBar.defaultLayerShadowRadius
                layer.shadowOffset = UINavigationBar.defaultLayerShadowOffset
                layer.shadowOpacity = UINavigationBar.defaultLayerShadowOpacity
            }
        }
    }
}

/// Configures the global `UINavigationBar.appearance()` so every nav bar in
/// the app starts with our brand colors, opaque background, and clear shadow.
/// Per-screen overrides happen via `NavigationBarLayoutOwner` in
/// `NavigationBarLayout.swift`.
@MainActor
private func setupNavigationBarAppearance() {
    let navBarAppearance = UINavigationBarAppearance()
    navBarAppearance.configureWithOpaqueBackground()
    navBarAppearance.backgroundColor = UINavigationBar.defaultBarTintColor
    navBarAppearance.titleTextAttributes = UINavigationBar.defaultTitleTextAttributes
    navBarAppearance.shadowColor = .clear

    let appearance = UINavigationBar.appearance()
    appearance.shadow = true
    appearance.tintColor = UINavigationBar.defaultTintColor
    appearance.isTranslucent = UINavigationBar.defaultIsTranslucent
    appearance.standardAppearance = navBarAppearance
    appearance.scrollEdgeAppearance = navBarAppearance
    appearance.compactAppearance = navBarAppearance
    appearance.compactScrollEdgeAppearance = navBarAppearance
}

public extension UIControl.State {
    /// All three states a bar-button can be in. Used for bulk attribute
    /// application via `attributeText(_:for:)`.
    static let all: [UIControl.State] = [.normal, .highlighted, .disabled]
}

/// The subset of `UINavigationBar`/`UITabBar` appearance properties we tweak.
/// `@MainActor` because the conforming UIKit bar types are themselves
/// `@MainActor` under the iOS 26 SDK.
@MainActor
public protocol BarAppearance {
    /// Tint color applied to bar-button items, back chevron, etc.
    var tintColor: UIColor! { get set }
    /// Bar background tint (opaque mode).
    var barTintColor: UIColor? { get set }
    /// Background image (set to empty `UIImage()` to clear).
    var backgroundImage: UIImage? { get set }
    /// 1pt shadow image under the bar (set to empty `UIImage()` to clear).
    var shadowImage: UIImage? { get set }
}

/// Bar types that carry attributed title text (e.g. `UINavigationBar`).
/// `@MainActor` because the conforming UIKit bar types are themselves
/// `@MainActor` under the iOS 26 SDK.
@MainActor
public protocol BarTextAppearance {
    /// Backing dictionary consumed by UIKit's appearance API.
    var titleTextAttributes: [NSAttributedString.Key: Any]? { get set }
    /// Replaces `titleTextAttributes` with the flattened form of `values`.
    mutating func attributeText(_ values: [TextAttribute])
}

public extension BarTextAppearance {
    /// Default impl — flattens our typed `[TextAttribute]` to UIKit's `[NSAttributedString.Key: Any]`.
    mutating func attributeText(_ values: [TextAttribute]) {
        titleTextAttributes = Dictionary(uniqueKeysWithValues: values.map { ($0.key, $0.value) })
    }
}

extension UITabBar: BarAppearance {}
extension UINavigationBar: BarTextAppearance {}

extension UINavigationBar: BarAppearance {}
public extension UINavigationBar {
    /// Bridges `UINavigationBar`'s state-based background-image API to a
    /// simple `UIImage?` property so it satisfies `BarAppearance`.
    var backgroundImage: UIImage? {
        get {
            backgroundImage(for: .default)
        }

        set {
            setBackgroundImage(newValue, for: .default)
        }
    }
}

public extension UIAppearance where Self: BarTextAppearance {
    /// Variant of `BarTextAppearance.attributeText(_:)` callable on the
    /// `UIAppearance()` proxy (which is `let` and therefore not mutable —
    /// but `titleTextAttributes` is a setter on the underlying class).
    func attributeText(_ values: [TextAttribute]) {
        var selfBarTextAppearance = self as BarTextAppearance
        selfBarTextAppearance.titleTextAttributes = values.attributes
    }
}

public extension [TextAttribute] {
    /// Flattens this array to the UIKit `[NSAttributedString.Key: Any]` shape.
    var attributes: [NSAttributedString.Key: Any] {
        Dictionary(uniqueKeysWithValues: map { ($0.key, $0.value) })
    }
}

/// Typed wrapper around the small subset of `NSAttributedString.Key` values
/// we actually apply to bar text. Beats juggling raw dictionaries at the call site.
public enum TextAttribute {
    /// Specifies the title font.
    case font(UIFont)
    /// Specifies the title text color (maps to `.foregroundColor`).
    case color(UIColor)

    /// The matching `NSAttributedString.Key`.
    var key: NSAttributedString.Key {
        switch self {
        case .font: .font
        case .color: .foregroundColor
        }
    }

    /// The unwrapped associated value, type-erased to `Any` for UIKit's API.
    var value: Any {
        switch self {
        case let .font(font):
            font
        case let .color(color):
            color
        }
    }
}

public extension UIAppearance where Self: UIBarItem {
    /// Bulk variant — applies `values` to every state in `states`.
    func attributeText(_ values: [TextAttribute], for states: [UIControl.State]) {
        for state in states {
            attributeText(values, for: state)
        }
    }

    /// Single-state variant — calls `setTitleTextAttributes(_:for:)` directly.
    func attributeText(_ values: [TextAttribute], for state: UIControl.State) {
        setTitleTextAttributes(values.attributes, for: state)
    }
}
