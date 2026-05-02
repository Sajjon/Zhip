@testable import AppFeature
import SingleLineControllerController
import UIKit
import XCTest

private final class FakeOwner: UIViewController, NavigationBarLayoutOwner {
    var navigationBarLayout: NavigationBarLayout = .hidden
}

@MainActor
final class NavigationBarLayoutingNavigationControllerTests: XCTestCase {
    func test_pushViewController_appliesLayoutFromOwner() {
        let owner = FakeOwner()
        let nav = NavigationBarLayoutingNavigationController()

        nav.pushViewController(owner, animated: false)

        XCTAssertEqual(nav.lastLayout?.visibility, NavigationBarLayout.Visibility.hidden(animated: false))
    }

    func test_present_appliesLayoutFromPresentedOwner() {
        let owner = FakeOwner()
        let nav = NavigationBarLayoutingNavigationController()
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = nav
        window.makeKeyAndVisible()

        nav.present(owner, animated: false, completion: nil)

        XCTAssertNotNil(nav.lastLayout)

        let dismissed = expectation(description: "presented dismissed")
        owner.dismiss(animated: false) { dismissed.fulfill() }
        wait(for: [dismissed], timeout: 1.0)
        window.isHidden = true
    }

    func test_popViewController_appliesLayoutOfTopVCAfterPop() {
        let firstOwner = FakeOwner()
        firstOwner.navigationBarLayout = .opaque
        let secondOwner = FakeOwner()
        secondOwner.navigationBarLayout = .hidden

        let nav = NavigationBarLayoutingNavigationController(rootViewController: firstOwner)
        nav.pushViewController(secondOwner, animated: false)
        XCTAssertNotNil(nav.lastLayout)

        let popped = nav.popViewController(animated: false)

        XCTAssertEqual(popped, secondOwner)
        XCTAssertEqual(nav.lastLayout?.visibility, NavigationBarLayout.Visibility.visible(animated: false))
    }

    func test_popToRootViewController_appliesLayoutOfRoot() {
        let root = FakeOwner()
        root.navigationBarLayout = .opaque
        let middle = FakeOwner()
        let top = FakeOwner()

        let nav = NavigationBarLayoutingNavigationController(rootViewController: root)
        nav.pushViewController(middle, animated: false)
        nav.pushViewController(top, animated: false)

        let popped = nav.popToRootViewController(animated: false)

        XCTAssertEqual(popped?.count, 2)
        XCTAssertEqual(nav.lastLayout?.visibility, NavigationBarLayout.Visibility.visible(animated: false))
    }

    func test_popToViewController_appliesLayoutOfTarget() {
        let root = FakeOwner()
        root.navigationBarLayout = .hidden
        let middle = FakeOwner()
        middle.navigationBarLayout = .opaque
        let top = FakeOwner()

        let nav = NavigationBarLayoutingNavigationController(rootViewController: root)
        nav.pushViewController(middle, animated: false)
        nav.pushViewController(top, animated: false)

        let popped = nav.popToViewController(middle, animated: false)

        XCTAssertEqual(popped, [top])
        XCTAssertNotNil(nav.lastLayout)
    }

    func test_viewWillAppear_setsInteractivePopDelegate() {
        let nav = NavigationBarLayoutingNavigationController(rootViewController: FakeOwner())
        let window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = nav
        window.makeKeyAndVisible()

        nav.beginAppearanceTransition(true, animated: false)
        nav.endAppearanceTransition()

        XCTAssertNotNil(nav.interactivePopGestureRecognizer?.delegate)
        window.isHidden = true
    }

    func test_applyLayout_nonOwner_doesNothing() {
        let nav = NavigationBarLayoutingNavigationController()
        let plainVC = UIViewController()

        nav.applyLayoutToViewController(plainVC)

        XCTAssertNil(nav.lastLayout)
    }

    func test_applyLayout_nilViewController_doesNothing() {
        let nav = NavigationBarLayoutingNavigationController()

        nav.applyLayoutToViewController(nil)

        XCTAssertNil(nav.lastLayout)
    }

    func test_gestureRecognizer_shouldRecognizeSimultaneously_returnsTrue() {
        let nav = NavigationBarLayoutingNavigationController()

        XCTAssertTrue(nav.gestureRecognizer(
            UIGestureRecognizer(),
            shouldRecognizeSimultaneouslyWith: UIGestureRecognizer()
        ))
    }

    func test_gestureRecognizer_shouldRequireFailureOf_returnsTrueForScreenEdge() {
        let nav = NavigationBarLayoutingNavigationController()

        XCTAssertTrue(nav.gestureRecognizer(
            UIGestureRecognizer(),
            shouldRequireFailureOf: UIScreenEdgePanGestureRecognizer()
        ))
    }

    func test_gestureRecognizer_shouldRequireFailureOf_returnsFalseForOtherTypes() {
        let nav = NavigationBarLayoutingNavigationController()

        XCTAssertFalse(nav.gestureRecognizer(UIGestureRecognizer(), shouldRequireFailureOf: UITapGestureRecognizer()))
    }

    // MARK: - UINavigationBar.applyLayout (covers translucent vs opaque branches)

    func test_navigationBar_applyLayout_translucentClear_configuresTransparent() {
        let bar = UINavigationBar()
        let layout = NavigationBarLayout.translucent

        let result = bar.applyLayout(layout)

        XCTAssertTrue(result.isTranslucent)
    }

    func test_navigationBar_applyLayout_opaque_configuresOpaque() {
        let bar = UINavigationBar()

        let result = bar.applyLayout(.opaque)

        XCTAssertFalse(result.isTranslucent)
    }

    // MARK: - Visibility

    func test_visibility_hiddenIsHidden() {
        XCTAssertTrue(NavigationBarLayout.Visibility.hidden(animated: true).isHidden)
    }

    func test_visibility_visibleIsNotHidden() {
        XCTAssertFalse(NavigationBarLayout.Visibility.visible(animated: false).isHidden)
    }

    func test_visibility_animatedFlagsExposed() {
        XCTAssertTrue(NavigationBarLayout.Visibility.hidden(animated: true).animated)
        XCTAssertFalse(NavigationBarLayout.Visibility.visible(animated: false).animated)
    }
}
