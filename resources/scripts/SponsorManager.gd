class_name SponsorManager
## Version: S38.3 — register_racing_income() added at all 5 sponsor payout sites (weekly active,
##   multi-sponsor weekly, commitment annual at sign + at season start, performance bonus) so the
##   Factory income cap (FinancialEngine) can anchor to total racing income. Payout logic unchanged.
## Version: S37.41 — Notification & News Roadmap, Phase 3 (events→notify_event). All 17 SponsorManager
##   notifications migrated: 2 blocking errors → show_popup (no-CFO defensive guard, slots full); the
##   rest → "event" (sponsor offers found/received, signed, expired, fulfilled, paid, cancelled,
##   commitment terms, CFO search status; the non-race penalty stays Critical-priority event). No
##   news here — sponsor lifecycle is player-facing, not world-feed material.
## Version: S37.40 — Commitment (type-3) sponsor is now a forward commitment: _pick_commitment_
##   championship excludes championships already in next_season_registrations (so the deal always
##   asks the player to register for a championship they have NOT yet committed to next season).
##   Sign-time notification reworded to "register for it next season". Pairs with the new
##   commitment-sponsor TDL in NotificationManager.
## Version: S37.10 — Commitment sponsor REDESIGN (per design owner). A type-3 sponsor wants the team
##   to race a SPECIFIC championship for N seasons, chosen from a REPUTATION BAND near the team's rep
##   (no GK team getting GP1 offers, no GP1 team getting Rally4). Payment is ANNUAL (~1 season's
##   entry+car ±variation) paid at the START of each registered season (not a lump at signing). The
##   offer expires a few weeks BEFORE the championship's registration deadline so it's actionable.
##   At season start (_process_sponsor_annual_payments, after the registration ledger is promoted):
##   registered → pay that season; NOT registered → penalty = repay only that season's amount and the
##   deal cancels. seasons_total/seasons_paid track progress; a fully-paid deal ends cleanly. Season
##   END now only ages weekly/bonus (type 1/2) sponsors. Also fixed the "all offers exactly 20K"
##   flat-floor bug (varied floor + cost band).
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
	gs.register_racing_income(payment)   ## S38.3 — cap anchor
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

## S37.10 — pick a championship for a COMMITMENT sponsor from a REPUTATION BAND near the team's
## own reputation. A sponsor wants the team in a series that fits its standing — no GK team gets a
## GP1 offer, no GP1 team gets a Rally4 offer. Each championship has a `rep` (15=GK … 100=GP1).
## Band: [player_rep − REP_BAND_DOWN, player_rep + REP_BAND_UP]. Returns "" if none in band.
const REP_BAND_DOWN: float = 18.0   ## sponsors may pitch a slightly lower series
const REP_BAND_UP:   float = 22.0   ## or a modest step up (aspirational, but not absurd)

func _pick_commitment_championship() -> String:
	var prep: float = gs.player_team.reputation
	var lo := prep - REP_BAND_DOWN
	var hi := prep + REP_BAND_UP
	var pool: Array = []
	for cid in gs.CHAMPIONSHIP_REGISTRY:
		## S37.40 — a commitment sponsor must target a championship the player has NOT already
		## committed to for next season; otherwise the "commitment" is meaningless and produces no
		## actionable TDL. (Currently-raced championships are still eligible — the sponsor then asks
		## the player to RE-commit for next season.)
		if cid in gs.next_season_registrations: continue
		var reg = gs.CHAMPIONSHIP_REGISTRY[cid]
		var crep: float = float(reg.get("rep", 50))
		if crep >= lo and crep <= hi:
			pool.append(cid)
	## Fallback: if the band caught nothing (e.g. very low/high rep extremes), take the closest
	## championship by rep so an offer can still be made.
	if pool.is_empty():
		var best := ""
		var best_d := 1e9
		for cid in gs.CHAMPIONSHIP_REGISTRY:
			if cid in gs.next_season_registrations: continue
			var crep: float = float(gs.CHAMPIONSHIP_REGISTRY[cid].get("rep", 50))
			var d: float = abs(crep - prep)
			if d < best_d:
				best_d = d; best = cid
		return best
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
		## S37.10 — commitment metadata (type 3): a sponsor wants the team to race a SPECIFIC
		## championship (chosen by reputation band) for `seasons_total` seasons, paying
		## `annual_payment` at the START of each season the team is registered for it. Missing a
		## season = repay that season's amount and the deal terminates.
		"requires_championship": false,
		"annual_payment":   0,
		"seasons_total":    0,
		"seasons_paid":     0,
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
		## Type 3 — COMMITMENT sponsor: tied to a reputation-appropriate championship, pays an
		## ANNUAL amount (~1 season's entry+car, ±variation) at the start of each committed season.
		3:
			var champ_id = _pick_commitment_championship()
			if champ_id != "":
				var seasons := randi_range(2, 3)
				var cost = _championship_annual_cost(champ_id)
				## ~95–120% of one season's cost, varied, rounded to 500 (no flat identical offers).
				var annual = int(round(max(cost * randf_range(0.95, 1.20), randf_range(18000, 26000)) / 500.0) * 500)
				offer.championship_id   = champ_id
				offer.annual_payment    = annual
				offer.seasons_total     = seasons
				offer.seasons_remaining = seasons
				## commitment_total kept for display = full contract value across all seasons.
				offer.commitment_total  = annual * seasons
				offer.requires_championship = true
				## S37.10 (#3) — the offer must be actionable BEFORE the championship's registration
				## deadline, so the player can register and start fulfilling it. Expire a few weeks
				## before that deadline (but never in the past / under 2 weeks from now).
				var dl: int = gs.get_entry_deadline_week(champ_id)
				var safe_expiry: int = max(gs.current_week + 2, dl - 3)
				offer.expires_week = safe_expiry
			else:
				## No reputation-appropriate championship → fall back to a weekly offer.
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
		gs.notify_event("sponsor_offer_%s" % offer.sponsor_id, "Normal", "New sponsor offer: %s. View in Sponsors tab." % offer.name, "hq", "event")


func start_cfo_sponsor_search() -> bool:
	if gs.cfo_search_active: return false
	var cfo = null
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.role == "CFO" and s.contract_team == gs.player_team.id:
			cfo = s
			break
	if not cfo:
		gs.show_popup("No CFO hired. Hire a CFO to search for sponsors.", "No CFO")
		return false
	## Rolling search — weeks_remaining is the interval between offers, not a one-time countdown
	## CFO skill determines how quickly each offer arrives (1-3 weeks between offers)
	var weeks = int(3.0 - (cfo.talent / 100.0) * 2.0)
	weeks = max(1, weeks)
	gs.cfo_search_active = true
	gs.cfo_search_weeks_remaining = weeks
	gs.cfo_search_results = []
	gs.add_log("🔍 CFO sponsor search started. New offers every %d week%s." % [weeks, "s" if weeks != 1 else ""])
	gs.notify_event("cfo_search_on", "Normal", "CFO sponsor search active. Offers will arrive every %d week%s. Stop search in HQ." % [weeks, "s" if weeks != 1 else ""], "", "event")
	return true


func stop_cfo_sponsor_search() -> void:
	gs.cfo_search_active = false
	gs.cfo_search_weeks_remaining = 0
	gs.add_log("🔍 CFO sponsor search stopped.")
	gs.notify_event("cfo_search_off", "Normal", "CFO sponsor search stopped.", "", "event")


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
		gs.notify_event("cfo_found_%s" % gs.sponsor_offers[-1].sponsor_id, "High",
			"CFO found a new sponsor offer: %s. View in Sponsors tab." % gs.sponsor_offers[-1].name, "hq", "event")
	else:
		gs.notify_event("cfo_found_batch", "High",
			"CFO found %d new sponsor offers this week. View in Sponsors tab." % num, "hq", "event")
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
		gs.notify_event("cfo_search_off", "Normal", "CFO sponsor search stopped — CFO no longer on team.", "", "event")


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
		gs.show_popup("Sponsor slots full (%d/%d). Upgrade HQ to unlock more slots." % [
				gs.active_sponsors.size(), max_slots], "Slots Full")
		return false
	if offer.type == 3 and offer.championship_id != "":
		var champ_name = offer.championship_id
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(offer.championship_id, {})
		if reg.has("name"): champ_name = reg["name"]
		## S37.10 — ANNUAL model: no lump at signing. The sponsor pays annual_payment at the START
		## of each season the team is registered for the championship (handled in
		## _process_sponsor_annual_payments at season start). If the championship is ALREADY in the
		## current season's race set, pay the first instalment now so signing mid-season isn't dead.
		var already_running: bool = offer.championship_id in gs.player_registered_championships
		if already_running:
			gs.register_racing_income(offer.annual_payment)   ## S38.3 — cap anchor
			gs.player_team.balance += offer.annual_payment
			offer.seasons_paid = 1
			gs.add_log("💰 %s: +CR %s (Season %d instalment) — requires racing %s for %d seasons." % [
				offer.name, gs._fmt_int(offer.annual_payment), gs.current_season, champ_name, offer.seasons_total])
		else:
			gs.add_log("🤝 %s signed: pays CR %s/season once you race %s (first instalment at next season start). %d-season deal." % [
				offer.name, gs._fmt_int(offer.annual_payment), champ_name, offer.seasons_total])
		gs.notify_event("commit_sponsor_%s" % offer.sponsor_id, "High",
			"%s: CR %s per season to race %s — register for it next season (%d-season deal). Skip a committed season → repay that season's CR %s." % [
				offer.name, gs._fmt_int(offer.annual_payment), champ_name, offer.seasons_total,
				gs._fmt_int(offer.annual_payment)],
			"hq", "event")
	gs.active_sponsors.append(offer)
	gs.sponsor_offers.remove_at(offer_idx)
	gs.add_log("🤝 Sponsor signed: %s (Type %d)." % [offer.name, offer.type])
	gs.notify_event("sponsor_signed_%s" % offer.sponsor_id, "High", "Sponsor signed: %s." % offer.name, "hq", "event")
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
	gs.notify_event("sponsor_cancelled_%s" % sp.get("sponsor_id", "?"), "High",
		"Cancelled %s deal. Penalty: −%d reputation, −%d marketability." % [
		sp.get("name", "?"), rep_penalty, mktg_penalty], "hq", "event")
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
			gs.register_racing_income(sp.weekly_payment)   ## S38.3 — cap anchor
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
			gs.register_racing_income(bonus)   ## S38.3 — cap anchor
			gs.player_team.balance += bonus
			gs.add_log("💰 Sponsor bonus: CR %s from %s (P%d)." % [gs._fmt_int(bonus), sp.name, final_position])


func _process_sponsors_season_end() -> void:
	## S37.10 — type-3 COMMITMENT sponsors are now handled at SEASON START (annual payment or
	## penalty), see _process_sponsor_annual_payments(). Season-end only ages non-commitment
	## sponsors (weekly/bonus types 1 & 2) and clears expired offers.
	var to_remove: Array = []
	for sp in gs.active_sponsors:
		if sp.type == 3:
			continue  ## commitment deals advance at season start, not here
		sp.seasons_remaining -= 1
		if sp.seasons_remaining <= 0:
			to_remove.append(sp)
			gs.notify_event("sponsor_expired_%s" % sp.sponsor_id, "Normal", "Sponsor contract expired: %s." % sp.name, "", "event")
	for sp in to_remove:
		gs.active_sponsors.erase(sp)
	gs.sponsor_offers = gs.sponsor_offers.filter(func(o): return o.expires_season > gs.current_season)
	_generate_passive_sponsor_offers()

## S37.10 — COMMITMENT sponsor processing, run at SEASON START (after the registration ledger is
## promoted into player_registered_championships, so it reflects the NEW season). For each active
## type-3 sponsor that still owes seasons:
##   • If the player is registered for the committed championship → pay this season's annual amount.
##   • If NOT registered → PENALTY: repay only the current unfulfilled season's amount, terminate.
## A deal with all its seasons paid simply ends (no penalty).
func _process_sponsor_annual_payments() -> void:
	var to_remove: Array = []
	for sp in gs.active_sponsors:
		if sp.type != 3 or sp.get("championship_id", "") == "":
			continue
		var paid: int = sp.get("seasons_paid", 0)
		var total: int = sp.get("seasons_total", 0)
		if paid >= total:
			to_remove.append(sp)
			gs.notify_event("sponsor_fulfilled_%s" % sp.sponsor_id, "Normal", "Sponsor contract fulfilled & ended: %s." % sp.name, "", "event")
			continue
		var cn = gs.CHAMPIONSHIP_REGISTRY.get(sp.championship_id, {}).get("name", sp.championship_id)
		var registered: bool = sp.championship_id in gs.player_registered_championships
		if registered:
			gs.register_racing_income(sp.annual_payment)   ## S38.3 — cap anchor
			gs.player_team.balance += sp.annual_payment
			sp.seasons_paid = paid + 1
			gs.add_log("💰 %s: +CR %s (Season %d of %d for racing %s)." % [
				sp.name, gs._fmt_int(sp.annual_payment), sp.seasons_paid, total, cn])
			gs.notify_event("sponsor_paid_%s" % sp.sponsor_id, "Normal", "%s paid CR %s for racing %s this season." % [
				sp.name, gs._fmt_int(sp.annual_payment), cn], "hq", "event")
			if sp.seasons_paid >= total:
				to_remove.append(sp)
				gs.notify_event("sponsor_fulfilled_%s" % sp.sponsor_id, "Normal", "Sponsor contract fulfilled & ended: %s." % sp.name, "", "event")
		else:
			## Penalty = repay only THIS season's unfulfilled instalment; contract terminates.
			gs.player_team.balance -= sp.annual_payment
			gs.add_log("⚠ Sponsor penalty: −CR %s. You did not register for %s — %s commitment broken." % [
				gs._fmt_int(sp.annual_payment), cn, sp.name])
			gs.notify_event("sponsor_penalty_%s" % sp.sponsor_id, "Critical",
				"Sponsor penalty CR %s: %s — you didn't race %s this season. Deal cancelled." % [
					gs._fmt_int(sp.annual_payment), sp.name, cn], "hq", "event")
			to_remove.append(sp)
	for sp in to_remove:
		gs.active_sponsors.erase(sp)

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
	gs.notify_event("race_sponsor_%s" % offer.sponsor_id, "Normal",
		"Your P%d finish attracted %s — sponsor offer received." % [player_position, offer.name],
		"hq", "event")
