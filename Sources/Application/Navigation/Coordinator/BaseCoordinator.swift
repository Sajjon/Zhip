// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit
import SingleLineControllerCore

/// Base class for our coordinators.
///
/// A *Coordinator* owns navigation logic for one logical flow (e.g. onboarding,
/// settings). It owns the `UINavigationController` it operates on, an array of
/// `childCoordinators` for sub-flows, and a `navigator` that emits typed
/// `NavigationStep`s consumed by the parent coordinator.
///
/// Subclasses must override `start(didStart:)`.
class BaseCoordinator<NavigationStep>: Coordinating, Navigating {
    /// Active sub-flows. Children are appended on `start(coordinator:...)` and
    /// removed in `remove(childCoordinator:)` to keep ARC happy.
    var childCoordinators = [Coordinating]()
    /// Stepper that emits typed navigation steps for the parent coordinator.
    let navigator = Navigator<NavigationStep>()
    /// Subscription bag holding our navigation pipelines for the lifetime of the coordinator.
    var cancellables = Set<AnyCancellable>()
    /// The `UINavigationController` this coordinator pushes/presents on.
    let navigationController: UINavigationController

    /// Wires the navigation controller this coordinator should drive.
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    /// Subclass hook — must build the root scene and present it. Crashes if
    /// not overridden because `BaseCoordinator` itself has no concrete flow.
    func start(didStart _: Completion? = nil) {
        abstract
    }
}

