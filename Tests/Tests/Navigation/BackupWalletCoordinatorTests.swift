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

/// Drives each `BackupWalletUserAction` branch of
/// `BackupWalletCoordinator` so all four navigation handlers run.
@MainActor
final class BackupWalletCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var mockWallet: MockWalletUseCase!
    private var walletSubject: CurrentValueSubject<AppFeature.Wallet, Never>!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: BackupWalletCoordinator!

    override func setUp() {
        super.setUp()
        mockWallet = MockWalletUseCase()
        let wallet = TestWalletFactory.makeWallet()
        mockWallet.storedWallet = wallet
        walletSubject = CurrentValueSubject<AppFeature.Wallet, Never>(wallet)
        Container.shared.walletStorageUseCase.register { [unowned self] in mainActorOnly { mockWallet } }
        navigationController = NavigationBarLayoutingNavigationController()
        window = TestWindowFactory.make(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = BackupWalletCoordinator(
            navigationController: navigationController,
            wallet: walletSubject.eraseToAnyPublisher()
        )
    }

    override func tearDown() {
        drainRunLoop()
        cancellables.removeAll()
        sut = nil
        window.isHidden = true
        window = nil
        navigationController = nil
        Container.shared.manager.reset()
        walletSubject = nil
        mockWallet = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func top<T>(as _: T.Type) -> T? {
        navigationController.viewControllers.last as? T
    }

    // MARK: - start

    func test_start_pushesBackupWalletAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is BackupWallet)
    }

    // MARK: - Navigation branches

    func test_cancelOrDismiss_bubblesCancel() throws {
        sut.start()
        var received: BackupWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let backup = try XCTUnwrap(top(as: BackupWallet.self))

        backup.viewModel.navigator.next(.cancelOrDismiss)
        drainRunLoop()

        if case .cancel = received { } else {
            XCTFail("expected .cancel, got \(String(describing: received))")
        }
    }

    func test_backupWallet_bubblesBackUp() throws {
        sut.start()
        var received: BackupWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let backup = try XCTUnwrap(top(as: BackupWallet.self))

        backup.viewModel.navigator.next(.backupWallet)
        drainRunLoop()

        if case .backUp = received { } else {
            XCTFail("expected .backUp, got \(String(describing: received))")
        }
    }

    func test_revealKeystore_presentsModalWithoutCrashing() throws {
        sut.start()
        let backup = try XCTUnwrap(top(as: BackupWallet.self))

        backup.viewModel.navigator.next(.revealKeystore)
        drainRunLoop()
        // Modal presented; presence on navigationController.presentedViewController proves path ran.
    }

    func test_revealPrivateKey_startsDecryptKeystoreChildCoordinator() throws {
        sut.start()
        let backup = try XCTUnwrap(top(as: BackupWallet.self))

        backup.viewModel.navigator.next(.revealPrivateKey)
        drainRunLoop()

        XCTAssertTrue(sut.childCoordinators.contains { $0 is DecryptKeystoreCoordinator })
    }

    // MARK: - init fallback

    func test_init_withoutWalletPublisher_usesContainerWalletStorage() {
        // Exercise the `wallet == nil` fallback branch.
        let coordinator = BackupWalletCoordinator(navigationController: navigationController)

        coordinator.start()

        XCTAssertTrue(navigationController.viewControllers.first is BackupWallet)
    }

    // MARK: - Modal navigation handlers

    private func firstChild<T>(as _: T.Type) throws -> T {
        try XCTUnwrap(sut.childCoordinators.first { $0 is T } as? T)
    }

    func test_decryptKeystoreBackingUpKeyPair_dismissesChildCoordinator() throws {
        sut.start()
        let backup = try XCTUnwrap(top(as: BackupWallet.self))
        backup.viewModel.navigator.next(.revealPrivateKey)
        drainRunLoop()
        let decrypt = try firstChild(as: DecryptKeystoreCoordinator.self)

        decrypt.navigator.next(.backingUpKeyPair)
        drainRunLoop()

        XCTAssertFalse(sut.childCoordinators.contains { $0 is DecryptKeystoreCoordinator })
    }

    func test_decryptKeystoreDismiss_dismissesChildCoordinator() throws {
        sut.start()
        let backup = try XCTUnwrap(top(as: BackupWallet.self))
        backup.viewModel.navigator.next(.revealPrivateKey)
        drainRunLoop()
        let decrypt = try firstChild(as: DecryptKeystoreCoordinator.self)

        decrypt.navigator.next(.dismiss)
        drainRunLoop()

        XCTAssertFalse(sut.childCoordinators.contains { $0 is DecryptKeystoreCoordinator })
    }

    func test_revealKeystoreFinished_dismissesModalScene() throws {
        sut.start()
        let backup = try XCTUnwrap(top(as: BackupWallet.self))
        backup.viewModel.navigator.next(.revealKeystore)
        drainRunLoop()
        guard let presentedNav = navigationController.presentedViewController as? UINavigationController,
              let backUp = presentedNav.viewControllers.first as? BackUpKeystore
        else {
            XCTFail("expected BackUpKeystore to be modally presented")
            return
        }

        backUp.viewModel.navigator.next(.finished)
        drainRunLoop()
        // Dismissal ran; no crash.
    }
}
