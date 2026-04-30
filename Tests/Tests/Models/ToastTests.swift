@testable import AppFeature
import Factory
import SingleLineControllerController
import UIKit
import XCTest

final class ToastTests: XCTestCase {
    func test_initWithDefaults_createsAutoDismissToast() {
        let sut = Toast("hello")
        _ = sut // non-optional, simply verify init doesn't crash
    }

    func test_initWithStringLiteral_createsToast() {
        let sut: Toast = "literal"
        _ = sut
    }

    func test_initWithManualDismissing_createsToast() {
        let sut = Toast("bye", dismissing: .manual(dismissButtonTitle: "OK"))
        _ = sut
    }

    func test_initWithCompletion_createsToast() {
        let sut = Toast("done", dismissing: .after(duration: 0.1), completion: {})
        _ = sut
    }

    func test_presentAutoDismissing_presentsAnAlert() {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        let host = UIViewController()
        window.rootViewController = host
        window.makeKeyAndVisible()

        let sut = Toast("auto", dismissing: .after(duration: 0.05))
        sut.present(using: host, clock: Container.shared.clock())

        // Pump the runloop so the queued `present(...)` call inside Toast
        // resolves before we observe `presentedViewController`.
        // `drainRunLoop` actively pumps the runloop in `.default` mode and
        // avoids the bare-`wait(for:)` flake where the GCD main-queue timer
        // is starved on CI.
        drainRunLoop()

        XCTAssertTrue(host.presentedViewController is UIAlertController)

        // Auto-dismiss is scheduled via `Container.shared.clock()`, which
        // tests register as `ImmediateClock` (fires on the next main-queue
        // cycle). The dismiss animation itself is disabled by
        // `SilenceSideEffects`, so a single drain settles everything.
        drainRunLoop(seconds: 0.5)

        window.isHidden = true
    }

    func test_presentManualDismiss_addsDismissAction() throws {
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        let host = UIViewController()
        window.rootViewController = host
        window.makeKeyAndVisible()

        let sut = Toast("manual", dismissing: .manual(dismissButtonTitle: "Close"))
        sut.present(using: host, clock: Container.shared.clock())

        drainRunLoop()

        let alert = try XCTUnwrap(host.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.actions.first?.title, "Close")

        host.dismiss(animated: false)
        drainRunLoop()
        window.isHidden = true
    }
}
