import XCTest

final class EnergyManagementUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchWithoutSavedSettingsShowsFirstRunSetupEntry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetInitialSetup"]
        app.launch()

        XCTAssertTrue(app.staticTexts["建立一个安静、稳定的睡眠节律。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["开始设置"].exists)
    }
}
