import Foundation
import UserNotifications

enum NotificationAuthorizationState: Equatable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
    case unknown
}

struct NotificationStatus: Equatable {
    let authorizationState: NotificationAuthorizationState
    let message: String?

    init(authorizationState: NotificationAuthorizationState, message: String? = nil) {
        self.authorizationState = authorizationState
        self.message = message
    }

    var canScheduleReminders: Bool {
        switch authorizationState {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied, .unknown:
            return false
        }
    }

    static func from(_ status: UNAuthorizationStatus, message: String? = nil) -> NotificationStatus {
        switch status {
        case .notDetermined:
            return NotificationStatus(authorizationState: .notDetermined, message: message)
        case .denied:
            return NotificationStatus(authorizationState: .denied, message: message)
        case .authorized:
            return NotificationStatus(authorizationState: .authorized, message: message)
        case .provisional:
            return NotificationStatus(authorizationState: .provisional, message: message)
        case .ephemeral:
            return NotificationStatus(authorizationState: .ephemeral, message: message)
        @unknown default:
            return NotificationStatus(authorizationState: .unknown, message: message)
        }
    }
}
