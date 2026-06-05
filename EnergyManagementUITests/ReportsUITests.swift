import XCTest

final class ReportsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testReadyReportsShowDailyAndSevenDayTrend() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startReports"]
        app.launch()

        XCTAssertTrue(app.staticTexts["今日睡眠报告"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["8 小时 6 分钟"].exists)
        XCTAssertTrue(app.staticTexts["昨晚睡觉"].exists)
        XCTAssertTrue(app.staticTexts["今早起床"].exists)
        XCTAssertTrue(app.staticTexts["七日节律"].exists)
        XCTAssertTrue(app.staticTexts["这是基于日程与手动确认的节律趋势，不代表医学睡眠时长。"].exists)
    }

    func testMissedReportKeepsEstimatedLanguage() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startReportsMissed"]
        app.launch()

        XCTAssertTrue(app.staticTexts["今日睡眠报告"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["待完整"].exists)
        XCTAssertTrue(app.staticTexts["缺少睡觉或起床确认，今天的报告会保持克制，不伪造完整数据。"].exists)
    }

    func testEmptyReportsShowPolishedEmptyState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-completeInitialSetup", "-startReportsEmpty"]
        app.launch()

        XCTAssertTrue(app.staticTexts["还没有报告"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["完成一次睡前或起床确认后，这里会显示基于日程的估计报告。"].exists)
    }
}
