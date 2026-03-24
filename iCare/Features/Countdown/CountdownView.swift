import AudioToolbox
import SwiftUI
import UIKit

struct CountdownView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var isComplete = false
    @State private var didStart = false
    @State private var endDate: Date?
    @State private var duration: Int = 20

    private let notificationHaptic = UINotificationFeedbackGenerator()
    private let impactHaptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        ZStack {
            ICareColors.surface.ignoresSafeArea()

            if isComplete {
                completedContent
            } else if let endDate {
                TimelineView(.periodic(from: .distantPast, by: 1)) { context in
                    let remaining = max(0, Int(endDate.timeIntervalSince(context.date)))
                    let progress = 1.0 - (Double(remaining) / Double(max(1, duration)))

                    countdownContent(remaining: remaining, progress: progress)
                        .onChange(of: remaining) { _, newValue in
                            if newValue <= 0 && !isComplete {
                                finishBreak(type: .completed)
                            }
                        }
                }
            }
        }
        .onAppear {
            guard !didStart else { return }
            didStart = true
            appState.notificationCoordinator.isShowingCountdown = true
            duration = max(1, appState.settings.breakDurationSeconds)
            if let started = appState.breakStartedAt {
                endDate = started.addingTimeInterval(Double(duration))
            } else {
                let now = Date()
                endDate = now.addingTimeInterval(Double(duration))
            }
            if appState.settings.hapticsEnabled {
                notificationHaptic.prepare()
                impactHaptic.prepare()
                impactHaptic.impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [impactHaptic] in
                    impactHaptic.impactOccurred()
                }
            }
        }
        .onDisappear {
            appState.notificationCoordinator.isShowingCountdown = false
        }
        .onChange(of: appState.breakStartedAt) { _, newValue in
            if newValue == nil && !isComplete {
                dismiss()
            }
        }
    }

    private func countdownContent(remaining: Int, progress: Double) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: ICareSpacing.lg) {
                ZStack {
                    ProgressRing(
                        progress: progress,
                        size: 200,
                        trackWidth: 2,
                        fillWidth: 3,
                        trackColor: ICareColors.brandMuted,
                        fillColor: ICareColors.brand
                    )
                    .animation(ICareAnimation.countdown, value: progress)

                    Text("\(remaining)")
                        .font(ICareTypography.displayLarge)
                        .foregroundStyle(ICareColors.textPrimary)
                        .contentTransition(.numericText())
                }

                Text("Look at something in the distance")
                    .font(ICareTypography.body)
                    .foregroundStyle(ICareColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ICareSpacing.xl)
            }

            Spacer()

            SecondaryButton(title: "Skip") {
                finishBreak(type: .skipped)
            }
            .padding(.bottom, ICareSpacing.xl)
        }
    }

    private var completedContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: ICareSpacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(ICareColors.brand)

                Text("Break complete")
                    .font(ICareTypography.title)
                    .foregroundStyle(ICareColors.textPrimary)
            }

            Spacer()
        }
    }

    private func finishBreak(type: BreakCompletionType) {
        guard !isComplete || type == .skipped else { return }

        if type == .completed, let endDate {
            let wallClockRemaining = endDate.timeIntervalSince(Date())
            if wallClockRemaining > 1.5 { return }
        }

        isComplete = true

        if type == .completed {
            if appState.settings.hapticsEnabled {
                notificationHaptic.notificationOccurred(.success)
            }
            if appState.settings.soundEnabled {
                AudioServicesPlaySystemSound(1025)
            }
        }

        appState.endBreak(type: type, device: .iphone)

        DispatchQueue.main.asyncAfter(deadline: .now() + (type == .completed ? 1.5 : 0)) {
            dismiss()
        }
    }
}
