// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

extension Validation: Equatable {
    /// Equality on the *case*, not the value: any two `.valid` are considered
    /// equal regardless of `Value`. Errors are compared via `InputError.isEqual`
    /// so per-error overrides decide what counts as "the same error".
    public static func == <V, E>(lhs: Validation<V, E>, rhs: Validation<V, E>) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid): true
        case (.invalid(.empty), .invalid(.empty)): true
        case let (.invalid(.error(lhsError)), .invalid(.error(rhsError))): lhsError.isEqual(rhsError)
        default: false
        }
    }
}
