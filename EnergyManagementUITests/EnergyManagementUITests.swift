import XCTest

final class EnergyManagementUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchWithoutSavedSettingsShowsFirstRunSetupEntry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetInitialSetup"]
        app.launch()

        XCTAssertTrue(app.staticTexts["睡眠能量"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["开始设置"].exists)
    }
}
