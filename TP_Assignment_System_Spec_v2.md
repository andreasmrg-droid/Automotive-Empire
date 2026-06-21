# TP Assignment System — Redesign Spec v2 (FINAL)

**Status:** SPEC → merge into GDD §9 (Staff) + §12. Supersedes spec v1 and the ad-hoc behaviour in
TPProposalEngine.gd. **Baseline:** GitHub `0d119db`. Session S32–S33 · Author: Andreas Maragkos.

This v2 captures every requirement clarified in the design conversation. Build from THIS.

---

## 1. Concept (unchanged)

Team Principals are advisors: they compute the optimal personnel allocation and **propose** it to the
player (accept all / some / reject; never auto-assign). AI teams use the **same optimiser** but
**apply directly** (no proposal). One consolidated proposal for the player — never one per TP.

## 2. The five personnel roles & their allocation rules

| Role | Granularity | Discipline adaptation? | Skipped for | Player surface | AI |
|---|---|---|---|---|---|
| **Driver** | per car | YES (`raw × adapt/100`) | — | proposal | auto-assign |
| **Mechanic** | per car | YES | — | proposal | auto-assign |
| **Pit Crew** | per car | **NO** (raw stats only) | **GK** (not required) | proposal | auto-assign |
| **Strategist** | **per championship** | YES | **GK and Rally** (not used) | proposal | auto-assign |
| **Team Principal** | **per championship** | YES | — | **MANUAL — no proposal** | **auto-reassign (season start)** |

Common to all: **prestige-ordered** allocation (best person → highest-prestige championship/car
first), and the **commitment rule** (one person → one championship; a committed person is removed
from the pool for all lower-prestige cars/championships).

### Granularity detail
- **Per-car** (driver, mechanic, pit crew): written to `car.driver_id` / `car.mechanic_id` /
  `car.pit_crew_id`.
- **Per-championship** (strategist, TP): written to `staff.assigned_championship`. A championship may
  field multiple cars but shares ONE strategist and ONE TP.

### Exceptions (skip the role entirely)
- **Pit Crew:** not required for **GK** → no pit-crew proposal/assignment for GK cars.
  (`get_pit_crew_required(champ_id)` already encodes this.)
- **Strategist:** not used in **GK or Rally** → no strategist proposal/assignment for those.
- **Adaptation:** applies to Driver, Mechanic, Strategist, TP. **Pit Crew uses raw stats** (no
  adaptation correction at all).

## 3. Scoring (effective stats)

- Driver: `eff_pace×0.6 + eff_consistency×0.4`, where `eff = raw × adapt/100`. Age eligibility
  (`min_age`/`max_age`) enforced.
- Mechanic: `eff_car_setup` (raw car_setup × adapt/100).
- Strategist: `eff_race_strategy` (raw race_strategy × adapt/100).
- **TP: `eff_overall` — sort AI TPs by OVERALL score** (aggregate of the TP's stats), then × adapt/100.
  Add `Staff.get_overall_skill()` mirroring the existing `Driver.get_overall_skill()` and the
  Designer aggregate in `get_primary_skill()`. For a TP, overall = mean of its amplifier/utility
  stats: `(race_strategy + practice_management + qualifying_management + race_pace_reading +
  car_setup_oversight + pit_stop_management + pr_skill + parts_knowledge + track_knowledge) / 9`.
  (The existing `get_primary_skill()` returns only `race_strategy` for a TP — keep it for the label,
  but AI TP allocation uses the overall aggregate.)
- **Pit Crew: raw** `pit_stop_speed` (+ optionally repair_skill) — NO adaptation.

## 4. Player vs AI

### Player — proposal (4 roles: driver, mechanic, pit crew, strategist)
- TP is **NOT** proposed — the player assigns/changes TPs manually.
- The consolidated proposal covers all the player's cars/championships in one set.
- Lifecycle (single source of truth `_last_tp_proposals`): generate → ONE notification + ONE tagged
  TDL → popup reads the source (no regeneration on view) → accept all / some / reject.
- **Partial accept → re-optimise:** accepted people become committed; the optimiser re-runs for the
  remaining unassigned cars/championships over the reduced pool; result becomes the new proposal.
- Consumed (all assigned or rejected) → clear `_last_tp_proposals`, dismiss TDL (by stable tag),
  clear notification.

### AI — auto-assign (5 roles: + TP)
- At **season start** and on **roster change**, AI teams run `compute_optimal_assignments(team)` and
  **apply directly** (no UI): driver/mechanic/pit-crew/strategist **and Team Principal**.
- **TP reassignment is AI-only and happens at season start:** allocate each AI team's TPs across its
  championships, best TP → highest-prestige championship (same shape as strategists).
- JSON (`car_assignments.json`) remains the **season-1 seed**; the optimiser takes over from the
  first roster change / new season onward.

## 5. Architecture — shared optimiser, two consumers

```
compute_optimal_assignments(team, team_cars, include_tp: bool) -> Array
   # pure, team-agnostic, headless-testable. Prestige order + effective stats +
   # commitment + per-role granularity + exceptions. Returns proposal objects.
   # include_tp=false for the player surface, true for AI.

Player:  generate_tp_assignment_proposals()
           = compute_optimal_assignments(player_team, player_team_cars, include_tp=false)
           → store _last_tp_proposals → fire ONE notification + ONE TDL.
         apply_tp_proposals(subset): apply per-car/per-champ; partial → re-optimise remainder.

AI:      ai_auto_assign(team)
           = compute_optimal_assignments(team, team_cars, include_tp=true) → apply directly.
         Hooked at season start (after JSON seed) and on AI roster change.
```

## 6. Proposal object (data model)

```
{
  "kind":        "assignment",                # future: "signing"
  "type":        "assign_driver" | "assign_mechanic" | "assign_pit_crew"
                 | "assign_strategist" | "assign_tp"
                 | "missing_driver" | "missing_mechanic" | "missing_pit_crew"
                 | "missing_strategist" | "dns_warning",
  "scope":       "car" | "championship",      # car for driver/mech/pit; championship for strat/TP
  "car_id":      String,                       # "" for championship-scope
  "champ_id":    String,
  "champ_name":  String,
  "person_id":   String,
  "person_name": String,
  "eff_score":   float,
  "note":        String,
  "priority":    "normal" | "warning" | "critical",
}
```

## 7. TDL / notification correctness (kill current bugs)
- ONE notification + ONE TDL per proposal, tagged with a stable id (e.g. todo "kind" = `"tp"`),
  dismissed by tag — never by fragile text-match.
- Remove the duplicate `add_todo_item` sites in the weekly check.
- On consume/re-optimise: dismiss the old TDL before adding any new one.

## 8. Refresh (kill current bug)
- On popup close, RacingDept must call `_build_ui()` AND `refresh()` (the former clears the driver
  list; only the latter refills it).
- Popup edits only `_last_tp_proposals`; the panel re-reads it. No divergent local copies.

## 9. Build order (phased, with a checkpoint)
**Phase 1 — engine + player surface (testable):**
0. `Staff.gd` — add `get_overall_skill()` (TP = mean of its 9 amplifier/utility stats; other roles
   can mirror their primary-skill grouping). Used for AI TP sorting (Phase 2) and any "overall"
   display.
1. `compute_optimal_assignments(team, cars, include_tp)` — shared optimiser: driver/mechanic/pit
   (raw)/strategist(per champ, GK+Rally skip)/TP(per champ, sort by overall × adapt); prestige +
   commitment; `_find_best_*` drop `is_gk`, add pit-crew & strategist & TP finders.
2. `generate_tp_assignment_proposals()` = wrapper (include_tp=false) + ONE notification/TDL.
3. `apply_tp_proposals()` — apply per-car & per-championship (set assigned_championship for strat);
   partial → re-optimise; TDL dismiss by tag.
4. `TPProposalsPopup.gd` — single source; rows for driver/mech/pit/strategist; pit/strategist only
   where applicable.
5. `RacingDept.gd` — close → `_build_ui()` + `refresh()`.
6. `Locale.gd` — new strings.
→ **CHECKPOINT: player tests in Godot.**

**Phase 2 — AI:**
7. `ai_auto_assign(team)` (include_tp=true) — apply all 5 roles incl. TP reassignment.
8. Hook at season start (after JSON seed) + AI roster change.

## 10. Out of scope (backlog)
- Driver-signing scouting proposals (the `kind="signing"` hook only).
- A change-cooldown (dropped — commitment rule covers exploitation).
- AI "character" weighting of allocation (Phase-5 balance).
