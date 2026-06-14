import SwiftUI
import UserNotifications

struct HomeView: View {
    let viewModel: HomeViewModel
    let onEditSchedule: () -> Void
    let onStartBedtime: () -> Void
    let onStartWake: () -> Void
    let onShowReports: () -> Void

    @State private var liveNotificationDenied = false

    init(
        viewModel: HomeViewModel,
        onEditSchedule: @escaping () -> Void = {},
        onStartBedtime: @escaping () -> Void = {},
        onStartWake: @escaping () -> Void = {},
        onShowReports: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onEditSchedule = onEditSchedule
        self.onStartBedtime = onStartBedtime
        self.onStartWake = onStartWake
        self.onShowReports = onShowReports
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            HStack(spacing: 10) {
                BrandMark()
                Text("睡眠教练")
                    .font(TypographyTokens.callout)
                    .foregroundStyle(ColorTokens.secondaryText)
            }

            Text("今日睡眠")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            HStack(spacing: SpacingTokens.regular) {
                timePanel(title: "睡觉", value: viewModel.bedtimeText, valueIdentifier: "homeBedtimeValue")
                timePanel(title: "起床", value: viewModel.wakeText, valueIdentifier: "homeWakeValue")
            }

            if liveNotificationDenied {
                notificationDeniedBanner
            } else if let notificationPrompt = viewModel.notificationPrompt {
                StatusBanner(notificationPrompt, tone: .warning)
                    .accessibilityIdentifier("homeNotificationPrompt")
            }

            Text("睡前准备 \(viewModel.prepStartText) 开始。\(liveNotificationDenied ? "提醒未开启。" : "提醒已计划。")")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.secondaryText)

            if viewModel.ritualState == .bedtimePreparation || viewModel.ritualState == .wakeConfirmation {
                StatusBanner("\(viewModel.nextActionTitle)。\(viewModel.nextActionDetail)", tone: .neutral)
                    .accessibilityIdentifier("homeRitualState")
            }

            HStack(spacing: SpacingTokens.small) {
                Button("修改作息", action: onEditSchedule)
                    .buttonStyle(SecondaryActionButton())
                    .accessibilityIdentifier("editScheduleButton")
                Button("睡前准备", action: onStartBedtime)
                    .buttonStyle(SecondaryActionButton())
                    .accessibilityIdentifier("startBedtimeButton")
                Button("起床确认", action: onStartWake)
                    .buttonStyle(SecondaryActionButton())
                    .accessibilityIdentifier("startWakeButton")
            }

            Button("查看报告", action: onShowReports)
                .buttonStyle(SecondaryActionButton())
                .accessibilityIdentifier("showReportsButton")

            Spacer()
        }
        .appSurface()
        .task { await checkNotificationStatus() }
    }

    private var notificationDeniedBanner: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            Text("睡前和起床提醒未开启。你不会收到通知，但仍可在 App 内操作。")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.secondaryText)
            Button("前往系统设置开启") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(TypographyTokens.caption)
            .foregroundStyle(ColorTokens.paleSage)
        }
        .padding(SpacingTokens.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.paper.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("notificationDeniedBanner")
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            liveNotificationDenied = (settings.authorizationStatus == .denied)
        }
    }

    private func timePanel(title: String, value: String, valueIdentifier: String) -> some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            Text(title)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.secondaryText)
            Text(value)
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)
                .accessibilityIdentifier(valueIdentifier)
        }
        .padding(SpacingTokens.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.paper.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(ColorTokens.secondaryText.opacity(0.16))
        }
    }
}
