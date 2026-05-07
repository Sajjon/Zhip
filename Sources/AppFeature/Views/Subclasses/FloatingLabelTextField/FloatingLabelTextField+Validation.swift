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
import Validation

extension FloatingLabelTextField {
    /// File-local alias for `AnyValidation.Color` to keep the body readable.
    typealias Color = AnyValidation.Color

    /// Public entry point — apply a validation result to the whole field
    /// (line/placeholder/title colours, error message text, status circle).
    /// Named `applyValidation` (not `validate`) to avoid colliding with
    /// `UIResponder.validate(_ command: UICommand)` which the compiler now
    /// picks up since `AnyValidation` lives in a separate module.
    func applyValidation(_ validation: AnyValidation) {
        updateColorsWithValidation(validation)
        updateErrorMessageWithValidation(validation)
    }

    /// Drives the field's error-message label.
    /// - `.errorMessage`: show the message in red.
    /// - `.valid(remark)`: show the remark (if any) in the "valid + remark"
    ///   colour — re-using the error-message slot lets us surface helpful hints
    ///   ("strong password!") without inventing a separate label.
    /// - `.valid(nil)` / `.empty`: clear the message.
    func updateErrorMessageWithValidation(_ validation: AnyValidation) {
        lineErrorColor = Color.error
        errorColor = Color.error
        switch validation {
        case let .errorMessage(errorMessage): self.errorMessage = errorMessage
        case let .valid(remark):
            if let remark {
                errorMessage = remark
                lineErrorColor = Color.validWithRemark
                errorColor = Color.validWithRemark
            } else {
                errorMessage = nil
            }
        case .empty: errorMessage = nil
        }
    }

    /// Updates every colour-bearing element (underline, placeholder, title,
    /// status circle) to match `validation`. The underline error colour is
    /// driven by the superclass via `lineErrorColor`; we only override the
    /// success/empty colours here.
    func updateColorsWithValidation(_ validation: AnyValidation) {
        updateLineColorWithValidation(validation)
        updatePlaceholderColorWithValidation(validation)
        updateSelectedTitleColorWithValidation(validation)

        let color = colorFromValidation(validation)
        validationCircleView.backgroundColor = color
    }

    /// Sets the field's selected-state underline colour. Errors fall through
    /// to the default `Color.empty`; the superclass handles error-state
    /// colouring via its own `lineErrorColor` property.
    func updateLineColorWithValidation(_ validation: AnyValidation) {
        let color: UIColor = switch validation {
        case let .valid(remark): (remark == nil) ? Color.validWithoutRemark : Color.validWithRemark
        default:
            // color of line in case of error is handled by the property `lineErrorColor` in the superclass
            Color.empty
        }
        selectedLineColor = color
    }

    /// Sets the placeholder colour. Same logic as the line colour above —
    /// errors go through the superclass.
    func updatePlaceholderColorWithValidation(_ validation: AnyValidation) {
        let color: UIColor = switch validation {
        case let .valid(remark): (remark == nil) ? Color.validWithoutRemark : Color.validWithRemark
        default:
            // color of line in case of error is handled by the property `lineErrorColor` in the superclass
            Color.empty
        }
        placeholderColor = color
    }

    /// Sets the selected-state title colour. Same logic as the line colour above.
    func updateSelectedTitleColorWithValidation(_ validation: AnyValidation) {
        let color: UIColor = switch validation {
        case let .valid(remark): (remark == nil) ? Color.validWithoutRemark : Color.validWithRemark
        default:
            // color of line in case of error is handled by the property `lineErrorColor` in the superclass
            Color.empty
        }
        selectedTitleColor = color
    }

    /// Plain validation → colour mapping. Used for the status circle, where
    /// every state needs an explicit colour (no superclass fallback).
    func colorFromValidation(_ validation: AnyValidation) -> UIColor {
        switch validation {
        case .empty: Color.empty
        case .errorMessage: Color.error
        case let .valid(remark): (remark == nil) ? Color.validWithoutRemark : Color.validWithRemark
        }
    }
}
