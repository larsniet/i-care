import SwiftUI

struct HomeInactiveRing: View {
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
            .opacity(0.3)

            VStack(spacing: ICareSpacing.sm) {
                Text("INACTIVE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ICareColors.textTertiary)
                    .tracking(1.5)

                Image(systemName: "moon.zzz")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(ICareColors.textTertiary)

                Text("Reminders are turned off")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(ICareColors.textSecondary)
            }
        }
    }
}

// MARK: - Inactive Buttons

struct HomeInactiveButtons: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button(action: { appState.settings.remindersEnabled = true }) {
            HStack(spacing: ICareSpacing.sm) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                Text("Turn On Reminders")
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
