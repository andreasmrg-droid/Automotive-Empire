extends Control
## Hall of Fame Screen
## Accessible from HQ and Museum.
## Shows all race wins, championship wins, and team history.

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

	# ── Header ─────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var lbl_title = Label.new()
	lbl_title.text = "🏆 HALL OF FAME  —  %s" % GameState.player_team.team_name
	lbl_title.add_theme_font_size_override("font_size", 24)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(100, 36)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)

	root.add_child(HSeparator.new())

	# ── Summary stats ───────────────────────────────────────────────────────
	var hof = GameState.hall_of_fame
	var team_wins = hof.filter(func(e): return e.get("team_id","") == GameState.player_team.id)
	var total_wins = team_wins.size()

	# Count by championship
	var by_champ: Dictionary = {}
	for entry in team_wins:
		var champ = entry.get("championship", "Unknown")
		by_champ[champ] = by_champ.get(champ, 0) + 1

	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 32)
	root.add_child(stats_row)

	for stat in [
		["🏁 Race Wins", str(total_wins)],
		["📅 Seasons Active", str(GameState.current_season)],
		["🏎 Championships Entered", str(GameState.active_championships.size())],
	]:
		var sv = VBoxContainer.new()
		sv.add_theme_constant_override("separation", 4)
		stats_row.add_child(sv)
		var lbl_v = Label.new()
		lbl_v.text = stat[1]
		lbl_v.add_theme_font_size_override("font_size", 28)
		lbl_v.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		sv.add_child(lbl_v)
		var lbl_k = Label.new()
		lbl_k.text = stat[0]
		lbl_k.add_theme_font_size_override("font_size", 11)
		lbl_k.modulate = Color(0.6, 0.6, 0.6)
		sv.add_child(lbl_k)

	root.add_child(HSeparator.new())

	# ── Two-column layout: wins by championship | full race wins list ───────
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	# Left: wins by championship
	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(280, 0)
	left.add_theme_constant_override("separation", 8)
	cols.add_child(left)

	var lbl_by_champ = Label.new()
	lbl_by_champ.text = "WINS BY CHAMPIONSHIP"
	lbl_by_champ.add_theme_font_size_override("font_size", 13)
	lbl_by_champ.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	left.add_child(lbl_by_champ)

	if by_champ.is_empty():
		var empty = Label.new()
		empty.text = "No wins yet — get racing! 🏎"
		empty.modulate = Color(0.5, 0.5, 0.5)
		empty.add_theme_font_size_override("font_size", 13)
		left.add_child(empty)
	else:
		# Sort by wins descending
		var champ_list = []
		for champ_name in by_champ:
			champ_list.append([champ_name, by_champ[champ_name]])
		champ_list.sort_custom(func(a, b): return a[1] > b[1])

		for entry in champ_list:
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			left.add_child(row)

			var lbl_trophy = Label.new()
			lbl_trophy.text = "🏆"
			row.add_child(lbl_trophy)

			var lbl_champ = Label.new()
			lbl_champ.text = entry[0]
			lbl_champ.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_champ.add_theme_font_size_override("font_size", 12)
			row.add_child(lbl_champ)

			var lbl_count = Label.new()
			lbl_count.text = "%d win%s" % [entry[1], "s" if entry[1] != 1 else ""]
			lbl_count.add_theme_font_size_override("font_size", 12)
			lbl_count.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			row.add_child(lbl_count)

	# Right: full wins list
	var right_scroll = ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(right_scroll)

	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	right_scroll.add_child(right)

	var lbl_wins = Label.new()
	lbl_wins.text = "ALL RACE WINS  (%d)" % total_wins
	lbl_wins.add_theme_font_size_override("font_size", 13)
	lbl_wins.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	right.add_child(lbl_wins)

	if team_wins.is_empty():
		var empty = Label.new()
		empty.text = "No wins recorded yet."
		empty.modulate = Color(0.5, 0.5, 0.5)
		right.add_child(empty)
	else:
		# Show most recent first
		var sorted_wins = team_wins.duplicate()
		sorted_wins.reverse()
		for entry in sorted_wins:
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			right.add_child(row)

			var lbl_season = Label.new()
			lbl_season.text = "S%d R%d" % [entry.get("season", 0), entry.get("round", 0)]
			lbl_season.custom_minimum_size = Vector2(60, 0)
			lbl_season.add_theme_font_size_override("font_size", 11)
			lbl_season.modulate = Color(0.5, 0.5, 0.5)
			row.add_child(lbl_season)

			var lbl_track = Label.new()
			lbl_track.text = entry.get("track", "?")
			lbl_track.custom_minimum_size = Vector2(180, 0)
			lbl_track.add_theme_font_size_override("font_size", 12)
			lbl_track.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			row.add_child(lbl_track)

			var lbl_champ = Label.new()
			lbl_champ.text = entry.get("championship", "")
			lbl_champ.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_champ.add_theme_font_size_override("font_size", 11)
			lbl_champ.modulate = Color(0.6, 0.7, 0.9)
			row.add_child(lbl_champ)

			var lbl_driver = Label.new()
			lbl_driver.text = entry.get("winner", "?")
			lbl_driver.custom_minimum_size = Vector2(140, 0)
			lbl_driver.add_theme_font_size_override("font_size", 12)
			lbl_driver.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			row.add_child(lbl_driver)

func _on_back() -> void:
	# Try to go back, fall back to MainHub
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
