import Foundation

enum CompletionTracker {

    private static let summaryKey = "icare.daily_summary"
    private static let recordsKey = "icare.break_records"
    private static let maxRecords = 50

    private static var defaults: UserDefaults { .standard }

    // MARK: - Daily Summary

    static func loadTodaySummary() -> DailySummary {
        guard let data = defaults.data(forKey: summaryKey),
              let summary = try? JSONDecoder().decode(DailySummary.self, from: data),
              summary.isToday
        else { return DailySummary() }
        return summary
    }

    static func save(_ summary: DailySummary) {
        guard let data = try? JSONEncoder().encode(summary) else { return }
        defaults.set(data, forKey: summaryKey)
    }

    // MARK: - Break Records

    static func recordBreak(
        type: BreakCompletionType,
        device: DeviceType,
        into summary: inout DailySummary
    ) {
        if !summary.isToday {
            summary = DailySummary()
        }

        let record = BreakRecord(
            completedAt: Date(),
            sourceDevice: device,
            completionType: type
        )

        switch type {
        case .completed:
            summary.completedBreakCount += 1
            summary.lastCompletedBreakAt = Date()
        case .skipped:
            summary.skippedBreakCount += 1
        case .cancelled:
            break
        }

        save(summary)
        appendRecord(record)
    }

    static func loadTodayRecords() -> [BreakRecord] {
        let calendar = Calendar.current
        return loadRecords().filter { calendar.isDateInToday($0.completedAt) }
    }

    // MARK: - Private

    private static func appendRecord(_ record: BreakRecord) {
        var records = loadRecords()
        records.append(record)
        if records.count > maxRecords {
            records = Array(records.suffix(maxRecords))
        }
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: recordsKey)
        }
    }

    private static func loadRecords() -> [BreakRecord] {
        guard let data = defaults.data(forKey: recordsKey),
              let records = try? JSONDecoder().decode([BreakRecord].self, from: data)
        else { return [] }
        return records
    }
}
