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

public extension UIView {
    /// Animates a horizontal shake on this view — used to signal validation
    /// failure or "incorrect input" without modal interruption.
    ///
    /// Implementation note: a single damped property animator with two stages —
    /// translate by `translation`, then translate back to zero — gives an
    /// elastic settle that reads as a "no" gesture. `dampingRatio: 0.2` is
    /// deliberately soft so the rebound is visible.
    ///
    /// Original technique: https://stackoverflow.com/a/50080005/1311272
    /// - Parameters:
    ///   - duration: Total animation length (default ≈ 0.42s).
    ///   - translation: How many points to displace horizontally on the first stage.
    ///   - done: Optional completion fired when the animation finishes.
    func shake(duration: TimeInterval = 0.42, withTranslation translation: CGFloat = 10, done: (() -> Void)? = nil) {
        let propertyAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.2) { [weak self] in
            self?.transform = CGAffineTransform(translationX: translation, y: 0)
        }

        propertyAnimator.addAnimations({ [weak self] in
            self?.transform = CGAffineTransform(translationX: 0, y: 0)
        }, delayFactor: CGFloat(duration / 2))

        propertyAnimator.addCompletion { (_: UIViewAnimatingPosition) in
            done?()
        }

        propertyAnimator.startAnimation()
    }
}
