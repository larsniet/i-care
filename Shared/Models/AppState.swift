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
            guard !isSyncingFromRemote else { return }
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
            if !isSyncingFromRemote {
                sendSyncContext()
            }
        }
    }
    @Published var pendingAction: NotificationAction?
    @Published var breakStartedAt: Date?
    @Published var focusFilterState: FocusFilterState {
        didSet { onFocusFilterChanged() }
    }

    let notificationCoordinator: NotificationCoordinator
    private let syncManager: WatchSyncManager
    private var isSyncingFromRemote = false
    private var hasCheckedNotificationStatus = false

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

        coordinator.registerCategories()
        bindNotificationActions(coordinator)
        #if os(iOS)
        syncManager.onSessionActivated = { [weak self] in
            self?.sendSyncContext()
        }
        syncManager.contextProvider = { [weak self] in
            guard let self else { return [:] }
            return self.buildContextDict()
        }
        syncManager.onCommandReceived = { [weak self] command, payload in
            guard let self else { return }
            switch command {
            case "pause": self.pause()
            case "resume": self.resume()
            case "reset": self.resetTimer()
            case "startBreak":
                if let ts = payload["breakStartedAt"] as? TimeInterval {
                    self.breakStartedAt = Date(timeIntervalSince1970: ts)
                } else if self.breakStartedAt == nil {
                    self.breakStartedAt = Date()
                }
                self.pendingAction = .startBreak
            default: break
            }
        }
        #endif
        #if os(watchOS)
        bindSyncManager()
        #endif
        syncManager.activate()

        Task { [weak self] in
            guard let self else { return }
            await self.refreshNotificationStatus()
            self.scheduleReminders()
        }
    }

    // MARK: - Public

    func refreshNotificationStatus() async {
        notificationAuthorizationStatus = await notificationCoordinator.currentStatus()
        hasCheckedNotificationStatus = true
        sendSyncContext()
    }

    func refreshFromStore() {
        let loadedOnboarding = SettingsStore.loadOnboardingCompleted()
        if loadedOnboarding != hasCompletedOnboarding {
            hasCompletedOnboarding = loadedOnboarding
        }

        let loadedSettings = SettingsStore.loadSettings()
        if loadedSettings != settings {
            settings = loadedSettings
        }

        let loadedRuntime = SettingsStore.loadRuntimeState()
        if loadedRuntime != runtimeState {
            runtimeState = loadedRuntime
        }

        todaySummary = CompletionTracker.loadTodaySummary()

        refreshFocusFilterState()
    }

    func refreshFocusFilterState() {
        let loaded = SettingsStore.loadFocusFilterState()
        if loaded != focusFilterState {
            focusFilterState = loaded
        }
    }

    func scheduleReminders(force: Bool = false) {
        guard isFullyOperational else {
            notificationCoordinator.cancelPendingReminders()
            runtimeState.nextReminderAt = nil
            return
        }

        let effectiveSettings = settingsWithFocusOverrides()

        if !force,
           let existing = runtimeState.nextReminderAt,
           existing.timeIntervalSinceNow > 0 {
            return
        }

        let dates = ReminderEngine.upcomingReminderDates(
            after: Date(),
            settings: effectiveSettings
        )
        guard let first = dates.first else {
            runtimeState.nextReminderAt = nil
            return
        }
        runtimeState.nextReminderAt = first
        notificationCoordinator.scheduleReminders(at: dates, settings: effectiveSettings)
        sendSyncContext()
    }

    func completeBreak(type: BreakCompletionType, device: DeviceType = .iphone) {
        CompletionTracker.recordBreak(type: type, device: device, into: &todaySummary)
        runtimeState.lastReminderHandledAt = Date()
        if type == .completed {
            runtimeState.lastReminderFiredAt = Date()
        }
        scheduleReminders(force: true)
        sendSyncContext()
    }

    func snooze() {
        let effectiveSettings = settingsWithFocusOverrides()
        let snoozeTarget = ReminderEngine.snoozeDate(settings: effectiveSettings)
        runtimeState.nextReminderAt = snoozeTarget

        var dates = [snoozeTarget]
        let rest = ReminderEngine.upcomingReminderDates(
            after: snoozeTarget,
            settings: effectiveSettings,
            limit: ReminderEngine.maxBatchSize - 1
        )
        dates.append(contentsOf: rest)
        notificationCoordinator.scheduleReminders(at: dates, settings: effectiveSettings)
        SettingsStore.save(runtimeState)
        sendSyncContext()
    }

    func startBreak() {
        let now = Date()
        breakStartedAt = now
        sendSyncContext()
        syncManager.sendCommand("startBreak", payload: [
            "breakStartedAt": now.timeIntervalSince1970
        ])
    }

    func resetTimer() {
        runtimeState.nextReminderAt = nil
        scheduleReminders(force: true)
    }

    func pause() {
        runtimeState.isPaused = true
        notificationCoordinator.cancelPendingReminders()
        sendSyncContext()
    }

    func resume() {
        runtimeState.isPaused = false
        runtimeState.pausedUntil = nil
        scheduleReminders(force: true)
        sendSyncContext()
    }

    // MARK: - Private

    private func sendSyncContext() {
        syncManager.sendContext(
            settings: settings,
            onboarded: hasCompletedOnboarding,
            notificationsAuthorized: notificationAuthorizationStatus == .authorized,
            isPaused: runtimeState.isPaused,
            nextReminderAt: runtimeState.nextReminderAt,
            breakStartedAt: breakStartedAt
        )
    }

    #if os(iOS)
    fileprivate func buildContextDict() -> [String: Any] {
        var context: [String: Any] = [
            "onboarded": hasCompletedOnboarding,
            "notificationsAuthorized": notificationAuthorizationStatus == .authorized,
            "isPaused": runtimeState.isPaused,
        ]
        if let data = try? JSONEncoder().encode(settings) {
            context["settings"] = data
        }
        if let date = runtimeState.nextReminderAt {
            context["nextReminderAt"] = date.timeIntervalSince1970
        }
        if let date = breakStartedAt {
            context["breakStartedAt"] = date.timeIntervalSince1970
        }
        return context
    }
    #endif

    private func onSettingsChanged() {
        SettingsStore.save(settings)
        Task { [weak self] in
            guard let self else { return }
            self.scheduleReminders(force: true)
            self.sendSyncContext()
        }
    }

    private func onFocusFilterChanged() {
        scheduleReminders(force: true)
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

    #if os(watchOS)
    private func bindSyncManager() {
        syncManager.onContextReceived = { [weak self] settings, onboarded, notificationsAuthorized, isPaused, nextReminderAt, breakStartedAt in
            guard let self else { return }
            self.isSyncingFromRemote = true

            if onboarded != self.hasCompletedOnboarding {
                self.hasCompletedOnboarding = onboarded
            }
            if settings != self.settings {
                self.settings = settings
                SettingsStore.save(settings)
            }
            let syncedStatus: NotificationAuthorizationStatus = notificationsAuthorized ? .authorized : .denied
            if syncedStatus != self.notificationAuthorizationStatus {
                self.notificationAuthorizationStatus = syncedStatus
                self.hasCheckedNotificationStatus = true
            }
            if isPaused != self.runtimeState.isPaused {
                self.runtimeState.isPaused = isPaused
            }
            if nextReminderAt != self.runtimeState.nextReminderAt {
                self.runtimeState.nextReminderAt = nextReminderAt
            }
            if breakStartedAt != self.breakStartedAt {
                self.breakStartedAt = breakStartedAt
                if let started = breakStartedAt {
                    let elapsed = Date().timeIntervalSince(started)
                    let duration = Double(self.settings.breakDurationSeconds)
                    if elapsed < duration {
                        self.pendingAction = .startBreak
                    } else {
                        self.breakStartedAt = nil
                    }
                }
            }

            self.isSyncingFromRemote = false
        }

        syncManager.onCommandReceived = { [weak self] command, payload in
            guard let self else { return }
            if command == "startBreak" {
                if let ts = payload["breakStartedAt"] as? TimeInterval {
                    self.breakStartedAt = Date(timeIntervalSince1970: ts)
                } else if self.breakStartedAt == nil {
                    self.breakStartedAt = Date()
                }
                self.pendingAction = .startBreak
            }
        }
    }
    #endif

    private func bindNotificationActions(_ coordinator: NotificationCoordinator) {
        coordinator.onStartBreak = { [weak self] in
            self?.pendingAction = .startBreak
        }
        coordinator.onSnooze = { [weak self] in
            self?.snooze()
        }
        coordinator.onSkip = { [weak self] in
            self?.completeBreak(type: .skipped)
        }
    }
}
