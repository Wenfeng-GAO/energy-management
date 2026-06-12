import XCTest
@testable import EnergyManagement

@MainActor
final class HappyPathIntegrationTests: XCTestCase {

    // MARK: - Test 1: Complete happy path from setup through wake to report

    func testCompleteHappyPathFromSetupThroughWakeToReport() async throws {
        let calendar = TestCalendar.make(timeZoneIdentifier: "Asia/Shanghai")
        let localDay = TestCalendar.date("2026-06-04T00:00:00+08:00")

        // Step 1: Create shared in-memory store
        let store = try SleepDataStore(inMemory: true)

        // Step 2: Create fake reminder scheduler
        let scheduler = FakeReminderScheduler(status: NotificationStatus(authorizationState: .authorized))

        // Step 3: SetupViewModel — set bedtime=23:00, wake=07:00, prepLead=30 -> saveSchedule()
        let setupVM = SetupViewModel(
            bedtimeHour: 23,
            bedtimeMinute: 0,
            wakeHour: 7,
            wakeMinute: 0,
            prepLeadMinutes: 30,
            notificationsEnabled: true,
            notificationStatus: NotificationStatus(authorizationState: .authorized),
            dataStore: store,
            reminderScheduler: scheduler
        )

        let didSave = await setupVM.saveSchedule()

        XCTAssertTrue(didSave, "Schedule should save successfully")
        let savedSchedule = try XCTUnwrap(store.activeSchedule())
        XCTAssertEqual(savedSchedule.bedtime, ClockTime(hour: 23, minute: 0))
        XCTAssertEqual(savedSchedule.wakeTime, ClockTime(hour: 7, minute: 0))
        XCTAssertEqual(savedSchedule.prepLeadMinutes, 30)
        XCTAssertEqual(scheduler.snapshots.count, 1, "Scheduler should be called once")

        // Step 4: Verify notification times — bedtime prep at 22:30, wake at 06:55
        let scheduledSnapshot = try XCTUnwrap(scheduler.snapshots.first)
        let notificationScheduler = SleepNotificationScheduler(client: FakeNotificationClient())
        let requests = notificationScheduler.dailyReminderRequests(for: scheduledSnapshot)

        let bedtimePrepRequest = try XCTUnwrap(requests.first(where: { $0.kind == .bedtimePreparation }))
        XCTAssertEqual(bedtimePrepRequest.hour, 22, "Bedtime prep notification should fire at 22:30")
        XCTAssertEqual(bedtimePrepRequest.minute, 30, "Bedtime prep notification should fire at 22:30")

        let wakeRequest = try XCTUnwrap(requests.first(where: { $0.kind == .wake }))
        XCTAssertEqual(wakeRequest.hour, 6, "Wake notification should fire at 06:55 (5 min before target)")
        XCTAssertEqual(wakeRequest.minute, 55, "Wake notification should fire at 06:55 (5 min before target)")

        // Step 5: HomeViewModel at 22:35 -> verify .bedtimePreparation state
        let snapshot = savedSchedule.snapshot
        let eveningNow = TestCalendar.date("2026-06-04T22:35:00+08:00")
        let homeAtBedtimePrep = HomeViewModel.make(
            scheduleSnapshot: snapshot,
            notificationStatus: NotificationStatus(authorizationState: .authorized),
            now: eveningNow,
            localDay: localDay,
            calendar: calendar
        )
        XCTAssertEqual(homeAtBedtimePrep.ritualState, .bedtimePreparation,
                       "At 22:35 with prepLead=30, home should show bedtimePreparation state")

        // Step 6: BedtimeViewModel at 22:55 -> confirmBedtime() -> verify record
        let bedtimeNow = TestCalendar.date("2026-06-04T22:55:00+08:00")
        let bedtimeVM = BedtimeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { bedtimeNow }
        )

        XCTAssertEqual(bedtimeVM.suggestions.count, 3, "Should show 3 suggestions (not checklist)")
        let bedtimeConfirmed = bedtimeVM.confirmBedtime()
        XCTAssertTrue(bedtimeConfirmed, "Bedtime confirmation should succeed")
        XCTAssertTrue(bedtimeVM.hasConfirmedBedtime)

        let recordAfterBedtime = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertNotNil(recordAfterBedtime.bedtimeConfirmedAt,
                        "Record should have bedtimeConfirmedAt set after confirmation")
        XCTAssertEqual(recordAfterBedtime.bedtimeConfirmedAt, bedtimeNow)

        // Step 7: HomeViewModel at 07:05 next morning -> verify .wakeConfirmation state
        let morningNow = TestCalendar.date("2026-06-04T07:05:00+08:00")
        let homeAtWake = HomeViewModel.make(
            scheduleSnapshot: snapshot,
            notificationStatus: NotificationStatus(authorizationState: .authorized),
            now: morningNow,
            localDay: localDay,
            record: recordAfterBedtime,
            calendar: calendar
        )
        XCTAssertEqual(homeAtWake.ritualState, .wakeConfirmation,
                       "At 07:05 with record present, home should show wakeConfirmation state")

        // Step 8: WakeViewModel at 07:05 -> confirmWake() -> verify record
        let wakeVM = WakeViewModel(
            scheduleSnapshot: snapshot,
            localDay: localDay,
            calendar: calendar,
            dataStore: store,
            now: { morningNow }
        )

        XCTAssertEqual(wakeVM.state, .confirmationAvailable)
        let wakeConfirmed = wakeVM.confirmWake()
        XCTAssertTrue(wakeConfirmed, "Wake confirmation should succeed")
        XCTAssertEqual(wakeVM.state, .confirmed)
        XCTAssertEqual(wakeVM.prompts.count, 3, "Should show 3 prompts after wake confirmation")

        let recordAfterWake = try XCTUnwrap(store.record(for: localDay, calendar: calendar))
        XCTAssertNotNil(recordAfterWake.wakeConfirmedAt,
                        "Record should have wakeConfirmedAt set after wake confirmation")
        XCTAssertEqual(recordAfterWake.wakeConfirmedAt, morningNow)

        // Step 9: ReportsViewModel -> verify complete daily report
        let allRecords = try store.records()
        XCTAssertFalse(allRecords.isEmpty, "Store should have at least one record")

        let reportsVM = ReportsViewModel.make(
            records: allRecords,
            calculator: SleepReportCalculator(calendar: calendar)
        )

        XCTAssertNotEqual(reportsVM.state, .empty, "Reports should not be empty after full flow")
        XCTAssertNotEqual(reportsVM.sleepWindowText, "待完整",
                          "Sleep window should be calculated with both confirmations present")
        XCTAssertEqual(reportsVM.bedtimeSignalText, "睡觉已确认",
                       "Bedtime signal should show confirmed")
        XCTAssertTrue(reportsVM.wakeSignalText.contains("确认起床"),
                      "Wake signal should contain confirmation language")
    }

    // MARK: - Test 2: Notification times match user expectation (5-min-before-wake)

    func testHappyPathNotificationTimesMatchUserExpectation() async throws {
        let store = try SleepDataStore(inMemory: true)
        let scheduler = FakeReminderScheduler(status: NotificationStatus(authorizationState: .authorized))

        // User sets bedtime=23:00, wake=07:00, prepLead=30
        let setupVM = SetupViewModel(
            bedtimeHour: 23,
            bedtimeMinute: 0,
            wakeHour: 7,
            wakeMinute: 0,
            prepLeadMinutes: 30,
            notificationsEnabled: true,
            notificationStatus: NotificationStatus(authorizationState: .authorized),
            dataStore: store,
            reminderScheduler: scheduler
        )

        let didSave = await setupVM.saveSchedule()
        XCTAssertTrue(didSave)

        // Verify: the scheduler received the correct snapshot
        let scheduledSnapshot = try XCTUnwrap(scheduler.snapshots.first)
        XCTAssertEqual(scheduledSnapshot.bedtime, ClockTime(hour: 23, minute: 0))
        XCTAssertEqual(scheduledSnapshot.wakeTime, ClockTime(hour: 7, minute: 0))
        XCTAssertEqual(scheduledSnapshot.prepLeadMinutes, 30)

        // Verify notification times end-to-end through the real scheduler logic
        let notificationScheduler = SleepNotificationScheduler(client: FakeNotificationClient())
        let requests = notificationScheduler.dailyReminderRequests(for: scheduledSnapshot)
        XCTAssertEqual(requests.count, 2, "Should create exactly 2 daily notifications")

        // Bedtime prep: 23:00 - 30 min = 22:30
        let bedtimePrepRequest = try XCTUnwrap(requests.first(where: { $0.kind == .bedtimePreparation }))
        XCTAssertEqual(bedtimePrepRequest.hour, 22)
        XCTAssertEqual(bedtimePrepRequest.minute, 30)
        XCTAssertTrue(bedtimePrepRequest.repeatsDaily)
        XCTAssertEqual(bedtimePrepRequest.identifier, SleepNotificationScheduler.bedtimePreparationIdentifier)

        // Wake: 07:00 - 5 min = 06:55 (wakeLeadMinutes = 5)
        let wakeRequest = try XCTUnwrap(requests.first(where: { $0.kind == .wake }))
        XCTAssertEqual(wakeRequest.hour, 6)
        XCTAssertEqual(wakeRequest.minute, 55)
        XCTAssertTrue(wakeRequest.repeatsDaily)
        XCTAssertEqual(wakeRequest.identifier, SleepNotificationScheduler.wakeIdentifier)

        // Verify the 5-minute lead is a constant
        XCTAssertEqual(SleepNotificationScheduler.wakeLeadMinutes, 5,
                       "Wake notification should always fire exactly 5 minutes before target wake time")
    }
}

// MARK: - Test Doubles

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

private final class FakeNotificationClient: SleepNotificationSchedulingClient {
    var removedIdentifiers: [String] = []
    var addedRequests: [SleepNotificationRequest] = []

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
    }

    func add(_ request: SleepNotificationRequest) async throws {
        addedRequests.append(request)
    }
}
