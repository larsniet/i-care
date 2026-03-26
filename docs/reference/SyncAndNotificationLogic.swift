// ============================================================================
// SyncAndNotificationLogic.swift
// Consolidated reference of all watch/phone syncing and notification logic.
//
// Source files:
//   - Shared/Models/SyncState.swift
//   - Shared/Services/WatchSyncManager.swift
//   - Shared/Models/AppState.swift (sync/notification portions)
//   - Shared/Services/NotificationCoordinator.swift
//   - Shared/Services/ReminderEngine.swift
//   - iCareWatch/Features/Notification/NotificationController.swift
//
// Architecture:
//   commitAndPublish(_ mutate:) is the ONLY local state mutation entry point.
//   applyStateLocally(_ state:isRemote:) is the ONLY place that derives
//   UI properties, schedules/cancels notifications, and updates local store.
//   Both local and remote paths converge into applyStateLocally.
//
//   Local:  action → commitAndPublish → mutate → applyStateLocally → publish
//   Remote: incoming → version check → applyStateLocally (no publish)
//
//   Transport:
//     updateApplicationContext is the sole state channel.
//     sendMessage is only a lightweight "stateChanged" nudge.
//     transferUserInfo is not used.
//
//   Conflict resolution:
//     higher version wins → later updatedAt wins → explicit origin priority.
//     Manager stores full acceptedState, encodes before accepting.
// ============================================================================


// MARK: - ===== SyncState.swift =====
// Source: Shared/Models/SyncState.swift

import Foundation

enum SyncPhase: String, Codable, Sendable {
    case idle
    case work
    case `break`
}

enum SyncOrigin: String, Codable, Sendable {
    case phone
    case watch
}

struct SyncState: Codable, Equatable, Sendable {
    var version: Int
    var phase: SyncPhase
    var phaseStartedAt: Date?
    var phaseEndsAt: Date?
    var isPaused: Bool
    var settings: ReminderSettings
    var onboarded: Bool
    var notificationsAuthorized: Bool
    var nextReminderAt: Date?
    var updatedAt: Date
    var origin: SyncOrigin
}


// MARK: - ===== WatchSyncManager.swift =====
// Source: Shared/Services/WatchSyncManager.swift

import WatchConnectivity

final class WatchSyncManager: NSObject, WCSessionDelegate, @unchecked Sendable {

    static let shared = WatchSyncManager()

    var onStateReceived: (@MainActor (SyncState) -> Void)?
    var onSessionActivated: (@MainActor () -> Void)?
    var onSyncRequested: (@MainActor () -> Void)?

    private(set) var acceptedState: SyncState?

    var currentVersion: Int { acceptedState?.version ?? 0 }

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Publish

    func publishState(_ state: SyncState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        acceptedState = state

        guard WCSession.default.activationState == .activated else { return }
        #if os(iOS)
        guard WCSession.default.isPaired,
              WCSession.default.isWatchAppInstalled else { return }
        #endif

        try? WCSession.default.updateApplicationContext(["syncState": data])

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                ["event": "stateChanged"],
                replyHandler: nil,
                errorHandler: nil
            )
        }
    }

    // MARK: - Request

    func requestSync() {
        guard WCSession.default.activationState == .activated else { return }
        let context = WCSession.default.receivedApplicationContext
        if !context.isEmpty { applyIncoming(context) }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                ["event": "requestSync"],
                replyHandler: nil,
                errorHandler: nil
            )
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }
        let context = session.receivedApplicationContext
        if !context.isEmpty { applyIncoming(context) }
        Task { @MainActor in onSessionActivated?() }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        applyIncoming(applicationContext)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        handleMessage(message)
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        handleMessage(message)
        replyHandler([:])
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    // MARK: - Private

    private func handleMessage(_ message: [String: Any]) {
        guard let event = message["event"] as? String else { return }
        switch event {
        case "stateChanged":
            let context = WCSession.default.receivedApplicationContext
            if !context.isEmpty { applyIncoming(context) }
        case "requestSync":
            Task { @MainActor in onSyncRequested?() }
        default:
            break
        }
    }

    private func applyIncoming(_ context: [String: Any]) {
        guard let data = context["syncState"] as? Data,
              let incoming = try? JSONDecoder().decode(SyncState.self, from: data) else { return }
        guard shouldAccept(incoming) else { return }
        acceptedState = incoming
        Task { @MainActor in onStateReceived?(incoming) }
    }

    private func shouldAccept(_ incoming: SyncState) -> Bool {
        guard let current = acceptedState else { return true }
        if incoming.version > current.version { return true }
        if incoming.version < current.version { return false }
        if incoming.updatedAt > current.updatedAt { return true }
        if incoming.updatedAt < current.updatedAt { return false }
        return originPriority(incoming.origin) > originPriority(current.origin)
    }

    private func originPriority(_ origin: SyncOrigin) -> Int {
        switch origin {
        case .phone: return 0
        case .watch: return 1
        }
    }
}


// MARK: - ===== AppState.swift (sync/notification pipeline) =====
// Source: Shared/Models/AppState.swift
//
// Only the pipeline and transition methods are shown here.
// Full file includes @Published properties, computed helpers, init, etc.

// --- commitAndPublish: the ONLY local mutation entry point ---
//
// private func commitAndPublish(_ mutate: (inout SyncState) -> Void) {
//     var next = buildCurrentSyncState()
//     let lastAccepted = syncManager.acceptedState?.version ?? 0
//     next.version = max(next.version, lastAccepted) + 1
//     next.updatedAt = Date()
//     next.origin = currentOrigin
//     mutate(&next)
//     applyStateLocally(next, isRemote: false)
//     syncManager.publishState(next)
// }

// --- applyStateLocally: the ONLY place UI + notifications are derived ---
//
// private func applyStateLocally(_ state: SyncState, isRemote: Bool) {
//     isApplyingState = true
//     defer { isApplyingState = false }
//
//     // 1. Write @Published properties from state
//     //    (settings, onboarded, notificationAuth, isPaused, nextReminderAt)
//
//     // 2. Phase-driven notification management:
//     //    .break → cancel reminders, schedule break-complete, set breakStartedAt
//     //    .work  → cancel break-complete, schedule reminders from nextReminderAt
//     //    .idle  → cancel everything
//
//     // 3. If isRemote && phase == .break → set pendingAction = .startBreak
// }

// --- All transitions go through commitAndPublish ---
//
// func startBreak() {
//     commitAndPublish { state in
//         state.phase = .break
//         state.phaseStartedAt = now
//         state.phaseEndsAt = now + breakDuration
//         state.nextReminderAt = nil
//     }
// }
//
// func endBreak(type:device:) {
//     recordBreak(type:device:)
//     commitAndPublish { state in
//         state.phase = .work
//         state.phaseStartedAt = nil
//         state.phaseEndsAt = nil
//         recomputeDerivedFields(&state)
//     }
// }
//
// func skipReminder(device:) {
//     recordBreak(type: .skipped, device:)
//     commitAndPublish { state in
//         state.phase = .work
//         state.phaseStartedAt = nil
//         state.phaseEndsAt = nil
//         recomputeDerivedFields(&state)
//     }
// }
//
// func pause()   { commitAndPublish { $0.isPaused = true; $0.phase = .idle; $0.nextReminderAt = nil } }
// func resume()  { commitAndPublish { $0.isPaused = false; recomputeDerivedFields(&$0) } }
// func snooze()  { commitAndPublish { $0.phase = .work; $0.nextReminderAt = snoozeDate } }
// func resetTimer() { commitAndPublish { recomputeDerivedFields(&$0) } }

// --- Notification actions route through the same pipeline ---
//
// coordinator.onStartBreak = { self?.startBreak(); self?.pendingAction = .startBreak }
// coordinator.onSkip       = { self?.skipReminder() }

// --- Receive path uses applyStateLocally only (no publish) ---
//
// syncManager.onStateReceived = { state in
//     self?.applyStateLocally(state, isRemote: true)
// }


// MARK: - ===== NotificationCoordinator.swift =====
// Source: Shared/Services/NotificationCoordinator.swift

import UserNotifications

final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    static let shared = NotificationCoordinator()

    static let categoryIdentifier = "ICARE_REMINDER"
    static let reminderIDPrefix = "icare.reminder."
    static let breakCompleteID = "icare.break.complete"

    var onStartBreak: (@MainActor () -> Void)?
    var onSkip: (@MainActor () -> Void)?

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Setup

    func registerCategories() {
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
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
        let ids = (0..<ReminderEngine.maxBatchSize).map { "\(Self.reminderIDPrefix)\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
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
        if id.hasPrefix(Self.reminderIDPrefix) && isAppInForeground {
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
            case UNNotificationDefaultActionIdentifier:
                onStartBreak?()
            case UNNotificationDismissActionIdentifier:
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


// MARK: - ===== ReminderEngine.swift =====
// Source: Shared/Services/ReminderEngine.swift

enum ReminderEngine {

    static let maxBatchSize = 50

    static func nextReminderDate(
        after referenceDate: Date = Date(),
        settings: ReminderSettings
    ) -> Date? {
        upcomingReminderDates(after: referenceDate, settings: settings, limit: 1).first
    }

    static func upcomingReminderDates(
        after referenceDate: Date = Date(),
        settings: ReminderSettings,
        limit: Int = maxBatchSize
    ) -> [Date] {
        guard settings.remindersEnabled, limit > 0 else { return [] }

        let calendar = Calendar.current
        let interval = TimeInterval(settings.reminderIntervalMinutes * 60)
        let searchLimit = calendar.date(byAdding: .day, value: 7, to: referenceDate)!

        var results: [Date] = []
        var candidate = referenceDate.addingTimeInterval(interval)

        while candidate < searchLimit, results.count < limit {
            if settings.weekdaysOnly {
                let weekday = calendar.component(.weekday, from: candidate)
                if weekday == 1 || weekday == 7 {
                    candidate = nextActiveStart(after: candidate, settings: settings, calendar: calendar)
                    continue
                }
            }

            if !settings.activeHoursEnabled {
                results.append(candidate)
                candidate = candidate.addingTimeInterval(interval)
                continue
            }

            let minuteOfDay = calendar.component(.hour, from: candidate) * 60
                + calendar.component(.minute, from: candidate)
            let startMinute = settings.activeStartHour * 60 + settings.activeStartMinute
            let endMinute = settings.activeEndHour * 60 + settings.activeEndMinute

            guard endMinute > startMinute else { return results }

            if minuteOfDay >= startMinute && minuteOfDay < endMinute {
                results.append(candidate)
                candidate = candidate.addingTimeInterval(interval)
                continue
            }

            if minuteOfDay < startMinute {
                var comps = calendar.dateComponents([.year, .month, .day], from: candidate)
                comps.hour = settings.activeStartHour
                comps.minute = settings.activeStartMinute
                comps.second = 0
                if let adjusted = calendar.date(from: comps) {
                    candidate = adjusted
                    continue
                }
            }

            candidate = nextActiveStart(after: candidate, settings: settings, calendar: calendar)
        }

        return results
    }

    static func snoozeDate(settings: ReminderSettings) -> Date {
        let snoozeMinutes = max(5, settings.reminderIntervalMinutes / 2)
        return Date().addingTimeInterval(TimeInterval(snoozeMinutes * 60))
    }

    // MARK: - Private

    private static func nextActiveStart(
        after date: Date,
        settings: ReminderSettings,
        calendar: Calendar
    ) -> Date {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) else {
            return date.addingTimeInterval(86400)
        }
        var comps = calendar.dateComponents([.year, .month, .day], from: nextDay)
        comps.hour = settings.activeStartHour
        comps.minute = settings.activeStartMinute
        comps.second = 0
        return calendar.date(from: comps) ?? date.addingTimeInterval(86400)
    }
}


// MARK: - ===== NotificationController.swift =====
// Source: iCareWatch/Features/Notification/NotificationController.swift

import WatchKit
import SwiftUI

final class NotificationController: WKUserNotificationHostingController<WatchNotificationBody> {

    override var body: WatchNotificationBody {
        WatchNotificationBody()
    }

    override func didReceive(_ notification: UNNotification) {
        let settings = SettingsStore.loadSettings()
        if settings.hapticsEnabled {
            WKInterfaceDevice.current().play(.notification)
        }
    }
}

struct WatchNotificationBody: View {

    var body: some View {
        VStack(spacing: ICareSpacing.sm) {
            Text("Time for a break")
                .font(ICareTypography.headline)
                .foregroundStyle(ICareColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Look away for 20 seconds")
                .font(ICareTypography.body)
                .foregroundStyle(ICareColors.textSecondary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)

            Button {
                let now = Date()
                NotificationCenter.default.post(
                    name: .iCareStartBreak,
                    object: nil,
                    userInfo: ["breakStartedAt": now.timeIntervalSince1970]
                )
            } label: {
                Text("Start")
                    .font(ICareTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ICareSpacing.md)
                    .background(ICareColors.brand)
                    .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.md))
            }
            .buttonStyle(.plain)

        }
        .padding(.horizontal, ICareSpacing.md)
        .padding(.vertical, ICareSpacing.sm)
        .background(ICareColors.surface)
    }
}

extension Notification.Name {
    static let iCareStartBreak = Notification.Name("icare.action.startBreak")
}
