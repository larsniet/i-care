import SwiftUI
import WatchKit

struct WatchCountdownView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Binding var isPresented: Bool

    @State private var isComplete = false
    @State private var didPlayStartHaptic = false
    @State private var endDate: Date?
    @State private var duration: Int = 20
    @State private var isBoundToActiveBreak = false

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
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }

                        Spacer(minLength: 0)

                        Button("Dismiss") {
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
            appState.notificationCoordinator.isShowingCountdown = true
            guard let started = appState.breakStartedAt else {
                isPresented = false
                return
            }
            let computedEndDate = started.addingTimeInterval(Double(duration))
            guard computedEndDate.timeIntervalSinceNow > 0 else {
                isPresented = false
                return
            }
            isBoundToActiveBreak = true
            endDate = computedEndDate
            if !didPlayStartHaptic && appState.settings.hapticsEnabled {
                didPlayStartHaptic = true
                WKInterfaceDevice.current().play(.click)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    WKInterfaceDevice.current().play(.click)
                }
            }
        }
        // Finishing only on the number reaching 0 missed the end whenever the screen
        // wasn't redrawing (wrist down, always-on, app in the background), so the
        // countdown sat at 0 until Dismiss while the next interval was already running.
        .task(id: endDate) {
            guard let endDate else { return }
            try? await Task.sleep(for: .seconds(max(0, endDate.timeIntervalSinceNow)))
            if !Task.isCancelled { finishBreak(type: .completed) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, let endDate, endDate.timeIntervalSinceNow <= 0 {
                finishBreak(type: .completed)
            }
        }
        .onDisappear {
            appState.notificationCoordinator.isShowingCountdown = false
            if isBoundToActiveBreak && !isComplete && appState.breakStartedAt != nil {
                appState.endBreak(type: .skipped, device: .watch)
            }
        }
        .onChange(of: appState.breakStartedAt) { _, newValue in
            if newValue == nil && !isComplete {
                isPresented = false
            }
        }
    }


    private func finishBreak(type requested: BreakCompletionType) {
        // Dismissing once the time is already up still means the break was taken.
        let isPastEnd = endDate.map { $0.timeIntervalSinceNow <= 1.5 } ?? false
        let type: BreakCompletionType = requested == .skipped && isPastEnd ? .completed : requested
        guard !isComplete else { return }

        if type == .completed, let endDate {
            let wallClockRemaining = endDate.timeIntervalSince(Date())
            if wallClockRemaining > 1.5 { return }
        }

        isComplete = true

        if type == .completed && appState.settings.hapticsEnabled {
            WKInterfaceDevice.current().play(.notification)
        }

        appState.endBreak(type: type, device: .watch)

        if type == .completed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isPresented = false
            }
        } else {
            isPresented = false
        }
    }
}
