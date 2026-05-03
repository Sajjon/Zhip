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

import AppFeature
import NanoViewControllerController
import UIKit

/// Owns the app's single window + the root `AppCoordinator`. The `UIScene`
/// lifecycle replaces the legacy AppDelegate-only window pattern: window
/// lives on the scene (so multi-window iPad / Catalyst contexts are addressable
/// later), and lock/unlock + deeplink delivery hook the per-scene events.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// The window installed on the scene. iOS 13+ best practice — never use
    /// the deprecated `UIScreen.main.bounds` constructor; `UIWindow(windowScene:)`
    /// inherits the correct frame for the scene's display.
    var window: UIWindow?

    /// Lazy because we need the scene + window to exist first so the coordinator
    /// can install/replace the window's rootViewController.
    private lazy var appCoordinator: AppCoordinator = {
        let navigationController = NavigationBarLayoutingNavigationController()
        window?.rootViewController = navigationController
        return AppCoordinator(
            navigationController: navigationController,
            isViewControllerRootOfWindow: { [weak window] in
                window?.rootViewController == $0
            },
            setRootViewControllerOfWindow: { [weak window] in
                window?.rootViewController = $0
            }
        )
    }()

    // MARK: - Scene lifecycle

    /// Called when the scene is first attached to its session. iOS may also
    /// pass deeplink URLs / user activities in `connectionOptions`; we forward
    /// those after `appCoordinator.start()`.
    func scene(
        _ scene: UIScene,
        willConnectTo _: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        appCoordinator.start()
        installDismissKeyboardOnTapGesture(on: window)
        window.makeKeyAndVisible()

        // If the scene was launched directly from a universal link, deliver
        // it now. The cold-start case lands here; warm re-entries come via
        // `scene(_:continue:)` below.
        for activity in connectionOptions.userActivities {
            handle(userActivity: activity)
        }
    }

    /// Universal-link / Handoff entry point on warm scene re-entries.
    func scene(_: UIScene, continue userActivity: NSUserActivity) {
        handle(userActivity: userActivity)
    }

    /// Installs the privacy-cover lock screen when the scene is genuinely
    /// going to background.
    ///
    /// `sceneDidEnterBackground` (not `sceneWillResignActive`) is the right
    /// hook on iOS 13+: `WillResignActive` also fires on transient
    /// interruptions like Control Center swipes, incoming-call banners, and
    /// FaceID prompts, which would cause the lock cover to flash during
    /// regular use. `DidEnterBackground` only fires when the app is
    /// actually backgrounded — matching the pre-iOS-13 behaviour of
    /// `applicationDidEnterBackground`.
    func sceneDidEnterBackground(_: UIScene) {
        appCoordinator.appWillResignActive()
    }

    /// Inverse of `sceneDidEnterBackground` — coordinator dismisses the
    /// lock screen (or transitions to pincode entry if one is configured).
    /// `sceneWillEnterForeground` rather than `sceneDidBecomeActive` so the
    /// unlock transition starts before the user sees the (possibly stale)
    /// last-frame snapshot the system shows during the foreground animation.
    func sceneWillEnterForeground(_: UIScene) {
        appCoordinator.appDidBecomeActive()
    }
}

// MARK: - Private

private extension SceneDelegate {
    /// Forwards a user activity (only universal-link `NSUserActivityTypeBrowsingWeb`
    /// is interesting here) to the coordinator's deep-link handler.
    func handle(userActivity: NSUserActivity) {
        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL
        else { return }
        _ = appCoordinator.handleDeepLink(incomingURL)
    }

    /// Installs a tap recognizer on the window that calls `endEditing(true)`
    /// — i.e. tap anywhere outside the focused text field dismisses the
    /// keyboard. Replaces the previous IQKeyboardManager dependency.
    ///
    /// `cancelsTouchesInView = false` is the magic bit: the recognizer
    /// detects taps but doesn't swallow them, so buttons / table cells /
    /// other tap targets still receive their hits.
    func installDismissKeyboardOnTapGesture(on window: UIWindow) {
        let tap = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        window.addGestureRecognizer(tap)
    }
}
