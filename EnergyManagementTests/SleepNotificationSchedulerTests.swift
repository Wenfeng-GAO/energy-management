import XCTest
@testable import EnergyManagement

final class SleepNotificationSchedulerTests: XCTestCase {
    func testBedtimeAndWakeRemindersUseScheduleTimes() async {
        let client = FakeNotificationSchedulingClient()
        let scheduler = SleepNotificationScheduler(client: client)
        let snapshot = ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        )

        let requests = scheduler.dailyReminderRequests(for: snapshot)
        _ = await scheduler.rescheduleDailyReminders(for: snapshot)

        XCTAssertEqual(requests.first(where: { $0.kind == .bedtimePreparation })?.hour, 22)
        XCTAssertEqual(requests.first(where: { $0.kind == .bedtimePreparation })?.minute, 30)
        XCTAssertEqual(requests.first(where: { $0.kind == .wake })?.hour, 7)
        XCTAssertEqual(requests.first(where: { $0.kind == .wake })?.minute, 0)
        XCTAssertEqual(client.removedIdentifiers, [
            SleepNotificationScheduler.bedtimePreparationIdentifier,
            SleepNotificationScheduler.wakeIdentifier
        ])
        XCTAssertEqual(client.addedRequests.count, 2)
    }

    func testChangingWakeTimeReplacesPreviousPendingWakeReminder() async {
        let client = FakeNotificationSchedulingClient()
        let scheduler = SleepNotificationScheduler(client: client)

        _ = await scheduler.rescheduleDailyReminders(for: ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        ))
        _ = await scheduler.rescheduleDailyReminders(for: ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 6, minute: 30),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        ))

        XCTAssertEqual(client.removedIdentifiers.filter { $0 == SleepNotificationScheduler.wakeIdentifier }.count, 2)
        XCTAssertEqual(client.addedRequests.last(where: { $0.kind == .wake })?.hour, 6)
        XCTAssertEqual(client.addedRequests.last(where: { $0.kind == .wake })?.minute, 30)
    }

    func testSchedulerFailureReturnsReadableStatus() async {
        let client = FakeNotificationSchedulingClient(errorToThrow: TestNotificationError.failed)
        let scheduler = SleepNotificationScheduler(client: client)

        let status = await scheduler.rescheduleDailyReminders(for: ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: "Asia/Shanghai"
        ))

        XCTAssertEqual(status.authorizationState, .unknown)
        XCTAssertEqual(status.message, "提醒暂时无法保存，请稍后再试。")
    }
}

private enum TestNotificationError: Error {
    case failed
}

private final class FakeNotificationSchedulingClient: SleepNotificationSchedulingClient {
    var removedIdentifiers: [String] = []
    var addedRequests: [SleepNotificationRequest] = []
    let errorToThrow: Error?

    init(errorToThrow: Error? = nil) {
        self.errorToThrow = errorToThrow
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
    }

    func add(_ request: SleepNotificationRequest) async throws {
        if let errorToThrow {
            throw errorToThrow
        }
        addedRequests.append(request)
    }
}
