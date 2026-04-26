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

/// Outcome of the set-pincode sub-flow. Both the "user picked + confirmed a
/// pincode" path and the "user explicitly skipped" path collapse to this single
/// step — the coordinator records the skip-flag itself so the parent doesn't
/// have to differentiate.
enum SetPincodeCoordinatorNavigationStep {
    /// Either a pincode was set (and persisted by `ConfirmNewPincodeViewModel`)
    /// or the user skipped (and the skip flag was recorded by `skipPincode()`).
    case setPincode
}

/// Coordinator owning the two-step pincode-setup flow:
/// 1. `ChoosePincode` — user picks a pincode (or skips).
/// 2. `ConfirmNewPincode` — user retypes to confirm; mismatch returns them to step 1.
///
/// Refuses to start if a pincode is already configured — the change-pincode flow
/// goes through Settings → remove wallet, not through this coordinator.
final class SetPincodeCoordinator: BaseCoordinator<SetPincodeCoordinatorNavigationStep> {
    /// Read/write facet for the pincode persistence + skip flag.
    private let useCase: PincodeUseCase

    /// Captures the use case.
    init(navigationController: UINavigationController, useCase: PincodeUseCase) {
        self.useCase = useCase
        super.init(navigationController: navigationController)
    }

    /// Begins at step 1. Crashes if a pincode is already set — that would
    /// indicate the parent flow forgot to gate this coordinator on
    /// `hasConfiguredPincode == false`.
    override func start(didStart _: Completion? = nil) {
        guard !useCase.hasConfiguredPincode else {
            incorrectImplementation(
                "Changing a pincode is not supported, make changes in UI so that user need to remove wallet first, then present user with the option to set a (new) pincode."
            )
        }

        toChoosePincode()
    }
}

// MARK: Private

private extension SetPincodeCoordinator {
    /// Step 1 — push the chooser. `.chosePincode` advances to confirmation,
    /// `.skip` short-circuits to `skipPincode()`.
    func toChoosePincode() {
        let viewModel = ChoosePincodeViewModel()

        push(scene: ChoosePincode.self, viewModel: viewModel) { [unowned self] userDid in
            switch userDid {
            case let .chosePincode(unconfirmedPincode): self.toConfirmPincode(unconfirmedPincode: unconfirmedPincode)
            case .skip: self.skipPincode()
            }
        }
    }

    /// Step 2 — push the confirm screen, parameterized with the unconfirmed
    /// pincode picked in step 1. The confirm view-model handles persistence.
    func toConfirmPincode(unconfirmedPincode: Pincode) {
        let viewModel = ConfirmNewPincodeViewModel(useCase: useCase, confirm: unconfirmedPincode)

        push(scene: ConfirmNewPincode.self, viewModel: viewModel) { [unowned self] userDid in
            switch userDid {
            case .skip: self.skipPincode()
            case .confirmPincode: self.finish()
            }
        }
    }

    /// Records the skip flag and finishes — the user won't be re-prompted on next launch.
    func skipPincode() {
        useCase.skipSettingUpPincode()
        finish()
    }

    /// Bubble `.setPincode` to the parent.
    func finish() {
        navigator.next(.setPincode)
    }
}
