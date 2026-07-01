# GK ELIMINATION — SAFEGUARD SPEC (freeze before the session-model migration)

This is the behavioral contract for the GK championship as it works in code TODAY (S41.x).
The sessions[] migration MUST preserve every item below. If a change would alter any of these,
stop and flag it — do not silently change GK behavior.

Source of truth in code:
- `resources/scripts/GKDiscipline.gd` (497 lines) — the elimination engine.
- `autoloads/GameState.gd` — CHAMPIONSHIP_CALENDARS["C-001"] (22 entries) + the advance_week GK block.

---

## 1. THE 4-ROUND STRUCTURE (GKDiscipline.ROUNDS — MUST NOT CHANGE)

| Round | groups | max_per_group | races | qualify_per_group | gk_round |
|-------|--------|---------------|-------|-------------------|----------|
| 1     | 32     | 0 (no cap, ~750 total) | 8 | top 10 → 320 advance | 1 |
| 2     | 16     | 20            | 7     | top 8  → 128 advance | 2 |
| 3     | 4      | 32            | 5     | top 15 → 60 advance  | 3 |
| Final | 2      | 30            | 2     | (see §2)             | 4 |

- 8 + 7 + 5 + 2 = **22 race entries** (calendar rounds 1..22).
- Player is auto-assigned to a Round-1 group. Eliminated drivers sit out the rest of the season.
- Non-player groups run a LIGHTWEIGHT shadow sim (standings only, no lap-by-lap) via
  `shadow_simulate_week(week, all_drivers)`. Player's group runs the full RaceSimulator.

## 2. THE FINAL WEEKEND (rounds 21 + 22, SAME week 46) — THE CORE CONCEPT

Two races, same weekend, in the 2 final groups of 30:
- **Round 21 = Semi-Final** (`is_semifinal:true`). Also a DOUBLE race concept in the design.
  After it, `apply_semifinal_cut()` keeps the **top 10 per group** across the 2 final groups and
  COLLAPSES them into ONE 20-driver Grand Final group (points reset to 0).
- **Round 22 = Grand Final** (`is_final:true`). The 20 survivors race; the **race winner = GK
  World Champion** (`get_champion()` returns the Grand Final group's top driver = race winner,
  NOT cumulative season points).

Both share `gk_round:4` and `week:46`. The two-races-same-week detection in advance_week relies on
scanning to the LAST same-week race to trigger round advancement (so race 1 doesn't prematurely
advance the round).

## 3. THE FLAGS THAT DRIVE IT (must survive into the new schema)

Per calendar entry:
- `gk_round` (1..4) — which elimination round this race belongs to. Round advancement in
  `advance_week` reads this to know when a gk_round's last race has run → calls `advance_round()`.
- `is_semifinal:true` — on round 21. Triggers `apply_semifinal_cut()` (top-10-per-group → 20).
- `is_final:true` — on round 22. Marks the champion-deciding race; drives the results-screen label
  ("GK Championship Final! — <city>") which is keyed off THIS FLAG, never city/round number
  (there are two "Las Vegas" GK rounds; only the flagged one is the semifinal).

In the sessions[] model these become session properties, e.g.:
  `{ "type":"race", "gk_round":4, "role":"semifinal", "double":true, "cut":"top10_per_group" }`
  `{ "type":"race", "gk_round":4, "role":"final", "grid_from":"semifinal", "decides_champion":true }`
…but the SEMANTICS above must be identical.

## 4. FUNCTIONS THAT MUST KEEP WORKING (GKDiscipline public API)

- `populate_season(all_drivers, all_staff, player_driver_ids, registered, calendars, season, cars)`
  — builds groups for the season; resets `eliminated` + `player_elimination_announced`.
- `shadow_simulate_week(week, all_drivers)` → `{team_id: points}` for non-player groups (folded into
  C-001 team_standings; the GK TEAM champion counts ALL races, the DRIVER champion uses elimination).
- `advance_round(all_drivers)` — cut + advance to next round (calls `apply_semifinal_cut()` at final).
- `apply_semifinal_cut()` — top-10-per-group → single 20-driver Grand Final group, points reset.
- `get_champion()` — Grand Final winner (race winner, not cumulative).
- `is_eliminated(id)`, `get_player_group(cid)`, `get_standings/all_standings`, `get_current_round`,
  `get_round_count`, `is_complete`, `serialize/deserialize`, `player_elimination_announced`.

## 5. GAMESTATE HOOKS (advance_week GK block — must keep firing)

- Scans C-001 STATIC calendar by week to decide if GK raced this week and whether it was a semi week
  (uses `is_semifinal`). Fires the elimination notice EXACTLY ONCE (`player_elimination_announced`).
- Round-advance detection scans to the LAST same-week race (multi-event final weekend).
- Folds `shadow_simulate_week()` team points into C-001 `team_standings`.

## 6. NON-NEGOTIABLE INVARIANTS (the checklist for "did we break GK?")

1. 32→16→4→2 group cascade with 10/8/15 per-group qualification counts intact.
2. Final weekend = 2 races, same week, semifinal cut (top-10-per-group → 20) then final.
3. Champion = Grand Final RACE WINNER, not season points.
4. Player elimination announced exactly once, at the real round of exit.
5. GK TEAM champion counts all races; DRIVER champion via elimination.
6. Non-player groups stay lightweight (no full sim); player group full sim.
7. Save/load round state survives (serialize/deserialize).
8. Results screen labels semifinal/final off the FLAGS, not round number/city.

Any migration step that can't satisfy all 8 → PAUSE and flag.
