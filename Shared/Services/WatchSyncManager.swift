import Foundation
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
