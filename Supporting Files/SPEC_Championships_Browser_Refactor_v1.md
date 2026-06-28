# Spec — Retire `CHAMP_TEAMS`, drive the Championships browser from real data (C-full)

**Status:** BACKLOG / next focused session. **Author note:** scoped S37.50 after the #22 name-IP
cleanup. This is a *scene refactor*, not a name-fix — deliberately split out so it gets a clean start.

---

## Problem

`scenes/Championships.gd` renders the championship browser from **hardcoded** structures that
duplicate (and drift from) the real simulated data, and carry the last of the #22 IP exposure:

- `CHAMP_TEAMS` (const, ~line 82) — a flavour list of team-name strings per championship key. Contains
  real-org names ("Andretti Collective" ×, "Alpine Rally Team") and US-venue place-names (Indy
  Collective, Long Beach Racing, Mid-Ohio Motorsport, Road America Collective, Portland, Chicagoland…).
- `CHAMP_STAFF` (const, ~line 1075) + `CHAMP_KEY_IDX` (~1051) — a parallel per-team display structure
  (tp / designers / drivers / cars counts) keyed by the hardcoded team-name strings.
- `ID_TO_KEY` (~1290) maps championship id → CHAMP_TEAMS key; `GK_GROUPS` (~1302) holds GK group counts.
- Description text with real trademarks: "IndyCar-equivalent", "Indy NXT equivalent", "USF equivalent"
  (the #30 building-text audit fixed this class elsewhere but missed Championships.gd).

These are **display-only** (the browser's team rows), separate from the real simulation
(`teams.json` → `GameState.all_teams` / `ai_cars[champ_id]`). So the browser shows a *different,
fictionalised-but-IP-tainted* roster than the rest of the game (Racing World, standings).

## Goal (owner-confirmed)

Move the browser to the **single source of truth**: derive each championship's roster (and staff
display) from the **real** data — `teams.json` / `ai_cars[champ_id]` / the team's `championships`
field — the same data the AIChampionshipSim and Racing World use. Delete `CHAMP_TEAMS` /
`CHAMP_STAFF`. Fix the description text. **Hard requirement: NO championship may render empty —
every championship must show a full grid.**

## Data sources available (verified S37.50)

- `ai_cars[champ_id]` → array of `Car` objects actually entered in that championship (real teams,
  with `mechanic_id` / `pit_crew_id` / `driver_id`). Car → team via the `T-xxx` prefix of `car.id`
  (e.g. `CAR-T-001-C-024-0` → T-001) or the team's roster.
- `GameState.all_teams` (from `teams.json`) — each team has `id`, `team_name`, `championships`
  (dict of disciplines→count it competes in), `staff`, `drivers_pro/cadet`.
- `T-FILL-<cid>-NNN` procedural teams (AIManager ~line 515) — already generated at runtime to fill
  under-subscribed championships. **These are the "no empty championship" mechanism** — the browser
  must include them, not just the 172 named teams.
- Team-level staff for the display (TP / designers): resolve via `get_player_staff_by_role` analogues
  for AI teams, or read the team's staff list. (Confirm the exact accessor when implementing.)

## Proposed approach

1. **Delete** `CHAMP_TEAMS`, `CHAMP_STAFF`, `CHAMP_KEY_IDX`, `ID_TO_KEY` (keep `GK_GROUPS` only if GK
   grouping still needs it — see step 4).
2. **New helper** `_teams_in_championship(champ_id) -> Array` — returns the real teams fielding a car
   in `champ_id`, derived from `ai_cars[champ_id]` (dedupe by team) **plus** any `T-FILL` teams for
   that championship, so the grid is always full. This is the heart of the "no empty championship"
   guarantee.
3. **Rewrite `_add_team_row`** to take a real team (or team_id) and read its name + staff from the
   real objects instead of the `CHAMP_STAFF` lookup.
4. **GK grouping** — GK shows groups, not a flat list. Decide: reuse the real GK group structure
   (`GKDiscipline`) if it exposes per-group team lists, or keep a thin grouping helper over the real
   roster. Must still distribute with no empty group (existing logic comment: "no empty groups").
5. **Description text** — strip "IndyCar-equivalent"/"Indy NXT equivalent"/"USF equivalent" →
   discipline-based phrasing (mirror the #30 fix: e.g. "The pinnacle of Open-Wheel racing").

## Acceptance criteria

- No hardcoded team-name list remains in `Championships.gd`; rosters come from real data.
- **Every** championship (all 21, incl. GK and any low-subscription tier) renders a full, non-empty
  grid — verified by opening each tab.
- Team names shown match what Racing World / standings show for the same championship (one source
  of truth).
- No real-org / real-trademark strings remain (no "Andretti", "Alpine Rally", "IndyCar", "Indy NXT").
- Parses clean; opening every championship tab throws no runtime "invalid key/property" errors
  (watch the field-name trap — confirm each real-object field exists before reading it).

## Risk / why it's its own session

Touches scene rendering + GK grouping + staff display + gap-fill, all at once. The field-name trap
(reading a key that doesn't exist on the real Car/Team objects) only surfaces at runtime, so this
needs careful per-field verification and a keyboard pass over all 21 tabs. Best done fresh, not at a
session tail.

## Related backlog (from §22 / §19)

- `NewGame.gd` card `buildings` display vs. real provisioning (GP4 understated) — cosmetic, separate.
- Designer-model reconsideration (1-per-principle + per-special-project + 1 commercial) — separate.
- Drivers-per-car (#38: Rally co-driver / EPC trio) — separate, larger, intersects the race sim.
