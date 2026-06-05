import SwiftUI

struct ScheduleSetupView: View {
    @StateObject private var viewModel: SetupViewModel
    let editing: Bool
    let onComplete: () -> Void

    @MainActor
    init(editing: Bool = false, viewModel: SetupViewModel? = nil, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel ?? SetupViewModel.live())
        self.editing = editing
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            HStack(spacing: 10) {
                BrandMark()
                Text("睡眠教练")
                    .font(TypographyTokens.callout)
                    .foregroundStyle(ColorTokens.secondaryText)
            }

            Text(editing ? "修改你的睡眠节律" : "设置你的睡眠节律")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            VStack(alignment: .leading, spacing: SpacingTokens.regular) {
                timeField(
                    title: "睡觉时间",
                    value: formatted(hour: viewModel.bedtimeHour, minute: viewModel.bedtimeMinute),
                    decrement: { adjustBedtime(by: -15) },
                    increment: { adjustBedtime(by: 15) }
                )
                timeField(
                    title: "起床时间",
                    value: formatted(hour: viewModel.wakeHour, minute: viewModel.wakeMinute),
                    decrement: { adjustWake(by: -15) },
                    increment: { adjustWake(by: 15) }
                )
                prepField
                reminderRow
            }

            if let prompt = viewModel.notificationPrompt {
                StatusBanner(prompt, tone: .neutral)
                    .accessibilityIdentifier("notificationPrompt")
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.red)
            }

            Button(editing ? "保存修改" : "保存并进入首页") {
                Task {
                    if await viewModel.saveSchedule() {
                        onComplete()
                    }
                }
            }
            .buttonStyle(PrimaryActionButton())
            .controlSize(.large)
            .accessibilityIdentifier("saveScheduleButton")

            Spacer(minLength: 0)
        }
        .appSurface()
    }

    private var prepField: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            Text("睡前准备")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.secondaryText)
            Text("在睡觉前留一小段缓冲时间，提醒自己放下屏幕，慢慢安静下来。")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Picker("睡前准备", selection: $viewModel.prepLeadMinutes) {
                ForEach([15, 30, 45, 60, 90], id: \.self) { value in
                    Text("提前 \(value) 分钟").tag(value)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .padding(.horizontal, SpacingTokens.medium)
            .background(ColorTokens.paper.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var reminderRow: some View {
        Toggle(isOn: $viewModel.notificationsEnabled) {
            VStack(alignment: .leading, spacing: SpacingTokens.extraSmall) {
                Text("提醒")
                    .font(TypographyTokens.callout)
                    .foregroundStyle(ColorTokens.ink)
                Text(viewModel.notificationsEnabled ? "睡前准备和起床时轻轻提醒你。" : "关闭后，只在打开 App 时看到提示。")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.secondaryText)
            }
        }
        .toggleStyle(.switch)
        .tint(ColorTokens.paleSage)
        .padding(SpacingTokens.medium)
        .background(ColorTokens.paper.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func timeField(title: String, value: String, decrement: @escaping () -> Void, increment: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            Text(title)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.secondaryText)
            HStack {
                Text(value)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.ink)
                Spacer()
                Button("－", action: decrement)
                    .buttonStyle(SecondaryActionButton())
                    .accessibilityLabel("\(title)减少十五分钟")
                Button("＋", action: increment)
                    .buttonStyle(SecondaryActionButton())
                    .accessibilityLabel("\(title)增加十五分钟")
            }
            .frame(minHeight: 54)
            .padding(.horizontal, SpacingTokens.medium)
            .background(ColorTokens.paper.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func adjustBedtime(by minutes: Int) {
        let adjusted = adjustedTime(hour: viewModel.bedtimeHour, minute: viewModel.bedtimeMinute, by: minutes)
        viewModel.bedtimeHour = adjusted.hour
        viewModel.bedtimeMinute = adjusted.minute
    }

    private func adjustWake(by minutes: Int) {
        let adjusted = adjustedTime(hour: viewModel.wakeHour, minute: viewModel.wakeMinute, by: minutes)
        viewModel.wakeHour = adjusted.hour
        viewModel.wakeMinute = adjusted.minute
    }

    private func adjustedTime(hour: Int, minute: Int, by delta: Int) -> (hour: Int, minute: Int) {
        let total = (hour * 60 + minute + delta + 24 * 60) % (24 * 60)
        return (total / 60, total % 60)
    }

    private func formatted(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }
}
