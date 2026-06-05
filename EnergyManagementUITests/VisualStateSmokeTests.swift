import XCTest

final class VisualStateSmokeTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testNotificationDeniedBannerIsNonBlocking() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-homeNotificationDenied"]
        app.launch()

        XCTAssertTrue(app.staticTexts["今日睡眠"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["通知未开启，但不会阻止应用内仪式。"].exists)
        XCTAssertTrue(app.buttons["查看报告"].isHittable)
    }

    func testMissedWakeStateLooksComplete() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startMissedWake"]
        app.launch()

        XCTAssertTrue(app.staticTexts["错过起床确认"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["今天已经过了确认窗口。报告会以未确认或估计状态呈现。"].exists)
        XCTAssertTrue(app.buttons["回到首页"].isHittable)
    }

    func testAccumulatingReportStateLooksComplete() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startReportsMissed"]
        app.launch()

        XCTAssertTrue(app.staticTexts["七日节律"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["已积累 3 天，满 7 天后趋势会更稳定。"].exists)
        XCTAssertTrue(app.buttons["回到首页"].exists)
    }

    func testReducedMotionLaunchDoesNotHidePrimaryAction() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetInitialSetup", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL", "-UIReduceMotionEnabled", "YES"]
        app.launch()

        let button = app.buttons["开始设置"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        XCTAssertTrue(button.isHittable)
        XCTAssertGreaterThanOrEqual(button.frame.height, 44)
    }
}
