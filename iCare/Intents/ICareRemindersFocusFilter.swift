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

    var filterState: FocusFilterState {
        FocusFilterState(
            overrideActive: !enableReminders || intervalMinutes != nil,
            enableReminders: enableReminders,
            intervalOverrideMinutes: intervalMinutes
        )
    }

    func perform() async throws -> some IntentResult {
        SettingsStore.save(filterState)
        // iOS only runs this while iCare is in the foreground, so apply it right away.
        await MainActor.run { AppState.current?.refreshFocusFilterState() }
        return .result()
    }

    /// iOS doesn't run `perform()` while iCare is in the background, so a Focus that
    /// starts or ends then is missed. Ask the system for the active filter on launch
    /// and on every return to the foreground instead.
    @MainActor
    static func syncFromSystem(into appState: AppState) async {
        // `current` throws when no Focus with this filter is on, which means no override.
        let state = (try? await current)?.filterState ?? FocusFilterState()
        SettingsStore.save(state)
        appState.refreshFocusFilterState()
    }
}
