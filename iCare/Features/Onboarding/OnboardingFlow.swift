import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentStep = 0
    @State private var goingForward = true
    @GestureState private var dragOffset: CGFloat = 0

    private let totalSteps = 4
    private var displayStep: Int { currentStep + 1 }
    private var lastStep: Int { totalSteps - 1 }

    private var canSwipeForward: Bool { currentStep < lastStep }
    private var canSwipeBack: Bool { currentStep > 0 }

    var body: some View {
        ZStack(alignment: .top) {
            onboardingBackground

            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    HStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                        Text("iCare")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(ICareColors.brand)
                    }

                    Spacer()

                    Text("STEP \(displayStep) OF \(totalSteps)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ICareColors.textTertiary)
                        .tracking(1.5)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, ICareSpacing.lg)
                .padding(.top, ICareSpacing.base)
                .padding(.bottom, ICareSpacing.lg)
                .zIndex(1)

                // MARK: - Step Content
                ZStack {
                    Group {
                        switch currentStep {
                        case 0: WelcomeStep()
                        case 1: ScheduleSetupStep()
                        case 2: FocusModeStep()
                        default: NotificationStep()
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: goingForward ? .trailing : .leading),
                            removal: .move(edge: goingForward ? .leading : .trailing)
                        )
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: dragOffset)
                .gesture(swipeGesture)

                // MARK: - Buttons
                buttonArea
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Button Area

    @ViewBuilder
    private var buttonArea: some View {
        VStack(spacing: 0) {
            switch currentStep {
            case 0:
                primaryButton("Get Started", icon: "arrow.right") { goTo(1) }
                backButton { }.hidden()

            case 1:
                primaryButton("Continue", icon: "arrow.right") { goTo(2) }
                backButton { goTo(0) }

            case 2:
                primaryButton("Continue", icon: "arrow.right") { goTo(3) }
                backButton { goTo(1) }

            default:
                primaryButton("Enable Notifications", icon: "bell.fill") { requestNotifications() }
                backButton("Skip for now") { skipNotifications() }
            }
        }
        .padding(.horizontal, ICareSpacing.lg)
        .padding(.top, ICareSpacing.base)
        .padding(.bottom, 10)
        .animation(.none, value: currentStep)
    }

    private func primaryButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: ICareSpacing.sm) {
                Text(title)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
            }
            .font(ICareTypography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(ICareColors.brand)
            .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
        }
        .buttonStyle(OnboardingButtonStyle())
    }

    private func backButton(_ label: String = "Back", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(ICareTypography.headline)
                .foregroundStyle(ICareColors.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
    }

    // MARK: - Notification Actions

    private func requestNotifications() {
        Task {
            _ = await appState.notificationCoordinator.requestAuthorization()
            await appState.refreshNotificationStatus()
            finishOnboarding()
        }
    }

    private func skipNotifications() {
        Task {
            await appState.refreshNotificationStatus()
            finishOnboarding()
        }
    }

    @MainActor
    private func finishOnboarding() {
        appState.hasCompletedOnboarding = true
        appState.settings.remindersEnabled = true
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .updating($dragOffset) { value, state, _ in
                let h = value.translation.width
                let goingLeft = h < 0
                let goingRight = h > 0

                if goingLeft && !canSwipeForward { return }
                if goingRight && !canSwipeBack { return }

                state = h * 0.3
            }
            .onEnded { value in
                let threshold: CGFloat = 50
                let h = value.translation.width

                if h < -threshold && canSwipeForward {
                    goTo(currentStep + 1)
                } else if h > threshold && canSwipeBack {
                    goTo(currentStep - 1)
                }
            }
    }

    private func goTo(_ step: Int) {
        goingForward = step > currentStep
        withAnimation(ICareAnimation.standard) {
            currentStep = step
        }
    }
}

private struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(ICareAnimation.standard, value: configuration.isPressed)
    }
}
