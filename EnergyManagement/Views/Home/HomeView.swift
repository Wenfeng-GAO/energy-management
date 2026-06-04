import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel
    let onStartBedtime: () -> Void
    let onStartWake: () -> Void
    let onShowReports: () -> Void

    init(
        viewModel: HomeViewModel,
        onStartBedtime: @escaping () -> Void = {},
        onStartWake: @escaping () -> Void = {},
        onShowReports: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onStartBedtime = onStartBedtime
        self.onStartWake = onStartWake
        self.onShowReports = onShowReports
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            Text("今日节律")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            Text(viewModel.scheduleSummary)
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)

            if let notificationPrompt = viewModel.notificationPrompt {
                Text(notificationPrompt)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.secondaryText)
                    .padding(SpacingTokens.medium)
                    .background(ColorTokens.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityIdentifier("homeNotificationPrompt")
            }

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text(viewModel.nextActionTitle)
                    .font(TypographyTokens.title)
                    .foregroundStyle(ColorTokens.ink)

                Text(viewModel.nextActionDetail)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityIdentifier("homeRitualState")

            switch viewModel.ritualState {
            case .bedtimePreparation:
                Button("开始睡前准备", action: onStartBedtime)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("startBedtimeButton")
            case .wakeConfirmation:
                Button("确认起床", action: onStartWake)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("startWakeButton")
            case .waiting, .missedWakeConfirmation:
                EmptyView()
            }

            Button("查看报告", action: onShowReports)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("showReportsButton")

            Spacer()
        }
        .padding(SpacingTokens.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorTokens.warmWhite)
        .accessibilityIdentifier("homeEntry")
    }
}
