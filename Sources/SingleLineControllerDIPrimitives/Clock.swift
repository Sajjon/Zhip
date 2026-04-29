// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Abstracts over delayed dispatch so callers can be tested without real-time
/// waits.
///
/// Production code uses `MainQueueClock`, which schedules work with a real
/// `DispatchQueue.main.asyncAfter` delay. Tests register an immediate-clock
/// double that ignores the delay and fires on the next main-queue cycle —
/// making timer-dependent tests run in milliseconds.
public protocol Clock: AnyObject {
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
public final class MainQueueClock: Clock {
    public init() {}

    @discardableResult
    public func schedule(
        after delay: TimeInterval,
        execute block: @escaping () -> Void
    ) -> DispatchWorkItem {
        let item = DispatchWorkItem(block: block)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        return item
    }
}
