import SwiftUI

struct ScheduleSetupView: View {
    @StateObject private var viewModel: SetupViewModel
    let onComplete: () -> Void

    @MainActor
    init(viewModel: SetupViewModel? = nil, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel ?? SetupViewModel.live())
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            Text("设置作息")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                Stepper("睡前 \(viewModel.bedtimeHour):00", value: $viewModel.bedtimeHour, in: 18...23)
                Stepper("起床 \(viewModel.wakeHour):00", value: $viewModel.wakeHour, in: 4...10)
                Stepper("睡前准备 \(viewModel.prepLeadMinutes) 分钟", value: $viewModel.prepLeadMinutes, in: 10...90, step: 10)
            }
            .font(TypographyTokens.body)

            if let prompt = viewModel.notificationPrompt {
                Text(prompt)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("notificationPrompt")
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.red)
            }

            Button("保存作息") {
                Task {
                    if await viewModel.saveSchedule() {
                        onComplete()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("saveScheduleButton")

            Spacer()
        }
        .padding(SpacingTokens.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorTokens.warmWhite)
        .accessibilityIdentifier("scheduleSetup")
    }
}
