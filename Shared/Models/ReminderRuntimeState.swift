import Foundation

struct ReminderRuntimeState: Codable, Equatable, Sendable {
    var nextReminderAt: Date?
    var isPaused: Bool = false
    var pausedUntil: Date?
    var lastReminderFiredAt: Date?
    var lastReminderHandledAt: Date?
}
