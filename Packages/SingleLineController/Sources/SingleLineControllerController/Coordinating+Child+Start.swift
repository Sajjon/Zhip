// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCombine
import SingleLineControllerNavigation
import UIKit

public extension Coordinating {
    /// Starts a child coordinator which might be part of a flow of multiple coordinators.
    /// Use this method when you know that you will finish the root coordinator at some
    /// point, which also will finish this new child coordinator.
    ///
    /// If you intend to start a single temporary coordinator that you will finish from
    /// the parent (the coordinator instance you called this method on) then please use
    /// `presentModalCoordinator` instead.
    func start<C: Coordinating & Navigating>(
        coordinator child: C,
        transition: CoordinatorTransition = .append,
        didStart: Completion? = nil,
        navigationHandler: @escaping (_ step: C.NavigationStep) -> Void
    ) {
        // Start the child coordinator and pass along the `didStart` closure.
        let startChild = { [weak child] in
            child?.start(didStart: didStart)
        }

        // Add the child coordinator to the childCoordinator array
        switch transition {
        case .replace:
            // .replace wipes the current navigation stack first so the user
            // doesn't see the previous flow's controllers flash through.
            // Starting the child is deferred to the wipe's completion.
            childCoordinators = [child]
            navigationController.removeAllViewControllers { startChild() }
        case .append:
            // .append keeps the existing stack and starts the child synchronously.
            childCoordinators.append(child)
            startChild()
        }

        // Subscribe to the navigation steps emitted by the child coordinator
        // And invoke the navigationHandler closure passed in to this method
        child.navigator.navigation
            .sinkOnMain { navigationHandler($0) }
            .store(in: &cancellables)
    }
}

private extension UINavigationController {
    /// Empties the navigation stack and any presented controller, invoking
    /// `completion` once the teardown finishes. Used by `CoordinatorTransition.replace`
    /// to clear the slate before starting the replacement child.
    func removeAllViewControllers(animated: Bool = true, completion: @escaping Completion) {
        func removeAllViewControllers() {
            if !viewControllers.isEmpty {
                viewControllers = []
            }
            // Hop to the next runloop tick so callers observe the empty
            // viewControllers array, not the in-flight one.
            DispatchQueue.main.async { completion() }
        }

        // If a modal is up, we must dismiss it before clearing the stack —
        // otherwise the modal's reference into our viewControllers becomes stale.
        if let presented = presentedViewController {
            presented.dismiss(animated: animated) {
                removeAllViewControllers()
            }
        } else {
            removeAllViewControllers()
        }
    }
}
