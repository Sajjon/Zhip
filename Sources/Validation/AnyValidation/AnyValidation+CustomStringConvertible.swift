// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

// MARK: - CustomStringConvertible

extension AnyValidation: CustomStringConvertible {
    /// Debug-friendly description used in test failures and `po self` output.
    public var description: String {
        switch self {
        case .empty: "empty"
        case let .valid(remark):
            if let remark {
                "valid, with remark: \(remark)"
            } else {
                "valid"
            }
        case let .errorMessage(errorMsg): "error: \(errorMsg)"
        }
    }
}
