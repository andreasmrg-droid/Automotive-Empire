# Automotive Empire — Buglist & Remaining-Issues Tracker

**Last updated:** 2026-06-25 (Session S37.1)
**Owner:** Andreas Maragkos
**Scope note:** This tracker covers known bugs, pending verification, and latent/structural issues.
Code-level history lives in the GDD changelog (v2.5) and `GDD_UPDATE_and_HANDOFF.md` (GitHub).
GitHub is authoritative; this file is a working tracker.

Status legend: ✅ Fixed · 🟡 Fixed–needs verification · 🟠 Known/latent · 🔵 Backlog/feature · ⚪ Open/unassigned

---

## CLUSTER A — "picked GP4 but saw GK races/results" (CLOSED, pending verification)

| ID | Status | Summary | Resolution / Notes |
|----|--------|---------|--------------------|
| A-CP4 | 🟡 | `active_championship` always returned `active_championships[0]` (= GK), so every legacy single-championship read (fuel/SP/condition, standings init, hiring gates) resolved to GK. | S37.0 getter rewrite: registered champ → owned car's champ → legacy → dummy. RaceSimulator threads the raced `champ` through per-race reads. |
| A-CP4b | 🟡 | A non-GK career still saw a stray **GK result screen** each GK race week. | Root cause: `GKDiscipline.populate_season()` forced ALL player drivers into GK group 0. S37.1: GK group 0 seeded only with real GK drivers (`player_in_gk` flag); weekly loop skips the real C-001 sim when player isn't in GK; GK world still resolved via shadow sim. |
| A-STD | ✅ | Newly-signed drivers were written into GK standings at sign-time (polluting the GK table). | hire_driver + immediate contract sign no longer write standings; driver joins the correct champ's standings at car assignment (Rule #6). Starter registered into its car's champ. |
| A-SP | ✅ | Repairs used a single global (GK) SP rate for all cars across all championships. | Auto-repair and manual `repair_car` now read `sp_per_10_pct_damage` per-car from each car's championship. |

### Verification checklist for Cluster A (do at keyboard — no Godot in the dev-assist env)
- [ ] Real Godot parse of all 6 changed files (no compile errors).
- [ ] Fresh **GP4** game → advance several weeks → **only GP4** result screens appear (no GK).
- [ ] Season end: GK world still crowns a **real champion with non-zero points** (check Racing World / EOS "rest of the world").
- [ ] Fresh **GK** game → GK still plays normally (group 0 = player, semifinal cut, Grand Final).
- [ ] Multi-car player across **two** championships → fuel/SP/condition apply to the right cars only.
- [ ] Save → load mid-season → `player_in_gk` persists; standings intact.

---

## LATENT / STRUCTURAL (not the reported bug, but adjacent — watch these)

| ID | Status | Summary | Notes / Trigger |
|----|--------|---------|------------------|
| L-COND | 🟠 | Per-championship `condition_loss_per_lap` is **hardcoded to 0.5** everywhere it's set. | The S37.0 per-champ condition-scoping is a no-op until distinct values are assigned. Will start mattering the moment championships get different wear rates. |
| L-ROLL | 🟠 | At season rollover, `populate_season` runs while **last season's cars still exist** but registrations are already the **new** season's. | Worked around with a discipline fallback in the GK driver filter. The case to stress-test: a multi-season run that **switches discipline** between seasons. |
| L-GKGATE | 🟡 | GK round/elimination notifications previously gated on registration only; a registered-but-not-fielding-GK player could get GK messages. | S37.1 tightened to the stricter `player_in_gk`. Verify no GK notifications for a registered-but-no-GK-car edge case. |

---

## BACKLOG / FEATURES (design-approved, sequenced after economy)

| ID | Status | Summary | Source / Sequencing |
|----|--------|---------|---------------------|
| F-AICHAMP | 🔵 | **AI Championship Sim** — every championship runs each season via a lightweight strength-scalar result model (not full lap-by-lap). Driver+team champions, standings, reputation hooks for AI teams. | `FEATURE_AI_Championship_Sim.md`. Build AFTER Phase 5 (economy/balance); pair with Transfer Market. New `AIChampionshipSim` RefCounted, Python-portable. |
| F-TRANSFER | 🔵 | **Transfer Market (P51)** — AI rivals sign drivers/staff; pairs with AI Championship Sim to make the world "alive." | Brainstorm thread 3 / feature spec. After economy. |
| F-AILADDER | 🔵 | **AI 5-stage ladder** (Survive→Settle→Develop→Establish→Conquer). Per-stage decision points still UNMAPPED (deferred until economy systems exist). | Brainstorm thread 1. Each economic system ships WITH its AI behavior attached. |
| F-NEWS | 🔵 | **News System** — sound-wave propagation model: `reach = importance − vertical_distance − horizontal_distance`; reuses the discipline-adaptation matrix; tier compresses horizontal distance. | Brainstorm thread 2. After/parallel to the living-world features. |
| F-RACEMOD | 🔵 | **Race module** (built LAST): 2D track + Telemetry Wall (3 rotating tabs) + speed control that snaps to ×1 and notifies on critical events. | Brainstorm thread 5. Economy first, race last. |
| F-FITCLINIC | 🔵 | **Fitness Clinic rework** — slash absurd max level; automate allocation ("most tired served first"); drag its R&D ladder with it. | Brainstorm thread 4. Coordinate with building-max ↔ R&D gate rule. |
| F-BLDGATE | 🟠 | **Building max ↔ R&D gate coupling** — building max levels don't match personnel peaks (driver demand ≫ Racing Dept slots). Rebalance deliberately, coordinated with R&D gates, or projects orphan. | Brainstorm thread 4. Pending balance work (Phase 5). |

---

## ROADMAP ANCHORS (from Brainstorm_Threads.md — for sequencing context)
- Phase 2: §23 car system (delivery delay, P2/P3 gating, DNS-until-ready, deadlines) — ECONOMY.
- Phase 3: Commercial factory + R&D Pillar 5 (second weekly income → playable without race).
- Phase 4: Stock market.
- Phase 5: Multi-season BALANCE pass — derive AI budgets & character as OUTPUTS; tune building maxes + R&D gates; headless Python stress-tests + playtests.
- Then: race sim swap-in. Parallel/after: AI Championship Sim + News System + Transfer Market.

---

## HOW TO USE THIS FILE
- Add new bugs at the top of the relevant section with a fresh ID (CLUSTER letter + short tag).
- Move ✅/🟡 items to a "Resolved" archive once verified in a real build + committed.
- Keep GitHub as the source of truth; sync this tracker there alongside the GDD.
