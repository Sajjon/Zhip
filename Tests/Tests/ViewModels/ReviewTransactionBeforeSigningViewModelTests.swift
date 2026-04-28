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
import SingleLineControllerController
@testable import Zhip

/// Tests for `ReviewTransactionBeforeSigningViewModel`.
///
/// Verifies the formatted recipient/amount/fee/total outputs derived from a
/// `Payment`, the proceed-button gate on the "I have reviewed" checkbox, and
/// that confirming the transaction emits `.acceptPaymentProceedWithSigning`
/// carrying the payment.
final class ReviewTransactionBeforeSigningViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var hasReviewed: CurrentValueSubject<Bool, Never>!
    private var proceedTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var payment: Payment!

    override func setUpWithError() throws {
        try super.setUpWithError()
        hasReviewed = CurrentValueSubject<Bool, Never>(false)
        proceedTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
        let address = try LegacyAddress(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let amount = try Amount(zil: 1)
        let gasPrice = try GasPrice(li: 1_000_000)
        payment = try Payment(
            to: address,
            amount: amount,
            gasPrice: gasPrice
        )
    }

    override func tearDown() {
        cancellables.removeAll()
        payment = nil
        fakeController = nil
        proceedTrigger = nil
        hasReviewed = nil
        super.tearDown()
    }

    func test_proceedButton_mirrorsCheckboxState() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var states: [Bool] = []
        output.isHasReviewedNowProceedWithSigningButtonEnabled
            .sink { states.append($0) }.store(in: &cancellables)

        hasReviewed.send(true)
        hasReviewed.send(false)

        XCTAssertEqual(states, [false, true, false])
    }

    func test_proceedTrigger_emitsAcceptPaymentWithPayment() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: ReviewTransactionBeforeSigningUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        proceedTrigger.send(())

        guard case let .acceptPaymentProceedWithSigning(emitted) = observed else {
            return XCTFail("Expected .acceptPaymentProceedWithSigning, got \(String(describing: observed))")
        }
        XCTAssertEqual(emitted.recipient.asString, payment.recipient.asString)
        XCTAssertEqual(emitted.amount, payment.amount)
    }

    func test_recipientAddresses_areEmittedInBothFormats() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var legacy: String?
        var bech32: String?
        output.recipientLegacyAddress.sink { legacy = $0 }.store(in: &cancellables)
        output.recipientBech32Address.sink { bech32 = $0 }.store(in: &cancellables)

        XCTAssertEqual(legacy, payment.recipient.asString)
        XCTAssertNotNil(bech32)
        XCTAssertNotEqual(bech32, legacy)
    }

    func test_amountFee_andTotalCost_areFormattedNonEmpty() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var amount: String?
        var fee: String?
        var total: String?
        output.amountToPay.sink { amount = $0 }.store(in: &cancellables)
        output.paymentFee.sink { fee = $0 }.store(in: &cancellables)
        output.totalCost.sink { total = $0 }.store(in: &cancellables)

        XCTAssertFalse((amount ?? "").isEmpty)
        XCTAssertFalse((fee ?? "").isEmpty)
        XCTAssertFalse((total ?? "").isEmpty)
    }

    private func makeSUT() -> ReviewTransactionBeforeSigningViewModel {
        ReviewTransactionBeforeSigningViewModel(paymentToReview: payment)
    }

    private func makeInput() -> ReviewTransactionBeforeSigningViewModel.Input {
        ReviewTransactionBeforeSigningViewModel.Input(
            fromView: .init(
                isHasReviewedPaymentCheckboxChecked: hasReviewed.eraseToAnyPublisher(),
                hasReviewedNowProceedWithSigningTrigger: proceedTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
