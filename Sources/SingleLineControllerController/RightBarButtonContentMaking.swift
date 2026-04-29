// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

/// Low-level opt-in for a screen that wants a custom right bar button — supply
/// any `BarButtonContent`. Apps with a predefined bar-button library typically
/// declare a Zhip-side refinement (see `RightBarButtonMaking` in Zhip) that
/// pre-fills `makeRightContent` from a typed enum case.
public protocol RightBarButtonContentMaking {
    /// The content to install as the right bar button on `viewDidLoad`.
    static var makeRightContent: BarButtonContent { get }
}

public extension RightBarButtonContentMaking {
    /// Convenience used by `SceneController.viewDidLoad()` to install the right
    /// bar button on the supplied controller.
    func setRightBarButton(for viewController: AbstractController) {
        viewController.setRightBarButtonUsing(content: Self.makeRightContent)
    }
}

/// Marker protocol — when a `SceneController` conforms, the system back chevron
/// is hidden AND the swipe-back gesture is disabled. Use on flow-terminating
/// screens (e.g. "wallet created" confirmation) where backing up would re-enter
/// an inconsistent state.
public protocol BackButtonHiding {}
