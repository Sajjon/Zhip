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

import Factory
import UIKit

/// A lightweight text message the UI surfaces as an auto-dismissing alert,
/// named after the Android equivalent.
///
/// ViewModels `send(Toast(...))` into `InputFromController.toastSubject` to
/// request a display; the `SceneController` presents it on the active view
/// controller.
struct Toast {
    /// Describes how the toast should disappear after presentation.
    enum Dismissing {
        /// Dismiss automatically after `duration` seconds.
        case after(duration: TimeInterval)

        /// Wait for the user to tap the dismiss button with the given title.
        case manual(dismissButtonTitle: String)
    }

    /// The body text shown inside the toast.
    private let message: String

    /// How the toast is torn down once presented.
    private let dismissing: Dismissing

    /// Optional callback invoked when the toast is dismissed.
    private let completion: Completion?

    /// Creates a toast. Default `dismissing` is "auto-dismiss after 0.6 s".
    init(_ message: String, dismissing: Dismissing = .after(duration: 0.6), completion: Completion? = nil) {
        self.message = message
        self.dismissing = dismissing
        self.completion = completion
    }
}

// MARK: ExpressibleByStringLiteral

extension Toast: ExpressibleByStringLiteral {
    init(stringLiteral message: String) {
        self.init(message)
    }
}

// MARK: - Toast + Presentation

extension Toast {
    func present(using navigationController: UIViewController, dismissedCompletion: Completion? = nil) {
        let dismissedCompletion = dismissedCompletion ?? completion
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)

        switch dismissing {
        case let .manual(dismissTitle):
            let dismissAction = UIAlertAction(title: dismissTitle, style: .default) { _ in
                dismissedCompletion?()
            }
            alert.addAction(dismissAction)
        case let .after(duration):
            Container.shared.clock().schedule(after: duration) {
                alert.dismiss(animated: true, completion: dismissedCompletion)
            }
        }

        DispatchQueue.main.async {
            navigationController.present(alert, animated: true, completion: nil)
        }
    }
}
