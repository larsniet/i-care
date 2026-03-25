import AppIntents

struct ICareRemindersFocusFilter: SetFocusFilterIntent {

    static var title: LocalizedStringResource = "Eye Care Reminders"
    static var description: IntentDescription? = IntentDescription(
        "Control iCare reminders during this Focus mode.",
        categoryName: "Reminders"
    )

    @Parameter(title: "Enable Reminders", default: true)
    var enableReminders: Bool

    @Parameter(title: "Custom Interval (minutes)")
    var intervalMinutes: Int?

    var displayRepresentation: DisplayRepresentation {
        if enableReminders {
            if let interval = intervalMinutes {
                return DisplayRepresentation(stringLiteral: "Reminders every \(interval) min")
            }
            return DisplayRepresentation(stringLiteral: "Reminders enabled")
        }
        return DisplayRepresentation(stringLiteral: "Reminders paused")
    }

    func perform() async throws -> some IntentResult {
        let hasOverride = !enableReminders || intervalMinutes != nil
        let state = FocusFilterState(
            overrideActive: hasOverride,
            enableReminders: enableReminders,
            intervalOverrideMinutes: intervalMinutes
        )
        SettingsStore.save(state)
        return .result()
    }
}
