import Foundation

enum WakeRitualState: Equatable {
    case confirmationAvailable
    case confirmed
    case missed
    case tooEarly
}

@MainActor
final class WakeViewModel: ObservableObject {
    @Published private(set) var state: WakeRitualState
    @Published private(set) var statusMessage: String
    @Published private(set) var errorMessage: String?

    let prompts: [String]

    private let scheduleSnapshot: ScheduleSnapshot
    private let localDay: Date
    private var calendar: Calendar
    private let dataStore: SleepDataStore?
    private let wakeWindowPolicy: WakeWindowPolicy
    private let now: () -> Date

    init(
        scheduleSnapshot: ScheduleSnapshot,
        localDay: Date,
        calendar inputCalendar: Calendar = .current,
        dataStore: SleepDataStore? = nil,
        wakeWindowPolicy: WakeWindowPolicy? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        var calendar = inputCalendar
        if let timeZone = TimeZone(identifier: scheduleSnapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        self.scheduleSnapshot = scheduleSnapshot
        self.localDay = localDay
        self.calendar = calendar
        self.dataStore = dataStore
        self.wakeWindowPolicy = wakeWindowPolicy ?? WakeWindowPolicy(calendar: calendar)
        self.now = now
        self.prompts = [
            "先喝几口水。",
            "把窗帘拉开，让房间变亮。",
            "站起来活动一分钟，再决定今天的第一件事。"
        ]

        let initialState = Self.state(
            decision: self.wakeWindowPolicy.decision(
                for: now(),
                localDay: localDay,
                scheduleSnapshot: scheduleSnapshot
            )
        )
        self.state = initialState
        self.statusMessage = Self.message(for: initialState)
    }

    static func live() -> WakeViewModel {
        let store = try? SleepDataStore()
        let snapshot = (try? store?.activeSchedule()?.snapshot) ?? ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: TimeZone.current.identifier
        )
        let testNow = launchOverrideDate(for: snapshot)
        return WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: testNow ?? Date(),
            dataStore: store,
            now: { testNow ?? Date() }
        )
    }

    func confirmWake() -> Bool {
        let confirmationDate = now()
        let decision = wakeWindowPolicy.decision(
            for: confirmationDate,
            localDay: localDay,
            scheduleSnapshot: scheduleSnapshot
        )

        switch decision {
        case .acceptedEarly, .acceptedOnTime, .acceptedLate:
            return saveAcceptedWake(at: confirmationDate)
        case .rejectedTooEarly:
            state = .tooEarly
            statusMessage = Self.message(for: .tooEarly)
            return false
        case .rejectedTooLate:
            return saveMissedWake(at: confirmationDate)
        }
    }

    private func saveAcceptedWake(at confirmationDate: Date) -> Bool {
        do {
            let record = try existingOrNewRecord()
            record.confirmWake(at: confirmationDate)
            try dataStore?.saveRecord(record)
            state = .confirmed
            statusMessage = Self.message(for: .confirmed)
            return true
        } catch {
            errorMessage = "起床确认暂时无法记录，请稍后再试。"
            return false
        }
    }

    private func saveMissedWake(at missedDate: Date) -> Bool {
        do {
            let record = try existingOrNewRecord()
            record.markWakeMissed(at: missedDate)
            try dataStore?.saveRecord(record)
            state = .missed
            statusMessage = Self.message(for: .missed)
            return false
        } catch {
            errorMessage = "未确认状态暂时无法记录，请稍后再试。"
            return false
        }
    }

    private func existingOrNewRecord() throws -> SleepRecord {
        if let record = try dataStore?.record(for: localDay, calendar: calendar) {
            return record
        }

        return SleepRecord(
            localDay: localDay,
            scheduleSnapshot: scheduleSnapshot,
            calendar: calendar,
            createdAt: now(),
            updatedAt: now()
        )
    }

    private static func state(decision: WakeWindowDecision) -> WakeRitualState {
        switch decision {
        case .acceptedEarly, .acceptedOnTime, .acceptedLate:
            return .confirmationAvailable
        case .rejectedTooEarly:
            return .tooEarly
        case .rejectedTooLate:
            return .missed
        }
    }

    private static func message(for state: WakeRitualState) -> String {
        switch state {
        case .confirmationAvailable:
            return "轻点确认你已经起床。这个信号用于日程节律，不代表睡眠质量。"
        case .confirmed:
            return "已记录起床信号。现在做一个很小的清醒动作。"
        case .missed:
            return "今天已经过了确认窗口。报告会以未确认或估计状态呈现。"
        case .tooEarly:
            return "现在还太早。目标起床前 30 分钟内再确认。"
        }
    }

    private static func launchOverrideDate(for snapshot: ScheduleSnapshot) -> Date? {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-startWakeConfirmation") || arguments.contains("-startMissedWake") else {
            return nil
        }

        var calendar = Calendar.current
        if let timeZone = TimeZone(identifier: snapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        let localDay = calendar.startOfDay(for: Date())
        let targetWake = snapshot.wakeTime.date(on: localDay, calendar: calendar)

        if arguments.contains("-startMissedWake") {
            return calendar.date(byAdding: .minute, value: 61, to: targetWake)
        }

        return calendar.date(byAdding: .minute, value: 10, to: targetWake)
    }
}
