// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

/// Protocol for table-view cells that can be populated from a typed `Model`.
/// Used together with `SingleCellTypeTableView` so the table → cell wiring
/// stays statically type-checked end-to-end.
public protocol CellConfigurable {
    /// The model type this cell knows how to render.
    associatedtype Model
    /// Renders `model` into the cell. Called every time the table dequeues
    /// the cell for a new index path.
    func configure(model: Model)
}
