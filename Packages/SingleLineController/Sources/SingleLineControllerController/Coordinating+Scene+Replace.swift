// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCombine
import SingleLineControllerNavigation
import UIKit

public extension Coordinating {
    /// Closure shape used by `modallyPresent(...)` and `replaceAllScenes(...)`:
    /// receives the next navigation step plus a `DismissScene` callback the
    /// handler can invoke to dismiss the presenting scene with optional animation.
    typealias NavigationHandlerModalScene<N: Navigating> = (N.NavigationStep, @escaping DismissScene) -> Void

    /// Replaces every scene in the current navigation stack with `scene`.
    func replaceAllScenes<S: Scene<V>, V: ContentView>(
        with _: S.Type,
        viewModel: V.ViewModel,
        animated: Bool = true,
        whenReplacingFinished: Completion? = nil,
        navigationHandler: @escaping NavigationHandlerModalScene<V.ViewModel>
    ) where V.ViewModel: Navigating {
        // Create a new instance of the `Scene`, injecting its ViewModel
        let scene = S(viewModel: viewModel)

        replaceAllScenes(
            with: scene,
            animated: animated,
            whenReplacingFinished: whenReplacingFinished,
            navigationHandler: navigationHandler
        )
    }

    /// Instance-level variant of `replaceAllScenes(with:viewModel:...)`.
    func replaceAllScenes<V: ContentView>(
        with scene: some Scene<V>,
        animated: Bool = true,
        whenReplacingFinished: Completion? = nil,
        navigationHandler: @escaping NavigationHandlerModalScene<V.ViewModel>
    ) where V.ViewModel: Navigating {
        let viewModel = scene.viewModel

        let oldVCs = navigationController.viewControllers

        navigationController.setRootViewControllerIfEmptyElsePush(
            viewController: scene,
            animated: animated,
            forceReplaceAllVCsInsteadOfPush: true
        ) {
            whenReplacingFinished?()
            oldVCs.forEach { $0.dismiss(animated: false, completion: nil) }
        }

        viewModel.navigator.navigation
            .sinkOnMain { [weak scene] step in
                navigationHandler(step) { animated, navigationCompletion in
                    scene?.dismiss(animated: animated, completion: navigationCompletion)
                }
            }
            .store(in: &cancellables)
    }
}

public extension UINavigationController {
    /// Smart push: pushes `viewController` if there is already at least one
    /// VC on the stack; otherwise sets it as the single root. Pass
    /// `forceReplaceAllVCsInsteadOfPush: true` to clear the stack
    /// regardless. Calls `completion` after the transition (animated or not).
    func setRootViewControllerIfEmptyElsePush(
        viewController: UIViewController,
        animated: Bool = true,
        forceReplaceAllVCsInsteadOfPush: Bool = false,
        completion: Completion? = nil
    ) {
        if viewControllers.isEmpty || forceReplaceAllVCsInsteadOfPush {
            setViewControllers([viewController], animated: animated)
        } else {
            pushViewController(viewController, animated: animated)
        }

        // Add extra functionality to pass a "completion" closure even for `push`ed ViewControllers.
        guard let completion else { return }
        // If there is no transition coordinator (i.e. we set VCs without an
        // animation context), schedule the completion for the next runloop
        // tick so callers observe a fully-applied stack.
        guard animated, let coordinator = transitionCoordinator else {
            DispatchQueue.main.async { completion() }
            return
        }
        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }
}

public extension UINavigationController {
    /// `popToRootViewController(animated:)` with a completion callback that
    /// fires after the pop animation finishes (or on the next runloop tick if
    /// no transition coordinator is available).
    func popToRootViewController(animated: Bool = true, completion: @escaping Completion) {
        popToRootViewController(animated: animated)
        guard animated, let coordinator = transitionCoordinator else {
            DispatchQueue.main.async { completion() }
            return
        }
        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }
}
