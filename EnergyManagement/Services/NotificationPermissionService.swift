import Foundation
import UserNotifications

protocol NotificationPermissionServicing {
    func currentStatus() async -> NotificationStatus
    func requestPermission() async -> NotificationStatus
}

final class NotificationPermissionService: NotificationPermissionServicing {
    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }

    func currentStatus() async -> NotificationStatus {
        let settings = await notificationCenter.notificationSettings()
        return NotificationStatus.from(settings.authorizationStatus)
    }

    func requestPermission() async -> NotificationStatus {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            return NotificationStatus(
                authorizationState: granted ? .authorized : .denied,
                message: granted ? nil : "通知未开启，仍可在应用内完成睡前和起床仪式。"
            )
        } catch {
            return NotificationStatus(
                authorizationState: .unknown,
                message: "通知状态暂时不可用，仍可继续设置作息。"
            )
        }
    }
}
