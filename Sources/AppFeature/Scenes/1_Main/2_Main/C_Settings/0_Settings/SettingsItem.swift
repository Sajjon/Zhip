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

/// Minimal contract every Settings cell model implements so
/// `SettingsTableViewCell.populate(with:)` can render any of them.
public protocol CellModel {
    /// Configures the cell's text label.
    var labelStyle: UILabel.Style { get }
    /// Configures the cell's leading icon image view.
    var imageViewStyle: UIImageView.Style { get }
    /// Trailing accessory (chevron, checkmark, none).
    var accessoryType: UITableViewCell.AccessoryType { get }
}

/// Cell model that, when tapped, navigates to a typed `Destination` value.
/// Used in Settings to wrap each row's `SettingsNavigation` step.
public struct NavigatingCellModel<Destination> {
    /// The navigation step the row emits when tapped.
    public let destination: Destination
    /// Trailing accessory — defaults to `.disclosureIndicator`.
    public let accessoryType: UITableViewCell.AccessoryType

    /// Title text shown in the cell.
    private let title: String
    /// Optional leading icon.
    private let icon: UIImage?
    /// Visual style — `.normal` (teal icon) vs `.destructive` (red icon).
    private let style: Style

    /// Private — call sites use the `whenSelectedNavigate(to:...)` factory below.
    fileprivate init(
        title: String,
        icon: UIImage?,
        destination: Destination,
        style: Style,
        accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator
    ) {
        self.title = title
        self.icon = icon
        self.destination = destination
        self.style = style
        self.accessoryType = accessoryType
    }
}

extension NavigatingCellModel: CellModel {
    /// Composes the body label style with the cell's title text.
    public var labelStyle: UILabel.Style {
        var labelStyle = style.labelStyle
        labelStyle.text = title
        return labelStyle
    }

    /// Composes the default image view style with the icon + style-derived tint.
    public var imageViewStyle: UIImageView.Style {
        var imageViewStyle: UIImageView.Style = .default
        imageViewStyle.image = icon
        imageViewStyle.tintColor = style.iconTintColor
        return imageViewStyle
    }
}

extension NavigatingCellModel {
    /// Visual variants used by Settings to mark destructive rows in red.
    enum Style {
        /// Default styling — teal icon.
        case normal
        /// Destructive styling — blood-red icon (e.g. "Remove wallet", "Remove pincode").
        case destructive
    }
}

extension NavigatingCellModel.Style {
    /// Label style — both variants use body text; only the icon tint differs.
    var labelStyle: UILabel.Style {
        switch self {
        case .normal, .destructive: .body
        }
    }

    /// Icon tint — teal vs blood-red.
    var iconTintColor: UIColor {
        switch self {
        case .normal: .teal
        case .destructive: .bloodRed
        }
    }
}

extension NavigatingCellModel {
    /// Builder factory used by the Settings hub. Reads better at call sites
    /// than calling the (private) memberwise init directly.
    static func whenSelectedNavigate(
        to destination: Destination,
        titled title: String,
        icon: UIImage?,
        style: Style = .normal,
        accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator
    ) -> NavigatingCellModel {
        NavigatingCellModel(
            title: title,
            icon: icon,
            destination: destination,
            style: style,
            accessoryType: accessoryType
        )
    }
}
