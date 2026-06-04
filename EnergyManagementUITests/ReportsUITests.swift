import XCTest

final class ReportsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testReadyReportsShowDailyAndSevenDayTrend() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startReports"]
        app.launch()

        XCTAssertTrue(app.staticTexts["今日报告"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["预估睡眠机会"].exists)
        XCTAssertTrue(app.staticTexts["8 小时"].exists)
        XCTAssertTrue(app.staticTexts["七日日程信号"].exists)
        XCTAssertTrue(app.staticTexts["以下为基于日程与手动确认的估计，不代表实际睡眠时长。"].exists)
    }

    func testMissedReportKeepsEstimatedLanguage() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startReportsMissed"]
        app.launch()

        XCTAssertTrue(app.staticTexts["今日报告"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["起床未确认，按估计处理"].exists)
        XCTAssertTrue(app.staticTexts["今天缺少起床确认。报告会保持估计口径，不把它当成实际睡眠质量。"].exists)
    }

    func testEmptyReportsShowPolishedEmptyState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startReportsEmpty"]
        app.launch()

        XCTAssertTrue(app.staticTexts["还没有报告"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["完成一次睡前或起床确认后，这里会显示基于日程的估计报告。"].exists)
    }
}
