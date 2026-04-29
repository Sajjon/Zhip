// MIT License — Copyright (c) 2018-2026 Open Zesame

/// Marker protocol for `InputValidator`s that delegate to a `ValidationRuleSet`.
///
/// When combined with the matching extension in `InputValidator.swift` it gives
/// the conforming validator a default `validate(input:)` implementation that
/// just runs the rules and wraps the first failure in the validator's `Error`.
public protocol ValidationRulesOwner {
    /// Type the rules operate on (typically `String`).
    associatedtype RuleInput: Validatable
    /// The composed rule set evaluated by the default `validate(input:)`.
    var rules: ValidationRuleSet<RuleInput> { get }
}
