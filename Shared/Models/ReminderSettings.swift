import Foundation

struct ReminderSettings: Codable, Equatable, Sendable {
    var reminderIntervalMinutes: Int = 20
    var breakDurationSeconds: Int = 20
    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = false
    var weekdaysOnly: Bool = false
    var activeStartHour: Int = 9
    var activeStartMinute: Int = 0
    var activeEndHour: Int = 17
    var activeEndMinute: Int = 0
    var remindersEnabled: Bool = false
}
