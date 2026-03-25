import SwiftUI

struct HomeActiveRing: View {
    @EnvironmentObject private var appState: AppState
    let ringSize: CGFloat
    let ringWidth: CGFloat

    private var isOutsideActiveHours: Bool {
        guard let next = appState.runtimeState.nextReminderAt else { return false }
        let remaining = next.timeIntervalSinceNow
        let intervalSeconds = Double(appState.effectiveIntervalMinutes * 60)
        return remaining > intervalSeconds * 1.5
    }

    var body: some View {
        if isOutsideActiveHours {
            doneForTodayRing
        } else {
            countdownRing
        }
    }

    private var countdownRing: some View {
        TimelineView(.periodic(from: .distantPast, by: 1)) { context in
            let remaining = secondsRemaining(at: context.date)
            let progress = intervalProgress(at: context.date)

            ZStack {
                ProgressRing(
                    progress: progress,
                    size: ringSize,
                    trackWidth: ringWidth,
                    fillWidth: ringWidth,
                    trackColor: ICareColors.separator,
                    fillColor: ICareColors.brand
                )
                .animation(.linear(duration: 1), value: progress)

                VStack(spacing: ICareSpacing.sm) {
                    Text(statusLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ICareColors.textTertiary)
                        .tracking(1.5)

                    Text(countdownString(seconds: remaining))
                        .font(.system(size: 52, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(ICareColors.textPrimary)
                        .contentTransition(.numericText())
                        .animation(ICareAnimation.countdown, value: remaining)

                    Text(nextBreakLabel(at: context.date))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(ICareColors.textSecondary)
                }
            }
        }
    }

    private var doneForTodayRing: some View {
        ZStack {
            ProgressRing(
                progress: 1.0,
                size: ringSize,
                trackWidth: ringWidth,
                fillWidth: ringWidth,
                trackColor: ICareColors.separator,
                fillColor: ICareColors.brand
            )

            VStack(spacing: ICareSpacing.sm) {
                Text("DONE FOR TODAY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ICareColors.brand)
                    .tracking(1.5)

                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(ICareColors.brand)

                Text(resumesLabel)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(ICareColors.textSecondary)
            }
        }
    }

    // MARK: - Labels

    private var statusLabel: String {
        appState.focusFilterState.overrideActive ? "FOCUS MODE ACTIVE" : "REMINDERS ACTIVE"
    }

    private var resumesLabel: String {
        guard let next = appState.runtimeState.nextReminderAt else { return "" }
        let formatter = DateFormatter()
        if Calendar.current.isDateInTomorrow(next) {
            formatter.dateFormat = "H:mm"
            return "Resumes tomorrow at \(formatter.string(from: next))"
        }
        formatter.dateFormat = "EEEE 'at' H:mm"
        return "Resumes \(formatter.string(from: next))"
    }

    // MARK: - Time Helpers

    private func countdownString(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func nextBreakLabel(at date: Date) -> String {
        guard let next = appState.runtimeState.nextReminderAt else { return "Scheduling..." }
        if next.timeIntervalSince(date) <= 0 { return "Break time" }
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "Next break at \(formatter.string(from: next))"
    }

    private func secondsRemaining(at date: Date) -> Int {
        guard let next = appState.runtimeState.nextReminderAt else { return 0 }
        return max(0, Int(next.timeIntervalSince(date)))
    }

    private func intervalProgress(at date: Date) -> Double {
        guard let next = appState.runtimeState.nextReminderAt else { return 0 }
        let totalInterval = Double(appState.effectiveIntervalMinutes * 60)
        guard totalInterval > 0 else { return 0 }
        let remaining = next.timeIntervalSince(date)
        if remaining <= 0 { return 1 }
        return 1.0 - (remaining / totalInterval)
    }
}

// MARK: - Active Buttons

struct HomeActiveButtons: View {
    @EnvironmentObject private var appState: AppState
    var onStartBreak: (() -> Void)?

    private var isOutsideActiveHours: Bool {
        guard let next = appState.runtimeState.nextReminderAt else { return false }
        let remaining = next.timeIntervalSinceNow
        let intervalSeconds = Double(appState.effectiveIntervalMinutes * 60)
        return remaining > intervalSeconds * 1.5
    }

    var body: some View {
        VStack(spacing: ICareSpacing.base) {
            if !isOutsideActiveHours {
                Button(action: { onStartBreak?() }) {
                    HStack(spacing: ICareSpacing.sm) {
                        Image(systemName: "eye")
                            .font(.system(size: 14, weight: .medium))
                        Text("Start Break")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(ICareColors.brand)
                    .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: ICareSpacing.sm) {
                if !isOutsideActiveHours {
                    Button(action: { appState.resetTimer() }) {
                        HStack(spacing: ICareSpacing.xs) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .medium))
                            Text("Reset")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ICareColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(ICareColors.separator.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }

                Button(action: { appState.pause() }) {
                    HStack(spacing: ICareSpacing.xs) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 11))
                        Text("Pause")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ICareColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(ICareColors.separator.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
