import XCTest

final class RitualFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testBedtimeGuidanceAndConfirmation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startBedtimePreparation"]
        app.launch()

        XCTAssertTrue(app.staticTexts["睡前准备"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["降低光线刺激"].exists)

        app.buttons["我睡觉了"].tap()

        XCTAssertTrue(app.staticTexts["可以安心睡了"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["回到首页"].exists)
    }

    func testWakeConfirmationShowsWakePrompts() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startWakeConfirmation"]
        app.launch()

        XCTAssertTrue(app.staticTexts["早安"].waitForExistence(timeout: 5))

        app.buttons["我起床了"].tap()

        XCTAssertTrue(app.staticTexts["开始清醒"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["喝几口水"].exists)
        XCTAssertTrue(app.staticTexts["拉开窗帘，让房间变亮"].exists)
    }

    func testMissedWakeConfirmationShowsEstimatedStateLanguage() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startMissedWake"]
        app.launch()

        XCTAssertTrue(app.staticTexts["错过起床确认"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["今天已经过了确认窗口。报告会以未确认或估计状态呈现。"].exists)
        XCTAssertFalse(app.buttons["我起床了"].exists)
    }
}
