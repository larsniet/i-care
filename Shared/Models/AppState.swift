import Combine
import Foundation

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
    case skip
}

// MARK: - App State

@MainActor
final class AppState: ObservableObject {

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
        bindSyncManager()
        syncManager.activate()

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
        guard breakStartedAt != nil else { return }
        recordBreak(type: type, device: device)
        commitAndPublish { state in
            state.phase = .work
            state.phaseStartedAt = nil
            state.phaseEndsAt = nil
            self.recomputeDerivedFields(&state)
        }
    }

    func skipReminder(device: DeviceType = .iphone) {
        recordBreak(type: .skipped, device: device)
        commitAndPublish { state in
            state.phase = .work
            state.phaseStartedAt = nil
            state.phaseEndsAt = nil
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
            self.recomputeDerivedFields(&state)
        }
    }

    func resetTimer() {
        commitAndPublish { state in
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

        if state.settings != settings {
            settings = state.settings
            SettingsStore.save(state.settings)
        }
        if state.onboarded != hasCompletedOnboarding {
            hasCompletedOnboarding = state.onboarded
        }
        let authStatus: NotificationAuthorizationStatus = state.notificationsAuthorized ? .authorized : .denied
        if authStatus != notificationAuthorizationStatus {
            notificationAuthorizationStatus = authStatus
            hasCheckedNotificationStatus = true
        }
        if state.isPaused != runtimeState.isPaused {
            runtimeState.isPaused = state.isPaused
        }
        if state.nextReminderAt != runtimeState.nextReminderAt {
            runtimeState.nextReminderAt = state.nextReminderAt
        }

        let effectiveSettings = settingsWithFocusOverrides()

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
                    if isRemote { pendingAction = .startBreak }
                } else {
                    breakStartedAt = nil
                    notificationCoordinator.cancelBreakComplete()
                }
            }
        case .work:
            breakStartedAt = nil
            notificationCoordinator.cancelBreakComplete()
            if let next = state.nextReminderAt, next.timeIntervalSinceNow > 0 {
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
    }

    // MARK: - Pipeline: Derive

    private func recomputeDerivedFields(_ state: inout SyncState) {
        let effective = settingsWithFocusOverrides()
        let operational = effective.remindersEnabled
            && state.notificationsAuthorized
            && !state.isPaused

        guard state.phase != .break else { return }

        if operational {
            state.phase = .work
            state.nextReminderAt = ReminderEngine.upcomingReminderDates(
                after: Date(), settings: effective
            ).first
            if state.nextReminderAt == nil {
                state.phase = .idle
            }
        } else {
            state.phase = .idle
            state.nextReminderAt = nil
        }
    }

    private func buildCurrentSyncState() -> SyncState {
        SyncState(
            version: syncVersion,
            phase: breakStartedAt != nil ? .break : (isFullyOperational ? .work : .idle),
            phaseStartedAt: breakStartedAt,
            phaseEndsAt: breakStartedAt.map {
                $0.addingTimeInterval(Double(settings.breakDurationSeconds))
            },
            isPaused: runtimeState.isPaused,
            settings: settings,
            onboarded: hasCompletedOnboarding,
            notificationsAuthorized: notificationAuthorizationStatus == .authorized,
            nextReminderAt: runtimeState.nextReminderAt,
            updatedAt: Date(),
            origin: currentOrigin
        )
    }

    // MARK: - Sync: Wiring

    private func bindSyncManager() {
        syncManager.onSessionActivated = { [weak self] in
            self?.commitAndPublish { _ in }
        }
        syncManager.onSyncRequested = { [weak self] in
            self?.commitAndPublish { _ in }
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
        coordinator.onSkip = { [weak self] in
            self?.skipReminder()
        }
    }

    // MARK: - Private

    private func recordBreak(type: BreakCompletionType, device: DeviceType) {
        CompletionTracker.recordBreak(type: type, device: device, into: &todaySummary)
        runtimeState.lastReminderHandledAt = Date()
        if type == .completed {
            runtimeState.lastReminderFiredAt = Date()
        }
    }

    private func onSettingsChanged() {
        SettingsStore.save(settings)
        commitAndPublish { state in
            self.recomputeDerivedFields(&state)
        }
    }

    private func onFocusFilterChanged() {
        commitAndPublish { state in
            self.recomputeDerivedFields(&state)
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
