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

/// Base class for the project's table-view cells. Composes a horizontal
/// `UIStackView` of [icon, label] inside `contentView` so subclasses get a
/// consistent look without re-implementing the layout.
///
/// Subclasses populate the views in `configure(model:)` (via
/// `CellConfigurable`) — see the `where Self: AbstractTableViewCell` extension
/// at the bottom for the default implementation that handles `CellModel`s.
class AbstractTableViewCell: UITableViewCell {
    /// Trailing label rendered after the icon. `fileprivate` so the
    /// `CellConfigurable` extension can populate it.
    fileprivate lazy var customLabel = UILabel()
    /// Leading icon. `fileprivate` for the same reason as `customLabel`.
    fileprivate lazy var customImageView = UIImageView()
    /// Horizontal stack composing icon + label.
    fileprivate lazy var stackView = UIStackView(arrangedSubviews: [customImageView, customLabel])

    /// Designated initialiser — runs the shared `setup()` then defers content
    /// to `configure(model:)`.
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }
}

private extension AbstractTableViewCell {
    /// One-time layout: clear background, default selection highlight,
    /// horizontal stack with proportional fill and 16pt horizontal margins,
    /// fixed 56pt row height. Per-cell content (label/image styling) is
    /// applied in `configure(model:)` instead.
    func setup() {
        backgroundColor = .clear
        selectionStyle = .default

        // Note that we should call `customLabel.withStyle(model.labelStyle)`
        // and `customImageView.withStyle(model.imageViewStyle)` inside `configure:model`
        stackView.withStyle(.horizontal) {
            $0.distribution(.fillProportionally)
                .layoutMargins(UIEdgeInsets(vertical: 0, horizontal: 16))
        }

        contentView.addSubview(stackView)
        stackView.edgesToSuperview()
        stackView.height(56)
    }
}

/// Concrete subclass parameterised on a `CellModel`. The empty body inherits
/// `configure(model:)` from the conditional extension below — most cells have
/// no extra logic beyond label/image styling, so the empty subclass is enough.
class TableViewCell<Model: CellModel>: AbstractTableViewCell, CellConfigurable {}

extension CellConfigurable where Self: AbstractTableViewCell, Model: CellModel {
    /// Default `configure(model:)` for any cell paired with a `CellModel` —
    /// applies the model's label style, image style, and accessory type.
    /// Subclasses can override to add their own behaviour after calling super.
    func configure(model: Model) {
        customLabel.withStyle(model.labelStyle)
        customImageView.withStyle(model.imageViewStyle)
        accessoryType = model.accessoryType
    }
}
