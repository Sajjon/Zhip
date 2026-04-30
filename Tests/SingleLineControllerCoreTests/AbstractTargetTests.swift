// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
@testable import SingleLineControllerCore
import XCTest

/// Tests `AbstractTarget` — the `@objc` target/action bridge that turns a
/// UIKit selector callback into a Combine pulse on the captured subject.
final class AbstractTargetTests: XCTestCase {
    func test_pressed_forwardsEventToTriggerSubject() {
        let subject = PassthroughSubject<Void, Never>()
        let sut = AbstractTarget(triggerSubject: subject)
        var received = 0
        let cancellable = subject.sink { received += 1 }

        sut.pressed()
        sut.pressed()

        XCTAssertEqual(received, 2)
        cancellable.cancel()
    }
}
