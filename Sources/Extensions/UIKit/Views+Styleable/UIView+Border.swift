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
import Validation

extension UIView {
    /// Lightweight value type describing a border's appearance.
    /// Stored as `CGColor` because `CALayer.borderColor` only accepts that —
    /// converting eagerly avoids a re-conversion on every `addBorder` call.
    struct Border {
        /// Border colour (already converted to `CGColor` for direct use on `CALayer`).
        let color: CGColor
        /// Border width in points. Default 1.5pt matches the form-input style.
        let width: CGFloat
        /// Designated initialiser — accepts a `UIColor` for ergonomic call sites
        /// and converts internally.
        init(color: UIColor, width: CGFloat = 1.5) {
            self.color = color.cgColor
            self.width = width
        }
    }

    /// Applies a border by writing through to `layer.borderWidth` /
    /// `layer.borderColor`. Pure mutation — no animation.
    func addBorder(_ border: Border) {
        layer.borderWidth = border.width
        layer.borderColor = border.color
    }
}

extension UIView.Border {
    /// Border style used when the field has no validation state to convey
    /// (subtle, low-emphasis colour from `AnyValidation.Color.empty`).
    static var empty: UIView.Border {
        UIView.Border(color: AnyValidation.Color.empty)
    }

    /// Border style for the error state — typically red, `AnyValidation.Color.error`.
    static var error: UIView.Border {
        UIView.Border(color: AnyValidation.Color.error)
    }

    /// Maps an `AnyValidation` value to the appropriate border style — the
    /// single source of truth for "what does this field look like right now?".
    /// Distinguishes `.valid(nil)` (clean valid) from `.valid(remark)` (valid
    /// with helpful note) so the two can carry different colours.
    static func fromValidation(_ validation: AnyValidation) -> UIView.Border {
        switch validation {
        case .empty: return .empty
        case .errorMessage: return .error
        case let .valid(remark):
            let color: UIColor = (remark == nil) ? AnyValidation.Color.validWithoutRemark : AnyValidation.Color
                .validWithRemark
            return UIView.Border(color: color)
        }
    }
}
