extends Control
## Version: S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## DEV PROFILE SELECTOR
## Shows before new game. Player picks a starting profile.
## Also handles the F9 dev console overlay (in-game cheat panel for testing).
## REMOVE or gate behind a build flag before public release.
##
## Usage:
##   1. In NewGame.tscn (or wherever you call setup_new_game()):
##      - Change scene to DevProfileSelector.tscn FIRST
##      - DevProfileSelector calls setup_new_game() then apply_dev_profile()
##      - Then changes scene to MainHub
##
##   2. In MainHub.gd, add to _input():
##      if event is InputEventKey and event.pressed and event.keycode == KEY_F9:
##          _open_dev_console()
##   Then call: get_tree().change_scene_to_file("res://scenes/dev/DevProfileSelector.tscn")
##   with GameState.dev_console_mode = true to open the in-game console.

## Set this to true from MainHub to open in console mode instead of selector mode.
var console_mode: bool = false

# ── Selector inputs ────────────────────────────────────────────────────────────
var _team_name_input: LineEdit
var _player_name_input: LineEdit
var _selected_profile: String = "starter"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if console_mode:
		_build_console_ui()
	else:
		_build_selector_ui()

# ═══════════════════════════════════════════════════════════════════════════════
# PROFILE SELECTOR
# ═══════════════════════════════════════════════════════════════════════════════

func _build_selector_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 40)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)

	# Title
	var lbl_title = Label.new()
	lbl_title.text = "🏎  AUTOMOTIVE EMPIRE"
	lbl_title.add_theme_font_size_override("font_size", 60)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl_title)

	var lbl_sub = Label.new()
	lbl_sub.text = "NEW GAME — Choose your starting profile"
	lbl_sub.add_theme_font_size_override("font_size", 32)
	lbl_sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl_sub)

	# Dev badge
	var lbl_dev = Label.new()
	lbl_dev.text = "⚠ DEV MODE — Remove profile selector before public release"
	lbl_dev.add_theme_font_size_override("font_size", 22)
	lbl_dev.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
	lbl_dev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl_dev)

	root.add_child(HSeparator.new())

	# Team name / player name inputs
	var inputs_row = HBoxContainer.new()
	inputs_row.add_theme_constant_override("separation", 30)
	inputs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(inputs_row)

	for pair in [["Team Name:", "My Racing Team", true], ["Your Name:", "Andreas", false]]:
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		inputs_row.add_child(vbox)
		var lbl = Label.new()
		lbl.text = pair[0]
		lbl.add_theme_font_size_override("font_size", 26)
		vbox.add_child(lbl)
		var input = LineEdit.new()
		input.text = pair[1]
		input.custom_minimum_size = Vector2(220, 36)
		input.add_theme_font_size_override("font_size", 28)
		if pair[2]:
			_team_name_input = input
		else:
			_player_name_input = input
		vbox.add_child(input)

	# Profile cards
	var profiles_label = Label.new()
	profiles_label.text = "STARTING PROFILE"
	profiles_label.add_theme_font_size_override("font_size", 28)
	profiles_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	root.add_child(profiles_label)

	var cards_row = HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 16)
	root.add_child(cards_row)

	for pid in GameState.DEV_PROFILES:
		cards_row.add_child(_build_profile_card(pid))

	root.add_child(HSeparator.new())

	# Start button
	var btn_start = Button.new()
	btn_start.text = "▶  START GAME"
	btn_start.custom_minimum_size = Vector2(280, 52)
	btn_start.add_theme_font_size_override("font_size", 36)
	btn_start.alignment = HORIZONTAL_ALIGNMENT_CENTER

	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(btn_row)
	btn_row.add_child(btn_start)

	btn_start.pressed.connect(_on_start_pressed)


func _build_profile_card(profile_id: String) -> PanelContainer:
	var profile = GameState.DEV_PROFILES[profile_id]
	var is_selected = profile_id == _selected_profile

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 110)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.16, 0.10) if is_selected else Color(0.09, 0.10, 0.13)
	style.border_width_left = 4; style.border_width_right = 1
	style.border_width_top  = 1; style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.9, 0.3) if is_selected else Color(0.25, 0.28, 0.35)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left  = 14; style.content_margin_right  = 14
	style.content_margin_top   = 12; style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var lbl_name = Label.new()
	lbl_name.text = profile["label"]
	lbl_name.add_theme_font_size_override("font_size", 30)
	if is_selected:
		lbl_name.add_theme_color_override("font_color", Color(0.4, 0.95, 0.4))
	vbox.add_child(lbl_name)

	var lbl_desc = Label.new()
	lbl_desc.text = profile["desc"]
	lbl_desc.add_theme_font_size_override("font_size", 22)
	lbl_desc.modulate = Color(0.6, 0.6, 0.6)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_desc)

	if is_selected:
		var lbl_sel = Label.new()
		lbl_sel.text = "✅ Selected"
		lbl_sel.add_theme_font_size_override("font_size", 22)
		lbl_sel.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		vbox.add_child(lbl_sel)

	var btn = Button.new()
	btn.text = "Select" if not is_selected else "Selected ✓"
	btn.disabled = is_selected
	btn.custom_minimum_size = Vector2(0, 26)
	btn.add_theme_font_size_override("font_size", 22)
	var pid = profile_id
	btn.pressed.connect(func():
		_selected_profile = pid
		get_tree().reload_current_scene()
	)
	vbox.add_child(btn)

	return panel


func _on_start_pressed() -> void:
	var team_name   = _team_name_input.text.strip_edges()
	var player_name = _player_name_input.text.strip_edges()
	if team_name == "":   team_name   = "My Racing Team"
	if player_name == "": player_name = "Player"
	GameState.setup_new_game(team_name, "British", player_name, 50000)
	GameState.apply_dev_profile(_selected_profile)
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")


# ═══════════════════════════════════════════════════════════════════════════════
# IN-GAME DEV CONSOLE (F9 from MainHub)
# ═══════════════════════════════════════════════════════════════════════════════

func _build_console_ui() -> void:
	# Semi-transparent overlay
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	margin.custom_minimum_size = Vector2(640, 560)
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 0)
	add_child(margin)

	var panel = PanelContainer.new()
	margin.add_child(panel)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var hdr = HBoxContainer.new()
	root.add_child(hdr)

	var lbl_title = Label.new()
	lbl_title.text = "🛠  DEV CONSOLE  (F9 to close)"
	lbl_title.add_theme_font_size_override("font_size", 34)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(lbl_title)

	var btn_close = Button.new()
	btn_close.text = "✕ Close"
	btn_close.custom_minimum_size = Vector2(90, 30)
	btn_close.pressed.connect(func(): queue_free())
	hdr.add_child(btn_close)

	root.add_child(HSeparator.new())

	# State summary
	var lbl_state = Label.new()
	lbl_state.text = "Season %d  ·  Week %d  ·  Balance CR %s  ·  RP %.0f / %d  ·  Cars: %d  ·  Staff: %d" % [
		GameState.current_season, GameState.current_week,
		_fmt(GameState.player_team.balance),
		GameState.research_points, GameState.get_rnd_rp_storage_cap(),
		GameState.player_team_cars.size(),
		GameState.get_all_player_staff().size()]
	lbl_state.add_theme_font_size_override("font_size", 24)
	lbl_state.modulate = Color(0.6, 0.85, 0.6)
	lbl_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(lbl_state)

	# Quick-action grid
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	root.add_child(grid)

	_console_btn(grid, "💰 +CR 100K",         func(): GameState.player_team.balance += 100000)
	_console_btn(grid, "💰 +CR 1M",            func(): GameState.player_team.balance += 1000000)
	_console_btn(grid, "💰 +CR 10M",           func(): GameState.player_team.balance += 10000000)
	_console_btn(grid, "🔵 +RP 100",           func(): GameState.research_points = min(GameState.research_points + 100, float(GameState.get_rnd_rp_storage_cap())))
	_console_btn(grid, "🔵 +RP 500",           func(): GameState.research_points = min(GameState.research_points + 500, float(GameState.get_rnd_rp_storage_cap())))
	_console_btn(grid, "🔵 Max RP",            func(): GameState.research_points = float(GameState.get_rnd_rp_storage_cap()))
	_console_btn(grid, "🔧 +500 SP",           func(): GameState.spare_parts += 500)
	_console_btn(grid, "⛽ +200 kg Fuel",      func(): GameState.fuel_kg += 200.0)
	_console_btn(grid, "⏩ +1 Season",          func(): GameState.current_season += 1)
	_console_btn(grid, "🏗 Build R&D Lv2",     func(): _dev_upgrade_building("R&D Design Studio", 2))
	_console_btn(grid, "🏗 Build CNC Lv2",      func(): _dev_upgrade_building("CNC Parts Plant", 2))
	_console_btn(grid, "🏗 All Eng. Lv2",       func(): _dev_upgrade_all_engineering(2))
	_console_btn(grid, "🔬 All P1 Blueprints",  func(): _dev_complete_pillar(1))
	_console_btn(grid, "🔬 All P2 Upgrades",    func(): _dev_complete_pillar(2))
	_console_btn(grid, "👤 Inject Designer",    func(): GameState._dev_inject_staff("Designer", 75.0))
	_console_btn(grid, "👤 Inject Mechanic",    func(): GameState._dev_inject_staff("Race Mechanic", 65.0))
	_console_btn(grid, "👤 Inject TP",          func(): GameState._dev_inject_staff("Team Principal", 70.0))
	_console_btn(grid, "📋 Register F3 (C-022)",func(): _dev_register("C-022"))
	_console_btn(grid, "📋 Register GT4 (C-009)",func(): _dev_register("C-009"))
	_console_btn(grid, "📋 Register F2 (C-023)",func(): _dev_register("C-023"))

	root.add_child(HSeparator.new())

	# Apply profile button row
	var lbl_prof = Label.new()
	lbl_prof.text = "Apply full profile over current state:"
	lbl_prof.add_theme_font_size_override("font_size", 24)
	lbl_prof.modulate = Color(0.6, 0.6, 0.6)
	root.add_child(lbl_prof)

	var prof_row = HBoxContainer.new()
	prof_row.add_theme_constant_override("separation", 10)
	root.add_child(prof_row)
	for pid in GameState.DEV_PROFILES:
		var btn = Button.new()
		btn.text = GameState.DEV_PROFILES[pid]["label"]
		btn.add_theme_font_size_override("font_size", 22)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var _pid = pid
		btn.pressed.connect(func():
			GameState.apply_dev_profile(_pid)
			queue_free()
			GameState.emit_signal("log_updated")
		)
		prof_row.add_child(btn)

	# Refresh button
	var btn_refresh = Button.new()
	btn_refresh.text = "🔄 Refresh State Display"
	btn_refresh.custom_minimum_size = Vector2(0, 32)
	btn_refresh.add_theme_font_size_override("font_size", 24)
	btn_refresh.pressed.connect(func():
		_build_console_ui()
	)
	root.add_child(btn_refresh)


func _console_btn(parent: GridContainer, label: String, action: Callable) -> void:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 34)
	btn.add_theme_font_size_override("font_size", 24)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func():
		action.call()
		GameState.emit_signal("log_updated")
		# Rebuild console to reflect new state
		for c in get_children(): c.queue_free()
		_build_console_ui()
	)
	parent.add_child(btn)


func _dev_upgrade_building(name: String, level: int) -> void:
	var b = GameState.campus_buildings.get(name, {})
	if not b.is_empty():
		b["built"] = true
		b["level"] = level
		b["construction_weeks_remaining"] = 0

func _dev_upgrade_all_engineering(level: int) -> void:
	for bname in ["R&D Design Studio", "CNC Parts Plant", "Aerodynamic Wind Tunnel",
			"Ops Sim & Telemetry", "Garage", "Headquarters"]:
		_dev_upgrade_building(bname, level)

func _dev_complete_pillar(pillar: int) -> void:
	for tid in GameState.RND_TASKS:
		var t = GameState.RND_TASKS[tid]
		if t.get("pillar", 0) != pillar: continue
		if tid in GameState.completed_rnd_tasks: continue
		GameState.completed_rnd_tasks.append(tid)
		GameState._apply_rnd_effect({
			"effect_key":   t.get("effect", ""),
			"effect_value": t.get("value", 0.0),
		})

func _dev_register(champ_id: String) -> void:
	if not champ_id in GameState.player_registered_championships:
		GameState.player_registered_championships.append(champ_id)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode in [KEY_F9, KEY_ESCAPE]:
		if console_mode:
			queue_free()

func _fmt(n: float) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.0fK" % (n / 1000.0)
	return str(int(n))
