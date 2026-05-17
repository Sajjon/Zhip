//
// MIT License
//
// Copyright (c) 2018-2026 Alexander Cyon (https://github.com/sajjon)
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
@MainActor
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
        Container.shared.transactionsUseCase.register { [unowned self] in mainActorOnly { mockTransactions } }
        Container.shared.walletStorageUseCase.register { [unowned self] in mainActorOnly { mockWallet } }
        Container.shared.pincodeUseCase.register { [unowned self] in mainActorOnly { mockPincode } }
        Container.shared.onboardingUseCase.register { [unowned self] in mainActorOnly { mockOnboarding } }
        Container.shared.urlOpener.register { [unowned self] in mainActorOnly { mockUrlOpener } }
        navigationController = NavigationBarLayoutingNavigationController()
        window = TestWindowFactory.make(frame: .init(x: 0, y: 0, width: 320, height: 480))
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
        drainRunLoop() // allow `viewWillAppear` → sections snapshot to apply
        // swiftlint:disable:next force_cast
        return navigationController.viewControllers.first as! Settings
    }

    /// Drives one of the `SettingsNavigation` cases by simulating a real row
    /// selection in the underlying table view (or, for `.closeSettings`,
    /// the right-bar button) — the navigator is no longer stored on the
    /// ViewModel, so injection through `.next(step)` is impossible.
    private func fire(_ step: SettingsNavigation, on scene: Settings) throws {
        switch step {
        case .closeSettings:
            scene.rightBarButtonSubject.send(())
        case .removePincode, .setPincode:
            try selectTableRow(section: 0, row: 0, in: scene.view)
        case .starUsOnGithub:
            try selectTableRow(section: 1, row: 0, in: scene.view)
        case .reportIssueOnGithub:
            try selectTableRow(section: 1, row: 1, in: scene.view)
        case .acknowledgments:
            try selectTableRow(section: 1, row: 2, in: scene.view)
        case .readTermsOfService:
            try selectTableRow(section: 2, row: 0, in: scene.view)
        case .backupWallet:
            try selectTableRow(section: 3, row: 0, in: scene.view)
        case .removeWallet:
            try selectTableRow(section: 3, row: 1, in: scene.view)
        }
        drainRunLoop()
    }

    // MARK: - start

    func test_start_pushesSettingsAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is Settings)
    }

    // MARK: - navigation-bar

    func test_closeSettings_bubblesToParentNavigator() throws {
        let scene = startAndGetScene()
        var received: SettingsCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        try fire(.closeSettings, on: scene)

        if case .closeSettings = received { } else {
            XCTFail("expected .closeSettings, got \(String(describing: received))")
        }
    }

    // MARK: - Section 0 (pincode)

    func test_removePincode_presentsModalWithoutCrashing() throws {
        mockPincode.pincode = try? Pincode(digits: [Digit.zero, .one, .two, .three])
        let scene = startAndGetScene()

        try fire(.removePincode, on: scene)
    }

    func test_setPincode_presentsModalCoordinatorWithoutCrashing() throws {
        let scene = startAndGetScene()

        try fire(.setPincode, on: scene)
    }

    // MARK: - Section 1 (github / acknowledgments)

    func test_starUsOnGithub_invokesOpenUrl() throws {
        let scene = startAndGetScene()

        try fire(.starUsOnGithub, on: scene)

        XCTAssertEqual(mockUrlOpener.openInvocations.count, 1)
        XCTAssertEqual(mockUrlOpener.lastOpenedUrl?.absoluteString, githubUrlString)
    }

    func test_reportIssueOnGithub_invokesOpenUrl() throws {
        let scene = startAndGetScene()

        try fire(.reportIssueOnGithub, on: scene)

        XCTAssertEqual(mockUrlOpener.openInvocations.count, 1)
        XCTAssertEqual(mockUrlOpener.lastOpenedUrl?.absoluteString, "\(githubUrlString)/issues/new")
    }

    func test_acknowledgments_invokesOpenUrl() throws {
        let scene = startAndGetScene()

        try fire(.acknowledgments, on: scene)

        XCTAssertEqual(mockUrlOpener.openInvocations.count, 1)
        XCTAssertEqual(mockUrlOpener.lastOpenedUrl?.absoluteString, UIApplication.openSettingsURLString)
    }

    // MARK: - Section 2 (legal / privacy)

    func test_readTermsOfService_presentsModalWithoutCrashing() throws {
        let scene = startAndGetScene()

        try fire(.readTermsOfService, on: scene)
    }

    // MARK: - Section 3 (wallet)

    func test_backupWallet_presentsModalCoordinatorWithoutCrashing() throws {
        let scene = startAndGetScene()

        try fire(.backupWallet, on: scene)
    }

    func test_removeWallet_presentsConfirmationModal() throws {
        let scene = startAndGetScene()

        try fire(.removeWallet, on: scene)
    }

    func test_confirmWalletRemoval_confirm_emitsRemoveWalletAndClearsState() throws {
        let scene = startAndGetScene()
        let removeWalletEmitted = expectation(description: "removeWallet emitted")
        sut.navigator.navigation.sink { step in
            if case .removeWallet = step { removeWalletEmitted.fulfill() }
        }.store(in: &cancellables)
        try fire(.removeWallet, on: scene)
        drainRunLoop()

        guard
            let nav = navigationController.presentedViewController as? UINavigationController,
            let modal = nav.viewControllers.first as? ConfirmWalletRemoval
        else {
            return XCTFail(
                "Expected ConfirmWalletRemoval modal, got \(String(describing: navigationController.presentedViewController))"
            )
        }

        // Drive the confirm path: tick the "I have backed up" checkbox + tap Confirm.
        try setCheckbox(on: true, in: modal.view)
        try tapButton(at: 0, in: modal.view) // confirmButton

        wait(for: [removeWalletEmitted], timeout: 10)
        XCTAssertEqual(mockTransactions.deleteCachedBalanceCallCount, 1)
        XCTAssertEqual(mockWallet.deleteWalletCallCount, 1)
        XCTAssertEqual(mockPincode.deletePincodeCallCount, 1)
    }
}
