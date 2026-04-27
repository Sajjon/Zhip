// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

extension Validation: CustomStringConvertible {
    /// Debug-friendly description used in test failures and `po self` output.
    public var description: String {
        switch self {
        case let .valid(_, remark):
            if let remark {
                "Valid with remark: \(remark.description)"
            } else {
                "Valid"
            }
        case let .invalid(invalid):
            switch invalid {
            case .empty: "empty"
            case let .error(error): "error: \(error.description)"
            }
        }
    }
}
