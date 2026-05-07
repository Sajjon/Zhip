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
import XCTest

@MainActor
final class BootstrapTests: XCTestCase {
    /// Fresh-install path: `hasRunAppBefore` is unset, so the wipe should
    /// proactively clear any leftover keychain wallet/pincode and stale
    /// preferences (cachedBalance / balanceWasUpdatedAt), then mark
    /// `hasRunAppBefore = true`.
    func test_wipeStaleKeychain_freshInstall_clearsAndMarksFlag() {
        let preferences = TestStoreFactory.makePreferences()
        let securePersistence = TestStoreFactory.makeSecurePersistence()
        // Pre-seed leftovers as if a previous install left state behind.
        let wallet = TestWalletFactory.makeWallet()
        securePersistence.save(wallet: wallet)
        let pincode = try? Pincode(digits: [Digit.zero, .one, .two, .three])
        if let pincode { securePersistence.save(pincode: pincode) }
        preferences.save(value: "100", for: .cachedBalance)
        preferences.save(value: Date(), for: .balanceWasUpdatedAt)

        wipeStaleKeychainOnReinstallIfNeeded(
            preferences: preferences,
            securePersistence: securePersistence
        )

        XCTAssertNil(securePersistence.wallet)
        XCTAssertNil(securePersistence.pincode)
        XCTAssertNil(preferences.loadValue(for: .cachedBalance) as String?)
        XCTAssertNil(preferences.loadValue(for: .balanceWasUpdatedAt) as Date?)
        XCTAssertTrue(preferences.isTrue(.hasRunAppBefore))
    }

    /// Re-launch path: `hasRunAppBefore == true` ⇒ wipe is a no-op so the
    /// existing wallet survives.
    func test_wipeStaleKeychain_alreadyMarked_isNoOp() {
        let preferences = TestStoreFactory.makePreferences()
        let securePersistence = TestStoreFactory.makeSecurePersistence()
        preferences.save(value: true, for: .hasRunAppBefore)
        let wallet = TestWalletFactory.makeWallet()
        securePersistence.save(wallet: wallet)

        wipeStaleKeychainOnReinstallIfNeeded(
            preferences: preferences,
            securePersistence: securePersistence
        )

        XCTAssertNotNil(securePersistence.wallet)
    }

    /// `wipeStaleKeychain` is documented as safe to call multiple times.
    /// The second call should hit the early-return guard.
    func test_wipeStaleKeychain_idempotent_secondCallIsNoOp() {
        let preferences = TestStoreFactory.makePreferences()
        let securePersistence = TestStoreFactory.makeSecurePersistence()

        wipeStaleKeychainOnReinstallIfNeeded(
            preferences: preferences,
            securePersistence: securePersistence
        )
        // Re-seed something after the first call cleared the slate.
        let wallet = TestWalletFactory.makeWallet()
        securePersistence.save(wallet: wallet)

        wipeStaleKeychainOnReinstallIfNeeded(
            preferences: preferences,
            securePersistence: securePersistence
        )

        // Second call hit the guard — wallet survived.
        XCTAssertNotNil(securePersistence.wallet)
    }
}
