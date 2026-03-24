# MVP Specification

## Goal

Ship the smallest possible Apple-native app that reliably supports the 20-20-20 rule on iPhone and Apple Watch.

## Platforms

- iPhone app: required
- Apple Watch app: required
- Shared configuration/state between iPhone and Watch: required

## Functional Requirements

### Reminders

- Users can enable and disable reminders.
- Users can set a reminder interval.
- The default interval is 20 minutes.
- Reminders use local notifications.
- Reminders respect configured working hours.
- Reminders can be limited to weekdays only.
- If a reminder is missed, the app continues the normal cadence instead of nagging repeatedly.

### Countdown

- Tapping a reminder opens a countdown flow.
- Default break duration is 20 seconds.
- Users can customize break duration.
- The countdown UI is minimal and legible.
- Completion ends the current break and returns the app to an idle state.

### Controls

- Start reminders
- Pause reminders
- Resume reminders
- Snooze next reminder
- Skip current break

### Settings

- Interval length
- Break duration
- Haptics on/off
- Sound on/off
- Working hours
- Weekdays-only toggle
- Reminder active/inactive state

### Basic Progress State

- Show whether reminders are currently active.
- Show the next scheduled reminder time.
- Track completed breaks for today.

## Apple Watch Requirements

- Reminder notifications must surface on Apple Watch when available.
- Watch interactions must support starting and completing the countdown without requiring the phone.
- Watch should feel faster and less disruptive than the phone-only experience.

## iPhone-Only Requirements

- The full reminder loop must still work without Apple Watch.
- Users without a watch must still receive notifications, vibration, countdown, and settings controls.

## Non-Functional Requirements

- No backend required for MVP.
- No account system.
- Data stays local on device.
- Notification behavior must remain predictable across app restarts and device reboot where platform rules allow.
- UX should remain calm, sparse, and understandable in under a minute.

## Explicit Non-Goals

Do not include in v1:

- subscriptions
- ads
- accounts
- social features
- medical claims
- complex analytics
- streaks or achievements
- wellness bundles
- hydration, posture, meditation, or pomodoro features
- AI features

## Release Boundary

The MVP is ready when:

- the reminder engine works on a real device
- iPhone and Watch flows both complete end-to-end
- settings persist reliably
- users can clearly tell whether reminders are active
- the app handles disabled notifications and off-hours behavior cleanly
