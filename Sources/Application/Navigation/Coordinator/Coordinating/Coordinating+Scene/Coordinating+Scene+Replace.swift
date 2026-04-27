//
// MIT License
//
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Combine
import SingleLineControllerCombine
import UIKit

/// MARKL - REPLACE
extension Coordinating {
    /// Closure shape used by `modallyPresent(...)` and `replaceAllScenes(...)`:
    /// receives the next navigation step plus a `DismissScene` callback the
    /// handler can invoke to dismiss the presenting scene with optional animation.
    typealias NavigationHandlerModalScene<N: Navigating> = (N.NavigationStep, @escaping DismissScene) -> Void

    /// This method is used to replace ALL scenes in the navigation stack in current coordinating context.
    ///
    /// - Parameters:
    ///   - scene: A `Scene` (UIViewController) to set as the single VC.
    ///   - animated: Whether to animate the presentation of the scene or not.
    ///   - navigationHandler: **Required** closure handling the navigation steps emitted by the scene's ViewModel.
    func replaceAllScenes<S: Scene<V>, V: ContentView>(
        with _: S.Type,
        viewModel: V.ViewModel,
        animated: Bool = true,
        whenReplacingFinished: Completion? = nil,
        navigationHandler: @escaping NavigationHandlerModalScene<V.ViewModel>
//        navigationHandler: @escaping (_ step: V.ViewModel.NavigationStep, _ dismiss: @escaping DismissScene) -> Void
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

    /// This method is used to replace ALL scenes in the navigation stack in current coordinating context.
    ///
    /// - Parameters:
    ///   - scene: A `Scene` (UIViewController) to set as the single VC.
    ///   - animated: Whether to animate the presentation of the scene or not.
    ///   - navigationHandler: **Required** closure handling the navigation steps emitted by the scene's ViewModel.
    func replaceAllScenes<V: ContentView>(
        with scene: some Scene<V>,
        animated: Bool = true,
        whenReplacingFinished: Completion? = nil,
//        navigationHandler: @escaping (_ step: V.ViewModel.NavigationStep, _ dismiss: @escaping DismissScene) -> Void
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
                    print("⛱ replaceAllScenes dismissCompletion of navigationHandler")
                    scene?.dismiss(animated: animated, completion: navigationCompletion)
                }
            }
            .store(in: &cancellables)
    }
}

extension UINavigationController {
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
            print("replacing VCs with one of type: \(type(of: viewController))")
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

extension UINavigationController {
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
