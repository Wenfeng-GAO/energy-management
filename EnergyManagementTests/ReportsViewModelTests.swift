import XCTest
@testable import EnergyManagement

@MainActor
final class ReportsViewModelTests: XCTestCase {
    func testCompleteWakeConfirmedRecordRendersDailyReportValues() {
        let records = [record(dayOffset: 0, wakeConfirmed: true)]

        let viewModel = ReportsViewModel.make(
            records: records,
            calculator: SleepReportCalculator(calendar: calendar)
        )

        XCTAssertEqual(viewModel.state, .accumulating)
        XCTAssertEqual(viewModel.estimatedOpportunityText, "8 小时")
        XCTAssertEqual(viewModel.wakeSignalText, "准点确认起床")
        XCTAssertEqual(viewModel.bedtimeSignalText, "已记录睡前仪式")
        XCTAssertEqual(viewModel.suggestionText, "节律信号很清楚。今晚继续保持轻量睡前准备。")
    }

    func testSevenDaysOfRecordsRenderReadyTrend() {
        let records = (0..<7).map { record(dayOffset: $0 - 6, wakeConfirmed: true) }

        let viewModel = ReportsViewModel.make(
            records: records,
            calculator: SleepReportCalculator(calendar: calendar)
        )

        XCTAssertEqual(viewModel.state, .ready)
        XCTAssertEqual(viewModel.trendSummary?.dayCount, 7)
        XCTAssertEqual(viewModel.trendSummary?.averageEstimatedSleepOpportunityMinutes, 480)
        XCTAssertEqual(viewModel.trendSummary?.wakeConfirmationRate, 1)
        XCTAssertEqual(viewModel.trendSummary?.consecutiveScheduleSignalDays, 7)
    }

    func testFewRecordsRenderAccumulatingState() {
        let records = (0..<3).map { record(dayOffset: $0 - 2, wakeConfirmed: true) }

        let viewModel = ReportsViewModel.make(
            records: records,
            calculator: SleepReportCalculator(calendar: calendar)
        )

        XCTAssertEqual(viewModel.state, .accumulating)
        XCTAssertEqual(viewModel.trendSummary?.dayCount, 3)
    }

    func testMissedWakeUsesEstimatedLanguage() {
        let records = [record(dayOffset: 0, wakeConfirmed: false)]

        let viewModel = ReportsViewModel.make(
            records: records,
            calculator: SleepReportCalculator(calendar: calendar)
        )

        XCTAssertEqual(viewModel.wakeSignalText, "起床未确认，按估计处理")
        XCTAssertEqual(viewModel.suggestionText, "今天缺少起床确认。报告会保持估计口径，不把它当成实际睡眠质量。")
    }

    func testEmptyRecordsRenderEmptyState() {
        let viewModel = ReportsViewModel.make(records: [])

        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertEqual(viewModel.emptyTitle, "还没有报告")
        XCTAssertEqual(viewModel.emptyDetail, "完成一次睡前或起床确认后，这里会显示基于日程的估计报告。")
    }

    func testWakeFlowRecordAppearsInReports() throws {
        let store = try SleepDataStore(inMemory: true)
        let confirmationDate = snapshot.wakeTime.date(on: localDay, calendar: calendar)
        let wakeViewModel = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { confirmationDate }
        )

        XCTAssertTrue(wakeViewModel.confirmWake())

        let reportsViewModel = ReportsViewModel.make(
            records: try store.records(),
            calculator: SleepReportCalculator(calendar: calendar)
        )
        XCTAssertEqual(reportsViewModel.wakeSignalText, "准点确认起床")
        XCTAssertEqual(reportsViewModel.estimatedOpportunityText, "8 小时")
    }

    private var calendar: Calendar {
        TestCalendar.make()
    }

    private var localDay: Date {
        TestCalendar.date("2026-06-03T16:00:00Z")
    }

    private var snapshot: ScheduleSnapshot {
        ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
    }

    private func record(dayOffset: Int, wakeConfirmed: Bool) -> SleepRecord {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: localDay) ?? localDay
        let wakeDate = snapshot.wakeTime.date(on: day, calendar: calendar)
        return SleepRecord(
            localDay: day,
            scheduleSnapshot: snapshot,
            bedtimeConfirmedAt: snapshot.bedtime.date(on: day, calendar: calendar),
            wakeConfirmedAt: wakeConfirmed ? wakeDate : nil,
            missedWakeMarkedAt: wakeConfirmed ? nil : calendar.date(byAdding: .minute, value: 61, to: wakeDate),
            calendar: calendar
        )
    }
}
