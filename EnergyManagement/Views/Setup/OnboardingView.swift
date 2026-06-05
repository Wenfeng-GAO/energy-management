import SwiftUI

struct OnboardingView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            HStack(spacing: 10) {
                BrandMark()
                Text("睡眠教练")
                    .font(TypographyTokens.callout)
                    .foregroundStyle(ColorTokens.secondaryText)
            }

            Spacer(minLength: 120)

            Text("建立一个安静、稳定的睡眠节律。")
                .font(TypographyTokens.display)
                .foregroundStyle(ColorTokens.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("好的睡眠节律，会让身体更容易恢复，也让第二天醒来时多一点清醒和掌控感。")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button("开始设置", action: onStart)
                .buttonStyle(PrimaryActionButton())
                .controlSize(.large)
                .accessibilityIdentifier("startSetupButton")
        }
        .appSurface()
        .accessibilityIdentifier("onboardingEntry")
    }
}

struct BrandMark: View {
    var body: some View {
        Circle()
            .strokeBorder(ColorTokens.secondaryText, lineWidth: 1)
            .frame(width: 24, height: 24)
            .overlay(alignment: .trailing) {
                Circle()
                    .fill(ColorTokens.secondaryText)
                    .frame(width: 8, height: 8)
                    .padding(.trailing, 4)
            }
            .accessibilityHidden(true)
    }
}
