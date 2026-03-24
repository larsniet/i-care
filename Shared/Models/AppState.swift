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
        didSet { onSettingsChanged() }
    }
    @Published var runtimeState: ReminderRuntimeState {
        didSet { SettingsStore.save(runtimeState) }
    }
    @Published var todaySummary: DailySummary
    @Published var notificationAuthorizationStatus: NotificationAuthorizationStatus
    @Published var hasCompletedOnboarding: Bool {
        didSet { SettingsStore.saveOnboardingCompleted(hasCompletedOnboarding) }
    }
    @Published var pendingAction: NotificationAction?
    @Published var focusFilterState: FocusFilterState {
        didSet { onFocusFilterChanged() }
    }

    let notificationCoordinator: NotificationCoordinator

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
        if notificationAuthorizationStatus != .authorized { return .blocked }
        return .active
    }

    // MARK: - Init

    init() {
        let coordinator = NotificationCoordinator.shared
        self.notificationCoordinator = coordinator

        self.settings = SettingsStore.loadSettings()
        self.runtimeState = SettingsStore.loadRuntimeState()
        self.todaySummary = CompletionTracker.loadTodaySummary()
        self.notificationAuthorizationStatus = .notDetermined
        self.hasCompletedOnboarding = SettingsStore.loadOnboardingCompleted()
        self.focusFilterState = SettingsStore.loadFocusFilterState()

        coordinator.registerCategories()
        bindNotificationActions(coordinator)

        Task { [weak self] in
            guard let self else { return }
            await self.refreshNotificationStatus()
            self.scheduleReminders()
        }
    }

    // MARK: - Public

    func refreshNotificationStatus() async {
        notificationAuthorizationStatus = await notificationCoordinator.currentStatus()
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
    }

    func completeBreak(type: BreakCompletionType, device: DeviceType = .iphone) {
        CompletionTracker.recordBreak(type: type, device: device, into: &todaySummary)
        runtimeState.lastReminderHandledAt = Date()
        if type == .completed {
            runtimeState.lastReminderFiredAt = Date()
        }
        scheduleReminders(force: true)
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
    }

    func resetTimer() {
        runtimeState.nextReminderAt = nil
        scheduleReminders(force: true)
    }

    func pause() {
        runtimeState.isPaused = true
        notificationCoordinator.cancelPendingReminders()
    }

    func resume() {
        runtimeState.isPaused = false
        runtimeState.pausedUntil = nil
        scheduleReminders(force: true)
    }

    // MARK: - Private

    private func onSettingsChanged() {
        SettingsStore.save(settings)
        scheduleReminders(force: true)
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
