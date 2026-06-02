extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   28)
	margin.add_theme_constant_override("margin_right",  28)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	var building = GameState.campus_buildings.get("Museum", {})
	var lbl_title = Label.new()
	lbl_title.text = "🏆 MUSEUM  ·  Level %d" % building.get("level", 1)
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)
	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(100, 36)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)
	root.add_child(HSeparator.new())

	# Two columns
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	cols.add_child(left)

	# Description
	var lbl_desc = Label.new()
	lbl_desc.text = "Converts race wins and retired chassis into brand prestige and passive income."
	lbl_desc.modulate = Color(0.7, 0.7, 0.7)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 13)
	left.add_child(lbl_desc)

	left.add_child(HSeparator.new())

	left.add_child(_section_label("HALL OF FAME"))
	left.add_child(_build_extra_panel())

	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(260, 0)
	right.add_theme_constant_override("separation", 14)
	cols.add_child(right)

	right.add_child(_section_label("BUILDING EFFECTS"))
	right.add_child(_build_effects_panel())

func _build_effects_panel() -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var building = GameState.campus_buildings.get("Museum", {})
	var level = building.get("level", 1)
	var maint = GameState.get_building_maintenance(building)

	# Count only THIS team's wins — museum displays team history only
	var team_wins = 0
	var hof = GameState.hall_of_fame if "hall_of_fame" in GameState else []
	for entry in hof:
		if entry.get("team_id", "") == GameState.player_team.id:
			team_wins += 1

	# Income requires trophies: 0 wins = 0 income. Each win adds 10% to base income.
	var base_inc = GameState.get_building_income(building)
	var actual_inc = 0 if team_wins == 0 else int(base_inc * (1.0 + team_wins * 0.1))

	var rows = [
		["Level",         "%d / %d" % [level, building.get("max_level", 10)]],
		["Maintenance",   "CR %d/wk" % maint],
		["Trophies",      "%d team win%s" % [team_wins, "s" if team_wins != 1 else ""]],
		["Weekly Income", "CR %d/wk%s" % [actual_inc,
			"  ⚠ earn wins first" if team_wins == 0 else ""]],
	]
	for e in rows:
		vbox.add_child(_stat_row(e[0], e[1]))
	return panel

func _build_extra_panel() -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var lbl = Label.new()
	lbl.text = "HALL OF FAME  —  %s" % GameState.player_team.team_name
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(lbl)
	var hof = GameState.hall_of_fame if "hall_of_fame" in GameState else []
	# Filter to team wins only
	var team_wins = hof.filter(func(e): return e.get("team_id","") == GameState.player_team.id)
	if team_wins.is_empty():
		var empty = Label.new()
		empty.text = "No wins yet — get out there and race! 🏆"
		empty.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(empty)
	else:
		for i in range(min(team_wins.size(), 10)):
			var entry = team_wins[team_wins.size() - 1 - i]
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			var lbl_round = Label.new()
			lbl_round.text = "S%d R%d" % [entry.get("season",1), entry.get("round",1)]
			lbl_round.custom_minimum_size.x = 60
			lbl_round.add_theme_font_size_override("font_size", 12)
			lbl_round.modulate = Color(0.55, 0.55, 0.55)
			row.add_child(lbl_round)
			var lbl_driver = Label.new()
			lbl_driver.text = entry.get("winner", "?")
			lbl_driver.add_theme_font_size_override("font_size", 12)
			lbl_driver.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			row.add_child(lbl_driver)
			var lbl_track = Label.new()
			lbl_track.text = "  %s" % entry.get("track", "?")
			lbl_track.modulate = Color(0.6, 0.6, 0.6)
			lbl_track.add_theme_font_size_override("font_size", 12)
			row.add_child(lbl_track)
			vbox.add_child(row)
	return panel
	return panel

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/campus.tscn")

func _section_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(0.5, 0.5, 0.5)
	return lbl

func _stat_row(label: String, value: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	var l = Label.new(); l.text = label; l.custom_minimum_size = Vector2(140, 0)
	l.add_theme_font_size_override("font_size", 12); l.modulate = Color(0.55, 0.55, 0.55)
	row.add_child(l)
	var v = Label.new(); v.text = value; v.add_theme_font_size_override("font_size", 12)
	row.add_child(v)
	return row

func _card_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.12, 0.15)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.22, 0.22, 0.26)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 12; style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel
