# Data Model

## Modeling Goals

- keep MVP storage simple
- make reminder state easy to inspect
- support both iPhone and Watch without a backend

## Core Entities

### ReminderSettings

Purpose:

- defines how reminders should behave

Fields:

- `reminderIntervalMinutes: Int`
- `breakDurationSeconds: Int`
- `hapticsEnabled: Bool`
- `soundEnabled: Bool`
- `weekdaysOnly: Bool`
- `activeStartTime: DateComponents`
- `activeEndTime: DateComponents`
- `remindersEnabled: Bool`

### ReminderRuntimeState

Purpose:

- stores current operational state

Fields:

- `nextReminderAt: Date?`
- `isPaused: Bool`
- `pausedUntil: Date?`
- `lastReminderFiredAt: Date?`
- `lastReminderHandledAt: Date?`

### BreakRecord

Purpose:

- records a completed break

Fields:

- `id: UUID`
- `startedAt: Date`
- `completedAt: Date`
- `sourceDevice: DeviceType`
- `completionType: BreakCompletionType`

Enums:

- `DeviceType`: `iphone`, `watch`
- `BreakCompletionType`: `completed`, `skipped`, `cancelled`

### DailySummary

Purpose:

- powers the lightweight "today" state

Fields:

- `date: Date`
- `completedBreakCount: Int`
- `skippedBreakCount: Int`
- `lastCompletedBreakAt: Date?`

## Persistence Recommendations

### App Group UserDefaults

Good fit for:

- settings
- active/paused state
- next reminder timestamp
- daily counters if kept very small

### Expand Later Only If Needed

Use a more formal store only if post-MVP features require history, queries, or trends.

Candidates later:

- SwiftData
- Core Data

## Derived State

The UI should compute these values from stored settings and runtime state rather than persist them separately when possible:

- whether the app is currently active
- whether the current time is inside the allowed schedule
- whether notifications are actionable
- what message should be shown on the home screen

## Scheduling Inputs

The Reminder Engine should compute the next reminder from:

- current time
- `ReminderSettings`
- `ReminderRuntimeState`
- notification authorization state

## Event Sources

Important events that should trigger rescheduling:

- first launch setup completion
- settings changed
- reminders paused
- reminders resumed
- snooze requested
- break completed
- app relaunch
- authorization state changed

## State Rules

- If notifications are disabled, `remindersEnabled` can remain true, but UI must show the app is not fully operational.
- If the app is paused, `nextReminderAt` should reflect the next valid post-pause time or remain empty until resume logic recomputes it.
- If the user taps a reminder late, the break can still complete normally.
- Missed reminders should not create stacked retries.
