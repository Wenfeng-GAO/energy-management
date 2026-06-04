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

        XCTAssertEqual(viewModel.suggestions.count, 4)
        XCTAssertTrue(viewModel.suggestions.contains("把手机放远一点，保留一盏柔和的灯。"))
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
            "已记录睡前仪式。这里不是测量入睡时间，只是保留今晚的节律信号。"
        )
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
