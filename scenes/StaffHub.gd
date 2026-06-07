extends Control
## Version: S15.2 — Strategist/TP assign shows championship picker (not auto-assign);
##                    TP buttons disable when championship already has a TP;
##                    assignment display uses championship registry lookup not active_championship.

# ── State ─────────────────────────────────────────────────────────────────────
var current_tab: String = "my_staff"
var sort_field: String = "skill"
var sort_ascending: bool = false
var role_filter: String = "All"

const ROLE_ICONS = {
	"Race Mechanic":   "🔧",
	"Pit Crew":        "⏱",
	"Team Principal":  "🧑‍💼",
	"CFO":             "💼",
	"Designer":        "🔬",
	"Race Strategist": "📡",
}

const ROLE_SHORT = {
	"Race Mechanic":   "Mechanic",
	"Pit Crew":        "Pit Crew",
	"Team Principal":  "Principal",
	"CFO":             "CFO",
	"Designer":        "Designer",
	"Race Strategist": "Strategist",
}

# ── Node refs ─────────────────────────────────────────────────────────────────
var tab_my_btn: Button
var tab_all_btn: Button
var list_container: VBoxContainer
var filter_btns: Dictionary = {}
var card_overlay: PanelContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	# Apply pre-filter if set by another scene (e.g. Garage sets "Race Mechanic")
	if GameState.pending_staff_filter != "":
		role_filter = GameState.pending_staff_filter
		GameState.pending_staff_filter = ""
		_show_tab("available_staff")

func _build_ui() -> void:
	var layout = VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 20
	layout.offset_top = 20
	layout.offset_right = -20
	layout.offset_bottom = -20
	layout.add_theme_constant_override("separation", 10)
	add_child(layout)

	# Header
	var header = HBoxContainer.new()
	layout.add_child(header)
	var title = Label.new()
	title.text = "🧑‍🔧 STAFF"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back_btn = Button.new()
	back_btn.text = "← Back to Hub"
	back_btn.custom_minimum_size = Vector2(150, 40)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	layout.add_child(HSeparator.new())

	# Tabs
	var tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	layout.add_child(tab_row)

	tab_my_btn = Button.new()
	tab_my_btn.text = "👥 My Staff (%d)" % GameState.get_all_player_staff().size()
	tab_my_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_my_btn.pressed.connect(func(): _show_tab("my_staff"))
	tab_row.add_child(tab_my_btn)

	tab_all_btn = Button.new()
	tab_all_btn.text = "🌍 Available Staff (%d)" % GameState.get_all_available_staff().size()
	tab_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_all_btn.pressed.connect(func(): _show_tab("available_staff"))
	tab_row.add_child(tab_all_btn)

	# Role filter bar
	var filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 4)
	layout.add_child(filter_row)
	var filter_lbl = Label.new()
	filter_lbl.text = "Role:"
	filter_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	filter_row.add_child(filter_lbl)

	for role in ["All", "Race Mechanic", "Pit Crew", "Team Principal",
			"CFO", "Designer", "Race Strategist"]:
		var btn = Button.new()
		btn.text = role if role == "All" else ROLE_ICONS.get(role, "") + " " + ROLE_SHORT.get(role, role)
		btn.custom_minimum_size = Vector2(0, 28)
		var _r = role
		btn.pressed.connect(func():
			role_filter = _r
			_refresh_list()
		)
		filter_row.add_child(btn)
		filter_btns[role] = btn

	# Sort bar
	var sort_row = HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 6)
	layout.add_child(sort_row)
	var sort_lbl = Label.new()
	sort_lbl.text = "Sort:"
	sort_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	sort_row.add_child(sort_lbl)
	for field in [["Skill", "skill"], ["Age", "age"], ["Salary", "salary"]]:
		var btn = Button.new()
		btn.text = field[0]
		btn.custom_minimum_size = Vector2(65, 28)
		var f = field[1]
		btn.pressed.connect(func():
			if sort_field == f:
				sort_ascending = !sort_ascending
			else:
				sort_field = f
				sort_ascending = false
			_refresh_list()
		)
		sort_row.add_child(btn)

	# Scroll + list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 5)
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_container)

	_show_tab("my_staff")

# ── Tab switching ─────────────────────────────────────────────────────────────

func _show_tab(tab: String) -> void:
	current_tab = tab
	tab_my_btn.flat = (tab != "my_staff")
	tab_all_btn.flat = (tab != "available_staff")
	_refresh_list()

func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	if current_tab == "my_staff":
		_build_my_staff_list()
	else:
		_build_available_staff_list()

# ── My Staff ──────────────────────────────────────────────────────────────────

func _build_my_staff_list() -> void:
	var all_my = GameState.get_all_player_staff()
	var filtered = _filter_and_sort(all_my)

	if filtered.is_empty():
		var lbl = Label.new()
		lbl.text = "No staff hired yet. Browse available staff to hire."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list_container.add_child(lbl)
		return

	# Group by role for My Staff view
	var by_role: Dictionary = {}
	for staff in filtered:
		if not staff.role in by_role:
			by_role[staff.role] = []
		by_role[staff.role].append(staff)

	for role in GameState.STAFF_ROLES:
		if not role in by_role:
			continue
		# Role header
		var role_hdr = Label.new()
		role_hdr.text = "%s %s" % [ROLE_ICONS.get(role, ""), role.to_upper()]
		role_hdr.add_theme_font_size_override("font_size", 13)
		role_hdr.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		list_container.add_child(role_hdr)

		for staff in by_role[role]:
			list_container.add_child(_make_my_staff_row(staff))

func _make_my_staff_row(staff) -> PanelContainer:
	var card = _make_card_panel(true)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Row 1 — identity
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)
	_add_col(row1, staff.display_name(), 170, Color(0.9, 0.9, 0.9), 14)
	_add_col(row1, "Age %d" % staff.age, 55)
	_add_col(row1, staff.nationality, 100)
	_add_col(row1, "%s %.0f" % [staff.get_primary_skill_label(), staff.get_primary_skill()], 100,
		_skill_color(staff.get_primary_skill()))

	# Assignment status
	var assign_text = ""
	if staff.role == "CFO" or staff.role == "Designer":
		assign_text = "Team Level"
	elif staff.assigned_car_id != "":
		var car = GameState.get_car_by_id(staff.assigned_car_id)
		assign_text = _car_display_name(car) if car else "Car ?"
	elif staff.assigned_championship != "":
		var _reg = GameState.CHAMPIONSHIP_REGISTRY.get(staff.assigned_championship, {})
		assign_text = _reg.get("name", staff.assigned_championship)
	else:
		assign_text = "⚠ Unassigned"
	var assign_color = Color(0.6, 0.6, 0.6) if assign_text == "Team Level" \
		else (Color(0.4, 0.9, 0.4) if assign_text != "⚠ Unassigned" \
		else Color(1.0, 0.6, 0.2))
	_add_col(row1, assign_text, 130, assign_color)

	# Previous season championship indicator
	var prev_champ_id = GameState.previous_season_championship.get(staff.id, "")
	if prev_champ_id != "":
		var prev_reg = GameState.CHAMPIONSHIP_REGISTRY.get(prev_champ_id, {})
		_add_col(row1, "↩ %s" % prev_reg.get("name", prev_champ_id).left(18), 140, Color(0.5, 0.75, 0.5))

	# Contract
	var contract_color = Color(1.0, 0.4, 0.4) if staff.contract_seasons_remaining <= 1 \
		else Color(0.7, 0.7, 0.7)
	_add_col(row1, "%d season%s" % [staff.contract_seasons_remaining, "s" if staff.contract_seasons_remaining != 1 else ""], 100, contract_color)
	_add_col(row1, "CR %s/yr" % _fmt_sal(int(staff.weekly_salary * 52)), 90, Color(0.6, 0.9, 0.6))

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	var s_id = staff.id

	var view_btn = Button.new()
	view_btn.text = "📋 View Card"
	view_btn.custom_minimum_size = Vector2(100, 28)
	view_btn.pressed.connect(func(): _show_staff_card(s_id))
	btn_row.add_child(view_btn)

	# Assign button — not shown for CFO (team-level role, no assignment needed)
	if staff.role != "CFO":
		var assign_btn = Button.new()
		assign_btn.text = "📌 Assign"
		assign_btn.custom_minimum_size = Vector2(85, 28)
		assign_btn.pressed.connect(func(): _show_assign_popup(s_id))
		btn_row.add_child(assign_btn)

	var renew_btn = Button.new()
	renew_btn.text = "📋 Renew (5 seasons)"
	renew_btn.custom_minimum_size = Vector2(145, 28)
	renew_btn.pressed.connect(func():
		GameState.renew_staff_contract(s_id, 5)
		_refresh_list()
	)
	btn_row.add_child(renew_btn)

	var release_btn = Button.new()
	release_btn.text = "👋 Release"
	release_btn.custom_minimum_size = Vector2(85, 28)
	release_btn.pressed.connect(func(): _confirm_release_staff(s_id))
	btn_row.add_child(release_btn)

	return card

# ── Available Staff ───────────────────────────────────────────────────────────

func _build_available_staff_list() -> void:
	var available = GameState.get_all_available_staff()
	var filtered = _filter_and_sort(available)

	if filtered.is_empty():
		var lbl = Label.new()
		lbl.text = "No available staff match the current filter."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list_container.add_child(lbl)
		return

	for staff in filtered:
		list_container.add_child(_make_available_staff_row(staff))

func _make_available_staff_row(staff) -> PanelContainer:
	var card = _make_card_panel(false)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)
	_add_col(row1, staff.display_name(), 170, Color(0.85, 0.85, 0.85), 14)
	_add_col(row1, "Age %d" % staff.age, 55)
	_add_col(row1, staff.nationality, 100)
	_add_col(row1, "%s %s" % [ROLE_ICONS.get(staff.role, ""), staff.role], 155,
		Color(0.7, 0.85, 1.0))
	_add_col(row1, "%s %.0f" % [staff.get_primary_skill_label(), staff.get_primary_skill()], 100,
		_skill_color(staff.get_primary_skill()))
	_add_col(row1, "CR %s/yr" % _fmt_sal(int(staff.weekly_salary * 52)), 90, Color(0.6, 0.6, 0.6))

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	var s_id = staff.id

	var view_btn = Button.new()
	view_btn.text = "📋 View Card"
	view_btn.custom_minimum_size = Vector2(100, 28)
	view_btn.pressed.connect(func(): _show_staff_card(s_id))
	btn_row.add_child(view_btn)

	var hire_btn = Button.new()
	hire_btn.custom_minimum_size = Vector2(80, 28)

	# Check slot availability for limited roles
	var slot_msg = _get_slot_message(staff.role)
	if slot_msg != "":
		hire_btn.text = "⚠ No Slot"
		hire_btn.disabled = true
		hire_btn.tooltip_text = slot_msg
	else:
		hire_btn.text = "✅ Hire"
		hire_btn.pressed.connect(func():
			if GameState.hire_staff(s_id):
				tab_my_btn.text = "👥 My Staff (%d)" % GameState.get_all_player_staff().size()
				tab_all_btn.text = "🌍 Available Staff (%d)" % GameState.get_all_available_staff().size()
				_refresh_list()
		)
	btn_row.add_child(hire_btn)

	return card

# ── Staff Card popup ──────────────────────────────────────────────────────────

func _show_staff_card(staff_id: String) -> void:
	if card_overlay:
		card_overlay.queue_free()

	var staff = GameState.all_staff.get(staff_id)
	if not staff:
		return

	card_overlay = PanelContainer.new()
	card_overlay.anchor_left   = 1.0
	card_overlay.anchor_top    = 0.0
	card_overlay.anchor_right  = 1.0
	card_overlay.anchor_bottom = 0.0
	card_overlay.offset_left   = -600
	card_overlay.offset_top    = 190
	card_overlay.offset_right  = -50
	card_overlay.offset_bottom = 60
	card_overlay.custom_minimum_size = Vector2(500, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 0.98)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.7, 0.85, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	card_overlay.add_theme_stylebox_override("panel", style)
	add_child(card_overlay)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card_overlay.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	var name_lbl = Label.new()
	name_lbl.text = "%s %s" % [ROLE_ICONS.get(staff.role, ""), _staff_display_name(staff)]
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_lbl)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(func(): card_overlay.queue_free(); card_overlay = null)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	_card_row(vbox, "Role", staff.role, Color(0.7, 0.85, 1.0))
	_card_row(vbox, "Age / Sex / Nationality",
		"%d  |  %s  |  %s" % [staff.age, staff.sex, staff.nationality])
	_card_row(vbox, "Reputation", "%.0f / 100" % staff.reputation,
		_skill_color(staff.reputation))
	_card_row(vbox, "Salary", "CR %s/yr  (CR %.0f/wk)" % [_fmt_sal(int(staff.weekly_salary * 52)), staff.weekly_salary])
	_card_row(vbox, "Contract",
		"%d season%s remaining" % [staff.contract_seasons_remaining, "s" if staff.contract_seasons_remaining != 1 else ""],
		Color(1.0, 0.4, 0.4) if staff.contract_seasons_remaining <= 1 else Color.WHITE)

	var assign_text = "Unassigned"
	if staff.role == "CFO" or staff.role == "Designer":
		assign_text = "Team Level (no assignment needed)"
	elif staff.assigned_car_id != "":
		var car = GameState.get_car_by_id(staff.assigned_car_id)
		assign_text = _car_display_name(car) if car else "Car ?"
	elif staff.assigned_championship != "":
		var _reg = GameState.CHAMPIONSHIP_REGISTRY.get(staff.assigned_championship, {})
		assign_text = _reg.get("name", staff.assigned_championship)
	_card_row(vbox, "Assignment", assign_text)

	vbox.add_child(HSeparator.new())

	# Role-specific attributes
	var attrs_title = Label.new()
	attrs_title.text = "ATTRIBUTES"
	attrs_title.add_theme_font_size_override("font_size", 15)
	attrs_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(attrs_title)

	var attrs = _get_staff_attrs(staff)
	for attr in attrs:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		var lbl = Label.new()
		lbl.text = attr[0]
		lbl.custom_minimum_size = Vector2(200, 0)
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		row.add_child(lbl)
		var bar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = attr[1]
		bar.custom_minimum_size = Vector2(160, 18)
		bar.show_percentage = false
		row.add_child(bar)
		var val_lbl = Label.new()
		val_lbl.text = "%.1f" % attr[1]
		val_lbl.add_theme_font_size_override("font_size", 15)
		val_lbl.add_theme_color_override("font_color", _skill_color(attr[1]))
		row.add_child(val_lbl)

	vbox.add_child(HSeparator.new())

	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var is_mine = staff.contract_team == GameState.player_team.id
	if is_mine:
		var assign_btn = Button.new()
		assign_btn.text = "📌 Assign"
		assign_btn.custom_minimum_size = Vector2(100, 32)
		assign_btn.pressed.connect(func():
			card_overlay.queue_free()
			card_overlay = null
			_show_assign_popup(staff_id)
		)
		btn_row.add_child(assign_btn)

		var renew_btn = Button.new()
		renew_btn.text = "📋 Renew Contract"
		renew_btn.custom_minimum_size = Vector2(140, 32)
		renew_btn.pressed.connect(func():
			GameState.renew_staff_contract(staff_id, 5)
			card_overlay.queue_free()
			card_overlay = null
			_refresh_list()
		)
		btn_row.add_child(renew_btn)
	elif staff.contract_team == "":
		var slot_msg = _get_slot_message(staff.role)
		var hire_btn = Button.new()
		hire_btn.custom_minimum_size = Vector2(100, 32)
		if slot_msg != "":
			hire_btn.text = "⚠ No Slot"
			hire_btn.disabled = true
			hire_btn.tooltip_text = slot_msg
		else:
			hire_btn.text = "✅ Hire"
			hire_btn.pressed.connect(func():
				if GameState.hire_staff(staff_id):
					card_overlay.queue_free()
					card_overlay = null
					tab_my_btn.text = "👥 My Staff (%d)" % GameState.get_all_player_staff().size()
					tab_all_btn.text = "🌍 Available Staff (%d)" % GameState.get_all_available_staff().size()
					_refresh_list()
			)
		btn_row.add_child(hire_btn)

# ── Assign popup ──────────────────────────────────────────────────────────────

func _show_assign_popup(staff_id: String) -> void:
	if card_overlay:
		card_overlay.queue_free()

	var staff = GameState.all_staff.get(staff_id)
	if not staff:
		return

	card_overlay = PanelContainer.new()
	card_overlay.anchor_left   = 1.0
	card_overlay.anchor_top    = 0.0
	card_overlay.anchor_right  = 1.0
	card_overlay.anchor_bottom = 0.0
	card_overlay.offset_left   = -600
	card_overlay.offset_top    = 190
	card_overlay.offset_right  = -50
	card_overlay.offset_bottom = 60
	card_overlay.custom_minimum_size = Vector2(380, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 0.98)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.9, 0.4)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	card_overlay.add_theme_stylebox_override("panel", style)
	add_child(card_overlay)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card_overlay.add_child(vbox)

	var header = HBoxContainer.new()
	vbox.add_child(header)
	var title = Label.new()
	title.text = "Assign %s:" % staff.display_name()
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.pressed.connect(func(): card_overlay.queue_free(); card_overlay = null)
	header.add_child(close_btn)

	var s_id = staff_id

	# Car-assigned roles: Mechanic, Pit Crew
	if staff.role in ["Race Mechanic", "Pit Crew"]:
		var lbl = Label.new()
		lbl.text = "Assign to car:"
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(lbl)
		for car in GameState.player_team_cars:
			var btn = Button.new()
			var current = ""
			if staff.role == "Race Mechanic" and car.mechanic_id != "":
				var m = GameState.all_staff.get(car.mechanic_id)
				current = "  (has: %s)" % m.full_name() if m else ""
			elif staff.role == "Pit Crew" and car.pit_crew_id != "" and car.pit_crew_id != "N/A":
				var p = GameState.all_staff.get(car.pit_crew_id)
				current = "  (has: %s)" % p.full_name() if p else ""
			btn.text = "%s%s" % [_car_display_name(car), current]
			btn.custom_minimum_size = Vector2(340, 36)
			var _car_id = car.id
			btn.pressed.connect(func():
				GameState.assign_staff_to_car(s_id, _car_id)
				card_overlay.queue_free()
				card_overlay = null
				_refresh_list()
			)
			vbox.add_child(btn)

	# Championship-assigned roles: TP, Strategist — show picker for all active championships
	elif staff.role in ["Team Principal", "Race Strategist"]:
		var lbl = Label.new()
		lbl.text = "Assign to championship:"
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(lbl)

		if GameState.active_championships.is_empty():
			var lbl_none = Label.new()
			lbl_none.text = "No active championships this season."
			lbl_none.modulate = Color(0.5, 0.5, 0.5)
			vbox.add_child(lbl_none)
		else:
			for champ in GameState.active_championships:
				var reg = GameState.CHAMPIONSHIP_REGISTRY.get(champ.id, {})
				var champ_name = reg.get("name", champ.id)

				## For TP: disable button if another TP is already assigned to this championship
				var already_has_tp = false
				if staff.role == "Team Principal":
					for sid2 in GameState.all_staff:
						var s2 = GameState.all_staff[sid2]
						if s2.id == s_id: continue
						if s2.role == "Team Principal" and s2.contract_team == GameState.player_team.id \
								and s2.assigned_championship == champ.id:
							already_has_tp = true
							break

				var is_assigned_here = staff.assigned_championship == champ.id

				var btn = Button.new()
				btn.custom_minimum_size = Vector2(340, 36)
				if is_assigned_here:
					btn.text = "✅ %s (current)" % champ_name
					btn.disabled = true
					btn.modulate = Color(0.6, 1.0, 0.6)
				elif already_has_tp:
					btn.text = "🔒 %s (TP slot taken)" % champ_name
					btn.disabled = true
					btn.modulate = Color(0.5, 0.5, 0.5)
				else:
					btn.text = "→ %s" % champ_name
					btn.pressed.connect(func():
						GameState.assign_staff_to_championship(s_id, champ.id)
						card_overlay.queue_free()
						card_overlay = null
						_refresh_list()
					)
				vbox.add_child(btn)

	# Team-level roles: CFO, Designer — no specific assignment needed
	else:
		var lbl = Label.new()
		lbl.text = "%s works at team level — no specific assignment needed.\nThey are active as long as they are on your staff." % staff.role
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)
		var ok_btn = Button.new()
		ok_btn.text = "OK"
		ok_btn.custom_minimum_size = Vector2(100, 32)
		ok_btn.pressed.connect(func(): card_overlay.queue_free(); card_overlay = null)
		vbox.add_child(ok_btn)

# ── Release confirmation ───────────────────────────────────────────────────────

func _confirm_release_staff(staff_id: String) -> void:
	## No confirmation dialog per design spec
	GameState.release_staff(staff_id)
	tab_my_btn.text = "👥 My Staff (%d)" % GameState.get_all_player_staff().size()
	_refresh_list()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _filter_and_sort(staff_list: Array) -> Array:
	var filtered = staff_list.filter(func(s):
		return role_filter == "All" or s.role == role_filter
	)
	filtered.sort_custom(func(a, b):
		var va = _sort_val(a)
		var vb = _sort_val(b)
		return va > vb if not sort_ascending else va < vb
	)
	return filtered

func _sort_val(staff) -> float:
	match sort_field:
		"age":    return float(staff.age)
		"salary": return staff.weekly_salary
		_:        return staff.get_primary_skill()

func _get_staff_attrs(staff) -> Array:
	match staff.role:
		"Race Mechanic":
			return [["Car Setup", staff.car_setup], ["Pit Stops", staff.pit_stops],
				["Car Knowledge", staff.car_knowledge], ["Track Knowledge", staff.track_knowledge]]
		"Pit Crew":
			return [["Pit Stop Speed", staff.pit_stop_speed], ["Repair Skill", staff.repair_skill],
				["Teamwork", staff.teamwork], ["Fitness", staff.fitness]]
		"Team Principal":
			return [["Race Strategy", staff.race_strategy],
				["Practice Management", staff.practice_management],
				["Qualifying Management", staff.qualifying_management],
				["Race Pace Reading", staff.race_pace_reading],
				["Car Setup Oversight", staff.car_setup_oversight],
				["Pit Stop Management", staff.pit_stop_management],
				["PR Skill", staff.pr_skill]]
		"CFO":
			return [["Loan Management", staff.loan_management],
				["Interest Rates", staff.interest_rates],
				["Sales Skill", staff.sales_skill],
				["Sponsor Negotiation", staff.sponsor_negotiation],
				["Resource Management", staff.resource_management],
				["Budget Planning", staff.budget_planning]]
		"Designer":
			return [["Engine", staff.engine], ["Aero", staff.aero],
				["Chassis", staff.chassis], ["Gearbox", staff.gearbox],
				["Suspension", staff.suspension], ["Brakes", staff.brakes],
				["Reliability", staff.reliability], ["Parts Knowledge", staff.parts_knowledge]]
		"Race Strategist":
			return [["Race Strategy", staff.race_strategy],
				["Race Pace Reading", staff.race_pace_reading],
				["Practice Scheduling", staff.practice_scheduling],
				["Qualifying Timing", staff.qualifying_timing],
				["Track Knowledge", staff.track_knowledge]]
	return []

func _make_card_panel(highlight: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.20, 1.0) if highlight else Color(0.11, 0.11, 0.13, 1.0)
	style.border_width_left = 3
	style.border_color = Color(0.7, 0.85, 1.0) if highlight else Color(0.25, 0.25, 0.3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	return card

func _add_col(parent: HBoxContainer, text: String, width: int,
		color: Color = Color.WHITE, font_size: int = 13) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(width, 0)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.clip_text = true
	parent.add_child(lbl)

func _card_row(parent: VBoxContainer, label: String, value: String,
		value_color: Color = Color.WHITE) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(200, 0)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	row.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 15)
	val.add_theme_color_override("font_color", value_color)
	row.add_child(val)

func _skill_color(value: float) -> Color:
	if value >= 75.0:   return Color(0.3, 1.0, 0.3)
	elif value >= 50.0: return Color(1.0, 0.84, 0.0)
	elif value >= 30.0: return Color(1.0, 0.6, 0.2)
	else:               return Color(0.7, 0.4, 0.4)

## Returns an error message if there is no open slot for this role, "" if hiring is allowed.
func _get_slot_message(role: String) -> String:
	match role:
		"Team Principal":
			var current = GameState.get_player_staff_by_role("Team Principal").size()
			var max_tp = GameState.get_hq_tp_slots()
			if current >= max_tp:
				return "TP slots full (%d/%d). Upgrade HQ to unlock more slots." % [current, max_tp]
		"CFO":
			if GameState.get_player_staff_by_role("CFO").size() >= 1:
				return "You already have a CFO. Release them first."
		"Race Strategist":
			# 1 per championship. Only required for non-GK.
			if GameState.active_championship.discipline == "GK":
				return "Race Strategist not required for GK championships."
			if GameState.get_player_staff_by_role("Race Strategist").size() >= 1:
				return "You already have a Race Strategist for this championship."
		"Race Mechanic":
			# Slot limit = max cars allowed = garage level (min 1 if built)
			# Allow hiring even during upgrade — building still operational
			var garage = GameState.get_building("Garage")
			var max_mechanics = max(1, garage.get("level", 1))
			if GameState.get_player_staff_by_role("Race Mechanic").size() >= max_mechanics:
				return "Mechanic slots full (Garage Lv%d = %d slot%s). Upgrade Garage for more." % [
					max_mechanics, max_mechanics, "s" if max_mechanics != 1 else ""]
		"Pit Crew":
			if GameState.active_championship.discipline == "GK":
				return "Pit Crew not required for GK championships."
			else:
				var arena = GameState.get_building("Pit Crew Arena")
				if not arena.get("built", false) or arena.get("level", 0) < 1:
					return "Build the Pit Crew Arena first to hire Pit Crew."
				var max_crews = max(1, arena.get("level", 1))
				if GameState.get_player_staff_by_role("Pit Crew").size() >= max_crews:
					return "Pit Crew slots full (Arena Lv%d = %d slot%s). Upgrade Arena for more." % [
						max_crews, max_crews, "s" if max_crews != 1 else ""]
		"Designer":
			# Slot limited by R&D Studio level. If not built, 0 slots.
			var rnd = GameState.get_building("R&D Design Studio")
			if rnd.is_empty() or not rnd.get("built", false) or rnd.get("level", 0) < 1:
				return "Build and level up the R&D Design Studio to hire Designers."
			var max_designers = rnd.get("level", 0)
			if GameState.get_player_staff_by_role("Designer").size() >= max_designers:
				return "Designer slots full (Level %d = %d slot%s). Upgrade R&D Studio for more." % [
					max_designers, max_designers, "s" if max_designers != 1 else ""]
	return ""

func _staff_display_name(staff) -> String:
	if staff.role == "Pit Crew":
		var num = staff.crew_number if "crew_number" in staff else 1
		return "Pit Crew %d" % num
	return staff.display_name()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if card_overlay:
			card_overlay.queue_free()
			card_overlay = null
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		var screenshot = get_viewport().get_texture().get_image()
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
		screenshot.save_png("user://screenshot_%s.png" % timestamp)

func _car_display_name(car) -> String:
	if car.car_name != null and car.car_name != "":
		return car.car_name
	return "Car %d" % car.car_number

func _fmt_sal(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif n >= 1000:
		return "%.0fK" % (n / 1000.0)
	return str(n)
