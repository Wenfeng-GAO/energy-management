import Foundation

protocol SleepReminderScheduling {
    func rescheduleDailyReminders(for snapshot: ScheduleSnapshot) async -> NotificationStatus
}

extension SleepNotificationScheduler: SleepReminderScheduling {}

@MainActor
final class SetupViewModel: ObservableObject {
    @Published var bedtimeHour: Int
    @Published var wakeHour: Int
    @Published var prepLeadMinutes: Int
    @Published private(set) var notificationStatus: NotificationStatus
    @Published private(set) var errorMessage: String?

    private let dataStore: SleepDataStore?
    private let reminderScheduler: SleepReminderScheduling?

    init(
        bedtimeHour: Int = 23,
        wakeHour: Int = 7,
        prepLeadMinutes: Int = 30,
        notificationStatus: NotificationStatus = NotificationStatus(authorizationState: .notDetermined),
        dataStore: SleepDataStore? = nil,
        reminderScheduler: SleepReminderScheduling? = nil
    ) {
        self.bedtimeHour = bedtimeHour
        self.wakeHour = wakeHour
        self.prepLeadMinutes = prepLeadMinutes
        self.notificationStatus = notificationStatus
        self.dataStore = dataStore
        self.reminderScheduler = reminderScheduler
    }

    static func live() -> SetupViewModel {
        let store = try? SleepDataStore()
        let scheduler = SleepNotificationScheduler(client: UserNotificationSchedulingClient())
        return SetupViewModel(dataStore: store, reminderScheduler: scheduler)
    }

    var notificationPrompt: String? {
        switch notificationStatus.authorizationState {
        case .denied:
            return "通知未开启。你仍可完成设置，并在应用内进行睡前和起床仪式。"
        case .unknown:
            return notificationStatus.message ?? "通知状态暂时不可用，仍可继续设置。"
        case .notDetermined:
            return "稍后会说明提醒用途，再请求通知权限。"
        case .authorized, .provisional, .ephemeral:
            return nil
        }
    }

    func saveSchedule() async -> Bool {
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: bedtimeHour, minute: 0),
            wakeTime: ClockTime(hour: wakeHour, minute: 0),
            prepLeadMinutes: prepLeadMinutes,
            timeZoneIdentifier: TimeZone.current.identifier
        )
        let schedule = SleepSchedule(
            bedtime: snapshot.bedtime,
            wakeTime: snapshot.wakeTime,
            prepLeadMinutes: snapshot.prepLeadMinutes,
            timeZoneIdentifier: snapshot.timeZoneIdentifier
        )

        do {
            try dataStore?.saveSchedule(schedule)
            if let reminderScheduler {
                notificationStatus = await reminderScheduler.rescheduleDailyReminders(for: snapshot)
            }
            return true
        } catch {
            errorMessage = "作息暂时无法保存，请稍后再试。"
            return false
        }
    }
}
