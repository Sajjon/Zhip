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

@testable import AppFeature
import Combine
import Foundation
import SingleLineControllerController

/// Builds a fake `InputFromController` suitable for driving a ViewModel under test.
///
/// Exposes the underlying subjects so tests can `viewDidLoadSubject.send(())` to
/// simulate lifecycle callbacks, then inspect the `leftBarButtonContentSubject` /
/// `titleSubject` / `toastSubject` outputs the ViewModel pushed back.
struct FakeInputFromController {
    /// Emits when the view controller would notify `viewDidLoad`.
    let viewDidLoadSubject = PassthroughSubject<Void, Never>()

    /// Emits when the view controller would notify `viewWillAppear`.
    let viewWillAppearSubject = PassthroughSubject<Void, Never>()

    /// Emits when the view controller would notify `viewDidAppear`.
    let viewDidAppearSubject = PassthroughSubject<Void, Never>()

    /// Emits when the user taps the left navigation bar button.
    let leftBarButtonTriggerSubject = PassthroughSubject<Void, Never>()

    /// Emits when the user taps the right navigation bar button.
    let rightBarButtonTriggerSubject = PassthroughSubject<Void, Never>()

    /// Title pushed by the ViewModel back to the controller.
    let titleSubject = PassthroughSubject<String, Never>()

    /// Left-bar-button content pushed by the ViewModel.
    let leftBarButtonContentSubject = PassthroughSubject<BarButtonContent, Never>()

    /// Right-bar-button content pushed by the ViewModel.
    let rightBarButtonContentSubject = PassthroughSubject<BarButtonContent, Never>()

    /// Toasts pushed by the ViewModel.
    let toastSubject = PassthroughSubject<Toast, Never>()

    /// Builds the `InputFromController` struct that the ViewModel expects.
    func makeInput() -> InputFromController {
        InputFromController(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            viewDidAppear: viewDidAppearSubject.eraseToAnyPublisher(),
            leftBarButtonTrigger: leftBarButtonTriggerSubject.eraseToAnyPublisher(),
            rightBarButtonTrigger: rightBarButtonTriggerSubject.eraseToAnyPublisher(),
            titleSubject: titleSubject,
            leftBarButtonContentSubject: leftBarButtonContentSubject,
            rightBarButtonContentSubject: rightBarButtonContentSubject,
            toastSubject: toastSubject
        )
    }
}
