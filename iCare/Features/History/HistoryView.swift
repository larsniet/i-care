import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ZStack {
                ICareColors.surface.ignoresSafeArea()

                VStack(spacing: ICareSpacing.lg) {
                    Spacer()

                    todayCard

                    VStack(spacing: ICareSpacing.sm) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(ICareColors.textTertiary)

                        Text("Detailed history coming soon")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(ICareColors.textSecondary)

                        Text("Your break stats will appear here\nover time.")
                            .font(.system(size: 13))
                            .foregroundStyle(ICareColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                    Spacer()
                }
                .padding(.horizontal, ICareSpacing.lg)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var todayCard: some View {
        VStack(spacing: ICareSpacing.base) {
            HStack {
                Text("Today")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ICareColors.textPrimary)
                Spacer()
                Text(todayDateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ICareColors.textTertiary)
            }

            HStack(spacing: ICareSpacing.base) {
                statBlock(
                    value: "\(appState.todaySummary.completedBreakCount)",
                    label: "Completed",
                    color: ICareColors.brand
                )
                statBlock(
                    value: "\(appState.todaySummary.skippedBreakCount)",
                    label: "Skipped",
                    color: ICareColors.statusPaused
                )
            }
        }
        .padding(ICareSpacing.base)
        .background(ICareColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
    }

    private func statBlock(value: String, label: String, color: Color) -> some View {
        VStack(spacing: ICareSpacing.xs) {
            Text(value)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ICareColors.textTertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ICareSpacing.md)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }
}
