class_name TPProposalEngine
## Version: S27.0 — Extracted from GameState.gd (P57)
##   TP auto-assignment proposals: driver/mechanic matching, DNS warnings,
##   cross-discipline adaptation, proposal notification and application.
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

func generate_tp_assignment_proposals() -> Array:
	var proposals: Array = []

	## Build sorted list of player cars by championship prestige (highest first)
	var sorted_cars: Array = gs.player_team_cars.duplicate()
	sorted_cars.sort_custom(func(a, b):
		var reg_a = gs.CHAMPIONSHIP_REGISTRY.get(a.championship_id, {})
		var reg_b = gs.CHAMPIONSHIP_REGISTRY.get(b.championship_id, {})
		var disc_a = reg_a.get("discipline", "GK")
		var disc_b = reg_b.get("discipline", "GK")
		var tier_a = reg_a.get("tier", 1)
		var tier_b = reg_b.get("tier", 1)
		var score_a = gs.DISC_PRESTIGE.get(disc_a, 1) * 10 + tier_a
		var score_b = gs.DISC_PRESTIGE.get(disc_b, 1) * 10 + tier_b
		return score_a > score_b)

	## Track committed drivers/mechanics per race-week
	## committed_drivers[driver_id] = Array of {week, track_id} they're committed to
	var committed_drivers: Dictionary = {}
	var committed_mechanics: Dictionary = {}

	## Available drivers/mechanics on the team
	var avail_drivers: Array = []
	for did in gs.player_team.drivers:
		var d = gs.all_drivers.get(did)
		if d: avail_drivers.append(d)

	var avail_mechanics: Array = []
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.contract_team == gs.player_team.id and s.role == "Race Mechanic":
			avail_mechanics.append(s)

	## Get race calendar for conflict checking
	var race_weeks: Dictionary = {}  ## car_id → Array of {week, track_id}
	for car in sorted_cars:
		var cid = car.championship_id
		var cal = gs.CHAMPIONSHIP_CALENDARS.get(cid, [])
		race_weeks[car.id] = cal.map(func(r): return {"week": r["week"], "track_id": r.get("track_id","")})

	## Process each car in prestige order
	for car in sorted_cars:
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
		var disc = reg.get("discipline", "GK")
		var champ_name = reg.get("name", car.championship_id)
		var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
		var is_gk = (disc == "GK")
		var car_races = race_weeks.get(car.id, [])

		## ── Driver proposal ──────────────────────────────────────────────
		var best_driver = _find_best_driver_for_car(
			car, disc, avail_drivers, committed_drivers, car_races, is_gk)

		if best_driver != null:
			var eff_pace = _effective_stat(best_driver, disc, "pace")
			var adapt = best_driver.discipline_adaptation.get(disc, 0.0)
			var note = "Assign %s → %s [%s]  (Eff. pace: %.0f" % [
				best_driver.full_name(), car_label, champ_name, eff_pace]
			if adapt < 70.0:
				note += ", ⚠ Low discipline adaptation %.0f%%" % adapt
			elif adapt < 40.0:
				note += ", 🚨 Very low adaptation %.0f%% — DNS risk" % adapt
			note += ")"

			## Check if GK same-venue multi-assignment
			var already_assigned = committed_drivers.get(best_driver.id, [])
			var is_multi = already_assigned.size() > 0
			if is_multi:
				note = "⚡ " + note + "  ← also covering another GK tier (same venue)"

			proposals.append({
				"type":        "assign_driver",
				"car_id":      car.id,
				"car_label":   car_label,
				"champ_id":    car.championship_id,
				"champ_name":  champ_name,
				"driver_id":   best_driver.id,
				"driver_name": best_driver.full_name(),
				"eff_pace":    eff_pace,
				"adaptation":  adapt,
				"note":        note,
				"priority":    "normal" if adapt >= 70.0 else "warning",
			})

			## Mark committed for non-GK or GK with specific race weeks
			if not committed_drivers.has(best_driver.id):
				committed_drivers[best_driver.id] = []
			for race in car_races:
				committed_drivers[best_driver.id].append(race)
		else:
			## No driver available
			var dns_proposals = _build_dns_proposals(car_races, committed_drivers, avail_drivers)
			if dns_proposals.size() > 0:
				for dp in dns_proposals:
					proposals.append({
						"type":       "dns_warning",
						"car_id":     car.id,
						"car_label":  car_label,
						"champ_name": champ_name,
						"note":       "⚠ %s — no driver for Week %d (%s). Expected DNS." % [
							car_label, dp["week"], dp["track_id"]],
						"priority":   "warning",
					})
			else:
				proposals.append({
					"type":       "missing_driver",
					"car_id":     car.id,
					"car_label":  car_label,
					"champ_name": champ_name,
					"note":       "🚫 %s [%s] — no driver available. Hire one." % [car_label, champ_name],
					"priority":   "critical",
				})

		## ── Mechanic proposal ────────────────────────────────────────────
		var best_mech = _find_best_mechanic_for_car(
			car, disc, avail_mechanics, committed_mechanics, car_races, is_gk)

		if best_mech != null:
			var eff_setup = _effective_stat_staff(best_mech, disc, "car_setup")
			var adapt = best_mech.discipline_adaptation.get(disc, best_mech.discipline_adaptation.get("GK", 50.0)) \
				if best_mech.discipline_adaptation.has(disc) else 50.0
			var note = "Assign mechanic %s → %s [%s]  (Eff. setup: %.0f" % [
				best_mech.full_name(), car_label, champ_name, eff_setup]
			if adapt < 60.0:
				note += ", ⚠ Low adaptation %.0f%%" % adapt
			note += ")"

			proposals.append({
				"type":         "assign_mechanic",
				"car_id":       car.id,
				"car_label":    car_label,
				"champ_id":     car.championship_id,
				"champ_name":   champ_name,
				"mechanic_id":  best_mech.id,
				"mechanic_name": best_mech.full_name(),
				"eff_setup":    eff_setup,
				"note":         note,
				"priority":     "normal" if adapt >= 60.0 else "warning",
			})

			if not committed_mechanics.has(best_mech.id):
				committed_mechanics[best_mech.id] = []
			for race in car_races:
				committed_mechanics[best_mech.id].append(race)
		else:
			proposals.append({
				"type":       "missing_mechanic",
				"car_id":     car.id,
				"car_label":  car_label,
				"champ_name": champ_name,
				"note":       "🚫 %s [%s] — no mechanic available. Hire one." % [car_label, champ_name],
				"priority":   "critical",
			})

	## Fire notification and TDL based on proposal severity
	_fire_tp_proposal_notification(proposals)
	return proposals

## Returns effective stat value for a driver in a discipline


func _effective_stat(driver, disc: String, stat: String) -> float:
	var raw: float = 50.0
	match stat:
		"pace": raw = driver.pace
		"consistency": raw = driver.consistency
		"fitness": raw = driver.fitness
	var adapt = driver.discipline_adaptation.get(disc, 1.0)
	return raw * (adapt / 100.0)

## Returns effective stat for staff in a discipline


func _effective_stat_staff(staff, disc: String, stat: String) -> float:
	var raw: float = 50.0
	if stat == "car_setup" and "car_setup_skill" in staff: raw = staff.car_setup_skill
	elif stat == "car_setup" and "car_setup" in staff: raw = staff.car_setup
	var adapt = staff.discipline_adaptation.get(disc, 50.0) \
		if "discipline_adaptation" in staff and staff.discipline_adaptation.has(disc) else 50.0
	return raw * (adapt / 100.0)

## Finds the best available driver for a car, respecting GK multi-assignment and adaptation.


func _find_best_driver_for_car(car, disc: String, avail_drivers: Array,
		committed: Dictionary, car_races: Array, is_gk: bool):
	var best = null
	var best_score = -1.0
	for d in avail_drivers:
		## GK: same driver can cover multiple tiers if no different-track same-week conflict
		if is_gk:
			var conflict = false
			var d_committed = committed.get(d.id, [])
			for race in car_races:
				for comm_race in d_committed:
					if comm_race["week"] == race["week"] and comm_race["track_id"] != race["track_id"]:
						conflict = true; break
				if conflict: break
			if conflict: continue
		else:
			## Non-GK: driver can only cover one championship
			if committed.has(d.id) and committed[d.id].size() > 0: continue

		## Age eligibility
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
		if d.age < reg.get("min_age", 0) or d.age > reg.get("max_age", 99): continue

		var score = _effective_stat(d, disc, "pace") * 0.6 + \
			_effective_stat(d, disc, "consistency") * 0.4
		if score > best_score:
			best_score = score
			best = d
	return best

## Finds the best available mechanic for a car.


func _find_best_mechanic_for_car(car, disc: String, avail_mechanics: Array,
		committed: Dictionary, car_races: Array, is_gk: bool):
	var best = null
	var best_score = -1.0
	for s in avail_mechanics:
		if is_gk:
			var conflict = false
			var s_committed = committed.get(s.id, [])
			for race in car_races:
				for comm_race in s_committed:
					if comm_race["week"] == race["week"] and comm_race["track_id"] != race["track_id"]:
						conflict = true; break
				if conflict: break
			if conflict: continue
		else:
			if committed.has(s.id) and committed[s.id].size() > 0: continue
		var setup = s.car_setup_skill if "car_setup_skill" in s else \
			(s.car_setup if "car_setup" in s else 50.0)
		var adapt = s.discipline_adaptation.get(disc, 50.0) \
			if "discipline_adaptation" in s and s.discipline_adaptation.has(disc) else 50.0
		var score = setup * (adapt / 100.0)
		if score > best_score:
			best_score = score
			best = s
	return best

## Returns DNS-risk race weeks where a driver conflict means empty car.


func _build_dns_proposals(car_races: Array, committed: Dictionary, avail_drivers: Array) -> Array:
	var dns_weeks: Array = []
	for race in car_races:
		var can_cover = false
		for d in avail_drivers:
			var d_comm = committed.get(d.id, [])
			var has_conflict = false
			for comm_race in d_comm:
				if comm_race["week"] == race["week"] and comm_race["track_id"] != race["track_id"]:
					has_conflict = true; break
			if not has_conflict:
				can_cover = true; break
		if not can_cover:
			dns_weeks.append(race)
	return dns_weeks

## Fires notification and TDL for TP proposals.


func _fire_tp_proposal_notification(proposals: Array) -> void:
	if proposals.is_empty(): return
	var has_critical = proposals.any(func(p): return p.get("priority","") == "critical")
	var has_warning  = proposals.any(func(p): return p.get("priority","") == "warning")
	var driver_assigns = proposals.filter(func(p): return p["type"] == "assign_driver").size()
	var mech_assigns   = proposals.filter(func(p): return p["type"] == "assign_mechanic").size()

	var msg: String
	var priority: String
	if has_critical:
		msg = "🚫 TP: missing personnel — some cars cannot race. → Racing Department"
		priority = "Critical"
	elif has_warning:
		msg = "⚠ TP proposals: %d driver + %d mechanic (low adaptation warnings). → Racing Department" % [driver_assigns, mech_assigns]
		priority = "High"
	else:
		msg = "🏁 TP proposals ready: %d driver + %d mechanic assignments. → Racing Department" % [driver_assigns, mech_assigns]
		priority = "High"

	gs.add_notification(priority, msg, "racing_dept")
	## TDL item — routes to Racing Department via _get_todo_destination
	var tdl_msg = "🏁 TP has %d assignment%s ready — Racing Department" % [
		driver_assigns + mech_assigns,
		"s" if driver_assigns + mech_assigns != 1 else ""]
	gs.add_todo_item(tdl_msg)

## Applies a list of TP proposals — assigns drivers and mechanics to cars.
## Call after player reviews and accepts proposals in Racing Department.


func apply_tp_proposals(proposals: Array) -> void:
	for prop in proposals:
		match prop["type"]:
			"assign_driver":
				var car_id = prop.get("car_id","")
				var driver_id = prop.get("driver_id","")
				if car_id != "" and driver_id != "":
					gs.assign_driver_to_car(driver_id, car_id)
			"assign_mechanic":
				var car_id = prop.get("car_id","")
				var mech_id = prop.get("mechanic_id","")
				if car_id != "" and mech_id != "":
					gs.assign_staff_to_car(mech_id, car_id)
	## Dismiss the TDL item
	for item in gs.custom_todo_items.duplicate():
		if "TP proposals ready" in item or "TP proposals:" in item:
			gs.dismiss_todo_item(item)
	gs.emit_signal("log_updated")

## Returns all TP/Strategist assignment proposals for all active championships.
## GK: single TP for all 4 tiers combined (one proposal, not four).
## Non-GK: 1 TP + 1 Strategist per championship (where applicable).
## Only generates proposals if the player has a car registered to that championship.
## Reads active_championships (not player_registered_championships).


func get_tp_proposals_all() -> Array:
	var result: Array = []

	## GK: single shared TP for all 4 GK tiers
	var gk_active: Array = []
	for champ in gs.active_championships:
		if champ.discipline == "GK":
			gk_active.append(champ)

	if not gk_active.is_empty():
		## Check if player has any car in any GK tier
		var has_gk_car = false
		for car in gs.player_team_cars:
			for champ in gk_active:
				if car.championship_id == champ.id:
					has_gk_car = true; break
			if has_gk_car: break

		if has_gk_car:
			## GK driver/mechanic proposals from GKDiscipline (car-aware)
			if gs.gk_discipline != null:
				for prop in gs.gk_discipline.get_pending_proposals():
					result.append(prop)

			## Single GK TP check — is any TP assigned to any GK championship?
			var gk_tp_assigned = false
			for champ in gk_active:
				if gs._get_tp_for_championship(champ.id) != null:
					gk_tp_assigned = true; break
			if not gk_tp_assigned:
				var best_tp = _find_best_unassigned_staff_for_gk()
				if best_tp:
					result.append({
						"type":       "tp_assignment",
						"champ_id":   "GK",
						"champ_name": "GK Discipline (all tiers)",
						"role":       "Team Principal",
						"staff_id":   best_tp.id,
						"staff_name": best_tp.full_name(),
						"note":       "Assign %s as GK Team Principal (covers all GK tiers)" % best_tp.full_name(),
					})

	## Non-GK: 1 TP + 1 Strategist per championship
	for champ in gs.active_championships:
		if champ.discipline == "GK": continue

		## Only propose if player has a car for this championship
		var has_car = false
		for car in gs.player_team_cars:
			if car.championship_id == champ.id:
				has_car = true; break
		if not has_car: continue

		var reg = gs.CHAMPIONSHIP_REGISTRY.get(champ.id, {})

		## TP check — stored on Staff.assigned_championship
		if gs._get_tp_for_championship(champ.id) == null:
			var best_tp = _find_best_unassigned_staff("Team Principal", champ.id)
			if best_tp:
				result.append({
					"type":       "tp_assignment",
					"champ_id":   champ.id,
					"champ_name": champ.championship_name,
					"role":       "Team Principal",
					"staff_id":   best_tp.id,
					"staff_name": best_tp.full_name(),
					"note":       "Assign %s as Team Principal for %s" % [
						best_tp.full_name(), champ.championship_name],
				})

		## Strategist check (not for Rally)
		var disc = champ.discipline
		if disc != "Rally":
			var strat_assigned = false
			for sid in gs.all_staff:
				var s = gs.all_staff[sid]
				if s.contract_team != gs.player_team.id: continue
				if s.role != "Race Strategist": continue
				if s.assigned_championship == champ.id:
					strat_assigned = true; break
			if not strat_assigned:
				var best_strat = _find_best_unassigned_staff("Race Strategist", champ.id)
				if best_strat:
					result.append({
						"type":       "strategist_assignment",
						"champ_id":   champ.id,
						"champ_name": champ.championship_name,
						"role":       "Race Strategist",
						"staff_id":   best_strat.id,
						"staff_name": best_strat.full_name(),
						"note":       "Assign %s as Strategist for %s" % [
							best_strat.full_name(), champ.championship_name],
					})

	## Driver/mechanic unassigned car proposals (any discipline)
	for car in gs.player_team_cars:
		var champ_name = ""
		for champ in gs.active_championships:
			if champ.id == car.championship_id:
				champ_name = champ.championship_name; break
		if champ_name == "": continue
		var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
		if car.driver_id == "":
			result.append({
				"type":    "driver_needed",
				"champ_id": car.championship_id,
				"champ_name": champ_name,
				"car_id":  car.id,
				"note":    "Assign a driver to %s [%s]" % [car_label, champ_name],
			})
		if car.mechanic_id == "":
			result.append({
				"type":    "mechanic_needed",
				"champ_id": car.championship_id,
				"champ_name": champ_name,
				"car_id":  car.id,
				"note":    "Assign a mechanic to %s [%s]" % [car_label, champ_name],
			})

	return result

## Finds the best available TP for GK — not already assigned to a non-GK championship.


func _find_best_unassigned_staff_for_gk():
	var best = null
	var best_score = -1.0
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.contract_team != gs.player_team.id: continue
		if s.role != "Team Principal": continue
		## Not already assigned to a non-GK championship
		var already = false
		for champ in gs.active_championships:
			if champ.discipline == "GK": continue
			if s.assigned_championship == champ.id:
				already = true; break
		if already: continue
		var score = s.race_pace_reading if "race_pace_reading" in s else 50.0
		if score > best_score:
			best_score = score
			best = s
	return best

## Returns the best available (unassigned) staff member of a given role for a championship.


func _find_best_unassigned_staff(role: String, champ_id: String):
	var best = null
	var best_score = -1.0
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.contract_team != gs.player_team.id: continue
		if s.role != role: continue
		## Not already assigned to a different championship
		var already_assigned = false
		for champ in gs.active_championships:
			if champ.id == champ_id: continue
			if role == "Team Principal" and s.assigned_championship == champ.id:
				already_assigned = true; break
			if role == "Race Strategist" and s.assigned_championship == champ.id:
				already_assigned = true; break
		if already_assigned: continue
		## Direct property access — Staff is a Resource, not a Dictionary
		var score = s.race_pace_reading if "race_pace_reading" in s else 50.0
		if score > best_score:
			best_score = score
			best = s
	return best

## Checks weekly whether TP proposals should fire a notification + TDL item.
## Rules:
## 1. Any player car with no driver OR no mechanic within 2 weeks of a race → Critical alert.
##    No roster-change gate — this fires every week until fixed.
## 2. Season start (week 1): consolidated TP assignment suggestions for all championships.
## 3. GK weekly: fires if roster changed AND a GK race is ≤2 weeks away.


func _check_tp_proposal_notifications() -> void:
	## Check if any car is missing driver/mechanic within 2 weeks of a race
	## Bug 21 fix: only check player's registered championships
	for champ in gs.active_championships:
		if not champ.id in gs.player_registered_championships: continue
		var race = champ.get_next_race()
		if not race: continue
		var weeks_until = int(race["week"]) - gs.current_week
		if weeks_until < 0 or weeks_until > 2: continue
		for car in gs.player_team_cars:
			if car.championship_id != champ.id: continue
			var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			if car.driver_id == "":
				var msg = "🚫 %s [%s] — no driver. Race in %d week%s!" % [
					car_label, champ.championship_name, weeks_until,
					"s" if weeks_until != 1 else ""]
				gs.add_notification("Critical", msg, "garage")
				gs.add_todo_item(msg)
			if car.mechanic_id == "":
				var msg = "🚫 %s [%s] — no mechanic. Race in %d week%s!" % [
					car_label, champ.championship_name, weeks_until,
					"s" if weeks_until != 1 else ""]
				gs.add_notification("Critical", msg, "garage")
				gs.add_todo_item(msg)

	## Regenerate TP proposals only when player race is approaching
	var should_generate = false
	if gs.current_week == 1 and not gs.player_team_cars.is_empty():
		should_generate = true
	else:
		for champ in gs.active_championships:
			if not champ.id in gs.player_registered_championships: continue
			var race = champ.get_next_race()
			if race and (race["week"] - gs.current_week) <= 3:
				should_generate = true; break

	if should_generate and not gs.player_team_cars.is_empty():
		## Only regenerate if roster changed or proposals are empty
		if gs._last_tp_proposals.is_empty() or _tp_roster_changed():
			gs._last_tp_proposals = generate_tp_assignment_proposals()
			_tp_roster_snapshot = _take_tp_roster_snapshot()

## Returns true if driver/mechanic roster changed since last TP proposal generation.
var _tp_roster_snapshot: Dictionary = {}


func _take_tp_roster_snapshot() -> Dictionary:
	var snap: Dictionary = {}
	for did in gs.player_team.drivers:
		var d = gs.all_drivers.get(did)
		if d: snap[did] = d.age
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.contract_team == gs.player_team.id and s.role == "Race Mechanic":
			snap[sid] = s.contract_seasons_remaining
	for car in gs.player_team_cars:
		snap["car_%s" % car.id] = car.championship_id
	return snap


func _tp_roster_changed() -> bool:
	var current = _take_tp_roster_snapshot()
	if current.size() != _tp_roster_snapshot.size(): return true
	for key in current:
		if not key in _tp_roster_snapshot or current[key] != _tp_roster_snapshot[key]:
			return true
	return false

## Called whenever a car is bought/built or a driver/mechanic is hired.
## Immediately checks if any unassigned combinations exist and fires TDL items.
## This is the event-driven trigger — no weekly polling needed for these.


func _fire_assignment_proposals() -> void:
	var proposals = get_tp_proposals_all()
	for prop in proposals:
		var note = prop.get("note","")
		if note == "": continue
		## Only fire actionable assignment proposals, not GK ecosystem proposals
		var ptype = prop.get("type","")
		if ptype in ["driver_needed","mechanic_needed","tp_assignment","strategist_assignment"]:
			## Don't duplicate existing TDL items
			var already = false
			for t in gs.custom_todo_items:
				if t == note: already = true; break
			if not already and not note in gs.dismissed_todo_items:
				gs.add_todo_item(note)
				var priority = "Critical" if ptype in ["driver_needed","mechanic_needed"] else "High"
				gs.add_notification(priority, note,
					"garage" if ptype in ["driver_needed","mechanic_needed"] else "racing_dept")

## ── P44 LOAN SYSTEM (S21) ────────────────────────────────────────────────────

## Returns the max loan tier (1-5) unlocked by current HQ level.
## Tier 1: HQ L1+  Tier 2: HQ L3+  Tier 3: HQ L6+  Tier 4: HQ L9+  Tier 5: HQ L12+
