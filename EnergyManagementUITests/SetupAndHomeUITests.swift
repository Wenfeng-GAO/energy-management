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
        XCTAssertTrue(app.staticTexts["设置你的睡眠节律"].waitForExistence(timeout: 5))

        app.buttons["保存并进入首页"].tap()

        XCTAssertTrue(app.staticTexts["今日睡眠"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["homeBedtimeValue"].label, "23:30")
        XCTAssertEqual(app.staticTexts["homeWakeValue"].label, "07:30")
        XCTAssertTrue(app.buttons["修改作息"].exists)
    }
}
