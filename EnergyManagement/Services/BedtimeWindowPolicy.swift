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

    func targetBedtimeDate(localDay: Date, scheduleSnapshot: ScheduleSnapshot) -> Date {
        var calendar = calendar
        if let timeZone = TimeZone(identifier: scheduleSnapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }
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
