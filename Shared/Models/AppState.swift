import Combine
import Foundation
#if os(watchOS)
import WatchKit
#endif

// MARK: - Supporting Types

enum NotificationAuthorizationStatus: String, Codable, Sendable {
    case authorized
    case denied
    case notDetermined
    case provisional
}

enum ReminderStatus: Sendable, Equatable {
    case active
    case paused
    case blocked
    case inactive
}

enum NotificationAction: Sendable {
    case startBreak
    case snooze
    case dismiss
}

// MARK: - App State

@MainActor
final class AppState: ObservableObject {

    static private(set) var current: AppState?

    @Published var settings: ReminderSettings {
        didSet {
            guard !isApplyingState else { return }
            onSettingsChanged()
        }
    }
    @Published var runtimeState: ReminderRuntimeState {
        didSet { SettingsStore.save(runtimeState) }
    }
    @Published var todaySummary: DailySummary
    @Published var notificationAuthorizationStatus: NotificationAuthorizationStatus
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            SettingsStore.saveOnboardingCompleted(hasCompletedOnboarding)
            guard !isApplyingState else { return }
            commitAndPublish { state in
                self.recomputeDerivedFields(&state)
            }
        }
    }
    @Published var pendingAction: NotificationAction?
    @Published var breakStartedAt: Date?
    @Published var focusFilterState: FocusFilterState {
        didSet {
            guard !isApplyingState else { return }
            onFocusFilterChanged()
        }
    }

    let notificationCoordinator: NotificationCoordinator
    private let syncManager: WatchSyncManager
    private var isApplyingState = false
    private var hasCheckedNotificationStatus = false
    private var syncVersion: Int
    private var pendingSettingsCommitTask: Task<Void, Never>?

    // MARK: - Computed

    var effectiveRemindersEnabled: Bool {
        if focusFilterState.overrideActive {
            return focusFilterState.enableReminders
        }
        return settings.remindersEnabled
    }

    var effectiveIntervalMinutes: Int {
        if focusFilterState.overrideActive, let override = focusFilterState.intervalOverrideMinutes {
            return override
        }
        return settings.reminderIntervalMinutes
    }

    var isFullyOperational: Bool {
        effectiveRemindersEnabled
            && notificationAuthorizationStatus == .authorized
            && !runtimeState.isPaused
    }

    var currentStatus: ReminderStatus {
        if !effectiveRemindersEnabled { return .inactive }
        if runtimeState.isPaused { return .paused }
        if hasCheckedNotificationStatus && notificationAuthorizationStatus != .authorized {
            return .blocked
        }
        return .active
    }

    var isAwaitingBreakStart: Bool {
        guard currentStatus == .active else { return false }
        guard breakStartedAt == nil, let next = runtimeState.nextReminderAt else { return false }
        return next.timeIntervalSinceNow <= 0
    }

    var shouldShowSetupPrompt: Bool {
        !hasCompletedOnboarding
            && syncVersion == 0
            && syncManager.acceptedState == nil
    }

    private var currentOrigin: SyncOrigin {
        #if os(iOS)
        return .phone
        #else
        return .watch
        #endif
    }

    // MARK: - Init

    init() {
        let coordinator = NotificationCoordinator.shared
        self.notificationCoordinator = coordinator
        self.syncManager = WatchSyncManager.shared

        self.settings = SettingsStore.loadSettings()
        self.runtimeState = SettingsStore.loadRuntimeState()
        self.todaySummary = CompletionTracker.loadTodaySummary()
        self.notificationAuthorizationStatus = .notDetermined
        self.hasCompletedOnboarding = SettingsStore.loadOnboardingCompleted()
        self.focusFilterState = SettingsStore.loadFocusFilterState()
        self.syncVersion = SettingsStore.loadSyncVersion()

        coordinator.registerCategories()
        bindNotificationActions(coordinator)
        drainPendingNotificationActions()
        bindSyncManager()

        if let persisted = SettingsStore.loadSyncState() {
            var restored = persisted
            recomputeDerivedFields(&restored)
            syncManager.bootstrapAcceptedState(restored)
            applyStateLocally(restored, isRemote: false)
        }

        syncManager.activate()
        Self.current = self

        Task { [weak self] in
            guard let self else { return }
            await self.refreshNotificationStatus()
        }
    }

    // MARK: - State Transitions

    func startBreak() {
        commitAndPublish { state in
            let now = Date()
            state.phase = .break
            state.phaseStartedAt = now
            state.phaseEndsAt = now.addingTimeInterval(Double(state.settings.breakDurationSeconds))
            state.nextReminderAt = nil
        }
    }

    func endBreak(type: BreakCompletionType, device: DeviceType = .iphone) {
        guard let startedAt = breakStartedAt else { return }
        let breakEndedAt = startedAt.addingTimeInterval(Double(settings.breakDurationSeconds))
        recordBreak(
            type: type,
            device: device,
            recordID: historyRecordID(scope: "break", anchor: startedAt),
            startedAt: startedAt
        )
        commitAndPublish { state in
            state.phase = .work
            state.phaseStartedAt = nil
            state.phaseEndsAt = nil
            if type == .completed {
                let effective = self.settingsWithFocusOverrides()
                state.nextReminderAt = ReminderEngine.upcomingReminderDates(
                    after: breakEndedAt,
                    settings: effective,
                    limit: 1
                ).first
            } else {
                state.nextReminderAt = nil
            }
            self.recomputeDerivedFields(&state)
        }
    }

    func dismissReminder(device: DeviceType = .iphone) {
        let startedAt = breakStartedAt ?? runtimeState.nextReminderAt ?? Date()
        let scope = breakStartedAt != nil ? "break" : "reminder"
        recordBreak(
            type: .skipped,
            device: device,
            recordID: historyRecordID(scope: scope, anchor: startedAt),
            startedAt: startedAt
        )
        commitAndPublish { state in
            state.phase = .work
            state.phaseStartedAt = nil
            state.phaseEndsAt = nil
            state.nextReminderAt = nil
            self.recomputeDerivedFields(&state)
        }
    }

    func snooze() {
        commitAndPublish { state in
            let effective = self.settingsWithFocusOverrides()
            state.phase = .work
            state.nextReminderAt = ReminderEngine.snoozeDate(settings: effective)
        }
    }

    func pause() {
        commitAndPublish { state in
            state.isPaused = true
            state.phase = .idle
            state.nextReminderAt = nil
        }
    }

    func resume() {
        runtimeState.pausedUntil = nil
        commitAndPublish { state in
            state.isPaused = false
            state.nextReminderAt = nil
            self.recomputeDerivedFields(&state)
        }
    }

    func resetTimer() {
        commitAndPublish { state in
            state.nextReminderAt = nil
            self.recomputeDerivedFields(&state)
        }
    }

    // MARK: - Queries / Refresh

    func refreshNotificationStatus() async {
        notificationAuthorizationStatus = await notificationCoordinator.currentStatus()
        hasCheckedNotificationStatus = true
        commitAndPublish { state in
            self.recomputeDerivedFields(&state)
        }
    }

    func refreshFromStore() {
        isApplyingState = true
        let loadedOnboarding = SettingsStore.loadOnboardingCompleted()
        if loadedOnboarding != hasCompletedOnboarding { hasCompletedOnboarding = loadedOnboarding }
        let loadedSettings = SettingsStore.loadSettings()
        if loadedSettings != settings { settings = loadedSettings }
        let loadedRuntime = SettingsStore.loadRuntimeState()
        if loadedRuntime != runtimeState { runtimeState = loadedRuntime }
        todaySummary = CompletionTracker.loadTodaySummary()
        let loadedFocus = SettingsStore.loadFocusFilterState()
        if loadedFocus != focusFilterState { focusFilterState = loadedFocus }
        isApplyingState = false
        commitAndPublish { state in
            self.recomputeDerivedFields(&state)
        }
    }

    func refreshFocusFilterState() {
        let loaded = SettingsStore.loadFocusFilterState()
        if loaded != focusFilterState {
            focusFilterState = loaded
        }
    }

    // MARK: - Pipeline: Commit

    private func commitAndPublish(_ mutate: (inout SyncState) -> Void) {
        pendingSettingsCommitTask?.cancel()
        pendingSettingsCommitTask = nil
        var next = buildCurrentSyncState()
        let lastAccepted = syncManager.acceptedState?.version ?? 0
        next.version = max(next.version, lastAccepted) + 1
        next.updatedAt = Date()
        next.origin = currentOrigin

        mutate(&next)

        applyStateLocally(next, isRemote: false)
        syncManager.publishState(next)
    }

    // MARK: - Pipeline: Apply

    private func applyStateLocally(_ state: SyncState, isRemote: Bool) {
        isApplyingState = true
        defer { isApplyingState = false }

        syncVersion = state.version
        SettingsStore.saveSyncVersion(syncVersion)
        SettingsStore.save(state)

        if state.settings != settings {
            settings = state.settings
            SettingsStore.save(state.settings)
        }
        if state.onboarded != hasCompletedOnboarding {
            hasCompletedOnboarding = state.onboarded
        }
        if state.isPaused != runtimeState.isPaused {
            runtimeState.isPaused = state.isPaused
        }
        if state.nextReminderAt != runtimeState.nextReminderAt {
            runtimeState.nextReminderAt = state.nextReminderAt
        }
        if let remoteTodayRecords = state.todayRecords {
            let mergedSummary = CompletionTracker.mergeTodayRecords(remoteTodayRecords)
            if mergedSummary != todaySummary {
                todaySummary = mergedSummary
            }
        }

        let effectiveSettings = settingsWithFocusOverrides()
        let canScheduleLocally = effectiveSettings.remindersEnabled
            && !runtimeState.isPaused
            && notificationAuthorizationStatus == .authorized

        switch state.phase {
        case .break:
            notificationCoordinator.cancelPendingReminders()
            if let started = state.phaseStartedAt {
                let elapsed = Date().timeIntervalSince(started)
                let duration = Double(state.settings.breakDurationSeconds)
                if elapsed < duration {
                    breakStartedAt = started
                    if let endsAt = state.phaseEndsAt {
                        notificationCoordinator.scheduleBreakComplete(
                            at: endsAt, soundEnabled: state.settings.soundEnabled
                        )
                    }
                    if isRemote {
                        pendingAction = .startBreak
                    }
                } else {
                    if runtimeState.lastReminderHandledAt == nil
                        || runtimeState.lastReminderHandledAt! < started {
                        let device: DeviceType = state.origin == .watch ? .watch : .iphone
                        recordBreak(
                            type: .completed,
                            device: device,
                            recordID: historyRecordID(scope: "break", anchor: started),
                            startedAt: started
                        )
                    }
                    breakStartedAt = nil
                    notificationCoordinator.cancelBreakComplete()
                }
            } else {
                breakStartedAt = nil
                notificationCoordinator.cancelBreakComplete()
            }
        case .awaitingBreak:
            breakStartedAt = nil
            notificationCoordinator.cancelBreakComplete()
            notificationCoordinator.cancelPendingReminders()
        case .work:
            breakStartedAt = nil
            notificationCoordinator.cancelBreakComplete()
            if canScheduleLocally, let next = state.nextReminderAt, next.timeIntervalSinceNow > 0 {
                var dates = [next]
                let rest = ReminderEngine.upcomingReminderDates(
                    after: next,
                    settings: effectiveSettings,
                    limit: ReminderEngine.maxBatchSize - 1
                )
                dates.append(contentsOf: rest)
                notificationCoordinator.scheduleReminders(at: dates, settings: effectiveSettings)
            } else {
                notificationCoordinator.cancelPendingReminders()
            }
        case .idle:
            breakStartedAt = nil
            notificationCoordinator.cancelBreakComplete()
            notificationCoordinator.cancelPendingReminders()
        }

        #if os(watchOS)
        if let next = state.nextReminderAt, next.timeIntervalSinceNow > 10 {
            WatchAppDelegate.scheduleBackgroundRefresh(before: next)
        }
        #endif
    }

    // MARK: - Pipeline: Derive

    private func recomputeDerivedFields(_ state: inout SyncState) {
        let effective = settingsWithFocusOverrides()
        let operational = effective.remindersEnabled && !state.isPaused

        guard state.phase != .break else { return }

        if operational {
            if state.nextReminderAt == nil {
                state.nextReminderAt = ReminderEngine.upcomingReminderDates(
                    after: Date(), settings: effective
                ).first
            }
            if state.nextReminderAt == nil {
                state.phase = .idle
            } else if let nextReminderAt = state.nextReminderAt, nextReminderAt.timeIntervalSinceNow <= 0 {
                state.phase = .awaitingBreak
            } else {
                state.phase = .work
            }
        } else {
            state.phase = .idle
            state.nextReminderAt = nil
        }
    }

    private func buildCurrentSyncState() -> SyncState {
        let syncOperational = effectiveRemindersEnabled && !runtimeState.isPaused
        let phase: SyncPhase
        if breakStartedAt != nil {
            phase = .break
        } else if syncOperational, let nextReminderAt = runtimeState.nextReminderAt,
                  nextReminderAt.timeIntervalSinceNow <= 0 {
            phase = .awaitingBreak
        } else if syncOperational {
            phase = .work
        } else {
            phase = .idle
        }
        return SyncState(
            version: syncVersion,
            phase: phase,
            phaseStartedAt: breakStartedAt,
            phaseEndsAt: breakStartedAt.map {
                $0.addingTimeInterval(Double(settings.breakDurationSeconds))
            },
            isPaused: runtimeState.isPaused,
            settings: settings,
            onboarded: hasCompletedOnboarding,
            notificationsAuthorized: notificationAuthorizationStatus == .authorized,
            nextReminderAt: runtimeState.nextReminderAt,
            todayRecords: CompletionTracker.loadTodayRecords(),
            updatedAt: Date(),
            origin: currentOrigin
        )
    }

    // MARK: - Sync: Wiring

    private func bindSyncManager() {
        syncManager.onSessionActivated = { [weak self] in
            self?.publishCurrentState()
        }
        syncManager.onSyncRequested = { [weak self] in
            self?.publishCurrentState()
        }
        syncManager.onStateReceived = { [weak self] state in
            self?.applyStateLocally(state, isRemote: true)
        }
    }

    // MARK: - Notification Actions

    private func bindNotificationActions(_ coordinator: NotificationCoordinator) {
        coordinator.onStartBreak = { [weak self] in
            self?.startBreak()
            self?.pendingAction = .startBreak
        }
        coordinator.onDismiss = { [weak self] in
            self?.dismissReminder()
        }
    }

    // MARK: - Private

    private func recordBreak(
        type: BreakCompletionType,
        device: DeviceType,
        recordID: String,
        startedAt: Date
    ) {
        CompletionTracker.recordBreak(
            id: recordID,
            startedAt: startedAt,
            type: type,
            device: device,
            into: &todaySummary
        )
        runtimeState.lastReminderHandledAt = Date()
        if type == .completed {
            runtimeState.lastReminderFiredAt = Date()
        }
    }

    private func historyRecordID(scope: String, anchor: Date) -> String {
        let milliseconds = Int(anchor.timeIntervalSince1970 * 1000)
        return "\(scope):\(milliseconds)"
    }

    private func onSettingsChanged() {
        SettingsStore.save(settings)
        pendingSettingsCommitTask?.cancel()
        pendingSettingsCommitTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled, let self else { return }
            self.pendingSettingsCommitTask = nil
            self.commitAndPublish { state in
                state.nextReminderAt = nil
                self.recomputeDerivedFields(&state)
            }
        }
    }

    private func onFocusFilterChanged() {
        SettingsStore.save(focusFilterState)
        commitAndPublish { state in
            state.nextReminderAt = nil
            self.recomputeDerivedFields(&state)
        }
    }

    private func publishCurrentState() {
        var current = buildCurrentSyncState()
        recomputeDerivedFields(&current)
        current.updatedAt = Date()
        current.origin = currentOrigin
        applyStateLocally(current, isRemote: false)
        syncManager.publishState(current)
    }

    private func drainPendingNotificationActions() {
        let defaults = UserDefaults.standard
        let pendingDismiss = defaults.bool(
            forKey: NotificationCoordinator.pendingDismissActionKey
        )
        let pendingStart = defaults.bool(
            forKey: NotificationCoordinator.pendingStartActionKey
        )

        guard pendingDismiss || pendingStart else { return }

        defaults.removeObject(forKey: NotificationCoordinator.pendingDismissActionKey)
        defaults.removeObject(forKey: NotificationCoordinator.pendingStartActionKey)

        if pendingDismiss {
            dismissReminder()
        } else if pendingStart {
            startBreak()
            pendingAction = .startBreak
        }
    }

    private func settingsWithFocusOverrides() -> ReminderSettings {
        guard focusFilterState.overrideActive else { return settings }
        var effective = settings
        effective.remindersEnabled = focusFilterState.enableReminders
        if let interval = focusFilterState.intervalOverrideMinutes {
            effective.reminderIntervalMinutes = interval
        }
        return effective
    }
}
