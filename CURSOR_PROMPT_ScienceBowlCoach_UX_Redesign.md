# Cursor Prompt — Science Bowl Coach: Complete UX + Fun Redesign

---

## What this prompt is

A **full UX overhaul** of the Science Bowl Coach app. The app is functionally complete. Do **not** change any business logic, data models, PDF parsing, or persistence. This is a complete redesign of how the app looks, feels, and moves — every screen, every interaction, every micro-moment.

The app is for **Soha**, a middle school student preparing for the National Science Bowl. She uses it every day to drill Biology, Chemistry, and Physics. Right now it feels like homework. It should feel like a game she wants to open.

**Target project:** `/Users/farah/Documents/FarahRasheed/ScienceBowlCoach/`

---

## Design vision

Pull from **all four** of these references simultaneously — they are not in conflict:

| Reference | What to steal |
|---|---|
| **Duolingo** | Streaks, XP, celebratory moments, hearts/lives, progress that feels like leveling up |
| **Apple Fitness** | Ring-style progress, crisp typography, purposeful use of color, calm between sessions |
| **A competitive game** | Speed, tension in the buzzer drill, a visible score, the feeling that something is at stake |
| **A personal coach** | Soha's name, encouraging copy, context-aware nudges ("You got 4/5 on Biology yesterday!") |

The single design rule: **every screen should make Soha want to stay one more minute.**

---

## Visual identity

### Color system

Move away from system blue only. This app has three subjects — each gets an identity color. Use these exactly:

```swift
// Subject colors
let biologyColor   = Color(red: 0.18, green: 0.75, blue: 0.47)   // Vivid emerald green
let chemistryColor = Color(red: 0.40, green: 0.52, blue: 0.98)   // Electric indigo-blue
let physicsColor   = Color(red: 1.00, green: 0.58, blue: 0.18)   // Warm amber-orange

// Surface
let appBackground  = Color(red: 0.07, green: 0.07, blue: 0.10)   // Near-black (dark mode default)
let cardSurface    = Color(red: 0.13, green: 0.13, blue: 0.18)   // Elevated card
let cardSurface2   = Color(red: 0.18, green: 0.18, blue: 0.24)   // Double-elevated

// Text
let textPrimary    = Color.white
let textSecondary  = Color.white.opacity(0.60)
let textTertiary   = Color.white.opacity(0.35)
```

The app is **dark mode by default**. The dark surface makes the subject colors pop like neon. Light mode is supported via a settings toggle but dark is the primary design target.

### Typography

SF Rounded — not SF Pro. Use `.design(.rounded)` on every `Font`. Rounded numerals and letters are friendlier and more energetic than the default serif.

```swift
// Usage pattern — always use rounded design
Font.system(.largeTitle, design: .rounded, weight: .bold)
Font.system(.title2, design: .rounded, weight: .semibold)
Font.system(.headline, design: .rounded, weight: .semibold)
Font.system(.body, design: .rounded)
Font.system(.caption, design: .rounded, weight: .medium)
```

### Cards

All cards use this style — apply it as a `ViewModifier`:

```swift
struct GameCard: ViewModifier {
    var color: Color = Color(red: 0.13, green: 0.13, blue: 0.18)
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
```

No system list style. No `Form`. No `grouped` background. Everything is **custom cards on the dark background** — HStack/VStack/ZStack with `.gameCard()`.

### Icons

SF Symbols, but large and colored. Every subject icon is always shown in its subject color at minimum 24pt. Use `.symbolRenderingMode(.hierarchical)` or `.palette` to get two-tone depth.

| Subject | Icon |
|---|---|
| Biology | `leaf.fill` in `biologyColor` |
| Chemistry | `flask.fill` in `chemistryColor` |
| Physics | `bolt.fill` in `physicsColor` |
| Streak | `flame.fill` in `.orange` |
| XP / Score | `star.fill` in `.yellow` |
| Correct | `checkmark.circle.fill` in `biologyColor` |
| Incorrect | `xmark.circle.fill` in `.red` |

---

## Global persistent elements

### XP and streak — always visible

Add a persistent top bar on the home screen (Today tab) showing:

```
🔥 12   ⭐ 840 XP
```

- Streak = consecutive days with at least one completed session or drill
- XP = earned from correct answers (toss-up correct = +10, bonus correct = +15, study session completed = +25, mock round completed = +50)
- Both values animate (count up) when earned
- Stored in `UserDefaults` as `currentStreak: Int` and `totalXP: Int`

### Subject color bleeds

Whenever a screen is focused on one subject, the top ~30% of the screen uses a **subtle radial gradient** using that subject's color at 15% opacity against the dark background. This makes every drill feel like it belongs to a different world.

```swift
// Example for Biology screen top bleed
ZStack {
    LinearGradient(
        colors: [biologyColor.opacity(0.15), Color.clear],
        startPoint: .top, endPoint: .center
    )
    .ignoresSafeArea()
    // content
}
```

---

## Tab bar redesign

Replace the default `TabView` tab bar with a custom floating tab bar that sits 16pt above the bottom safe area:

```
[  🏠 Today  |  ⚡ Drill  |  📈 Progress  |  ⚙ Settings  ]
```

- Floating card shape (pill with 28pt corner radius), dark card background, thin shadow
- Selected tab: label visible + icon in subject-accent or system yellow
- Unselected: icon only, `.textTertiary`
- Tab labels: "Today", "Drill", "Progress", "Settings"
- Animate tab switch with a `.spring(response: 0.3)` scale pulse on the selected icon

---

## Tab 1 — Today (redesigned)

### Header
```
Good morning, Soha! 👋          🔥 12  ⭐ 840
```
- Greeting changes by time of day (morning/afternoon/evening)
- Streak and XP inline, right-aligned
- Below the greeting: a one-line coach nudge in `.textSecondary`:
  - "You're on a 12-day streak. Don't break it today."
  - "Yesterday you nailed Biology. Chemistry is up today."
  - "3 sessions left this week. You've got this."

### Today's blocks — card stack, not a list

Each study block is a **large hero card** (full width, ~120pt tall) with:
- A subject-color left accent bar (4pt wide, full height of card)
- Subject icon (28pt) in subject color
- Subject name in `.title2` bold
- Book + chapter in `.caption` secondary
- Focus line (1 line, truncated) in `.body`
- A large **"Start Session →"** button — filled, subject-color background, white text, 14pt corner radius
- The card background uses `cardSurface` with a barely-visible subject-color tint (3% opacity)

```
┌─────────────────────────────────────────┐
│ ▌  🧪  Chemistry                   Today │
│ ▌  Modern Chemistry · Ch 3          →    │
│ ▌  Atoms, atomic number, isotopes        │
│ ▌  [      Start Session →        ]       │
└─────────────────────────────────────────┘
```

### Quick Drill strip

Below the session cards: a horizontal scroll strip of **quick-tap drill chips**:

```
[ ⚡ 5 Bio Qs ]  [ ⚡ 5 Chem Qs ]  [ ⚡ 5 Phys Qs ]  [ 🎲 Random 10 ]
```

- Compact pill buttons, subject color tint
- Tapping any of them goes straight into the drill — **zero intermediate screens**
- This is the fastest path to a question in the whole app

### Daily ring (Apple Fitness style)

A circular progress ring below the header — 3 concentric rings:
- Outer ring: Biology sessions completed this week (e.g., 1 of 2) in `biologyColor`
- Middle ring: Chemistry sessions (e.g., 0 of 2) in `chemistryColor`
- Inner ring: Physics sessions (e.g., 1 of 1) in `physicsColor`

Use `Canvas` or a custom `Shape` to draw the arcs. Show a small legend below: "Bio · Chem · Phys" with colored dots.

---

## Tab 2 — Drill (redesigned, was "Quiz")

This is the action tab. It should feel like launching a game.

### Root view

No section headers. Just a vertical stack of large launch cards:

**Card 1 — Buzzer Drill** (largest card, most prominent)
```
┌─────────────────────────────────────────┐
│  ⚡  Buzzer Drill                        │
│  Tap to buzz. Beat the clock.            │
│                                          │
│  [ Bio ]  [ Chem ]  [ Phys ]  [ All ]   │
│                                          │
│  [ Start Drill → ]                       │
└─────────────────────────────────────────┘
```
- Subject filter chips inline on the card — tap to toggle, subject color when selected
- "Start Drill →" launches immediately with selected subjects

**Card 2 — Topic Quiz**
```
┌─────────────────────────────────────────┐
│  📋  Topic Quiz                          │
│  4 choices · no time pressure            │
│                                          │
│  [ Start Quiz → ]                        │
└─────────────────────────────────────────┘
```

**Card 3 — Mock Round (DOE style)**
```
┌─────────────────────────────────────────┐
│  🏆  Mock Round                          │
│  25 questions · real NSB format          │
│  Your best: 18/25                        │
│                                          │
│  [ Start Mock Round → ]                  │
└─────────────────────────────────────────┘
```
- "Your best" pulls from stored mock round history

**Card 4 — Browse DOE Archive**
```
┌─────────────────────────────────────────┐
│  📚  DOE Question Archive                │
│  Sets 1–16 · 2007–2022 · ~4,800 Qs      │
│                                          │
│  [ Browse → ]                            │
└─────────────────────────────────────────┘
```

### Buzzer Drill view — the most important screen in the app

This screen needs maximum tension and speed. Full redesign:

**Layout:**
- Dark background with subject-color top gradient bleed
- Round counter at top: "Question 3 of 10" in small `.caption` secondary
- Score pill top-right: "✓ 2  ✗ 0" — green and red, animated
- **5-second countdown arc** — a circular arc around the buzz button that drains in 5 seconds. Use `withAnimation(.linear(duration: 5))` on a `@State var progress: CGFloat`. Color: subject color.

```
                 Question 3 of 10        ✓ 2  ✗ 0

   ┌────────────────────────────────────────────┐
   │                                            │
   │   Biology — Multiple Choice                │
   │                                            │
   │   Which organelle produces most ATP        │
   │   in eukaryotic cells?                     │
   │                                            │
   └────────────────────────────────────────────┘


              ╔═══════════════════╗
              ║                   ║
              ║      BUZZ  ⚡     ║    ← 5-second arc drains around this
              ║                   ║
              ╚═══════════════════╝

```

- The **BUZZ button** is the largest element on screen — minimum 180×80pt, filled with subject color, SF Rounded bold 22pt, prominent shadow
- Tapping BUZZ stops the timer and reveals the answer with a smooth expand animation
- After reveal: two large buttons side by side — **"✓ Got it"** (green) and **"✗ Missed it"** (red)
- If timer runs out without buzz: answer auto-reveals, logged as incorrect, brief red flash on the background
- Correct: green flash + haptic `.success` + "+10 XP" floats up from the score pill and fades
- Incorrect: red flash + haptic `.error`
- After logging ✓/✗: auto-advance to next question after 0.8 seconds

**End screen (after all questions):**

Full-screen result card:
```
        🎉  Nice Round!

   ✓  8 correct      ✗  2 missed

   Biology    ████████░░  4/5
   Chemistry  ██████░░░░  3/5
   Physics    ████████████ 1/0  (missed 1)

   +80 XP earned  🔥 Streak active

   [ Drill Again ]   [ Review Misses ]
```
- If 9 or 10 correct: confetti animation (`CAEmitterLayer` or a simple SwiftUI particle effect)
- If < 5 correct: "Rough round — let's review what you missed" in secondary text

---

## Tab 3 — Progress (redesigned)

### Header
```
Your NSB Journey 🚀
⭐ 840 XP   🔥 12-day streak   📅 Week 3 of 10
```

### Subject scorecards — 3 horizontal cards (scroll)

Each subject gets a card showing:
```
┌──────────────────────────┐
│  🧬  Biology              │
│  ████████████░░  82%      │
│  47 correct · 10 missed   │
│  Last drilled: Today      │
└──────────────────────────┘
```
Cards scroll horizontally. Subject color accent on each.

### Weekly XP bar chart

A simple bar chart of XP earned each day this week. Bars in subject color blend (gradient if mixed, single color if one subject dominated). Use `Charts` framework (iOS 16+):

```swift
Chart(weeklyXP) { day in
    BarMark(x: .value("Day", day.label), y: .value("XP", day.xp))
        .foregroundStyle(day.dominantColor)
        .cornerRadius(6)
}
.chartXAxis { AxisMarks(values: .automatic) }
.frame(height: 120)
```

### Mastery checklist — redesigned

Not a flat list. Group by subject, each group collapsed by default with a subject-colored expand chevron. Items have 3 states:
- ○ Not started (unfilled circle)
- ◐ Practiced (half-filled, yellow — drilled but some misses)
- ● Mastered (filled circle in subject color — toggled on by Soha)

Tap any item to expand it and see the definition/focus line from `StudyBlock`.

### Missed questions — "Weak Spots" section

A card showing the last 10 questions logged as incorrect. Each shows:
- Subject color dot
- Question stem (truncated to 1 line)
- "Drill this →" button → launches a single-question drill for that item

---

## Study Session view redesign

The 4-stage session needs to feel like a focused game mode, not a form.

### Entry animation

When Soha taps "Start Session", the subject card expands to fill the screen with a `matchedGeometryEffect` transition. The subject-color gradient floods the top. A brief "Ready?" title fades in, then transitions to Stage 1.

### Stage indicator

Replace the page-style `TabView` with a horizontal **step dots** indicator at the top:

```
  ●───○───○───○
  Recall  Read  Know Cold  Toss-ups
```
Active dot: filled in subject color. Completed: filled white. Upcoming: hollow.

### Stage 1 — Recall (0–5 min)
- Title: "Warm Up ⚡" in subject color
- 5 questions from last week, shown one at a time as flip cards
- Card has question on front, answer on back — tap to flip with 3D card flip animation (`rotation3DEffect`)
- After flipping: "Got it 👍" / "Missed it 👎" buttons
- After all 5: brief score + "Let's study →" advances to Stage 2

### Stage 2 — Read (5–20 min)
- Title: "Study Time 📖" in subject color
- Scrollable content card with chapter, focus, formulas, key terms
- At bottom: large "I've read this ✓" button in subject color
- Optional 15-minute countdown timer in `.caption` at top right if timer is enabled in Settings

### Stage 3 — Know Cold (20–25 min)
- Title: "Test Yourself 🧠" in subject color
- Items shown as individual flip cards — same mechanics as Stage 1
- After all items: "Let's toss up →"

### Stage 4 — Toss-ups (25–30 min)
- Title: "Toss-Up Time ⚡" in subject color
- Uses the same Buzzer Drill view component (reuse `BuzzDrillQuestionView`) — same BUZZ button, same timer arc, same ✓/✗ logging
- End screen: "+25 XP — Session Complete 🎉" with subject ring closing

---

## Micro-interactions and animation inventory

Implement all of the following. These are not optional polish — they are the difference between dead and alive:

| Moment | Animation |
|---|---|
| Tab switch | `.spring(response: 0.3)` scale pulse on selected icon |
| Card tap | Brief `.scaleEffect(0.97)` press-down on tap |
| BUZZ button tap | Scale to 0.92, release with spring overshoot to 1.04 |
| Correct answer | Green flash (`.background(Color.green.opacity(0.2))`) + haptic `.success` |
| Incorrect answer | Red flash + haptic `.error` |
| XP earned | Float-up text "+10 XP" using offset animation, opacity fade |
| Streak increment | Flame icon `scaleEffect(1.3)` pulse + haptic `.success` |
| Session complete | Confetti if ≥ 80%, otherwise encouraging card |
| Stage advance | Horizontal slide transition `.move(edge: .leading)` |
| Flip card | `rotation3DEffect(.degrees(180), axis: (0, 1, 0))` split into front/back |
| Answer reveal | `.transition(.move(edge: .bottom).combined(with: .opacity))` |
| Progress ring fill | `withAnimation(.spring(response: 0.8))` arc draw on appear |
| XP bar chart | Bars animate up on appear with staggered `.delay(Double(index) * 0.05)` |

Use `@AppStorage` to persist streak and XP. Use `withAnimation` on all state changes that change visible layout.

---

## Copy and voice

Rewrite every piece of static text in the app to match this voice: **energetic, direct, 13-year-old-smart — like a coach who believes in you.** No clinical language. No "Please select a subject." Examples:

| Old | New |
|---|---|
| "Start Session" | "Let's go →" |
| "Study Session" | "Game On 🎯" |
| "Correct" | "Nailed it! ✓" |
| "Incorrect" | "Not quite — check the answer" |
| "Progress" | "Your Journey" |
| "No data yet" | "No questions yet — start a drill!" |
| "Round complete" | "Round done! Here's how you did:" |
| "Settings" | "Settings ⚙" |
| Streak label | "🔥 Day streak" |
| XP label | "⭐ Total XP" |

Apply this voice everywhere: button labels, empty states, section headers, end screens, toast messages, the greeting on Today.

---

## Empty states

Every empty state needs a subject-color illustration (use a large SF Symbol at 80pt, subject color, low opacity) and a call to action:

```
        🧬   (80pt, biologyColor, 30% opacity)

   No Biology drills yet.
   Start a quick drill to see
   your scores here.

   [ Start Bio Drill → ]
```

Never show a blank screen or a plain "No items" label.

---

## Settings tab (light redesign)

Keep the same settings, but present them as a custom card stack (no `Form`):

```
┌─────────────────────────────────────┐
│ 🌙 Dark Mode Default      [Toggle]  │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ ⏱ Countdown Timer         [Toggle]  │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ 👂 Read Aloud Mode         [Toggle]  │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ 📅 Current Week     [Picker: 1–10]  │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│ 📖 Current Pass        [Picker 1–3] │
└─────────────────────────────────────┘
```

Add one new setting:
- **Reset XP and Streak** — destructive button, red, with a confirmation alert before acting

Add a motivational footer:
```
"The buzzer waits for no one." 🎯
Science Bowl Coach · Soha's Edition
```

---

## Toss-Up Drill — complete screen specification

This is the most played screen in the app. Every detail matters. Build it as a standalone `TossupDrillView` that is reused in three contexts: the Drill tab, Stage 1 (Recall) of Study Session, and Stage 4 (Toss-ups) of Study Session.

### Screen states

The view cycles through exactly five states per question. Use a `@State var screenState: DrillScreenState` enum:

```swift
enum DrillScreenState {
    case countdown          // 3-2-1 before first question only
    case questionLive       // timer running, BUZZ available
    case buzzed             // timer stopped, answer hidden, player answering
    case revealed           // answer visible, ✓/✗ buttons shown
    case transitioning      // 0.8 second pause before next question
}
```

---

### State 0 — Countdown (first question only)

Full-screen centered countdown before the first question. Subject-color gradient bleed at top.

```
         ⚡ Buzzer Drill

              Biology

          Get ready...

               3
```

- Number animates: scale from 1.8 → 1.0 with spring, then cross-fades to next digit
- Sequence: "3" → "2" → "1" → "Go!" (each 0.8 seconds) → transitions to `questionLive`
- Haptic: `.rigid` impact on each digit
- "Go!" appears in subject color at 1.5× scale, then the question card slides up

---

### State 1 — Question Live

This is the tension state. Timer is running. Question is visible. BUZZ button is available.

**Full layout top to bottom:**

```
┌─────────────────────────────────────────────────────┐
│  ←  [  Question 3 of 10  ]            [✓ 2  ✗ 1]  │   ← navigation bar area
├─────────────────────────────────────────────────────┤
│                                                     │
│  ████████████████████░░░░░░░  ← thin progress bar  │   ← 4pt tall, subject color,
│                                    (question pos)   │     full width, top of content
│                                                     │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │                                              │  │
│  │   🧬  Biology · Toss-Up · Multiple Choice    │  │   ← subject badge row
│  │                                              │  │
│  │   Which organelle is responsible for         │  │   ← .title3 rounded semibold
│  │   producing most of the ATP in a             │  │
│  │   eukaryotic cell?                           │  │
│  │                                              │  │
│  │   W) Nucleus                                 │  │   ← answer choices, shown
│  │   X) Ribosome                                │  │     from the start for MC
│  │   Y) Mitochondria                            │  │
│  │   Z) Chloroplast                             │  │
│  │                                              │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│                                                     │
│           ┌──────────────────────────┐              │
│           │                          │   arc ring   │   ← circular countdown arc
│           │       BUZZ  ⚡           │   draining   │     drawn around the button
│           │                          │   clockwise  │
│           └──────────────────────────┘              │
│                                                     │
│              ●●●●●○○○○○                             │   ← 10 dots showing
│          [        Skip →        ]                   │     questions remaining
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Question card:**
- Background: `cardSurface` with 3% subject-color tint
- Corner radius: 20pt continuous
- Subject badge: icon + subject name + "Toss-Up" + format — in one `.caption` row, subject color
- Question text: `.title3` SF Rounded semibold, `.textPrimary`, top-padded 8pt from badge
- For Multiple Choice: answer choices shown below the question text, each on its own line, prefixed W/X/Y/Z in subject color
- For Short Answer: no choices shown; a small label "Short Answer" replaces the choice list

**BUZZ button:**
- Size: 200×72pt minimum
- Shape: `RoundedRectangle(cornerRadius: 18, style: .continuous)`
- Fill: subject color
- Label: "BUZZ ⚡" in SF Rounded bold 22pt white
- Shadow: `color: subjectColor.opacity(0.5), radius: 16, y: 6` — the glow is the signature visual
- On press-down (`.onLongPressGesture` with `minimumDuration: 0` + `pressing` binding): scale to 0.93 with `.spring(response: 0.2)`
- On release: scale back to 1.0 with spring overshoot to 1.04

**Countdown arc:**
- A `Circle` stroke drawn with `trim(from: 0, to: progress)` — starts at 1.0, drains to 0 over 5 seconds
- Stroke: subject color, lineWidth 4pt
- Behind the arc: a faint full circle in subject color at 15% opacity (the "track")
- The arc is sized to be 16pt larger than the BUZZ button on each side — it frames the button without touching it
- Arc color shifts from subject color → `.red` in the last 1.5 seconds: interpolate using `progress < 0.3 ? Color.red : subjectColor`
- At < 1 second: arc pulses (scale 1.02 → 1.0, repeat) to signal urgency

**Timer implementation:**
```swift
@State private var progress: CGFloat = 1.0
@State private var timerTask: Task<Void, Never>? = nil

func startTimer() {
    timerTask = Task {
        let start = Date()
        let duration: TimeInterval = 5.0
        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(start)
            let remaining = max(0, 1.0 - elapsed / duration)
            await MainActor.run { progress = remaining }
            if remaining <= 0 {
                await MainActor.run { handleTimeExpired() }
                return
            }
            try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
        }
    }
}

func stopTimer() {
    timerTask?.cancel()
    timerTask = nil
}
```

**Dot progress row:**
- 10 filled dots below the BUZZ button (or N dots for N questions in the drill)
- Completed questions: subject-color dot. Current question: white dot. Remaining: tertiary dot.
- Use `HStack(spacing: 6)` with `Circle().frame(width: 8, height: 8)`

**Skip button:**
- Tertiary, small — `.textSecondary` color, no fill, no border
- Tapping Skip logs the question as incorrect and advances — same as time expiry

---

### State 2 — Buzzed

Player has tapped BUZZ. Timer stops. Question is still visible. Answer is hidden. A text field or a 3-second self-answer window appears:

```
   🧬  Biology · Toss-Up · Multiple Choice

   Which organelle is responsible for
   producing most of the ATP in a
   eukaryotic cell?

   W) Nucleus
   X) Ribosome
   Y) Mitochondria
   Z) Chloroplast

   ───────────────────────────────────────

         Think... what's your answer?

         [ Reveal Answer → ]
```

- The BUZZ button is replaced by a "Reveal Answer →" button (same size, same color, different label)
- A small stopwatch counts up from 0 from the moment of buzz — this is the "answer time" — shown in `.caption` tertiary
- In parent/coach mode (Settings toggle "Read aloud"), add a secondary label: "Soha, what's your answer?" — this mode is for Farah to run a buzzer round out loud
- Haptic: `.medium` impact on buzz
- "Reveal Answer →" transitions to State 3

---

### State 3 — Revealed

The answer is now visible. Choices (for MC) highlight the correct one. Two large action buttons appear.

```
   🧬  Biology · Toss-Up · Multiple Choice

   Which organelle is responsible for
   producing most of the ATP in a
   eukaryotic cell?

   W) Nucleus
   X) Ribosome
   ✓ Y) Mitochondria     ← highlighted in biologyColor with checkmark
   Z) Chloroplast

   ANSWER: MITOCHONDRIA
   ───────────────────────────────────────

   ┌─────────────────┐   ┌─────────────────┐
   │   ✓  Got it!    │   │   ✗  Missed it  │
   └─────────────────┘   └─────────────────┘
```

**Answer reveal animation:**
- The answer text animates in from below with `.transition(.move(edge: .bottom).combined(with: .opacity))`
- The correct choice row gets a background of `biologyColor.opacity(0.20)` with a checkmark prepended — animate with `.animation(.spring(response: 0.4), value: isRevealed)`
- For Short Answer: show the answer text in a highlighted box (subject color at 15% opacity, rounded 12pt)
- "ANSWER:" label in `.caption` subject color uppercase; answer text in `.title2` SF Rounded bold white

**"✓ Got it!" button:**
- Fill: `Color(red: 0.18, green: 0.75, blue: 0.47)` (biologyColor — always green regardless of subject)
- Width: `(screenWidth - 48) / 2`
- Height: 56pt
- Corner radius: 14pt

**"✗ Missed it" button:**
- Fill: `Color(red: 0.85, green: 0.25, blue: 0.25)` — system red equivalent
- Same dimensions

**On "✓ Got it!" tap:**
1. Haptic: `.success`
2. Brief green overlay flash on entire screen: `.background(Color.green.opacity(0.15))` fading out in 0.4s
3. "+10 XP" floats up from the score pill: starts at score pill position, floats 40pt up, fades — `withAnimation(.easeOut(duration: 0.8))`
4. Score pill updates: correct count increments with a spring scale pulse
5. `screenState = .transitioning` after 0.1s delay
6. Log: `drillSession.correct += 1`, append to `sessionLog`

**On "✗ Missed it" tap:**
1. Haptic: `.error`
2. Brief red overlay flash
3. Score pill updates: incorrect count increments
4. `screenState = .transitioning` after 0.1s delay
5. Log: `drillSession.missed.append(currentQuestion)` — so it shows up in "Weak Spots"

---

### State 4 — Transitioning

0.8-second auto-advance pause. Screen shows:
- The revealed answer card (still visible, no buttons)
- A thin animated line sweeping across the bottom of the card from left to right over 0.8 seconds — subject color — this is the visual cue that the next question is loading
- Then the next question card slides in from the right with `.transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))`
- `progress` resets to 1.0
- `startTimer()` called
- `screenState = .questionLive`

For the last question in the drill, transition to the End Screen instead.

---

### End Screen — full specification

Triggered when `questionIndex == questions.count`. Replace the entire drill view content with the end screen using a `.fullScreenCover` or an in-place transition.

**Layout:**

```
┌────────────────────────────────────────────┐
│                                            │
│              🎉                            │   ← large emoji, 64pt
│         Great Round!                       │   ← .largeTitle rounded bold
│    You got 8 out of 10 right               │   ← .title3 secondary
│                                            │
│  ┌──────────────────────────────────────┐  │
│  │  ✓ Correct      8    ✗ Missed   2   │  │   ← score summary card
│  └──────────────────────────────────────┘  │
│                                            │
│  Biology      ████████████░░░░   4 / 5     │   ← per-subject breakdown
│  Chemistry    ██████████░░░░░░   3 / 5     │     animated bars, fill on appear
│  Physics      ████░░░░░░░░░░░░   1 / 4     │
│                                            │
│  ─────────────────────────────────────── │
│                                            │
│  ⭐ +80 XP earned                          │   ← XP summary
│  🔥 12-day streak — still alive!           │   ← streak status
│                                            │
│  ─────────────────────────────────────── │
│                                            │
│  [ 🔁  Drill Again ]                       │   ← primary, subject color fill
│  [ 👀  Review Missed Questions ]           │   ← secondary, outlined
│  [ 🏠  Back to Today ]                     │   ← tertiary, text only
│                                            │
└────────────────────────────────────────────┘
```

**Headline copy by score:**

| Score | Emoji | Headline |
|---|---|---|
| 10/10 | 🏆 | "Perfect Round!" |
| 8–9 | 🎉 | "Great Round!" |
| 6–7 | 💪 | "Solid Work!" |
| 4–5 | 📈 | "Getting There!" |
| 0–3 | 🔄 | "Let's Keep Drilling" |

**Subline copy:**
- 10/10: "All 10 correct. You're ready."
- 8–9: "You got [N] out of [total] right."
- 6–7: "More than half — keep going."
- 4–5: "Every miss is a question to master."
- 0–3: "Rough round. Review the misses and try again."

**Per-subject bars:**
- Only show subjects that appeared in the drill (skip if 0 questions)
- Bar: `RoundedRectangle(cornerRadius: 4)` filled with subject color, background track in subject color at 20% opacity
- Animate from 0 to final width on appear with `.animation(.spring(response: 0.6).delay(Double(index) * 0.15), value: appeared)`
- Label: subject name left, "X / Y" right in `.caption` secondary

**Confetti:**
- Trigger confetti if score ≥ 80%
- Use `CAEmitterLayer` with small star and circle shapes in the three subject colors + white + yellow
- Emit from top-center, gravity pulls down, lifetime 3 seconds, fade out
- Wrap in `UIViewRepresentable` as `ConfettiView`

**"Review Missed Questions" button:**
- Navigates to a `MissedQuestionsView` showing only the questions logged as missed in this session
- Same Buzzer Drill view, but no timer (timer disabled), each question shows answer immediately after buzz

**"Drill Again" button:**
- Resets state, picks a new random set of questions from the same subject filter, goes back to countdown

---

### Bonus mode — Mock Round (DOE style)

Activated from Drill tab → "Mock Round". Uses the same `TossupDrillView` but with these differences:

- Questions are pulled only from `DOEQuestion` bank, filtered to Bio/Chem/Phys
- 20 questions total: 10 toss-ups and 10 bonuses, alternating in pairs (Toss-Up 1 → Bonus 1 → Toss-Up 2 → Bonus 2...)
- Timer: 5 seconds for toss-ups, 20 seconds for bonuses (bonuses allow more thinking time)
- Bonus questions show all parts (some DOE bonuses have 3 sub-parts) stacked in the card
- Score tracked separately as `mockRoundHistory: [MockRoundResult]` in `UserDefaults`
- End screen adds a "Mock Round" badge and shows best-ever score comparison

---

### `TossupDrillView` — component contract

The view is initialized with a configuration struct so it can be reused across contexts:

```swift
struct DrillConfig {
    var questions: [any QuizQuestion]   // protocol — both DOEQuestion and TossupQuestion conform
    var subject: Subject?               // nil = mixed
    var timerDuration: TimeInterval     // 5.0 for toss-ups, 20.0 for bonuses
    var showTimer: Bool                 // from Settings
    var context: DrillContext           // .standalone, .sessionRecall, .sessionTossup, .mockRound
    var onComplete: (DrillResult) -> Void
}

enum DrillContext {
    case standalone      // launched from Drill tab
    case sessionRecall   // Stage 1 of Study Session
    case sessionTossup   // Stage 4 of Study Session
    case mockRound       // Mock Round mode
}

struct DrillResult {
    var correct: Int
    var missed: [any QuizQuestion]
    var xpEarned: Int
    var bySubject: [Subject: (correct: Int, total: Int)]
}
```

In `.sessionRecall` and `.sessionTossup` context, suppress the top navigation bar back button and the "Back to Today" end-screen button — the session flow handles navigation.

In `.mockRound` context, show the DOE source label on each question card in `.caption` tertiary: "Set 16 · Round 1 · 2022".

---

## File changes summary

These are the files that need to be created or significantly modified. Do not touch models, data, or persistence logic outside of adding `currentStreak: Int` and `totalXP: Int` to `AppState`.

**Modify:**
- `ContentView.swift` — custom floating TabView
- `TodayView.swift` — full redesign
- `StudySessionView.swift` — full redesign with matchedGeometryEffect + stage redesign
- `QuizRootView.swift` — rename to `DrillRootView.swift`, full redesign
- `TossupDrillView.swift` — full redesign (BUZZ button, arc timer, XP animation)
- `TopicQuizView.swift` — card-based, subject color, flip mechanics
- `ProgressView.swift` — full redesign with rings, chart, scorecards
- `ChecklistView.swift` — grouped collapsible, 3-state items
- `SettingsView.swift` — card stack, no Form

**Create:**
- `DesignSystem.swift` — all colors, fonts, modifiers, and shared components (GameCard, SubjectBadge, BuzzButton, XPFloater, ConfettiView)
- `HapticManager.swift` — wraps `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator`
- `XPManager.swift` — handles XP calculation and streak logic, writes to `@AppStorage`

---

## Constraints

- iOS 17+ · SwiftUI only · iPhone only
- No third-party dependencies — use `Charts` (native), `CoreHaptics` or `UIFeedbackGenerator`, `CAEmitterLayer` for confetti
- All colors defined in `DesignSystem.swift` — no inline hex values anywhere else
- Every animation uses `withAnimation` or `.animation(.spring(), value:)` — no implicit animations
- Preserve all existing data models, PDF parsing, seed data, and `UserDefaults` keys exactly

---

*This is a UX and design pass only. When in doubt: make it faster to get to a question, make correct answers feel like victories, and make Soha want to open the app tomorrow.*
