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

import Foundation
@testable import AppFeature

/// Hand-written mock of `PincodeUseCase` for ViewModel tests.
///
/// Stored properties are mutable so tests can seed initial state. Each write method
/// increments a `…CallCount` so tests can verify the ViewModel drove the use case.
final class MockPincodeUseCase: PincodeUseCase {
    var pincode: Pincode?

    var hasConfiguredPincode: Bool {
        pincode != nil
    }

    private(set) var userChosePincodeCallCount = 0
    private(set) var skipSettingUpPincodeCallCount = 0
    private(set) var deletePincodeCallCount = 0

    init(pincode: Pincode? = nil) {
        self.pincode = pincode
    }

    func userChoose(pincode: Pincode) {
        userChosePincodeCallCount += 1
        self.pincode = pincode
    }

    func skipSettingUpPincode() {
        skipSettingUpPincodeCallCount += 1
    }

    func deletePincode() {
        deletePincodeCallCount += 1
        pincode = nil
    }
}
