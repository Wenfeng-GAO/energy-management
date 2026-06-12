import XCTest
@testable import EnergyManagement

@MainActor
final class WakeViewModelTests: XCTestCase {
    func testWakeConfirmationThirtyMinutesBeforeTargetIsAccepted() throws {
        let store = try SleepDataStore(inMemory: true)
        let confirmationDate = TestCalendar.date("2026-06-03T22:30:00Z")
        let viewModel = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { confirmationDate }
        )

        XCTAssertEqual(viewModel.state, .confirmationAvailable)
        XCTAssertTrue(viewModel.confirmWake())

        let record = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertEqual(record.wakeConfirmedAt, confirmationDate)
        XCTAssertEqual(record.wakeState, .confirmed)
        XCTAssertEqual(viewModel.state, .confirmed)
        XCTAssertEqual(viewModel.prompts.count, 3)
    }

    func testWakeConfirmationSixtyOneMinutesAfterTargetIsMissed() throws {
        let store = try SleepDataStore(inMemory: true)
        let missedDate = TestCalendar.date("2026-06-04T00:01:00Z")
        let viewModel = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { missedDate }
        )

        XCTAssertEqual(viewModel.state, .missed)
        XCTAssertFalse(viewModel.confirmWake())

        let record = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertEqual(record.missedWakeMarkedAt, missedDate)
        XCTAssertNil(record.wakeConfirmedAt)
        XCTAssertEqual(record.wakeState, .missed)
        XCTAssertEqual(viewModel.statusMessage, "今天已经过了确认窗口。报告会以未确认或估计状态呈现。")
    }

    func testWakeConfirmationTooEarlyDoesNotCreateRecord() throws {
        let store = try SleepDataStore(inMemory: true)
        let tooEarlyDate = TestCalendar.date("2026-06-03T22:29:00Z")
        let viewModel = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { tooEarlyDate }
        )

        XCTAssertEqual(viewModel.state, .tooEarly)
        XCTAssertFalse(viewModel.confirmWake())
        XCTAssertNil(try store.record(for: localDay, calendar: calendar))
        XCTAssertEqual(viewModel.statusMessage, "现在还太早。目标起床前 30 分钟内再确认。")
    }

    // MARK: - Category B: State Flow Completeness

    func testDoubleTapConfirmWakeIsIdempotent() throws {
        let store = try SleepDataStore(inMemory: true)
        let firstDate = TestCalendar.date("2026-06-03T23:10:00Z")
        let secondDate = TestCalendar.date("2026-06-03T23:15:00Z")
        var currentDate = firstDate
        let viewModel = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { currentDate }
        )

        XCTAssertTrue(viewModel.confirmWake())
        XCTAssertEqual(viewModel.state, .confirmed)

        currentDate = secondDate
        XCTAssertTrue(viewModel.confirmWake())
        XCTAssertEqual(viewModel.state, .confirmed)

        let record = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertEqual(record.wakeConfirmedAt, secondDate)
        XCTAssertEqual(record.wakeState, .confirmed)
    }

    func testWakeConfirmWithoutPriorBedtimeConfirmation() throws {
        let store = try SleepDataStore(inMemory: true)
        let confirmationDate = TestCalendar.date("2026-06-03T23:05:00Z")
        let viewModel = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { confirmationDate }
        )

        XCTAssertTrue(viewModel.confirmWake())
        XCTAssertEqual(viewModel.state, .confirmed)

        let record = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertEqual(record.wakeConfirmedAt, confirmationDate)
        XCTAssertNil(record.bedtimeConfirmedAt)
        XCTAssertEqual(record.bedtimeState, .unconfirmed)
        XCTAssertEqual(record.wakeState, .confirmed)
    }

    func testConfirmWakeAfterAlreadyMarkedMissed() throws {
        let store = try SleepDataStore(inMemory: true)
        let missedDate = TestCalendar.date("2026-06-04T00:01:00Z")
        let recoveryDate = TestCalendar.date("2026-06-03T23:30:00Z")
        var currentDate = missedDate
        let viewModel = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { currentDate }
        )

        XCTAssertFalse(viewModel.confirmWake())
        XCTAssertEqual(viewModel.state, .missed)

        let recordAfterMiss = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertNotNil(recordAfterMiss.missedWakeMarkedAt)
        XCTAssertNil(recordAfterMiss.wakeConfirmedAt)

        currentDate = recoveryDate
        XCTAssertTrue(viewModel.confirmWake())
        XCTAssertEqual(viewModel.state, .confirmed)

        let recordAfterRecovery = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertEqual(recordAfterRecovery.wakeConfirmedAt, recoveryDate)
        XCTAssertNil(recordAfterRecovery.missedWakeMarkedAt)
        XCTAssertEqual(recordAfterRecovery.wakeState, .confirmed)
    }

    // MARK: - Category C: Undo

    func testUndoWakeWithinFiveMinutesSucceeds() throws {
        let store = try SleepDataStore(inMemory: true)
        // 07:05 Shanghai = 23:05 UTC (previous day)
        let confirmDate = TestCalendar.date("2026-06-03T23:05:00Z")
        let undoDate = TestCalendar.date("2026-06-03T23:07:00Z")
        var currentDate = confirmDate
        let viewModel = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { currentDate }
        )

        XCTAssertTrue(viewModel.confirmWake())
        XCTAssertEqual(viewModel.state, .confirmed)

        currentDate = undoDate
        XCTAssertTrue(viewModel.undoWake())
        XCTAssertEqual(viewModel.state, .confirmationAvailable)

        let record = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertNil(record.wakeConfirmedAt)
    }

    func testUndoWakeAfterFiveMinutesFails() throws {
        let store = try SleepDataStore(inMemory: true)
        // 07:05 Shanghai = 23:05 UTC (previous day)
        let confirmDate = TestCalendar.date("2026-06-03T23:05:00Z")
        let undoDate = TestCalendar.date("2026-06-03T23:11:00Z")
        var currentDate = confirmDate
        let viewModel = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { currentDate }
        )

        XCTAssertTrue(viewModel.confirmWake())
        XCTAssertEqual(viewModel.state, .confirmed)

        currentDate = undoDate
        XCTAssertFalse(viewModel.undoWake())
    }

    func testUndoWakeNotAvailableForMissedState() throws {
        let store = try SleepDataStore(inMemory: true)
        // 08:01 Shanghai = 00:01 UTC — missed (61 min after 07:00 target)
        let missedDate = TestCalendar.date("2026-06-04T00:01:00Z")
        let viewModel = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { missedDate }
        )

        XCTAssertFalse(viewModel.confirmWake())
        XCTAssertEqual(viewModel.state, .missed)
        XCTAssertFalse(viewModel.canUndoWake)
    }

    private var calendar: Calendar {
        TestCalendar.make()
    }

    private var localDay: Date {
        TestCalendar.date("2026-06-03T16:00:00Z")
    }

    private var snapshot: ScheduleSnapshot {
        ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
    }
}
