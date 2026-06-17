class_name SeasonManager
## Version: S28.1 — NextSeasonLedger activation (GDD §16.3 Steps 13-14, §23.1).
##   start_new_season() now ACTIVATES gs.next_season_registrations into
##   gs.player_registered_championships at the TOP of the transition, then clears the
##   ledger. Removed the end-of-function .clear() that wiped registrations (the Season-2
##   car/registration collapse — Logistics only showed GK, BeginOfSeason saw 0 champs).
##   Stale TP proposals reset + regenerated for the new season (shot 14 fix).
## --- S28.0: Driver/Staff lifecycle rewrite (Bug 2 fix).
##   REMOVED the is_eligible_for_gk_regional() delete-and-respawn loop that was
##   wiping every adult AI driver each off-season and backfilling age-8 D-GEN
##   fillers into Rally/GP/etc. (a GK-only age check misused as a global retire test).
##   Replaced with two real rules (GDD §4.2, §22):
##     • Driver age retirement: rising chance from 38, forced at 50 (rare past 38 —
##       covers veteran TC drivers). Retirement = permanent removal + History archive.
##     • Driver free-agent decay: uncontracted 2 full seasons → erased.
##     • Staff: now age each off-season; hard retire at 65. No free-agent decay.
##   New drivers are NEVER respawned here. Grid gaps are filled elsewhere via
##   the existing NameGenerator path. Retirements archived to gs.retired_personnel.
## --- S27.0 base: Extracted from GameState.gd (P57 Phase 1).
##   Owns the full season lifecycle: end_season(), start_new_season(), _process_off_season().
##   Called by GameState._end_season() and GameState.start_new_season().
##   Follows the 15-step season transition order from GDD §16.3.
extends RefCounted

## Driver age-retirement: per-season chance once a driver is at or past this age.
## Below RETIRE_AGE_MIN nobody retires by age. At/after RETIRE_AGE_MAX it is forced.
const RETIRE_AGE_MIN: int = 38
const RETIRE_AGE_MAX: int = 50  ## hard cap — covers rare long-career TC veterans
## Staff retire hard at this age (no free-agent decay for staff).
const STAFF_RETIRE_AGE: int = 65
## A driver/staff member uncontracted for this many seasons is erased entirely.
const FREE_AGENT_MAX_SEASONS: int = 2

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

	# ── GDD §16.3 Step 13: Next Season → Current Season ──────────────────
	## S28.1: ACTIVATE the NextSeasonLedger. The championships the player
	## registered+paid for last season become THIS season's race set.
	## This must happen FIRST so every downstream check (car-needed, delivery,
	## Logistics list, TDL) sees the correct registrations. Never blind-wiped.
	gs.player_registered_championships = gs.next_season_registrations.duplicate()
	# ── GDD §16.3 Step 14: clear the ledger, ready for new planning ──────
	gs.next_season_registrations.clear()
	if gs.player_registered_championships.is_empty():
		gs.add_log("⚠ No championships were registered for Season %d." % gs.current_season)
	else:
		var names: Array = []
		for cid in gs.player_registered_championships:
			names.append(gs.CHAMPIONSHIP_REGISTRY.get(cid, {}).get("name", cid))
		gs.add_log("🏁 Season %d race set activated: %s" % [gs.current_season, ", ".join(names)])

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

	## (TP proposals are reset and regenerated at the end of the transition,
	##  after cars are wiped — see S28.1 block below.)

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

	# ── S28.1: registrations already activated at the top from the ledger. ──
	## Do NOT clear player_registered_championships here — that was the Season-2
	## collapse bug. Instead, flush stale planning state from last season.
	## Clear stale TDL items (shots 5/12 fix): per-season "unmet requirements before
	## Season N" / "no car for X" custom + dismissed items must not survive into the
	## new season. They are regenerated fresh for the current season as needed.
	gs.custom_todo_items.clear()
	gs.dismissed_todo_items.clear()
	## Clear stale TP proposals (shot 14 fix) — they referenced last season's cars.
	gs._last_tp_proposals = []
	## Regenerate TP proposals for the new season's actual cars (if any exist yet).
	if not gs.player_team_cars.is_empty():
		gs._last_tp_proposals = gs.generate_tp_assignment_proposals()

	if gs.player_registered_championships.is_empty():
		gs.add_notification("Normal",
			"Season %d started with no championships. Register during this season for Season %d." % [
			gs.current_season, gs.current_season + 1])
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
		## Free-agent counter (S28): only accrues while uncontracted; resets when
		## the driver holds a contract. Prevents a later-signed driver from being
		## wrongly erased by the 2-season free-agent decay rule.
		if driver.contract_team == "":
			driver.seasons_without_contract += 1
		else:
			driver.seasons_without_contract = 0
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

	# ── Age staff + decrement staff contracts ─────────────────────────────
	## Staff are aged here (this is the only place staff age advances) so the
	## hard retirement at STAFF_RETIRE_AGE can fire. Actual retirement is
	## processed later in the lifecycle pass below.
	for staff_id in gs.all_staff:
		var staff = gs.all_staff[staff_id]
		staff.age += 1
		if staff.contract_seasons_remaining > 0:
			staff.contract_seasons_remaining -= 1
			if staff.contract_seasons_remaining == 0 and staff.contract_team == gs.player_team.id:
				gs.add_notification("High",
					"⚠ %s (%s) contract expired! Re-sign or they will leave." % [
					staff.full_name(), staff.role])

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

	# ── DRIVER & STAFF LIFECYCLE (GDD §4.2, §22) ─────────────────────────
	## No driver/staff is ever deleted "just like this". Exactly two rules:
	##   1. Age retirement — drivers: rising chance from 38, forced at 50.
	##                       staff:   hard retire at 65.
	##      Retirement is permanent (game over for that person) and archived.
	##   2. Free-agent decay — drivers uncontracted for 2 full seasons are erased.
	## New drivers are NOT respawned here — grid gaps are filled elsewhere via
	## the normal NameGenerator path, so no D-GEN / DRV-XX fillers leak in.
	_process_driver_lifecycle()
	_process_staff_lifecycle()


## Rule 1 (drivers) + Rule 2 (drivers): age retirement and free-agent decay.
func _process_driver_lifecycle() -> void:
	var to_retire: Array = []   ## age retirement — permanent
	var to_erase: Array = []    ## free-agent 2 seasons — permanent

	for driver_id in gs.all_drivers:
		var driver = gs.all_drivers[driver_id]

		## Rule 1 — age retirement. Cadets/academy kids never qualify.
		if driver.contract_type != "academy" and _driver_retires_by_age(driver.age):
			to_retire.append(driver_id)
			continue  ## retirement takes precedence over free-agent decay

		## Rule 2 — free-agent decay. Only for genuinely uncontracted people.
		if driver.contract_team == "" and driver.seasons_without_contract >= FREE_AGENT_MAX_SEASONS:
			to_erase.append(driver_id)

	for driver_id in to_retire:
		_retire_person(driver_id, gs.all_drivers, "driver")
	for driver_id in to_erase:
		_erase_free_agent(driver_id, gs.all_drivers, "driver")


## Rule 1 (staff): hard retirement at STAFF_RETIRE_AGE. No free-agent decay.
func _process_staff_lifecycle() -> void:
	var to_retire: Array = []
	for staff_id in gs.all_staff:
		var staff = gs.all_staff[staff_id]
		if staff.age >= STAFF_RETIRE_AGE:
			to_retire.append(staff_id)
	for staff_id in to_retire:
		_retire_person(staff_id, gs.all_staff, "staff")


## Rising retirement chance: 0 below MIN, climbing each year, forced at MAX.
## Deliberately rare in the late 30s/40s so veteran TC careers can run to ~50.
func _driver_retires_by_age(age: int) -> bool:
	if age < RETIRE_AGE_MIN:
		return false
	if age >= RETIRE_AGE_MAX:
		return true
	## Probability ramps from ~5% at 38 toward ~100% at 50.
	var span: float = float(RETIRE_AGE_MAX - RETIRE_AGE_MIN)
	var t: float = float(age - RETIRE_AGE_MIN) / span   ## 0.0 → 1.0
	var chance: float = 0.05 + (t * t) * 0.85           ## quadratic ramp, low early
	return randf() < chance


## Permanent removal (age retirement). Archives to History, frees the name,
## strips from team rosters, car assignments, and championship standings.
func _retire_person(person_id: String, pool: Dictionary, kind: String) -> void:
	if not (person_id in pool):
		return
	var person = pool[person_id]
	var is_player := false

	if kind == "driver":
		is_player = (person.contract_team == gs.player_team.id)
		## Remove from any team roster
		for team in gs.all_teams:
			team.drivers.erase(person_id)
		## Remove from all championship standings
		for champ in gs.active_championships:
			champ.standings.erase(person_id)
		gs.add_log("🏁 %s has retired from racing at age %d." % [person.full_name(), person.age])
		if is_player:
			gs.add_notification("Critical",
				"🏁 Your driver %s has retired (age %d). Sign a replacement before Race 1." % [
				person.full_name(), person.age])
	else:  ## staff
		is_player = (person.contract_team == gs.player_team.id)
		person.contract_team = ""
		if "assigned_championship" in person:
			person.assigned_championship = ""
		if "assigned_car_id" in person:
			person.assigned_car_id = ""
		gs.add_log("🏁 %s (%s) has retired at age %d." % [person.full_name(), person.role, person.age])
		if is_player:
			gs.add_notification("Critical",
				"🏁 Your %s %s has retired (age %d). Hire a replacement." % [
				person.role, person.full_name(), person.age])

	## Archive for History / News (GDD §13, §19)
	gs.retired_personnel.append({
		"season": gs.current_season,
		"name": person.full_name(),
		"kind": kind,
		"role": (person.role if kind == "staff" else "Driver"),
		"age": person.age,
		"was_player": is_player,
	})

	NameGenerator.release_name(person.full_name())
	pool.erase(person_id)


## Permanent removal for a free agent unsigned 2+ seasons (drivers only).
func _erase_free_agent(person_id: String, pool: Dictionary, kind: String) -> void:
	if not (person_id in pool):
		return
	var person = pool[person_id]
	## Defensive: never erase anyone still on a team roster.
	for team in gs.all_teams:
		if person_id in team.drivers:
			return
	for champ in gs.active_championships:
		champ.standings.erase(person_id)
	gs.add_log("📁 %s left the sport after 2 seasons without a contract." % person.full_name())
	NameGenerator.release_name(person.full_name())
	pool.erase(person_id)
