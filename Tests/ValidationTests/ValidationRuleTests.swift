// MIT License — Copyright (c) 2018-2026 Open Zesame

import XCTest
@testable import Validation

/// Tests for the rule machinery: `ValidationRuleCondition`, `ValidationRuleSet`,
/// `Validatable.validate(rules:)`, and the bundled
/// `ValidationRuleHexadecimalCharacters` rule.
final class ValidationRuleTests: XCTestCase {
    // MARK: - ValidationRuleCondition

    func test_condition_validatesTrueWhenClosureReturnsTrue() {
        let sut = ValidationRuleCondition<String>(error: StubRuleError.any) { ($0 ?? "").count > 2 }
        XCTAssertTrue(sut.validate(input: "abc"))
    }

    func test_condition_validatesFalseWhenClosureReturnsFalse() {
        let sut = ValidationRuleCondition<String>(error: StubRuleError.any) { ($0 ?? "").count > 5 }
        XCTAssertFalse(sut.validate(input: "abc"))
    }

    func test_condition_exposesError() {
        let sut = ValidationRuleCondition<String>(error: StubRuleError.any) { _ in true }
        XCTAssertTrue(sut.error is StubRuleError)
    }

    // MARK: - ValidationRuleSet

    func test_ruleSet_noRules_isAlwaysValid() {
        let set = ValidationRuleSet<String>()
        if case .invalid = set.validate(input: "any") { XCTFail("empty rule set should always be valid") }
    }

    func test_ruleSet_withPassingRule_isValid() {
        var set = ValidationRuleSet<String>()
        set.add(rule: ValidationRuleCondition(error: StubRuleError.any) { ($0 ?? "").count > 0 })
        if case .invalid = set.validate(input: "x") { XCTFail("passing rule should produce .valid") }
    }

    func test_ruleSet_withFailingRule_isInvalidAndReportsError() {
        var set = ValidationRuleSet<String>()
        set.add(rule: ValidationRuleCondition(error: StubRuleError.any) { _ in false })
        guard case let .invalid(errors) = set.validate(input: "x") else {
            return XCTFail("expected invalid")
        }
        XCTAssertEqual(errors.count, 1)
    }

    func test_ruleSet_accumulatesAllErrors() {
        var set = ValidationRuleSet<String>()
        set.add(rule: ValidationRuleCondition(error: StubRuleError.any) { _ in false })
        set.add(rule: ValidationRuleCondition(error: StubRuleError.other) { _ in false })
        guard case let .invalid(errors) = set.validate(input: "x") else {
            return XCTFail("expected invalid")
        }
        XCTAssertEqual(errors.count, 2)
    }

    // MARK: - Validatable on String

    func test_string_validatesAgainstRuleSet_valid() {
        var set = ValidationRuleSet<String>()
        set.add(rule: ValidationRuleCondition(error: StubRuleError.any) { ($0 ?? "").count > 0 })
        if case .invalid = "abc".validate(rules: set) { XCTFail("passing rule should produce .valid") }
    }

    func test_string_validatesAgainstRuleSet_invalid() {
        var set = ValidationRuleSet<String>()
        set.add(rule: ValidationRuleCondition(error: StubRuleError.any) { ($0 ?? "").count > 100 })
        if case .valid = "abc".validate(rules: set) { XCTFail("failing rule should produce .invalid") }
    }

    // MARK: - ValidationRuleHexadecimalCharacters

    func test_hexRule_acceptsValidHex() {
        let rule = ValidationRuleHexadecimalCharacters(error: StubRuleError.any)
        XCTAssertTrue(rule.validate(input: "0x1a2b3c"))
        XCTAssertTrue(rule.validate(input: "abcdef0123456789"))
    }

    func test_hexRule_rejectsNonHex() {
        let rule = ValidationRuleHexadecimalCharacters(error: StubRuleError.any)
        XCTAssertFalse(rule.validate(input: "hello world"))
        XCTAssertFalse(rule.validate(input: "g1h2i3"))
    }

    func test_hexRule_rejectsNil() {
        let rule = ValidationRuleHexadecimalCharacters(error: StubRuleError.any)
        XCTAssertFalse(rule.validate(input: nil))
    }
}

private enum StubRuleError: ValidationError {
    case any
    case other
}
