import SwiftUI
import WatchKit

struct WatchCountdownView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isPresented: Bool

    @State private var isComplete = false
    @State private var didPlayStartHaptic = false
    @State private var endDate: Date?
    @State private var duration: Int = 20

    var body: some View {
        ZStack {
            ICareColors.surface.ignoresSafeArea()

            if let endDate {
                TimelineView(.periodic(from: .distantPast, by: 1)) { context in
                    let remaining = max(0, Int(endDate.timeIntervalSince(context.date)))
                    let progress = isComplete ? 1.0 : 1.0 - (Double(remaining) / Double(max(1, duration)))

                    VStack(spacing: ICareSpacing.md) {
                        Spacer(minLength: 0)

                        ZStack {
                            ProgressRing(
                                progress: progress,
                                size: 120
                            )

                            if isComplete {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(ICareColors.brand)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text("\(remaining)")
                                    .font(.system(size: 34, weight: .light, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(ICareColors.textPrimary)
                                    .contentTransition(.numericText())
                                    .animation(ICareAnimation.countdown, value: remaining)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }

                        Spacer(minLength: 0)

                        Button("Skip") {
                            finishBreak(type: .skipped)
                        }
                        .font(ICareTypography.caption)
                        .foregroundStyle(ICareColors.textSecondary)
                        .buttonStyle(.plain)
                        .opacity(isComplete ? 0 : 1)
                        .animation(.easeInOut(duration: 0.3), value: isComplete)
                    }
                    .padding(.horizontal, ICareSpacing.base)
                    .padding(.bottom, ICareSpacing.sm)
                    .onChange(of: remaining) { _, newValue in
                        if newValue <= 0 && !isComplete {
                            finishBreak(type: .completed)
                        }
                    }
                }
            }
        }
        
        .onAppear {
            guard endDate == nil else { return }
            duration = max(1, appState.settings.breakDurationSeconds)
            if let started = appState.breakStartedAt {
                endDate = started.addingTimeInterval(Double(duration))
            } else {
                let now = Date()
                endDate = now.addingTimeInterval(Double(duration))
            }
            if !didPlayStartHaptic && appState.settings.hapticsEnabled {
                didPlayStartHaptic = true
                WKInterfaceDevice.current().play(.click)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    WKInterfaceDevice.current().play(.click)
                }
            }
        }
        .onDisappear {
            if !isComplete && appState.breakStartedAt != nil {
                appState.endBreak(type: .skipped, device: .watch)
            }
        }
        .onChange(of: isComplete) { _, complete in
            guard complete else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isPresented = false
            }
        }
        .onChange(of: appState.breakStartedAt) { _, newValue in
            if newValue == nil && !isComplete {
                isPresented = false
            }
        }
    }


    private func finishBreak(type: BreakCompletionType) {
        guard !isComplete || type == .skipped else { return }

        if type == .completed, let endDate {
            let wallClockRemaining = endDate.timeIntervalSince(Date())
            if wallClockRemaining > 1.5 { return }
        }

        isComplete = true

        if type == .completed && appState.settings.hapticsEnabled {
            WKInterfaceDevice.current().play(.stop)
        }

        appState.endBreak(type: type, device: .watch)
    }
}
