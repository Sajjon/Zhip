// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Error protocol every per-validator `Error` enum conforms to so the view
/// layer can render a localized message without knowing the concrete type.
///
/// `isEqual(_:)` is needed because `Validation`'s `Equatable` conformance
/// has to compare typed errors through the existential without relying on
/// each error type also being `Equatable`.
public protocol InputError: Swift.Error, CustomStringConvertible {
    /// The localized, user-facing message rendered in the floating-label field.
    var errorMessage: String { get }
    /// Existential equality. Default is "always equal" — override per-error
    /// to compare associated values (see `WalletEncryptionPassword.Error`).
    func isEqual(_ error: InputError) -> Bool
}

public extension CustomStringConvertible where Self: InputError {
    /// Default `description` simply forwards to `errorMessage`.
    var description: String {
        errorMessage
    }
}

public extension InputError {
    /// Default impl — treat all values of the same case as equal. Concrete
    /// errors with associated values that matter for equality (e.g. password
    /// rule errors) should override.
    func isEqual(_: InputError) -> Bool {
        true
    }
}
