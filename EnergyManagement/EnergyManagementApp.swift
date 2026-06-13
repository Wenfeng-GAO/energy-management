import SwiftUI
import UIKit
import UserNotifications

@main
struct EnergyManagementApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var appDelegate

    init() {
        if ProcessInfo.processInfo.arguments.contains("-resetInitialSetup") {
            UserDefaults.standard.set(false, forKey: "hasCompletedInitialSetup")
        }
        if ProcessInfo.processInfo.arguments.contains("-completeInitialSetup") {
            UserDefaults.standard.set(true, forKey: "hasCompletedInitialSetup")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.navigationState)
        }
    }
}

final class NavigationState: ObservableObject {
    @Published var pendingRoute: AppRoute?
}

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static let foregroundPresentationOptions: UNNotificationPresentationOptions = [.banner, .list, .sound]
    let navigationState = NavigationState()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        Self.foregroundPresentationOptions
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let resolver = NotificationRouteResolver()
        let now = Date()
        let calendar = Calendar.current
        let localDay = calendar.startOfDay(for: now)

        let store = try? SleepDataStore()
        let record = try? store?.record(for: localDay, calendar: calendar)
        let snapshot = (try? store?.activeSchedule()?.snapshot) ?? ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 0),
            wakeTime: ClockTime(hour: 7, minute: 0),
            prepLeadMinutes: 30,
            timeZoneIdentifier: TimeZone.current.identifier
        )

        let route = resolver.route(
            userInfo: userInfo,
            currentDate: now,
            localDay: localDay,
            scheduleSnapshot: snapshot,
            record: record
        )

        await MainActor.run {
            navigationState.pendingRoute = route
        }
    }
}
