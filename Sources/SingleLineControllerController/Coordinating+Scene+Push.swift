// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCombine
import SingleLineControllerNavigation
import UIKit

public extension Coordinating {
    /// Convenience overload: builds the `Scene` from its type + view model and forwards.
    func push<S: Scene<V>, V: ContentView>(
        scene _: S.Type,
        viewModel: V.ViewModel,
        animated: Bool = true,
        navigationPresentationCompletion: Completion? = nil,
        navigationHandler: @escaping (_ step: V.ViewModel.NavigationStep) -> Void
    ) where V.ViewModel: Navigating {
        let scene = S(viewModel: viewModel)
        pushSceneInstance(
            scene,
            animated: animated,
            navigationPresentationCompletion: navigationPresentationCompletion,
            navigationHandler: navigationHandler
        )
    }

    /// Pushes `scene` onto the navigation stack (or sets it as the root if the
    /// stack is empty) and subscribes to its view-model navigator so coordinator
    /// logic can react to user actions and decide when to advance/pop.
    func pushSceneInstance<V: ContentView>(
        _ scene: some Scene<V>,
        animated: Bool = true,
        navigationPresentationCompletion: Completion? = nil,
        navigationHandler: @escaping (_ step: V.ViewModel.NavigationStep) -> Void
    ) where V.ViewModel: Navigating {
        let viewModel = scene.viewModel

        navigationController.setRootViewControllerIfEmptyElsePush(
            viewController: scene,
            animated: animated,
            completion: navigationPresentationCompletion
        )

        // Forward navigation steps from the view-model to the caller's handler.
        // The handler closes over coordinator state and decides whether to push
        // another scene, present a modal, or finish the flow.
        viewModel.navigator.navigation
            .sinkOnMain { navigationHandler($0) }
            .store(in: &cancellables)
    }
}
