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
import UIKit
import XCTest
@testable import AppFeature

/// Exercises the `UITableView.setFooterLabel(text:)` helper and
/// `footerLabelBinder`.
final class UITableViewFooterTests: XCTestCase {
    func test_setFooterLabel_installsFooterView() {
        let tableView = UITableView()

        tableView.setFooterLabel(text: "hello")

        XCTAssertNotNil(tableView.tableFooterView)
    }

    func test_setFooterLabel_reusesExistingFooterView() {
        let tableView = UITableView()
        tableView.setFooterLabel(text: "first")
        let firstFooter = tableView.tableFooterView

        tableView.setFooterLabel(text: "second")

        XCTAssertTrue(tableView.tableFooterView === firstFooter)
    }

    func test_footerLabelBinder_setsFooterText() {
        let tableView = UITableView()

        tableView.footerLabelBinder.on("bound")

        XCTAssertNotNil(tableView.tableFooterView)
    }

    func test_itemSelectedPublisher_onUnconformingTableView_returnsEmpty() {
        let tableView = UITableView()
        var received: IndexPath?
        var cancellables: Set<AnyCancellable> = []

        tableView.itemSelectedPublisher
            .sink { received = $0 }
            .store(in: &cancellables)

        XCTAssertNil(received)
    }
}
