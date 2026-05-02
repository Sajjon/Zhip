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

@testable import AppFeature
import Combine
import Factory
import NanoViewControllerController
import NanoViewControllerDIPrimitives
import UIKit
import XCTest

/// Drives each `SettingsCoordinator` navigation branch so every case in
/// `toSettings`'s big switch is exercised. Modal presentations run against a
/// real `UIWindow` so the presentation path doesn't silently no-op.
final class SettingsCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var mockTransactions: MockTransactionsUseCase!
    private var mockWallet: MockWalletUseCase!
    private var mockPincode: MockPincodeUseCase!
    private var mockOnboarding: MockOnboardingUseCase!
    private var mockUrlOpener: MockUrlOpener!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: SettingsCoordinator!

    override func setUp() {
        super.setUp()
        mockTransactions = MockTransactionsUseCase()
        mockWallet = MockWalletUseCase()
        mockWallet.storedWallet = TestWalletFactory.makeWallet()
        mockPincode = MockPincodeUseCase()
        mockOnboarding = MockOnboardingUseCase()
        mockUrlOpener = MockUrlOpener()
        Container.shared.transactionsUseCase.register { [unowned self] in mockTransactions }
        Container.shared.walletStorageUseCase.register { [unowned self] in mockWallet }
        Container.shared.pincodeUseCase.register { [unowned self] in mockPincode }
        Container.shared.onboardingUseCase.register { [unowned self] in mockOnboarding }
        Container.shared.urlOpener.register { [unowned self] in mockUrlOpener }
        navigationController = NavigationBarLayoutingNavigationController()
        window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = SettingsCoordinator(navigationController: navigationController)
    }

    override func tearDown() {
        drainRunLoop()
        cancellables.removeAll()
        sut = nil
        window.isHidden = true
        window = nil
        navigationController = nil
        Container.shared.manager.reset()
        mockUrlOpener = nil
        mockOnboarding = nil
        mockPincode = nil
        mockWallet = nil
        mockTransactions = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func startAndGetScene() -> Settings {
        sut.start()
        // swiftlint:disable:next force_cast
        return navigationController.viewControllers.first as! Settings
    }

    private func fire(_ step: SettingsNavigation, on scene: Settings) {
        scene.viewModel.navigator.next(step)
        drainRunLoop()
    }

    // MARK: - start

    func test_start_pushesSettingsAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is Settings)
    }

    // MARK: - navigation-bar

    func test_closeSettings_bubblesToParentNavigator() {
        let scene = startAndGetScene()
        var received: SettingsCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        fire(.closeSettings, on: scene)

        if case .closeSettings = received { } else {
            XCTFail("expected .closeSettings, got \(String(describing: received))")
        }
    }

    // MARK: - Section 0 (pincode)

    func test_removePincode_presentsModalWithoutCrashing() {
        mockPincode.pincode = try? Pincode(digits: [Digit.zero, .one, .two, .three])
        let scene = startAndGetScene()

        fire(.removePincode, on: scene)
    }

    func test_setPincode_presentsModalCoordinatorWithoutCrashing() {
        let scene = startAndGetScene()

        fire(.setPincode, on: scene)
    }

    // MARK: - Section 1 (github / acknowledgments)

    func test_starUsOnGithub_invokesOpenUrl() {
        let scene = startAndGetScene()

        fire(.starUsOnGithub, on: scene)

        XCTAssertEqual(mockUrlOpener.openInvocations.count, 1)
        XCTAssertEqual(mockUrlOpener.lastOpenedUrl?.absoluteString, githubUrlString)
    }

    func test_reportIssueOnGithub_invokesOpenUrl() {
        let scene = startAndGetScene()

        fire(.reportIssueOnGithub, on: scene)

        XCTAssertEqual(mockUrlOpener.openInvocations.count, 1)
        XCTAssertEqual(mockUrlOpener.lastOpenedUrl?.absoluteString, "\(githubUrlString)/issues/new")
    }

    func test_acknowledgments_invokesOpenUrl() {
        let scene = startAndGetScene()

        fire(.acknowledgments, on: scene)

        XCTAssertEqual(mockUrlOpener.openInvocations.count, 1)
        XCTAssertEqual(mockUrlOpener.lastOpenedUrl?.absoluteString, UIApplication.openSettingsURLString)
    }

    // MARK: - Section 2 (legal / privacy)

    func test_readTermsOfService_presentsModalWithoutCrashing() {
        let scene = startAndGetScene()

        fire(.readTermsOfService, on: scene)
    }

    func test_changeAnalyticsPermissions_presentsModalWithoutCrashing() {
        let scene = startAndGetScene()

        fire(.changeAnalyticsPermissions, on: scene)
    }

    func test_readCustomECCWarning_presentsModalWithoutCrashing() {
        let scene = startAndGetScene()

        fire(.readCustomECCWarning, on: scene)
    }

    // MARK: - Section 3 (wallet)

    func test_backupWallet_presentsModalCoordinatorWithoutCrashing() {
        let scene = startAndGetScene()

        fire(.backupWallet, on: scene)
    }

    func test_removeWallet_presentsConfirmationModal() {
        let scene = startAndGetScene()

        fire(.removeWallet, on: scene)
    }

    func test_confirmWalletRemoval_confirm_emitsRemoveWalletAndClearsState() {
        let scene = startAndGetScene()
        let removeWalletEmitted = expectation(description: "removeWallet emitted")
        sut.navigator.navigation.sink { step in
            if case .removeWallet = step { removeWalletEmitted.fulfill() }
        }.store(in: &cancellables)
        fire(.removeWallet, on: scene)
        drainRunLoop()

        guard
            let nav = navigationController.presentedViewController as? UINavigationController,
            let modal = nav.viewControllers.first as? ConfirmWalletRemoval
        else {
            return XCTFail(
                "Expected ConfirmWalletRemoval modal, got \(String(describing: navigationController.presentedViewController))"
            )
        }

        modal.viewModel.navigator.next(.confirm)

        wait(for: [removeWalletEmitted], timeout: 10)
        XCTAssertEqual(mockTransactions.deleteCachedBalanceCallCount, 1)
        XCTAssertEqual(mockWallet.deleteWalletCallCount, 1)
        XCTAssertEqual(mockPincode.deletePincodeCallCount, 1)
    }
}
