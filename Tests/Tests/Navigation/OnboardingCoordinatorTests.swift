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
import UIKit
import XCTest

/// Covers `OnboardingCoordinator` state-machine routing. Each resumable-state
/// combo is seeded via `MockOnboardingUseCase`/`MockWalletUseCase` so every
/// branch in `toNextStep()` runs.
final class OnboardingCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var mockTransactions: MockTransactionsUseCase!
    private var mockWallet: MockWalletUseCase!
    private var mockPincode: MockPincodeUseCase!
    private var mockOnboarding: MockOnboardingUseCase!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: OnboardingCoordinator!

    override func setUp() {
        super.setUp()
        mockTransactions = MockTransactionsUseCase()
        mockWallet = MockWalletUseCase()
        mockPincode = MockPincodeUseCase()
        mockOnboarding = MockOnboardingUseCase()
        Container.shared.transactionsUseCase.register { [unowned self] in mockTransactions }
        Container.shared.walletStorageUseCase.register { [unowned self] in mockWallet }
        Container.shared.pincodeUseCase.register { [unowned self] in mockPincode }
        Container.shared.onboardingUseCase.register { [unowned self] in mockOnboarding }
        navigationController = NavigationBarLayoutingNavigationController()
        window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = OnboardingCoordinator(navigationController: navigationController)
    }

    override func tearDown() {
        drainRunLoop()
        cancellables.removeAll()
        sut = nil
        window.isHidden = true
        window = nil
        navigationController = nil
        Container.shared.manager.reset()
        mockOnboarding = nil
        mockPincode = nil
        mockWallet = nil
        mockTransactions = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func top<T>(as _: T.Type, file _: StaticString = #filePath, line _: UInt = #line) -> T? {
        navigationController.viewControllers.last as? T
    }

    // MARK: - start

    func test_start_pushesWelcomeAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is Welcome)
    }

    // MARK: - Welcome.start → routes based on onboarding state

    func test_welcomeStart_whenNoTermsAccepted_pushesTermsOfService() throws {
        sut.start()
        let welcome = try XCTUnwrap(top(as: Welcome.self))

        welcome.viewModel.navigator.next(.start)
        drainRunLoop()

        XCTAssertTrue(top(as: TermsOfService.self) != nil)
    }

    func test_welcomeStart_whenTermsAcceptedNoWallet_startsChooseWalletChild() throws {
        mockOnboarding.hasAcceptedTermsOfService = true
        sut.start()
        let welcome = try XCTUnwrap(top(as: Welcome.self))

        welcome.viewModel.navigator.next(.start)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is ChooseWalletCoordinator })
    }

    func test_welcomeStart_whenTermsAcceptedAndWalletExistsAndPincodePrompted_startsSetPincode() throws {
        mockOnboarding.hasAcceptedTermsOfService = true
        mockWallet.storedWallet = TestWalletFactory.makeWallet()
        mockOnboarding.shouldPromptUserToChosePincode = true
        sut.start()
        let welcome = try XCTUnwrap(top(as: Welcome.self))

        welcome.viewModel.navigator.next(.start)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is SetPincodeCoordinator })
    }

    func test_welcomeStart_whenEverythingDone_bubblesFinishOnboarding() throws {
        mockOnboarding.hasAcceptedTermsOfService = true
        mockWallet.storedWallet = TestWalletFactory.makeWallet()
        mockOnboarding.shouldPromptUserToChosePincode = false
        sut.start()
        var received: OnboardingCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let welcome = try XCTUnwrap(top(as: Welcome.self))

        welcome.viewModel.navigator.next(.start)
        drainRunLoop()

        if case .finishOnboarding = received {} else {
            XCTFail("expected .finishOnboarding, got \(String(describing: received))")
        }
    }

    // MARK: - TermsOfService → ChooseWallet

    func test_termsOfServiceAccept_startsChooseWalletChild() throws {
        sut.start()
        let welcome = try XCTUnwrap(top(as: Welcome.self))
        welcome.viewModel.navigator.next(.start)
        drainRunLoop()
        let terms = try XCTUnwrap(top(as: TermsOfService.self))

        terms.viewModel.navigator.next(.acceptTermsOfService)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is ChooseWalletCoordinator })
    }

    // MARK: - Child coordinator completion handlers

    private func firstChild<T>(as _: T.Type) throws -> T {
        try XCTUnwrap(sut.childCoordinators.first { $0 is T } as? T)
    }

    func test_chooseWalletFinishChoosing_startsSetPincodeChild() throws {
        mockOnboarding.hasAcceptedTermsOfService = true
        mockOnboarding.shouldPromptUserToChosePincode = true
        sut.start()
        let welcome = try XCTUnwrap(top(as: Welcome.self))
        welcome.viewModel.navigator.next(.start)
        drainRunLoop()
        let chooseWallet = try firstChild(as: ChooseWalletCoordinator.self)

        // Emit .finishChoosingWallet from the inner ChooseWalletCoordinator to
        // exercise OnboardingCoordinator's toChooseWallet navigationHandler.
        chooseWallet.navigator.next(.finishChoosingWallet)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is SetPincodeCoordinator })
    }

    func test_setPincodeDone_bubblesFinishOnboarding() throws {
        mockOnboarding.hasAcceptedTermsOfService = true
        mockWallet.storedWallet = TestWalletFactory.makeWallet()
        mockOnboarding.shouldPromptUserToChosePincode = true
        sut.start()
        let welcome = try XCTUnwrap(top(as: Welcome.self))
        welcome.viewModel.navigator.next(.start)
        drainRunLoop()
        let setPin = try firstChild(as: SetPincodeCoordinator.self)
        var received: OnboardingCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        setPin.navigator.next(.setPincode)
        drainRunLoop()

        if case .finishOnboarding = received { } else {
            XCTFail("expected .finishOnboarding, got \(String(describing: received))")
        }
    }
}
