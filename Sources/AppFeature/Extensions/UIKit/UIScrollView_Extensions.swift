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

extension UIScrollView {
    /// `true` when the user has scrolled "near the bottom" of the content,
    /// where "near" is within `precision` points (default 50).
    ///
    /// The three guards encode three distinct exclusions:
    ///   1. `yOffset > 0` — they haven't started scrolling at all.
    ///   2. `contentSize.height > precision` — content is shorter than the precision
    ///      window (e.g. an empty list); concept of "near bottom" doesn't apply.
    ///   3. The remaining distance below the visible viewport is < `precision`.
    ///
    /// Used by infinite-scroll / paginated table views to decide when to
    /// pre-fetch the next page.
    func isContentOffsetNearBottom(precision: CGFloat = 50) -> Bool {
        let yOffset = contentOffset.y
        guard
            yOffset > 0,
            contentSize.height > precision,
            contentSize.height - (yOffset + frame.height) < precision
        else { return false }
        return true
    }
}
