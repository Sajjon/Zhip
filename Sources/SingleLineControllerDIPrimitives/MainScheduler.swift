// MIT License — Copyright (c) 2018-2026 Open Zesame

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
public protocol MainScheduler: AnyObject {
    /// Schedules `work` to run on the main thread.
    func schedule(_ work: @escaping () -> Void)
}

/// Production `MainScheduler` backed by `DispatchQueue.main.async`.
public final class DispatchMainScheduler: MainScheduler {
    public init() {}

    public func schedule(_ work: @escaping () -> Void) {
        DispatchQueue.main.async(execute: work)
    }
}

/// Test `MainScheduler` that invokes work synchronously on the calling
/// thread, so navigation hops resolve before the test's next assertion.
public final class ImmediateMainScheduler: MainScheduler {
    public init() {}

    public func schedule(_ work: @escaping () -> Void) {
        work()
    }
}
