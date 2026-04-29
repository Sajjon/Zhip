// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Marker-with-payload protocol opt-into by `SceneController` subclasses that want
/// the navigation bar title set automatically.
///
/// `SceneController.viewDidLoad()` checks `self as? TitledScene` and, if present,
/// assigns `sceneTitle` to `UIViewController.title`. Conformers only need to
/// override `static var title` — the instance-side `sceneTitle` is provided
/// by the default extension.
public protocol TitledScene {
    /// The string to display in the navigation bar for this scene type.
    /// Defaults to the empty string (no title) via the protocol extension.
    static var title: String { get }
}

public extension TitledScene {
    /// Default — no title. Override on a per-scene basis when one is needed.
    static var title: String {
        ""
    }

    /// Instance-side accessor that simply forwards to the static `title`.
    /// Exists so call sites can read the title without knowing the concrete
    /// metatype, and so `SceneController.viewDidLoad()` can do
    /// `(self as? TitledScene)?.sceneTitle` cleanly.
    var sceneTitle: String {
        Self.title
    }
}
