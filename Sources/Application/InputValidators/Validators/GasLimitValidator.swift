//
//  GasLimitValidator.swift
//  Zhip
//
//  Created by Alexander Cyon on 2021-05-30.
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//

import Zesame

/// Validates a Zilliqa transaction gas limit string, producing a `GasLimit`.
///
/// Rejects non-numeric input and values below `GasLimit.minimum` (the network
/// floor). The error type re-uses `AmountError<Qa>` so the message renders
/// in `qa` units (gas limit is always a count, not an amount of currency).
struct GasLimitValidator: InputValidator {
    typealias Error = AmountError<Qa>

    /// Parses `limitString`; rejects non-numeric input and values below `GasLimit.minimum`.
    func validate(input limitString: String) -> Validation<GasLimit, Error> {
        guard let gasLimit: GasLimit = .init(limitString) else {
            return error(Error.nonNumericString)
        }

        guard gasLimit >= GasLimit.minimum else {
            // showUnit: false because the limit is a unit-less count, not a currency amount.
            return error(Error.tooSmall(min: GasLimit.minimum.description, unit: .qa, showUnit: false))
        }

        return .valid(gasLimit)
    }
}
