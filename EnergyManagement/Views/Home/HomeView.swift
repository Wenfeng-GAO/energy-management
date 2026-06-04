import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            Text("今日节律")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            Text(viewModel.scheduleSummary)
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)

            if let notificationPrompt = viewModel.notificationPrompt {
                Text(notificationPrompt)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.secondaryText)
                    .padding(SpacingTokens.medium)
                    .background(ColorTokens.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityIdentifier("homeNotificationPrompt")
            }

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text(viewModel.nextActionTitle)
                    .font(TypographyTokens.title)
                    .foregroundStyle(ColorTokens.ink)

                Text(viewModel.nextActionDetail)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityIdentifier("homeRitualState")

            Spacer()
        }
        .padding(SpacingTokens.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorTokens.warmWhite)
        .accessibilityIdentifier("homeEntry")
    }
}
