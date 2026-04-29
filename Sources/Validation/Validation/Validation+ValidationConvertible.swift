// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

// MARK: - ValidationConvertible

extension Validation: ValidationConvertible {
    /// Erases the typed `Value`/`Error` to the view-friendly `AnyValidation`.
    /// Loses the typed payload but preserves the user-facing error/remark message.
    public var validation: AnyValidation {
        switch self {
        case let .invalid(invalid):
            switch invalid {
            case .empty: .empty
            case let .error(error): .errorMessage(error.errorMessage)
            }
        case let .valid(_, remark): .valid(withRemark: remark?.errorMessage)
        }
    }
}
