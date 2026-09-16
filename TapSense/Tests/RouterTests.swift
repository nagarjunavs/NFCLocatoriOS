import XCTest
@testable import TapSense

@MainActor
final class RouterTests: XCTestCase {
    func testFinishSplashGoesToHomeWhenOnboarded() {
        let router = Router()
        router.push(.tapGuide)

        router.finishSplash(onboardingCompleted: true)

        XCTAssertEqual(router.root, .home)
        XCTAssertTrue(router.path.isEmpty)
    }

    func testFinishSplashGoesToOnboardingWhenNotOnboarded() {
        let router = Router()

        router.finishSplash(onboardingCompleted: false)

        XCTAssertEqual(router.root, .onboarding)
        XCTAssertTrue(router.path.isEmpty)
    }

    func testPushAppendsToPath() {
        let router = Router()
        router.finishSplash(onboardingCompleted: true)

        router.push(.phoneSelection)
        router.push(.phoneConfirmed)

        XCTAssertEqual(router.path, [.phoneSelection, .phoneConfirmed])
        XCTAssertEqual(router.current, .phoneConfirmed)
    }

    func testPopRemovesLastPathEntry() {
        let router = Router()
        router.finishSplash(onboardingCompleted: true)
        router.push(.troubleshoot)
        router.push(.education)

        router.pop()

        XCTAssertEqual(router.path, [.troubleshoot])
    }

    func testPopOnEmptyPathIsANoOp() {
        let router = Router()
        router.finishSplash(onboardingCompleted: true)

        router.pop()

        XCTAssertTrue(router.path.isEmpty)
        XCTAssertEqual(router.root, .home)
    }

    /// `navigate(Y) { popUpTo(X){inclusive=true} }` where X is the current top of stack —
    /// replaces it rather than pushing on top.
    func testReplaceTopReplacesLastPathEntry() {
        let router = Router()
        router.finishSplash(onboardingCompleted: true)
        router.push(.phoneSelection)

        router.replaceTop(with: .phoneConfirmed)

        XCTAssertEqual(router.path, [.phoneConfirmed])
    }

    func testReplaceTopWithEmptyPathReplacesRoot() {
        let router = Router()
        router.finishSplash(onboardingCompleted: false)

        router.replaceTop(with: .home)

        XCTAssertEqual(router.root, .home)
        XCTAssertTrue(router.path.isEmpty)
    }

    /// A bottom-tab switch clears every pushed screen and shows the tab's root fresh.
    func testNavigateTopLevelClearsPath() {
        let router = Router()
        router.finishSplash(onboardingCompleted: true)
        router.push(.tapGuide)
        router.push(.tapTest)

        router.navigateTopLevel(.settings)

        XCTAssertEqual(router.root, .settings)
        XCTAssertTrue(router.path.isEmpty)
        XCTAssertEqual(router.current, .settings)
    }

    func testCurrentReflectsRootWhenPathEmpty() {
        let router = Router()
        router.finishSplash(onboardingCompleted: true)

        XCTAssertEqual(router.current, .home)
    }

    func testBottomBarRoutesContainsOnlyHomeMyPhoneSettings() {
        XCTAssertEqual(Route.bottomBarRoutes, [.home, .myPhone, .settings])
    }
}
