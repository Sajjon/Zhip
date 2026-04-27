// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Abstracts reading "what time is it now" so callers can be tested without
/// depending on the real wall clock.
///
/// Production uses `DefaultDateProvider` (returns `Date()`); tests register
/// a fixed-clock double, which returns a deterministic instant so relative-time
/// formatting and "balance last updated" timestamps stay reproducible.
public protocol DateProvider: AnyObject {
    /// The current instant according to whichever implementation is registered.
    func now() -> Date
}

/// Production `DateProvider` backed by `Date()`.
public final class DefaultDateProvider: DateProvider {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
