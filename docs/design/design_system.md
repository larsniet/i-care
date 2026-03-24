# I Care Design System

A compact, Apple-native design system for a focused 20-20-20 reminder utility. Light mode primary, dark mode secondary. Every choice serves glanceability and calm.

## Color Roles

### Primary Palette

Derived from the Stitch seed green, adjusted for Apple-native contexts.

| Role | Light Mode | Dark Mode | Usage |
|------|-----------|-----------|-------|
| `brand` | `#086B59` | `#7BCDB8` | Primary actions, active status indicator, progress ring |
| `brandSubtle` | `#A0F2DB` | `#1A3D33` | Active-state background tint, selected chip fill |
| `brandMuted` | `#E8F7F3` | `#0F2620` | Section backgrounds, card fills |
| `surface` | `#F6F6F4` | `#1C1C1E` | App background |
| `surfaceRaised` | `#FFFFFF` | `#2C2C2E` | Grouped list backgrounds, settings rows |
| `surfaceOverlay` | `#FAFAF9` | `#242426` | Secondary surface for nesting |
| `textPrimary` | `#1A1D1E` | `#F0F0EE` | Headlines, primary labels |
| `textSecondary` | `#6B7274` | `#98989F` | Supporting copy, timestamps |
| `textTertiary` | `#A0A4A6` | `#636366` | Placeholder text, disabled labels |
| `statusPaused` | `#D4A053` | `#D4A053` | Paused state indicator |
| `statusBlocked` | `#C45C56` | `#E8867F` | Permission-denied indicator |
| `separator` | `#E8E8E6` | `#38383A` | List separators (use sparingly) |

### Application Rules

- Never use pure black (`#000`) or pure white (`#FFF`) for backgrounds or text.
- Use `brand` for the single primary action on any screen. Secondary actions use `textSecondary` with no fill.
- Status colors (`statusPaused`, `statusBlocked`) appear only in small indicators and labels, never as full backgrounds.
- Tint neutrals slightly warm to avoid clinical coldness.

## Typography

Use the system San Francisco font family throughout. No custom fonts. This keeps the app feeling like a native Apple utility rather than a branded product.

| Style | Weight | Size | Tracking | Usage |
|-------|--------|------|----------|-------|
| `displayLarge` | Light | 48pt | -0.5pt | Countdown seconds (monospaced variant) |
| `displaySmall` | Regular | 34pt | 0pt | Next-break time on home |
| `title` | Semibold | 20pt | 0pt | Screen titles, section headers |
| `headline` | Medium | 17pt | 0pt | Setting row labels, primary button text |
| `body` | Regular | 17pt | 0pt | Descriptive copy |
| `callout` | Regular | 16pt | 0pt | Supporting labels |
| `subhead` | Regular | 15pt | 0pt | Secondary information |
| `caption` | Regular | 12pt | 0pt | Timestamps, tertiary labels |
| `captionMono` | Regular | 12pt | 0pt | Countdown sub-labels (monospaced) |

### Rules

- Use `displayLarge` with SF Mono for the countdown timer to prevent digit-width jitter.
- Limit each screen to three type sizes maximum for hierarchy clarity.
- Line height: 1.4x for body, 1.2x for display.

## Spacing Scale

A base-4 scale that produces comfortable density without waste.

| Token | Value | Common Usage |
|-------|-------|-------------|
| `xs` | 4pt | Icon-to-label gap |
| `sm` | 8pt | Intra-group padding |
| `md` | 12pt | Row internal padding |
| `base` | 16pt | Standard content padding, list row height padding |
| `lg` | 24pt | Section spacing |
| `xl` | 32pt | Screen-edge to content, major section gaps |
| `xxl` | 48pt | Top-of-screen breathing room |

### Content Insets

- iPhone screen margins: `base` (16pt) horizontal
- Settings rows: `md` (12pt) vertical, `base` (16pt) horizontal
- Watch screen margins: `sm` (8pt) horizontal

## Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `sm` | 8pt | Chips, small buttons |
| `md` | 12pt | Grouped list sections, settings groups |
| `lg` | 16pt | Cards, modal sheets |
| `full` | 50% | Progress ring, circular indicators, avatar shapes |

Keep corner radius consistent within a screen. Prefer `md` for most container shapes.

## Component Patterns

### Primary Button

- Background: `brand`
- Text: white (on light) / `surface` (on dark)
- Corner radius: `md` (12pt)
- Height: 50pt
- Full-width within content area
- Press state: reduce opacity to 0.85, scale to 0.98

### Secondary Button

- Background: transparent
- Text: `brand`
- Border: none
- Press state: `brandMuted` background fill

### Status Indicator

A small inline badge communicating the current reminder state.

| State | Color | Icon | Label |
|-------|-------|------|-------|
| Active | `brand` | Filled circle | "Active" or next time |
| Paused | `statusPaused` | Pause icon | "Paused" |
| Blocked | `statusBlocked` | Warning triangle | "Notifications Off" |

### Progress Ring (Countdown)

- Track: `brandMuted` at 2pt stroke
- Fill: `brand` at 3pt stroke, round cap
- Size: 200pt diameter on iPhone, 120pt on Watch
- Centered on screen with countdown digits inside

### Settings Row

- Background: `surfaceRaised`
- Leading icon: SF Symbol in `textSecondary`, 22pt
- Label: `headline` weight
- Trailing: value text in `textSecondary`, or toggle, or chevron
- Grouped inside `md` corner-radius container
- Separated by hairline in `separator` (0.5pt)

### Chip (Interval/Duration Selector)

- Default: `surfaceRaised` background, `textPrimary` label
- Selected: `brandSubtle` background, `brand` label
- Corner radius: `sm` (8pt)
- Horizontal padding: `md` (12pt)

## State Treatments

### Home Screen States

**Active**: Show next-reminder countdown prominently using `displaySmall`. Below it, today's break count in `body`. Single "Pause" action as a secondary button. Background: `surface`.

**Paused**: Muted presentation. Replace countdown with a brief "Reminders paused" label in `statusPaused`. Show a "Resume" primary button. No extraneous stats.

**Blocked (Notifications Off)**: Show a calm but clear banner at the top using `statusBlocked` tint. Brief explanation. Direct link to system settings. Below, show the normal home layout in a disabled/dimmed state.

### Countdown Screen

Full-screen takeover with progress ring centered. Large countdown digits inside the ring. Brief instruction text below: "Look at something in the distance." Single "Skip" secondary action at the bottom. No navigation chrome.

### Watch Adaptations

Watch screens should not miniaturize phone layouts. Instead:

- Home: show only the status indicator and next-break time. One tap target.
- Notification: "Time for a break" + "Start" button + "Snooze" button. Nothing else.
- Countdown: progress ring filling the display, large seconds, skip as force-press or small bottom action.
- Completion: brief checkmark animation, auto-dismiss after 2 seconds.

## Iconography

Use SF Symbols exclusively. Prefer the "regular" weight to match body text.

| Concept | SF Symbol |
|---------|-----------|
| Eye / Vision | `eye` |
| Timer / Interval | `timer` |
| Pause | `pause.circle` |
| Resume / Play | `play.circle` |
| Settings | `gearshape` |
| Notifications | `bell` |
| Notifications Off | `bell.slash` |
| Check / Complete | `checkmark.circle` |
| Skip | `forward.end` |
| Snooze | `clock.arrow.circlepath` |
| Active Hours | `sun.max` |
| Calendar | `calendar` |
| Haptics | `hand.tap` |
| Sound | `speaker.wave.2` |
| Sound Off | `speaker.slash` |

## Motion

### Principles

- Prefer system-default SwiftUI transitions (`opacity`, `.move`, `.scale`).
- Use `spring(response: 0.35, dampingFraction: 0.85)` as the default animation curve.
- Countdown progress ring animates with `.linear` timing to match real seconds.
- Respect `UIAccessibility.isReduceMotionEnabled`.

### Key Moments

- **Home state change** (active/paused/blocked): cross-fade content, 0.3s.
- **Countdown start**: ring scales from 0.9 to 1.0 with spring, digits fade in.
- **Countdown complete**: ring fills, brief scale pulse (1.0 to 1.05 to 1.0), checkmark appears.
- **Onboarding step transition**: horizontal slide with matched geometry where possible.

## Dark Mode

Dark mode inverts surface and text roles but keeps brand hue consistent. Adjustments:

- `brand` shifts to its lighter tint (`#7BCDB8`) for adequate contrast.
- Backgrounds use iOS system dark grays (`#1C1C1E`, `#2C2C2E`).
- Progress ring track lightens slightly for visibility.
- Status colors stay unchanged for recognition.

## Accessibility

- All interactive elements meet WCAG AA contrast (4.5:1 for text, 3:1 for UI components).
- Countdown screen supports VoiceOver with live-region announcements every 5 seconds.
- All buttons have minimum 44pt touch targets on iPhone, 38pt on Watch.
- Dynamic Type supported for body, callout, subhead, and caption styles.
- Reduce Motion disables spring animations and progress-ring animation; shows static progress instead.
