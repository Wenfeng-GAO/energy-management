import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false

    var body: some View {
        Group {
            if hasCompletedInitialSetup {
                HomeEntryView()
            } else {
                OnboardingEntryView()
            }
        }
        .background(ColorTokens.warmWhite)
    }
}

private struct OnboardingEntryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            Spacer()

            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                Text("睡眠能量")
                    .font(TypographyTokens.display)
                    .foregroundStyle(ColorTokens.ink)

                Text("先设定你的入睡、起床和睡前准备时间。MVP 只记录本机手动信号，不接入账号、健康数据或云同步。")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("开始设置") {}
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("startSetupButton")

            Spacer()
        }
        .padding(SpacingTokens.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(ColorTokens.warmWhite)
        .accessibilityIdentifier("onboardingEntry")
    }
}

private struct HomeEntryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            Text("今日节律")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            Text("这里将显示今晚的睡前准备、目标起床时间和基于日程的睡眠机会估计。")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(SpacingTokens.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorTokens.warmWhite)
        .accessibilityIdentifier("homeEntry")
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypographyTokens.callout)
            .foregroundStyle(ColorTokens.buttonText)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(configuration.isPressed ? ColorTokens.clay.opacity(0.8) : ColorTokens.clay)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    ContentView()
}
