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

/// Drives `DecryptKeystoreCoordinator` routing: start pushes
/// `DecryptKeystoreToRevealKeyPair`; dismiss bubbles .dismiss; successful
/// decryption pushes `BackUpRevealedKeyPair` which then bubbles
/// .backingUpKeyPair on finish.
final class DecryptKeystoreCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var mockWallet: MockWalletUseCase!
    private var walletSubject: CurrentValueSubject<AppFeature.Wallet, Never>!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: DecryptKeystoreCoordinator!

    override func setUp() {
        super.setUp()
        mockWallet = MockWalletUseCase()
        let wallet = TestWalletFactory.makeWallet()
        mockWallet.storedWallet = wallet
        walletSubject = CurrentValueSubject<AppFeature.Wallet, Never>(wallet)
        Container.shared.walletStorageUseCase.register { [unowned self] in mockWallet }
        navigationController = NavigationBarLayoutingNavigationController()
        window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = DecryptKeystoreCoordinator(
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

    private func makeKeyPair() throws -> KeyPair {
        KeyPair(private: PrivateKey())
    }

    // MARK: - start

    func test_start_pushesDecryptKeystoreAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is DecryptKeystoreToRevealKeyPair)
    }

    // MARK: - DecryptKeystore branches

    func test_decryptKeystoreDismiss_bubblesDismiss() throws {
        sut.start()
        var received: DecryptKeystoreCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let decrypt = try XCTUnwrap(top(as: DecryptKeystoreToRevealKeyPair.self))

        decrypt.viewModel.navigator.next(.dismiss)
        drainRunLoop()

        if case .dismiss = received { } else {
            XCTFail("expected .dismiss, got \(String(describing: received))")
        }
    }

    func test_decryptKeystoreRevealing_pushesBackUpRevealedKeyPair() throws {
        sut.start()
        let decrypt = try XCTUnwrap(top(as: DecryptKeystoreToRevealKeyPair.self))
        let keyPair = try makeKeyPair()

        decrypt.viewModel.navigator.next(.decryptKeystoreReavealing(keyPair: keyPair))
        drainRunLoop()

        XCTAssertTrue(top(as: BackUpRevealedKeyPair.self) != nil)
    }

    // MARK: - BackUpRevealed branch

    func test_init_withoutWalletPublisher_fallsBackToContainerWalletStorage() {
        // Exercise the `wallet == nil` fallback branch that reads from the
        // shared Container-registered walletStorageUseCase.
        let coordinator = DecryptKeystoreCoordinator(navigationController: navigationController)

        coordinator.start()

        XCTAssertTrue(navigationController.viewControllers.first is DecryptKeystoreToRevealKeyPair)
    }

    func test_backUpRevealedFinish_bubblesBackingUpKeyPair() throws {
        sut.start()
        let decrypt = try XCTUnwrap(top(as: DecryptKeystoreToRevealKeyPair.self))
        try decrypt.viewModel.navigator.next(.decryptKeystoreReavealing(keyPair: makeKeyPair()))
        drainRunLoop()
        var received: DecryptKeystoreCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let backUp = try XCTUnwrap(top(as: BackUpRevealedKeyPair.self))

        backUp.viewModel.navigator.next(.finish)
        drainRunLoop()

        if case .backingUpKeyPair = received { } else {
            XCTFail("expected .backingUpKeyPair, got \(String(describing: received))")
        }
    }
}
