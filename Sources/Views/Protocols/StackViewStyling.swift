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
import SingleLineControllerController

/// Refines `ContentViewProvider` so a view can declare its layout as a
/// `UIStackView.Style` and get the boilerplate `makeContentView()` for free.
///
/// Conformers only need `stackViewStyle` — the default extension below builds
/// the actual stack view. This is the entry point used by every scene view
/// (`CreateNewWalletView`, `SettingsView`, …) that lays out vertically/horizontally.
protocol StackViewStyling: ContentViewProvider {
    /// Layout description (subviews + axis/alignment/spacing/margins).
    /// See `UIStackView+Styling.swift` for the structure.
    var stackViewStyle: UIStackView.Style { get }
}

extension ContentViewProvider where Self: StackViewStyling {
    /// Default — builds the stack view from the conformer's `stackViewStyle`.
    /// Note: `withStyle(_:)` here mirrors the call shape on the existing
    /// stack view rather than the constructor used in the Extensions-side
    /// extension; both produce equivalent output.
    func makeContentView() -> UIView {
        UIStackView(frame: .zero).withStyle(stackViewStyle)
    }
}
