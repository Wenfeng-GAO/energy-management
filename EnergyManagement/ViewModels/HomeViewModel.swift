import Foundation

enum HomeRitualState: Equatable {
    case waiting
    case bedtimePreparation
    case wakeConfirmation
    case missedWakeConfirmation
}

struct HomeViewModel: Equatable {
    let bedtimeText: String
    let wakeText: String
    let prepStartText: String
    let nextActionTitle: String
    let nextActionDetail: String
    let notificationPrompt: String?
    let ritualState: HomeRitualState

    static func make(
        scheduleSnapshot: ScheduleSnapshot,
        notificationStatus: NotificationStatus,
        now: Date,
        localDay: Date,
        record: SleepRecord? = nil,
        calendar inputCalendar: Calendar = .current,
        wakeWindowPolicy: WakeWindowPolicy? = nil
    ) -> HomeViewModel {
        var calendar = inputCalendar
        if let timeZone = TimeZone(identifier: scheduleSnapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        let policy = wakeWindowPolicy ?? WakeWindowPolicy(calendar: calendar)
        let state = ritualState(
            scheduleSnapshot: scheduleSnapshot,
            now: now,
            localDay: localDay,
            record: record,
            calendar: calendar,
            wakeWindowPolicy: policy
        )

        return HomeViewModel(
            bedtimeText: formatted(scheduleSnapshot.bedtime),
            wakeText: formatted(scheduleSnapshot.wakeTime),
            prepStartText: prepStartText(scheduleSnapshot: scheduleSnapshot, localDay: localDay, calendar: calendar),
            nextActionTitle: title(for: state),
            nextActionDetail: detail(for: state),
            notificationPrompt: prompt(for: notificationStatus),
            ritualState: state
        )
    }

    @MainActor
    static func live(context: HomeRouteContext = .normal) -> HomeViewModel {
        let store = try? SleepDataStore()
        let snapshot = (try? store?.activeSchedule()?.snapshot) ?? ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 30),
            wakeTime: ClockTime(hour: 7, minute: 30),
            prepLeadMinutes: 45,
            timeZoneIdentifier: TimeZone.current.identifier
        )
        let records = (try? store?.records()) ?? []
        let record = records.sorted { $0.localDay < $1.localDay }.last
        let notificationStatus: NotificationStatus
        if ProcessInfo.processInfo.arguments.contains("-homeNotificationDenied") {
            notificationStatus = NotificationStatus(authorizationState: .denied)
        } else {
            notificationStatus = NotificationStatus(authorizationState: .authorized)
        }
        let now = Date()
        var calendar = Calendar.current
        if let timeZone = TimeZone(identifier: snapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        let localDay = calendar.startOfDay(for: now)
        let viewModel = make(
            scheduleSnapshot: snapshot,
            notificationStatus: notificationStatus,
            now: now,
            localDay: localDay,
            record: record
        )
        if context == .missedWake {
            return HomeViewModel(
                bedtimeText: viewModel.bedtimeText,
                wakeText: viewModel.wakeText,
                prepStartText: viewModel.prepStartText,
                nextActionTitle: title(for: .missedWakeConfirmation),
                nextActionDetail: detail(for: .missedWakeConfirmation),
                notificationPrompt: viewModel.notificationPrompt,
                ritualState: .missedWakeConfirmation
            )
        }
        return viewModel
    }

    static func placeholder(notificationStatus: NotificationStatus = NotificationStatus(authorizationState: .notDetermined)) -> HomeViewModel {
        make(
            scheduleSnapshot: ScheduleSnapshot(
                bedtime: ClockTime(hour: 23, minute: 30),
                wakeTime: ClockTime(hour: 7, minute: 30),
                prepLeadMinutes: 45,
                timeZoneIdentifier: TimeZone.current.identifier
            ),
            notificationStatus: notificationStatus,
            now: Date(),
            localDay: Date()
        )
    }

    static func launchPlaceholder() -> HomeViewModel {
        if ProcessInfo.processInfo.arguments.contains("-homeNotificationDenied") {
            return placeholder(notificationStatus: NotificationStatus(authorizationState: .denied))
        }
        return placeholder()
    }

    private static func ritualState(
        scheduleSnapshot: ScheduleSnapshot,
        now: Date,
        localDay: Date,
        record: SleepRecord?,
        calendar: Calendar,
        wakeWindowPolicy: WakeWindowPolicy
    ) -> HomeRitualState {
        if let record, wakeWindowPolicy.contains(now, record: record) {
            return .wakeConfirmation
        }

        let targetWake = wakeWindowPolicy.targetWakeDate(localDay: localDay, scheduleSnapshot: scheduleSnapshot)
        let wakeWindowClose = calendar.date(
            byAdding: .minute,
            value: wakeWindowPolicy.closesMinutesAfterTarget,
            to: targetWake
        ) ?? targetWake

        let bedtime = scheduleSnapshot.bedtime.date(on: localDay, calendar: calendar)
        let prepStart = calendar.date(
            byAdding: .minute,
            value: -scheduleSnapshot.prepLeadMinutes,
            to: bedtime
        ) ?? bedtime
        if now >= prepStart && now <= bedtime {
            return .bedtimePreparation
        }

        if record != nil, now > wakeWindowClose, record?.wakeConfirmedAt == nil {
            return .missedWakeConfirmation
        }

        return .waiting
    }

    private static func formatted(_ time: ClockTime) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
    }

    private static func prepStartText(scheduleSnapshot: ScheduleSnapshot, localDay: Date, calendar: Calendar) -> String {
        let bedtime = scheduleSnapshot.bedtime.date(on: localDay, calendar: calendar)
        let prepStart = calendar.date(byAdding: .minute, value: -scheduleSnapshot.prepLeadMinutes, to: bedtime) ?? bedtime
        let components = calendar.dateComponents([.hour, .minute], from: prepStart)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private static func prompt(for status: NotificationStatus) -> String? {
        switch status.authorizationState {
        case .denied:
            return "通知未开启，但不会阻止应用内仪式。"
        case .unknown:
            return status.message ?? "提醒状态暂时不可用。"
        case .notDetermined:
            return "可在设置后开启轻提醒。"
        case .authorized, .provisional, .ephemeral:
            return nil
        }
    }

    private static func title(for state: HomeRitualState) -> String {
        switch state {
        case .waiting:
            return "今晚会在睡前提醒你"
        case .bedtimePreparation:
            return "睡前准备时间到了"
        case .wakeConfirmation:
            return "该起床了"
        case .missedWakeConfirmation:
            return "今天错过了起床确认"
        }
    }

    private static func detail(for state: HomeRitualState) -> String {
        switch state {
        case .waiting:
            return "睡前准备会按计划开始。"
        case .bedtimePreparation:
            return "现在开始远离屏幕，降低灯光。"
        case .wakeConfirmation:
            return "轻轻开始今天，不要先刷手机。"
        case .missedWakeConfirmation:
            return "报告会以未确认或估计状态呈现，不会假装你准时确认。"
        }
    }
}
