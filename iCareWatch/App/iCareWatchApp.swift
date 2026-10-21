import SwiftUI
import WatchConnectivity
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
                    Task { await appState.refreshNotificationStatus() }
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

    // Communicator.shared.task completes its task but never clears it, so a second
    // sync completed it twice and a replaced task was freed uncompleted (both crash).
    // We own connectivity tasks instead and complete each exactly once.
    private var connectivityTasks: [WKWatchConnectivityRefreshBackgroundTask] = []

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                connectivityTasks.append(connectivityTask)
                completeConnectivityTasksWhenIdle()
            case let refreshTask as WKApplicationRefreshBackgroundTask:
                WatchSyncManager.shared.requestSync()
                refreshTask.setTaskCompletedWithSnapshot(false)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    /// Gives WatchConnectivity time to deliver pending data, then completes every held task.
    private func completeConnectivityTasksWhenIdle(attempt: Int = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self, !self.connectivityTasks.isEmpty else { return }
            if WCSession.default.hasContentPending && attempt < 10 {
                self.completeConnectivityTasksWhenIdle(attempt: attempt + 1)
                return
            }
            let tasks = self.connectivityTasks
            self.connectivityTasks.removeAll()
            tasks.forEach { $0.setTaskCompletedWithSnapshot(false) }
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
