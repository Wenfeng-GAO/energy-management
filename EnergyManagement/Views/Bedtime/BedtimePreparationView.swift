import SwiftUI

struct BedtimePreparationView: View {
    @ObservedObject private var viewModel: BedtimeViewModel
    let onSleepConfirmed: () -> Void
    let onDone: () -> Void

    @MainActor
    init(viewModel: BedtimeViewModel? = nil, onSleepConfirmed: @escaping () -> Void = {}, onDone: @escaping () -> Void = {}) {
        self.viewModel = viewModel ?? BedtimeViewModel.live()
        self.onSleepConfirmed = onSleepConfirmed
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
                    .foregroundStyle(ColorTokens.warmWhite)
            }
            .foregroundStyle(ColorTokens.warmWhite.opacity(0.86))

            Spacer(minLength: 18)

            Text("睡前准备")
                .font(TypographyTokens.display)
                .foregroundStyle(ColorTokens.warmWhite)

            Text("距离睡觉时间还有 \(viewModel.prepLeadMinutes) 分钟。先把环境调到更容易入睡的状态。")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.warmWhite.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: SpacingTokens.regular) {
                ForEach(Array(viewModel.suggestions.enumerated()), id: \.offset) { index, suggestion in
                    sleepTip(index: index + 1, rawText: suggestion)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.red)
            }

            if let warning = viewModel.windowWarning {
                Text(warning)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.warmWhite.opacity(0.8))
                    .padding(SpacingTokens.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorTokens.warmWhite.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text("准备好上床时，直接确认睡觉。")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.warmWhite.opacity(0.66))

            Button("我睡觉了") {
                if viewModel.confirmBedtime() {
                    onSleepConfirmed()
                }
            }
            .buttonStyle(PrimaryActionButton(isProminent: true))
            .controlSize(.large)
            .accessibilityIdentifier("confirmBedtimeButton")

            Spacer(minLength: 0)
        }
        .appSurface(background: ColorTokens.night)
        .onAppear { viewModel.checkBedtimeWindow() }
    }

    private func sleepTip(index: Int, rawText: String) -> some View {
        let parts = rawText.split(separator: "|", maxSplits: 1).map(String.init)
        let title = parts.first ?? rawText
        let detail = parts.count > 1 ? parts[1] : ""
        return HStack(alignment: .top, spacing: SpacingTokens.regular) {
            Text(String(format: "%02d", index))
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.warmWhite.opacity(0.76))
                .frame(width: 30, height: 30)
                .background(ColorTokens.warmWhite.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text(title)
                    .font(TypographyTokens.callout)
                    .foregroundStyle(ColorTokens.warmWhite)
                Text(detail)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.warmWhite.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(SpacingTokens.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorTokens.warmWhite.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(ColorTokens.warmWhite.opacity(0.13))
        }
    }
}

#Preview {
    BedtimePreparationView()
}

struct SleepCompleteView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var settled = false
    let wakeText: String
    let canUndo: Bool
    let onUndo: (() -> Void)?
    let onDone: () -> Void

    init(wakeText: String? = nil, canUndo: Bool = false, onUndo: (() -> Void)? = nil, onDone: @escaping () -> Void) {
        self.wakeText = wakeText ?? Self.liveWakeText()
        self.canUndo = canUndo
        self.onUndo = onUndo
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
            .foregroundStyle(ColorTokens.warmWhite.opacity(0.86))

            Spacer()

            sleepRitualMark

            Text("可以安心睡了")
                .font(TypographyTokens.title)
                .foregroundStyle(ColorTokens.warmWhite)

            Text("今天到这里就好。把手机放远一点，让身体慢慢进入休息。")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.warmWhite.opacity(0.74))
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: SpacingTokens.small) {
                Text("明早起床")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.warmWhite.opacity(0.7))
                Text(wakeText)
                    .font(TypographyTokens.display)
                    .foregroundStyle(ColorTokens.warmWhite)
            }
            .padding(.vertical, SpacingTokens.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { Divider().background(ColorTokens.warmWhite.opacity(0.16)) }
            .overlay(alignment: .bottom) { Divider().background(ColorTokens.warmWhite.opacity(0.16)) }

            if canUndo, let onUndo {
                Button("撤回") { onUndo() }
                    .buttonStyle(SecondaryActionButton())
                    .accessibilityIdentifier("undoBedtimeButton")
            }

            Button("回到首页", action: onDone)
                .buttonStyle(PrimaryActionButton())

            Spacer()
        }
        .appSurface(background: ColorTokens.night)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 2.2)) {
                settled = true
            }
        }
        .accessibilityIdentifier("sleepComplete")
    }

    private var sleepRitualMark: some View {
        ZStack {
            Circle()
                .stroke(ColorTokens.warmWhite.opacity(0.34), lineWidth: 1)
                .frame(width: 106, height: 106)
                .scaleEffect(reduceMotion || settled ? 0.82 : 1.18)
                .opacity(reduceMotion || settled ? 0.72 : 0.12)
            Circle()
                .fill(ColorTokens.warmWhite.opacity(0.88))
                .frame(width: 28, height: 28)
                .scaleEffect(reduceMotion || settled ? 0.72 : 1.45)
        }
        .accessibilityHidden(true)
    }

    private static func liveWakeText() -> String {
        let snapshot = (try? SleepDataStore().activeSchedule()?.snapshot) ?? ScheduleSnapshot(
            bedtime: ClockTime(hour: 23, minute: 30),
            wakeTime: ClockTime(hour: 7, minute: 30),
            prepLeadMinutes: 45,
            timeZoneIdentifier: TimeZone.current.identifier
        )
        return String(format: "%02d:%02d", snapshot.wakeTime.hour, snapshot.wakeTime.minute)
    }
}
