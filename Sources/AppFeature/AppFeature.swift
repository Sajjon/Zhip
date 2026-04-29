// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Public entry point for the `AppFeature` SPM library — the entire Zhip
/// app (Coordinators, Scenes, ViewModels, Views, Models, UseCases, …)
/// minus the iOS-app shell that wires AppDelegate to UIKit.
///
/// The actual implementation lives in the migrated source trees being
/// folded into this target across Phases A2–A5. For now, this file just
/// declares the module's namespace so callers can `import AppFeature`.
public enum AppFeature {
    /// Module-version sentinel — verifies the SPM target compiles + links.
    public static let version = "0.1.0"
}
