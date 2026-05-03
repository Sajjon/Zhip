// MIT License — Copyright (c) 2018-2026 Open Zesame

import NanoViewControllerController
import UIKit

/// Zhip-side brand-default factories for `NavigationBarLayout`.
///
/// `NavigationBarLayout` ships in `NanoViewControllerController` as a
/// memberwise-only struct (every field required) — this file layers Zhip's
/// brand defaults on top via `extension NavigationBarLayout` so call sites
/// can read `.opaque` / `.translucent(...)` / `.hidden` / `.default` like
/// before.
///
/// The package itself never reaches into `UINavigationBar.default*` — those
/// statics live in `AppAppearance.swift` and are Zhip-specific.
public extension NavigationBarLayout {
    /// Memberwise init with Zhip's brand defaults. Mirrors the original
    /// pre-extraction shape so call sites that only override a couple of
    /// fields keep compiling unchanged.
    ///
    /// `@MainActor` because the brand-default values referenced in the
    /// argument list (`UINavigationBar.default*` static accessors) are
    /// `@MainActor` under the iOS 26 SDK.
    @MainActor
    init(
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
        self.init(
            barStyle: barStyle,
            visibility: visibility,
            isTranslucent: isTranslucent ?? UINavigationBar.defaultIsTranslucent,
            barTintColor: barTintColor ?? UINavigationBar.defaultBarTintColor,
            tintColor: tintColor ?? UINavigationBar.defaultTintColor,
            backgroundColor: backgroundColor ?? UINavigationBar.defaultBackgroundColor,
            backgroundImage: backgroundImage ?? UINavigationBar.defaultBackgroundImage,
            shadowImage: shadowImage ?? UINavigationBar.defaultShadowImage,
            titleFont: titleFont ?? UINavigationBar.defaultFont,
            titleColor: titleColor ?? UINavigationBar.defaultTextColor
        )
    }

    /// App-wide fallback layout used by controllers that don't conform to `NavigationBarLayoutOwner`.
    /// Read by the package's nav controller from arbitrary contexts; in practice
    /// it's only mutated (if ever) at app init on the main thread.
    @MainActor
    static var `default`: NavigationBarLayout = .opaque

    /// Brand-default opaque bar (white text on dusky-blue background).
    @MainActor
    static var opaque: NavigationBarLayout {
        NavigationBarLayout(
            isTranslucent: false
        )
    }

    /// Translucent bar with default tint/title colors. Use the function
    /// variant to override individual colors.
    @MainActor
    static var translucent: NavigationBarLayout {
        translucent()
    }

    /// Translucent bar with optional tint/title color overrides — used by the
    /// onboarding flow where the bar floats over a hero image.
    @MainActor
    static func translucent(tintColor: UIColor? = nil, titleColor: UIColor? = nil) -> NavigationBarLayout {
        NavigationBarLayout(
            isTranslucent: true,
            tintColor: tintColor,
            backgroundColor: .clear,
            titleColor: titleColor
        )
    }

    /// Hidden bar (no animation) — used by full-bleed screens like the splash.
    @MainActor
    static var hidden: NavigationBarLayout {
        NavigationBarLayout(
            visibility: .hidden(animated: false)
        )
    }
}
