//
// MIT License
//
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import UIKit

/// Protocol exposing the runtime class name as a `String`. Restricted to
/// `NSObjectProtocol` so we can reach `NSStringFromClass`.
protocol ClassIdentifiable: NSObjectProtocol {
    /// The class name (without the module prefix).
    static var className: String { get }
}

/// Protocol exposing a stable string identifier — used as the cell-reuse
/// identifier in `SingleCellTypeTableView`.
///
/// Note: deliberately not named `Swift.Identifiable` because we don't want to
/// conform to the system protocol (which has different semantics).
protocol Identifiable {
    /// Stable string identifier.
    static var identifier: String { get }
}

extension Identifiable where Self: ClassIdentifiable {
    /// Default — derive `identifier` from the class name. Lets every cell
    /// type get a unique reuse identifier without per-cell boilerplate.
    static var identifier: String {
        className
    }
}

/// Auto-conform every `UITableViewCell` to `Identifiable` so cells can be
/// registered/dequeued by class without manual identifier strings.
extension UITableViewCell: Identifiable {}

extension NSObject: ClassIdentifiable {
    /// Strips the module prefix from `NSStringFromClass` to return the bare
    /// type name (e.g. `"Zhip.SettingsTableViewCell"` → `"SettingsTableViewCell"`).
    /// Force-unwraps the last component because every `NSStringFromClass`
    /// result is non-empty by definition.
    static var className: String {
        NSStringFromClass(self).components(separatedBy: ".").last!
    }
}
