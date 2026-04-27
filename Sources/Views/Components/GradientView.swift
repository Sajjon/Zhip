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

import UIKit
import SingleLineControllerCore

/// Pair of unit-square points describing a gradient's start and end.
/// `x` is the start point, `y` is the end point — yes the names are awkward,
/// but they match `CAGradientLayer.startPoint`/`endPoint` semantics.
public typealias GradientType = (x: CGPoint, y: CGPoint)

/// Eight cardinal/diagonal gradient directions, mapped to the unit-square
/// `CAGradientLayer` start/end points by `draw()`.
///
/// Cred goes to: https://medium.com/ios-os-x-development/swift-3-easy-gradients-54ccc9284ce4
public enum GradientPoint {
    /// Left → right horizontal gradient.
    case leftToRight
    /// Right → left horizontal gradient.
    case rightToLeft
    /// Top → bottom vertical gradient.
    case topToBottom
    /// Bottom → top vertical gradient.
    case bottomToTop
    /// Diagonal: top-left → bottom-right.
    case topLeftToBottomRight
    /// Diagonal: bottom-right → top-left.
    case bottomRightToTopLeft
    /// Diagonal: top-right → bottom-left.
    case topRightToBottomLeft
    /// Diagonal: bottom-left → top-right.
    case bottomLeftToTopRight

    /// Maps the symbolic direction to the underlying `(start, end)` unit-square
    /// points. Each cardinal direction picks the obvious centre/edge pair;
    /// diagonals connect opposite corners.
    func draw() -> GradientType {
        switch self {
        case .leftToRight:
            (x: CGPoint(x: 0, y: 0.5), y: CGPoint(x: 1, y: 0.5))
        case .rightToLeft:
            (x: CGPoint(x: 1, y: 0.5), y: CGPoint(x: 0, y: 0.5))
        case .topToBottom:
            (x: CGPoint(x: 0.5, y: 0), y: CGPoint(x: 0.5, y: 1))
        case .bottomToTop:
            (x: CGPoint(x: 0.5, y: 1), y: CGPoint(x: 0.5, y: 0))
        case .topLeftToBottomRight:
            (x: CGPoint(x: 0, y: 0), y: CGPoint(x: 1, y: 1))
        case .bottomRightToTopLeft:
            (x: CGPoint(x: 1, y: 1), y: CGPoint(x: 0, y: 0))
        case .topRightToBottomLeft:
            (x: CGPoint(x: 1, y: 0), y: CGPoint(x: 0, y: 1))
        case .bottomLeftToTopRight:
            (x: CGPoint(x: 0, y: 1), y: CGPoint(x: 1, y: 0))
        }
    }
}

/// `CAGradientLayer` subclass that lets us assign a `GradientType` directly
/// instead of writing both `startPoint` and `endPoint` separately.
public class GradientLayer: CAGradientLayer {
    /// Setting this updates `startPoint`/`endPoint` together — `nil` resets to
    /// `.zero` (which collapses the gradient to a single point).
    public var gradient: GradientType? {
        didSet {
            startPoint = gradient?.x ?? CGPoint.zero
            endPoint = gradient?.y ?? CGPoint.zero
        }
    }
}

/// `UIView` whose backing layer is a `GradientLayer`. Used for hero scenes
/// (welcome, splash) where the dark-blue background fades into a teal accent.
public class GradientView: UIView {
    /// Project-wide default colour stops — five-stop fade from translucent teal
    /// at the top to almost-opaque deepBlue at the bottom.
    public static var defaultColors: [UIColor] = [
        UIColor.teal.withAlphaComponent(0.25),
        UIColor.teal.withAlphaComponent(0.1),
        UIColor.deepBlue.withAlphaComponent(0.3),
        UIColor.deepBlue.withAlphaComponent(0.7),
        UIColor.deepBlue.withAlphaComponent(0.9),
    ]

    /// Direction of the gradient. Stored so `updateColors(_:withAlphaComponent:)`
    /// can re-apply it whenever the colours change.
    public let direction: GradientPoint

    /// Designated initialiser. `colors == nil` falls back to `defaultColors`.
    public init(direction: GradientPoint = .topToBottom, colors: [UIColor]? = nil) {
        self.direction = direction
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        gradientLayer.colors = (colors ?? GradientView.defaultColors).map(\.cgColor)
        gradientLayer.gradient = direction.draw()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    public required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Tells UIKit to back this view with a `GradientLayer` rather than the
    /// default `CALayer`, so `view.layer` is castable to our custom type.
    override public class var layerClass: Swift.AnyClass {
        GradientLayer.self
    }
}

public extension GradientView {
    /// Replaces the gradient colours, optionally pre-applying a uniform alpha
    /// to every colour. Re-applies `direction` so the gradient endpoints stay
    /// in sync if `colors` changed in length.
    func updateColors(_ colors: [UIColor], withAlphaComponent alpha: CGFloat? = nil) {
        var colors = colors
        if let alpha {
            colors = colors.map { $0.withAlphaComponent(alpha) }
        }
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.gradient = direction.draw()
    }
}

/// Generic association protocol — lets `GradientView` (and any future variants)
/// expose `gradientLayer` typed as the *concrete* layer subclass without each
/// view subclass having to write the cast itself.
public protocol GradientViewProvider {
    /// The concrete `CAGradientLayer` subclass this view uses.
    associatedtype GradientViewType
}

public extension GradientViewProvider where Self: GradientView {
    /// The view's backing layer, force-cast to the concrete `GradientViewType`.
    /// Force-cast is safe because `layerClass` overrides the layer creation.
    var gradientLayer: Self.GradientViewType {
        // swiftlint:disable:next force_cast
        layer as! Self.GradientViewType
    }
}

/// `GradientView` uses `GradientLayer` as its backing layer.
extension GradientView: GradientViewProvider {
    public typealias GradientViewType = GradientLayer
}

