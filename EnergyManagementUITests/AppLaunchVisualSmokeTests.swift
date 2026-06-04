import XCTest

final class AppLaunchVisualSmokeTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsWarmBrandedFirstFrame() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetInitialSetup"]
        app.launch()

        XCTAssertTrue(app.staticTexts["睡眠能量"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["先设定睡前、起床和准备时间。所有记录只保存在本机，报告展示的是日程信号和预估睡眠机会。"].exists)
        XCTAssertGreaterThanOrEqual(app.buttons["开始设置"].frame.height, 44)
    }
}
