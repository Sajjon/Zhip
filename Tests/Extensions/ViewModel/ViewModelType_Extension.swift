//
// MIT License
//
// Copyright (c) 2018-2019 Open Zesame (https://github.com/OpenZesame)
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

import Combine
import Foundation
import SingleLineControllerCore
@testable import Zhip

extension ViewModelType where Input: InputType, Self.Input.FromController == InputFromController {
    func transform(inputFromView: Input.FromView) -> OutputVM {
        let input = Input(fromView: inputFromView, fromController: .empty)
        return transform(input: input)
    }
}

private extension InputFromController {
    static var empty: InputFromController {
        InputFromController(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            viewWillAppear: Empty().eraseToAnyPublisher(),
            viewDidAppear: Empty().eraseToAnyPublisher(),
            leftBarButtonTrigger: Empty().eraseToAnyPublisher(),
            rightBarButtonTrigger: Empty().eraseToAnyPublisher(),
            titleSubject: PassthroughSubject<String, Never>(),
            leftBarButtonContentSubject: PassthroughSubject<BarButtonContent, Never>(),
            rightBarButtonContentSubject: PassthroughSubject<BarButtonContent, Never>(),
            toastSubject: PassthroughSubject<Toast, Never>()
        )
    }
}
