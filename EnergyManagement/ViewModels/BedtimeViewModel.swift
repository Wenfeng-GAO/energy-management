import Foundation

@MainActor
final class BedtimeViewModel: ObservableObject {
    @Published private(set) var hasConfirmedBedtime: Bool
    @Published private(set) var completionMessage: String?
    @Published private(set) var errorMessage: String?

    let suggestions: [String]

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
        self.suggestions = [
            "把手机放远一点，保留一盏柔和的灯。",
            "写下明早第一件小事，让大脑停止排队。",
            "做三轮慢呼吸，肩膀和下颌都松下来。",
            "如果还不困，只做安静的纸质阅读。"
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
            completionMessage = "已记录睡前仪式。这里不是测量入睡时间，只是保留今晚的节律信号。"
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
