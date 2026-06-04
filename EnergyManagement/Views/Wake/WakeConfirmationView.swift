import SwiftUI

struct WakeConfirmationView: View {
    @StateObject private var viewModel: WakeViewModel
    let onDone: () -> Void

    @MainActor
    init(viewModel: WakeViewModel? = nil, onDone: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel ?? WakeViewModel.live())
        self.onDone = onDone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            Text(title)
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            Text(viewModel.statusMessage)
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("wakeStatusMessage")

            if viewModel.state == .confirmed {
                WakePromptsView(prompts: viewModel.prompts)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.red)
            }

            Button(buttonTitle) {
                switch viewModel.state {
                case .confirmationAvailable:
                    _ = viewModel.confirmWake()
                case .confirmed, .missed, .tooEarly:
                    onDone()
                }
            }
            .buttonStyle(PrimaryActionButton())
            .controlSize(.large)
            .accessibilityIdentifier("wakePrimaryButton")

            Spacer()
        }
        .appSurface()
        .accessibilityIdentifier("wakeConfirmation")
    }

    private var title: String {
        switch viewModel.state {
        case .confirmationAvailable:
            return "确认已经起床"
        case .confirmed:
            return "早安"
        case .missed:
            return "错过起床确认"
        case .tooEarly:
            return "还没到确认时间"
        }
    }

    private var buttonTitle: String {
        switch viewModel.state {
        case .confirmationAvailable:
            return "我已经起床"
        case .confirmed, .missed, .tooEarly:
            return "回到今日节律"
        }
    }
}

#Preview {
    WakeConfirmationView()
}
