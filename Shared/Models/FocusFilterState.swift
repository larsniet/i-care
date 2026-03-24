import Foundation

struct FocusFilterState: Codable, Equatable, Sendable {
    var overrideActive: Bool = false
    var enableReminders: Bool = true
    var intervalOverrideMinutes: Int? = nil
}
