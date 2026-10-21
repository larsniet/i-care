import WatchKit
import SwiftUI
import UserNotifications

final class NotificationController: WKUserNotificationHostingController<WatchNotificationBody> {

    override var body: WatchNotificationBody {
        WatchNotificationBody()
    }

    override func didReceive(_ notification: UNNotification) {
        let settings = SettingsStore.loadSettings()
        if settings.hapticsEnabled {
            WKInterfaceDevice.current().play(.notification)
        }
    }
}

struct WatchNotificationBody: View {

    var body: some View {
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
        }
        .padding(.horizontal, ICareSpacing.md)
        .padding(.vertical, ICareSpacing.sm)
        .background(ICareColors.surface)
    }
}
