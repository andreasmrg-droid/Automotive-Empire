# BUG REPORT — Driver & Staff Pool Depletion / `DRV-XXXXX` Naming

**Status:** Diagnosed, NOT fixed. Deserves its own focused session (touches driver + staff
generation pipelines, the GK feeder, and NameGenerator — none of it is R&D).
**Severity:** Cosmetic-escalating-to-structural. World integrity degrades over ~5–10 seasons.
**Discovered:** 10-season playtest (S41.6 build). Confirmed against code + `drivers_professional.json`.

---

## Symptom 1 — drivers display as `DRV-XXXXX` instead of names

From ~S2 onward, championship winners appear as e.g. `RALLY4 — Champion: DRV-05818`. The
affected tiers climb over time: S2 it's only low Rally/TC classes; by S10 it has reached OWC
and EPC. GK, GP1, and other pinnacle classes still show named drivers longest (deepest pools).

### Root cause
Two compounding issues:

1. **The GK feeder generates 0 new cadets every season.** Every rollover logs
   `GK feeder: cleared N stale FA, generated 0 new young cadets`. In
   `DriverManager.regenerate_gk_field` the top-up is `to_make = target_size (510) − existing_GK_racers`.
   But GK drivers **age in place and never leave GK**, so `existing` stays at 510 and `to_make`
   is permanently 0. The feeder — the intended birthplace of all new named talent — never fires.

2. **No promotion pyramid + finite named pools.** Named drivers come from the JSON pools
   (`drivers_professional.json`: `teams` = 734 named e.g. "William Wilson", `free_agents` = 120
   named e.g. `DRV-07020` "Rune Jensen"; `drivers_cadets.json`: `free_agents` = 0). They retire
   at 44–50. With no feeder producing replacements and no pyramid promoting GK → pro, the pools
   drain from the top. Depleted seats get backfilled by drivers whose `first_name`/`last_name`
   are empty, so `Driver.full_name()` (`first_name + " " + last_name`) renders the raw ID.

### Data notes
- JSON name keys are `first` / `last` (NOT `first_name`/`last_name`). The loader
  `AIManager._driver_from_dict` maps them correctly and defaults to `"Unknown"`/`"Driver"`.
- `drivers_cadets.json` `free_agents` is already empty (0) at game start — the cadet reservoir
  has no depth to begin with.

---

## Symptom 2 — staff will hit the same wall (predicted, confirmed coming)

S8 is the first mass staff-retirement wave (age 65): Team Principals, Race Mechanics, Pit Crew,
CFOs, Designers, Race Strategists all retire together; S9–S10 continue it. **There is no staff
feeder at all.** Pools are finite and small:

| Pool | Size |
|------|------|
| staff_designer | 100 |
| staff_mechanic | 20 |
| staff_tp | 20 |
| staff_strategist | 20 |
| staff_cfo | 20 |
| staff_pitcrew | 20 |

With no regeneration, staff will deplete and fall back to the loader's `"Unknown"/"Driver"`
default → "Unknown Driver" staff. Worse than the driver case (drivers at least have a—broken—
feeder; staff have none).

### Downstream R&D impact (why this also matters for the planner)
The S41.6 AI R&D planner requires each AI team to have a **Lead Designer** (`_lead_designer_for`)
to drive its design lines. As Designers retire with no replacement, AI teams lose their Lead →
`_lead_designer_for` returns "" → the planner early-outs and does nothing. This is the leading
suspected cause of the **zero `[AIPlan]` lines** across the 10-season playtest (see separate
finding). Fixing the staff feeder is likely a prerequisite for the planner to actually run.

---

## Fix direction (for the dedicated session — NOT this one)

1. **Fix the GK feeder counting.** `regenerate_gk_field` should top up to a target *intake of
   young cadets* (e.g. maintain a rolling population by age band), not "fill to 510 total". Base
   `to_make` on a young-age-band count or a fixed per-season intake, so new named 8–17 y/o cadets
   enter every season regardless of the aged-in-place population.
2. **Add a staff feeder.** Mirror the (fixed) driver feeder: generate N new junior staff per role
   per season via `NameGenerator`, contracted or into a free-agent pool, so retirements are
   replaced. Size the intake to the retirement rate (~1 wave every few seasons per role).
3. **Backfill safety net.** Any runtime-created driver/staff MUST get a `NameGenerator` name; the
   `"Unknown"/"Driver"` loader default should never reach a race seat. Audit every runtime
   creation path (`_fill_championship_grids`, filler teams, promotions) to ensure naming.
4. **Optional: expand the seed JSON pools** for more starting depth, but the feeders are the real
   fix — expanding pools only delays depletion.

## Files implicated
- `resources/scripts/DriverManager.gd` — `regenerate_gk_field` (the 0-cadet bug), `_create_driver*`
- `resources/scripts/SeasonManager.gd` — rollover, `_process_off_season_aging`, feeder call site
- `autoloads/AIManager.gd` — `_driver_from_dict`, `_from_dict` (staff), `_fill_championship_grids`
- `autoloads/NameGenerator.gd` — name generation
- `data/drivers_*.json`, `data/staff_*.json` — seed pools
