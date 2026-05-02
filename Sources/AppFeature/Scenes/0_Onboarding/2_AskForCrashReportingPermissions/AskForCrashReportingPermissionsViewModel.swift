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

import Combine
import Foundation
import NanoViewControllerCombine
import NanoViewControllerController

// MARK: - AnalyticsPermissionNavigation

/// Outcomes the crash-reporting permission screen surfaces to its parent coordinator.
public enum AskForCrashReportingPermissionsNavigation {
    /// User answered the question (yes or no — recorded in `Preferences`).
    case answerQuestionAboutCrashReporting
    /// User dismissed via the "Done" bar-button (only available in the Settings-modal context).
    case dismiss
}

// MARK: - AnalyticsPermissionViewModel

/// View model for the crash-reporting opt-in screen.
///
/// Like `TermsOfServiceViewModel`, drives two presentation contexts:
/// onboarding (no dismiss button, must answer) vs Settings modal (dismiss button visible).
public final class AskForCrashReportingPermissionsViewModel: BaseViewModel<
    AskForCrashReportingPermissionsNavigation,
    AskForCrashReportingPermissionsViewModel.InputFromView,
    AskForCrashReportingPermissionsViewModel.Output
> {
    /// Records the answer flag in `Preferences`.
    private let useCase: OnboardingUseCase
    /// `true` for the Settings-modal presentation, `false` for onboarding.
    private let isDismissible: Bool

    /// Captures the use case + presentation context.
    init(useCase: OnboardingUseCase, isDismissible: Bool) {
        self.useCase = useCase
        self.isDismissible = isDismissible
    }

    /// Wires:
    /// - Either button tap → record the answer (true=accept, false=decline) +
    ///   emit `.answerQuestionAboutCrashReporting`.
    /// - Both buttons gated on the "I have read" checkbox via `areButtonsEnabled`.
    /// - For the dismissible variant: install a "Done" right bar-button.
    override public func transform(input: Input) -> Output {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        // Collapse both button taps into a single `Bool` stream where
        // `true == accept`, `false == decline`. Avoids forking the persistence path.
        let hasAnsweredAnalyticsPermissionsQuestionTrigger = input.fromView.acceptTrigger.map { true }
            .merge(with: input.fromView.declineTrigger.map { false }).eraseToAnyPublisher()

        if isDismissible {
            // Settings-modal context: install a "Done" right-bar button
            // (the user has already answered earlier, this revisit is informational).
            input.fromController.rightBarButtonContentSubject.onBarButton(.done)
            input.fromController.rightBarButtonTrigger
                .sink { userDid(.dismiss) }.store(in: &cancellables)
        }

        [
            hasAnsweredAnalyticsPermissionsQuestionTrigger.sink { [weak self] in
                guard let self else { return }
                // Persist *first* so re-entering onboarding from a kill picks up the new state.
                useCase.answeredCrashReportingQuestion(acceptsCrashReporting: $0)
                navigator.next(.answerQuestionAboutCrashReporting)
            },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            // Both buttons enable/disable in lockstep with the checkbox.
            areButtonsEnabled: input.fromView.isHaveReadDisclaimerCheckboxChecked
        )
    }
}

public extension AskForCrashReportingPermissionsViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// `true` whenever the "I have read the disclaimer" checkbox is checked.
        let isHaveReadDisclaimerCheckboxChecked: AnyPublisher<Bool, Never>
        /// Fires when the user opts in.
        let acceptTrigger: AnyPublisher<Void, Never>
        /// Fires when the user opts out.
        let declineTrigger: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Drives both buttons' `isEnabledBinder` — they share the same gate.
        let areButtonsEnabled: AnyPublisher<Bool, Never>
    }
}
