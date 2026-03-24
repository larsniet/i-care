import WatchKit
import SwiftUI
import UserNotifications

final class NotificationController: WKUserNotificationHostingController<WatchNotificationBody> {

    private let appState = AppState()

    override var body: WatchNotificationBody {
        WatchNotificationBody(appState: appState)
    }

    override func didReceive(_ notification: UNNotification) {
        if appState.settings.hapticsEnabled {
            WKInterfaceDevice.current().play(.notification)
        }
    }
}

struct WatchNotificationBody: View {
    @ObservedObject var appState: AppState
    @State private var showCountdown = false

    var body: some View {
        NavigationStack {
            VStack(spacing: ICareSpacing.sm) {
                Text("Time for a break")
                    .font(ICareTypography.headline)
                    .foregroundStyle(ICareColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Look away for 20 seconds")
                    .font(ICareTypography.body)
                    .foregroundStyle(ICareColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)

                Button {
                    appState.startBreak()
                    showCountdown = true
                } label: {
                    Text("Start")
                        .font(ICareTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ICareSpacing.md)
                        .background(ICareColors.brand)
                        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
                }
                .buttonStyle(.plain)

                Button {
                    appState.snooze()
                } label: {
                    Text("Snooze")
                        .font(ICareTypography.headline)
                        .foregroundStyle(ICareColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, ICareSpacing.md)
            .padding(.vertical, ICareSpacing.sm)
            .background(ICareColors.surface)
            .navigationDestination(isPresented: $showCountdown) {
                WatchCountdownView()
                    .environmentObject(appState)
            }
        }
    }
}
