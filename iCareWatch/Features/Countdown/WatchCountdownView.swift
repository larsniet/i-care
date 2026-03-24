import Combine
import SwiftUI

struct WatchCountdownView: View {
    let breakDurationSeconds: Int
    var onComplete: ((BreakCompletionType) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var remaining: Int
    @State private var isComplete = false
    @State private var timerCancellable: AnyCancellable?

    init(breakDurationSeconds: Int, onComplete: ((BreakCompletionType) -> Void)? = nil) {
        self.breakDurationSeconds = max(1, breakDurationSeconds)
        self.onComplete = onComplete
        _remaining = State(initialValue: max(1, breakDurationSeconds))
    }

    var body: some View {
        ZStack {
            ICareColors.surface.ignoresSafeArea()

            VStack(spacing: ICareSpacing.md) {
                Spacer(minLength: 0)

                ZStack {
                    ProgressRing(
                        progress: ringProgress,
                        size: 120
                    )

                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(ICareColors.brand)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("\(remaining)")
                            .font(.system(size: 34, weight: .light, design: .monospaced))
                            .foregroundStyle(ICareColors.textPrimary)
                            .contentTransition(.numericText())
                            .animation(ICareAnimation.countdown, value: remaining)
                    }
                }
                .animation(ICareAnimation.stateChange, value: isComplete)

                Spacer(minLength: 0)

                if !isComplete {
                    Button("Skip") {
                        stopTimer()
                        onComplete?(.skipped)
                        dismiss()
                    }
                    .font(ICareTypography.caption)
                    .foregroundStyle(ICareColors.textSecondary)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ICareSpacing.base)
            .padding(.bottom, ICareSpacing.sm)
        }
        .onAppear(perform: startTimerIfNeeded)
        .onDisappear(perform: stopTimer)
        .onChange(of: isComplete) { _, complete in
            guard complete else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }

    private var ringProgress: Double {
        guard breakDurationSeconds > 0 else { return 0 }
        if isComplete { return 1 }
        return Double(remaining) / Double(breakDurationSeconds)
    }

    private func startTimerIfNeeded() {
        guard !isComplete else { return }
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if remaining <= 1 {
                    remaining = 0
                    stopTimer()
                    isComplete = true
                    onComplete?(.completed)
                } else {
                    remaining -= 1
                }
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
