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
        // Not "Dismiss": watchOS adds its own Dismiss (which only closes the
        // notification), and reminders forwarded from the iPhone use these titles.
        let dismissAction = UNNotificationAction(
            identifier: Self.dismissActionID,
            title: "Skip break",
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
    /// Reminders this process scheduled and still wants. Anything else with the
    /// reminder prefix is stale (cancelled, or left by an earlier launch or version).
    private var scheduledReminderIDs: Set<String> = []

    func scheduleReminders(at dates: [Date], settings: ReminderSettings) {
        if let last = lastScheduledBatch, last.dates == dates, last.soundEnabled == settings.soundEnabled {
            return
        }
        cancelPendingReminders()
        lastScheduledBatch = (dates, settings.soundEnabled)

        // A paired Watch silently drops a forwarded reminder whose ID it has seen
        // before, so every batch gets fresh IDs instead of reusing reminder.0...49.
        let batch = Int(Date().timeIntervalSince1970)
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
            let identifier = "\(Self.reminderIDPrefix)\(batch).\(index)"
            scheduledReminderIDs.insert(identifier)
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func cancelPendingReminders() {
        lastScheduledBatch = nil
        center.removePendingNotificationRequests(withIdentifiers: Array(scheduledReminderIDs))
        scheduledReminderIDs.removeAll()
        removeStalePendingReminders()
    }

    /// Clears reminders already sitting in Notification Center once a break is handled.
    func clearDeliveredReminders() {
        center.getDeliveredNotifications { [center] delivered in
            let ids = delivered.map(\.request.identifier).filter { $0.hasPrefix(Self.reminderIDPrefix) }
            center.removeDeliveredNotifications(withIdentifiers: ids)
        }
    }

    /// Removes pending reminders this process no longer tracks. The check runs on the
    /// main queue against the current set, so a batch added meanwhile is never removed.
    private func removeStalePendingReminders() {
        center.getPendingNotificationRequests { [weak self] requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(Self.reminderIDPrefix) }
            DispatchQueue.main.async {
                guard let self else { return }
                let stale = ids.filter { !self.scheduledReminderIDs.contains($0) }
                self.center.removePendingNotificationRequests(withIdentifiers: stale)
            }
        }
    }

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
