import XCTest
@testable import EnergyManagement

final class CrossMidnightAndTimezoneTests: XCTestCase {

    // MARK: - Category A: Cross-Midnight Boundary

    func testBedtimePreparationStateWhenBedtimeCrossesMidnight() {
        // Schedule: bedtime=23:30, wake=07:00, prepLead=45min
        // prepStart = 23:30 - 45min = 22:45
        // now = 22:50, which is between prepStart(22:45) and bedtime(23:30)
        let calendar = TestCalendar.make(timeZoneIdentifier: "Asia/Shanghai")
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        let now = TestCalendar.date("2026-06-04T22:50:00+08:00")
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 30),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 45,
            timeZoneIdentifier: "Asia/Shanghai"
        )

        let viewModel = HomeViewModel.make(
            scheduleSnapshot: snapshot,
            notificationStatus: NotificationStatus(authorizationState: .authorized),
            now: now,
            localDay: localDay,
            record: nil,
            calendar: calendar
        )

        XCTAssertEqual(viewModel.ritualState, .bedtimePreparation)
    }

    func testWakeWindowTargetDateUsesNextDayWhenWakeIsAfterMidnight() {
        // Schedule: bedtime=23:00, wake=07:00
        // localDay=2026-06-04 (the day the record belongs to)
        // targetWakeDate should be 2026-06-04T07:00:00+08:00 (wake on that calendar day)
        //
        // But if localDay is set to the evening before (bedtime day = June 3),
        // then targetWakeDate would be June 3 at 07:00, which is in the PAST.
        let calendar = TestCalendar.make(timeZoneIdentifier: "Asia/Shanghai")
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let policy = WakeWindowPolicy(calendar: calendar)

        // Case 1: localDay is the wake day (June 4) -> targetWake = June 4 at 07:00
        let localDayWakeDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        let targetWake = policy.targetWakeDate(localDay: localDayWakeDay, scheduleSnapshot: snapshot)
        XCTAssertEqual(targetWake, TestCalendar.date("2026-06-04T07:00:00+08:00"))

        // Case 2: localDay is the bedtime day (June 3) -> targetWake = June 3 at 07:00 (past!)
        // This demonstrates the cross-midnight issue when record's localDay is the bedtime day.
        let localDayBedtimeDay = TestCalendar.date("2026-06-03T00:00:00+08:00")
        let targetWakePast = policy.targetWakeDate(localDay: localDayBedtimeDay, scheduleSnapshot: snapshot)
        XCTAssertEqual(targetWakePast, TestCalendar.date("2026-06-03T07:00:00+08:00"))

        // Confirmation at 07:05 on June 4 would be rejected as too late for June 3's target wake
        let confirmationDate = TestCalendar.date("2026-06-04T07:05:00+08:00")
        let decision = policy.decision(
            for: confirmationDate,
            localDay: localDayBedtimeDay,
            scheduleSnapshot: snapshot
        )
        // 07:05 on Jun 4 is 24*60 + 5 = 1445 minutes after Jun 3 at 07:00
        XCTAssertEqual(decision, .rejectedTooLate(minutesAfterTarget: 1445))
    }

    func testEstimatedSleepOpportunityMinutesForCrossMidnightSchedule() {
        // bedtime=23:00 (1380 min), wake=07:00 (420 min)
        // sameDayDifference = 420 - 1380 = -960 (<= 0)
        // result = -960 + 1440 = 480 minutes (8 hours)
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )

        XCTAssertEqual(snapshot.estimatedSleepOpportunityMinutes, 480)
    }

    func testHomeRitualStateWithMidnightBedtimeExactly() {
        // Schedule: bedtime=00:00 (midnight), wake=08:00, prepLead=30min
        // bedtime.date(on: localDay) = 2026-06-04T00:00:00+08:00 (start of June 4)
        // prepStart = bedtime - 30min = 2026-06-03T23:30:00+08:00
        // now = 2026-06-03T23:35:00+08:00, which is between prepStart(23:30) and bedtime(00:00 Jun 4)
        let calendar = TestCalendar.make(timeZoneIdentifier: "Asia/Shanghai")
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        let now = TestCalendar.date("2026-06-03T23:35:00+08:00")
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 0, minute: 0),
            wakeTime: ClockTime(hour: 8, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )

        let viewModel = HomeViewModel.make(
            scheduleSnapshot: snapshot,
            notificationStatus: NotificationStatus(authorizationState: .authorized),
            now: now,
            localDay: localDay,
            record: nil,
            calendar: calendar
        )

        // bedtime at hour 0 -> date(on: localDay) uses bySettingHour:0 on startOfDay(Jun4)
        // which should return 2026-06-04T00:00:00+08:00
        // prepStart = 00:00 - 30min = 2026-06-03T23:30:00+08:00
        // now(23:35) >= prepStart(23:30) && now(23:35) <= bedtime(00:00 Jun 4)
        XCTAssertEqual(viewModel.ritualState, .bedtimePreparation)
    }

    // MARK: - Category F: Timezone Edge Cases

    func testWakeWindowPolicyWithDifferentRecordAndDeviceTimezones() {
        // Record created with timezone Asia/Shanghai, localDay=2026-06-04
        // WakeWindowPolicy initialized with calendar in America/Los_Angeles
        // targetWakeDate should override to Asia/Shanghai timezone from the snapshot
        let laCalendar = TestCalendar.make(timeZoneIdentifier: "America/Los_Angeles")
        let shanghaiCalendar = TestCalendar.make(timeZoneIdentifier: "Asia/Shanghai")
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let record = SleepRecord(
            localDay: localDay,
            scheduleSnapshot: snapshot,
            calendar: shanghaiCalendar
        )

        let policy = WakeWindowPolicy(
            opensMinutesBeforeTarget: 30,
            closesMinutesAfterTarget: 60,
            calendar: laCalendar
        )

        // targetWakeDate overrides to Asia/Shanghai, so target = 2026-06-04T07:00:00+08:00
        let targetWake = policy.targetWakeDate(for: record)
        XCTAssertEqual(targetWake, TestCalendar.date("2026-06-04T07:00:00+08:00"))

        // Confirmation at 07:10 Shanghai time should be acceptedLate(10)
        let confirmationInShanghai = TestCalendar.date("2026-06-04T07:10:00+08:00")
        let decision = policy.decision(for: confirmationInShanghai, record: record)
        XCTAssertEqual(decision, .acceptedLate(minutesAfterTarget: 10))

        // Confirmation at 06:00 Shanghai time (1 hour before target) should be rejectedTooEarly
        let tooEarlyConfirmation = TestCalendar.date("2026-06-04T06:00:00+08:00")
        let earlyDecision = policy.decision(for: tooEarlyConfirmation, record: record)
        XCTAssertEqual(earlyDecision, .rejectedTooEarly(minutesBeforeTarget: 60))
    }

    func testHomeViewModelTimeZoneOverrideFromScheduleSnapshot() {
        // scheduleSnapshot.timeZoneIdentifier = "America/New_York"
        // Calendar initially Asia/Shanghai
        // localDay = 2026-06-04T00:00:00+08:00
        // now = 2026-06-04T10:30:00+08:00 (which is 2026-06-03T22:30:00-04:00 in NY)
        // Schedule: bedtime=23:00, prepLead=45min
        // HomeViewModel.make overrides calendar to NY timezone.
        // bedtime in NY = 23:00 on localDay (interpreted in NY timezone)
        // prepStart = 23:00 - 45min = 22:15 NY time
        // now in NY = 22:30, between prepStart(22:15) and bedtime(23:00)
        let shanghaiCalendar = TestCalendar.make(timeZoneIdentifier: "Asia/Shanghai")
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        let now = TestCalendar.date("2026-06-04T10:30:00+08:00")
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 45,
            timeZoneIdentifier: "America/New_York"
        )

        let viewModel = HomeViewModel.make(
            scheduleSnapshot: snapshot,
            notificationStatus: NotificationStatus(authorizationState: .authorized),
            now: now,
            localDay: localDay,
            record: nil,
            calendar: shanghaiCalendar
        )

        // After timezone override to NY:
        // localDay startOfDay in NY = 2026-06-03T00:00:00-04:00 (June 3 in NY)
        // bedtime = 23:00 on June 3 NY = 2026-06-03T23:00:00-04:00 = 2026-06-04T03:00:00+08:00
        // Wait -- now(10:30+08:00) vs bedtime(03:00+08:00): now > bedtime, so NOT between prepStart and bedtime.
        //
        // Actually let's recalculate. The key is what "localDay" becomes in NY timezone.
        // localDay = 2026-06-04T00:00:00+08:00 = 2026-06-03T12:00:00-04:00 (noon June 3 in NY)
        // startOfDay in NY = 2026-06-03T00:00:00-04:00
        // bedtime = bySettingHour:23 on startOfDay(June 3 NY) = 2026-06-03T23:00:00-04:00
        // prepStart = 2026-06-03T22:15:00-04:00
        // now = 2026-06-04T10:30:00+08:00 = 2026-06-03T22:30:00-04:00
        // 22:15 <= 22:30 <= 23:00 -> bedtimePreparation
        XCTAssertEqual(viewModel.ritualState, .bedtimePreparation)
    }

    func testClockTimeDateOnDayDuringDSTSpringForward() {
        // America/New_York DST spring forward 2026: March 8 at 2:00 AM
        // Clocks jump from 2:00 AM to 3:00 AM, so 2:30 AM does not exist.
        let calendar = TestCalendar.make(timeZoneIdentifier: "America/New_York")
        let localDay = TestCalendar.date("2026-03-08T05:00:00+00:00") // March 8 midnight EST = 05:00 UTC

        let clockTime = ClockTime(hour: 2, minute: 30)
        let result = clockTime.date(on: localDay, calendar: calendar)

        // Calendar.date(bySettingHour:minute:second:of:) for a non-existent time
        // on Apple platforms resolves to the DST transition point (3:00 AM EDT = 07:00 UTC).
        // The implementation uses ?? startOfDay as fallback if nil, but here it returns non-nil.
        XCTAssertNotNil(result)

        // Observed behavior: bySettingHour returns 3:00 AM EDT (the DST jump target),
        // NOT the requested 2:30 AM (which doesn't exist) and NOT 3:30 AM.
        // This means a wake time of 02:30 on spring-forward day silently becomes 03:00.
        let dstTransitionPoint = TestCalendar.date("2026-03-08T07:00:00+00:00") // 3:00 AM EDT
        XCTAssertEqual(
            result, dstTransitionPoint,
            "On DST spring-forward, ClockTime(2:30) resolves to 3:00 AM EDT (the transition point), not the requested time"
        )

        // This is a subtle bug: user's scheduled 2:30 AM wake becomes 3:00 AM on this day,
        // losing 30 minutes of expected wake window lead time.
        let expectedMinutesAfterMidnight = calendar.dateComponents([.hour, .minute], from: result)
        XCTAssertEqual(expectedMinutesAfterMidnight.hour, 3)
        XCTAssertEqual(expectedMinutesAfterMidnight.minute, 0)
    }

    func testRecordLocalDayNormalizationAcrossTimezoneChange() {
        // Create SleepRecord with localDay at 22:00+08:00 on June 4 (Shanghai evening)
        // The init normalizes to startOfDay using the snapshot's timezone (Asia/Shanghai)
        // So normalized localDay = 2026-06-04T00:00:00+08:00
        let shanghaiCalendar = TestCalendar.make(timeZoneIdentifier: "Asia/Shanghai")
        let eveningDate = TestCalendar.date("2026-06-04T22:00:00+08:00")
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )

        let record = SleepRecord(
            localDay: eveningDate,
            scheduleSnapshot: snapshot,
            calendar: shanghaiCalendar
        )

        // Verify normalization: localDay should be start of June 4 in Shanghai
        let expectedLocalDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        XCTAssertEqual(record.localDay, expectedLocalDay)

        // Now query with a different timezone calendar (America/Los_Angeles)
        // 2026-06-04T00:00:00+08:00 = 2026-06-03T09:00:00-07:00 (June 3 in LA)
        let laCalendar = TestCalendar.make(timeZoneIdentifier: "America/Los_Angeles")
        let queryDate = TestCalendar.date("2026-06-04T00:00:00+08:00")

        // isDate(_:inSameDayAs:) with LA calendar:
        // record.localDay in LA timezone = June 3 (09:00 AM LA)
        // queryDate in LA timezone = June 3 (09:00 AM LA)
        // They are in the same LA day (June 3), but this is NOT June 4 which the user intended.
        let isSameDayInLA = laCalendar.isDate(record.localDay, inSameDayAs: queryDate)
        XCTAssertTrue(isSameDayInLA, "Same absolute time matches same LA day")

        // But if we query for June 4 in LA timezone (the day the user THINKS the record is for)
        let june4InLA = TestCalendar.date("2026-06-04T07:00:00+00:00") // June 4 00:00 PDT = 07:00 UTC
        let matchesJune4InLA = laCalendar.isDate(record.localDay, inSameDayAs: june4InLA)
        // record.localDay (Jun 3 09:00 LA) is NOT in the same day as Jun 4 in LA
        XCTAssertFalse(
            matchesJune4InLA,
            "Cross-timezone mismatch: record stored as June 4 Shanghai but appears as June 3 in LA calendar"
        )
    }
}
