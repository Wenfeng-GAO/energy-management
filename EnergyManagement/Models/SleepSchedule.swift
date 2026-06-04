import Foundation
import SwiftData

struct ClockTime: Codable, Equatable, Hashable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        precondition((0...23).contains(hour), "Hour must be between 0 and 23.")
        precondition((0...59).contains(minute), "Minute must be between 0 and 59.")
        self.hour = hour
        self.minute = minute
    }

    var minutesAfterMidnight: Int {
        hour * 60 + minute
    }

    func date(on day: Date, calendar inputCalendar: Calendar) -> Date {
        let startOfDay = inputCalendar.startOfDay(for: day)
        return inputCalendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay) ?? startOfDay
    }
}

struct ScheduleSnapshot: Codable, Equatable, Hashable {
    let bedtime: ClockTime
    let wakeTime: ClockTime
    let prepLeadMinutes: Int
    let timeZoneIdentifier: String

    var estimatedSleepOpportunityMinutes: Int {
        let bedtimeMinutes = bedtime.minutesAfterMidnight
        let wakeMinutes = wakeTime.minutesAfterMidnight
        let sameDayDifference = wakeMinutes - bedtimeMinutes
        return sameDayDifference > 0 ? sameDayDifference : sameDayDifference + 24 * 60
    }
}

@Model
final class SleepSchedule {
    @Attribute(.unique) var id: UUID
    var bedtimeHour: Int
    var bedtimeMinute: Int
    var wakeHour: Int
    var wakeMinute: Int
    var prepLeadMinutes: Int
    var timeZoneIdentifier: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        bedtime: ClockTime,
        wakeTime: ClockTime,
        prepLeadMinutes: Int,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        updatedAt: Date = Date()
    ) {
        precondition(prepLeadMinutes >= 0, "Preparation lead time must not be negative.")
        self.id = id
        self.bedtimeHour = bedtime.hour
        self.bedtimeMinute = bedtime.minute
        self.wakeHour = wakeTime.hour
        self.wakeMinute = wakeTime.minute
        self.prepLeadMinutes = prepLeadMinutes
        self.timeZoneIdentifier = timeZoneIdentifier
        self.updatedAt = updatedAt
    }

    var bedtime: ClockTime {
        get { ClockTime(hour: bedtimeHour, minute: bedtimeMinute) }
        set {
            bedtimeHour = newValue.hour
            bedtimeMinute = newValue.minute
            updatedAt = Date()
        }
    }

    var wakeTime: ClockTime {
        get { ClockTime(hour: wakeHour, minute: wakeMinute) }
        set {
            wakeHour = newValue.hour
            wakeMinute = newValue.minute
            updatedAt = Date()
        }
    }

    var snapshot: ScheduleSnapshot {
        ScheduleSnapshot(
            bedtime: bedtime,
            wakeTime: wakeTime,
            prepLeadMinutes: prepLeadMinutes,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }
}
