import SwiftUI
import WatchConnectivity

struct WatchHomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showCountdown = false

    var body: some View {
        NavigationStack {
            ZStack {
                ICareColors.surface.ignoresSafeArea()

                if !appState.hasCompletedOnboarding {
                    setupNeededContent
                } else if appState.currentStatus == .blocked {
                    blockedContent
                } else if appState.currentStatus == .inactive {
                    inactiveContent
                } else {
                    mainDashboard
                }
            }
            .navigationDestination(isPresented: $showCountdown) {
                WatchCountdownView(
                    breakDurationSeconds: appState.settings.breakDurationSeconds,
                    hapticsEnabled: appState.settings.hapticsEnabled,
                    breakStartedAt: appState.breakStartedAt,
                    onComplete: { type in
                        appState.breakStartedAt = nil
                        appState.completeBreak(type: type, device: .watch)
                    }
                )
            }
            .onReceive(appState.$pendingAction) { action in
                guard let action else { return }
                appState.pendingAction = nil
                if action == .startBreak {
                    showCountdown = true
                }
            }
        }
    }

    // MARK: - Setup Needed

    private var setupNeededContent: some View {
        VStack(spacing: ICareSpacing.md) {
            Spacer(minLength: 0)

            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 28))
                .foregroundStyle(ICareColors.brand)

            Text("Open icare on\nyour iPhone to\nget started.")
                .font(ICareTypography.body)
                .foregroundStyle(ICareColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, ICareSpacing.base)
        .onReceive(
            Timer.publish(every: 3, on: .main, in: .common).autoconnect()
        ) { _ in
            WatchSyncManager.shared.requestContextFromPhone()
        }
    }

    // MARK: - Active

    private var isOutsideActiveHours: Bool {
        guard let next = appState.runtimeState.nextReminderAt else { return false }
        let remaining = next.timeIntervalSinceNow
        let intervalSeconds = Double(appState.effectiveIntervalMinutes * 60)
        return remaining > intervalSeconds * 1.5
    }

    private var hasBottomButtons: Bool {
        appState.currentStatus == .active && !isOutsideActiveHours
    }

    private var mainDashboard: some View {
        GeometryReader { geo in
            let buttonAreaHeight: CGFloat = 96
            let ringCenterY = hasBottomButtons
                ? (geo.size.height - buttonAreaHeight) / 2
                : geo.size.height / 2

            ZStack(alignment: .top) {
                ringContent
                    .frame(width: geo.size.width, height: 120)
                    .position(x: geo.size.width / 2, y: ringCenterY)
                    .animation(.easeInOut(duration: 0.35), value: hasBottomButtons)

                if hasBottomButtons {
                    VStack(spacing: ICareSpacing.xs) {
                        Button {
                            appState.startBreak()
                            showCountdown = true
                        } label: {
                            Text("Start break")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, ICareSpacing.sm)
                                .background(ICareColors.brand)
                                .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: ICareSpacing.xs) {
                            Button {
                                WatchSyncManager.shared.sendCommand("reset")
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 10, weight: .medium))
                                    Text("Reset")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ICareColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, ICareSpacing.xs)
                                .background(ICareColors.separator.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.sm))
                            }
                            .buttonStyle(.plain)

                            Button {
                                WatchSyncManager.shared.sendCommand("pause")
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "pause.fill")
                                        .font(.system(size: 9))
                                    Text("Pause")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ICareColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, ICareSpacing.xs)
                                .background(ICareColors.separator.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.sm))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, ICareSpacing.base)
                    .padding(.bottom, ICareSpacing.xs)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: appState.currentStatus)
        }
    }

    @ViewBuilder
    private var ringContent: some View {
        switch appState.currentStatus {
        case .active:
            if isOutsideActiveHours {
                doneForTodayRing
            } else {
                countdownRing
            }
        case .paused:
            pausedRing
        default:
            EmptyView()
        }
    }

    private var countdownRing: some View {
        TimelineView(.periodic(from: .distantPast, by: 1)) { context in
            let remaining = secondsRemaining(at: context.date)
            let progress = intervalProgress(at: context.date)

            ZStack {
                ProgressRing(
                    progress: progress,
                    size: 120,
                    trackWidth: 4,
                    fillWidth: 4,
                    trackColor: ICareColors.separator,
                    fillColor: ICareColors.brand
                )
                .animation(.linear(duration: 1), value: progress)

                VStack(spacing: 2) {
                    Text(countdownString(seconds: remaining))
                        .font(.system(size: 28, weight: .light, design: .rounded))
                        .foregroundStyle(ICareColors.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    Text(nextBreakTimeLabel(at: context.date))
                        .font(.system(size: 10))
                        .foregroundStyle(ICareColors.textTertiary)
                }
            }
        }
    }

    private var doneForTodayRing: some View {
        ZStack {
            ProgressRing(
                progress: 1.0,
                size: 120,
                trackWidth: 4,
                fillWidth: 4,
                trackColor: ICareColors.separator,
                fillColor: ICareColors.brand
            )

            VStack(spacing: 2) {
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(ICareColors.brand)

                Text("Done")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ICareColors.brand)

                Text(resumesLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(ICareColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Paused

    private var pausedRing: some View {
        Button {
            WatchSyncManager.shared.sendCommand("resume")
        } label: {
            ZStack {
                ProgressRing(
                    progress: 0,
                    size: 120,
                    trackWidth: 4,
                    fillWidth: 4,
                    trackColor: ICareColors.separator,
                    fillColor: ICareColors.statusPaused
                )
                .opacity(0.4)

                VStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(ICareColors.brand)

                    Text("PAUSED")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(ICareColors.statusPaused)
                        .tracking(1.2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Blocked

    private var blockedContent: some View {
        VStack(spacing: ICareSpacing.md) {
            Spacer(minLength: 0)

            Image(systemName: "bell.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(ICareColors.statusBlocked.opacity(0.6))

            Text("Enable notifications\non your iPhone")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ICareColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, ICareSpacing.base)
    }

    // MARK: - Inactive

    private var inactiveContent: some View {
        VStack(spacing: ICareSpacing.md) {
            Spacer(minLength: 0)

            Image(systemName: "moon.zzz")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(ICareColors.textTertiary)

            Text("Reminders are\nturned off")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ICareColors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, ICareSpacing.base)
    }

    // MARK: - Breaks Row

    private var breaksRow: some View {
        HStack {
            Text(breakCountText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ICareColors.textPrimary)

            Spacer()

            Text("today")
                .font(.system(size: 11))
                .foregroundStyle(ICareColors.textTertiary)
        }
        .padding(.horizontal, ICareSpacing.sm)
        .padding(.vertical, ICareSpacing.xs)
        .background(ICareColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.sm))
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

    private func nextBreakTimeLabel(at date: Date) -> String {
        guard let next = appState.runtimeState.nextReminderAt else { return "" }
        if next.timeIntervalSince(date) <= 0 { return "now" }
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return "at \(formatter.string(from: next))"
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

    private var resumesLabel: String {
        guard let next = appState.runtimeState.nextReminderAt else { return "" }
        let formatter = DateFormatter()
        if Calendar.current.isDateInTomorrow(next) {
            formatter.dateFormat = "H:mm"
            return "Tomorrow \(formatter.string(from: next))"
        }
        formatter.dateFormat = "EEE H:mm"
        return formatter.string(from: next)
    }
}
