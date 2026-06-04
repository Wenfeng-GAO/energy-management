import SwiftUI

struct ReportsView: View {
    let viewModel: ReportsViewModel
    let onDone: () -> Void

    @MainActor
    init(viewModel: ReportsViewModel? = nil, onDone: @escaping () -> Void = {}) {
        self.viewModel = viewModel ?? ReportsViewModel.live()
        self.onDone = onDone
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpacingTokens.large) {
                if viewModel.state == .empty {
                    ReportEmptyStateView(
                        title: viewModel.emptyTitle,
                        detail: viewModel.emptyDetail
                    )
                } else {
                    DailyReportCard(viewModel: viewModel)

                    if let trendSummary = viewModel.trendSummary {
                        SevenDayTrendView(summary: trendSummary)
                    }
                }

                Button("回到今日节律", action: onDone)
                    .buttonStyle(PrimaryActionButton())
                    .controlSize(.large)
                    .accessibilityIdentifier("reportsDoneButton")
            }
            .padding(SpacingTokens.screenPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ColorTokens.warmWhite)
        .accessibilityIdentifier("reportsView")
    }
}

#Preview("Ready") {
    ReportsView(viewModel: .previewReady())
}

#Preview("Accumulating") {
    ReportsView(viewModel: .previewAccumulating())
}

#Preview("Missed") {
    ReportsView(viewModel: .previewMissed())
}
