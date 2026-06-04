import SwiftUI

struct ReportEmptyStateView: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.medium) {
            Text(title)
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            Text(detail)
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(SpacingTokens.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.paper)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("reportEmptyState")
    }
}

#Preview {
    ReportEmptyStateView(
        title: "还没有报告",
        detail: "完成一次睡前或起床确认后，这里会显示基于日程的估计报告。"
    )
    .padding()
}
