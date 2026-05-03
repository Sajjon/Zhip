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
import Zesame

/// Drives `CreateNewWalletCoordinator` routing:
/// EnsureThatYouAreNotBeingWatched → CreateNewWallet → BackupWallet
/// (via the child coordinator chain).
@MainActor
final class CreateNewWalletCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var mockWallet: MockWalletUseCase!
    private var preferences: Preferences!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: CreateNewWalletCoordinator!

    override func setUp() {
        super.setUp()
        mockWallet = MockWalletUseCase()
        // In-memory preferences so the new persist-on-create flow's
        // `hasConfirmedNewWalletBackup` flag write doesn't leak into real
        // UserDefaults during the test.
        preferences = TestStoreFactory.makePreferences()
        Container.shared.walletStorageUseCase.register { [unowned self] in mainActorOnly { mockWallet } }
        Container.shared.preferences.register { [unowned self] in mainActorOnly { preferences } }
        navigationController = NavigationBarLayoutingNavigationController()
        window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = CreateNewWalletCoordinator(navigationController: navigationController)
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
        preferences = nil
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

    func test_ensureUnderstand_pushesCreateNewWallet() throws {
        sut.start()
        let ensure = try XCTUnwrap(top(as: EnsureThatYouAreNotBeingWatched.self))

        ensure.viewModel.navigator.next(.understand)
        drainRunLoop()

        XCTAssertTrue(top(as: CreateNewWallet.self) != nil)
    }

    func test_ensureCancel_bubblesCancel() throws {
        sut.start()
        var received: CreateNewWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let ensure = try XCTUnwrap(top(as: EnsureThatYouAreNotBeingWatched.self))

        ensure.viewModel.navigator.next(.cancel)
        drainRunLoop()

        if case .cancel = received { } else {
            XCTFail("expected .cancel, got \(String(describing: received))")
        }
    }

    // MARK: - CreateNewWallet branches

    func test_createWalletCancel_bubblesCancel() throws {
        sut.start()
        top(as: EnsureThatYouAreNotBeingWatched.self)?.viewModel.navigator.next(.understand)
        drainRunLoop()
        var received: CreateNewWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let create = try XCTUnwrap(top(as: CreateNewWallet.self))

        create.viewModel.navigator.next(.cancel)
        drainRunLoop()

        if case .cancel = received { } else {
            XCTFail("expected .cancel, got \(String(describing: received))")
        }
    }

    func test_createWalletCreateWallet_pushesBackupWallet() throws {
        sut.start()
        top(as: EnsureThatYouAreNotBeingWatched.self)?.viewModel.navigator.next(.understand)
        drainRunLoop()
        let create = try XCTUnwrap(top(as: CreateNewWallet.self))

        create.viewModel.navigator.next(.createWallet(TestWalletFactory.makeWallet()))
        drainRunLoop()

        XCTAssertTrue(top(as: BackupWallet.self) != nil)
        XCTAssertTrue(sut.childCoordinators.contains { $0 is BackupWalletCoordinator })
    }

    func test_createWalletCreateWallet_persistsImmediatelyAndMarksNotBackedUp() throws {
        // The wallet must be persisted on derivation so an app kill before
        // the user reaches "I have backed up" doesn't lose the random
        // private key. The backup-confirmed flag should be `false` until
        // the user finishes the BackupWalletCoordinator.
        sut.start()
        top(as: EnsureThatYouAreNotBeingWatched.self)?.viewModel.navigator.next(.understand)
        drainRunLoop()
        let create = try XCTUnwrap(top(as: CreateNewWallet.self))
        let wallet = TestWalletFactory.makeWallet()

        create.viewModel.navigator.next(.createWallet(wallet))
        drainRunLoop()

        XCTAssertNotNil(mockWallet.storedWallet, "wallet must be persisted on creation, not deferred to backup confirm")
        XCTAssertTrue(preferences.isFalse(.hasConfirmedNewWalletBackup), "backup-confirmed flag must start false")
    }

    func test_backupWalletBackUp_marksBackupConfirmed() {
        let backup = driveToBackupWallet()

        backup.viewModel.navigator.next(.backupWallet)
        drainRunLoop()

        XCTAssertTrue(
            preferences.isTrue(.hasConfirmedNewWalletBackup),
            "flag should flip true after backup confirmation"
        )
    }

    // MARK: - BackupWalletCoordinator completion branches

    private func driveToBackupWallet() -> BackupWallet {
        sut.start()
        top(as: EnsureThatYouAreNotBeingWatched.self)!.viewModel.navigator.next(.understand)
        drainRunLoop()
        let create = top(as: CreateNewWallet.self)!
        create.viewModel.navigator.next(.createWallet(TestWalletFactory.makeWallet()))
        drainRunLoop()
        return top(as: BackupWallet.self)!
    }

    func test_backupWalletBackUp_bubblesCreate() {
        let backup = driveToBackupWallet()
        var received: CreateNewWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        backup.viewModel.navigator.next(.backupWallet)
        drainRunLoop()

        if case .create = received { } else {
            XCTFail("expected .create, got \(String(describing: received))")
        }
    }

    func test_backupWalletCancel_bubblesCancel() {
        let backup = driveToBackupWallet()
        var received: CreateNewWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        backup.viewModel.navigator.next(.cancelOrDismiss)
        drainRunLoop()

        if case .cancel = received { } else {
            XCTFail("expected .cancel, got \(String(describing: received))")
        }
    }
}
