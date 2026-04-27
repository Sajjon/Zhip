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
import SingleLineControllerNavigation

// MARK: - Start Child Coordinator

extension Coordinating {
    /// Starts a new temporary flow with a new Coordinator.
    ///
    /// "Temporary" meaning that it's expected that the new coordinator (the "child")
    /// is expected to finish and when it finishes the calling coordinator (the "parent")
    /// will remove it from its `childCoordinator` collection.
    ///
    /// The child coordinator initialized by the parent call-site, in the `makeCoordinator` closure.
    /// This function initializes a new `UINavigationController` that is passed into the
    /// by the `makeCoordinator` closure as an argument.
    ///
    /// Optionally the parent can pass a `didStart` closure which will be invoked with the child
    /// coordinator has finished presenting its first ViewController.
    ///
    /// The `navigationHandler` closure is mandatory and should contain navigation logic where the
    /// parent handles each `NavigationStep` emitted by the child. Said `NavigationStep` is the first
    /// argument of the `navigationHandler` closure, the second argument being a closure the parent
    /// **should** call when it finishes this temporary flow. It is this call that removes the child
    /// coordinator from the parents `childCoordinator` array and also dismisses navigation stack.
    ///
    /// - Parameters:
    ///   - makeCoordinator: **Required** closure in which you should initialize the new child coordinator using the
    ///       `UINavigationController` being created by this function, passed as an argument in the closure.
    ///   - newNavController: The new `UINavigationController` created by this function, used when creating the child
    /// Coordinator.
    ///   - didStart: Optional Closure in which you can pass logic to be executed when the new child coordinator
    ///       has finished presentation of its root ViewController. In most cases this is not needed.
    ///   - navigationHandler: **Required** closure in which you should handle all navigation steps emitted by the
    ///       new child coordinator. This closure has two arguments:
    ///   - step: The navigation step emitted by this new child coordinator. Handled by `navigationHandler` in this
    /// parent coordinator.
    ///   - dismiss: Closure you **should** call when you want to end this temporary flow, which dismisses the
    /// navigation
    ///           stack and removes the child coordinator from its parent (the coordinator instance you called this
    /// method on).
    func presentModalCoordinator<C: Coordinating & Navigating>(
        makeCoordinator: (_ newNavController: UINavigationController) -> C,
        didStart: Completion? = nil,
        navigationHandler: @escaping (_ step: C.NavigationStep, _ dismiss: (_ animateDismiss: Bool) -> Void) -> Void
    ) {
        // Initialize a new NavigationController to be passed to the new child coordinator
        let newModalNavigationController = NavigationBarLayoutingNavigationController()

        // Initialize the new child coordinator, by invoking the `makeCoordinator` closure,
        // passing the newly created NavigationController
        let child = makeCoordinator(newModalNavigationController)

        // Add the child coordinator to the parents array of children.
        childCoordinators.append(child)

        // Start the child coordinator (which is responsible for setting up its root UIViewController and presenting it)
        // and pass along the `didStart` closure, which the child should invoke or forward it along until some other
        // entity finally invokes.
        child.start(didStart: didStart)

        // Present the new NavigationController. The child coordinator is responsible for presenting its own root
        // ViewController
        navigationController.present(newModalNavigationController, animated: true, completion: nil)

        // Subscribe to the navigation steps emitted by the child coordinator
        // And invoke the `navigationHandler` closure passed in to this method.
        // When invoking the `navigationHandler` besides passing the `navigationStep`
        // from the `child.navigator` we also pass a trailing closure, the `((_ animateDismiss: Bool) -> Void)`
        // closure, which the parent coordinator _SHOULD_ invoke when it wants to finish this
        // temporary child coordinator.
        child.navigator.navigation
            .sinkOnMain { [
                unowned self,
                unowned newModalNavigationController,
                unowned child
            ] navigationStep in
                navigationHandler(navigationStep) { animated in
                    // Clean up navigation stack
                    newModalNavigationController.dismiss(animated: animated, completion: nil)
                    // Clean up coordinator stack
                    self.remove(childCoordinator: child)
                }
            }
            .store(in: &cancellables)
    }
}
