import XCTest
@testable import EnergyManagement

@MainActor
final class SleepDataStoreTests: XCTestCase {
    func testStoresOneActiveScheduleAndLocalDayRecordsInMemory() throws {
        let calendar = TestCalendar.make()
        let store = try SleepDataStore(inMemory: true)
        let schedule = SleepSchedule(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        try store.saveSchedule(schedule)

        let record = SleepRecord(
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            schedule: schedule,
            wakeConfirmedAt: TestCalendar.date("2026-06-04T07:10:00+08:00"),
            calendar: calendar
        )
        try store.saveRecord(record)

        XCTAssertEqual(try store.activeSchedule()?.snapshot, schedule.snapshot)
        XCTAssertEqual(try store.record(for: TestCalendar.date("2026-06-04T18:00:00+08:00"), calendar: calendar)?.wakeState, .confirmed)
        XCTAssertEqual(try store.records().count, 1)
    }

    func testDestructiveResetRequiresExplicitDevelopmentFlag() throws {
        let store = try SleepDataStore(inMemory: true)

        XCTAssertThrowsError(try store.deleteAllDevelopmentData(allowDestructiveReset: false)) { error in
            XCTAssertEqual(error as? SleepDataStoreError, .destructiveResetRequiresExplicitDevelopmentFlag)
        }
    }

    func testExplicitDevelopmentResetDeletesLocalData() throws {
        let calendar = TestCalendar.make()
        let store = try SleepDataStore(inMemory: true)
        let schedule = SleepSchedule(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        try store.saveSchedule(schedule)
        try store.saveRecord(
            SleepRecord(
                localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
                schedule: schedule,
                calendar: calendar
            )
        )

        try store.deleteAllDevelopmentData(allowDestructiveReset: true)

        XCTAssertNil(try store.activeSchedule())
        XCTAssertEqual(try store.records().count, 0)
    }
}
