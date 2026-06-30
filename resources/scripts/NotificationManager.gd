class_name NotificationManager
## Version: S40.0 — TDL: when no CFO is hired, add a second advisory row "📉 Financial Department is
##   not optimized." beneath the existing optional-CFO row (read-only, dismissible, routes to Staff).
## Version: S37.64 — Crash fix: _push_news now pushes a String (was a Dictionary) into the typed
##   news_feed. TDL auto-clean also purges legacy "TP has N … ready" count variants.
## Version: S37.62 — News/TDL cleanup: notifications no longer mirror into the NEWS/event log
##   (readiness alerts are not news); TDL deadline items resolve on crew/mechanic fill; legacy
##   week-countdown TDL variants purged from old saves.
## Version: S37.60 — Bug #38 (multi-driver): driver-readiness tasks flag any empty seat and resolve
##   only when all seats are filled.
## Version: S37.50 — Added the Race Strategist readiness check (Step 3a in get_pending_tasks),
##   previously deferred (it was blocked by the new-game Ops Sim building bug, fixed in GameState
##   S37.50). Flags "No Race Strategist for: <champs> (car will DNS)" per championship the player
##   fields a car in, for every discipline except GK & Rally. Matches the can_car_race strategist-DNS
##   enforcement (RaceSimulator S37.50) so the TDL warning and the actual DNS agree.
## Version: S37.43 — BUGFIX (false GK-TP TDL for non-GK players): the TP readiness check keyed on
##   "any GK championship is active" (GK/C-001 is ALWAYS in the world), so an SC/Rally/etc. player
##   wrongly saw "no TP for GK" while their real championships went unchecked — and the non-GK branch
##   iterated EVERY active championship. Now derived from the cars the player actually fields
##   (player_champ_ids), GK shares one TP, non-GK each need their own.
## Version: S37.42 — Readiness gaps are now CRITICAL (red): missing driver / mechanic / Team Principal
##   all cause a DNS, so their TDL rows are prefixed with 🚫 (the UI's critical-color marker) instead
##   of ⚠/🔧/👤 which rendered orange. (Driver-on-car 🏎 and Pit Crew ⏱ were already red.) Routing
##   substrings preserved so the → buttons still resolve. Strategist readiness check still pending
##   (tied to the SC-Dev-Cup building-slot investigation).
## Version: S37.40 — Commitment (type-3) sponsor TDL: while not registered for the championship
##   a championship-sponsor requires, a TDL prompts registration NEXT SEASON (clears on register).
##   Championship sponsors now drive a TDL, not just a notification.
## Version: S37.39 — DRAFT exclusion: pending-negotiation TDL skips draft approaches (a round the
##   player opened but has not yet acted on).
## Version: S37.38 — clear_all_notifications() added (Main Hub "Delete All" button); Main Hub
##   notification panel: snooze removed, "Mark All as Read" + "Delete All" buttons added next to
##   the panel title.
## Version: S37.9 — Renegotiation TDL: the round-1 "make your opening offer" task is now suppressed
##   for player-initiated renegotiations until an offer is actually submitted (player_initiated +
##   offer_submitted flags from ContractEngine). Opening the Renegotiate dialog no longer creates a
##   TDL row by itself.
## Version: S37.7 — Notification framework: added notify_event() (modes once/standing/event/news)
##   + _fired_once tracking + _push_news hook. CFO is now a READ-ONLY TO-DO row here (the TDL never
##   notifies); the one-time "no CFO" notice is fired via notify_event from GameState.
## Version: S37.6 — Removed the recurring "No CFO hired" TDL task (CFO is optional — it nagged every
##   week). A one-time hint notification fires from GameState instead (cfo_hint_shown).
## Version: S35.11 — TDL 8b "queue manufacturing" nag now clears when a part of the blueprint
##   exists anywhere (queued / warehouse / installed), not just when queued — needed because the
##   WRA approval now persists after building (RnDEngine S35.11b, issue 3).
## Version: S35.1 — Recurring-notification collapse. add_notification() gains an optional `subject`
##   key. A notification carrying a subject SUPERSEDES any earlier notification with the same
##   subject (the previous instance is removed before the new one is appended), so a standing
##   weekly reminder ("no car for SC Dev", "no fuel", "register a championship") keeps only its
##   CURRENT-week instance instead of stacking one per advanced week. This fixes the case the S31.1
##   identical-text dedup missed: notifications whose TEXT changes week to week (e.g. a delivery
##   week or deadline baked into the message) are still the same subject, so identical-match never
##   caught them. Subject supersede is text-independent. One-off notifications pass no subject and
##   behave exactly as before. Critical still always shows AND still supersedes by subject (so a
##   critical weekly reminder collapses too — only the latest survives, never suppressed away).
## Version: S38.7 — Commercial TDL: a researched model blueprint with a free Factory line and no
##   line yet for that segment surfaces a "build it (Commercial Department)" to-do; auto-resolves
##   once the line is built. Requires a CFO + the Factory.
## Version: S34.2 — Bond-countered To-Do text now points to HQ ("…accept, counter or reject in
##   HQ") since all negotiation actions are handled from HQ Pending Activity.
## Version: S34.1 — TDL bond visibility fix. get_pending_tasks() step 7b now branches on
##   bond_status inside the "approaching" case: "awaiting_team"→sent/await, "countered"→an
##   ACTIONABLE "team wants CR X — accept/counter/reject" task (was falling through to a stale
##   "reply expected next week" line, so a waiting bond decision never surfaced in the To-Do List),
##   "offered"→your offer is with their team. This is the fix for "approach sent, no TDL, nothing".
## Version: S31.1 — Bug 5: cross-week dedup. add_notification now suppresses an identical
##   non-Critical message while it is still UNREAD (instead of only within the same week),
##   so standing reminders ("assign a driver") stop restacking every week. Re-fires after
##   the player reads/dismisses if still relevant. Critical always shows.
## --- S27.0 — Extracted from GameState.gd (P57)
##   Notifications, TDL, logging, resource warnings.
extends RefCounted

var gs

## ── Notification framework (S37.7) ─────────────────────────────────────────────
## One model for all notifications, per the design rule:
##   1. An EVENT triggers a notification (this method).
##   2. The notification may carry a `destination` button that leads to where you act
##      (e.g. "logistics", "garage", "staff"), and/or the TDL reflects the standing task.
##   3. Meaningful world events (mode "news") also post to the news feed.
## The TO-DO LIST is READ-ONLY: it is rebuilt from current state in get_pending_tasks() and
## NEVER emits notifications (the player can already see the list). Operational "you should do X"
## reminders belong in the TDL, not as repeating notifications.
##
## modes:
##   "once"     — fire exactly once ever (tracked by event_id, persisted). For optional standing
##                conditions you mention a single time (e.g. "no CFO").
##   "standing" — subject-superseded: one live instance, refreshed when the condition re-fires
##                (e.g. low fuel before a race). Use sparingly — prefer the TDL for chores.
##   "event"    — a one-off event notification (no dedup beyond identical-text), e.g. "Garage
##                upgraded to L2" with a button to the Garage.
##   "news"     — like "event" but also flagged for the news feed (big signings, titles, top-tier
##                entries).
var _fired_once: Dictionary = {}   ## event_id -> true, persisted via serialize/deserialize

func _init(game_state) -> void:
	gs = game_state

## Framework entry point. event_id is a stable key used for once-firing and supersede.
func notify_event(event_id: String, priority: String, message: String,
		destination: String = "", mode: String = "event") -> void:
	match mode:
		"once":
			if _fired_once.get(event_id, false):
				return
			_fired_once[event_id] = true
			add_notification(priority, message, destination, "")
		"standing":
			add_notification(priority, message, destination, event_id)  ## event_id == subject
		"news":
			add_notification(priority, message, destination, "")
			_push_news(message)
		_:  ## "event"
			add_notification(priority, message, destination, "")

## Reset a once-fired event so it can fire again (e.g. after the condition is resolved and recurs,
## or at a new season). Optional — most "once" events stay fired for the whole save.
func reset_once(event_id: String) -> void:
	_fired_once.erase(event_id)

func _push_news(message: String) -> void:
	## S37.64 — news_feed is a typed Array[String]; push the message string (the old stub pushed a
	## Dictionary, which crashed against the typed array). Genuine news from notify_event(mode:"news")
	## lands here; the dedicated GameState.log_news() path appends here too via add_log-adjacent calls.
	if "news_feed" in gs:
		gs.news_feed.append(message)
		gs.emit_signal("log_updated")

func add_notification(priority: String, message: String, destination: String = "", subject: String = "") -> void:
	# ── S35.1: subject supersede (recurring-notification collapse) ──────────────
	# A notification with a `subject` represents a STANDING condition that re-fires each
	# week (no car for champ X, no fuel, no championship registered, delivery deadline).
	# Remove any prior notification on the same subject so only the CURRENT week's instance
	# survives — even if its text changed (a delivery week / deadline embedded in the
	# message would defeat the identical-text dedup below). This runs for ALL priorities,
	# including Critical, so a critical weekly reminder collapses to its latest instance
	# rather than stacking (it is still SHOWN — supersede replaces, it does not suppress).
	if subject != "":
		var had_unread := false
		gs.notifications = gs.notifications.filter(func(n):
			if n.get("subject", "") == subject:
				if not n.get("read", false):
					had_unread = true
				return false   ## drop the superseded prior instance
			return true
		)
		## Keep the unread counter honest after dropping a possibly-unread prior instance.
		if had_unread and gs.unread_notification_count > 0:
			gs.unread_notification_count -= 1

	# Bug 5 (S31.1): suppress noise from standing notifications re-firing every week.
	# Skip if an identical (non-Critical) message is ALREADY UNREAD in the panel —
	# no point stacking the same "assign a driver" reminder week after week. Once the
	# player reads or dismisses it, it may fire again if the condition still holds.
	# Critical always shows (e.g. bankruptcy risk must re-fire each week).
	# S35.1: subject-bearing notifications already collapsed above and MUST be appended
	# (otherwise the unread-count decrement from supersede leaves the panel empty for that
	# subject) — so this identical-text guard only applies to no-subject standing messages.
	if priority != "Critical" and subject == "":
		for n in gs.notifications:
			if n["message"] == message and not n.get("read", false):
				return
	# priority: "Critical", "High", "Normal"
	gs.notifications.append({
		"priority":    priority,
		"message":     message,
		"destination": destination,
		"subject":     subject,
		"week":        gs.current_week,
		"season":      gs.current_season,
		"read":        false,
	})
	gs.unread_notification_count += 1
	gs.emit_signal("notifications_updated")
	## S37.62 — notifications are NOT news. They live in the Notification panel only; mirroring
	## Critical/High into the weekly_log polluted the NEWS panel with readiness reminders
	## ("driver seat unfilled", "no mechanic"). The NEWS/event log is fed exclusively by genuine
	## news events (see _push_news / log_news_event), per GDD §12.


func mark_all_notifications_read() -> void:
	for n in gs.notifications:
		n["read"] = true
	gs.unread_notification_count = 0
	gs.emit_signal("notifications_updated")

## Dismiss a single notification by index — removes it entirely.


func dismiss_notification(index: int) -> void:
	if index >= 0 and index < gs.notifications.size():
		gs.notifications.remove_at(index)
		gs.unread_notification_count = 0
		for n in gs.notifications:
			if not n["read"]:
				gs.unread_notification_count += 1
		gs.emit_signal("notifications_updated")

## S37.38 — Delete ALL notifications at once (Main Hub "Delete All" button).
func clear_all_notifications() -> void:
	gs.notifications.clear()
	gs.unread_notification_count = 0
	gs.emit_signal("notifications_updated")

## Snooze a notification — pushes its week forward so it won't show until then.


func snooze_notification(index: int, weeks: int) -> void:
	if index >= 0 and index < gs.notifications.size():
		gs.notifications[index]["week"] = gs.current_week + weeks
		gs.notifications[index]["read"] = true
		gs.unread_notification_count = 0
		for n in gs.notifications:
			if not n["read"]:
				gs.unread_notification_count += 1
		gs.emit_signal("notifications_updated")

## Returns count of unread Critical notifications specifically.


func _purge_old_notifications(keep_weeks: int = 2) -> void:
	var cutoff_week = gs.current_week - keep_weeks
	gs.notifications = gs.notifications.filter(func(n):
		return not n["read"] or n["week"] >= cutoff_week
	)
	gs.unread_notification_count = 0
	for n in gs.notifications:
		if not n["read"]:
			gs.unread_notification_count += 1
	gs.emit_signal("notifications_updated")


func get_critical_count() -> int:
	var count = 0
	for n in gs.notifications:
		if not n["read"] and n["priority"] == "Critical":
			count += 1
	return count

## Removes notifications that have been read AND are older than keep_weeks.
## Called each week to prevent pile-up.


func add_log(message: String) -> void:
	gs.weekly_log.append(message)
	print(message)

## ScreenShot Function


func _check_resource_notifications() -> void:
	# S35.1: every standing weekly notification below carries a `subject` so it collapses to its
	# current-week instance instead of stacking one per advanced week. Per-champ / per-part
	# subjects embed the id so distinct items stay separate while each collapses over time.

	# SP warnings
	if gs.spare_parts <= 0:
		add_notification("Critical", "No spare parts remaining! Buy more at the Logistics Center to repair your car.", "", "res_spare_parts")
	elif gs.active_championship != null and gs.spare_parts < gs.active_championship.sp_per_10_pct_damage:
		add_notification("High", "Spare parts low (%d units). Not enough to repair 10%% damage." % gs.spare_parts, "", "res_spare_parts")

	# Fuel warnings
	if gs.active_championship != null:
		var fuel_needed = gs.active_championship.fuel_per_car_per_race
		if gs.fuel_kg <= 0.0:
			add_notification("Critical", "No fuel remaining! Buy more at the Logistics Center before next race.", "", "res_fuel")
		elif gs.fuel_kg < fuel_needed:
			add_notification("High", "Fuel running low (%.1f kg). Less than 1 race worth remaining." % gs.fuel_kg, "", "res_fuel")

	# No car for running championship warning — only player's registered championships
	for champ_id in gs.player_registered_championships:
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
		var champ_name = reg.get("name", champ_id)
		var cars_for_champ = gs.player_team_cars.filter(func(c): return c.championship_id == champ_id)
		if cars_for_champ.is_empty():
			var race1_week = gs.FIRST_RACE_WEEK.get(champ_id, 6)
			if gs.current_week >= race1_week - 4:
				add_notification("Critical",
					"🚨 No car entered for %s! Race 1 is Week %d — buy a car at the Logistics Center or you will DNS all races." % [champ_name, race1_week],
					"logistics", "res_no_car_%s" % champ_id)

	# Bankruptcy warning
	var weekly_expenses = 1250
	if gs.player_team.balance < 0:
		add_notification("Critical", "BANKRUPTCY RISK: Balance is negative (CR %.0f)!" % gs.player_team.balance, "", "res_bankruptcy")
	elif gs.player_team.balance < weekly_expenses * 2:
		add_notification("High", "Low funds warning: Less than 2 weeks of expenses remaining.", "", "res_bankruptcy")


func _check_part_inventory_notifications() -> void:
	## CFO reminds player if any part stock is at or below warning threshold.
	## Only fires if player has a CFO hired.
	var has_cfo = gs.get_player_staff_by_role("CFO").size() > 0
	if not has_cfo:
		return
	var champ_id = gs.active_championship.id
	if not champ_id in gs.part_inventory:
		return
	for part in gs.PARTS_LIST:
		var stock = gs.part_inventory[champ_id].get(part, 0)
		if stock <= gs.CFO_PART_WARNING_THRESHOLD:
			add_notification("High",
				"💼 CFO: %s parts stock critically low (%d remaining). A part failure means DNF — buy replacements at Logistics Center." % [part, stock],
				"", "res_part_stock_%s" % part)


func get_pending_tasks() -> Array[String]:
	var tasks: Array[String] = []

	## Step 1 — No car for ACTIVE championships (not next-season registrations)
	var active_champ_ids: Array = []
	for champ in gs.active_championships:
		active_champ_ids.append(champ.id)

	for reg_champ_id in gs.player_registered_championships:
		if not reg_champ_id in active_champ_ids:
			continue  ## Next-season registration — BeginOfSeason handles it
		var has_car = false
		for car in gs.player_team_cars:
			if car.championship_id == reg_champ_id:
				has_car = true
				break
		if not has_car:
			var reg = gs.CHAMPIONSHIP_REGISTRY.get(reg_champ_id, {})
			tasks.append("🏎 No car for %s — buy one at Logistics Center." % reg.get("name", reg_champ_id))

	## Step 2 — Cars exist: check driver/mechanic/pit crew assignment
	## Only show these if the car exists (don't pile on when car not bought yet)
	for car in gs.player_team_cars:
		## Skip if this car's championship has no car task above (redundant check — car exists)
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
		var champ_name = reg.get("name", car.championship_id)
		var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
		if not car.all_seats_filled():
			if gs.player_team.drivers.is_empty():
				tasks.append("🚫 No drivers signed — hire one from Drivers screen (car will DNS).")
			elif car.seat_count() > 1:
				var _e = car.seat_count() - car.assigned_driver_ids().size()
				tasks.append("🏎 %s [%s] — %d of %d driver seats empty. Go to Garage." % [car_label, champ_name, _e, car.seat_count()])
			else:
				tasks.append("🏎 %s [%s] — no driver assigned. Go to Garage." % [car_label, champ_name])
		if car.mechanic_id == "":
			var has_mechanic = false
			for sid in gs.all_staff:
				var s = gs.all_staff[sid]
				if s.role == "Race Mechanic" and s.contract_team == gs.player_team.id:
					has_mechanic = true
					break
			if not has_mechanic:
				tasks.append("🚫 No Race Mechanic hired — hire one from Staff screen (car will DNS).")
			else:
				tasks.append("🚫 %s [%s] — no mechanic assigned. Go to Garage (car will DNS)." % [car_label, champ_name])
		if gs.get_pit_crew_required(car.championship_id):
			if car.pit_crew_id == "" or car.pit_crew_id == "N/A":
				tasks.append("⏱ %s [%s] — no Pit Crew. Assign in Pit Crew Arena." % [car_label, champ_name])

	## Step 3 — Team Principal missing for a championship the PLAYER actually fields a car in.
	## S37.43 — BUGFIX: the old check keyed on has_gk_active = "any GK championship is in
	## active_championships", but GK (C-001) is ALWAYS in the world, so a non-GK player (e.g. SC Dev
	## Cup) wrongly got a "no TP for GK" TDL while their real championships were never checked. And
	## the non-GK branch iterated ALL active_championships (every AI series). Now we derive the
	## player's championships from the cars they actually field and check a TP per discipline-group.
	## GK shares ONE TP across all its tiers; non-GK championships each need their own.
	var player_champ_ids: Array = []
	for car in gs.player_team_cars:
		if car.championship_id != "" and not car.championship_id in player_champ_ids:
			player_champ_ids.append(car.championship_id)
	var gk_player_champs: Array = []
	var nongk_missing_tp: Array = []
	for cid in player_champ_ids:
		var creg = gs.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var cdisc = creg.get("discipline", "")
		if cdisc == "GK":
			gk_player_champs.append(cid)
		else:
			if gs._get_tp_for_championship(cid) == null:
				nongk_missing_tp.append(creg.get("name", cid))
	## GK: one TP covers all GK tiers the player fields.
	if not gk_player_champs.is_empty():
		var gk_tp_ok := false
		for cid in gk_player_champs:
			if gs._get_tp_for_championship(cid) != null:
				gk_tp_ok = true
				break
		if not gk_tp_ok:
			if gs.get_player_staff_by_role("Team Principal").size() == 0:
				tasks.append("🚫 No Team Principal — hire one from Staff screen (car will DNS).")
			else:
				tasks.append("🚫 GK has no Team Principal assigned. Go to Racing Department (car will DNS).")
	if nongk_missing_tp.size() > 0:
		tasks.append("🚫 No Team Principal for: %s (car will DNS)." % ", ".join(nongk_missing_tp))

	## Step 3a — Race Strategist missing. S37.50: previously deferred (tied to the new-game Ops Sim
	## building bug, now fixed). A Strategist is required in every discipline EXCEPT GK and Rally
	## (same rule as TPProposalEngine: disc not in {GK, Rally}). Checked per-championship the player
	## actually fields a car in. The Strategist occupies an Ops Sim & Telemetry slot.
	var missing_strategist: Array = []
	for cid in player_champ_ids:
		var sreg = gs.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var sdisc = sreg.get("discipline", "")
		if sdisc == "GK" or sdisc == "Rally":
			continue
		if gs._get_strategist_for_championship(cid) == null:
			missing_strategist.append(sreg.get("name", cid))
	if missing_strategist.size() > 0:
		tasks.append("🚫 No Race Strategist for: %s (car will DNS)." % ", ".join(missing_strategist))
	## CFO is OPTIONAL ("good to have"). It appears as a READ-ONLY TO-DO row while missing (the
	## player can see the list; the TDL never fires notifications). The one-time "no CFO"
	## notification is handled separately by notify_event("no_cfo", ..., "once") in GameState.
	if gs.get_cfo() == null:
		tasks.append("💼 No CFO (optional) — hire one from the Staff screen for financial perks.")
		## S40.0 — extra read-only TDL line: without a CFO the Factory burns full upkeep for zero
		## output and contract/loan/market perks are all forfeit, so the whole money side runs
		## under-tuned. Surfaced as its own row so the cost of the empty CFO seat is explicit.
		tasks.append("📉 Financial Department is not optimized.")

	## Step 4 — Resources
	## Low SP — only warn when races are still coming
	if gs.has_remaining_races_this_season():
		if gs.spare_parts < 20:
			tasks.append("🔧 Spare parts low (%d units) — buy at Logistics." % gs.spare_parts)
		## Low fuel — only warn when race approaching
		if gs.active_championship != null:
			var next_race = gs.active_championship.get_next_race()
			if next_race:
				var weeks_until = next_race["week"] - gs.current_week
				if weeks_until <= 2 and gs.fuel_kg < gs.active_championship.fuel_per_car_per_race:
					tasks.append("⛽ Fuel below race minimum (%.0f kg) — buy at Logistics." % gs.fuel_kg)

	## Step 5 — Financial
	if gs.player_team.balance < 0:
		tasks.append("💸 Balance negative (CR %s). Bankruptcy risk." % gs._fmt_int(int(gs.player_team.balance)))

	## Step 6 — Car condition
	for car in gs.player_team_cars:
		if car.condition < 30.0:
			tasks.append("🔩 %s condition critical (%.0f%%) — repair in Garage." % [
				car.car_name if car.car_name != "" else "Car %d" % car.car_number, car.condition])

	## Step 7 — Expiring contracts
	for driver_id in gs.player_team.drivers:
		var driver = gs.all_drivers.get(driver_id)
		if driver and driver.contract_seasons_remaining <= 1:
			tasks.append("📋 %s contract expires soon." % driver.full_name())
	for staff_id in gs.all_staff:
		var staff = gs.all_staff[staff_id]
		if staff.contract_team == gs.player_team.id and staff.contract_seasons_remaining <= 1:
			tasks.append("📋 %s (%s) contract expires soon." % [staff.full_name(), staff.role])

	## Step 7b — Pending negotiations awaiting player response
	for ap in gs.active_approaches:
		if ap.get("draft", false): continue  ## S37.39 — drafts aren't live; no TDL until acted on
		if ap["status"] in ["failed","rejected","expired","activated","agreed"]: continue
		match ap["status"]:
			"bond_incoming":
				tasks.append("💰 %s wants %s — respond to their bond offer." % [
					ap.get("approaching_team_name","AI Team"), ap["subject_name"]])
			"approaching":
				match ap.get("bond_status", ""):
					"awaiting_team":
						tasks.append("📤 Bond approach sent to %s's team — reply expected next week." % ap["subject_name"])
					"countered":
						tasks.append("💰 %s's team wants CR %s — accept, counter or reject in HQ." % [
							ap["subject_name"], gs._fmt_int(int(ap.get("bond_team_ask", 0)))])
					"offered":
						tasks.append("📤 Your bond offer for %s is with their team — reply next week." % ap["subject_name"])
					_:
						tasks.append("📤 Bond approach for %s in progress." % ap["subject_name"])
			"negotiating":
				var rounds_left = ap.get("max_contract_rounds",4) - ap.get("contract_round",1)
				if ap.get("player_turn", true):
					if ap.get("contract_round", 1) == 1:
						## S37.9 — a player-initiated renegotiation that the player opened but has
						## NOT yet submitted an offer for should not nag them ("make your opening
						## offer") — they're already in the dialog. Only show it once a real
						## back-and-forth exists (offer submitted) or for AI-initiated approaches.
						if ap.get("player_initiated", false) and not ap.get("offer_submitted", false):
							pass
						else:
							tasks.append("📋 Negotiations open: %s — make your opening offer." % ap["subject_name"])
					else:
						tasks.append("📋 Contract Round %d/%d with %s — their reply received, respond now." % [
							ap.get("contract_round",1), ap.get("max_contract_rounds",4), ap["subject_name"]])
				else:
					tasks.append("📋 Offer sent to %s — awaiting their reply (Round %d/%d)." % [
						ap["subject_name"], ap.get("contract_round",1), ap.get("max_contract_rounds",4)])

	## Step 8 — R&D → WRA → CNC → Garage pipeline
	## 8a: Blueprints ready but not yet submitted to WRA
	## - Next-season blueprints (P1/P3): always remind
	## - Current-season P2 upgrades: also remind (need WRA this season)
	for bp_id in gs.known_blueprints:
		if not gs.is_blueprint_submitted(bp_id) and not gs.is_blueprint_approved(bp_id):
			var bp = gs.known_blueprints[bp_id]
			var bp_season = bp.get("season", gs.current_season)
			var bp_pillar = bp.get("pillar", 1)
			var is_next_season = bp_season > gs.current_season
			var is_current_p2  = bp_pillar == 2 and bp_season == gs.current_season
			if is_next_season or is_current_p2:
				tasks.append("📐 Blueprint ready: '%s' — submit to WRA for approval." % bp.get("name", bp_id))
				break

	## 8b: WRA-approved blueprints with NO part yet (not queued, not in warehouse, not
	## installed). S35.11: the approval now persists after building (issue 3), so this must
	## check for an actual part anywhere — otherwise it would nag forever after the first build.
	var unqueued_approvals = gs.wra_approved_blueprints.filter(func(app):
		var bp_id = app.blueprint_id
		## In production queue?
		for job in gs.cnc_production_queue:
			if job.get("blueprint_id","") == bp_id: return false
		## In warehouse inventory?
		for inv_key in gs.cnc_parts_inventory:
			var it = gs.cnc_parts_inventory[inv_key]
			if it is Dictionary and it.get("blueprint_id","") == bp_id \
				and it.get("quantity",0) > 0: return false
		## Installed on any car?
		for cid in gs.car_installed_parts:
			for pc in gs.car_installed_parts[cid]:
				var pd = gs.car_installed_parts[cid][pc]
				if pd is Dictionary and pd.get("blueprint_id","") == bp_id: return false
		return true)
	if not unqueued_approvals.is_empty():
		var bp = gs.known_blueprints.get(unqueued_approvals[0].blueprint_id, {})
		tasks.append("⚙ WRA approved: '%s' — queue manufacturing in CNC Plant." % bp.get("name", unqueued_approvals[0].blueprint_id))

	## 8c: CNC parts in inventory not yet installed on any car
	for inv_key in gs.cnc_parts_inventory:
		var item = gs.cnc_parts_inventory[inv_key]
		var qty = item.get("quantity", 0) if item is Dictionary else int(item)
		if qty > 0:
			var part = item.get("part", inv_key) if item is Dictionary else inv_key
			## Check if already installed on every car
			var all_installed = true
			for car in gs.player_team_cars:
				if car.championship_id == item.get("championship_id",""):
					var inst = gs.get_installed_parts_for_car(car.id)
					var pcode = item.get("part_code","") if item is Dictionary else ""
					if pcode == "" or not pcode in inst:
						all_installed = false
						break
			if not all_installed:
				tasks.append("🔩 CNC part in warehouse: %s — install it in Garage." % part)
				break  ## One reminder per week

	## Step 9 — New game: no car bought yet, no championships active
	if gs.player_team_cars.is_empty() and gs.active_championships.size() <= 1 \
			and gs.player_registered_championships.is_empty():
		tasks.append("🏎 Welcome! Buy your first car at the Logistics Center to get started.")

	## Step 10 — No championships registered for next season (mid/late season warning)
	## Only fire after Week 20 so it doesn't spam at season start
	if gs.current_week >= 20 and gs.player_registered_championships.is_empty() \
			and not gs.active_championships.is_empty():
		tasks.append("📋 No championships registered for next season — register in HQ → WRA.")

	## Step 11 — Commitment (type-3) sponsors require racing a SPECIFIC championship NEXT SEASON.
	## The TDL clears only once the player has COMMITTED for next season (next_season_registrations) —
	## NOT merely because they race it this season (a re-commit sponsor for the championship you're
	## currently in still needs you to register for next season, or you owe that season back).
	## (S37.40 — per design: championship sponsors must drive a TDL, not just a notice.)
	for sp in gs.active_sponsors:
		if sp.get("type", 0) != 3: continue
		var champ_id: String = sp.get("championship_id", "")
		if champ_id == "": continue
		if champ_id in gs.next_season_registrations: continue
		var champ_name: String = champ_id
		var reg: Dictionary = gs.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
		if reg.has("name"): champ_name = reg["name"]
		tasks.append("🤝 %s requires racing %s — register for it next season (HQ → WRA)." % [
			sp.get("name", "Sponsor"), champ_name])

	## S38.7 — Commercial: a researched model blueprint with no production line yet → build it.
	## Resolves automatically once a line for that segment exists (or the blueprint is unbuilt).
	if gs._commercial_market != null and gs.get_cfo() != null:
		var fac = gs.campus_buildings.get("Vehicle Assembly Factory", {})
		if fac.get("built", false) and int(fac.get("level", 0)) >= 1:
			for seg_key in gs._commercial_market.segment_keys():
				if gs.is_commercial_blueprint_researched(seg_key) and not gs.has_commercial_line_for(seg_key):
					if gs.commercial_free_lines() > 0:
						tasks.append("🏭 %s blueprint ready — build it on a production line (Commercial Department)." % gs._commercial_market.segment_name(seg_key))

	## Auto-clean custom_todo_items that are no longer relevant
	## (e.g. "Assign a driver to Car X" after driver has been assigned)
	var to_remove: Array = []
	for item in gs.custom_todo_items:
		## S37.62 — purge legacy deadline variants that embedded a changing week count
		## ("... Race in N week(s)!"); these piled up one-per-week before the stable-text fix.
		if "Race in" in item and "week" in item:
			to_remove.append(item)
			continue
		## S37.64 — purge legacy TP count-bearing variants ("TP has N assignment(s) ready"); the
		## stable item is now "TP assignments ready — Racing Department" (no count) so old ones go.
		if "TP has" in item and "ready" in item:
			to_remove.append(item)
			continue
		if _is_todo_item_resolved(item):
			to_remove.append(item)
	for item in to_remove:
		gs.custom_todo_items.erase(item)

	## Custom injected items (TP proposals, etc.)
	for item in gs.custom_todo_items:
		tasks.append(item)

	return tasks.filter(func(t): return not t in gs.dismissed_todo_items)

## Returns true if a custom TDL item is no longer relevant and can be auto-removed.


func _is_todo_item_resolved(item: String) -> bool:
	## S37.62 — TP deadline reminders (stable text). Resolve when the car is crewed / has a mechanic.
	if "driver seat unfilled. Go to Garage." in item:
		for car in gs.player_team_cars:
			var cl = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			if cl in item and car.all_seats_filled():
				return true
		return false   ## still unfilled (or car gone) → keep until a matching car is crewed
	if "no mechanic. Go to Garage." in item:
		for car in gs.player_team_cars:
			var cl = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			if cl in item and car.mechanic_id != "":
				return true
		return false
	## "Assign a driver to Car X [Champ Y]" — resolved if car now has a driver
	if "Assign a driver to" in item:
		for car in gs.player_team_cars:
			var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			if car_label in item and car.all_seats_filled():
				return true
	## "Assign a mechanic to Car X [Champ Y]" — resolved if car now has mechanic
	if "Assign a mechanic to" in item:
		for car in gs.player_team_cars:
			var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			if car_label in item and car.mechanic_id != "":
				return true
	## "GK TP: assignment update" — resolved if GK TP is now assigned
	if "GK TP:" in item:
		for champ in gs.active_championships:
			if champ.discipline == "GK" and gs._get_tp_for_championship(champ.id) != null:
				return true
	## "Assign X as GK Team Principal" — resolved if any GK TP assigned
	if "GK Team Principal" in item:
		for champ in gs.active_championships:
			if champ.discipline == "GK" and gs._get_tp_for_championship(champ.id) != null:
				return true
	## "Assign X as Team Principal for Y" — resolved if TP now assigned to that champ
	if "Team Principal for" in item:
		for champ in gs.active_championships:
			if champ.championship_name in item and gs._get_tp_for_championship(champ.id) != null:
				return true
	return false


func add_todo_item(item_text: String) -> void:
	if not item_text in gs.custom_todo_items and not item_text in gs.dismissed_todo_items:
		gs.custom_todo_items.append(item_text)
		gs.emit_signal("log_updated")


func dismiss_todo_item(item_text: String) -> void:
	if not item_text in gs.dismissed_todo_items:
		gs.dismissed_todo_items.append(item_text)
	gs.emit_signal("log_updated")


func clear_dismissed_todo_items() -> void:
	gs.dismissed_todo_items.clear()
	gs.emit_signal("log_updated")

## Weekly pit crew fitness recovery.


func _clear_notifications_containing(substring: String) -> void:
	gs.notifications = gs.notifications.filter(func(n): return not substring in n["message"])
	gs.unread_notification_count = 0
	for n in gs.notifications:
		if not n["read"]: gs.unread_notification_count += 1
	gs.emit_signal("notifications_updated")

## Small chance of sponsor approach after a good race
