import Foundation

struct NotificationRouteResolver {
    var wakeWindowPolicy: WakeWindowPolicy

    init(wakeWindowPolicy: WakeWindowPolicy = WakeWindowPolicy()) {
        self.wakeWindowPolicy = wakeWindowPolicy
    }

    func route(
        notificationIdentifier: String,
        currentDate: Date,
        record: SleepRecord?
    ) -> AppRoute {
        switch notificationIdentifier {
        case SleepNotificationScheduler.bedtimePreparationIdentifier:
            return .bedtimePreparation
        case SleepNotificationScheduler.wakeIdentifier:
            guard let record else {
                return .home(.normal)
            }
            return wakeWindowPolicy.contains(currentDate, record: record)
                ? .wakeConfirmation
                : .home(.missedWake)
        default:
            return .home(.normal)
        }
    }

    func route(userInfo: [AnyHashable: Any], currentDate: Date, record: SleepRecord?) -> AppRoute {
        guard let kind = userInfo[SleepNotificationScheduler.userInfoKindKey] as? String else {
            return .home(.normal)
        }

        switch SleepNotificationKind(rawValue: kind) {
        case .bedtimePreparation:
            return .bedtimePreparation
        case .wake:
            guard let record else {
                return .home(.normal)
            }
            return wakeWindowPolicy.contains(currentDate, record: record)
                ? .wakeConfirmation
                : .home(.missedWake)
        case nil:
            return .home(.normal)
        }
    }
}
