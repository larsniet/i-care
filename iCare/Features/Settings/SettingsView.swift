import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedIntervalMinutes = 20
    @State private var selectedBreakDurationSeconds = 20

    private let intervalOptions = [15, 20, 30, 45]
    private let breakDurationOptions = [10, 20, 30]

    var body: some View {
        ZStack(alignment: .top) {
            pageBackground

            ScrollView {
                VStack(spacing: ICareSpacing.lg) {
                    pageHeader
                    scheduleSection
                    activeHoursSection
                    notificationsSection
                    statusSection
                }
                .padding(.horizontal, ICareSpacing.lg)
                .padding(.top, ICareSpacing.base)
                .padding(.bottom, ICareSpacing.xl)
                .readableWidth()
            }
        }
        .onAppear { syncLocalSelectionsFromSettings() }
        .onChange(of: appState.settings) { _, _ in
            syncLocalSelectionsFromSettings()
        }
        .onChange(of: selectedIntervalMinutes) { _, newValue in
            guard newValue != appState.settings.reminderIntervalMinutes else { return }
            Task { @MainActor in
                await Task.yield()
                var s = appState.settings
                s.reminderIntervalMinutes = newValue
                appState.settings = s
            }
        }
        .onChange(of: selectedBreakDurationSeconds) { _, newValue in
            guard newValue != appState.settings.breakDurationSeconds else { return }
            Task { @MainActor in
                await Task.yield()
                var s = appState.settings
                s.breakDurationSeconds = newValue
                appState.settings = s
            }
        }
    }

    // MARK: - Header & Background

    private var pageHeader: some View {
        HStack {
            Text("Settings")
                .scaledFont(size: 18, weight: .semibold)
                .foregroundStyle(ICareColors.textPrimary)
            Spacer()
        }
    }

    private var pageBackground: some View {
        ZStack(alignment: .top) {
            ICareColors.surface.ignoresSafeArea()
            LinearGradient(
                colors: [ICareColors.brandMuted, ICareColors.surface],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.45)
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: ICareSpacing.sm) {
            sectionLabel("SCHEDULE")

            VStack(spacing: 0) {
                settingsRow {
                    pickerRowLayout {
                        Text("Interval")
                            .scaledFont(size: 15, weight: .medium)
                            .foregroundStyle(ICareColors.textPrimary)
                        Spacer()
                        Picker("", selection: intervalMinutesBinding) {
                            ForEach(intervalOptions, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(ICareColors.brand)
                    }
                }

                rowDivider

                settingsRow {
                    pickerRowLayout {
                        Text("Break Duration")
                            .scaledFont(size: 15, weight: .medium)
                            .foregroundStyle(ICareColors.textPrimary)
                        Spacer()
                        Picker("", selection: breakDurationSecondsBinding) {
                            ForEach(breakDurationOptions, id: \.self) { seconds in
                                Text("\(seconds) sec").tag(seconds)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(ICareColors.brand)
                    }
                }
            }
            .background(ICareColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
        }
    }

    // MARK: - Active Hours

    private var activeHoursSection: some View {
        VStack(alignment: .leading, spacing: ICareSpacing.sm) {
            sectionLabel("ACTIVE HOURS")

            VStack(spacing: 0) {
                settingsRow {
                    Toggle("Limit to Active Hours", isOn: activeHoursEnabledBinding)
                        .scaledFont(size: 15, weight: .medium)
                        .foregroundStyle(ICareColors.textPrimary)
                        .tint(ICareColors.brand)
                }

                if appState.settings.activeHoursEnabled {
                    rowDivider

                    settingsRow {
                        DatePicker(
                            "Start",
                            selection: activeStartTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .scaledFont(size: 15, weight: .medium)
                        .foregroundStyle(ICareColors.textPrimary)
                        .tint(ICareColors.brand)
                    }

                    rowDivider

                    settingsRow {
                        DatePicker(
                            "End",
                            selection: activeEndTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .scaledFont(size: 15, weight: .medium)
                        .foregroundStyle(ICareColors.textPrimary)
                        .tint(ICareColors.brand)
                    }
                }

                rowDivider

                settingsRow {
                    Toggle("Weekdays Only", isOn: weekdaysOnlyBinding)
                        .scaledFont(size: 15, weight: .medium)
                        .foregroundStyle(ICareColors.textPrimary)
                        .tint(ICareColors.brand)
                }
            }
            .background(ICareColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
            .animation(.easeInOut(duration: 0.25), value: appState.settings.activeHoursEnabled)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: ICareSpacing.sm) {
            sectionLabel("NOTIFICATIONS")

            VStack(spacing: 0) {
                settingsRow {
                    Toggle("Sound", isOn: soundEnabledBinding)
                        .scaledFont(size: 15, weight: .medium)
                        .foregroundStyle(ICareColors.textPrimary)
                        .tint(ICareColors.brand)
                }

                rowDivider

                settingsRow {
                    Toggle("Haptics", isOn: hapticsEnabledBinding)
                        .scaledFont(size: 15, weight: .medium)
                        .foregroundStyle(ICareColors.textPrimary)
                        .tint(ICareColors.brand)
                }
            }
            .background(ICareColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: ICareSpacing.sm) {
            sectionLabel("STATUS")

            VStack(spacing: 0) {
                settingsRow {
                    HStack(spacing: ICareSpacing.md) {
                        Image(systemName: notificationStatusIcon)
                            .scaledFont(size: 22)
                            .foregroundStyle(notificationStatusColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Permission")
                                .scaledFont(size: 15, weight: .medium)
                                .foregroundStyle(ICareColors.textPrimary)
                            Text(notificationStatusDescription)
                                .scaledFont(size: 13)
                                .foregroundStyle(ICareColors.textSecondary)
                        }

                        Spacer(minLength: 0)
                    }
                }

                if appState.notificationAuthorizationStatus == .notDetermined {
                    rowDivider

                    settingsRow {
                        Button {
                            Task { await appState.requestNotificationPermission() }
                        } label: {
                            HStack {
                                Text("Enable Notifications")
                                    .scaledFont(size: 15, weight: .semibold)
                                    .foregroundStyle(ICareColors.brand)
                                Spacer()
                                Image(systemName: "bell.fill")
                                    .scaledFont(size: 13, weight: .semibold)
                                    .foregroundStyle(ICareColors.brand)
                            }
                        }
                    }
                }

                if appState.notificationAuthorizationStatus == .denied {
                    rowDivider

                    settingsRow {
                        Button {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                openURL(url)
                            }
                        } label: {
                            HStack {
                                Text("Open Settings")
                                    .scaledFont(size: 15, weight: .semibold)
                                    .foregroundStyle(ICareColors.brand)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .scaledFont(size: 13, weight: .semibold)
                                    .foregroundStyle(ICareColors.brand)
                            }
                        }
                    }
                }
            }
            .background(ICareColors.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
        }
    }

    // MARK: - Shared Components

    /// Label and value side by side, or stacked once the text is too big to fit.
    private var pickerRowLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: ICareSpacing.xs))
            : AnyLayout(HStackLayout())
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .scaledFont(size: 11, weight: .semibold)
            .foregroundStyle(ICareColors.textTertiary)
            .tracking(1.5)
            .padding(.leading, ICareSpacing.xs)
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, ICareSpacing.base)
            .padding(.vertical, ICareSpacing.md)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(ICareColors.separator)
            .padding(.leading, ICareSpacing.base)
    }

    // MARK: - Bindings

    private var intervalMinutesBinding: Binding<Int> {
        Binding(
            get: { selectedIntervalMinutes },
            set: { selectedIntervalMinutes = $0 }
        )
    }

    private var breakDurationSecondsBinding: Binding<Int> {
        Binding(
            get: { selectedBreakDurationSeconds },
            set: { selectedBreakDurationSeconds = $0 }
        )
    }

    private let minimumActiveWindowMinutes = 60

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

                let startMinutes = s.activeStartHour * 60 + s.activeStartMinute
                let endMinutes = s.activeEndHour * 60 + s.activeEndMinute
                if endMinutes - startMinutes < minimumActiveWindowMinutes {
                    let clamped = min(startMinutes + minimumActiveWindowMinutes, 24 * 60 - 1)
                    s.activeEndHour = clamped / 60
                    s.activeEndMinute = clamped % 60
                }

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

                let startMinutes = s.activeStartHour * 60 + s.activeStartMinute
                let endMinutes = s.activeEndHour * 60 + s.activeEndMinute
                if endMinutes - startMinutes < minimumActiveWindowMinutes {
                    let clamped = max(endMinutes - minimumActiveWindowMinutes, 0)
                    s.activeStartHour = clamped / 60
                    s.activeStartMinute = clamped % 60
                }

                appState.settings = s
            }
        )
    }

    private var activeHoursEnabledBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.activeHoursEnabled },
            set: { newValue in
                var s = appState.settings
                s.activeHoursEnabled = newValue
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

    private func syncLocalSelectionsFromSettings() {
        if selectedIntervalMinutes != appState.settings.reminderIntervalMinutes {
            selectedIntervalMinutes = appState.settings.reminderIntervalMinutes
        }
        if selectedBreakDurationSeconds != appState.settings.breakDurationSeconds {
            selectedBreakDurationSeconds = appState.settings.breakDurationSeconds
        }
    }

    // MARK: - Status Helpers

    private var notificationStatusIcon: String {
        switch appState.notificationAuthorizationStatus {
        case .authorized: "checkmark.circle.fill"
        case .denied: "xmark.circle.fill"
        case .notDetermined: "bell.badge"
        case .provisional: "checkmark.circle"
        }
    }

    private var notificationStatusColor: Color {
        switch appState.notificationAuthorizationStatus {
        case .authorized: ICareColors.brand
        case .denied: ICareColors.statusBlocked
        case .notDetermined: ICareColors.textSecondary
        case .provisional: ICareColors.brandSubtle
        }
    }

    private var notificationStatusDescription: String {
        switch appState.notificationAuthorizationStatus {
        case .authorized: "Allowed — reminders can be delivered."
        case .denied: "Blocked in system settings."
        case .notDetermined: "Not requested yet."
        case .provisional: "Quiet delivery — limited alerts."
        }
    }
}
