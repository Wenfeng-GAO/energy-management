import XCTest
@testable import EnergyManagement

final class NotificationRouteResolverTests: XCTestCase {
    func testBedtimeNotificationRoutesToBedtimePreparation() {
        let resolver = NotificationRouteResolver(wakeWindowPolicy: WakeWindowPolicy(calendar: TestCalendar.make()))

        let route = resolver.route(
            notificationIdentifier: SleepNotificationScheduler.bedtimePreparationIdentifier,
            currentDate: TestCalendar.date("2026-06-03T22:30:00+08:00"),
            localDay: TestCalendar.date("2026-06-03T00:00:00+08:00"),
            scheduleSnapshot: snapshot,
            record: nil
        )

        XCTAssertEqual(route, .bedtimePreparation)
    }

    func testWakeNotificationDuringConfirmationWindowRoutesToWakeConfirmation() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)
        let resolver = NotificationRouteResolver(wakeWindowPolicy: WakeWindowPolicy(calendar: calendar))

        let route = resolver.route(
            notificationIdentifier: SleepNotificationScheduler.wakeIdentifier,
            currentDate: TestCalendar.date("2026-06-04T07:10:00+08:00"),
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            scheduleSnapshot: snapshot,
            record: record
        )

        XCTAssertEqual(route, .wakeConfirmation)
    }

    func testStaleWakeNotificationRoutesToHomeMissedWakeContext() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)
        let resolver = NotificationRouteResolver(wakeWindowPolicy: WakeWindowPolicy(calendar: calendar))

        let route = resolver.route(
            notificationIdentifier: SleepNotificationScheduler.wakeIdentifier,
            currentDate: TestCalendar.date("2026-06-04T08:30:00+08:00"),
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            scheduleSnapshot: snapshot,
            record: record
        )

        XCTAssertEqual(route, .home(.missedWake))
    }

    func testUserInfoKindRoutesWakeNotification() {
        let calendar = TestCalendar.make()
        let record = TestRecords.record(localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"), calendar: calendar)
        let resolver = NotificationRouteResolver(wakeWindowPolicy: WakeWindowPolicy(calendar: calendar))

        let route = resolver.route(
            userInfo: [SleepNotificationScheduler.userInfoKindKey: SleepNotificationKind.wake.rawValue],
            currentDate: TestCalendar.date("2026-06-04T06:45:00+08:00"),
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            scheduleSnapshot: snapshot,
            record: record
        )

        XCTAssertEqual(route, .wakeConfirmation)
    }

    func testWakeNotificationWithoutRecordRoutesToWakeConfirmation() {
        let resolver = NotificationRouteResolver(wakeWindowPolicy: WakeWindowPolicy(calendar: TestCalendar.make()))

        let route = resolver.route(
            notificationIdentifier: SleepNotificationScheduler.wakeIdentifier,
            currentDate: TestCalendar.date("2026-06-04T07:05:00+08:00"),
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            scheduleSnapshot: snapshot,
            record: nil
        )

        XCTAssertEqual(route, .wakeConfirmation)
    }

    func testWakeNotificationWithoutRecordTooLateRoutesMissedWake() {
        let resolver = NotificationRouteResolver(wakeWindowPolicy: WakeWindowPolicy(calendar: TestCalendar.make()))

        let route = resolver.route(
            notificationIdentifier: SleepNotificationScheduler.wakeIdentifier,
            currentDate: TestCalendar.date("2026-06-04T08:30:00+08:00"),
            localDay: TestCalendar.date("2026-06-04T00:00:00+08:00"),
            scheduleSnapshot: snapshot,
            record: nil
        )

        XCTAssertEqual(route, .home(.missedWake))
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
