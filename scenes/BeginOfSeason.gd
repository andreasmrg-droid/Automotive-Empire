extends Control
## Version: S29.6 — Two-column content wrapped in a ScrollContainer so the START
##   SEASON button stays pinned at the bottom with large fonts (issue #9).
## --- S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
## Version: S28.2 — "Championships This Season" now lists the REGISTERED race set
##   (player_registered_championships), not just owned-car championships. Fixes the
##   "No championships registered" false display at season start (cars are wiped then).
## --- S17.1 — Fix E: navigating to buildings sets pending_season_screen so MainHub redirects back.

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right"]:
		margin.add_theme_constant_override(s, 60)
	for s in ["margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 36)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	# ── Title ─────────────────────────────────────────────────────────────────
	var lbl_season = Label.new()
	lbl_season.text = "🏁  SEASON %d BEGINS" % GameState.current_season
	lbl_season.add_theme_font_size_override("font_size", 76)
	lbl_season.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	lbl_season.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl_season)

	var lbl_sub = Label.new()
	lbl_sub.text = "Week 1 of 52  ·  Build your legacy."
	lbl_sub.add_theme_font_size_override("font_size", 28)
	lbl_sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl_sub)

	root.add_child(HSeparator.new())

	# ── Two columns (wrapped in a scroll so the START button stays pinned) ──────
	## S29.6 — with large fonts the column content overflowed and pushed START
	## SEASON off-screen; the cols now scroll internally, footer stays visible.
	var body_scroll = ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(body_scroll)

	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(cols)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	cols.add_child(left)

	left.add_child(_section_lbl("🏆  CHAMPIONSHIPS THIS SEASON"))

	## S28.2: show the championships the player is REGISTERED to race this season
	## (the activated race set), not just ones they already own a car for. At season
	## start cars are wiped, so keying off cars wrongly showed "none registered".
	var player_champs: Array = []
	for champ in GameState.active_championships:
		if champ.id in GameState.player_registered_championships:
			player_champs.append(champ)

	if player_champs.is_empty():
		var lbl_none = Label.new()
		lbl_none.text = "No championships registered for this season. Register during the season for next season."
		lbl_none.modulate = Color(0.55, 0.55, 0.55)
		lbl_none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left.add_child(lbl_none)
		var btn_reg = _action_btn("🏆 Championship Registration →", Color(0.15, 0.40, 0.65))
		btn_reg.pressed.connect(func(): _go("res://scenes/ChampionshipSelect.tscn"))
		left.add_child(btn_reg)
	else:
		for champ in player_champs:
			left.add_child(_build_champ_card(champ))

	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(310, 0)
	right.add_theme_constant_override("separation", 12)
	cols.add_child(right)

	right.add_child(_section_lbl("📋  SEASON TO-DO"))
	right.add_child(_build_tdl())
	right.add_child(HSeparator.new())
	right.add_child(_section_lbl("💰  FINANCES"))
	right.add_child(_build_finance_panel())

	# ── Footer ────────────────────────────────────────────────────────────────
	root.add_child(HSeparator.new())
	var btn_start = Button.new()
	btn_start.text = "▶  START SEASON %d" % GameState.current_season
	btn_start.custom_minimum_size = Vector2(0, 52)
	btn_start.add_theme_font_size_override("font_size", 44)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.48, 0.18)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	btn_start.add_theme_stylebox_override("normal", style)
	btn_start.pressed.connect(_on_start)
	root.add_child(btn_start)


func _build_champ_card(champ) -> PanelContainer:
	var panel = _card_panel(Color(0.10, 0.12, 0.16))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	panel.add_child(vbox)

	var reg = GameState.CHAMPIONSHIP_REGISTRY.get(champ.id, {})
	var lbl_name = Label.new()
	lbl_name.text = "🏆 %s  ·  Tier %d  ·  %d races" % [
		champ.championship_name, reg.get("tier", 1), champ.num_races]
	lbl_name.add_theme_font_size_override("font_size", 28)
	lbl_name.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(lbl_name)

	for check in _get_readiness(champ):
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		var icon = Label.new()
		icon.text = "✅" if check["ok"] else "⚠"
		icon.add_theme_font_size_override("font_size", 24)
		row.add_child(icon)
		var lbl = Label.new()
		lbl.text = check["text"]
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color",
			Color(0.5, 0.9, 0.5) if check["ok"] else Color(1.0, 0.55, 0.2))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		if not check["ok"] and check.get("dest", "") != "":
			var btn = Button.new()
			btn.text = "Fix →"
			btn.custom_minimum_size = Vector2(54, 22)
			btn.add_theme_font_size_override("font_size", 20)
			var d = check["dest"]
			btn.pressed.connect(func(): _go(d))
			row.add_child(btn)
		vbox.add_child(row)

	return panel


func _get_readiness(champ) -> Array:
	var checks = []
	var car = null
	for c in GameState.player_team_cars:
		if c.championship_id == champ.id: car = c; break

	if car:
		var cname = car.car_name if car.car_name != "" else "Car %d" % car.car_number
		checks.append({"ok": true, "text": "Car: %s  (%.0f%%)" % [cname, car.condition]})
		var drv = GameState.all_drivers.get(car.driver_id)
		if drv:
			checks.append({"ok": true, "text": "Driver: %s" % drv.full_name()})
		else:
			checks.append({"ok": false, "text": "No driver assigned",
				"dest": "res://scenes/buildings/Garage.tscn"})
		if car.mechanic_id != "":
			var m = GameState.all_staff.get(car.mechanic_id)
			checks.append({"ok": true, "text": "Mechanic: %s" % (m.full_name() if m else "Assigned")})
		else:
			checks.append({"ok": false, "text": "No mechanic assigned",
				"dest": "res://scenes/buildings/Garage.tscn"})
		if GameState.get_pit_crew_required(champ.id):
			var ok = car.pit_crew_id != "" and car.pit_crew_id != "N/A"
			checks.append({"ok": ok,
				"text": "Pit crew assigned" if ok else "No pit crew — DNS risk",
				"dest": "res://scenes/buildings/PitCrewArena.tscn"})
	else:
		checks.append({"ok": false, "text": "No car — buy at Logistics",
			"dest": "res://scenes/buildings/Logistics.tscn"})

	if champ.id in ["C-021","C-022","C-023","C-024"]:
		var code = GameState.CHAMP_CODES.get(champ.id, "")
		var has_bp = false
		for bp_id in GameState.completed_rnd_tasks:
			if bp_id.begins_with("BP-%s-" % code) and ("S%d-L1" % GameState.current_season) in bp_id:
				has_bp = true; break
		checks.append({"ok": has_bp,
			"text": "Season blueprint: %s" % ("ready ✓" if has_bp else "REQUIRED (Formula)"),
			"dest": "res://scenes/buildings/RnDStudio.tscn"})
	return checks


func _build_tdl() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	const ITEMS = [
		["🏆", "Register championships",      "res://scenes/ChampionshipSelect.tscn"],
		["🏎", "Buy / check cars",             "res://scenes/buildings/Logistics.tscn"],
		["👤", "Sign / renew driver contracts","res://scenes/Drivers.tscn"],
		["🔧", "Hire / renew staff contracts", "res://scenes/Staff.tscn"],
		["🔬", "Start R&D tasks",              "res://scenes/buildings/RnDStudio.tscn"],
		["📐", "Submit blueprints to WRA",     "res://scenes/buildings/HQ.tscn"],
		["⚙",  "Manufacture WRA-approved parts","res://scenes/buildings/CNCPlant.tscn"],
		["🔩", "Install CNC parts (Garage)",   "res://scenes/buildings/Garage.tscn"],
		["🤝", "Review sponsor offers",        "res://scenes/buildings/HQ.tscn"],
		["⛽", "Stock fuel & spare parts",     "res://scenes/buildings/Logistics.tscn"],
	]
	for item in ITEMS:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var ic = Label.new(); ic.text = item[0]
		ic.add_theme_font_size_override("font_size", 26)
		row.add_child(ic)
		var lbl = Label.new(); lbl.text = item[1]
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var btn = Button.new(); btn.text = "→"
		btn.custom_minimum_size = Vector2(26, 22)
		btn.add_theme_font_size_override("font_size", 20)
		var d = item[2]
		btn.pressed.connect(func(): _go(d))
		row.add_child(btn)
		vbox.add_child(row)
	return vbox


func _build_finance_panel() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	var team = GameState.player_team
	for data in [
		["Balance",       "CR %s" % _fmt(int(team.balance)),
			Color(0.4, 0.9, 0.4) if team.balance >= 0 else Color(1.0, 0.4, 0.4)],
		["Wkly Expenses", "CR %s" % _fmt(int(GameState.get_weekly_expenses())), Color(1.0, 0.6, 0.4)],
		["Runway",        "%d wks" % GameState.get_runway_weeks()
			if GameState.get_runway_weeks() < 999 else "Stable", Color(0.7, 0.7, 0.7)],
		["Sponsors",      "%d / %d slots" % [
			GameState.active_sponsors.size(), GameState.get_hq_sponsor_slots()], Color(0.6, 0.8, 1.0)],
		["Reputation",    "%.0f / 100" % team.reputation, Color(0.9, 0.8, 0.3)],
	]:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var k = Label.new(); k.text = data[0]
		k.custom_minimum_size = Vector2(120, 0)
		k.add_theme_font_size_override("font_size", 24)
		k.modulate = Color(0.45, 0.45, 0.45)
		row.add_child(k)
		var v = Label.new(); v.text = data[1]
		v.add_theme_font_size_override("font_size", 24)
		v.add_theme_color_override("font_color", data[2])
		row.add_child(v)
		vbox.add_child(row)
	return vbox


func _on_start() -> void:
	GameState.pending_season_screen = ""
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

## Navigate away while keeping pending_season_screen so MainHub returns here.
func _go(scene_path: String) -> void:
	GameState.pending_season_screen = "begin_of_season"
	get_tree().change_scene_to_file(scene_path)


func _section_lbl(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	return l

func _card_panel(bg: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.border_color = Color(0.20, 0.25, 0.35)
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _action_btn(text: String, bg: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 34)
	btn.add_theme_font_size_override("font_size", 26)
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	return btn

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.2fM" % (n / 1000000.0)
	if n >= 1000:    return "%dK" % (n / 1000)
	return str(n)
