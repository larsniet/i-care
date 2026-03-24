import AudioToolbox
import SwiftUI
import UIKit

struct CountdownView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var isComplete = false
    @State private var didStart = false

    private let hapticEngine = UINotificationFeedbackGenerator()

    private var endDate: Date {
        let started = appState.breakStartedAt ?? Date()
        return started.addingTimeInterval(Double(appState.settings.breakDurationSeconds))
    }

    private var totalSeconds: Int {
        max(1, appState.settings.breakDurationSeconds)
    }

    var body: some View {
        ZStack {
            ICareColors.surface.ignoresSafeArea()

            if isComplete {
                completedContent
            } else if appState.breakStartedAt != nil {
                TimelineView(.periodic(from: .distantPast, by: 1)) { context in
                    let remaining = max(0, Int(endDate.timeIntervalSince(context.date)))
                    let progress = 1.0 - (Double(remaining) / Double(totalSeconds))

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
            if appState.settings.hapticsEnabled {
                hapticEngine.prepare()
            }
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
        isComplete = true

        if type == .completed {
            if appState.settings.hapticsEnabled {
                hapticEngine.notificationOccurred(.success)
            }
            if appState.settings.soundEnabled {
                AudioServicesPlaySystemSound(1025)
            }
        }

        #if os(iOS)
        appState.endBreak(type: type, device: .iphone)
        #endif

        DispatchQueue.main.asyncAfter(deadline: .now() + (type == .completed ? 1.5 : 0)) {
            dismiss()
        }
    }
}
