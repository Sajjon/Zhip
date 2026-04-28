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
import SingleLineControllerCombine
import SingleLineControllerController

/// Outcomes of the pincode chooser screen.
enum ChoosePincodeUserAction {
    /// User completed a full pincode and tapped done — coordinator advances to confirm step.
    case chosePincode(Pincode)
    /// User tapped the right-bar "Skip" button.
    case skip
}

/// View model for the pincode chooser. Forwards the entered pincode (or skip)
/// to the parent coordinator and auto-focuses the input on appear.
final class ChoosePincodeViewModel: BaseViewModel<
    ChoosePincodeUserAction,
    ChoosePincodeViewModel.InputFromView,
    ChoosePincodeViewModel.Output
> {
    /// Wires done-tap (with the latest entered pincode) and skip-tap; gates the
    /// done button on pincode-completeness; auto-focuses the input on appear.
    override func transform(input: Input) -> Output {
        func userDid(_ step: NavigationStep) {
            navigator.next(step)
        }

        let pincode = input.fromView.pincode

        [
            // withLatestFrom + filterNil: only trigger when a complete pincode exists.
            input.fromView.doneTrigger.withLatestFrom(pincode.filterNil())
                .sink { userDid(.chosePincode($0)) },

            input.fromController.rightBarButtonTrigger
                .sink { userDid(.skip) },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            // Auto-focus on viewWillAppear so the numeric keyboard is up immediately.
            inputBecomeFirstResponder: input.fromController.viewWillAppear,
            isDoneButtonEnabled: pincode.map { $0 != nil }.eraseToAnyPublisher()
        )
    }
}

extension ChoosePincodeViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Latest pincode value — `nil` while the user hasn't entered all digits yet.
        let pincode: AnyPublisher<Pincode?, Never>
        /// Fires when the user taps the done CTA.
        let doneTrigger: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Pulses on `viewWillAppear` to put the pincode input in focus.
        let inputBecomeFirstResponder: AnyPublisher<Void, Never>
        /// Drives `doneButton.isEnabledBinder` — true once a complete pincode is entered.
        let isDoneButtonEnabled: AnyPublisher<Bool, Never>
    }
}
