import Foundation

enum HomeRitualState: Equatable {
    case waiting
    case bedtimePreparation
    case wakeConfirmation
    case missedWakeConfirmation
}

struct HomeViewModel: Equatable {
    let scheduleSummary: String
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
            scheduleSummary: "睡前 \(formatted(scheduleSnapshot.bedtime)) · 起床 \(formatted(scheduleSnapshot.wakeTime)) · 准备 \(scheduleSnapshot.prepLeadMinutes) 分钟",
            nextActionTitle: title(for: state),
            nextActionDetail: detail(for: state),
            notificationPrompt: prompt(for: notificationStatus),
            ritualState: state
        )
    }

    static func placeholder(notificationStatus: NotificationStatus = NotificationStatus(authorizationState: .notDetermined)) -> HomeViewModel {
        make(
            scheduleSnapshot: ScheduleSnapshot(
                bedtime: ClockTime(hour: 23, minute: 0),
                wakeTime: ClockTime(hour: 7, minute: 0),
                prepLeadMinutes: 30,
                timeZoneIdentifier: TimeZone.current.identifier
            ),
            notificationStatus: notificationStatus,
            now: Date(),
            localDay: Date()
        )
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
            return "下一步还没开始"
        case .bedtimePreparation:
            return "进入睡前准备"
        case .wakeConfirmation:
            return "确认已经起床"
        case .missedWakeConfirmation:
            return "今天错过了起床确认"
        }
    }

    private static func detail(for state: HomeRitualState) -> String {
        switch state {
        case .waiting:
            return "保持轻松，到了准备时间再行动。"
        case .bedtimePreparation:
            return "做几件低负担的事，让今晚安静收尾。"
        case .wakeConfirmation:
            return "轻点确认今天的日程信号。"
        case .missedWakeConfirmation:
            return "报告会以未确认或估计状态呈现，不会假装你准时确认。"
        }
    }
}
