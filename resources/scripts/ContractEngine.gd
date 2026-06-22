class_name ContractEngine
## Version: S35.0 — Season Transition Pipeline support. Added effective_join_season(ap): the single
##   named definition of WHEN a pre-signing lands (= signed_season + 1), so the rest of the engine
##   reasons about an ABSOLUTE target season instead of the fragile relative string "next_season"
##   (the string-replay was the root of the old "bounces back, never joins" Stage-B bug).
##   _activate_presigned_contracts now gates on this helper. No new stored state: signed_season
##   stays the single source of truth (no parallel field to drift out of sync); the helper only
##   NAMES the derived value. Behaviour identical to S34.0; this is a clarity/contract change that
##   the reordered SeasonManager.start_new_season (S35.0) relies on.
## Version: S34.0 — Bond negotiation rebuilt to GDD §12-A. (1) The S33.3 auto-accept regression
##   is removed: initiate_approach no longer pre-fills the player's bond offer at the estimate
##   (which made the team auto-accept and skipped the whole negotiation). A contracted approach
##   now goes out as bond_status="awaiting_team"; the owner team names its opening ask next week
##   via new _generate_team_bond_ask() (premium 1.0–1.25× of estimate), routed through
##   bond_status="countered" so the existing Accept|Counter|Reject UI handles the player's reply.
##   (2) Free-agent-at-join-date check: a contract expiring before the join date (incl. last-season
##   next-season signings) needs no bond. (3) Immediate-transfer disruption fee (1.5×+25%) now
##   fires for ANY mid-contract immediate join (weeks_remaining > 0), not only > 1 season left.
## Version: S33.3 — Two contract-flow fixes. (1) Bond approach now progresses: the initial
##   approach to a contracted subject's team sets bond_status="offered" (+bond_round=1) so the
##   weekly _advance_approaches bond branch fires next week and the team replies (previously it
##   sat at approaching/pending forever). (2) Pre-signed season slip fixed: _apply_approach_result
##   now stamps signed_season=current_season when marking pre_signed (it didn't before, so the
##   activation gate fell back to default=current_season and the join slipped a season —
##   signed S1 joined S3 instead of S2). Person joins at signed_season + 1.
## Version: S33.2 — Canonical SLOT rule + early-join fix. (1) _get_max_slots_for_role now derives
##   every cap from BUILDING LEVEL, not car count: Mechanic=Garage, Pit Crew=Pit Crew Arena,
##   Strategist=Ops Sim & Telemetry, Designer=R&D Studio, TP=HQ, CFO=1 (slots = hiring capacity;
##   car/championship needs are a separate assignment check). Fixes next-season negotiation being
##   blocked at rollover (cars=0 no longer means 0 mechanic/pit slots). (2) _activate_presigned_
##   contracts() now season-gated (current_season > signed_season) so a mid-season level-up no
##   longer makes a pre-signed driver/staff join early; removed the redundant weekly activation.
## Version: S33.1 — FIX: next-season (pre-signed) contracts were unreliable — some signed
##   immediately, some never joined. Root cause: start_date lived in TWO unsynced fields
##   (top-level ap.start_date, read by _apply_approach_result; and ap.terms.start_date.player_offer,
##   set by the UI dropdown + read at activation). Fixes: (1) submit syncs top-level from the
##   dropdown term; (2) "Accept all" no longer overwrites the player's start_date choice with
##   their_ask; (3) activation forces start_date="immediate" + _presigned bypass so the pre-signed
##   contract actually applies and isn't blocked by a roster-full guard. Debug prints removed.
## --- S33.0 — TP Phase 2: team-scoped _get_tp_for_championship_team()/_get_strategist_for_championship_team()
##   (player-scoped getters now thin wrappers). Lets the optimiser detect already-assigned
##   championship roles for AI teams.
## --- S27.0 — Extracted from GameState.gd (P57 Phase 4)
##   _get_strategist_for_championship_team(); the original player-scoped getters are now thin
##   wrappers passing player_team.id (callers unchanged). Lets the shared optimiser detect
##   already-assigned championship roles for AI teams.
## --- S27.0 — Extracted from GameState.gd (P57 Phase 4)
##   Owns all contract negotiation: approach/bond system, opening offers,
##   weekly negotiation rounds, sponsor negotiations, contract application.
##   Called by GameState via wrapper functions.
extends RefCounted

## Reference to the main GameState node — all data lives there.
var gs  # GameState reference (untyped to avoid circular dependency)


func _init(game_state) -> void:
	gs = game_state


## ── Opening offer generation ─────────────────────────────────────────────────

## Generate the opening offer for a Driver contract negotiation.
## Returns a Dictionary with all contract terms at the driver's "ask" level.
func generate_driver_opening_offer(driver_id: String) -> Dictionary:
	var driver = gs.all_drivers.get(driver_id)
	if driver == null: return {}
	var skill = driver.get_overall_skill()
	var tier = _get_active_championship_tier()
	## Base weekly salary: skill-scaled, tier-adjusted
	var base_sal = _calc_driver_ask_salary(skill, tier)
	## Bonus asks: scale with skill
	var win_ask       = int(base_sal * 52 * clamp(skill / 100.0, 0.1, 1.0) * 0.6)
	var podium_ask    = int(win_ask * 0.35)
	var champ_ask     = int(win_ask * 1.5)
	var release_ask   = int(base_sal * 52 * 0.8)
	## Duration: better drivers want shorter contracts (more options)
	var duration_ask  = 3 if skill >= 70 else (2 if skill >= 50 else 1)
	## CFO improves our opening position
	var cfo = gs.get_cfo()
	var cfo_bonus = (cfo.sponsor_negotiation / 100.0) * 0.15 if cfo else 0.0
	return {
		"subject_id":    driver_id,
		"subject_type":  "driver",
		"round":         1,
		"max_rounds":    randi_range(3, 5),
		"their_ask": {
			"weekly_salary":        base_sal,
			"win_bonus":            win_ask,
			"podium_bonus":         podium_ask,
			"championship_bonus":   champ_ask,
			"release_clause":       release_ask,
			"duration_seasons":     duration_ask,
		},
		"player_offer": {
			"weekly_salary":        round(base_sal * (0.75 - cfo_bonus)),
			"win_bonus":            round(win_ask * 0.5),
			"podium_bonus":         round(podium_ask * 0.5),
			"championship_bonus":   round(champ_ask * 0.5),
			"release_clause":       round(release_ask * 0.5),
			"duration_seasons":     duration_ask,
		},
		"status":  "active",  ## active | accepted | rejected
		"history": [],
		"cfo_bonus": cfo_bonus,
	}

## Generate opening offer for a Staff contract.
func generate_staff_opening_offer(staff_id: String) -> Dictionary:
	var staff = gs.all_staff.get(staff_id)
	if staff == null: return {}
	var skill = staff.get_primary_skill()
	var salary_range = gs.STAFF_BASE_SALARIES.get(staff.role, {"min": 200.0, "max": 500.0})
	var ask_sal = salary_range["min"] + (salary_range["max"] - salary_range["min"]) * (skill / 100.0)
	## If this is a currently hired staff we're renewing, their existing salary is the floor
	if staff.contract_team == gs.player_team.id:
		ask_sal = max(ask_sal, staff.weekly_salary * 1.05)
	var champ_ask   = int(ask_sal * 52 * 0.3)
	var perf_ask    = int(ask_sal * 52 * 0.2)
	var release_ask = int(ask_sal * 52 * 0.6)
	var duration_ask = 3 if skill >= 70 else (2 if skill >= 50 else 1)
	var cfo = gs.get_cfo()
	var cfo_bonus = (cfo.sponsor_negotiation / 100.0) * 0.15 if cfo else 0.0
	return {
		"subject_id":    staff_id,
		"subject_type":  "staff",
		"round":         1,
		"max_rounds":    randi_range(3, 5),
		"their_ask": {
			"weekly_salary":      ask_sal,
			"championship_bonus": champ_ask,
			"performance_bonus":  perf_ask,
			"release_clause":     release_ask,
			"duration_seasons":   duration_ask,
		},
		"player_offer": {
			"weekly_salary":      round(ask_sal * (0.75 - cfo_bonus)),
			"championship_bonus": round(champ_ask * 0.5),
			"performance_bonus":  round(perf_ask * 0.5),
			"release_clause":     round(release_ask * 0.5),
			"duration_seasons":   duration_ask,
		},
		"status":   "active",
		"history":  [],
		"cfo_bonus": cfo_bonus,
	}

## Wrap an existing staff/driver contract into an approach-style dict
## so renegotiation can use open_approach() with lock support.
func make_renegotiation_approach(subject_id: String, subject_type: String) -> Dictionary:
	var neg: Dictionary
	if subject_type == "driver":
		neg = generate_driver_opening_offer(subject_id)
	else:
		neg = generate_staff_opening_offer(subject_id)
	if neg.is_empty(): return {}

	var name_str = _get_subject_display_name(subject_id, subject_type)
	var ap = {
		"neg_id":            "reneg_%s_%d_%d" % [subject_id, gs.current_season, gs.current_week],
		"type":              "renegotiation",
		"subject_id":        subject_id,
		"subject_type":      subject_type,
		"subject_name":      name_str,
		"current_team_id":   gs.player_team.id,
		"current_team_name": gs.player_team.team_name,
		"approaching_team":  gs.player_team.id,
		"needs_bond":        false,
		"bond_status":       "agreed",  ## No bond for own staff
		"start_date":        "immediate",
		"contract_round":    1,
		"max_contract_rounds": neg["max_rounds"],
		"last_action_week":  gs.current_week,
		"patience_weeks":    3,
		"locked_fields":     [],
		"player_turn":       true,
		"status":            "negotiating",
		"terms":             {},
		"their_current_ask": {},
	}
	for key in neg["their_ask"]:
		ap["terms"][key] = {
			"their_ask":    neg["their_ask"][key],
			"player_offer": neg["player_offer"][key],
			"locked":       false,
			"agreed":       false,
		}
	ap["their_current_ask"] = neg["their_ask"].duplicate()
	gs.active_approaches.append(ap)
	gs.emit_signal("approach_updated")
	return ap

## Generate opening offer for a Sponsor (counter-offer negotiation).
func generate_sponsor_negotiation(sponsor_id: String) -> Dictionary:
	## Look in active_sponsors (renegotiating an existing deal)
	var offer = null
	for sp in gs.active_sponsors:
		if sp.get("sponsor_id","") == sponsor_id:
			offer = sp; break
	## Fall back to pending offers (negotiating a new offer)
	if offer == null:
		for o in gs.sponsor_offers:
			if o.get("sponsor_id","") == sponsor_id:
				offer = o; break
	if offer == null: return {}
	var cfo = gs.get_cfo()
	var cfo_bonus = (cfo.sponsor_negotiation / 100.0) * 0.2 if cfo else 0.0
	var base: Dictionary = {}
	match offer.get("type", 1):
		1: base = {"weekly_payment": offer.get("weekly_payment", 0), "seasons_remaining": offer.get("seasons_remaining", 1)}
		2: base = {"win_bonus": offer.get("win_bonus", 0), "podium_bonus": offer.get("podium_bonus", 0),
				"season_bonus": offer.get("season_bonus", 0), "seasons_remaining": offer.get("seasons_remaining", 1)}
		3: base = {"commitment_total": offer.get("commitment_total", 0), "seasons_remaining": offer.get("seasons_remaining", 1)}
	var player_counter = {}
	for k in base:
		if k == "seasons_remaining":
			player_counter[k] = base[k]
		elif k.ends_with("_total") or k.ends_with("_payment") or k.ends_with("_bonus"):
			player_counter[k] = int(base[k] * (1.0 + cfo_bonus))
	return {
		"subject_id":   sponsor_id,
		"subject_type": "sponsor",
		"round":        1,
		"max_rounds":   randi_range(2, 4),
		"their_ask":    base,
		"player_offer": player_counter,
		"status":       "active",
		"history":      [],
		"cfo_bonus":    cfo_bonus,
		"offer_data":   offer,
	}

## Wrap a sponsor negotiation into approach format so HQ can use open_approach() with locks.
func make_sponsor_approach(sponsor_id: String) -> Dictionary:
	var neg = generate_sponsor_negotiation(sponsor_id)
	if neg.is_empty(): return {}
	var offer = neg["offer_data"]
	var ap = {
		"neg_id":            "sponsor_%s_%d_%d" % [sponsor_id, gs.current_season, gs.current_week],
		"type":              "sponsor_negotiation",
		"subject_id":        sponsor_id,
		"subject_type":      "sponsor",
		"subject_name":      offer.get("name", "Sponsor"),
		"current_team_id":   "",
		"current_team_name": "",
		"approaching_team":  gs.player_team.id,
		"needs_bond":        false,
		"bond_status":       "agreed",
		"start_date":        "immediate",
		"contract_round":    1,
		"max_contract_rounds": neg["max_rounds"],
		"last_action_week":  gs.current_week,
		"patience_weeks":    3,
		"locked_fields":     [],
		"player_turn":       true,
		"status":            "negotiating",
		"terms":             {},
		"their_current_ask": {},
		"sponsor_type":      offer.get("type", 1),
		"offer_data":        offer,
	}
	for key in neg["their_ask"]:
		ap["terms"][key] = {
			"their_ask":    neg["their_ask"][key],
			"player_offer": neg["player_offer"].get(key, neg["their_ask"][key]),
			"locked":       false,
			"agreed":       false,
		}
	ap["their_current_ask"] = neg["their_ask"].duplicate()
	gs.active_approaches.append(ap)
	gs.emit_signal("approach_updated")
	return ap

## ── Negotiation flow ─────────────────────────────────────────────────────────

## Start a negotiation. Stores state in active_negotiation.
func start_negotiation(neg: Dictionary) -> void:
	if not "locked_fields" in neg: neg["locked_fields"] = []
	gs.active_negotiation = neg
	gs.emit_signal("negotiation_updated")

## Player submits their current offer. Returns the outcome.
## outcome: "accepted" | "counter" | "rejected" | "waiting"
## "waiting" means offer submitted but counter arrives next week (1 round per week rule).
func submit_negotiation_offer(player_offer: Dictionary) -> String:
	if gs.active_negotiation.is_empty(): return "rejected"
	## Enforce 1-round-per-week: if counter is pending, block resubmission until next week
	if gs.active_negotiation.get("waiting_week", 0) > gs.current_week:
		return "waiting"
	gs.active_negotiation["player_offer"] = player_offer
	gs.active_negotiation["history"].append({
		"round": gs.active_negotiation["round"],
		"player": player_offer.duplicate(),
		"their": gs.active_negotiation["their_ask"].duplicate(),
	})
	var outcome = _evaluate_offer(gs.active_negotiation)
	gs.active_negotiation["round"] += 1
	if outcome == "accepted" or gs.active_negotiation["round"] > gs.active_negotiation["max_rounds"]:
		if outcome != "accepted":
			outcome = "rejected"
		else:
			## Pre-validate slot availability before declaring accepted
			var start_date = gs.active_negotiation.get("player_offer", {}).get("start_date", "immediate")
			if start_date == "immediate":
				var stype = gs.active_negotiation.get("subject_type", "")
				if stype == "driver":
					var max_d = gs.get_max_drivers()
					var d = gs.all_drivers.get(gs.active_negotiation.get("subject_id",""))
					if d and d.contract_team == "" and gs.player_team.drivers.size() >= max_d:
						## Slots full — reject with specific outcome
						gs.active_negotiation["status"] = "rejected"
						gs.active_negotiation["waiting_week"] = 0
						gs.emit_signal("negotiation_concluded", false,
							gs.active_negotiation["subject_id"], gs.active_negotiation["subject_type"])
						gs.add_notification("High",
							"Deal fell through — no driver slots available for immediate signing. Sign for next season instead.")
						gs.active_negotiation = {}
						gs.emit_signal("log_updated")
						return "no_slot"
				elif stype == "staff":
					var s = gs.all_staff.get(gs.active_negotiation.get("subject_id",""))
					if s and s.contract_team == "" and s.role == "Team Principal":
						if gs.get_player_staff_by_role("Team Principal").size() >= gs.get_hq_tp_slots():
							gs.active_negotiation["status"] = "rejected"
							gs.active_negotiation["waiting_week"] = 0
							gs.emit_signal("negotiation_concluded", false,
								gs.active_negotiation["subject_id"], gs.active_negotiation["subject_type"])
							gs.add_notification("High", "Deal fell through — TP slots full. Sign for next season.")
							gs.active_negotiation = {}
							gs.emit_signal("log_updated")
							return "no_slot"
		gs.active_negotiation["status"] = outcome
		gs.active_negotiation["waiting_week"] = 0
		_apply_negotiation_result(gs.active_negotiation, outcome == "accepted")
		gs.emit_signal("negotiation_concluded", outcome == "accepted",
			gs.active_negotiation["subject_id"], gs.active_negotiation["subject_type"])
	else:
		## Counter arrives next week — gate further submission
		gs.active_negotiation["waiting_week"] = gs.current_week + 1
		_apply_counter_offer(gs.active_negotiation)
		gs.emit_signal("negotiation_updated")
		return "counter"
	return outcome

## Walk away — player ends negotiation.
## Subjects who walked away from negotiation — unavailable for N seasons
## Format: { subject_id: season_available_again }
var walked_away_subjects: Dictionary = {}

func abandon_negotiation() -> void:
	if gs.active_negotiation.is_empty(): return
	var subject_id   = gs.active_negotiation.get("subject_id", "")
	var subject_type = gs.active_negotiation.get("subject_type", "")
	## Mark unavailable for 2 seasons — also add to dismissed so TDL clears
	if subject_id != "":
		gs.walked_away_subjects[subject_id] = gs.current_season + 2
		var name_str = _get_subject_display_name(subject_id, subject_type)
		gs.add_notification("Normal", "%s is no longer interested for 2 seasons." % name_str)
		## Dismiss any TDL items referencing this subject
		for item in gs.custom_todo_items.duplicate():
			if name_str in item:
				gs.dismiss_todo_item(item)
	gs.active_negotiation["status"] = "rejected"
	gs.emit_signal("negotiation_concluded", false, subject_id, subject_type)
	gs.active_negotiation = {}
	gs.emit_signal("log_updated")

func is_subject_available(subject_id: String) -> bool:
	if subject_id not in gs.walked_away_subjects: return true
	return gs.current_season >= gs.walked_away_subjects[subject_id]

# ══════════════════════════════════════════════════════════════════════════════
# APPROACH / BOND / WEEKLY NEGOTIATION SYSTEM  (S18)
# ══════════════════════════════════════════════════════════════════════════════

## ── Data structure ────────────────────────────────────────────────────────────
## Creates a new approach record. subject_type: "driver" | "staff"
func _make_approach(subject_id: String, subject_type: String,
		current_team_id: String, start_date: String) -> Dictionary:
	var name_str = _get_subject_display_name(subject_id, subject_type)
	var current_team_name = ""
	for t in gs.all_teams:
		if t.id == current_team_id: current_team_name = t.team_name; break
	return {
		"neg_id":            "%s_%d_%d" % [subject_id, gs.current_season, gs.current_week],
		"type":              "approach",
		"subject_id":        subject_id,
		"subject_type":      subject_type,
		"subject_name":      name_str,
		"current_team_id":   current_team_id,
		"current_team_name": current_team_name,
		"approaching_team":  gs.player_team.id,

		## Interest check
		"interest_checked":  false,
		"subject_interested": false,

		## Bond phase (skipped for free agents or last-season contracts)
		"needs_bond":         current_team_id != "",
		"bond_estimate":      0.0,
		"bond_player_offer":  0.0,
		"bond_team_ask":      0.0,
		"bond_round":         0,     ## 0=not started, 1=awaiting reply, 2=counter reply
		"bond_reply_week":    0,
		"bond_status":        "pending",  ## pending|awaiting_team|offered|countered|agreed|rejected

		## Contract negotiation phase
		"start_date":         start_date,  ## "immediate" | "next_season"
		"contract_round":     0,
		"max_contract_rounds": randi_range(3, 5),
		"last_action_week":   gs.current_week,
		"patience_weeks":     3,
		"terms":              {},   ## populated when contract phase starts
		"their_current_ask":  {},
		"locked_fields":      [],   ## fields both sides have agreed on

		"status": "interest_check",
		## interest_check → approaching → bond_offered → bond_countered
		## → negotiating → agreed → failed → rejected → expired
	}

## ── Interest check ────────────────────────────────────────────────────────────
## Returns true if the subject is willing to be approached.
## Uses hidden talent + rep gap + TP reputation.
func _check_subject_interest(subject_id: String, subject_type: String,
		current_team_id: String) -> bool:
	var talent = 50.0
	if subject_type == "driver":
		var d = gs.all_drivers.get(subject_id)
		if d: talent = d.potential if d.potential > 0 else 50.0
	else:
		var s = gs.all_staff.get(subject_id)
		if s: talent = s.talent if s.talent > 0 else 50.0

	var base_chance = talent * 0.5 + 50.0

	## Reputation gap: subject wants to move up, not down
	var their_team_rep = 50.0
	for t in gs.all_teams:
		if t.id == current_team_id:
			their_team_rep = t.reputation if t.has_method("get_reputation") else 50.0
			break
	var rep_gap = gs.player_team.reputation - their_team_rep
	var rep_mod = clamp(rep_gap * 0.5, -25.0, 25.0)

	## TP modifier
	var tp_mod = 0.0
	for champ in gs.active_championships:
		var tp = _get_tp_for_championship(champ.id)
		if tp:
			tp_mod = max(tp_mod, tp.reputation * 0.3)
			break

	var final_chance = clamp(base_chance + rep_mod + tp_mod, 1.0, 100.0)
	return randf() * 100.0 < final_chance

## ── Bond estimate ─────────────────────────────────────────────────────────────
## Returns the CFO's estimate of what the bond should cost.
## No hard limits — this is informational only.
func get_bond_estimate(subject_id: String, subject_type: String,
		start_date: String) -> Dictionary:
	var weekly_sal = 0.0
	var weeks_remaining = 0
	var talent = 50.0

	if subject_type == "driver":
		var d = gs.all_drivers.get(subject_id)
		if d:
			weekly_sal = d.weekly_salary if d.weekly_salary > 0 else _calc_driver_ask_salary(
				d.get_overall_skill(), _get_active_championship_tier())
			weeks_remaining = d.contract_seasons_remaining * 52
			talent = d.potential if d.potential > 0 else 50.0
	else:
		var s = gs.all_staff.get(subject_id)
		if s:
			weekly_sal = s.weekly_salary if s.weekly_salary > 0 else 300.0
			weeks_remaining = s.contract_seasons_remaining * 52
			talent = s.talent if s.talent > 0 else 50.0

	## If next season signing, weeks = from season start not from now
	if start_date == "next_season":
		weeks_remaining = max(0, weeks_remaining - (gs.max_weeks - gs.current_week))

	## Talent factor
	var talent_factor = 0.8
	if talent > 80:   talent_factor = 1.8
	elif talent > 60: talent_factor = 1.3
	elif talent > 30: talent_factor = 1.0

	var raw_estimate = weekly_sal * float(weeks_remaining) * talent_factor

	## CFO accuracy
	var cfo = gs.get_cfo()
	var accuracy = 0.30 if cfo == null else 0.08
	var lo = raw_estimate * (1.0 - accuracy)
	var hi = raw_estimate * (1.0 + accuracy)

	## Immediate transfer while still under contract = 1.5× bond + 25% disruption fee
	## (GDD §12-A step 3). "Mid-contract" = any time remaining at an immediate join, not only
	## more than one season. Rare and expensive by design; most signings are next-season.
	if start_date == "immediate" and weeks_remaining > 0:
		raw_estimate *= 1.5 * 1.25
		lo *= 1.5 * 1.25
		hi *= 1.5 * 1.25

	return {
		"estimate":  int(raw_estimate),
		"low":       int(lo),
		"high":      int(hi),
		"accuracy":  accuracy,
		"has_cfo":   cfo != null,
	}

## ── Slot projection ───────────────────────────────────────────────────────────
## Returns { "now": int, "next_season": int } available slots for drivers or staff role.
func get_slot_projection(subject_type: String, role: String = "") -> Dictionary:
	var now_used = 0
	var now_max = 0
	var next_used = 0
	var next_max = 0

	if subject_type == "driver":
		now_used = gs.player_team.drivers.size()
		now_max = gs.get_max_drivers()
		## Next season: subtract expiring contracts
		var expiring = 0
		for d_id in gs.player_team.drivers:
			var d = gs.all_drivers.get(d_id)
			if d and d.contract_seasons_remaining <= 1: expiring += 1
		next_used = now_used - expiring
		next_max = now_max
	else:
		var all_hired = gs.get_player_staff_by_role(role)
		now_used = all_hired.size()
		now_max = _get_max_slots_for_role(role)
		var expiring = 0
		for s in all_hired:
			if s.contract_seasons_remaining <= 1: expiring += 1
		next_used = now_used - expiring
		next_max = now_max

	return {
		"now_used":    now_used,
		"now_max":     now_max,
		"now_free":    now_max - now_used,
		"next_used":   next_used,
		"next_max":    next_max,
		"next_free":   next_max - next_used,
	}

func _get_max_slots_for_role(role: String) -> int:
	## CANONICAL RULE (GDD): SLOTS come from BUILDINGS (hiring capacity), independent of cars.
	## Assignments (car needs 1 mechanic / 1 pit crew; championship needs 1 TP / 1 strategist)
	## are a SEPARATE downstream check — never the hiring cap. Building level = number of slots.
	match role:
		"Team Principal":  return gs.get_hq_tp_slots()
		"CFO":             return 1
		"Race Mechanic":   return max(1, gs.campus_buildings.get("Garage", {}).get("level", 1))
		"Race Strategist": return max(1, gs.campus_buildings.get("Ops Sim & Telemetry", {}).get("level", 1))
		"Designer":
			var bld = gs.campus_buildings.get("R&D Design Studio", {})
			return max(1, bld.get("level", 1))
		"Pit Crew":        return max(1, gs.campus_buildings.get("Pit Crew Arena", {}).get("level", 1))
	return 1

## Player-scoped wrappers (unchanged signature — existing callers keep working).
func _get_tp_for_championship(champ_id: String):
	return _get_tp_for_championship_team(champ_id, gs.player_team.id)

func _get_strategist_for_championship(champ_id: String):
	return _get_strategist_for_championship_team(champ_id, gs.player_team.id)

## S33.0 — Team-scoped variants. Needed so the shared optimiser can detect an
## already-assigned championship role for ANY team (AI auto-assign), not just the player.
func _get_tp_for_championship_team(champ_id: String, team_id: String):
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.role == "Team Principal" and s.contract_team == team_id \
				and s.assigned_championship == champ_id:
			return s
	return null

func _get_strategist_for_championship_team(champ_id: String, team_id: String):
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.role == "Race Strategist" and s.contract_team == team_id \
				and s.assigned_championship == champ_id:
			return s
	return null

## ── Initiate approach ─────────────────────────────────────────────────────────
## Called when player clicks Approach on a driver or staff member.
## Requires a TP assigned to an active championship.
## Returns "" on success, or an error string.
func initiate_approach(subject_id: String, subject_type: String,
		start_date: String) -> String:
	## Already approaching this person?
	for ap in gs.active_approaches:
		if ap["subject_id"] == subject_id and ap["status"] not in ["agreed","failed","rejected","expired"]:
			return "You already have an active approach for this person."

	var current_team_id = ""
	var is_free_agent = false
	if subject_type == "driver":
		var d = gs.all_drivers.get(subject_id)
		if d == null: return "Driver not found."
		if d.contract_team == gs.player_team.id: return "Already on your team."
		current_team_id = d.contract_team
		is_free_agent = (current_team_id == "")
	else:
		var s = gs.all_staff.get(subject_id)
		if s == null: return "Staff not found."
		if s.contract_team == gs.player_team.id: return "Already on your team."
		current_team_id = s.contract_team
		is_free_agent = (current_team_id == "")

	## TP required ONLY for bond approach (contracted staff/drivers) — not free agents
	if not is_free_agent:
		var has_tp = false
		for champ in gs.active_championships:
			if _get_tp_for_championship(champ.id) != null:
				has_tp = true; break
		if not has_tp:
			return "Assign a Team Principal before approaching contracted staff or drivers."

	## Interest check — hidden roll
	var interested = _check_subject_interest(subject_id, subject_type, current_team_id)

	if not interested:
		var name_str = _get_subject_display_name(subject_id, subject_type)
		## TP hint
		var tp_hint = ""
		for champ in gs.active_championships:
			var tp = _get_tp_for_championship(champ.id)
			if tp:
				tp_hint = " %s's assessment: not the right time." % tp.full_name()
				break
		gs.add_notification("Normal",
			"%s is not interested in joining your team at this time.%s" % [name_str, tp_hint])
		gs.add_log("📋 Approach to %s: declined (not interested)." % name_str)
		return "not_interested"

	var ap = _make_approach(subject_id, subject_type, current_team_id, start_date)
	ap["interest_checked"] = true
	ap["subject_interested"] = true

	var name_str = _get_subject_display_name(subject_id, subject_type)

	## GDD §12-A step 2: determine contract status AT THE JOIN DATE, not now. A person whose
	## contract expires before the join date is a free agent THEN — no bond. For a next-season
	## join, anyone in their last season (<=1 season remaining) has expired by season start.
	var free_at_join: bool = (current_team_id == "")
	if not free_at_join:
		var seasons_left := 0
		if subject_type == "driver":
			var d = gs.all_drivers.get(subject_id)
			if d: seasons_left = d.contract_seasons_remaining
		else:
			var s = gs.all_staff.get(subject_id)
			if s: seasons_left = s.contract_seasons_remaining
		if start_date == "next_season" and seasons_left <= 1:
			free_at_join = true   ## last season → expired by next-season join → no bond

	if free_at_join:
		## Free agent at join date — skip bond, go straight to contract negotiation
		ap["status"] = "negotiating"
		ap["needs_bond"] = false
		_start_contract_phase(ap)
		var fa_note: String = "free agent" if current_team_id == "" else "contract expires before joining"
		gs.add_log("📋 Approach to %s (%s) — no bond, contract negotiation begins." % [name_str, fa_note])
		gs.add_notification("Normal", "%s is interested! Contract negotiation begins (no buyout needed)." % name_str)
	else:
		## Contracted at join date — bond negotiation with the OWNER TEAM (GDD §12-A step 3).
		## The team replies NEXT WEEK with its opening ask; the player then accepts / counters /
		## rejects. We do NOT pre-fill the player's offer (that auto-accepted and skipped the
		## whole negotiation — the S33.3 regression). bond_status "awaiting_team" means the
		## approach has been sent and we're waiting for the team to name its price.
		var bond_info = get_bond_estimate(subject_id, subject_type, start_date)
		ap["bond_estimate"] = bond_info["estimate"]
		ap["bond_reply_week"] = gs.current_week + 1
		ap["status"] = "approaching"
		ap["bond_status"] = "awaiting_team"
		ap["bond_round"] = 0
		gs.add_log("📋 Approach sent to %s's team. CFO estimate: CR %s (±%d%%). Their team replies next week." % [
			name_str, gs._fmt_int(bond_info["estimate"]), int(bond_info["accuracy"] * 100.0)])
		gs.add_notification("Normal",
			"Approach sent for %s. Their team will name a buyout price next week." % name_str,
			"drivers" if subject_type == "driver" else "staff_hub")

	gs.active_approaches.append(ap)
	gs.emit_signal("approach_updated")
	return ""

## ── Send bond offer ───────────────────────────────────────────────────────────
## Player sets their bond offer amount and sends it.
func send_bond_offer(neg_id: String, offer_amount: float) -> void:
	var ap = _get_approach(neg_id)
	if ap == null or ap["status"] != "approaching": return
	ap["bond_player_offer"] = offer_amount
	ap["bond_round"] = 1
	ap["bond_reply_week"] = gs.current_week + 1
	ap["bond_status"] = "offered"
	gs.emit_signal("approach_updated")

## Player responds to a bond counter from the other team.
func respond_bond_counter(neg_id: String, accept: bool, counter_amount: float = 0.0) -> void:
	var ap = _get_approach(neg_id)
	if ap == null or ap["bond_status"] != "countered": return
	if accept:
		ap["bond_status"] = "agreed"
		ap["bond_amount_final"] = ap["bond_team_ask"]
		ap["status"] = "negotiating"
		_start_contract_phase(ap)
		var name_str = ap["subject_name"]
		gs.add_notification("Normal",
			"Bond agreed for %s (CR %s). Contract negotiation begins." % [
			name_str, gs._fmt_int(int(ap["bond_team_ask"]))])
		gs.emit_signal("approach_updated")
	elif counter_amount > 0:
		ap["bond_player_offer"] = counter_amount
		ap["bond_round"] = 2
		ap["bond_reply_week"] = gs.current_week + 1
		ap["bond_status"] = "offered"
		gs.emit_signal("approach_updated")
	else:
		ap["bond_status"] = "rejected"
		ap["status"] = "rejected"
		gs.add_notification("Normal", "Bond negotiation with %s's team failed." % ap["subject_name"])
		gs.emit_signal("approach_updated")

## ── Player's own staff approached by AI ──────────────────────────────────────
## Called when AI approaches one of the player's contracted personnel.
func handle_incoming_approach(subject_id: String, subject_type: String,
		ai_team_id: String, ai_team_name: String, proposed_bond: float) -> void:
	var neg_id = "incoming_%s_%d_%d" % [subject_id, gs.current_season, gs.current_week]
	var ap = {
		"neg_id":            neg_id,
		"type":              "bond_incoming",
		"subject_id":        subject_id,
		"subject_type":      subject_type,
		"subject_name":      _get_subject_display_name(subject_id, subject_type),
		"current_team_id":   gs.player_team.id,
		"current_team_name": gs.player_team.team_name,
		"approaching_team":  ai_team_id,
		"approaching_team_name": ai_team_name,
		"bond_team_ask":     proposed_bond,
		"bond_player_offer": proposed_bond,
		"bond_status":       "incoming",
		"status":            "bond_incoming",
		"reply_due_week":    gs.current_week + 1,
	}
	gs.active_approaches.append(ap)
	gs.emit_signal("approach_updated")
	gs.add_notification("High",
		"%s (%s) wants to approach %s. Proposed bond: CR %s — respond in HQ." % [
		ai_team_name, ai_team_id,
		_get_subject_display_name(subject_id, subject_type),
		gs._fmt_int(int(proposed_bond))], "hq")

## Player responds to an incoming approach for their own staff.
func respond_incoming_approach(neg_id: String, accept: bool, counter_amount: float = 0.0) -> void:
	var ap = _get_approach(neg_id)
	if ap == null or ap["type"] != "bond_incoming": return
	if accept:
		ap["bond_status"] = "agreed"
		ap["status"] = "agreed"
		## Bond payment comes to player team
		var bond = ap["bond_team_ask"]
		gs.player_team.balance += bond
		gs.add_log("💰 Bond received: CR %s for %s transfer." % [gs._fmt_int(int(bond)), ap["subject_name"]])
		gs.add_notification("Normal",
			"Bond accepted: CR %s received for %s." % [gs._fmt_int(int(bond)), ap["subject_name"]])
		## The subject will leave at the agreed start_date — handled in advance_week
	elif counter_amount > 0:
		ap["bond_team_ask"] = counter_amount
		ap["bond_status"] = "countered"
		ap["reply_due_week"] = gs.current_week + 1
		gs.add_notification("Normal", "Counter-bond sent for %s. Awaiting reply." % ap["subject_name"])
	else:
		ap["status"] = "rejected"
		gs.add_notification("Normal", "Approach for %s rejected." % ap["subject_name"])
	gs.emit_signal("approach_updated")

## ── Contract phase ────────────────────────────────────────────────────────────
## Populates terms from the existing generate_X_opening_offer logic.
func _start_contract_phase(ap: Dictionary) -> void:
	var neg: Dictionary
	if ap["subject_type"] == "driver":
		neg = generate_driver_opening_offer(ap["subject_id"])
	else:
		neg = generate_staff_opening_offer(ap["subject_id"])
	if neg.is_empty(): return
	## Add start_date and lock support to terms
	ap["terms"] = {}
	for key in neg["their_ask"]:
		ap["terms"][key] = {
			"their_ask":    neg["their_ask"][key],
			"player_offer": neg["player_offer"][key],
			"locked":       false,
			"agreed":       false,
		}
	ap["their_current_ask"] = neg["their_ask"].duplicate()
	ap["max_contract_rounds"] = neg["max_rounds"]
	ap["contract_round"] = 1
	ap["last_action_week"] = gs.current_week
	ap["locked_fields"] = []
	ap["player_turn"] = true  ## Round 1: player opens first
	## Add start_date as a lockable term
	ap["terms"]["start_date"] = {
		"their_ask":    ap["start_date"],
		"player_offer": ap["start_date"],
		"locked":       false,
		"agreed":       false,
	}

## Player submits a contract offer with per-field values and lock states.
func submit_approach_contract_offer(neg_id: String,
		field_offers: Dictionary, locked_fields: Array) -> String:
	var ap = _get_approach(neg_id)
	if ap == null or ap["status"] != "negotiating": return "error"

	## Update player offers and locks
	for key in field_offers:
		if key in ap["terms"]:
			ap["terms"][key]["player_offer"] = field_offers[key]
	## S33.1: the dropdown writes start_date into the TERM; keep the top-level ap.start_date
	## in step with it, or _apply_approach_result reads the stale opened-with value and signs
	## immediately instead of next-season.
	if "start_date" in field_offers:
		ap["start_date"] = field_offers["start_date"]
	ap["locked_fields"] = locked_fields
	for key in locked_fields:
		if key in ap["terms"]:
			ap["terms"][key]["locked"] = true

	ap["last_action_week"] = gs.current_week
	ap["player_turn"] = false  ## Waiting for their reply — not the player's turn until next week

	## Evaluate BEFORE incrementing round — round shown is the round just played
	var outcome = _evaluate_approach_offer(ap)

	if outcome == "accepted":
		ap["status"] = "agreed"
		_apply_approach_result(ap)
		gs.emit_signal("approach_updated")
		return "accepted"
	elif outcome == "rejected" or ap["contract_round"] >= ap["max_contract_rounds"]:
		ap["status"] = "failed"
		var name_str = ap["subject_name"]
		gs.add_notification("Normal", "Contract negotiations with %s have broken down." % name_str)
		gs.emit_signal("approach_updated")
		return "rejected"
	else:
		## Counter — do NOT increment round here. Round advances when they reply next week.
		## _advance_approaches will increment contract_round and set player_turn=true.
		_apply_approach_counter(ap)
		gs.emit_signal("approach_updated")
		return "counter"

## Accept all their current asks outright.
func accept_approach_terms(neg_id: String) -> void:
	var ap = _get_approach(neg_id)
	if ap == null or ap["status"] != "negotiating": return
	for key in ap["terms"]:
		## S33.1: start_date is the player's qualitative choice (Immediate / Next-Season),
		## never the AI's "ask" — preserve it. Overwriting it with their_ask is what made a
		## next-season pick silently become immediate on "Accept all".
		if key == "start_date": continue
		ap["terms"][key]["player_offer"] = ap["terms"][key]["their_ask"]
	ap["status"] = "agreed"
	_apply_approach_result(ap)
	gs.emit_signal("approach_updated")

func walk_away_approach(neg_id: String) -> void:
	var ap = _get_approach(neg_id)
	if ap == null: return
	ap["status"] = "rejected"
	gs.walked_away_subjects[ap["subject_id"]] = gs.current_season + 2
	gs.add_notification("Normal",
		"You walked away from negotiations with %s." % ap["subject_name"])
	gs.emit_signal("approach_updated")

## ── Evaluate approach offer ───────────────────────────────────────────────────
func _evaluate_approach_offer(ap: Dictionary) -> String:
	var total_ratio = 0.0
	var count = 0
	for key in ap["terms"]:
		if key in ["start_date"]: continue  ## start_date is qualitative, handle separately
		var term = ap["terms"][key]
		if term.get("locked", false) or term.get("agreed", false): continue
		var ask = float(term["their_ask"])
		if ask <= 0: continue
		var offer = float(term["player_offer"])
		## For salary/bonuses: ratio = offer/ask (they want MORE, player offers LESS is bad)
		## For duration: they want LONGER, player offering less is bad
		total_ratio += clamp(offer / ask, 0.0, 1.0)
		count += 1
	if count == 0: return "accepted"
	var ratio = total_ratio / float(count)
	var round_n = ap["contract_round"]
	var max_r = ap["max_contract_rounds"]
	## Threshold tightens from 0.85 (round 1) to 0.70 (final round)
	var threshold = lerp(0.85, 0.70, float(round_n - 1) / float(max(max_r - 1, 1)))
	if ratio >= threshold: return "accepted"
	if ratio < 0.35 and round_n >= max_r - 1: return "rejected"
	return "counter"

func _apply_approach_counter(ap: Dictionary) -> void:
	var progress = float(ap["contract_round"]) / float(ap["max_contract_rounds"])
	for key in ap["terms"]:
		var term = ap["terms"][key]
		if term["locked"] or term["agreed"] or key in ["duration_seasons","start_date"]: continue
		var ask = float(term["their_ask"])
		var offer = float(term["player_offer"])
		if ask <= 0: continue
		var gap = ask - offer
		if gap > 0:
			var concession = gap * 0.10 * progress
			ap["terms"][key]["their_ask"] = max(offer, ask - concession)

## ── Apply agreed approach result ──────────────────────────────────────────────
func _apply_approach_result(ap: Dictionary) -> void:
	var subject_id = ap["subject_id"]
	var subject_type = ap["subject_type"]
	var start_date = ap.get("start_date", "immediate")
	var name_str = ap["subject_name"]

	## Pay bond if there was one
	if ap.get("bond_status", "") == "agreed" and ap.get("bond_amount_final", 0) > 0:
		var bond = ap["bond_amount_final"]
		gs.player_team.balance -= bond
		gs.add_log("💰 Bond paid: CR %s to %s for %s." % [
			gs._fmt_int(int(bond)), ap["current_team_name"], name_str])

	if start_date == "next_season":
		## Queue for next season — don't apply yet
		ap["type"] = "pre_signed"
		## S33.3 FIX: stamp the season this was signed IN. Without it, activation's gate
		## (current_season > signed_season) fell back to default=current_season, so the join
		## slipped one extra season (signed S1 → joined S3 instead of S2). signed_season is the
		## CURRENT season; the person joins at signed_season + 1.
		ap["signed_season"] = gs.current_season
		ap["status"] = "agreed"
		gs.add_log("✅ %s pre-signed — joins Season %d." % [name_str, gs.current_season + 1])
		gs.add_notification("Normal",
			"%s pre-signed and will join at the start of Season %d." % [name_str, gs.current_season + 1],
			"hq")
		return

	## Sponsor renegotiation — update existing active_sponsor in place
	if ap.get("type") == "sponsor_negotiation":
		for sp in gs.active_sponsors:
			if sp.get("sponsor_id","") == subject_id:
				for key in ap["terms"]:
					if key in sp: sp[key] = ap["terms"][key]["player_offer"]
				break
		gs.add_log("🤝 Sponsor deal renegotiated: %s." % name_str)
		gs.add_notification("Normal", "Sponsor deal with %s updated." % name_str, "hq")
		gs.emit_signal("log_updated")
		return

	## Immediate — apply contract now using existing _apply_negotiation_result
	var fake_neg = {
		"subject_id":   subject_id,
		"subject_type": subject_type,
		"player_offer": {},
	}
	for key in ap["terms"]:
		fake_neg["player_offer"][key] = ap["terms"][key]["player_offer"]
	_apply_negotiation_result(fake_neg, true)

## ── Weekly advance hooks ──────────────────────────────────────────────────────
## Called from advance_week() to process all active approaches.
func _advance_approaches() -> void:
	var changed = false
	for ap in gs.active_approaches:
		if ap["status"] in ["agreed","failed","rejected","expired"]: continue

		## ── Bond phase: owner team names its opening ask (GDD §12-A step 3) ──
		if ap["type"] == "approach" and ap["status"] == "approaching" \
				and ap.get("bond_status", "") == "awaiting_team" \
				and gs.current_week >= ap["bond_reply_week"]:
			_generate_team_bond_ask(ap)
			changed = true

		## ── Bond phase: waiting for team reply to a player offer ────────────
		elif ap["type"] == "approach" and ap["status"] == "approaching" \
				and ap["bond_status"] == "offered" \
				and gs.current_week >= ap["bond_reply_week"]:
			_process_bond_reply(ap)
			changed = true

		## ── Incoming bond: player hasn't replied ────────────────────────────
		elif ap["type"] == "bond_incoming" and ap["status"] == "bond_incoming" \
				and gs.current_week >= ap.get("reply_due_week", 0):
			## Auto-reject after 2 weeks of silence
			if gs.current_week >= ap.get("reply_due_week", 0) + 2:
				ap["status"] = "rejected"
				gs.add_notification("Normal",
					"Incoming approach for %s auto-rejected (no response)." % ap["subject_name"])
				changed = true

		## ── Contract negotiation: patience / round advancement ──────────────
		elif ap["status"] == "negotiating":
			var weeks_silent = gs.current_week - ap["last_action_week"]

			if weeks_silent >= ap["patience_weeks"]:
				## Player ignored too long — expired
				ap["status"] = "expired"
				gs.add_notification("High",
					"Negotiations with %s have expired — no response given." % ap["subject_name"])
				changed = true

			elif weeks_silent >= 1:
				if ap.get("player_turn", true):
					## Player's turn but hasn't responded — remind them, don't advance round
					## Just update last_action_week so we don't fire every week
					ap["last_action_week"] = gs.current_week
					gs.add_notification("High",
						"Reminder: Contract Round %d/%d with %s — respond from HQ." % [
						ap["contract_round"], ap["max_contract_rounds"], ap["subject_name"]], "hq")
					changed = true
				else:
					## Player submitted, other side has had time to reply — advance round
					ap["contract_round"] = min(ap["contract_round"] + 1, ap["max_contract_rounds"])
					_apply_approach_counter(ap)
					ap["player_turn"] = true
					ap["last_action_week"] = gs.current_week
					if ap["contract_round"] >= ap["max_contract_rounds"]:
						ap["status"] = "failed"
						gs.add_notification("Normal",
							"Contract negotiations with %s have concluded without a deal." % ap["subject_name"])
					else:
						gs.add_notification("High",
							"Contract Round %d/%d with %s — respond from HQ." % [
							ap["contract_round"], ap["max_contract_rounds"], ap["subject_name"]], "hq")
					changed = true

		## ── Pre-signed: activation is handled by _activate_presigned_contracts() below,
		## which is season-gated (only fires once current_season > signed_season). No per-week
		## handling here — that previously caused double-apply / early-join. ──────────────

	## Activate pre-signed contracts at season start (called from start_new_season too)
	_activate_presigned_contracts()

	if changed:
		gs.emit_signal("approach_updated")

## S35.0 — The single, named definition of WHEN a pre-signing takes effect.
## A pre-signing is stamped signed_season = the season it was struck in; the person joins
## the FOLLOWING season. Expressing this as one helper (rather than scattering
## "signed_season + 1" / "current_season > signed_season" inline) means the whole pipeline
## reasons about one absolute target season — the timing-independent fact the owner asked for.
## signed_season remains the only STORED field (no parallel state to drift); this just names it.
func effective_join_season(ap: Dictionary) -> int:
	return int(ap.get("signed_season", gs.current_season)) + 1

func _activate_presigned_contracts() -> void:
	for ap in gs.active_approaches:
		if ap.get("type") == "pre_signed" and ap.get("status") == "agreed":
			## S35.0: activate once we have actually reached the join season (absolute check via
			## the named helper). Equivalent to the old (current_season <= signed_season → skip)
			## guard, but expressed against the target season so the intent is unambiguous.
			## This prevents a mid-season slot opening (Racing-Dept/Garage level-up) from
			## activating a pre-signing early — they wait for their effective join season.
			if gs.current_season < effective_join_season(ap):
				continue
			var fake_neg = {
				"subject_id":   ap["subject_id"],
				"subject_type": ap["subject_type"],
				"player_offer": {},
			}
			for key in ap["terms"]:
				fake_neg["player_offer"][key] = ap["terms"][key]["player_offer"]
			## S33.1 FIX: the stored term still says start_date="next_season" (that's what made
			## this a pre-signing). Passing it through makes _apply_negotiation_result re-take
			## the next_season branch, re-queue the approach, and return WITHOUT joining the
			## person — the signing silently never lands. It IS next season now, so force
			## immediate so the contract applies for real. _presigned bypasses the "roster full"
			## immediate-block (the player already committed this slot).
			fake_neg["player_offer"]["start_date"] = "immediate"
			fake_neg["_presigned"] = true
			_apply_negotiation_result(fake_neg, true)
			ap["status"] = "activated"

## ── Owner team names its opening buyout ask (GDD §12-A step 3) ─────────────────
## Fired the week after the player's approach. The owner team values its personnel at the
## true bond (the estimate is the player-facing approximation), with a small premium and
## variance, then presents that ask. We route through bond_status="countered" so the existing
## bond-response UI (Accept | Counter | Reject) and respond_bond_counter() handle the player's
## reply — no new UI needed. This is the team's security: the player must meet a real price.
func _generate_team_bond_ask(ap: Dictionary) -> void:
	var estimate: float = float(ap.get("bond_estimate", 0))
	## Team asks at a premium over the player-visible estimate, with variance so it isn't
	## perfectly predictable. Range ~1.0×–1.25× of the estimate.
	var premium := 1.0 + randf() * 0.25
	var ask := int(round(estimate * premium))
	ap["bond_team_ask"] = ask
	ap["bond_status"] = "countered"
	ap["bond_round"] = 1
	ap["bond_reply_week"] = gs.current_week + 1
	gs.add_log("💰 %s's team will release them for CR %s. Accept, counter, or walk away." % [
		ap["subject_name"], gs._fmt_int(ask)])
	gs.add_notification("High",
		"%s's team wants CR %s to let them go. Decide from %s." % [
			ap["subject_name"], gs._fmt_int(ask),
			"Drivers" if ap["subject_type"] == "driver" else "Staff"],
		"drivers" if ap["subject_type"] == "driver" else "staff_hub")
	gs.emit_signal("approach_updated")

## ── Bond reply from AI team ───────────────────────────────────────────────────
func _process_bond_reply(ap: Dictionary) -> void:
	## AI team decision: accept, counter, or reject
	## Simple AI: if offer >= 80% of estimate, accept; 50-80% counter; <50% reject
	var estimate = ap["bond_estimate"]
	var offer = ap["bond_player_offer"]
	var ratio = offer / max(estimate, 1.0)

	if ratio >= 0.80:
		ap["bond_status"] = "agreed"
		ap["bond_amount_final"] = offer
		ap["status"] = "negotiating"
		_start_contract_phase(ap)
		gs.add_notification("Normal",
			"%s's team accepted the bond (CR %s). Contract negotiation begins." % [
			ap["subject_name"], gs._fmt_int(int(offer))],
			"drivers" if ap["subject_type"] == "driver" else "staff_hub")
	elif ratio >= 0.50 and ap["bond_round"] < 2:
		## Counter: ask for estimate × 1.1
		ap["bond_team_ask"] = int(estimate * 1.1)
		ap["bond_status"] = "countered"
		ap["bond_round"] += 1
		ap["bond_reply_week"] = gs.current_week + 1
		gs.add_notification("High",
			"%s's team countered: CR %s for the bond. Accept, counter or reject in Drivers/Staff Hub." % [
			ap["subject_name"], gs._fmt_int(int(ap["bond_team_ask"]))],
			"drivers" if ap["subject_type"] == "driver" else "staff_hub")
	else:
		ap["bond_status"] = "rejected"
		ap["status"] = "rejected"
		gs.add_notification("Normal",
			"%s's team rejected the bond offer." % ap["subject_name"])

## ── Helpers ───────────────────────────────────────────────────────────────────
func _get_approach(neg_id: String) -> Dictionary:
	for ap in gs.active_approaches:
		if ap["neg_id"] == neg_id: return ap
	return {}

func _get_approach_by_subject(subject_id: String) -> Dictionary:
	for ap in gs.active_approaches:
		if ap["subject_id"] == subject_id and \
				ap["status"] not in ["failed","rejected","expired","activated"]:
			return ap
	return {}

## Remove an approach that was opened but never submitted (Round 1, player_turn=true).
## Called when player closes the popup without making any offer.
func cancel_approach_before_submit(neg_id: String) -> void:
	for i in range(gs.active_approaches.size()):
		var ap = gs.active_approaches[i]
		if ap["neg_id"] == neg_id:
			## Only cancel if player never submitted — Round 1 and still their turn
			if ap.get("contract_round", 1) == 1 and ap.get("player_turn", true):
				gs.active_approaches.remove_at(i)
				gs.emit_signal("approach_updated")
			else:
				## Already submitted at least once — just reset last_action_week
				ap["last_action_week"] = gs.current_week
			return

func get_active_approaches_for_display() -> Array:
	## Returns all approaches that should show in HQ Pending Activity
	return gs.active_approaches.filter(func(ap):
		return ap["status"] not in ["activated", "expired"] or \
			(ap["status"] == "agreed" and ap.get("type") == "pre_signed"))

func get_pending_contract_negotiation() -> Dictionary:
	## Returns the first approach in "negotiating" status (for popup display)
	for ap in gs.active_approaches:
		if ap["status"] == "negotiating": return ap
	return {}

func _get_subject_display_name(subject_id: String, subject_type: String) -> String:
	match subject_type:
		"driver":
			var d = gs.all_drivers.get(subject_id)
			return d.full_name() if d else subject_id
		"staff":
			var s = gs.all_staff.get(subject_id)
			return s.full_name() if s else subject_id
		"sponsor":
			for o in gs.sponsor_offers:
				if o.get("sponsor_id","") == subject_id: return o.get("name", subject_id)
	return subject_id

## ── Internal helpers ─────────────────────────────────────────────────────────

func _get_active_championship_tier() -> int:
	if gs.active_championship == null: return 1
	return gs.active_championship.tier

func _calc_driver_ask_salary(skill: float, tier: int) -> float:
	## Base weekly: tier 1 starts at ~50, tier 4 at ~2850
	const TIER_BASES = {1: 50.0, 2: 250.0, 3: 900.0, 4: 2850.0}
	var base = TIER_BASES.get(tier, 50.0)
	return round((base + base * (skill / 100.0) * 1.5) / 10.0) * 10.0

## Evaluate whether the player's offer is acceptable.
## Returns "accepted", "counter", or "rejected".
func _evaluate_offer(neg: Dictionary) -> String:
	var player = neg["player_offer"]
	var ask    = neg["their_ask"]
	var round_n = neg["round"]
	var max_r   = neg["max_rounds"]
	var locked  = neg.get("locked_fields", [])
	var ratio = _calc_offer_ratio(player, ask, locked)
	## Threshold: starts at 0.95 (Round 1) and gradually drops to 0.82 (final round).
	## They are reluctant early — only accept if the player is very close to their ask.
	## By the final round they have softened but still need ~82% of their ask.
	var threshold = lerp(0.95, 0.82, float(round_n - 1) / float(max(max_r - 1, 1)))
	if ratio >= threshold: return "accepted"
	## Walk away if offer is insultingly low in mid-late rounds
	if ratio < 0.40 and round_n >= 2: return "rejected"
	if ratio < 0.30: return "rejected"
	return "counter"

func _calc_offer_ratio(player: Dictionary, ask: Dictionary, locked_fields: Array = []) -> float:
	var total_ratio = 0.0
	var count = 0
	for key in ask:
		if key == "duration_seasons": continue
		if key in locked_fields: continue
		if ask[key] <= 0: continue
		var p_val = float(player.get(key, 0))
		var a_val = float(ask[key])
		total_ratio += clamp(p_val / a_val, 0.0, 1.0)
		count += 1
	return total_ratio / float(max(count, 1))

## Move their ask slightly toward player's offer — conservative concessions.
## They concede max 15% of the gap over the full negotiation (was 25%).
## Concession rate is slow early and picks up only if player is close.
func _apply_counter_offer(neg: Dictionary) -> void:
	var player = neg["player_offer"]
	var ask    = neg["their_ask"]
	var progress = float(neg["round"]) / float(neg["max_rounds"])
	var ratio = _calc_offer_ratio(player, ask, neg.get("locked_fields", []))
	## Concede more if player is close (ratio > 0.75), less if far away
	var concede_rate = lerp(0.02, 0.06, clamp((ratio - 0.5) * 4.0, 0.0, 1.0))
	for key in ask:
		if key == "duration_seasons": continue
		if ask[key] <= 0: continue
		var gap = ask[key] - player.get(key, 0)
		if gap > 0:
			var concession = gap * concede_rate * progress
			neg["their_ask"][key] = max(player.get(key, 0), ask[key] - concession)

## Apply the result — actually hire/set contract terms.
func _apply_negotiation_result(neg: Dictionary, accepted: bool) -> void:
	if not accepted: return
	var terms = neg["player_offer"]
	var start_date = terms.get("start_date", "immediate")
	var is_presigned: bool = neg.get("_presigned", false)  ## S33.1: activation of a committed pre-signing

	match neg["subject_type"]:
		"driver":
			var driver = gs.all_drivers.get(neg["subject_id"])
			if driver == null: return
			## Slot check — only block immediate signing, not next-season, and never a
			## pre-signing activation (the player already planned that slot last season).
			var max_d = gs.get_max_drivers()
			if driver.contract_team == "" and gs.player_team.drivers.size() >= max_d \
					and start_date == "immediate" and not is_presigned:
				gs.add_notification("High", "Racing Dept full — can't sign %s immediately. Sign for next season instead." % driver.full_name())
				return
			## Next-season signing — mark as pre_signed, don't apply yet
			if start_date == "next_season":
				## Find the approach and mark it pre_signed
				for ap in gs.active_approaches:
					if ap["subject_id"] == neg["subject_id"] and ap["status"] == "negotiating":
						ap["type"] = "pre_signed"
						ap["status"] = "agreed"
						ap["signed_season"] = gs.current_season
						break
				gs.add_log("✅ %s pre-signed — joins Season %d." % [driver.full_name(), gs.current_season + 1])
				gs.add_notification("Normal",
					"%s pre-signed and will join at the start of Season %d." % [
					driver.full_name(), gs.current_season + 1], "hq")
				gs.emit_signal("log_updated")
				return
			## Immediate signing
			driver.contract_team = gs.player_team.id
			driver.contract_seasons_remaining = terms.get("duration_seasons", 1)
			driver.weekly_salary       = terms.get("weekly_salary", 50.0)
			driver.win_bonus           = terms.get("win_bonus", 0)
			driver.podium_bonus        = terms.get("podium_bonus", 0)
			driver.championship_bonus  = terms.get("championship_bonus", 0)
			driver.release_clause      = terms.get("release_clause", 0)
			if not neg["subject_id"] in gs.player_team.drivers:
				gs.player_team.drivers.append(neg["subject_id"])
				if gs.active_championship:
					gs.active_championship.standings[neg["subject_id"]] = 0
			gs.add_log("✅ %s signed: CR %.0f/wk, %d seasons, Win:CR %s, Podium:CR %s" % [
				driver.full_name(), driver.weekly_salary, driver.contract_seasons_remaining,
				gs._fmt_int(driver.win_bonus), gs._fmt_int(driver.podium_bonus)])
			gs.add_notification("Normal", "%s signed. Assign them to a car in the Garage." % driver.full_name())
			gs._fire_assignment_proposals()
		"staff":
			var staff = gs.all_staff.get(neg["subject_id"])
			if staff == null: return
			## Next-season signing for staff
			if start_date == "next_season":
				for ap in gs.active_approaches:
					if ap["subject_id"] == neg["subject_id"] and ap["status"] == "negotiating":
						ap["type"] = "pre_signed"
						ap["status"] = "agreed"
						ap["signed_season"] = gs.current_season
						break
				gs.add_log("✅ %s pre-signed — joins Season %d." % [staff.full_name(), gs.current_season + 1])
				gs.add_notification("Normal",
					"%s pre-signed and will join at the start of Season %d." % [
					staff.full_name(), gs.current_season + 1], "hq")
				gs.emit_signal("log_updated")
				return
			## Slot checks for immediate (same as hire_staff)
			if staff.contract_team == "":
				if staff.role == "Team Principal":
					var existing = gs.get_player_staff_by_role("Team Principal")
					if existing.size() >= gs.get_hq_tp_slots():
						gs.add_notification("High", "TP slots full. Upgrade HQ."); return
				elif staff.role == "CFO":
					if gs.get_player_staff_by_role("CFO").size() >= 1:
						gs.add_notification("High", "You already have a CFO."); return
			staff.contract_team = gs.player_team.id
			staff.contract_seasons_remaining = terms.get("duration_seasons", 1)
			staff.weekly_salary        = terms.get("weekly_salary", staff.weekly_salary)
			staff.championship_bonus   = terms.get("championship_bonus", 0)
			staff.performance_bonus    = terms.get("performance_bonus", 0)
			staff.release_clause       = terms.get("release_clause", 0)
			if staff.role == "Pit Crew" and staff.crew_number == 0:
				staff.crew_number = gs.get_player_staff_by_role("Pit Crew").size()
			gs.add_log("✅ %s (%s) signed: CR %.0f/wk, %d seasons" % [
				staff.full_name(), staff.role, staff.weekly_salary, staff.contract_seasons_remaining])
			gs.add_notification("Normal", "%s (%s) joined your team." % [staff.full_name(), staff.role])
			if staff.role in ["Race Mechanic", "Team Principal", "Race Strategist"]:
				gs._fire_assignment_proposals()
		"sponsor":
			## sign_sponsor adds the original offer — then overwrite with negotiated terms
			if gs.sign_sponsor(neg["subject_id"]):
				var negotiated = neg["player_offer"]
				for sp in gs.active_sponsors:
					if sp.get("sponsor_id","") == neg["subject_id"] or \
							sp.get("name","") == neg.get("sponsor_name",""):
						for key in negotiated:
							if key in sp:
								sp[key] = negotiated[key]
						break
	gs.emit_signal("log_updated")
