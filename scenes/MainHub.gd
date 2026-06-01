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
var notif_dim: ColorRect = null
var tab_cars_btn: Button
var cars_panel: ScrollContainer
var cars_box: VBoxContainer


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

	var drivers_btn = Button.new()
	drivers_btn.text = "👤 Drivers"
	drivers_btn.custom_minimum_size = Vector2(110, 35)
	drivers_btn.pressed.connect(_on_drivers_pressed)
	top_bar.add_child(drivers_btn)

	var staff_btn = Button.new()
	staff_btn.text = "🧑‍🔧 Staff"
	staff_btn.custom_minimum_size = Vector2(100, 35)
	staff_btn.pressed.connect(_on_staff_pressed)
	top_bar.add_child(staff_btn)

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
	notif_panel.custom_minimum_size = Vector2(560, 0)
	notif_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Center on screen
	notif_panel.set_anchor(SIDE_LEFT,   0.5)
	notif_panel.set_anchor(SIDE_RIGHT,  0.5)
	notif_panel.set_anchor(SIDE_TOP,    0.5)
	notif_panel.set_anchor(SIDE_BOTTOM, 0.5)
	notif_panel.offset_left   = -280
	notif_panel.offset_right  =  280
	notif_panel.offset_top    = -320
	notif_panel.offset_bottom =  320
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

	var close_btn = Button.new()
	close_btn.text = "✕ Close"
	close_btn.custom_minimum_size = Vector2(75, 30)
	close_btn.pressed.connect(_on_close_notif_panel)
	notif_header.add_child(close_btn)

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
	tab_cars_btn = Button.new()
	tab_cars_btn.text = "🔩 Cars"
	tab_cars_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_cars_btn.pressed.connect(func(): _show_tab("cars"))
	tab_row.add_child(tab_cars_btn)

	# Cars panel — ScrollContainer so it handles many cars gracefully
	cars_panel = ScrollContainer.new()
	cars_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cars_panel.visible = false
	side_panel.add_child(cars_panel)

	cars_box = VBoxContainer.new()
	cars_box.add_theme_constant_override("separation", 10)
	cars_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cars_panel.add_child(cars_box)

func _show_tab(tab: String) -> void:
	current_tab = tab
	drivers_panel.visible = (tab == "drivers")
	teams_panel.visible   = (tab == "teams")
	driver_panel.visible  = (tab == "mydriver")
	cars_panel.visible    = (tab == "cars")

	tab_drivers_btn.flat = (tab != "drivers")
	tab_teams_btn.flat   = (tab != "teams")
	tab_driver_btn.flat  = (tab != "mydriver")
	tab_cars_btn.flat    = (tab != "cars")

	match tab:
		"drivers":  _refresh_driver_standings()
		"teams":    _refresh_team_standings()
		"mydriver": _refresh_driver_stats()
		"cars":     _refresh_cars()

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

	# SP/FU warning colors — use championship thresholds
	var sp_threshold = GameState.active_championship.sp_per_10_pct_damage if GameState.active_championship else 120
	var fu_threshold = GameState.active_championship.fuel_per_car_per_race if GameState.active_championship else 15.0
	sp_label.add_theme_color_override("font_color",
		Color(1.0, 0.3, 0.3) if GameState.spare_parts < sp_threshold else Color(1.0, 0.8, 0.4))
	fu_label.add_theme_color_override("font_color",
		Color(1.0, 0.3, 0.3) if GameState.fuel_kg < fu_threshold else Color(1.0, 0.5, 0.3))

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
		# Add dim overlay behind panel
		notif_dim = ColorRect.new()
		notif_dim.color = Color(0, 0, 0, 0.55)
		notif_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		notif_dim.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_on_close_notif_panel()
		)
		add_child(notif_dim)
		move_child(notif_dim, get_child_count() - 2)  # dim behind panel
		_refresh_notifications()
		_update_display()
		GameState.mark_all_notifications_read()
	else:
		if notif_dim:
			notif_dim.queue_free()
			notif_dim = null

func _on_clear_notifs_pressed() -> void:
	GameState.mark_all_notifications_read()
	_refresh_notifications()
	_update_display()

func _on_close_notif_panel() -> void:
	notif_visible = false
	notif_panel.visible = false
	if notif_dim:
		notif_dim.queue_free()
		notif_dim = null
	
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

	for i in range(notifs.size() - 1, -1, -1):
		var n = notifs[i]
		var card = PanelContainer.new()

		# Unread cards get a highlighted style
		if not n["read"]:
			var stylebox = StyleBoxFlat.new()
			stylebox.bg_color = Color(0.18, 0.18, 0.22, 1.0)
			stylebox.border_width_left = 3
			stylebox.border_color = (
				Color(1.0, 0.3, 0.3) if n["priority"] == "Critical" else
				(Color(1.0, 0.6, 0.1) if n["priority"] == "High" else Color(0.3, 0.5, 1.0))
			)
			card.add_theme_stylebox_override("panel", stylebox)
		else:
			var stylebox = StyleBoxFlat.new()
			stylebox.bg_color = Color(0.12, 0.12, 0.14, 1.0)
			stylebox.border_width_left = 3
			stylebox.border_color = Color(0.3, 0.3, 0.3)
			card.add_theme_stylebox_override("panel", stylebox)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		card.add_child(vbox)

		var header_row = HBoxContainer.new()
		vbox.add_child(header_row)

		var priority_icon = "🔴" if n["priority"] == "Critical" else ("🟠" if n["priority"] == "High" else "🔵")
		var header = Label.new()
		header.text = "%s  S%d W%d" % [priority_icon, n["season"], n["week"]]
		header.add_theme_font_size_override("font_size", 11)
		header.add_theme_color_override("font_color",
			Color(1.0, 1.0, 1.0) if not n["read"] else Color(0.5, 0.5, 0.5))
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(header)

		if not n["read"]:
			var new_badge = Label.new()
			new_badge.text = " ● NEW"
			new_badge.add_theme_font_size_override("font_size", 11)
			new_badge.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
			header_row.add_child(new_badge)

		var msg = Label.new()
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg.custom_minimum_size = Vector2(500, 0)
		var color = (
			Color(1.0, 0.4, 0.4) if n["priority"] == "Critical" else
			(Color(1.0, 0.7, 0.3) if n["priority"] == "High" else Color(0.6, 0.8, 1.0))
		)

		msg.text = n["message"]
		if n["read"]:
			color = color.darkened(0.4)
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
	var tasks = GameState.get_pending_tasks()
	if tasks.is_empty():
		GameState.advance_week()
		_update_display()
		_show_tab(current_tab)
	else:
		_show_pending_tasks_dialog(tasks)

func _show_pending_tasks_dialog(tasks: Array) -> void:
	_show_modal(
		"📋 PENDING TASKS",
		"You have %d item%s that may need attention before advancing:" % [
			tasks.size(), "s" if tasks.size() != 1 else ""],
		tasks,
		"Review Later — Advance Anyway",
		"Go Back and Review",
		func():
			GameState.advance_week()
			_update_display()
			_show_tab(current_tab),
		null
	)

## Show a large centred modal panel with a title, subtitle, optional item list,
## and two action buttons. on_confirm fires on the left button, on_cancel on the right.
## Pass null for on_cancel to just close the modal.
func _show_modal(title: String, subtitle: String, items: Array,
		confirm_text: String, cancel_text: String,
		on_confirm: Callable, on_cancel) -> void:

	# Dim overlay — fills screen, modal sits on top
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Modal panel — anchored to full rect then sized via offsets to appear centered
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Override to give it a fixed width and auto height, truly centered
	panel.set_anchor(SIDE_LEFT,   0.5)
	panel.set_anchor(SIDE_RIGHT,  0.5)
	panel.set_anchor(SIDE_TOP,    0.5)
	panel.set_anchor(SIDE_BOTTOM, 0.5)
	panel.offset_left   = -310
	panel.offset_right  =  310
	panel.offset_top    = -300
	panel.offset_bottom =  300
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.13, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.6, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Title
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	vbox.add_child(HSeparator.new())

	# Subtitle
	if subtitle != "":
		var sub_lbl = Label.new()
		sub_lbl.text = subtitle
		sub_lbl.add_theme_font_size_override("font_size", 14)
		sub_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(sub_lbl)

	# Items list — fixed height scroll so items are always visible
	if not items.is_empty():
		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(520, 200)  # height always visible
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(scroll)

		var items_vbox = VBoxContainer.new()
		items_vbox.add_theme_constant_override("separation", 8)
		items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(items_vbox)

		for item in items:
			var item_panel = PanelContainer.new()
			item_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var item_style = StyleBoxFlat.new()
			item_style.bg_color = Color(0.16, 0.16, 0.20, 1.0)
			item_style.border_width_left = 3
			item_style.border_color = Color(1.0, 0.6, 0.2)
			item_style.content_margin_left = 12
			item_style.content_margin_right = 8
			item_style.content_margin_top = 8
			item_style.content_margin_bottom = 8
			item_panel.add_theme_stylebox_override("panel", item_style)
			items_vbox.add_child(item_panel)

			var item_lbl = Label.new()
			item_lbl.text = item
			item_lbl.add_theme_font_size_override("font_size", 13)
			item_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.6))
			item_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_panel.add_child(item_lbl)

	vbox.add_child(HSeparator.new())

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var cancel_btn = Button.new()
	cancel_btn.text = cancel_text
	cancel_btn.custom_minimum_size = Vector2(220, 44)
	cancel_btn.add_theme_font_size_override("font_size", 14)
	cancel_btn.visible = cancel_text != ""
	cancel_btn.pressed.connect(func():
		overlay.queue_free()
		panel.queue_free()
		if on_cancel != null:
			on_cancel.call()
	)
	btn_row.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = confirm_text
	confirm_btn.custom_minimum_size = Vector2(220, 44)
	confirm_btn.add_theme_font_size_override("font_size", 14)
	confirm_btn.pressed.connect(func():
		overlay.queue_free()
		panel.queue_free()
		on_confirm.call()
	)
	btn_row.add_child(confirm_btn)

func _show_notification(message: String) -> void:
	_show_modal(
		"📋 Automotive Empire",
		message,
		[],
		"OK",
		"",
		func(): pass,
		null
	)

func _show_confirmation(message: String, on_confirm: Callable) -> void:
	_show_modal(
		"Automotive Empire",
		message,
		[],
		"Confirm",
		"Cancel",
		on_confirm,
		null
	)

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

func _on_drivers_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Drivers.tscn")

func _on_staff_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Staff.tscn")

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

func _make_resource_label(_prefix: String, color: Color) -> Label:
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2(130, 0)
	return label

func _refresh_cars() -> void:
	for child in cars_box.get_children():
		child.queue_free()

	# ── Header ───────────────────────────────────────────────
	var title = Label.new()
	title.text = "🔩 MY CARS"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	cars_box.add_child(title)

	cars_box.add_child(HSeparator.new())

	# ── Resource summary ─────────────────────────────────────
	var sp_threshold = GameState.active_championship.sp_per_10_pct_damage
	var fu_threshold = GameState.active_championship.fuel_per_car_per_race
	var sp_icon = "🟢" if GameState.spare_parts >= sp_threshold else ("🟠" if GameState.spare_parts >= sp_threshold / 2 else "🔴")
	var fu_icon = "🟢" if GameState.fuel_kg >= fu_threshold else "🔴"
	var res_label = Label.new()
	res_label.text = "%s SP: %d units   %s FU: %.0f kg" % [sp_icon, GameState.spare_parts, fu_icon, GameState.fuel_kg]
	res_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	res_label.add_theme_font_size_override("font_size", 13)
	cars_box.add_child(res_label)

	if GameState.fuel_kg < fu_threshold:
		var warn = Label.new()
		warn.text = "⛽ WARNING: Fuel below %.0f kg — car will DNS!" % fu_threshold
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		warn.add_theme_font_size_override("font_size", 12)
		cars_box.add_child(warn)

	cars_box.add_child(HSeparator.new())

	# ── One card per Car object ───────────────────────────────
	if GameState.player_team_cars.is_empty():
		var no_car = Label.new()
		no_car.text = "No cars assigned yet."
		no_car.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		cars_box.add_child(no_car)
		return

	for car in GameState.player_team_cars:
		var driver = GameState.all_drivers.get(car.driver_id)
		var mechanic = GameState.get_mechanic_for_car(car.id)
		var condition = car.condition
		var damage = 100.0 - condition

		# ── Card ─────────────────────────────────────────────
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.13, 0.13, 0.16, 1.0)
		card_style.border_width_left = 3
		card_style.content_margin_left = 10
		card_style.content_margin_right = 10
		card_style.content_margin_top = 10
		card_style.content_margin_bottom = 10
		card_style.corner_radius_top_left = 4
		card_style.corner_radius_bottom_left = 4
		if condition >= 70.0:
			card_style.border_color = Color(0.2, 0.85, 0.2)
		elif condition >= 40.0:
			card_style.border_color = Color(1.0, 0.7, 0.1)
		else:
			card_style.border_color = Color(1.0, 0.25, 0.25)
		card.add_theme_stylebox_override("panel", card_style)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cars_box.add_child(card)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(vbox)

		# Car title + driver
		var name_row = HBoxContainer.new()
		vbox.add_child(name_row)
		var car_lbl = Label.new()
		car_lbl.text = "🏎  Car %d  [%s]" % [car.car_number, car.car_type_id]
		car_lbl.add_theme_font_size_override("font_size", 14)
		car_lbl.add_theme_color_override("font_color", Color.WHITE)
		car_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_row.add_child(car_lbl)
		var drv_lbl = Label.new()
		drv_lbl.text = driver.full_name() if driver else "⚠ No Driver"
		drv_lbl.add_theme_font_size_override("font_size", 13)
		drv_lbl.add_theme_color_override("font_color",
			Color(0.4, 0.8, 1.0) if driver else Color(1.0, 0.4, 0.4))
		name_row.add_child(drv_lbl)

		# Mechanic row
		var mech_lbl = Label.new()
		mech_lbl.text = "🔧 Mechanic: %s" % (mechanic.full_name() if mechanic else "⚠ None assigned")
		mech_lbl.add_theme_font_size_override("font_size", 12)
		mech_lbl.add_theme_color_override("font_color",
			Color(0.7, 0.9, 0.7) if mechanic else Color(1.0, 0.6, 0.2))
		vbox.add_child(mech_lbl)

		# Condition bar
		var cond_row = HBoxContainer.new()
		cond_row.add_theme_constant_override("separation", 8)
		vbox.add_child(cond_row)
		var cond_title = Label.new()
		cond_title.text = "Condition:"
		cond_title.add_theme_font_size_override("font_size", 12)
		cond_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		cond_title.custom_minimum_size = Vector2(80, 0)
		cond_row.add_child(cond_title)
		var bar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = condition
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(0, 18)
		bar.show_percentage = false
		var bar_style = StyleBoxFlat.new()
		bar_style.bg_color = Color(0.15, 0.75, 0.15) if condition >= 70.0 \
			else (Color(0.85, 0.55, 0.05) if condition >= 40.0 else Color(0.85, 0.15, 0.15))
		bar.add_theme_stylebox_override("fill", bar_style)
		cond_row.add_child(bar)
		var pct_lbl = Label.new()
		pct_lbl.text = "%.0f%%" % condition
		pct_lbl.add_theme_font_size_override("font_size", 13)
		pct_lbl.custom_minimum_size = Vector2(40, 0)
		pct_lbl.add_theme_color_override("font_color",
			Color(0.3, 1.0, 0.3) if condition >= 70.0
			else (Color(1.0, 0.75, 0.2) if condition >= 40.0 else Color(1.0, 0.3, 0.3)))
		cond_row.add_child(pct_lbl)

		# Fuel row
		var fuel_row = HBoxContainer.new()
		vbox.add_child(fuel_row)
		var fuel_title = Label.new()
		fuel_title.text = "Fuel:"
		fuel_title.add_theme_font_size_override("font_size", 12)
		fuel_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		fuel_title.custom_minimum_size = Vector2(80, 0)
		fuel_row.add_child(fuel_title)
		var fuel_ok = GameState.fuel_kg >= fu_threshold
		var fuel_val = Label.new()
		fuel_val.text = "%.0f kg available  (need %.0f kg)  %s" % [
			GameState.fuel_kg, fu_threshold,
			"✅ OK" if fuel_ok else "🚫 DNS RISK"]
		fuel_val.add_theme_font_size_override("font_size", 12)
		fuel_val.add_theme_color_override("font_color",
			Color(0.3, 1.0, 0.3) if fuel_ok else Color(1.0, 0.3, 0.3))
		fuel_row.add_child(fuel_val)

		# SP repair cost preview
		if damage > 0.0:
			var sp_for_full = int(ceil(damage / 10.0) * sp_threshold)
			var sp_preview = Label.new()
			sp_preview.text = "Full repair cost: %d SP  (have: %d SP)" % [
				sp_for_full, GameState.spare_parts]
			sp_preview.add_theme_font_size_override("font_size", 12)
			sp_preview.add_theme_color_override("font_color",
				Color(0.6, 0.9, 1.0) if GameState.spare_parts >= sp_for_full else Color(1.0, 0.5, 0.3))
			vbox.add_child(sp_preview)

		# Repair buttons
		var btn_row = HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 6)
		vbox.add_child(btn_row)

		var car_id = car.id
		var driver_id = car.driver_id

		var repair10_btn = Button.new()
		repair10_btn.text = "Fix 10%%  (-%d SP)" % sp_threshold
		repair10_btn.custom_minimum_size = Vector2(140, 30)
		repair10_btn.disabled = damage <= 0.0 or GameState.spare_parts < sp_threshold
		repair10_btn.pressed.connect(func():
			if GameState.repair_car(driver_id, 10.0):
				_refresh_cars()
				_update_display()
		)
		btn_row.add_child(repair10_btn)

		var repair50_btn = Button.new()
		repair50_btn.text = "Fix 50%%  (-%d SP)" % (sp_threshold * 5)
		repair50_btn.custom_minimum_size = Vector2(140, 30)
		repair50_btn.disabled = damage <= 0.0 or GameState.spare_parts < sp_threshold * 5
		repair50_btn.pressed.connect(func():
			if GameState.repair_car(driver_id, 50.0):
				_refresh_cars()
				_update_display()
		)
		btn_row.add_child(repair50_btn)

		var full_btn = Button.new()
		full_btn.text = "Full Repair"
		full_btn.custom_minimum_size = Vector2(110, 30)
		var sp_full = int(ceil(damage / 10.0) * sp_threshold)
		full_btn.disabled = damage <= 0.0 or GameState.spare_parts < sp_full
		full_btn.pressed.connect(func():
			if GameState.repair_car_full(driver_id):
				_refresh_cars()
				_update_display()
		)
		btn_row.add_child(full_btn)

	# Bottom hint
	var hint = Label.new()
	hint.text = "Buy SP, FU and parts at the Logistics Center on Campus."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cars_box.add_child(hint)
