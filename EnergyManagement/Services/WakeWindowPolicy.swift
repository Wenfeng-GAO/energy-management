import Foundation

enum WakeWindowDecision: Equatable {
    case acceptedEarly(minutesBeforeTarget: Int)
    case acceptedOnTime
    case acceptedLate(minutesAfterTarget: Int)
    case rejectedTooEarly(minutesBeforeTarget: Int)
    case rejectedTooLate(minutesAfterTarget: Int)
}

struct WakeWindowPolicy {
    let opensMinutesBeforeTarget: Int
    let closesMinutesAfterTarget: Int
    var calendar: Calendar

    init(
        opensMinutesBeforeTarget: Int = 30,
        closesMinutesAfterTarget: Int = 60,
        calendar: Calendar = .current
    ) {
        self.opensMinutesBeforeTarget = opensMinutesBeforeTarget
        self.closesMinutesAfterTarget = closesMinutesAfterTarget
        self.calendar = calendar
    }

    func targetWakeDate(for record: SleepRecord) -> Date {
        targetWakeDate(localDay: record.localDay, scheduleSnapshot: record.scheduleSnapshot)
    }

    func targetWakeDate(localDay: Date, scheduleSnapshot: ScheduleSnapshot) -> Date {
        var calendar = calendar
        if let timeZone = TimeZone(identifier: scheduleSnapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        return scheduleSnapshot.wakeTime.date(on: localDay, calendar: calendar)
    }

    func isTargetWakeDSTAdjusted(localDay: Date, scheduleSnapshot: ScheduleSnapshot) -> Bool {
        var calendar = calendar
        if let timeZone = TimeZone(identifier: scheduleSnapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
        return scheduleSnapshot.wakeTime.resolvedDate(on: localDay, calendar: calendar).wasAdjustedForDST
    }

    func decision(for confirmationDate: Date, record: SleepRecord) -> WakeWindowDecision {
        decision(
            for: confirmationDate,
            localDay: record.localDay,
            scheduleSnapshot: record.scheduleSnapshot
        )
    }

    func decision(
        for confirmationDate: Date,
        localDay: Date,
        scheduleSnapshot: ScheduleSnapshot
    ) -> WakeWindowDecision {
        let targetDate = targetWakeDate(localDay: localDay, scheduleSnapshot: scheduleSnapshot)
        let secondsFromTarget = confirmationDate.timeIntervalSince(targetDate)
        let minutesFromTarget = Int((secondsFromTarget / 60).rounded())

        if minutesFromTarget < -opensMinutesBeforeTarget {
            return .rejectedTooEarly(minutesBeforeTarget: abs(minutesFromTarget))
        }

        if minutesFromTarget > closesMinutesAfterTarget {
            return .rejectedTooLate(minutesAfterTarget: minutesFromTarget)
        }

        if minutesFromTarget < 0 {
            return .acceptedEarly(minutesBeforeTarget: abs(minutesFromTarget))
        }

        if minutesFromTarget == 0 {
            return .acceptedOnTime
        }

        return .acceptedLate(minutesAfterTarget: minutesFromTarget)
    }

    func contains(_ confirmationDate: Date, record: SleepRecord) -> Bool {
        switch decision(for: confirmationDate, record: record) {
        case .acceptedEarly, .acceptedOnTime, .acceptedLate:
            return true
        case .rejectedTooEarly, .rejectedTooLate:
            return false
        }
    }
}
