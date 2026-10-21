import Foundation

enum SyncPhase: String, Codable, Sendable {
    case idle
    case work
    case awaitingBreak
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
    var todayRecords: [BreakRecord]?
    /// Device that started the current break, so either side records it correctly.
    var breakDevice: DeviceType?
    /// The iPhone's active Focus filter, mirrored to the Watch.
    var focusFilter: FocusFilterState?
    var updatedAt: Date
    var origin: SyncOrigin
}
