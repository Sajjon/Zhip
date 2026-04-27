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

/// Covers `ChooseWalletCoordinator` routing: `.createNewWallet` /
/// `.restoreWallet` branches, each presenting a child modal coordinator.
final class ChooseWalletCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var mockWallet: MockWalletUseCase!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: ChooseWalletCoordinator!

    override func setUp() {
        super.setUp()
        mockWallet = MockWalletUseCase()
        Container.shared.walletStorageUseCase.register { [unowned self] in mockWallet }
        navigationController = NavigationBarLayoutingNavigationController()
        window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = ChooseWalletCoordinator(navigationController: navigationController)
    }

    override func tearDown() {
        drainRunLoop()
        cancellables.removeAll()
        sut = nil
        window.isHidden = true
        window = nil
        navigationController = nil
        Container.shared.manager.reset()
        mockWallet = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func top<T>(as _: T.Type) -> T? {
        navigationController.viewControllers.last as? T
    }

    // MARK: - start

    func test_start_pushesChooseWalletAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is ChooseWallet)
    }

    // MARK: - Branches

    func test_createNewWallet_startsCreateNewWalletChildCoordinator() throws {
        sut.start()
        let choose = try XCTUnwrap(top(as: ChooseWallet.self))

        choose.viewModel.navigator.next(.createNewWallet)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is CreateNewWalletCoordinator })
    }

    func test_restoreWallet_startsRestoreWalletChildCoordinator() throws {
        sut.start()
        let choose = try XCTUnwrap(top(as: ChooseWallet.self))

        choose.viewModel.navigator.next(.restoreWallet)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is RestoreWalletCoordinator })
    }

    // MARK: - Modal navigation handlers

    private func firstChild<T>(as _: T.Type) throws -> T {
        try XCTUnwrap(sut.childCoordinators.first { $0 is T } as? T)
    }

    func test_createNewWalletCreate_emitsFinishStep() throws {
        // Note: this test no longer asserts on the wallet being saved by
        // ChooseWalletCoordinator. The create flow now persists the wallet
        // immediately on derivation (inside `CreateNewWalletCoordinator`)
        // so an app kill before backup confirmation doesn't lose the
        // random private key. By the time the child emits `.create(...)`
        // here, save has already happened in its own flow — `ChooseWallet`
        // is no longer the persistence boundary for the create branch.
        // See `CreateNewWalletCoordinatorTests` for the persist-on-create
        // assertion.
        sut.start()
        let choose = try XCTUnwrap(top(as: ChooseWallet.self))
        choose.viewModel.navigator.next(.createNewWallet)
        drainRunLoop()
        let create = try firstChild(as: CreateNewWalletCoordinator.self)
        var received: ChooseWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        let wallet = TestWalletFactory.makeWallet()
        create.navigator.next(.create(wallet: wallet))
        drainRunLoop()

        if case .finishChoosingWallet = received { } else {
            XCTFail("expected .finishChoosingWallet, got \(String(describing: received))")
        }
    }

    func test_createNewWalletCancel_doesNotSaveWallet() throws {
        sut.start()
        let choose = try XCTUnwrap(top(as: ChooseWallet.self))
        choose.viewModel.navigator.next(.createNewWallet)
        drainRunLoop()
        let create = try firstChild(as: CreateNewWalletCoordinator.self)
        var received: ChooseWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        create.navigator.next(.cancel)
        drainRunLoop()

        XCTAssertNil(mockWallet.storedWallet)
        XCTAssertNil(received)
    }

    func test_restoreWalletFinishedRestoring_savesWalletAndEmitsFinishStep() throws {
        sut.start()
        let choose = try XCTUnwrap(top(as: ChooseWallet.self))
        choose.viewModel.navigator.next(.restoreWallet)
        drainRunLoop()
        let restore = try firstChild(as: RestoreWalletCoordinator.self)
        var received: ChooseWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        let wallet = TestWalletFactory.makeWallet()
        restore.navigator.next(.finishedRestoring(wallet: wallet))
        drainRunLoop()

        XCTAssertNotNil(mockWallet.storedWallet)
        if case .finishChoosingWallet = received { } else {
            XCTFail("expected .finishChoosingWallet, got \(String(describing: received))")
        }
    }

    func test_restoreWalletCancel_doesNotSaveWallet() throws {
        sut.start()
        let choose = try XCTUnwrap(top(as: ChooseWallet.self))
        choose.viewModel.navigator.next(.restoreWallet)
        drainRunLoop()
        let restore = try firstChild(as: RestoreWalletCoordinator.self)
        var received: ChooseWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        restore.navigator.next(.cancel)
        drainRunLoop()

        XCTAssertNil(mockWallet.storedWallet)
        XCTAssertNil(received)
    }
}
