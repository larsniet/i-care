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
