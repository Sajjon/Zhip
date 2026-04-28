// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCombine
import SingleLineControllerNavigation
import UIKit

// MARK: - Start Child Coordinator

public extension Coordinating {
    /// Starts a new temporary flow with a new Coordinator presented modally.
    ///
    /// The child coordinator is initialized by the call-site in `makeCoordinator`,
    /// which receives a fresh `UINavigationController`. The `navigationHandler`
    /// closure receives each `NavigationStep` plus a `dismiss` closure the
    /// caller invokes when the flow finishes — that dismiss tears down the
    /// navigation stack AND removes the child from `childCoordinators`.
    func presentModalCoordinator<C: Coordinating & Navigating>(
        makeCoordinator: (_ newNavController: UINavigationController) -> C,
        didStart: Completion? = nil,
        navigationHandler: @escaping (_ step: C.NavigationStep, _ dismiss: (_ animateDismiss: Bool) -> Void) -> Void
    ) {
        let newModalNavigationController = NavigationBarLayoutingNavigationController()

        let child = makeCoordinator(newModalNavigationController)

        childCoordinators.append(child)

        child.start(didStart: didStart)

        navigationController.present(newModalNavigationController, animated: true, completion: nil)

        // Subscribe to the navigation steps emitted by the child coordinator
        // And invoke the `navigationHandler` closure. When the parent invokes
        // the trailing `dismiss` closure we tear down the modal AND remove
        // the child from `childCoordinators` so it can be deallocated.
        child.navigator.navigation
            .sinkOnMain { [
                weak self,
                weak newModalNavigationController,
                weak child
            ] navigationStep in
                navigationHandler(navigationStep) { animated in
                    newModalNavigationController?.dismiss(animated: animated, completion: nil)
                    if let self, let child {
                        self.remove(childCoordinator: child)
                    }
                }
            }
            .store(in: &cancellables)
    }
}
