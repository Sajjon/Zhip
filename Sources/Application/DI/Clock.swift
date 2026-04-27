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

/// Abstracts over delayed dispatch so callers can be tested without real-time
/// waits.
///
/// Production code uses `MainQueueClock` (via Factory DI), which schedules
/// work with a real `DispatchQueue.main.asyncAfter` delay. Tests register
/// `ImmediateClock`, which ignores the delay and fires on the next main-queue
/// cycle — making timer-dependent tests run in milliseconds.
protocol Clock: AnyObject {
    /// Schedules `block` to run on the main thread after `delay` seconds.
    ///
    /// - Returns: A `DispatchWorkItem` that can be cancelled before it fires.
    @discardableResult
    func schedule(
        after delay: TimeInterval,
        execute block: @escaping () -> Void
    ) -> DispatchWorkItem
}

/// Production `Clock` implementation backed by `DispatchQueue.main.asyncAfter`.
final class MainQueueClock: Clock {
    init() {}

    @discardableResult
    func schedule(
        after delay: TimeInterval,
        execute block: @escaping () -> Void
    ) -> DispatchWorkItem {
        let item = DispatchWorkItem(block: block)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        return item
    }
}
