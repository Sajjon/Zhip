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
@testable import Zhip

/// Drives `RestoreWalletCoordinator` routing: EnsureThatYouAreNotBeingWatched
/// → RestoreWallet → finishedRestoring / cancel bubble.
final class RestoreWalletCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: RestoreWalletCoordinator!

    override func setUp() {
        super.setUp()
        navigationController = NavigationBarLayoutingNavigationController()
        window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = RestoreWalletCoordinator(navigationController: navigationController)
    }

    override func tearDown() {
        drainRunLoop()
        cancellables.removeAll()
        sut = nil
        window.isHidden = true
        window = nil
        navigationController = nil
        Container.shared.manager.reset()
        super.tearDown()
    }

    // MARK: - Helpers

    private func top<T>(as _: T.Type) -> T? {
        navigationController.viewControllers.last as? T
    }

    // MARK: - start

    func test_start_pushesEnsureThatYouAreNotBeingWatchedAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is EnsureThatYouAreNotBeingWatched)
    }

    // MARK: - EnsureThatYouAreNotBeingWatched branches

    func test_ensureUnderstand_pushesRestoreWallet() throws {
        sut.start()
        let ensure = try XCTUnwrap(top(as: EnsureThatYouAreNotBeingWatched.self))

        ensure.viewModel.navigator.next(.understand)
        drainRunLoop()

        XCTAssertTrue(top(as: RestoreWallet.self) != nil)
    }

    func test_ensureCancel_bubblesCancel() throws {
        sut.start()
        var received: RestoreWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let ensure = try XCTUnwrap(top(as: EnsureThatYouAreNotBeingWatched.self))

        ensure.viewModel.navigator.next(.cancel)
        drainRunLoop()

        if case .cancel = received { } else {
            XCTFail("expected .cancel, got \(String(describing: received))")
        }
    }

    // MARK: - RestoreWallet branch

    func test_restoreWallet_bubblesFinishedRestoring() throws {
        sut.start()
        top(as: EnsureThatYouAreNotBeingWatched.self)?.viewModel.navigator.next(.understand)
        drainRunLoop()
        var received: RestoreWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let restore = try XCTUnwrap(top(as: RestoreWallet.self))
        let wallet = TestWalletFactory.makeWallet()

        restore.viewModel.navigator.next(.restoreWallet(wallet))
        drainRunLoop()

        if case .finishedRestoring = received { } else {
            XCTFail("expected .finishedRestoring, got \(String(describing: received))")
        }
    }
}
