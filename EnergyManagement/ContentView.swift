import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    @State private var isShowingScheduleSetup = false
    @State private var route: AppRoute

    init(initialRoute: AppRoute? = nil) {
        _route = State(initialValue: initialRoute ?? Self.launchRoute())
    }

    var body: some View {
        Group {
            if hasCompletedInitialSetup {
                routedContent
            } else if isShowingScheduleSetup {
                ScheduleSetupView {
                    hasCompletedInitialSetup = true
                    route = .home(.normal)
                }
            } else {
                OnboardingView {
                    isShowingScheduleSetup = true
                }
            }
        }
        .background(ColorTokens.warmWhite)
    }

    @ViewBuilder
    private var routedContent: some View {
        switch route {
        case .setup:
            ScheduleSetupView {
                hasCompletedInitialSetup = true
                route = .home(.normal)
            }
        case .home:
            HomeView(
                viewModel: .placeholder(),
                onStartBedtime: { route = .bedtimePreparation },
                onStartWake: { route = .wakeConfirmation },
                onShowReports: { route = .reports }
            )
        case .bedtimePreparation:
            BedtimePreparationView {
                route = .home(.normal)
            }
        case .wakeConfirmation:
            WakeConfirmationView {
                route = .home(.normal)
            }
        case .reports:
            ReportsView {
                route = .home(.normal)
            }
        }
    }

    private static func launchRoute() -> AppRoute {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-startBedtimePreparation") {
            return .bedtimePreparation
        }
        if arguments.contains("-startWakeConfirmation") {
            return .wakeConfirmation
        }
        if arguments.contains("-startMissedWake") {
            return .wakeConfirmation
        }
        if arguments.contains("-startReports")
            || arguments.contains("-startReportsEmpty")
            || arguments.contains("-startReportsMissed") {
            return .reports
        }
        return .home(.normal)
    }
}

#Preview {
    ContentView()
}
