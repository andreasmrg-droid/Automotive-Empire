## Version: S37.24 — layout: driver-row fonts reduced (30→26/26→24/24→22) for a lighter left
##   column; right column widened 340→360; _stat_row/_section_label clip+ellipsis (S37.23) keep
##   championship names / TP-panel text inside the column.
extends Control
## Version: S37.23 — popup-position: right column widened 300→340; _stat_row + _section_label
##   values now expand+clip+ellipsis so championship names / TP-panel text stop clipping off-screen.
## Version: S37.16 — #41: driver-assign shows a modal popup on age-limit failure (kept open so a
##   different car can be chosen).
## Version: S36.9 — Removed the Racing World button from the championship panel (redundant — the
##   header already has one). Wrapped the right column in a ScrollContainer so the now-multi-entry
##   championship list (up to 21) plus TP-proposals and effects panels can't overflow the screen.
## Version: S36.8 — Bug #9/#19 (cluster A): driver standings now look up each driver's position in
##   THEIR OWN car's championship (was the singular active_championship = GK). The championship summary
##   panel is now a PER-CHAMPIONSHIP LIST (one block per registered championship: name/discipline/
##   round/cars) instead of showing only GK, and gained a Racing World button. Uses GameState
##   get_championship_by_id() / player_registered_championships.
## Version: S32.3 — TP panel now uses GameState.peek_tp_proposals() (read-only compute, no
##   notification/TDL) instead of generate_tp_assignment_proposals(), which re-fired the TP
##   notification + TDL every time the panel was built. Pairs with the engine S32.3
##   skip-already-assigned fix so the panel clears after accepting.
## --- S31.2 — Fix: accepting TP proposals now refreshes the Racing Department scene.
##   The popup's closed signal called _build_ui() only, which clears _drivers_container but
##   never refills it (refresh() does); now it calls both, so newly-assigned drivers/mechanics
##   appear immediately and the proposals panel clears.
## --- S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## --- S29.0 — Not-interested popup on renewal decline (issue 1: visible AcceptDialog).
## --- S28.3 — Re-applied "Wet"→"Car Control" label (Batch B).
## --- S23.0 — TP proposals panel: new structured proposals with Accept All, per-item Accept/Skip, priority coloring.
##                    Accept button navigates to Garage for driver/mechanic needed proposals,
##                    Logistics for car_needed. TDL dismissal separate from proposal visibility.

# ── Node refs ─────────────────────────────────────────────────────────────────
var _drivers_container: VBoxContainer
var _empty_label: Label
var _lbl_slots: Label

# Assign car popup (reuses same panel for all drivers)
var _popup: PanelContainer
var _popup_title: Label
var _popup_list: VBoxContainer
var _assigning_driver_id: String = ""

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh()

func _build_ui() -> void:
	## Clear all existing children to prevent overlay on rebuild
	for c in get_children():
		c.queue_free()
	## Reset node refs so they get re-assigned below
	_drivers_container = null
	_empty_label = null
	_lbl_slots = null
	_popup = null
	_popup_title = null
	_popup_list = null

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   28)
	margin.add_theme_constant_override("margin_right",  28)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	margin.add_child(root_vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root_vbox.add_child(header)

	var building = GameState.campus_buildings.get("Racing Department", {})
	var level = building.get("level", 1)

	var lbl_title = Label.new()
	lbl_title.text = "🏎 RACING DEPARTMENT  ·  Level %d" % level
	lbl_title.add_theme_font_size_override("font_size", 44)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	_lbl_slots = Label.new()
	_lbl_slots.add_theme_font_size_override("font_size", 28)
	_lbl_slots.modulate = Color(0.7, 0.7, 0.7)
	header.add_child(_lbl_slots)

	var btn_racing_world = Button.new()
	btn_racing_world.text = Locale.t("rw_btn")
	btn_racing_world.custom_minimum_size = Vector2(140, 36)
	btn_racing_world.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/RacingWorld.tscn"))
	header.add_child(btn_racing_world)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(100, 36)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)

	root_vbox.add_child(HSeparator.new())

	# ── Two-column layout ─────────────────────────────────────────────────────
	var columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(columns)

	# ── Left: driver roster ───────────────────────────────────────────────────
	var left = VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)

	# Action bar — hire button
	var action_bar = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 10)
	left.add_child(action_bar)

	var btn_hire = Button.new()
	btn_hire.text = "Hire Driver →"
	btn_hire.custom_minimum_size = Vector2(160, 34)
	btn_hire.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Drivers.tscn"))
	action_bar.add_child(btn_hire)

	left.add_child(HSeparator.new())

	# Driver list scroll
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(scroll_vbox)

	_empty_label = Label.new()
	_empty_label.text = "No drivers signed.\nUse 'Hire Driver' to sign from the free agent pool."
	_empty_label.modulate = Color(0.5, 0.5, 0.5)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_label.visible = false
	scroll_vbox.add_child(_empty_label)

	_drivers_container = VBoxContainer.new()
	_drivers_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_drivers_container.add_theme_constant_override("separation", 10)
	scroll_vbox.add_child(_drivers_container)

	# ── Right: championship status + effects (scrollable — the championship list can
	# now hold up to 21 entries, so the column must scroll to avoid overflow) ──────
	var right_scroll = ScrollContainer.new()
	right_scroll.custom_minimum_size = Vector2(360, 0)
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(right_scroll)

	var right = VBoxContainer.new()
	right.add_theme_constant_override("separation", 14)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right)

	right.add_child(_section_label("CHAMPIONSHIP ENTRY"))
	right.add_child(_build_champ_panel())

	right.add_child(HSeparator.new())

	right.add_child(_section_label(Locale.t("rw_tp_proposals")))
	right.add_child(_build_tp_proposals_panel())

	right.add_child(HSeparator.new())

	right.add_child(_section_label("BUILDING EFFECTS"))
	right.add_child(_build_effects_panel())

	# ── Assign car popup ──────────────────────────────────────────────────────
	_popup = PanelContainer.new()
	_popup.set_anchors_preset(Control.PRESET_CENTER)
	_popup.custom_minimum_size = Vector2(400, 0)
	_popup.visible = false
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.10, 0.10, 0.13, 0.98)
	popup_style.border_width_left   = 2
	popup_style.border_width_right  = 2
	popup_style.border_width_top    = 2
	popup_style.border_width_bottom = 2
	popup_style.border_color = Color(0.4, 0.8, 1.0)
	popup_style.corner_radius_top_left     = 6
	popup_style.corner_radius_top_right    = 6
	popup_style.corner_radius_bottom_left  = 6
	popup_style.corner_radius_bottom_right = 6
	popup_style.content_margin_left   = 16
	popup_style.content_margin_right  = 16
	popup_style.content_margin_top    = 16
	popup_style.content_margin_bottom = 16
	_popup.add_theme_stylebox_override("panel", popup_style)
	add_child(_popup)

	var popup_vbox = VBoxContainer.new()
	popup_vbox.add_theme_constant_override("separation", 12)
	_popup.add_child(popup_vbox)

	var popup_hdr = HBoxContainer.new()
	popup_vbox.add_child(popup_hdr)

	_popup_title = Label.new()
	_popup_title.add_theme_font_size_override("font_size", 32)
	_popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_hdr.add_child(_popup_title)

	var btn_close = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(32, 32)
	btn_close.pressed.connect(func(): _popup.visible = false)
	popup_hdr.add_child(btn_close)

	popup_vbox.add_child(HSeparator.new())

	var popup_scroll = ScrollContainer.new()
	popup_scroll.custom_minimum_size = Vector2(0, 180)
	popup_vbox.add_child(popup_scroll)

	_popup_list = VBoxContainer.new()
	_popup_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_popup_list.add_theme_constant_override("separation", 8)
	popup_scroll.add_child(_popup_list)

# ── Refresh ───────────────────────────────────────────────────────────────────
func refresh() -> void:
	var max_d = GameState.get_max_drivers()
	var cur_d = GameState.player_team.drivers.size()
	_lbl_slots.text = "Driver Slots: %d / %d" % [cur_d, max_d]
	if cur_d >= max_d:
		_lbl_slots.modulate = Color(1.0, 0.55, 0.15)
	else:
		_lbl_slots.modulate = Color(0.7, 0.7, 0.7)
	_refresh_drivers()

func _refresh_drivers() -> void:
	for child in _drivers_container.get_children():
		child.queue_free()

	var drivers = GameState.get_player_drivers()
	_empty_label.visible = drivers.is_empty()

	for driver in drivers:
		_drivers_container.add_child(_build_driver_card(driver))

func _build_driver_card(driver) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.13, 0.16)
	style.border_width_left   = 3
	style.border_width_right  = 0
	style.border_width_top    = 0
	style.border_width_bottom = 0
	style.border_color = Color(0.4, 0.8, 1.0)
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left   = 14
	style.content_margin_right  = 12
	style.content_margin_top    = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Row 1 — name + overall + car + contract
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	vbox.add_child(row1)

	var lbl_name = Label.new()
	lbl_name.text = driver.full_name()
	lbl_name.add_theme_font_size_override("font_size", 26)
	lbl_name.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(lbl_name)

	var lbl_ovr = Label.new()
	lbl_ovr.text = "Ovr %.0f" % driver.get_overall_skill()
	lbl_ovr.add_theme_font_size_override("font_size", 24)
	lbl_ovr.add_theme_color_override("font_color", _skill_color(driver.get_overall_skill()))
	row1.add_child(lbl_ovr)

	var lbl_age = Label.new()
	lbl_age.text = "Age %d  ·  %s" % [driver.age, driver.nationality]
	lbl_age.add_theme_font_size_override("font_size", 22)
	lbl_age.modulate = Color(0.6, 0.6, 0.6)
	row1.add_child(lbl_age)

	# Row 2 — car + championship position
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 16)
	vbox.add_child(row2)

	var car = GameState.get_car_for_driver(driver.id)
	var car_lbl = Label.new()
	if car:
		var name = car.car_name if car.car_name != "" else "Car %d" % car.car_number
		car_lbl.text = "🏎 %s" % name
		car_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		car_lbl.text = "🏎 No car assigned"
		car_lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.15))
	car_lbl.add_theme_font_size_override("font_size", 22)
	row2.add_child(car_lbl)

	# Championship standing — look up in the driver's OWN car's championship, not the
	# singular active_championship (= GK). (Cluster A, Bug #9/#19.)
	var pos = 0
	var pts = 0
	var dcar = GameState.get_car_for_driver(driver.id)
	if dcar and dcar.championship_id != "":
		var dchamp = GameState.get_championship_by_id(dcar.championship_id)
		if dchamp:
			var sorted = dchamp.get_standings_sorted()
			for i in range(sorted.size()):
				if sorted[i]["driver_id"] == driver.id:
					pos = i + 1
					pts = sorted[i]["points"]
					break
	var lbl_champ = Label.new()
	lbl_champ.text = "P%d  ·  %d pts" % [pos, pts] if pos > 0 else "Not in standings"
	lbl_champ.add_theme_font_size_override("font_size", 22)
	lbl_champ.modulate = Color(0.65, 0.65, 0.65)
	row2.add_child(lbl_champ)

	var lbl_contract = Label.new()
	lbl_contract.text = "%d season%s left" % [
		driver.contract_seasons_remaining,
		"s" if driver.contract_seasons_remaining != 1 else ""]
	lbl_contract.add_theme_font_size_override("font_size", 22)
	lbl_contract.modulate = Color(1.0, 0.4, 0.4) if driver.contract_seasons_remaining <= 1 \
		else Color(0.6, 0.6, 0.6)
	row2.add_child(lbl_contract)

	# Row 3 — stat chips
	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 6)
	vbox.add_child(stats_row)
	for stat in [
		["Pace", driver.pace], ["Car Control", driver.car_control], ["Focus", driver.focus],
		["Craft", driver.race_craft], ["Cons", driver.consistency],
		["Fit", driver.fitness], ["Mktg", driver.marketability]
	]:
		stats_row.add_child(_stat_chip(stat[0], stat[1]))

	# Row 4 — action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var d_id = driver.id

	var btn_view = Button.new()
	btn_view.text = "📋 View Card"
	btn_view.custom_minimum_size = Vector2(110, 28)
	btn_view.pressed.connect(func(): _show_driver_card(d_id))
	btn_row.add_child(btn_view)

	var btn_assign = Button.new()
	btn_assign.text = "Assign Car" if not car else "Change Car"
	btn_assign.custom_minimum_size = Vector2(110, 28)
	btn_assign.pressed.connect(func(): _open_assign_popup(d_id))
	btn_row.add_child(btn_assign)

	if car:
		var btn_unassign = Button.new()
		btn_unassign.text = "Unassign Car"
		btn_unassign.custom_minimum_size = Vector2(110, 28)
		btn_unassign.pressed.connect(func(): _on_unassign_car(d_id))
		btn_row.add_child(btn_unassign)

	var btn_renew = Button.new()
	btn_renew.text = "📋 Renew Contract"
	btn_renew.custom_minimum_size = Vector2(140, 28)
	btn_renew.pressed.connect(func():
		## Trigger approach/negotiation for renewal
		var err = GameState.initiate_approach(d_id, "driver", "immediate")
		if err == "not_interested":
			_show_not_interested_popup(d_id)  ## S29.0 — visible popup, not just notification
		elif err != "":
			GameState.add_notification("High", err)
		elif err == "":
			var ap = GameState._get_approach_by_subject(d_id)
			if not ap.is_empty() and ap["status"] == "negotiating":
				var neg_panel = preload("res://scenes/ContractNegotiation.tscn").instantiate()
				get_tree().current_scene.add_child(neg_panel)
				neg_panel.open_approach(ap)
				neg_panel.closed.connect(func(): refresh())
				return
		refresh())
	btn_row.add_child(btn_renew)

	var btn_release = Button.new()
	btn_release.text = "Release"
	btn_release.custom_minimum_size = Vector2(80, 28)
	btn_release.modulate = Color(1.0, 0.5, 0.5)
	btn_release.pressed.connect(func(): _confirm_release(d_id))
	btn_row.add_child(btn_release)

	return panel

# ── TP Proposals panel ────────────────────────────────────────────────────────
func _build_tp_proposals_panel() -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var proposals = GameState._last_tp_proposals
	if proposals.is_empty() and not GameState.player_team_cars.is_empty():
		## Read-only compute (no notification/TDL side effects — see peek_tp_proposals).
		proposals = GameState.peek_tp_proposals()
		GameState._last_tp_proposals = proposals

	if proposals.is_empty():
		var lbl = Label.new()
		lbl.text = Locale.t("tp_popup_empty")
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.modulate = Color(0.4, 0.9, 0.4)
		vbox.add_child(lbl)
		return panel

	var assignable = proposals.filter(func(p): return p["type"] in ["assign_driver","assign_mechanic"])
	var critical   = proposals.filter(func(p): return p.get("priority","") == "critical")
	var warnings   = proposals.filter(func(p): return p.get("priority","") == "warning")

	## Summary line
	var lbl_sum = Label.new()
	lbl_sum.text = "%d assignment%s ready" % [assignable.size(), "s" if assignable.size() != 1 else ""]
	if critical.size() > 0:
		lbl_sum.text += "  ·  🚫 %d critical" % critical.size()
		lbl_sum.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	elif warnings.size() > 0:
		lbl_sum.text += "  ·  ⚠ %d warning%s" % [warnings.size(), "s" if warnings.size() != 1 else ""]
		lbl_sum.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	else:
		lbl_sum.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	lbl_sum.add_theme_font_size_override("font_size", 26)
	vbox.add_child(lbl_sum)

	## Review button — opens popup
	var btn_review = Button.new()
	btn_review.text = Locale.t("tp_popup_open_btn")
	btn_review.custom_minimum_size = Vector2(0, 36)
	btn_review.add_theme_font_size_override("font_size", 26)
	btn_review.modulate = Color(0.5, 0.78, 1.0)
	btn_review.pressed.connect(func(): _open_tp_popup())
	vbox.add_child(btn_review)

	return panel

func _open_tp_popup() -> void:
	var popup = preload("res://scenes/TPProposalsPopup.tscn").instantiate()
	get_tree().current_scene.add_child(popup)
	popup.open(GameState._last_tp_proposals)
	## Rebuild layout AND refresh the dynamic driver list. _build_ui() alone does not
	## repopulate driver cards (it clears _drivers_container; only refresh() refills it),
	## so without this the scene showed no update after accepting proposals.
	popup.closed.connect(func():
		_build_ui()
		refresh())

# ── Championship panel ────────────────────────────────────────────────────────
func _build_champ_panel() -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	## Per-championship list (cluster A, Bug #9/#19): the player's racing programme spans
	## multiple series, so list every registered championship instead of the singular
	## active_championship (= GK). (Resolved via player_registered_championships.)
	var player_champs: Array = []
	for cid in GameState.player_registered_championships:
		var pc = GameState.get_championship_by_id(cid)
		if pc:
			player_champs.append(pc)

	var hdr = Label.new()
	hdr.text = "🏆 Your Championships (%d)" % player_champs.size()
	hdr.add_theme_font_size_override("font_size", 28)
	hdr.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(hdr)

	if player_champs.is_empty():
		var none_lbl = Label.new()
		none_lbl.text = "No championship registrations this season. Register at HQ → World Racing Association."
		none_lbl.add_theme_font_size_override("font_size", 24)
		none_lbl.modulate = Color(0.6, 0.6, 0.6)
		none_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(none_lbl)
	else:
		for pc in player_champs:
			vbox.add_child(HSeparator.new())
			var cars_in = GameState.player_team_cars.filter(
				func(c): return c.championship_id == pc.id).size()
			vbox.add_child(_stat_row("Championship", pc.championship_name))
			vbox.add_child(_stat_row("Discipline", pc.discipline))
			vbox.add_child(_stat_row("Round", "%d / %d" % [pc.current_round, pc.num_races]))
			vbox.add_child(_stat_row("Cars", "%d built" % cars_in))

	# DNS risk warning
	var dns_risks = 0
	for car in GameState.player_team_cars:
		if car.driver_id == "" or car.mechanic_id == "":
			dns_risks += 1
	if dns_risks > 0:
		var lbl_warn = Label.new()
		lbl_warn.text = "⚠ %d car%s at DNS risk" % [
			dns_risks, "s" if dns_risks != 1 else ""]
		lbl_warn.add_theme_font_size_override("font_size", 24)
		lbl_warn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
		vbox.add_child(lbl_warn)

	return panel

# ── Effects panel ─────────────────────────────────────────────────────────────
func _build_effects_panel() -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var building = GameState.campus_buildings.get("Racing Department", {})
	var level = building.get("level", 1)
	var max_level = building.get("max_level", 89)

	var effects = [
		["Driver Slots",      "%d (Lv %d)" % [level, level]],
		["Morale Bonus",      "+%.0f%%" % (10.0 + (level - 1) * 5.0)],
		["Focus Bonus",       "+%.0f%%" % (10.0 + (level - 1) * 5.0)],
		["Maintenance",       "-$%s/wk" % _fmt(building.get("weekly_maintenance", 0))],
		["Level",             "%d / %d" % [level, max_level]],
	]

	for e in effects:
		vbox.add_child(_stat_row(e[0], e[1]))

	return panel

# ── Assign car popup ──────────────────────────────────────────────────────────
func _open_assign_popup(driver_id: String) -> void:
	_assigning_driver_id = driver_id
	var driver = GameState.all_drivers.get(driver_id)
	_popup_title.text = "Assign Car — %s" % (driver.full_name() if driver else "Driver")

	for child in _popup_list.get_children():
		child.queue_free()

	if GameState.player_team_cars.is_empty():
		var lbl = Label.new()
		lbl.text = "No cars built.\nBuild a car in the Garage first."
		lbl.modulate = Color(0.6, 0.6, 0.6)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_popup_list.add_child(lbl)
	else:
		for car in GameState.player_team_cars:
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)

			var car_name = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			var lbl = Label.new()
			lbl.text = car_name
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(lbl)

			# Show current occupant
			if car.driver_id != "" and car.driver_id != driver_id:
				var other = GameState.all_drivers.get(car.driver_id)
				var lbl_occ = Label.new()
				lbl_occ.text = "→ %s" % (other.full_name() if other else "?")
				lbl_occ.modulate = Color(0.55, 0.55, 0.55)
				lbl_occ.add_theme_font_size_override("font_size", 22)
				row.add_child(lbl_occ)

			var btn = Button.new()
			var already = car.driver_id == driver_id
			btn.text = "Assigned ✅" if already else "Assign"
			btn.disabled = already
			var car_id_cap = car.id
			btn.pressed.connect(func():
				var err = GameState.assign_driver_to_car(driver_id, car_id_cap)
				if err != "":
					_show_assign_blocked_popup(err)
					return   ## keep the assign popup open to pick a different car
				_popup.visible = false
				refresh()
			)
			row.add_child(btn)
			_popup_list.add_child(row)

	_popup.visible = true

func _on_unassign_car(driver_id: String) -> void:
	var car = GameState.get_car_for_driver(driver_id)
	if car:
		car.driver_id = ""
		var driver = GameState.all_drivers.get(driver_id)
		GameState.add_log("👤 %s unassigned from %s." % [
			driver.full_name() if driver else driver_id,
			car.car_name if car.car_name != "" else "Car %d" % car.car_number])
	refresh()

# ── Not-interested popup (S29.0) ───────────────────────────────────────────────
## Visible modal shown when a driver declines a renewal approach (was silent before).
func _show_not_interested_popup(subject_id: String) -> void:
	var subject = GameState.all_drivers.get(subject_id)
	if subject == null:
		subject = GameState.all_staff.get(subject_id)
	var name_str = subject.full_name() if subject else subject_id
	var dialog = AcceptDialog.new()
	dialog.title = Locale.t("ap_ni_popup_title")
	dialog.dialog_text = "%s\n\n%s" % [
		Locale.tf("ap_ni_popup_body", [name_str]), Locale.t("ap_ni_popup_hint")]
	dialog.ok_button_text = Locale.t("btn_close")
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

# ── Release confirmation ───────────────────────────────────────────────────────
func _confirm_release(driver_id: String) -> void:
	var driver = GameState.all_drivers.get(driver_id)
	var dialog = ConfirmationDialog.new()
	dialog.title = "Release Driver"
	dialog.dialog_text = "Release %s?\nThey will become a free agent." % \
		(driver.full_name() if driver else "this driver")
	dialog.ok_button_text = "Release"
	dialog.cancel_button_text = "Cancel"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func():
		GameState.release_driver(driver_id)
		dialog.queue_free()
		refresh()
	)
	dialog.canceled.connect(dialog.queue_free)

# ── Navigation ────────────────────────────────────────────────────────────────
func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

# ── Helpers ───────────────────────────────────────────────────────────────────
func _section_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.modulate = Color(0.5, 0.5, 0.5)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return lbl

func _stat_row(label: String, value: String, value_color: Color = Color(0.85, 0.85, 0.85)) -> HBoxContainer:
	var row = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(130, 0)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.modulate = Color(0.55, 0.55, 0.55)
	row.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 24)
	val.add_theme_color_override("font_color", value_color)
	## Expand into the remaining column width and clip rather than overflow the panel edge.
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.clip_text = true
	val.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(val)
	return row

func _stat_chip(label: String, value: float) -> PanelContainer:
	var chip = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22)
	style.corner_radius_top_left     = 3
	style.corner_radius_top_right    = 3
	style.corner_radius_bottom_left  = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left   = 5
	style.content_margin_right  = 5
	style.content_margin_top    = 2
	style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)
	var lbl = Label.new()
	lbl.text = "%s %.0f" % [label, value]
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", _skill_color(value))
	chip.add_child(lbl)
	return chip

func _card_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.12, 0.15)
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.22, 0.22, 0.26)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left   = 14
	style.content_margin_right  = 14
	style.content_margin_top    = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _show_driver_card(driver_id: String) -> void:
	var existing = get_node_or_null("DriverCardOverlay")
	if existing: existing.queue_free()

	var driver = GameState.all_drivers.get(driver_id)
	if not driver: return

	var overlay = PanelContainer.new()
	overlay.name = "DriverCardOverlay"
	overlay.anchor_left   = 1.0
	overlay.anchor_top    = 0.0
	overlay.anchor_right  = 1.0
	overlay.anchor_bottom = 0.0
	overlay.offset_left   = -600
	overlay.offset_top    = 190
	overlay.offset_right  = -50
	overlay.offset_bottom = 60
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 0.98)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.8, 1.0)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 20; style.content_margin_right = 20
	style.content_margin_top = 20; style.content_margin_bottom = 20
	overlay.add_theme_stylebox_override("panel", style)
	add_child(overlay)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	overlay.add_child(vbox)

	var header = HBoxContainer.new()
	vbox.add_child(header)
	var name_lbl = Label.new()
	name_lbl.text = "👤 %s" % driver.full_name()
	name_lbl.add_theme_font_size_override("font_size", 48)
	name_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_lbl)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(func(): overlay.queue_free())
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	_card_row(vbox, "Age / Sex / Nationality",
		"%d  |  %s  |  %s" % [driver.age, driver.sex, driver.nationality])
	_card_row(vbox, "Discipline", "%s  (Adapt: %.1f)" % [
		driver.active_discipline, driver.get_active_adaptation()])

	var car = GameState.get_car_for_driver(driver_id)
	_card_row(vbox, "Contract",
		"%d seasons remaining  |  Car: %s" % [
			driver.contract_seasons_remaining,
			(car.car_name if car.car_name != "" else "Car %d" % car.car_number) if car else "Unassigned"])

	vbox.add_child(HSeparator.new())

	var attrs_title = Label.new()
	attrs_title.text = "ATTRIBUTES"
	attrs_title.add_theme_font_size_override("font_size", 30)
	attrs_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(attrs_title)

	for stat in [
		["🚀 Pace", driver.pace, driver.get_effective_pace()],
		["🌧 Car Control", driver.car_control, driver.get_effective_wet()],
		["🎯 Focus", driver.focus, driver.get_effective_focus()],
		["⚔ Race Craft", driver.race_craft, driver.get_effective_race_craft()],
		["🔄 Consistency", driver.consistency, driver.get_effective_consistency()],
		["💬 Feedback", driver.feedback, -1.0],
		["📣 Marketability", driver.marketability, -1.0],
		["💪 Fitness", driver.fitness, -1.0],
	]:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		var lbl = Label.new()
		lbl.text = stat[0]
		lbl.custom_minimum_size = Vector2(200, 0)
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		row.add_child(lbl)
		var bar = ProgressBar.new()
		bar.min_value = 0; bar.max_value = 100; bar.value = stat[1]
		bar.custom_minimum_size = Vector2(160, 18); bar.show_percentage = false
		row.add_child(bar)
		var val_lbl = Label.new()
		val_lbl.text = "%.1f" % stat[1]
		if stat[2] >= 0: val_lbl.text += "  (eff: %.1f)" % stat[2]
		val_lbl.add_theme_font_size_override("font_size", 30)
		val_lbl.add_theme_color_override("font_color", _skill_color(stat[1]))
		row.add_child(val_lbl)

	vbox.add_child(HSeparator.new())
	_card_row(vbox, "Overall Skill", "%.1f / 100" % driver.get_overall_skill(),
		_skill_color(driver.get_overall_skill()))

func _card_row(parent: VBoxContainer, label: String, value: String,
		value_color: Color = Color.WHITE) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(200, 0)
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	row.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 30)
	val.add_theme_color_override("font_color", value_color)
	row.add_child(val)

func _skill_color(value: float) -> Color:
	if value >= 75.0:   return Color(0.3, 1.0, 0.3)
	elif value >= 50.0: return Color(1.0, 0.84, 0.0)
	elif value >= 30.0: return Color(1.0, 0.6, 0.2)
	else:               return Color(0.7, 0.4, 0.4)

func _fmt(n: int) -> String:
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

## #41 — Visible modal when a driver can't be assigned (e.g. fails the championship age limit).
func _show_assign_blocked_popup(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Cannot Assign Driver"
	dialog.dialog_text = message
	dialog.ok_button_text = "OK"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
