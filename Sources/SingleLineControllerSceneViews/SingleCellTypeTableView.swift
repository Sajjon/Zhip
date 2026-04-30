// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCombine
import SingleLineControllerCore
import UIKit

/// Constraint typealias for cells usable with `SingleCellTypeTableView` —
/// must be both a `UITableViewCell` (for the layout chassis) and
/// `CellConfigurable` (so `configure(model:)` is callable).
public typealias ListCell = CellConfigurable & UITableViewCell

/// Strongly-typed table view: one cell type, one model type per row, optional
/// `Header` per section. Also serves as its own `dataSource` and `delegate`,
/// and exposes selection as a Combine publisher (via `SelectionPublishing`).
///
/// Why "single cell type"? Most app tables use a uniform cell — being
/// explicit about that lets the type system carry the cell/model pairing
/// end-to-end and avoids the usual cast-and-pray pattern.
open class SingleCellTypeTableView<Header, Cell: ListCell>: UITableView, UITableViewDelegate, UITableViewDataSource,
    SelectionPublishing {
    // MARK: - Data

    /// The data backing the table. Setting it triggers a full `reloadData()`
    /// — fine for small tables (settings/wallet rows). Performance-sensitive
    /// callers should switch to a diffable data source.
    private var sectionModels: [SectionModel<Header, Cell.Model>] = [] {
        didSet { reloadData() }
    }

    /// Sink: bind a publisher of section models to reload the table.
    public var sections: Binder<[SectionModel<Header, Cell.Model>]> {
        Binder(self) { $0.sectionModels = $1 }
    }

    // MARK: - Selection

    /// Internal subject the delegate pushes index paths into.
    private let selectionSubject = PassthroughSubject<IndexPath, Never>()
    /// `SelectionPublishing` conformance — the public publisher of selected rows.
    public var selectionPublisher: AnyPublisher<IndexPath, Never> {
        selectionSubject.eraseToAnyPublisher()
    }

    /// Alias preferred by some scenes that read more naturally as
    /// `tableView.didSelectItem`.
    public var didSelectItem: AnyPublisher<IndexPath, Never> {
        selectionPublisher
    }

    /// Whether to auto-deselect rows on tap. Defaults to immediate animated
    /// deselection (matches iOS HIG for non-stateful selection); scenes can
    /// switch to `.noImmediateDeselection` if they want to keep the selection
    /// highlight visible (e.g. master-detail).
    public var cellDeselectionMode: CellDeselectionMode = .deselectCellsDirectly(animate: true)

    // MARK: - Initialization

    /// Designated initialiser — pass through to `UITableView`'s
    /// `(frame:style:)` and run the local setup chain.
    public init(style: UITableView.Style) {
        super.init(frame: .zero, style: style)
        setup()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    // MARK: - UITableViewDelegate

    /// Selection delegate hook — applies the configured deselection policy,
    /// then forwards the index path through `selectionSubject`.
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch cellDeselectionMode {
        case let .deselectCellsDirectly(animated): tableView.deselectRow(at: indexPath, animated: animated)
        case .noImmediateDeselection: break
        }
        selectionSubject.send(indexPath)
    }

    // MARK: - UITableViewDataSource

    /// Number of sections — derived from `sectionModels.count`.
    public func numberOfSections(in _: UITableView) -> Int {
        sectionModels.count
    }

    /// Number of rows in `section` — derived from the section's `items.count`.
    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sectionModels[section].items.count
    }

    /// Dequeues a `Cell` (by its auto-derived `ReuseIdentifiable.identifier`) and
    /// hands it the matching model via `configure(model:)`.
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.identifier, for: indexPath)
        if let typedCell = cell as? Cell {
            typedCell.configure(model: sectionModels[indexPath.section].items[indexPath.row])
        }
        return cell
    }
}

// MARK: - CellDeselectionMode

public extension SingleCellTypeTableView {
    /// Policy for what happens to a row's selection highlight after a tap.
    enum CellDeselectionMode {
        /// Deselect the row immediately on tap, optionally animated.
        case deselectCellsDirectly(animate: Bool)
        /// Leave the selection highlight visible — the scene is expected to
        /// manage deselection itself (e.g. on segue completion).
        case noImmediateDeselection
    }
}

// MARK: - Private

private extension SingleCellTypeTableView {
    /// Auto Layout setup, cell registration, and self-as-delegate/dataSource.
    /// Clear background + no separators is a common chrome default; consumers
    /// override after init if they want the system look.
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        register(Cell.self, forCellReuseIdentifier: Cell.identifier)
        backgroundColor = .clear
        separatorStyle = .none
        dataSource = self
        delegate = self
    }
}

// MARK: - SectionModel

/// Minimal section model.
///
/// Kept in this file because it's specific to the diffable-data-source-style
/// usage of `SingleCellTypeTableView`.
public struct SectionModel<Section, Item> {
    /// Section payload — `Header` in the table-view generic; can be `Void`.
    public let model: Section
    /// Rows in this section.
    public let items: [Item]

    /// Memberwise initializer.
    public init(model: Section, items: [Item]) {
        self.model = model
        self.items = items
    }
}
