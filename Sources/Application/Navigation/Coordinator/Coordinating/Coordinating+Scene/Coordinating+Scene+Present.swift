// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCombine
import SingleLineControllerNavigation
import UIKit

extension Coordinating {
    /// Convenience overload: builds the `Scene` from its type + view model and forwards.
    func modallyPresent<S: Scene<V>, V: ContentView>(
        scene _: S.Type,
        viewModel: V.ViewModel,
        animated: Bool = true,
        presentationCompletion: Completion? = nil,
        navigationHandler: @escaping NavigationHandlerModalScene<V.ViewModel>
    ) where V.ViewModel: Navigating {
        let scene = S(viewModel: viewModel)
        modallyPresent(
            scene: scene,
            animated: animated,
            presentationCompletion: presentationCompletion,
            navigationHandler: navigationHandler
        )
    }

    /// Wraps `scene` in its own `NavigationBarLayoutingNavigationController` and
    /// presents it modally on `self.navigationController`. Subscribes to the
    /// scene's view-model navigator so coordinator-level handling can react
    /// to user actions and dismiss when appropriate.
    func modallyPresent<V: ContentView>(
        scene: some Scene<V>,
        animated: Bool = true,
        presentationCompletion: Completion? = nil,
        navigationHandler: @escaping NavigationHandlerModalScene<V.ViewModel>
    ) where V.ViewModel: Navigating {
        let viewModel = scene.viewModel
        // Wrap in a nav controller so the modal sheet has its own navigation
        // bar (and our shared layout owner machinery still works).
        let viewControllerToPresent = NavigationBarLayoutingNavigationController(rootViewController: scene)
        navigationController.present(viewControllerToPresent, animated: animated, completion: presentationCompletion)

        // Bridge the view-model's navigation pulses to the caller's handler,
        // handing the handler a closure it can call to dismiss this modal.
        viewModel.navigator.navigation
            .sinkOnMain { [weak scene] step in
                navigationHandler(step) { animated, navigationCompletion in
                    scene?.dismiss(animated: animated, completion: navigationCompletion)
                }
            }
            .store(in: &cancellables)
    }
}
