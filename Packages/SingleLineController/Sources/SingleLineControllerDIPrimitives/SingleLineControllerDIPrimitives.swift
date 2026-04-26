// MIT License — Copyright (c) 2018-2026 Open Zesame
//
// SingleLineControllerDIPrimitives (UIKit) — protocol-only DI primitives
// (Clock, MainScheduler, DateProvider, HapticFeedback, Pasteboard, UrlOpener).
// Deliberately NO dependency on Factory / any specific DI container —
// consumers wire their own. File-moves into this module land in Phase 6.

/// Module-version sentinel. Allows `import SingleLineControllerDIPrimitives`
/// to succeed during Phase 0 (skeleton) before any real types have been
/// migrated.
public enum SingleLineControllerDIPrimitives {
    /// Semantic version of the `SingleLineControllerDIPrimitives` module.
    public static let version = "0.0.1"
}
