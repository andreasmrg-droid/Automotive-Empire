class_name CarManager
## Version: S37.0 — CP4 (closes cluster A): manual repair_car() reads the SP-per-10%-damage rate from
##   THIS car's championship (get_championship_by_id(car.championship_id)) instead of the singular
##   gs.active_championship (= GK). Cars span multiple championships, so a single global rate was
##   wrong for every non-GK car. assign_driver_to_car() was already correct (it registers the driver
##   into the car's championship standings) — that is now the SINGLE registration point cluster-A
##   relies on, after DriverManager/ContractEngine stopped writing GK at sign time.
## Version: S35.11 — Installed CNC parts now store `level` + R&D `value` (via _installed_part_*
##   helpers) so get_cnc_part_bonus can scale the on-track bonus by what the part actually is.
## Version: S30.3 — Phase 2: add_car sets delivery state. A real in-season purchase
##   (silent=false) creates the car in-build (delivered=false) with delivery_week =
##   get_car_delivery_week(champ_id) and acquisition="bought" → DNS-until-ready. The
##   new-game/setup path (silent=true) keeps cars instantly delivered so the starter
##   car races from Race 1 as before. (Restored S30.5 — file was missing from f5b8a48.)
## --- S28.4 — assign_pit_crew_to_car / unassign_pit_crew_from_car added (Bug 6).
## --- S28.3 — add_car(silent) suppresses premature "assign driver/mechanic" notifications
##   during new-game setup (issue 1); install_part_on_car robust to non-canonical inventory keys (CNC install fix).
## --- S27.0 — Extracted from GameState.gd (P57)
##   Car lifecycle: add/remove/rename, driver/staff assignment, repairs, parts.
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

func generate_car_name(for_champ_id: String = "") -> String:
	# Use provided champ_id, or fall back
	var champ_id = for_champ_id
	if champ_id == "":
		champ_id = gs.active_championship.id
	if champ_id == "" and not gs.player_registered_championships.is_empty():
		champ_id = gs.player_registered_championships[0]

	const CHAMP_CODES = {
		"C-001": "GK",
		"C-005": "RL4", "C-006": "RL3", "C-007": "RL2", "C-008": "RLP",
		"C-009": "TCS", "C-010": "TCE",
		"C-011": "OWN", "C-012": "OWD", "C-013": "OWP",
		"C-014": "SCD", "C-015": "SCT", "C-016": "SCC", "C-017": "SCU",
		"C-018": "EPS", "C-019": "EPL", "C-020": "EPH",
		"C-021": "GP4", "C-022": "GP3", "C-023": "GP2", "C-024": "GP1",
	}
	var code = CHAMP_CODES.get(champ_id, "CAR")
	var season = "S%d" % gs.current_season
	# Letter counts cars assigned to THIS championship only (A = first, B = second...)
	var same_champ_count = 0
	for car in gs.player_team_cars:
		if car.championship_id == champ_id:
			same_champ_count += 1
	var letter = char(65 + same_champ_count)
	return "%s-%s-%s" % [code, season, letter]


func add_car(for_champ_id: String = "", silent: bool = false) -> bool:
	var max_c = gs.get_max_cars()
	if gs.player_team_cars.size() >= max_c:
		gs.add_notification("High",
			"Garage full (%d/%d slots). Upgrade the Garage to field more cars." % [
			gs.player_team_cars.size(), max_c])
		return false

	# Determine which championship this car is for
	var champ_id = for_champ_id
	if champ_id == "":
		champ_id = gs.active_championship.id
		if champ_id == "" and not gs.player_registered_championships.is_empty():
			champ_id = gs.player_registered_championships[0]

	var car_number = gs.player_team_cars.size() + 1
	var car        = Car.new()
	car.id         = "CAR-P%03d" % car_number
	car.car_type_id    = "A_01"
	car.championship_id = champ_id
	car.car_number = car_number
	car.car_name   = generate_car_name(champ_id)
	car.driver_id  = ""
	car.mechanic_id = ""
	# Pit crew: not required for GK, required for all others
	var reg = gs.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var discipline = reg.get("discipline", "GK")
	car.pit_crew_id = "N/A" if not gs.PIT_CREW_REQUIRED.get(discipline, true) else ""
	car.condition   = 100.0
	car.part_conditions = {"Aero": 100.0, "Engine": 100.0, "Gearbox": 100.0,
		"Suspension": 100.0, "Brakes": 100.0, "Chassis": 100.0}
	## Phase 2 delivery state. A real in-season acquisition (silent=false) is in-build:
	## it becomes raceable on its delivery week (max part build time). The new-game/setup
	## path (silent=true) keeps the car instantly delivered so the starter car races at once.
	if silent:
		car.delivered     = true
		car.delivery_week = 0
		car.acquisition   = "delivered"
	else:
		car.delivered     = false
		car.delivery_week = gs.get_car_delivery_week(champ_id)
		car.acquisition   = "bought"
	# Use championship-appropriate telemetry
	const CHAMP_CAR_TYPE = {
		"C-001": "A_01",
		"C-005": "A_05", "C-006": "A_05", "C-007": "A_05", "C-008": "A_05",
		"C-009": "A_09", "C-010": "A_09",
		"C-011": "A_11", "C-012": "A_11", "C-013": "A_11",
		"C-014": "A_14", "C-015": "A_14", "C-016": "A_14", "C-017": "A_14",
		"C-018": "A_18", "C-019": "A_18", "C-020": "A_18",
		"C-021": "A_21", "C-022": "A_21", "C-023": "A_21", "C-024": "A_21",
	}
	var car_type = CHAMP_CAR_TYPE.get(champ_id, "A_01")
	car.car_type_id = car_type
	var telemetry = gs.CAR_TELEMETRY.get(car_type, gs.CAR_TELEMETRY.get("A_01", {}))
	if not telemetry.is_empty():
		car.top_speed = telemetry["top_speed"]
		car.acceleration = telemetry["acceleration"]
		car.deceleration = telemetry["deceleration"]
		car.cornering_grip = telemetry["cornering_grip"]
		car.fuel_consumption_per_km = telemetry["fuel_per_km"]
		car.tire_wear_rate = telemetry["tire_wear"]
		car.baseline_performance_index = telemetry["perf_index"]
	gs.player_team_cars.append(car)
	if car.delivered:
		gs.add_log("🏎 %s added to garage for %s — assign a driver and mechanic before racing." % [
			car.car_name, reg.get("name", champ_id)])
	else:
		gs.add_log("🏎 %s ordered for %s — in build, arrives Week %d. Pre-assign crew now." % [
			car.car_name, reg.get("name", champ_id), car.delivery_week])
	## S28.3 (issue 1): during initial new-game setup, the driver/mechanic/pit crew are
	## assigned immediately AFTER this call, so firing "assign a driver" notifications and
	## TP proposals here produces stale warnings. `silent` suppresses them in that case.
	if not silent:
		if gs.get_pit_crew_required(champ_id):
			gs.add_notification("High",
				"🔧 %s needs a Pit Crew assigned before Race 1 or it will DNS. Hire at Pit Crew Arena." % car.car_name)
		if car.delivered:
			gs.add_notification("Normal", "%s ready. Assign a driver via the Garage." % car.car_name)
		else:
			gs.add_notification("Normal",
				"🏎 %s in build — arrives Week %d. Pre-assign a driver via the Garage so it's race-ready on delivery." % [
				car.car_name, car.delivery_week], "garage")
		gs._fire_assignment_proposals()
	gs.emit_signal("log_updated")
	return true

## Removes a car by car_id. Clears any driver/mechanic assignments first.
## Does NOT release the driver — they remain on the roster.


func remove_car(car_id: String) -> bool:
	for i in range(gs.player_team_cars.size()):
		var car = gs.player_team_cars[i]
		if car.id == car_id:
			if car.driver_id != "":
				gs.add_log("🏎 Car %d removed — %s is now without a car." % [
					car.car_number, gs.all_drivers[car.driver_id].full_name() if car.driver_id in gs.all_drivers else car.driver_id])
			# Clear mechanic assignment
			if car.mechanic_id != "" and car.mechanic_id in gs.all_staff:
				gs.all_staff[car.mechanic_id].assigned_car_id = ""
			gs.player_team_cars.remove_at(i)
			# Re-number remaining cars
			for j in range(gs.player_team_cars.size()):
				gs.player_team_cars[j].car_number = j + 1
			gs.add_log("🗑 Car removed. %d car(s) remaining." % gs.player_team_cars.size())
			gs.emit_signal("log_updated")
			return true
	return false

## Renames a car. Validates the name is non-empty and max 12 chars.
## Returns true on success, false if validation fails.


func rename_car(car_id: String, new_name: String) -> bool:
	var name = new_name.strip_edges()
	if name == "":
		gs.add_notification("Normal", "Car name cannot be empty.")
		return false
	if name.length() > 12:
		gs.add_notification("Normal", "Car name must be 12 characters or fewer.")
		return false
	var car = get_car_by_id(car_id)
	if not car:
		return false
	var old_name = car.car_name
	car.car_name = name
	gs.add_log("✏ Car renamed: %s → %s" % [old_name, name])
	gs.emit_signal("log_updated")
	return true


func assign_driver_to_car(driver_id: String, car_id: String) -> void:
	var car = get_car_by_id(car_id)
	if not car:
		return
	# Age eligibility check for this championship
	var driver = gs.all_drivers.get(driver_id)
	if driver:
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
		var min_age = reg.get("min_age", 0)
		var max_age = reg.get("max_age", 99)
		if driver.age < min_age or driver.age > max_age:
			gs.add_notification("High",
				"⚠ Cannot assign %s (age %d) to %s — age limit is %d–%s." % [
				driver.full_name(), driver.age, reg.get("name", car.championship_id),
				min_age, str(max_age) if max_age < 99 else "+"])
			gs.emit_signal("log_updated")
			return
	# Unassign from any current car first
	for c in gs.player_team_cars:
		if c.driver_id == driver_id:
			c.driver_id = ""
	if car:
		# Unassign whoever was in this car
		if car.driver_id != "" and car.driver_id != driver_id:
			var old_driver = gs.all_drivers.get(car.driver_id)
			if old_driver:
				gs.add_log("↩ %s unassigned from Car %d" % [old_driver.full_name(), car.car_number])
		car.driver_id = driver_id
		var assigned_driver = gs.all_drivers.get(driver_id)
		gs.add_log("🏎 %s assigned to %s" % [assigned_driver.full_name() if assigned_driver else driver_id, car.car_name if car.car_name != "" else "Car %d" % car.car_number])
		# Add driver to this championship's standings if not already there
		for champ in gs.active_championships:
			if champ.id == car.championship_id and not driver_id in champ.standings:
				champ.standings[driver_id] = 0
			if champ.id == car.championship_id and not gs.player_team.id in champ.team_standings:
				champ.team_standings[gs.player_team.id] = 0
		# Record which championship this driver is running — shown next season
		gs.previous_season_championship[driver_id] = car.championship_id
		gs.emit_signal("log_updated")

## Creates a new empty car slot. Capped by Garage level.
## Called from the Garage scene — independent of driver hire.
## Generates a car display name: e.g. GKR-S1-A, GKN-S3-B
## Must be called BEFORE appending the new car to player_team_cars.


func unassign_driver_from_car(car_id: String) -> void:
	var car = get_car_by_id(car_id)
	if not car: return
	if car.driver_id == "": return
	var drv = gs.all_drivers.get(car.driver_id)
	gs.add_log("↩ %s unassigned from %s" % [
		drv.full_name() if drv else car.driver_id,
		car.car_name if car.car_name != "" else "Car %d" % car.car_number])
	car.driver_id = ""
	gs.emit_signal("log_updated")


func assign_staff_to_car(staff_id: String, car_id: String) -> void:
	if not staff_id in gs.all_staff:
		return
	var staff = gs.all_staff[staff_id]
	var car = get_car_by_id(car_id)
	staff.assigned_car_id = car_id
	staff.assigned_championship = car.championship_id if car else gs.active_championship.id
	# Record which championship this staff member is running
	if car:
		gs.previous_season_championship[staff_id] = car.championship_id
	# Wire mechanic/pit crew to car
	if car:
		if staff.role == "Race Mechanic":
			car.mechanic_id = staff_id
		elif staff.role == "Pit Crew":
			car.pit_crew_id = staff_id
	gs.add_log("🔧 %s assigned to Car %s" % [staff.full_name(), car_id])


func unassign_mechanic_from_car(car_id: String) -> void:
	var car = get_car_by_id(car_id)
	if not car: return
	if car.mechanic_id == "": return
	var mech = gs.all_staff.get(car.mechanic_id)
	if mech:
		mech.assigned_car_id = ""
		gs.add_log("↩ %s unassigned from %s" % [
			mech.full_name(),
			car.car_name if car.car_name != "" else "Car %d" % car.car_number])
	car.mechanic_id = ""
	gs.emit_signal("log_updated")


## S28.3 (Bug 6) — Pit Crew assignment, mirrors the mechanic functions.
func assign_pit_crew_to_car(staff_id: String, car_id: String) -> void:
	if not staff_id in gs.all_staff:
		return
	var staff = gs.all_staff[staff_id]
	if staff.role != "Pit Crew":
		return
	var car = get_car_by_id(car_id)
	if not car: return
	staff.assigned_car_id = car_id
	staff.assigned_championship = car.championship_id
	gs.previous_season_championship[staff_id] = car.championship_id
	car.pit_crew_id = staff_id
	gs.add_log("⏱ %s (Pit Crew) assigned to %s" % [
		staff.full_name(), car.car_name if car.car_name != "" else "Car %d" % car.car_number])
	gs.emit_signal("log_updated")


func unassign_pit_crew_from_car(car_id: String) -> void:
	var car = get_car_by_id(car_id)
	if not car: return
	if car.pit_crew_id in ["", "N/A"]: return
	var crew = gs.all_staff.get(car.pit_crew_id)
	if crew:
		crew.assigned_car_id = ""
		gs.add_log("↩ %s (Pit Crew) unassigned from %s" % [
			crew.full_name(),
			car.car_name if car.car_name != "" else "Car %d" % car.car_number])
	car.pit_crew_id = ""
	gs.emit_signal("log_updated")


func get_car_for_driver(driver_id: String) -> Car:
	for car in gs.player_team_cars:
		if car.driver_id == driver_id:
			return car
	return null


func get_car_by_id(car_id: String) -> Car:
	for car in gs.player_team_cars:
		if car.id == car_id:
			return car
	return null


func get_car_condition(driver_id: String) -> float:
	var car = get_car_for_driver(driver_id)
	return car.condition if car else 100.0

## ═══════════════════════════════════════════════════════════════════════════
## PART INVENTORY SYSTEM
## ═══════════════════════════════════════════════════════════════════════════


func repair_car(driver_id: String, repair_pct: float) -> bool:
	var car = get_car_for_driver(driver_id)
	if not car:
		return false
	var current = car.condition
	var actual_repair = min(repair_pct, 100.0 - current)
	if actual_repair <= 0.0:
		gs.add_notification("Normal", "Car is already at full condition.")
		return false
	## CP4 — SP cost read from THIS car's championship, not the singular active_championship (= GK).
	var car_champ: Championship = gs.get_championship_by_id(car.championship_id)
	var sp_rate = car_champ.sp_per_10_pct_damage if car_champ != null else gs.active_championship.sp_per_10_pct_damage
	var sp_cost = int(ceil(actual_repair / 10.0) * sp_rate)
	if gs.spare_parts < sp_cost:
		gs.add_notification("High",
			"Not enough SP to repair car. Need %d SP, have %d." % [sp_cost, gs.spare_parts])
		return false
	gs.spare_parts -= sp_cost
	car.condition = min(100.0, current + actual_repair)
	gs.add_log("🔧 Manual repair +%.0f%% → %.0f%% condition (-%d SP, %d remaining)" % [
		actual_repair, car.condition, sp_cost, gs.spare_parts])
	gs.emit_signal("log_updated")
	return true


func repair_car_full(driver_id: String) -> bool:
	var car = get_car_for_driver(driver_id)
	if not car:
		return false
	var damage = 100.0 - car.condition
	if damage <= 0.0:
		gs.add_notification("Normal", "Car is already at full condition.")
		return false
	return repair_car(driver_id, damage)


func install_part_on_car(car_id: String, champ_id: String, pcode: String) -> bool:
	## S28.3 (CNC install fix): find the inventory entry the SAME way the Garage popup does
	## (get_cnc_stock_for_slot) rather than assuming the canonical "CHAMP|PCODE" key. Older
	## jobs stored parts under a bare part-name key, so rebuilding the key missed them and the
	## install silently returned false ("clicked, nothing happened").
	var inv_key = gs._cnc_inv_key(champ_id, pcode)
	if not inv_key in gs.cnc_parts_inventory:
		## Fall back to the matching-scan used for display.
		var matches = gs.get_cnc_stock_for_slot(champ_id, pcode)
		if matches.is_empty():
			gs.add_notification("High", "No %s in CNC inventory." % pcode)
			return false
		inv_key = matches[0]
	var item = gs.cnc_parts_inventory[inv_key]
	if not item is Dictionary or item.get("quantity", 0) <= 0:
		gs.add_notification("High", "No %s in CNC inventory." % pcode)
		return false
	var car = null
	for c in gs.player_team_cars:
		if c.id == car_id: car = c; break
	if car == null: return false
	item["quantity"] -= 1
	if item["quantity"] <= 0:
		gs.cnc_parts_inventory.erase(inv_key)
	if not car_id in gs.car_installed_parts:
		gs.car_installed_parts[car_id] = {}
	gs.car_installed_parts[car_id][pcode] = {
		"reliability":  item.get("reliability", 60.0),
		"quality":      item.get("quality", 1.0),
		"blueprint_id": item.get("blueprint_id", ""),
		"part":         item.get("part", ""),
		## S35.11 — store level + R&D performance value so get_cnc_part_bonus can scale the
		## on-track lap bonus by what the part actually is (value already bakes in level via
		## the P2 carry-over chain + designer lift). Pulled from the source blueprint.
		"level":        _installed_part_level(item.get("blueprint_id", "")),
		"value":        _installed_part_value(item.get("blueprint_id", "")),
	}
	var cname = car.car_name if car.car_name != "" else "Car %d" % car.car_number
	gs.add_log("🔩 %s CNC part installed on %s. Rel:%.0f%% Qual:%.2f×" % [
		pcode, cname, item.get("reliability", 60.0), item.get("quality", 1.0)])
	gs.add_notification("Normal", "%s installed on %s." % [pcode, cname])
	gs.emit_signal("log_updated")
	return true

## S35.11 — Read a blueprint's level (for the installed-part record). Defaults to 0 if the
## blueprint is unknown (e.g. a provider/legacy part with no blueprint_id).
func _installed_part_level(blueprint_id: String) -> int:
	if blueprint_id == "" or not blueprint_id in gs.known_blueprints:
		return 0
	return int(gs.known_blueprints[blueprint_id].get("level", 0))

## S35.11 — Read a blueprint's R&D performance value (for the installed-part record). This
## already bakes in level (via the P2 carry-over chain) and the designer lift. Defaults to 0.
func _installed_part_value(blueprint_id: String) -> float:
	if blueprint_id == "" or not blueprint_id in gs.known_blueprints:
		return 0.0
	return float(gs.known_blueprints[blueprint_id].get("value", 0.0))

## Remove a CNC part from a car and return it to inventory.


func remove_part_from_car(car_id: String, pcode: String) -> bool:
	if not car_id in gs.car_installed_parts: return false
	var installed = gs.car_installed_parts[car_id]
	if not pcode in installed: return false
	var part_data = installed[pcode]
	installed.erase(pcode)
	var car = null
	for c in gs.player_team_cars:
		if c.id == car_id: car = c; break
	## Return to inventory
	var champ_id = car.championship_id if car else part_data.get("championship_id", "")
	var inv_key = gs._cnc_inv_key(champ_id, pcode) if champ_id != "" else pcode
	if inv_key in gs.cnc_parts_inventory:
		gs.cnc_parts_inventory[inv_key]["quantity"] += 1
	else:
		gs.cnc_parts_inventory[inv_key] = {
			"quantity":       1,
			"reliability": part_data.get("reliability", 60.0),
			"quality":     part_data.get("quality", 1.0),
			"blueprint_id": part_data.get("blueprint_id", ""),
			"part":         part_data.get("part", ""),
			"part_code":   pcode,
			"championship_id": champ_id,
		}
	var cname = car.car_name if car and car.car_name != "" else "Car"
	gs.add_log("🔩 %s CNC part removed from %s → back in warehouse." % [pcode, cname])
	gs.emit_signal("log_updated")
	return true

## Install a provider (L0) part from part_inventory into a car slot.


func install_provider_part(car_id: String, champ_id: String, pcode: String) -> bool:
	const PCODE_TO_NAME = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	var part_name = PCODE_TO_NAME.get(pcode, pcode)
	if gs.get_part_stock(part_name, champ_id) <= 0:
		gs.add_notification("High", "No %s provider parts in stock." % part_name)
		return false
	var car = null
	for c in gs.player_team_cars:
		if c.id == car_id: car = c; break
	if car == null: return false
	## If a CNC part is already in this slot, remove it first (back to warehouse)
	if car_id in gs.car_installed_parts and pcode in gs.car_installed_parts[car_id]:
		remove_part_from_car(car_id, pcode)
	## If a provider part is already in slot, return it to stock
	if car_id in gs.car_provider_parts and pcode in gs.car_provider_parts[car_id]:
		gs.part_inventory[champ_id][part_name] = gs.part_inventory.get(champ_id, {}).get(part_name, 0) + 1
	## Deduct from stock and slot it
	gs.part_inventory[champ_id][part_name] -= 1
	if not car_id in gs.car_provider_parts:
		gs.car_provider_parts[car_id] = {}
	## Provider part starts at condition based on current WRA cycle baseline
	var base_rel = gs._get_provider_part_base_rel(champ_id)
	gs.car_provider_parts[car_id][pcode] = {
		"condition": 100.0,
		"reliability": base_rel,
		"quality": gs._get_provider_part_base_qual(champ_id),
		"part": part_name,
		"part_code": pcode,
	}
	var cname = car.car_name if car.car_name != "" else "Car %d" % car.car_number
	gs.add_log("🔩 L0 %s provider part installed on %s." % [part_name, cname])
	gs.emit_signal("log_updated")
	return true

## Remove a provider part from a car slot and return to stock.


func remove_provider_part(car_id: String, pcode: String) -> bool:
	if not car_id in gs.car_provider_parts: return false
	if not pcode in gs.car_provider_parts[car_id]: return false
	const PCODE_TO_NAME = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	var part_name = PCODE_TO_NAME.get(pcode, pcode)
	var car = null
	for c in gs.player_team_cars:
		if c.id == car_id: car = c; break
	var champ_id = car.championship_id if car else ""
	gs.car_provider_parts[car_id].erase(pcode)
	if champ_id != "":
		if not champ_id in gs.part_inventory: gs.part_inventory[champ_id] = {}
		gs.part_inventory[champ_id][part_name] = gs.part_inventory[champ_id].get(part_name, 0) + 1
	var cname = car.car_name if car and car.car_name != "" else "Car"
	gs.add_log("🔩 L0 %s removed from %s → back in stock." % [part_name, cname])
	gs.emit_signal("log_updated")
	return true

## Swap a CNC part onto a car — removes whatever is in the slot first (back to stock/inventory).


func get_all_parts_for_car(car_id: String) -> Dictionary:
	var result: Dictionary = {}
	var cnc = gs.car_installed_parts.get(car_id, {})
	var prov = gs.car_provider_parts.get(car_id, {})
	const PCODE_TO_NAME = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	for pcode in ["AER","ENG","GRB","SUS","BRK","CHS"]:
		if pcode in cnc:
			var d = cnc[pcode]
			var lvl = 0
			var bp_id = d.get("blueprint_id", "")
			if bp_id != "":
				lvl = gs.known_blueprints.get(bp_id, {}).get("level", 1)
			result[pcode] = {
				"type": "cnc",
				"part_name": PCODE_TO_NAME.get(pcode, pcode),
				"level": lvl,
				"reliability": d.get("reliability", 60.0),
				"quality": d.get("quality", 1.0),
				"condition": d.get("condition", 100.0),
				"blueprint_id": bp_id,
			}
		elif pcode in prov:
			var d = prov[pcode]
			result[pcode] = {
				"type": "provider",
				"part_name": PCODE_TO_NAME.get(pcode, pcode),
				"level": 0,
				"reliability": d.get("reliability", 60.0),
				"quality": d.get("quality", 1.0),
				"condition": d.get("condition", 100.0),
				"blueprint_id": "",
			}
	return result

## Returns the provider part base reliability for a championship this season.
## Season 1 of cycle = 60, +5 per season, capped at 90.
