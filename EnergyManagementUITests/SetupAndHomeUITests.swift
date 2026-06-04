import XCTest

final class SetupAndHomeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSetupSavesScheduleAndRoutesToHome() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetInitialSetup"]
        app.launch()

        app.buttons["开始设置"].tap()
        XCTAssertTrue(app.staticTexts["设置作息"].waitForExistence(timeout: 5))

        app.buttons["保存作息"].tap()

        XCTAssertTrue(app.staticTexts["今日节律"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["睡前 23:00 · 起床 07:00 · 准备 30 分钟"].exists)
    }
}
