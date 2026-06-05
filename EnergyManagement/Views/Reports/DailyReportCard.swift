import SwiftUI

struct DailyReportCard: View {
    let viewModel: ReportsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.medium) {
            Text("今日睡眠报告")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            Divider()

            Text(viewModel.sleepWindowText)
                .font(.system(size: 52, weight: .semibold, design: .serif))
                .foregroundStyle(ColorTokens.ink)
                .minimumScaleFactor(0.62)
                .lineLimit(1)

            Text(viewModel.sleepWindowText == "待完整" ? "缺少睡觉或起床确认，今天的报告会保持克制，不伪造完整数据。" : "这是昨晚手动确认形成的睡眠窗口，不是医学睡眠时长。")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SpacingTokens.medium) {
                metricRow(title: "昨晚睡觉", value: viewModel.sleepConfirmedText)
                metricRow(title: "今早起床", value: viewModel.wakeConfirmedText)
                metricRow(title: "目标睡觉", value: viewModel.targetBedtimeText)
                metricRow(title: "目标起床", value: viewModel.targetWakeText)
            }
        }
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
        .padding(.bottom, SpacingTokens.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

#Preview {
    DailyReportCard(viewModel: .previewReady())
        .padding()
}
