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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}
