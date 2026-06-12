import Foundation
import UserNotifications

enum SleepNotificationKind: String, Equatable {
    case bedtimePreparation
    case wake
}

struct SleepNotificationRequest: Equatable {
    let identifier: String
    let kind: SleepNotificationKind
    let hour: Int
    let minute: Int
    let title: String
    let body: String
    let repeatsDaily: Bool
}

protocol SleepNotificationSchedulingClient {
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func add(_ request: SleepNotificationRequest) async throws
}

final class UserNotificationSchedulingClient: SleepNotificationSchedulingClient {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func add(_ request: SleepNotificationRequest) async throws {
        var dateComponents = DateComponents()
        dateComponents.hour = request.hour
        dateComponents.minute = request.minute

        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        content.categoryIdentifier = request.kind.rawValue
        content.userInfo = [
            SleepNotificationScheduler.userInfoKindKey: request.kind.rawValue
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: request.repeatsDaily)
        let notificationRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: trigger
        )
        try await notificationCenter.add(notificationRequest)
    }
}

struct SleepNotificationScheduler {
    static let bedtimePreparationIdentifier = "sleep.bedtimePreparation.daily"
    static let wakeIdentifier = "sleep.wake.daily"
    static let userInfoKindKey = "sleepNotificationKind"
    static let wakeLeadMinutes = 5

    private let client: SleepNotificationSchedulingClient

    init(client: SleepNotificationSchedulingClient) {
        self.client = client
    }

    func rescheduleDailyReminders(for schedule: SleepSchedule) async -> NotificationStatus {
        await rescheduleDailyReminders(for: schedule.snapshot)
    }

    func rescheduleDailyReminders(for snapshot: ScheduleSnapshot) async -> NotificationStatus {
        let requests = dailyReminderRequests(for: snapshot)
        client.removePendingNotificationRequests(withIdentifiers: requests.map(\.identifier))

        do {
            for request in requests {
                try await client.add(request)
            }
            return NotificationStatus(authorizationState: .authorized)
        } catch {
            return NotificationStatus(
                authorizationState: .unknown,
                message: "提醒暂时无法保存，请稍后再试。"
            )
        }
    }

    func dailyReminderRequests(for snapshot: ScheduleSnapshot) -> [SleepNotificationRequest] {
        [
            bedtimePreparationRequest(for: snapshot),
            wakeRequest(for: snapshot)
        ]
    }

    private func bedtimePreparationRequest(for snapshot: ScheduleSnapshot) -> SleepNotificationRequest {
        let reminderMinutes = positiveMinutesAfterMidnight(
            snapshot.bedtime.minutesAfterMidnight - snapshot.prepLeadMinutes
        )
        return SleepNotificationRequest(
            identifier: Self.bedtimePreparationIdentifier,
            kind: .bedtimePreparation,
            hour: reminderMinutes / 60,
            minute: reminderMinutes % 60,
            title: "开始睡前准备",
            body: "给自己一点安静时间，准备进入今晚的睡眠节律。",
            repeatsDaily: true
        )
    }

    private func wakeRequest(for snapshot: ScheduleSnapshot) -> SleepNotificationRequest {
        let reminderMinutes = positiveMinutesAfterMidnight(
            snapshot.wakeTime.minutesAfterMidnight - Self.wakeLeadMinutes
        )
        return SleepNotificationRequest(
            identifier: Self.wakeIdentifier,
            kind: .wake,
            hour: reminderMinutes / 60,
            minute: reminderMinutes % 60,
            title: "确认起床",
            body: "轻点确认今天的起床信号，记录你的日程节律。",
            repeatsDaily: true
        )
    }

    private func positiveMinutesAfterMidnight(_ minutes: Int) -> Int {
        let day = 24 * 60
        return ((minutes % day) + day) % day
    }
}
