import Foundation

struct SleepReportCalculator {
    var calendar: Calendar
    var wakeWindowPolicy: WakeWindowPolicy

    init(calendar: Calendar = .current, wakeWindowPolicy: WakeWindowPolicy? = nil) {
        self.calendar = calendar
        self.wakeWindowPolicy = wakeWindowPolicy ?? WakeWindowPolicy(calendar: calendar)
    }

    func dailySummary(for record: SleepRecord) -> DailyReportSummary {
        DailyReportSummary(
            localDay: record.localDay,
            estimatedSleepOpportunityMinutes: record.scheduleSnapshot.estimatedSleepOpportunityMinutes,
            bedtimeConfirmed: record.bedtimeState == .confirmed,
            wakeSignal: wakeSignal(for: record)
        )
    }

    func sevenDayTrend(for records: [SleepRecord]) -> SevenDayTrendSummary {
        let sortedRecords = records.sorted { $0.localDay < $1.localDay }
        guard !sortedRecords.isEmpty else {
            return SevenDayTrendSummary(
                state: .accumulatingData,
                dayCount: 0,
                averageEstimatedSleepOpportunityMinutes: nil,
                wakeConfirmationRate: 0,
                consecutiveScheduleSignalDays: 0
            )
        }

        let recentRecords = Array(sortedRecords.suffix(7))
        let totalOpportunity = recentRecords.reduce(0) { partialResult, record in
            partialResult + record.scheduleSnapshot.estimatedSleepOpportunityMinutes
        }
        let confirmedWakeCount = recentRecords.filter { record in
            switch wakeSignal(for: record) {
            case .early, .onTime, .slightlyLate:
                return true
            case .missedOrEstimated, .accumulatingData:
                return false
            }
        }.count

        return SevenDayTrendSummary(
            state: recentRecords.count < 7 ? .accumulatingData : .ready,
            dayCount: recentRecords.count,
            averageEstimatedSleepOpportunityMinutes: totalOpportunity / recentRecords.count,
            wakeConfirmationRate: Double(confirmedWakeCount) / Double(recentRecords.count),
            consecutiveScheduleSignalDays: consecutiveConfirmedDays(fromEndOf: recentRecords)
        )
    }

    private func wakeSignal(for record: SleepRecord) -> WakePunctualitySignal {
        guard let wakeConfirmedAt = record.wakeConfirmedAt else {
            return .missedOrEstimated
        }

        switch wakeWindowPolicy.decision(for: wakeConfirmedAt, record: record) {
        case .acceptedEarly(let minutesBeforeTarget):
            return .early(minutesBeforeTarget: minutesBeforeTarget)
        case .acceptedOnTime:
            return .onTime
        case .acceptedLate(let minutesAfterTarget):
            return .slightlyLate(minutesAfterTarget: minutesAfterTarget)
        case .rejectedTooEarly, .rejectedTooLate:
            return .missedOrEstimated
        }
    }

    private func consecutiveConfirmedDays(fromEndOf records: [SleepRecord]) -> Int {
        records.reversed().prefix { record in
            switch wakeSignal(for: record) {
            case .early, .onTime, .slightlyLate:
                return true
            case .missedOrEstimated, .accumulatingData:
                return false
            }
        }.count
    }
}
