import SwiftUI

struct HomeActiveContent: View {
    @EnvironmentObject private var appState: AppState
    var onStartBreak: (() -> Void)?

    var body: some View {
        VStack(spacing: ICareSpacing.xl) {
            StatusBadge(status: .active)

            VStack(spacing: ICareSpacing.xs) {
                Text("Next break in")
                    .font(ICareTypography.caption)
                    .foregroundStyle(ICareColors.textSecondary)

                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Group {
                        if let minutes = minutesRemaining(referenceDate: context.date) {
                            Text(minutes == 1 ? "1 min" : "\(minutes) min")
                                .font(ICareTypography.displaySmall)
                                .foregroundStyle(ICareColors.textPrimary)
                        } else {
                            Text("Scheduling...")
                                .font(ICareTypography.displaySmall)
                                .foregroundStyle(ICareColors.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .multilineTextAlignment(.center)

            Text(breaksTodayLabel)
                .font(ICareTypography.body)
                .foregroundStyle(ICareColors.textSecondary)

            SecondaryButton(title: "Pause") {
                appState.pause()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ICareSpacing.base)
    }

    private var breaksTodayLabel: String {
        let n = appState.todaySummary.completedBreakCount
        return n == 1 ? "1 break today" : "\(n) breaks today"
    }

    private func minutesRemaining(referenceDate: Date) -> Int? {
        guard let next = appState.runtimeState.nextReminderAt else { return nil }
        let interval = next.timeIntervalSince(referenceDate)
        if interval <= 0 { return 0 }
        return Int(ceil(interval / 60))
    }
}
