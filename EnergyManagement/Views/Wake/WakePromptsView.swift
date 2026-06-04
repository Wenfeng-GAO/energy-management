import SwiftUI

struct WakePromptsView: View {
    let prompts: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.medium) {
            Text("现在做一件小事")
                .font(TypographyTokens.callout)
                .foregroundStyle(ColorTokens.ink)

            ForEach(prompts, id: \.self) { prompt in
                Text(prompt)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.ink)
                    .padding(SpacingTokens.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorTokens.warmGray.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .accessibilityIdentifier("wakePrompts")
    }
}

#Preview {
    WakePromptsView(prompts: [
        "先喝几口水。",
        "把窗帘拉开，让房间变亮。",
        "站起来活动一分钟。"
    ])
}
