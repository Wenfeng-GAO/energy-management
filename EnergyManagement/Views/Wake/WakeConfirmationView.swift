import SwiftUI

struct WakeConfirmationView: View {
    @StateObject private var viewModel: WakeViewModel
    let onWakeConfirmed: () -> Void
    let onDone: () -> Void

    @MainActor
    init(viewModel: WakeViewModel? = nil, onWakeConfirmed: @escaping () -> Void = {}, onDone: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel ?? WakeViewModel.live())
        self.onWakeConfirmed = onWakeConfirmed
        self.onDone = onDone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            HStack {
                HStack(spacing: 10) {
                    BrandMark()
                    Text("睡眠教练")
                        .font(TypographyTokens.callout)
                }
                Spacer()
                Button("返回", action: onDone)
                    .font(TypographyTokens.callout)
            }
            .foregroundStyle(ColorTokens.secondaryText)

            Text(title)
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            Text(viewModel.statusMessage)
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("wakeStatusMessage")

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.red)
            }

            Button(buttonTitle) {
                switch viewModel.state {
                case .confirmationAvailable:
                    if viewModel.confirmWake() {
                        onWakeConfirmed()
                    }
                case .confirmed, .missed, .tooEarly:
                    onDone()
                }
            }
            .buttonStyle(PrimaryActionButton())
            .controlSize(.large)
            .accessibilityIdentifier("wakePrimaryButton")

            Spacer()
        }
        .appSurface(background: ColorTokens.morning)
        .accessibilityIdentifier("wakeConfirmation")
    }

    private var title: String {
        switch viewModel.state {
        case .confirmationAvailable:
            return "早安"
        case .confirmed:
            return "开始清醒"
        case .missed:
            return "错过起床确认"
        case .tooEarly:
            return "还没到确认时间"
        }
    }

    private var buttonTitle: String {
        switch viewModel.state {
        case .confirmationAvailable:
            return "我起床了"
        case .confirmed, .missed, .tooEarly:
            return "回到首页"
        }
    }
}

#Preview {
    WakeConfirmationView()
}
