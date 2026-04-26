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

import UIKit

extension Coordinating {
    /// Identity-based lookup of `child` in `childCoordinators`. Identity (rather
    /// than equality) because coordinators are `AnyObject`-only.
    func firstIndexOf(child: Coordinating) -> Int? {
        childCoordinators.firstIndex(where: { $0 === child })
    }

    /// Removes `child` from `childCoordinators`. Crashes (`incorrectImplementation`)
    /// if the child cannot be found — that would mean a coordinator was started
    /// without being added to the parent's stack and we'd leak it.
    func remove(childCoordinator child: Coordinating) {
        guard let index = firstIndexOf(child: child) else {
            incorrectImplementation(
                "Should and must be able to find child coordinator and remove it in order to avoid memory leaks."
            )
        }
        childCoordinators.remove(at: index)

        // Sanity-check that we removed the only copy. Duplicate appends would
        // produce a leak that survives this call — fail loudly during dev.
        guard firstIndexOf(child: child) == nil else {
            incorrectImplementation(
                "Child coordinators should not contain the instance of `\(child)` after it have been removed"
            )
        }
    }

    /// Recursively descends through `childCoordinators` and returns the
    /// deepest active coordinator (the one whose own `childCoordinators` is empty).
    var topMostCoordinator: Coordinating {
        guard let last = childCoordinators.last else { return self }
        return last.topMostCoordinator
    }

    /// The `AbstractController` currently visible on screen, taking into
    /// account modal presentations. Used by Toast presentation so a toast
    /// is shown on top of any modal that's currently up.
    var topMostScene: AbstractController? {
        if let presentedController = topMostCoordinator.navigationController.presentedViewController {
            if let presentedNavigationController = presentedController as? UINavigationController {
                return presentedNavigationController.topViewController as? AbstractController
            } else {
                return presentedController as? AbstractController
            }
        } else {
            return topMostCoordinator.navigationController.topViewController as? AbstractController
        }
    }
}
