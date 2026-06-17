class_name SponsorManager
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


func _generate_sponsor_offer(type: int, tier: int) -> Dictionary:
	var mult = 1.0 + (tier - 1) * 2.5
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
	}
	match type:
		1: offer.weekly_payment = int(randi_range(500, 2000) * mult)
		2:
			offer.win_bonus    = int(randi_range(2000, 8000) * mult)
			offer.podium_bonus = int(randi_range(500, 2000) * mult)
			offer.season_bonus = int(randi_range(5000, 20000) * mult)
		3:
			if not gs.active_championships.is_empty():
				var champ = gs.active_championships[randi() % gs.active_championships.size()]
				offer.championship_id = champ.id
				offer.commitment_total = int(randi_range(20000, 80000) * mult)
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
		gs.add_log("💰 Commitment sponsor: %s. CR %s." % [offer.name, gs._fmt_int(offer.commitment_total)])
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
			var still_active = false
			for champ in gs.active_championships:
				if champ.id == sp.championship_id:
					still_active = true
					break
			if not still_active:
				gs.player_team.balance -= sp.commitment_total
				gs.add_log("⚠ Sponsor penalty: CR %s. Dropped %s." % [gs._fmt_int(sp.commitment_total), sp.name])
				gs.add_notification("Critical", "Sponsor penalty CR %s: %s (championship exit)." % [
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
