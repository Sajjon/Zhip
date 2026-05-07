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

@testable import AppFeature
import Foundation

/// Hand-written mock of `OnboardingUseCase` for ViewModel tests.
///
/// Every stored property is mutable so tests can seed initial state, and each method
/// updates a corresponding `…Called` flag / count so tests can verify the ViewModel
/// interacted with the use case.
final class MockOnboardingUseCase: OnboardingUseCase {
    // MARK: - TermsOfService

    /// Value returned from `hasAcceptedTermsOfService`. Mutable so tests can seed.
    var hasAcceptedTermsOfService: Bool = false

    /// Number of times `didAcceptTermsOfService()` was invoked.
    private(set) var didAcceptTermsOfServiceCallCount = 0

    func didAcceptTermsOfService() {
        didAcceptTermsOfServiceCallCount += 1
    }

    // MARK: - Pincode prompt

    /// Value returned from `shouldPromptUserToChosePincode`. Mutable so tests can seed.
    var shouldPromptUserToChosePincode: Bool = false
}
