extends Control
## Version: S37.40 — TDL routing: commitment-sponsor "requires racing X" task routes to HQ and
##   opens the WRA tab (registration), matching the R&D→WRA submit task.
## Version: S37.38 — Notification panel: removed per-notification Snooze buttons; added "Mark All as
##   Read" + "Delete All" buttons in the panel header next to the NOTIFICATIONS title (new
##   _build_notifications_panel). The per-notification nav "Go →" button is preserved (now in
##   action_row). Calls GameState.clear_all_notifications() / mark_all_notifications_read().
## Version: S37.37 — MainHub now uses the shared ResourceBar component (res://scenes/components/
##   ResourceBar.gd) instead of its own hand-rolled CR/RP/SP/FU labels — single source of truth for
##   the bar across every scene. removed the now-dead _make_resource_label helper.
## Version: S37.27 — MAIN HUB REDESIGN (mockup-driven). Hard prerequisite for the notification loop.
##   Layout: Row1 = team/player name · resource bar · Menu (BELL REMOVED). Row2 = Season|Week|Next
##   Race strip. Row3 = nav (Campus · Calendar · Drivers · Staff · Shortlist · Racing World). Centre
##   = three always-visible panels: TO-DO LIST · NOTIFICATIONS (now a permanent column, no bell/
##   slide-in) · NEWS (doubles as the weekly event LOG until the news system is built). Bottom =
##   a 5-WEEK STRIP (player-related events only, compact "+N more" overflow, from CalendarManager)
##   + the three advance buttons (Advance Week / Next Race / End of Season). The side panel + its
##   4 tabs (drivers/teams/my-driver/cars) are DELETED (standings live in Racing World).
##   Calendar button → res://scenes/Calendar.tscn (this session's feature).
## Prior (carried-over) version notes:
## S37.9 — Renegotiation TDL X button; S37.4 repair UX; S36.4 cluster-A active_championship reads.

# Built entirely in code from the simplified .tscn (root Control + Layout VBox).
var top_bar: HBoxContainer
var nameplate_label: Label
var title_label: Label
var week_label: Label
var balance_label: Label
var next_race_label: Label

# Resource bar
var resource_bar: HBoxContainer        ## wrapper kept for layout; bar is the shared component now
var _resource_bar = null               ## S37.37 shared ResourceBar component
const ResourceBarScript = preload("res://scenes/components/ResourceBar.gd")

# Centre panels
var tdl_box: VBoxContainer          ## To-Do list column body
var notif_box: VBoxContainer        ## Notifications column body (permanent — no bell/slide-in)
var log_box: VBoxContainer          ## News/Log column body
var log_container: ScrollContainer  ## scroll wrapper for log_box

# Bottom 5-week strip
var week_strip: HBoxContainer

# Advance buttons
var advance_button: Button
var advance_to_race_button: Button

# Menu popup
var menu_popup: PanelContainer

const WEEK_STRIP_COUNT := 5         ## weeks shown ahead on the hub strip
const STRIP_MAX_CHIPS := 3          ## events shown per week before "+N more"


func _ready() -> void:
	## Fix E: returning from BeginOfSeason to a building → come back here.
	if GameState.pending_season_screen == "begin_of_season":
		get_tree().change_scene_to_file("res://scenes/BeginOfSeason.tscn")
		return

	var layout: VBoxContainer = $Layout
	## Inset 10px from every screen edge (small gap so content doesn't touch the bezel).
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 10
	layout.offset_top = 10
	layout.offset_right = -10
	layout.offset_bottom = -10
	layout.add_theme_constant_override("separation", 10)

	# ═══ ROW 1: nameplate · resource bar · menu ═══
	top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 16)
	layout.add_child(top_bar)

	nameplate_label = Label.new()
	nameplate_label.add_theme_font_size_override("font_size", 30)
	nameplate_label.custom_minimum_size = Vector2(300, 0)
	top_bar.add_child(nameplate_label)

	# Shared ResourceBar component (S37.37) — replaces the hand-rolled CR/RP/SP/FU labels.
	resource_bar = HBoxContainer.new()
	resource_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(resource_bar)
	_resource_bar = ResourceBarScript.new()
	_resource_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resource_bar.add_child(_resource_bar)

	var menu_btn := Button.new()
	menu_btn.text = "☰ Menu"
	menu_btn.custom_minimum_size = Vector2(110, 40)
	menu_btn.pressed.connect(_show_menu_popup)
	top_bar.add_child(menu_btn)

	# hidden legacy labels still referenced by carried-over code
	title_label = Label.new(); title_label.visible = false; layout.add_child(title_label)
	week_label = Label.new(); week_label.visible = false; layout.add_child(week_label)
	balance_label = Label.new(); balance_label.visible = false; layout.add_child(balance_label)

	# ═══ ROW 2: Season | Week | Next Race strip ═══
	var status_panel := PanelContainer.new()
	status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_race_label = Label.new()
	next_race_label.add_theme_font_size_override("font_size", 26)
	next_race_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_panel.add_child(next_race_label)
	layout.add_child(status_panel)

	# ═══ ROW 3: nav buttons ═══
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	layout.add_child(nav)
	for spec in [
		["🏛 Campus",  _on_campus_pressed],
		["📅 Calendar", func(): get_tree().change_scene_to_file("res://scenes/Calendar.tscn")],
		["👤 Drivers",  _on_drivers_pressed],
		["🧑‍🔧 Staff",   _on_staff_pressed],
		["⭐ Shortlist", func(): get_tree().change_scene_to_file("res://scenes/Shortlist.tscn")],
		[Locale.t("rw_btn_short"), func(): get_tree().change_scene_to_file("res://scenes/RacingWorld.tscn")],
	]:
		var b := Button.new()
		b.text = spec[0]
		b.custom_minimum_size = Vector2(140, 40)
		b.pressed.connect(spec[1])
		nav.add_child(b)

	# ═══ CENTRE: three equal panels (To-Do · Notifications · News/Log) ═══
	var centre := HBoxContainer.new()
	centre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centre.add_theme_constant_override("separation", 12)
	layout.add_child(centre)

	tdl_box = _build_panel(centre, "📋 TO-DO LIST")
	notif_box = _build_notifications_panel(centre)
	var log_pair := _build_scroll_panel(centre, "📰 NEWS")
	log_container = log_pair[0]
	log_box = log_pair[1]

	# ═══ BOTTOM: 5-week strip + advance buttons ═══
	var strip_panel := PanelContainer.new()
	strip_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	week_strip = HBoxContainer.new()
	week_strip.add_theme_constant_override("separation", 8)
	week_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip_panel.add_child(week_strip)
	layout.add_child(strip_panel)

	var adv_row := HBoxContainer.new()
	adv_row.alignment = BoxContainer.ALIGNMENT_CENTER
	adv_row.add_theme_constant_override("separation", 14)
	layout.add_child(adv_row)

	advance_button = Button.new()
	advance_button.custom_minimum_size = Vector2(220, 52)
	advance_button.add_theme_font_size_override("font_size", 32)
	advance_button.text = "Advance Week ▶"
	advance_button.pressed.connect(_on_advance_pressed)
	adv_row.add_child(advance_button)

	advance_to_race_button = Button.new()
	advance_to_race_button.custom_minimum_size = Vector2(220, 52)
	advance_to_race_button.add_theme_font_size_override("font_size", 32)
	advance_to_race_button.text = "⏭ Next Race"
	advance_to_race_button.pressed.connect(_on_advance_to_race_pressed)
	adv_row.add_child(advance_to_race_button)

	var skip_btn := Button.new()
	skip_btn.custom_minimum_size = Vector2(220, 52)
	skip_btn.add_theme_font_size_override("font_size", 30)
	skip_btn.text = "⏩ End of Season"
	skip_btn.modulate = Color(0.8, 0.8, 0.8)
	skip_btn.pressed.connect(_on_skip_to_season_end)
	adv_row.add_child(skip_btn)

	# ═══ signals ═══
	GameState.week_advanced.connect(_on_week_advanced)
	GameState.season_ended.connect(_on_season_ended)
	GameState.log_updated.connect(_refresh_log)
	GameState.notifications_updated.connect(_on_notifications_updated)
	GameState.bankruptcy_triggered.connect(_show_bankruptcy_screen)
	if GameState.has_signal("approach_updated") and not GameState.approach_updated.is_connected(_update_display):
		GameState.approach_updated.connect(_update_display)

	_update_display()
	_refresh_todo()
	_refresh_log()
	_refresh_notifications()
	_refresh_week_strip()

	## Restore advance-button state mid-season-transition
	if GameState.pending_season_screen == "end_of_season":
		advance_button.text = "Start Season %d ▶" % (GameState.current_season + 1)
		advance_button.disabled = false
		if advance_button.pressed.is_connected(_on_advance_pressed):
			advance_button.pressed.disconnect(_on_advance_pressed)
		if not advance_button.pressed.is_connected(_on_new_season_pressed):
			advance_button.pressed.connect(_on_new_season_pressed)
		advance_to_race_button.disabled = true
	elif GameState.pending_season_screen == "begin_of_season":
		advance_button.text = "Advance Week ▶"
		if advance_button.pressed.is_connected(_on_new_season_pressed):
			advance_button.pressed.disconnect(_on_new_season_pressed)
		if not advance_button.pressed.is_connected(_on_advance_pressed):
			advance_button.pressed.connect(_on_advance_pressed)
		advance_to_race_button.disabled = false
		GameState.pending_season_screen = ""

## Builds a titled panel with a header + a VBox body (returned for population).
func _build_panel(parent: Control, title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	var h := Label.new()
	h.text = title
	h.add_theme_font_size_override("font_size", 26)
	h.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vb.add_child(h)
	vb.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	scroll.add_child(body)
	vb.add_child(scroll)
	parent.add_child(panel)
	return body

## Like _build_panel but the header row carries "Mark All as Read" + "Delete All" buttons next to
## the NOTIFICATIONS title (S37.38). Returns the body VBox (same contract as _build_panel).
func _build_notifications_panel(parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	vb.add_child(header)

	var h := Label.new()
	h.text = "🔔 NOTIFICATIONS"
	h.add_theme_font_size_override("font_size", 26)
	h.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(h)

	var btn_read_all := Button.new()
	btn_read_all.text = "Mark All as Read"
	btn_read_all.add_theme_font_size_override("font_size", 20)
	btn_read_all.tooltip_text = "Mark every notification as read."
	btn_read_all.pressed.connect(func():
		GameState.mark_all_notifications_read()
		_refresh_notifications()
		_update_display())
	header.add_child(btn_read_all)

	var btn_delete_all := Button.new()
	btn_delete_all.text = "Delete All"
	btn_delete_all.add_theme_font_size_override("font_size", 20)
	btn_delete_all.add_theme_color_override("font_color", Color(0.95, 0.5, 0.5))
	btn_delete_all.tooltip_text = "Remove all notifications."
	btn_delete_all.pressed.connect(func():
		GameState.clear_all_notifications()
		_refresh_notifications()
		_update_display())
	header.add_child(btn_delete_all)

	vb.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	scroll.add_child(body)
	vb.add_child(scroll)
	parent.add_child(panel)
	return body
func _build_scroll_panel(parent: Control, title: String) -> Array:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	var h := Label.new()
	h.text = title
	h.add_theme_font_size_override("font_size", 26)
	h.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vb.add_child(h)
	vb.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	scroll.add_child(body)
	vb.add_child(scroll)
	parent.add_child(panel)
	return [scroll, body]

func _update_display() -> void:
	nameplate_label.text = "%s\n%s" % [
		GameState.player_team.team_name if GameState.player_team else "—",
		GameState.player_name if "player_name" in GameState else ""]
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
		next_race_label.text = "Season %d  ·  Week %d / 52      🏎 Next Race: Round %d — %s%s  (Week %d)" % [
			GameState.current_season, GameState.current_week,
			soonest_race["round"], soonest_race["name"], champ_tag, soonest_race["week"]]
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
		next_race_label.text = "Season %d  ·  Week %d / 52      ✅ No more races this season" % [
			GameState.current_season, GameState.current_week]
		if advance_to_race_button:
			advance_to_race_button.text = "⏭ Next Race"
			advance_to_race_button.disabled = true
	next_race_label.add_theme_color_override("font_color", Color.WHITE)
	# Resources — shared component handles values + warning colors (S37.37).
	if _resource_bar != null and _resource_bar.has_method("refresh"):
		_resource_bar.refresh()

func _format_number(n: float) -> String:
	if abs(n) >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif abs(n) >= 1000:
		return "%.1fK" % (n / 1000.0)
	else:
		return "%.0f" % n

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
		lbl_header.add_theme_font_size_override("font_size", 22)
		lbl_header.modulate = Color(1.0, 1.0, 1.0) if not n["read"] else Color(0.5, 0.5, 0.5)
		lbl_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(lbl_header)

		if not n["read"]:
			var badge = Label.new()
			badge.text = "NEW"
			badge.add_theme_font_size_override("font_size", 20)
			badge.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
			header_row.add_child(badge)

		# Dismiss button
		var btn_dismiss = Button.new()
		btn_dismiss.text = "✕"
		btn_dismiss.custom_minimum_size = Vector2(24, 22)
		btn_dismiss.add_theme_font_size_override("font_size", 22)
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
		msg.add_theme_font_size_override("font_size", 24)
		msg.text = n["message"]
		vbox.add_child(msg)

		# Action row — only for unread notifications (S37.38: snooze removed; nav button kept)
		if not n["read"]:
			var action_row = HBoxContainer.new()
			action_row.add_theme_constant_override("separation", 4)
			vbox.add_child(action_row)

			## Navigation action button (S20)
			var dest = notifs[idx].get("destination", "")
			if dest != "" and dest in GameState.NOTIFICATION_DESTINATIONS:
				var btn_goto = Button.new()
				btn_goto.text = GameState.NOTIFICATION_DESTINATION_LABELS.get(dest, "Go \u2192")
				btn_goto.custom_minimum_size = Vector2(140, 24)
				btn_goto.add_theme_font_size_override("font_size", 22)
				btn_goto.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
				var capture_dest = dest
				var capture_idx2 = idx
				btn_goto.pressed.connect(func():
					notifs[capture_idx2]["read"] = true
					if capture_dest == "wra_office":
						GameState.pending_hq_tab = "wra"
					get_tree().change_scene_to_file(
						GameState.NOTIFICATION_DESTINATIONS[capture_dest]))
				action_row.add_child(btn_goto)

		notif_box.add_child(card)

func _refresh_todo() -> void:
	## ── TDL (fixed panel, always visible) ────────────────────────────────────
	for child in tdl_box.get_children():
		child.queue_free()

	var todo_header = HBoxContainer.new()
	todo_header.add_theme_constant_override("separation", 8)
	tdl_box.add_child(todo_header)

	var todo_lbl = Label.new()
	todo_lbl.text = "📋 TO-DO"
	todo_lbl.add_theme_font_size_override("font_size", 24)
	todo_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	todo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	todo_header.add_child(todo_lbl)

	var tasks = GameState.get_pending_tasks()
	if tasks.is_empty():
		var lbl_ok = Label.new()
		lbl_ok.text = "✅ All clear"
		lbl_ok.add_theme_font_size_override("font_size", 22)
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
			tl.add_theme_font_size_override("font_size", 22)
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
				btn_go.add_theme_font_size_override("font_size", 20)
				btn_go.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
				var d = dest
				## HQ-bound tasks: most negotiation/bond tasks open the Overview (Pending
				## Activity) panel. S35.11 (issue 2): the R&D→WRA submit task must open the WRA
				## tab, not Overview, so the player lands on the blueprint-submission panel.
				var go_hq: bool = (d == "res://scenes/buildings/HQ.tscn")
				var hq_tab := "overview"
				if go_hq and ("submit to WRA" in task_text or "Blueprint ready" in task_text \
						or "requires racing" in task_text):
					hq_tab = "wra"
				btn_go.pressed.connect(func():
					if go_hq:
						GameState.pending_hq_tab = hq_tab
					get_tree().change_scene_to_file(d))
				task_row.add_child(btn_go)

			var is_negotiation_task = "Offer sent to" in task_text or \
				"Negotiations open:" in task_text or "Contract Round" in task_text or \
				"their reply received" in task_text or "awaiting their reply" in task_text or \
				"team wants CR" in task_text or "Bond approach" in task_text or \
				"bond offer for" in task_text
			## S37.9 — a "Negotiations open: NAME — make your opening offer." row is a player-
			## initiated renegotiation the player hasn't submitted yet. Give it an X to dismiss
			## (cancels the un-submitted approach). Other negotiation tasks (offer sent, bond,
			## in-progress rounds) stay non-dismissible so a live offer can't be dropped by accident.
			var is_dismissible_negotiation = "Negotiations open:" in task_text \
				and "make your opening offer" in task_text
			if not is_negotiation_task or is_dismissible_negotiation:
				var btn_x = Button.new()
				btn_x.text = "✕"
				btn_x.custom_minimum_size = Vector2(22, 22)
				btn_x.add_theme_font_size_override("font_size", 20)
				btn_x.modulate = Color(0.5, 0.5, 0.5)
				var tt = task_text
				if is_dismissible_negotiation:
					## Extract the subject name between "Negotiations open: " and " — make".
					var nm = tt
					var p = nm.find("Negotiations open: ")
					if p != -1:
						nm = nm.substr(p + "Negotiations open: ".length())
					var dash = nm.find(" — make")
					if dash != -1:
						nm = nm.substr(0, dash)
					nm = nm.strip_edges()
					btn_x.tooltip_text = "Dismiss this renegotiation (you haven't made an offer yet)."
					btn_x.pressed.connect(func():
						GameState.cancel_renegotiation_by_subject_name(nm)
						_refresh_log())
				else:
					btn_x.pressed.connect(func():
						GameState.dismiss_todo_item(tt))
				task_row.add_child(btn_x)

func _refresh_log() -> void:
	_refresh_todo()
	_refresh_week_strip()
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
			label.add_theme_font_size_override("font_size", 30)
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

func _refresh_week_strip() -> void:
	if week_strip == null: return
	for c in week_strip.get_children():
		c.queue_free()
	var cal = GameState.get_calendar_manager()
	var reg: Array = GameState.player_registered_championships
	for i in range(WEEK_STRIP_COUNT):
		var wk: int = GameState.current_week + i
		if wk > GameState.max_weeks:
			break
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(0.16, 0.18, 0.24) if i == 0 else Color(0.11, 0.12, 0.15)
		cs.set_corner_radius_all(6)
		cs.set_content_margin_all(6)
		if i == 0:
			cs.set_border_width_all(2); cs.border_color = Color(0.3, 0.6, 0.9)
		cell.add_theme_stylebox_override("panel", cs)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 3)
		cell.add_child(vb)
		var wl := Label.new()
		wl.text = "Wk %d%s" % [wk, "  · now" if i == 0 else ""]
		wl.add_theme_font_size_override("font_size", 18)
		wl.modulate = Color(0.5, 0.75, 1.0) if i == 0 else Color(0.6, 0.6, 0.6)
		vb.add_child(wl)
		# player-related events only: my races + deadlines for my champs + my building/rnd/cnc + custom
		var evs: Array = []
		for ev in cal.get_events_for_week(wk):
			var t: String = ev["type"]
			var keep := false
			if t == "race_mine" or t == "building" or t == "rnd" or t == "cnc" or t == "custom":
				keep = true
			elif t == "deadline" and ev.get("champ_id", "") in reg:
				keep = true
			if keep:
				evs.append(ev)
		if evs.is_empty():
			var none := Label.new()
			none.text = "—"
			none.modulate = Color(0.4, 0.4, 0.4)
			none.add_theme_font_size_override("font_size", 16)
			vb.add_child(none)
		else:
			var shown := 0
			for ev in evs:
				if shown >= STRIP_MAX_CHIPS:
					break
				var cl := Label.new()
				cl.text = ev["title"]
				cl.add_theme_font_size_override("font_size", 15)
				cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				cl.tooltip_text = ev.get("tooltip", "")
				vb.add_child(cl)
				shown += 1
			if evs.size() > STRIP_MAX_CHIPS:
				var more := Label.new()
				more.text = "+%d more" % (evs.size() - STRIP_MAX_CHIPS)
				more.add_theme_font_size_override("font_size", 14)
				more.modulate = Color(0.55, 0.7, 0.95)
				vb.add_child(more)
		week_strip.add_child(cell)

func _on_advance_pressed() -> void:
	var tasks = GameState.get_pending_tasks()
	if tasks.is_empty():
		GameState.advance_week()
		_update_display()
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
				if not inner_news.is_empty():
					_show_modal("📰 News While You Were Away", "", inner_news, "OK", "", func(): pass, null),
			null
		)
		return
	var news = _skip_weeks_collect_news(weeks_to_skip - 1)
	_update_display()
	_refresh_log()
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
	if not news.is_empty():
		_show_modal("📰 Season Summary", "Events during the skip:", news, "OK", "", func(): pass, null)

## Advances N weeks silently, collecting notable events (building completions, race results).
## Returns an Array of strings for the news modal.

func _skip_weeks_collect_news(n: int) -> Array:
	var news: Array = []
	## S35.3: mark that we're fast-forwarding so the CFO auto-buys race logistics during the
	## skip (GameState.advance_week reads this flag). Always cleared in the defer below, even
	## if the loop breaks early (season end / scene change).
	GameState.simulating_to_season_end = true
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
	GameState.simulating_to_season_end = false
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
			_update_display(),
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
	title_lbl.add_theme_font_size_override("font_size", 44)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	vbox.add_child(HSeparator.new())

	# Subtitle
	if subtitle != "":
		var sub_lbl = Label.new()
		sub_lbl.text = subtitle
		sub_lbl.add_theme_font_size_override("font_size", 28)
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
			item_lbl.add_theme_font_size_override("font_size", 26)
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
	cancel_btn.add_theme_font_size_override("font_size", 28)
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
	confirm_btn.add_theme_font_size_override("font_size", 28)
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
	_refresh_notifications()

func _on_week_advanced(_week: int) -> void:
	_update_display()
	_refresh_log()

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
	lbl.add_theme_font_size_override("font_size", 36)
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
		k.add_theme_font_size_override("font_size", 24)
		k.modulate = Color(0.5, 0.5, 0.5)
		r.add_child(k)
		var v = Label.new(); v.text = row[1]
		v.add_theme_font_size_override("font_size", 24)
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
		btn.add_theme_font_size_override("font_size", 30)
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
	lbl_title.add_theme_font_size_override("font_size", 32)
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
		lbl_slot.add_theme_font_size_override("font_size", 26)
		lbl_slot.add_theme_color_override("font_color",
			Color(0.8, 0.88, 1.0) if not meta.is_empty() else Color(0.4, 0.4, 0.4))
		info.add_child(lbl_slot)

		if meta.is_empty():
			var lbl_e = Label.new()
			lbl_e.text = "— empty —"
			lbl_e.add_theme_font_size_override("font_size", 22)
			lbl_e.modulate = Color(0.35, 0.35, 0.35)
			info.add_child(lbl_e)
		else:
			any_found = true
			var lbl_d = Label.new()
			lbl_d.text = "%s  ·  S%d W%d  ·  CR %s" % [
				meta["team"], meta["season"], meta["week"],
				GameState._fmt_int(int(meta["balance"]))]
			lbl_d.add_theme_font_size_override("font_size", 22)
			lbl_d.modulate = Color(0.6, 0.6, 0.6)
			info.add_child(lbl_d)

			var ts = int(meta["modified"])
			var lbl_t = Label.new()
			lbl_t.text = Time.get_datetime_string_from_unix_time(ts).left(16).replace("T", "  ")
			lbl_t.add_theme_font_size_override("font_size", 20)
			lbl_t.modulate = Color(0.38, 0.38, 0.38)
			info.add_child(lbl_t)

			var btn = Button.new()
			btn.text = "Load"
			btn.custom_minimum_size = Vector2(70, 32)
			btn.add_theme_font_size_override("font_size", 26)
			var load_path = path
			btn.pressed.connect(func():
				dim.queue_free()
				menu_popup.queue_free(); menu_popup = null
				GameState.load_game(load_path)
				_update_display()
				_refresh_log()
				_refresh_notifications())
			row.add_child(btn)

		vbox.add_child(sp)

	if not any_found:
		var lbl_none = Label.new()
		lbl_none.text = "No save files found."
		lbl_none.modulate = Color(0.5, 0.5, 0.5)
		lbl_none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_none)

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
	## Bond decision (team named its price) — HQ Pending Activity has the inline Decide popup
	if "team wants CR" in task and "accept, counter or reject" in task:
		return "res://scenes/buildings/HQ.tscn"
	if "💰" in task and "bond" in task.to_lower():
		return "res://scenes/buildings/HQ.tscn"
	if "📤 Bond approach" in task:
		return "res://scenes/buildings/HQ.tscn"
	## R&D → WRA → CNC → Garage pipeline
	if "submit to WRA" in task or "Blueprint ready" in task:
		return "res://scenes/buildings/HQ.tscn"
	## Commitment sponsor requires racing a championship — register via HQ → WRA (S37.40)
	if "requires racing" in task:
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
	lbl_title.add_theme_font_size_override("font_size", 72)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(lbl_title)

	var lbl_sub = Label.new()
	lbl_sub.text = "Your team has been insolvent for 8 consecutive weeks.\nYou must choose how to proceed."
	lbl_sub.add_theme_font_size_override("font_size", 30)
	lbl_sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(lbl_sub)

	var lbl_bal = Label.new()
	lbl_bal.text = "Balance: CR %s" % GameState._fmt_int(int(GameState.player_team.balance))
	lbl_bal.add_theme_font_size_override("font_size", 36)
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
	btn_dismiss.add_theme_font_size_override("font_size", 22)
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
	lt.add_theme_font_size_override("font_size", 28)
	lt.add_theme_color_override("font_color", border_color)
	lt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(lt)

	var ld = Label.new()
	ld.text = desc
	ld.add_theme_font_size_override("font_size", 22)
	ld.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	ld.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ld.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(ld)

	return btn
