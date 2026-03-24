Split reference docs:

- `docs/README.md`
- `docs/product/product_brief.md`
- `docs/product/mvp_spec.md`
- `docs/product/user_flows.md`
- `docs/technical/architecture.md`
- `docs/technical/data_model.md`
- `docs/technical/notification_strategy.md`
- `docs/delivery/implementation_plan.md`
- `docs/delivery/acceptance_criteria.md`

Original business idea:

Core idea

Build a free, minimal, no-subscription 20-20-20 eye care reminder app for Apple devices.

The app helps people follow the 20-20-20 rule in a way that is actually usable in daily life:

every 20 minutes, remind the user to stop staring at a nearby screen
prompt them to look at something far away
run a simple 20-second countdown
then get out of the way

The app must work well for people with only an iPhone and feel even better for people with an Apple Watch through subtle watch haptics.

This is not a wellness platform, not a habit-gamification app, and not a subscription product. It is a focused utility that does one job cleanly.

The problem

A lot of people spend hours at screens and know about the 20-20-20 rule, but they still do not follow it consistently.

That is not because the rule is hard to understand. It is because remembering to do it is annoying, easy to ignore, and usually handled badly by existing apps.

Most existing apps in this category have one or more of these problems:

they charge for basic reminder functionality
they are overdesigned and full of clutter
they are too loud or intrusive
they rely too much on the phone when the user is not actively looking at it
they feel like generic “wellness” apps instead of a tiny practical utility
they do not support Apple Watch well
they add pointless features instead of making the core loop frictionless

The result is that users either:

stop using those apps
turn off the notifications
or never install them in the first place

There is room for a much simpler product:
a free, trustworthy reminder app that is quiet, fast, and watch-friendly.

The user need

The actual need is very narrow:

“I want something to quietly remind me to look away from my screen every 20 minutes, preferably with a subtle vibration on my watch, and then show me a 20-second countdown.”

That is the product.

The app should solve this without forcing the user to think about it.

The experience should feel like this:

user enables reminders once
user chooses whether they want haptics, sound, or both
reminder appears every 20 minutes
if they have an Apple Watch, they feel a subtle tap
if they do not, their iPhone vibrates and shows a notification
they tap once
a 20-second countdown starts
they finish
the app disappears until the next reminder

That is the whole value.

Product position

The product should be positioned as:

A free 20-20-20 reminder app for iPhone, with the best experience on Apple Watch.

That is the correct positioning because:

it works for everyone with an iPhone
it does not exclude users without a watch
it still gives watch users a much better experience
it stays easy to explain
it avoids promising more than it should

The Apple Watch should be treated as a major experience advantage, but not a requirement.

So the product is not:

“an Apple Watch app that also has an iPhone companion”

It is:

“an iPhone app with full standalone usefulness, enhanced by Apple Watch”

That matters because it keeps the addressable audience much bigger.

Core product promise

The core promise should be something like:

Follow the 20-20-20 rule without annoying reminders, subscriptions, or clutter.

Or even more directly:

A quiet, free reminder to look away from your screen every 20 minutes.

The promise is not “improve your vision.”
The promise is not “reduce eye strain scientifically guaranteed.”
The promise is not “optimize your health.”

That would be sloppy and risky.

The actual promise is behavioral and practical:

help users remember the rule
make taking the break frictionless
do it in a way that does not suck
Target users

The main users are straightforward:

Primary users

People who spend long periods looking at screens, especially:

office workers
software developers
designers
students
remote workers
gamers
people who read a lot on laptops or phones
Strong secondary users

People who already know they should take visual breaks but fail to do so consistently:

people who feel eye fatigue
people who get dry eyes from screens
people who feel mentally “locked in” to work and forget to pause
people who already use reminders for water, posture, standing, or focus
Watch-heavy segment

People with Apple Watch who want the least disruptive form of reminder:

subtle wrist tap
no loud sounds
no need to keep phone visible
fastest possible break interaction

That segment is especially valuable because the watch makes the use case much better.

Product principles

These principles should guide every decision.

1. The app must be useful without Apple Watch

The watch experience is better, but the app cannot depend on it.

If someone only has an iPhone, they should still get:

reminders
vibration
optional sound
countdown
pause/snooze
scheduling controls 2. The watch should feel like the ideal mode

If someone does have an Apple Watch, the app should feel materially better:

subtle haptic cue
quick interaction from the wrist
fast countdown view
no need to grab the phone 3. The app should be quiet, not noisy

Default behavior should be subtle:

haptics on
sound off by default
simple notifications
no nagging
no guilt language 4. The app should be tiny in scope

This should not grow into a bloated eye-health dashboard.

No account system.
No social feed.
No “coach.”
No pseudo-medical claims.
No junk.

5. The app should do one thing very well

The whole product stands or falls on the quality of this loop:

remind
start countdown
finish
repeat

If that loop feels great, the product works.

The exact user problem being solved

The problem is not just “people forget.”

It is more specific:

people get absorbed in work and lose track of time
people do not want a loud or disruptive reminder
people do not want to manually start timers themselves
people do not want to pay for an app this basic
people do not want to keep their phone visible all the time
people want the reminder to feel like a light nudge, not a command

That means the product must reduce friction in these places:

Friction point 1: remembering

Solved by recurring reminders.

Friction point 2: being interrupted too aggressively

Solved by defaulting to subtle haptics and simple notifications.

Friction point 3: having to open a big app workflow

Solved by making the countdown start quickly with minimal taps.

Friction point 4: watch users wanting the reminder on the wrist

Solved by Apple Watch support.

Friction point 5: people without a watch being excluded

Solved by full iPhone-only usability.

Core app behavior

This is the core logic of the app.

Default behavior
every 20 minutes, the app sends a reminder
the reminder tells the user to look at something far away
the user taps the reminder
the app opens a 20-second countdown
after the countdown, the break is done
the reminder cycle continues

That is the default 20-20-20 behavior.

Suggested default settings
interval: 20 minutes
break duration: 20 seconds
haptics: enabled
sound: disabled
reminders active only during chosen hours
weekdays only: optional but likely useful
countdown starts after user taps the reminder

These defaults are sensible and avoid being annoying.

iPhone-only experience

The app must stand on its own on iPhone.

iPhone reminder behavior

If the user does not have an Apple Watch:

iPhone delivers a notification
phone vibrates
optional sound can play if enabled
user taps notification
20-second countdown opens on phone
app returns to background after completion
Why this still works

Even without the watch, the app is still useful because:

most users always have their phone nearby
phone notifications are enough for many people
the app’s value is primarily reminder consistency, not watch exclusivity
Limitations of iPhone-only mode

Be honest about them:

phone reminders are easier to miss than watch haptics
a phone in a pocket or on silent can be less immediate
the interaction is a little less seamless than on the wrist

That is fine. It is still a valid product.

Apple Watch experience

The Apple Watch is where the product becomes noticeably better.

Watch reminder behavior

If the user has an Apple Watch:

reminder appears on watch
watch gives a subtle haptic tap
optional sound is available
user taps the notification
20-second countdown runs on watch
user finishes without picking up the phone
Why the watch matters

This use case matches the watch extremely well:

the watch is always on the user
haptic reminders are private and quiet
the user does not need to be looking at a screen to notice it
the reminder arrives exactly where it is most useful

The watch is not necessary for the product to work, but it is the best delivery surface for this particular job.

What makes this app materially better than existing options

This has to be thought through clearly, because “another reminder app” is weak unless the differentiation is real.

The real differentiation is not technical complexity. It is product discipline.

1. Completely free for the core use case

Most competing apps lock basic recurring reminders, customization, or watch support behind payment.

That is ridiculous for something this simple.

A fully free version immediately creates a strong trust advantage.

2. Built around the actual use case, not generic wellness bloat

Most existing products drift into:

mindfulness
hydration
posture
breathing exercises
subscriptions
habit streaks
dashboards

This app should stay focused on one behavior only.

That makes it cleaner and more usable.

3. Apple Watch-first quality without Apple Watch dependency

Many apps either:

ignore the watch
or act like the watch is the whole product

This app should do the correct middle ground:

fully useful on iPhone
clearly best on watch

That is stronger product design.

4. Quiet by default

A lot of reminder apps are way too loud, aggressive, or visual.

For this use case, subtlety is a feature.

5. Frictionless countdown

The app should not make users navigate menus just to take a 20-second break.

One tap. Countdown. Done.

That matters more than most people think.

What the app is not

Defining what it is not is important because it prevents scope creep.

This app is not:

a medical device
a vision therapy app
an eye exam app
a posture trainer
a meditation platform
a productivity suite
a general break timer for every possible use case
a gamified habit platform

It can still later support related needs carefully, but its identity should stay narrow.

Detailed feature set
MVP feature set

This is what version 1 should include.

Core reminders
recurring reminders at user-defined interval
default 20-minute interval
local notifications
iPhone notification support
Apple Watch notification support where available
Countdown
20-second countdown screen
customizable countdown duration
clear, minimal UI
completion state
optional auto-dismiss after finish
Controls
start reminders
pause reminders
resume reminders
snooze next reminder
skip current break
Settings
interval length
break duration
haptic on/off
sound on/off
working hours
weekdays only toggle
reminder text style or message choice if desired, but minimal
Platform support
full iPhone use without Apple Watch
enhanced experience on Apple Watch
Basic state
today’s completed breaks
whether reminders are active
next scheduled reminder time

That is enough for a solid product.

Post-MVP features

These can be added later if they genuinely help.

Good additions
Apple Watch complication showing next break
iPhone widget showing next reminder
quick actions in notification:
Start now
Snooze 5 min
Skip
temporary pause modes:
pause 1 hour
pause until tomorrow
simple daily/weekly completion stats
Focus mode integration if feasible
accessibility options for larger countdown text and stronger visual cues
Features to be cautious with
streaks
achievements
visual trends
multiple reminder modes
break categories
“smart reminders”
AI recommendations

These can make the app worse if they distract from the core use case.

UX design direction

The UX should feel like a calm utility.

Visual design
very clean
minimal text
large countdown numbers
muted, non-stressful styling
no cluttered dashboards
no unnecessary color explosions
Notification tone

The messaging should be direct and neutral:

“Look away for 20 seconds”
“Look at something in the distance”
“Time for a visual break”

Not:

guilt-trippy messages
fake cheerful nonsense
over-medical language
Interaction model

The user should be able to understand the entire app in under a minute.

On first launch:

grant notification permissions
choose reminder schedule
choose haptics/sound
activate reminders

Then they should mostly never need the app except for small adjustments.

That is ideal utility design.

Technical product model

The product should be designed around local reliability, not complexity.

Core system model

At a high level:

user defines reminder settings
app stores settings locally
app schedules local notifications
notification fires on iPhone and watch where applicable
tapping it opens countdown experience
completion is recorded locally
app continues cycle

This is the right product shape because it avoids unnecessary backend complexity.

Why local-first matters

A backend is not needed for the core functionality.

That means:

less cost
faster build
more privacy
no account requirement
fewer failure points
easier to keep free

For this app, local-first is the correct architecture.

Technical stack

Use Apple-native tooling.

Recommended stack
Swift
SwiftUI
UserNotifications
watchOS app target
shared settings/state via App Groups if needed
Watch Connectivity where necessary for settings sync
Why native is the right choice

This app relies heavily on:

Apple notifications
Apple Watch support
watch interaction patterns
smooth local device behavior

Using React Native or Flutter for something like this is usually a mistake unless you already have a reason to support Android soon.

For an Apple-only MVP, native is cleaner and safer.

Functional architecture

The app can be thought of as five simple layers.

1. Reminder engine

Responsible for:

computing next reminder times
scheduling notifications
handling pause windows
respecting working hours and weekday settings 2. Settings layer

Responsible for:

interval
countdown length
sound/haptic preferences
schedule preferences
active/inactive state 3. Countdown flow

Responsible for:

opening from notification
showing timer
completion
cancel or skip 4. Completion tracking

Responsible for:

counting completed breaks today
maybe lightweight history for weekly summary 5. Platform surfaces

Responsible for:

iPhone screens
Apple Watch screens
widgets/complications later

That is enough structure without overengineering.

Edge cases that should be thought through now

This is where weak apps usually get sloppy.

1. What happens if the user ignores a reminder?

Best approach:

do not break the whole schedule
continue normal reminder cadence
optionally allow a snooze action
do not repeatedly nag about the missed one 2. What happens if the user taps late?

If they tap the reminder later than intended, the countdown should still work.
Do not overcomplicate it.

3. What happens during sleep or outside work hours?

Reminders should not fire unless within the configured active window.

This is important, otherwise people uninstall fast.

4. What happens if notifications are disabled?

The app should clearly show that reminders cannot work properly until notifications are enabled.

5. What happens if the watch is unavailable?

The iPhone flow should still work normally.

6. What happens if both iPhone and watch are present?

The experience should feel coherent, not duplicated in a confusing way.
This needs testing and careful notification handling.

7. What happens after reboot or app reinstall?

Reminder state should recover as cleanly as possible.
The app should make it obvious whether reminders are active.

8. What happens if user pauses reminders?

The pause state must be very clear.
Users should never wonder whether reminders are running.

Success criteria

You need to know what “good” means before building.

The app is successful if:

User-level success
people can set it up in under a minute
reminders feel subtle, not annoying
countdown is fast to start
watch users prefer it over phone-only reminder apps
iPhone-only users still find it useful enough to keep installed
Product-level success
no subscriptions needed
the app remains small and understandable
retention comes from usefulness, not gimmicks
App Store reviews mention simplicity, watch support, and being free
Technical success
notifications are reliable enough for daily use
settings sync properly
countdown flow is stable
background behavior is predictable within Apple platform constraints
Risks and limitations

These should be acknowledged honestly.

1. Apple notification/background behavior has limits

You will not get perfect “always alive background timer” behavior the way a desktop app might.

So the product should rely on notification scheduling, not background timer fantasies.

2. Reminders are only as useful as the user’s willingness to respond

No reminder app can force compliance.

The goal is to reduce friction, not guarantee behavior.

3. Some users will want more than the product should offer

There will always be requests for:

hydration
posture
Pomodoro
meditation
focus timer
macOS support
Android support

Most of that should be ignored initially.

4. The app can become annoying if defaults are wrong

This is why subtle defaults matter a lot:

sound off by default
reasonable schedule controls
easy pause options
Why this can actually work as a product

This works because it is not trying to be a huge business platform. It is trying to be a very good small utility.

Small utilities succeed when:

the need is obvious
the use case is repeated often
existing options are bad, bloated, or overpriced
the experience can be made meaningfully better with focus and taste

This idea has those conditions.

The biggest reason it can work is that the experience can be materially better than competitors through:

no paywall
much less friction
strong Apple Watch support
less clutter
calmer UX

That is enough differentiation in this category.

Recommended product statement

A clean version of the full concept:

A free, minimal 20-20-20 reminder app for iPhone and Apple Watch. It helps users follow the 20-20-20 eye care rule by sending subtle recurring reminders and launching a simple 20-second countdown to look into the distance. The app is fully usable on iPhone alone and offers its best experience on Apple Watch through quiet wrist haptics. It avoids subscriptions, clutter, and wellness-app bloat, focusing entirely on one job: making visual breaks easy to remember and easy to take.

Recommended MVP scope, final version

Build this first:

Required
iPhone app
Apple Watch app
recurring reminders
iPhone notification flow
watch notification flow
20-second countdown
configurable interval and duration
haptic and sound controls
pause, resume, snooze
working hours support
basic completed-break tracking
Explicitly leave out for v1
accounts
backend
subscriptions
ads
social features
medical claims
complex analytics
wellness bundles
gamification
