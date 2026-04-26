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

/// Idiomatic shape for table-backed scenes — combines `BaseTableViewOwner`
/// with the `TableViewOwner` marker so the scene's `populate(with:)` can
/// reach the strongly-typed table view through the `TableViewOwner.tableView`
/// requirement.
typealias TableViewSceneView<Header, Cell: ListCell> = BaseTableViewOwner<Header, Cell> & TableViewOwner

/// Convenience for table scenes that don't have section headers — uses `Void`
/// as the header type so the diffable data source still type-checks but the
/// header value can be ignored entirely.
typealias HeaderlessTableViewSceneView<Cell: ListCell> = TableViewSceneView<Void, Cell>

/// `AbstractSceneView` specialisation that hosts a `SingleCellTypeTableView`
/// as its scroll view. Generic over `Header` and `Cell` types so the diffable
/// data source has a single, statically-typed source of truth for both.
class BaseTableViewOwner<Header, Cell: ListCell>: AbstractSceneView {
    /// The owned, strongly-typed table view. Identical reference to the
    /// abstract base's `scrollView`, just typed concretely so call sites can
    /// drive the diffable data source without casting.
    let tableView: SingleCellTypeTableView<Header, Cell>

    // MARK: - Initialization

    /// Constructs the table with the requested UIKit style (plain, grouped,
    /// inset-grouped) and passes it as the scroll view to the abstract base.
    /// Then runs the `setup()` hook so subclasses can do per-scene wiring.
    init(style: UITableView.Style) {
        tableView = SingleCellTypeTableView(style: style)
        super.init(scrollView: tableView)
        setup()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }
}
