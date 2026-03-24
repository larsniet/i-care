import Foundation

struct DailySummary: Codable, Equatable, Sendable {
    var date: Date
    var completedBreakCount: Int = 0
    var skippedBreakCount: Int = 0
    var lastCompletedBreakAt: Date?

    init(date: Date = Calendar.current.startOfDay(for: Date())) {
        self.date = date
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
