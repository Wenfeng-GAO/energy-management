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
