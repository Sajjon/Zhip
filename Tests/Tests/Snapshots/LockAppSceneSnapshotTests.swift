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
import SnapshotTesting
import UIKit
import XCTest

/// Pixel-level coverage for `LockAppScene`. The scene has no view model — it's
/// a static privacy cover with the app name on a parallax aurora background —
/// so a snapshot is the only meaningful regression check (logic-wise there's
/// nothing to assert beyond "the layout still renders").
///
/// Reference PNG: `Tests/Tests/Snapshots/__Snapshots__/LockAppSceneSnapshotTests/`.
@MainActor
final class LockAppSceneSnapshotTests: XCTestCase {
    func test_lockAppScene_iPhone17() {
        // Arrange: instantiate the controller and force-load its view at the
        // simulator's natural size so the layout settles before the snapshot.
        let scene = LockAppScene()
        scene.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        scene.view.layoutIfNeeded()

        // Act + Assert: 0.99 precision tolerates sub-pixel font rendering
        // diffs that aren't real regressions.
        assertSnapshot(of: scene, as: .image(precision: 0.99))
    }
}
