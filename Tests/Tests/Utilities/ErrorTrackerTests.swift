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
import SingleLineControllerCore
@testable import Zhip

/// Tests that `ErrorTracker` republishes failures from tracked publishers and
/// exposes them through `asPublisher()` for downstream subscribers.
final class ErrorTrackerTests: XCTestCase {

    private enum TestError: Error { case boom }

    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_asPublisher_emitsErrorFromTrackedFailure() {
        let tracker = ErrorTracker()
        var emitted: Error?
        tracker.asPublisher().sink { emitted = $0 }.store(in: &cancellables)

        Fail<Void, TestError>(error: .boom)
            .trackError(tracker)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        XCTAssertNotNil(emitted)
    }

    func test_track_passesThroughSuccessfulValues() {
        let tracker = ErrorTracker()
        var received: [Int] = []

        Just(42)
            .setFailureType(to: TestError.self)
            .trackError(tracker)
            .sink(receiveCompletion: { _ in }, receiveValue: { received.append($0) })
            .store(in: &cancellables)

        XCTAssertEqual(received, [42])
    }
}

