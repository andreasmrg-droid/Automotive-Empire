class_name SeasonManager
## Version: S35.11 — Step 4 R&D rollover hardened: P2 (Upgrade) blueprints now fully purged
##   from known_blueprints + WRA submissions + WRA approvals + CNC queue (previously only the
##   task lists were cleared, so P2 leaked across the season boundary). P1/P3 next-season
##   blueprints self-activate via their design_season stamp + the start_cnc_job season-gate —
##   no explicit activation needed. Added inert FUTURE hook for outbound supply-contract
##   activation + late-delivery penalties at season start.
## Version: S35.6 — _process_lifecycle_cull() calls gs.invalidate_player_staff_cache() after
##   retirements, so the player-staff cache (GameState S35.6) refreshes if a player staff retired.
## Version: S35.0 — SEASON TRANSITION PIPELINE reorder (Season_Transition_Pipeline_Spec_v1).
##   start_new_season() is now an explicit, commented A→E ordered sequence instead of the old
##   tangled order. The CRITICAL fix is ordering, not new logic: Stage B (activate pre-signed
##   signings) now runs BEFORE Stage E (the 2-season free-agent cull). Previously B ran dead-last
##   (after the cull inside _process_off_season), so a driver you pre-signed last season — still a
##   free agent at rollover — could be ERASED by the 2-season decay in the same tick, BEFORE the
##   activation that would have joined them to your team. The pre-signing silently evaporated.
##   Stages B (S33.1/33.2) and D (S33.1 GK generate-to-fill) were already individually fixed and
##   verified live; this session only REORDERS them into the correct sequence and adds the missing
##   archive write (below). Pipeline order now:
##     A  promote registration ledger        (was top — unchanged position)
##     B  apply signings + staff assignments  (MOVED UP from end; was line ~220)
##     C  TP assignment / AI auto-assign       (clean slot)
##     D  GK generate-to-fill                  (after rosters settle)
##     E  lifecycle cull + archive            (now LAST; _process_off_season split so the cull
##                                             runs after B, not before it)
##   Also: _erase_free_agent now ARCHIVES the departing person to gs.retired_personnel (reason
##   "left_sport") before erasing — previously a 2-season free-agent just vanished with no record
##   (Spec Stage-E gap). NOT written to gs.hall_of_fame: that array is race-WIN records consumed
##   by HallOfFame.gd/Museum.gd (filtered by team_id, counted as wins) — a career-exit entry there
##   would corrupt the win tally. retired_personnel is the correct career archive (matches the
##   existing _retire_person schema).
## --- S33.1 — GK feeder regeneration: replaced the destructive GK wipe (which deleted all
##   non-player GK drivers then relied on populate_season to "repopulate" — but populate_season
##   only SORTS, never CREATES, so GK went empty every season past S1). Now the contracted GK
##   field persists; only stale D-GK-FA pool drivers are cleared; gs.regenerate_gk_field(510)
##   tops up the gap with new young cadets. Fixes the empty-GK-world + dried-up promotion pyramid.
## --- S33.0 — TP Phase 2 hook: after the JSON seed (load_car_assignments), for Season >= 2
##   call gs.ai_auto_assign_all_teams() so the optimiser takes over AI assignment from Season 2
##   onward (Season 1 stays JSON-seeded). Absorbs the season's AI roster changes too.
## --- S28.4 — AI teams auto-renew expiring contracts each off-season (Bug 8).
## --- S28.3 — Free-agent pool replenished each season after retirements (Bug 7).
## --- S28.1 — NextSeasonLedger activation (GDD §16.3 Steps 13-14, §23.1).
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

	# ═══════════════════════════════════════════════════════════════════════
	# SEASON TRANSITION PIPELINE (Season_Transition_Pipeline_Spec_v1) — A→E.
	# The stages run in this exact order. Two earlier-broken stages (B, D) were
	# already fixed (S33.1/33.2) and individually verified; S35.0 is the REORDER
	# that makes B run before E, plus the Stage-E archive write. See header.
	# ═══════════════════════════════════════════════════════════════════════

	# ── STAGE A — Promote the ledger (registrations) ────────────────────────
	## GDD §16.3 Steps 13-14. The championships the player registered+paid for last
	## season become THIS season's race set; then clear the ledger for new planning.
	## Must be first so every downstream check (car-needed, delivery, Logistics, TDL)
	## sees the correct registrations. Never blind-wiped.
	gs.player_registered_championships = gs.next_season_registrations.duplicate()
	gs.next_season_registrations.clear()
	if gs.player_registered_championships.is_empty():
		gs.add_log("⚠ No championships were registered for Season %d." % gs.current_season)
	else:
		var names: Array = []
		for cid in gs.player_registered_championships:
			names.append(gs.CHAMPIONSHIP_REGISTRY.get(cid, {}).get("name", cid))
		gs.add_log("🏁 Season %d race set activated: %s" % [gs.current_season, ", ".join(names)])

	# ── PRE-B — Age & lapse (was the front half of _process_off_season) ─────
	## Age drivers/staff, decrement contracts, lapse expired player contracts.
	## Runs BEFORE Stage B so a contract expiring at this rollover frees its holder
	## before signings are applied. The CULL half is now Stage E (late), not here.
	_process_off_season_aging()

	# ── STAGE B — Apply signings & releases ─────────────────────────────────
	## Activate every pre-signed contract whose effective join season is now (joins the
	## person to their new team), and flush queued TP/Strategist assignments. MOVED UP
	## from the old end-of-function slot: it MUST precede Stage E, or a driver pre-signed
	## last season — still a free agent at this instant — gets erased by the 2-season
	## cull before this activation can join them (the silent-evaporation bug). Fixed
	## (S33.1/33.2); this is purely the ordering correction.
	gs._activate_presigned_contracts()
	gs._apply_pending_staff_assignments()
	gs.add_log("=== SEASON %d BEGINS ===" % gs.current_season)

	# ── STAGE C — TP assignment (AI auto-assign) ────────────────────────────
	## Season 1 stays JSON-seeded (load_car_assignments runs later in the presentation
	## block). From Season 2 the optimiser re-allocates every AI team's 5 roles. Player
	## proposals are generated at the end (after the car wipe) via generate_tp_assignment_
	## proposals — see the presentation block. AI auto-assign is moved earlier so AI rosters
	## are settled before GK fill and the cull read them.
	if gs.current_season >= 2:
		gs.ai_auto_assign_all_teams()

	# ── STAGE D — GK feeder generate-to-fill ────────────────────────────────
	## GK is the ONLY birthplace of new drivers (the pyramid's source). The contracted GK
	## field PERSISTS across seasons; we only clear the stale D-GK-FA pool and TOP UP the
	## gap with new young cadets (regenerate_gk_field = target − existing). Verified live:
	## regenerate_gk_field really creates drivers via _create_driver_for_discipline. NOT a
	## wipe (the old destructive bug). Runs after rosters settle so "existing" is accurate.
	if gs.gk_discipline == null:
		gs.gk_discipline = GKDiscipline.new()
	var gk_fa_to_clear: Array = []
	for did in gs.all_drivers:
		if did.begins_with("D-GK-FA"):
			gk_fa_to_clear.append(did)
	for did in gk_fa_to_clear:
		gs.all_drivers.erase(did)
	var gk_generated: int = gs.regenerate_gk_field(510)
	print("[SeasonManager] GK feeder: cleared %d stale FA, generated %d new young cadets." % [
		gk_fa_to_clear.size(), gk_generated])
	gs.gk_discipline.populate_season(
		gs.all_drivers,
		gs.all_staff,
		gs.player_team.drivers,
		gs.player_registered_championships,
		gs.CHAMPIONSHIP_CALENDARS,
		gs.current_season,
		gs.player_team_cars)

	# ── STAGE E — Lifecycle cull + Hall-of-Fame / archive ───────────────────
	## Age retirement + 2-season free-agent erase, run LAST so a just-released or just-
	## activated (Stage B) person is not culled in the same tick they change status.
	## _erase_free_agent now archives departing free agents to retired_personnel before
	## erasing (the Stage-E gap the spec flagged).
	_process_lifecycle_cull()

	# ═══════════════════════════════════════════════════════════════════════
	# DOWNSTREAM PRESENTATION (not lifecycle): car reset, champ reset, notifs,
	# R&D carry-over, WRA check, stale-state flush. Order among these is cosmetic.
	# ═══════════════════════════════════════════════════════════════════════

	# ── Step 5: CNC jobs destroyed, inventory cleared + wipe ALL player cars ─
	gs.player_team_cars.clear()
	for staff_id in gs.all_staff:
		var s = gs.all_staff[staff_id]
		if s.assigned_car_id != "":
			s.assigned_car_id = ""
	gs.car_installed_parts.clear()
	gs.car_provider_parts.clear()
	gs.cnc_parts_inventory.clear()
	gs.add_log("🏎 All cars retired for Season %d. Buy or build new cars before Race 1." % gs.current_season)

	# ── Reset all championships for new season ───────────────────────────
	## ALL 24 championships reset and stay active — the world keeps running.
	for champ in gs.active_championships:
		champ.reset_for_new_season()
	gs._sync_gk_group0_to_standings()

	## Notify player if not registered anywhere / missing a car
	if gs.player_registered_championships.is_empty():
		gs.add_notification("High",
			"⚠ No championships registered for Season %d! Use the Championships screen to register." % gs.current_season)
	else:
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

	## Re-register AI drivers and teams into championship standings (Season-1 JSON seed
	## + the absorbed AI roster changes from Stage C).
	gs.ai_manager.load_car_assignments()

	# ── Step 4: R&D carry over — P2/UPG fully purged, P1/P3 next-season activate ──
	## S35.11 — P2 (Upgrade) blueprints are CURRENT-season only. At rollover they must be
	## purged from EVERY stage of the pipeline, not just the task lists (previously only
	## completed_upg_tasks + UPG- tasks were cleared, so P2 blueprints leaked across the
	## boundary via known_blueprints / WRA / CNC). P1+P3 next-season blueprints need NO
	## explicit activation: they are stamped season = design_season (next), survive in
	## known_blueprints, and the start_cnc_job season-gate (bp.season ≤ current_season)
	## auto-unlocks them the instant current_season increments. cnc_parts_inventory is
	## already wiped above (every season scraps all cars), and next-season parts can't be
	## manufactured pre-rollover (season-gate), so no early next-season stock exists to lose.
	var expired_upg = gs.completed_upg_tasks.size()
	gs.completed_upg_tasks.clear()
	gs.completed_rnd_tasks = gs.completed_rnd_tasks.filter(
		func(tid): return not tid.begins_with("UPG-"))
	## Purge P2 blueprints from R&D storage, WRA pipeline, and the CNC queue.
	var p2_bp_ids: Array = []
	for bp_id in gs.known_blueprints:
		if gs.known_blueprints[bp_id].get("pillar", 0) == 2:
			p2_bp_ids.append(bp_id)
	for bp_id in p2_bp_ids:
		gs.known_blueprints.erase(bp_id)
	gs.active_wra_submissions = gs.active_wra_submissions.filter(
		func(sub): return not sub.get("blueprint_id","") in p2_bp_ids)
	gs.wra_approved_blueprints = gs.wra_approved_blueprints.filter(
		func(app): return not app.get("blueprint_id","") in p2_bp_ids)
	gs.cnc_production_queue = gs.cnc_production_queue.filter(
		func(job): return not job.get("blueprint_id","") in p2_bp_ids)
	if expired_upg > 0 or not p2_bp_ids.is_empty():
		gs.add_log("📋 %d upgrade tasks + %d P2 blueprints purged (R&D/WRA/CNC) for Season %d. Upgrades reset to L1." % [
			expired_upg, p2_bp_ids.size(), gs.current_season])

	## FUTURE (S35.11 hook — inert): outbound parts/cars supply contracts activate HERE at
	## season start. If the provider fails to deliver contracted parts/cars on time, apply a
	## financial penalty. Wired as a no-op until the supply-contract delivery system exists.
	## gs._activate_outbound_supply_contracts()        # activate this season's obligations
	## gs._assess_supply_delivery_penalties()           # charge late/non-delivery penalties

	## WRA regulation change check
	if gs.current_season > gs.wra_cycle_start_season and \
		(gs.current_season - gs.wra_cycle_start_season) % gs.WRA_CYCLE_LENGTH == 0:
		gs._apply_wra_regulation_change()

	gs._rebuild_seasonal_rnd_tasks()
	gs.add_log("🔬 R&D catalog updated for Season %d." % gs.current_season)

	# ── Flush stale planning state from last season (don't re-clear registrations) ──
	gs.custom_todo_items.clear()
	gs.dismissed_todo_items.clear()
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

## S35.0 — renamed from _process_off_season: this now ONLY ages drivers/staff, decrements
## contracts, and lapses expired player contracts (the "pre-B" early phase). The cull moved to
## _process_lifecycle_cull (Stage E, late). Must run BEFORE Stage B signings so a contract that
## expires at this rollover frees its holder before signings are applied.
func _process_off_season_aging() -> void:
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
	## S35.0: the cull phase moved OUT of this function into _process_lifecycle_cull(),
	## called as Stage E (LATE) in start_new_season — after Stage B activates pre-signed
	## contracts. Running it here (early) erased a just-pre-signed driver (still a free agent
	## at this point) before their activation could join them. Aging/contract-decrement above
	## still runs early (Stage "pre-B"): a contract that expires this rollover must lapse before
	## signings so the freed person is available. See the function below.


## S35.0 — Stage E: the lifecycle cull, split out of _process_off_season so it runs LATE
## (after Stage B pre-signed activation). Exactly two removal rules (GDD §4.2, §22):
##   1. Age retirement — drivers: rising chance from 38, forced at 50; staff: hard retire at 65.
##   2. Free-agent decay — drivers uncontracted for 2 full seasons are erased (now archived).
## New drivers are NOT respawned here — GK generate-to-fill (Stage D) handles the pyramid source.
func _process_lifecycle_cull() -> void:
	_process_driver_lifecycle()
	_process_staff_lifecycle()
	## S28.3 (Bug 7): top up the free-agent pool after retirements so it doesn't drain.
	gs.replenish_free_agent_pool()
	## S28.3 (Bug 8): AI teams automatically renew their own expiring contracts so the
	## negotiation cycle "triggers automatically" for the AI world (GDD §13 / line 605).
	_ai_auto_renew_contracts()
	## S35.6 — a player staff member may have retired; refresh the player-staff cache.
	gs.invalidate_player_staff_cache()


## S28.3 (Bug 8) — AI teams auto-renew expiring contracts for their own drivers & staff.
## Without this, AI personnel sit at contract_seasons_remaining = 0 forever (no negotiation
## ever fired for them). Player contracts are untouched — the player renews manually.
func _ai_auto_renew_contracts() -> void:
	var renewed = 0
	var pid = gs.player_team.id
	for driver_id in gs.all_drivers:
		var d = gs.all_drivers[driver_id]
		if d.contract_team != "" and d.contract_team != pid and d.contract_seasons_remaining <= 0:
			d.contract_seasons_remaining = randi_range(2, 4)
			renewed += 1
	for staff_id in gs.all_staff:
		var s = gs.all_staff[staff_id]
		if s.contract_team != "" and s.contract_team != pid and s.contract_seasons_remaining <= 0:
			s.contract_seasons_remaining = randi_range(2, 4)
			renewed += 1
	if renewed > 0:
		gs.add_log("📋 AI teams renewed %d expiring contracts for the new season." % renewed)


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
	## S35.0 — archive to the career record BEFORE erasing (Spec Stage-E gap: a 2-season
	## free agent previously just vanished with no trace). Schema matches _retire_person's
	## retired_personnel entries; reason="left_sport" distinguishes a quiet exit from an age
	## retirement. NOT written to gs.hall_of_fame — that array is race-WIN records (consumed
	## by HallOfFame.gd / Museum.gd, filtered by team_id and counted as wins); a career-exit
	## entry there would corrupt the win tally. retired_personnel is the correct archive.
	gs.retired_personnel.append({
		"season": gs.current_season,
		"name": person.full_name(),
		"kind": kind,
		"role": (person.role if kind == "staff" else "Driver"),
		"age": (person.age if "age" in person else 0),
		"was_player": false,  ## a 2-season free agent is by definition unrostered
		"reason": "left_sport",
	})
	gs.add_log("📁 %s left the sport after 2 seasons without a contract." % person.full_name())
	NameGenerator.release_name(person.full_name())
	pool.erase(person_id)
