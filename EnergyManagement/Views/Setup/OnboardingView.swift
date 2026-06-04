import SwiftUI

struct OnboardingView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            Spacer()

            Text("睡眠能量")
                .font(TypographyTokens.display)
                .foregroundStyle(ColorTokens.ink)

            Text("先设定睡前、起床和准备时间。所有记录只保存在本机，报告展示的是日程信号和预估睡眠机会。")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button("开始设置", action: onStart)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("startSetupButton")

            Spacer()
        }
        .padding(SpacingTokens.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(ColorTokens.warmWhite)
        .accessibilityIdentifier("onboardingEntry")
    }
}
