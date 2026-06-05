import XCTest

final class AccessibilityUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPrimaryActionsRemainVisibleAndTappable() throws {
        let setupApp = XCUIApplication()
        setupApp.launchArguments = ["-resetInitialSetup"]
        setupApp.launch()

        let startButton = setupApp.buttons["开始设置"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        XCTAssertTrue(startButton.isHittable)
        XCTAssertGreaterThanOrEqual(startButton.frame.height, 44)

        let wakeApp = XCUIApplication()
        wakeApp.launchArguments = ["-completeInitialSetup", "-startWakeConfirmation"]
        wakeApp.launch()

        let wakeButton = wakeApp.buttons["我起床了"]
        XCTAssertTrue(wakeButton.waitForExistence(timeout: 5))
        XCTAssertTrue(wakeButton.isHittable)
        XCTAssertGreaterThanOrEqual(wakeButton.frame.height, 44)

        let reportsApp = XCUIApplication()
        reportsApp.launchArguments = ["-completeInitialSetup", "-startReportsEmpty"]
        reportsApp.launch()

        let reportsButton = reportsApp.buttons["回到首页"]
        XCTAssertTrue(reportsButton.waitForExistence(timeout: 5))
        XCTAssertTrue(reportsButton.isHittable)
        XCTAssertGreaterThanOrEqual(reportsButton.frame.height, 44)
    }
}
