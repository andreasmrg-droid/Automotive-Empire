extends Control
## Version: S22.1 — TDL pinned above log scroll (never buried by log messages).
##                    Racing World button in top bar.
##                    TDL routing: GK TP and TP assignment items → Racing Department.

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

var advance_to_race_button: Button
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
var menu_popup: PanelContainer
var tdl_box: VBoxContainer  ## Fixed TDL panel — lives above the scroll log


func _ready() -> void:
	## Fix E: if we navigated away from BeginOfSeason to a building, come back here
	if GameState.pending_season_screen == "begin_of_season":
		get_tree().change_scene_to_file("res://scenes/BeginOfSeason.tscn")
		return

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

	var racing_world_btn = Button.new()
	racing_world_btn.text = Locale.t("rw_btn_short")
	racing_world_btn.custom_minimum_size = Vector2(120, 35)
	racing_world_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/RacingWorld.tscn"))
	top_bar.add_child(racing_world_btn)

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

	# Menu button — top right, opens centred popup overlay
	var menu_top_btn = Button.new()
	menu_top_btn.text = "☰ Menu"
	menu_top_btn.custom_minimum_size = Vector2(90, 35)
	menu_top_btn.pressed.connect(_show_menu_popup)
	top_bar.add_child(menu_top_btn)

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

	var dismiss_all_btn = Button.new()
	dismiss_all_btn.text = "Clear all"
	dismiss_all_btn.custom_minimum_size = Vector2(75, 30)
	dismiss_all_btn.modulate = Color(0.8, 0.5, 0.5)
	dismiss_all_btn.pressed.connect(func():
		GameState.notifications.clear()
		GameState.unread_notification_count = 0
		GameState.emit_signal("notifications_updated")
		_refresh_notifications()
		_update_display()
	)
	notif_header.add_child(dismiss_all_btn)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(30, 30)
	close_btn.pressed.connect(_on_close_notif_panel)
	notif_header.add_child(close_btn)

	var notif_scroll = ScrollContainer.new()
	notif_scroll.custom_minimum_size = Vector2(480, 0)
	notif_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notif_vbox.add_child(notif_scroll)

	notif_box = VBoxContainer.new()
	notif_box.custom_minimum_size = Vector2(480, 0)
	notif_box.add_theme_constant_override("separation", 6)
	notif_scroll.add_child(notif_box)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# MainArea
	var main_area = $Layout/MainArea
	main_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_area.add_theme_constant_override("separation", 20)

	# Log area: TDL (fixed) + Log (scrollable) stacked in a VBoxContainer
	var log_area = VBoxContainer.new()
	log_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_area.size_flags_stretch_ratio = 0.6
	log_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_area.add_theme_constant_override("separation", 0)
	## Reparent log_container into log_area
	main_area.remove_child(log_container)

	## Fixed TDL panel — always visible at top
	var tdl_panel = PanelContainer.new()
	tdl_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tdl_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var tdl_style = StyleBoxFlat.new()
	tdl_style.bg_color = Color(0.10, 0.11, 0.09)
	tdl_style.border_width_bottom = 1
	tdl_style.border_color = Color(0.3, 0.3, 0.2)
	tdl_style.content_margin_left = 8; tdl_style.content_margin_right = 8
	tdl_style.content_margin_top = 6; tdl_style.content_margin_bottom = 6
	tdl_panel.add_theme_stylebox_override("panel", tdl_style)
	tdl_box = VBoxContainer.new()
	tdl_box.add_theme_constant_override("separation", 4)
	tdl_panel.add_child(tdl_box)
	log_area.add_child(tdl_panel)

	## Scrollable log below
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_area.add_child(log_container)
	main_area.add_child(log_area)
	## Move log_area before side_panel (insert at index 0)
	main_area.move_child(log_area, 0)

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

	# Next Race button — sits next to Advance Week in the same parent
	advance_to_race_button = Button.new()
	advance_to_race_button.custom_minimum_size = Vector2(200, 50)
	advance_to_race_button.add_theme_font_size_override("font_size", 18)
	advance_to_race_button.text = "⏭ Next Race"
	advance_to_race_button.pressed.connect(_on_advance_to_race_pressed)
	advance_button.get_parent().add_child(advance_to_race_button)

	# Skip to End of Season button
	var skip_season_btn = Button.new()
	skip_season_btn.custom_minimum_size = Vector2(220, 50)
	skip_season_btn.add_theme_font_size_override("font_size", 16)
	skip_season_btn.text = "⏩ End of Season"
	skip_season_btn.modulate = Color(0.8, 0.8, 0.8)
	skip_season_btn.pressed.connect(_on_skip_to_season_end)
	advance_button.get_parent().add_child(skip_season_btn)

	# Championship Registration — always visible so deadlines are never missed
	# Connect signals
	GameState.week_advanced.connect(_on_week_advanced)
	GameState.season_ended.connect(_on_season_ended)
	GameState.log_updated.connect(_refresh_log)
	GameState.notifications_updated.connect(_on_notifications_updated)
	GameState.bankruptcy_triggered.connect(_show_bankruptcy_screen)

	_update_display()
	_refresh_log()
	_show_tab("drivers")

	balance_label.visible = false

	## Restore advance button state if we're mid-season-transition
	if GameState.pending_season_screen == "end_of_season":
		## Came back from EndOfSeason — show "Start Season N" button
		advance_button.text = "Start Season %d ▶" % (GameState.current_season + 1)
		advance_button.disabled = false
		if advance_button.pressed.is_connected(_on_advance_pressed):
			advance_button.pressed.disconnect(_on_advance_pressed)
		if not advance_button.pressed.is_connected(_on_new_season_pressed):
			advance_button.pressed.connect(_on_new_season_pressed)
		advance_to_race_button.disabled = true
		advance_to_race_button.text = "⏭ Next Race"
	elif GameState.pending_season_screen == "begin_of_season":
		## Came back from BeginOfSeason — normal week advance mode
		advance_button.text = "Advance Week ▶"
		if advance_button.pressed.is_connected(_on_new_season_pressed):
			advance_button.pressed.disconnect(_on_new_season_pressed)
		if not advance_button.pressed.is_connected(_on_advance_pressed):
			advance_button.pressed.connect(_on_advance_pressed)
		advance_to_race_button.disabled = false
		GameState.pending_season_screen = ""

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

	# Cars panel
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
	balance_label.text = "💰 Balance: CR %.0f" % GameState.player_team.balance
	if GameState.player_team.balance >= 0:
		balance_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		balance_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	# Find the soonest upcoming race across all active championships
	var soonest_race = null
	var soonest_champ = null
	for champ in GameState.active_championships:
		var nr = champ.get_next_race()
		if nr:
			if soonest_race == null or nr["week"] < soonest_race["week"]:
				soonest_race = nr
				soonest_champ = champ

	if soonest_race:
		var champ_tag = " [%s]" % soonest_champ.championship_name if GameState.active_championships.size() > 1 else ""
		next_race_label.text = "🏎 Next Race: Round %d — %s%s   (Week %d)" % [
			soonest_race["round"], soonest_race["name"], champ_tag, soonest_race["week"]
		]
		var weeks_away = soonest_race["week"] - GameState.current_week
		if advance_to_race_button:
			if weeks_away > 1:
				advance_to_race_button.text = "⏭ Next Race  (%d wks)" % weeks_away
				advance_to_race_button.disabled = false
			elif weeks_away == 1:
				advance_to_race_button.text = "⏭ Next Race  (1 wk)"
				advance_to_race_button.disabled = false
			else:
				advance_to_race_button.text = "⏭ Race Week!"
				advance_to_race_button.disabled = true
	else:
		next_race_label.text = "✅ No more races this season"
		if advance_to_race_button:
			advance_to_race_button.text = "⏭ Next Race"
			advance_to_race_button.disabled = true
	next_race_label.add_theme_color_override("font_color", Color.WHITE)
	# Resources
	cr_label.text = "💰 CR  %s" % _format_number(GameState.player_team.balance)
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

	# Notification bell — shows critical count in red, total unread in badge
	var unread = GameState.unread_notification_count
	var critical = GameState.get_critical_count()
	if critical > 0:
		notif_button.text = "🔔 %d 🔴%d" % [unread, critical]
		notif_button.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	elif unread > 0:
		notif_button.text = "🔔 %d" % unread
		notif_button.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
	else:
		notif_button.text = "🔔"
		notif_button.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

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
		empty.text = "No notifications — all clear! ✅"
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		notif_box.add_child(empty)
		return

	# Sort: unread first, then by priority (Critical > High > Normal), then by week desc
	var priority_order = {"Critical": 0, "High": 1, "Normal": 2}
	var sorted_notifs = []
	for i in range(notifs.size()):
		sorted_notifs.append({"index": i, "n": notifs[i]})
	sorted_notifs.sort_custom(func(a, b):
		var ar = 0 if not a["n"]["read"] else 1
		var br = 0 if not b["n"]["read"] else 1
		if ar != br: return ar < br
		var ap = priority_order.get(a["n"]["priority"], 2)
		var bp = priority_order.get(b["n"]["priority"], 2)
		if ap != bp: return ap < bp
		return a["n"]["week"] > b["n"]["week"]
	)

	for item in sorted_notifs:
		var idx = item["index"]
		var n = item["n"]
		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var is_critical = n["priority"] == "Critical"
		var is_high = n["priority"] == "High"
		var border_color = Color(1.0, 0.3, 0.3) if is_critical else \
			(Color(1.0, 0.6, 0.1) if is_high else Color(0.3, 0.5, 1.0))
		var bg_color = Color(0.18, 0.10, 0.10) if is_critical else \
			(Color(0.16, 0.13, 0.08) if is_high else Color(0.10, 0.12, 0.20))
		if n["read"]:
			bg_color = Color(0.11, 0.11, 0.13)
			border_color = border_color.darkened(0.5)

		var style = StyleBoxFlat.new()
		style.bg_color = bg_color
		style.border_width_left = 4
		style.border_color = border_color
		style.content_margin_left = 10; style.content_margin_right = 8
		style.content_margin_top = 8; style.content_margin_bottom = 8
		style.corner_radius_top_right = 4; style.corner_radius_bottom_right = 4
		card.add_theme_stylebox_override("panel", style)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		card.add_child(vbox)

		# Header row: icon + season/week + NEW badge + dismiss button
		var header_row = HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 6)
		vbox.add_child(header_row)

		var icon = "🔴" if is_critical else ("🟠" if is_high else "🔵")
		var lbl_header = Label.new()
		lbl_header.text = "%s  S%d W%d" % [icon, n["season"], n["week"]]
		lbl_header.add_theme_font_size_override("font_size", 11)
		lbl_header.modulate = Color(1.0, 1.0, 1.0) if not n["read"] else Color(0.5, 0.5, 0.5)
		lbl_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(lbl_header)

		if not n["read"]:
			var badge = Label.new()
			badge.text = "NEW"
			badge.add_theme_font_size_override("font_size", 10)
			badge.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
			header_row.add_child(badge)

		# Dismiss button
		var btn_dismiss = Button.new()
		btn_dismiss.text = "✕"
		btn_dismiss.custom_minimum_size = Vector2(24, 22)
		btn_dismiss.add_theme_font_size_override("font_size", 11)
		btn_dismiss.modulate = Color(0.6, 0.6, 0.6)
		var capture_idx = idx
		btn_dismiss.pressed.connect(func():
			GameState.dismiss_notification(capture_idx)
			_refresh_notifications()
			_update_display()
		)
		header_row.add_child(btn_dismiss)

		# Message
		var msg = Label.new()
		msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var text_color = border_color if not n["read"] else border_color.darkened(0.3)
		msg.add_theme_color_override("font_color", text_color)
		msg.add_theme_font_size_override("font_size", 12)
		msg.text = n["message"]
		vbox.add_child(msg)

		# Snooze row — only for unread notifications
		if not n["read"]:
			var snooze_row = HBoxContainer.new()
			snooze_row.add_theme_constant_override("separation", 4)
			vbox.add_child(snooze_row)
			var snooze_lbl = Label.new()
			snooze_lbl.text = "Snooze:"
			snooze_lbl.add_theme_font_size_override("font_size", 10)
			snooze_lbl.modulate = Color(0.5, 0.5, 0.5)
			snooze_row.add_child(snooze_lbl)
			for weeks in [1, 2, 4]:
				var btn_snooze = Button.new()
				btn_snooze.text = "%d wk" % weeks
				btn_snooze.custom_minimum_size = Vector2(44, 22)
				btn_snooze.add_theme_font_size_override("font_size", 10)
				var ci = idx
				var cw = weeks
				btn_snooze.pressed.connect(func():
					GameState.snooze_notification(ci, cw)
					_refresh_notifications()
					_update_display()
				)
				snooze_row.add_child(btn_snooze)

			## Navigation action button (S20)
			var dest = notifs[idx].get("destination", "")
			if dest != "" and dest in GameState.NOTIFICATION_DESTINATIONS:
				var btn_goto = Button.new()
				btn_goto.text = GameState.NOTIFICATION_DESTINATION_LABELS.get(dest, "Go \u2192")
				btn_goto.custom_minimum_size = Vector2(140, 24)
				btn_goto.add_theme_font_size_override("font_size", 11)
				btn_goto.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
				var capture_dest = dest
				var capture_idx2 = idx
				btn_goto.pressed.connect(func():
					notifs[capture_idx2]["read"] = true
					if capture_dest == "wra_office":
						GameState.pending_hq_tab = "wra_office"
					get_tree().change_scene_to_file(
						GameState.NOTIFICATION_DESTINATIONS[capture_dest]))
				snooze_row.add_child(btn_goto)

		notif_box.add_child(card)

func _refresh_driver_standings() -> void:
	for child in drivers_box.get_children():
		child.queue_free()

	# Show standings for ALL active championships
	for champ in GameState.active_championships:
		var title = Label.new()
		title.text = "🏆 %s" % champ.championship_name.to_upper()
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		drivers_box.add_child(title)

		var sorted = champ.get_standings_sorted()
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

		# Separator between championships
		if GameState.active_championships.size() > 1:
			drivers_box.add_child(HSeparator.new())

func _refresh_team_standings() -> void:
	for child in teams_box.get_children():
		child.queue_free()

	for champ in GameState.active_championships:
		var title = Label.new()
		title.text = "🏭 %s — TEAMS" % champ.championship_name.to_upper()
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		teams_box.add_child(title)

		var sorted = champ.get_team_standings_sorted()
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


		if GameState.active_championships.size() > 1:
			teams_box.add_child(HSeparator.new())

func _refresh_driver_stats() -> void:
	if GameState.player_team.drivers.size() == 0:
		driver_stats_label.text = "No drivers signed.\nGo to the Drivers screen to hire a driver."
		driver_stats_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		return

	var lines = []
	var sorted = GameState.active_championship.get_standings_sorted()

	for idx in range(GameState.player_team.drivers.size()):
		var driver_id = GameState.player_team.drivers[idx]
		var driver = GameState.all_drivers.get(driver_id)
		if not driver:
			continue

		var player_position = 0
		var player_points = 0
		for i in range(sorted.size()):
			if sorted[i]["driver_id"] == driver_id:
				player_position = i + 1
				player_points = sorted[i]["points"]
				break

		var car = GameState.get_car_for_driver(driver_id)
		var active_adapt = driver.get_active_adaptation()

		if idx > 0:
			lines.append("")
			lines.append("")

		lines.append("👤 %s" % ("YOUR DRIVER" if idx == 0 else "DRIVER %d" % (idx + 1)))
		lines.append("━━━━━━━━━━━━━━━━━━━")
		lines.append("%s | Age: %d | %s | %s" % [
			driver.full_name(), driver.age, driver.nationality, driver.sex])
		lines.append("Car: %s" % ("Car %d" % car.car_number if car else "⚠ Unassigned"))
		lines.append("")
		lines.append("Championship: %s" % (
			"P%d — %d pts" % [player_position, player_points] if player_position > 0 else "Not registered"))
		lines.append("")
		lines.append("RACING ATTRIBUTES")
		lines.append("━━━━━━━━━━━━━━━━━━━")
		lines.append("🚀 Pace:             %.1f  (eff: %.1f)" % [driver.pace, driver.get_effective_pace()])
		lines.append("🌧 Wet / Traction:   %.1f  (eff: %.1f)" % [driver.wet, driver.get_effective_wet()])
		lines.append("🎯 Focus:            %.1f  (eff: %.1f)" % [driver.focus, driver.get_effective_focus()])
		lines.append("⚔ Race Craft:       %.1f  (eff: %.1f)" % [driver.race_craft, driver.get_effective_race_craft()])
		lines.append("🔄 Consistency:      %.1f  (eff: %.1f)" % [driver.consistency, driver.get_effective_consistency()])
		lines.append("💬 Feedback:         %.1f" % driver.feedback)
		lines.append("")
		lines.append("🔄 %s Adapt:        %.1f / 100" % [driver.active_discipline, active_adapt])
		lines.append("")
		lines.append("STATUS")
		lines.append("━━━━━━━━━━━━━━━━━━━")
		lines.append("💪 Fitness:          %.1f" % driver.fitness)
		lines.append("😊 Morale:           %.1f" % driver.morale)
		lines.append("📣 Marketability:    %.1f" % driver.marketability)
		lines.append("⭐ Overall:          %.1f" % driver.get_overall_skill())

	driver_stats_label.text = "\n".join(lines)
	driver_stats_label.add_theme_color_override("font_color", Color.WHITE)

func _refresh_log() -> void:
	## ── TDL (fixed panel, always visible) ────────────────────────────────────
	for child in tdl_box.get_children():
		child.queue_free()

	var todo_header = HBoxContainer.new()
	todo_header.add_theme_constant_override("separation", 8)
	tdl_box.add_child(todo_header)

	var todo_lbl = Label.new()
	todo_lbl.text = "📋 TO-DO"
	todo_lbl.add_theme_font_size_override("font_size", 12)
	todo_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	todo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	todo_header.add_child(todo_lbl)

	var tasks = GameState.get_pending_tasks()
	if tasks.is_empty():
		var lbl_ok = Label.new()
		lbl_ok.text = "✅ All clear"
		lbl_ok.add_theme_font_size_override("font_size", 11)
		lbl_ok.modulate = Color(0.4, 0.9, 0.4)
		tdl_box.add_child(lbl_ok)
	else:
		for task_text in tasks:
			var task_row = HBoxContainer.new()
			task_row.add_theme_constant_override("separation", 4)
			tdl_box.add_child(task_row)

			var tl = Label.new()
			tl.text = task_text
			tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tl.add_theme_font_size_override("font_size", 11)
			tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var is_critical = task_text.begins_with("🚫") or task_text.begins_with("⏱") \
				or task_text.begins_with("⛽") or task_text.begins_with("💸") \
				or task_text.begins_with("🏎")
			tl.add_theme_color_override("font_color",
				Color(1.0, 0.4, 0.4) if is_critical else Color(1.0, 0.7, 0.3))
			task_row.add_child(tl)

			var dest = _get_todo_destination(task_text)
			if dest != "":
				var btn_go = Button.new()
				btn_go.text = "→"
				btn_go.custom_minimum_size = Vector2(28, 22)
				btn_go.add_theme_font_size_override("font_size", 10)
				btn_go.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
				var d = dest
				btn_go.pressed.connect(func():
					get_tree().change_scene_to_file(d))
				task_row.add_child(btn_go)

			var is_negotiation_task = "Offer sent to" in task_text or \
				"Negotiations open:" in task_text or "Contract Round" in task_text or \
				"their reply received" in task_text or "awaiting their reply" in task_text
			if not is_negotiation_task:
				var btn_x = Button.new()
				btn_x.text = "✕"
				btn_x.custom_minimum_size = Vector2(22, 22)
				btn_x.add_theme_font_size_override("font_size", 10)
				btn_x.modulate = Color(0.5, 0.5, 0.5)
				var tt = task_text
				btn_x.pressed.connect(func():
					GameState.dismiss_todo_item(tt))
				task_row.add_child(btn_x)

	## ── Log (scrollable below TDL) ────────────────────────────────────────────
	for child in log_box.get_children():
		child.queue_free()

	for message in GameState.weekly_log:
		if message.begins_with("Weekly expenses") or message.begins_with("Campus:") \
				or message.begins_with("💼 "):
			continue
		var label = Label.new()
		label.text = message
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(400, 0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if message.begins_with("==="):
			label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
			label.add_theme_font_size_override("font_size", 15)
			if GameState.active_championships.size() > 1:
				const DISC_COLORS = {
					"GK": Color(0.3, 0.9, 0.3), "Rally": Color(0.9, 0.55, 0.1),
					"TC": Color(0.3, 0.7, 1.0), "OWC": Color(0.8, 0.3, 0.9),
					"SC": Color(1.0, 0.3, 0.3), "EPC": Color(0.2, 0.9, 0.9),
					"GP": Color(1.0, 0.85, 0.0),
				}
				for champ in GameState.active_championships:
					if champ.championship_name in message:
						var reg = GameState.CHAMPIONSHIP_REGISTRY.get(champ.id, {})
						var disc = reg.get("discipline", "GK")
						label.add_theme_color_override("font_color",
							DISC_COLORS.get(disc, Color(1.0, 0.8, 0.0)))
						break
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

func _on_advance_to_race_pressed() -> void:
	# Find soonest upcoming race across all active championships
	var next_race = null
	for champ in GameState.active_championships:
		var nr = champ.get_next_race()
		if nr:
			if next_race == null or nr["week"] < next_race["week"]:
				next_race = nr
	# No more races — skip to end of season instead
	if not next_race:
		_on_skip_to_season_end()
		return
	var weeks_to_skip = next_race["week"] - GameState.current_week
	if weeks_to_skip <= 0:
		_on_advance_pressed()
		return
	var blocking = GameState.get_race_blocking_tasks()
	if not blocking.is_empty():
		_show_modal(
			"🚫 RACE BLOCKED",
			"These issues will prevent your car from racing:",
			blocking,
			"Advance Anyway",
			"Go Back and Fix",
			func():
				var inner_news = _skip_weeks_collect_news(weeks_to_skip - 1)
				_update_display()
				_refresh_log()
				_show_tab(current_tab)
				if not inner_news.is_empty():
					_show_modal("📰 News While You Were Away", "", inner_news, "OK", "", func(): pass, null),
			null
		)
		return
	var news = _skip_weeks_collect_news(weeks_to_skip - 1)
	_update_display()
	_refresh_log()
	_show_tab(current_tab)
	if not news.is_empty():
		_show_modal("📰 News While You Were Away", "Events during the skip:", news, "OK", "", func(): pass, null)

func _on_skip_to_season_end() -> void:
	var weeks_remaining = GameState.max_weeks - GameState.current_week
	if weeks_remaining <= 0:
		_show_notification("Already at the end of the season.")
		return
	var news = _skip_weeks_collect_news(weeks_remaining)
	_update_display()
	_refresh_log()
	_show_tab(current_tab)
	if not news.is_empty():
		_show_modal("📰 Season Summary", "Events during the skip:", news, "OK", "", func(): pass, null)

## Advances N weeks silently, collecting notable events (building completions, race results).
## Returns an Array of strings for the news modal.
func _skip_weeks_collect_news(n: int) -> Array:
	var news: Array = []
	for i in range(n):
		if GameState.current_week >= GameState.max_weeks:
			break
		GameState.advance_week()
		# Collect building completions from the weekly log
		for entry in GameState.weekly_log:
			if "✅" in entry and ("built" in entry.to_lower() or "upgraded" in entry.to_lower() or "complete" in entry.to_lower()):
				news.append("Wk %d: %s" % [GameState.current_week, entry])
		# Collect player race wins
		if GameState.last_race_results and not GameState.last_race_results.is_empty():
			var p1 = GameState.last_race_results[0]
			if p1.get("driver_id", "") in GameState.player_team.drivers:
				var d = GameState.all_drivers.get(p1["driver_id"])
				if d:
					news.append("🏆 Wk %d: %s WON the race!" % [GameState.current_week, d.full_name()])
	return news

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

func _on_notifications_updated() -> void:
	_update_display()

func _on_week_advanced(_week: int) -> void:
	_update_display()
	_refresh_log()
	_show_tab(current_tab)

func _on_season_ended(_season: int) -> void:
	## Show EndOfSeason screen instead of just updating the button
	get_tree().change_scene_to_file("res://scenes/EndOfSeason.tscn")

func _on_new_season_pressed() -> void:
	GameState.start_new_season()
	## Show BeginOfSeason screen
	get_tree().change_scene_to_file("res://scenes/BeginOfSeason.tscn")

func _on_campus_pressed() -> void:
	var campus_scene = load("res://scenes/Campus.tscn")
	if campus_scene == null:
		push_error("❌ Failed to load Campus.tscn! Scene might be missing from export.")
		return
	var error = get_tree().change_scene_to_packed(campus_scene)
	if error != OK:
			push_error("❌ Failed to switch to Campus scene. Error code: %s" % error)

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

	if event is InputEventKey and event.pressed and event.keycode == KEY_F9:
		var console = load("res://scenes/dev/DevProfileSelector.tscn").instantiate()
		console.console_mode = true
		get_tree().root.add_child(console)

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

func _show_menu_popup() -> void:
	## Remove any existing popup
	if menu_popup != null and is_instance_valid(menu_popup):
		menu_popup.queue_free()

	## Dim overlay — added before popup so it's behind it
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	## Centred card — assigned BEFORE connecting dim signal so lambda is never null
	menu_popup = PanelContainer.new()
	menu_popup.custom_minimum_size = Vector2(340, 0)
	## Position: horizontally left of centre, vertically upper quarter
	menu_popup.set_anchor(SIDE_LEFT,   0.5)
	menu_popup.set_anchor(SIDE_RIGHT,  0.5)
	menu_popup.set_anchor(SIDE_TOP,    0.15)
	menu_popup.set_anchor(SIDE_BOTTOM, 0.15)
	menu_popup.offset_left   = -250
	menu_popup.offset_right  = 0
	menu_popup.offset_top    = 0
	menu_popup.offset_bottom = 0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.11, 0.15)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.30, 0.38, 0.52)
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	style.content_margin_left = 20; style.content_margin_right = 20
	style.content_margin_top = 18; style.content_margin_bottom = 18
	menu_popup.add_theme_stylebox_override("panel", style)
	add_child(menu_popup)

	## Connect dim AFTER menu_popup is in scene so lambda never captures null
	dim.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			if is_instance_valid(menu_popup): menu_popup.queue_free()
			menu_popup = null
			if is_instance_valid(dim): dim.queue_free())

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	menu_popup.add_child(vbox)

	## Header row
	var hdr = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = "☰  MENU"
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(lbl)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.flat = true
	close_btn.pressed.connect(func():
		dim.queue_free()
		menu_popup.queue_free()
		menu_popup = null)
	hdr.add_child(close_btn)
	vbox.add_child(hdr)
	vbox.add_child(HSeparator.new())

	## Game info strip
	for row in [
		[Locale.t("lbl_season") + ":", "%d" % GameState.current_season],
		[Locale.t("lbl_week") + ":",   "%d / 52" % GameState.current_week],
		["Team:",    GameState.player_team.team_name if GameState.player_team else "—"],
		["Balance:", "CR %s" % GameState._fmt_int(int(GameState.player_team.balance if GameState.player_team else 0))],
	]:
		var r = HBoxContainer.new()
		r.add_theme_constant_override("separation", 8)
		var k = Label.new(); k.text = row[0]
		k.custom_minimum_size = Vector2(80, 0)
		k.add_theme_font_size_override("font_size", 12)
		k.modulate = Color(0.5, 0.5, 0.5)
		r.add_child(k)
		var v = Label.new(); v.text = row[1]
		v.add_theme_font_size_override("font_size", 12)
		r.add_child(v)
		vbox.add_child(r)

	vbox.add_child(HSeparator.new())

	## Action buttons
	const ACTIONS = [
		["🏁  New Game",    "new_game", Color(0.15, 0.38, 0.55)],
		["💾  Save Game",   "save",     Color(0.14, 0.42, 0.18)],
		["📂  Load Game",   "load",     Color(0.18, 0.22, 0.30)],
		["⚙   Settings",   "settings", Color(0.22, 0.18, 0.30)],
		["❌  Quit",        "quit",     Color(0.40, 0.12, 0.12)],
	]
	for action in ACTIONS:
		var btn = Button.new()
		btn.text = action[0]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", 15)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = action[2]
		btn_style.corner_radius_top_left = 5; btn_style.corner_radius_top_right = 5
		btn_style.corner_radius_bottom_left = 5; btn_style.corner_radius_bottom_right = 5
		btn_style.content_margin_top = 4; btn_style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", btn_style)
		var hover = btn_style.duplicate()
		hover.bg_color = action[2].lightened(0.12)
		btn.add_theme_stylebox_override("hover", hover)
		var action_id = action[1]
		var dim_ref = dim
		btn.pressed.connect(func():
			dim_ref.queue_free()
			menu_popup.queue_free()
			menu_popup = null
			_on_menu_action(action_id))
		vbox.add_child(btn)

func _on_menu_action(action: String) -> void:
	match action:
		"new_game":
			_show_confirmation(
				"Start a new game?\nAll unsaved progress will be lost.",
				func(): get_tree().change_scene_to_file("res://scenes/NewGame.tscn"))
		"save":
			GameState.save_game()
			_show_notification("✅ " + Locale.t("menu_saved"))
		"load":
			_show_load_picker()
		"settings":
			_show_notification("⚙ Settings coming soon.")
		"quit":
			_show_confirmation(
				Locale.t("menu_quit_confirm"),
				func(): get_tree().quit())

func _make_resource_label(_prefix: String, color: Color) -> Label:
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2(130, 0)
	return label


func _read_save_meta(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return {}
	var txt = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(txt) != OK: return {}
	var data = json.get_data()
	if not data is Dictionary: return {}
	return {
		"season":   data.get("current_season", 0),
		"week":     data.get("current_week", 0),
		"balance":  data.get("player_team", {}).get("balance", 0.0) \
			if data.get("player_team") is Dictionary else 0.0,
		"team":     data.get("player_team", {}).get("team_name", "?") \
			if data.get("player_team") is Dictionary else "?",
		"modified": FileAccess.get_modified_time(path),
	}


func _show_load_picker() -> void:
	if menu_popup != null and is_instance_valid(menu_popup):
		menu_popup.queue_free()

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	menu_popup = PanelContainer.new()
	menu_popup.custom_minimum_size = Vector2(420, 0)
	menu_popup.set_anchor(SIDE_LEFT,   0.5)
	menu_popup.set_anchor(SIDE_RIGHT,  0.5)
	menu_popup.set_anchor(SIDE_TOP,    0.15)
	menu_popup.set_anchor(SIDE_BOTTOM, 0.15)
	menu_popup.offset_left   = -250
	menu_popup.offset_right  = 0
	menu_popup.offset_top    = 0
	menu_popup.offset_bottom = 0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.11, 0.15)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.30, 0.38, 0.52)
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	style.content_margin_left = 20; style.content_margin_right = 20
	style.content_margin_top = 18; style.content_margin_bottom = 18
	menu_popup.add_theme_stylebox_override("panel", style)
	add_child(menu_popup)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	menu_popup.add_child(vbox)

	## Header
	var hdr = HBoxContainer.new()
	var lbl_title = Label.new()
	lbl_title.text = "📂  LOAD GAME"
	lbl_title.add_theme_font_size_override("font_size", 16)
	lbl_title.add_theme_color_override("font_color", Color.WHITE)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(lbl_title)
	var close_btn = Button.new()
	close_btn.text = "✕"; close_btn.flat = true
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.pressed.connect(func():
		dim.queue_free()
		menu_popup.queue_free(); menu_popup = null)
	hdr.add_child(close_btn)
	vbox.add_child(hdr)
	vbox.add_child(HSeparator.new())

	## Slot list
	const SLOTS = [
		["Manual Save", "user://save_game.json"],
		["Autosave 1",  "user://autosave_0.json"],
		["Autosave 2",  "user://autosave_1.json"],
		["Autosave 3",  "user://autosave_2.json"],
		["Autosave 4",  "user://autosave_3.json"],
	]

	var any_found = false
	for slot in SLOTS:
		var label = slot[0]
		var path  = slot[1]
		var meta  = _read_save_meta(path)

		var sp = PanelContainer.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sp_style = StyleBoxFlat.new()
		sp_style.bg_color = Color(0.13, 0.16, 0.22) if not meta.is_empty() \
			else Color(0.09, 0.10, 0.13)
		sp_style.corner_radius_top_left = 5; sp_style.corner_radius_top_right = 5
		sp_style.corner_radius_bottom_left = 5; sp_style.corner_radius_bottom_right = 5
		sp_style.content_margin_left = 12; sp_style.content_margin_right = 12
		sp_style.content_margin_top = 8; sp_style.content_margin_bottom = 8
		sp.add_theme_stylebox_override("panel", sp_style)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		sp.add_child(row)

		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 3)
		row.add_child(info)

		var lbl_slot = Label.new()
		lbl_slot.text = label
		lbl_slot.add_theme_font_size_override("font_size", 13)
		lbl_slot.add_theme_color_override("font_color",
			Color(0.8, 0.88, 1.0) if not meta.is_empty() else Color(0.4, 0.4, 0.4))
		info.add_child(lbl_slot)

		if meta.is_empty():
			var lbl_e = Label.new()
			lbl_e.text = "— empty —"
			lbl_e.add_theme_font_size_override("font_size", 11)
			lbl_e.modulate = Color(0.35, 0.35, 0.35)
			info.add_child(lbl_e)
		else:
			any_found = true
			var lbl_d = Label.new()
			lbl_d.text = "%s  ·  S%d W%d  ·  CR %s" % [
				meta["team"], meta["season"], meta["week"],
				GameState._fmt_int(int(meta["balance"]))]
			lbl_d.add_theme_font_size_override("font_size", 11)
			lbl_d.modulate = Color(0.6, 0.6, 0.6)
			info.add_child(lbl_d)

			var ts = int(meta["modified"])
			var lbl_t = Label.new()
			lbl_t.text = Time.get_datetime_string_from_unix_time(ts).left(16).replace("T", "  ")
			lbl_t.add_theme_font_size_override("font_size", 10)
			lbl_t.modulate = Color(0.38, 0.38, 0.38)
			info.add_child(lbl_t)

			var btn = Button.new()
			btn.text = "Load"
			btn.custom_minimum_size = Vector2(70, 32)
			btn.add_theme_font_size_override("font_size", 13)
			var load_path = path
			btn.pressed.connect(func():
				dim.queue_free()
				menu_popup.queue_free(); menu_popup = null
				GameState.load_game(load_path)
				_update_display()
				_refresh_log()
				_show_tab("drivers"))
			row.add_child(btn)

		vbox.add_child(sp)

	if not any_found:
		var lbl_none = Label.new()
		lbl_none.text = "No save files found."
		lbl_none.modulate = Color(0.5, 0.5, 0.5)
		lbl_none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_none)

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
	var sp_icon = "🟢" if GameState.spare_parts >= sp_threshold else ("🟠" if GameState.spare_parts >= sp_threshold / 2.0 else "🔴")
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
		car_lbl.text = "🏎  %s" % (car.car_name if car.car_name != "" else "Car %d" % car.car_number)
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

		var _car_id = car.id
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

## Returns scene path for a to-do item based on its content
func _get_todo_destination(task: String) -> String:
	## TP proposals — route to Racing Department
	if "GK TP" in task or "TP suggests" in task or "TPs have" in task \
			or "assignment suggestion" in task or "assignment update" in task \
			or "TP has" in task or "TP proposals" in task or "Racing Department" in task:
		return "res://scenes/buildings/RacingDept.tscn"
	## Car purchase — always Logistics first
	if "buy one at Logistics" in task or "No car for" in task or "Buy your first car" in task:
		return "res://scenes/buildings/Logistics.tscn"
	## Driver: hire = Drivers scene, assign = Garage
	if "No drivers signed" in task or "hire one from Drivers" in task:
		return "res://scenes/Drivers.tscn"
	if "no driver assigned" in task or "Go to Garage" in task:
		return "res://scenes/buildings/Garage.tscn"
	## Mechanic: hire = Staff scene, assign = Garage
	if "No Race Mechanic hired" in task or "hire one from Staff" in task:
		return "res://scenes/Staff.tscn"
	if "no mechanic assigned" in task:
		return "res://scenes/buildings/Garage.tscn"
	## Pit Crew
	if "Pit Crew" in task:
		return "res://scenes/buildings/PitCrewArena.tscn"
	## Staff roles
	if "Team Principal" in task:
		return "res://scenes/Staff.tscn"
	if "CFO" in task:
		return "res://scenes/Staff.tscn"
	## Resources
	if "Fuel" in task or "fuel" in task or "Spare parts" in task or "Logistics" in task:
		return "res://scenes/buildings/Logistics.tscn"
	## Financial
	if "Balance negative" in task or "Bankruptcy" in task:
		return "res://scenes/FinancialDept.tscn"
	## Car condition
	if "condition critical" in task or "Garage" in task:
		return "res://scenes/buildings/Garage.tscn"
	## Contracts — driver tasks have no role in brackets, staff tasks do e.g. "(Race Mechanic)"
	if "contract expires" in task:
		if "(" in task:  ## Has a role in brackets → staff
			return "res://scenes/Staff.tscn"
		return "res://scenes/Drivers.tscn"
	## Contract negotiations — always route to HQ (Pending Activity panel)
	## Match all patterns from get_pending_tasks step 7b
	if "Negotiations open:" in task or "negotiations open:" in task:
		return "res://scenes/buildings/HQ.tscn"
	if "Contract Round" in task or "contract round" in task:
		return "res://scenes/buildings/HQ.tscn"
	if "Offer sent to" in task and "reply" in task:
		return "res://scenes/buildings/HQ.tscn"
	if "awaiting their reply" in task:
		return "res://scenes/buildings/HQ.tscn"
	if "their reply received" in task:
		return "res://scenes/buildings/HQ.tscn"
	if "bond offer" in task.to_lower() or "bond approach" in task.to_lower():
		return "res://scenes/buildings/HQ.tscn"
	if "💰" in task and "bond" in task.to_lower():
		return "res://scenes/buildings/HQ.tscn"
	if "📤 Bond approach" in task:
		return "res://scenes/buildings/HQ.tscn"
	## R&D → WRA → CNC → Garage pipeline
	if "submit to WRA" in task or "Blueprint ready" in task:
		return "res://scenes/buildings/HQ.tscn"
	if "queue manufacturing" in task or "CNC Plant" in task:
		return "res://scenes/buildings/CNCPlant.tscn"
	if "install it in Garage" in task or "warehouse" in task:
		return "res://scenes/buildings/Garage.tscn"
	return ""

## ═══════════════════════════════════════════════════════════════════════════
## BANKRUPTCY SCREEN
## ═══════════════════════════════════════════════════════════════════════════

func _show_bankruptcy_screen() -> void:
	var overlay = PanelContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.07, 0.96)
	style.border_width_left = 4; style.border_width_right = 4
	style.border_width_top = 4; style.border_width_bottom = 4
	style.border_color = Color(0.8, 0.2, 0.2)
	overlay.add_theme_stylebox_override("panel", style)
	add_child(overlay)

	var center = VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 20)
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(640, 0)
	overlay.add_child(center)

	var lbl_title = Label.new()
	lbl_title.text = "🚨 BANKRUPTCY"
	lbl_title.add_theme_font_size_override("font_size", 36)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(lbl_title)

	var lbl_sub = Label.new()
	lbl_sub.text = "Your team has been insolvent for 8 consecutive weeks.\nYou must choose how to proceed."
	lbl_sub.add_theme_font_size_override("font_size", 15)
	lbl_sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(lbl_sub)

	var lbl_bal = Label.new()
	lbl_bal.text = "Balance: CR %s" % GameState._fmt_int(int(GameState.player_team.balance))
	lbl_bal.add_theme_font_size_override("font_size", 18)
	lbl_bal.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	lbl_bal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(lbl_bal)

	center.add_child(HSeparator.new())

	## Option 1 — Close team
	var btn_quit = _bankruptcy_btn(
		"❌  Close the Team",
		"End your career here. Return to the main menu.",
		Color(0.8, 0.3, 0.3))
	btn_quit.pressed.connect(func():
		overlay.queue_free()
		get_tree().change_scene_to_file("res://scenes/MainHub.tscn"))
	center.add_child(btn_quit)

	## Option 2 — Get hired
	var btn_hire = _bankruptcy_btn(
		"🤝  Get Hired by Another Team",
		"Your CEO enters the job market. Take over a struggling AI team\nas a hired manager — career continues.",
		Color(0.3, 0.6, 0.9))
	btn_hire.pressed.connect(func():
		overlay.queue_free()
		## CEO Job Market scene — coming in future build
		GameState.add_notification("Normal",
			"CEO Job Market coming in a future update."))
	center.add_child(btn_hire)

	## Option 3 — Start new team (requires CEO wealth)
	var ceo_wealth = GameState.ceo_accumulated_salary
	var threshold = 150000.0
	var can_start = ceo_wealth >= threshold
	var btn_start = _bankruptcy_btn(
		"🏁  Start a New Team  (CR %s required)" % GameState._fmt_int(int(threshold)),
		("Use your personal savings (CR %s) to start fresh." % GameState._fmt_int(int(ceo_wealth))) if can_start
		else "You need CR %s in personal savings. Currently: CR %s." % [
			GameState._fmt_int(int(threshold)), GameState._fmt_int(int(ceo_wealth))],
		Color(0.3, 0.8, 0.4) if can_start else Color(0.4, 0.4, 0.4))
	if not can_start:
		btn_start.modulate = Color(0.5, 0.5, 0.5)
		btn_start.disabled = true
	btn_start.pressed.connect(func():
		overlay.queue_free()
		## New team start — coming in future build
		GameState.add_notification("Normal",
			"New Team start coming in a future update."))
	center.add_child(btn_start)

	## Dismiss — temporary, allows continue
	var btn_dismiss = Button.new()
	btn_dismiss.text = "Dismiss  (continue at your own risk)"
	btn_dismiss.add_theme_font_size_override("font_size", 11)
	btn_dismiss.modulate = Color(0.4, 0.4, 0.4)
	btn_dismiss.pressed.connect(func():
		overlay.queue_free()
		GameState.bankruptcy_screen_shown = false)
	center.add_child(btn_dismiss)

func _bankruptcy_btn(title: String, desc: String, border_color: Color) -> Button:
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 70)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.10, 0.11, 0.14)
	style_normal.border_width_left = 3
	style_normal.border_color = border_color
	style_normal.corner_radius_top_left = 5; style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_left = 5; style_normal.corner_radius_bottom_right = 5
	style_normal.content_margin_left = 16; style_normal.content_margin_right = 16
	style_normal.content_margin_top = 12; style_normal.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.14, 0.15, 0.19)
	btn.add_theme_stylebox_override("hover", style_hover)

	var style_pressed_sb = style_normal.duplicate()
	style_pressed_sb.bg_color = Color(0.08, 0.09, 0.12)
	btn.add_theme_stylebox_override("pressed", style_pressed_sb)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(vb)

	var lt = Label.new()
	lt.text = title
	lt.add_theme_font_size_override("font_size", 14)
	lt.add_theme_color_override("font_color", border_color)
	lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(lt)

	var ld = Label.new()
	ld.text = desc
	ld.add_theme_font_size_override("font_size", 11)
	ld.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	ld.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ld.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(ld)

	return btn
