import Foundation

enum BedtimeWindowDecision: Equatable {
    case withinWindow
    case outsideWindowTooEarly(minutesBeforeWindowOpens: Int)
    case outsideWindowTooLate(minutesAfterWindowCloses: Int)
}

struct BedtimeWindowPolicy {
    let opensHoursBeforeBedtime: Int
    let closesHoursAfterBedtime: Int
    var calendar: Calendar

    init(
        opensHoursBeforeBedtime: Int = 2,
        closesHoursAfterBedtime: Int = 1,
        calendar: Calendar = .current
    ) {
        self.opensHoursBeforeBedtime = opensHoursBeforeBedtime
        self.closesHoursAfterBedtime = closesHoursAfterBedtime
        self.calendar = calendar
    }

    /// Computes the bedtime date relative to the wake day (localDay).
    /// For cross-midnight schedules (bedtime > wake in clock terms, e.g., 23:00/07:00),
    /// bedtime is on the day BEFORE localDay.
    /// For same-day schedules (bedtime < wake, e.g., 00:30/08:00),
    /// bedtime is on localDay itself.
    func targetBedtimeDate(localDay: Date, scheduleSnapshot: ScheduleSnapshot) -> Date {
        var calendar = calendar
        if let timeZone = TimeZone(identifier: scheduleSnapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }

        let bedtimeMinutes = scheduleSnapshot.bedtime.minutesAfterMidnight
        let wakeMinutes = scheduleSnapshot.wakeTime.minutesAfterMidnight

        if bedtimeMinutes >= wakeMinutes {
            // Cross-midnight: bedtime on previous day (e.g., 23:00 bed / 07:00 wake)
            let previousDay = calendar.date(byAdding: .day, value: -1, to: localDay) ?? localDay
            return scheduleSnapshot.bedtime.date(on: previousDay, calendar: calendar)
        }

        // Same-day: bedtime before wake on same calendar day (e.g., 00:30 bed / 08:00 wake)
        return scheduleSnapshot.bedtime.date(on: localDay, calendar: calendar)
    }

    func decision(
        for confirmationDate: Date,
        localDay: Date,
        scheduleSnapshot: ScheduleSnapshot
    ) -> BedtimeWindowDecision {
        let targetDate = targetBedtimeDate(localDay: localDay, scheduleSnapshot: scheduleSnapshot)
        let secondsFromTarget = confirmationDate.timeIntervalSince(targetDate)
        let minutesFromTarget = Int((secondsFromTarget / 60).rounded())

        let opensMinutesBefore = opensHoursBeforeBedtime * 60
        let closesMinutesAfter = closesHoursAfterBedtime * 60

        if minutesFromTarget < -opensMinutesBefore {
            return .outsideWindowTooEarly(minutesBeforeWindowOpens: abs(minutesFromTarget) - opensMinutesBefore)
        }

        if minutesFromTarget > closesMinutesAfter {
            return .outsideWindowTooLate(minutesAfterWindowCloses: minutesFromTarget - closesMinutesAfter)
        }

        return .withinWindow
    }
}
