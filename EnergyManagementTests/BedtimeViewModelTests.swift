import XCTest
@testable import EnergyManagement

@MainActor
final class BedtimeViewModelTests: XCTestCase {
    func testBedtimeSuggestionsRenderAsGuidanceNotChecklist() throws {
        let viewModel = BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar
        )

        XCTAssertEqual(viewModel.suggestions.count, 3)
        XCTAssertTrue(viewModel.suggestions.contains("降低光线刺激|睡前减少屏幕和强光，让大脑更容易接收到夜晚信号。"))
        XCTAssertFalse(viewModel.hasConfirmedBedtime)
    }

    func testConfirmingBedtimeRecordsRitualEvent() throws {
        let store = try SleepDataStore(inMemory: true)
        let confirmationDate = TestCalendar.date("2026-06-04T14:45:00Z")
        let viewModel = BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { confirmationDate }
        )

        XCTAssertTrue(viewModel.confirmBedtime())

        let record = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertEqual(record.bedtimeConfirmedAt, confirmationDate)
        XCTAssertEqual(record.bedtimeState, .confirmed)
        XCTAssertEqual(
            viewModel.completionMessage,
            "可以安心睡了。"
        )
    }

    // MARK: - Category B: State Flow Completeness

    func testDoubleTapConfirmBedtimeIsIdempotent() throws {
        let store = try SleepDataStore(inMemory: true)
        let firstDate = TestCalendar.date("2026-06-04T14:50:00Z")
        let secondDate = TestCalendar.date("2026-06-04T14:51:00Z")
        var currentDate = firstDate
        let viewModel = BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { currentDate }
        )

        XCTAssertTrue(viewModel.confirmBedtime())
        XCTAssertTrue(viewModel.hasConfirmedBedtime)

        currentDate = secondDate
        XCTAssertTrue(viewModel.confirmBedtime())
        XCTAssertTrue(viewModel.hasConfirmedBedtime)

        let record = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertEqual(record.bedtimeConfirmedAt, secondDate)
        XCTAssertEqual(record.bedtimeState, .confirmed)
    }

    // MARK: - Category C: Undo & Window Warning

    func testUndoBedtimeWithinFiveMinutesSucceeds() throws {
        let store = try SleepDataStore(inMemory: true)
        let confirmDate = TestCalendar.date("2026-06-04T14:45:00Z")
        let undoDate = TestCalendar.date("2026-06-04T14:47:00Z")
        var currentDate = confirmDate
        let viewModel = BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { currentDate }
        )

        XCTAssertTrue(viewModel.confirmBedtime())
        XCTAssertTrue(viewModel.hasConfirmedBedtime)

        currentDate = undoDate
        XCTAssertTrue(viewModel.undoBedtime())

        let record = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertNil(record.bedtimeConfirmedAt)
        XCTAssertFalse(viewModel.hasConfirmedBedtime)
    }

    func testUndoBedtimeAfterFiveMinutesFails() throws {
        let store = try SleepDataStore(inMemory: true)
        let confirmDate = TestCalendar.date("2026-06-04T14:45:00Z")
        let undoDate = TestCalendar.date("2026-06-04T14:51:00Z")
        var currentDate = confirmDate
        let viewModel = BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { currentDate }
        )

        XCTAssertTrue(viewModel.confirmBedtime())
        XCTAssertTrue(viewModel.hasConfirmedBedtime)

        currentDate = undoDate
        XCTAssertFalse(viewModel.undoBedtime())

        let record = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertEqual(record.bedtimeConfirmedAt, confirmDate)
    }

    func testConfirmBedtimeWithinWindowSetsNoWarning() throws {
        let store = try SleepDataStore(inMemory: true)
        // 22:30 Shanghai = 14:30 UTC — within 2h window for 23:00 bedtime
        let confirmDate = TestCalendar.date("2026-06-04T14:30:00Z")
        let viewModel = BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { confirmDate }
        )

        XCTAssertTrue(viewModel.confirmBedtime())
        XCTAssertNil(viewModel.windowWarning)
    }

    func testConfirmBedtimeTooEarlySetsWarningButStillConfirms() throws {
        let store = try SleepDataStore(inMemory: true)
        // 20:00 Shanghai = 12:00 UTC — 3h before bedtime, outside 2h window
        let confirmDate = TestCalendar.date("2026-06-04T12:00:00Z")
        let viewModel = BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { confirmDate }
        )

        XCTAssertTrue(viewModel.confirmBedtime())
        XCTAssertNotNil(viewModel.windowWarning)
        XCTAssertTrue(viewModel.hasConfirmedBedtime)
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
            prepLeadMinutes: 45,
            timeZoneIdentifier: "Asia/Shanghai"
        )
    }
}
