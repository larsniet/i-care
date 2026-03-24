import SwiftUI
import WatchKit

@main
struct iCareWatchApp: App {
    @StateObject private var appState = AppState()
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(appState)
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: WKApplication.willEnterForegroundNotification
                    )
                ) { _ in
                    WatchSyncManager.shared.requestContextFromPhone()
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: .iCareStartBreak)
                ) { notification in
                    guard let ts = notification.userInfo?["breakStartedAt"] as? TimeInterval else { return }
                    let started = Date(timeIntervalSince1970: ts)
                    guard appState.breakStartedAt == nil else { return }
                    let elapsed = Date().timeIntervalSince(started)
                    let duration = Double(appState.settings.breakDurationSeconds)
                    guard elapsed < duration else { return }
                    appState.breakStartedAt = started
                    let completeAt = started.addingTimeInterval(duration)
                    appState.notificationCoordinator.scheduleBreakComplete(
                        at: completeAt, soundEnabled: appState.settings.soundEnabled
                    )
                    appState.pendingAction = .startBreak
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: .iCareSnooze)
                ) { _ in
                    appState.snooze()
                }
        }

        WKNotificationScene(
            controller: NotificationController.self,
            category: NotificationCoordinator.categoryIdentifier
        )
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {}
}
