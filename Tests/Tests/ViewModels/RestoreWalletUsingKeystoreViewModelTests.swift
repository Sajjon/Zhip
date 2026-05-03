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
import XCTest
import Zesame

/// Tests for `RestoreWalletUsingKeystoreViewModel`.
///
/// Verifies the placeholder publishers, that `keyRestoration` becomes non-nil
/// only when a valid keystore JSON and matching password are supplied, and stays
/// nil if either side is invalid or missing.
@MainActor
final class RestoreWalletUsingKeystoreViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var keystoreDidBeginEditing: PassthroughSubject<Void, Never>!
    private var isEditingKeystore: CurrentValueSubject<Bool, Never>!
    private var keystoreText: CurrentValueSubject<String, Never>!
    private var encryptionPassword: CurrentValueSubject<String, Never>!
    private var isEditingEncryptionPassword: CurrentValueSubject<Bool, Never>!
    private var keystoreJSON: String!

    override func setUp() {
        super.setUp()
        keystoreDidBeginEditing = PassthroughSubject<Void, Never>()
        isEditingKeystore = CurrentValueSubject<Bool, Never>(false)
        keystoreText = CurrentValueSubject<String, Never>("")
        encryptionPassword = CurrentValueSubject<String, Never>("")
        isEditingEncryptionPassword = CurrentValueSubject<Bool, Never>(false)
        keystoreJSON = TestWalletFactory.makeWallet().keystoreAsJSON
    }

    override func tearDown() {
        cancellables.removeAll()
        keystoreJSON = nil
        isEditingEncryptionPassword = nil
        encryptionPassword = nil
        keystoreText = nil
        isEditingKeystore = nil
        keystoreDidBeginEditing = nil
        super.tearDown()
    }

    func test_keystorePlaceholder_startsWithPrompt() {
        let sut = makeSUT()
        var first: String?
        sut.output.keystoreTextFieldPlaceholder
            .first()
            .sink { first = $0 }
            .store(in: &cancellables)

        XCTAssertEqual(first, "Paste your keystore here")
    }

    func test_keystorePlaceholder_clearsOnBeginEditing() {
        let sut = makeSUT()
        var latest: String?
        sut.output.keystoreTextFieldPlaceholder
            .sink { latest = $0 }
            .store(in: &cancellables)

        keystoreDidBeginEditing.send(())

        XCTAssertEqual(latest, "")
    }

    func test_encryptionPasswordPlaceholder_isNonEmpty() {
        let sut = makeSUT()
        var placeholder: String?
        sut.output.encryptionPasswordPlaceholder.sink { placeholder = $0 }
            .store(in: &cancellables)

        XCTAssertFalse((placeholder ?? "").isEmpty)
    }

    func test_keyRestoration_isNilWhenKeystoreMissing() {
        let sut = makeSUT()
        var latest: KeyRestoration?
        sut.output.keyRestoration.sink { latest = $0 }.store(in: &cancellables)

        encryptionPassword.send(TestWalletFactory.testPassword)

        XCTAssertNil(latest)
    }

    func test_keyRestoration_isNilWhenPasswordMissing() {
        let sut = makeSUT()
        var latest: KeyRestoration?
        sut.output.keyRestoration.sink { latest = $0 }.store(in: &cancellables)

        keystoreText.send(keystoreJSON)

        XCTAssertNil(latest)
    }

    func test_keyRestoration_becomesKeystoreWhenBothValid() {
        let sut = makeSUT()
        var latest: KeyRestoration?
        sut.output.keyRestoration.sink { latest = $0 }.store(in: &cancellables)

        keystoreText.send(keystoreJSON)
        encryptionPassword.send(TestWalletFactory.testPassword)

        switch latest {
        case .keystore: break
        default: XCTFail("Expected .keystore, got \(String(describing: latest))")
        }
    }

    private func makeSUT() -> RestoreWalletUsingKeystoreViewModel {
        RestoreWalletUsingKeystoreViewModel(
            inputFromView: .init(
                keystoreDidBeginEditing: keystoreDidBeginEditing.eraseToAnyPublisher(),
                isEditingKeystore: isEditingKeystore.eraseToAnyPublisher(),
                keystoreText: keystoreText.eraseToAnyPublisher(),
                encryptionPassword: encryptionPassword.eraseToAnyPublisher(),
                isEditingEncryptionPassword: isEditingEncryptionPassword.eraseToAnyPublisher()
            )
        )
    }
}
