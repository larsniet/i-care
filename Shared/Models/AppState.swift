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

    let notificationCoordinator: NotificationCoordinator

    // MARK: - Computed

    var isFullyOperational: Bool {
        settings.remindersEnabled
            && notificationAuthorizationStatus == .authorized
            && !runtimeState.isPaused
    }

    var currentStatus: ReminderStatus {
        if !settings.remindersEnabled { return .inactive }
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

        coordinator.registerCategories()
        bindNotificationActions(coordinator)

        Task { [weak self] in
            guard let self else { return }
            await self.refreshNotificationStatus()
            self.scheduleNextReminderIfNeeded()
        }
    }

    // MARK: - Public

    func refreshNotificationStatus() async {
        notificationAuthorizationStatus = await notificationCoordinator.currentStatus()
    }

    func scheduleNextReminderIfNeeded() {
        guard isFullyOperational else {
            notificationCoordinator.cancelPendingReminders()
            runtimeState.nextReminderAt = nil
            return
        }
        guard let next = ReminderEngine.nextReminderDate(after: Date(), settings: settings) else {
            runtimeState.nextReminderAt = nil
            return
        }
        runtimeState.nextReminderAt = next
        notificationCoordinator.scheduleReminder(at: next, settings: settings)
    }

    func completeBreak(type: BreakCompletionType, device: DeviceType = .iphone) {
        CompletionTracker.recordBreak(type: type, device: device, into: &todaySummary)
        runtimeState.lastReminderHandledAt = Date()
        if type == .completed {
            runtimeState.lastReminderFiredAt = Date()
        }
        scheduleNextReminderIfNeeded()
    }

    func snooze() {
        let target = ReminderEngine.snoozeDate(settings: settings)
        runtimeState.nextReminderAt = target
        notificationCoordinator.scheduleReminder(at: target, settings: settings)
        SettingsStore.save(runtimeState)
    }

    func pause() {
        runtimeState.isPaused = true
        notificationCoordinator.cancelPendingReminders()
    }

    func resume() {
        runtimeState.isPaused = false
        runtimeState.pausedUntil = nil
        scheduleNextReminderIfNeeded()
    }

    // MARK: - Private

    private func onSettingsChanged() {
        SettingsStore.save(settings)
        scheduleNextReminderIfNeeded()
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
