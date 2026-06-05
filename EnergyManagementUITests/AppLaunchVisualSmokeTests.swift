import XCTest

final class AppLaunchVisualSmokeTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsWarmBrandedFirstFrame() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetInitialSetup"]
        app.launch()

        XCTAssertTrue(app.staticTexts["建立一个安静、稳定的睡眠节律。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["好的睡眠节律，会让身体更容易恢复，也让第二天醒来时多一点清醒和掌控感。"].exists)
        XCTAssertGreaterThanOrEqual(app.buttons["开始设置"].frame.height, 44)
    }
}
