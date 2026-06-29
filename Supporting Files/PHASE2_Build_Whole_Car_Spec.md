# Phase 2 — "Build Whole Car" CNC action (Design Spec)

**Status:** SPEC → merge into GDD §8 (R&D / CNC) and §6.0 (Car Acquisition & Delivery).
**Session:** S30 · 2026-06-21 · Author: Andreas Maragkos (design) + build assist.
**Depends on:** Car.gd S30.0 (delivery state), GameState S30.2 (delivery clock + serialization),
RaceSimulator S30.1 (DNS-until-ready), CarManager S30.3 (buy = in-build).

---

## 1. Problem

The own-build championships (C-007 RALLY2, C-008 Premier Rally, C-020 EPC Hyper, C-024 GP1) have
no buy option — the player must design + manufacture. But today there is **no single action that
produces a raceable car** from manufactured parts: the player would have to press six separate
"Start Manufacturing" buttons, and even then no `Car` object is created (a `Car` only comes from the
buy flow). Result: own-build championships are currently unfinishable. This also applies to any
buildable championship where the player *chooses* to build rather than buy.

## 2. Decision (confirmed this session)

- **One button, "Build Whole Car"**, in the CNC Parts Plant. Queues all 6 part jobs in a single pass.
- **Gating:** enabled only when **all 6 part blueprints for that championship are WRA-approved and
  present in CNC** (`is_blueprint_approved` true for each of Aero/Engine/Gearbox/Suspension/Brakes/
  Chassis). Otherwise disabled, showing which parts are missing.
- **Slot-limited queue:** the 6 jobs enter the existing `cnc_production_queue`; the plant's slot count
  (`get_cnc_slots()`, from building level) governs how many run in parallel. Parts beyond the slot
  count wait, exactly like current CNC behaviour (S28.3).
- **Car created immediately, in-build.** The moment the player clicks, a `Car` is created with
  `delivered = false`, `acquisition = "built"`. This triggers driver/staff assignment options and TP
  proposals **right away** (so the player can crew the car while it builds) — identical to the buy flow.
- **Delivery = when the LAST part finishes.** `delivery_week` = current_week + the slot-aware
  completion week of the slowest of the 6 queued jobs (not the generic engine-weeks estimate). The car
  flips to delivered via the existing weekly `_process_car_deliveries()` clock.
- **Build/buy is independent of assignments.** Acquiring a car never assigns anyone; it only *offers*
  the assignment + TP-proposal options. (Already true for buy; the build path reuses the same trigger.)

## 3. Slot-aware delivery week

Given 6 jobs each with `weeks_total = w[i]` and `S = get_cnc_slots()` parallel slots, completion is a
list-scheduling problem (each freed slot takes the next job). Compute:

```
finish_offset = schedule_completion(weeks = [w0..w5], slots = S)   # weeks from now until the last finishes
delivery_week = current_week + finish_offset
```

`schedule_completion`: maintain `S` slot-end times (start at 0), repeatedly assign the next job to the
earliest-free slot (`slot_end += job_weeks`); the answer is `max(slot_end)`. With S ≥ 6 this is just
`max(w)`. With S < 6 it accounts for queue waiting — matching the queue-card ETAs the UI already shows.

> Extra reliability investment (`+wks`) is **not** offered in the one-pass build (kept simple: base
> weeks only). Players wanting to over-invest a specific part can still use the per-part manufacture
> controls. Backlog: optional per-part quality sliders in the build dialog.

## 4. Engine API (GameState, delegating to RnDEngine where the CNC data lives)

```gdscript
## True only if all 6 part blueprints for champ_id are WRA-approved & in CNC.
func can_build_whole_car(champ_id: String) -> bool

## Returns the list of part names still missing an approved blueprint (for UI hinting).
func missing_car_blueprints(champ_id: String) -> Array

## Creates the in-build Car (acquisition="built"), queues all 6 CNC jobs, sets the
## slot-aware delivery_week, fires assignment + TP proposals. Returns false if gating
## fails, garage full, or insufficient funds for the 6 jobs.
func build_whole_car(champ_id: String) -> bool
```

`build_whole_car` flow:
1. Guard: `can_build_whole_car`, garage slot free (`player_team_cars.size() < get_max_cars()`),
   affordability (sum of the 6 `get_cnc_manufacturing_cr`).
2. `add_car(champ_id, silent=false)` → creates the in-build Car and fires assignment/TP proposals.
   (add_car sets delivered=false / acquisition="bought"; build_whole_car then overrides
   acquisition="built" and recomputes delivery_week from the real queued jobs.)
3. For each of the 6 parts: resolve its approved blueprint_id → `start_cnc_job(bp_id, 1)`.
4. Compute slot-aware `delivery_week` from the 6 job `weeks_total`; assign to the new car.
5. Log + Normal notification ("🏗 {champ} car in build — all 6 parts queued, arrives Wk N").

## 5. UI (CNC Parts Plant)

A "BUILD WHOLE CAR" section at the top of the MANUFACTURE PARTS column, per registered championship
the player has no car for yet:
- Enabled button when `can_build_whole_car`; shows projected delivery week + total CR.
- Disabled with a clear "Missing: Engine, Chassis…" line when blueprints are incomplete
  (`missing_car_blueprints`).
- All new strings via `Locale.t(...)`; `Locale.gd` updated in the same pass (Rule 3). Pre-existing
  hardcoded strings in CNCPlant.gd are NOT touched (full sweep is a separate deferred task per GDD §16).

## 6. Out of scope (backlog)

- Per-part quality sliders inside the one-pass build.
- AI teams using build_whole_car (AI cars are assumed present; player-economy mechanic for now).
- Cancelling / refunding an in-progress whole-car build.
