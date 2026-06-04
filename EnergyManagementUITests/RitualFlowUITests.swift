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
        XCTAssertTrue(app.staticTexts["把手机放远一点，保留一盏柔和的灯。"].exists)

        app.buttons["记录睡前仪式"].tap()

        XCTAssertTrue(app.staticTexts["已记录睡前仪式。这里不是测量入睡时间，只是保留今晚的节律信号。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["回到今日节律"].exists)
    }

    func testWakeConfirmationShowsWakePrompts() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startWakeConfirmation"]
        app.launch()

        XCTAssertTrue(app.staticTexts["确认已经起床"].waitForExistence(timeout: 5))

        app.buttons["我已经起床"].tap()

        XCTAssertTrue(app.staticTexts["早安"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["先喝几口水。"].exists)
        XCTAssertTrue(app.staticTexts["把窗帘拉开，让房间变亮。"].exists)
    }

    func testMissedWakeConfirmationShowsEstimatedStateLanguage() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startMissedWake"]
        app.launch()

        XCTAssertTrue(app.staticTexts["错过起床确认"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["今天已经过了确认窗口。报告会以未确认或估计状态呈现。"].exists)
        XCTAssertFalse(app.buttons["我已经起床"].exists)
    }
}
