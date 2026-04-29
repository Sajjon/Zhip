// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

// MARK: - Equatable

extension AnyValidation: Equatable {
    /// Field-by-field equality. `.valid` matches on the remark string;
    /// `.errorMessage` matches on the message; `.empty` matches itself only.
    public static func == (lhs: AnyValidation, rhs: AnyValidation) -> Bool {
        switch (lhs, rhs) {
        case let (.valid(lhsRemark), .valid(rhsRemark)): lhsRemark == rhsRemark
        case (.empty, .empty): true
        case let (.errorMessage(lhsError), .errorMessage(rhsError)): lhsError == rhsError
        default: false
        }
    }
}
