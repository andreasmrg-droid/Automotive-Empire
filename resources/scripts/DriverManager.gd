class_name DriverManager
## Version: S27.0 — Extracted from GameState.gd + StaffManager.gd (P57)
##   Driver generation, hiring, releasing, contract renewal, queries.
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

func get_available_drivers() -> Array:
	var result = []
	for driver_id in gs.all_drivers:
		var driver = gs.all_drivers[driver_id]
		if driver.contract_team == "":
			result.append(driver)
	return result

## Returns all drivers contracted to the player team.

func get_player_drivers() -> Array:
	var result = []
	for driver_id in gs.player_team.drivers:
		if driver_id in gs.all_drivers:
			result.append(gs.all_drivers[driver_id])
	return result

## Hire a driver — adds to player roster only. Does NOT create a car.
## Cars are managed independently via add_car() in the Garage.

func hire_driver(driver_id: String) -> bool:
	if not driver_id in gs.all_drivers:
		return false
	var driver = gs.all_drivers[driver_id]
	if driver.contract_team != "":
		gs.add_notification("High", "%s is already contracted to another team." % driver.full_name())
		return false
	# Enforce Racing Department slot cap
	var max_d = gs.get_max_drivers()
	if gs.player_team.drivers.size() >= max_d:
		gs.add_notification("High",
			"Racing Department full (%d/%d slots). Upgrade it to sign more drivers." % [
			gs.player_team.drivers.size(), max_d])
		return false
	driver.contract_team = gs.player_team.id
	driver.contract_seasons_remaining = 5
	gs.player_team.drivers.append(driver_id)
	gs.active_championship.standings[driver_id] = 0
	gs.add_log("✅ Signed %s — contract: 5 seasons. Assign them to a car in the Drivers screen." % driver.full_name())
	gs.add_notification("Normal", "%s signed. Build a car in the Garage, then assign them." % driver.full_name())
	gs._fire_assignment_proposals()
	gs.emit_signal("log_updated")
	return true

## Release a driver from the player team.
## Clears their assignment from any car but does NOT delete the car.

func release_driver(driver_id: String) -> void:
	if not driver_id in gs.all_drivers:
		return
	var driver = gs.all_drivers[driver_id]
	## Deduct release clause if driver is under contract and clause > 0
	var clause = driver.release_clause if driver.release_clause > 0 else 0
	if clause > 0 and driver.contract_seasons_remaining > 0:
		gs.player_team.balance -= clause
		gs.add_log("💰 Release clause paid: CR %s for %s." % [gs._fmt_int(clause), driver.full_name()])
		gs.add_notification("High",
			"Released %s — CR %s release clause paid." % [driver.full_name(), gs._fmt_int(clause)])
	driver.contract_team = ""
	driver.contract_seasons_remaining = 0
	driver.release_clause = 0
	## If departing driver was a star, apply legacy bonus to team marketability
	gs.apply_departure_legacy(driver)
	gs.player_team.drivers.erase(driver_id)
	for car in gs.player_team_cars:
		if car.driver_id == driver_id:
			car.driver_id = ""
			gs.add_log("🏎 Car %d now has no driver." % car.car_number)
			break
	gs.add_log("👋 Released driver: %s" % driver.full_name())
	gs.emit_signal("log_updated")

## Renew a driver's contract.

func renew_driver_contract(driver_id: String, seasons: int = 5) -> void:
	if not driver_id in gs.all_drivers:
		return
	var driver = gs.all_drivers[driver_id]
	if driver.contract_team != gs.player_team.id:
		return
	driver.contract_seasons_remaining = seasons
	gs.add_log("📋 Contract renewed: %s — %d seasons" % [driver.full_name(), seasons])
	gs.emit_signal("log_updated")

## Assign a driver to a specific car by car_id.

func get_max_drivers() -> int:
	return gs.campus_buildings.get("Racing Department", {}).get("level", 1)

## Max cars the player can field — 1 per Garage level.


func _find_and_sign_starting_driver(discipline: String, champ_id: String) -> Driver:
	var reg     = gs.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var min_age = reg.get("min_age", 8)
	var max_age = reg.get("max_age", 99)
	var candidates: Array = []
	for d_id in gs.all_drivers:
		var d = gs.all_drivers[d_id]
		if d.contract_team != "": continue
		if d.age < min_age or d.age > max_age: continue
		if d.active_discipline != discipline: continue
		candidates.append(d)
	if candidates.is_empty():
		push_warning("[GameState] No starting driver for discipline %s" % discipline)
		return null
	candidates.sort_custom(func(a, b): return a.get_overall_skill() < b.get_overall_skill())
	var pick = candidates[clamp(candidates.size() / 3, 0, candidates.size() - 1)]
	pick.contract_team = gs.player_team.id
	pick.contract_seasons_remaining = 1
	var sal = gs._get_championship_driver_salary()
	pick.weekly_salary = sal * 1.2
	pick.win_bonus     = int(sal * 52 * 0.3)
	pick.podium_bonus  = int(sal * 52 * 0.1)
	pick.release_clause = int(pick.weekly_salary * 8)  ## 8 weeks salary as default clause
	gs.player_team.drivers.append(pick.id)
	if gs.active_championship != null:
		gs.active_championship.standings[pick.id] = 0
	return pick

## ═══ CAR MANAGER — delegated to CarManager.gd (S27) ═══


func _generate_drivers() -> void:
	## Generates a free agent pool covering ALL championships.
	## Player starts with no driver — must hire from this pool.
	## Pool covers: GK (age 8-16), Rally/TC/OWC/SC/EPC (16-35), GP (16-35)
	## Each discipline gets ~15 free agents at varying skill levels.
	var nats = ["British","Italian","German","French","Spanish","Finnish",
		"Brazilian","Japanese","American","Australian","Dutch","Belgian",
		"Mexican","Canadian","Austrian","Swedish","Norwegian","Portuguese"]

	var driver_idx = 0

	## GK: generate a small pool of uncontracted cadets for player to hire as starting driver
	## These are NOT added to GKDiscipline groups — they only serve as FA pool for hiring
	for i in range(8):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.3 else "Female"
		var age = randi_range(13, 17)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-GK-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "GK", 1)
		## Mark as cadet without academy so GKDiscipline excludes them from group population
		d.contract_type = "cadet"
		gs.all_drivers[d.id] = d
		driver_idx += 1

	# Rally free agents — ages 17-32, 12 drivers
	for i in range(12):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.25 else "Female"
		var age = randi_range(17, 32)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "Rally", 1)
		gs.all_drivers[d.id] = d
		driver_idx += 1

	# TC (GT) free agents — ages 18-40, 12 drivers
	for i in range(12):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.2 else "Female"
		var age = randi_range(18, 40)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "TC", 1)
		gs.all_drivers[d.id] = d
		driver_idx += 1

	# OWC (Indy/Open Wheel) free agents — ages 16-35, 12 drivers
	for i in range(12):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.25 else "Female"
		var age = randi_range(16, 35)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "OWC", 1)
		gs.all_drivers[d.id] = d
		driver_idx += 1

	# SC (NASCAR) free agents — ages 18-45, 12 drivers
	for i in range(12):
		var nat = ["American","Canadian","Mexican"][randi() % 3]
		var sex = "Male" if randf() > 0.15 else "Female"
		var age = randi_range(18, 45)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "SC", 1)
		gs.all_drivers[d.id] = d
		driver_idx += 1

	# EPC (Endurance/LMP) free agents — ages 18-45, 10 drivers
	for i in range(10):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.2 else "Female"
		var age = randi_range(18, 45)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "EPC", 1)
		gs.all_drivers[d.id] = d
		driver_idx += 1

	# GP (Formula) free agents — ages 16-35, 15 drivers
	for i in range(15):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.25 else "Female"
		var age = randi_range(16, 35)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "GP", 1)
		gs.all_drivers[d.id] = d
		driver_idx += 1

## Creates a driver suited for a specific discipline and tier.
## Tier 1 = entry level skills, Tier 4 = elite skills.


func _create_driver_for_discipline(id: String, first: String, last: String,
		nationality: String, age: int, sex: String,
		discipline: String, tier: int) -> Driver:
	var d = Driver.new()
	d.id = id
	d.first_name = first
	d.last_name = last
	d.nationality = nationality
	d.age = age
	d.sex = sex
	d.contract_team = ""  # free agent
	d.active_discipline = discipline
	d.discipline_change_season = gs.current_season

	# Skill scaling: age peak 24-32, tier boosts base skills
	var age_factor = clamp(float(age - 8) / 20.0, 0.0, 1.0)
	var peak_factor = 1.0 - abs(float(age) - 28.0) / 28.0  # peaks at 28
	peak_factor = clamp(peak_factor, 0.3, 1.0)
	var tier_bonus = (tier - 1) * 15.0  # T1=0, T2=+15, T3=+30, T4=+45

	d.pace        = clamp(randf_range(20.0, 55.0) + age_factor * 30.0 + tier_bonus + peak_factor * 10.0, 1.0, 100.0)
	d.car_control = clamp(randf_range(15.0, 45.0) + age_factor * 25.0 + tier_bonus * 0.8, 1.0, 100.0)
	d.focus       = clamp(randf_range(20.0, 50.0) + age_factor * 25.0 + tier_bonus * 0.9, 1.0, 100.0)
	d.race_craft  = clamp(randf_range(15.0, 45.0) + age_factor * 30.0 + tier_bonus, 1.0, 100.0)
	d.consistency = clamp(randf_range(15.0, 45.0) + age_factor * 25.0 + tier_bonus * 0.8, 1.0, 100.0)
	d.feedback    = clamp(randf_range(20.0, 55.0) + age_factor * 20.0 + tier_bonus * 0.7, 1.0, 100.0)
	d.marketability = clamp(randf_range(5.0, 30.0) + age_factor * 15.0 + tier_bonus * 0.5, 1.0, 99.0)
	d.fitness            = 100.0
	d.fatigue_resistance = clamp(randf_range(25.0, 65.0) + age_factor * 15.0 + float(tier) * 5.0, 1.0, 100.0)
	d.potential          = randf_range(40.0, 95.0)
	d.aggression         = randf_range(20.0, 80.0)
	d.experience         = age_factor * 40.0
	d.morale             = 100.0

	# Discipline adaptation — good in their primary discipline, low elsewhere
	for disc in d.discipline_adaptation.keys():
		if disc == discipline:
			var starting = 5.0 + age_factor * 20.0 + tier_bonus * 0.3
			d.discipline_adaptation[disc] = clamp(starting, 1.0, 60.0)
			d.peak_adaptation[disc] = d.discipline_adaptation[disc]
		else:
			d.discipline_adaptation[disc] = 1.0
			d.peak_adaptation[disc] = 1.0

	# AI drivers start with 3 season contracts; free agents have 0
	d.contract_seasons_remaining = 3 if d.contract_team != "" else 0

	return d


func _create_driver(id: String, first: String, last: String, nationality: String, age: int, sex: String, team_id: String) -> Driver:
	var d = Driver.new()
	d.id = id
	d.first_name = first
	d.last_name = last
	d.nationality = nationality
	d.age = age
	d.sex = sex
	d.contract_team = team_id
	d.active_championships = ["C-001"]
	d.active_discipline = "GK"
	d.discipline_change_season = gs.current_season

	var age_factor = float(age - 8) / 8.0
	d.pace        = randf_range(20.0, 50.0) + age_factor * 25.0
	d.car_control = randf_range(15.0, 45.0) + age_factor * 20.0
	d.focus       = randf_range(20.0, 50.0) + age_factor * 20.0
	d.race_craft  = randf_range(15.0, 45.0) + age_factor * 25.0
	d.consistency = randf_range(15.0, 45.0) + age_factor * 20.0  # NEW
	d.feedback    = randf_range(20.0, 60.0) + age_factor * 15.0  # NEW
	d.marketability = randf_range(5.0, 25.0) + age_factor * 10.0 # NEW — low at start
	d.fitness            = 100.0
	d.fatigue_resistance = clamp(randf_range(20.0, 60.0) + age_factor * 20.0, 1.0, 100.0)
	d.potential          = randf_range(50.0, 95.0)
	d.aggression         = randf_range(20.0, 80.0)
	d.experience         = age_factor * 30.0
	d.morale             = 100.0

	var talent_factor = d.potential / 100.0
	var starting_gk = 5.0 + (talent_factor * 10.0) + (age_factor * 5.0)
	d.discipline_adaptation["GK"] = starting_gk
	d.peak_adaptation["GK"] = starting_gk

	return d
