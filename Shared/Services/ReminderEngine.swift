import Foundation

enum ReminderEngine {

    static let maxBatchSize = 50

    /// Computes the next valid reminder date after `referenceDate`, respecting
    /// active hours and weekday settings. Returns nil if reminders are disabled
    /// or no valid slot exists within 7 days.
    static func nextReminderDate(
        after referenceDate: Date = Date(),
        settings: ReminderSettings
    ) -> Date? {
        upcomingReminderDates(after: referenceDate, settings: settings, limit: 1).first
    }

    /// Computes up to `limit` upcoming reminder dates, for batch scheduling.
    /// iOS allows up to 64 pending notifications per app.
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

    /// Convenience: computes the snooze target (half the normal interval, clamped
    /// to 5-minute minimum).
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
