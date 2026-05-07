//
// MIT License
//
// Copyright (c) 2018-2026 Alexander Cyon (https://github.com/sajjon)
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
import UIKit
import XCTest

/// Exercises the in-house `UIView+AutoLayout` helpers — primarily covers the
/// `usingSafeArea: true` branches and the size/stack helpers the existing
/// `UIViewExtensionsTests` doesn't reach.
@MainActor
final class UIViewAutoLayoutTests: XCTestCase {
    private var parent: UIView!
    private var sut: UIView!

    override func setUp() {
        super.setUp()
        parent = UIView()
        sut = UIView()
        parent.addSubview(sut)
    }

    override func tearDown() {
        sut = nil
        parent = nil
        super.tearDown()
    }

    // MARK: - centerInSuperview / center{X,Y}ToSuperview

    func test_centerInSuperview_activatesBothCenterConstraints() {
        let constraints = sut.centerInSuperview()

        XCTAssertEqual(constraints.count, 2)
        XCTAssertTrue(constraints.allSatisfy(\.isActive))
        XCTAssertFalse(sut.translatesAutoresizingMaskIntoConstraints)
    }

    func test_centerXToSuperview_withSafeArea_usesSafeAreaAnchor() {
        let constraint = sut.centerXToSuperview(usingSafeArea: true)

        XCTAssertTrue(constraint.isActive)
        XCTAssertEqual(constraint.constant, 0)
    }

    func test_centerYToSuperview_withSafeArea_usesSafeAreaAnchor() {
        let constraint = sut.centerYToSuperview(offset: 12, usingSafeArea: true)

        XCTAssertTrue(constraint.isActive)
        XCTAssertEqual(constraint.constant, 12)
    }

    // MARK: - top/bottom/leading/trailing — safe-area branches

    func test_topToSuperview_withSafeArea() {
        let constraint = sut.topToSuperview(offset: 8, usingSafeArea: true)

        XCTAssertTrue(constraint.isActive)
        XCTAssertEqual(constraint.constant, 8)
    }

    func test_bottomToSuperview_withSafeArea() {
        let constraint = sut.bottomToSuperview(offset: -16, usingSafeArea: true)

        XCTAssertTrue(constraint.isActive)
        XCTAssertEqual(constraint.constant, -16)
    }

    func test_leadingToSuperview_withSafeArea() {
        let constraint = sut.leadingToSuperview(offset: 4, usingSafeArea: true)

        XCTAssertTrue(constraint.isActive)
        XCTAssertEqual(constraint.constant, 4)
    }

    func test_trailingToSuperview_withSafeArea() {
        let constraint = sut.trailingToSuperview(offset: -4, usingSafeArea: true)

        XCTAssertTrue(constraint.isActive)
        XCTAssertEqual(constraint.constant, -4)
    }

    // MARK: - left/right — pin to absolute (LTR-only) edges

    func test_leftToSuperview_default() {
        let constraint = sut.leftToSuperview()

        XCTAssertTrue(constraint.isActive)
        XCTAssertEqual(constraint.constant, 0)
    }

    func test_leftToSuperview_withSafeArea() {
        let constraint = sut.leftToSuperview(offset: 5, usingSafeArea: true)

        XCTAssertTrue(constraint.isActive)
        XCTAssertEqual(constraint.constant, 5)
    }

    func test_rightToSuperview_default() {
        let constraint = sut.rightToSuperview(offset: -10)

        XCTAssertTrue(constraint.isActive)
        XCTAssertEqual(constraint.constant, -10)
    }

    func test_rightToSuperview_withSafeArea() {
        let constraint = sut.rightToSuperview(usingSafeArea: true)

        XCTAssertTrue(constraint.isActive)
    }

    // MARK: - heightToSuperview / size

    func test_heightToSuperview_matchesSuperviewHeight() {
        let constraint = sut.heightToSuperview()

        XCTAssertTrue(constraint.isActive)
    }

    func test_size_pinsBothWidthAndHeight() {
        let constraints = sut.size(CGSize(width: 100, height: 50))

        XCTAssertEqual(constraints.count, 2)
        XCTAssertTrue(constraints.allSatisfy(\.isActive))
        XCTAssertEqual(constraints[0].constant, 100)
        XCTAssertEqual(constraints[1].constant, 50)
    }

    // MARK: - bottomToTop — sibling stacking

    func test_bottomToTop_pinsThisViewAboveOther() {
        let other = UIView()
        parent.addSubview(other)

        let constraint = sut.bottomToTop(of: other, offset: -8)

        XCTAssertTrue(constraint.isActive)
        XCTAssertEqual(constraint.constant, -8)
    }

    // MARK: - hugging / compression-resistance

    func test_setHugging_appliesPriorityForAxis() {
        sut.setHugging(.required, for: .horizontal)

        XCTAssertEqual(sut.contentHuggingPriority(for: .horizontal), .required)
    }

    func test_setCompressionResistance_appliesPriorityForAxis() {
        sut.setCompressionResistance(.defaultLow, for: .vertical)

        XCTAssertEqual(sut.contentCompressionResistancePriority(for: .vertical), .defaultLow)
    }
}
