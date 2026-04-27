import UIKit
import XCTest
@testable import Zhip

@MainActor
final class SpinnerViewTests: XCTestCase {
    func test_init_isHiddenAndNotAnimating() {
        let sut = SpinnerView()
        XCTAssertFalse(sut.isAnimating)
        XCTAssertTrue(sut.isHidden)
    }

    func test_startSpinning_setsAnimatingTrueAndShows() {
        let sut = SpinnerView()
        sut.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        sut.layoutIfNeeded()

        sut.startSpinning()

        XCTAssertTrue(sut.isAnimating)
        XCTAssertFalse(sut.isHidden)
    }

    func test_startSpinning_calledTwice_doesNotRestart() {
        let sut = SpinnerView()
        sut.startSpinning()
        sut.startSpinning()
        XCTAssertTrue(sut.isAnimating)
    }

    func test_stopSpinning_setsAnimatingFalseAndHides() {
        let sut = SpinnerView()
        sut.startSpinning()

        sut.stopSpinning()

        XCTAssertFalse(sut.isAnimating)
        XCTAssertTrue(sut.isHidden)
    }

    func test_changeTo_isLoadingTrue_starts() {
        let sut = SpinnerView()
        sut.changeTo(isLoading: true)
        XCTAssertTrue(sut.isAnimating)
    }

    func test_changeTo_isLoadingFalse_stops() {
        let sut = SpinnerView()
        sut.startSpinning()
        sut.changeTo(isLoading: false)
        XCTAssertFalse(sut.isAnimating)
    }

    func test_isLoadingBinder_propagatesToChangeTo() {
        let sut = SpinnerView()
        sut.isLoadingBinder.on(true)
        XCTAssertTrue(sut.isAnimating)
        sut.isLoadingBinder.on(false)
        XCTAssertFalse(sut.isAnimating)
    }

    func test_layoutSubviews_updatesCircleLayer() {
        let sut = SpinnerView()
        sut.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        sut.layoutIfNeeded()
        XCTAssertEqual(sut.circleLayer.frame, sut.bounds)
    }
}
