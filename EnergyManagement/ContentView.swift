import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    @State private var isShowingScheduleSetup = false
    @State private var route: AppRoute
    @State private var bedtimeViewModel: BedtimeViewModel?
    @State private var wakeViewModel: WakeViewModel?

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorTokens.warmWhite)
    }

    @ViewBuilder
    private var routedContent: some View {
        switch route {
        case .setup:
            ScheduleSetupView(editing: false) {
                hasCompletedInitialSetup = true
                route = .home(.normal)
            }
        case .setupEdit:
            ScheduleSetupView(editing: true) {
                hasCompletedInitialSetup = true
                route = .home(.normal)
            }
        case .home:
            HomeView(
                viewModel: .live(context: homeContext),
                onEditSchedule: { route = .setupEdit },
                onStartBedtime: { route = .bedtimePreparation },
                onStartWake: { route = .wakeConfirmation },
                onShowReports: { route = .reports }
            )
        case .bedtimePreparation:
            BedtimePreparationView(viewModel: getOrCreateBedtimeViewModel()) {
                route = .sleepComplete
            } onDone: {
                bedtimeViewModel = nil
                route = .home(.normal)
            }
        case .sleepComplete:
            SleepCompleteView(
                canUndo: bedtimeViewModel?.canUndoBedtime ?? false,
                onUndo: {
                    if bedtimeViewModel?.undoBedtime() == true {
                        route = .bedtimePreparation
                    }
                },
                onDone: {
                    bedtimeViewModel = nil
                    route = .home(.normal)
                }
            )
        case .wakeConfirmation:
            WakeConfirmationView(viewModel: getOrCreateWakeViewModel()) {
                route = .wakeComplete
            } onDone: {
                wakeViewModel = nil
                route = .home(.normal)
            }
        case .wakeComplete:
            WakeCompleteView(
                canUndo: wakeViewModel?.canUndoWake ?? false,
                onUndo: {
                    if wakeViewModel?.undoWake() == true {
                        route = .wakeConfirmation
                    }
                },
                onHome: {
                    wakeViewModel = nil
                    route = .home(.normal)
                },
                onReports: {
                    wakeViewModel = nil
                    route = .reports
                }
            )
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
        if arguments.contains("-startSleepComplete") {
            return .sleepComplete
        }
        if arguments.contains("-startWakeComplete") {
            return .wakeComplete
        }
        if arguments.contains("-startReports")
            || arguments.contains("-startReportsEmpty")
            || arguments.contains("-startReportsMissed") {
            return .reports
        }
        return .home(.normal)
    }

    private var homeContext: HomeRouteContext {
        if case let .home(context) = route {
            return context
        }
        return .normal
    }

    @MainActor
    private func getOrCreateBedtimeViewModel() -> BedtimeViewModel {
        if let existing = bedtimeViewModel { return existing }
        let vm = BedtimeViewModel.live()
        bedtimeViewModel = vm
        return vm
    }

    @MainActor
    private func getOrCreateWakeViewModel() -> WakeViewModel {
        if let existing = wakeViewModel { return existing }
        let vm = WakeViewModel.live()
        wakeViewModel = vm
        return vm
    }
}

#Preview {
    ContentView()
}
