// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation
import NanoViewControllerController

/// Localization-aware convenience initialiser for ``ControllerConfig``.
///
/// Zhip's screens carry their navigation titles as `LocalizedStringResource`
/// keys auto-generated from the `.xcstrings` catalogues (e.g.
/// `.CreateNewWallet.title`, a member on `LocalizedStringResource` produced
/// by Xcode's string-catalog symbol generator). The package's
/// ``ControllerConfig/init(title:hidesBackButton:leftBarButton:rightBarButton:navigationBarLayout:)``
/// takes a resolved `String`, which forces every call site to wrap the key
/// in `String(localized:)`. This extension folds that wrapping into the
/// initialiser so call sites read:
///
/// ```swift
/// public static let config = ControllerConfig(
///     titleKey: .CreateNewWallet.title,
///     leftBarButton: BarButton.cancel.content
/// )
/// ```
///
/// instead of the noisier `title: String(localized: .CreateNewWallet.title)`.
@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
public extension ControllerConfig {
    /// Designated init that takes a localization key for the title and
    /// forwards everything else verbatim to the package's
    /// memberwise ``ControllerConfig/init(title:hidesBackButton:leftBarButton:rightBarButton:navigationBarLayout:)``.
    ///
    /// - Parameters:
    ///   - titleKey: `.xcstrings`-derived key resolved via `String(localized:)`.
    ///   - hidesBackButton: Suppress the system back arrow on this controller.
    ///   - leftBarButton: Static left bar-button content.
    ///   - rightBarButton: Static right bar-button content.
    ///   - navigationBarLayout: Per-controller navigation bar layout override.
    init(
        titleKey: LocalizedStringResource,
        hidesBackButton: Bool = false,
        leftBarButton: BarButtonContent? = nil,
        rightBarButton: BarButtonContent? = nil,
        navigationBarLayout: NavigationBarLayout? = nil
    ) {
        self.init(
            title: String(localized: titleKey),
            hidesBackButton: hidesBackButton,
            leftBarButton: leftBarButton,
            rightBarButton: rightBarButton,
            navigationBarLayout: navigationBarLayout
        )
    }
}
