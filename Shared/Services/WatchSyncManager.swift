import Communicator
import Foundation

final class WatchSyncManager: @unchecked Sendable {
 
    static let shared = WatchSyncManager()

    var onStateReceived: (@MainActor (SyncState) -> Void)?
    var onSessionActivated: (@MainActor () -> Void)?
    var onSyncRequested: (@MainActor () -> Void)?

    private(set) var acceptedState: SyncState?

    
    var currentVersion: Int { acceptedState?.version ?? 0 }

    private init() {}

    func activate() {
        Context.observe { [weak self] context in
            self?.applyIncoming(context.content)
        }

        ImmediateMessage.observe { [weak self] message in
            switch message.identifier {
            case "stateChanged":
                let previous = self?.acceptedState
                let context = Communicator.shared.mostRecentlyReceievedContext
                self?.applyIncoming(context.content)
                if self?.acceptedState == previous,
                   Communicator.shared.currentReachability == .immediatelyReachable {
                    let request = ImmediateMessage(identifier: "requestSync")
                    Communicator.shared.send(request)
                }
            case "requestSync":
                Task { @MainActor in self?.onSyncRequested?() }
            default:
                break
            }
        }

        Communicator.State.observe { [weak self] state in
            guard state == .activated else { return }
            let context = Communicator.shared.mostRecentlyReceievedContext
            self?.applyIncoming(context.content)
            Task { @MainActor in self?.onSessionActivated?() }
        }
    }

    // MARK: - Publish

    func bootstrapAcceptedState(_ state: SyncState) {
        guard shouldAccept(state) else { return }
        acceptedState = state
    }

    func publishState(_ state: SyncState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        acceptedState = state

        let context = Context(content: ["syncState": data])
        try? Communicator.shared.sync(context)

        if Communicator.shared.currentReachability == .immediatelyReachable {
            let nudge = ImmediateMessage(identifier: "stateChanged")
            Communicator.shared.send(nudge)
        }
    }

    // MARK: - Request

    func requestSync() {
        let context = Communicator.shared.mostRecentlyReceievedContext
        applyIncoming(context.content)
        if Communicator.shared.currentReachability == .immediatelyReachable {
            let request = ImmediateMessage(identifier: "requestSync")
            Communicator.shared.send(request)
        }
    }

    // MARK: - Private

    private func applyIncoming(_ content: Content) {
        guard let data = content["syncState"] as? Data,
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
        case .phone: return 1
        case .watch: return 0
        }
    }
}
