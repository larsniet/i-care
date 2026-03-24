import SwiftUI

import UIKit

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL

    private let intervalOptions = [15, 20, 30, 45]
    private let breakDurationOptions = [10, 20, 30]

    var body: some View {
        NavigationStack {
            List {
                Section("Schedule") {
                    Picker("Interval", selection: intervalMinutesBinding) {
                        ForEach(intervalOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Break Duration", selection: breakDurationSecondsBinding) {
                        ForEach(breakDurationOptions, id: \.self) { seconds in
                            Text("\(seconds) sec").tag(seconds)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Active Hours") {
                    DatePicker(
                        "Start",
                        selection: activeStartTimeBinding,
                        displayedComponents: .hourAndMinute
                    )

                    DatePicker(
                        "End",
                        selection: activeEndTimeBinding,
                        displayedComponents: .hourAndMinute
                    )

                    Toggle("Weekdays Only", isOn: weekdaysOnlyBinding)
                        .tint(ICareColors.brand)
                }

                Section("Notifications") {
                    Toggle("Sound", isOn: soundEnabledBinding)
                        .tint(ICareColors.brand)

                    Toggle("Haptics", isOn: hapticsEnabledBinding)
                        .tint(ICareColors.brand)
                }

                Section("Status") {
                    HStack(spacing: ICareSpacing.md) {
                        Image(systemName: notificationStatusIcon)
                            .font(.title2)
                            .foregroundStyle(notificationStatusColor)

                        VStack(alignment: .leading, spacing: ICareSpacing.xs) {
                            Text("Permission")
                                .font(ICareTypography.body)
                                .foregroundStyle(ICareColors.textPrimary)

                            Text(notificationStatusDescription)
                                .font(ICareTypography.caption)
                                .foregroundStyle(ICareColors.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }
                    .listRowInsets(EdgeInsets(
                        top: ICareSpacing.md,
                        leading: ICareSpacing.base,
                        bottom: ICareSpacing.md,
                        trailing: ICareSpacing.base
                    ))

                    if appState.notificationAuthorizationStatus == .denied {
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                        .font(ICareTypography.headline)
                        .foregroundStyle(ICareColors.brand)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(ICareColors.surface)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(ICareColors.brand)
    }

    private var intervalMinutesBinding: Binding<Int> {
        Binding(
            get: { appState.settings.reminderIntervalMinutes },
            set: { newValue in
                var s = appState.settings
                s.reminderIntervalMinutes = newValue
                appState.settings = s
            }
        )
    }

    private var breakDurationSecondsBinding: Binding<Int> {
        Binding(
            get: { appState.settings.breakDurationSeconds },
            set: { newValue in
                var s = appState.settings
                s.breakDurationSeconds = newValue
                appState.settings = s
            }
        )
    }

    private var activeStartTimeBinding: Binding<Date> {
        Binding(
            get: {
                timeDate(
                    hour: appState.settings.activeStartHour,
                    minute: appState.settings.activeStartMinute
                )
            },
            set: { newDate in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                var s = appState.settings
                s.activeStartHour = parts.hour ?? 0
                s.activeStartMinute = parts.minute ?? 0
                appState.settings = s
            }
        )
    }

    private var activeEndTimeBinding: Binding<Date> {
        Binding(
            get: {
                timeDate(
                    hour: appState.settings.activeEndHour,
                    minute: appState.settings.activeEndMinute
                )
            },
            set: { newDate in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                var s = appState.settings
                s.activeEndHour = parts.hour ?? 0
                s.activeEndMinute = parts.minute ?? 0
                appState.settings = s
            }
        )
    }

    private var weekdaysOnlyBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.weekdaysOnly },
            set: { newValue in
                var s = appState.settings
                s.weekdaysOnly = newValue
                appState.settings = s
            }
        )
    }

    private var soundEnabledBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.soundEnabled },
            set: { newValue in
                var s = appState.settings
                s.soundEnabled = newValue
                appState.settings = s
            }
        )
    }

    private var hapticsEnabledBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.hapticsEnabled },
            set: { newValue in
                var s = appState.settings
                s.hapticsEnabled = newValue
                appState.settings = s
            }
        )
    }

    private func timeDate(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }

    private var notificationStatusIcon: String {
        switch appState.notificationAuthorizationStatus {
        case .authorized:
            "checkmark.circle.fill"
        case .denied:
            "xmark.circle.fill"
        case .notDetermined:
            "bell.badge"
        case .provisional:
            "checkmark.circle"
        }
    }

    private var notificationStatusColor: Color {
        switch appState.notificationAuthorizationStatus {
        case .authorized:
            ICareColors.brand
        case .denied:
            ICareColors.statusBlocked
        case .notDetermined:
            ICareColors.textSecondary
        case .provisional:
            ICareColors.brandSubtle
        }
    }

    private var notificationStatusDescription: String {
        switch appState.notificationAuthorizationStatus {
        case .authorized:
            "Allowed — reminders can be delivered."
        case .denied:
            "Blocked in system settings."
        case .notDetermined:
            "Not requested yet."
        case .provisional:
            "Quiet delivery — limited alerts."
        }
    }
}
