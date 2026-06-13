import Foundation
import SwiftData

enum BedtimeConfirmationState: String, Codable, Equatable {
    case unconfirmed
    case confirmed
}

enum WakeConfirmationState: String, Codable, Equatable {
    case pending
    case confirmed
    case missed
}

@Model
final class SleepRecord {
    @Attribute(.unique) var id: UUID
    /// The calendar date this record belongs to, normalized to startOfDay in the schedule's timezone.
    /// Always represents the date on which the wake window occurs (not the bedtime date).
    /// For bedtime 23:00 / wake 07:00, a record with localDay June 4 means bedtime on June 3 evening, wake on June 4 morning.
    var localDay: Date
    var timeZoneIdentifier: String
    var scheduledBedtimeHour: Int
    var scheduledBedtimeMinute: Int
    var scheduledWakeHour: Int
    var scheduledWakeMinute: Int
    var scheduledPrepLeadMinutes: Int
    var bedtimeConfirmedAt: Date?
    var wakeConfirmedAt: Date?
    var missedWakeMarkedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        localDay: Date,
        scheduleSnapshot: ScheduleSnapshot,
        bedtimeConfirmedAt: Date? = nil,
        wakeConfirmedAt: Date? = nil,
        missedWakeMarkedAt: Date? = nil,
        calendar inputCalendar: Calendar = .current,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        var calendar = inputCalendar
        if let timeZone = TimeZone(identifier: scheduleSnapshot.timeZoneIdentifier) {
            calendar.timeZone = timeZone
        }

        self.id = id
        self.localDay = calendar.startOfDay(for: localDay)
        self.timeZoneIdentifier = scheduleSnapshot.timeZoneIdentifier
        self.scheduledBedtimeHour = scheduleSnapshot.bedtime.hour
        self.scheduledBedtimeMinute = scheduleSnapshot.bedtime.minute
        self.scheduledWakeHour = scheduleSnapshot.wakeTime.hour
        self.scheduledWakeMinute = scheduleSnapshot.wakeTime.minute
        self.scheduledPrepLeadMinutes = scheduleSnapshot.prepLeadMinutes
        self.bedtimeConfirmedAt = bedtimeConfirmedAt
        self.wakeConfirmedAt = wakeConfirmedAt
        self.missedWakeMarkedAt = missedWakeMarkedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(
        id: UUID = UUID(),
        localDay: Date,
        schedule: SleepSchedule,
        bedtimeConfirmedAt: Date? = nil,
        wakeConfirmedAt: Date? = nil,
        missedWakeMarkedAt: Date? = nil,
        calendar: Calendar = .current,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.init(
            id: id,
            localDay: localDay,
            scheduleSnapshot: schedule.snapshot,
            bedtimeConfirmedAt: bedtimeConfirmedAt,
            wakeConfirmedAt: wakeConfirmedAt,
            missedWakeMarkedAt: missedWakeMarkedAt,
            calendar: calendar,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    var scheduleSnapshot: ScheduleSnapshot {
        ScheduleSnapshot(
            bedtime: ClockTime(hour: scheduledBedtimeHour, minute: scheduledBedtimeMinute),
            wakeTime: ClockTime(hour: scheduledWakeHour, minute: scheduledWakeMinute),
            prepLeadMinutes: scheduledPrepLeadMinutes,
            timeZoneIdentifier: timeZoneIdentifier
        )
    }

    var bedtimeState: BedtimeConfirmationState {
        bedtimeConfirmedAt == nil ? .unconfirmed : .confirmed
    }

    var wakeState: WakeConfirmationState {
        if wakeConfirmedAt != nil {
            return .confirmed
        }
        if missedWakeMarkedAt != nil {
            return .missed
        }
        return .pending
    }

    func confirmBedtime(at date: Date) {
        bedtimeConfirmedAt = date
        updatedAt = Date()
    }

    func confirmWake(at date: Date) {
        wakeConfirmedAt = date
        missedWakeMarkedAt = nil
        updatedAt = Date()
    }

    func markWakeMissed(at date: Date) {
        wakeConfirmedAt = nil
        missedWakeMarkedAt = date
        updatedAt = Date()
    }

    func revokeBedtime() {
        bedtimeConfirmedAt = nil
        updatedAt = Date()
    }

    func revokeWake() {
        wakeConfirmedAt = nil
        missedWakeMarkedAt = nil
        updatedAt = Date()
    }
}
