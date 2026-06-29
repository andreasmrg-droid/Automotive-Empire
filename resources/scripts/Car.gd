class_name Car
extends Resource
## Version: S37.60 — Bug #38: MULTI-DRIVER-PER-CAR model. A car now holds an ARRAY of drivers
##   (`driver_ids`) sized by its championship's drivers-per-car rule (GK/GP/OWC/SC = 1,
##   Rally/TC = 2, EPC = 3). Co-drivers are CO-EQUAL: each occupies a real seat, each is
##   registered into the championship standings, and each accrues fitness / stat growth
##   independently in the race sim. The legacy scalar `driver_id` is preserved as a SYNCED
##   compatibility property (driver_id == driver_ids[0], the lead seat) so the existing
##   single-driver read-sites keep working unchanged while multi-driver-aware sites read the
##   array. Save/load and the new-game / grid-fill paths migrate transparently:
##   `set_seat_count()` resizes the array, and `_migrate_legacy_driver()` upgrades old
##   single-seat saves on load.
## --- S30.0 — Phase 2 delivery state: delivered / delivery_week / acquisition.
##   Cars are now acquired in an "in-build" state and only become raceable on their
##   delivery week (max part build time, per get_car_delivery_week). is_ready_for_race
##   short-circuits to false while undelivered -> DNS-until-ready (enforced in RaceSimulator).
##   All three new fields default to a delivered/legacy-safe state so existing saves and
##   the new-game starter car load as ready (no silent DNS regressions).
## --- S29.8 — Comment: "GK Regional" -> "GK Championship" (cosmetic).

# -- Identity ------------------------------------------------------------------
@export var id: String = ""              # "CAR-P001", "CAR-P002", etc.
@export var car_type_id: String = ""     # "A_01" -- links to Cars sheet baseline data
@export var championship_id: String = "" # "C-001"
@export var car_number: int = 1          # Display number: Car 1, Car 2, etc.
@export var car_name: String = ""        # Generated name: e.g. "GKR-S1-A"

# -- Assigned personnel --------------------------------------------------------
## CANONICAL driver store (S37.60). One entry per seat the car's discipline allows.
## Empty-string entries are unfilled seats. The array length IS the seat count for this
## car (set at creation via set_seat_count from GameState.get_drivers_per_car). Co-drivers
## are co-equal -- there is no "main" vs "reserve"; seat 0 is merely the display lead.
@export var driver_ids: Array = []      # e.g. ["DRV-001"] or ["DRV-001","DRV-002","DRV-003"]
@export var mechanic_id: String = ""    # "" = no mechanic assigned
@export var pit_crew_id: String = ""    # "" = none / "N/A" set for GK discipline

## Legacy single-driver accessor (S37.60). Proxies seat 0 of driver_ids so every existing
## `car.driver_id` read/write keeps working (reads the lead seat; writing replaces seat 0).
## NOT exported -- driver_ids is the serialized field. This keeps the single-driver
## call-sites valid without edits; multi-driver-aware sites use driver_ids / seat helpers.
var driver_id: String:
	get:
		return driver_ids[0] if driver_ids.size() > 0 else ""
	set(value):
		if driver_ids.is_empty():
			driver_ids = [value]
		else:
			driver_ids[0] = value

# -- Telemetry (from Cars sheet, set at car creation, read-only in-game) -------
@export var top_speed: float = 0.0              # km/h
@export var acceleration: float = 0.0           # m/s^2 (initial a0)
@export var deceleration: float = 0.0           # m/s^2 (base d0)
@export var cornering_grip: float = 0.0         # lateral G
@export var fuel_consumption_per_km: float = 0.0 # kg/km
@export var tire_wear_rate: float = 0.0          # % per lap
@export var baseline_performance_index: int = 1  # from Cars sheet column 3

# -- Condition -----------------------------------------------------------------
@export var condition: float = 100.0    # Overall car health 0-100

# Per-part conditions (all start at 100.0)
# When incident system is built, these degrade individually.
# If any part hits 0 and stock = 0 -> DNF.
@export var part_conditions: Dictionary = {
	"Aero": 100.0, "Engine": 100.0, "Gearbox": 100.0,
	"Suspension": 100.0, "Brakes": 100.0, "Chassis": 100.0
}

# -- Delivery state (Phase 2) --------------------------------------------------
## A car is acquired either by BUYING a supplier car (buyable championships) or by
## BUILDING it via R&D -> CNC (any championship). In both cases the car is not raceable
## the instant it is acquired: it becomes ready on its delivery_week -- the week the
## lengthiest part finishes (usually the engine; see GameState.get_car_delivery_week).
##
## Defaults are deliberately legacy-safe: delivered = true so any car loaded from an
## older save, or created by the new-game / silent setup path, is treated as ready.
## Real in-season acquisitions set delivered = false and a delivery_week explicitly.
@export var delivered: bool = true          # false while in build / in transit
@export var delivery_week: int = 0          # absolute week in the season the car becomes raceable
@export var acquisition: String = "delivered" # "bought" | "built" | "delivered" (legacy/instant)

# -- Seat management (S37.60) --------------------------------------------------

## Sets how many driver seats this car has (from the discipline's drivers-per-car rule).
## Preserves any drivers already seated; pads with "" for new empty seats; trims extras
## (returning any displaced drivers' ids so the caller can release them). Always keeps at
## least one seat so the legacy driver_id accessor is safe.
func set_seat_count(n: int) -> Array:
	n = max(1, n)
	var displaced: Array = []
	if driver_ids.size() > n:
		for i in range(n, driver_ids.size()):
			if driver_ids[i] != "":
				displaced.append(driver_ids[i])
		driver_ids = driver_ids.slice(0, n)
	while driver_ids.size() < n:
		driver_ids.append("")
	return displaced

## Number of seats this car has (>=1).
func seat_count() -> int:
	return max(1, driver_ids.size())

## Returns the list of actually-assigned (non-empty) driver ids, in seat order.
func assigned_driver_ids() -> Array:
	var out: Array = []
	for d in driver_ids:
		if d != "":
			out.append(d)
	return out

## True when every seat is filled.
func all_seats_filled() -> bool:
	if driver_ids.is_empty():
		return false
	for d in driver_ids:
		if d == "":
			return false
	return true

## Index of the first empty seat, or -1 if the car is full.
func first_empty_seat() -> int:
	for i in range(driver_ids.size()):
		if driver_ids[i] == "":
			return i
	return -1

## True if the given driver occupies any seat on this car.
func has_driver(d_id: String) -> bool:
	return d_id in driver_ids

## Removes a driver from whatever seat they occupy (leaving the seat empty). Returns true
## if they were seated.
func remove_driver(d_id: String) -> bool:
	var found := false
	for i in range(driver_ids.size()):
		if driver_ids[i] == d_id:
			driver_ids[i] = ""
			found = true
	return found

## Migrates a legacy single-driver save field onto the seat array (S37.60). Called from
## _deserialize_cars for old saves that stored a scalar "driver_id" and no "driver_ids".
func _migrate_legacy_driver(legacy_id: String, seats: int) -> void:
	driver_ids = []
	set_seat_count(seats)
	if legacy_id != "":
		driver_ids[0] = legacy_id

# -- Computed properties -------------------------------------------------------

## Estimated HP for display. Formula: index * 15 + 15
## GK Championship (index 1) -> 30 HP    GP1 (index 70) -> 1,065 HP
func get_estimated_hp() -> int:
	return baseline_performance_index * 15 + 15

## Returns true if the car has ALL driver seats filled, a mechanic assigned (and pit crew
## if non-GK). Used for pre-race readiness checks.
## S37.60: a multi-driver car (Rally/TC/EPC) must have EVERY seat filled to be race-ready --
## a Rally car missing its co-driver, or an EPC car missing a third, is not ready.
## Phase 2: an undelivered (in-build) car can never start -- it DNS's until its
## delivery week arrives. This short-circuit makes delivery the first gate.
func is_ready_for_race(discipline: String) -> bool:
	if not delivered:
		return false
	if not all_seats_filled():
		return false
	if mechanic_id == "":
		return false
	if discipline != "GK" and pit_crew_id == "":
		return false
	return true

## True while the car is being built / in transit (acquired but not yet raceable).
## Convenience for UI ("In build -- arrives Wk N") and delivery processing.
func is_in_build() -> bool:
	return not delivered

## Weeks remaining until delivery, given the current season week.
## Returns 0 once delivered or if the delivery week has already passed.
func weeks_until_delivery(current_week: int) -> int:
	if delivered:
		return 0
	return max(0, delivery_week - current_week)

## Returns overall condition considering worst individual part.
## A car can have 80% overall but a 10% Aero -- that matters for racing.
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
