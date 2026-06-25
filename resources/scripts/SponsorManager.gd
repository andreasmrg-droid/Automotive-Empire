class_name SponsorManager
## Version: S37.9 — Bugs #5/#6 (sponsor realism).
##   #5 Offer floor: offers now scale to real running costs. Type-3 (commitment) pays ~105% of the
##      tied championship's annual cost (entry fee + car cost). Type-1 (weekly) and Type-2 (bonuses)
##      carry no championship tie, so they scale to a fraction of a REFERENCE championship's annual
##      cost (≈25–45% of cost as a season of weekly pay for T1; %-of-cost bonuses for T2). Replaces
##      the old flat randi_range bands that were far below one year's entry+car.
##   #6 Commitment clause: a Type-3 sponsor REQUIRES the team to keep racing the tied championship.
##      The season-end penalty now checks the PLAYER'S registration (player_registered_championships
##      / next_season_registrations) rather than mere world-existence of the championship (which was
##      always true, so the penalty never fired). The clause is surfaced at sign time (log + High
##      notification) so the player knows leaving repays commitment_total.
## Version: S27.0 — Extracted from GameState.gd (P57)
##   Sponsor generation, CFO search, sign/cancel, weekly/season processing.
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

func _setup_sponsor() -> void:
	var national_sponsors = [
		{"id": "SP-006", "name": "Velocity Spark", "category": "Energy Drink"},
		{"id": "SP-016", "name": "Precision Fluids", "category": "Lubricants"},
		{"id": "SP-026", "name": "Velocity Parts", "category": "Auto Parts"},
		{"id": "SP-033", "name": "Apex Finance", "category": "Finance"},
		{"id": "SP-039", "name": "Atlas Bank", "category": "Finance"},
		{"id": "SP-046", "name": "Precision Tech", "category": "Tech"},
		{"id": "SP-049", "name": "Dynamic Systems", "category": "Tech"},
		{"id": "SP-053", "name": "Apex Grip", "category": "Tires"},
		{"id": "SP-059", "name": "Helix Tires", "category": "Tires"},
		{"id": "SP-062", "name": "Velocity Style", "category": "Fashion"},
		{"id": "SP-073", "name": "Legacy Shield", "category": "Insurance"},
		{"id": "SP-083", "name": "Stellar Connect", "category": "Telecom"},
		{"id": "SP-089", "name": "Helix Mobile", "category": "Telecom"},
		{"id": "SP-095", "name": "Core Distillery", "category": "Beverage"},
		{"id": "SP-098", "name": "Dynamic Spirits", "category": "Beverage"},
	]
	var picked = national_sponsors[randi() % national_sponsors.size()]
	gs.active_sponsor = {
		"id": picked["id"],
		"name": picked["name"],
		"category": picked["category"],
		"base_weekly": 1000,
		"current_weekly": 1000,
		"performance_bonus": 500,
		"seasons_remaining": 1,
	}
	gs.add_log("📋 Sponsor signed: %s — CR 1,000/week" % picked["name"])
## ═══ NOTIFICATION MANAGER — delegated to NotificationManager.gd (S27) ═══


func _update_sponsor_performance(race_results: Array) -> void:
	if gs.active_sponsor.is_empty():
		return

	var player_scored = false
	var player_top5 = false

	for i in range(race_results.size()):
		var result = race_results[i]
		var driver = result["driver"]
		if driver.id in gs.player_team.drivers:
			if result["points"] > 0:
				player_scored = true
			if i < 5:
				player_top5 = true

	if player_top5:
		gs.active_sponsor["current_weekly"] = gs.active_sponsor["base_weekly"] + gs.active_sponsor["performance_bonus"]
		gs.sponsor_no_points_streak = 0
		gs.add_log("🌟 %s bonus: +CR %d this week!" % [gs.active_sponsor["name"], gs.active_sponsor["current_weekly"]])
	elif player_scored:
		gs.active_sponsor["current_weekly"] = gs.active_sponsor["base_weekly"]
		gs.sponsor_no_points_streak = 0
	else:
		gs.sponsor_no_points_streak += 1
		if gs.sponsor_no_points_streak >= 3:
			gs.active_sponsor["current_weekly"] = 500
			gs.add_log("⚠ %s unhappy — reduced to CR 500/week (no points in 3 races)" % gs.active_sponsor["name"])


func _apply_sponsor_income() -> void:
	if gs.active_sponsor.is_empty():
		return
	var payment = gs.active_sponsor["current_weekly"]
	gs.player_team.balance += payment
	gs.add_log("💼 %s: +CR %d" % [gs.active_sponsor["name"], payment])


func _generate_sponsor_id() -> String:
	return "SP_%d_%d" % [gs.current_season, randi() % 99999]


func _generate_sponsor_name() -> String:
	return "%s %s" % [
		gs.SPONSOR_NAME_PREFIXES[randi() % gs.SPONSOR_NAME_PREFIXES.size()],
		gs.SPONSOR_NAME_SUFFIXES[randi() % gs.SPONSOR_NAME_SUFFIXES.size()]]


func _get_sponsor_tier_for_team() -> int:
	if gs.player_team.reputation >= 75: return 3
	if gs.player_team.reputation >= 40: return 2
	return 1


## S37.9 (#5) — annual cost of one championship = one-time entry fee + the car cost for that
## championship. Used to floor sponsor offers so they're meaningful against real running costs.
func _championship_annual_cost(champ_id: String) -> int:
	if champ_id == "": return 0
	var reg = gs.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var entry = int(reg.get("entry_fee", 0))
	var car   = gs.get_provider_car_cost(champ_id)
	return entry + car

## Pick a championship the player is actually in (preferred) or any active one, for tying a
## commitment-type sponsor to. Returns "" if none.
func _pick_commitment_championship() -> String:
	## Prefer a championship the player is registered in (the offer should be relevant).
	var pool: Array = []
	for cid in gs.player_registered_championships:
		pool.append(cid)
	if pool.is_empty():
		for champ in gs.active_championships:
			pool.append(champ.id)
	if pool.is_empty(): return ""
	return pool[randi() % pool.size()]

## Median-ish annual cost across the player's relevant championships — used to scale the
## NON-committed sponsor types (1 weekly, 2 bonuses), which carry no championship tie.
func _reference_annual_cost() -> int:
	var costs: Array = []
	for cid in gs.player_registered_championships:
		var c = _championship_annual_cost(cid)
		if c > 0: costs.append(c)
	if costs.is_empty():
		for champ in gs.active_championships:
			var c = _championship_annual_cost(champ.id)
			if c > 0: costs.append(c)
	if costs.is_empty():
		return 50000  ## sane fallback before any registration exists
	costs.sort()
	return int(costs[costs.size() / 2])


func _generate_sponsor_offer(type: int, tier: int) -> Dictionary:
	var offer = {
		"sponsor_id":       _generate_sponsor_id(),
		"name":             _generate_sponsor_name(),
		"type":             type,
		"tier":             tier,
		"championship_id":  "",
		"weekly_payment":   0,
		"win_bonus":        0,
		"podium_bonus":     0,
		"season_bonus":     0,
		"commitment_total": 0,
		"seasons_remaining": randi_range(1, 3),
		"season_signed":    gs.current_season,
		"expires_season":   gs.current_season + 2,
		## Offer expires in 2–4 weeks if not acted on (Bugs doc §10)
		"expires_week":     gs.current_week + randi_range(2, 4),
		## S37.9 (#6) — commitment metadata (filled for type 3): the team must keep racing the
		## tied championship for the contract's duration or pay commitment_total back (penalty).
		"requires_championship": false,
	}
	match type:
		## Type 1 — ongoing WEEKLY income, no championship tie. Scale a season's worth of weekly
		## pay to a fraction (~25–45%) of a reference championship's annual cost.
		1:
			var ref_cost = _reference_annual_cost()
			var annual_share = ref_cost * randf_range(0.25, 0.45)
			offer.weekly_payment = max(200, int(round(annual_share / 52.0)))
		## Type 2 — performance BONUSES, no tie. Scaled off the reference cost too.
		2:
			var ref2 = _reference_annual_cost()
			offer.win_bonus    = max(1000, int(ref2 * randf_range(0.04, 0.08)))
			offer.podium_bonus = max(400,  int(ref2 * randf_range(0.015, 0.03)))
			offer.season_bonus = max(3000, int(ref2 * randf_range(0.10, 0.20)))
		## Type 3 — COMMITMENT sponsor: tied to a championship, pays a lump that covers ~105% of
		## that championship's annual cost (entry + car) in exchange for the team racing it.
		3:
			var champ_id = _pick_commitment_championship()
			if champ_id != "":
				offer.championship_id = champ_id
				var cost = _championship_annual_cost(champ_id)
				## 105% of (entry + car); never below a floor so tier-1 cheap champs still pay.
				offer.commitment_total = max(20000, int(round(cost * 1.05)))
				offer.requires_championship = true
			else:
				## No championship to tie to → fall back to a weekly-style offer so the slot
				## isn't a dead "Type 3 with no commitment".
				offer.type = 1
				var rc = _reference_annual_cost()
				offer.weekly_payment = max(200, int(round(rc * randf_range(0.25, 0.45) / 52.0)))
	return offer


func _generate_passive_sponsor_offers() -> void:
	var max_tier = _get_sponsor_tier_for_team()
	for i in range(randi_range(1, 3)):
		var offer = _generate_sponsor_offer(randi_range(1, 3), randi_range(1, max_tier))
		gs.sponsor_offers.append(offer)
		gs.pending_hq_tab = "sponsors"
		gs.add_notification("Normal", "New sponsor offer: %s. View in Sponsors tab." % offer.name, "hq")


func start_cfo_sponsor_search() -> bool:
	if gs.cfo_search_active: return false
	var cfo = null
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.role == "CFO" and s.contract_team == gs.player_team.id:
			cfo = s
			break
	if not cfo:
		gs.add_notification("High", "No CFO hired. Hire a CFO to search for sponsors.")
		return false
	## Rolling search — weeks_remaining is the interval between offers, not a one-time countdown
	## CFO skill determines how quickly each offer arrives (1-3 weeks between offers)
	var weeks = int(3.0 - (cfo.talent / 100.0) * 2.0)
	weeks = max(1, weeks)
	gs.cfo_search_active = true
	gs.cfo_search_weeks_remaining = weeks
	gs.cfo_search_results = []
	gs.add_log("🔍 CFO sponsor search started. New offers every %d week%s." % [weeks, "s" if weeks != 1 else ""])
	gs.add_notification("Normal", "CFO sponsor search active. Offers will arrive every %d week%s. Stop search in HQ." % [weeks, "s" if weeks != 1 else ""])
	return true


func stop_cfo_sponsor_search() -> void:
	gs.cfo_search_active = false
	gs.cfo_search_weeks_remaining = 0
	gs.add_log("🔍 CFO sponsor search stopped.")
	gs.add_notification("Normal", "CFO sponsor search stopped.")


func _advance_cfo_search() -> void:
	if not gs.cfo_search_active: return
	gs.cfo_search_weeks_remaining -= 1
	if gs.cfo_search_weeks_remaining > 0: return
	## Generate 1-2 new offers this week
	var max_tier = min(3, _get_sponsor_tier_for_team() + 1)
	var num = randi_range(1, 2)
	for i in range(num):
		var offer = _generate_sponsor_offer(randi_range(1, 3), randi_range(1, max_tier))
		offer.expires_season = gs.current_season + 1
		gs.sponsor_offers.append(offer)
		gs.cfo_search_results.append(offer.sponsor_id)
	## Notify player each time a new offer arrives
	gs.pending_hq_tab = "sponsors"
	if num == 1:
		gs.add_notification("High",
			"CFO found a new sponsor offer: %s. View in Sponsors tab." % gs.sponsor_offers[-1].name, "hq")
	else:
		gs.add_notification("High",
			"CFO found %d new sponsor offers this week. View in Sponsors tab." % num, "hq")
	gs.add_log("📋 CFO: %d new sponsor offer%s this week." % [num, "s" if num != 1 else ""])
	## Reset countdown for next offer cycle
	var cfo = null
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.role == "CFO" and s.contract_team == gs.player_team.id:
			cfo = s
			break
	if cfo:
		var weeks = int(3.0 - (cfo.talent / 100.0) * 2.0)
		gs.cfo_search_weeks_remaining = max(1, weeks)
	else:
		## CFO was released — stop search
		gs.cfo_search_active = false
		gs.add_notification("Normal", "CFO sponsor search stopped — CFO no longer on team.")


func dismiss_sponsor_offer(sponsor_id: String) -> void:
	for i in range(gs.sponsor_offers.size()):
		if gs.sponsor_offers[i].sponsor_id == sponsor_id:
			gs.sponsor_offers.remove_at(i)
			gs.emit_signal("log_updated")
			return


func sign_sponsor(sponsor_id: String) -> bool:
	var offer = null
	var offer_idx = -1
	for i in range(gs.sponsor_offers.size()):
		if gs.sponsor_offers[i].sponsor_id == sponsor_id:
			offer = gs.sponsor_offers[i]
			offer_idx = i
			break
	if not offer: return false
	## Enforce HQ sponsor slot cap
	var max_slots = gs.get_hq_sponsor_slots()
	if gs.active_sponsors.size() >= max_slots:
		gs.add_notification("High",
			"Sponsor slots full (%d/%d). Upgrade HQ to unlock more slots." % [
				gs.active_sponsors.size(), max_slots])
		return false
	if offer.type == 3 and offer.championship_id != "":
		gs.player_team.balance += offer.commitment_total
		var champ_name = offer.championship_id
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(offer.championship_id, {})
		if reg.has("name"): champ_name = reg["name"]
		gs.add_log("💰 Commitment sponsor: %s. CR %s up front — you must race %s for %d season(s) or repay it." % [
			offer.name, gs._fmt_int(offer.commitment_total), champ_name, offer.get("seasons_remaining", 1)])
		gs.add_notification("High",
			"%s pays CR %s but requires you to keep racing %s. Leaving repays CR %s." % [
				offer.name, gs._fmt_int(offer.commitment_total), champ_name, gs._fmt_int(offer.commitment_total)],
			"hq")
	gs.active_sponsors.append(offer)
	gs.sponsor_offers.remove_at(offer_idx)
	gs.add_log("🤝 Sponsor signed: %s (Type %d)." % [offer.name, offer.type])
	gs.add_notification("High", "Sponsor signed: %s." % offer.name, "hq")
	return true

## Cancel an active sponsor deal early. Applies rep and marketability penalty.


func cancel_sponsor(sponsor_id: String) -> void:
	var sp_idx = -1
	var sp = null
	for i in range(gs.active_sponsors.size()):
		if gs.active_sponsors[i].get("sponsor_id", "") == sponsor_id:
			sp = gs.active_sponsors[i]
			sp_idx = i
			break
	if sp == null: return

	gs.active_sponsors.remove_at(sp_idx)

	## Penalty scaled by seasons remaining
	var seasons_left = sp.get("seasons_remaining", 1)
	var rep_penalty = clamp(5 * seasons_left, 5, 20)
	var mktg_penalty = clamp(8 * seasons_left, 8, 30)

	## Reputation is a direct property on player_team
	gs.player_team.reputation = max(0.0, gs.player_team.reputation - rep_penalty)

	## Team marketability is stored as meta (not a property on Team resource)
	var cur_mktg = gs.player_team.get_meta("team_marketability", 50.0) if \
		gs.player_team.has_meta("team_marketability") else 50.0
	gs.player_team.set_meta("team_marketability", max(0.0, cur_mktg - mktg_penalty))

	gs.add_log("❌ Sponsor deal cancelled: %s. Rep −%d, Marketability −%d." % [
		sp.get("name", "?"), rep_penalty, mktg_penalty])
	gs.add_notification("High",
		"Cancelled %s deal. Penalty: −%d reputation, −%d marketability." % [
		sp.get("name", "?"), rep_penalty, mktg_penalty], "hq")
	gs.emit_signal("log_updated")


func _process_sponsors_weekly() -> void:
	## Expire pending offers that have timed out (2–4 week window)
	var expired_offers = gs.sponsor_offers.filter(func(o):
		return o.get("expires_week", 9999) <= gs.current_week)
	for o in expired_offers:
		gs.sponsor_offers.erase(o)
		gs.add_log("📋 Sponsor offer expired: %s" % o.name)
	if not expired_offers.is_empty():
		gs.emit_signal("log_updated")
	## Pay active sponsors
	for sp in gs.active_sponsors:
		if sp.type == 1:
			gs.player_team.balance += sp.weekly_payment

## Applies sponsor bonuses for podiums/win.
## Can be called with or without a position.
## If no position is passed, it automatically finds the best position
## of any player driver in the last race.


func apply_sponsor_race_bonuses(position: int = -1) -> void:
	if gs.last_race_results.is_empty():
		return
		
	var final_position = position
	# If no position was passed, calculate the best player position automatically
	if final_position == -1:
		final_position = 99
		for i in range(gs.last_race_results.size()):
			var result = gs.last_race_results[i]
			if result.get("dns", false):
				continue
			if result["driver"].id in gs.player_team.drivers:
				final_position = min(final_position, i + 1)

	# No podium achieved
	if final_position > 3:
		return

	for sp in gs.active_sponsors:
		if sp.type != 2:
			continue

		var bonus = 0
		if final_position == 1:
			bonus = sp.win_bonus
		elif final_position <= 3:
			bonus = sp.podium_bonus

		if bonus > 0:
			gs.player_team.balance += bonus
			gs.add_log("💰 Sponsor bonus: CR %s from %s (P%d)." % [gs._fmt_int(bonus), sp.name, final_position])


func _process_sponsors_season_end() -> void:
	var to_remove: Array = []
	for sp in gs.active_sponsors:
		if sp.type == 3 and sp.championship_id != "":
			## S37.9 (#6) — the commitment is to the PLAYER racing this championship. The previous
			## check only asked "does this championship still exist in the world", which is always
			## true — so a player who dropped their registration escaped the penalty. Now we check
			## the player's own registration for the upcoming season.
			var player_in_it = sp.championship_id in gs.player_registered_championships \
				or sp.championship_id in gs.next_season_registrations
			if not player_in_it:
				gs.player_team.balance -= sp.commitment_total
				gs.add_log("⚠ Sponsor penalty: CR %s. You left %s's championship." % [
					gs._fmt_int(sp.commitment_total), sp.name])
				gs.add_notification("Critical", "Sponsor penalty CR %s: %s — you stopped racing the committed championship." % [
					gs._fmt_int(sp.commitment_total), sp.name])
				to_remove.append(sp)
				continue
		sp.seasons_remaining -= 1
		if sp.seasons_remaining <= 0:
			to_remove.append(sp)
			gs.add_notification("Normal", "Sponsor contract expired: %s." % sp.name)
	for sp in to_remove:
		gs.active_sponsors.erase(sp)
	gs.sponsor_offers = gs.sponsor_offers.filter(func(o): return o.expires_season > gs.current_season)
	_generate_passive_sponsor_offers()

## Loads a pending race snapshot into the last_race_* vars for RaceResults to display.


func _maybe_generate_race_sponsor_offer(player_position: int) -> void:
	var chance = 0.0
	if player_position == 1:   chance = 0.30
	elif player_position <= 3: chance = 0.15
	elif player_position <= 5: chance = 0.05
	if chance <= 0.0 or randf() > chance: return
	var max_tier = _get_sponsor_tier_for_team()
	var offer = _generate_sponsor_offer(randi_range(1, 2), randi_range(1, max_tier))
	offer.expires_season = gs.current_season + 1
	gs.sponsor_offers.append(offer)
	gs.add_notification("Normal",
		"Your P%d finish attracted %s — sponsor offer received." % [player_position, offer.name],
		"hq")
