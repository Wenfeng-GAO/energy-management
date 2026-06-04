import XCTest
@testable import EnergyManagement

@MainActor
final class SetupViewModelTests: XCTestCase {
    func testSavingSetupPersistsScheduleAndReschedulesReminders() async throws {
        let store = try SleepDataStore(inMemory: true)
        let scheduler = FakeReminderScheduler(status: NotificationStatus(authorizationState: .authorized))
        let viewModel = SetupViewModel(dataStore: store, reminderScheduler: scheduler)

        let didSave = await viewModel.saveSchedule()

        XCTAssertTrue(didSave)
        XCTAssertEqual(try store.activeSchedule()?.bedtime, ClockTime(hour: 23, minute: 0))
        XCTAssertEqual(try store.activeSchedule()?.wakeTime, ClockTime(hour: 7, minute: 0))
        XCTAssertEqual(scheduler.snapshots.count, 1)
    }

    func testNotificationDeniedPromptDoesNotBlockSetup() async throws {
        let store = try SleepDataStore(inMemory: true)
        let viewModel = SetupViewModel(
            notificationStatus: NotificationStatus(authorizationState: .denied),
            dataStore: store,
            reminderScheduler: nil
        )

        XCTAssertEqual(viewModel.notificationPrompt, "通知未开启。你仍可完成设置，并在应用内进行睡前和起床仪式。")
        let didSave = await viewModel.saveSchedule()
        XCTAssertTrue(didSave)
    }
}

private final class FakeReminderScheduler: SleepReminderScheduling {
    var snapshots: [ScheduleSnapshot] = []
    let status: NotificationStatus

    init(status: NotificationStatus) {
        self.status = status
    }

    func rescheduleDailyReminders(for snapshot: ScheduleSnapshot) async -> NotificationStatus {
        snapshots.append(snapshot)
        return status
    }
}
