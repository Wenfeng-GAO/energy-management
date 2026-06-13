import Foundation

@MainActor
final class BedtimeViewModel: ObservableObject {
    @Published private(set) var hasConfirmedBedtime: Bool
    @Published private(set) var completionMessage: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var windowWarning: String?
    @Published private(set) var canUndoBedtime = false

    let suggestions: [String]
    let prepLeadMinutes: Int
    let wakeText: String

    static let undoWindowSeconds: TimeInterval = 5 * 60

    private let scheduleSnapshot: ScheduleSnapshot
    private let localDay: Date
    private let calendar: Calendar
    private let dataStore: SleepDataStore?
    private let bedtimeWindowPolicy: BedtimeWindowPolicy
    private let now: () -> Date
    private var bedtimeConfirmedAtDate: Date?
    private var undoTask: Task<Void, Never>?

    init(
        scheduleSnapshot: ScheduleSnapshot,
        localDay: Date,
        calendar: Calendar = .current,
        dataStore: SleepDataStore? = nil,
        bedtimeWindowPolicy: BedtimeWindowPolicy? = nil,
        now: @escaping () -> Date = Date.init,
        hasConfirmedBedtime: Bool = false
    ) {
        var adjustedCalendar = calendar
        if let timeZone = TimeZone(identifier: scheduleSnapshot.timeZoneIdentifier) {
            adjustedCalendar.timeZone = timeZone
        }
        self.scheduleSnapshot = scheduleSnapshot
        self.localDay = localDay
        self.calendar = adjustedCalendar
        self.dataStore = dataStore
        self.bedtimeWindowPolicy = bedtimeWindowPolicy ?? BedtimeWindowPolicy(calendar: adjustedCalendar)
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
        var calendar = Calendar.current
        if let timeZone = TimeZone(identifier: snapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        let localDay = calendar.startOfDay(for: Date())
        return BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            dataStore: store
        )
    }

    func checkBedtimeWindow() {
        let decision = bedtimeWindowPolicy.decision(
            for: now(),
            localDay: localDay,
            scheduleSnapshot: scheduleSnapshot
        )
        switch decision {
        case .withinWindow:
            windowWarning = nil
        case .outsideWindowTooEarly(let minutes):
            windowWarning = "离建议睡觉时间还有 \(minutes + bedtimeWindowPolicy.opensHoursBeforeBedtime * 60) 分钟，仍可确认。"
        case .outsideWindowTooLate(let minutes):
            windowWarning = "已超出建议睡觉时间 \(minutes + bedtimeWindowPolicy.closesHoursAfterBedtime * 60) 分钟，仍可确认。"
        }
    }

    func confirmBedtime() -> Bool {
        do {
            let record = try existingOrNewRecord()
            let confirmationDate = now()

            let decision = bedtimeWindowPolicy.decision(
                for: confirmationDate,
                localDay: localDay,
                scheduleSnapshot: scheduleSnapshot
            )
            switch decision {
            case .withinWindow:
                windowWarning = nil
            case .outsideWindowTooEarly(let minutes):
                windowWarning = "离建议睡觉时间还有 \(minutes + bedtimeWindowPolicy.opensHoursBeforeBedtime * 60) 分钟，仍可确认。"
            case .outsideWindowTooLate(let minutes):
                windowWarning = "已超出建议睡觉时间 \(minutes + bedtimeWindowPolicy.closesHoursAfterBedtime * 60) 分钟，仍可确认。"
            }

            record.confirmBedtime(at: confirmationDate)
            try dataStore?.saveRecord(record)
            hasConfirmedBedtime = true
            completionMessage = "可以安心睡了。"
            bedtimeConfirmedAtDate = confirmationDate
            canUndoBedtime = true
            startUndoCountdown()
            return true
        } catch {
            errorMessage = "睡前仪式暂时无法记录，请稍后再试。"
            return false
        }
    }

    func undoBedtime() -> Bool {
        guard canUndoBedtime else { return false }
        guard let confirmedAt = bedtimeConfirmedAtDate else { return false }

        let elapsed = now().timeIntervalSince(confirmedAt)
        guard elapsed <= Self.undoWindowSeconds else {
            canUndoBedtime = false
            return false
        }

        do {
            guard let record = try dataStore?.record(for: localDay, calendar: calendar) else {
                return false
            }
            record.revokeBedtime()
            try dataStore?.saveRecord(record)
            hasConfirmedBedtime = false
            canUndoBedtime = false
            completionMessage = nil
            bedtimeConfirmedAtDate = nil
            undoTask?.cancel()
            return true
        } catch {
            errorMessage = "撤回操作暂时无法完成，请稍后再试。"
            return false
        }
    }

    private func startUndoCountdown() {
        undoTask?.cancel()
        undoTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.undoWindowSeconds))
            guard !Task.isCancelled else { return }
            self?.canUndoBedtime = false
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
