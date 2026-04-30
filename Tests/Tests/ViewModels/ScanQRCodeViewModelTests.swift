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
import SingleLineControllerController
@testable import AppFeature

/// Tests for `ScanQRCodeViewModel`.
///
/// The VM parses scanned strings into `TransactionIntent` (plain address, JSON, or
/// `zilliqa://` deep-links) and emits `.scanQRContainingTransaction` on success. It
/// also honors a toast + cancel path on failure/left-bar-button taps.
final class ScanQRCodeViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var scannedSubject: PassthroughSubject<String?, Never>!
    private var fakeController: FakeInputFromController!

    override func setUp() {
        super.setUp()
        scannedSubject = PassthroughSubject<String?, Never>()
        fakeController = FakeInputFromController()
    }

    override func tearDown() {
        cancellables.removeAll()
        fakeController = nil
        scannedSubject = nil
        super.tearDown()
    }

    func test_scannedValidBech32Address_emitsScanQRContainingTransaction() {
        let sut = makeSUT()
        var observed: ScanQRCodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        scannedSubject.send("zil175grxdeqchwnc0qghj8qsh5vnqwww353msqj82")

        guard case .scanQRContainingTransaction = observed else {
            return XCTFail("Expected .scanQRContainingTransaction, got \(String(describing: observed))")
        }
    }

    func test_scannedZilliqaPrefixStripped() {
        let sut = makeSUT()
        var observed: ScanQRCodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        scannedSubject.send("zilliqa://zil175grxdeqchwnc0qghj8qsh5vnqwww353msqj82")

        guard case .scanQRContainingTransaction = observed else {
            return XCTFail("Expected .scanQRContainingTransaction, got \(String(describing: observed))")
        }
    }

    func test_nilScannedString_emitsToast() {
        let sut = makeSUT()
        var toastedCount = 0
        fakeController.toastSubject.sink { _ in toastedCount += 1 }.store(in: &cancellables)
        var observed: ScanQRCodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        scannedSubject.send(nil)

        XCTAssertEqual(toastedCount, 1, "A failure toast should be emitted")
        XCTAssertNil(observed, "Navigator should not fire on parse failure")
    }

    func test_invalidScanString_emitsToast() {
        let sut = makeSUT()
        var toastedCount = 0
        fakeController.toastSubject.sink { _ in toastedCount += 1 }.store(in: &cancellables)
        var observed: ScanQRCodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        scannedSubject.send("completely-nonsense")

        XCTAssertEqual(toastedCount, 1)
        XCTAssertNil(observed)
    }

    func test_leftBarButton_emitsCancel() {
        let sut = makeSUT()
        var observed: ScanQRCodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.leftBarButtonTriggerSubject.send(())

        guard case .cancel = observed else {
            return XCTFail("Expected .cancel, got \(String(describing: observed))")
        }
    }

    private func makeSUT() -> ScanQRCodeViewModel {
        let sut = ScanQRCodeViewModel()
        let input = ScanQRCodeViewModel.Input(
            fromView: .init(scannedQrCodeString: scannedSubject.eraseToAnyPublisher()),
            fromController: fakeController.makeInput()
        )
        _ = sut.transform(input: input)
        return sut
    }
}
