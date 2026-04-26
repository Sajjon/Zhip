// MIT License — Copyright (c) 2018-2026 Open Zesame
//
// Validation — sibling of SingleLineController. Reactive validation framework
// (AnyValidation, Validation, EditingValidation, InputValidator,
// ValidationRule*, eagerValidLazyErrorTurnedToEmptyOnEdit). File-moves into
// this module land in Phase 3 of the extraction plan.

/// Module-version sentinel. Allows `import Validation` to succeed during
/// Phase 0 (skeleton) before any real types have been migrated.
public enum Validation {
    /// Semantic version of the `Validation` module.
    public static let version = "0.0.1"
}
