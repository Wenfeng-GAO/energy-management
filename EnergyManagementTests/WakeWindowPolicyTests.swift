import XCTest
@testable import EnergyManagement

final class WakeWindowPolicyTests: XCTestCase {
    func testConfirmationTwentyMinutesBeforeTargetIsAcceptedAsNaturalEarlyWaking() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)
        let policy = WakeWindowPolicy(calendar: calendar)

        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T06:40:00+08:00"),
            record: record
        )

        XCTAssertEqual(decision, .acceptedEarly(minutesBeforeTarget: 20))
        XCTAssertTrue(policy.contains(TestCalendar.date("2026-06-04T06:40:00+08:00"), record: record))
    }

    func testConfirmationSeventyMinutesAfterTargetIsRejectedAsTooLate() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)
        let policy = WakeWindowPolicy(calendar: calendar)

        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T08:10:00+08:00"),
            record: record
        )

        XCTAssertEqual(decision, .rejectedTooLate(minutesAfterTarget: 70))
        XCTAssertFalse(policy.contains(TestCalendar.date("2026-06-04T08:10:00+08:00"), record: record))
    }
}
