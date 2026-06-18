# Cursor Prompt — TossUp: Complete UX + Fun Redesign

---

## What this prompt is

A **full UX overhaul** of the **TossUp** app — the lean NSB practice app that drills official DOE sample questions from bundled PDFs. Do **not** change PDF parsing, SwiftData models, or question-bank logic. Redesign look, feel, and motion only.

**Target project:** `/Users/farah/Documents/FarahRasheed/TossUp/`

**Shared design DNA** with Science Bowl Coach (same subject colors, XP/streak, dark game aesthetic) — see `CURSOR_PROMPT_ScienceBowlCoach_UX_Redesign.md` for the full visual spec. This document adapts that spec to TossUp's **4-tab** structure.

**Platforms:** iOS 16+ and **macOS 14+** (keep `NavigationSplitView` sidebar on Mac; floating tab bar on iPhone only).

---

## TossUp vs Science Bowl Coach

| | **TossUp** | **Science Bowl Coach** |
|---|---|---|
| Tabs | Study · **Drill** (Quiz) · Progress · Settings | Today · Drill · Progress · Settings (+ Calendar, Learn, …) |
| Study plan | None — browse/search questions | Daily blocks, 4-stage sessions |
| Question source | DOE PDFs + bundled JSON | DOE + encyclopedia + schedule |
| Drill | `QuizSessionView` timed MC/SA | `TossupDrillView` buzz + reveal |

---

## Design vision (shared)

Duolingo streaks/XP · Apple Fitness rings · competitive buzzer tension · personal coach voice for **Soha**.

**Design rule:** fastest path to a question — tap a chip, you're drilling.

---

## Visual identity

Use the **same color tokens** as Science Bowl Coach (`DesignSystem.swift`):

- Biology `0.18, 0.75, 0.47` · Chemistry `0.40, 0.52, 0.98` · Physics `1.00, 0.58, 0.18`
- Math `0.55, 0.45, 0.95` · Earth & Space `0.30, 0.78, 0.85` (TossUp-only subjects)
- Dark surfaces: `appBackground`, `cardSurface`, `cardSurface2`
- SF Rounded on all text · `GameCard` modifier · no `Form` / grouped lists on iOS

**Dark mode default** via `SettingsStore.preferDarkMode` (new `@AppStorage`, default `true`).

---

## Global: XP and streak

```
🔥 12   ⭐ 840 XP
```

| Action | XP |
|---|---|
| Correct toss-up / MC answer | +10 |
| Quiz session completed | +25 |
| Perfect session (100%) | +50 bonus |

- `totalXP` and `currentStreak` in `@AppStorage` via `XPManager`
- Streak = consecutive calendar days with ≥1 completed quiz session (extend `ProgressViewModel` to call `XPManager.recordActivity()` on session save)
- Animate count-up when XP earned; flame pulse on streak day

Show XP/streak on **Drill** setup and **Progress** headers (not Study — keep Study calm).

---

## Tab bar (iOS)

Replace system `TabView` bar with **floating pill tab bar** 16pt above safe area:

```
[ 📖 Study | ⚡ Drill | 📈 Journey | ⚙ Settings ]
```

- Selected: icon + label, accent yellow
- Unselected: icon only, tertiary
- Spring scale pulse on select
- Mac: keep sidebar; apply dark `DesignSystem` colors to sidebar + detail

Rename tabs in copy:
- Quiz → **Drill**
- Progress → **Your Journey**

---

## Tab 1 — Study (browse)

### Header
```
Hey Soha! 👋                    🔥 12  ⭐ 840
Browse · search · learn the bank
```

### Content
- Dark background, subject filter chips (existing `SubjectFilterBar` → subject colors from `DesignSystem`)
- Question rows as **cards** not plain `List` rows — subject dot, truncated stem, chevron
- Empty state: large `leaf.fill` at 30% biology color + "No questions yet — download PDFs in Settings"

### Question detail
- Subject gradient bleed at top
- Large question card, choices with subject-colored W/X/Y/Z prefixes
- Read-aloud + explanation cards use `GameCard`

---

## Tab 2 — Drill (was Quiz)

### Setup (`QuizSetupView` / `QuizTabView` setup phase)

Hero launch card:
```
┌─────────────────────────────────────────┐
│  ⚡  Buzzer Drill                        │
│  Beat the clock. Nail the answer.        │
│                                          │
│  [ Bio ] [ Chem ] [ Phys ] [ Math ] …   │
│  Length: [ 5 ] [ 10 ] [ 20 ]            │
│                                          │
│  [ Let's go → ]                          │
└─────────────────────────────────────────┘
```

Quick chips (horizontal scroll, zero setup):
```
[ ⚡ 5 Bio ] [ ⚡ 5 Chem ] [ ⚡ 5 Phys ] [ 🎲 Random 10 ]
```

### Active drill (`QuizSessionView`)

Reuse buzzer UX from Science Bowl Coach spec:

- `DrillScreenState`: countdown → questionLive → buzzed → revealed → transitioning
- 5s arc timer around **BUZZ ⚡** button (MC) · 20s for short answer
- Score pill: `✓ 2  ✗ 1`
- Progress dots + thin top bar
- Correct: green flash, haptic, `+10 XP` float
- End screen: per-subject bars, XP earned, confetti if ≥80%

**Mac:** keep keyboard shortcuts (Space, arrows); same visual design.

### Summary (`QuizSummaryView`)

Game-style results card — headline by score tier, Drill Again / Review misses / Back.

---

## Tab 3 — Your Journey (Progress)

### Header
```
Your NSB Journey 🚀
⭐ 840 XP · 🔥 12-day streak
```

- Horizontal **subject scorecards** (scroll) — accuracy bar per subject in subject color
- Weekly XP bar chart (`Charts` framework) — 7 bars, staggered appear animation
- Recent sessions as cards (not plain list)
- Weakest subject callout with "Drill this →" CTA

---

## Tab 4 — Settings

Custom card stack (no `Form` on iOS):

- 🌙 Dark mode default
- ⏱ Timer presets · quiz length · auto-advance
- 👂 Read questions aloud · student name · voice
- 📖 Show detailed explanations
- Subject toggles (card)
- **Reset XP and Streak** — destructive, confirmation alert
- Reset progress (existing)
- Re-parse PDFs

Footer:
```
"The buzzer waits for no one." 🎯
TossUp · Soha's Edition
```

---

## Copy voice (examples)

| Old | New |
|---|---|
| Quiz | Drill |
| Progress | Your Journey |
| Correct | Nailed it! ✓ |
| Incorrect | Not quite |
| Start Quiz | Let's go → |
| No sessions yet | No drills yet — hit Drill! |
| You've got this, Soha! | Good morning, Soha! 👋 |

---

## Files to create

- `TossUp/Helpers/DesignSystem.swift` — colors, fonts, `GameCard`, `BuzzButton`, `CountdownArc`, `XPStreakBar`, `FloatingGameTabBar`, `ConfettiView`
- `TossUp/Services/XPManager.swift` — XP + streak `@AppStorage`
- `TossUp/Helpers/HapticManager.swift` — success/error/rigid impacts

## Files to modify

- `RootView.swift` — floating tab bar (iOS), dark background
- `QuizTabView.swift` — hero setup + quick chips
- `QuizSessionView.swift` — full buzzer drill states
- `QuizViewModel.swift` — wire XP on grade, screen states
- `StudyView.swift` — card browse, header
- `ProgressTabView.swift` — journey redesign, XP chart
- `SettingsTabView.swift` — card stack, reset XP
- `SharedComponents.swift` — delegate colors to `DesignSystem`
- `SettingsStore.swift` — `preferDarkMode`, reset XP hook
- `generate_xcodeproj.py` — add new source files

---

## Constraints

- No third-party dependencies
- Preserve SwiftData models, PDF parser, `QuestionBank` cache
- macOS + iOS universal target
- All colors in `DesignSystem.swift` only

---

*Make it faster to get to a question. Make correct answers feel like victories. Make Soha want to open TossUp tomorrow.*
