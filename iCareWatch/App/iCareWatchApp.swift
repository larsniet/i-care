import Communicator
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
                    appState.notificationCoordinator.isAppInForeground = true
                    WatchSyncManager.shared.requestSync()
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: WKApplication.didEnterBackgroundNotification
                    )
                ) { _ in
                    appState.notificationCoordinator.isAppInForeground = false
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

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                Communicator.shared.task = connectivityTask
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                WatchSyncManager.shared.requestSync()
                refreshTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}

extension WatchAppDelegate {
    static func scheduleBackgroundRefresh(before date: Date) {
        let refreshDate = date.addingTimeInterval(-60)
        guard refreshDate.timeIntervalSinceNow > 10 else { return }
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: refreshDate,
            userInfo: nil
        ) { _ in }
    }
}
