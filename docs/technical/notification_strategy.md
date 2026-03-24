# Notification Strategy

## Why This Needs Its Own Spec

The MVP depends on notification reliability more than any other subsystem. The app should be designed around scheduled local notifications, not around assumptions about long-running background timers.

## Design Principles

- reminders must be subtle
- reminder behavior must be predictable
- the app must avoid nagging
- the user must always understand whether notifications can work

## Notification Model

Use local notifications as the primary delivery mechanism for reminders.

Each reminder should:

- fire at the next eligible scheduled time
- contain short neutral copy
- support tapping into the countdown flow
- optionally expose quick actions such as snooze or skip

## Scheduling Rules

- Only schedule reminders inside the active time window.
- Respect weekdays-only settings.
- When settings change, clear and recompute future reminder requests.
- When reminders are paused, remove or withhold future requests according to the chosen pause model.
- When a break completes, schedule the next eligible reminder.
- If the user ignores a reminder, continue normal cadence without repeated retries.

## Authorization Handling

The app must:

- request notification permission during onboarding
- expose current authorization state in the app UI
- explain clearly when reminders cannot function because permission is denied
- provide a route to system settings if permission must be re-enabled

## iPhone and Watch Behavior

Expected behavior:

- iPhone-only users receive and handle reminders on phone
- paired users should get a coherent experience across phone and watch
- Apple Watch should feel like the preferred interaction surface when available

This needs real-device validation because final presentation depends on Apple platform behavior and pairing state.

## Notification Content Guidelines

Good examples:

- "Look away for 20 seconds"
- "Time for a visual break"
- "Look at something in the distance"

Avoid:

- guilt-based language
- medical claims
- noisy or overly cheerful tone

## Quick Actions

MVP-acceptable actions:

- Start now
- Snooze
- Skip

If actions complicate the first release too much, the minimum acceptable path is tap-to-open countdown plus in-app pause/snooze controls.

## Failure Modes to Test

- notification permission denied
- notification permission later revoked
- app relaunched after reminders were active
- device reboot
- paired watch unavailable
- watch and phone both present
- user taps reminder after delay

## Implementation Notes

- centralize notification identifiers and categories
- make scheduling idempotent
- keep reminder-copy variants limited
- log scheduling decisions during development to debug edge cases on device
