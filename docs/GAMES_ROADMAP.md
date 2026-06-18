# TossUp — Mini-Games Roadmap ✅ Shipped

All five mini-games are live under **Drill → Mini-Games** (hub + quick-launch chips).

**Shared plan with Science Bowl Coach** — full specs, priorities, and code reuse map:

→ **[../ScienceBowlCoach/docs/GAMES_ROADMAP.md](../ScienceBowlCoach/docs/GAMES_ROADMAP.md)**

## TossUp-specific notes

- **Nav:** Add games under **Drill** tab (keep 4-tab structure) or a “Break” section on Study.
- **Content:** Term banks from `Data/TopicCatalog.swift`, `Services/QuestionBank.swift`, bundled `Resources/StudyContent/topics.json` — no encyclopedia module yet.
- **Reuse first:** `Helpers/BuzzerDrillComponents.swift`, `Views/QuizSessionView.swift`, `Services/XPManager.swift`.
- **Element Blitz:** May need a small `Data/ElementCatalog.swift` (symbols/names) unless shared package is extracted later.
- **UX:** Match `Helpers/DesignSystem.swift` + `CURSOR_PROMPT_TossUp_UX_Redesign.md`.

## Build order (same as Coach) — done

1. True or False Blitz ✅  
2. Element Blitz ✅  
3. Science Wordle ✅  
4. Molecule Match ✅  
5. Cell Builder ✅  

---

*Last updated: June 2026 — macOS build verified.*
