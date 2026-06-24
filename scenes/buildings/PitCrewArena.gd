extends Control
## Version: S36.13 — Bug #9/#19 (cluster A): the "Pit Crew not required" gate now checks the
##   player's ACTUAL championships via get_player_championships() + get_pit_crew_required(), instead
##   of scanning active_championships (the world always contains non-GK series, so the old check was
##   always true and the message never showed for a GK-only team). Now uses the authoritative
##   PIT_CREW_REQUIRED rule rather than a hardcoded "non-GK".
## Version: S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## Version: S28.3 — Fixed crash: Pit Crew "teamwork" stat (removed) → "fatigue_resistance".
## --- S15.2 — Build/upgrade costs reduced to Garage standards (build 10wks/30K, upgrade 4wks/15K).

var _crew_container: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh()

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
	var building = GameState.campus_buildings.get("Pit Crew Arena", {})
	var lbl = Label.new()
	lbl.text = "⏱ PIT CREW ARENA  ·  Level %d" % building.get("level", 1)
	lbl.add_theme_font_size_override("font_size", 44)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl)
	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(100, 36)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)
	root.add_child(HSeparator.new())

	# Discipline check (cluster A, Bug #9/#19): show the "not required" message based on the
	# player's ACTUAL championships, not active_championships (the world always contains non-GK
	# series, so the old check was always true and the message never appeared for a GK-only team).
	# Pit crew is required where get_pit_crew_required() is true (same rule the car list uses).
	var needs_pit_crew = false
	for champ in GameState.get_player_championships():
		if GameState.get_pit_crew_required(champ.id):
			needs_pit_crew = true
			break
	if not needs_pit_crew:
		var lbl_gk = Label.new()
		lbl_gk.text = "Pit Crew not required for your current championships.\nThis building activates when you race a championship that needs a pit crew."
		lbl_gk.modulate = Color(0.55, 0.55, 0.55)
		lbl_gk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		root.add_child(lbl_gk)
		return

	# Two columns
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	cols.add_child(left)

	left.add_child(_section_label("PIT CREW ROSTER"))

	var action_row = HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	left.add_child(action_row)

	var max_crew = building.get("level", 1)
	var cur_crew = GameState.get_player_staff_by_role("Pit Crew").size()
	var slots_lbl = Label.new()
	slots_lbl.text = "Slots: %d / %d" % [cur_crew, max_crew]
	slots_lbl.modulate = Color(1.0, 0.5, 0.15) if cur_crew >= max_crew else Color(0.5, 0.9, 0.5)
	action_row.add_child(slots_lbl)

	var btn_hire = Button.new()
	btn_hire.text = "Hire Pit Crew →"
	btn_hire.disabled = cur_crew >= max_crew
	btn_hire.pressed.connect(func():
		GameState.pending_staff_filter = "Pit Crew"
		get_tree().change_scene_to_file("res://scenes/Staff.tscn")
	)
	action_row.add_child(btn_hire)

	left.add_child(HSeparator.new())

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_crew_container = VBoxContainer.new()
	_crew_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_crew_container.add_theme_constant_override("separation", 10)
	scroll.add_child(_crew_container)

	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(260, 0)
	right.add_theme_constant_override("separation", 14)
	cols.add_child(right)

	right.add_child(_section_label("BUILDING EFFECTS"))
	right.add_child(_build_effects_panel())

func refresh() -> void:
	if _crew_container == null:
		return
	for c in _crew_container.get_children():
		c.queue_free()

	var crews = GameState.get_player_staff_by_role("Pit Crew")
	if crews.is_empty():
		var lbl = Label.new()
		lbl.text = "No Pit Crew hired."
		lbl.modulate = Color(0.55, 0.55, 0.55)
		_crew_container.add_child(lbl)
		return

	for crew in crews:
		_crew_container.add_child(_build_crew_card(crew))

func _build_crew_card(crew) -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	var lbl_name = Label.new()
	# Show as crew unit, not individual name
	var crew_label = crew.display_name() if crew.crew_number > 0 else ("Crew (Chief: %s)" % crew.full_name())
	lbl_name.text = crew_label
	lbl_name.add_theme_font_size_override("font_size", 30)
	lbl_name.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(lbl_name)
	var lbl_sal = Label.new()
	lbl_sal.text = "CR %d/wk" % int(crew.weekly_salary)
	lbl_sal.modulate = Color(0.6, 0.6, 0.6)
	row1.add_child(lbl_sal)
	vbox.add_child(row1)

	# Fitness bar
	var fit_row = HBoxContainer.new()
	fit_row.add_theme_constant_override("separation", 8)
	var fit_lbl = Label.new()
	fit_lbl.text = "Fitness:"
	fit_lbl.custom_minimum_size.x = 60
	fit_lbl.add_theme_font_size_override("font_size", 24)
	fit_row.add_child(fit_lbl)
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = crew.fitness
	bar.custom_minimum_size = Vector2(160, 16)
	bar.show_percentage = false
	bar.modulate = _fit_color(crew.fitness)
	fit_row.add_child(bar)
	var fit_val = Label.new()
	fit_val.text = "%.0f%%" % crew.fitness
	fit_val.modulate = _fit_color(crew.fitness)
	fit_val.add_theme_font_size_override("font_size", 24)
	fit_row.add_child(fit_val)
	vbox.add_child(fit_row)

	# Stat chips
	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 6)
	for stat in [["Pit Stop", crew.pit_stop_speed], ["Repair", crew.repair_skill], ["Fatigue Res", crew.fatigue_resistance]]:
		stats_row.add_child(_stat_chip(stat[0], stat[1]))
	vbox.add_child(stats_row)

	# Car assignment — only non-GK cars need pit crew
	var non_gk_cars = GameState.player_team_cars.filter(func(c):
		return GameState.get_pit_crew_required(c.championship_id))
	if not non_gk_cars.is_empty():
		var assign_row = HBoxContainer.new()
		assign_row.add_theme_constant_override("separation", 8)
		var assigned_car = _find_car_for_crew(crew.id)
		var lbl_car = Label.new()
		lbl_car.text = "Assigned to: %s" % (_car_name(assigned_car) if assigned_car else "⚠ Unassigned — DNS risk")
		lbl_car.modulate = Color(0.4, 0.9, 0.4) if assigned_car else Color(1.0, 0.5, 0.15)
		lbl_car.add_theme_font_size_override("font_size", 24)
		lbl_car.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		assign_row.add_child(lbl_car)
		for car in non_gk_cars:
			var btn = Button.new()
			var reg = GameState.CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
			btn.text = "%s (%s)" % [_car_name(car), reg.get("discipline", "?")]
			btn.add_theme_font_size_override("font_size", 22)
			if assigned_car and assigned_car.id == car.id:
				btn.text += " ✅"
				btn.disabled = true
			elif car.pit_crew_id != "" and car.pit_crew_id != "N/A":
				btn.text += " (taken)"
				btn.modulate = Color(0.5, 0.5, 0.5)
			var cid = car.id
			var sid = crew.id
			btn.pressed.connect(func():
				GameState.assign_staff_to_car(sid, cid)
				refresh()
			)
			assign_row.add_child(btn)
		vbox.add_child(assign_row)
	elif GameState.player_team_cars.is_empty():
		var lbl_no_car = Label.new()
		lbl_no_car.text = "No cars in garage yet."
		lbl_no_car.add_theme_font_size_override("font_size", 22)
		lbl_no_car.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(lbl_no_car)
	else:
		var lbl_gk = Label.new()
		lbl_gk.text = "All current cars are GK — no pit crew needed."
		lbl_gk.add_theme_font_size_override("font_size", 22)
		lbl_gk.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(lbl_gk)

	return panel

func _find_car_for_crew(crew_id: String):
	for car in GameState.player_team_cars:
		if car.pit_crew_id == crew_id:
			return car
	return null

func _car_name(car) -> String:
	return car.car_name if car.car_name != "" else "Car %d" % car.car_number

func _build_effects_panel() -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var building = GameState.campus_buildings.get("Pit Crew Arena", {})
	var level = building.get("level", 1)
	var effects = [
		["Pit Stop Bonus",  "-%.1fs" % (0.1 * level)],
		["Crew Slots",      "%d" % level],
		["Maintenance",     "CR %d/wk" % GameState.get_building_maintenance(building)],
		["Level",           "%d / %d" % [level, building.get("max_level", 20)]],
	]
	for e in effects:
		vbox.add_child(_stat_row(e[0], e[1]))
	return panel

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

func _fit_color(v: float) -> Color:
	if v >= 70: return Color(0.3, 0.9, 0.4)
	elif v >= 40: return Color(1.0, 0.75, 0.1)
	return Color(1.0, 0.3, 0.3)

func _section_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.modulate = Color(0.5, 0.5, 0.5)
	return lbl

func _stat_row(label: String, value: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	var l = Label.new(); l.text = label; l.custom_minimum_size = Vector2(140, 0)
	l.add_theme_font_size_override("font_size", 24); l.modulate = Color(0.55, 0.55, 0.55)
	row.add_child(l)
	var v = Label.new(); v.text = value; v.add_theme_font_size_override("font_size", 24)
	row.add_child(v)
	return row

func _stat_chip(label: String, value: float) -> PanelContainer:
	var chip = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22)
	style.corner_radius_top_left = 3; style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3; style.corner_radius_bottom_right = 3
	style.content_margin_left = 5; style.content_margin_right = 5
	style.content_margin_top = 2; style.content_margin_bottom = 2
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
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.22, 0.22, 0.26)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 12; style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _skill_color(v: float) -> Color:
	if v >= 75: return Color(0.3, 1.0, 0.3)
	elif v >= 50: return Color(1.0, 0.84, 0.0)
	elif v >= 30: return Color(1.0, 0.6, 0.2)
	return Color(0.7, 0.4, 0.4)
