class_name DriverManager
## Version: S37.61 — Bug #38 CREW MODEL: starting-driver standings registration moved to the
##   caller (registers only the representative); release still frees the driver's own seat.
## Version: S37.60 — Bug #38 (multi-driver): releasing a driver frees their actual seat (remove_driver),
##   not just seat 0.
## Version: S37.49 — Phase 3 (events→notify_event): driver signing + release → "news"; rest done.
## Version: S37.37 — Notification & News Roadmap, Phase 1: blocking-error add_notification calls
##   converted to gs.show_popup() (on-the-spot AcceptDialog). Genuine events (hired / signed /
##   released) left as notifications for Phase 3.
## Version: S37.15 — #18 hidden-gems: _roll_potential() Box–Muller wide-normal distribution used for
##   ALL driver pools (most ordinary, stars rare) so the TP's eye-for-talent read is meaningful.
## Version: S37.14 — #18 GK starting-driver too strong. GK cadet age range now starts at 8 (was 13)
##   in both the FA hiring pool and the GK field regen, so a fresh cadet has age_factor 0 (no age
##   skill bonus). Added GK-tier-1-only "prodigy damping" in _create_driver_for_discipline: raw
##   skills compressed toward an entry band (~12–40), potential lifted to 60–95, experience 0 — a
##   raw karting prospect to develop, not a finished racer. Shared tier system (other disciplines /
##   AI fields) untouched. Registry GK min_age was already 8, so age-8 starters pass the filter.
## Version: S37.0 — CP4 (closes cluster A): stopped writing newly-signed drivers into the singular
##   active_championship.standings (= GK). hire_driver() no longer registers any standings entry — a
##   driver with no car belongs to no championship and is added to the CORRECT one when assigned to a
##   car (CarManager.assign_driver_to_car), per Rule #6. _find_and_sign_starting_driver() now
##   registers the starter into THEIR car's championship (player_team_cars[0].championship_id, set at
##   setup) instead of GK, so a non-GK starter (e.g. GP4) appears in the right table from race 1.
## Version: S33.1 — Added regenerate_gk_field(): tops up the contracted GK racing field with new
##   young cadets at season rollover (GK = the feeder/birthplace; other championships fill gaps
##   from the existing pool). Assigns each new cadet to a GK (C-001) AI team so populate_season
##   includes them in groups. Fixes the empty-GK-world bug.
## --- S27.0 — Extracted from GameState.gd + StaffManager.gd (P57)
##   Driver generation, hiring, releasing, contract renewal, queries.
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

## ── Wide-normal potential roll (#18 / hidden-gems) ───────────────────────────
## Most drivers are ORDINARY; genuine stars are rare. Returns a potential value drawn from
## an approximately normal distribution (Box–Muller) centered on `mean`, clamped to [lo, hi].
## Used for ALL driver pools so talent exists everywhere, not just GK. A wide spread is what
## makes the TP's "eye for talent" meaningful — without it every prospect looks the same.
func _roll_potential(mean: float = 58.0, spread: float = 16.0, lo: float = 25.0, hi: float = 98.0) -> float:
	var u1 = max(randf(), 1e-6)
	var u2 = randf()
	var z = sqrt(-2.0 * log(u1)) * cos(TAU * u2)   ## standard normal
	return clamp(mean + z * spread, lo, hi)

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
		gs.show_popup("%s is already contracted to another team." % driver.full_name(), "Cannot Sign")
		return false
	# Enforce Racing Department slot cap
	var max_d = gs.get_max_drivers()
	if gs.player_team.drivers.size() >= max_d:
		gs.show_popup(
			"Racing Department full (%d/%d slots). Upgrade it to sign more drivers." % [
			gs.player_team.drivers.size(), max_d], "Slots Full")
		return false
	driver.contract_team = gs.player_team.id
	driver.contract_seasons_remaining = 5
	gs.player_team.drivers.append(driver_id)
	## CP4 — do NOT write into active_championship.standings (= GK) here. A freshly-hired driver
	## has no car yet, so they belong to no championship. They are added to the CORRECT
	## championship's standings when assigned to a car (CarManager.assign_driver_to_car). Writing
	## GK here was the source of non-GK drivers polluting the GK table.
	gs.add_log("✅ Signed %s — contract: 5 seasons. Assign them to a car in the Drivers screen." % driver.full_name())
	gs.notify_event("signed_%s" % driver.id, "Normal", "%s signed. Build a car in the Garage, then assign them." % driver.full_name(), "garage", "news")
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
		gs.notify_event("released_%s" % driver.id, "Normal", "Released %s — CR %s release clause paid." % [driver.full_name(), gs._fmt_int(clause)], "", "news")
	driver.contract_team = ""
	driver.contract_seasons_remaining = 0
	driver.release_clause = 0
	## If departing driver was a star, apply legacy bonus to team marketability
	gs.apply_departure_legacy(driver)
	gs.player_team.drivers.erase(driver_id)
	for car in gs.player_team_cars:
		if car.has_driver(driver_id):
			car.remove_driver(driver_id)
			gs.add_log("🏎 Car %d — seat freed (%s released)." % [car.car_number, driver.full_name()])
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
	## S37.61 — standings registration is handled by the caller (_give_starting_assets section 8),
	## which registers ONLY the car representative (seat 0) under the crew model. Registering every
	## signed driver here would wrongly give each Rally/EPC co-driver a separate standings row.
	return pick

## ═══ CAR MANAGER — delegated to CarManager.gd (S27) ═══


func _generate_drivers() -> void:
	## Generates a free agent pool covering ALL championships.
	## Player starts with no driver — must hire from this pool.
	## Pool covers: GK (age 8-17), Rally/TC/OWC/SC/EPC (16-35), GP (16-35)
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
		var age = randi_range(8, 17)   ## GK cadets start at 8 — bottom of the pyramid
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
	d.potential          = _roll_potential()   ## #18 — wide-normal: ordinary common, stars rare
	d.aggression         = randf_range(20.0, 80.0)
	d.experience         = age_factor * 40.0
	d.morale             = 100.0

	## GK PRODIGY DAMPING (#18) — a brand-new GK cadet is RAW TALENT, not a finished racer.
	## Karting is the bottom of the pyramid: skills should read low (lots of room to grow) while
	## POTENTIAL is high. Applied to GK tier-1 only, so the shared tier system (other disciplines,
	## AI fields) is untouched. age 8 already zeroes age_factor; this compresses the residual rolls
	## toward an entry band (~12–40) and raises potential into the prospect range.
	if discipline == "GK" and tier == 1:
		var GK_FLOOR := 12.0   ## nobody is hopeless
		var GK_SPAN  := 0.55   ## compress the raw spread to ~55% — caps lucky highs in the ~40s
		d.pace        = clamp(GK_FLOOR + (d.pace        - GK_FLOOR) * GK_SPAN, 1.0, 100.0)
		d.car_control = clamp(GK_FLOOR + (d.car_control - GK_FLOOR) * GK_SPAN, 1.0, 100.0)
		d.focus       = clamp(GK_FLOOR + (d.focus       - GK_FLOOR) * GK_SPAN, 1.0, 100.0)
		d.race_craft  = clamp(GK_FLOOR + (d.race_craft  - GK_FLOOR) * GK_SPAN, 1.0, 100.0)
		d.consistency = clamp(GK_FLOOR + (d.consistency - GK_FLOOR) * GK_SPAN, 1.0, 100.0)
		d.feedback    = clamp(GK_FLOOR + (d.feedback    - GK_FLOOR) * GK_SPAN, 1.0, 100.0)
		## Wide-normal potential — GK is the feeder tier so center a touch higher (more upside on
		## average) but keep the spread so most cadets are ordinary and a real gem is rare (#18).
		d.potential   = _roll_potential(62.0, 17.0, 25.0, 98.0)
		d.experience  = 0.0


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


## S33.1 — GK is the feeder/birthplace of new drivers (world model). At each season rollover the
## GK racing field is topped up with NEW young contracted cadets to replace those who aged out /
## progressed / retired, so GK never empties and the promotion pyramid keeps its water supply.
## Returns the number of new cadets generated. Mirrors _create_driver_for_discipline("GK") and
## assigns each to a real GK (C-001) AI team so populate_season() includes them in race groups
## (it requires a non-empty contract_team and excludes D-GK-FA / filler ids).
func regenerate_gk_field(target_size: int = 510) -> int:
	## Collect the AI teams registered in GK (C-001), excluding the player team.
	var gk_team_ids: Array = []
	for team in gs.all_teams:
		if team == null: continue
		if team.id == gs.player_team.id: continue
		if "C-001" in team.active_championships:
			gk_team_ids.append(team.id)
	if gk_team_ids.is_empty():
		return 0   ## no GK AI teams — nothing to attach cadets to

	## Count the GK racers that already exist (contracted, non-player, non-FA, non-filler).
	var existing := 0
	for did in gs.all_drivers:
		var d = gs.all_drivers[did]
		if d.active_discipline != "GK": continue
		if did.begins_with("D-GK-FA") or did.begins_with("D-FILL"): continue
		if d.contract_team == "" or d.contract_team.begins_with("T-FILL"): continue
		if d.contract_team == gs.player_team.id: continue
		existing += 1

	var to_make: int = max(0, target_size - existing)
	if to_make == 0:
		return 0

	var nats = ["British","Italian","German","French","Spanish","Finnish","Brazilian","Japanese",
		"American","Australian","Dutch","Belgian","Mexican","Canadian","Austrian","Swedish",
		"Norwegian","Portuguese"]
	for i in range(to_make):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.3 else "Female"
		var age = randi_range(8, 17)   ## young entrants — bottom of the pyramid (GK starts at 8)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var new_id = "D-GK-GEN-S%d-%04d" % [gs.current_season, i]
		var d = _create_driver_for_discipline(new_id, name_data["first"], name_data["last"],
			nat, age, sex, "GK", 1)
		## Assign to a GK AI team so the driver is a contracted racer (populate_season eligible).
		d.contract_team = gk_team_ids[randi() % gk_team_ids.size()]
		d.contract_seasons_remaining = 3
		gs.all_drivers[d.id] = d
	return to_make

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
	d.potential          = _roll_potential(62.0, 17.0, 25.0, 98.0)   ## #18 wide-normal
	d.aggression         = randf_range(20.0, 80.0)
	d.experience         = age_factor * 30.0
	d.morale             = 100.0

	var talent_factor = d.potential / 100.0
	var starting_gk = 5.0 + (talent_factor * 10.0) + (age_factor * 5.0)
	d.discipline_adaptation["GK"] = starting_gk
	d.peak_adaptation["GK"] = starting_gk

	return d
