# Automotive Empire — Architecture Map (read-order for session start)

> **Purpose:** this file exists so every chat can orient in minutes instead of re-deriving the codebase. Read this FIRST, then the files in the "Core read-set" below, then the GDD (`Supporting Files/GDD.md`). Generated from a full-tree survey; regenerate if the structure shifts materially.
>
> **Engine:** Godot 4.7 / GDScript. **71 `.gd` files, ~45,000 LOC.** Architecture per GDD §2: pure `RefCounted` engine classes hold the logic (headless-testable), kept out of UI. `GameState` is the hub everything delegates through.

---

## How the code is layered

- **`autoloads/`** — global singletons (always loaded). `GameState` is the spine; `AIManager` runs the AI world; the rest are name/sound/locale utilities.
- **`resources/scripts/`** — the **engine + model layer**: pure `class_name` RefCounted logic (the economy, R&D, race, contracts, season pipeline) plus the data models (Car, Driver, Staff, Team, Championship). This is where design work lives.
- **`scenes/`** — the UI layer (buildings, hubs, screens). Reads from the engines; holds little logic. Read a scene only when the task is specifically about that screen.
- **`data/`** — JSON seeds (teams, drivers, staff, calendars, part costs). Season-1 world state + modding surface.
- **`Supporting Files/`** — the GDD and companion design docs.

Delegation pattern: engines are instantiated in `GameState` as `_<name>_engine` / `_<name>_manager` and exposed via pass-through methods, so most code calls `gs.some_method()` rather than the engine directly. `gs` inside an engine is the untyped GameState back-reference (type your `:=` off it explicitly).

---

## CORE READ-SET (read in full, every session, before design work)

These are the highest understanding-per-token files. Reading them + their version headers gives ~80% of the architecture.

| # | File | LOC | Owns |
|---|------|-----|------|
| 1 | `autoloads/GameState.gd` | 5,385 | The spine: game state, all registries (CHAMPIONSHIP_REGISTRY, CNC_DATA, tiers), save/load, and the delegation layer to every engine. Read its var declarations, registries, and function signatures — not every body. |
| 2 | `resources/scripts/RnDEngine.gd` | 1,654 | R&D + economy heart: RP, blueprints, P1/P2/P3 tasks, the 100 P4 special projects, the P4 effect accessor layer, design-weeks logic. |
| 3 | `resources/scripts/FinancialEngine.gd` | 498 | Weekly economic cycle: income, expenses, campus, corporate tax, commercial income. |
| 4 | `resources/scripts/SeasonManager.gd` | 642 | Season rollover pipeline (GDD §7.1 A→E stages). Subtle ordering rules live here. |
| 5 | `resources/scripts/RaceSimulator.gd` | 946 | Race/lap engine, RP earning, degradation, fitness drop. |
| 6 | `autoloads/AIManager.gd` | 613 | **The AI world entry point.** AI team behaviour, roster/assignment loading, the hook the AI economy build extends. Core from S40 onward. |

**Read-order:** ARCHITECTURE.md (this file) → the 6 above → `Supporting Files/GDDv7.5.md` in full. Only then start design work.

---

## TIER-2 (read on demand — when the task touches them)

| File | LOC | Read when the task is about… |
|------|-----|------|
| `resources/scripts/CarManager.gd` | 740 | cars, parts, installation, the multi-driver crew model |
| `resources/scripts/CampusManager.gd` | 632 | buildings, levels, maintenance, the building↔R&D coupling (GDD §10) |
| `resources/scripts/ContractEngine.gd` | 1,665 | contracts, the approach/negotiation flow (GDD §12) |
| `resources/scripts/CommercialMarketSim.gd` | 462 | the road-car market / Factory (GDD §4) |
| `resources/scripts/StaffManager.gd` | 385 | staff generation, free-agent pools |
| `resources/scripts/DriverManager.gd` | 430 | driver generation, GK feeder, standings registration |
| `resources/scripts/SponsorManager.gd` | 558 | sponsor income and offers |
| `resources/scripts/GKDiscipline.gd` | 498 | the GK elimination championship |
| `resources/scripts/TPProposalEngine.gd` | 813 | the TP/personnel assignment optimizer (GDD §9-I) |
| `resources/scripts/LeadDesignerProposalEngine.gd` | 289 | the Lead-designer advisor; **the AI R&D seam** (`ai_fill_design_lines_*`) |
| `resources/scripts/AIChampionshipSim.gd` | 111 | AI championship simulation (works with AIManager) |
| `resources/scripts/NotificationManager.gd` | 678 | notifications / TDL / news routing |
| `resources/scripts/CalendarManager.gd` | 238 | the race calendar (note: no `class_name` by design — preloaded) |

**Data models (small, read once to internalize):** `Car.gd` (205), `Driver.gd` (352), `Staff.gd` (263), `Championship.gd` (167), `Team.gd` (42).

---

## AI SURFACE (for the AI economy build — read all three)

- `autoloads/AIManager.gd` (613) — the entry point; AI team decisions, roster/assignment loading.
- `resources/scripts/AIChampionshipSim.gd` (111) — simulates AI championship results.
- `resources/scripts/LeadDesignerProposalEngine.gd` (289) — carries the inert `ai_fill_design_lines_*` seam the AI R&D economy activates. The P4 accessor layer in `RnDEngine` is already team-aware for this.

Data the AI reads: `data/teams.json`, `data/car_assignments.json`, and the `staff_*.json` pools.

---

## UI SCENES (read only when the task is that specific screen)

Largest/most-referenced: `scenes/MainHub.gd` (1,585), `scenes/buildings/HQ.gd` (2,812), `scenes/buildings/RnDStudio.gd` (1,851), `scenes/StaffHub.gd` (1,766), `scenes/Drivers.gd` (1,426), `scenes/buildings/Garage.gd` (1,105), `scenes/buildings/CNCPlant.gd` (1,093). Others are smaller per-building screens.

---

## COMPANION DOCS (in `Supporting Files/`)

- **`GDDv7.5.md`** — THE single source of truth for design. Read in full at session start. (Do NOT use any `.docx` in the Claude project files as the GDD — those are legacy snapshots.)
- `Brainstorm_Threads.md` — design vision & rationale (the "why").
- `FEATURE_AI_Championship_Sim.md` — spec for the deferred living-world AI feature.
- `Season_Transition_Pipeline_Spec_v1.md` — detailed companion to GDD §7.1.
- `Phase3_Commercial_Validation.md` — the commercial/Factory validation.
- `Road_map.md`, `Notification_News_Roadmap_v1.md`, `TP_Assignment_System_Spec.md`, plus per-phase specs.

---

## KNOWN DOC↔CODE DISCREPANCIES (reconcile when touched)

- **WRA cycle length:** GDD §11 says a flat "every 4 seasons," but the code (`RnDEngine._get_wra_group_season`) uses per-group `CYCLE_LEN` of 4–10 seasons (Formula 4 … Endurance 10). Per the GDD's own rule, code is truth — update §11.
- **Engine version:** some legacy headers/snapshots say Godot 4.6.3; actual is 4.7.

---

## NOTES FOR ANY SESSION

- No Godot binary in this environment: `.gd` changes are verified by Python brace-balance + type audit only. Real parse/playtest is the user's job.
- Strict GDScript: type any `:=` sourced from the untyped `gs`/GameState autoload or untyped loop vars.
- Bump the version header on every edited file; copy edits to outputs + present_files.
- Cars race; drivers are assigned to cars. Every edit reconciles code ↔ GDD.
