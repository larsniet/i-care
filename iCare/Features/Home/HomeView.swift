import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0
    @State private var showCountdown = false

    var body: some View {
        TabView(selection: $selectedTab) {
            focusTab
                .tabItem {
                    Image(systemName: "eye")
                    Text("Focus")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("History")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(2)
        }
        .tint(ICareColors.brand)
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

    // MARK: - Focus Tab

    private var focusTab: some View {
        ZStack(alignment: .top) {
            homeBackground

            VStack(spacing: 0) {
                homeHeader
                    .padding(.horizontal, ICareSpacing.lg)
                    .padding(.top, ICareSpacing.sm)

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
        }
    }

    // MARK: - Header

    private var homeHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                Text("icare")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ICareColors.brand)
            }

            Spacer()
        }
    }

    // MARK: - Background

    private var homeBackground: some View {
        ZStack(alignment: .top) {
            ICareColors.surface.ignoresSafeArea()

            LinearGradient(
                colors: [
                    ICareColors.brandMuted,
                    ICareColors.surface,
                ],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.45)
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Inactive Content

private struct HomeInactiveContent: View {
    @EnvironmentObject private var appState: AppState

    private let ringSize: CGFloat = 260
    private let ringWidth: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: ICareSpacing.lg)

            ZStack {
                ProgressRing(
                    progress: 0,
                    size: ringSize,
                    trackWidth: ringWidth,
                    fillWidth: ringWidth,
                    trackColor: ICareColors.separator,
                    fillColor: ICareColors.brand
                )
                .opacity(0.3)

                VStack(spacing: ICareSpacing.sm) {
                    Text("INACTIVE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ICareColors.textTertiary)
                        .tracking(1.5)

                    Image(systemName: "moon.zzz")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(ICareColors.textTertiary)

                    Text("Reminders are turned off")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(ICareColors.textSecondary)
                }
            }

            Spacer(minLength: ICareSpacing.xl)

            Button(action: { appState.settings.remindersEnabled = true }) {
                HStack(spacing: ICareSpacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                    Text("Turn On Reminders")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(ICareColors.brand)
                .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ICareSpacing.lg)
            .padding(.bottom, ICareSpacing.base)
        }
    }
}
