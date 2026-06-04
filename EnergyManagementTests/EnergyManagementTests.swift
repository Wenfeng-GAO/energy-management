import XCTest
@testable import EnergyManagement

final class EnergyManagementTests: XCTestCase {
    func testDesignTokensExposeInitialWarmVisualSystem() {
        XCTAssertNotNil(ColorTokens.warmWhite)
        XCTAssertNotNil(ColorTokens.warmGray)
        XCTAssertNotNil(TypographyTokens.display)
        XCTAssertEqual(SpacingTokens.screenPadding, 24)
    }
}
