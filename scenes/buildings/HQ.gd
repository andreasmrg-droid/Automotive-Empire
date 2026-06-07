extends Control
## Version: S15.1 — refresh() called on _build_ui completion; null guards added

# ── Node refs ─────────────────────────────────────────────────────────────────
var _stats_container: VBoxContainer
var _cfo_panel: PanelContainer

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	GameState.log_updated.connect(func():
		## Only rebuild center column (WRA + Sponsors) to avoid full rebuild on every log
		_refresh_center_column())

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame

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
	# ── Left column: Staff (narrow) ──────────────────────────────────────────
	var left = VBoxContainer.new()
	left.add_theme_constant_override("separation", 14)
	left.custom_minimum_size = Vector2(360, 0)
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	columns.add_child(left)

	# Team overview panel
	left.add_child(_section_label("TEAM OVERVIEW"))
	_stats_container = VBoxContainer.new()
	_stats_container.add_theme_constant_override("separation", 6)
	left.add_child(_stats_container)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	left.add_child(btn_row)

	var btn_hof = Button.new()
	btn_hof.text = "🏆 Hall of Fame"
	btn_hof.custom_minimum_size = Vector2(0, 34)
	btn_hof.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/HallOfFame.tscn"))
	btn_row.add_child(btn_hof)

	var btn_drivers = Button.new()
	btn_drivers.text = "🏎 Drivers"
	btn_drivers.custom_minimum_size = Vector2(0, 34)
	btn_drivers.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/Drivers.tscn"))
	btn_row.add_child(btn_drivers)

	var btn_staff = Button.new()
	btn_staff.text = "👤 Staff"
	btn_staff.custom_minimum_size = Vector2(0, 34)
	btn_staff.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/Staff.tscn"))
	btn_row.add_child(btn_staff)

	var btn_finance = Button.new()
	btn_finance.text = "💰 Financial Dept"
	btn_finance.custom_minimum_size = Vector2(0, 34)
	btn_finance.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/FinancialDept.tscn"))
	btn_row.add_child(btn_finance)

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
	# ── Center column: WRA Office + Sponsors ─────────────────────────────────
	var center_scroll = ScrollContainer.new()
	center_scroll.name = "CenterScroll"
	center_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(center_scroll)

	var center = VBoxContainer.new()
	center.add_theme_constant_override("separation", 14)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_scroll.add_child(center)

	center.add_child(_section_label("WRA OFFICE"))
	center.add_child(_build_wra_office())

	center.add_child(HSeparator.new())

	center.add_child(_section_label("SPONSORS"))
	center.add_child(_build_sponsors_section())

	# ── Right column: Building Effects + Loans (narrow) ──────────────────────
	var right = VBoxContainer.new()
	right.add_theme_constant_override("separation", 14)
	right.custom_minimum_size = Vector2(280, 0)
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	columns.add_child(right)

	right.add_child(_section_label("BUILDING EFFECTS"))
	right.add_child(_build_effects_panel())

	right.add_child(HSeparator.new())

	right.add_child(_section_label("LOANS"))
	right.add_child(_build_loan_placeholder())

	## Populate dynamic slots now that the tree is built
	refresh()

# ── Refresh ───────────────────────────────────────────────────────────────────
func refresh() -> void:
	if _stats_container == null or not is_instance_valid(_stats_container): return
	_refresh_stats()
	_refresh_tp_slots()
	if _cfo_panel == null or not is_instance_valid(_cfo_panel): return
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
	vbox.add_theme_constant_override("separation", 4)
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

		# Championship assignment dropdown
		var champ_row = HBoxContainer.new()
		champ_row.add_theme_constant_override("separation", 6)
		vbox.add_child(champ_row)
		var lbl_c = Label.new()
		lbl_c.text = "Championship:"
		lbl_c.add_theme_font_size_override("font_size", 11)
		lbl_c.modulate = Color(0.55, 0.55, 0.55)
		champ_row.add_child(lbl_c)

		var assigned = tp.assigned_championship
		# Show current assignment or unassigned
		if assigned != "" and assigned in GameState.CHAMPIONSHIP_REGISTRY:
			var reg = GameState.CHAMPIONSHIP_REGISTRY[assigned]
			var lbl_assigned = Label.new()
			lbl_assigned.text = reg.get("name", assigned)
			lbl_assigned.add_theme_font_size_override("font_size", 11)
			lbl_assigned.add_theme_color_override("font_color", Color(0.4, 0.85, 0.4))
			champ_row.add_child(lbl_assigned)
		else:
			var lbl_none = Label.new()
			lbl_none.text = "⚠ None assigned"
			lbl_none.add_theme_font_size_override("font_size", 11)
			lbl_none.modulate = Color(1.0, 0.6, 0.2)
			champ_row.add_child(lbl_none)

		# Assign buttons for each active championship
		var assign_row = HBoxContainer.new()
		assign_row.add_theme_constant_override("separation", 4)
		vbox.add_child(assign_row)
		for champ in GameState.active_championships:
			var reg = GameState.CHAMPIONSHIP_REGISTRY.get(champ.id, {})
			var btn_assign = Button.new()
			btn_assign.text = reg.get("name", champ.id).left(14)
			btn_assign.add_theme_font_size_override("font_size", 10)
			btn_assign.custom_minimum_size = Vector2(0, 24)
			if tp.assigned_championship == champ.id:
				btn_assign.modulate = Color(0.4, 0.85, 0.4)
				btn_assign.disabled = true
			var tid = tp.id; var cid = champ.id
			btn_assign.pressed.connect(func():
				var t = GameState.all_staff.get(tid)
				if t: t.assigned_championship = cid
				refresh()
			)
			assign_row.add_child(btn_assign)

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
		["Sponsor",
			"%s  (+CR %s/wk)" % [GameState.active_sponsors[0].name,
				_fmt(GameState.active_sponsors[0].weekly_payment)]
			if not GameState.active_sponsors.is_empty() else "None",
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

## ═══════════════════════════════════════════════════════════════════════════
## WRA OFFICE (S14)
## ═══════════════════════════════════════════════════════════════════════════

func _refresh_center_column() -> void:
	var center_scroll = _find_node_by_name(self, "CenterScroll")
	if center_scroll == null or not is_instance_valid(center_scroll): return
	if center_scroll.get_child_count() == 0: return
	var center = center_scroll.get_child(0)
	if center == null or not is_instance_valid(center): return
	for child in center.get_children():
		if is_instance_valid(child): child.queue_free()
	await get_tree().process_frame
	if not is_instance_valid(center): return
	center.add_child(_section_label("WRA OFFICE"))
	center.add_child(_build_wra_office())
	center.add_child(HSeparator.new())
	center.add_child(_section_label("SPONSORS"))
	center.add_child(_build_sponsors_section())

func _build_wra_office() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_build_wra_cycle_countdowns(vbox)
	vbox.add_child(HSeparator.new())
	_build_wra_submit_panel(vbox)
	vbox.add_child(HSeparator.new())
	_build_wra_pending_panel(vbox)
	vbox.add_child(HSeparator.new())
	_build_wra_approved_panel(vbox)
	vbox.add_child(HSeparator.new())
	_build_supply_contracts_panel(vbox)
	vbox.add_child(HSeparator.new())
	# Championship registration shortcut
	var btn_champ = Button.new()
	btn_champ.text = "🏁 Championship Registration →"
	btn_champ.custom_minimum_size = Vector2(0, 32)
	btn_champ.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ChampionshipSelect.tscn"))
	vbox.add_child(btn_champ)
	return vbox

func _build_wra_cycle_countdowns(parent: VBoxContainer) -> void:
	var lbl = Label.new()
	lbl.text = "Regulation Cycle Status"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	parent.add_child(lbl)
	const WRA_GROUPS = {
		"Formula":4,"Touring":5,"Karting":6,
		"Open Wheel":7,"Stock Car":8,"Rally":9,"Endurance":10,
	}
	for group in WRA_GROUPS:
		var length = WRA_GROUPS[group]
		var start = GameState.wra_cycle_starts.get(group, 1)
		var seasons_in = GameState.current_season - start
		var seasons_until = length - (seasons_in % length)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		parent.add_child(row)
		var lg = Label.new()
		lg.text = group
		lg.custom_minimum_size = Vector2(110, 0)
		lg.add_theme_font_size_override("font_size", 11)
		row.add_child(lg)
		var ls = Label.new()
		ls.add_theme_font_size_override("font_size", 11)
		if seasons_until == 1:
			ls.text = "⚠ Resets NEXT SEASON"
			ls.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
		elif seasons_until == 2:
			ls.text = "⚠ Resets in 2 seasons"
			ls.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		else:
			ls.text = "Resets in %d seasons" % seasons_until
			ls.modulate = Color(0.5, 0.5, 0.5)
		row.add_child(ls)

func _build_wra_submit_panel(parent: VBoxContainer) -> void:
	var lbl = Label.new()
	lbl.text = "Blueprints Ready to Submit"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	parent.add_child(lbl)
	var submittable: Array = []
	for bp_id in GameState.known_blueprints:
		if not GameState.is_blueprint_submitted(bp_id) and \
		   not GameState.is_blueprint_approved(bp_id):
			submittable.append(bp_id)
	if submittable.is_empty():
		var e = Label.new()
		e.text = "No blueprints available for submission."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 11)
		parent.add_child(e)
		return
	for bp_id in submittable:
		var bp = GameState.known_blueprints[bp_id]
		var cid = bp.get("championship_id", "")
		var tier = GameState._get_championship_tier(cid)
		var fee = GameState.WRA_SUBMISSION_FEE.get(tier, 500)
		var weeks = GameState.WRA_APPROVAL_WEEKS.get(tier, 2)
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		parent.add_child(row)
		var ln = Label.new()
		ln.text = "%s [%s]" % [bp.get("name", bp_id), reg.get("name", cid)]
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ln.add_theme_font_size_override("font_size", 11)
		row.add_child(ln)
		var li = Label.new()
		li.text = "CR %s | %dwks" % [_fmt(fee), weeks]
		li.add_theme_font_size_override("font_size", 10)
		li.modulate = Color(0.55, 0.55, 0.55)
		row.add_child(li)
		var btn = Button.new()
		btn.text = "Submit"
		btn.custom_minimum_size = Vector2(70, 24)
		btn.pressed.connect(func():
			if GameState.submit_to_wra(bp_id): _build_ui())
		row.add_child(btn)

func _build_wra_pending_panel(parent: VBoxContainer) -> void:
	var lbl = Label.new()
	lbl.text = "Pending Decision (%d)" % GameState.active_wra_submissions.size()
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	parent.add_child(lbl)
	if GameState.active_wra_submissions.is_empty():
		var e = Label.new()
		e.text = "No pending submissions."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 11)
		parent.add_child(e)
		return
	for sub in GameState.active_wra_submissions:
		var bp = GameState.known_blueprints.get(sub.blueprint_id, {})
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(sub.championship_id, {})
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		parent.add_child(row)
		var ln = Label.new()
		ln.text = "%s [%s]" % [bp.get("name", sub.blueprint_id), reg.get("name", sub.championship_id)]
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ln.add_theme_font_size_override("font_size", 11)
		row.add_child(ln)
		var lw = Label.new()
		lw.text = "⏳ %d wk%s" % [sub.weeks_remaining, "s" if sub.weeks_remaining != 1 else ""]
		lw.add_theme_font_size_override("font_size", 11)
		lw.add_theme_color_override("font_color",
			Color(1.0, 0.6, 0.1) if sub.weeks_remaining <= 1 else Color(0.55, 0.55, 0.55))
		row.add_child(lw)

func _build_wra_approved_panel(parent: VBoxContainer) -> void:
	var lbl = Label.new()
	lbl.text = "Approved (%d)" % GameState.wra_approved_blueprints.size()
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	parent.add_child(lbl)
	if GameState.wra_approved_blueprints.is_empty():
		var e = Label.new()
		e.text = "No approved blueprints yet."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 11)
		parent.add_child(e)
		return
	for app in GameState.wra_approved_blueprints:
		var bp = GameState.known_blueprints.get(app.blueprint_id, {})
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(app.championship_id, {})
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		parent.add_child(row)
		var lc = Label.new()
		lc.text = "✅"
		lc.custom_minimum_size = Vector2(20, 0)
		row.add_child(lc)
		var ln = Label.new()
		ln.text = "%s [%s]" % [bp.get("name", app.blueprint_id), reg.get("name", app.championship_id)]
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ln.add_theme_font_size_override("font_size", 11)
		ln.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		row.add_child(ln)
		var btn = Button.new()
		btn.text = "Manufacture →"
		btn.custom_minimum_size = Vector2(105, 24)
		btn.pressed.connect(func():
			GameState.pending_cnc_blueprint = app.blueprint_id
			get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn"))
		row.add_child(btn)

func _build_supply_contracts_panel(parent: VBoxContainer) -> void:
	var lbl = Label.new()
	lbl.text = "Supply Contracts (%d)" % GameState.active_supply_contracts.size()
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.modulate = Color(0.7, 0.7, 0.7)
	parent.add_child(lbl)
	if GameState.active_supply_contracts.is_empty():
		var e = Label.new()
		e.text = "No active supply contracts."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 11)
		parent.add_child(e)
		return
	for sc in GameState.active_supply_contracts:
		if not sc.active: continue
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(sc.championship_id, {})
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		parent.add_child(row)
		var ln = Label.new()
		ln.text = "%s — %s [%s] CR %s/pt %d seasons" % [
			sc.ai_team_name, sc.part_code,
			reg.get("name", sc.championship_id),
			_fmt(sc.cr_per_part), sc.seasons_remaining]
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ln.add_theme_font_size_override("font_size", 11)
		row.add_child(ln)
		var prog = Label.new()
		prog.text = "%d/%d" % [sc.parts_delivered, sc.parts_per_season]
		prog.add_theme_font_size_override("font_size", 11)
		var pct = float(sc.parts_delivered) / float(sc.parts_per_season)
		prog.add_theme_color_override("font_color",
			Color(0.4,0.9,0.4) if pct >= 0.8 else
			Color(1.0,0.6,0.1) if pct >= 0.4 else Color(1.0,0.3,0.3))
		row.add_child(prog)

## ═══════════════════════════════════════════════════════════════════════════
## SPONSORS SECTION (S18)
## ═══════════════════════════════════════════════════════════════════════════

func _build_sponsors_section() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	if not GameState.active_sponsors.is_empty():
		var la = Label.new()
		la.text = "Active (%d)" % GameState.active_sponsors.size()
		la.add_theme_font_size_override("font_size", 12)
		la.modulate = Color(0.7,0.7,0.7)
		vbox.add_child(la)
		for sp in GameState.active_sponsors:
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			vbox.add_child(row)
			var ln = Label.new()
			ln.text = sp.name
			ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ln.add_theme_font_size_override("font_size", 12)
			ln.add_theme_color_override("font_color", Color(0.4,0.9,0.4))
			row.add_child(ln)
			var li = Label.new()
			li.add_theme_font_size_override("font_size", 10)
			li.modulate = Color(0.55,0.55,0.55)
			match sp.type:
				1: li.text = "CR %s/wk | %d seasons" % [_fmt(sp.weekly_payment), sp.seasons_remaining]
				2: li.text = "Win:CR %s | %d seasons" % [_fmt(sp.win_bonus), sp.seasons_remaining]
				3: li.text = "Commitment | %d seasons" % sp.seasons_remaining
			row.add_child(li)
		vbox.add_child(HSeparator.new())

	var lo = Label.new()
	lo.text = "Offers (%d)" % GameState.sponsor_offers.size()
	lo.add_theme_font_size_override("font_size", 12)
	lo.modulate = Color(0.7,0.7,0.7)
	vbox.add_child(lo)

	if GameState.sponsor_offers.is_empty():
		var e = Label.new()
		e.text = "No offers. Search below."
		e.modulate = Color(0.45,0.45,0.45)
		e.add_theme_font_size_override("font_size", 11)
		vbox.add_child(e)
	else:
		for offer in GameState.sponsor_offers:
			var card = _build_sponsor_offer_card(offer)
			vbox.add_child(card)

	if GameState.cfo_search_active:
		var search_row = HBoxContainer.new()
		search_row.add_theme_constant_override("separation", 8)
		vbox.add_child(search_row)
		var ls = Label.new()
		ls.text = "🔍 CFO searching... next offer in %d wk%s" % [
			GameState.cfo_search_weeks_remaining,
			"s" if GameState.cfo_search_weeks_remaining != 1 else ""]
		ls.add_theme_font_size_override("font_size", 11)
		ls.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		ls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		search_row.add_child(ls)
		var btn_stop = Button.new()
		btn_stop.text = "⏹ Stop Search"
		btn_stop.custom_minimum_size = Vector2(110, 28)
		btn_stop.modulate = Color(1.0, 0.5, 0.5)
		btn_stop.pressed.connect(func():
			GameState.stop_cfo_sponsor_search()
			_build_ui())
		search_row.add_child(btn_stop)
	else:
		## Check if CFO is hired
		var has_cfo = false
		for sid in GameState.all_staff:
			var s = GameState.all_staff[sid]
			if s.role == "CFO" and s.contract_team == GameState.player_team.id:
				has_cfo = true
				break
		var btn = Button.new()
		btn.text = "🔍 CFO: Search for Sponsors"
		btn.custom_minimum_size = Vector2(0, 30)
		if not has_cfo:
			btn.modulate = Color(0.5, 0.5, 0.5)
			btn.tooltip_text = "Hire a CFO first to search for sponsors"
		btn.pressed.connect(func():
			if not GameState.start_cfo_sponsor_search():
				pass  ## GameState shows notification
			else:
				_build_ui())
		vbox.add_child(btn)

	return vbox

func _build_sponsor_offer_card(offer: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.13)
	style.border_width_left = 2
	var colors = [Color(0.3,0.3,0.3), Color(0.3,0.7,0.9), Color(0.9,0.6,0.2), Color(0.6,0.3,0.9)]
	style.border_color = colors[offer.type] if offer.type < colors.size() else colors[0]
	style.corner_radius_top_left = 3; style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3; style.corner_radius_bottom_right = 3
	style.content_margin_left = 8; style.content_margin_right = 8
	style.content_margin_top = 6; style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 6)
	vb.add_child(hdr)
	var ln = Label.new()
	ln.text = offer.name
	ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ln.add_theme_font_size_override("font_size", 12)
	hdr.add_child(ln)
	var lt = Label.new()
	lt.text = "T%d" % offer.tier
	lt.add_theme_font_size_override("font_size", 10)
	lt.modulate = Color(0.5,0.5,0.5)
	hdr.add_child(lt)
	var ld = Label.new()
	ld.add_theme_font_size_override("font_size", 10)
	match offer.type:
		1: ld.text = "CR %s/wk | %d seasons" % [_fmt(offer.weekly_payment), offer.seasons_remaining]
		2: ld.text = "Win:CR %s  Podium:CR %s  Season:CR %s | %d seasons" % [
			_fmt(offer.win_bonus), _fmt(offer.podium_bonus),
			_fmt(offer.season_bonus), offer.seasons_remaining]
		3:
			var reg = GameState.CHAMPIONSHIP_REGISTRY.get(offer.championship_id, {})
			ld.text = "Commitment [%s]: CR %s | %d seasons" % [
				reg.get("name", offer.championship_id),
				_fmt(offer.commitment_total), offer.seasons_remaining]
	ld.modulate = Color(0.65,0.65,0.65)
	vb.add_child(ld)
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vb.add_child(btn_row)
	var btn = Button.new()
	btn.text = "Sign Sponsor"
	btn.custom_minimum_size = Vector2(100, 26)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func():
		GameState.sign_sponsor(offer.sponsor_id)
		_build_ui())
	btn_row.add_child(btn)
	var btn_dismiss = Button.new()
	btn_dismiss.text = "✕ Dismiss"
	btn_dismiss.custom_minimum_size = Vector2(80, 26)
	btn_dismiss.modulate = Color(0.6, 0.6, 0.6)
	btn_dismiss.pressed.connect(func():
		GameState.dismiss_sponsor_offer(offer.sponsor_id)
		_build_ui())
	btn_row.add_child(btn_dismiss)
	return panel
