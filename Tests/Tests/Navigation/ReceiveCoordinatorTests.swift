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
import Zesame
import SingleLineControllerController
@testable import AppFeature

/// Drives each branch of `ReceiveCoordinator`: start, `.finish` bubble, and
/// `.requestTransaction` which triggers the share-sheet path.
final class ReceiveCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var mockWallet: MockWalletUseCase!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: ReceiveCoordinator!

    override func setUp() {
        super.setUp()
        mockWallet = MockWalletUseCase()
        mockWallet.storedWallet = TestWalletFactory.makeWallet()
        Container.shared.walletStorageUseCase.register { [unowned self] in mockWallet }
        navigationController = NavigationBarLayoutingNavigationController()
        window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = ReceiveCoordinator(navigationController: navigationController)
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

    func test_start_pushesReceiveAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is Receive)
    }

    // MARK: - Branches

    func test_finish_bubblesFinishNavigationStep() throws {
        sut.start()
        var received: ReceiveCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let receive = try XCTUnwrap(top(as: Receive.self))

        receive.viewModel.navigator.next(.finish)
        drainRunLoop()

        if case .finish = received { } else {
            XCTFail("expected .finish, got \(String(describing: received))")
        }
    }

    func test_requestTransaction_presentsShareSheetWithoutCrashing() throws {
        sut.start()
        let receive = try XCTUnwrap(top(as: Receive.self))
        let address = try Address(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let intent = TransactionIntent(to: address)

        receive.viewModel.navigator.next(.requestTransaction(intent))
        drainRunLoop()
        // UIActivityViewController presented; we just verify the branch ran.
    }
}
