@testable import AppFeature
import UIKit
import XCTest

@MainActor
final class GradientViewTests: XCTestCase {
    // MARK: - GradientPoint

    func test_draw_leftToRight() {
        let g = GradientPoint.leftToRight.draw()
        XCTAssertEqual(g.x, CGPoint(x: 0, y: 0.5))
        XCTAssertEqual(g.y, CGPoint(x: 1, y: 0.5))
    }

    func test_draw_rightToLeft() {
        let g = GradientPoint.rightToLeft.draw()
        XCTAssertEqual(g.x, CGPoint(x: 1, y: 0.5))
        XCTAssertEqual(g.y, CGPoint(x: 0, y: 0.5))
    }

    func test_draw_topToBottom() {
        let g = GradientPoint.topToBottom.draw()
        XCTAssertEqual(g.x, CGPoint(x: 0.5, y: 0))
        XCTAssertEqual(g.y, CGPoint(x: 0.5, y: 1))
    }

    func test_draw_bottomToTop() {
        let g = GradientPoint.bottomToTop.draw()
        XCTAssertEqual(g.x, CGPoint(x: 0.5, y: 1))
        XCTAssertEqual(g.y, CGPoint(x: 0.5, y: 0))
    }

    func test_draw_topLeftToBottomRight() {
        let g = GradientPoint.topLeftToBottomRight.draw()
        XCTAssertEqual(g.x, CGPoint(x: 0, y: 0))
        XCTAssertEqual(g.y, CGPoint(x: 1, y: 1))
    }

    func test_draw_bottomRightToTopLeft() {
        let g = GradientPoint.bottomRightToTopLeft.draw()
        XCTAssertEqual(g.x, CGPoint(x: 1, y: 1))
        XCTAssertEqual(g.y, CGPoint(x: 0, y: 0))
    }

    func test_draw_topRightToBottomLeft() {
        let g = GradientPoint.topRightToBottomLeft.draw()
        XCTAssertEqual(g.x, CGPoint(x: 1, y: 0))
        XCTAssertEqual(g.y, CGPoint(x: 0, y: 1))
    }

    func test_draw_bottomLeftToTopRight() {
        let g = GradientPoint.bottomLeftToTopRight.draw()
        XCTAssertEqual(g.x, CGPoint(x: 0, y: 1))
        XCTAssertEqual(g.y, CGPoint(x: 1, y: 0))
    }

    // MARK: - GradientLayer

    func test_gradientLayer_setGradient_setsStartAndEndPoints() {
        let layer = GradientLayer()
        let g: GradientType = (x: CGPoint(x: 0.1, y: 0.2), y: CGPoint(x: 0.9, y: 0.8))
        layer.gradient = g
        XCTAssertEqual(layer.startPoint, g.x)
        XCTAssertEqual(layer.endPoint, g.y)
    }

    func test_gradientLayer_setGradientNil_resetsToZero() {
        let layer = GradientLayer()
        layer.gradient = nil
        XCTAssertEqual(layer.startPoint, .zero)
        XCTAssertEqual(layer.endPoint, .zero)
    }

    // MARK: - GradientView

    func test_init_default_usesDefaultColors() {
        let view = GradientView()
        XCTAssertEqual(view.direction, .topToBottom)
        XCTAssertNotNil(view.gradientLayer.colors)
    }

    func test_init_customDirectionAndColors() {
        let colors: [UIColor] = [.red, .green, .blue]
        let view = GradientView(direction: .leftToRight, colors: colors)
        XCTAssertEqual(view.direction, .leftToRight)
        XCTAssertEqual(view.gradientLayer.colors?.count, 3)
    }

    func test_layerClass_isGradientLayer() {
        XCTAssertTrue(GradientView.layerClass == GradientLayer.self)
    }

    func test_updateColors_withoutAlpha_replacesColors() {
        let view = GradientView()
        view.updateColors([.red, .yellow])
        XCTAssertEqual(view.gradientLayer.colors?.count, 2)
    }

    func test_updateColors_withAlpha_appliesAlpha() {
        let view = GradientView()
        view.updateColors([.red, .yellow], withAlphaComponent: 0.3)
        XCTAssertEqual(view.gradientLayer.colors?.count, 2)
    }

    func test_defaultColors_hasFiveEntries() {
        XCTAssertEqual(GradientView.defaultColors.count, 5)
    }
}
