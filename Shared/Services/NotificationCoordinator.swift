import Foundation
import UserNotifications

final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    static let shared = NotificationCoordinator()

    static let categoryIdentifier = "ICARE_REMINDER"
    static let startActionID = "ICARE_START"
    static let snoozeActionID = "ICARE_SNOOZE"
    static let skipActionID = "ICARE_SKIP"
    static let reminderIDPrefix = "icare.reminder."

    var onStartBreak: (@MainActor () -> Void)?
    var onSnooze: (@MainActor () -> Void)?
    var onSkip: (@MainActor () -> Void)?

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Setup

    func registerCategories() {
        let start = UNNotificationAction(
            identifier: Self.startActionID,
            title: "Start",
            options: .foreground
        )
        let snooze = UNNotificationAction(
            identifier: Self.snoozeActionID,
            title: "Snooze"
        )
        let skip = UNNotificationAction(
            identifier: Self.skipActionID,
            title: "Skip"
        )

        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [start, snooze, skip],
            intentIdentifiers: []
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

    func scheduleReminders(at dates: [Date], settings: ReminderSettings) {
        cancelPendingReminders()

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
        center.getPendingNotificationRequests { [weak self] requests in
            guard let prefix = self.map({ _ in Self.reminderIDPrefix }) else { return }
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }
            if !ids.isEmpty {
                self?.center.removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        let action = response.actionIdentifier
        Task { @MainActor in
            switch action {
            case Self.startActionID, UNNotificationDefaultActionIdentifier:
                onStartBreak?()
            case Self.snoozeActionID:
                onSnooze?()
            case Self.skipActionID:
                onSkip?()
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
