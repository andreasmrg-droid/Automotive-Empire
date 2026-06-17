class_name RaceSimulator
## Version: S27.0 — Extracted from GameState.gd (P57 Phase 3)
##   Owns race simulation, DNS checks, post-race processing,
##   driver/staff stat growth, car degradation, fitness recovery.
##   Called by GameState.advance_week() via wrapper functions.
extends RefCounted

## Reference to the main GameState node — all data lives there.
var gs  # GameState reference (untyped to avoid circular dependency)


func _init(game_state) -> void:
	gs = game_state


# ═══════════════════════════════════════════════════════════════════════════
# PRE-RACE CHECKS
# ═══════════════════════════════════════════════════════════════════════════

func check_race_requirements_for(champ: Championship) -> void:
	var tp = gs.get_team_principal()
	if tp == null:
		gs.add_notification("High",
			"⚠ No Team Principal for %s! Racing without tactical oversight." % champ.championship_name)
	var has_cfo = gs.get_cfo() != null
	if not has_cfo:
		gs.add_notification("Normal",
			"💼 No CFO on staff. Financial optimisation unavailable.")


## DNS check — returns true if the car CAN race, false if DNS.
func can_car_race(driver_id: String) -> bool:
	var car = gs.get_car_for_driver(driver_id)

	# DNS: no fuel
	var fuel_needed = gs.active_championship.fuel_per_car_per_race
	if gs.fuel_kg < fuel_needed:
		gs.add_notification("Critical",
			"DNS: Not enough fuel (%.1f kg). Need %.1f kg. Buy fuel at Logistics Center." % [
				gs.fuel_kg, fuel_needed])
		gs.add_log("🚫 DNS — Insufficient fuel for race start.")
		return false

	if car == null:
		return false

	# DNS: no race mechanic
	if car.mechanic_id == "":
		gs.add_notification("Critical",
			"DNS: %s has no Race Mechanic! Assign one in the Garage before racing." % (car.car_name if car.car_name != "" else "Car %d" % car.car_number))
		gs.add_log("🚫 DNS — No Race Mechanic on %s." % (car.car_name if car.car_name != "" else "Car %d" % car.car_number))
		return false

	# DNS: no pit crew for non-GK championships
	if gs.get_pit_crew_required(car.championship_id):
		if car.pit_crew_id == "" or car.pit_crew_id == "N/A":
			gs.add_notification("Critical",
				"DNS: %s has no Pit Crew! Assign one in the Pit Crew Arena before racing." % (car.car_name if car.car_name != "" else "Car %d" % car.car_number))
			gs.add_log("🚫 DNS — No Pit Crew on %s." % (car.car_name if car.car_name != "" else "Car %d" % car.car_number))
			return false

	return true


# ═══════════════════════════════════════════════════════════════════════════
# MAIN RACE SIMULATION
# ═══════════════════════════════════════════════════════════════════════════

func simulate_race(race_data: Dictionary, champ: Championship = null) -> void:
	# Use provided championship or fall back to active_championship (backward compat)
	var c: Championship = champ if champ != null else gs.active_championship
	gs.add_log("=== RACE %d: %s [%s] ===" % [c.current_round + 1, race_data["name"], c.championship_name])

	# ── Staff Synergy Factor ─────────────────────────────────────────────
	var tp = gs.get_team_principal()

	var mechanic: Staff   = null
	var strategist: Staff = null
	for car in gs.player_team_cars:
		if car.mechanic_id != "" and car.mechanic_id in gs.all_staff:
			mechanic = gs.all_staff[car.mechanic_id]
			break
	var strats = gs.get_player_staff_by_role("Race Strategist")
	if strats.size() > 0:
		strategist = strats[0]

	var tp_factor: float = 1.0
	if tp != null:
		tp_factor = 1.0 + tp.race_pace_reading / 200.0

	var current_track_id: String = race_data.get("track_id", "")

	var mech_setup:  float = 0.0
	var mech_track:  float = 0.0
	var strat_pace:  float = 0.0
	var strat_track: float = 0.0
	if mechanic != null:
		mech_setup = mechanic.car_setup * tp_factor
		var mech_tk = mechanic.get_track_knowledge_for(current_track_id) \
				if current_track_id != "" else mechanic.track_knowledge
		mech_track = mech_tk * tp_factor
	if strategist != null:
		strat_pace  = strategist.race_strategy * tp_factor
		var strat_tk = strategist.get_track_knowledge_for(current_track_id) \
				if current_track_id != "" else strategist.track_knowledge
		strat_track = strat_tk * tp_factor

	var staff_synergy: float = 1.0 \
		+ (mech_setup  / 100.0) * 0.08 \
		+ (strat_pace  / 100.0) * 0.06 \
		+ (mech_track  / 100.0) * 0.03 \
		+ (strat_track / 100.0) * 0.03

	if tp != null or mechanic != null or strategist != null:
		gs.add_log("👥 Staff synergy: %.3f (mech %.0f, strat %.0f, TP %s)" % [
			staff_synergy,
			mech_setup if mechanic else 0.0,
			strat_pace if strategist else 0.0,
			tp.full_name() if tp else "none"])

	# ── DNS check ────────────────────────────────────────────────────────
	var dns_driver_ids: Array = []
	var dns_car_ids: Array = []
	var cars_for_champ = gs.player_team_cars.filter(func(car): return car.championship_id == c.id)
	if cars_for_champ.is_empty():
		for d_id in gs.player_team.drivers:
			dns_driver_ids.append(d_id)
		gs.add_log("🚫 DNS [%s]: No car assigned to this championship." % c.championship_name)
	else:
		for car in cars_for_champ:
			var car_dns = false
			var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number

			if car.driver_id == "":
				gs.add_log("🚫 DNS [%s] %s — no driver assigned." % [c.championship_name, car_label])
				gs.add_notification("Critical",
					"DNS: %s has no driver for %s! Assign in Garage." % [
					car_label, c.championship_name], "garage")
				car_dns = true
			elif not can_car_race(car.driver_id):
				car_dns = true

			if car.mechanic_id == "":
				gs.add_log("🚫 DNS [%s] %s — no mechanic assigned." % [c.championship_name, car_label])
				gs.add_notification("Critical",
					"DNS: %s has no mechanic for %s! Assign in Garage." % [
					car_label, c.championship_name], "garage")
				car_dns = true

			if gs.get_pit_crew_required(c.id):
				if car.pit_crew_id == "" or car.pit_crew_id == "N/A":
					gs.add_log("🚫 DNS [%s] %s — no Pit Crew assigned." % [c.championship_name, car_label])
					gs.add_notification("Critical",
						"DNS: %s has no Pit Crew for %s! Assign one in Pit Crew Arena." % [
						car_label, c.championship_name])
					car_dns = true

			if car_dns:
				dns_car_ids.append(car.id)
				if car.driver_id != "":
					dns_driver_ids.append(car.driver_id)
				gs.add_log("🏎 Car condition unchanged (DNS)")

	# ── Collect all drivers, skipping DNS ─────────────────────────────────
	var race_drivers = []
	for driver_id in c.standings:
		if not driver_id in gs.all_drivers: continue
		if driver_id in dns_driver_ids: continue
		var is_player_driver = driver_id in gs.player_team.drivers
		if is_player_driver:
			var has_valid_car = false
			for car in cars_for_champ:
				if car.driver_id == driver_id and not car.id in dns_car_ids:
					has_valid_car = true
					break
			if not has_valid_car: continue
		race_drivers.append(gs.all_drivers[driver_id])

	# Determine weather
	var is_wet = randf() * 100.0 < race_data["rain_probability"]

	# ── Track discipline bonus ────────────────────────────────────────────
	var track_perf_bonus: float = 0.0
	const TRACK_BONUS_MAP = {
		"GK": "Karting Track", "Rally": "Gravel Track",
		"SC": "Oval Track", "OWC": "Oval Track",
		"GP": "Race Track", "EPC": "Race Track", "TC": "Race Track",
	}
	var disc = c.discipline
	if disc in TRACK_BONUS_MAP:
		var tname = TRACK_BONUS_MAP[disc]
		var tbld  = gs.campus_buildings.get(tname, {})
		if tbld.get("built", false):
			var tlevel = tbld.get("level", 1)
			var base_b = 0.03 if disc in ["GP", "EPC", "TC"] else 0.05
			track_perf_bonus = base_b + (tlevel - 1) * 0.03
			gs.add_log("🏟 %s bonus: +%.0f%% pace" % [tname, track_perf_bonus * 100.0])

	# ── Calculate lap times ──────────────────────────────────────────────
	var driver_times = []
	for driver in race_drivers:
		var base_time = 60.0
		var effective_pace  = driver.get_effective_pace()
		var effective_wet   = driver.get_effective_wet()
		var effective_focus = driver.get_effective_focus()

		var spread = 0.05 if c.id == "C-001" else 0.03
		var pace_factor = 1.0 - ((effective_pace - 60.0) / 60.0) * spread
		pace_factor = clamp(pace_factor, 1.0 - spread * 2.0, 1.0 + spread * 2.0)

		var wet_factor = 1.0
		if is_wet:
			wet_factor = 1.0 + ((100.0 - effective_wet) / 100.0) * 0.03

		var focus_factor = 1.0 - ((effective_focus - 50.0) / 50.0) * 0.005
		focus_factor = clamp(focus_factor, 0.995, 1.005)

		var fitness_factor = driver.fitness_penalty()
		var fitness_penalty = (1.0 - fitness_factor) * 0.01

		var lap_time = base_time * pace_factor * wet_factor * focus_factor * (1.0 + fitness_penalty)

		if current_track_id != "" and driver.id in gs.player_team.drivers:
			var driver_tk = driver.get_track_knowledge(current_track_id)
			var tk_bonus = (driver_tk / 100.0) * 0.01
			lap_time *= (1.0 - tk_bonus)

		if driver.id in gs.player_team.drivers:
			lap_time /= (1.0 + (staff_synergy - 1.0) * 0.5)
			var aero_bonus = gs.get_wind_tunnel_aero_bonus()
			if aero_bonus > 0.0:
				lap_time /= (1.0 + aero_bonus * 0.5)
			if track_perf_bonus > 0.0:
				lap_time /= (1.0 + track_perf_bonus * 0.5)
			var rnd_combined = (gs.get_rnd_bonus("aero_perf") + gs.get_rnd_bonus("engine_perf") + gs.get_rnd_bonus("chassis_perf")) * 0.33
			if rnd_combined > 0.0:
				lap_time /= (1.0 + rnd_combined)
			for pcar in gs.player_team_cars:
				if pcar.driver_id == driver.id:
					var cnc_bonus = gs.get_cnc_part_bonus(pcar.id)
					if cnc_bonus > 0.0:
						lap_time /= (1.0 + cnc_bonus)
					break
		else:
			lap_time *= gs.get_difficulty_mult()["ai_performance"]

		var noise_pct = 0.01 - (driver.consistency / 100.0) * 0.007
		var noise = lap_time * noise_pct
		lap_time += randf_range(-noise, noise)

		driver_times.append({
			"driver": driver,
			"lap_time": lap_time,
			"total_time": lap_time * race_data["laps"],
			"points": 0
		})

	# Snapshot pre-race driver stats for delta display
	var pre_race_stats: Dictionary = {}
	for entry in driver_times:
		var d = entry["driver"]
		pre_race_stats[d.id] = {
			"pace": d.pace, "car_control": d.car_control, "focus": d.focus,
			"experience": d.experience, "fitness": d.fitness
		}

	# Sort by total time
	driver_times.sort_custom(func(a, b): return a["total_time"] < b["total_time"])

	# ── Award points and prizes ──────────────────────────────────────────
	var points_system = c.points_system
	for i in range(driver_times.size()):
		var entry = driver_times[i]
		var driver = entry["driver"]
		var standing_position = i + 1
		var pts = 0

		if i < points_system.size():
			pts = points_system[i]
			c.add_points(driver.id, pts)
			driver_times[i]["points"] = pts

		var entry_prize = 0.0
		for team in gs.all_teams:
			if driver.id in team.drivers:
				c.add_team_points(team.id, pts)
				if standing_position == 1:
					entry_prize = c.prize_1st
				elif standing_position == 2:
					entry_prize = c.prize_2nd
				elif standing_position == 3:
					entry_prize = c.prize_3rd
				if team.id == gs.player_team.id:
					entry_prize *= gs.get_difficulty_mult()["player_economy"]
				team.balance += entry_prize
				break
		driver_times[i]["prize"] = entry_prize
		driver_times[i]["is_player"] = driver.id in gs.player_team.drivers

		_update_driver_stats_after_race(driver, standing_position, race_data["laps"], is_wet, race_drivers.size(), race_data.get("track_id", ""))

		if driver.id in pre_race_stats:
			var pre = pre_race_stats[driver.id]
			driver_times[i]["stat_deltas"] = {
				"pace": driver.pace - pre["pace"],
				"car_control": driver.car_control - pre.get("car_control", driver.car_control),
				"focus": driver.focus - pre["focus"],
				"experience": driver.experience - pre["experience"],
				"fitness": driver.fitness - pre["fitness"],
			}

	# ── Update mechanic + strategist stats ───────────────────────────────
	_update_staff_stats_after_race(race_data["laps"], race_data.get("track_id", ""))

	## Sync GK Group 0 standings
	if gs.gk_discipline != null and c.discipline == "GK":
		var cid = c.id
		if gs.shadow_standings_has_group_0(cid):
			for entry in gs.gk_discipline.get_standings(cid):
				var did = entry["driver_id"]
				if did in c.standings:
					entry["points"] = c.standings[did]
				if driver_times.size() > 0 and driver_times[0].get("driver", null) != null:
					if driver_times[0]["driver"].id == did:
						entry["wins"] = entry.get("wins", 0) + 1
				entry["races"] = entry.get("races", 0) + 1

	# ── DNS entries ──────────────────────────────────────────────────────
	for d_id in dns_driver_ids:
		var driver = gs.all_drivers.get(d_id)
		if driver:
			driver_times.append({
				"driver": driver,
				"lap_time": 0.0,
				"total_time": 0.0,
				"points": 0,
				"dns": true
			})

	# ── Store last race data ─────────────────────────────────────────────
	gs.last_race_round = c.current_round + 1
	gs.last_race_laps  = race_data["laps"]
	gs.last_race_name  = race_data["name"]
	gs.last_race_wet = is_wet
	gs.last_race_results = driver_times
	gs.last_race_championship = c.championship_name

	## Race-triggered sponsor offer
	for i in range(driver_times.size()):
		var entry2 = driver_times[i]
		if entry2.get("dns", false): continue
		if entry2["driver"].id in gs.player_team.drivers:
			gs._maybe_generate_race_sponsor_offer(i + 1)
			break
	gs.last_race_championship_id = c.id
	gs.last_race_num_races = c.num_races

	gs.last_race_standings = c.get_standings_sorted()

	# ── Hall of fame ─────────────────────────────────────────────────────
	if driver_times.size() > 0:
		var winner = null
		for entry3 in driver_times:
			if not entry3.get("dns", false):
				winner = entry3["driver"]
				break
		if winner:
			var winner_team_id = ""
			var winner_team_name = "Unknown"
			for team in gs.all_teams:
				if winner.id in team.drivers:
					winner_team_id = team.id
					winner_team_name = team.team_name
					break
			gs.hall_of_fame.append({
				"season": gs.current_season,
				"round": gs.last_race_round,
				"championship": c.championship_name,
				"track": race_data["name"],
				"winner": winner.full_name(),
				"team": winner_team_name,
				"team_id": winner_team_id
			})

	# ── Car degradation ──────────────────────────────────────────────────
	degrade_car_conditions(race_data["laps"], dns_driver_ids)

	# Consume fuel and earn RP — only for player's own championships
	## Bug 13 fix: designers were earning RP from all 24 championships
	if c.id in gs.player_registered_championships:
		consume_race_resources()
		earn_race_rp(race_data["laps"])

	# Season ends at week 52 regardless
	if gs.current_week >= gs.max_weeks:
		gs._end_season()
		return

	# Queue results for player championships
	var player_in_this_champ = false
	for pid in gs.player_team.drivers:
		if c.standings.has(pid):
			player_in_this_champ = true
			break

	if player_in_this_champ:
		gs._pending_race_results.append({
			"round":           gs.last_race_round,
			"laps":            gs.last_race_laps,
			"name":            gs.last_race_name,
			"is_wet":          gs.last_race_wet,
			"results":         gs.last_race_results.duplicate(),
			"championship":    gs.last_race_championship,
			"championship_id": gs.last_race_championship_id,
			"num_races":       gs.last_race_num_races,
			"standings":       gs.last_race_standings.duplicate(),
			"staff_deltas":    gs.last_race_staff_deltas.duplicate(),
		})


# ═══════════════════════════════════════════════════════════════════════════
# POST-RACE: DRIVER STAT GROWTH
# ═══════════════════════════════════════════════════════════════════════════

func _update_driver_stats_after_race(driver: Driver, standing_position: int, laps: int, is_wet: bool, grid_size: int, track_id: String = "") -> void:
	var fitness_drop = laps * 0.4
	driver.fitness = max(0.0, driver.fitness - fitness_drop)

	var exp_gain = randf_range(0.5, 1.5)
	driver.experience = min(100.0, driver.experience + exp_gain)

	if driver.consistency < driver.potential:
		driver.consistency = min(driver.potential, driver.consistency + exp_gain * 0.15)

	if driver.feedback < driver.potential:
		driver.feedback = min(driver.potential, driver.feedback + exp_gain * 0.08)

	if track_id != "":
		var tk_gain = 4.0 + randf_range(0.0, 4.0)
		if standing_position == 1:   tk_gain *= 1.3
		elif standing_position <= 3: tk_gain *= 1.15
		driver.update_track_knowledge(track_id, tk_gain)

	driver.update_marketability_after_race(standing_position, grid_size, false)
	var total_races = gs.active_championship.num_races
	driver.update_adaptation_after_race(gs.current_season, total_races)

	var improvement = 0.1 + randf_range(0.0, 0.2)
	if standing_position <= 3:
		improvement += 0.1

	if driver.pace < driver.potential:
		driver.pace = min(driver.potential, driver.pace + improvement * 0.5)
	if driver.focus < driver.potential:
		driver.focus = min(driver.potential, driver.focus + improvement * 0.3)
	if driver.race_craft < driver.potential:
		driver.race_craft = min(driver.potential, driver.race_craft + improvement * 0.4)
	if is_wet and driver.car_control < driver.potential:
		driver.car_control = min(driver.potential, driver.car_control + improvement * 0.6)

	if standing_position == 1:
		driver.morale = min(100.0, driver.morale + 10.0)
	elif standing_position <= 3:
		driver.morale = min(100.0, driver.morale + 5.0)
	elif standing_position >= 8:
		driver.morale = max(0.0, driver.morale - 5.0)


# ═══════════════════════════════════════════════════════════════════════════
# POST-RACE: STAFF STAT GROWTH
# ═══════════════════════════════════════════════════════════════════════════

func _update_staff_stats_after_race(_laps: int, track_id: String = "") -> void:
	gs.last_race_staff_deltas = []
	var improvement = 0.08 + randf_range(0.0, 0.12)
	for car in gs.player_team_cars:
		if car.mechanic_id != "" and car.mechanic_id in gs.all_staff:
			var mech = gs.all_staff[car.mechanic_id]
			var pre_setup = mech.car_setup
			var pre_track = mech.track_knowledge
			if mech.car_setup < 100.0:
				mech.car_setup = min(100.0, mech.car_setup + improvement * 0.6)
			if track_id != "":
				mech.update_track_knowledge(track_id, improvement * 6.0)
			elif mech.track_knowledge < 100.0:
				mech.track_knowledge = min(100.0, mech.track_knowledge + improvement * 0.4)
			var d_setup = mech.car_setup - pre_setup
			var d_track = mech.track_knowledge - pre_track
			if d_setup > 0.01 or d_track > 0.01:
				gs.last_race_staff_deltas.append({
					"name": mech.full_name(), "role": "Race Mechanic",
					"deltas": {"car_setup": d_setup, "track_knowledge": d_track, "race_strategy": 0.0}
				})
	for strat in gs.get_player_staff_by_role("Race Strategist"):
		var pre_strat = strat.race_strategy
		var pre_track = strat.track_knowledge
		if strat.race_strategy < 100.0:
			strat.race_strategy = min(100.0, strat.race_strategy + improvement * 0.5)
		if track_id != "":
			strat.update_track_knowledge(track_id, improvement * 5.0)
		elif strat.track_knowledge < 100.0:
			strat.track_knowledge = min(100.0, strat.track_knowledge + improvement * 0.3)
		var d_strat = strat.race_strategy - pre_strat
		var d_track = strat.track_knowledge - pre_track
		if d_strat > 0.01 or d_track > 0.01:
			gs.last_race_staff_deltas.append({
				"name": strat.full_name(), "role": "Race Strategist",
				"deltas": {"car_setup": 0.0, "track_knowledge": d_track, "race_strategy": d_strat}
			})


# ═══════════════════════════════════════════════════════════════════════════
# POST-RACE: RESOURCES & CAR CONDITION
# ═══════════════════════════════════════════════════════════════════════════

func consume_race_resources() -> void:
	if gs.active_championship == null:
		return
	var cars_raced = 0
	for car in gs.player_team_cars:
		if car.championship_id != gs.active_championship.id:
			continue
		if car.driver_id == "":
			continue
		var was_dns = false
		for entry in gs.last_race_results:
			if entry["driver"].id == car.driver_id and entry.get("dns", false):
				was_dns = true
				break
		if not was_dns:
			cars_raced += 1
	var fuel_used = gs.active_championship.fuel_per_car_per_race * cars_raced
	if fuel_used > 0.0:
		gs.fuel_kg -= fuel_used
		gs.fuel_kg = max(gs.fuel_kg, 0.0)
		gs.add_log("⛽ Fuel used: %.1f kg × %d car%s (stock: %.1f kg)" % [
			gs.active_championship.fuel_per_car_per_race, cars_raced,
			"s" if cars_raced != 1 else "", gs.fuel_kg])
	else:
		gs.add_log("⛽ Fuel used: 0.0 kg (no cars started)")


func earn_race_rp(laps: int) -> void:
	var rnd_studio = gs.campus_buildings.get("R&D Design Studio", {})
	if not rnd_studio.get("built", false):
		return
	var designers = gs.get_player_staff_by_role("Designer")
	if designers.is_empty():
		return
	var design_power = 0.0
	for d in designers:
		var avg = (d.engine + d.aero + d.chassis + d.gearbox + d.brakes + d.suspension) / 6.0
		design_power += avg / 100.0
	var rp_gained = laps * 1 * design_power
	rp_gained *= gs.get_difficulty_mult()["player_rnd"]
	var rp_cap = gs.get_rnd_rp_storage_cap()
	gs.research_points = min(gs.research_points + rp_gained, float(rp_cap))
	gs.add_log("🔬 RP gained: %.0f (total: %.0f / %d)" % [rp_gained, gs.research_points, rp_cap])


func degrade_car_conditions(laps: int, dns_driver_ids: Array = []) -> void:
	var loss = gs.active_championship.condition_loss_per_lap * float(laps)
	for car in gs.player_team_cars:
		if car.driver_id == "" or car.driver_id in dns_driver_ids:
			gs.add_log("🔩 Car %d condition unchanged (DNS)" % car.car_number)
			continue
		car.condition = max(0.0, car.condition - loss)
		## Degrade per-part condition for CNC installed parts
		if car.id in gs.car_installed_parts:
			for pcode in gs.car_installed_parts[car.id]:
				var pd = gs.car_installed_parts[car.id][pcode]
				pd["condition"] = max(0.0, pd.get("condition", 100.0) - loss)
				if pd["condition"] <= 0.0:
					gs.add_notification("Critical",
						"🔩 %s TERMINAL DAMAGE on %s! Slot empty — car cannot race." % [
						pcode, car.car_name if car.car_name != "" else "Car %d" % car.car_number])
					gs.car_installed_parts[car.id].erase(pcode)
		## Degrade per-part condition for provider parts
		if car.id in gs.car_provider_parts:
			for pcode in gs.car_provider_parts[car.id].keys():
				var pd = gs.car_provider_parts[car.id][pcode]
				pd["condition"] = max(0.0, pd.get("condition", 100.0) - loss)
				if pd["condition"] <= 0.0:
					gs.add_notification("Critical",
						"🔩 %s TERMINAL DAMAGE on %s! Slot empty — buy provider parts at Logistics." % [
						pcode, car.car_name if car.car_name != "" else "Car %d" % car.car_number])
					gs.car_provider_parts[car.id].erase(pcode)
		gs.add_log("🔩 Car %d condition after race: %.0f%% (−%.1f%% over %d laps)" % [
			car.car_number, car.condition, loss, laps])


func auto_repair_cars_post_race() -> void:
	if gs.player_team_cars.is_empty():
		return

	if not has_remaining_races_this_season():
		gs.add_log("🔧 Season's last race — no auto-repair. Cars will be serviced in the off-season.")
		return

	var sp_rate = gs.active_championship.sp_per_10_pct_damage
	var any_failed = false
	var failed_car_names: Array = []

	for car in gs.player_team_cars:
		var damage = 100.0 - car.condition
		if damage <= 0.0:
			continue

		if car.mechanic_id == "":
			gs.add_notification("High",
				"Car %d cannot be repaired — no Race Mechanic assigned!" % car.car_number)
			any_failed = true
			failed_car_names.append("Car %d (no mechanic)" % car.car_number)
			continue

		var sp_needed = int(ceil(damage / 10.0) * sp_rate)

		if gs.spare_parts >= sp_needed:
			gs.spare_parts -= sp_needed
			car.condition = 100.0
			gs.add_log("🔧 Car %d auto-repaired to 100%% (-%d SP, %d remaining)" % [
				car.car_number, sp_needed, gs.spare_parts])
		elif gs.spare_parts > 0:
			var repair_pct = float(gs.spare_parts) / float(sp_rate) * 10.0
			car.condition = min(100.0, car.condition + repair_pct)
			gs.add_log("🔧 Car %d partial repair: %.0f%% condition (SP exhausted)" % [
				car.car_number, car.condition])
			gs.spare_parts = 0
			any_failed = true
			failed_car_names.append("Car %d" % car.car_number)
		else:
			any_failed = true
			failed_car_names.append("Car %d" % car.car_number)

	if any_failed:
		var names = ", ".join(failed_car_names)
		gs.add_notification("Critical" if gs.spare_parts == 0 else "High",
			"SP insufficient to fully repair %s. Buy more SP at Logistics Center." % names)


# ═══════════════════════════════════════════════════════════════════════════
# WEEKLY FITNESS RECOVERY
# ═══════════════════════════════════════════════════════════════════════════

func apply_weekly_fitness_recovery() -> void:
	var fatigue_reduction = gs.get_fitness_fatigue_reduction()
	var base_recovery = 8.0
	var actual_recovery = base_recovery * (1.0 + fatigue_reduction)
	for driver_id in gs.all_drivers:
		var driver = gs.all_drivers[driver_id]
		driver.fitness = min(100.0, driver.fitness + actual_recovery)


func recover_pit_crew_fitness() -> void:
	for staff_id in gs.all_staff:
		var staff = gs.all_staff[staff_id]
		if staff.role == "Pit Crew" and staff.contract_team == gs.player_team.id:
			staff.fitness = min(100.0, staff.fitness + 8.0)


# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func has_remaining_races_this_season() -> bool:
	for champ in gs.active_championships:
		var next_race = champ.get_next_race()
		if not next_race.is_empty():
			return true
	return false


func pay_driver_race_bonuses(race_results: Array) -> void:
	for entry in race_results:
		var driver = entry.get("driver")
		if driver == null: continue
		if driver.contract_team != gs.player_team.id: continue
		var pos = entry.get("position", 99)
		var bonus = 0
		if pos == 1:   bonus = driver.win_bonus
		elif pos <= 3: bonus = driver.podium_bonus
		if bonus > 0:
			gs.player_team.balance -= bonus
			gs.add_log("🏆 Race bonus paid: %s — CR %s (P%d)" % [
				driver.full_name(), gs._fmt_int(bonus), pos])
