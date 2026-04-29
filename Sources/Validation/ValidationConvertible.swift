// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Anything that can project itself to an `AnyValidation` for view-layer rendering.
///
/// `Validation<Value, Error>` and `AnyValidation` itself both conform —
/// the protocol exists so generic publisher helpers like `onlyErrors()`
/// work on both shapes uniformly.
public protocol ValidationConvertible {
    /// The view-friendly type-erased projection.
    var validation: AnyValidation { get }
}
