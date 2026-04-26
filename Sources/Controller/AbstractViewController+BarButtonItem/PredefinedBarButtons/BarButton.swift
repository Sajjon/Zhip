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

import Foundation

/// The predefined library of navigation-bar buttons used across the app.
///
/// Restricting screens to this small set keeps the navigation chrome consistent
/// and means localised copy / system styling lives in exactly one place.
enum BarButton {
    /// Localised "Skip" text button — used in optional onboarding steps.
    case skip
    /// System Cancel button — abandons the current modal flow.
    case cancel
    /// System Done button — confirms the current modal flow.
    case done
}

// MARK: BarButtonContent

extension BarButton {
    /// Materialises this case into a concrete `BarButtonContent`.
    /// Cancel/Done use the iOS *system* items so we automatically get the right
    /// glyph/style/a11y label per locale; Skip is text-only with localised copy.
    var content: BarButtonContent {
        switch self {
        case .skip: BarButtonContent(title: String(localized: .Generic.skip))
        case .cancel: BarButtonContent(system: .cancel)
        case .done: BarButtonContent(system: .done)
        }
    }
}
