extends Control
## Version: S15.2 — New scene. Beginning of season screen.
## Shows season number, registered championships, and a mandatory TDL to get each ready.
## Triggered from MainHub when current_week == 1 and current_season > 1,
## OR immediately after season rollover in advance_week().

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right"]:
		margin.add_theme_constant_override(s, 60)
	for s in ["margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 40)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)

	# ── Title ─────────────────────────────────────────────────────────────────
	var lbl_season = Label.new()
	lbl_season.text = "🏁  SEASON %d BEGINS" % GameState.current_season
	lbl_season.add_theme_font_size_override("font_size", 36)
	lbl_season.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	lbl_season.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl_season)

	var lbl_sub = Label.new()
	lbl_sub.text = "Week 1 of 52  ·  Your empire awaits."
	lbl_sub.add_theme_font_size_override("font_size", 15)
	lbl_sub.modulate = Color(0.6, 0.6, 0.6)
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl_sub)

	root.add_child(HSeparator.new())

	# ── Two columns ───────────────────────────────────────────────────────────
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 30)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	# Left: Championship readiness checklist
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	cols.add_child(left)

	var lbl_champs = Label.new()
	lbl_champs.text = "REGISTERED CHAMPIONSHIPS"
	lbl_champs.add_theme_font_size_override("font_size", 13)
	lbl_champs.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	left.add_child(lbl_champs)

	if GameState.active_championships.is_empty():
		var lbl_none = Label.new()
		lbl_none.text = "No championships registered.\nGo to Championship Registration to sign up."
		lbl_none.modulate = Color(0.6, 0.6, 0.6)
		lbl_none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left.add_child(lbl_none)
		var btn_reg = Button.new()
		btn_reg.text = "🏆 Championship Registration →"
		btn_reg.custom_minimum_size = Vector2(0, 36)
		btn_reg.pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/ChampionshipSelect.tscn"))
		left.add_child(btn_reg)
	else:
		for champ in GameState.active_championships:
			left.add_child(_build_champ_checklist(champ))

	# Right: Season TDL + Financial snapshot
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(320, 0)
	right.add_theme_constant_override("separation", 12)
	cols.add_child(right)

	var lbl_tdl = Label.new()
	lbl_tdl.text = "SEASON TO-DO LIST"
	lbl_tdl.add_theme_font_size_override("font_size", 13)
	lbl_tdl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	right.add_child(lbl_tdl)

	right.add_child(_build_season_tdl())

	right.add_child(HSeparator.new())

	var lbl_fin = Label.new()
	lbl_fin.text = "FINANCIAL SNAPSHOT"
	lbl_fin.add_theme_font_size_override("font_size", 13)
	lbl_fin.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	right.add_child(lbl_fin)

	right.add_child(_build_finance_panel())

	# ── Footer ────────────────────────────────────────────────────────────────
	root.add_child(HSeparator.new())
	var btn_continue = Button.new()
	btn_continue.text = "▶  START SEASON %d" % GameState.current_season
	btn_continue.custom_minimum_size = Vector2(0, 50)
	btn_continue.add_theme_font_size_override("font_size", 20)
	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0.15, 0.45, 0.15)
	style_btn.corner_radius_top_left = 6; style_btn.corner_radius_top_right = 6
	style_btn.corner_radius_bottom_left = 6; style_btn.corner_radius_bottom_right = 6
	btn_continue.add_theme_stylebox_override("normal", style_btn)
	btn_continue.pressed.connect(_on_continue)
	root.add_child(btn_continue)


func _build_champ_checklist(champ) -> PanelContainer:
	var panel = _card_panel(Color(0.10, 0.12, 0.16))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	panel.add_child(vbox)

	var reg = GameState.CHAMPIONSHIP_REGISTRY.get(champ.id, {})
	var lbl_name = Label.new()
	lbl_name.text = "🏆 %s" % champ.championship_name
	lbl_name.add_theme_font_size_override("font_size", 14)
	lbl_name.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(lbl_name)

	var lbl_info = Label.new()
	lbl_info.text = "%d races  ·  %s discipline  ·  Tier %d" % [
		champ.num_races, champ.discipline, reg.get("tier", 1)]
	lbl_info.add_theme_font_size_override("font_size", 11)
	lbl_info.modulate = Color(0.55, 0.55, 0.55)
	vbox.add_child(lbl_info)

	# Readiness checks
	var checks = _get_champ_readiness(champ)
	for check in checks:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var icon = Label.new()
		icon.text = "✅" if check["ok"] else "⚠"
		icon.add_theme_font_size_override("font_size", 12)
		row.add_child(icon)
		var lbl_c = Label.new()
		lbl_c.text = check["text"]
		lbl_c.add_theme_font_size_override("font_size", 12)
		lbl_c.add_theme_color_override("font_color",
			Color(0.5, 0.9, 0.5) if check["ok"] else Color(1.0, 0.55, 0.2))
		lbl_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl_c)
		if not check["ok"] and check.get("dest", "") != "":
			var btn = Button.new()
			btn.text = "Fix →"
			btn.custom_minimum_size = Vector2(58, 24)
			btn.add_theme_font_size_override("font_size", 10)
			var d = check["dest"]
			btn.pressed.connect(func(): get_tree().change_scene_to_file(d))
			row.add_child(btn)
		vbox.add_child(row)

	return panel


func _get_champ_readiness(champ) -> Array:
	var checks = []
	var car = null
	for c in GameState.player_team_cars:
		if c.championship_id == champ.id:
			car = c; break

	# Car
	if car:
		checks.append({"ok": true, "text": "Car: %s (Cond: %.0f%%)" % [
			car.car_name if car.car_name != "" else "Car %d" % car.car_number, car.condition]})
		# Driver
		var drv = GameState.all_drivers.get(car.driver_id)
		if drv:
			checks.append({"ok": true, "text": "Driver: %s" % drv.full_name()})
		else:
			checks.append({"ok": false, "text": "No driver assigned",
				"dest": "res://scenes/buildings/Garage.tscn"})
		# Mechanic
		if car.mechanic_id != "":
			var mech = GameState.all_staff.get(car.mechanic_id)
			checks.append({"ok": true, "text": "Mechanic: %s" % (mech.full_name() if mech else "Assigned")})
		else:
			checks.append({"ok": false, "text": "No mechanic assigned",
				"dest": "res://scenes/buildings/Garage.tscn"})
		# Pit crew (non-GK only)
		if GameState.get_pit_crew_required(champ.id):
			if car.pit_crew_id != "" and car.pit_crew_id != "N/A":
				checks.append({"ok": true, "text": "Pit crew assigned"})
			else:
				checks.append({"ok": false, "text": "No pit crew — DNS risk",
					"dest": "res://scenes/buildings/PitCrewArena.tscn"})
	else:
		checks.append({"ok": false, "text": "No car — buy at Logistics",
			"dest": "res://scenes/buildings/Logistics.tscn"})

	# Formula: need next-season blueprint
	if champ.id in ["C-021","C-022","C-023","C-024"]:
		var code = GameState.CHAMP_CODES.get(champ.id, "")
		var has_bp = false
		for bp_id in GameState.completed_rnd_tasks:
			if bp_id.begins_with("BP-%s-" % code) and "S%d-L1" % GameState.current_season in bp_id:
				has_bp = true; break
		if has_bp:
			checks.append({"ok": true, "text": "Season blueprint: ready"})
		else:
			checks.append({"ok": false, "text": "Season blueprint required (Formula)",
				"dest": "res://scenes/buildings/RnDStudio.tscn"})

	return checks


func _build_season_tdl() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	const TDL_ITEMS = [
		["🏆", "Register for championships (off-season)", "res://scenes/ChampionshipSelect.tscn"],
		["🏎", "Buy/check car for each championship", "res://scenes/buildings/Logistics.tscn"],
		["👤", "Sign/renew driver contracts", "res://scenes/Drivers.tscn"],
		["🔧", "Hire/renew mechanic & staff contracts", "res://scenes/Staff.tscn"],
		["🔬", "Start R&D tasks for this season", "res://scenes/buildings/RnDStudio.tscn"],
		["📐", "Submit completed blueprints to WRA", "res://scenes/buildings/HQ.tscn"],
		["⚙", "Manufacture WRA-approved parts in CNC", "res://scenes/buildings/CNCPlant.tscn"],
		["🔩", "Install CNC parts on cars (Garage)", "res://scenes/buildings/Garage.tscn"],
		["🤝", "Review sponsor offers (HQ)", "res://scenes/buildings/HQ.tscn"],
		["⛽", "Stock up on fuel and spare parts", "res://scenes/buildings/Logistics.tscn"],
	]

	for item in TDL_ITEMS:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var icon = Label.new(); icon.text = item[0]
		icon.add_theme_font_size_override("font_size", 13)
		row.add_child(icon)
		var lbl = Label.new()
		lbl.text = item[1]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.modulate = Color(0.8, 0.8, 0.8)
		row.add_child(lbl)
		var btn = Button.new()
		btn.text = "→"
		btn.custom_minimum_size = Vector2(28, 22)
		btn.add_theme_font_size_override("font_size", 10)
		var d = item[2]
		btn.pressed.connect(func(): get_tree().change_scene_to_file(d))
		row.add_child(btn)
		vbox.add_child(row)

	return vbox


func _build_finance_panel() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)

	var team = GameState.player_team
	var weekly_exp = GameState.get_weekly_expenses()
	var runway = GameState.get_runway_weeks()

	for row_data in [
		["Balance", "CR %s" % GameState._fmt_int(int(team.balance)),
			Color(0.4, 0.9, 0.4) if team.balance >= 0 else Color(1.0, 0.4, 0.4)],
		["Est. Weekly Expenses", "CR %s" % GameState._fmt_int(int(weekly_exp)), Color(1.0, 0.6, 0.4)],
		["Runway", "%s weeks" % runway if runway < 999 else "Stable", Color(0.7, 0.7, 0.7)],
		["Active Sponsors", "%d / %d slots" % [
			GameState.active_sponsors.size(), GameState.get_hq_sponsor_slots()], Color(0.6, 0.8, 1.0)],
		["Reputation", "%.0f / 100" % team.reputation, Color(0.9, 0.8, 0.3)],
	]:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var l = Label.new(); l.text = row_data[0]
		l.custom_minimum_size = Vector2(160, 0)
		l.add_theme_font_size_override("font_size", 12)
		l.modulate = Color(0.55, 0.55, 0.55)
		row.add_child(l)
		var v = Label.new(); v.text = row_data[1]
		v.add_theme_font_size_override("font_size", 12)
		v.add_theme_color_override("font_color", row_data[2])
		row.add_child(v)
		vbox.add_child(row)

	return vbox


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")


func _card_panel(bg: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.22, 0.28, 0.38)
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel
