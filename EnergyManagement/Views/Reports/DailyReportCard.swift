import SwiftUI

struct DailyReportCard: View {
    let viewModel: ReportsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.medium) {
            Text("今日报告")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            metricRow(title: "预估睡眠机会", value: viewModel.estimatedOpportunityText)
            metricRow(title: "起床信号", value: viewModel.wakeSignalText)
            metricRow(title: "睡前信号", value: viewModel.bedtimeSignalText)

            Text(viewModel.suggestionText)
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(SpacingTokens.large)
        .background(ColorTokens.paper)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("dailyReportCard")
    }

    private func metricRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            Text(title)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.secondaryText)
            Text(value)
                .font(TypographyTokens.callout)
                .foregroundStyle(ColorTokens.ink)
        }
    }
}

#Preview {
    DailyReportCard(viewModel: .previewReady())
        .padding()
}
