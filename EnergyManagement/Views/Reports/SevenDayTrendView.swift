import SwiftUI

struct SevenDayTrendView: View {
    let summary: SevenDayTrendSummary

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.medium) {
            Text(summary.title)
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            if summary.state == .accumulatingData {
                Text("已积累 \(summary.dayCount) 天，满 7 天后趋势会更稳定。")
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.secondaryText)
            }

            metricRow(title: "平均预估睡眠机会", value: averageOpportunityText)
            metricRow(title: "起床确认率", value: "\(Int((summary.wakeConfirmationRate * 100).rounded()))%")
            metricRow(title: "连续日程信号", value: "\(summary.consecutiveScheduleSignalDays) 天")

            Text(summary.estimateDisclaimer)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(SpacingTokens.large)
        .background(ColorTokens.warmGray.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("sevenDayTrend")
    }

    private var averageOpportunityText: String {
        guard let minutes = summary.averageEstimatedSleepOpportunityMinutes else {
            return "数据积累中"
        }
        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 {
            return "\(hours) 小时"
        }
        return "\(hours) 小时 \(remainder) 分钟"
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)
            Spacer()
            Text(value)
                .font(TypographyTokens.callout)
                .foregroundStyle(ColorTokens.ink)
        }
    }
}

#Preview {
    SevenDayTrendView(summary: ReportsViewModel.previewReady().trendSummary!)
        .padding()
}
