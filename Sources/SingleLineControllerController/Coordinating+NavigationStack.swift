// MIT License — Copyright (c) 2018-2026 Open Zesame

import SingleLineControllerNavigation
import UIKit

public extension Coordinating {
    /// Returns `true` iff the navigation stack's topmost view controller is an
    /// instance of `Scene`. Used by handlers that need to make sure they're
    /// reacting to navigation only when they are the active scene
    /// (e.g. avoiding double-pushes from leftover subscriptions).
    func isTopmost<Scene: UIViewController>(scene _: Scene.Type) -> Bool {
        guard navigationController.topViewController is Scene else { return false }
        return true
    }
}
