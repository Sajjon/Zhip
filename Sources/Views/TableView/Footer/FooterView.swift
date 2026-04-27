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

import SingleLineControllerCore
import UIKit

/// Two-line centred-text footer used by `UITableView.setFooterLabel(text:height:)`
/// to attach a small grey caption below the table content (e.g. version info,
/// help links).
final class FooterView: UITableViewHeaderFooterView {
    /// Label inside the footer's `contentView`. Updated via `updateLabel(text:)`.
    private lazy var label = UILabel()

    /// Designated initialiser — runs `setup()` to install and style the label.
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }
}

extension FooterView {
    /// Updates the footer's caption text. Called by `UITableView.setFooterLabel(text:)`.
    func updateLabel(text: String) {
        label.text = text
    }
}

private extension FooterView {
    /// Centres a 2-line silver-grey hint label inside the footer's content view.
    func setup() {
        label.withStyle(.init(textAlignment: .center, textColor: .silverGrey, font: .hint, numberOfLines: 2))

        contentView.addSubview(label)
        label.edgesToSuperview()
    }
}
