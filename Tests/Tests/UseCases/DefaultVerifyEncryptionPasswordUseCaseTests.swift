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
import Zesame

/// Tests that `DefaultVerifyEncryptionPasswordUseCase` forwards the password
/// and keystore to the injected service and propagates its boolean result.
final class DefaultVerifyEncryptionPasswordUseCaseTests: XCTestCase {
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

    func test_verify_forwardsPasswordAndReturnsTrue() {
        mockService.verifyEncryptionPasswordResult = .success(true)
        let sut = DefaultVerifyEncryptionPasswordUseCase()
        let keystore = TestWalletFactory.makeWallet().wallet.keystore
        var result: Bool?
        let expectation = expectation(description: "value")

        sut.verify(password: "secret", forKeystore: keystore)
            .sink(receiveCompletion: { _ in }, receiveValue: {
                result = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(result, true)
        XCTAssertEqual(mockService.verifyEncryptionPasswordCallCount, 1)
        XCTAssertEqual(mockService.lastVerifyPassword, "secret")
    }

    func test_verify_returnsFalseWhenServiceRejects() {
        mockService.verifyEncryptionPasswordResult = .success(false)
        let sut = DefaultVerifyEncryptionPasswordUseCase()
        let keystore = TestWalletFactory.makeWallet().wallet.keystore
        var result: Bool?
        let expectation = expectation(description: "value")

        sut.verify(password: "wrong", forKeystore: keystore)
            .sink(receiveCompletion: { _ in }, receiveValue: {
                result = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(result, false)
    }

    func test_verifyForWallet_convenienceOverload_forwardsToKeystore() {
        mockService.verifyEncryptionPasswordResult = .success(true)
        let sut = DefaultVerifyEncryptionPasswordUseCase()
        let wallet = TestWalletFactory.makeWallet()
        var result: Bool?
        let expectation = expectation(description: "value")

        sut.verify(password: "secret", forWallet: wallet)
            .sink(receiveCompletion: { _ in }, receiveValue: {
                result = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(result, true)
        XCTAssertEqual(mockService.verifyEncryptionPasswordCallCount, 1)
    }
}
