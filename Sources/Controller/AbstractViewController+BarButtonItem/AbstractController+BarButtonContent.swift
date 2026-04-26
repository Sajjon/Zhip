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

extension AbstractController {
    /// Installs `barButtonContent` as the navigation item's *right* bar button,
    /// wiring its tap to the controller's `rightBarButtonAbstractTarget` (which in
    /// turn pushes to `rightBarButtonSubject`, exposed to the ViewModel as
    /// `InputFromController.rightBarButtonTrigger`).
    func setRightBarButtonUsing(content barButtonContent: BarButtonContent) {
        let item = barButtonContent.makeBarButtonItem(
            target: rightBarButtonAbstractTarget,
            selector: #selector(AbstractTarget.pressed)
        )
        navigationItem.rightBarButtonItem = item
    }

    /// Mirror of `setRightBarButtonUsing(content:)` for the *left* bar button.
    /// See that method's documentation for the wiring chain.
    func setLeftBarButtonUsing(content barButtonContent: BarButtonContent) {
        let item = barButtonContent.makeBarButtonItem(
            target: leftBarButtonAbstractTarget,
            selector: #selector(AbstractTarget.pressed)
        )
        navigationItem.leftBarButtonItem = item
    }
}
