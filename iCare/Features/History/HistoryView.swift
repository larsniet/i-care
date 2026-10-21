import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var todayRecords: [BreakRecord] = []

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground

            ScrollView {
                VStack(spacing: ICareSpacing.lg) {
                    pageHeader
                    todayCard

                    if todayRecords.isEmpty {
                        emptyState
                    } else {
                        recordsList
                    }
                }
                .padding(.horizontal, ICareSpacing.lg)
                .padding(.top, ICareSpacing.base)
                .padding(.bottom, ICareSpacing.xl)
                .readableWidth()
            }
        }
        .onAppear { todayRecords = CompletionTracker.loadTodayRecords() }
        .onChange(of: appState.todaySummary) { _, _ in
            todayRecords = CompletionTracker.loadTodayRecords()
        }
    }

    // MARK: - Header & Background

    private var pageHeader: some View {
        HStack {
            Text("History")
                .scaledFont(size: 18, weight: .semibold)
                .foregroundStyle(ICareColors.textPrimary)
            Spacer()
        }
    }

    private var pageBackground: some View {
        ZStack(alignment: .top) {
            ICareColors.surface.ignoresSafeArea()
            LinearGradient(
                colors: [ICareColors.brandMuted, ICareColors.surface],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.45)
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Today Card

    private var todayCard: some View {
        VStack(spacing: ICareSpacing.base) {
            HStack {
                Text("Today")
                    .scaledFont(size: 18, weight: .semibold)
                    .foregroundStyle(ICareColors.textPrimary)
                Spacer()
                Text(todayDateString)
                    .scaledFont(size: 13, weight: .medium)
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
                    label: "Dismissed",
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
                .scaledFont(size: 12, weight: .medium)
                .foregroundStyle(ICareColors.textTertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ICareSpacing.md)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: ICareSpacing.sm) {
            Image(systemName: "eye")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(ICareColors.textTertiary)

            Text("No breaks yet today")
                .scaledFont(size: 15, weight: .medium)
                .foregroundStyle(ICareColors.textSecondary)

            Text("Completed breaks will appear here.")
                .scaledFont(size: 13)
                .foregroundStyle(ICareColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ICareSpacing.xxl)
    }

    // MARK: - Records List

    private var recordsList: some View {
        VStack(alignment: .leading, spacing: ICareSpacing.sm) {
            Text("TODAY'S BREAKS")
                .scaledFont(size: 11, weight: .semibold)
                .foregroundStyle(ICareColors.textTertiary)
                .tracking(1.5)
                .padding(.leading, ICareSpacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(todayRecords.reversed().enumerated()), id: \.element.id) { index, record in
                    if index > 0 {
                        Divider()
                            .overlay(ICareColors.separator)
                            .padding(.leading, ICareSpacing.base)
                    }
                    recordRow(record)
                }
            }
            .background(ICareColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
        }
    }

    private func recordRow(_ record: BreakRecord) -> some View {
        HStack(spacing: ICareSpacing.md) {
            Image(systemName: record.completionType == .completed ? "checkmark.circle.fill" : "forward.fill")
                .scaledFont(size: 18)
                .foregroundStyle(record.completionType == .completed ? ICareColors.brand : ICareColors.statusPaused)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.completionType == .completed ? "Completed" : "Dismissed")
                    .scaledFont(size: 15, weight: .medium)
                    .foregroundStyle(ICareColors.textPrimary)
                Text(recordTimeString(record.completedAt))
                    .scaledFont(size: 13)
                    .foregroundStyle(ICareColors.textTertiary)
            }

            Spacer()

            if record.sourceDevice == .watch {
                Image(systemName: "applewatch")
                    .scaledFont(size: 14)
                    .foregroundStyle(ICareColors.textTertiary)
            }
        }
        .padding(.horizontal, ICareSpacing.base)
        .padding(.vertical, ICareSpacing.md)
    }

    // MARK: - Helpers

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }

    private func recordTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
