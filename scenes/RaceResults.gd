extends Control
## Race Results Screen
## Shows: round/championship header, race results with positions/points/prizes,
## current championship standings, player car condition, attribute changes.
## Displayed after every simulated race before returning to MainHub.

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_right",  32)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	# ── Header ────────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var lbl_title = Label.new()
	var wet_tag = "  🌧 WET" if GameState.last_race_wet else ""
	lbl_title.text = "🏁 ROUND %d / %d  —  %s%s" % [
		GameState.last_race_round,
		GameState.last_race_num_races,
		GameState.last_race_championship,
		wet_tag
	]
	lbl_title.add_theme_font_size_override("font_size", 20)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	var lbl_track = Label.new()
	lbl_track.text = "📍 %s" % GameState.last_race_name
	lbl_track.add_theme_font_size_override("font_size", 13)
	lbl_track.modulate = Color(0.6, 0.6, 0.6)
	header.add_child(lbl_track)

	var btn_continue = Button.new()
	btn_continue.text = "Continue  ▶"
	btn_continue.custom_minimum_size = Vector2(140, 40)
	btn_continue.add_theme_font_size_override("font_size", 15)
	btn_continue.pressed.connect(_on_continue)
	header.add_child(btn_continue)

	root.add_child(HSeparator.new())

	# ── Three-column layout ───────────────────────────────────────────────────
	var columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	# Left column: race results — fixed width, blue panel
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(680, 0)
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lp_style = StyleBoxFlat.new()
	lp_style.bg_color = Color(0.09, 0.10, 0.13)
	lp_style.border_width_left = 1; lp_style.border_width_right = 1
	lp_style.border_width_top = 1; lp_style.border_width_bottom = 1
	lp_style.border_color = Color(0.2, 0.35, 0.55)
	lp_style.corner_radius_top_left = 5; lp_style.corner_radius_top_right = 5
	lp_style.corner_radius_bottom_left = 5; lp_style.corner_radius_bottom_right = 5
	lp_style.content_margin_left = 8; lp_style.content_margin_right = 8
	lp_style.content_margin_top = 8; lp_style.content_margin_bottom = 8
	left_panel.add_theme_stylebox_override("panel", lp_style)
	columns.add_child(left_panel)

	var left_scroll = ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(left_scroll)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	left_scroll.add_child(left)

	_build_race_results(left)

	# Middle column: driver standings — purple panel
	var mid_panel = PanelContainer.new()
	mid_panel.custom_minimum_size = Vector2(500, 0)
	mid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mp_style = StyleBoxFlat.new()
	mp_style.bg_color = Color(0.09, 0.10, 0.13)
	mp_style.border_width_left = 1; mp_style.border_width_right = 1
	mp_style.border_width_top = 1; mp_style.border_width_bottom = 1
	mp_style.border_color = Color(0.4, 0.25, 0.65)
	mp_style.corner_radius_top_left = 5; mp_style.corner_radius_top_right = 5
	mp_style.corner_radius_bottom_left = 5; mp_style.corner_radius_bottom_right = 5
	mp_style.content_margin_left = 8; mp_style.content_margin_right = 8
	mp_style.content_margin_top = 8; mp_style.content_margin_bottom = 8
	mid_panel.add_theme_stylebox_override("panel", mp_style)
	columns.add_child(mid_panel)

	var mid_scroll = ScrollContainer.new()
	mid_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_panel.add_child(mid_scroll)

	var mid = VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 6)
	mid_scroll.add_child(mid)

	_build_standings(mid, false)

	# Right column: expands to fill remaining space
	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(right_scroll)

	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	right_scroll.add_child(right)

	# Teams standings panel — gold border
	var teams_panel = _section_panel(Color(1.0, 0.8, 0.2))
	right.add_child(teams_panel)
	_build_standings(teams_panel.get_child(0), true)

	# Only show car condition + staff development if player had a car in this race
	var player_raced = GameState.player_team_cars.any(
		func(c): return c.championship_id == GameState.last_race_championship_id)

	if player_raced:
		var worst_cond = 100.0
		for car in GameState.player_team_cars:
			if car.championship_id == GameState.last_race_championship_id:
				worst_cond = min(worst_cond, car.condition)
		var cond_color = Color(0.3, 0.85, 0.3)
		if worst_cond < 70.0: cond_color = Color(1.0, 0.6, 0.1)
		if worst_cond < 40.0: cond_color = Color(1.0, 0.25, 0.25)
		var cond_panel = _section_panel(cond_color)
		right.add_child(cond_panel)
		_build_car_condition(cond_panel.get_child(0))

		## Driver development — now in right column with staff development
		var driver_dev_panel = _section_panel(Color(0.3, 0.7, 0.5))
		right.add_child(driver_dev_panel)
		_build_driver_improvements(driver_dev_panel.get_child(0))

		var staff_panel = _section_panel(Color(0.25, 0.75, 0.65))
		right.add_child(staff_panel)
		_build_staff_improvements(staff_panel.get_child(0))

func _build_race_results(parent: VBoxContainer) -> void:
	var lbl = Label.new()
	lbl.text = "RACE RESULTS"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	parent.add_child(lbl)

	var results = GameState.last_race_results
	if results.is_empty():
		var empty = Label.new()
		empty.text = "No results available."
		empty.modulate = Color(0.5, 0.5, 0.5)
		parent.add_child(empty)
		return

	# Column headers
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 0)
	parent.add_child(hdr)
	for pair in [["Pos",36],["Driver",-1],["Laps",46],["Time",110],["Gap",88],["Pts",52],["Prize",80]]:
		var lh = Label.new()
		lh.text = pair[0]
		lh.add_theme_font_size_override("font_size", 10)
		lh.modulate = Color(0.45, 0.45, 0.45)
		if pair[1] == -1:
			lh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			lh.custom_minimum_size = Vector2(pair[1], 0)
		if pair[0] in ["Laps","Time","Gap","Pts","Prize"]:
			lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hdr.add_child(lh)

	parent.add_child(HSeparator.new())

	# Find leader time for gap calculation
	var leader_time: float = -1.0
	for entry in results:
		if not entry.get("dns", false):
			leader_time = entry.get("total_time", 0.0)
			break

	var total_laps: int = GameState.last_race_laps if "last_race_laps" in GameState else 0

	for i in range(results.size()):
		var entry = results[i]
		var driver = entry["driver"]
		var is_dns = entry.get("dns", false)
		var is_player = entry.get("is_player", false) or driver.id in GameState.player_team.drivers
		var pts = entry.get("points", 0)
		var prize = entry.get("prize", 0.0)
		var pos = i + 1
		var t_time = entry.get("total_time", 0.0)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		parent.add_child(row)

		# Position / medal
		var lbl_pos = Label.new()
		if is_dns:     lbl_pos.text = "DNS"
		elif pos == 1: lbl_pos.text = "🥇"
		elif pos == 2: lbl_pos.text = "🥈"
		elif pos == 3: lbl_pos.text = "🥉"
		else:          lbl_pos.text = "%2d." % pos
		lbl_pos.custom_minimum_size = Vector2(36, 0)
		lbl_pos.add_theme_font_size_override("font_size", 13)
		if is_dns: lbl_pos.modulate = Color(0.45, 0.45, 0.45)
		row.add_child(lbl_pos)

		# Driver name
		var lbl_name = Label.new()
		lbl_name.text = driver.full_name()
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_name.add_theme_font_size_override("font_size", 13)
		lbl_name.clip_contents = true
		if is_dns:
			lbl_name.modulate = Color(0.45, 0.45, 0.45)
		elif is_player:
			lbl_name.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		elif pos == 1:
			lbl_name.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		row.add_child(lbl_name)

		# Laps
		var lbl_laps = Label.new()
		lbl_laps.text = str(total_laps) if not is_dns else "—"
		lbl_laps.custom_minimum_size = Vector2(46, 0)
		lbl_laps.add_theme_font_size_override("font_size", 12)
		lbl_laps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_laps.modulate = Color(0.65, 0.65, 0.65)
		row.add_child(lbl_laps)

		# Total time H:MM:SS.ms
		var lbl_time = Label.new()
		lbl_time.custom_minimum_size = Vector2(110, 0)
		lbl_time.add_theme_font_size_override("font_size", 12)
		lbl_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if is_dns:
			lbl_time.text = "—"
			lbl_time.modulate = Color(0.45, 0.45, 0.45)
		else:
			lbl_time.text = _fmt_time(t_time)
			lbl_time.add_theme_color_override("font_color",
				Color(1.0, 0.84, 0.0) if pos == 1 else Color(0.75, 0.75, 0.75))
		row.add_child(lbl_time)

		# Gap to leader
		var lbl_gap = Label.new()
		lbl_gap.custom_minimum_size = Vector2(88, 0)
		lbl_gap.add_theme_font_size_override("font_size", 12)
		lbl_gap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if is_dns:
			lbl_gap.text = "DNS"
			lbl_gap.modulate = Color(0.45, 0.45, 0.45)
		elif pos == 1:
			lbl_gap.text = "LEADER"
			lbl_gap.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		else:
			lbl_gap.text = "+%s" % _fmt_time(t_time - leader_time)
			lbl_gap.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		row.add_child(lbl_gap)

		# Points
		var lbl_pts = Label.new()
		lbl_pts.text = "+%d" % pts if (pts > 0 and not is_dns) else "—"
		lbl_pts.custom_minimum_size = Vector2(52, 0)
		lbl_pts.add_theme_font_size_override("font_size", 12)
		lbl_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_pts.add_theme_color_override("font_color",
			Color(0.45,0.45,0.45) if (pts == 0 or is_dns) else Color(0.6, 1.0, 0.6))
		row.add_child(lbl_pts)

		# Prize
		var lbl_prize = Label.new()
		lbl_prize.text = "+CR %s" % _fmt(int(prize)) if prize > 0 else ""
		lbl_prize.custom_minimum_size = Vector2(80, 0)
		lbl_prize.add_theme_font_size_override("font_size", 11)
		lbl_prize.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_prize.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
		row.add_child(lbl_prize)
		## Driver stat deltas moved to right column — see _build_driver_improvements()

func _build_standings(parent: VBoxContainer, teams_mode: bool) -> void:
	var lbl = Label.new()
	lbl.text = "TEAMS STANDINGS" if teams_mode else "DRIVERS STANDINGS"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	parent.add_child(lbl)

	if teams_mode:
		var champ = null
		for c in GameState.active_championships:
			if c.id == GameState.last_race_championship_id:
				champ = c
				break
		if champ == null and GameState.active_championships.size() > 0:
			champ = GameState.active_championships[0]
		if champ == null:
			var empty = Label.new()
			empty.text = "No standings yet."
			empty.modulate = Color(0.5, 0.5, 0.5)
			parent.add_child(empty)
			return

		# Column headers
		var hdr = HBoxContainer.new()
		hdr.add_theme_constant_override("separation", 0)
		parent.add_child(hdr)
		for pair in [["#", 28], ["Team", -1], ["Pts", 50]]:
			var lh = Label.new()
			lh.text = pair[0]
			lh.add_theme_font_size_override("font_size", 10)
			lh.modulate = Color(0.45, 0.45, 0.45)
			if pair[1] == -1: lh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			else: lh.custom_minimum_size = Vector2(pair[1], 0)
			if pair[0] == "Pts": lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hdr.add_child(lh)

		parent.add_child(HSeparator.new())

		var team_sorted = champ.get_team_standings_sorted()
		for i in range(team_sorted.size()):
			var entry = team_sorted[i]
			var team_name = "Unknown"
			var is_player = false
			for team in GameState.all_teams:
				if team.id == entry["team_id"]:
					team_name = team.team_name
					is_player = team.is_player_team
					break
			var pos = i + 1
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 0)
			parent.add_child(row)
			var lbl_pos = Label.new()
			lbl_pos.text = "%2d." % pos
			lbl_pos.custom_minimum_size = Vector2(28, 0)
			lbl_pos.add_theme_font_size_override("font_size", 12)
			row.add_child(lbl_pos)
			var lbl_name = Label.new()
			lbl_name.text = team_name
			lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_name.add_theme_font_size_override("font_size", 12)
			lbl_name.clip_contents = true
			if is_player:
				lbl_name.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			elif pos == 1:
				lbl_name.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			row.add_child(lbl_name)
			var lbl_pts = Label.new()
			lbl_pts.text = "%d pts" % entry["points"]
			lbl_pts.custom_minimum_size = Vector2(50, 0)
			lbl_pts.add_theme_font_size_override("font_size", 12)
			lbl_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl_pts.modulate = Color(0.7, 0.7, 0.7)
			row.add_child(lbl_pts)
	else:
		var standings = GameState.last_race_standings
		if standings.is_empty():
			var empty = Label.new()
			empty.text = "No standings yet."
			empty.modulate = Color(0.5, 0.5, 0.5)
			parent.add_child(empty)
			return

		# Column headers
		var hdr = HBoxContainer.new()
		hdr.add_theme_constant_override("separation", 0)
		parent.add_child(hdr)
		for pair in [["#", 28], ["Driver", 130], ["Team", -1], ["Pts", 50]]:
			var lh = Label.new()
			lh.text = pair[0]
			lh.add_theme_font_size_override("font_size", 10)
			lh.modulate = Color(0.45, 0.45, 0.45)
			if pair[1] == -1: lh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			else: lh.custom_minimum_size = Vector2(pair[1], 0)
			if pair[0] == "Pts": lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hdr.add_child(lh)

		parent.add_child(HSeparator.new())

		for i in range(standings.size()):
			var entry = standings[i]
			var driver = GameState.all_drivers.get(entry["driver_id"])
			if not driver:
				continue
			var is_player = entry["driver_id"] in GameState.player_team.drivers
			var pos = i + 1
			var team_name = ""
			for team in GameState.all_teams:
				if entry["driver_id"] in team.drivers:
					team_name = team.team_name
					break
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 0)
			parent.add_child(row)
			var lbl_pos = Label.new()
			lbl_pos.text = "%2d." % pos
			lbl_pos.custom_minimum_size = Vector2(28, 0)
			lbl_pos.add_theme_font_size_override("font_size", 12)
			row.add_child(lbl_pos)
			var lbl_name = Label.new()
			lbl_name.text = driver.full_name()
			lbl_name.custom_minimum_size = Vector2(130, 0)
			lbl_name.add_theme_font_size_override("font_size", 12)
			lbl_name.clip_contents = true
			if is_player:
				lbl_name.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			elif pos == 1:
				lbl_name.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			row.add_child(lbl_name)
			var lbl_team = Label.new()
			lbl_team.text = team_name
			lbl_team.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_team.add_theme_font_size_override("font_size", 10)
			lbl_team.clip_contents = true
			lbl_team.add_theme_color_override("font_color",
				Color(0.4, 0.8, 1.0) if is_player else Color(0.45, 0.45, 0.45))
			row.add_child(lbl_team)
			var lbl_pts = Label.new()
			lbl_pts.text = "%d pts" % entry["points"]
			lbl_pts.custom_minimum_size = Vector2(50, 0)
			lbl_pts.add_theme_font_size_override("font_size", 12)
			lbl_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl_pts.modulate = Color(0.7, 0.7, 0.7)
			row.add_child(lbl_pts)

func _build_car_condition(parent: VBoxContainer) -> void:
	var player_cars = GameState.player_team_cars.filter(
		func(c): return c.championship_id == GameState.last_race_championship_id)

	if player_cars.is_empty():
		return

	var lbl = Label.new()
	lbl.text = "CAR CONDITION"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	parent.add_child(lbl)

	for car in player_cars:
		var panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.12, 0.15)
		style.border_width_left = 2; style.border_width_right = 1
		style.border_width_top = 1; style.border_width_bottom = 1
		var cond = car.condition
		var border_c = Color(0.3, 0.9, 0.3)
		if cond < 70: border_c = Color(1.0, 0.6, 0.1)
		if cond < 40: border_c = Color(1.0, 0.2, 0.2)
		style.border_color = border_c
		style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
		style.content_margin_left = 10; style.content_margin_right = 10
		style.content_margin_top = 8; style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", style)
		parent.add_child(panel)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)

		var lbl_car = Label.new()
		lbl_car.text = "%s  —  Overall: %.0f%%" % [
			car.car_name if car.car_name != "" else "Car %d" % car.car_number, cond]
		lbl_car.add_theme_font_size_override("font_size", 13)
		var cc = Color(0.3, 0.9, 0.3)
		if cond < 70: cc = Color(1.0, 0.6, 0.1)
		if cond < 40: cc = Color(1.0, 0.3, 0.3)
		lbl_car.add_theme_color_override("font_color", cc)
		vbox.add_child(lbl_car)

		var parts_row = HBoxContainer.new()
		parts_row.add_theme_constant_override("separation", 8)
		vbox.add_child(parts_row)
		for part_name in ["Aero", "Engine", "Gearbox", "Suspension", "Brakes", "Chassis"]:
			var part_cond = car.part_conditions.get(part_name, 100.0)
			var pc = Color(0.3, 0.9, 0.3)
			if part_cond < 70: pc = Color(1.0, 0.6, 0.1)
			if part_cond < 40: pc = Color(1.0, 0.3, 0.3)
			var chip = Label.new()
			chip.text = "%s %.0f%%" % [part_name.left(3), part_cond]
			chip.add_theme_font_size_override("font_size", 10)
			chip.add_theme_color_override("font_color", pc)
			parts_row.add_child(chip)

func _on_continue() -> void:
	GameState.apply_post_race_repairs()
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		var screenshot = get_viewport().get_texture().get_image()
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
		screenshot.save_png("user://screenshot_%s.png" % timestamp)

func _section_panel(border_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.13)
	style.border_width_left = 3
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	# Inner VBox — callers add children to this
	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)
	return panel

func _fmt_time(seconds: float) -> String:
	if seconds <= 0.0: return "0:00:00.000"
	var h  = int(seconds) / 3600
	var m  = (int(seconds) % 3600) / 60
	var s  = int(seconds) % 60
	var ms = int((seconds - int(seconds)) * 1000.0)
	return "%d:%02d:%02d.%03d" % [h, m, s, ms]

func _build_driver_improvements(parent: VBoxContainer) -> void:
	var lbl = Label.new()
	lbl.text = "DRIVER DEVELOPMENT"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6))
	parent.add_child(lbl)

	var any = false
	for entry in GameState.last_race_results:
		var driver = entry.get("driver")
		if not driver: continue
		if not driver.id in GameState.player_team.drivers: continue
		if entry.get("dns", false): continue
		var deltas = entry.get("stat_deltas", {})
		if deltas.is_empty(): continue

		any = true
		var name_lbl = Label.new()
		name_lbl.text = driver.full_name() if driver.has_method("full_name") else str(driver)
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		parent.add_child(name_lbl)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		parent.add_child(row)

		for sk in [["Pace","pace"],["Wet","wet"],["Focus","focus"],["Exp","experience"],["Fit","fitness"]]:
			var dv = deltas.get(sk[1], 0.0)
			if abs(dv) > 0.01:
				var dl = Label.new()
				dl.text = "%s %s%.1f%s" % [sk[0], "+" if dv >= 0 else "", dv,
					"%" if sk[0] == "Fit" else ""]
				dl.add_theme_font_size_override("font_size", 11)
				dl.add_theme_color_override("font_color",
					Color(0.4, 0.9, 0.4) if dv >= 0 else Color(1.0, 0.4, 0.4))
				row.add_child(dl)

	if not any:
		var empty = Label.new()
		empty.text = "No development this race."
		empty.modulate = Color(0.5, 0.5, 0.5)
		empty.add_theme_font_size_override("font_size", 11)
		parent.add_child(empty)

func _build_staff_improvements(parent: VBoxContainer) -> void:
	var driver_deltas: Array = []
	for entry in GameState.last_race_results:
		if entry.get("dns", false): continue
		if not (entry.get("is_player", false) or entry["driver"].id in GameState.player_team.drivers):
			continue
		var deltas = entry.get("stat_deltas", {})
		var has_any = false
		for sk in ["pace","wet","focus","experience","fitness"]:
			if abs(deltas.get(sk, 0.0)) > 0.01: has_any = true; break
		if has_any: driver_deltas.append({"driver": entry["driver"], "deltas": deltas})

	var mech_deltas: Array = GameState.last_race_staff_deltas if "last_race_staff_deltas" in GameState else []
	if driver_deltas.is_empty() and mech_deltas.is_empty(): return

	var lbl_hdr = Label.new()
	lbl_hdr.text = "STAFF DEVELOPMENT"
	lbl_hdr.add_theme_font_size_override("font_size", 13)
	lbl_hdr.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	parent.add_child(lbl_hdr)

	for item in driver_deltas:
		var d = item["driver"]
		var deltas = item["deltas"]
		var panel = _make_dev_card(d.full_name(), "👤", Color(0.3, 0.55, 0.9))
		var vbox = panel.get_child(0)
		var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 10); vbox.add_child(row)
		for sk in [["Pace","pace"],["Wet","wet"],["Focus","focus"],["Exp","experience"]]:
			var dv = deltas.get(sk[1], 0.0)
			if abs(dv) > 0.01: row.add_child(_delta_lbl("%s %s%.1f" % [sk[0], "+" if dv >= 0 else "", dv], dv))
		var fd = deltas.get("fitness", 0.0)
		if abs(fd) > 0.01: row.add_child(_delta_lbl("Fit %s%.1f%%" % ["+" if fd >= 0 else "", fd], fd))
		parent.add_child(panel)

	for item in mech_deltas:
		var panel = _make_dev_card(item.get("name","Staff"), "🔧", Color(0.3, 0.7, 0.45))
		var vbox = panel.get_child(0)
		var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 10); vbox.add_child(row)
		for sk in [["Setup","car_setup"],["Track","track_knowledge"],["Strat","race_strategy"]]:
			var dv = item.get("deltas", {}).get(sk[1], 0.0)
			if abs(dv) > 0.01: row.add_child(_delta_lbl("%s %s%.1f" % [sk[0], "+" if dv >= 0 else "", dv], dv))
		parent.add_child(panel)

func _make_dev_card(name: String, icon: String, border: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.10) if icon == "🔧" else Color(0.08, 0.12, 0.18)
	style.border_width_left = 3; style.border_color = border
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 7; style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 4); panel.add_child(vbox)
	var lbl = Label.new(); lbl.text = "%s %s" % [icon, name]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.55,0.9,0.65) if icon == "🔧" else Color(0.65,0.85,1.0))
	vbox.add_child(lbl)
	return panel

func _delta_lbl(text: String, value: float) -> Label:
	var lbl = Label.new(); lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.4,0.9,0.4) if value >= 0 else Color(1.0,0.4,0.4))
	return lbl

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
