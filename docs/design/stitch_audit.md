# Stitch Project Audit

Audit of the existing Stitch "I Care" project (ID: 12262917460942848614) against the product docs and brand context.

## Screens Reviewed

| Screen | Stitch Title | Doc Coverage |
|--------|-------------|--------------|
| Onboarding | Onboarding: Welcome | Flow 1 (partial) |
| Home Active | Home: Active State | Flows 2, 7 |
| Home Paused | Home: Paused State | Flow 4 |
| Home Blocked | Home: Permissions Denied | Flow 6 |
| Settings | Settings | MVP settings list |
| Watch Notification | Watch: Notification | Flow 3 (partial) |
| Watch Home | Watch: Home (Active) | Watch status |
| Watch Countdown | Watch: Countdown | Flow 3 countdown |
| Design System | Product Design Specification | Internal reference |

## Keep

These choices align well with the product docs and brand direction:

- **Soft green palette** anchored in `#086b59` with warm neutrals. Feels restful without being clinical. Aligns with the "quiet, utilitarian, and trustworthy" brand.
- **Status-first home layout** showing next break time and today's completed count as the two primary pieces of information. Matches the data model's derived state priorities.
- **Settings grouped by category**: Schedule, Active Hours, Notifications, Permissions. Clean separation that maps directly to `ReminderSettings` fields.
- **Watch notification prioritizes "Start Break"** as the primary action with snooze as secondary. Matches the notification strategy's quick-action hierarchy.
- **Light mode as primary expression**. Matches `.impeccable.md` direction.
- **Lowercase "i care" branding**. Quiet and non-attention-seeking.
- **Tonal surface layering** over hard borders. The "no-line rule" in the Stitch design system works well for a calm utility.

## Adjust

These need to be toned down, simplified, or reconsidered:

- **"Focus Mode Active" header** on the home screen reads like a productivity app. The home screen should communicate reminder state without branding it as a "mode". Simpler: just show active/paused/blocked status inline.
- **Home Paused copy**: "Take a break from your breaks" is too clever. The notification strategy doc says keep copy "calm, direct, and non-medical." Also shows too much secondary information (last active time, interval echo). Docs say avoid dashboard complexity.
- **Settings includes "Background Activity Allowed"** permission status. Not in the MVP spec. Keep permissions display focused on notification authorization only.
- **Header spa icon and account icon** give wellness-platform and account-system impressions. Both are explicit non-goals. Replace with minimal, utilitarian navigation.
- **Watch screens rendered at phone dimensions** (780px wide). Real watchOS screens need radically different density and hierarchy. These should be redesigned for actual watch constraints.
- **Design system prescribes glassmorphism** ("surface-variant at 70% opacity with 20px backdrop blur") and gradient treatments. Too decorative for the brand direction. `.impeccable.md` says "sparse and efficient."
- **"Digital Sanatorium" creative direction** in the Stitch design system markdown is too conceptual and medical-adjacent. The product brief explicitly says "not a medical device" and "not a vision therapy app."
- **Typography scale suggests 3.5rem display** with massive top padding for a "gallery feel." This wastes space on a utility app that should be glanceable, not editorial.

## Remove

Discard these entirely from the design direction:

- Glassmorphism / blur surface treatments
- Gradient backgrounds on countdown or status screens
- Account/profile icon in navigation (no accounts in MVP)
- "Product Design Specification" desktop screen (internal doc, not a user-facing surface)
- "Distance: 20ft" label on watch notification (unnecessary detail; the prompt should be enough)
- Decorative spa/wellness iconography
- Gallery-scale whitespace and editorial-style padding

## Missing

These MVP states and flows have no Stitch representation yet:

- **iPhone countdown screen** (the most important interaction after the notification tap)
- **Onboarding: notification permission request step** (Flow 1, step 3)
- **Onboarding: schedule configuration step** (Flow 1, steps 4-5)
- **Onboarding: activation confirmation** (Flow 1, step 7)
- **Watch: paused state**
- **Watch: break completion feedback**
- **Snooze confirmation** on both platforms
- **Break completion** return-to-idle transition on iPhone

## Summary

The Stitch project establishes a usable palette and general mood but leans too editorial and decorative for a focused Apple utility. The core information hierarchy on the home screen is sound. The watch designs need to be completely rethought for real watchOS constraints. Several critical flows (iPhone countdown, onboarding steps, completion states) are missing entirely.

The native design system should carry forward the green tonal palette and status-first layout philosophy while stripping away the web-editorial aesthetics in favor of Apple-native restraint.
