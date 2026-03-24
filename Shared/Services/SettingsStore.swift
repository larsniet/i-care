import Foundation

enum SettingsStore {

    private static let settingsKey = "icare.settings"
    private static let runtimeKey = "icare.runtime_state"
    private static let onboardingKey = "icare.onboarding_completed"
    private static let focusFilterKey = "icare.focus_filter_state"

    private static var defaults: UserDefaults { .standard }

    // MARK: - Settings

    static func loadSettings() -> ReminderSettings {
        guard let data = defaults.data(forKey: settingsKey),
              let value = try? JSONDecoder().decode(ReminderSettings.self, from: data)
        else { return ReminderSettings() }
        return value
    }

    static func save(_ settings: ReminderSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }

    // MARK: - Runtime State

    static func loadRuntimeState() -> ReminderRuntimeState {
        guard let data = defaults.data(forKey: runtimeKey),
              let value = try? JSONDecoder().decode(ReminderRuntimeState.self, from: data)
        else { return ReminderRuntimeState() }
        return value
    }

    static func save(_ state: ReminderRuntimeState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: runtimeKey)
    }

    // MARK: - Onboarding

    static func loadOnboardingCompleted() -> Bool {
        defaults.bool(forKey: onboardingKey)
    }

    static func saveOnboardingCompleted(_ value: Bool) {
        defaults.set(value, forKey: onboardingKey)
    }

    // MARK: - Focus Filter

    static func loadFocusFilterState() -> FocusFilterState {
        guard let data = defaults.data(forKey: focusFilterKey),
              let value = try? JSONDecoder().decode(FocusFilterState.self, from: data)
        else { return FocusFilterState() }
        return value
    }

    static func save(_ state: FocusFilterState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: focusFilterKey)
    }
}
