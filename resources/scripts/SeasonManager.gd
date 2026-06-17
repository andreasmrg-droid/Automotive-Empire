class_name SeasonManager
## Version: S27.0 — Extracted from GameState.gd (P57 Phase 1)
##   Owns the full season lifecycle: end_season(), start_new_season(), _process_off_season().
##   Called by GameState._end_season() and GameState.start_new_season().
##   Follows the 15-step season transition order from GDD §16.3.
extends RefCounted

## Reference to the main GameState node — all data lives there.
var gs  # GameState reference (untyped to avoid circular dependency)


func _init(game_state) -> void:
	gs = game_state


# ═══════════════════════════════════════════════════════════════════════════
# STEP 1: END OF SEASON — Finalise current season
# ═══════════════════════════════════════════════════════════════════════════

func end_season() -> void:
	gs.add_log("=== SEASON %d COMPLETE ===" % gs.current_season)

	# ── 1. Award champion titles, archive to History ─────────────────────
	# Log driver standings top 3 and award drivers championship
	var sorted_drivers = gs.active_championship.get_standings_sorted()
	gs.add_log("DRIVERS CHAMPIONSHIP:")
	for i in range(min(3, sorted_drivers.size())):
		var entry = sorted_drivers[i]
		var driver = gs.all_drivers.get(entry["driver_id"])
		if driver:
			gs.add_log("P%d: %s — %d pts" % [i + 1, driver.full_name(), entry["points"]])
	## Award drivers championship to winner
	if sorted_drivers.size() > 0:
		gs._award_drivers_championship(sorted_drivers[0]["driver_id"], gs.active_championship)

	# Log team standings top 3 and award constructors championship
	var sorted_teams = gs.active_championship.get_team_standings_sorted()
	gs.add_log("TEAMS CHAMPIONSHIP:")
	for i in range(min(3, sorted_teams.size())):
		var entry = sorted_teams[i]
		var team_name = "Unknown"
		for team in gs.all_teams:
			if team.id == entry["team_id"]:
				team_name = team.team_name
				break
		gs.add_log("P%d: %s — %d pts" % [i + 1, team_name, entry["points"]])
	## Award constructors championship to winner
	if sorted_teams.size() > 0:
		gs._award_teams_championship(sorted_teams[0]["team_id"], gs.active_championship)

	## Apply reputation inertia — rep moves toward earned value slowly
	gs._apply_reputation_inertia()

	gs.emit_signal("season_ended", gs.current_season)
	gs.emit_signal("log_updated")
	gs._process_sponsors_season_end()
	gs._process_supply_contracts_season_end()
	gs.pending_season_screen = "end_of_season"


# ═══════════════════════════════════════════════════════════════════════════
# STEP 2: START NEW SEASON — 15-step order from GDD §16.3
# ═══════════════════════════════════════════════════════════════════════════

func start_new_season() -> void:
	gs.current_season += 1
	gs.current_week = 1
	gs.weekly_log.clear()
	gs.pending_season_screen = "begin_of_season"

	# ── Step 7: Contract decrements — age drivers/staff ──────────────────
	# ── Step 8: Expired contracts — free agent pool ──────────────────────
	# ── Step 9: Academy — drivers turning 18 ─────────────────────────────
	_process_off_season()

	# ── GK: Populate groups for new season ───────────────────────────────
	if gs.gk_discipline == null:
		gs.gk_discipline = GKDiscipline.new()
	## Clear old GK cadet drivers before repopulating to avoid accumulation
	var gk_driver_ids_to_clear: Array = []
	for did in gs.all_drivers:
		var d = gs.all_drivers[did]
		if d.active_discipline == "GK" and d.contract_team != gs.player_team.id:
			gk_driver_ids_to_clear.append(did)
	for did in gk_driver_ids_to_clear:
		gs.all_drivers.erase(did)
	print("[SeasonManager] Cleared %d GK AI drivers for season reset" % gk_driver_ids_to_clear.size())

	gs.gk_discipline.populate_season(
		gs.all_drivers,
		gs.all_staff,
		gs.player_team.drivers,
		gs.player_registered_championships,
		gs.CHAMPIONSHIP_CALENDARS,
		gs.current_season,
		gs.player_team_cars)

	## Generate TP assignment proposals for the new season
	if not gs.player_team_cars.is_empty():
		var tp_proposals = gs.generate_tp_assignment_proposals()
		gs._last_tp_proposals = tp_proposals

	# ── Step 5: CNC — jobs in progress destroyed, inventory cleared ──────
	# ── Wipe ALL player cars ─────────────────────────────────────────────
	gs.player_team_cars.clear()
	## Clear car assignments on all staff — cars no longer exist
	for staff_id in gs.all_staff:
		var s = gs.all_staff[staff_id]
		if s.assigned_car_id != "":
			s.assigned_car_id = ""
	## Wipe all installed parts (CNC and provider) and warehouse inventory
	gs.car_installed_parts.clear()
	gs.car_provider_parts.clear()
	gs.cnc_parts_inventory.clear()
	gs.add_log("🏎 All cars retired for Season %d. Buy or build new cars before Race 1." % gs.current_season)

	# ── Reset all championships for new season ───────────────────────────
	## ALL 24 championships reset and stay active — the world keeps running.
	for champ in gs.active_championships:
		champ.reset_for_new_season()

	## Sync GK Group 0 to standings after reset
	gs._sync_gk_group0_to_standings()

	## Notify player if not registered anywhere
	if gs.player_registered_championships.is_empty():
		gs.add_notification("High",
			"⚠ No championships registered for Season %d! Use the Championships screen to register." % gs.current_season)
	else:
		## Check player has a car for each registered championship
		for champ_id in gs.player_registered_championships:
			var has_car = false
			for car in gs.player_team_cars:
				if car.championship_id == champ_id: has_car = true; break
			if not has_car:
				var reg = gs.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
				gs.add_notification("High",
					"🏎 No car for %s — buy or manufacture one before Race 1." % reg.get("name", champ_id),
					"logistics")

	## Delivery deadline notifications
	for champ in gs.active_championships:
		var delivery_wk = gs.get_car_delivery_week(champ.id)
		var race1_wk    = gs.FIRST_RACE_WEEK.get(champ.id, 6)
		gs.add_notification("High",
			"Season %d [%s]: New car needed. Delivery: Week %d. Race 1: Week %d." % [
			gs.current_season, champ.championship_name, delivery_wk, race1_wk])

	## Re-register AI drivers and teams into championship standings
	gs.ai_manager.load_car_assignments()

	gs.add_log("=== SEASON %d BEGINS ===" % gs.current_season)

	# ── Step 10: Transfer market — activate pre-signed contracts ─────────
	gs._activate_presigned_contracts()

	# ── Step 4: R&D carry over — P2 wiped, P4 always carry ──────────────
	var expired_upg = gs.completed_upg_tasks.size()
	gs.completed_upg_tasks.clear()
	gs.completed_rnd_tasks = gs.completed_rnd_tasks.filter(
		func(tid): return not tid.begins_with("UPG-"))
	if expired_upg > 0:
		gs.add_log("📋 %d upgrade blueprints expired for Season %d. Upgrades reset to L1." % [expired_upg, gs.current_season])

	## WRA regulation change check
	if gs.current_season > gs.wra_cycle_start_season and \
		(gs.current_season - gs.wra_cycle_start_season) % gs.WRA_CYCLE_LENGTH == 0:
		gs._apply_wra_regulation_change()

	gs._rebuild_seasonal_rnd_tasks()
	gs.add_log("🔬 R&D catalog updated for Season %d." % gs.current_season)

	# ── Clear registrations AFTER everything — player re-registers ───────
	var prev_champ_names_s = []
	for champ in gs.active_championships:
		prev_champ_names_s.append(champ.championship_name)
	gs.player_registered_championships.clear()
	if not prev_champ_names_s.is_empty():
		gs.add_notification("Normal",
			"Season %d active: %s. Re-register during off-season for Season %d." % [
			gs.current_season, ", ".join(prev_champ_names_s), gs.current_season + 1])
	gs.emit_signal("week_advanced", gs.current_week)
	gs.emit_signal("log_updated")


# ═══════════════════════════════════════════════════════════════════════════
# OFF-SEASON PROCESSING — Steps 7-9 from GDD §16.3
# ═══════════════════════════════════════════════════════════════════════════

func _process_off_season() -> void:
	# ── Age all drivers, recover fitness, accumulate experience ───────────
	for driver_id in gs.all_drivers:
		var driver = gs.all_drivers[driver_id]
		driver.age += 1
		driver.fitness = 100.0
		driver.experience = min(100.0, driver.experience + 1.0)
		driver.seasons_without_contract += 1
		## Decrement contract — academy drivers use age-based bond
		if driver.contract_type == "academy":
			## Academy bond ends at age 18 — notify player
			if driver.contract_team == gs.player_team.id:
				if driver.age == 17:
					gs.add_notification("High",
						"🎓 %s will turn 18 next season — offer a professional contract or release from the academy." % driver.full_name())
				elif driver.age >= 18:
					gs.add_notification("Critical",
						"🎓 %s has turned 18 — academy bond expired. Offer professional contract or they will leave." % driver.full_name())
			## Academy bond: seasons_remaining tracks seasons until 18
			driver.contract_seasons_remaining = max(0, 18 - driver.age)
		elif driver.contract_seasons_remaining > 0:
			driver.contract_seasons_remaining -= 1
			if driver.contract_seasons_remaining == 0 and driver.contract_team == gs.player_team.id:
				if driver.contract_type == "cadet":
					gs.add_notification("High",
						"⚠ Cadet %s's contract has expired! Re-sign or they will leave." % driver.full_name())
				else:
					gs.add_notification("High",
						"⚠ %s's contract has expired! Re-sign them or they will leave." % driver.full_name())

	# ── Decrement staff contracts ────────────────────────────────────────
	for staff_id in gs.all_staff:
		var staff = gs.all_staff[staff_id]
		if staff.contract_seasons_remaining > 0:
			staff.contract_seasons_remaining -= 1
			if staff.contract_seasons_remaining == 0 and staff.contract_team == gs.player_team.id:
				gs.add_notification("High",
					"⚠ %s (%s) contract expired! Re-sign or they will leave." % [
					staff.full_name(), staff.role])

	var driver_counter = gs.all_drivers.size()

	# ── Process player team expired contracts ────────────────────────────
	var player_drivers_to_release: Array = []
	for driver_id in gs.player_team.drivers:
		if driver_id in gs.all_drivers:
			var driver = gs.all_drivers[driver_id]
			if driver.contract_seasons_remaining == 0:
				player_drivers_to_release.append(driver_id)
	for driver_id in player_drivers_to_release:
		var driver = gs.all_drivers[driver_id]
		gs.add_log("👋 %s's contract expired — left the team." % driver.full_name())
		gs.add_notification("High", "%s has left — contract expired." % driver.full_name())
		driver.contract_team = ""
		driver.contract_seasons_remaining = 0
		gs.player_team.drivers.erase(driver_id)
		## Remove from all active championship standings
		for champ in gs.active_championships:
			champ.standings.erase(driver_id)

	var player_staff_to_release: Array = []
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.contract_team == gs.player_team.id and s.contract_seasons_remaining == 0:
			player_staff_to_release.append(sid)
	for sid in player_staff_to_release:
		var s = gs.all_staff[sid]
		gs.add_log("👋 %s (%s) contract expired — left the team." % [s.full_name(), s.role])
		gs.add_notification("High", "%s (%s) has left — contract expired." % [s.full_name(), s.role])
		s.contract_team = ""
		s.assigned_championship = ""

	# ── AI team driver aging / replacement ───────────────────────────────
	for team in gs.all_teams:
		## Never auto-remove player team drivers
		if team.id == gs.player_team.id:
			continue

		var drivers_to_remove = []
		var drivers_to_add = []

		for driver_id in team.drivers:
			if driver_id in gs.all_drivers:
				var driver = gs.all_drivers[driver_id]
				if not driver.is_eligible_for_gk_regional():
					drivers_to_remove.append(driver_id)
					var new_id = "D-GEN-%04d" % driver_counter
					driver_counter += 1
					var nat = NameGenerator.get_nationality_for_team(team.nationality)
					var sex = "Male" if randf() > 0.3 else "Female"
					var name_data = NameGenerator.get_full_name(nat, sex)
					var new_driver = gs._create_driver(
						new_id,
						name_data["first"],
						name_data["last"],
						nat,
						8,
						sex,
						team.id
					)
					drivers_to_add.append(new_driver)
					NameGenerator.release_name(driver.full_name())
					gs.add_log("%s aged out of %s — replaced by %s" % [
						driver.full_name(), team.team_name, new_driver.full_name()])

		for driver_id in drivers_to_remove:
			team.drivers.erase(driver_id)
			gs.all_drivers.erase(driver_id)

		for new_driver in drivers_to_add:
			gs.all_drivers[new_driver.id] = new_driver
			team.drivers.append(new_driver.id)
