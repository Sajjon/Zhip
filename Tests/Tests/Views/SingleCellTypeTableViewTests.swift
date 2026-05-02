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

@testable import AppFeature
import Combine
import NanoViewControllerSceneViews
import UIKit
import XCTest

/// Drives `SingleCellTypeTableView` selection forwarding and data loading so
/// its delegate/data-source methods and `CellDeselectionMode` branches run.
final class SingleCellTypeTableViewTests: XCTestCase {
    private typealias Model = NavigatingCellModel<String>
    private typealias Cell = TableViewCell<Model>
    private typealias Table = SingleCellTypeTableView<String, Cell>

    private var sut: Table!
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        sut = Table(style: .plain)
        sut.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
    }

    override func tearDown() {
        cancellables.removeAll()
        sut = nil
        super.tearDown()
    }

    private func makeItem(_ title: String) -> Model {
        Model.whenSelectedNavigate(to: title, titled: title, icon: nil)
    }

    func test_sectionsBinding_setsRowCounts() {
        sut.sections.on([SectionModel(model: "Header", items: [makeItem("A"), makeItem("B")])])
        sut.layoutIfNeeded()

        XCTAssertEqual(sut.numberOfSections, 1)
        XCTAssertEqual(sut.numberOfRows(inSection: 0), 2)
    }

    func test_cellForRow_configuresCell() {
        sut.sections.on([SectionModel(model: "Header", items: [makeItem("Item 0")])])
        sut.layoutIfNeeded()

        let cell = sut.tableView(sut, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is Cell)
    }

    func test_didSelectRow_deselectsAndEmitsSelection() {
        sut.sections.on([SectionModel(model: "h", items: [makeItem("Only")])])
        sut.layoutIfNeeded()
        var observed: IndexPath?
        sut.didSelectItem.sink { observed = $0 }.store(in: &cancellables)

        sut.tableView(sut, didSelectRowAt: IndexPath(row: 0, section: 0))

        XCTAssertEqual(observed, IndexPath(row: 0, section: 0))
    }

    func test_didSelectRow_noImmediateDeselection_stillEmitsSelection() {
        sut.cellDeselectionMode = .noImmediateDeselection
        sut.sections.on([SectionModel(model: "h", items: [makeItem("Only")])])
        sut.layoutIfNeeded()
        var observed: IndexPath?
        sut.didSelectItem.sink { observed = $0 }.store(in: &cancellables)

        sut.tableView(sut, didSelectRowAt: IndexPath(row: 0, section: 0))

        XCTAssertEqual(observed, IndexPath(row: 0, section: 0))
    }
}
