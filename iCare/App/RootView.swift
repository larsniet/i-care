import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingFlow()
            }
        }
        .animation(ICareAnimation.stateChange, value: appState.hasCompletedOnboarding)
    }
}
