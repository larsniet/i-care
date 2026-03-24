import SwiftUI

@main
struct iCareWatchApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(appState)
        }
    }
}
