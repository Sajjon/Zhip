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

/// `UINavigationController` subclass that re-applies a per-scene `NavigationBarLayout`
/// at every navigation transition (push, pop, present, will-appear).
///
/// Why a subclass? `UINavigationBar` is a single shared chrome surface, but each
/// scene wants its own (possibly hidden, possibly translucent) configuration.
/// Without this glue you'd see flashes of stale styling between transitions.
///
/// Original technique: https://stackoverflow.com/a/46895818/1311272
public final class NavigationBarLayoutingNavigationController: UINavigationController {
    /// The layout most recently applied to the nav bar.
    /// `SceneController.applyLayoutIfNeeded()` reads this to skip re-applying an
    /// identical layout — avoids needless animation flickers.
    public var lastLayout: NavigationBarLayout?

    // MARK: - Overridden Methods

    /// Re-applies the top scene's layout when the nav controller itself reappears
    /// (e.g. after a modal dismissal), and installs `self` as the gesture-recognizer
    /// delegate so the swipe-back recognizer can coexist with custom gestures.
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyLayoutToViewController(topViewController)
        interactivePopGestureRecognizer?.delegate = self
    }

    /// Applies the *destination* scene's layout *before* the push runs, so the bar
    /// already has the right look when the animation starts (no mid-transition flicker).
    override public func pushViewController(_ viewController: UIViewController, animated: Bool) {
        applyLayoutToViewController(viewController)
        super.pushViewController(viewController, animated: animated)
    }

    /// Same trick as `pushViewController` but for modal presentation — apply first,
    /// then call super.
    override public func present(
        _ viewControllerToPresent: UIViewController,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        applyLayoutToViewController(viewControllerToPresent)
        super.present(viewControllerToPresent, animated: animated, completion: completion)
    }

    /// Pops the top VC, then applies the *new* top VC's layout. Order matters:
    /// `topViewController` is the destination only after `super.popViewController` returns.
    @discardableResult
    override public func popViewController(animated: Bool) -> UIViewController? {
        let viewController = super.popViewController(animated: animated)
        applyLayoutToViewController(topViewController)
        return viewController
    }

    /// Pops to a specific VC and applies that VC's layout.
    @discardableResult
    override public func popToViewController(
        _ viewController: UIViewController,
        animated: Bool
    ) -> [UIViewController]? {
        let result = super.popToViewController(viewController, animated: animated)
        applyLayoutToViewController(viewController)
        return result
    }

    /// Pops to the root and applies whatever the new top VC needs.
    @discardableResult
    override public func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let result = super.popToRootViewController(animated: animated)
        applyLayoutToViewController(topViewController)
        return result
    }
}

// MARK: - Public Methods

public extension NavigationBarLayoutingNavigationController {
    /// Reads the layout from a `NavigationBarLayoutOwner` (if the VC opts in) and
    /// applies it. No-op if the VC doesn't own a layout — the previous layout stays.
    func applyLayoutToViewController(_ viewController: UIViewController?) {
        guard let viewController, let barLayoutOwner = viewController as? NavigationBarLayoutOwner else { return }
        applyLayout(barLayoutOwner.navigationBarLayout)
    }

    /// Applies a `NavigationBarLayout` to the underlying `UINavigationBar`,
    /// records it as `lastLayout`, and updates the bar's hidden/animated state.
    func applyLayout(_ layout: NavigationBarLayout) {
        lastLayout = navigationBar.applyLayout(layout)
        let isHidden = layout.visibility.isHidden
        let animated = layout.visibility.animated
        setNavigationBarHidden(isHidden, animated: animated)
    }
}

// MARK: - UIGestureRecognizerDelegate Methods

extension NavigationBarLayoutingNavigationController: UIGestureRecognizerDelegate {}
public extension NavigationBarLayoutingNavigationController {
    /// Lets the swipe-back recogniser run alongside other recognisers — required
    /// when scenes have their own pan gestures (e.g. cards, sheets).
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        true
    }

    /// Other screen-edge pan recognisers must lose to the system swipe-back so
    /// edge-swipes always pop instead of triggering a custom edge gesture.
    func gestureRecognizer(
        _: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}
