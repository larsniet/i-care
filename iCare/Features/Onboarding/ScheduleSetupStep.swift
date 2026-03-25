import SwiftUI

struct ScheduleSetupStep: View {
    @EnvironmentObject private var appState: AppState

    private var activeHoursEnabled: Binding<Bool> {
        Binding(
            get: { appState.settings.activeHoursEnabled },
            set: { appState.settings.activeHoursEnabled = $0 }
        )
    }

    private let intervalOptions = [15, 20, 30, 45]
    private let breakOptions = [10, 20, 30]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Set your\nschedule")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(ICareColors.textPrimary)
                    .padding(.bottom, ICareSpacing.sm)

                Text("Customize how often you receive reminders to rest your eyes and maintain focus.")
                    .font(ICareTypography.body)
                    .foregroundStyle(ICareColors.textSecondary)
                    .padding(.bottom, ICareSpacing.xxl)

                // MARK: - Durations

                sectionLabel("DURATIONS")

                VStack(spacing: 0) {
                    settingsRow(
                        title: "Interval",
                        subtitle: "Remind me every...",
                        trailing: {
                            Picker("", selection: intervalBinding) {
                                ForEach(intervalOptions, id: \.self) { m in
                                    Text("\(m)m").tag(m)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(ICareColors.brand)
                        }
                    )

                    Divider()
                        .padding(.leading, ICareSpacing.base)

                    settingsRow(
                        title: "Break Duration",
                        subtitle: "Length of your rest",
                        trailing: {
                            Picker("", selection: breakBinding) {
                                ForEach(breakOptions, id: \.self) { s in
                                    Text("\(s)s").tag(s)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(ICareColors.brand)
                        }
                    )
                }
                .background(ICareColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
                .padding(.bottom, ICareSpacing.lg)

                // MARK: - Availability

                sectionLabel("AVAILABILITY")

                VStack(spacing: 0) {
                    settingsRow(
                        title: "Active Hours",
                        subtitle: "Only notify during work",
                        trailing: {
                            Toggle("", isOn: activeHoursEnabled)
                                .labelsHidden()
                                .tint(ICareColors.brand)
                        }
                    )

                    if activeHoursEnabled.wrappedValue {
                        HStack(spacing: ICareSpacing.sm) {
                            timeBlock(label: "START", binding: startTimeBinding)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(ICareColors.textTertiary)
                            timeBlock(label: "END", binding: endTimeBinding)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, ICareSpacing.base)
                        .padding(.bottom, ICareSpacing.base)
                    }

                    Divider()
                        .padding(.leading, ICareSpacing.base)

                    settingsRow(
                        title: "Weekdays only",
                        subtitle: "Mute on Saturday & Sunday",
                        trailing: {
                            Toggle("", isOn: weekdaysOnlyBinding)
                                .labelsHidden()
                                .tint(ICareColors.brand)
                        }
                    )
                }
                .background(ICareColors.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: ICareSpacing.CornerRadius.lg))
            }
            .padding(.horizontal, ICareSpacing.lg)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(ICareColors.textTertiary)
            .tracking(1.5)
            .padding(.bottom, ICareSpacing.sm)
            .padding(.leading, ICareSpacing.xs)
    }

    private func settingsRow<Trailing: View>(
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center, spacing: ICareSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ICareColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(ICareColors.textTertiary)
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, ICareSpacing.base)
        .padding(.vertical, ICareSpacing.md)
    }

    private func timeBlock(label: String, binding: Binding<Date>) -> some View {
        HStack(spacing: ICareSpacing.xs) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(ICareColors.textTertiary)
                .tracking(0.5)
            DatePicker("", selection: binding, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(ICareColors.brand)
        }
    }

    // MARK: - Bindings

    private var intervalBinding: Binding<Int> {
        Binding(
            get: { appState.settings.reminderIntervalMinutes },
            set: { appState.settings.reminderIntervalMinutes = $0 }
        )
    }

    private var breakBinding: Binding<Int> {
        Binding(
            get: { appState.settings.breakDurationSeconds },
            set: { appState.settings.breakDurationSeconds = $0 }
        )
    }

    private var weekdaysOnlyBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.weekdaysOnly },
            set: { appState.settings.weekdaysOnly = $0 }
        )
    }

    private let minimumActiveWindowMinutes = 60

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: { Self.timeDate(hour: appState.settings.activeStartHour, minute: appState.settings.activeStartMinute) },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
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

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: { Self.timeDate(hour: appState.settings.activeEndHour, minute: appState.settings.activeEndMinute) },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
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

    private static func timeDate(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
