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
    let sleepWindowText: String
    let sleepConfirmedText: String
    let wakeConfirmedText: String
    let targetBedtimeText: String
    let targetWakeText: String
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
                sleepWindowText: "待完整",
                sleepConfirmedText: "未确认",
                wakeConfirmedText: "未确认",
                targetBedtimeText: "--:--",
                targetWakeText: "--:--",
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
            sleepWindowText: sleepWindowText(for: latestRecord),
            sleepConfirmedText: timeText(latestRecord.bedtimeConfirmedAt, snapshot: latestRecord.scheduleSnapshot),
            wakeConfirmedText: timeText(latestRecord.wakeConfirmedAt, snapshot: latestRecord.scheduleSnapshot),
            targetBedtimeText: clockText(latestRecord.scheduleSnapshot.bedtime),
            targetWakeText: clockText(latestRecord.scheduleSnapshot.wakeTime),
            wakeSignalText: wakeSignalText(for: dailySummary.wakeSignal),
            bedtimeSignalText: dailySummary.bedtimeConfirmed ? "睡觉已确认" : "睡觉未确认",
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

    private static func sleepWindowText(for record: SleepRecord) -> String {
        guard let bedtime = record.bedtimeConfirmedAt, let wake = record.wakeConfirmedAt else {
            return "待完整"
        }
        var minutes = Int(wake.timeIntervalSince(bedtime) / 60)
        if minutes <= 0 {
            minutes += 24 * 60
        }
        return durationText(minutes: minutes)
    }

    private static func timeText(_ date: Date?, snapshot: ScheduleSnapshot) -> String {
        guard let date else { return "未确认" }
        var calendar = Calendar(identifier: .gregorian)
        if let timeZone = TimeZone(identifier: snapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private static func clockText(_ time: ClockTime) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
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
            return "最近七天保持接近 8 小时睡眠窗口。今晚继续按计划开始准备。"
        case .slightlyLate:
            return "今天有起床信号，但略晚。明早把第一个动作再降低一点难度。"
        case .missedOrEstimated, .accumulatingData:
            return "缺少睡觉或起床确认，今天的报告会保持克制，不伪造完整数据。"
        }
    }

    private static func previewRecords(missedLatestWake: Bool, dayCount: Int) -> [SleepRecord] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let today = calendar.startOfDay(for: Date())
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 30),
            wakeTime: ClockTime(hour: 7, minute: 30),
            prepLeadMinutes: 45,
            timeZoneIdentifier: TimeZone.current.identifier
        )

        return (0..<dayCount).map { offset in
            let day = calendar.date(byAdding: .day, value: offset - dayCount + 1, to: today) ?? today
            let targetWake = snapshot.wakeTime.date(on: day, calendar: calendar)
            let bedtimeConfirmedAt = calendar.date(byAdding: .minute, value: -2, to: snapshot.bedtime.date(on: day, calendar: calendar))
            let wakeConfirmedAt = missedLatestWake && offset == dayCount - 1
                ? nil
                : calendar.date(byAdding: .minute, value: 4, to: targetWake)
            let missedWakeMarkedAt = missedLatestWake && offset == dayCount - 1
                ? calendar.date(byAdding: .minute, value: 61, to: targetWake)
                : nil
            return SleepRecord(
                localDay: day,
                scheduleSnapshot: snapshot,
                bedtimeConfirmedAt: bedtimeConfirmedAt,
                wakeConfirmedAt: wakeConfirmedAt,
                missedWakeMarkedAt: missedWakeMarkedAt,
                calendar: calendar
            )
        }
    }
}
