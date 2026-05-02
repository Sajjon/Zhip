// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

/// Low-level opt-in for a screen that wants a custom left bar button.
///
/// Conformers supply a fully-formed `BarButtonContent` directly. Apps with a
/// predefined bar-button library typically declare a refinement (see
/// `LeftBarButtonMaking` in Zhip) that pre-fills `makeLeftContent` from a
/// typed enum case.
public protocol LeftBarButtonContentMaking {
    /// The content to install as the left bar button on `viewDidLoad`.
    static var makeLeftContent: BarButtonContent { get }
}

public extension LeftBarButtonContentMaking {
    /// Convenience used by `SceneController.viewDidLoad()` to install the left
    /// bar button on the supplied controller without exposing the static
    /// indirection at every call site.
    func setLeftBarButton(for viewController: AbstractController) {
        viewController.setLeftBarButtonUsing(content: Self.makeLeftContent)
    }
}
