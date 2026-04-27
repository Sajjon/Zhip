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

/// Tests for `BackUpRevealedKeyPairViewModel`.
///
/// Verifies the hex-formatted private and public key outputs, the two
/// copy-to-pasteboard side effects with toasts, and the right-bar-button →
/// `.finish` navigation branch.
final class BackUpRevealedKeyPairViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var copyPrivateKey: PassthroughSubject<Void, Never>!
    private var copyPublicKey: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var keyPair: KeyPair!
    private var mockPasteboard: MockPasteboard!

    override func setUpWithError() throws {
        try super.setUpWithError()
        copyPrivateKey = PassthroughSubject<Void, Never>()
        copyPublicKey = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
        let privateKey = try PrivateKey(
            rawRepresentation: Data(hex: "0E891B9DFF485000C7D1DC22ECF3A583CC50328684321D61947A86E57CF6C638")
        )
        keyPair = KeyPair(private: privateKey)
        mockPasteboard = MockPasteboard()
        Container.shared.pasteboard.register { [unowned self] in mockPasteboard }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        mockPasteboard = nil
        keyPair = nil
        fakeController = nil
        copyPublicKey = nil
        copyPrivateKey = nil
        super.tearDown()
    }

    func test_output_emitsHexPrivateAndPublicKeys() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var privateKey: String?
        var publicKey: String?
        output.privateKey.sink { privateKey = $0 }.store(in: &cancellables)
        output.publicKeyUncompressed.sink { publicKey = $0 }.store(in: &cancellables)

        XCTAssertEqual(privateKey, keyPair.privateKey.rawRepresentation.asHex)
        XCTAssertEqual(publicKey, keyPair.publicKey.x963Representation.asHex)
    }

    func test_copyPrivateKey_writesHexPrivateKeyToPasteboardAndSendsToast() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var toasts: [Toast] = []
        fakeController.toastSubject.sink { toasts.append($0) }.store(in: &cancellables)

        copyPrivateKey.send(())

        XCTAssertEqual(toasts.count, 1)
        XCTAssertEqual(mockPasteboard.copiedString, keyPair.privateKey.rawRepresentation.asHex)
    }

    func test_copyPublicKey_writesHexPublicKeyToPasteboardAndSendsToast() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var toasts: [Toast] = []
        fakeController.toastSubject.sink { toasts.append($0) }.store(in: &cancellables)

        copyPublicKey.send(())

        XCTAssertEqual(toasts.count, 1)
        XCTAssertEqual(mockPasteboard.copiedString, keyPair.publicKey.x963Representation.asHex)
    }

    func test_rightBarButton_emitsFinish() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: BackUpRevealedKeyPairUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.rightBarButtonTriggerSubject.send(())

        guard case .finish = observed else {
            return XCTFail("Expected .finish, got \(String(describing: observed))")
        }
    }

    private func makeSUT() -> BackUpRevealedKeyPairViewModel {
        BackUpRevealedKeyPairViewModel(keyPair: keyPair)
    }

    private func makeInput() -> BackUpRevealedKeyPairViewModel.Input {
        BackUpRevealedKeyPairViewModel.Input(
            fromView: .init(
                copyPrivateKeyTrigger: copyPrivateKey.eraseToAnyPublisher(),
                copyPublicKeyTrigger: copyPublicKey.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
