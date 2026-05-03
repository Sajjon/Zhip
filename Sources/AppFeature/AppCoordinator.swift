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
import Factory
import NanoViewControllerCombine
import NanoViewControllerDIPrimitives
import NanoViewControllerNavigation
import UIKit
import Zesame

/// Navigation steps the app-level coordinator itself can emit. Empty because
/// `AppCoordinator` is the root — it has nowhere "above" to report back to.
public enum AppCoordinatorNavigationStep: Sendable {}

/// Root coordinator owning the app's top-level flow: deciding between onboarding
/// and the main wallet experience on launch, and the lock/unlock transitions when
/// the app resigns active / returns active.
public final class AppCoordinator: BaseCoordinator<AppCoordinatorNavigationStep> {
    /// Handles incoming deep links and decides whether they should be buffered
    /// (while the lock screen is visible) or delivered immediately. Resolved
    /// via Factory so `AppDelegate` (which receives universal-link URLs and
    /// forwards them via `handle(url:)`) and this coordinator share the same
    /// singleton handler — the buffered link from before unlock must be
    /// observable by the unlock flow.
    @Injected(\.deepLinkHandler) private var deepLinkHandler: DeepLinkHandler

    @Injected(\.walletStorageUseCase) private var walletStorageUseCase: WalletStorageUseCase
    @Injected(\.pincodeUseCase) private var pincodeUseCase: PincodeUseCase
    @Injected(\.clock) private var clock: Clock

    /// Splash-style lock scene shown while the app is in the background.
    private lazy var lockAppScene = LockAppScene()

    /// The pincode-entry scene shown when the user returns to the app and a pincode
    /// has been configured. Lazily constructed so the use case and navigation
    /// subscription only exist once the scene is actually needed.
    private lazy var unlockAppScene: UnlockAppWithPincode = {
        let viewModel = UnlockAppWithPincodeViewModel()
        let scene = UnlockAppWithPincode(viewModel: viewModel)

        scene.viewModel.navigator.navigation
            .sinkOnMain { [weak self] userDid in
                switch userDid {
                case .unlockApp:
                    self?.appIsUnlockedEmitBufferedDeeplinks()
                    self?.restoreMainNavigationStack()
                }
            }
            .store(in: &cancellables)
        return scene
    }()

    /// Window-level root controller setter. Passed in rather than synthesized so
    /// tests can capture the transitions without a real UIWindow.
    private let __setRootViewControllerOfWindow: (UIViewController) -> Void

    /// Returns `true` if the given view controller is currently the window's root.
    /// Used to distinguish the lock vs. unlock vs. main stack states.
    private let isViewControllerRootOfWindow: (UIViewController) -> Bool

    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - navigationController: the wallet/onboarding navigation stack.
    ///   - isViewControllerRootOfWindow: window-level root predicate.
    ///   - setRootViewControllerOfWindow: window-level root setter.
    public init(
        navigationController: UINavigationController,
        isViewControllerRootOfWindow: @escaping (UIViewController) -> Bool,
        setRootViewControllerOfWindow: @escaping (UIViewController) -> Void
    ) {
        __setRootViewControllerOfWindow = setRootViewControllerOfWindow
        self.isViewControllerRootOfWindow = isViewControllerRootOfWindow
        super.init(navigationController: navigationController)
    }

    /// Routes the user to either the main wallet experience (with the unlock
    /// scene if needed) or the onboarding flow, depending on whether a wallet is
    /// already configured in secure storage.
    override public func start(didStart _: Completion? = nil) {
        if walletStorageUseCase.hasConfiguredWallet {
            toMain(displayUnlockSceneIfNeeded: true)
        } else {
            toOnboarding()
        }
    }
}

// MARK: - Private

private extension AppCoordinator {
    func toOnboarding() {
        let onboarding = OnboardingCoordinator(
            navigationController: navigationController
        )

        start(coordinator: onboarding, transition: .replace) { [weak self] userDid in
            switch userDid {
            case .finishOnboarding: self?.toMain()
            }
        }
    }

    func toMain(displayUnlockSceneIfNeeded displayUnlockScene: Bool = false) {
        let main = MainCoordinator(
            navigationController: navigationController,
            deeplinkedTransaction: deepLinkHandler.navigation.map(\.asTransaction).filterNil().eraseToAnyPublisher()
        )

        start(coordinator: main, transition: .replace, didStart: { [weak self] in
            if displayUnlockScene {
                self?.toUnlockAppWithPincodeIfNeeded()
            }
        }, navigationHandler: { [weak self] userDid in
            switch userDid {
            case .removeWallet: self?.toOnboarding()
            }
        })
    }

    var hasConfiguredPincode: Bool {
        pincodeUseCase.hasConfiguredPincode
    }

    func toUnlockAppWithPincodeIfNeeded() {
        guard hasConfiguredPincode, !isCurrentlyPresentingUnLockScene else {
            return
        }

        setRootViewControllerOfWindow(to: unlockAppScene)
    }
}

private extension AppCoordinator {
    func restoreMainNavigationStack() {
        setRootViewControllerOfWindow(to: navigationController)
    }

    func setRootViewControllerOfWindow(to viewController: UIViewController) {
        __setRootViewControllerOfWindow(viewController)
    }
}

// MARK: - Lock app with pincode

public extension AppCoordinator {
    func appWillResignActive() {
        lockApp()
    }

    func appDidBecomeActive() {
        unlockApp()
    }
}

// MARK: - Private Lock app with pincode

private extension AppCoordinator {
    func lockApp() {
        if isCurrentlyPresentingUnLockScene || isCurrentlyPresentingLockScene {
            return
        }
        deepLinkHandler.appIsLockedBufferDeeplinks()
        setRootViewControllerOfWindow(to: lockAppScene)
    }

    func unlockApp() {
        if isCurrentlyPresentingUnLockScene { return }
        guard isCurrentlyPresentingLockScene else { return }
        if hasConfiguredPincode {
            toUnlockAppWithPincodeIfNeeded()
        } else {
            restoreMainNavigationStack()
            appIsUnlockedEmitBufferedDeeplinks()
        }
    }

    var isCurrentlyPresentingUnLockScene: Bool {
        guard hasConfiguredPincode else { return false }
        return isViewControllerRootOfWindow(unlockAppScene)
    }

    var isCurrentlyPresentingLockScene: Bool {
        isViewControllerRootOfWindow(lockAppScene)
    }

    func appIsUnlockedEmitBufferedDeeplinks(delayInSeconds: TimeInterval = 0.2) {
        // `clock.schedule(after:_:)` takes a @Sendable closure but the
        // production clock fires on the main thread (MainQueueClock).
        // Hop back to the main actor explicitly so the @MainActor-isolated
        // `deepLinkHandler` access type-checks under Swift 6 concurrency.
        clock.schedule(after: delayInSeconds) { [weak self] in
            MainActor.assumeIsolated {
                self?.deepLinkHandler.appIsUnlockedEmitBufferedDeeplinks()
            }
        }
    }
}

// MARK: - DeepLink Handler

public extension AppCoordinator {
    /// returns: `true` if the delegate successfully handled the request or `false` if the attempt to open the URL
    /// resource failed.
    func handleDeepLink(_ url: URL) -> Bool {
        deepLinkHandler.handle(url: url)
    }
}
