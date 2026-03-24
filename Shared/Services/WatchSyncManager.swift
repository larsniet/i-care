import Foundation
import WatchConnectivity

final class WatchSyncManager: NSObject, WCSessionDelegate, @unchecked Sendable {

    static let shared = WatchSyncManager()

    #if os(iOS)
    var onSessionActivated: (@MainActor () -> Void)?
    var contextProvider: (() -> [String: Any])?
    var onCommandReceived: (@MainActor (_ command: String, _ payload: [String: Any]) -> Void)?
    #endif

    #if os(watchOS)
    var onContextReceived: (@MainActor (_ settings: ReminderSettings, _ onboarded: Bool, _ notificationsAuthorized: Bool, _ isPaused: Bool, _ nextReminderAt: Date?, _ breakStartedAt: Date?) -> Void)?
    var onCommandReceived: (@MainActor (_ command: String, _ payload: [String: Any]) -> Void)?
    #endif

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - iOS → Watch

    func sendContext(
        settings: ReminderSettings,
        onboarded: Bool,
        notificationsAuthorized: Bool = false,
        isPaused: Bool = false,
        nextReminderAt: Date? = nil,
        breakStartedAt: Date? = nil
    ) {
        #if os(iOS)
        guard WCSession.default.activationState == .activated else { return }

        let context = buildContext(
            settings: settings,
            onboarded: onboarded,
            notificationsAuthorized: notificationsAuthorized,
            isPaused: isPaused,
            nextReminderAt: nextReminderAt,
            breakStartedAt: breakStartedAt
        )

        try? WCSession.default.updateApplicationContext(context)

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(context, replyHandler: nil, errorHandler: nil)
        }
        #endif
    }

    #if os(iOS)
    private func buildContext(
        settings: ReminderSettings,
        onboarded: Bool,
        notificationsAuthorized: Bool,
        isPaused: Bool,
        nextReminderAt: Date?,
        breakStartedAt: Date? = nil
    ) -> [String: Any] {
        var context: [String: Any] = [
            "onboarded": onboarded,
            "notificationsAuthorized": notificationsAuthorized,
            "isPaused": isPaused,
        ]
        if let data = try? JSONEncoder().encode(settings) {
            context["settings"] = data
        }
        if let date = nextReminderAt {
            context["nextReminderAt"] = date.timeIntervalSince1970
        }
        if let date = breakStartedAt {
            context["breakStartedAt"] = date.timeIntervalSince1970
        }
        return context
    }
    #endif

    // MARK: - Bidirectional Commands

    func sendCommand(_ command: String, payload: [String: Any] = [:]) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return }
        var message: [String: Any] = ["command": command]
        message.merge(payload) { current, _ in current }
        WCSession.default.sendMessage(
            message,
            replyHandler: { [weak self] reply in
                #if os(watchOS)
                if !reply.isEmpty { self?.applyContext(reply) }
                #endif
            },
            errorHandler: nil
        )
    }

    // MARK: - Watch → iPhone

    #if os(watchOS)
    func requestContextFromPhone() {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else {
            reapplyReceivedContext()
            return
        }
        WCSession.default.sendMessage(["request": "state"], replyHandler: { [weak self] reply in
            self?.applyContext(reply)
        }, errorHandler: { [weak self] _ in
            self?.reapplyReceivedContext()
        })
    }

    func reapplyReceivedContext() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }
        let context = WCSession.default.receivedApplicationContext
        guard !context.isEmpty else { return }
        applyContext(context)
    }
    #endif

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }

        #if os(iOS)
        Task { @MainActor in
            onSessionActivated?()
        }
        #endif

        #if os(watchOS)
        let context = session.receivedApplicationContext
        if !context.isEmpty {
            applyContext(context)
        }
        requestContextFromPhone()
        #endif
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        #if os(watchOS)
        applyContext(applicationContext)
        #endif
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        if let command = message["command"] as? String {
            Task { @MainActor in
                #if os(iOS)
                onCommandReceived?(command, message)
                #endif
                #if os(watchOS)
                onCommandReceived?(command, message)
                #endif
            }
            return
        }

        #if os(watchOS)
        applyContext(message)
        #endif
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        #if os(iOS)
        if message["request"] as? String == "state" {
            let context = contextProvider?() ?? [:]
            replyHandler(context)
        } else if let command = message["command"] as? String {
            Task { @MainActor in
                onCommandReceived?(command, message)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                let context = self?.contextProvider?() ?? [:]
                replyHandler(context)
            }
        } else {
            replyHandler([:])
        }
        #endif

        #if os(watchOS)
        if let command = message["command"] as? String {
            Task { @MainActor in
                onCommandReceived?(command, message)
            }
        } else {
            applyContext(message)
        }
        replyHandler([:])
        #endif
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    // MARK: - Private

    #if os(watchOS)
    private func applyContext(_ context: [String: Any]) {
        let onboarded = context["onboarded"] as? Bool ?? false
        let notificationsAuthorized = context["notificationsAuthorized"] as? Bool ?? false
        let isPaused = context["isPaused"] as? Bool ?? false
        var settings = ReminderSettings()
        if let data = context["settings"] as? Data,
           let decoded = try? JSONDecoder().decode(ReminderSettings.self, from: data) {
            settings = decoded
        }
        var nextReminderAt: Date?
        if let ts = context["nextReminderAt"] as? TimeInterval {
            nextReminderAt = Date(timeIntervalSince1970: ts)
        }
        var breakStartedAt: Date?
        if let ts = context["breakStartedAt"] as? TimeInterval {
            breakStartedAt = Date(timeIntervalSince1970: ts)
        }
        Task { @MainActor in
            onContextReceived?(settings, onboarded, notificationsAuthorized, isPaused, nextReminderAt, breakStartedAt)
        }
    }
    #endif
}
