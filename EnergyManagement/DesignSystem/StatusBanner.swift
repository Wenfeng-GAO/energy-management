import SwiftUI

struct StatusBanner: View {
    enum Tone {
        case neutral
        case positive
        case warning
    }

    let text: String
    let tone: Tone

    init(_ text: String, tone: Tone = .neutral) {
        self.text = text
        self.tone = tone
    }

    var body: some View {
        Text(text)
            .font(TypographyTokens.caption)
            .foregroundStyle(ColorTokens.secondaryText)
            .padding(SpacingTokens.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var backgroundColor: Color {
        switch tone {
        case .neutral:
            return ColorTokens.paper
        case .positive:
            return ColorTokens.paleSage.opacity(0.26)
        case .warning:
            return ColorTokens.clay.opacity(0.18)
        }
    }
}
