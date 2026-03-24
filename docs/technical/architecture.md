# Proposed Architecture

## Architecture Summary

Build the MVP as a native Apple app using:

- Swift
- SwiftUI
- UserNotifications
- watchOS app target
- App Groups for shared persistence
- Watch Connectivity only where direct coordination is needed

The architecture should stay local-first. The app does not need a backend for MVP.

## System Goals

- reliable recurring reminders
- fast countdown launch from notifications
- full iPhone usability without Apple Watch
- better wrist-first experience when Apple Watch is available
- simple state model that is easy to reason about and test

## App Targets

### iOS App

Responsibilities:

- onboarding and settings
- notification permission handling
- reminder status display
- countdown UI on phone
- scheduling notifications
- local completion tracking

### watchOS App

Responsibilities:

- reminder interaction on wrist
- countdown UI on watch
- lightweight status display
- completion reporting into shared app state

## Logical Modules

### 1. Settings Store

Owns user-configurable preferences:

- reminder interval
- break duration
- haptics enabled
- sound enabled
- active hours
- weekdays-only setting
- reminders active/paused state

Implementation notes:

- persist to shared storage via App Groups
- expose observable state to both platforms
- centralize defaults in one place

### 2. Reminder Engine

Owns scheduling logic:

- compute next eligible reminder time
- skip times outside active hours
- respect weekdays-only rules
- handle pause and snooze state
- reschedule after completion, skip, or app relaunch

Implementation notes:

- base behavior on notification scheduling, not a continuously running background timer
- make scheduling idempotent so the app can safely re-run it on launch and settings changes

### 3. Notification Coordinator

Owns notification setup and delivery:

- request permission
- define notification categories and actions
- register notification content
- handle notification responses
- expose current authorization state to UI

Implementation notes:

- keep notification copy short and neutral
- use actions for snooze and skip if included in MVP
- verify how iPhone and Watch notification presentation behaves when both devices are present

### 4. Countdown Flow

Owns break execution:

- open from notification tap
- display remaining seconds
- mark break complete
- support cancel or skip

Implementation notes:

- countdown state should be lightweight and local to the active session
- completion should update persistent daily stats and trigger next scheduling pass

### 5. Completion Tracker

Owns lightweight usage data:

- breaks completed today
- last completed break timestamp
- optional short rolling history for later summaries

Implementation notes:

- keep storage minimal for MVP
- avoid analytics infrastructure

## Recommended State Flow

1. App loads persisted settings.
2. Reminder Engine computes the next valid reminder.
3. Notification Coordinator schedules the local notification.
4. User taps notification on iPhone or Watch.
5. Countdown Flow runs on the device that handled the action.
6. Completion Tracker records success.
7. Reminder Engine schedules the next reminder.

## Persistence Strategy

Use local storage only.

Recommended split:

- `UserDefaults` in an App Group for settings and lightweight state
- optional small local store later if history grows beyond simple counters

## Sync Strategy

Use the simplest possible shared-state model first:

- shared settings and basic counters through App Group storage
- Watch Connectivity only for cases where active communication is needed beyond shared persistence

Avoid building a complicated sync layer for MVP.

## Suggested Project Structure

```text
EyeCare/
  App/
  Features/
    Onboarding/
    Settings/
    ReminderStatus/
    Countdown/
  Services/
    ReminderEngine/
    NotificationCoordinator/
    SettingsStore/
    CompletionTracker/
    Sync/
  Shared/
    Models/
    Utilities/
    DesignSystem/
  WatchApp/
```

## Key Technical Decisions

### Local-first over backend

Reason:

- lower cost
- simpler build
- better privacy
- fewer failure points

### Native Apple stack over cross-platform

Reason:

- notifications are core to the product
- Apple Watch is a first-class surface
- platform behavior matters more than cross-platform reuse

### Schedule-based reminders over background timer logic

Reason:

- aligns with Apple platform constraints
- more reliable than trying to keep a timer alive in the background

## Architecture Risks

- notification behavior differs when both iPhone and Watch are present
- reminder rescheduling after reboot must be explicitly verified
- permission-denied and paused states can become confusing if not modeled cleanly
- watch sync can be overbuilt if the shared-state boundary is not kept small
