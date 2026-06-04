import Foundation
@testable import EnergyManagement

enum TestCalendar {
    static func make(timeZoneIdentifier: String = "Asia/Shanghai") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_Hans_CN")
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier)!
        return calendar
    }

    static func date(_ iso8601String: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601String)!
    }
}

enum TestRecords {
    static func record(
        localDay: Date,
        wakeConfirmedAt: Date? = nil,
        calendar: Calendar
    ) -> SleepRecord {
        SleepRecord(
            localDay: localDay,
            scheduleSnapshot: ScheduleSnapshot(
                bedtime: ClockTime(hour: 23, minute: 0),
                wakeTime: ClockTime(hour: 7, minute: 0),
                prepLeadMinutes: 30,
                timeZoneIdentifier: "Asia/Shanghai"
            ),
            wakeConfirmedAt: wakeConfirmedAt,
            calendar: calendar
        )
    }
}
