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
import NanoViewControllerCore
import NanoViewControllerNavigation
import UIKit
import XCTest

/// Covers shared Coordinating extensions: stack management, navigation-stack
/// queries, debug printing, and UINavigationController helpers that back
/// `replaceAllScenes` / `popToRootViewController`.
@MainActor
final class CoordinatingInfrastructureTests: XCTestCase {
    private var mockTransactions: MockTransactionsUseCase!
    private var mockWallet: MockWalletUseCase!
    private var mockPincode: MockPincodeUseCase!

    override func setUp() {
        super.setUp()
        mockTransactions = MockTransactionsUseCase()
        mockWallet = MockWalletUseCase()
        mockPincode = MockPincodeUseCase()
        Container.shared.transactionsUseCase.register { [unowned self] in mainActorOnly { mockTransactions } }
        Container.shared.walletStorageUseCase.register { [unowned self] in mainActorOnly { mockWallet } }
        Container.shared.pincodeUseCase.register { [unowned self] in mainActorOnly { mockPincode } }
    }

    override func tearDown() {
        Container.shared.manager.reset()
        mockPincode = nil
        mockWallet = nil
        mockTransactions = nil
        super.tearDown()
    }

    // MARK: - Coordinating+Stack

    func test_firstIndexOf_returnsNilWhenChildAbsent() {
        let parent = ReceiveCoordinator(navigationController: UINavigationController())
        let child = ReceiveCoordinator(navigationController: UINavigationController())

        XCTAssertNil(parent.firstIndexOf(child: child))
    }

    func test_firstIndexOf_returnsIndexWhenChildPresent() {
        let parent = ReceiveCoordinator(navigationController: UINavigationController())
        let child = ReceiveCoordinator(navigationController: UINavigationController())
        parent.childCoordinators.append(child)

        XCTAssertEqual(parent.firstIndexOf(child: child), 0)
    }

    func test_removeChildCoordinator_removesFromStack() {
        let parent = ReceiveCoordinator(navigationController: UINavigationController())
        let child = ReceiveCoordinator(navigationController: UINavigationController())
        parent.childCoordinators.append(child)

        parent.remove(childCoordinator: child)

        XCTAssertTrue(parent.childCoordinators.isEmpty)
    }

    func test_topMostCoordinator_withNoChildren_isSelf() {
        let parent = ReceiveCoordinator(navigationController: UINavigationController())

        XCTAssertTrue(parent.topMostCoordinator === parent)
    }

    func test_topMostCoordinator_withNestedChildren_isDeepest() {
        let parent = ReceiveCoordinator(navigationController: UINavigationController())
        let child = ReceiveCoordinator(navigationController: UINavigationController())
        let grandchild = ReceiveCoordinator(navigationController: UINavigationController())
        parent.childCoordinators.append(child)
        child.childCoordinators.append(grandchild)

        XCTAssertTrue(parent.topMostCoordinator === grandchild)
    }

    func test_topMostScene_withNoControllers_isNil() {
        let parent = ReceiveCoordinator(navigationController: UINavigationController())

        XCTAssertNil(parent.topMostScene)
    }

    func test_topMostScene_withTopAbstractController_returnsIt() {
        let topController = UIViewController()
        let nav = UINavigationController(rootViewController: topController)
        let parent = ReceiveCoordinator(navigationController: nav)

        XCTAssertTrue(parent.topMostScene === topController)
    }

    // MARK: - Coordinating+NavigationStack

    func test_isTopmost_returnsFalseWhenStackEmpty() {
        let parent = ReceiveCoordinator(navigationController: UINavigationController())

        XCTAssertFalse(parent.isTopmost(scene: UIViewController.self))
    }

    // MARK: - Coordinating+DebugPrinting

    func test_stringRepresentation_emptyCoordinator_producesOutput() {
        let parent = ReceiveCoordinator(navigationController: UINavigationController())

        let output = parent.stringRepresentation(level: 0)

        XCTAssertFalse(output.isEmpty)
        XCTAssertTrue(output.contains("ReceiveCoordinator"))
    }

    func test_stringRepresentation_withChildCoordinator_mentionsChild() {
        let parent = ReceiveCoordinator(navigationController: UINavigationController())
        let child = SettingsCoordinator(navigationController: UINavigationController())
        parent.childCoordinators.append(child)

        let output = parent.stringRepresentation(level: 0)

        XCTAssertTrue(output.contains("SettingsCoordinator"))
    }

    func test_stringRepresentation_withStartedScene_mentionsSceneInStack() {
        let nav = UINavigationController()
        let coord = ReceiveCoordinator(navigationController: nav)
        coord.start()

        let output = coord.stringRepresentation(level: 0)

        XCTAssertFalse(output.isEmpty)
    }

    // MARK: - UINavigationController helpers

    func test_setRootViewControllerIfEmptyElsePush_onEmptyStack_setsRoot() {
        let nav = UINavigationController()
        let vc = UIViewController()

        nav.setRootViewControllerIfEmptyElsePush(viewController: vc, animated: false)

        XCTAssertEqual(nav.viewControllers.count, 1)
    }

    func test_setRootViewControllerIfEmptyElsePush_onNonEmptyStack_pushes() {
        let nav = UINavigationController()
        let root = UIViewController()
        let vc = UIViewController()
        nav.setViewControllers([root], animated: false)

        nav.setRootViewControllerIfEmptyElsePush(viewController: vc, animated: false)

        XCTAssertEqual(nav.viewControllers.count, 2)
    }

    func test_setRootViewControllerIfEmptyElsePush_forceReplace_replacesStack() {
        let nav = UINavigationController()
        let root = UIViewController()
        nav.setViewControllers([root, UIViewController(), UIViewController()], animated: false)
        let vc = UIViewController()

        nav.setRootViewControllerIfEmptyElsePush(
            viewController: vc,
            animated: false,
            forceReplaceAllVCsInsteadOfPush: true
        )

        XCTAssertEqual(nav.viewControllers.count, 1)
        XCTAssertTrue(nav.viewControllers.first === vc)
    }

    func test_setRootViewControllerIfEmptyElsePush_invokesCompletion() {
        let nav = UINavigationController()
        let vc = UIViewController()
        let expectation = expectation(description: "completion")

        nav.setRootViewControllerIfEmptyElsePush(viewController: vc, animated: false) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    func test_popToRootViewController_onSingleRoot_invokesCompletion() {
        let nav = UINavigationController()
        nav.setViewControllers([UIViewController()], animated: false)
        let expectation = expectation(description: "completion")

        nav.popToRootViewController(animated: false) { expectation.fulfill() }

        wait(for: [expectation], timeout: 2)
    }
}
