import XCTest
@testable import EnergyManagement

final class NotificationPermissionServiceTests: XCTestCase {
    func testDeniedStatusDoesNotAllowSchedulingButKeepsReadableState() {
        let status = NotificationStatus(authorizationState: .denied, message: "通知未开启")

        XCTAssertFalse(status.canScheduleReminders)
        XCTAssertEqual(status.message, "通知未开启")
    }

    func testAuthorizedStatusAllowsScheduling() {
        XCTAssertTrue(NotificationStatus(authorizationState: .authorized).canScheduleReminders)
        XCTAssertTrue(NotificationStatus(authorizationState: .provisional).canScheduleReminders)
        XCTAssertTrue(NotificationStatus(authorizationState: .ephemeral).canScheduleReminders)
    }
}
