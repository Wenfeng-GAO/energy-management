import XCTest
@testable import EnergyManagement

final class SleepReportCalculatorTests: XCTestCase {
    func testDailySummaryUsesEstimatedSleepOpportunityAndWakeSignal() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            wakeConfirmedAt: TestCalendar.date("2026-06-04T07:10:00+08:00"),
            calendar: calendar
        )
        record.confirmBedtime(at: TestCalendar.date("2026-06-03T23:02:00+08:00"))

        let summary = SleepReportCalculator(calendar: calendar).dailySummary(for: record)

        XCTAssertEqual(summary.estimatedSleepOpportunityMinutes, 8 * 60)
        XCTAssertEqual(summary.estimatedSleepOpportunityLabel, "预估睡眠机会")
        XCTAssertEqual(summary.scheduleSignalLabel, "日程信号")
        XCTAssertTrue(summary.bedtimeConfirmed)
        XCTAssertEqual(summary.wakeSignal, .slightlyLate(minutesAfterTarget: 10))
    }

    func testMissingWakeConfirmationIsReportedAsMissedOrEstimated() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            calendar: calendar
        )

        let summary = SleepReportCalculator(calendar: calendar).dailySummary(for: record)

        XCTAssertEqual(summary.wakeSignal, .missedOrEstimated)
    }

    func testSevenDayTrendSummarizesRecentRecordsAndConsecutiveSignals() {
        let calendar = TestCalendar.make()
        let records = (0..<7).map { offset in
            let localDay = calendar.date(
                byAdding: .day,
                value: offset,
                to: TestCalendar.date("2026-06-01T00:00:00+08:00")
            )!
            return TestRecords.record(
                localDay: localDay,
                wakeConfirmedAt: calendar.date(bySettingHour: 7, minute: offset == 6 ? 5 : 0, second: 0, of: localDay)!,
                calendar: calendar
            )
        }

        let trend = SleepReportCalculator(calendar: calendar).sevenDayTrend(for: records)

        XCTAssertEqual(trend.state, .ready)
        XCTAssertEqual(trend.dayCount, 7)
        XCTAssertEqual(trend.averageEstimatedSleepOpportunityMinutes, 8 * 60)
        XCTAssertEqual(trend.wakeConfirmationRate, 1, accuracy: 0.001)
        XCTAssertEqual(trend.consecutiveScheduleSignalDays, 7)
        XCTAssertEqual(trend.title, "七日节律")
        XCTAssertTrue(trend.estimateDisclaimer.contains("不代表医学睡眠时长"))
    }

    func testEmptyHistoryReturnsAccumulatingDataState() {
        let trend = SleepReportCalculator(calendar: TestCalendar.make()).sevenDayTrend(for: [])

        XCTAssertEqual(trend.state, .accumulatingData)
        XCTAssertNil(trend.averageEstimatedSleepOpportunityMinutes)
        XCTAssertEqual(trend.wakeConfirmationRate, 0)
    }

    func testScheduleSnapshotPreservesHistoricalReportAfterScheduleChange() {
        let calendar = TestCalendar.make()
        let originalSchedule = SleepSchedule(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let record = SleepRecord(
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            schedule: originalSchedule,
            wakeConfirmedAt: TestCalendar.date("2026-06-04T07:00:00+08:00"),
            calendar: calendar
        )
        originalSchedule.bedtime = ClockTime(hour: 22, minute: 0)
        originalSchedule.wakeTime = ClockTime(hour: 6, minute: 30)

        let summary = SleepReportCalculator(calendar: calendar).dailySummary(for: record)

        XCTAssertEqual(record.scheduleSnapshot.bedtime, ClockTime(hour: 23, minute: 0))
        XCTAssertEqual(record.scheduleSnapshot.wakeTime, ClockTime(hour: 7, minute: 0))
        XCTAssertEqual(summary.estimatedSleepOpportunityMinutes, 8 * 60)
    }

    func testStoredTimeZoneKeepsHistoricalTargetWakeStable() {
        let shanghaiCalendar = TestCalendar.make(timeZoneIdentifier: "Asia/Shanghai")
        let newYorkCalendar = TestCalendar.make(timeZoneIdentifier: "America/New_York")
        let record = TestRecords.record(
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            wakeConfirmedAt: TestCalendar.date("2026-06-04T07:00:00+08:00"),
            calendar: shanghaiCalendar
        )

        let targetInChangedDeviceZone = WakeWindowPolicy(calendar: newYorkCalendar).targetWakeDate(for: record)

        XCTAssertEqual(targetInChangedDeviceZone, TestCalendar.date("2026-06-04T07:00:00+08:00"))
    }

    // MARK: - Category H: Report Calculator Boundaries

    func testSevenDayTrendWithMoreThanSevenRecordsTakesLastSeven() {
        let calendar = TestCalendar.make()
        let records = (0..<10).map { offset in
            let localDay = calendar.date(
                byAdding: .day,
                value: offset,
                to: TestCalendar.date("2026-06-01T00:00:00+08:00")
            )!
            let wakeConfirmedAt: Date? = offset < 3 ? nil : calendar.date(bySettingHour: 7, minute: 5, second: 0, of: localDay)!
            return TestRecords.record(
                localDay: localDay,
                wakeConfirmedAt: wakeConfirmedAt,
                calendar: calendar
            )
        }

        let trend = SleepReportCalculator(calendar: calendar).sevenDayTrend(for: records)

        XCTAssertEqual(trend.state, .ready)
        XCTAssertEqual(trend.dayCount, 7)
        XCTAssertEqual(trend.wakeConfirmationRate, 1.0, accuracy: 0.001)
        XCTAssertEqual(trend.consecutiveScheduleSignalDays, 7)
    }

    func testSevenDayTrendAllRecordsMissedWake() {
        let calendar = TestCalendar.make()
        let records = (0..<7).map { offset in
            let localDay = calendar.date(
                byAdding: .day,
                value: offset,
                to: TestCalendar.date("2026-06-01T00:00:00+08:00")
            )!
            return TestRecords.record(
                localDay: localDay,
                wakeConfirmedAt: nil,
                calendar: calendar
            )
        }

        let trend = SleepReportCalculator(calendar: calendar).sevenDayTrend(for: records)

        XCTAssertEqual(trend.state, .ready)
        XCTAssertEqual(trend.dayCount, 7)
        XCTAssertEqual(trend.wakeConfirmationRate, 0.0, accuracy: 0.001)
        XCTAssertEqual(trend.consecutiveScheduleSignalDays, 0)
    }

    func testConsecutiveStreakBreaksInMiddle() {
        let calendar = TestCalendar.make()
        let records = (0..<7).map { offset in
            let localDay = calendar.date(
                byAdding: .day,
                value: offset,
                to: TestCalendar.date("2026-06-01T00:00:00+08:00")
            )!
            let wakeConfirmedAt: Date? = offset == 4 ? nil : calendar.date(bySettingHour: 7, minute: 5, second: 0, of: localDay)!
            return TestRecords.record(
                localDay: localDay,
                wakeConfirmedAt: wakeConfirmedAt,
                calendar: calendar
            )
        }

        let trend = SleepReportCalculator(calendar: calendar).sevenDayTrend(for: records)

        XCTAssertEqual(trend.state, .ready)
        XCTAssertEqual(trend.consecutiveScheduleSignalDays, 2)
        XCTAssertEqual(trend.wakeConfirmationRate, 6.0 / 7.0, accuracy: 0.001)
    }

    func testSevenDayTrendWithFewerThanSevenRecords() {
        let calendar = TestCalendar.make()
        let records = (0..<3).map { offset in
            let localDay = calendar.date(
                byAdding: .day,
                value: offset,
                to: TestCalendar.date("2026-06-01T00:00:00+08:00")
            )!
            return TestRecords.record(
                localDay: localDay,
                wakeConfirmedAt: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: localDay)!,
                calendar: calendar
            )
        }

        let trend = SleepReportCalculator(calendar: calendar).sevenDayTrend(for: records)

        XCTAssertEqual(trend.state, .accumulatingData)
        XCTAssertEqual(trend.dayCount, 3)
        XCTAssertEqual(trend.wakeConfirmationRate, 1.0, accuracy: 0.001)
        XCTAssertEqual(trend.consecutiveScheduleSignalDays, 3)
        XCTAssertEqual(trend.averageEstimatedSleepOpportunityMinutes, 480)
    }

    func testDailySummaryWithWakeConfirmedOutsideWindowReportsMissed() {
        let calendar = TestCalendar.make()
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        let targetWakePlus70 = TestCalendar.date("2026-06-04T08:10:00+08:00")
        let record = TestRecords.record(
            localDay: localDay,
            wakeConfirmedAt: targetWakePlus70,
            calendar: calendar
        )

        let summary = SleepReportCalculator(calendar: calendar).dailySummary(for: record)

        XCTAssertEqual(summary.wakeSignal, .missedOrEstimated)
    }
}
