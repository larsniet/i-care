# User Flows

## Flow 1: First-Time Setup

1. User opens the app for the first time.
2. App explains the core loop in one screen.
3. User grants notification permission.
4. User chooses reminder schedule.
5. User chooses haptics and optional sound.
6. User activates reminders.
7. App shows active state and next reminder time.

## Flow 2: iPhone Reminder

1. Local notification fires on iPhone.
2. Phone vibrates and optionally plays sound.
3. Notification copy prompts the user to look into the distance.
4. User taps the notification.
5. Countdown screen opens on iPhone.
6. User completes the 20-second break.
7. App records completion and returns to idle.

## Flow 3: Apple Watch Reminder

1. Local notification surfaces on Apple Watch.
2. Watch provides a subtle haptic.
3. User taps the notification on the watch.
4. Countdown runs on the watch.
5. User completes the break without touching the phone.
6. Completion state syncs back to shared app state.

## Flow 4: Pause and Resume

1. User opens the app.
2. User taps pause.
3. App clearly indicates reminders are paused.
4. Scheduled reminder state updates accordingly.
5. User later resumes reminders.
6. App recalculates the next reminder and shows active status.

## Flow 5: Snooze

1. Reminder fires.
2. User chooses snooze.
3. App delays only the next reminder.
4. Normal cadence resumes after the snoozed reminder completes or expires.

## Flow 6: Notification Permission Denied

1. User denies notification permission or disables it later.
2. App detects the disabled state on launch and in settings.
3. App shows that reminders cannot function correctly.
4. App offers a clear path to re-enable notifications in system settings.

## Flow 7: Reminder Outside Active Hours

1. Reminder engine calculates the next eligible reminder.
2. If current time is outside the active window, the reminder is not fired.
3. App schedules the next valid reminder inside the configured window.

## Flow 8: Late Tap

1. User taps a reminder after it originally fired.
2. App still opens the countdown.
3. Completion is recorded normally.
4. Future reminders continue on the standard schedule model.
