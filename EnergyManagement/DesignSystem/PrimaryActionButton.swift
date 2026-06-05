import SwiftUI

struct PrimaryActionButton: ButtonStyle {
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypographyTokens.callout)
            .foregroundStyle(ColorTokens.buttonText)
            .frame(maxWidth: .infinity)
            .frame(minHeight: isProminent ? 72 : 58)
            .padding(.horizontal, SpacingTokens.large)
            .background(configuration.isPressed ? ColorTokens.night : ColorTokens.button)
            .clipShape(Capsule())
            .shadow(color: ColorTokens.button.opacity(0.18), radius: 18, y: 12)
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

struct SecondaryActionButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypographyTokens.callout)
            .foregroundStyle(ColorTokens.ink)
            .frame(minHeight: SpacingTokens.minimumTapTarget)
            .padding(.horizontal, SpacingTokens.medium)
            .background(configuration.isPressed ? ColorTokens.paperDeep : ColorTokens.paperDeep.opacity(0.72))
            .clipShape(Capsule())
    }
}
