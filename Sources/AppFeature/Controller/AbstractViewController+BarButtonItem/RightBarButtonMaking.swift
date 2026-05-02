// MIT License — Copyright (c) 2018-2026 Open Zesame

import SingleLineControllerController
import UIKit

/// Zhip-side refinement of the package's `RightBarButtonContentMaking` —
/// adopters declare which `BarButton` case they want, and the default
/// extension derives `makeRightContent` from `makeRight.content`.
///
/// The package ships the underlying `RightBarButtonContentMaking` protocol
/// which only requires a `BarButtonContent` directly; this typed convenience
/// is Zhip-specific because `BarButton` is Zhip's catalog.
public protocol RightBarButtonMaking: RightBarButtonContentMaking {
    /// The predefined `BarButton` case to install as the right button.
    static var makeRight: BarButton { get }
}

public extension RightBarButtonMaking {
    /// Default bridge — derive the content from the chosen predefined `BarButton`.
    static var makeRightContent: BarButtonContent {
        makeRight.content
    }
}
