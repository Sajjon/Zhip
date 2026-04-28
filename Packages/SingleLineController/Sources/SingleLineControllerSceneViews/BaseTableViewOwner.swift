// MIT License — Copyright (c) 2018-2026 Open Zesame

import SingleLineControllerCore
import UIKit

/// Idiomatic shape for table-backed scenes — combines `BaseTableViewOwner`
/// with the `TableViewOwner` marker so the scene's `populate(with:)` can
/// reach the strongly-typed table view through the `TableViewOwner.tableView`
/// requirement.
public typealias TableViewSceneView<Header, Cell: ListCell> = BaseTableViewOwner<Header, Cell> & TableViewOwner

/// Convenience for table scenes that don't have section headers — uses `Void`
/// as the header type so the diffable data source still type-checks but the
/// header value can be ignored entirely.
public typealias HeaderlessTableViewSceneView<Cell: ListCell> = TableViewSceneView<Void, Cell>

/// `AbstractSceneView` specialisation that hosts a `SingleCellTypeTableView`
/// as its scroll view. Generic over `Header` and `Cell` types so the diffable
/// data source has a single, statically-typed source of truth for both.
open class BaseTableViewOwner<Header, Cell: ListCell>: AbstractSceneView {
    /// The owned, strongly-typed table view. Identical reference to the
    /// abstract base's `scrollView`, just typed concretely so call sites can
    /// drive the diffable data source without casting.
    public let tableView: SingleCellTypeTableView<Header, Cell>

    // MARK: - Initialization

    /// Constructs the table with the requested UIKit style (plain, grouped,
    /// inset-grouped) and passes it as the scroll view to the abstract base.
    /// Then runs the `setup()` hook so subclasses can do per-scene wiring.
    public init(style: UITableView.Style) {
        tableView = SingleCellTypeTableView(style: style)
        super.init(scrollView: tableView)
        setup()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }
}
