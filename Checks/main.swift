// Date-logic checks the simulator can't exercise (it can't change its clock or time zone).
// Run with Checks/run.sh, which compiles this against the real sources in several time zones.

import Foundation

var failures = 0

func check(_ condition: Bool, _ message: String) {
    if !condition {
        failures += 1
        print("FAIL [\(TimeZone.current.identifier)] \(message)")
    }
}

let calendar = Calendar.current

/// A local wall-clock time on a fixed date: Friday 2026-10-23 unless a day is given.
func at(_ hour: Int, _ minute: Int, day: Int = 23, month: Int = 10) -> Date {
    calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute))!
}

func parts(_ date: Date) -> (day: Int, hour: Int, minute: Int) {
    let c = calendar.dateComponents([.day, .hour, .minute], from: date)
    return (c.day!, c.hour!, c.minute!)
}

var settings = ReminderSettings()
settings.remindersEnabled = true // 20 min interval, active 09:00–17:00 by default

// Inside active hours: one interval later.
check(parts(ReminderEngine.nextReminderDate(after: at(10, 0), settings: settings)!) == (23, 10, 20),
      "10:00 should remind at 10:20")

// Before the window opens: at the start of the window.
check(parts(ReminderEngine.nextReminderDate(after: at(7, 0), settings: settings)!) == (23, 9, 0),
      "07:00 should remind at 09:00 the same day")

// After the window closes: next day's start.
check(parts(ReminderEngine.nextReminderDate(after: at(16, 50), settings: settings)!) == (24, 9, 0),
      "16:50 on Friday should remind at 09:00 Saturday")

// Weekdays only: Friday evening skips to Monday.
var weekdays = settings
weekdays.weekdaysOnly = true
check(parts(ReminderEngine.nextReminderDate(after: at(16, 50), settings: weekdays)!) == (26, 9, 0),
      "Friday 16:50 with weekdays only should remind Monday 09:00")
check(parts(ReminderEngine.nextReminderDate(after: at(12, 0, day: 24), settings: weekdays)!) == (26, 9, 0),
      "Saturday noon with weekdays only should remind Monday 09:00")

// Active hours off: crosses midnight normally.
var anytime = settings
anytime.activeHoursEnabled = false
check(parts(ReminderEngine.nextReminderDate(after: at(23, 50), settings: anytime)!) == (24, 0, 10),
      "23:50 with active hours off should remind at 00:10")

// Reminders are always a whole interval apart in real time, even across a DST change
// (29 March 2026 in Europe, 8 March 2026 in the US).
for (day, month) in [(29, 3), (8, 3), (25, 10), (1, 11)] {
    let start = at(0, 30, day: day, month: month)
    let dates = ReminderEngine.upcomingReminderDates(after: start, settings: anytime, limit: 12)
    let gaps = zip(dates, dates.dropFirst()).map { $1.timeIntervalSince($0) }
    check(gaps.allSatisfy { $0 == 20 * 60 }, "reminders on \(day)/\(month) should stay 20 min apart")
}

// The batch respects the limit and never schedules outside active hours.
let batch = ReminderEngine.upcomingReminderDates(after: at(8, 0), settings: settings, limit: 50)
check(batch.count == 50, "should schedule a full batch of 50")
check(batch.allSatisfy { (9..<17).contains(calendar.component(.hour, from: $0)) },
      "every scheduled reminder should fall inside 09:00–17:00")

// Disabled reminders schedule nothing.
check(ReminderEngine.upcomingReminderDates(after: at(10, 0), settings: ReminderSettings()).isEmpty,
      "disabled reminders should schedule nothing")

// New day: yesterday's summary and records stop counting.
let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
check(!DailySummary(date: calendar.startOfDay(for: yesterday)).isToday, "yesterday's summary should not be today")
check(DailySummary().isToday, "a fresh summary should be today")

let domain = ProcessInfo.processInfo.processName
UserDefaults.standard.removePersistentDomain(forName: domain)
let summary = CompletionTracker.mergeTodayRecords([
    BreakRecord(id: "old", startedAt: yesterday, completedAt: yesterday),
    BreakRecord(id: "new", startedAt: Date(), completedAt: Date()),
])
check(summary.completedBreakCount == 1, "only today's break should count, got \(summary.completedBreakCount)")
check(CompletionTracker.loadTodayRecords().map(\.id) == ["new"], "today's records should exclude yesterday")
UserDefaults.standard.removePersistentDomain(forName: domain)

if failures == 0 {
    print("ok [\(TimeZone.current.identifier)]")
} else {
    exit(1)
}
