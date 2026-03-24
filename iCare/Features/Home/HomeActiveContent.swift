import SwiftUI

struct HomeActiveContent: View {
    @EnvironmentObject private var appState: AppState
    var onStartBreak: (() -> Void)?

    private let ringSize: CGFloat = 260
    private let ringWidth: CGFloat = 8

    private var isOutsideActiveHours: Bool {
        guard let next = appState.runtimeState.nextReminderAt else { return false }
        let remaining = next.timeIntervalSinceNow
        let intervalSeconds = Double(appState.effectiveIntervalMinutes * 60)
        return remaining > intervalSeconds * 1.5
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: ICareSpacing.lg)

            if isOutsideActiveHours {
                doneForTodayContent
            } else {
                countdownContent
            }

            Spacer(minLength: ICareSpacing.xl)

            breaksCard
                .padding(.horizontal, ICareSpacing.lg)
                .padding(.bottom, ICareSpacing.base)

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
            .padding(.horizontal, ICareSpacing.lg)
            .padding(.bottom, ICareSpacing.base)
        }
    }

    // MARK: - Countdown Content

    private var countdownContent: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
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
                        .foregroundStyle(ICareColors.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text(nextBreakLabel(at: context.date))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(ICareColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Done For Today

    private var doneForTodayContent: some View {
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

    // MARK: - Status

    private var statusLabel: String {
        if appState.focusFilterState.overrideActive {
            return "FOCUS MODE ACTIVE"
        }
        return "REMINDERS ACTIVE"
    }

    // MARK: - Breaks Card

    private var breaksCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(breakCountText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ICareColors.textPrimary)
                Text("COMPLETED TODAY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ICareColors.textTertiary)
                    .tracking(1)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(ICareColors.brandMuted, ICareColors.brand.opacity(0.15))
                .symbolRenderingMode(.palette)
        }
        .padding(ICareSpacing.base)
        .background(ICareColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
    }

    private var breakCountText: String {
        let n = appState.todaySummary.completedBreakCount
        return n == 1 ? "1 break" : "\(n) breaks"
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
