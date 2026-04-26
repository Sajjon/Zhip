// MIT License — Copyright (c) 2018-2026 Open Zesame

import XCTest
@testable import SingleLineControllerCore

/// Smoke test for the Phase 0 skeleton — ensures the module compiles and the
/// version sentinel is reachable. Real tests land alongside their types in
/// Phase 7 of the extraction plan.
final class SingleLineControllerCoreSmokeTests: XCTestCase {
    func test_versionSentinel_isPresent() {
        XCTAssertFalse(SingleLineControllerCore.version.isEmpty)
    }
}
