extends Control

@onready var title_label = $Layout/TitleLabel
@onready var week_label = $Layout/WeekLabel
@onready var balance_label = $Layout/BalanceLabel
@onready var next_race_label = $Layout/NextRaceLabel
@onready var log_container = $Layout/MainArea/LogContainer
@onready var log_box = $Layout/MainArea/LogContainer/LogBox
@onready var advance_button = $Layout/AdvanceButton
@onready var side_panel = $Layout/MainArea/SidePanel
@onready var tab_row = $Layout/MainArea/SidePanel/TabRow
@onready var drivers_panel = $Layout/MainArea/SidePanel/DriversPanel
@onready var drivers_box = $Layout/MainArea/SidePanel/DriversPanel/DriversBox
@onready var teams_panel = $Layout/MainArea/SidePanel/TeamsPanel
@onready var teams_box = $Layout/MainArea/SidePanel/TeamsPanel/TeamsBox
@onready var driver_panel = $Layout/MainArea/SidePanel/DriverPanel
@onready var driver_stats_label = $Layout/MainArea/SidePanel/DriverPanel/DriverStatsLabel

var top_bar: HBoxContainer

var tab_drivers_btn: Button
var tab_teams_btn: Button
var tab_driver_btn: Button
var current_tab: String = "drivers"
var resource_bar: HBoxContainer
var cr_label: Label
var rp_label: Label
var sp_label: Label
var fu_label: Label
var notif_button: Button
var notif_panel: PanelContainer
var notif_box: VBoxContainer
var notif_visible: bool = false

func _ready() -> void:
	# Layout fills screen
	$Layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Title
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color.WHITE)

# Top navigation bar
	top_bar = $Layout/TopBar

# ── TOP BAR ──────────────────────────────────────────────────────
	var campus_btn = Button.new()
	campus_btn.text = "🏛 Campus"
	campus_btn.custom_minimum_size = Vector2(130, 35)
	campus_btn.pressed.connect(_on_campus_pressed)
	top_bar.add_child(campus_btn)

	# Resource bar
	resource_bar = HBoxContainer.new()
	resource_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	resource_bar.add_theme_constant_override("separation", 30)
	top_bar.add_child(resource_bar)

	cr_label = _make_resource_label("💰 CR", Color(0.4, 0.9, 0.4))
	rp_label = _make_resource_label("🔬 RP", Color(0.5, 0.7, 1.0))
	sp_label = _make_resource_label("🔧 SP", Color(1.0, 0.8, 0.4))
	fu_label = _make_resource_label("⛽ FU", Color(1.0, 0.5, 0.3))
	resource_bar.add_child(cr_label)
	resource_bar.add_child(rp_label)
	resource_bar.add_child(sp_label)
	resource_bar.add_child(fu_label)

	# Notification bell
	notif_button = Button.new()
	notif_button.text = "🔔 0"
	notif_button.custom_minimum_size = Vector2(70, 35)
	notif_button.pressed.connect(_on_notif_pressed)
	top_bar.add_child(notif_button)

	# Save / Load / Quit buttons (right side)
	var save_btn = Button.new()
	save_btn.text = "💾 Save"
	save_btn.custom_minimum_size = Vector2(90, 35)
	save_btn.pressed.connect(_on_save_pressed)
	top_bar.add_child(save_btn)

	var load_btn = Button.new()
	load_btn.text = "📂 Load"
	load_btn.custom_minimum_size = Vector2(90, 35)
	load_btn.pressed.connect(_on_load_pressed)
	top_bar.add_child(load_btn)

	var quit_btn = Button.new()
	quit_btn.text = "❌ Quit"
	quit_btn.custom_minimum_size = Vector2(90, 35)
	quit_btn.pressed.connect(_on_quit_pressed)
	top_bar.add_child(quit_btn)

	# ── NOTIFICATION PANEL (hidden by default) ────────────────────────
	notif_panel = PanelContainer.new()
	notif_panel.visible = false
	notif_panel.custom_minimum_size = Vector2(420, 0)
	notif_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Position it as overlay — add to root Control, not layout
	notif_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	notif_panel.offset_left = -440
	notif_panel.offset_top = 50
	notif_panel.offset_right = -10
	notif_panel.offset_bottom = 600
	add_child(notif_panel)

	var notif_vbox = VBoxContainer.new()
	notif_vbox.add_theme_constant_override("separation", 6)
	notif_panel.add_child(notif_vbox)

	var notif_header = HBoxContainer.new()
	notif_vbox.add_child(notif_header)

	var notif_title = Label.new()
	notif_title.text = "🔔 NOTIFICATIONS"
	notif_title.add_theme_font_size_override("font_size", 16)
	notif_title.add_theme_color_override("font_color", Color.WHITE)
	notif_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notif_header.add_child(notif_title)

	var clear_btn = Button.new()
	clear_btn.text = "Mark all read"
	clear_btn.custom_minimum_size = Vector2(110, 30)
	clear_btn.pressed.connect(_on_clear_notifs_pressed)
	notif_header.add_child(clear_btn)

	var notif_scroll = ScrollContainer.new()
	notif_scroll.custom_minimum_size = Vector2(400, 0)
	notif_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notif_vbox.add_child(notif_scroll)

	notif_box = VBoxContainer.new()
	notif_box.custom_minimum_size = Vector2(400, 0)
	notif_box.add_theme_constant_override("separation", 6)
	notif_scroll.add_child(notif_box)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# MainArea
	var main_area = $Layout/MainArea
	main_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_area.add_theme_constant_override("separation", 20)

	# Log container
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_container.size_flags_stretch_ratio = 0.6
	log_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.custom_minimum_size = Vector2(400, 0)

# Side panel sizing
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_panel.size_flags_stretch_ratio = 0.4
	side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Panel content sizing
	drivers_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	teams_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	driver_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drivers_box.custom_minimum_size = Vector2(300, 0)
	teams_box.custom_minimum_size = Vector2(300, 0)
	driver_stats_label.custom_minimum_size = Vector2(300, 0)
	driver_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Side panel
	side_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_panel.size_flags_stretch_ratio = 0.4
	side_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.add_theme_constant_override("separation", 5)

	# Build tabs
	_build_tabs()

	# Advance button
	advance_button.custom_minimum_size = Vector2(200, 50)
	advance_button.add_theme_font_size_override("font_size", 18)
	advance_button.text = "Advance Week ▶"
	advance_button.pressed.connect(_on_advance_pressed)

	# Connect signals
	GameState.week_advanced.connect(_on_week_advanced)
	GameState.season_ended.connect(_on_season_ended)
	GameState.log_updated.connect(_refresh_log)

	_update_display()
	_refresh_log()
	_show_tab("drivers")

	balance_label.visible = false

func _build_tabs() -> void:
	tab_row.add_theme_constant_override("separation", 2)

	tab_drivers_btn = Button.new()
	tab_drivers_btn.text = "🏆 Drivers"
	tab_drivers_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_drivers_btn.pressed.connect(func(): _show_tab("drivers"))
	tab_row.add_child(tab_drivers_btn)

	tab_teams_btn = Button.new()
	tab_teams_btn.text = "🏭 Teams"
	tab_teams_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_teams_btn.pressed.connect(func(): _show_tab("teams"))
	tab_row.add_child(tab_teams_btn)

	tab_driver_btn = Button.new()
	tab_driver_btn.text = "👤 My Driver"
	tab_driver_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_driver_btn.pressed.connect(func(): _show_tab("mydriver"))
	tab_row.add_child(tab_driver_btn)

func _show_tab(tab: String) -> void:
	current_tab = tab
	drivers_panel.visible = (tab == "drivers")
	teams_panel.visible = (tab == "teams")
	driver_panel.visible = (tab == "mydriver")
	tab_drivers_btn.flat = (tab != "drivers")
	tab_teams_btn.flat = (tab != "teams")
	tab_driver_btn.flat = (tab != "mydriver")
	match tab:
		"drivers": _refresh_driver_standings()
		"teams": _refresh_team_standings()
		"mydriver": _refresh_driver_stats()

func _update_display() -> void:
	title_label.text = "🏁 AUTOMOTIVE EMPIRE"
	week_label.text = "Season %d   —   Week %d / 52" % [GameState.current_season, GameState.current_week]
	week_label.add_theme_color_override("font_color", Color.WHITE)
	balance_label.text = "💰 Balance: $%.0f" % GameState.player_team.balance
	if GameState.player_team.balance >= 0:
		balance_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		balance_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	var next_race = GameState.active_championship.get_next_race()
	if next_race:
		next_race_label.text = "🏎 Next Race: Round %d — %s   (Week %d)" % [
			next_race["round"], next_race["name"], next_race["week"]
		]
	else:
		next_race_label.text = "✅ No more races this season"
	next_race_label.add_theme_color_override("font_color", Color.WHITE)
	# Resources
	cr_label.text = "💰 CR  $%s" % _format_number(GameState.player_team.balance)
	if GameState.player_team.balance >= 0:
		cr_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		cr_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	rp_label.text = "🔬 RP  %.0f" % GameState.research_points
	sp_label.text = "🔧 SP  %d" % GameState.spare_parts
	fu_label.text = "⛽ FU  %.0f kg" % GameState.fuel_kg

	# SP/FU warning colors
	sp_label.add_theme_color_override("font_color",
		Color(1.0, 0.3, 0.3) if GameState.spare_parts < 120 else Color(1.0, 0.8, 0.4))
	fu_label.add_theme_color_override("font_color",
		Color(1.0, 0.3, 0.3) if GameState.fuel_kg < 15.0 else Color(1.0, 0.5, 0.3))

	# Notification bell
	var unread = GameState.unread_notification_count
	notif_button.text = "🔔 %d" % unread
	if unread > 0:
		notif_button.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		notif_button.add_theme_color_override("font_color", Color.WHITE)

	# Also remove the old balance label update since cr_label handles it now

func _format_number(n: float) -> String:
	if abs(n) >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif abs(n) >= 1000:
		return "%.1fK" % (n / 1000.0)
	else:
		return "%.0f" % n

func _on_notif_pressed() -> void:
	notif_visible = !notif_visible
	notif_panel.visible = notif_visible
	if notif_visible:
		_refresh_notifications()
		GameState.mark_all_notifications_read()
		_update_display()

func _on_clear_notifs_pressed() -> void:
	GameState.mark_all_notifications_read()
	_refresh_notifications()
	_update_display()

func _refresh_notifications() -> void:
	for child in notif_box.get_children():
		child.queue_free()

	var notifs = GameState.notifications
	if notifs.is_empty():
		var empty = Label.new()
		empty.text = "No notifications"
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		notif_box.add_child(empty)
		return

	# Show newest first
	for i in range(notifs.size() - 1, -1, -1):
		var n = notifs[i]
		var card = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		card.add_child(vbox)

		var header = Label.new()
		var priority_icon = "🔴" if n["priority"] == "Critical" else ("🟠" if n["priority"] == "High" else "🔵")
		header.text = "%s  S%d W%d" % [priority_icon, n["season"], n["week"]]
		header.add_theme_font_size_override("font_size", 11)
		header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(header)

		var msg = Label.new()
		msg.text = n["message"]
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg.custom_minimum_size = Vector2(380, 0)
		var color = Color(1.0, 0.4, 0.4) if n["priority"] == "Critical" else (Color(1.0, 0.7, 0.3) if n["priority"] == "High" else Color(0.6, 0.8, 1.0))
		msg.add_theme_color_override("font_color", color)
		vbox.add_child(msg)

		notif_box.add_child(card)

		var sep = HSeparator.new()
		notif_box.add_child(sep)

func _refresh_driver_standings() -> void:
	for child in drivers_box.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "🏆 DRIVERS CHAMPIONSHIP"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	drivers_box.add_child(title)

	var sep = HSeparator.new()
	drivers_box.add_child(sep)

	var sorted = GameState.active_championship.get_standings_sorted()
	var player_drivers = GameState.player_team.drivers

	for i in range(sorted.size()):
		var entry = sorted[i]
		var driver = GameState.all_drivers.get(entry["driver_id"])
		if not driver:
			continue
		var pos = i + 1
		var is_player = entry["driver_id"] in player_drivers
		var medal = "🥇" if pos == 1 else ("🥈" if pos == 2 else ("🥉" if pos == 3 else "  %d." % pos))
		var label = Label.new()
		label.text = "%s %s — %d pts" % [medal, driver.full_name(), entry["points"]]
		label.custom_minimum_size = Vector2(300, 0)
		label.add_theme_color_override("font_color",
			Color(0.4, 0.8, 1.0) if is_player else
			(Color(1.0, 0.84, 0.0) if pos == 1 else
			(Color(0.75, 0.75, 0.75) if pos == 2 else
			(Color(0.8, 0.5, 0.2) if pos == 3 else Color.WHITE))))
		if is_player:
			label.add_theme_font_size_override("font_size", 15)
		drivers_box.add_child(label)

func _refresh_team_standings() -> void:
	for child in teams_box.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "🏭 TEAMS CHAMPIONSHIP"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	teams_box.add_child(title)

	var sep = HSeparator.new()
	teams_box.add_child(sep)

	var sorted = GameState.active_championship.get_team_standings_sorted()
	for i in range(sorted.size()):
		var entry = sorted[i]
		var team_name = "Unknown"
		var is_player = false
		for team in GameState.all_teams:
			if team.id == entry["team_id"]:
				team_name = team.team_name
				is_player = team.is_player_team
				break
		var pos = i + 1
		var medal = "🥇" if pos == 1 else ("🥈" if pos == 2 else ("🥉" if pos == 3 else "  %d." % pos))
		var label = Label.new()
		label.text = "%s %s — %d pts" % [medal, team_name, entry["points"]]
		label.custom_minimum_size = Vector2(300, 0)
		label.add_theme_color_override("font_color",
			Color(0.4, 0.8, 1.0) if is_player else
			(Color(1.0, 0.84, 0.0) if pos == 1 else
			(Color(0.75, 0.75, 0.75) if pos == 2 else
			(Color(0.8, 0.5, 0.2) if pos == 3 else Color.WHITE))))
		if is_player:
			label.add_theme_font_size_override("font_size", 15)
		teams_box.add_child(label)

func _refresh_driver_stats() -> void:
	if GameState.player_team.drivers.size() == 0:
		return
	var driver_id = GameState.player_team.drivers[0]
	var driver = GameState.all_drivers.get(driver_id)
	if not driver:
		return
	var sorted = GameState.active_championship.get_standings_sorted()
	var player_position = 0
	var player_points = 0
	for i in range(sorted.size()):
		if sorted[i]["driver_id"] == driver_id:
			player_position = i + 1
			player_points = sorted[i]["points"]
			break
	var active_adapt = driver.get_active_adaptation()
	var lines = []
	lines.append("👤 YOUR DRIVER")
	lines.append("━━━━━━━━━━━━━━━━━━━")
	lines.append("%s | Age: %d | %s" % [driver.full_name(), driver.age, driver.nationality])
	lines.append("")
	lines.append("Championship: P%d — %d pts" % [player_position, player_points])
	lines.append("")
	lines.append("ATTRIBUTES")
	lines.append("━━━━━━━━━━━━━━━━━━━")
	lines.append("🚀 Pace:             %.1f  (eff: %.1f)" % [driver.pace, driver.get_effective_pace()])
	lines.append("🌧 Wet:              %.1f  (eff: %.1f)" % [driver.wet, driver.get_effective_wet()])
	lines.append("🎯 Focus:            %.1f  (eff: %.1f)" % [driver.focus, driver.get_effective_focus()])
	lines.append("⚔ Race Craft:       %.1f  (eff: %.1f)" % [driver.race_craft, driver.get_effective_race_craft()])
	lines.append("💪 Fitness:          %.1f" % driver.fitness)
	lines.append("")
	lines.append("🔄 %s Adapt:        %.1f / 100" % [driver.active_discipline, active_adapt])
	lines.append("")
	lines.append("HIDDEN")
	lines.append("━━━━━━━━━━━━━━━━━━━")
	lines.append("⭐ Potential:        %.1f" % driver.potential)
	lines.append("😤 Aggression:       %.1f" % driver.aggression)
	lines.append("📚 Experience:       %.1f" % driver.experience)
	lines.append("")
	lines.append("STATUS")
	lines.append("━━━━━━━━━━━━━━━━━━━")
	lines.append("😊 Morale:           %.1f" % driver.morale)

	if GameState.player_team.drivers.size() > 1:
		var driver_id2 = GameState.player_team.drivers[1]
		var driver2 = GameState.all_drivers.get(driver_id2)
		if driver2:
			var pos2 = 0
			var pts2 = 0
			for i in range(sorted.size()):
				if sorted[i]["driver_id"] == driver_id2:
					pos2 = i + 1
					pts2 = sorted[i]["points"]
					break
			lines.append("")
			lines.append("")
			lines.append("👤 DRIVER 2")
			lines.append("━━━━━━━━━━━━━━━━━━━")
			lines.append("%s | Age: %d | %s" % [driver2.full_name(), driver2.age, driver2.nationality])
			lines.append("")
			lines.append("Championship: P%d — %d pts" % [pos2, pts2])
			lines.append("")
			lines.append("ATTRIBUTES")
			lines.append("━━━━━━━━━━━━━━━━━━━")
			lines.append("🚀 Pace:             %.1f  (eff: %.1f)" % [driver2.pace, driver2.get_effective_pace()])
			lines.append("🌧 Wet:              %.1f  (eff: %.1f)" % [driver2.wet, driver2.get_effective_wet()])
			lines.append("🎯 Focus:            %.1f  (eff: %.1f)" % [driver2.focus, driver2.get_effective_focus()])
			lines.append("⚔ Race Craft:       %.1f  (eff: %.1f)" % [driver2.race_craft, driver2.get_effective_race_craft()])
			lines.append("💪 Fitness:          %.1f" % driver2.fitness)
			lines.append("")
			lines.append("🔄 %s Adapt:        %.1f / 100" % [driver2.active_discipline, driver2.get_active_adaptation()])
			lines.append("")
			lines.append("HIDDEN")
			lines.append("━━━━━━━━━━━━━━━━━━━")
			lines.append("⭐ Potential:        %.1f" % driver2.potential)
			lines.append("😤 Aggression:       %.1f" % driver2.aggression)
			lines.append("📚 Experience:       %.1f" % driver2.experience)
			lines.append("")
			lines.append("STATUS")
			lines.append("━━━━━━━━━━━━━━━━━━━")
			lines.append("😊 Morale:           %.1f" % driver2.morale)

	driver_stats_label.text = "\n".join(lines)
	driver_stats_label.add_theme_color_override("font_color", Color.WHITE)

func _refresh_log() -> void:
	for child in log_box.get_children():
		child.queue_free()
	for message in GameState.weekly_log:
		var label = Label.new()
		label.text = message
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(400, 0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if message.begins_with("==="):
			label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
			label.add_theme_font_size_override("font_size", 16)
		elif message.begins_with("P1:") or message.begins_with("DRIVERS") or message.begins_with("TEAMS"):
			label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		elif message.begins_with("P2:"):
			label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		elif message.begins_with("P3:"):
			label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
		elif message.begins_with("Your driver"):
			label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		elif message.begins_with("Weather: WET"):
			label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
		elif message.begins_with("---"):
			label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		elif message.begins_with("Weekly expenses") or message.begins_with("Campus:"):
			label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		elif message.begins_with("🏗") or message.begins_with("⬆") or message.begins_with("✅"):
			label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		elif message.begins_with("aged out"):
			label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.0))
		else:
			label.add_theme_color_override("font_color", Color.WHITE)
		log_box.add_child(label)
	if is_inside_tree():
		await get_tree().process_frame
		if is_inside_tree():
			log_container.scroll_vertical = log_container.get_v_scroll_bar().max_value

func _on_advance_pressed() -> void:
	GameState.advance_week()
	_update_display()
	_show_tab(current_tab)

func _on_week_advanced(_week: int) -> void:
	_update_display()
	_refresh_log()
	_show_tab(current_tab)

func _on_season_ended(_season: int) -> void:
	advance_button.text = "Start Season %d ▶" % (GameState.current_season + 1)
	advance_button.disabled = false
	advance_button.pressed.disconnect(_on_advance_pressed)
	advance_button.pressed.connect(_on_new_season_pressed)
	_update_display()
	_refresh_log()
	_show_tab(current_tab)

func _on_new_season_pressed() -> void:
	GameState.start_new_season()
	advance_button.text = "Advance Week ▶"
	advance_button.pressed.disconnect(_on_new_season_pressed)
	advance_button.pressed.connect(_on_advance_pressed)
	_update_display()
	_refresh_log()
	_show_tab("drivers")

func _on_campus_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			var screenshot = get_viewport().get_texture().get_image()
			var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
			var path = "user://screenshot_%s.png" % timestamp
			screenshot.save_png(path)
			print("Screenshot saved: " + path)

func _on_save_pressed() -> void:
	GameState.save_game()
	_show_notification("✅ Game saved successfully!")

func _on_load_pressed() -> void:
	_show_confirmation(
		"Load saved game?\nAll unsaved progress will be lost.",
		func():
			GameState.load_game()
			_update_display()
			_refresh_log()
			_show_tab("drivers")
	)

func _on_quit_pressed() -> void:
	_show_confirmation(
		"Quit to desktop?\nAll unsaved progress will be lost.",
		func():
			get_tree().quit()
	)

func _show_notification(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Automotive Empire"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _make_resource_label(_prefix: String, color: Color) -> Label:
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2(130, 0)
	return label

func _show_confirmation(message: String, on_confirm: Callable) -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Automotive Empire"
	dialog.dialog_text = message
	dialog.ok_button_text = "Confirm"
	dialog.cancel_button_text = "Cancel"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func():
		on_confirm.call()
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
