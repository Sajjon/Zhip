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
import SnapshotTesting
import UIKit
import XCTest

/// First snapshot test in the project — serves as the reference template for
/// future scene snapshot tests. The reference PNG lives under
/// `Tests/Tests/Snapshots/__Snapshots__/WelcomeViewSnapshotTests/` and is
/// committed alongside this file. CI re-renders the view and diffs against
/// the committed image; any visual regression fails the suite.
///
/// To record / re-record a snapshot locally, set `withSnapshotTesting(record:)`
/// to `.all` (e.g. by wrapping the test body in a `withSnapshotTesting` block),
/// run the test once, then commit the new reference and revert the recording
/// override.
@MainActor
final class WelcomeViewSnapshotTests: XCTestCase {
    func test_welcomeView_iPhone17() {
        // Arrange: pin the frame to the simulator size matching CI
        // (iPhone 17 @ 2x — 393×852 pt). The fonts/images are bundled with
        // the AppFeature module so the render is hermetic.
        let view = WelcomeView()
        view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        view.layoutIfNeeded()

        // Act + Assert: 0.99 precision tolerates sub-pixel font rendering
        // diffs that aren't real regressions.
        assertSnapshot(of: view, as: .image(precision: 0.99))
    }
}
