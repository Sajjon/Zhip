// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// How `Coordinating.start(coordinator:transition:...)` mounts a new child.
///
/// `.append` keeps the existing child stack and stacks the new one on top
/// (the common case). `.replace` empties the current navigation stack and
/// makes the new child the only one alive — used when transitioning between
/// fundamentally different app states (e.g. onboarding finished → main app).
public enum CoordinatorTransition {
    /// Append the new child to `childCoordinators` without disturbing existing ones.
    case append
    /// Replace the entire `childCoordinators` array (and clear the navigation stack).
    case replace
}
