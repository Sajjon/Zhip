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

import Foundation

/// Marker-with-payload protocol for views that own a `SingleCellTypeTableView`.
/// Used by `BaseTableViewOwner` to surface the strongly-typed table view to
/// the scene's `populate(with:)` bindings, and by infrastructure (e.g.
/// pull-to-refresh) to reach the underlying scroll view.
protocol TableViewOwner {
    /// Section header model type — passed through to the diffable data source.
    associatedtype Header
    /// Cell view type. Must conform to `ListCell` so it carries an associated
    /// `Model` type the diffable data source can reference.
    associatedtype Cell: ListCell
    /// The owned, strongly-typed table view instance.
    var tableView: SingleCellTypeTableView<Header, Cell> { get }
}
