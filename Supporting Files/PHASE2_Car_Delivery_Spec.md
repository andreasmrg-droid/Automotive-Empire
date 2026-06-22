# Phase 2 — Car Acquisition & Delivery (Design Spec)

**Status:** SPEC (to be merged into GDD §6 as a new sub-section §6.0, ahead of §6.1 Unified Lap Time).
**Session:** S30 · 2026-06-21 · Author: Andreas Maragkos (design) + build assist.
**Scope rule:** this spec adds the *enforcement* layer only. The data and UI already exist (see "Already built" below); do not rebuild them.

---

## 0. Why this spec exists

The GDD §18 Phase-2 brief is four words: *"delivery delay, P2/P3 gating, DNS-until-ready, deadlines."*
On inspection of the live code (`ee292ae`), three of those four are **already implemented as data + UI + advisories**:

| Brief term | Status in code (`ee292ae`) | Where |
|---|---|---|
| Delivery delay | Data + display only | `GameState.CNC_DATA` (`engine_weeks`), `get_car_delivery_week()` = `max(engine_weeks, race1-1)`; shown on the Logistics buy card |
| Deadlines | Implemented | `get_entry_deadline_week()` = `52 − design_weeks − 1` |
| "P2/P3 gating" (= buy vs own-build) | Implemented | `Logistics.OWN_BUILD_CHAMPS = [C-007,C-008,C-020,C-024]` + per-champ `PART_SPEC` Spec/Open map; own-build redirects to R&D→CNC |
| **DNS-until-ready** | **NOT enforced** | `simulate_race()` DNS pipeline checks fuel/driver/mechanic/pit-crew but **not delivery**; `add_car()` makes a car instantly raceable; `Car.gd` has **no delivery state** |

**Therefore Phase 2's remaining work is narrow and specific:** make `delivery_week` *real* — a car is created undelivered, counts down weekly, and **DNS's each round until it arrives**. Everything else is wiring the existing data into that one new state.

---

## 1. Confirmed design decisions (this session)

1. **Both paths share one rule.** Buy (provider) and own-build (R&D→CNC) both produce a car that is **not ready at season start**; it arrives on the week the lengthiest part finishes (`get_car_delivery_week`).
2. **Single `delivery_week` per car** (whole car arrives at once). No per-part delivery tracking. The lengthiest part *is* the car's delivery week — already what `get_car_delivery_week` returns.
3. **Clock counts down.** `delivery_week` is an **absolute week number in the new season**, set when the player buys / when CNC finishes the car. Each weekly tick checks `current_week >= delivery_week` and flips the car to delivered.
4. **DNS that round only.** If a round runs before the car is delivered, that car/its driver DNS that round (no points). It joins automatically once delivered — no whole-season forfeit, no grace-period special case.
5. **Own-build availability is universal.** Path B (design & manufacture) is available for *every* championship. Path A (buy) is available only where `champ_id NOT IN OWN_BUILD_CHAMPS`.
6. **Excel sync debt closed.** v2.8 already carries GK = 21 races and SC Dev (C-014) cap = 4. §19 item struck.

---

## 2. The two acquisition paths (narrative, current season → next season)

### Path A — Buy (supplier-built car) — buyable championships only
1. **Current season:** team registers for a championship. Engine flags it buyable (not in `OWN_BUILD_CHAMPS`) → TDL item "buy car next season".
2. **Next season starts:** Logistics → BUY RACING CAR shows the buy option for the registered championship.
3. Player buys: pays `get_provider_car_cost(champ_id)`; receives a full car (all 6 parts) **in an undelivered state**.
4. Car becomes raceable on `delivery_week = get_car_delivery_week(champ_id)` (= the lengthiest part, usually the engine).

### Path B — Design & manufacture — all championships
1. **Current season:** team uses R&D **Pillar 1 (Design / Own Development)** and **Pillar 3 (Reverse Engineering, from an already-owned car)** to produce **blueprints**.
2. Blueprints → **HQ-WRA approval** → approved → move to **CNC**, locked until season rollover.
3. **Next season starts:** CNC unlocks the blueprints for manufacturing.
4. Car becomes raceable when the lengthiest manufactured part finishes — same `delivery_week` rule. (Extra build weeks beyond base = higher reliability per §5; base weeks are the delivery floor.)

> First-time entrant with no car to reverse-engineer relies on Pillar 1 only — confirmed fine in current R&D.

---

## 3. New state on the `Car` resource

Add three fields to `Car.gd` (no breaking changes; all default to a delivered/legacy-safe state):

```gdscript
@export var delivered: bool = true          # legacy/existing cars load as delivered
@export var delivery_week: int = 0          # absolute week in the season the car becomes raceable
@export var acquisition: String = "delivered"  # "bought" | "built" | "delivered"(legacy)
```

- `delivered = true` is the **default** so any car loaded from an old save, or any car created by paths not yet migrated, is treated as ready (no silent DNS regressions).
- A freshly acquired car sets `delivered = false`, `delivery_week = get_car_delivery_week(champ_id)`, `acquisition = "bought"|"built"`.

### `Car.is_ready_for_race()` extension
Current signature checks driver/mechanic/pit-crew. Add an **undelivered short-circuit**:
```gdscript
func is_ready_for_race(discipline: String) -> bool:
    if not delivered:
        return false      # undelivered cars cannot start
    # ... existing driver/mechanic/pit-crew checks unchanged ...
```

---

## 4. Enforcement points (exact functions to touch)

### 4.1 Set state on acquisition
- **Buy:** `CarManager.add_car()` (called by `Logistics._on_buy_car_pressed` → `GameState.add_car`). When a `for_champ_id` is supplied during a season (not new-game setup), set `delivered=false`, `delivery_week=get_car_delivery_week(champ_id)`, `acquisition="bought"`.
- **Build (CNC):** when `_advance_cnc_production()` completes the final required part for a car, mark that car delivered or set its delivery week. (Phase 2a can treat the CNC-built car the same as bought: set its `delivery_week` at season start when the build is scheduled.)
- **New-game / instantly-ready cars:** keep `delivered=true` (the `silent` path in `add_car`) so the starting car races immediately as today.

### 4.2 Count down + flip — `GameState.advance_week()`
Add one weekly step (alongside `_advance_cnc_production()`):
```gdscript
_process_car_deliveries()   # flip undelivered cars whose delivery_week has arrived
```
`_process_car_deliveries()`:
- For each `player_team_cars` car where `not delivered` and `current_week >= delivery_week`: set `delivered=true`, fire a Normal notification ("🏎 {car} delivered — ready to race."), log it.

### 4.3 Set delivery weeks at season rollover — `SeasonManager.start_new_season()`
The season-start block already (a) retires all cars and (b) emits "Delivery: Week N" notifications. Extend it so that any car the engine (re)creates for the new season — bought or built — is created **undelivered** with `delivery_week = get_car_delivery_week(champ_id)`. The existing delivery-deadline notifications become *accurate* rather than cosmetic.

### 4.4 DNS-until-ready — `RaceSimulator.simulate_race()`
The DNS pipeline already builds `dns_driver_ids` / `dns_car_ids` for fuel/driver/mechanic/pit-crew. Add one reason **before** those checks:
```gdscript
if not car.delivered:
    car_dns = true
    gs.add_log("🚫 DNS [%s] %s — car not yet delivered (arrives Wk %d)." % [c.championship_name, car_label, car.delivery_week])
    gs.add_notification("High", "DNS: %s not delivered until Week %d." % [car_label, car.delivery_week])
```
Because this runs per-round, a car undelivered at round 1 simply DNS's round 1 and races from the round on/after its delivery week — satisfying "DNS that round only, joins once ready" with **no extra logic**.

---

## 5. UI touch (Logistics) — minimal

The buy card already shows `Delivery Wk N · Race 1 Wk M`. Two small truthful additions:
- After buying, the car appears in the Garage flagged **"In build — arrives Wk N"** (not assignable to race, but driver/mechanic can be pre-assigned so it's ready the moment it lands).
- The "⚠ DNS risk" advisory upgrades from speculative to factual once a car's `delivery_week > first_race_week` (the player *will* miss round(s) — show how many).

All new strings go through `Locale.t(...)` and ship with an updated `Locale.gd` (Rule 3).

---

## 6. What is explicitly OUT of Phase 2 (backlog)

- Per-part delivery tracking / staggered part arrival (decided: single car-level week).
- Mid-season car upgrades changing delivery (that's Pillar 2 upgrade flow, already in-season).
- AI teams' car delivery (AI cars are assumed present; the delivery clock is a player-economy mechanic for now — revisit with the AI Championship Sim, §14).
- Selling undelivered cars / cancelling a build (no cancel path this phase).

---

## 7. Implementation order (proposed for the build half)

1. `Car.gd` — add the three fields + `is_ready_for_race` short-circuit. **(start here — the state model)**
2. `RaceSimulator.simulate_race` — add the undelivered DNS reason.
3. `GameState.advance_week` + `_process_car_deliveries()` — the weekly flip.
4. `CarManager.add_car` — set undelivered state on real purchases (keep `silent`/new-game path delivered).
5. `SeasonManager.start_new_season` — create new-season cars undelivered with their delivery week.
6. `Logistics.gd` — "In build — arrives Wk N" flag + factual DNS-risk line + `Locale.gd` keys.
7. Health checks: Locale key scan, indentation/balance, a save/load round-trip of the new `Car` fields.

Each step is independently testable; steps 1–3 alone make delivery *enforced* even before the UI polish in 6.
