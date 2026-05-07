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

import Foundation
import NanoViewControllerDIPrimitives
import XCTest

extension XCTestCase {
    /// Drains the main runloop until pending Combine
    /// `.receive(on: DispatchQueue.main)` and GCD main-queue work has run,
    /// then returns. Used by coordinator/use-case tests that fire a
    /// navigation event and assert on its visible side effect.
    ///
    /// This helper has historically bounced between two implementations
    /// that each address only half of the CI flake matrix:
    ///
    ///   1. `XCTestExpectation` + `DispatchQueue.main.asyncAfter` — relies
    ///      on the GCD timer subsystem to fire the sentinel within the
    ///      timeout. On the CI simulator that timer was occasionally
    ///      starved for >10s, producing
    ///      `Asynchronous wait failed: Exceeded timeout of 10.1 seconds`.
    ///   2. `RunLoop.main.run(mode: .default, before:)` in a loop — pumps
    ///      the runloop directly but `run(mode:before:)` returns after one
    ///      source fires, so on CI the loop sometimes exits before the
    ///      Combine main-queue hop has run, producing
    ///      `expected .X, got nil` and `mockUrlOpener count = 0`.
    ///
    /// The hybrid below combines them so each side covers the other's
    /// failure mode:
    ///
    ///   * A sentinel is scheduled via `DispatchQueue.main.asyncAfter` so
    ///     when it fires we know (a) at least `seconds` of real time has
    ///     elapsed, and (b) every main-queue block enqueued before the
    ///     sentinel has run (serial-FIFO guarantee).
    ///   * While waiting for the sentinel we actively pump the runloop in
    ///     `.default` mode, so even when GCD's timer is starved the
    ///     runloop continues to drain main-queue dispatch sources, which
    ///     is what eventually fires the timer too.
    ///   * The wait uses `XCTWaiter()` (not `XCTestCase.wait`) so a
    ///     hard-deadline expiry doesn't auto-XCTFail — under genuine
    ///     starvation we'd rather see the test's own assertion than a
    ///     misleading drain timeout.
    func drainRunLoop(seconds: TimeInterval = 0.1) {
        // Use a plain Bool flag set by the GCD callback rather than an
        // XCTestExpectation: XCTWaiter rejects repeated waits on the same
        // expectation with "API violation - expectations can only be waited
        // on once", and we need to spin in a loop to keep pumping the
        // runloop. Both writer (the GCD block) and reader (this loop) run
        // on the main thread, so plain `Bool` is safe.
        var sentinelFired = false
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            sentinelFired = true
        }
        let hardDeadline = Date(timeIntervalSinceNow: seconds + 10)
        while !sentinelFired, Date() < hardDeadline {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
    }
}
