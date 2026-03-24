import SwiftUI
import WatchKit

struct WatchCountdownView: View {
    let breakDurationSeconds: Int
    let hapticsEnabled: Bool
    let breakStartedAt: Date?
    var onComplete: ((BreakCompletionType) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var isComplete = false
    @State private var didPlayStartHaptic = false

    private var endDate: Date {
        let started = breakStartedAt ?? Date()
        return started.addingTimeInterval(Double(breakDurationSeconds))
    }

    var body: some View {
        ZStack {
            ICareColors.surface.ignoresSafeArea()

            if isComplete {
                completeContent
            } else {
                TimelineView(.periodic(from: .distantPast, by: 1)) { context in
                    let remaining = max(0, Int(endDate.timeIntervalSince(context.date)))
                    let progress = 1.0 - (Double(remaining) / Double(max(1, breakDurationSeconds)))

                    countdownContent(remaining: remaining, progress: progress)
                        .onChange(of: remaining) { _, newValue in
                            if newValue <= 0 && !isComplete {
                                isComplete = true
                                if hapticsEnabled {
                                    WKInterfaceDevice.current().play(.success)
                                }
                                onComplete?(.completed)
                            }
                        }
                }
            }
        }
        .onAppear {
            if !didPlayStartHaptic && hapticsEnabled {
                didPlayStartHaptic = true
                WKInterfaceDevice.current().play(.start)
            }
        }
        .onChange(of: isComplete) { _, complete in
            guard complete else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }

    private func countdownContent(remaining: Int, progress: Double) -> some View {
        VStack(spacing: ICareSpacing.md) {
            Spacer(minLength: 0)

            ZStack {
                ProgressRing(
                    progress: progress,
                    size: 120
                )

                Text("\(remaining)")
                    .font(.system(size: 34, weight: .light, design: .monospaced))
                    .foregroundStyle(ICareColors.textPrimary)
                    .contentTransition(.numericText())
                    .animation(ICareAnimation.countdown, value: remaining)
            }

            Spacer(minLength: 0)

            Button("Skip") {
                onComplete?(.skipped)
                dismiss()
            }
            .font(ICareTypography.caption)
            .foregroundStyle(ICareColors.textSecondary)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ICareSpacing.base)
        .padding(.bottom, ICareSpacing.sm)
    }

    private var completeContent: some View {
        VStack(spacing: ICareSpacing.md) {
            Spacer(minLength: 0)

            ZStack {
                ProgressRing(
                    progress: 1.0,
                    size: 120
                )

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(ICareColors.brand)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, ICareSpacing.base)
        .transition(.scale.combined(with: .opacity))
    }
}
