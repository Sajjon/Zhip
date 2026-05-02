// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation
import NanoViewControllerController

/// The predefined library of navigation-bar buttons used across Zhip.
///
/// Restricting screens to this small set keeps the navigation chrome consistent
/// and means localised copy / system styling lives in exactly one place.
///
/// `BarButtonContent` ships in the `NanoViewControllerController` package as
/// the primitive; this enum is Zhip's typed catalog on top of it.
public enum BarButton {
    /// Localised "Skip" text button — used in optional onboarding steps.
    case skip
    /// System Cancel button — abandons the current modal flow.
    case cancel
    /// System Done button — confirms the current modal flow.
    case done
}

// MARK: BarButtonContent

extension BarButton {
    /// Materialises this case into a concrete `BarButtonContent`.
    /// Cancel/Done use the iOS *system* items so we automatically get the right
    /// glyph/style/a11y label per locale; Skip is text-only with localised copy.
    var content: BarButtonContent {
        switch self {
        case .skip: BarButtonContent(title: String(localized: .Generic.skip))
        case .cancel: BarButtonContent(system: .cancel)
        case .done: BarButtonContent(system: .done)
        }
    }
}
