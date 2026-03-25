import SwiftUI

@main
struct iCareApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: willEnterForegroundNotification
                    )
                ) { _ in
                    appState.notificationCoordinator.isAppInForeground = true
                    appState.refreshFocusFilterState()
                    Task { await appState.refreshNotificationStatus() }
                    appState.scheduleReminders()
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: didEnterBackgroundNotification
                    )
                ) { _ in
                    appState.notificationCoordinator.isAppInForeground = false
                }
        }
    }

    #if canImport(UIKit)
    private var willEnterForegroundNotification: Notification.Name {
        UIApplication.willEnterForegroundNotification
    }
    private var didEnterBackgroundNotification: Notification.Name {
        UIApplication.didEnterBackgroundNotification
    }
    #else
    private var willEnterForegroundNotification: Notification.Name {
        Notification.Name("WKApplicationWillEnterForegroundNotification")
    }
    private var didEnterBackgroundNotification: Notification.Name {
        Notification.Name("WKApplicationDidEnterBackgroundNotification")
    }
    #endif
}
