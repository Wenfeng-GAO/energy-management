import Foundation

enum WakePunctualitySignal: Equatable {
    case early(minutesBeforeTarget: Int)
    case onTime
    case slightlyLate(minutesAfterTarget: Int)
    case missedOrEstimated
    case accumulatingData
}

struct DailyReportSummary: Equatable {
    let localDay: Date
    let estimatedSleepOpportunityMinutes: Int
    let bedtimeConfirmed: Bool
    let wakeSignal: WakePunctualitySignal
    let estimatedSleepOpportunityLabel: String
    let scheduleSignalLabel: String

    init(
        localDay: Date,
        estimatedSleepOpportunityMinutes: Int,
        bedtimeConfirmed: Bool,
        wakeSignal: WakePunctualitySignal,
        estimatedSleepOpportunityLabel: String = "预估睡眠机会",
        scheduleSignalLabel: String = "日程信号"
    ) {
        self.localDay = localDay
        self.estimatedSleepOpportunityMinutes = estimatedSleepOpportunityMinutes
        self.bedtimeConfirmed = bedtimeConfirmed
        self.wakeSignal = wakeSignal
        self.estimatedSleepOpportunityLabel = estimatedSleepOpportunityLabel
        self.scheduleSignalLabel = scheduleSignalLabel
    }
}

enum SevenDayTrendState: Equatable {
    case accumulatingData
    case ready
}

struct SevenDayTrendSummary: Equatable {
    let state: SevenDayTrendState
    let dayCount: Int
    let averageEstimatedSleepOpportunityMinutes: Int?
    let wakeConfirmationRate: Double
    let consecutiveScheduleSignalDays: Int
    let title: String
    let estimateDisclaimer: String

    init(
        state: SevenDayTrendState,
        dayCount: Int,
        averageEstimatedSleepOpportunityMinutes: Int?,
        wakeConfirmationRate: Double,
        consecutiveScheduleSignalDays: Int,
        title: String = "七日日程信号",
        estimateDisclaimer: String = "以下为基于日程与手动确认的估计，不代表实际睡眠时长。"
    ) {
        self.state = state
        self.dayCount = dayCount
        self.averageEstimatedSleepOpportunityMinutes = averageEstimatedSleepOpportunityMinutes
        self.wakeConfirmationRate = wakeConfirmationRate
        self.consecutiveScheduleSignalDays = consecutiveScheduleSignalDays
        self.title = title
        self.estimateDisclaimer = estimateDisclaimer
    }
}
