# Feature Spec — AI Championship Simulation (the "living world")

**Status:** BACKLOG (noted S28.4, 2026-06-18). Not a bug — a real feature.
**Add to GDD §16 / roadmap. Sits alongside P51 (Transfer Market) as part of "the AI world is alive."**

---

## Problem / motivation

Today, only the championship(s) the player actually races get standings populated.
`Championship.add_points()` is called exclusively from the player's own race
(`RaceSimulator` line ~280). Every other championship in `active_championships`
has **empty** `standings` / `team_standings` all season.

Consequences:
- The end-of-season screen can only show championships the player raced (the S28.4
  fix correctly filters to `player_registered_championships` — this prevented the
  empty-data crash, incl. the bankruptcy-continue crash).
- There is no sense of a living world: rival championships have no champions, no
  results, no narrative. The player can't "scout" a series before entering it.
- AI team reputations don't move based on results in series the player isn't in.

## What "done" looks like

Every championship in the world runs each season — whether or not the player is in it —
and produces:
- A driver champion + full final standings.
- A team champion + team standings.
- Per-round results good enough to show a season summary.
- Hooks for reputation/marketability movement of AI teams based on results.

The player can then:
- See other championships' champions & standings on the end-of-season screen
  (a read-only "Rest of the World" section).
- Browse live standings of any championship mid-season in the Racing World view.
- Make informed decisions about which championship to enter next.

## Design approach (keep it cheap — this must run every week for ~20+ championships)

**Do NOT run the full lap-by-lap race sim for AI championships** — far too expensive
to do 20+ championships × N rounds × full physics every week. Instead use a
**lightweight "result model"**: each AI car has a single strength score derived from
its existing stats (driver skill × car performance index × staff multipliers × a
random race-day factor). Sort by score + noise → finishing order → award points via
the championship's existing points table. This reuses `Championship.add_points()` and
the existing standings structures, so the EOS / Racing World screens need almost no
change once data exists.

Suggested pieces:
- `AIChampionshipSim` (new RefCounted engine, testable headless):
  - `simulate_round(champ)` → produces finishing order + awards points.
  - `car_strength(car)` → single scalar from existing stats (pure function — Python-portable for balance tests).
  - `simulate_season_to_date(champ)` → catch-up for championships when first viewed.
- Hook into the weekly tick / season advance so AI championships advance their rounds
  in lockstep with the calendar (each champ has its own race weeks).
- At season end, derive champion = top of final standings (same as player champ logic).

## Why it's deferred (not fast)

- Needs a new sim engine + a balanced strength model (so AI results feel plausible,
  not random) — that's a balance pass in itself.
- Touches the weekly tick, season transition, and the standings/EOS/RacingWorld reads.
- Best built AFTER the economy phases, because AI team budgets/character (Phase 5)
  should influence how strong each AI team's cars are — i.e. the strength model
  should read the same economic outputs we're about to build. Building it now would
  mean re-deriving the strength inputs later.

## Recommended sequencing

Slot this AFTER Phase 5 (multi-season balance), alongside / just before the race sim
swap-in, and pair it conceptually with **P51 Transfer Market** — together they make the
AI world fully alive (rivals race, get results, sign drivers, build reputation).

## Cheap interim option (if you ever want *something* before the full feature)

A read-only "Other Championships This Season" list on the EOS screen showing just
name / discipline / tier / "Not entered" — **no standings access**, so no crash risk.
Low value (duplicates the championship browser) but zero risk. Currently declined.
