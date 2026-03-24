# Acceptance Criteria

## MVP Must-Haves

- User can enable reminders in under one minute.
- App clearly shows whether reminders are active, paused, or blocked by disabled notifications.
- Reminder interval and break duration are configurable.
- Reminders respect working hours and weekday settings.
- iPhone-only users can complete the full reminder-to-countdown flow.
- Apple Watch users can complete the full reminder-to-countdown flow from the wrist.
- Completed breaks are tracked for today.

## Reminder Behavior

- A valid next reminder is scheduled after setup.
- Changing settings recomputes future reminders correctly.
- Pausing reminders prevents further reminders until resumed.
- Resuming reminders schedules the next valid reminder cleanly.
- Snoozing affects only the next reminder.
- Ignored reminders do not create repeated nagging notifications.
- Late taps still open the countdown flow successfully.

## Notification and Platform Behavior

- The app handles notification authorization denial gracefully.
- The home/status UI explains when reminders cannot function because permissions are off.
- Behavior remains coherent when both iPhone and Watch are present.
- The app recovers reminder state cleanly after app relaunch.
- The app recovers reminder state as predictably as platform limits allow after reboot.

## UX Quality Bar

- Notification copy is calm, direct, and non-medical.
- The countdown UI is readable at a glance.
- The app has no unnecessary dashboard complexity.
- Sound is off by default.
- Watch haptics feel subtle rather than aggressive.

## Release Blockers

Do not ship if any of these are unresolved:

- reminders silently stop scheduling
- users cannot tell whether reminders are active
- notification-denied state is unclear
- Watch and phone behavior conflicts in a confusing way
- countdown completion does not reliably record state

## Manual QA Scenarios

1. First launch with permission granted.
2. First launch with permission denied.
3. iPhone-only reminder flow.
4. Paired iPhone + Watch reminder flow.
5. Pause then resume.
6. Snooze next reminder.
7. Outside working hours.
8. Weekdays-only schedule on a weekend.
9. Tap reminder late.
10. Reopen app after force quit.
11. Reboot device and verify reminder recovery behavior.
