import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    @State private var isShowingScheduleSetup = false

    var body: some View {
        Group {
            if hasCompletedInitialSetup {
                HomeView(viewModel: .placeholder())
            } else if isShowingScheduleSetup {
                ScheduleSetupView {
                    hasCompletedInitialSetup = true
                }
            } else {
                OnboardingView {
                    isShowingScheduleSetup = true
                }
            }
        }
        .background(ColorTokens.warmWhite)
    }
}

#Preview {
    ContentView()
}
