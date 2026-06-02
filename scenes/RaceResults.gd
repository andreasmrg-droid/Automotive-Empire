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

	# Left column: race results
	var left_scroll = ScrollContainer.new()
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(left_scroll)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	left_scroll.add_child(left)

	_build_race_results(left)

	# Middle column: driver standings
	var mid_scroll = ScrollContainer.new()
	mid_scroll.custom_minimum_size = Vector2(300, 0)
	mid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(mid_scroll)

	var mid = VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 6)
	mid_scroll.add_child(mid)

	_build_standings(mid, false)

	# Right column: team standings + car condition
	var right_scroll = ScrollContainer.new()
	right_scroll.custom_minimum_size = Vector2(280, 0)
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(right_scroll)

	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	right_scroll.add_child(right)

	_build_standings(right, true)
	right.add_child(HSeparator.new())
	_build_car_condition(right)

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

	for i in range(results.size()):
		var entry = results[i]
		var driver = entry["driver"]
		var is_dns = entry.get("dns", false)
		var is_player = entry.get("is_player", false) or driver.id in GameState.player_team.drivers
		var pts = entry.get("points", 0)
		var prize = entry.get("prize", 0.0)
		var pos = i + 1

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		parent.add_child(row)

		# Position fixed 36px
		var lbl_pos = Label.new()
		if is_dns:     lbl_pos.text = "DNS"
		elif pos == 1: lbl_pos.text = "\U0001F947"
		elif pos == 2: lbl_pos.text = "\U0001F948"
		elif pos == 3: lbl_pos.text = "\U0001F949"
		else:          lbl_pos.text = "%2d." % pos
		lbl_pos.custom_minimum_size = Vector2(36, 0)
		lbl_pos.add_theme_font_size_override("font_size", 13)
		if is_dns: lbl_pos.modulate = Color(0.45, 0.45, 0.45)
		row.add_child(lbl_pos)

		# Driver name — expand
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

		# Points fixed 65px right-aligned
		var lbl_pts = Label.new()
		lbl_pts.text = "DNS" if is_dns else ("+%d pts" % pts if pts > 0 else "—")
		lbl_pts.custom_minimum_size = Vector2(65, 0)
		lbl_pts.add_theme_font_size_override("font_size", 12)
		lbl_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_pts.add_theme_color_override("font_color",
			Color(0.45,0.45,0.45) if (pts == 0 or is_dns) else Color(0.6, 1.0, 0.6))
		row.add_child(lbl_pts)

		# Prize fixed 80px right-aligned
		var lbl_prize = Label.new()
		lbl_prize.text = "+CR %s" % _fmt(int(prize)) if prize > 0 else ""
		lbl_prize.custom_minimum_size = Vector2(80, 0)
		lbl_prize.add_theme_font_size_override("font_size", 11)
		lbl_prize.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_prize.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
		row.add_child(lbl_prize)

		# Stat deltas for player drivers only
		if is_player and not is_dns:
			var deltas = entry.get("stat_deltas", {})
			if not deltas.is_empty():
				var dr = HBoxContainer.new()
				dr.add_theme_constant_override("separation", 8)
				parent.add_child(dr)
				var sp = Control.new()
				sp.custom_minimum_size = Vector2(36, 0)
				dr.add_child(sp)
				for sk in [["Pace","pace"],["Wet","wet"],["Focus","focus"],["Exp","experience"]]:
					var dv = deltas.get(sk[1], 0.0)
					if abs(dv) > 0.01:
						var dl = Label.new()
						dl.text = "%s %s%.1f" % [sk[0], "+" if dv >= 0 else "", dv]
						dl.add_theme_font_size_override("font_size", 10)
						dl.add_theme_color_override("font_color",
							Color(0.4,0.9,0.4) if dv >= 0 else Color(1.0,0.4,0.4))
						dr.add_child(dl)
				var fd = deltas.get("fitness", 0.0)
				if abs(fd) > 0.01:
					var fl = Label.new()
					fl.text = "Fit %s%.1f%%" % ["+" if fd >= 0 else "", fd]
					fl.add_theme_font_size_override("font_size", 10)
					fl.add_theme_color_override("font_color",
						Color(0.4,0.9,0.4) if fd >= 0 else Color(1.0,0.6,0.2))
					dr.add_child(fl)

func _build_standings(parent: VBoxContainer, teams_mode: bool) -> void:
	var lbl = Label.new()
	lbl.text = "TEAMS STANDINGS" if teams_mode else "DRIVERS STANDINGS"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	parent.add_child(lbl)

	if teams_mode:
		# Get current championship team standings
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
		var team_sorted = champ.get_team_standings_sorted()
		var max_show = min(team_sorted.size(), 10)
		for i in range(max_show):
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
		if team_sorted.size() > 10:
			var lbl_more = Label.new()
			lbl_more.text = "+%d more" % (team_sorted.size() - 10)
			lbl_more.add_theme_font_size_override("font_size", 11)
			lbl_more.modulate = Color(0.45, 0.45, 0.45)
			parent.add_child(lbl_more)
	else:
		# Driver standings
		var standings = GameState.last_race_standings
		if standings.is_empty():
			var empty = Label.new()
			empty.text = "No standings yet."
			empty.modulate = Color(0.5, 0.5, 0.5)
			parent.add_child(empty)
			return
		var max_show = min(standings.size(), 10)
		for i in range(max_show):
			var entry = standings[i]
			var driver = GameState.all_drivers.get(entry["driver_id"])
			if not driver:
				continue
			var is_player = entry["driver_id"] in GameState.player_team.drivers
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
			lbl_name.text = driver.full_name()
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
		if standings.size() > 10:
			var lbl_more = Label.new()
			lbl_more.text = "+%d more drivers" % (standings.size() - 10)
			lbl_more.add_theme_font_size_override("font_size", 11)
			lbl_more.modulate = Color(0.45, 0.45, 0.45)
			parent.add_child(lbl_more)

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
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		var screenshot = get_viewport().get_texture().get_image()
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
		screenshot.save_png("user://screenshot_%s.png" % timestamp)

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
