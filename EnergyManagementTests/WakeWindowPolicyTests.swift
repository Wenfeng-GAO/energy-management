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

    // MARK: - Category C: Precise Boundaries

    func testDecisionExactlyAtMinusThirtyMinuteBoundary() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)
        let policy = WakeWindowPolicy(opensMinutesBeforeTarget: 30, closesMinutesAfterTarget: 60, calendar: calendar)

        // Confirmation at exactly 06:30:00 — exactly 30 minutes before target 07:00
        // secondsFromTarget = -1800, minutesFromTarget = Int((-1800/60).rounded()) = -30
        // -30 < -30 is FALSE, so not rejectedTooEarly; falls through to acceptedEarly
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T06:30:00+08:00"),
            record: record
        )

        XCTAssertEqual(decision, .acceptedEarly(minutesBeforeTarget: 30))
        XCTAssertTrue(policy.contains(TestCalendar.date("2026-06-04T06:30:00+08:00"), record: record))
    }

    func testDecisionExactlyAtPlusSixtyMinuteBoundary() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)
        let policy = WakeWindowPolicy(opensMinutesBeforeTarget: 30, closesMinutesAfterTarget: 60, calendar: calendar)

        // Confirmation at exactly 08:00:00 — exactly 60 minutes after target 07:00
        // secondsFromTarget = 3600, minutesFromTarget = Int((3600/60).rounded()) = 60
        // 60 > 60 is FALSE, so not rejectedTooLate; falls through to acceptedLate
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T08:00:00+08:00"),
            record: record
        )

        XCTAssertEqual(decision, .acceptedLate(minutesAfterTarget: 60))
        XCTAssertTrue(policy.contains(TestCalendar.date("2026-06-04T08:00:00+08:00"), record: record))
    }

    func testDecisionRoundingAt30SecondsProducesRoundedMinute() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)
        let policy = WakeWindowPolicy(calendar: calendar)

        // Confirmation at 07:00:30 — 30 seconds after target
        // secondsFromTarget = 30, (30/60).rounded() = (0.5).rounded() = 1.0, minutesFromTarget = 1
        // Returns .acceptedLate(minutesAfterTarget: 1)
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T07:00:30+08:00"),
            record: record
        )

        XCTAssertEqual(decision, .acceptedLate(minutesAfterTarget: 1))
    }

    func testDecisionRoundingAtExactlyOnTarget() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)
        let policy = WakeWindowPolicy(calendar: calendar)

        // Confirmation at exactly 07:00:00 — 0 seconds from target
        // secondsFromTarget = 0, minutesFromTarget = 0
        // Returns .acceptedOnTime
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T07:00:00+08:00"),
            record: record
        )

        XCTAssertEqual(decision, .acceptedOnTime)
        XCTAssertTrue(policy.contains(TestCalendar.date("2026-06-04T07:00:00+08:00"), record: record))
    }

    func testDecisionOneSecondBeforeMinusThirtyBoundary() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)
        let policy = WakeWindowPolicy(calendar: calendar)

        // At 06:29:31 — 1829 seconds before target
        // (-1829/60).rounded() = (-30.483...).rounded() = -30, minutesFromTarget = -30
        // -30 < -30 is FALSE, accepted
        let decisionJustInside = policy.decision(
            for: TestCalendar.date("2026-06-04T06:29:31+08:00"),
            record: record
        )
        XCTAssertEqual(decisionJustInside, .acceptedEarly(minutesBeforeTarget: 30))

        // At 06:29:30 — 1830 seconds before target
        // (-1830/60).rounded() = (-30.5).rounded() = -31, minutesFromTarget = -31
        // -31 < -30 is TRUE, rejected
        let decisionJustOutside = policy.decision(
            for: TestCalendar.date("2026-06-04T06:29:30+08:00"),
            record: record
        )
        XCTAssertEqual(decisionJustOutside, .rejectedTooEarly(minutesBeforeTarget: 31))
    }

    // MARK: - Category E: Extreme Schedule Configurations

    func testVeryShortSleepScheduleEstimatedOpportunity() {
        // Polyphasic: bedtime 02:00, wake 04:00 — same day, 2-hour sleep
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 2, minute: 0),
            wakeTime: ClockTime(hour: 4, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )

        // wakeMinutes(240) - bedtimeMinutes(120) = 120 > 0, returns 120
        XCTAssertEqual(snapshot.estimatedSleepOpportunityMinutes, 120)
    }

    func testSameTimeBedtimeAndWakeGivesFullDaySleepOpportunity() {
        // Degenerate: bedtime and wake both at 07:00
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 7, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 0,
            timeZoneIdentifier: "Asia/Shanghai"
        )

        // wakeMinutes(420) - bedtimeMinutes(420) = 0, NOT > 0, returns 0 + 1440 = 1440
        XCTAssertEqual(snapshot.estimatedSleepOpportunityMinutes, 1440)
    }
}
