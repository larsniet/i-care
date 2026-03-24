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

## Post-MVP Roadmap

Good additions to consider after v1:

- Apple Watch complication showing next break
- iPhone widget showing next reminder
- Quick actions in notification: Start now / Snooze 5 min / Skip
- Temporary pause modes: pause 1 hour, pause until tomorrow
- Simple daily and weekly completion stats
- Accessibility options for larger countdown text and stronger visual cues

Be cautious with:

- streaks and achievements
- visual trends or charts
- multiple reminder modes
- break categories
- "smart reminders"
- AI recommendations

These can make the app worse if they distract from the core use case.

## Scope-Creep Resistance

There will always be requests for hydration reminders, posture tracking, Pomodoro timers, meditation, focus timers, macOS support, and Android support. Most of that should be ignored initially. The product identity must stay narrow: one rule, one job, one clean loop.

## Release Boundary

The MVP is ready when:

- the reminder engine works on a real device
- iPhone and Watch flows both complete end-to-end
- settings persist reliably
- users can clearly tell whether reminders are active
- the app handles disabled notifications and off-hours behavior cleanly
