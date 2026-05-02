// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// Marker-with-payload protocol for views that own a `SingleCellTypeTableView`.
/// Used by `BaseTableViewOwner` to surface the strongly-typed table view to
/// the scene's `populate(with:)` bindings, and by infrastructure (e.g.
/// pull-to-refresh) to reach the underlying scroll view.
public protocol TableViewOwner {
    /// Section header model type — passed through to the diffable data source.
    associatedtype Header
    /// Cell view type. Must conform to `ListCell` so it carries an associated
    /// `Model` type the diffable data source can reference.
    associatedtype Cell: ListCell
    /// The owned, strongly-typed table view instance.
    var tableView: SingleCellTypeTableView<Header, Cell> { get }
}
