class_name TPProposalEngine
## Version: S32.2 — TP system rebuild (spec v2), Phase 1 engine + path reconciliation. Shared
##   compute_optimal_assignments(team, cars, include_tp): driver/mechanic/pit(raw)/strategist
##   (per champ, GK+Rally skip)/TP(per champ, AI-only, sorted by overall). Prestige-ordered,
##   adaptation-corrected (except pit crew), commitment (one person → one championship; GK
##   multi-tier exception removed). apply_tp_proposals routes per-car vs per-championship and
##   re-optimises on partial accept. _fire_assignment_proposals now routes through the SINGLE
##   consolidated path (was the separate get_tp_proposals_all → duplicate TDL items).
##   get_tp_proposals_all retained as dead code (no internal callers) pending full removal.
## --- S31.3 — Fix: apply_tp_proposals now dismisses the TP TDL item by matching its
##   ACTUAL text ("TP has … ready"); the old filter looked for "TP proposals ready"/"TP
##   proposals:" which the item never contained, so it was never removed. (Keeps the S31.1
##   bug-4 roster-snapshot refresh.)
## --- S31.1 — Bug 4: apply_tp_proposals now refreshes _tp_roster_snapshot after
##   accepting, so accepted proposals don't reappear on the next weekly tick (stale
##   snapshot was making _tp_roster_changed() fire and regenerate them).
## --- S28.3 — apply_tp_proposals() regenerates the proposal cache so the Racing Dept
##   count refreshes to 0 after accepting (issue 5: was showing stale proposals).
## --- S27.0 — Extracted from GameState.gd (P57)
##   TP auto-assignment proposals: driver/mechanic matching, DNS warnings,
##   cross-discipline adaptation, proposal notification and application.
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

## Player entry point — produces the consolidated proposal for the player's team (driver,
## mechanic, pit crew, strategist; NOT TP — player manages TPs manually) and fires the single
## notification + TDL. Delegates to the shared, team-agnostic optimiser.
func generate_tp_assignment_proposals() -> Array:
	var proposals = compute_optimal_assignments(gs.player_team, gs.player_team_cars, false)
	_fire_tp_proposal_notification(proposals)
	return proposals

## Shared, team-agnostic optimiser. Computes the optimal allocation for ANY team:
##   • driver, mechanic, pit crew  → per CAR
##   • strategist, Team Principal   → per CHAMPIONSHIP
## Prestige-ordered (best → highest-prestige championship/car first), adaptation-corrected
## stats (except pit crew = raw), commitment rule (one person → one championship).
## Exceptions: pit crew skipped for GK; strategist skipped for GK & Rally.
## include_tp=false for the player surface (TP is manual); true for AI auto-assign.
## Pure: no side effects — callers decide (player → proposal UI; AI → apply directly).
func compute_optimal_assignments(team, team_cars: Array, include_tp: bool) -> Array:
	var proposals: Array = []

	## Sort the team's cars by championship prestige (highest first)
	var sorted_cars: Array = team_cars.duplicate()
	sorted_cars.sort_custom(func(a, b):
		return _prestige_score(a.championship_id) > _prestige_score(b.championship_id))

	## Commitment: one person → one championship. Once committed, removed from the pool for
	## all lower-prestige cars/championships. Simple set keyed by person id.
	var committed: Dictionary = {}   ## person_id → true

	## Available personnel on THIS team
	var avail_drivers: Array = []
	for did in team.drivers:
		var d = gs.all_drivers.get(did)
		if d: avail_drivers.append(d)

	var avail_mechanics: Array = []
	var avail_pit: Array = []
	var avail_strategists: Array = []
	var avail_tps: Array = []
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.contract_team != team.id:
			continue
		match s.role:
			"Race Mechanic":   avail_mechanics.append(s)
			"Pit Crew":        avail_pit.append(s)
			"Race Strategist": avail_strategists.append(s)
			"Team Principal":  avail_tps.append(s)

	## ── Per-CAR roles: driver, mechanic, pit crew (prestige order) ──────────────
	for car in sorted_cars:
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
		var disc = reg.get("discipline", "GK")
		var champ_name = reg.get("name", car.championship_id)
		var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
		var pit_required = gs.get_pit_crew_required(car.championship_id)

		## Driver
		var best_driver = _find_best_driver(car, disc, avail_drivers, committed)
		if best_driver != null:
			var eff = _eff_driver_score(best_driver, disc)
			var adapt = best_driver.discipline_adaptation.get(disc, 0.0)
			var note = "Assign %s → %s [%s]  (Eff. pace: %.0f" % [
				best_driver.full_name(), car_label, champ_name, eff]
			if adapt < 40.0:   note += ", 🚨 Very low adaptation %.0f%% — DNS risk" % adapt
			elif adapt < 70.0: note += ", ⚠ Low adaptation %.0f%%" % adapt
			note += ")"
			proposals.append(_mk(car, "assign_driver", "car", best_driver.id,
				best_driver.full_name(), eff, note, "normal" if adapt >= 70.0 else "warning"))
			committed[best_driver.id] = true
		else:
			proposals.append(_mk(car, "missing_driver", "car", "", "", 0.0,
				"🚫 %s [%s] — no driver available. Hire one." % [car_label, champ_name], "critical"))

		## Mechanic
		var best_mech = _find_best_mechanic(car, disc, avail_mechanics, committed)
		if best_mech != null:
			var eff = _eff_mechanic_score(best_mech, disc)
			var adapt = best_mech.discipline_adaptation.get(disc, 50.0) \
				if best_mech.discipline_adaptation.has(disc) else 50.0
			var note = "Assign mechanic %s → %s [%s]  (Eff. setup: %.0f%s)" % [
				best_mech.full_name(), car_label, champ_name, eff,
				", ⚠ Low adaptation %.0f%%" % adapt if adapt < 60.0 else ""]
			proposals.append(_mk(car, "assign_mechanic", "car", best_mech.id,
				best_mech.full_name(), eff, note, "normal" if adapt >= 60.0 else "warning"))
			committed[best_mech.id] = true
		else:
			proposals.append(_mk(car, "missing_mechanic", "car", "", "", 0.0,
				"🚫 %s [%s] — no mechanic available. Hire one." % [car_label, champ_name], "critical"))

		## Pit crew (not required for GK)
		if pit_required:
			var best_pit = _find_best_pit_crew(avail_pit, committed)
			if best_pit != null:
				var score = best_pit.pit_stop_speed   ## RAW — pit crew has no adaptation
				var note = "Assign pit crew %s → %s [%s]  (Pit speed: %.0f)" % [
					best_pit.full_name(), car_label, champ_name, score]
				proposals.append(_mk(car, "assign_pit_crew", "car", best_pit.id,
					best_pit.full_name(), score, note, "normal"))
				committed[best_pit.id] = true
			else:
				proposals.append(_mk(car, "missing_pit_crew", "car", "", "", 0.0,
					"🚫 %s [%s] — no pit crew available. Hire one." % [car_label, champ_name], "critical"))

	## ── Per-CHAMPIONSHIP roles: strategist, (TP if include_tp) ──────────────────
	## One per championship the team races, prestige order, commitment-respecting.
	var champ_ids: Array = []
	for car in sorted_cars:
		if not car.championship_id in champ_ids:
			champ_ids.append(car.championship_id)

	for cid in champ_ids:
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var disc = reg.get("discipline", "GK")
		var champ_name = reg.get("name", cid)

		## Strategist — NOT used in GK or Rally
		if disc != "GK" and disc != "Rally":
			var best_strat = _find_best_strategist(disc, avail_strategists, committed)
			if best_strat != null:
				var eff = _eff_strategist_score(best_strat, disc)
				var note = "Assign strategist %s → [%s]  (Eff. strategy: %.0f)" % [
					best_strat.full_name(), champ_name, eff]
				proposals.append(_mk_champ(cid, champ_name, "assign_strategist", best_strat.id,
					best_strat.full_name(), eff, note, "normal"))
				committed[best_strat.id] = true
			else:
				proposals.append(_mk_champ(cid, champ_name, "missing_strategist", "", "", 0.0,
					"🚫 [%s] — no strategist available. Hire one." % champ_name, "warning"))

		## Team Principal — AI only (player manages TPs manually)
		if include_tp:
			var best_tp = _find_best_tp(disc, avail_tps, committed)
			if best_tp != null:
				var eff = _eff_tp_score(best_tp, disc)
				var note = "Assign TP %s → [%s]  (Overall: %.0f)" % [
					best_tp.full_name(), champ_name, eff]
				proposals.append(_mk_champ(cid, champ_name, "assign_tp", best_tp.id,
					best_tp.full_name(), eff, note, "normal"))
				committed[best_tp.id] = true

	return proposals

## ── Helpers: prestige, proposal builders, scoring, finders ────────────────────

func _prestige_score(champ_id: String) -> float:
	var reg = gs.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var disc = reg.get("discipline", "GK")
	var tier = reg.get("tier", 1)
	return gs.DISC_PRESTIGE.get(disc, 1) * 10 + tier

## Build a per-CAR proposal object.
func _mk(car, ptype: String, scope: String, pid: String, pname: String,
		eff: float, note: String, priority: String) -> Dictionary:
	var reg = gs.CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
	return {
		"kind": "assignment", "type": ptype, "scope": scope,
		"car_id": car.id,
		"car_label": car.car_name if car.car_name != "" else "Car %d" % car.car_number,
		"champ_id": car.championship_id, "champ_name": reg.get("name", car.championship_id),
		"person_id": pid, "person_name": pname,
		"eff_score": eff, "note": note, "priority": priority,
	}

## Build a per-CHAMPIONSHIP proposal object (strategist / TP).
func _mk_champ(cid: String, champ_name: String, ptype: String, pid: String, pname: String,
		eff: float, note: String, priority: String) -> Dictionary:
	return {
		"kind": "assignment", "type": ptype, "scope": "championship",
		"car_id": "", "champ_id": cid, "champ_name": champ_name,
		"person_id": pid, "person_name": pname,
		"eff_score": eff, "note": note, "priority": priority,
	}

## Role-appropriate scoring (per the design: each role scored on its performance-driving
## stat(s); only TP uses an overall aggregate). Adaptation applies to all except pit crew.
func _eff_driver_score(d, disc: String) -> float:
	return _effective_stat(d, disc, "pace") * 0.6 + _effective_stat(d, disc, "consistency") * 0.4

func _eff_mechanic_score(s, disc: String) -> float:
	return _effective_stat_staff(s, disc, "car_setup")

func _eff_strategist_score(s, disc: String) -> float:
	var raw = s.race_strategy if "race_strategy" in s else 50.0
	var adapt = s.discipline_adaptation.get(disc, 50.0) \
		if "discipline_adaptation" in s and s.discipline_adaptation.has(disc) else 50.0
	return raw * (adapt / 100.0)

func _eff_tp_score(s, disc: String) -> float:
	var raw = s.get_overall_skill()
	var adapt = s.discipline_adaptation.get(disc, 50.0) \
		if "discipline_adaptation" in s and s.discipline_adaptation.has(disc) else 50.0
	return raw * (adapt / 100.0)

## Finders — pick the highest-scoring uncommitted, age/role-eligible candidate.
func _find_best_driver(car, disc: String, avail: Array, committed: Dictionary):
	var best = null
	var best_score = -1.0
	var reg = gs.CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
	for d in avail:
		if committed.has(d.id):
			continue
		if d.age < reg.get("min_age", 0) or d.age > reg.get("max_age", 99):
			continue
		var score = _eff_driver_score(d, disc)
		if score > best_score:
			best_score = score; best = d
	return best

func _find_best_mechanic(car, disc: String, avail: Array, committed: Dictionary):
	var best = null
	var best_score = -1.0
	for s in avail:
		if committed.has(s.id):
			continue
		var score = _eff_mechanic_score(s, disc)
		if score > best_score:
			best_score = score; best = s
	return best

func _find_best_pit_crew(avail: Array, committed: Dictionary):
	var best = null
	var best_score = -1.0
	for s in avail:
		if committed.has(s.id):
			continue
		var score = s.pit_stop_speed   ## RAW — no adaptation
		if score > best_score:
			best_score = score; best = s
	return best

func _find_best_strategist(disc: String, avail: Array, committed: Dictionary):
	var best = null
	var best_score = -1.0
	for s in avail:
		if committed.has(s.id):
			continue
		var score = _eff_strategist_score(s, disc)
		if score > best_score:
			best_score = score; best = s
	return best

func _find_best_tp(disc: String, avail: Array, committed: Dictionary):
	var best = null
	var best_score = -1.0
	for s in avail:
		if committed.has(s.id):
			continue
		var score = _eff_tp_score(s, disc)
		if score > best_score:
			best_score = score; best = s
	return best


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


## Fires notification and TDL for TP proposals.


func _fire_tp_proposal_notification(proposals: Array) -> void:
	if proposals.is_empty(): return
	var has_critical = proposals.any(func(p): return p.get("priority","") == "critical")
	var has_warning  = proposals.any(func(p): return p.get("priority","") == "warning")
	## Count all assignable roles (driver/mechanic/pit crew/strategist).
	var assign_types = ["assign_driver", "assign_mechanic", "assign_pit_crew", "assign_strategist"]
	var total_assigns = proposals.filter(func(p): return p.get("type","") in assign_types).size()

	var msg: String
	var priority: String
	if has_critical:
		msg = "🚫 TP: missing personnel — some cars cannot race. → Racing Department"
		priority = "Critical"
	elif has_warning:
		msg = "⚠ TP proposals: %d assignment%s (some low-adaptation). → Racing Department" % [
			total_assigns, "s" if total_assigns != 1 else ""]
		priority = "High"
	else:
		msg = "🏁 TP proposals ready: %d assignment%s. → Racing Department" % [
			total_assigns, "s" if total_assigns != 1 else ""]
		priority = "High"

	gs.add_notification(priority, msg, "racing_dept")
	## ONE TDL item, identifiable by the "TP has … ready" text (dismissed in apply_tp_proposals).
	var tdl_msg = "🏁 TP has %d assignment%s ready — Racing Department" % [
		total_assigns, "s" if total_assigns != 1 else ""]
	gs.add_todo_item(tdl_msg)

## Applies a list of TP proposals — assigns drivers and mechanics to cars.
## Call after player reviews and accepts proposals in Racing Department.


func apply_tp_proposals(proposals: Array) -> void:
	for prop in proposals:
		var pid = prop.get("person_id", "")
		var car_id = prop.get("car_id", "")
		var champ_id = prop.get("champ_id", "")
		match prop.get("type", ""):
			"assign_driver":
				if car_id != "" and pid != "":
					gs.assign_driver_to_car(pid, car_id)
			"assign_mechanic":
				if car_id != "" and pid != "":
					gs.assign_staff_to_car(pid, car_id)
			"assign_pit_crew":
				if car_id != "" and pid != "":
					gs.assign_pit_crew_to_car(pid, car_id)
			"assign_strategist", "assign_tp":
				## Per-championship roles set the staff member's assigned_championship.
				if champ_id != "" and pid != "":
					gs.assign_staff_to_championship(pid, champ_id)
	## Dismiss the TP TDL item(s) by their actual text (see _fire_tp_proposal_notification).
	for item in gs.custom_todo_items.duplicate():
		if "TP has" in item or "TP proposals" in item:
			gs.dismiss_todo_item(item)
	## Partial accept = re-optimise: regenerate proposals for the remaining unassigned cars/
	## championships over the now-reduced pool (accepted personnel are committed because they're
	## now assigned, so the optimiser won't re-propose them). This drops accepted items and
	## surfaces a fresh smaller proposal — the single source of truth.
	gs._last_tp_proposals = generate_tp_assignment_proposals()
	## Bug 4: refresh the roster snapshot to the post-accept state so the next advance_week
	## doesn't see a phantom roster change and regenerate the just-accepted proposals.
	_tp_roster_snapshot = _take_tp_roster_snapshot()
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
	## Event-driven trigger (car bought/built, staff hired/lost). Routes through the SINGLE
	## consolidated proposal path: regenerate the optimal proposal (driver/mechanic/pit/
	## strategist), store it as the source of truth, and fire ONE notification + ONE TDL via
	## generate_tp_assignment_proposals. (Previously used the separate get_tp_proposals_all,
	## which produced duplicate TDL items overlapping the consolidated proposal.)
	if gs.player_team_cars.is_empty():
		return
	gs._last_tp_proposals = generate_tp_assignment_proposals()
	_tp_roster_snapshot = _take_tp_roster_snapshot()

## ── P44 LOAN SYSTEM (S21) ────────────────────────────────────────────────────

## Returns the max loan tier (1-5) unlocked by current HQ level.
## Tier 1: HQ L1+  Tier 2: HQ L3+  Tier 3: HQ L6+  Tier 4: HQ L9+  Tier 5: HQ L12+
