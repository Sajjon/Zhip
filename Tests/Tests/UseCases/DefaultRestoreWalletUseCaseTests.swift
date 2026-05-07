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
import XCTest
import Zesame

/// Tests that `DefaultRestoreWalletUseCase` maps the `KeyRestoration` case to
/// the correct `Wallet.Origin` and forwards to the injected service.
@MainActor
final class DefaultRestoreWalletUseCaseTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var mockService: MockZilliqaServiceReactive!

    override func setUp() {
        super.setUp()
        mockService = MockZilliqaServiceReactive()
        Container.shared.zilliqaService.register { [unowned self] in mainActorOnly { mockService } }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        mockService = nil
        super.tearDown()
    }

    func test_restoreFromKeystore_tagsOriginAsImportedKeystore() {
        let wallet = TestWalletFactory.makeWallet()
        mockService.restoreWalletResult = .success(wallet.wallet)
        let sut = DefaultRestoreWalletUseCase()
        var produced: AppFeature.Wallet?
        let expectation = expectation(description: "value")

        sut.restoreWallet(from: .keystore(wallet.wallet.keystore, password: TestWalletFactory.testPassword))
            .sink(receiveCompletion: { _ in }, receiveValue: {
                produced = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(produced?.origin, .importedKeystore)
        XCTAssertEqual(mockService.restoreWalletCallCount, 1)
    }

    func test_restoreFromPrivateKey_tagsOriginAsImportedPrivateKey() throws {
        let wallet = TestWalletFactory.makeWallet()
        mockService.restoreWalletResult = .success(wallet.wallet)
        let sut = DefaultRestoreWalletUseCase()
        let privateKey = try PrivateKey(
            rawRepresentation: Data(hex: "0E891B9DFF485000C7D1DC22ECF3A583CC50328684321D61947A86E57CF6C638")
        )
        var produced: AppFeature.Wallet?
        let expectation = expectation(description: "value")

        sut.restoreWallet(from: .privateKey(privateKey, encryptBy: "apabanan123", kdf: .pbkdf2))
            .sink(receiveCompletion: { _ in }, receiveValue: {
                produced = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(produced?.origin, .importedPrivateKey)
    }
}
