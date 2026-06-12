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
        }
    }
}

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static let foregroundPresentationOptions: UNNotificationPresentationOptions = [.banner, .list, .sound]

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
}
