// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
@testable import SingleLineControllerCore
import XCTest

/// Smoke tests for the Phase 1 set of Core types. Covers the protocols and
/// the helpers that have no UIKit/Combine dependency surface beyond what's
/// already in Core. Richer tests migrate from the Zhip target in Phase 7.
final class SingleLineControllerCoreSmokeTests: XCTestCase {
    func test_emptyInitializable_canSpinUpInstance() {
        struct Foo: EmptyInitializable {
            var marker = "spun"
        }
        XCTAssertEqual(Foo().marker, "spun")
    }

    func test_activityIndicator_emitsFalseOnSubscribe() {
        let indicator = ActivityIndicator()
        var received: [Bool] = []
        let cancellable = indicator.asPublisher().sink { received.append($0) }
        XCTAssertEqual(received, [false])
        cancellable.cancel()
    }

    func test_errorTracker_capturesFailures() {
        let tracker = ErrorTracker()
        var captured: [Error] = []
        let trackerCancellable = tracker.asPublisher().sink { captured.append($0) }

        struct StubError: Swift.Error {}
        let upstream = Fail<Int, Swift.Error>(error: StubError())
        let pipelineCancellable = tracker.track(from: upstream).sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in }
        )

        XCTAssertEqual(captured.count, 1)
        trackerCancellable.cancel()
        pipelineCancellable.cancel()
    }
}
