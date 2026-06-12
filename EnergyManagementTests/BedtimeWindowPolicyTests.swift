import XCTest
@testable import EnergyManagement

final class BedtimeWindowPolicyTests: XCTestCase {
    func testConfirmationWithinWindowReturnsWithinWindow() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")

        // Confirm at 22:00 — 1h before bedtime 23:00, within 2h window
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T22:00:00+08:00"),
            localDay: localDay,
            scheduleSnapshot: snapshot
        )

        XCTAssertEqual(decision, .withinWindow)
    }

    func testConfirmationTooEarlyReturnsOutsideWithMinutes() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")

        // Confirm at 20:00 — 3h before bedtime 23:00, window opens at 21:00
        // minutesFromTarget = -180, opensMinutesBefore = 120
        // -180 < -120 → outsideWindowTooEarly(minutesBeforeWindowOpens: 180 - 120 = 60)
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T20:00:00+08:00"),
            localDay: localDay,
            scheduleSnapshot: snapshot
        )

        XCTAssertEqual(decision, .outsideWindowTooEarly(minutesBeforeWindowOpens: 60))
    }

    func testConfirmationTooLateReturnsOutsideWithMinutes() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")

        // Confirm at 00:30+1day — 1.5h after bedtime 23:00, window closes at 00:00
        // minutesFromTarget = 90, closesMinutesAfter = 60
        // 90 > 60 → outsideWindowTooLate(minutesAfterWindowCloses: 90 - 60 = 30)
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-05T00:30:00+08:00"),
            localDay: localDay,
            scheduleSnapshot: snapshot
        )

        XCTAssertEqual(decision, .outsideWindowTooLate(minutesAfterWindowCloses: 30))
    }

    func testConfirmationExactlyAtWindowOpenBoundary() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")

        // Confirm at exactly 21:00 — exactly 2h before bedtime 23:00
        // minutesFromTarget = -120, opensMinutesBefore = 120
        // -120 < -120 is FALSE → falls through to .withinWindow
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T21:00:00+08:00"),
            localDay: localDay,
            scheduleSnapshot: snapshot
        )

        XCTAssertEqual(decision, .withinWindow)
    }

    func testConfirmationExactlyAtWindowCloseBoundary() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")

        // Confirm at exactly 00:00+1day — exactly 1h after bedtime 23:00
        // minutesFromTarget = 60, closesMinutesAfter = 60
        // 60 > 60 is FALSE → falls through to .withinWindow
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-05T00:00:00+08:00"),
            localDay: localDay,
            scheduleSnapshot: snapshot
        )

        XCTAssertEqual(decision, .withinWindow)
    }
}
