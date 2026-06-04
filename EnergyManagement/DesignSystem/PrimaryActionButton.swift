import SwiftUI

struct PrimaryActionButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypographyTokens.callout)
            .foregroundStyle(ColorTokens.buttonText)
            .frame(minHeight: SpacingTokens.minimumTapTarget)
            .padding(.horizontal, SpacingTokens.large)
            .background(configuration.isPressed ? ColorTokens.night : ColorTokens.clay)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

struct SecondaryActionButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypographyTokens.callout)
            .foregroundStyle(ColorTokens.ink)
            .frame(minHeight: SpacingTokens.minimumTapTarget)
            .padding(.horizontal, SpacingTokens.large)
            .background(configuration.isPressed ? ColorTokens.warmGray.opacity(0.38) : ColorTokens.paper)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
