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

import Combine
import Foundation
import NanoViewControllerController
import NanoViewControllerCore

// MARK: - User action and navigation steps

/// Outcomes the privacy-gate screen surfaces to its parent coordinator.
public enum EnsureThatYouAreNotBeingWatchedUserAction: Sendable {
    /// User tapped "I understand" — proceed to wallet creation.
    case understand
    /// User tapped the cancel "X" — abort and return to chooser.
    case cancel
}

// MARK: - EnsureThatYouAreNotBeingWatchedViewModel

/// Wires the cancel bar-button and the understand CTA to navigation steps.
/// No `Output` — the screen is entirely static.
public final class EnsureThatYouAreNotBeingWatchedViewModel: BaseViewModel<
    EnsureThatYouAreNotBeingWatchedUserAction,
    EnsureThatYouAreNotBeingWatchedViewModel.InputFromView,
    EnsureThatYouAreNotBeingWatchedViewModel.Output
> {
    /// Wires both inputs (cancel bar-button + understand CTA) directly to navigator steps.
    override public func transform(input: Input) -> Output {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        // MARK: Navigate

        [
            input.fromController.leftBarButtonTrigger
                .sink { userDid(.cancel) },

            input.fromView.understandTrigger
                .sink { userDid(.understand) },
        ].forEach { $0.store(in: &cancellables) }

        return Output()
    }
}

public extension EnsureThatYouAreNotBeingWatchedViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires when the user taps "I understand".
        let understandTrigger: AnyPublisher<Void, Never>
    }

    /// No outputs — entirely static screen.
    struct Output {}
}
