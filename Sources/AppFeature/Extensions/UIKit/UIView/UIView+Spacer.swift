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

extension UIView {
    /// Returns a transparent, flexible spacer view suitable for `UIStackView`s.
    ///
    /// All four content-priority properties default to `.medium` (~500), which
    /// is the sweet spot:
    ///   * High enough to push back against neighbours and grab leftover space.
    ///   * Low enough that explicit `.required` constraints (or true content
    ///     views with their own intrinsic size) win over the spacer.
    /// Override the vertical priorities when the spacer must specifically
    /// compress or stretch differently from neighbours.
    static func spacer(
        verticalCompressionResistancePriority: UILayoutPriority = .medium,
        verticalContentHuggingPriority: UILayoutPriority = .medium
    ) -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        spacer.setContentCompressionResistancePriority(.medium, for: .horizontal)
        spacer.setContentCompressionResistancePriority(verticalCompressionResistancePriority, for: .vertical)

        spacer.setContentHuggingPriority(.medium, for: .horizontal)
        spacer.setContentHuggingPriority(verticalContentHuggingPriority, for: .vertical)
        spacer.backgroundColor = .clear
        return spacer
    }

    /// Property-style accessor for the default flexible spacer — lets call
    /// sites use `.spacer` (no parens) inside `stackViewStyle` lists for clarity.
    static var spacer: UIView {
        spacer()
    }

    /// Fixed-height spacer — useful for forcing a known gap inside a vertical
    /// stack view rather than relying on inter-spacing.
    static func spacer(height: CGFloat) -> UIView {
        let spacer: UIView = .spacer
        spacer.height(height)
        return spacer
    }
}
