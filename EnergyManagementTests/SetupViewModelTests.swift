import XCTest
@testable import EnergyManagement

@MainActor
final class SetupViewModelTests: XCTestCase {
    func testSavingSetupPersistsScheduleAndReschedulesReminders() async throws {
        let store = try SleepDataStore(inMemory: true)
        let scheduler = FakeReminderScheduler(status: NotificationStatus(authorizationState: .authorized))
        let permissionService = FakeNotificationPermissionService(
            currentStatus: NotificationStatus(authorizationState: .authorized)
        )
        let viewModel = SetupViewModel(
            dataStore: store,
            reminderScheduler: scheduler,
            permissionService: permissionService
        )

        let didSave = await viewModel.saveSchedule()

        XCTAssertTrue(didSave)
        XCTAssertEqual(try store.activeSchedule()?.bedtime, ClockTime(hour: 23, minute: 30))
        XCTAssertEqual(try store.activeSchedule()?.wakeTime, ClockTime(hour: 7, minute: 30))
        XCTAssertEqual(scheduler.snapshots.count, 1)
        XCTAssertEqual(permissionService.currentStatusCallCount, 1)
        XCTAssertEqual(permissionService.requestPermissionCallCount, 0)
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

    func testNotDeterminedNotificationPermissionIsRequestedBeforeScheduling() async throws {
        let store = try SleepDataStore(inMemory: true)
        let scheduler = FakeReminderScheduler(status: NotificationStatus(authorizationState: .authorized))
        let permissionService = FakeNotificationPermissionService(
            currentStatus: NotificationStatus(authorizationState: .notDetermined),
            requestedStatus: NotificationStatus(authorizationState: .authorized)
        )
        let viewModel = SetupViewModel(
            dataStore: store,
            reminderScheduler: scheduler,
            permissionService: permissionService
        )

        let didSave = await viewModel.saveSchedule()

        XCTAssertTrue(didSave)
        XCTAssertEqual(permissionService.currentStatusCallCount, 1)
        XCTAssertEqual(permissionService.requestPermissionCallCount, 1)
        XCTAssertEqual(scheduler.snapshots.count, 1)
    }

    func testDeniedNotificationPermissionDoesNotScheduleSystemReminders() async throws {
        let store = try SleepDataStore(inMemory: true)
        let scheduler = FakeReminderScheduler(status: NotificationStatus(authorizationState: .authorized))
        let permissionService = FakeNotificationPermissionService(
            currentStatus: NotificationStatus(authorizationState: .denied, message: "通知未开启")
        )
        let viewModel = SetupViewModel(
            dataStore: store,
            reminderScheduler: scheduler,
            permissionService: permissionService
        )

        let didSave = await viewModel.saveSchedule()

        XCTAssertTrue(didSave)
        XCTAssertEqual(try store.activeSchedule()?.bedtime, ClockTime(hour: 23, minute: 30))
        XCTAssertEqual(viewModel.notificationStatus.authorizationState, .denied)
        XCTAssertEqual(scheduler.snapshots.count, 0)
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

private final class FakeNotificationPermissionService: NotificationPermissionServicing {
    private let status: NotificationStatus
    private let requestedStatus: NotificationStatus
    var currentStatusCallCount = 0
    var requestPermissionCallCount = 0

    init(
        currentStatus: NotificationStatus,
        requestedStatus: NotificationStatus = NotificationStatus(authorizationState: .authorized)
    ) {
        self.status = currentStatus
        self.requestedStatus = requestedStatus
    }

    func currentStatus() async -> NotificationStatus {
        currentStatusCallCount += 1
        return status
    }

    func requestPermission() async -> NotificationStatus {
        requestPermissionCallCount += 1
        return requestedStatus
    }
}
