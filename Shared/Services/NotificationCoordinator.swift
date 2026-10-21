import Foundation
import UserNotifications

final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    static let shared = NotificationCoordinator()

    static let categoryIdentifier = "ICARE_REMINDER"
    static let reminderIDPrefix = "icare.reminder."
    static let breakCompleteID = "icare.break.complete"

    var onStartBreak: (@MainActor () -> Void)?
    var onDismiss: (@MainActor () -> Void)?

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Setup

    static let startActionID = "START_BREAK"
    static let dismissActionID = "DISMISS_BREAK"
    static let pendingStartActionKey = "icare.pendingNotificationStartBreak"
    static let pendingDismissActionKey = "icare.pendingNotificationDismissReminder"

    func registerCategories() {
        let startAction = UNNotificationAction(
            identifier: Self.startActionID,
            title: "Start",
            options: [.foreground]
        )
        // watchOS adds its own Dismiss button (which only closes the notification),
        // so ours gets a distinct name there instead of showing "Dismiss" twice.
        #if os(watchOS)
        let dismissTitle = "Skip break"
        #else
        let dismissTitle = "Dismiss"
        #endif
        let dismissAction = UNNotificationAction(
            identifier: Self.dismissActionID,
            title: dismissTitle,
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [startAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func currentStatus() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        return mapStatus(settings.authorizationStatus)
    }

    // MARK: - Scheduling

    // Every applied sync state reschedules, so skip identical batches instead of
    // cancelling and re-adding the same notifications over and over.
    private var lastScheduledBatch: (dates: [Date], soundEnabled: Bool)?

    func scheduleReminders(at dates: [Date], settings: ReminderSettings) {
        if let last = lastScheduledBatch, last.dates == dates, last.soundEnabled == settings.soundEnabled {
            return
        }
        cancelPendingReminders()
        lastScheduledBatch = (dates, settings.soundEnabled)

        for (index, date) in dates.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Time for a break"
            content.body = Self.bodies[index % Self.bodies.count]
            content.categoryIdentifier = Self.categoryIdentifier
            if settings.soundEnabled {
                content.sound = .default
            }

            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: date
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(Self.reminderIDPrefix)\(index)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func cancelPendingReminders() {
        lastScheduledBatch = nil
        center.removePendingNotificationRequests(withIdentifiers: Self.reminderIDs)
    }

    /// Clears reminders already sitting in Notification Center once a break is handled.
    func clearDeliveredReminders() {
        center.removeDeliveredNotifications(withIdentifiers: Self.reminderIDs)
    }

    private static let reminderIDs = (0..<ReminderEngine.maxBatchSize).map { "\(reminderIDPrefix)\($0)" }

    // MARK: - Break Complete Notification

    func scheduleBreakComplete(at date: Date, soundEnabled: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Break complete"
        content.body = "Great job! Your eyes will thank you."
        content.sound = soundEnabled ? .default : nil

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, date.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Self.breakCompleteID,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelBreakComplete() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.breakCompleteID])
        center.removeDeliveredNotifications(withIdentifiers: [Self.breakCompleteID])
    }

    // MARK: - UNUserNotificationCenterDelegate

    var isShowingCountdown = false
    var isAppInForeground = false

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier
        if id == Self.breakCompleteID && isShowingCountdown {
            handler([])
            return
        }
        handler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        let action = response.actionIdentifier

        guard id.hasPrefix(Self.reminderIDPrefix) else {
            handler()
            return
        }

        Task { @MainActor in
            switch action {
            case Self.startActionID, UNNotificationDefaultActionIdentifier:
                if let onStartBreak {
                    onStartBreak()
                } else {
                    UserDefaults.standard.set(true, forKey: Self.pendingStartActionKey)
                }
            case Self.dismissActionID:
                if let onDismiss {
                    onDismiss()
                } else {
                    UserDefaults.standard.set(true, forKey: Self.pendingDismissActionKey)
                }
            default:
                break
            }
        }
        handler()
    }

    // MARK: - Private

    private static let bodies = [
        "Look at something in the distance",
        "Time for a visual break",
        "Look away for 20 seconds",
    ]

    private func mapStatus(_ status: UNAuthorizationStatus) -> NotificationAuthorizationStatus {
        switch status {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized: .authorized
        case .provisional: .provisional
        case .ephemeral: .authorized
        @unknown default: .notDetermined
        }
    }
}
