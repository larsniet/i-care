# Implementation Plan

## Delivery Strategy

Build the MVP in vertical slices so reminder behavior is proven on real devices as early as possible.

## Milestone 1: Foundations

Deliver:

- Xcode project with iOS and watchOS targets
- shared models and settings store
- design tokens and minimal app shell
- local persistence via App Group

Exit criteria:

- app launches on iPhone and Watch
- settings can be saved and read across targets

## Milestone 2: Reminder Engine

Deliver:

- reminder scheduling logic
- active-hours and weekdays filtering
- pause and resume behavior
- next reminder calculation

Exit criteria:

- app can compute and reschedule the next valid reminder consistently
- pause state is visible and reliable

## Milestone 3: Notifications

Deliver:

- permission request flow
- local notification scheduling
- notification categories and actions
- handling for disabled permissions

Exit criteria:

- notifications fire on device
- user can understand whether reminders are operational

## Milestone 4: Countdown Flow

Deliver:

- phone countdown screen
- watch countdown screen
- completion, cancel, and skip handling
- post-countdown rescheduling

Exit criteria:

- notification tap reaches countdown on both platforms
- completed breaks update local state

## Milestone 5: MVP Polish

Deliver:

- onboarding flow
- home/status screen
- settings screen
- basic daily completed-break display
- UX polish for calm visual style

Exit criteria:

- first-time setup can be finished in under one minute
- reminder state is obvious at a glance

## Milestone 6: Device QA

Deliver:

- iPhone-only test pass
- iPhone + Watch paired-device test pass
- reboot/relaunch behavior verification
- edge-case pass for denied permissions, off-hours, and missed reminders

Exit criteria:

- app behavior matches `docs/delivery/acceptance_criteria.md`

## Recommended Task Breakdown

1. Create shared settings and runtime models.
2. Build the Reminder Engine with unit-testable date logic.
3. Add notification permissions and scheduling.
4. Build the iPhone countdown flow.
5. Build the Watch countdown flow.
6. Add completion tracking and today summary.
7. Add pause, resume, and snooze controls.
8. Finish onboarding and settings UX.
9. Run real-device QA and refine notification behavior.

## Suggested Early Prototypes

- reminder scheduling logic in isolation
- notification handling on real iPhone hardware
- watch notification and countdown handoff on paired devices

These are the highest-risk pieces and should be proven early.
