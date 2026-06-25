class_name StaffManager
## Version: S37.15 — #18: runtime-generated Team Principals now roll talent_scouting (wide 10–90,
## independent of overall quality — a mediocre TP can have a great eye).
## Version: S35.6 — get_player_staff_by_role() now reads GameState's player-staff cache instead of
##   scanning all 5000+ staff every call (called many times per HQ render). hire/release invalidate
##   the cache. See GameState S35.6.
## Version: S28.3 — Added replenish_free_agent_pool(): tops up uncontracted staff per role
##   each season so retirements/hirings don't drain the market (Bug 7).
## --- S27.0 — Extracted from GameState.gd (P57)
##   Staff/driver generation, hiring, releasing, attribute generation, queries.
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

func _generate_available_staff(count: int) -> void:
	## Generates `count` staff spread across all roles and nationalities.
	## All start as available (contract_team = "").
	var role_distribution = {
		"Race Mechanic":   int(count * 0.25),  # 15
		"Pit Crew":        int(count * 0.20),  # 12
		"Team Principal":  int(count * 0.12),  # 7
		"CFO":             int(count * 0.10),  # 6
		"Designer":        int(count * 0.18),  # 11
		"Race Strategist": int(count * 0.15),  # 9
	}

	var nationalities = ["British", "Italian", "German", "French", "Spanish",
		"Finnish", "Brazilian", "Japanese", "American", "Australian",
		"Dutch", "Belgian", "Swiss", "Austrian", "Swedish"]

	for role in role_distribution:
		var role_count = role_distribution[role]
		for i in range(role_count):
			var staff = _create_staff(role, nationalities[randi() % nationalities.size()])
			gs.all_staff[staff.id] = staff


## S28.3 (Bug 7) — top up the free-agent pool each season so retirements/hirings don't
## drain it over many seasons. Counts current UNCONTRACTED staff per role and generates
## new free agents for any role below its target minimum.
func replenish_free_agent_pool() -> void:
	## Target minimum free agents available per role.
	var target_per_role = {
		"Race Mechanic":   8,
		"Pit Crew":        8,
		"Team Principal":  4,
		"CFO":             4,
		"Designer":        6,
		"Race Strategist": 5,
	}
	var nationalities = ["British", "Italian", "German", "French", "Spanish",
		"Finnish", "Brazilian", "Japanese", "American", "Australian",
		"Dutch", "Belgian", "Swiss", "Austrian", "Swedish"]

	## Count current free agents (uncontracted) per role.
	var free_counts: Dictionary = {}
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.contract_team == "":
			free_counts[s.role] = free_counts.get(s.role, 0) + 1

	var added = 0
	for role in target_per_role:
		var have = free_counts.get(role, 0)
		var need = target_per_role[role] - have
		for i in range(max(0, need)):
			var staff = _create_staff(role, nationalities[randi() % nationalities.size()])
			gs.all_staff[staff.id] = staff
			added += 1
	if added > 0:
		gs.add_log("👔 Staff market replenished: %d new free agents available." % added)


func _create_staff(role: String, nationality: String) -> Staff:
	gs._staff_id_counter += 1
	var staff = Staff.new()
	staff.id = "ST-%04d" % gs._staff_id_counter
	staff.nationality = nationality
	staff.role = role
	staff.age = randi_range(22, 58)
	staff.sex = "Male" if randf() > 0.3 else "Female"
	staff.contract_team = ""
	staff.contract_seasons_remaining = 0

	# Generate name
	var name_data = NameGenerator.get_full_name(nationality, staff.sex)
	staff.first_name = name_data["first"]
	staff.last_name = name_data["last"]

	# Talent — bell curve distribution
	var raw_talent = randf_range(20.0, 95.0)
	# Most staff cluster around 40-70, fewer at extremes
	staff.talent = clamp((raw_talent + randf_range(20.0, 80.0)) / 2.0, 20.0, 95.0)

	# Starting quality is ~65-85% of talent (from Excel: Overall_Quality_vs_Talent_Ratio ≈ 0.7)
	var quality_ratio = randf_range(0.55, 0.85)
	var base_quality = staff.talent * quality_ratio

	# Reputation scales with quality
	staff.reputation = clamp(base_quality * 0.8, 5.0, 90.0)
	staff.morale = randf_range(70.0, 100.0)

	# Salary — scales with talent
	var salary_range = gs.STAFF_BASE_SALARIES.get(role, {"min": 200.0, "max": 500.0})
	var talent_factor = staff.talent / 100.0
	staff.weekly_salary = salary_range["min"] + (salary_range["max"] - salary_range["min"]) * talent_factor

	# Generate role-specific attributes
	_generate_staff_attributes(staff, base_quality)

	return staff


func _generate_staff_attributes(staff: Staff, base_quality: float) -> void:
	## Generates role-specific attributes around base_quality with variance.
	var q = base_quality

	match staff.role:
		"Race Mechanic":
			staff.car_setup      = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.pit_stops      = clamp(q + randf_range(-20.0, 20.0), 1.0, 100.0)
			staff.parts_knowledge = clamp(q + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.track_knowledge  = clamp(randf_range(5.0, 40.0), 1.0, 100.0) # Grows with events
			staff.race_pace        = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.discipline_adaptation["GK"] = clamp(q * 0.5, 1.0, 100.0)

		"Pit Crew":
			staff.pit_stop_speed     = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.repair_skill       = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.fatigue_resistance = clamp(q + randf_range(-20.0, 20.0), 1.0, 100.0)
			staff.fitness            = 100.0

		"Team Principal":
			staff.race_strategy        = clamp(q + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.practice_management  = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.qualifying_management = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.race_pace_reading    = clamp(q + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.car_setup_oversight  = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.pit_stop_management  = clamp(q + randf_range(-20.0, 20.0), 1.0, 100.0)
			staff.pr_skill             = clamp(q + randf_range(-20.0, 20.0), 1.0, 100.0)
			staff.parts_knowledge      = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.track_knowledge      = clamp(randf_range(10.0, 50.0), 1.0, 100.0)
			## Eye for talent — INDEPENDENT of overall quality (a mediocre TP can have a great eye,
			## and vice versa), so it's its own wide roll rather than q ± variance. Grows by season.
			staff.talent_scouting      = clamp(randf_range(10.0, 90.0), 1.0, 100.0)

		"CFO":
			staff.loan_management     = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.sales_skill         = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.sponsor_negotiation = clamp(q + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.resource_management = clamp(q + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.budget_planning     = clamp(q + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.speculation         = clamp(q + randf_range(-20.0, 20.0), 1.0, 100.0)

		"Designer":
			# Each designer has a specialisation — one stat is notably higher
			var specialisms = ["engine", "aero", "brakes", "suspension", "chassis", "gearbox"]
			var specialism = specialisms[randi() % specialisms.size()]
			staff.engine     = clamp(q * 0.7 + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.aero       = clamp(q * 0.7 + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.brakes     = clamp(q * 0.7 + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.suspension = clamp(q * 0.7 + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.chassis    = clamp(q * 0.7 + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.gearbox    = clamp(q * 0.7 + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.reliability    = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.parts_knowledge = clamp(q + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.discipline_adaptation["GK"] = clamp(q * 0.4, 1.0, 100.0)
			# Boost specialism by 15-25 points
			match specialism:
				"engine":     staff.engine     = min(95.0, staff.engine + randf_range(15.0, 25.0))
				"aero":       staff.aero       = min(95.0, staff.aero + randf_range(15.0, 25.0))
				"brakes":     staff.brakes     = min(95.0, staff.brakes + randf_range(15.0, 25.0))
				"suspension": staff.suspension = min(95.0, staff.suspension + randf_range(15.0, 25.0))
				"chassis":    staff.chassis    = min(95.0, staff.chassis + randf_range(15.0, 25.0))
				"gearbox":    staff.gearbox    = min(95.0, staff.gearbox + randf_range(15.0, 25.0))

		"Race Strategist":
			staff.race_strategy       = clamp(q + randf_range(-10.0, 10.0), 1.0, 100.0)
			staff.race_pace_reading   = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.practice_scheduling = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.qualifying_timing   = clamp(q + randf_range(-15.0, 15.0), 1.0, 100.0)
			staff.track_knowledge     = clamp(randf_range(5.0, 35.0), 1.0, 100.0)
			staff.discipline_adaptation["GK"] = clamp(q * 0.4, 1.0, 100.0)

## ═══════════════════════════════════════════════════════════════════════════
## CONTRACT NEGOTIATION SYSTEM (S16.1)
## GDD §6: 3-5 rounds, plain text counters, "Not Interested" from round 1.
## Used by Driver contracts, Staff contracts, and Sponsor renegotiation.
## ═══════════════════════════════════════════════════════════════════════════

## Active negotiation state. One at a time.
var active_negotiation: Dictionary = {}

## ── Approach / Bond / Weekly Negotiation System (S18) ────────────────────────
## Each entry is a Dictionary — see ContractEngine._make_approach() for structure.
var active_approaches: Array = []

## Subjects who walked away from negotiation — unavailable for N seasons
## Format: { subject_id: season_available_again }
var walked_away_subjects: Dictionary = {}

## Signals for the UI
signal negotiation_updated()
signal negotiation_concluded(accepted: bool, subject_id: String, subject_type: String)
signal approach_updated()   ## fired whenever gs.active_approaches changes

## ═══════════════════════════════════════════════════════════════════════════
## CONTRACT ENGINE — delegated to ContractEngine.gd (S27 P57 Phase 4)
## ═══════════════════════════════════════════════════════════════════════════


func hire_staff(staff_id: String) -> bool:
	if not staff_id in gs.all_staff:
		return false
	var staff = gs.all_staff[staff_id]
	if staff.is_hired():
		return false
	## TP slots = 1 per HQ level. CFO: always 1.
	if staff.role == "Team Principal":
		var existing_tp = get_player_staff_by_role("Team Principal")
		var max_tp = gs.get_hq_tp_slots()
		if existing_tp.size() >= max_tp:
			gs.add_notification("High",
				"TP slots full (%d/%d). Upgrade the HQ to unlock more slots." % [existing_tp.size(), max_tp])
			return false
	if staff.role == "CFO":
		var existing_cfo = get_player_staff_by_role("CFO")
		if existing_cfo.size() >= 1:
			gs.add_notification("High", "You already have a CFO. Release them first.")
			return false
	staff.contract_team = gs.player_team.id
	staff.contract_seasons_remaining = 5
	gs.invalidate_player_staff_cache()  ## S35.6 — roster changed
	# Assign crew number for Pit Crew units
	if staff.role == "Pit Crew":
		var existing_crews = get_player_staff_by_role("Pit Crew")
		staff.crew_number = existing_crews.size() + 1
		gs.add_log("✅ Hired %s — CR %.0f/week" % [staff.display_name(), staff.weekly_salary])
		gs.add_notification("Normal", "Pit Crew #%d hired. Assign them to a non-GK car in the Pit Crew Arena." % staff.crew_number)
	else:
		gs.add_log("✅ Hired %s (%s) — CR %.0f/week" % [staff.full_name(), staff.role, staff.weekly_salary])
		gs.add_notification("Normal", "%s (%s) joined your team." % [staff.full_name(), staff.role])
		gs._clear_notifications_containing("No CFO hired")
		gs._clear_notifications_containing("No Team Principal")
	## Fire assignment proposals for roles that affect car racing
	if staff.role in ["Race Mechanic", "Team Principal", "Race Strategist"]:
		gs._fire_assignment_proposals()
	gs.emit_signal("log_updated")
	return true


func release_staff(staff_id: String) -> void:
	if not staff_id in gs.all_staff:
		return
	var staff = gs.all_staff[staff_id]
	var clause = staff.release_clause if staff.release_clause > 0 else 0
	if clause > 0 and staff.contract_seasons_remaining > 0:
		gs.player_team.balance -= clause
		gs.add_log("💰 Release clause paid: CR %s for %s." % [gs._fmt_int(clause), staff.full_name()])
		gs.add_notification("High",
			"Released %s — CR %s release clause paid." % [staff.full_name(), gs._fmt_int(clause)])
	staff.contract_team = ""
	staff.assigned_championship = ""
	staff.assigned_car_id = ""
	staff.contract_seasons_remaining = 0
	staff.release_clause = 0
	gs.invalidate_player_staff_cache()  ## S35.6 — roster changed
	gs.add_log("👋 Released %s (%s)" % [staff.full_name(), staff.role])
	gs.emit_signal("log_updated")


func renew_staff_contract(staff_id: String, seasons: int = 5) -> void:
	if not staff_id in gs.all_staff:
		return
	var staff = gs.all_staff[staff_id]
	if staff.contract_team != gs.player_team.id:
		return
	staff.contract_seasons_remaining = seasons
	gs.add_log("📋 Contract renewed: %s (%s) — %d seasons" % [staff.full_name(), staff.role, seasons])
	gs.emit_signal("log_updated")

## ── Driver management ────────────────────────────────────────────────────────

## Returns all drivers not contracted to any team (available for hire).


func _create_starting_staff(role: String, skill_min: float, skill_max: float) -> Staff:
	var nats = ["British","Italian","German","French","Spanish","Finnish","Brazilian"]
	var nat  = nats[randi() % nats.size()]
	var sex  = "Male" if randf() > 0.35 else "Female"
	var name_data = NameGenerator.get_full_name(nat, sex)
	var s = Staff.new()
	s.id         = "S-START-%s-%d" % [role.replace(" ","_").to_lower(), randi() % 9999]
	s.first_name = name_data["first"]
	s.last_name  = name_data["last"]
	s.nationality = nat
	s.sex        = sex
	s.age        = randi_range(24, 38)
	s.role       = role
	var skill    = randf_range(skill_min, skill_max)
	match role:
		"Team Principal":
			s.race_strategy     = skill
			s.race_pace_reading = skill * 0.9
			s.car_setup_oversight = skill * 0.8
		"Race Mechanic":
			s.car_setup        = skill
			s.track_knowledge  = randf_range(10.0, 30.0)
			s.repair_skill     = skill * 0.85
		"Pit Crew":
			s.pit_stop_speed   = skill
			s.fatigue_resistance = clamp(skill * 0.9 + randf_range(-10.0, 10.0), 1.0, 100.0)
		"Race Strategist":
			s.race_strategy    = skill
			s.qualifying_timing= skill * 0.85
			s.race_pace_reading= skill * 0.8
	var sal_range = gs.STAFF_BASE_SALARIES.get(role, {"min": 200.0, "max": 500.0})
	s.weekly_salary = sal_range["min"] + \
		(sal_range["max"] - sal_range["min"]) * (skill / 100.0)
	return s


func get_player_staff_by_role(role: String) -> Array:
	## S35.6 — read from the cached per-role list instead of scanning all_staff every call.
	if gs._player_staff_cache_dirty:
		gs._rebuild_player_staff_cache()
	return gs._player_staff_by_role.get(role, [])


func get_team_principal() -> Staff:
	var tps = get_player_staff_by_role("Team Principal")
	for tp in tps:
		if tp.assigned_championship == gs.active_championship.id or tp.assigned_championship == "":
			return tp
	return null

## Returns the CFO, or null.


func get_mechanic_for_car(car_id: String) -> Staff:
	for staff_id in gs.all_staff:
		var staff = gs.all_staff[staff_id]
		if staff.role == "Race Mechanic" and staff.assigned_car_id == car_id \
				and staff.contract_team == gs.player_team.id:
			return staff
	return null

## Returns the Team Principal assigned to active championship, or null.


func get_cfo() -> Staff:
	var cfos = get_player_staff_by_role("CFO")
	return cfos[0] if cfos.size() > 0 else null

## Returns only tasks that would cause a DNS or prevent racing entirely.
## Used by the Next Race skip button — advisory warnings don't block the skip.
