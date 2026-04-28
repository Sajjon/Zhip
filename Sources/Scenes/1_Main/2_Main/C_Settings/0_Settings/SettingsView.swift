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

import Combine
import SingleLineControllerCombine
import SingleLineControllerCore
import UIKit
import SingleLineControllerController
import SingleLineControllerSceneViews

// MARK: - SettingsView

/// Settings hub — a `.grouped` table view backed by `SingleCellTypeTableView`
/// (via `HeaderlessTableViewSceneView`). All sections + cells are produced
/// reactively by the view-model.
final class SettingsView: HeaderlessTableViewSceneView<SettingsTableViewCell> {
    /// Default initializer — picks `.grouped` style for the section dividers.
    init() {
        super.init(style: .grouped)
    }

    /// Storyboards/xibs aren't used in this app.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Override-hook from `HeaderlessTableViewSceneView` — adds bottom inset
    /// so the version-string footer doesn't crowd the screen edge.
    override func setup() {
        tableView.contentInset = UIEdgeInsets(top: 0, bottom: 30)
    }
}

extension SettingsView: ViewModelled {
    typealias ViewModel = SettingsViewModel

    /// Routes the section snapshots into the diffable data source and the
    /// footer-text into the table footer.
    func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.sections --> tableView.sections,
            viewModel.footerText --> tableView.footerLabelBinder,
        ]
    }

    /// Surfaces only row selection — the view-model maps each `IndexPath` to a navigation step.
    var inputFromView: InputFromView {
        InputFromView(
            selectedIndexPath: tableView.selectionPublisher
        )
    }
}
