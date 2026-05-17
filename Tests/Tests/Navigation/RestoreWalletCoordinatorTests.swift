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

/// Drives `RestoreWalletCoordinator` routing: EnsureThatYouAreNotBeingWatched
/// → RestoreWallet → finishedRestoring / cancel bubble.
@MainActor
final class RestoreWalletCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var mockWallet: MockWalletUseCase!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: RestoreWalletCoordinator!

    override func setUp() {
        super.setUp()
        // Register the mocked wallet use case so the `RestoreWalletViewModel`'s
        // `restoreWalletUseCase` resolves to a fake that emits a wallet
        // synchronously instead of running real keystore derivation.
        mockWallet = MockWalletUseCase()
        Container.shared.walletStorageUseCase.register { [unowned self] in mainActorOnly { mockWallet } }
        Container.shared.restoreWalletUseCase.register { [unowned self] in mainActorOnly { mockWallet } }
        navigationController = NavigationBarLayoutingNavigationController()
        window = TestWindowFactory.make(frame: .init(x: 0, y: 0, width: 320, height: 480))
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
        mockWallet = nil
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

        try tapButton(at: 0, in: ensure.view) // "I understand"
        drainRunLoop()

        XCTAssertTrue(top(as: RestoreWallet.self) != nil)
    }

    func test_ensureCancel_bubblesCancel() throws {
        sut.start()
        var received: RestoreWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let ensure = try XCTUnwrap(top(as: EnsureThatYouAreNotBeingWatched.self))

        // `.cancel` is wired to the left-bar button.
        ensure.leftBarButtonSubject.send(())
        drainRunLoop()

        if case .cancel = received { } else {
            XCTFail("expected .cancel, got \(String(describing: received))")
        }
    }

    // MARK: - RestoreWallet branch

    func test_restoreWallet_bubblesFinishedRestoring() throws {
        sut.start()
        let ensure = try XCTUnwrap(top(as: EnsureThatYouAreNotBeingWatched.self))
        try tapButton(at: 0, in: ensure.view) // "I understand"
        drainRunLoop()
        var received: RestoreWalletCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let restore = try XCTUnwrap(top(as: RestoreWallet.self))
        // Seed the mock so the restore use case returns this wallet (`MockWalletUseCase.restoreWalletResult`).
        mockWallet.restoreWalletResult = .success(TestWalletFactory.makeWallet(origin: .importedKeystore))

        // Default segment is "private key" — fill its three fields with valid
        // inputs and tap the restore button. The private-key field expects
        // a 32-byte hex string (64 chars); the two password fields must
        // match and be ≥ 8 chars.
        let privateKeyHex = "0E891B9DFF485000C7D1DC22ECF3A583CC50328684321D61947A86E57CF6C638"
        // The view hierarchy contains `RestoreUsingPrivateKeyView`'s three
        // `FloatingLabelTextField`s; private key is the first.
        try setText(privateKeyHex, in: restore.view, ofType: FloatingLabelTextField.self, at: 0)
        try setText("apabanan123", in: restore.view, ofType: FloatingLabelTextField.self, at: 1)
        try setText("apabanan123", in: restore.view, ofType: FloatingLabelTextField.self, at: 2)
        // The restore CTA at the bottom of `RestoreWalletView` is a `ButtonWithSpinner`
        // — pick it specifically so the inner "Show" button on the private-key
        // field doesn't accidentally claim index 0.
        try tapControl(ButtonWithSpinner.self, at: 0, in: restore.view)
        drainRunLoop()

        if case .finishedRestoring = received { } else {
            XCTFail("expected .finishedRestoring, got \(String(describing: received))")
        }
    }
}
