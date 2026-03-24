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

            Button {
                let now = Date()
                NotificationCenter.default.post(
                    name: .iCareStartBreak,
                    object: nil,
                    userInfo: ["breakStartedAt": now.timeIntervalSince1970]
                )
                WatchSyncManager.shared.sendCommand("startBreak", payload: [
                    "breakStartedAt": now.timeIntervalSince1970
                ])
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
                NotificationCenter.default.post(name: .iCareSnooze, object: nil)
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
    }
}

extension Notification.Name {
    static let iCareStartBreak = Notification.Name("icare.action.startBreak")
    static let iCareSnooze = Notification.Name("icare.action.snooze")
}
