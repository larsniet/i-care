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
        id: String,
        startedAt: Date,
        type: BreakCompletionType,
        device: DeviceType,
        into summary: inout DailySummary
    ) {
        if !summary.isToday {
            summary = DailySummary()
        }

        let record = BreakRecord(
            id: id,
            startedAt: startedAt,
            completedAt: Date(),
            sourceDevice: device,
            completionType: type
        )
        summary = upsertRecord(record)
        save(summary)
    }

    static func loadTodayRecords() -> [BreakRecord] {
        let calendar = Calendar.current
        return loadRecords().filter { calendar.isDateInToday($0.completedAt) }
    }

    static func mergeTodayRecords(_ incoming: [BreakRecord]) -> DailySummary {
        let calendar = Calendar.current
        let existing = loadRecords()
        let historical = existing.filter { !calendar.isDateInToday($0.completedAt) }

        var mergedByID = Dictionary(uniqueKeysWithValues: loadTodayRecords().map { ($0.id, $0) })
        for record in incoming where calendar.isDateInToday(record.completedAt) {
            mergedByID[record.id] = record
        }

        let mergedToday = mergedByID.values.sorted { $0.completedAt < $1.completedAt }
        var combined = (historical + mergedToday).sorted { $0.completedAt < $1.completedAt }
        if combined.count > maxRecords {
            combined = Array(combined.suffix(maxRecords))
        }

        if let data = try? JSONEncoder().encode(combined) {
            defaults.set(data, forKey: recordsKey)
        }

        let summary = makeSummary(from: mergedToday)
        save(summary)
        return summary
    }

    // MARK: - Private

    private static func upsertRecord(_ record: BreakRecord) -> DailySummary {
        var records = loadRecords()
        if let existingIndex = records.firstIndex(where: { $0.id == record.id }) {
            records[existingIndex] = record
        } else {
            records.append(record)
        }
        if records.count > maxRecords {
            records = Array(records.suffix(maxRecords))
        }
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: recordsKey)
        }
        let todayRecords = records.filter { Calendar.current.isDateInToday($0.completedAt) }
        return makeSummary(from: todayRecords)
    }

    private static func loadRecords() -> [BreakRecord] {
        guard let data = defaults.data(forKey: recordsKey),
              let records = try? JSONDecoder().decode([BreakRecord].self, from: data)
        else { return [] }
        return records
    }

    private static func makeSummary(from records: [BreakRecord]) -> DailySummary {
        var summary = DailySummary()
        for record in records {
            switch record.completionType {
            case .completed:
                summary.completedBreakCount += 1
                if let last = summary.lastCompletedBreakAt {
                    summary.lastCompletedBreakAt = max(last, record.completedAt)
                } else {
                    summary.lastCompletedBreakAt = record.completedAt
                }
            case .skipped:
                summary.skippedBreakCount += 1
            case .cancelled:
                break
            }
        }
        return summary
    }
}
