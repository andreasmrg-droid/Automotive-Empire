class_name Car
extends Resource

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

# ── Computed properties ───────────────────────────────────────────────────────

## Estimated HP for display. Formula: index * 15 + 15
## GK Regional (index 1) → 30 HP ✅   GP1 (index 70) → 1,065 HP ✅
func get_estimated_hp() -> int:
	return baseline_performance_index * 15 + 15

## Returns true if the car has a driver, mechanic assigned (and pit crew if non-GK).
## Used for pre-race readiness checks.
func is_ready_for_race(discipline: String) -> bool:
	if driver_id == "":
		return false
	if mechanic_id == "":
		return false
	if discipline != "GK" and pit_crew_id == "":
		return false
	return true

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
