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
        XCTAssertEqual(viewModel.sleepWindowText, "8 小时 6 分钟")
        XCTAssertEqual(viewModel.sleepConfirmedText, "23:28")
        XCTAssertEqual(viewModel.wakeConfirmedText, "07:34")
        XCTAssertEqual(viewModel.targetBedtimeText, "23:30")
        XCTAssertEqual(viewModel.targetWakeText, "07:30")
        XCTAssertEqual(viewModel.wakeSignalText, "晚 4 分钟确认起床")
        XCTAssertEqual(viewModel.bedtimeSignalText, "睡觉已确认")
        XCTAssertEqual(viewModel.suggestionText, "今天有起床信号，但略晚。明早把第一个动作再降低一点难度。")
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
        XCTAssertEqual(viewModel.suggestionText, "缺少睡觉或起床确认，今天的报告会保持克制，不伪造完整数据。")
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
        XCTAssertEqual(reportsViewModel.sleepWindowText, "待完整")
    }

    private var calendar: Calendar {
        TestCalendar.make()
    }

    private var localDay: Date {
        TestCalendar.date("2026-06-03T16:00:00Z")
    }

    private var snapshot: ScheduleSnapshot {
        ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 30),
            wakeTime: ClockTime(hour: 7, minute: 30),
            prepLeadMinutes: 45,
            timeZoneIdentifier: "Asia/Shanghai"
        )
    }

    private func record(dayOffset: Int, wakeConfirmed: Bool) -> SleepRecord {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: localDay) ?? localDay
        let wakeDate = snapshot.wakeTime.date(on: day, calendar: calendar)
        let bedtimeDate = snapshot.bedtime.date(on: day, calendar: calendar)
        return SleepRecord(
            localDay: day,
            scheduleSnapshot: snapshot,
            bedtimeConfirmedAt: calendar.date(byAdding: .minute, value: -2, to: bedtimeDate),
            wakeConfirmedAt: wakeConfirmed ? calendar.date(byAdding: .minute, value: 4, to: wakeDate) : nil,
            missedWakeMarkedAt: wakeConfirmed ? nil : calendar.date(byAdding: .minute, value: 61, to: wakeDate),
            calendar: calendar
        )
    }
}
