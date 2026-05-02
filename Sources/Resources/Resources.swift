// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Namespace for accessing the bundled resources (xcstrings, asset catalog,
/// fonts, html, audio) that ship with the SPM `Resources` module.
///
/// Pre-extraction Zhip read these files from `Bundle.main`. With the assets
/// living inside an SPM target, the right bundle is the auto-generated
/// `Bundle.module`. Consumers reach the bundle through `Resources.bundle`
/// (and the typed accessors below) so we never sprinkle `Bundle.module`
/// references through the rest of the codebase.
public enum Resources {
    /// The `Bundle.module` accessor for this SPM target. Routes asset / font /
    /// html / audio lookups to the in-tree resources rather than the host
    /// app's main bundle.
    public static let bundle: Bundle = .module
}

// MARK: - Localized strings

public extension String {
    /// `String(localized:)` overload that resolves the catalog out of the
    /// `Resources` module's bundle. Each `.xcstrings` file in
    /// `Sources/Resources/Resources/` becomes its own catalog at build time;
    /// pass the catalog name as `table` (e.g. `String.localized("send.cta", table: "Send")`).
    static func localized(_ key: String.LocalizationValue, table: String? = nil) -> String {
        String(localized: key, table: table, bundle: Resources.bundle)
    }
}
