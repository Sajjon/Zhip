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
import SingleLineControllerController

/// Low-level opt-in for a screen that wants a custom left bar button.
///
/// Conformers supply a fully-formed `BarButtonContent` directly. Use this when
/// you need a one-off design that doesn't fit the predefined `BarButton` cases.
/// For the common case prefer `LeftBarButtonMaking`.
protocol LeftBarButtonContentMaking {
    /// The content to install as the left bar button on `viewDidLoad`.
    static var makeLeftContent: BarButtonContent { get }
}

/// High-level opt-in for a screen that wants a left bar button chosen from the
/// app's `BarButton` library (skip / cancel / done).
///
/// Refines `LeftBarButtonContentMaking` and supplies `makeLeftContent` for free
/// by reading `makeLeft.content` — so conformers only need to declare the case.
protocol LeftBarButtonMaking: LeftBarButtonContentMaking {
    /// The predefined `BarButton` case to install as the left button.
    static var makeLeft: BarButton { get }
}

extension LeftBarButtonMaking {
    /// Default bridge: derive the content from the chosen predefined `BarButton`.
    /// Allows any `LeftBarButtonMaking` conformer to satisfy
    /// `LeftBarButtonContentMaking` without writing the bridge themselves.
    static var makeLeftContent: BarButtonContent {
        makeLeft.content
    }
}

extension LeftBarButtonContentMaking {
    /// Convenience used by `SceneController.viewDidLoad()` to install the left
    /// bar button on the supplied controller without exposing the static
    /// indirection at every call site.
    func setLeftBarButton(for viewController: AbstractController) {
        viewController.setLeftBarButtonUsing(content: Self.makeLeftContent)
    }
}
