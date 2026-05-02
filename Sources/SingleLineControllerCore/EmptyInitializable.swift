// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Marker protocol asserting "this type can be constructed with no arguments".
///
/// Used by `SceneController` to instantiate the root content view via
/// `(View.self as EmptyInitializable.Type).init()`. Declaring conformance is
/// effectively free for any type whose `init()` is non-failable.
public protocol EmptyInitializable {
    /// No-argument initialiser the harness uses to spin up an instance.
    init()
}
