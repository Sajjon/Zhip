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
import UIKit
import XCTest
import Zesame

/// Tests for `MainCoordinator` — instantiates the coordinator with a real
/// `UINavigationController`, drives `start()`, and verifies the initial scene
/// is pushed.
@MainActor
final class MainCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var deeplinkSubject: PassthroughSubject<TransactionIntent, Never>!
    private var mockTransactions: MockTransactionsUseCase!
    private var mockWallet: MockWalletUseCase!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: MainCoordinator!

    override func setUp() {
        super.setUp()
        navigationController = NavigationBarLayoutingNavigationController()
        deeplinkSubject = PassthroughSubject<TransactionIntent, Never>()
        mockTransactions = MockTransactionsUseCase()
        mockWallet = MockWalletUseCase()
        mockWallet.storedWallet = TestWalletFactory.makeWallet()
        Container.shared.transactionsUseCase.register { [unowned self] in
            mainActorOnly { mockTransactions }
        }
        Container.shared.walletStorageUseCase.register { [unowned self] in
            mainActorOnly { mockWallet }
        }
        window = TestWindowFactory.make(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = MainCoordinator(
            navigationController: navigationController,
            deeplinkedTransaction: deeplinkSubject.eraseToAnyPublisher()
        )
    }

    override func tearDown() {
        drainRunLoop()
        cancellables.removeAll()
        Container.shared.manager.reset()
        sut = nil
        window.isHidden = true
        window = nil
        mockWallet = nil
        mockTransactions = nil
        deeplinkSubject = nil
        navigationController = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func top<T>(as _: T.Type) -> T? {
        navigationController.viewControllers.last as? T
    }

    // MARK: - start

    func test_start_pushesMainSceneAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is Main)
    }

    // MARK: - Deep-link branch

    func test_deeplinkedTransaction_whenNoChildren_triggersSendModal() throws {
        sut.start()
        let address = try Address(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let intent = TransactionIntent(to: address)

        deeplinkSubject.send(intent)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is SendCoordinator })
    }

    func test_deeplinkedTransaction_whenChildAlreadyPresented_isNoOp() throws {
        sut.start()
        let main = try XCTUnwrap(top(as: Main.self))
        // Tap "Send" — first ImageAboveLabelButton in MainView.
        try tapButton(at: 0, in: main.view)
        drainRunLoop()
        let childCountBefore = sut.childCoordinators.count

        let address = try Address(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        deeplinkSubject.send(TransactionIntent(to: address))
        drainRunLoop()

        XCTAssertEqual(sut.childCoordinators.count, childCountBefore)
    }

    // MARK: - MainViewModel user-intent branches

    func test_sendIntent_startsSendChildCoordinator() throws {
        sut.start()
        let main = try XCTUnwrap(top(as: Main.self))

        // Tap "Send" — first ImageAboveLabelButton in MainView.
        try tapButton(at: 0, in: main.view)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is SendCoordinator })
    }

    func test_receiveIntent_startsReceiveChildCoordinator() throws {
        sut.start()
        let main = try XCTUnwrap(top(as: Main.self))

        // Tap "Receive" — second ImageAboveLabelButton in MainView.
        try tapButton(at: 1, in: main.view)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is ReceiveCoordinator })
    }

    func test_goToSettingsIntent_startsSettingsChildCoordinator() throws {
        sut.start()
        let main = try XCTUnwrap(top(as: Main.self))

        // Settings is wired to the right-bar-button trigger.
        main.rightBarButtonSubject.send(())
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is SettingsCoordinator })
    }

    // MARK: - Bubbled navigation from child coordinators

    private func firstChild<T>(as _: T.Type) throws -> T {
        try XCTUnwrap(sut.childCoordinators.first { $0 is T } as? T)
    }

    func test_sendFinish_dismissesSendChildCoordinator() throws {
        sut.start()
        let main = try XCTUnwrap(top(as: Main.self))
        try tapButton(at: 0, in: main.view)
        drainRunLoop()
        let send = try firstChild(as: SendCoordinator.self)

        send.navigator.next(.finish(fetchBalance: true))
        drainRunLoop()

        XCTAssertFalse(sut.childCoordinators.contains { $0 is SendCoordinator })
    }

    func test_sendFinish_withoutBalanceFetching_dismissesSendChildCoordinator() throws {
        sut.start()
        let main = try XCTUnwrap(top(as: Main.self))
        try tapButton(at: 0, in: main.view)
        drainRunLoop()
        let send = try firstChild(as: SendCoordinator.self)

        send.navigator.next(.finish(fetchBalance: false))
        drainRunLoop()

        XCTAssertFalse(sut.childCoordinators.contains { $0 is SendCoordinator })
    }

    func test_receiveFinish_dismissesReceiveChildCoordinator() throws {
        sut.start()
        let main = try XCTUnwrap(top(as: Main.self))
        try tapButton(at: 1, in: main.view)
        drainRunLoop()
        let receive = try firstChild(as: ReceiveCoordinator.self)

        receive.navigator.next(.finish)
        drainRunLoop()

        XCTAssertFalse(sut.childCoordinators.contains { $0 is ReceiveCoordinator })
    }

    func test_settingsCloseSettings_dismissesSettingsChildCoordinator() throws {
        sut.start()
        let main = try XCTUnwrap(top(as: Main.self))
        main.rightBarButtonSubject.send(())
        drainRunLoop()
        let settings = try firstChild(as: SettingsCoordinator.self)

        settings.navigator.next(.closeSettings)
        drainRunLoop()

        XCTAssertFalse(sut.childCoordinators.contains { $0 is SettingsCoordinator })
    }

    func test_settingsRemoveWallet_bubblesRemoveWalletNavigationStep() throws {
        sut.start()
        let main = try XCTUnwrap(top(as: Main.self))
        main.rightBarButtonSubject.send(())
        drainRunLoop()
        let settings = try firstChild(as: SettingsCoordinator.self)
        var received: MainCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        settings.navigator.next(.removeWallet)
        drainRunLoop()

        if case .removeWallet = received { } else {
            XCTFail("expected .removeWallet, got \(String(describing: received))")
        }
    }
}
