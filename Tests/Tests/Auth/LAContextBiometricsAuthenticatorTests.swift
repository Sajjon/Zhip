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
import XCTest

/// Tests the production `LAContextBiometricsAuthenticator`. On the simulator
/// `canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` returns
/// `false`, so the guard path fires and `authenticate()` resolves to `false`
/// without ever triggering a real Face ID / Touch ID prompt.
@MainActor
final class LAContextBiometricsAuthenticatorTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_authenticate_onSimulator_emitsFalseWithoutPrompt() {
        let sut = LAContextBiometricsAuthenticator()
        var received: Bool?
        let expectation = expectation(description: "emission")

        sut.authenticate().sink { value in
            received = value
            expectation.fulfill()
        }.store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(received, false)
    }
}
