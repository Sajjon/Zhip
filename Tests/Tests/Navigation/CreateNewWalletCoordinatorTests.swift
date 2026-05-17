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
        // Also register the create-wallet use case so the VM's
        // `flatMapLatest { createWalletUseCase.createNewWallet(...) }` resolves
        // to `MockWalletUseCase.createNewWallet`, which returns the mock's
        // `createWalletResult` synchronously instead of running real KDF.
        Container.shared.createWalletUseCase.register { [unowned self] in mainActorOnly { mockWallet } }
        Container.shared.preferences.register { [unowned self] in mainActorOnly { preferences } }
        navigationController = NavigationBarLayoutingNavigationController()
        window = TestWindowFactory.make(frame: .init(x: 0, y: 0, width: 320, height: 480))
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

        // Tap "I understand" — the lone UIButton in EnsureThatYouAreNotBeingWatchedView.
        try tapButton(at: 0, in: ensure.view)
        drainRunLoop()

        XCTAssertTrue(top(as: CreateNewWallet.self) != nil)
    }

    func test_ensureCancel_bubblesCancel() throws {
        sut.start()
        var received: CreateNewWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let ensure = try XCTUnwrap(top(as: EnsureThatYouAreNotBeingWatched.self))

        // Cancel is wired to the left-bar button.
        ensure.leftBarButtonSubject.send(())
        drainRunLoop()

        if case .cancel = received { } else {
            XCTFail("expected .cancel, got \(String(describing: received))")
        }
    }

    // MARK: - CreateNewWallet branches

    func test_createWalletCancel_bubblesCancel() throws {
        sut.start()
        try drivePast(EnsureThatYouAreNotBeingWatched.self)
        var received: CreateNewWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let create = try XCTUnwrap(top(as: CreateNewWallet.self))

        // Cancel is wired to the left-bar button.
        create.leftBarButtonSubject.send(())
        drainRunLoop()

        if case .cancel = received { } else {
            XCTFail("expected .cancel, got \(String(describing: received))")
        }
    }

    func test_createWalletCreateWallet_pushesBackupWallet() throws {
        sut.start()
        try drivePast(EnsureThatYouAreNotBeingWatched.self)
        let create = try XCTUnwrap(top(as: CreateNewWallet.self))

        try drivePastCreateNewWallet(create)
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
        try drivePast(EnsureThatYouAreNotBeingWatched.self)
        let create = try XCTUnwrap(top(as: CreateNewWallet.self))
        // Seed the mock so a specific wallet is returned from `createWalletUseCase`.
        mockWallet.createWalletResult = .success(TestWalletFactory.makeWallet())

        try drivePastCreateNewWallet(create)
        drainRunLoop()

        XCTAssertNotNil(mockWallet.storedWallet, "wallet must be persisted on creation, not deferred to backup confirm")
        XCTAssertTrue(preferences.isFalse(.hasConfirmedNewWalletBackup), "backup-confirmed flag must start false")
    }

    func test_backupWalletBackUp_marksBackupConfirmed() throws {
        let backup = try driveToBackupWallet()

        // Confirm the "I have backed up" checkbox + tap Done.
        try setCheckbox(on: true, in: backup.view)
        try tapButton(at: 3, in: backup.view) // done button (4th UIButton)
        drainRunLoop()

        XCTAssertTrue(
            preferences.isTrue(.hasConfirmedNewWalletBackup),
            "flag should flip true after backup confirmation"
        )
    }

    // MARK: - BackupWalletCoordinator completion branches

    /// Walks the UI from the root screen (`EnsureThatYouAreNotBeingWatched`)
    /// through `CreateNewWallet` and into `BackupWallet`, returning the
    /// pushed scene so tests can drive its CTA next.
    private func driveToBackupWallet() throws -> BackupWallet {
        sut.start()
        try drivePast(EnsureThatYouAreNotBeingWatched.self)
        let create = try XCTUnwrap(top(as: CreateNewWallet.self))
        try drivePastCreateNewWallet(create)
        drainRunLoop()
        return try XCTUnwrap(top(as: BackupWallet.self))
    }

    /// Taps the lone "I understand" button on the
    /// `EnsureThatYouAreNotBeingWatched` scene.
    private func drivePast<T: UIViewController>(_: T.Type) throws {
        let ensure = try XCTUnwrap(top(as: T.self))
        try tapButton(at: 0, in: ensure.view)
        drainRunLoop()
    }

    /// Fills both password fields with a matching 11-char password (≥ min
    /// length 8), checks the backup-acknowledged checkbox, and taps the
    /// continue button. Triggers the (mocked) `CreateWalletUseCase` which
    /// returns the `TestWalletFactory` default via `MockWalletUseCase`.
    private func drivePastCreateNewWallet(_ create: CreateNewWallet) throws {
        // CreateNewWalletView has two FloatingLabelTextFields and one checkbox.
        try setText("apabanan123", in: create.view, ofType: FloatingLabelTextField.self, at: 0)
        try setText("apabanan123", in: create.view, ofType: FloatingLabelTextField.self, at: 1)
        try setCheckbox(on: true, in: create.view)
        // The continue button is a `ButtonWithSpinner` (a UIButton subclass) and
        // the only button on the screen.
        try tapButton(at: 0, in: create.view)
    }

    func test_backupWalletBackUp_bubblesCreate() throws {
        let backup = try driveToBackupWallet()
        var received: CreateNewWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        // Confirm backup checkbox + tap Done.
        try setCheckbox(on: true, in: backup.view)
        try tapButton(at: 3, in: backup.view)
        drainRunLoop()

        if case .create = received { } else {
            XCTFail("expected .create, got \(String(describing: received))")
        }
    }

    func test_backupWalletCancel_bubblesCancel() throws {
        let backup = try driveToBackupWallet()
        var received: CreateNewWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        // `.cancelOrDismiss` in the cancellable mode is the left-bar button.
        backup.leftBarButtonSubject.send(())
        drainRunLoop()

        if case .cancel = received { } else {
            XCTFail("expected .cancel, got \(String(describing: received))")
        }
    }
}
