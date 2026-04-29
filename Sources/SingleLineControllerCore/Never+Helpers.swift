// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Stub used in `init?(coder:)` overrides — the app does not use Storyboards
/// or XIBs, so these initializers should never be invoked.
public var interfaceBuilderSucks: Never {
    fatalError("interfaceBuilderSucks")
}

/// Crashes with a descriptive message. Used at code-paths that indicate a
/// programmer error rather than a user-facing failure (e.g. missing font file,
/// unreachable switch case in an exhaustive enum).
public func incorrectImplementation(_ message: CustomStringConvertible) -> Never {
    fatalError("Incorrect implementation - \(message.description)")
}

/// Marker for "abstract" stored properties or methods that subclasses are
/// expected to override. Crashes if invoked on the base class.
public var abstract: Never {
    fatalError("Override me")
}
