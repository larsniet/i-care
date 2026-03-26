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
