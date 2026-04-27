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
import XCTest
import Zesame
@testable import Zhip

/// Tests that `DefaultCreateWalletUseCase` forwards to the injected
/// `ZilliqaServiceReactive`, tags the resulting wallet with
/// `.generatedByThisApp`, and propagates errors.
final class DefaultCreateWalletUseCaseTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var mockService: MockZilliqaServiceReactive!

    override func setUp() {
        super.setUp()
        mockService = MockZilliqaServiceReactive()
        Container.shared.zilliqaService.register { [unowned self] in mockService }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        mockService = nil
        super.tearDown()
    }

    func test_createNewWallet_forwardsPasswordAndDefaultKDF() {
        let zesameWallet = TestWalletFactory.makeWallet().wallet
        mockService.createNewWalletResult = .success(zesameWallet)
        let sut = DefaultCreateWalletUseCase()
        let expectation = expectation(description: "completed")

        sut.createNewWallet(encryptionPassword: "hunter2")
            .sink(receiveCompletion: { _ in expectation.fulfill() }, receiveValue: { _ in })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockService.createNewWalletCallCount, 1)
        XCTAssertEqual(mockService.lastCreateWalletPassword, "hunter2")
    }

    func test_createNewWallet_tagsOriginAsGeneratedByThisApp() {
        let zesameWallet = TestWalletFactory.makeWallet().wallet
        mockService.createNewWalletResult = .success(zesameWallet)
        let sut = DefaultCreateWalletUseCase()
        var produced: Zhip.Wallet?
        let expectation = expectation(description: "value")

        sut.createNewWallet(encryptionPassword: "pw")
            .sink(receiveCompletion: { _ in }, receiveValue: {
                produced = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(produced?.origin, .generatedByThisApp)
    }

    func test_createNewWallet_propagatesError() {
        mockService.createNewWalletResult = .failure(.keystorePasswordTooShort(provided: 1, minimum: 8))
        let sut = DefaultCreateWalletUseCase()
        var received: Swift.Error?
        let expectation = expectation(description: "error")

        sut.createNewWallet(encryptionPassword: "")
            .sink(
                receiveCompletion: {
                    if case let .failure(err) = $0 {
                        received = err
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertNotNil(received)
    }
}
