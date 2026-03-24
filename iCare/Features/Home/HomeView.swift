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
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            guard let started = appState.breakStartedAt, !showCountdown else { return }
            let elapsed = Date().timeIntervalSince(started)
            let duration = Double(appState.settings.breakDurationSeconds)
            if elapsed < duration {
                showCountdown = true
            } else {
                appState.breakStartedAt = nil
            }
        }
        .onChange(of: appState.breakStartedAt) { _, newValue in
            if newValue != nil && !showCountdown {
                showCountdown = true
            }
        }
    }

    // MARK: - Focus Tab

    private let ringSize: CGFloat = 260
    private let ringWidth: CGFloat = 8

    private var focusTab: some View {
        ZStack(alignment: .top) {
            homeBackground

            VStack(spacing: 0) {
                homeHeader
                    .padding(.horizontal, ICareSpacing.lg)
                    .padding(.top, ICareSpacing.base)

                focusDashboard
            }
        }
    }

    private var focusDashboard: some View {
        GeometryReader { geo in
            let buttonAreaHeight: CGFloat = 180
            let ringCenterY = (geo.size.height - buttonAreaHeight) / 2

            ZStack(alignment: .top) {
                ringView
                    .frame(width: geo.size.width, height: ringSize)
                    .position(x: geo.size.width / 2, y: ringCenterY)

                VStack(spacing: ICareSpacing.base) {
                    if appState.currentStatus == .active || appState.currentStatus == .paused {
                        breaksCard
                            .padding(.horizontal, ICareSpacing.lg)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    bottomButtons
                        .padding(.horizontal, ICareSpacing.lg)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, ICareSpacing.base)
            }
            .animation(.easeInOut(duration: 0.35), value: appState.currentStatus)
        }
    }

    @ViewBuilder
    private var ringView: some View {
        switch appState.currentStatus {
        case .active:
            HomeActiveRing(ringSize: ringSize, ringWidth: ringWidth)
        case .paused:
            HomePausedRing(ringSize: ringSize, ringWidth: ringWidth)
        case .blocked:
            HomeBlockedRing(ringSize: ringSize, ringWidth: ringWidth)
        case .inactive:
            HomeInactiveRing(ringSize: ringSize, ringWidth: ringWidth)
        }
    }

    @ViewBuilder
    private var bottomButtons: some View {
        switch appState.currentStatus {
        case .active:
            HomeActiveButtons(onStartBreak: {
                appState.startBreak()
                showCountdown = true
            })
        case .paused:
            HomePausedButtons()
        case .blocked:
            HomeBlockedButtons()
        case .inactive:
            HomeInactiveButtons()
        }
    }

    private var breaksCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.todaySummary.completedBreakCount == 1
                     ? "1 break" : "\(appState.todaySummary.completedBreakCount) breaks")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ICareColors.textPrimary)
                Text("COMPLETED TODAY")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ICareColors.textTertiary)
                    .tracking(1)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(ICareColors.brandMuted, ICareColors.brand.opacity(0.15))
                .symbolRenderingMode(.palette)
        }
        .padding(ICareSpacing.base)
        .background(ICareColors.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
    }

    // MARK: - Header

    private var homeHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
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

