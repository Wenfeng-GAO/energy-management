import Foundation

@MainActor
final class BedtimeViewModel: ObservableObject {
    @Published private(set) var hasConfirmedBedtime: Bool
    @Published private(set) var completionMessage: String?
    @Published private(set) var errorMessage: String?

    let suggestions: [String]
    let prepLeadMinutes: Int
    let wakeText: String

    private let scheduleSnapshot: ScheduleSnapshot
    private let localDay: Date
    private let calendar: Calendar
    private let dataStore: SleepDataStore?
    private let now: () -> Date

    init(
        scheduleSnapshot: ScheduleSnapshot,
        localDay: Date,
        calendar: Calendar = .current,
        dataStore: SleepDataStore? = nil,
        now: @escaping () -> Date = Date.init,
        hasConfirmedBedtime: Bool = false
    ) {
        self.scheduleSnapshot = scheduleSnapshot
        self.localDay = localDay
        self.calendar = calendar
        self.dataStore = dataStore
        self.now = now
        self.hasConfirmedBedtime = hasConfirmedBedtime
        self.prepLeadMinutes = scheduleSnapshot.prepLeadMinutes
        self.wakeText = String(format: "%02d:%02d", scheduleSnapshot.wakeTime.hour, scheduleSnapshot.wakeTime.minute)
        self.suggestions = [
            "降低光线刺激|睡前减少屏幕和强光，让大脑更容易接收到夜晚信号。",
            "让卧室安静、偏凉、偏暗|稳定的睡眠环境，比临时补救更能帮助身体进入休息。",
            "避开临睡前刺激|尽量远离咖啡因、酒精、大餐和激烈运动，把最后一段时间留给放松。"
        ]
    }

    static func live() -> BedtimeViewModel {
        let store = try? SleepDataStore()
        let snapshot = (try? store?.activeSchedule()?.snapshot) ?? ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: TimeZone.current.identifier
        )
        return BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: Date(),
            dataStore: store
        )
    }

    func confirmBedtime() -> Bool {
        do {
            let record = try existingOrNewRecord()
            let confirmationDate = now()
            record.confirmBedtime(at: confirmationDate)
            try dataStore?.saveRecord(record)
            hasConfirmedBedtime = true
            completionMessage = "可以安心睡了。"
            return true
        } catch {
            errorMessage = "睡前仪式暂时无法记录，请稍后再试。"
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
}
