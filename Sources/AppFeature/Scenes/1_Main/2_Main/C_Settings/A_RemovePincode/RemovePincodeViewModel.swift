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
import SingleLineControllerCore
import Validation

// MARK: - RemovePincodeUserAction

/// Outcomes of the pincode-removal modal.
public enum RemovePincodeUserAction {
    /// User tapped Cancel — close without removing.
    case cancelPincodeRemoval
    /// Entered pincode matched — pincode deleted, modal closes.
    case removePincode
}

// MARK: - RemovePincodeViewModel

/// View model for the pincode-removal modal. Mirrors the unlock-screen pattern:
/// auto-fires removal as soon as the entered pincode matches the saved one.
public final class RemovePincodeViewModel: BaseViewModel<
    RemovePincodeUserAction,
    RemovePincodeViewModel.InputFromView,
    RemovePincodeViewModel.Output
> {
    /// Used to read the current pincode for comparison + delete on success.
    private let useCase: PincodeUseCase
    /// The persisted pincode the user must match.
    private let pincode: Pincode

    /// Captures the use case and stashes the current pincode for comparison.
    /// Crashes if missing — would mean the modal was shown without a pincode set.
    init(useCase: PincodeUseCase) {
        self.useCase = useCase
        guard let pincode = useCase.pincode else {
            incorrectImplementation("Should have pincode set")
        }
        self.pincode = pincode
    }

    /// Wires real-time pincode comparison; on first match, deletes the pincode
    /// and emits `.removePincode`. Cancel bar-button emits `.cancelPincodeRemoval`.
    override public func transform(input: Input) -> RemovePincodeViewModel.Output {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        let validator = InputValidator(existingPincode: pincode)

        let pincodeValidationValue: AnyPublisher<PincodeValidator.ValidationResult, Never> = input.fromView.pincode
            .map {
                validator.validate(unconfirmedPincode: $0)
            }.eraseToAnyPublisher()

        [
            input.fromController.leftBarButtonTrigger
                .sink { userDid(.cancelPincodeRemoval) },

            // First valid match wires straight to delete-then-emit.
            pincodeValidationValue.filter(\.isValid)
                .mapToVoid()
                .sink { [weak useCase] in
                    useCase?.deletePincode()
                    userDid(.removePincode)
                },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            inputBecomeFirstResponder: input.fromController.viewDidAppear,
            pincodeValidation: pincodeValidationValue.map(\.validation).eraseToAnyPublisher()
        )
    }
}

public extension RemovePincodeViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Latest pincode value (`nil` while incomplete).
        let pincode: AnyPublisher<Pincode?, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Pulses on viewDidAppear to put the input in focus.
        let inputBecomeFirstResponder: AnyPublisher<Void, Never>
        /// Drives the input's validation styling.
        let pincodeValidation: AnyPublisher<AnyValidation, Never>
    }

    /// Adapts `PincodeValidator(settingNew: false)` to the modal — captures the
    /// saved pincode and delegates each validation to the shared validator.
    internal struct InputValidator {
        private let existingPincode: Pincode
        private let pincodeValidator = PincodeValidator(settingNew: false)

        /// Captures the saved pincode the user must match.
        init(existingPincode: Pincode) {
            self.existingPincode = existingPincode
        }

        /// Compares `unconfirmedPincode` against the saved one.
        func validate(unconfirmedPincode: Pincode?) -> PincodeValidator.ValidationResult {
            pincodeValidator.validate(input: (unconfirmedPincode, existingPincode))
        }
    }
}
