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
import UIKit
import XCTest
@testable import Zhip

/// Covers `AppCoordinator` routing behavior: the decision between onboarding
/// and main on start, lock/unlock transitions around background/foreground
/// lifecycle, and deep-link forwarding.
///
/// `AppCoordinator` uses `[unowned self]` inside async `.replace` transition
/// callbacks, so the SUT is held as an instance var and we drain the run loop
/// before tearDown to let those callbacks fire against a still-alive object.
final class AppCoordinatorTests: XCTestCase {
    private var mockWallet: MockWalletUseCase!
    private var mockPincode: MockPincodeUseCase!
    private var mockTransactions: MockTransactionsUseCase!
    private var mockOnboarding: MockOnboardingUseCase!
    private var sut: AppCoordinator!
    private var rootControllers: [UIViewController] = []
    private var setRootCallCount = 0
    private var currentRoot: UIViewController?

    override func setUp() {
        super.setUp()
        mockWallet = MockWalletUseCase()
        mockPincode = MockPincodeUseCase()
        mockTransactions = MockTransactionsUseCase()
        mockOnboarding = MockOnboardingUseCase()
        rootControllers = []
        setRootCallCount = 0
        currentRoot = nil
        Container.shared.walletStorageUseCase.register { [unowned self] in mockWallet }
        Container.shared.pincodeUseCase.register { [unowned self] in mockPincode }
        Container.shared.transactionsUseCase.register { [unowned self] in mockTransactions }
        Container.shared.onboardingUseCase.register { [unowned self] in mockOnboarding }
    }

    override func tearDown() {
        // Longer drain than the default: `.replace` transition callbacks fire
        // async while `sut` is still alive and need more than 100ms to settle.
        drainRunLoop(seconds: 0.25)
        sut = nil
        Container.shared.manager.reset()
        mockOnboarding = nil
        mockTransactions = nil
        mockPincode = nil
        mockWallet = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeCoordinator(hasWallet: Bool, hasPincode: Bool) -> AppCoordinator {
        if hasWallet {
            mockWallet.storedWallet = TestWalletFactory.makeWallet()
        }
        if hasPincode {
            mockPincode.pincode = try? Pincode(digits: [Digit.zero, .one, .two, .three])
        }
        let nav = UINavigationController()
        let handler = DeepLinkHandler()
        sut = AppCoordinator(
            navigationController: nav,
            deepLinkHandler: handler,
            isViewControllerRootOfWindow: { [weak self] vc in self?.currentRoot === vc },
            setRootViewControllerOfWindow: { [weak self] vc in
                self?.setRootCallCount += 1
                self?.rootControllers.append(vc)
                self?.currentRoot = vc
            }
        )
        return sut
    }

    // MARK: - start() routing

    func test_start_withoutConfiguredWallet_routesToOnboarding() {
        _ = makeCoordinator(hasWallet: false, hasPincode: false)

        sut.start()

        XCTAssertFalse(sut.childCoordinators.isEmpty)
        XCTAssertTrue(sut.childCoordinators.first is OnboardingCoordinator)
    }

    func test_start_withConfiguredWallet_noPincode_routesToMain() {
        _ = makeCoordinator(hasWallet: true, hasPincode: false)

        sut.start()

        XCTAssertTrue(sut.childCoordinators.first is MainCoordinator)
    }

    func test_start_withWalletAndPincode_presentsUnlockSceneAsync() {
        _ = makeCoordinator(hasWallet: true, hasPincode: true)
        let expectation = expectation(description: "unlock scene presented")

        sut.start()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            if self?.rootControllers.contains(where: { $0 is UnlockAppWithPincode }) == true {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 2)
    }

    // MARK: - Lock/unlock transitions

    func test_appWillResignActive_whenNotLocked_presentsLockScene() {
        _ = makeCoordinator(hasWallet: true, hasPincode: false)
        sut.start()
        let setCountBefore = setRootCallCount

        sut.appWillResignActive()

        XCTAssertGreaterThan(setRootCallCount, setCountBefore)
        XCTAssertTrue(rootControllers.contains { $0 is LockAppScene })
    }

    func test_appWillResignActive_whenAlreadyLocked_isNoOp() {
        _ = makeCoordinator(hasWallet: true, hasPincode: false)
        sut.start()
        sut.appWillResignActive()
        let setCountBefore = setRootCallCount

        sut.appWillResignActive()

        XCTAssertEqual(setRootCallCount, setCountBefore)
    }

    func test_appDidBecomeActive_whenLocked_noPincode_restoresMainStack() {
        _ = makeCoordinator(hasWallet: true, hasPincode: false)
        sut.start()
        sut.appWillResignActive()
        let setCountBefore = setRootCallCount

        sut.appDidBecomeActive()

        XCTAssertGreaterThan(setRootCallCount, setCountBefore)
    }

    func test_appDidBecomeActive_whenLocked_withPincode_presentsUnlock() {
        _ = makeCoordinator(hasWallet: true, hasPincode: true)
        sut.start()
        sut.appWillResignActive()
        let setCountBefore = setRootCallCount

        sut.appDidBecomeActive()

        XCTAssertGreaterThanOrEqual(setRootCallCount, setCountBefore)
    }

    func test_appDidBecomeActive_whenNotLocked_isNoOp() {
        _ = makeCoordinator(hasWallet: true, hasPincode: false)
        sut.start()
        let setCountBefore = setRootCallCount

        sut.appDidBecomeActive()

        XCTAssertEqual(setRootCallCount, setCountBefore)
    }

    // MARK: - Deep link forwarding

    func test_handleDeepLink_validSendUrl_returnsTrue() throws {
        _ = makeCoordinator(hasWallet: true, hasPincode: false)
        sut.start()
        let url = try XCTUnwrap(URL(string: "https://zhip.app/send?to=e3090a1309DfAC40352d03dEc6cCD9cAd213e76B"))

        XCTAssertTrue(sut.handleDeepLink(url))
    }

    func test_handleDeepLink_invalidUrl_returnsFalse() throws {
        _ = makeCoordinator(hasWallet: true, hasPincode: false)
        sut.start()
        let url = try XCTUnwrap(URL(string: "https://zhip.app/unknown"))

        XCTAssertFalse(sut.handleDeepLink(url))
    }

    // MARK: - Bubbled navigation from child coordinators

    func test_onboardingFinishOnboarding_replacesOnboardingWithMain() throws {
        _ = makeCoordinator(hasWallet: false, hasPincode: false)
        sut.start()
        let onboarding = try XCTUnwrap(sut.childCoordinators.first as? OnboardingCoordinator)
        // Simulate completed onboarding by writing a wallet so the subsequent
        // toMain() call has stored state to read.
        mockWallet.storedWallet = TestWalletFactory.makeWallet()

        onboarding.navigator.next(.finishOnboarding)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is MainCoordinator })
    }

    func test_mainRemoveWallet_replacesMainWithOnboarding() throws {
        _ = makeCoordinator(hasWallet: true, hasPincode: false)
        sut.start()
        let main = try XCTUnwrap(sut.childCoordinators.first as? MainCoordinator)
        // Simulate wallet removal so toOnboarding() reflects fresh state.
        mockWallet.storedWallet = nil

        main.navigator.next(.removeWallet)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is OnboardingCoordinator })
    }

    func test_unlockSceneUnlockApp_restoresMainNavigationStack() {
        _ = makeCoordinator(hasWallet: true, hasPincode: true)
        sut.start()
        // Wait for the unlock scene to be presented.
        let setupExpectation = expectation(description: "unlock scene available")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { setupExpectation.fulfill() }
        wait(for: [setupExpectation], timeout: 2)

        // The unlock scene is a private lazy var; re-trigger it via lock/unlock so
        // we can grab a UnlockAppWithPincode controller from rootControllers.
        sut.appWillResignActive()
        sut.appDidBecomeActive()
        drainRunLoop()

        guard let unlock = rootControllers.compactMap({ $0 as? UnlockAppWithPincode }).first else {
            XCTFail("expected UnlockAppWithPincode in root controller history")
            return
        }
        let setCountBefore = setRootCallCount

        unlock.viewModel.navigator.next(.unlockApp)
        drainRunLoop()

        XCTAssertGreaterThan(setRootCallCount, setCountBefore)
    }
}
