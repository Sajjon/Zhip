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
import NanoViewControllerController
import UIKit
import Validation
import XCTest

/// Drives `RestoreWalletView`'s `populate(with:)` to exercise the keystore
/// error binder — which forces a segment switch to `.keystore` and runs the
/// `switchToViewFor(.keystore)` branch that is otherwise never hit in smoke
/// tests.
@MainActor
final class RestoreWalletViewTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_keystoreRestorationError_switchesToKeystoreSegment() {
        let view = RestoreWalletView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()

        let headerLabel = PassthroughSubject<String, Never>()
        let isRestoreButtonEnabled = PassthroughSubject<Bool, Never>()
        let isRestoring = PassthroughSubject<Bool, Never>()
        let keystoreRestorationError = PassthroughSubject<AnyValidation, Never>()

        let publishers = RestoreWalletViewModel.Publishers(
            headerLabel: headerLabel.eraseToAnyPublisher(),
            isRestoreButtonEnabled: isRestoreButtonEnabled.eraseToAnyPublisher(),
            isRestoring: isRestoring.eraseToAnyPublisher(),
            keystoreRestorationError: keystoreRestorationError.eraseToAnyPublisher()
        )

        view.populate(with: publishers).forEach { $0.store(in: &cancellables) }

        // Subscribe to selectedSegment to exercise the map-closure inside inputFromView.
        var observedSegments: [RestoreWalletViewModel.InputFromView.Segment] = []
        view.inputFromView.selectedSegment.sink { observedSegments.append($0) }.store(in: &cancellables)

        let expectation = expectation(description: "keystore segment emitted")
        expectation.assertForOverFulfill = false
        var segmentSink: AnyCancellable?
        segmentSink = view.inputFromView.selectedSegment.sink { segment in
            if segment == .keystore { expectation.fulfill() }
        }
        segmentSink?.store(in: &cancellables)

        keystoreRestorationError.send(.errorMessage("bad keystore"))

        wait(for: [expectation], timeout: 2)
        XCTAssertTrue(observedSegments.contains(.keystore))
    }
}
