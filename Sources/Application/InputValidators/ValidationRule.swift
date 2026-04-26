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

// In-app replacements for the abandoned `Validator` SPM package.
// These types mirror the Validator library's public API so existing
// code that imported Validator compiles unchanged after removing the dependency.

import Foundation

// MARK: - ValidationError

/// Marker protocol for validation errors.
public protocol ValidationError: Swift.Error {}

// MARK: - ValidationRule

/// A rule that validates a value of a given input type.
public protocol ValidationRule {
    /// The type the rule operates on (e.g. `String`).
    associatedtype InputType
    /// The error to surface when `validate(input:)` returns `false`.
    var error: ValidationError { get }
    /// Returns `true` if `input` satisfies the rule, `false` otherwise.
    func validate(input: InputType?) -> Bool
}

// MARK: - ValidationRuleCondition

/// A validation rule backed by a closure predicate.
public struct ValidationRuleCondition<T>: ValidationRule {
    public typealias InputType = T

    /// Error returned when `condition(input)` is `false`.
    public var error: ValidationError
    /// Predicate that defines whether the input is valid.
    private let condition: (T?) -> Bool

    /// Wraps `condition` in a `ValidationRule` that surfaces `error` on failure.
    public init(error: ValidationError, condition: @escaping (T?) -> Bool) {
        self.error = error
        self.condition = condition
    }

    /// Forwards to the wrapped closure.
    public func validate(input: T?) -> Bool {
        condition(input)
    }
}

// MARK: - ValidationRuleResult

/// The result returned after evaluating a `ValidationRuleSet`.
public enum ValidationRuleResult {
    /// All rules passed.
    case valid
    /// One or more rules failed; carries the typed errors in evaluation order.
    case invalid([ValidationError])
}

// MARK: - ValidationRuleSet

/// An ordered collection of rules all applied to the same input type.
public struct ValidationRuleSet<T> {
    /// Each rule is captured as a thunk so heterogeneous rule types can
    /// coexist in the same evaluator array.
    private var evaluators: [(T?) -> ValidationError?] = []

    /// Empty starting set — rules are added with `add(rule:)`.
    public init() {}

    /// Captures `rule` as an evaluator thunk and appends it to the set.
    public mutating func add<R: ValidationRule>(rule: R) where R.InputType == T {
        evaluators.append { input in
            rule.validate(input: input) ? nil : rule.error
        }
    }

    /// Runs every evaluator in insertion order. Returns `.valid` only when
    /// all of them pass, otherwise `.invalid(errors)` carrying every failure.
    public func validate(input: T?) -> ValidationRuleResult {
        let errors = evaluators.compactMap { $0(input) }
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

// MARK: - Validatable

/// A type that can be validated against a set of rules.
public protocol Validatable {
    /// Runs `rules` against `self` and returns the aggregated result.
    func validate(rules: ValidationRuleSet<Self>) -> ValidationRuleResult
}

public extension Validatable {
    /// Default impl forwards to `ValidationRuleSet.validate(input:)`.
    func validate(rules: ValidationRuleSet<Self>) -> ValidationRuleResult {
        rules.validate(input: self)
    }
}

// MARK: - String conformance (used by address/hex validators)

extension String: Validatable {}
