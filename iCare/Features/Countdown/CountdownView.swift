import AudioToolbox
import SwiftUI
import UIKit

struct CountdownView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var remainingSeconds: Int = 0
    @State private var totalSeconds: Int = 1
    @State private var isRunning = true
    @State private var isComplete = false
    @State private var didLoadDuration = false

    private let hapticEngine = UINotificationFeedbackGenerator()

    private var progress: Double {
        1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    var body: some View {
        ZStack {
            ICareColors.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                if didLoadDuration {
                    if isComplete {
                        VStack(spacing: ICareSpacing.lg) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(ICareColors.brand)

                            Text("Break complete")
                                .font(ICareTypography.title)
                                .foregroundStyle(ICareColors.textPrimary)
                        }
                    } else {
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

                                Text("\(remainingSeconds)")
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
                    }
                }

                Spacer()

                if didLoadDuration, !isComplete {
                    SecondaryButton(title: "Skip") {
                        isRunning = false
                        appState.breakStartedAt = nil
                        appState.completeBreak(type: .skipped)
                        dismiss()
                    }
                    .padding(.bottom, ICareSpacing.xl)
                }
            }
        }
        .onAppear {
            guard !didLoadDuration else { return }
            let duration = max(appState.settings.breakDurationSeconds, 1)
            totalSeconds = duration
            if let started = appState.breakStartedAt {
                let elapsed = Int(Date().timeIntervalSince(started))
                remainingSeconds = max(0, duration - elapsed)
            } else {
                remainingSeconds = duration
            }
            didLoadDuration = true
            if appState.settings.hapticsEnabled {
                hapticEngine.prepare()
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard didLoadDuration, isRunning, !isComplete else { return }
            guard remainingSeconds > 0 else { return }
            remainingSeconds -= 1
            if remainingSeconds == 0 {
                isRunning = false
                isComplete = true
                if appState.settings.hapticsEnabled {
                    hapticEngine.notificationOccurred(.success)
                }
                if appState.settings.soundEnabled {
                    AudioServicesPlaySystemSound(1025)
                }
                appState.breakStartedAt = nil
                appState.completeBreak(type: .completed)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}
