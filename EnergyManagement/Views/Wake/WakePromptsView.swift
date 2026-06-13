import SwiftUI

struct WakePromptsView: View {
    let prompts: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.medium) {
            ForEach(prompts, id: \.self) { prompt in
                Text(prompt)
                    .font(TypographyTokens.body)
                    .foregroundStyle(ColorTokens.ink)
                    .padding(SpacingTokens.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorTokens.paper.opacity(0.76))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .accessibilityIdentifier("wakePrompts")
    }
}

struct WakeCompleteView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var viewModel: WakeViewModel
    @State private var awake = false
    let onHome: () -> Void
    let onReports: () -> Void

    init(
        viewModel: WakeViewModel,
        onHome: @escaping () -> Void = {},
        onReports: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onHome = onHome
        self.onReports = onReports
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
                Button("返回", action: onHome)
                    .font(TypographyTokens.callout)
            }
            .foregroundStyle(ColorTokens.secondaryText)

            wakeRitualMark

            Text("开始清醒")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.ink)

            Text("先做一件小事，让身体比手机先醒来。")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.secondaryText)

            WakePromptsView(prompts: viewModel.prompts)

            if viewModel.canUndoWake {
                Button("撤回") { _ = viewModel.undoWake() }
                    .buttonStyle(SecondaryActionButton())
                    .accessibilityIdentifier("undoWakeButton")
            }

            Button("回到首页", action: onHome)
                .buttonStyle(SecondaryActionButton())

            Button("查看今日报告", action: onReports)
                .buttonStyle(PrimaryActionButton())
                .accessibilityIdentifier("wakeReportButton")

            Spacer(minLength: 0)
        }
        .appSurface(background: ColorTokens.morning)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.98, dampingFraction: 0.78)) {
                awake = true
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            if newState == .confirmationAvailable { onHome() }
        }
        .accessibilityIdentifier("wakeComplete")
    }

    private var wakeRitualMark: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(ColorTokens.paleSage.opacity(0.18), lineWidth: 1)
                    .frame(width: CGFloat(76 + index * 18), height: CGFloat(76 + index * 18))
                    .scaleEffect(reduceMotion || awake ? 1.18 : 0.55)
                    .opacity(reduceMotion || awake ? 0.28 : 0)
            }
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.97, blue: 0.78),
                            Color(red: 0.94, green: 0.78, blue: 0.44),
                            Color(red: 0.85, green: 0.64, blue: 0.30)
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 44
                    )
                )
                .frame(width: 62, height: 62)
                .shadow(color: Color(red: 0.85, green: 0.64, blue: 0.30).opacity(0.22), radius: 24, y: 14)
                .offset(y: reduceMotion || awake ? 0 : 28)
                .opacity(reduceMotion || awake ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 144)
        .accessibilityHidden(true)
    }
}

#Preview {
    WakePromptsView(prompts: [
        "喝几口水",
        "拉开窗帘，让房间变亮",
        "站起来活动一分钟"
    ])
}
