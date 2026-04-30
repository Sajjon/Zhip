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
@testable import AppFeature

/// Tests that `DefaultExtractKeyPairUseCase` forwards to the injected service
/// and surfaces its `KeyPair` result.
final class DefaultExtractKeyPairUseCaseTests: XCTestCase {
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

    func test_extractKeyPair_forwardsAndReturnsKeyPair() throws {
        let privateKey = try PrivateKey(
            rawRepresentation: Data(hex: "0E891B9DFF485000C7D1DC22ECF3A583CC50328684321D61947A86E57CF6C638")
        )
        let keyPair = try KeyPair(private: privateKey)
        mockService.extractKeyPairResult = .success(keyPair)
        let keystore = TestWalletFactory.makeWallet().wallet.keystore
        let sut = DefaultExtractKeyPairUseCase()
        var produced: KeyPair?
        let expectation = expectation(description: "value")

        sut.extractKeyPairFrom(keystore: keystore, encryptedBy: "secret")
            .sink(receiveCompletion: { _ in }, receiveValue: {
                produced = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertNotNil(produced)
        XCTAssertEqual(mockService.extractKeyPairCallCount, 1)
    }

    func test_extractKeyPairFromWallet_convenienceOverload_forwardsToKeystore() throws {
        let privateKey = try PrivateKey(
            rawRepresentation: Data(hex: "0E891B9DFF485000C7D1DC22ECF3A583CC50328684321D61947A86E57CF6C638")
        )
        let keyPair = try KeyPair(private: privateKey)
        mockService.extractKeyPairResult = .success(keyPair)
        let wallet = TestWalletFactory.makeWallet()
        let sut = DefaultExtractKeyPairUseCase()
        var produced: KeyPair?
        let expectation = expectation(description: "value")

        sut.extractKeyPairFrom(wallet: wallet, encryptedBy: "secret")
            .sink(receiveCompletion: { _ in }, receiveValue: {
                produced = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertNotNil(produced)
        XCTAssertEqual(mockService.extractKeyPairCallCount, 1)
    }
}
