// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation
import SingleLineControllerController

/// Zhip-side refinement of the package's `LeftBarButtonContentMaking` —
/// adopters declare which `BarButton` case they want; the default extension
/// derives `makeLeftContent` from `makeLeft.content`.
public protocol LeftBarButtonMaking: LeftBarButtonContentMaking {
    /// The predefined `BarButton` case to install as the left button.
    static var makeLeft: BarButton { get }
}

extension LeftBarButtonMaking {
    /// Default bridge: derive the content from the chosen predefined `BarButton`.
    public static var makeLeftContent: BarButtonContent {
        makeLeft.content
    }
}
