import Foundation

enum ReportsViewState: Equatable {
    case empty
    case accumulating
    case ready
}

struct ReportsViewModel: Equatable {
    let state: ReportsViewState
    let dailySummary: DailyReportSummary?
    let trendSummary: SevenDayTrendSummary?
    let estimatedOpportunityText: String
    let wakeSignalText: String
    let bedtimeSignalText: String
    let suggestionText: String
    let emptyTitle: String
    let emptyDetail: String

    static func make(
        records: [SleepRecord],
        calculator: SleepReportCalculator = SleepReportCalculator()
    ) -> ReportsViewModel {
        let sortedRecords = records.sorted { $0.localDay < $1.localDay }
        guard let latestRecord = sortedRecords.last else {
            return ReportsViewModel(
                state: .empty,
                dailySummary: nil,
                trendSummary: nil,
                estimatedOpportunityText: "",
                wakeSignalText: "",
                bedtimeSignalText: "",
                suggestionText: "",
                emptyTitle: "还没有报告",
                emptyDetail: "完成一次睡前或起床确认后，这里会显示基于日程的估计报告。"
            )
        }

        let dailySummary = calculator.dailySummary(for: latestRecord)
        let trendSummary = calculator.sevenDayTrend(for: sortedRecords)
        let state: ReportsViewState = trendSummary.state == .ready ? .ready : .accumulating

        return ReportsViewModel(
            state: state,
            dailySummary: dailySummary,
            trendSummary: trendSummary,
            estimatedOpportunityText: durationText(minutes: dailySummary.estimatedSleepOpportunityMinutes),
            wakeSignalText: wakeSignalText(for: dailySummary.wakeSignal),
            bedtimeSignalText: dailySummary.bedtimeConfirmed ? "已记录睡前仪式" : "睡前仪式未确认",
            suggestionText: suggestion(for: dailySummary),
            emptyTitle: "",
            emptyDetail: ""
        )
    }

    @MainActor
    static func live() -> ReportsViewModel {
        if ProcessInfo.processInfo.arguments.contains("-startReportsEmpty") {
            return make(records: [])
        }

        if ProcessInfo.processInfo.arguments.contains("-startReportsMissed") {
            return make(records: previewRecords(missedLatestWake: true, dayCount: 3))
        }

        if ProcessInfo.processInfo.arguments.contains("-startReports") {
            return make(records: previewRecords(missedLatestWake: false, dayCount: 7))
        }

        let store = try? SleepDataStore()
        if let records = try? store?.records(), !records.isEmpty {
            return make(records: records)
        }

        return make(records: [])
    }

    static func previewReady() -> ReportsViewModel {
        make(records: previewRecords(missedLatestWake: false, dayCount: 7))
    }

    static func previewAccumulating() -> ReportsViewModel {
        make(records: previewRecords(missedLatestWake: false, dayCount: 3))
    }

    static func previewMissed() -> ReportsViewModel {
        make(records: previewRecords(missedLatestWake: true, dayCount: 3))
    }

    private static func durationText(minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return "\(hours) 小时"
        }
        return "\(hours) 小时 \(remainder) 分钟"
    }

    private static func wakeSignalText(for signal: WakePunctualitySignal) -> String {
        switch signal {
        case .early(let minutesBeforeTarget):
            return "提前 \(minutesBeforeTarget) 分钟确认起床"
        case .onTime:
            return "准点确认起床"
        case .slightlyLate(let minutesAfterTarget):
            return "晚 \(minutesAfterTarget) 分钟确认起床"
        case .missedOrEstimated, .accumulatingData:
            return "起床未确认，按估计处理"
        }
    }

    private static func suggestion(for summary: DailyReportSummary) -> String {
        switch summary.wakeSignal {
        case .early, .onTime:
            return "节律信号很清楚。今晚继续保持轻量睡前准备。"
        case .slightlyLate:
            return "今天有起床信号，但略晚。明早把第一个动作再降低一点难度。"
        case .missedOrEstimated, .accumulatingData:
            return "今天缺少起床确认。报告会保持估计口径，不把它当成实际睡眠质量。"
        }
    }

    private static func previewRecords(missedLatestWake: Bool, dayCount: Int) -> [SleepRecord] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let today = calendar.startOfDay(for: Date())
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: TimeZone.current.identifier
        )

        return (0..<dayCount).map { offset in
            let day = calendar.date(byAdding: .day, value: offset - dayCount + 1, to: today) ?? today
            let targetWake = snapshot.wakeTime.date(on: day, calendar: calendar)
            let wakeConfirmedAt = missedLatestWake && offset == dayCount - 1 ? nil : targetWake
            let missedWakeMarkedAt = missedLatestWake && offset == dayCount - 1
                ? calendar.date(byAdding: .minute, value: 61, to: targetWake)
                : nil
            return SleepRecord(
                localDay: day,
                scheduleSnapshot: snapshot,
                bedtimeConfirmedAt: snapshot.bedtime.date(on: day, calendar: calendar),
                wakeConfirmedAt: wakeConfirmedAt,
                missedWakeMarkedAt: missedWakeMarkedAt,
                calendar: calendar
            )
        }
    }
}
