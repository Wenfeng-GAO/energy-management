import XCTest
@testable import EnergyManagement

final class HomeViewModelTests: XCTestCase {
    func testHomeShowsWaitingStateBeforePreparationWindow() {
        let viewModel = HomeViewModel.make(
            scheduleSnapshot: snapshot(),
            notificationStatus: NotificationStatus(authorizationState: .authorized),
            now: TestCalendar.date("2026-06-04T20:00:00+08:00"),
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            calendar: TestCalendar.make()
        )

        XCTAssertEqual(viewModel.ritualState, .waiting)
        XCTAssertEqual(viewModel.nextActionTitle, "下一步还没开始")
    }

    func testHomeShowsWakeConfirmationDuringWakeWindow() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)

        let viewModel = HomeViewModel.make(
            scheduleSnapshot: snapshot(),
            notificationStatus: NotificationStatus(authorizationState: .authorized),
            now: TestCalendar.date("2026-06-04T07:10:00+08:00"),
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            record: record,
            calendar: calendar
        )

        XCTAssertEqual(viewModel.ritualState, .wakeConfirmation)
    }

    func testHomeShowsMissedStateAfterWakeWindowWithoutConfirmation() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)

        let viewModel = HomeViewModel.make(
            scheduleSnapshot: snapshot(),
            notificationStatus: NotificationStatus(authorizationState: .authorized),
            now: TestCalendar.date("2026-06-04T08:30:00+08:00"),
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            record: record,
            calendar: calendar
        )

        XCTAssertEqual(viewModel.ritualState, .missedWakeConfirmation)
        XCTAssertTrue(viewModel.nextActionDetail.contains("不会假装"))
    }

    func testHomeShowsLowNoiseDeniedNotificationPrompt() {
        let viewModel = HomeViewModel.placeholder(
            notificationStatus: NotificationStatus(authorizationState: .denied)
        )

        XCTAssertEqual(viewModel.notificationPrompt, "通知未开启，但不会阻止应用内仪式。")
    }

    private func snapshot() -> ScheduleSnapshot {
        ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )
    }
}
