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

import Foundation
@testable import Zhip

/// In-test `DateProvider` that returns a caller-controlled `Date` instead of
/// the real wall clock, so timestamp-dependent logic (balance-last-updated,
/// relative-time formatting) stays reproducible across runs.
///
/// Default `now` is the Unix epoch so tests that don't care about the specific
/// instant still get a deterministic value.
final class FixedDateProvider: DateProvider {
    /// The `Date` returned by `now()`. Mutate between calls to simulate time
    /// passing within a single test.
    var fixedNow: Date

    init(now: Date = Date(timeIntervalSince1970: 0)) {
        fixedNow = now
    }

    func now() -> Date {
        fixedNow
    }
}
