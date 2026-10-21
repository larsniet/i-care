import SwiftUI
import UIKit

struct HomeBlockedRing: View {
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
                fillColor: ICareColors.statusBlocked
            )
            .opacity(0.3)

            VStack(spacing: ICareSpacing.sm) {
                Text("NOTIFICATIONS OFF")
                    .scaledFont(size: 11, weight: .semibold)
                    .foregroundStyle(ICareColors.statusBlocked)
                    .tracking(1.5)

                Image(systemName: "bell.slash")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundStyle(ICareColors.statusBlocked.opacity(0.6))

                Text("Enable notifications to\nreceive break reminders")
                    .scaledFont(size: 15, weight: .regular)
                    .foregroundStyle(ICareColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Blocked Buttons

struct HomeBlockedButtons: View {
    @EnvironmentObject private var appState: AppState

    // Skipping permission in onboarding leaves no Notifications row in iOS Settings,
    // so ask directly until iOS has an answer.
    private var canAskDirectly: Bool {
        appState.notificationAuthorizationStatus == .notDetermined
    }

    var body: some View {
        Button {
            if canAskDirectly {
                Task { await appState.requestNotificationPermission() }
            } else if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: ICareSpacing.sm) {
                Image(systemName: canAskDirectly ? "bell.fill" : "gear")
                    .scaledFont(size: 14)
                Text(canAskDirectly ? "Enable Notifications" : "Open Settings")
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
