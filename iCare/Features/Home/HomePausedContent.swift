import SwiftUI

struct HomePausedContent: View {
    @EnvironmentObject private var appState: AppState

    private let ringSize: CGFloat = 260
    private let ringWidth: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: ICareSpacing.lg)

            ZStack {
                ProgressRing(
                    progress: 0,
                    size: ringSize,
                    trackWidth: ringWidth,
                    fillWidth: ringWidth,
                    trackColor: ICareColors.separator,
                    fillColor: ICareColors.brand
                )
                .opacity(0.4)

                VStack(spacing: ICareSpacing.sm) {
                    Text("PAUSED")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ICareColors.statusPaused)
                        .tracking(1.5)

                    Image(systemName: "pause.circle")
                        .font(.system(size: 52, weight: .ultraLight))
                        .foregroundStyle(ICareColors.statusPaused)

                    Text("Reminders are paused")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(ICareColors.textSecondary)
                }
            }

            Spacer(minLength: ICareSpacing.xl)

            breaksCard
                .padding(.horizontal, ICareSpacing.lg)
                .padding(.bottom, ICareSpacing.base)

            Button(action: { appState.resume() }) {
                HStack(spacing: ICareSpacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                    Text("Resume Reminders")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(ICareColors.brand)
                .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ICareSpacing.lg)
            .padding(.bottom, ICareSpacing.base)
        }
    }

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
}
