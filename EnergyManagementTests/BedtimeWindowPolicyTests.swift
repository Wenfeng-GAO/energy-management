import XCTest
@testable import EnergyManagement

final class BedtimeWindowPolicyTests: XCTestCase {
    // localDay = wake day (June 5). For bedtime 23:00 / wake 07:00,
    // targetBedtimeDate resolves to June 4 at 23:00 (previous day).

    func testConfirmationWithinWindowReturnsWithinWindow() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)

        // Confirm at 22:00 June 4 — 1h before bedtime 23:00, within 2h window
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T22:00:00+08:00"),
            localDay: wakeDay,
            scheduleSnapshot: snapshot
        )

        XCTAssertEqual(decision, .withinWindow)
    }

    func testConfirmationTooEarlyReturnsOutsideWithMinutes() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)

        // Confirm at 20:00 June 4 — 3h before bedtime 23:00, window opens at 21:00
        // 60 minutes before window opens
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T20:00:00+08:00"),
            localDay: wakeDay,
            scheduleSnapshot: snapshot
        )

        XCTAssertEqual(decision, .outsideWindowTooEarly(minutesBeforeWindowOpens: 60))
    }

    func testConfirmationTooLateReturnsOutsideWithMinutes() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)

        // Confirm at 00:30 June 5 — 1.5h after bedtime, window closes at 00:00
        // 30 minutes after window closes
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-05T00:30:00+08:00"),
            localDay: wakeDay,
            scheduleSnapshot: snapshot
        )

        XCTAssertEqual(decision, .outsideWindowTooLate(minutesAfterWindowCloses: 30))
    }

    func testConfirmationExactlyAtWindowOpenBoundary() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)

        // Confirm at exactly 21:00 June 4 — exactly 2h before bedtime 23:00
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-04T21:00:00+08:00"),
            localDay: wakeDay,
            scheduleSnapshot: snapshot
        )

        XCTAssertEqual(decision, .withinWindow)
    }

    func testConfirmationExactlyAtWindowCloseBoundary() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)

        // Confirm at exactly 00:00 June 5 — exactly 1h after bedtime 23:00
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-05T00:00:00+08:00"),
            localDay: wakeDay,
            scheduleSnapshot: snapshot
        )

        XCTAssertEqual(decision, .withinWindow)
    }

    func testPostMidnightBedtimeUsesLocalDayDirectly() {
        let calendar = TestCalendar.make()
        let policy = BedtimeWindowPolicy(calendar: calendar)
        // bedtime=00:30, wake=08:00 — same day, no cross-midnight
        let postMidnightSnapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 0, minute: 30),
            wakeTime: ClockTime(hour: 8, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let localDay = TestCalendar.date("2026-06-05T00:00:00+08:00")

        // Confirm at 00:15 — 15 min before bedtime 00:30, within 2h window
        let decision = policy.decision(
            for: TestCalendar.date("2026-06-05T00:15:00+08:00"),
            localDay: localDay,
            scheduleSnapshot: postMidnightSnapshot
        )

        XCTAssertEqual(decision, .withinWindow)
    }

    // Wake day = June 5 (the day the user wakes up)
    private var wakeDay: Date {
        TestCalendar.date("2026-06-05T00:00:00+08:00")
    }

    private var snapshot: ScheduleSnapshot {
        ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
    }
}
