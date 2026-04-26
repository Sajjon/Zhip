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

/// Low-level opt-in for a screen that wants a custom right bar button — supply
/// any `BarButtonContent`. For predefined buttons use `RightBarButtonMaking`.
protocol RightBarButtonContentMaking {
    /// The content to install as the right bar button on `viewDidLoad`.
    static var makeRightContent: BarButtonContent { get }
}

/// High-level opt-in for a screen that wants a right bar button chosen from the
/// app's predefined `BarButton` library. Refines `RightBarButtonContentMaking`
/// and provides `makeRightContent` automatically from `makeRight.content`.
protocol RightBarButtonMaking: RightBarButtonContentMaking {
    /// The predefined `BarButton` case to install as the right button.
    static var makeRight: BarButton { get }
}

extension RightBarButtonMaking {
    /// Default bridge — derive the content from the chosen predefined `BarButton`.
    static var makeRightContent: BarButtonContent {
        makeRight.content
    }
}

extension RightBarButtonContentMaking {
    /// Convenience used by `SceneController.viewDidLoad()` to install the right
    /// bar button on the supplied controller.
    func setRightBarButton(for viewController: AbstractController) {
        viewController.setRightBarButtonUsing(content: Self.makeRightContent)
    }
}

/// Marker protocol — when a `SceneController` conforms, the system back chevron
/// is hidden AND the swipe-back gesture is disabled. Use on flow-terminating
/// screens (e.g. "wallet created" confirmation) where backing up would re-enter
/// an inconsistent state.
protocol BackButtonHiding {}
