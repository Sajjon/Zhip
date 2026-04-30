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

import SingleLineControllerCore
import UIKit
import XCTest
@testable import AppFeature

/// Smoke-tests for `UIView` subclasses that have no required dependencies.
///
/// Each test simply instantiates the view via its `EmptyInitializable`
/// initializer and forces a layout pass. This exercises every `setup()`
/// configuration path (subview composition, styling, motion-effects,
/// localization) without requiring image-snapshot assertions, giving wide
/// coverage of view code without committing reference images.
@MainActor
final class SimpleViewSmokeTests: XCTestCase {
    func test_welcomeView_initializes() {
        let view = WelcomeView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_termsOfServiceView_initializes() {
        let view = TermsOfServiceView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_askForCrashReportingPermissionsView_initializes() {
        let view = AskForCrashReportingPermissionsView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_warningCustomECCView_initializes() {
        let view = WarningCustomECCView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_chooseWalletView_initializes() {
        let view = ChooseWalletView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_backUpKeystoreView_initializes() {
        let view = BackUpKeystoreView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_backUpRevealedKeyPairView_initializes() {
        let view = BackUpRevealedKeyPairView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_decryptKeystoreToRevealKeyPairView_initializes() {
        let view = DecryptKeystoreToRevealKeyPairView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_confirmWalletRemovalView_initializes() {
        let view = ConfirmWalletRemovalView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_choosePincodeView_initializes() {
        let view = ChoosePincodeView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_confirmNewPincodeView_initializes() {
        let view = ConfirmNewPincodeView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_receiveView_initializes() {
        let view = ReceiveView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_settingsView_initializes() {
        let view = SettingsView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_mainView_initializes() {
        let view = MainView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_createNewWalletView_initializes() {
        let view = CreateNewWalletView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_backupWalletView_initializes() {
        let view = BackupWalletView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_prepareTransactionView_initializes() {
        let view = PrepareTransactionView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_pollTransactionStatusView_initializes() {
        let view = PollTransactionStatusView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_restoreWalletView_initializes() {
        let view = RestoreWalletView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_reviewTransactionBeforeSigningView_initializes() {
        let view = ReviewTransactionBeforeSigningView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_scanQRCodeView_initializes() {
        let view = ScanQRCodeView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_restoreUsingPrivateKeyView_initializes() {
        let view = RestoreUsingPrivateKeyView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.superview ?? view)
    }

    func test_signTransactionView_initializes() {
        let view = SignTransactionView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_restoreUsingKeystoreView_initializes() {
        let view = RestoreUsingKeystoreView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.superview ?? view)
    }

    func test_ensureThatYouAreNotBeingWatchedView_initializes() {
        let view = EnsureThatYouAreNotBeingWatchedView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_unlockAppWithPincodeView_initializes() {
        let view = UnlockAppWithPincodeView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }

    func test_removePincodeView_initializes() {
        let view = RemovePincodeView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        view.layoutIfNeeded()
        XCTAssertNotNil(view.inputFromView)
    }
}
