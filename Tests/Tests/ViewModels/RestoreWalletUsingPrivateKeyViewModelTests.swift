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
import XCTest
import Zesame
@testable import Zhip

/// Tests for `RestoreWalletUsingPrivateKeyViewModel`.
///
/// Covers the three validation streams (private key, new password, confirm
/// password), the show/hide private-key secure-text-entry toggle, and the
/// `keyRestoration` stream that only emits a non-nil value once every field
/// is valid.
final class RestoreWalletUsingPrivateKeyViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var privateKey: CurrentValueSubject<String, Never>!
    private var isEditingPrivateKey: CurrentValueSubject<Bool, Never>!
    private var showPrivateKey: PassthroughSubject<Void, Never>!
    private var newPassword: CurrentValueSubject<String, Never>!
    private var isEditingNewPassword: CurrentValueSubject<Bool, Never>!
    private var confirmPassword: CurrentValueSubject<String, Never>!
    private var isEditingConfirmPassword: CurrentValueSubject<Bool, Never>!

    private let validPrivateKeyHex = "0E891B9DFF485000C7D1DC22ECF3A583CC50328684321D61947A86E57CF6C638"

    override func setUp() {
        super.setUp()
        privateKey = CurrentValueSubject<String, Never>("")
        isEditingPrivateKey = CurrentValueSubject<Bool, Never>(false)
        showPrivateKey = PassthroughSubject<Void, Never>()
        newPassword = CurrentValueSubject<String, Never>("")
        isEditingNewPassword = CurrentValueSubject<Bool, Never>(false)
        confirmPassword = CurrentValueSubject<String, Never>("")
        isEditingConfirmPassword = CurrentValueSubject<Bool, Never>(false)
    }

    override func tearDown() {
        cancellables.removeAll()
        isEditingConfirmPassword = nil
        confirmPassword = nil
        isEditingNewPassword = nil
        newPassword = nil
        showPrivateKey = nil
        isEditingPrivateKey = nil
        privateKey = nil
        super.tearDown()
    }

    // MARK: - Secure entry toggle

    func test_showPrivateKeyTrigger_togglesSecureEntry() {
        let sut = makeSUT()
        var secureStates: [Bool] = []
        sut.output.privateKeyFieldIsSecureTextEntry.sink { secureStates.append($0) }
            .store(in: &cancellables)

        showPrivateKey.send(())
        showPrivateKey.send(())

        XCTAssertEqual(secureStates, [false, true])
    }

    func test_togglePrivateKeyVisibilityButtonTitle_reflectsSecureState() {
        let sut = makeSUT()
        var titles: [String] = []
        sut.output.togglePrivateKeyVisibilityButtonTitle.sink { titles.append($0) }
            .store(in: &cancellables)

        showPrivateKey.send(())
        showPrivateKey.send(())

        XCTAssertEqual(titles.count, 2)
        XCTAssertNotEqual(titles[0], titles[1])
    }

    // MARK: - keyRestoration gating

    func test_keyRestoration_isNilWhenFieldsIncomplete() {
        let sut = makeSUT()
        var latest: KeyRestoration??
        sut.output.keyRestoration.sink { latest = $0 }.store(in: &cancellables)

        privateKey.send(validPrivateKeyHex)

        XCTAssertNil(latest ?? nil)
    }

    func test_keyRestoration_becomesNonNilWhenAllFieldsValidAndMatch() {
        let sut = makeSUT()
        var latest: KeyRestoration?
        sut.output.keyRestoration.sink { latest = $0 }.store(in: &cancellables)

        privateKey.send(validPrivateKeyHex)
        newPassword.send("apabanan123")
        confirmPassword.send("apabanan123")

        switch latest {
        case .privateKey: break
        default: XCTFail("Expected .privateKey, got \(String(describing: latest))")
        }
    }

    func test_keyRestoration_nilWhenPasswordsMismatch() {
        let sut = makeSUT()
        var latest: KeyRestoration?
        sut.output.keyRestoration.sink { latest = $0 }.store(in: &cancellables)

        privateKey.send(validPrivateKeyHex)
        newPassword.send("apabanan123")
        confirmPassword.send("different!")

        XCTAssertNil(latest)
    }

    // MARK: - Placeholder

    func test_encryptionPasswordPlaceholder_isNonEmpty() {
        let sut = makeSUT()
        var placeholder: String?
        sut.output.encryptionPasswordPlaceholder.sink { placeholder = $0 }
            .store(in: &cancellables)

        XCTAssertFalse((placeholder ?? "").isEmpty)
    }

    private func makeSUT() -> RestoreWalletUsingPrivateKeyViewModel {
        RestoreWalletUsingPrivateKeyViewModel(
            inputFromView: .init(
                privateKey: privateKey.eraseToAnyPublisher(),
                isEditingPrivateKey: isEditingPrivateKey.eraseToAnyPublisher(),
                showPrivateKeyTrigger: showPrivateKey.eraseToAnyPublisher(),
                newEncryptionPassword: newPassword.eraseToAnyPublisher(),
                isEditingNewEncryptionPassword: isEditingNewPassword.eraseToAnyPublisher(),
                confirmEncryptionPassword: confirmPassword.eraseToAnyPublisher(),
                isEditingConfirmedEncryptionPassword: isEditingConfirmPassword.eraseToAnyPublisher()
            )
        )
    }
}
