import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showCountdown = false

    var body: some View {
        NavigationStack {
            ZStack {
                ICareColors.surface.ignoresSafeArea()

                Group {
                    switch appState.currentStatus {
                    case .active:
                        HomeActiveContent(onStartBreak: { showCountdown = true })
                    case .paused:
                        HomePausedContent()
                    case .blocked:
                        HomeBlockedContent()
                    case .inactive:
                        HomeInactiveContent()
                    }
                }
                .animation(ICareAnimation.stateChange, value: appState.currentStatus)
            }
            .navigationTitle("i care")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(ICareColors.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showCountdown) {
                CountdownView()
                    .environmentObject(appState)
            }
            .onReceive(appState.$pendingAction) { action in
                guard let action else { return }
                appState.pendingAction = nil
                switch action {
                case .startBreak:
                    showCountdown = true
                case .snooze, .skip:
                    break
                }
            }
        }
    }
}

private struct HomeInactiveContent: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: ICareSpacing.xl) {
            StatusBadge(status: .inactive)

            Text("Reminders off")
                .font(ICareTypography.title)
                .foregroundStyle(ICareColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Enable reminders when you want gentle break nudges.")
                .font(ICareTypography.body)
                .foregroundStyle(ICareColors.textSecondary)
                .multilineTextAlignment(.center)

            PrimaryButton(title: "Turn on reminders") {
                appState.settings.remindersEnabled = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ICareSpacing.base)
    }
}
