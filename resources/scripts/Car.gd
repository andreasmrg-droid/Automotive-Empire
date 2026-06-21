class_name Car
extends Resource
## Version: S30.0 — Phase 2 delivery state: delivered / delivery_week / acquisition.
##   Cars are now acquired in an "in-build" state and only become raceable on their
##   delivery week (max part build time, per get_car_delivery_week). is_ready_for_race
##   short-circuits to false while undelivered → DNS-until-ready (enforced in RaceSimulator).
##   All three new fields default to a delivered/legacy-safe state so existing saves and
##   the new-game starter car load as ready (no silent DNS regressions).
## --- S29.8 — Comment: "GK Regional" -> "GK Championship" (cosmetic).

# ── Identity ──────────────────────────────────────────────────────────────────
@export var id: String = ""              # "CAR-P001", "CAR-P002", etc.
@export var car_type_id: String = ""     # "A_01" — links to Cars sheet baseline data
@export var championship_id: String = "" # "C-001"
@export var car_number: int = 1          # Display number: Car 1, Car 2, etc.
@export var car_name: String = ""        # Generated name: e.g. "GKR-S1-A"

# ── Assigned personnel ────────────────────────────────────────────────────────
@export var driver_id: String = ""      # "" = no driver assigned
@export var mechanic_id: String = ""    # "" = no mechanic assigned
@export var pit_crew_id: String = ""    # "" = none / "N/A" set for GK discipline

# ── Telemetry (from Cars sheet, set at car creation, read-only in-game) ───────
@export var top_speed: float = 0.0              # km/h
@export var acceleration: float = 0.0           # m/s² (initial a0)
@export var deceleration: float = 0.0           # m/s² (base d0)
@export var cornering_grip: float = 0.0         # lateral G
@export var fuel_consumption_per_km: float = 0.0 # kg/km
@export var tire_wear_rate: float = 0.0          # % per lap
@export var baseline_performance_index: int = 1  # from Cars sheet column 3

# ── Condition ─────────────────────────────────────────────────────────────────
@export var condition: float = 100.0    # Overall car health 0–100

# Per-part conditions (all start at 100.0)
# When incident system is built, these degrade individually.
# If any part hits 0 and stock = 0 → DNF.
@export var part_conditions: Dictionary = {
	"Aero": 100.0, "Engine": 100.0, "Gearbox": 100.0,
	"Suspension": 100.0, "Brakes": 100.0, "Chassis": 100.0
}

# ── Delivery state (Phase 2) ──────────────────────────────────────────────────
## A car is acquired either by BUYING a supplier car (buyable championships) or by
## BUILDING it via R&D → CNC (any championship). In both cases the car is not raceable
## the instant it is acquired: it becomes ready on its delivery_week — the week the
## lengthiest part finishes (usually the engine; see GameState.get_car_delivery_week).
##
## Defaults are deliberately legacy-safe: delivered = true so any car loaded from an
## older save, or created by the new-game / silent setup path, is treated as ready.
## Real in-season acquisitions set delivered = false and a delivery_week explicitly.
@export var delivered: bool = true          # false while in build / in transit
@export var delivery_week: int = 0          # absolute week in the season the car becomes raceable
@export var acquisition: String = "delivered" # "bought" | "built" | "delivered" (legacy/instant)

# ── Computed properties ───────────────────────────────────────────────────────

## Estimated HP for display. Formula: index * 15 + 15
## GK Championship (index 1) → 30 HP ✅   GP1 (index 70) → 1,065 HP ✅
func get_estimated_hp() -> int:
	return baseline_performance_index * 15 + 15

## Returns true if the car has a driver, mechanic assigned (and pit crew if non-GK).
## Used for pre-race readiness checks.
## Phase 2: an undelivered (in-build) car can never start — it DNS's until its
## delivery week arrives. This short-circuit makes delivery the first gate.
func is_ready_for_race(discipline: String) -> bool:
	if not delivered:
		return false
	if driver_id == "":
		return false
	if mechanic_id == "":
		return false
	if discipline != "GK" and pit_crew_id == "":
		return false
	return true

## True while the car is being built / in transit (acquired but not yet raceable).
## Convenience for UI ("In build — arrives Wk N") and delivery processing.
func is_in_build() -> bool:
	return not delivered

## Weeks remaining until delivery, given the current season week.
## Returns 0 once delivered or if the delivery week has already passed.
func weeks_until_delivery(current_week: int) -> int:
	if delivered:
		return 0
	return max(0, delivery_week - current_week)

## Returns overall condition considering worst individual part.
## A car can have 80% overall but a 10% Aero — that matters for racing.
func get_critical_part_condition() -> float:
	var worst = 100.0
	for part in part_conditions:
		if part_conditions[part] < worst:
			worst = part_conditions[part]
	return worst

## Returns the name of the part in worst condition.
func get_weakest_part() -> String:
	var worst_part = ""
	var worst_val = 100.0
	for part in part_conditions:
		if part_conditions[part] < worst_val:
			worst_val = part_conditions[part]
			worst_part = part
	return worst_part
