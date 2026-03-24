import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                ICareColors.surface.ignoresSafeArea()

                if !appState.hasCompletedOnboarding {
                    setupNeededContent
                } else {
                    VStack(spacing: ICareSpacing.md) {
                        statusHeader

                        switch appState.currentStatus {
                        case .active:
                            activeContent
                        case .paused:
                            pausedContent
                        case .blocked:
                            blockedContent
                        case .inactive:
                            inactiveContent
                        }
                    }
                    .padding(.horizontal, ICareSpacing.base)
                    .padding(.vertical, ICareSpacing.md)
                }
            }
        }
    }

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
    }

    private var statusHeader: some View {
        HStack(spacing: ICareSpacing.sm) {
            Image(systemName: statusSymbolName)
                .font(.title3)
                .foregroundStyle(statusColor)
            Text(statusTitle)
                .font(ICareTypography.caption)
                .foregroundStyle(ICareColors.textSecondary)
        }
    }

    private var activeContent: some View {
        VStack(spacing: ICareSpacing.md) {
            Text(nextBreakLabel)
                .font(ICareTypography.displaySmall)
                .foregroundStyle(ICareColors.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)

            NavigationLink {
                WatchCountdownView(
                    breakDurationSeconds: appState.settings.breakDurationSeconds,
                    onComplete: { type in appState.completeBreak(type: type, device: .watch) }
                )
            } label: {
                Text("Start break")
                    .font(ICareTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ICareSpacing.base)
                    .background(ICareColors.brand)
                    .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
            }
            .buttonStyle(.plain)
        }
    }

    private var pausedContent: some View {
        VStack(spacing: ICareSpacing.md) {
            Text("Paused")
                .font(ICareTypography.title)
                .foregroundStyle(ICareColors.textPrimary)

            Button {
                appState.resume()
            } label: {
                Text("Resume")
                    .font(ICareTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ICareSpacing.base)
                    .background(ICareColors.brand)
                    .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
            }
            .buttonStyle(.plain)
        }
    }

    private var blockedContent: some View {
        VStack(spacing: ICareSpacing.sm) {
            Text("Alerts need permission on iPhone.")
                .font(ICareTypography.body)
                .foregroundStyle(ICareColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var inactiveContent: some View {
        Text("Reminders off")
            .font(ICareTypography.body)
            .foregroundStyle(ICareColors.textTertiary)
            .multilineTextAlignment(.center)
    }

    private var statusSymbolName: String {
        switch appState.currentStatus {
        case .active: "bell.fill"
        case .paused: "pause.circle.fill"
        case .blocked: "exclamationmark.triangle.fill"
        case .inactive: "bell.slash.fill"
        }
    }

    private var statusColor: Color {
        switch appState.currentStatus {
        case .active: ICareColors.brand
        case .paused: ICareColors.statusPaused
        case .blocked: ICareColors.statusBlocked
        case .inactive: ICareColors.textTertiary
        }
    }

    private var statusTitle: String {
        switch appState.currentStatus {
        case .active: "Active"
        case .paused: "Paused"
        case .blocked: "Blocked"
        case .inactive: "Off"
        }
    }

    private var nextBreakLabel: String {
        guard let date = appState.runtimeState.nextReminderAt else {
            return "Next break"
        }
        return date.formatted(date: .omitted, time: .shortened)
    }
}
