import SwiftUI

struct BedtimePreparationView: View {
    @StateObject private var viewModel: BedtimeViewModel
    let onDone: () -> Void

    @MainActor
    init(viewModel: BedtimeViewModel? = nil, onDone: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel ?? BedtimeViewModel.live())
        self.onDone = onDone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.large) {
            Text("睡前准备")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            Text("选一两件轻松的事就好，不需要完成清单。")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)

            VStack(alignment: .leading, spacing: SpacingTokens.medium) {
                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .font(TypographyTokens.body)
                        .foregroundStyle(ColorTokens.ink)
                        .padding(SpacingTokens.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ColorTokens.warmGray.opacity(0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if let message = viewModel.completionMessage {
                Text(message)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.red)
            }

            Button(viewModel.hasConfirmedBedtime ? "回到今日节律" : "记录睡前仪式") {
                if viewModel.hasConfirmedBedtime {
                    onDone()
                } else {
                    _ = viewModel.confirmBedtime()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("confirmBedtimeButton")

            Spacer()
        }
        .padding(SpacingTokens.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ColorTokens.warmWhite)
        .accessibilityIdentifier("bedtimePreparation")
    }
}

#Preview {
    BedtimePreparationView()
}
