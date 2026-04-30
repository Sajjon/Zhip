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
import XCTest

/// Tests that `DefaultWalletStorageUseCase` forwards each operation to the
/// injected `SecurePersistence` (here an in-memory store from
/// `TestStoreFactory`).
final class DefaultWalletStorageUseCaseTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Container.shared.securePersistence.register { TestStoreFactory.makeSecurePersistence() }
    }

    override func tearDown() {
        Container.shared.manager.reset()
        super.tearDown()
    }

    func test_saveThenLoadWallet_roundTrips() {
        let sut = DefaultWalletStorageUseCase()
        let wallet = TestWalletFactory.makeWallet()

        sut.save(wallet: wallet)

        XCTAssertEqual(sut.loadWallet()?.bech32Address.asString, wallet.bech32Address.asString)
    }

    func test_hasConfiguredWallet_trueAfterSave() {
        let sut = DefaultWalletStorageUseCase()
        XCTAssertFalse(sut.hasConfiguredWallet)

        sut.save(wallet: TestWalletFactory.makeWallet())

        XCTAssertTrue(sut.hasConfiguredWallet)
    }

    func test_deleteWallet_removesStoredWallet() {
        let sut = DefaultWalletStorageUseCase()
        sut.save(wallet: TestWalletFactory.makeWallet())
        XCTAssertNotNil(sut.loadWallet())

        sut.deleteWallet()

        XCTAssertNil(sut.loadWallet())
        XCTAssertFalse(sut.hasConfiguredWallet)
    }

    func test_walletPublisher_emitsCurrentlyLoadedWallet() {
        let sut = DefaultWalletStorageUseCase()
        sut.save(wallet: TestWalletFactory.makeWallet())
        var cancellables: Set<AnyCancellable> = []
        var received: Wallet?
        let expectation = expectation(description: "wallet")

        sut.wallet.sink {
            received = $0
            expectation.fulfill()
        }.store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertNotNil(received)
    }

    func test_walletPublisher_emitsNilWhenEmpty() {
        let sut = DefaultWalletStorageUseCase()
        var cancellables: Set<AnyCancellable> = []
        var emitted = false
        var receivedValue: Wallet?
        let expectation = expectation(description: "wallet")

        sut.wallet.sink {
            emitted = true
            receivedValue = $0
            expectation.fulfill()
        }.store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(emitted)
        XCTAssertNil(receivedValue)
    }
}
