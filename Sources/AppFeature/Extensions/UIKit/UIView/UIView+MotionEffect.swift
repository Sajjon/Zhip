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

import UIKit

extension UIMotionEffect {
    /// Creates a 2-axis parallax motion effect that shifts the view's centre
    /// by ±`strength` points as the device tilts horizontally and vertically.
    /// Used to give layered hero artwork (welcome screen) a sense of depth.
    class func twoAxesShift(strength: CGFloat) -> UIMotionEffect {
        /// internal method that creates motion effect
        /// Builds one axis's interpolating effect — keypath choice tells UIKit
        /// which centre coordinate to interpolate.
        func motion(type: UIInterpolatingMotionEffect.EffectType) -> UIInterpolatingMotionEffect {
            let keyPath = type == .tiltAlongHorizontalAxis ? "center.x" : "center.y"
            let motion = UIInterpolatingMotionEffect(keyPath: keyPath, type: type)
            motion.minimumRelativeValue = -strength
            motion.maximumRelativeValue = strength
            return motion
        }

        // group of motion effects
        let group = UIMotionEffectGroup()
        group.motionEffects = [
            motion(type: .tiltAlongHorizontalAxis),
            motion(type: .tiltAlongVerticalAxis),
        ]
        return group
    }
}

extension UIView {
    /// Convenience: install a 2-axis tilt motion effect with the given strength.
    func addMotionEffect(strength: CGFloat) {
        addMotionEffect(.twoAxesShift(strength: strength))
    }

    /// Composes a three-layer parallax illusion: `back`, `middle`, `front`
    /// images stacked behind each other with progressively stronger motion.
    /// Returns the constructed image views in the same `(front, middle, back)`
    /// order so the caller can hold onto them if needed.
    func addMotionEffect(front: UIImage, middle: UIImage, back: UIImage) {
        addMotionEffectFromImages(front: front, middle: middle, back: back)
    }

    /// The actual workhorse — adds three image views (back-to-front), pins them
    /// edge-to-edge with a slight overscan so motion-driven offsets don't expose
    /// the layer's edges, and applies different motion strengths so the layers
    /// move at different rates (the "parallax" effect).
    ///
    /// Defaults: front=6, middle=20, back=48 — gives a comfortable depth feel
    /// without inducing motion sickness.
    @discardableResult
    func addMotionEffectFromImages(
        front: UIImage, motionEffectStrength frontStrength: CGFloat = 6,
        middle: UIImage, motionEffectStrength middleStrength: CGFloat = 20,
        back: UIImage, motionEffectStrength backStrength: CGFloat = 48,
        verticalInsetForImageViews: CGFloat = -40,
        horizontalInsetForImageViews: CGFloat = -80
        // swiftlint:disable:next large_tuple
    ) -> (frontImageView: UIImageView, middleImageView: UIImageView, backImageView: UIImageView) {
        // Iterate back→front so addSubview Z-order matches what we want visually.
        let imageViews = [back, middle, front].map { image -> UIImageView in
            let imageView = UIImageView()
            imageView.withStyle(.background(image: image))
            addSubview(imageView)
            imageView.edgesToSuperview(insets:
                UIEdgeInsets(
                    top: verticalInsetForImageViews,
                    left: horizontalInsetForImageViews,
                    bottom: verticalInsetForImageViews,
                    right: horizontalInsetForImageViews
                )
            )
            return imageView
        }

        addMotionEffectTo(
            views: (imageViews[0], imageViews[1], imageViews[2]),
            strengths: (frontStrength, middleStrength, backStrength)
        )
        // Reverse so the returned tuple's order matches the (front, middle, back) labels.
        return (imageViews[2], imageViews[1], imageViews[0])
    }

    // swiftlint:disable large_tuple
    /// Tuple-positional convenience that zips three views with three strengths
    /// and forwards to `addMotionEffectTo(viewsAndEffectStrength:)`.
    /// Alternative strength presets retained for tuning experiments:
    ///   `[4, 15, 40]`
    ///   `(8, 30, 50)`
    func addMotionEffectTo(
        views: (back: UIView, middle: UIView, front: UIView),
        strengths: (back: CGFloat, middle: CGFloat, front: CGFloat)
    ) { // swiftlint:enable large_tuple
        let views = [views.back, views.middle, views.front]
        let strengths = [strengths.back, strengths.middle, strengths.front]
        let viewsAndEffectStrength = zip(views, strengths).map { ($0.0, $0.1) }

        addMotionEffectTo(viewsAndEffectStrength: viewsAndEffectStrength)
    }

    /// Loop-based application of a 2-axis tilt to each (view, strength) pair —
    /// the bottom-most worker that everything else here funnels into.
    func addMotionEffectTo(viewsAndEffectStrength: [(UIView, CGFloat)]) {
        for item in viewsAndEffectStrength {
            let (view, strength) = item
            view.addMotionEffect(strength: CGFloat(strength))
        }
    }
}
