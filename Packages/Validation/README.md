# Validation

Reactive validation framework extracted from
[Zhip](https://github.com/OpenZesame/Zhip), sibling of the
[`SingleLineController`](../SingleLineController/) package in the same monorepo.

## What's in the package

| Type                              | Role                                                                       |
|-----------------------------------|----------------------------------------------------------------------------|
| `AnyValidation`                   | View-friendly type-erased verdict (`.valid(remark:)` / `.empty` / `.errorMessage(_)`) |
| `Validation<Value, Error>`        | Typed verdict — carries the typed value or the typed error                |
| `EditingValidation`               | Pair of "is the field being edited?" + the validation verdict             |
| `InputError`                      | Protocol every per-validator error enum conforms to                        |
| `ValidationConvertible`           | Anything that projects itself to an `AnyValidation`                       |
| `InputValidator`                  | Pure function from raw input to typed `Validation<Output, Error>`         |
| `ValidationRule` + `Set` + `Result` | Generic rule machinery (mirrors the abandoned `Validator` SPM API)        |
| `ValidationRulesOwner`            | Mixin protocol giving validators a default rule-set-driven `validate(input:)` |
| `Validatable`                     | Type that can validate itself against a rule set                           |
| `ValidationRuleHexadecimalCharacters` | Concrete rule used by the address / private-key validators            |
| `Publisher.eagerValidLazyErrorTurnedToEmptyOnEdit` | Reactive operator: show "valid" the moment the input becomes valid, but suppress error feedback while the user is still typing |

## Dependencies

- `SingleLineControllerCore` (for `ErrorTracker`)
- `SingleLineControllerCombine` (for the reactive operators)

## What stays in the consuming app

Per-domain validators (e.g. `AddressValidator`, `EncryptionPasswordValidator`,
`AmountValidator`) live in the consumer because their typed errors and
validation rules are domain-specific. The same goes for
`AnyValidation+Colors` (UIKit-coupled brand colors) — the package ships the
core enum, the consumer extends it with a `Color` namespace.
