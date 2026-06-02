extends Control

# ── Node refs ─────────────────────────────────────────────────────────────────
var _stats_container: VBoxContainer
var _cfo_panel: PanelContainer

# ── Lifecycle ─────────────────────────────────────────────────────────────────
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

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	vbox.add_child(header)

	var lbl_title = Label.new()
	lbl_title.text = "🏛 HEADQUARTERS"
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	var building = GameState.campus_buildings.get("Headquarters", {})
	var lbl_level = Label.new()
	lbl_level.text = "Level %d" % building.get("level", 1)
	lbl_level.add_theme_font_size_override("font_size", 14)
	lbl_level.modulate = Color(0.4, 0.9, 0.5)
	header.add_child(lbl_level)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(100, 36)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)

	vbox.add_child(HSeparator.new())

	# ── Two-column layout ─────────────────────────────────────────────────────
	var columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(columns)

	# Left column — team overview + staff slots
	var left = VBoxContainer.new()
	left.add_theme_constant_override("separation", 14)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)

	# Team overview panel
	left.add_child(_section_label("TEAM OVERVIEW"))
	_stats_container = VBoxContainer.new()
	_stats_container.add_theme_constant_override("separation", 6)
	left.add_child(_stats_container)

	var btn_hof = Button.new()
	btn_hof.text = "🏆 View Hall of Fame"
	btn_hof.custom_minimum_size = Vector2(200, 32)
	btn_hof.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/HallOfFame.tscn"))
	left.add_child(btn_hof)

	left.add_child(HSeparator.new())

	# CEO slot (player — display only)
	left.add_child(_section_label("EXECUTIVE STAFF"))
	left.add_child(_build_ceo_slot())

	left.add_child(_spacer_v(8))

	# TP slots — 1 per HQ level, shown dynamically
	var tp_section_lbl = _section_label("TEAM PRINCIPAL SLOTS  (1 per HQ level)")
	left.add_child(tp_section_lbl)
	var tp_slots_container = VBoxContainer.new()
	tp_slots_container.name = "TPSlotsContainer"
	tp_slots_container.add_theme_constant_override("separation", 6)
	left.add_child(tp_slots_container)

	left.add_child(_spacer_v(8))

	# CFO slot (always 1)
	_cfo_panel = _build_staff_slot("CFO", "💼")
	left.add_child(_cfo_panel)

	# Right column — effects + loan placeholder
	var right = VBoxContainer.new()
	right.add_theme_constant_override("separation", 14)
	right.custom_minimum_size = Vector2(300, 0)
	columns.add_child(right)

	right.add_child(_section_label("BUILDING EFFECTS"))
	right.add_child(_build_effects_panel())

	right.add_child(HSeparator.new())

	right.add_child(_section_label("LOANS"))
	right.add_child(_build_loan_placeholder())

# ── Refresh ───────────────────────────────────────────────────────────────────
func refresh() -> void:
	_refresh_stats()
	_refresh_tp_slots()
	_refresh_staff_slot(_cfo_panel, "CFO", "💼")

func _refresh_tp_slots() -> void:
	var container = get_node_or_null("TPSlotsContainer")
	# Find it in the tree (it's nested inside the columns layout)
	container = _find_node_by_name(self, "TPSlotsContainer")
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

	var max_tp = GameState.get_hq_tp_slots()
	var hired_tp = GameState.get_player_staff_by_role("Team Principal")
	for i in range(max_tp):
		var slot = _build_tp_slot(i, hired_tp)
		container.add_child(slot)

func _build_tp_slot(index: int, hired_tp: Array) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.12, 0.15)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.25, 0.25, 0.30)
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 8; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var lbl_icon = Label.new()
	lbl_icon.text = "🧑‍💼"
	lbl_icon.add_theme_font_size_override("font_size", 18)
	hbox.add_child(lbl_icon)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	if index < hired_tp.size():
		var tp = hired_tp[index]
		var lbl_name = Label.new()
		lbl_name.text = tp.full_name()
		lbl_name.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		vbox.add_child(lbl_name)
		var lbl_stats = Label.new()
		lbl_stats.text = "Strategy %.0f  ·  Pace %.0f  ·  CR %.0f/wk" % [
			tp.race_strategy, tp.race_pace_reading, tp.weekly_salary]
		lbl_stats.modulate = Color(0.6, 0.6, 0.6)
		lbl_stats.add_theme_font_size_override("font_size", 11)
		vbox.add_child(lbl_stats)
		var btn_release = Button.new()
		btn_release.text = "Release"
		btn_release.modulate = Color(1.0, 0.5, 0.5)
		btn_release.add_theme_font_size_override("font_size", 11)
		var tid = tp.id
		btn_release.pressed.connect(func():
			GameState.release_staff(tid)
			refresh()
		)
		hbox.add_child(btn_release)
	else:
		var lbl_empty = Label.new()
		lbl_empty.text = "TP Slot %d — Empty" % (index + 1)
		lbl_empty.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(lbl_empty)
		var btn_hire = Button.new()
		btn_hire.text = "Hire →"
		btn_hire.add_theme_font_size_override("font_size", 11)
		btn_hire.pressed.connect(func():
			GameState.pending_staff_filter = "Team Principal"
			get_tree().change_scene_to_file("res://scenes/Staff.tscn")
		)
		hbox.add_child(btn_hire)

	return panel

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found = _find_node_by_name(child, target_name)
		if found:
			return found
	return null

func _refresh_stats() -> void:
	for child in _stats_container.get_children():
		child.queue_free()

	var team = GameState.player_team
	var champ = GameState.active_championship

	# Season record
	var sorted = champ.get_standings_sorted()
	var player_pos = 0
	var player_pts = 0
	for i in range(sorted.size()):
		if sorted[i]["driver_id"] in team.drivers:
			if player_pos == 0 or sorted[i]["points"] > player_pts:
				player_pos = i + 1
				player_pts = sorted[i]["points"]

	var rows = [
		["Team",          team.team_name,                      Color.WHITE],
		["Balance",       "CR %s" % _fmt(int(team.balance)),
			Color(0.3, 0.9, 0.4) if team.balance >= 0 else Color(1.0, 0.3, 0.3)],
		["Reputation",    "%.0f / 100" % team.reputation,      Color(0.9, 0.8, 0.3)],
		["Season",        "Season %d  ·  Week %d" % [GameState.current_season, GameState.current_week],
			Color(0.7, 0.7, 0.7)],
		["Championship",  "%s  ·  P%d  ·  %d pts" % [
			champ.championship_name, player_pos, player_pts] if player_pos > 0
			else champ.championship_name,
			Color(0.6, 0.85, 1.0)],
		["Sponsor",       GameState.active_sponsor.get("name", "None") +
			("  ($%d/wk)" % GameState.active_sponsor.get("current_weekly", 0)
			if not GameState.active_sponsor.is_empty() else ""),
			Color(0.7, 0.7, 0.7)],
	]

	for row in rows:
		_stats_container.add_child(_stat_row(row[0], row[1], row[2]))

# ── Staff slot builders ───────────────────────────────────────────────────────
func _build_ceo_slot() -> PanelContainer:
	var panel = _card_panel(Color(0.12, 0.14, 0.18))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var icon = Label.new()
	icon.text = "👔"
	icon.add_theme_font_size_override("font_size", 22)
	row.add_child(icon)
	var info = VBoxContainer.new()
	var lbl_role = Label.new()
	lbl_role.text = "CEO  (You)"
	lbl_role.add_theme_font_size_override("font_size", 11)
	lbl_role.modulate = Color(0.55, 0.55, 0.55)
	info.add_child(lbl_role)
	var lbl_name = Label.new()
	lbl_name.text = GameState.player_name
	lbl_name.add_theme_font_size_override("font_size", 15)
	info.add_child(lbl_name)
	row.add_child(info)
	vbox.add_child(row)

	return panel

func _build_staff_slot(role: String, icon_text: String) -> PanelContainer:
	var panel = _card_panel(Color(0.12, 0.14, 0.18))
	panel.set_meta("role", role)
	# Content filled by _refresh_staff_slot
	return panel

func _refresh_staff_slot(panel: PanelContainer, role: String, icon_text: String) -> void:
	# Clear existing content
	for child in panel.get_children():
		child.queue_free()

	var staff_list = GameState.get_player_staff_by_role(role)
	var staff = staff_list[0] if staff_list.size() > 0 else null

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var icon = Label.new()
	icon.text = icon_text
	icon.add_theme_font_size_override("font_size", 22)
	row.add_child(icon)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl_role = Label.new()
	lbl_role.text = role.to_upper()
	lbl_role.add_theme_font_size_override("font_size", 10)
	lbl_role.modulate = Color(0.55, 0.55, 0.55)
	info.add_child(lbl_role)

	if staff:
		var lbl_name = Label.new()
		lbl_name.text = staff.full_name()
		lbl_name.add_theme_font_size_override("font_size", 15)
		info.add_child(lbl_name)

		var lbl_detail = Label.new()
		lbl_detail.text = "%s  ·  $%d/wk  ·  %d seasons left" % [
			staff.nationality, int(staff.weekly_salary), staff.contract_seasons_remaining]
		lbl_detail.add_theme_font_size_override("font_size", 11)
		lbl_detail.modulate = Color(0.6, 0.6, 0.6)
		info.add_child(lbl_detail)
	else:
		var lbl_empty = Label.new()
		lbl_empty.text = "— No %s hired —" % role
		lbl_empty.add_theme_font_size_override("font_size", 14)
		lbl_empty.modulate = Color(0.9, 0.5, 0.15)
		info.add_child(lbl_empty)

	row.add_child(info)

	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	if staff:
		var btn_view = Button.new()
		btn_view.text = "View Card"
		btn_view.pressed.connect(func(): _go_to_staff(role, false))
		btn_row.add_child(btn_view)
		var btn_release = Button.new()
		btn_release.text = "Release"
		btn_release.modulate = Color(1.0, 0.5, 0.5)
		btn_release.pressed.connect(func(): _on_release_staff(staff.id))
		btn_row.add_child(btn_release)
	else:
		var btn_hire = Button.new()
		btn_hire.text = "Hire %s →" % role
		btn_hire.pressed.connect(func(): _go_to_staff(role, true))
		btn_row.add_child(btn_hire)

	vbox.add_child(row)
	vbox.add_child(btn_row)

# ── Effects panel ─────────────────────────────────────────────────────────────
func _build_effects_panel() -> PanelContainer:
	var panel = _card_panel(Color(0.10, 0.12, 0.15))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var building = GameState.campus_buildings.get("Headquarters", {})
	var level = building.get("level", 1)
	var max_level = building.get("max_level", 26)

	var effects = [
		["Marketability Bonus", "+%d%%" % level],
		["Sponsor Slots",       "%d" % (1 + level / 2)],
		["Loan Tier",           "Tier %d" % min(level / 3 + 1, 5)],
		["Max Level",           "%d / %d" % [level, max_level]],
		["Maintenance",         "-$%s/wk" % _fmt(building.get("weekly_maintenance", 0))],
	]

	for e in effects:
		vbox.add_child(_stat_row(e[0], e[1], Color(0.8, 0.8, 0.8)))

	return panel

# ── Loan placeholder ──────────────────────────────────────────────────────────
func _build_loan_placeholder() -> PanelContainer:
	var panel = _card_panel(Color(0.10, 0.12, 0.15))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var lbl = Label.new()
	lbl.text = "Loan management coming in a future update.\nHQ Level determines maximum loan tiers."
	lbl.modulate = Color(0.5, 0.5, 0.5)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl)

	var building = GameState.campus_buildings.get("Headquarters", {})
	var level = building.get("level", 1)
	var loan_tier = min(level / 3 + 1, 5)
	var max_loan = [10000, 50000, 150000, 500000, 2000000][loan_tier - 1]

	var lbl_cap = Label.new()
	lbl_cap.text = "Current loan cap:  $%s  (Tier %d)" % [_fmt(max_loan), loan_tier]
	lbl_cap.add_theme_font_size_override("font_size", 13)
	lbl_cap.modulate = Color(0.7, 0.85, 1.0)
	vbox.add_child(lbl_cap)

	return panel

# ── Actions ───────────────────────────────────────────────────────────────────
func _go_to_staff(role: String, go_to_hire: bool) -> void:
	GameState.pending_staff_filter = role
	if not go_to_hire:
		# View card — go to My Staff tab with filter
		GameState.pending_staff_filter = ""  # let StaffHub open normally, filter by role on my tab
	get_tree().change_scene_to_file("res://scenes/Staff.tscn")

func _on_release_staff(staff_id: String) -> void:
	var dialog = ConfirmationDialog.new()
	var staff = GameState.all_staff.get(staff_id)
	dialog.title = "Release Staff"
	dialog.dialog_text = "Release %s from the team?" % (staff.full_name() if staff else "this staff member")
	dialog.ok_button_text = "Release"
	dialog.cancel_button_text = "Cancel"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func():
		GameState.release_staff(staff_id)
		dialog.queue_free()
		refresh()
	)
	dialog.canceled.connect(dialog.queue_free)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/campus.tscn")

# ── Helpers ───────────────────────────────────────────────────────────────────
func _section_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.modulate = Color(0.5, 0.5, 0.5)
	return lbl

func _stat_row(label: String, value: String, value_color: Color = Color.WHITE) -> HBoxContainer:
	var row = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(140, 0)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = Color(0.6, 0.6, 0.6)
	row.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", value_color)
	row.add_child(val)
	return row

func _card_panel(bg: Color = Color(0.13, 0.13, 0.15)) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.22, 0.22, 0.26)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left   = 14
	style.content_margin_right  = 14
	style.content_margin_top    = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _spacer_v(height: int) -> Control:
	var s = Control.new()
	s.custom_minimum_size = Vector2(0, height)
	return s

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
