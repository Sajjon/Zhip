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

/// Abstracts main-thread scheduling so navigation/UI hops can be swapped for
/// synchronous delivery in tests.
///
/// Sibling concept to `Clock`: `Clock` controls *delayed* dispatch
/// (`asyncAfter`); `MainScheduler` controls *immediate* dispatch
/// (`async` / Combine's `.receive(on: DispatchQueue.main)`).
///
/// Production registers `DispatchMainScheduler`, which hops via
/// `DispatchQueue.main.async`. Tests register `ImmediateMainScheduler`, which
/// invokes work synchronously on the calling thread. With the immediate
/// scheduler in place, coordinator/navigation tests can assert on side
/// effects without pumping the runloop.
protocol MainScheduler: AnyObject {
    /// Schedules `work` to run on the main thread.
    func schedule(_ work: @escaping () -> Void)
}

/// Production `MainScheduler` backed by `DispatchQueue.main.async`.
final class DispatchMainScheduler: MainScheduler {
    init() {}

    func schedule(_ work: @escaping () -> Void) {
        DispatchQueue.main.async(execute: work)
    }
}

/// Test `MainScheduler` that invokes work synchronously on the calling
/// thread, so navigation hops resolve before the test's next assertion.
final class ImmediateMainScheduler: MainScheduler {
    init() {}

    func schedule(_ work: @escaping () -> Void) {
        work()
    }
}
