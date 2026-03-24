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
                    appState.refreshFocusFilterState()
                    Task { await appState.refreshNotificationStatus() }
                    appState.scheduleReminders()
                }
        }
    }

    #if canImport(UIKit)
    private var willEnterForegroundNotification: Notification.Name {
        UIApplication.willEnterForegroundNotification
    }
    #else
    private var willEnterForegroundNotification: Notification.Name {
        Notification.Name("WKApplicationWillEnterForegroundNotification")
    }
    #endif
}
