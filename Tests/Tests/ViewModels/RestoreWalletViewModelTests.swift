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
import XCTest
import Zesame

/// Tests for `RestoreWalletViewModel`.
///
/// Covers the segment-controlled headerLabel, the `isRestoreButtonEnabled` gating on
/// a non-nil key restoration, and the restore path which calls the use case and
/// emits `.restoreWallet`.
@MainActor
final class RestoreWalletViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var segmentSubject: CurrentValueSubject<RestoreWalletViewModel.InputFromView.Segment, Never>!
    private var privateKeyRestorationSubject: CurrentValueSubject<KeyRestoration?, Never>!
    private var keystoreRestorationSubject: CurrentValueSubject<KeyRestoration?, Never>!
    private var restoreTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var mockWallet: MockWalletUseCase!

    override func setUp() {
        super.setUp()
        segmentSubject = CurrentValueSubject<RestoreWalletViewModel.InputFromView.Segment, Never>(.privateKey)
        privateKeyRestorationSubject = CurrentValueSubject<KeyRestoration?, Never>(nil)
        keystoreRestorationSubject = CurrentValueSubject<KeyRestoration?, Never>(nil)
        restoreTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
        mockWallet = MockWalletUseCase()
        Container.shared.restoreWalletUseCase.register { [unowned self] in mainActorOnly { mockWallet } }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        mockWallet = nil
        fakeController = nil
        restoreTrigger = nil
        keystoreRestorationSubject = nil
        privateKeyRestorationSubject = nil
        segmentSubject = nil
        super.tearDown()
    }

    func test_restoreTrigger_withValidPrivateKey_emitsRestoreWallet() throws {
        let sut = makeSUT()
        var observed: RestoreWalletNavigation?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        let privateKey = try PrivateKey(
            rawRepresentation: Data(hex: "0E891B9DFF485000C7D1DC22ECF3A583CC50328684321D61947A86E57CF6C638")
        )
        privateKeyRestorationSubject.send(
            .privateKey(privateKey, encryptBy: "apabanan123", kdf: .pbkdf2)
        )
        restoreTrigger.send(())

        XCTAssertEqual(mockWallet.restoreWalletCallCount, 1)
        guard case .restoreWallet = observed else {
            return XCTFail("Expected .restoreWallet, got \(String(describing: observed))")
        }
    }

    func test_isRestoreButtonEnabled_trueWhenRestorationProvided() throws {
        let sut = makeSUT()
        var isEnabledEvents: [Bool] = []
        let output = sut.transform(input: makeInput())
        output.isRestoreButtonEnabled.sink { isEnabledEvents.append($0) }.store(in: &cancellables)

        XCTAssertEqual(isEnabledEvents.last, false)

        let privateKey = try PrivateKey(
            rawRepresentation: Data(hex: "0E891B9DFF485000C7D1DC22ECF3A583CC50328684321D61947A86E57CF6C638")
        )
        privateKeyRestorationSubject.send(
            .privateKey(privateKey, encryptBy: "apabanan123", kdf: .pbkdf2)
        )

        XCTAssertEqual(isEnabledEvents.last, true)
    }

    func test_segmentChange_updatesHeaderLabel() {
        let sut = makeSUT()
        var labels: [String] = []
        let output = sut.transform(input: makeInput())
        output.headerLabel.sink { labels.append($0) }.store(in: &cancellables)

        segmentSubject.send(.keystore)

        XCTAssertGreaterThanOrEqual(labels.count, 2, "Expected a header label emission per segment change")
    }

    private func makeSUT() -> RestoreWalletViewModel {
        let sut = RestoreWalletViewModel()
        _ = sut.transform(input: makeInput())
        return sut
    }

    private func makeInput() -> RestoreWalletViewModel.Input {
        RestoreWalletViewModel.Input(
            fromView: .init(
                selectedSegment: segmentSubject.eraseToAnyPublisher(),
                keyRestorationUsingPrivateKey: privateKeyRestorationSubject.eraseToAnyPublisher(),
                keyRestorationUsingKeystore: keystoreRestorationSubject.eraseToAnyPublisher(),
                restoreTrigger: restoreTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
