import Foundation

struct NotificationRouteResolver {
    var wakeWindowPolicy: WakeWindowPolicy

    init(wakeWindowPolicy: WakeWindowPolicy = WakeWindowPolicy()) {
        self.wakeWindowPolicy = wakeWindowPolicy
    }

    func route(
        notificationIdentifier: String,
        currentDate: Date,
        localDay: Date,
        scheduleSnapshot: ScheduleSnapshot?,
        record: SleepRecord?
    ) -> AppRoute {
        switch notificationIdentifier {
        case SleepNotificationScheduler.bedtimePreparationIdentifier:
            return .bedtimePreparation
        case SleepNotificationScheduler.wakeIdentifier:
            return wakeRoute(currentDate: currentDate, localDay: localDay, scheduleSnapshot: scheduleSnapshot, record: record)
        default:
            return .home(.normal)
        }
    }

    func route(userInfo: [AnyHashable: Any], currentDate: Date, localDay: Date, scheduleSnapshot: ScheduleSnapshot?, record: SleepRecord?) -> AppRoute {
        guard let kind = userInfo[SleepNotificationScheduler.userInfoKindKey] as? String else {
            return .home(.normal)
        }

        switch SleepNotificationKind(rawValue: kind) {
        case .bedtimePreparation:
            return .bedtimePreparation
        case .wake:
            return wakeRoute(currentDate: currentDate, localDay: localDay, scheduleSnapshot: scheduleSnapshot, record: record)
        case nil:
            return .home(.normal)
        }
    }

    private func wakeRoute(currentDate: Date, localDay: Date, scheduleSnapshot: ScheduleSnapshot?, record: SleepRecord?) -> AppRoute {
        if let record {
            return wakeWindowPolicy.contains(currentDate, record: record)
                ? .wakeConfirmation
                : .home(.missedWake)
        }

        guard let scheduleSnapshot else {
            return .wakeConfirmation
        }

        let decision = wakeWindowPolicy.decision(
            for: currentDate,
            localDay: localDay,
            scheduleSnapshot: scheduleSnapshot
        )

        switch decision {
        case .acceptedEarly, .acceptedOnTime, .acceptedLate:
            return .wakeConfirmation
        case .rejectedTooEarly:
            return .wakeConfirmation
        case .rejectedTooLate:
            return .home(.missedWake)
        }
    }
}
