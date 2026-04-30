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

import SingleLineControllerCombine
import SingleLineControllerCore
import UIKit

/// Themed indeterminate-progress spinner. Replaces `UIActivityIndicatorView`
/// across the app so the visual style matches the rest of the chrome (3pt
/// rounded-cap white stroke that grows-then-shrinks while rotating).
///
/// The animation is a single `CAAnimationGroup` driving four properties on
/// a `CAShapeLayer` arc; see `addAnimation()` for the four-stage breakdown.
public class SpinnerView: UIView {
    /// Backing arc layer. `internal` so tests can verify configuration without
    /// reaching into private state.
    let circleLayer = CAShapeLayer()
    /// `true` while a spinner animation is currently attached. Read-only
    /// externally; set via `start`/`stopSpinning`.
    private(set) var isAnimating = false
    /// One full sweep duration in seconds. Default 2s reads as a slow, calm
    /// progress indicator — fast enough to feel alive, slow enough to feel
    /// patient. Settable so tests can tighten the loop.
    var animationDuration: TimeInterval = 2

    /// Programmatic init. Always builds with a white stroke (the only colour
    /// used by the project; refactor the signature if that changes).
    init() {
        super.init(frame: .zero)
        setup(strokeColor: .white)
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Recompute the arc path on every layout pass *only* if the bounds
    /// changed — `path` rebuilds are expensive enough to be worth gating.
    public override func layoutSubviews() {
        super.layoutSubviews()
        if circleLayer.frame != bounds {
            updateCircleLayer()
        }
    }
}

extension SpinnerView {
    /// Show the spinner and (re)attach the animation. No-op if already animating.
    func startSpinning() {
        isHidden = false
        guard !isAnimating else { return }
        isAnimating = true
        addAnimation()
    }

    /// Hide the spinner and remove the animation. Hiding (rather than alpha
    /// fade) saves layout cost when the spinner sits in a stack view.
    func stopSpinning() {
        isHidden = true
        isAnimating = false
        circleLayer.removeAnimation(forKey: .spinner)
    }

    /// Bool→start/stop bridge used by `isLoadingBinder`.
    func changeTo(isLoading: Bool) {
        if isLoading {
            startSpinning()
        } else {
            stopSpinning()
        }
    }
}

extension SpinnerView {
    /// Reactive sink: bind a `Bool` publisher to drive the spinner.
    var isLoadingBinder: Binder<Bool> {
        Binder(self) {
            $0.changeTo(isLoading: $1)
        }
    }
}

private extension SpinnerView {
    /// One-time layer config. The arc is drawn fully empty
    /// (`strokeStart == strokeEnd == 0`) so an inactive spinner has no visible
    /// fill — `addAnimation()` then animates the strokes outward.
    func setup(strokeColor: UIColor) {
        translatesAutoresizingMaskIntoConstraints = false
        layer.addSublayer(circleLayer)

        circleLayer.fillColor = nil
        circleLayer.lineWidth = 3

        circleLayer.strokeColor = strokeColor.cgColor
        circleLayer.strokeStart = 0
        circleLayer.strokeEnd = 0

        circleLayer.lineCap = .round

        stopSpinning()
    }

    /// Builds the circular `UIBezierPath` and seats it on the shape layer.
    /// The radius is reduced by half the line width so the stroke doesn't
    /// clip at the bounds edges.
    func updateCircleLayer() {
        let height = bounds.height
        let center = CGPoint(x: bounds.size.width / 2, y: height / 2)
        let radius = (height - circleLayer.lineWidth) / 2

        let startAngle: CGFloat = 0
        let endAngle: CGFloat = 2 * .pi

        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        circleLayer.path = path.cgPath
        circleLayer.frame = bounds
    }

    /// Composes the indeterminate animation: a continuous rotation plus a
    /// two-phase stroke "grow then chase" cycle.
    ///
    /// Phase 1 (first half): start at 0, grow head→0.25, tail→1 (the visible
    /// arc lengthens from a dot into a 3/4-circle).
    /// Phase 2 (second half): head chases tail from 0.25→1 (the arc shortens
    /// back to nothing while keeping its tail pinned).
    /// `repeatCount: .infinity` and `isRemovedOnCompletion = false` keep it
    /// going until `stopSpinning()` removes the animation key.
    func addAnimation() {
        let rotateAnimation = CAKeyframeAnimation(keyPath: .transformRotation)

        rotateAnimation.values = [0, Float.pi, 2 * Float.pi]

        let halfDuration = animationDuration / 2

        let headAnimation = CABasicAnimation(keyPath: .strokeStart)
        headAnimation.duration = halfDuration
        headAnimation.fromValue = 0
        headAnimation.toValue = 0.25

        let tailAnimation = CABasicAnimation(keyPath: .strokeEnd)
        tailAnimation.duration = halfDuration
        tailAnimation.fromValue = 0
        tailAnimation.toValue = 1

        let endHeadAnimation = CABasicAnimation(keyPath: .strokeStart)
        endHeadAnimation.beginTime = halfDuration
        endHeadAnimation.duration = halfDuration
        endHeadAnimation.fromValue = 0.25
        endHeadAnimation.toValue = 1

        let endTailAnimation = CABasicAnimation(keyPath: .strokeEnd)
        endTailAnimation.beginTime = halfDuration
        endTailAnimation.duration = halfDuration
        endTailAnimation.fromValue = 1
        endTailAnimation.toValue = 1

        let animations = CAAnimationGroup()
        animations.duration = animationDuration
        animations.animations = [
            rotateAnimation,
            headAnimation,
            tailAnimation,
            endHeadAnimation,
            endTailAnimation,
        ]
        animations.repeatCount = .infinity
        animations.isRemovedOnCompletion = false

        circleLayer.add(animations, forKey: .spinner)
    }
}

/// Animation/keypath identifiers — kept private to this file because they're
/// implementation details of the spinner.
private extension String {
    /// Animation key under which the group lives on `circleLayer`.
    static let spinner = SpinnerView.description()
    /// `CAShapeLayer.strokeStart` keypath, as a typed constant.
    static let strokeStart = "strokeStart"
    /// `CAShapeLayer.strokeEnd` keypath, as a typed constant.
    static let strokeEnd = "strokeEnd"
    /// `CALayer.transform.rotation` keypath, as a typed constant.
    static let transformRotation = "transform.rotation"
}
