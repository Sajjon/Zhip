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

// MARK: - Coloring

extension AnyValidation {
    /// Color tokens used by `FloatingLabelTextField.validationBinder` to tint
    /// the floating-label text + underline based on the validation state.
    enum Color {
        /// Plain "valid" — calm brand teal.
        static let validWithoutRemark: UIColor = .teal
        /// Valid but worth flagging (e.g. weak-but-acceptable password) — mellow yellow.
        static let validWithRemark: UIColor = .mellowYellow
        /// Error — alert red.
        static let error: UIColor = .bloodRed
        /// Empty / untouched — neutral grey.
        static let empty: UIColor = .silverGrey
    }
}
