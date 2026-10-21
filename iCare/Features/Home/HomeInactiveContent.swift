import SwiftUI

struct HomeInactiveRing: View {
    @EnvironmentObject private var appState: AppState
    let ringSize: CGFloat
    let ringWidth: CGFloat

    var body: some View {
        ZStack {
            ProgressRing(
                progress: 0,
                size: ringSize,
                trackWidth: ringWidth,
                fillWidth: ringWidth,
                trackColor: ICareColors.ringTrack,
                fillColor: ICareColors.brand
            )
            .opacity(0.3)

            VStack(spacing: ICareSpacing.sm) {
                Text("INACTIVE")
                    .scaledFont(size: 11, weight: .semibold)
                    .foregroundStyle(ICareColors.textTertiary)
                    .tracking(1.5)

                Image(systemName: "moon.zzz")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(ICareColors.textTertiary)

                Text(appState.isTurnedOffByFocus ? "Turned off by your Focus" : "Reminders are turned off")
                    .scaledFont(size: 15, weight: .regular)
                    .foregroundStyle(ICareColors.textSecondary)
            }
        }
    }
}

// MARK: - Inactive Buttons

struct HomeInactiveButtons: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if appState.isTurnedOffByFocus {
            // The Focus wins over this setting, so a button here would do nothing.
            Text("Reminders come back when this Focus ends.")
                .font(.subheadline)
                .foregroundStyle(ICareColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
        } else {
            turnOnButton
        }
    }

    private var turnOnButton: some View {
        Button(action: { appState.settings.remindersEnabled = true }) {
            HStack(spacing: ICareSpacing.sm) {
                Image(systemName: "play.fill")
                    .scaledFont(size: 12)
                Text("Turn On Reminders")
            }
            .scaledFont(size: 16, weight: .semibold)
            .foregroundStyle(ICareColors.onBrand)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(ICareColors.brand)
            .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
