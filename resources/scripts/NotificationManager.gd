class_name NotificationManager
## Version: S31.1 — Bug 5: cross-week dedup. add_notification now suppresses an identical
##   non-Critical message while it is still UNREAD (instead of only within the same week),
##   so standing reminders ("assign a driver") stop restacking every week. Re-fires after
##   the player reads/dismisses if still relevant. Critical always shows.
## --- S27.0 — Extracted from GameState.gd (P57)
##   Notifications, TDL, logging, resource warnings.
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

func add_notification(priority: String, message: String, destination: String = "") -> void:
	# Bug 5: suppress noise from standing notifications re-firing every week.
	# Skip if an identical (non-Critical) message is ALREADY UNREAD in the panel —
	# no point stacking the same "assign a driver" reminder week after week. Once the
	# player reads or dismisses it, it may fire again if the condition still holds.
	# Critical always shows (e.g. bankruptcy risk must re-fire each week).
	if priority != "Critical":
		for n in gs.notifications:
			if n["message"] == message and not n.get("read", false):
				return
	# priority: "Critical", "High", "Normal"
	gs.notifications.append({
		"priority":    priority,
		"message":     message,
		"destination": destination,
		"week":        gs.current_week,
		"season":      gs.current_season,
		"read":        false,
	})
	gs.unread_notification_count += 1
	gs.emit_signal("notifications_updated")
	# Also log critical ones
	if priority == "Critical":
		add_log("🔴 CRITICAL: %s" % message)
	elif priority == "High":
		add_log("🟠 %s" % message)


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
	# SP warnings
	if gs.spare_parts <= 0:
		add_notification("Critical", "No spare parts remaining! Buy more at the Logistics Center to repair your car.")
	elif gs.active_championship != null and gs.spare_parts < gs.active_championship.sp_per_10_pct_damage:
		add_notification("High", "Spare parts low (%d units). Not enough to repair 10%% damage." % gs.spare_parts)

	# Fuel warnings
	if gs.active_championship != null:
		var fuel_needed = gs.active_championship.fuel_per_car_per_race
		if gs.fuel_kg <= 0.0:
			add_notification("Critical", "No fuel remaining! Buy more at the Logistics Center before next race.")
		elif gs.fuel_kg < fuel_needed:
			add_notification("High", "Fuel running low (%.1f kg). Less than 1 race worth remaining." % gs.fuel_kg)

	# No car for running championship warning — only player's registered championships
	for champ_id in gs.player_registered_championships:
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
		var champ_name = reg.get("name", champ_id)
		var cars_for_champ = gs.player_team_cars.filter(func(c): return c.championship_id == champ_id)
		if cars_for_champ.is_empty():
			var race1_week = gs.FIRST_RACE_WEEK.get(champ_id, 6)
			if gs.current_week >= race1_week - 4:
				add_notification("Critical",
					"🚨 No car entered for %s! Race 1 is Week %d — buy a car at the Logistics Center or you will DNS all races." % [champ_name, race1_week])

	# Bankruptcy warning
	var weekly_expenses = 1250
	if gs.player_team.balance < 0:
		add_notification("Critical", "BANKRUPTCY RISK: Balance is negative (CR %.0f)!" % gs.player_team.balance)
	elif gs.player_team.balance < weekly_expenses * 2:
		add_notification("High", "Low funds warning: Less than 2 weeks of expenses remaining.")


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
				"💼 CFO: %s parts stock critically low (%d remaining). A part failure means DNF — buy replacements at Logistics Center." % [part, stock])


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
		if car.driver_id == "":
			if gs.player_team.drivers.is_empty():
				tasks.append("👤 No drivers signed — hire one from Drivers screen.")
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
				tasks.append("🔧 No Race Mechanic hired — hire one from Staff screen.")
			else:
				tasks.append("🔧 %s [%s] — no mechanic assigned. Go to Garage." % [car_label, champ_name])
		if gs.get_pit_crew_required(car.championship_id):
			if car.pit_crew_id == "" or car.pit_crew_id == "N/A":
				tasks.append("⏱ %s [%s] — no Pit Crew. Assign in Pit Crew Arena." % [car_label, champ_name])

	## Step 3 — Staff roles missing
	## GK discipline: one TP for all tiers combined
	var has_gk_active = false
	var gk_tp_ok = false
	for champ in gs.active_championships:
		if champ.discipline == "GK":
			has_gk_active = true
			if gs._get_tp_for_championship(champ.id) != null:
				gk_tp_ok = true
	if has_gk_active and not gk_tp_ok:
		var has_any_tp = gs.get_player_staff_by_role("Team Principal").size() > 0
		if not has_any_tp:
			tasks.append("⚠ No Team Principal — hire one from Staff screen.")
		else:
			tasks.append("⚠ GK disciplines have no Team Principal assigned. Go to Racing Department.")
	elif not has_gk_active:
		## Non-GK: check each active championship
		var non_gk_missing_tp: Array = []
		for champ in gs.active_championships:
			if champ.discipline == "GK": continue
			if gs._get_tp_for_championship(champ.id) == null:
				non_gk_missing_tp.append(champ.championship_name)
		if non_gk_missing_tp.size() > 0:
			tasks.append("⚠ No Team Principal for: %s" % ", ".join(non_gk_missing_tp))
	if gs.get_cfo() == null:
		tasks.append("💼 No CFO hired — hire one from Staff screen.")

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
		if ap["status"] in ["failed","rejected","expired","activated","agreed"]: continue
		match ap["status"]:
			"bond_incoming":
				tasks.append("💰 %s wants %s — respond to their bond offer." % [
					ap.get("approaching_team_name","AI Team"), ap["subject_name"]])
			"approaching":
				tasks.append("📤 Bond approach sent to %s's team — reply expected next week." % ap["subject_name"])
			"negotiating":
				var rounds_left = ap.get("max_contract_rounds",4) - ap.get("contract_round",1)
				if ap.get("player_turn", true):
					if ap.get("contract_round", 1) == 1:
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

	## 8b: WRA-approved blueprints waiting to be manufactured
	var unqueued_approvals = gs.wra_approved_blueprints.filter(func(app):
		for job in gs.cnc_production_queue:
			if job.get("blueprint_id","") == app.blueprint_id: return false
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

	## Auto-clean custom_todo_items that are no longer relevant
	## (e.g. "Assign a driver to Car X" after driver has been assigned)
	var to_remove: Array = []
	for item in gs.custom_todo_items:
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
	## "Assign a driver to Car X [Champ Y]" — resolved if car now has a driver
	if "Assign a driver to" in item:
		for car in gs.player_team_cars:
			var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			if car_label in item and car.driver_id != "":
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
