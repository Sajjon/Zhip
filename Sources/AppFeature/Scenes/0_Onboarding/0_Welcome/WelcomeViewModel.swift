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

/// The single navigation step the welcome scene can emit.
public enum WelcomeUserAction: Sendable {
    /// The user tapped "Get Started", signalling intent to begin onboarding.
    case /* user intends to */ start
}

/// ViewModel for the first screen the user sees on a fresh install.
///
/// The scene has a single job: forward the `startTrigger` to the onboarding
/// coordinator as `.start`.
public final class WelcomeViewModel: BaseViewModel<
    WelcomeUserAction,
    WelcomeViewModel.InputFromView,
    WelcomeViewModel.Publishers
> {
    /// Wires `startTrigger` → `navigator.next(.start)`. Returns an empty `Publishers`
    /// because the welcome scene has no ViewModel-driven UI state.
    override public func transform(input: Input) -> Output<Publishers, NavigationStep> {
        func userIntends(to userAction: NavigationStep) {
            navigator.next(userAction)
        }

        // MARK: Navigate

        [
            input.fromView.startTrigger
                .sink { userIntends(to: .start) },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            publishers: Publishers(),
            navigation: navigator.navigation
        )
    }
}

public extension WelcomeViewModel {
    /// User-event publishers the ViewModel consumes.
    struct InputFromView {
        /// Fires when the user taps the "Get Started" button.
        let startTrigger: AnyPublisher<Void, Never>
    }

    /// No outputs — the scene is entirely static until the user taps Start.
    struct Publishers {}
}
