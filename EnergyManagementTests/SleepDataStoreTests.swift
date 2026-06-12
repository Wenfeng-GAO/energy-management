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

    // MARK: - Category G: Data Layer Robustness

    func testWakeViewModelWithNilDataStoreStillUpdatesState() {
        let calendar = TestCalendar.make()
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let confirmationDate = TestCalendar.date("2026-06-04T07:10:00+08:00")
        let vm = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: nil,
            now: { confirmationDate }
        )

        let result = vm.confirmWake()

        XCTAssertTrue(result)
        XCTAssertEqual(vm.state, .confirmed)
        XCTAssertNil(vm.errorMessage)
    }

    func testBedtimeViewModelWithNilDataStoreConfirmsBedtime() {
        let calendar = TestCalendar.make()
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let confirmationDate = TestCalendar.date("2026-06-03T23:05:00+08:00")
        let vm = BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: nil,
            now: { confirmationDate }
        )

        let result = vm.confirmBedtime()

        XCTAssertTrue(result)
        XCTAssertTrue(vm.hasConfirmedBedtime)
        XCTAssertEqual(vm.completionMessage, "可以安心睡了。")
        XCTAssertNil(vm.errorMessage)
    }

    func testScheduleChangeAfterRecordCreationPreservesRecordSnapshot() {
        let calendar = TestCalendar.make()
        let originalSchedule = SleepSchedule(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        let record = SleepRecord(
            localDay: localDay,
            schedule: originalSchedule,
            wakeConfirmedAt: TestCalendar.date("2026-06-04T07:00:00+08:00"),
            calendar: calendar
        )

        originalSchedule.wakeTime = ClockTime(hour: 6, minute: 0)

        XCTAssertEqual(record.scheduleSnapshot.wakeTime, ClockTime(hour: 7, minute: 0))

        let policy = WakeWindowPolicy(calendar: calendar)
        let targetWake = policy.targetWakeDate(for: record)
        XCTAssertEqual(targetWake, TestCalendar.date("2026-06-04T07:00:00+08:00"))
    }

    func testDataStoreRecordLookupWithMultipleRecordsSameDay() throws {
        let calendar = TestCalendar.make()
        let store = try SleepDataStore(inMemory: true)
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")
        let schedule = SleepSchedule(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
        try store.saveSchedule(schedule)

        let record1 = SleepRecord(
            localDay: localDay,
            schedule: schedule,
            wakeConfirmedAt: TestCalendar.date("2026-06-04T07:00:00+08:00"),
            calendar: calendar
        )
        try store.saveRecord(record1)

        let record2 = SleepRecord(
            localDay: localDay,
            schedule: schedule,
            wakeConfirmedAt: TestCalendar.date("2026-06-04T07:30:00+08:00"),
            calendar: calendar
        )
        try store.saveRecord(record2)

        let fetched = try store.record(for: TestCalendar.date("2026-06-04T12:00:00+08:00"), calendar: calendar)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(try store.records().count, 2)
    }
}
