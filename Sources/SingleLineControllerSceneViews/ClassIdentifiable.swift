// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

/// Protocol exposing the runtime class name as a `String`. Restricted to
/// `NSObjectProtocol` so we can reach `NSStringFromClass`.
public protocol ClassIdentifiable: NSObjectProtocol {
    /// The class name (without the module prefix).
    static var className: String { get }
}

/// Protocol exposing a stable string reuse identifier — used as the
/// cell-reuse identifier in `SingleCellTypeTableView`.
///
/// Deliberately named `ReuseIdentifiable` (rather than the more obvious
/// `Identifiable`) to avoid shadowing Swift's stdlib `Identifiable` protocol.
/// They are unrelated — `Swift.Identifiable` requires an `id` of any
/// `Hashable` type for SwiftUI/diffing, whereas this requires a `String`
/// for UIKit cell registration.
public protocol ReuseIdentifiable {
    /// Stable string identifier used as the UIKit cell-reuse identifier.
    static var identifier: String { get }
}

public extension ReuseIdentifiable where Self: ClassIdentifiable {
    /// Default — derive `identifier` from the class name. Lets every cell
    /// type get a unique reuse identifier without per-cell boilerplate.
    static var identifier: String {
        className
    }
}

/// Auto-conform every `UITableViewCell` to `ReuseIdentifiable` so cells can be
/// registered/dequeued by class without manual identifier strings.
extension UITableViewCell: ReuseIdentifiable {}

extension NSObject: ClassIdentifiable {
    /// Strips the module prefix from `NSStringFromClass` to return the bare
    /// type name (e.g. `"Zhip.SettingsTableViewCell"` → `"SettingsTableViewCell"`).
    /// Force-unwraps the last component because every `NSStringFromClass`
    /// result is non-empty by definition.
    public static var className: String {
        NSStringFromClass(self).components(separatedBy: ".").last!
    }
}
