import SwiftUI

struct HomePausedRing: View {
    let ringSize: CGFloat
    let ringWidth: CGFloat

    var body: some View {
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
    }
}

// MARK: - Paused Buttons

struct HomePausedButtons: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
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
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
