extends Control
## Version: S15.1 — Fixed get_installed_parts_for_car crash; new inventory dict format;
##                    install/remove via install_part_on_car/remove_part_from_car; parts panel always renders.

# ── State ─────────────────────────────────────────────────────────────────────
var _assigning_car_id: String = ""
var _popup_mode: String = "mechanic"  # "mechanic" | "driver"
var _rename_popup: PanelContainer
var _rename_input: LineEdit
var _rename_car_id: String = ""

# ── Built-in-code node refs ───────────────────────────────────────────────────
var _lbl_level: Label
var _lbl_slots: Label
var _lbl_income: Label
var _cars_container: VBoxContainer
var _empty_label: Label
var _parts_container: HBoxContainer

# Mechanic popup
var _popup: PanelContainer
var _popup_title: Label
var _popup_list: VBoxContainer

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   24)
	margin.add_theme_constant_override("margin_right",  24)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# ── Header ────────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	vbox.add_child(header)

	_lbl_level = Label.new()
	_lbl_level.add_theme_font_size_override("font_size", 22)
	_lbl_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_lbl_level)

	_lbl_slots = Label.new()
	_lbl_slots.add_theme_font_size_override("font_size", 14)
	_lbl_slots.modulate = Color(0.7, 0.7, 0.7)
	header.add_child(_lbl_slots)

	_lbl_income = Label.new()
	_lbl_income.add_theme_font_size_override("font_size", 14)
	_lbl_income.modulate = Color(0.4, 0.9, 0.5)
	header.add_child(_lbl_income)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(100, 36)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)

	vbox.add_child(HSeparator.new())

	# ── Action bar ────────────────────────────────────────────────────────────
	var action_bar = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 12)
	vbox.add_child(action_bar)

	var btn_buy = Button.new()
	btn_buy.text = "🛒 Buy Car  →  Logistics"
	btn_buy.custom_minimum_size = Vector2(220, 36)
	btn_buy.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/Logistics.tscn"))
	action_bar.add_child(btn_buy)

	var btn_mech = Button.new()
	btn_mech.text = "🔧 Hire Mechanic  →  Staff"
	btn_mech.custom_minimum_size = Vector2(220, 36)
	btn_mech.pressed.connect(func():
		GameState.pending_staff_filter = "Race Mechanic"
		get_tree().change_scene_to_file("res://scenes/Staff.tscn")
	)
	action_bar.add_child(btn_mech)

	var lbl_hint = Label.new()
	lbl_hint.text = "Cars are purchased from the Logistics Center or built at the CNC Plant."
	lbl_hint.add_theme_font_size_override("font_size", 11)
	lbl_hint.modulate = Color(0.5, 0.5, 0.5)
	action_bar.add_child(lbl_hint)

	vbox.add_child(HSeparator.new())

	# ── Cars scroll ───────────────────────────────────────────────────────────
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(scroll_vbox)

	_empty_label = Label.new()
	_empty_label.text = "No cars in the garage.\nPurchase a car from the Logistics Center, or build one at the CNC Plant."
	_empty_label.modulate = Color(0.5, 0.5, 0.5)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.visible = false
	scroll_vbox.add_child(_empty_label)

	_cars_container = VBoxContainer.new()
	_cars_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cars_container.add_theme_constant_override("separation", 12)
	scroll_vbox.add_child(_cars_container)

	vbox.add_child(HSeparator.new())

	# ── Parts bar ─────────────────────────────────────────────────────────────
	var parts_vbox = VBoxContainer.new()
	parts_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(parts_vbox)

	var parts_title = Label.new()
	parts_title.text = "PARTS INVENTORY  (Provider Spare Parts)"
	parts_title.add_theme_font_size_override("font_size", 11)
	parts_title.modulate = Color(0.6, 0.6, 0.6)
	parts_vbox.add_child(parts_title)

	_parts_container = HBoxContainer.new()
	_parts_container.add_theme_constant_override("separation", 28)
	parts_vbox.add_child(_parts_container)

	# ── CNC Parts Installation ────────────────────────────────────────────────
	vbox.add_child(HSeparator.new())
	var install_title = Label.new()
	install_title.text = "CNC PARTS INSTALLATION"
	install_title.add_theme_font_size_override("font_size", 14)
	install_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(install_title)

	var install_scroll = ScrollContainer.new()
	install_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	install_scroll.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(install_scroll)

	var install_vbox = VBoxContainer.new()
	install_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	install_vbox.add_theme_constant_override("separation", 8)
	install_scroll.add_child(install_vbox)
	_build_parts_installation(install_vbox)

	# ── Mechanic popup ────────────────────────────────────────────────────────
	_popup = PanelContainer.new()
	_popup.set_anchors_preset(Control.PRESET_CENTER)
	_popup.custom_minimum_size = Vector2(420, 0)
	_popup.visible = false
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.10, 0.10, 0.13, 0.98)
	popup_style.border_width_left   = 2
	popup_style.border_width_right  = 2
	popup_style.border_width_top    = 2
	popup_style.border_width_bottom = 2
	popup_style.border_color = Color(0.35, 0.65, 1.0)
	popup_style.corner_radius_top_left     = 6
	popup_style.corner_radius_top_right    = 6
	popup_style.corner_radius_bottom_left  = 6
	popup_style.corner_radius_bottom_right = 6
	popup_style.content_margin_left   = 16
	popup_style.content_margin_right  = 16
	popup_style.content_margin_top    = 16
	popup_style.content_margin_bottom = 16
	_popup.add_theme_stylebox_override("panel", popup_style)
	add_child(_popup)

	var popup_vbox = VBoxContainer.new()
	popup_vbox.add_theme_constant_override("separation", 12)
	_popup.add_child(popup_vbox)

	var popup_header = HBoxContainer.new()
	popup_vbox.add_child(popup_header)

	_popup_title = Label.new()
	_popup_title.add_theme_font_size_override("font_size", 17)
	_popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_header.add_child(_popup_title)

	var btn_close = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(32, 32)
	btn_close.pressed.connect(func(): _popup.visible = false)
	popup_header.add_child(btn_close)

	popup_vbox.add_child(HSeparator.new())

	var popup_scroll = ScrollContainer.new()
	popup_scroll.custom_minimum_size = Vector2(0, 200)
	popup_vbox.add_child(popup_scroll)

	_popup_list = VBoxContainer.new()
	_popup_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_popup_list.add_theme_constant_override("separation", 8)
	popup_scroll.add_child(_popup_list)

	# ── Rename popup ──────────────────────────────────────────────────────────
	_rename_popup = PanelContainer.new()
	_rename_popup.set_anchors_preset(Control.PRESET_CENTER)
	_rename_popup.custom_minimum_size = Vector2(340, 0)
	_rename_popup.visible = false
	var rename_style = StyleBoxFlat.new()
	rename_style.bg_color = Color(0.10, 0.10, 0.13, 0.98)
	rename_style.border_width_left   = 2
	rename_style.border_width_right  = 2
	rename_style.border_width_top    = 2
	rename_style.border_width_bottom = 2
	rename_style.border_color = Color(1.0, 0.75, 0.2)
	rename_style.corner_radius_top_left     = 6
	rename_style.corner_radius_top_right    = 6
	rename_style.corner_radius_bottom_left  = 6
	rename_style.corner_radius_bottom_right = 6
	rename_style.content_margin_left   = 16
	rename_style.content_margin_right  = 16
	rename_style.content_margin_top    = 16
	rename_style.content_margin_bottom = 16
	_rename_popup.add_theme_stylebox_override("panel", rename_style)
	add_child(_rename_popup)

	var rename_vbox = VBoxContainer.new()
	rename_vbox.add_theme_constant_override("separation", 12)
	_rename_popup.add_child(rename_vbox)

	var rename_hdr = HBoxContainer.new()
	rename_vbox.add_child(rename_hdr)
	var rename_title = Label.new()
	rename_title.text = "✏ Rename Car"
	rename_title.add_theme_font_size_override("font_size", 16)
	rename_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rename_hdr.add_child(rename_title)
	var rename_close = Button.new()
	rename_close.text = "✕"
	rename_close.custom_minimum_size = Vector2(32, 32)
	rename_close.pressed.connect(func(): _rename_popup.visible = false)
	rename_hdr.add_child(rename_close)

	var rename_hint = Label.new()
	rename_hint.text = "Max 12 characters."
	rename_hint.add_theme_font_size_override("font_size", 11)
	rename_hint.modulate = Color(0.55, 0.55, 0.55)
	rename_vbox.add_child(rename_hint)

	_rename_input = LineEdit.new()
	_rename_input.max_length = 12
	_rename_input.custom_minimum_size = Vector2(300, 36)
	_rename_input.placeholder_text = "e.g. GKR-S1-ROCKET"
	rename_vbox.add_child(_rename_input)

	var rename_btn_row = HBoxContainer.new()
	rename_btn_row.add_theme_constant_override("separation", 8)
	rename_vbox.add_child(rename_btn_row)
	var btn_confirm = Button.new()
	btn_confirm.text = "Rename"
	btn_confirm.custom_minimum_size = Vector2(120, 34)
	btn_confirm.pressed.connect(_on_rename_confirm)
	rename_btn_row.add_child(btn_confirm)
	var btn_cancel = Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.pressed.connect(func(): _rename_popup.visible = false)
	rename_btn_row.add_child(btn_cancel)

# ── Refresh ───────────────────────────────────────────────────────────────────
func refresh() -> void:
	_refresh_header()
	_refresh_cars()
	_refresh_parts()

func _refresh_header() -> void:
	var building = GameState.campus_buildings.get("Garage", {})
	var level    = building.get("level", 1)
	var max_c    = GameState.get_max_cars()
	var cur_c    = GameState.player_team_cars.size()
	var income   = building.get("weekly_income", 0)
	_lbl_level.text  = "🔧 GARAGE  ·  Level %d" % level
	_lbl_slots.text  = "Cars: %d / %d" % [cur_c, max_c]
	_lbl_income.text = "CR %s / week" % _fmt(income)

# ── Cars list ─────────────────────────────────────────────────────────────────
func _refresh_cars() -> void:
	for child in _cars_container.get_children():
		child.queue_free()
	var cars = GameState.player_team_cars
	_empty_label.visible = cars.is_empty()
	for car in cars:
		_cars_container.add_child(_build_car_card(car))

func _build_car_card(car) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.13, 0.15)
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.25, 0.25, 0.28)
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left   = 14
	style.content_margin_right  = 14
	style.content_margin_top    = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var _cid = car.id  # captured once for all lambdas in this card

	# Row 1 — title + rename + remove
	var row1 = HBoxContainer.new()
	var lbl_car = Label.new()
	lbl_car.text = _car_display_name(car)
	lbl_car.add_theme_font_size_override("font_size", 18)
	row1.add_child(lbl_car)
	var lbl_sub = Label.new()
	lbl_sub.text = "  ·  Car %d" % car.car_number
	lbl_sub.add_theme_font_size_override("font_size", 12)
	lbl_sub.modulate = Color(0.5, 0.5, 0.5)
	row1.add_child(lbl_sub)
	# Championship name — clearly labelled so player knows which series this car runs in
	var reg = GameState.CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
	if not reg.is_empty():
		var lbl_champ = Label.new()
		lbl_champ.text = "  🏆 %s" % reg.get("name", car.championship_id)
		lbl_champ.add_theme_font_size_override("font_size", 11)
		lbl_champ.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		row1.add_child(lbl_champ)
	row1.add_child(_spacer())
	var btn_rename = Button.new()
	btn_rename.text = "✏"
	btn_rename.tooltip_text = "Rename car"
	btn_rename.custom_minimum_size = Vector2(32, 28)
	btn_rename.pressed.connect(func(): _open_rename_popup(_cid))
	row1.add_child(btn_rename)
	var btn_remove = Button.new()
	btn_remove.text = "Remove"
	btn_remove.modulate = Color(1.0, 0.5, 0.5)
	btn_remove.pressed.connect(func(): _on_remove_car(_cid))
	row1.add_child(btn_remove)
	vbox.add_child(row1)

	# Row 2 — condition bar
	var cond_row = HBoxContainer.new()
	cond_row.add_theme_constant_override("separation", 8)
	var lbl_cond_title = Label.new()
	lbl_cond_title.text = "Condition:"
	lbl_cond_title.custom_minimum_size.x = 90
	cond_row.add_child(lbl_cond_title)
	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value     = car.condition
	bar.custom_minimum_size = Vector2(200, 18)
	bar.show_percentage = false
	bar.modulate = _condition_color(car.condition)
	cond_row.add_child(bar)
	var lbl_cond_val = Label.new()
	lbl_cond_val.text = "  %.0f%%" % car.condition
	lbl_cond_val.modulate = _condition_color(car.condition)
	cond_row.add_child(lbl_cond_val)
	vbox.add_child(cond_row)

	# Row 3 — driver + mechanic
	var row3 = HBoxContainer.new()
	row3.add_theme_constant_override("separation", 32)

	# Driver column
	var d_vbox = VBoxContainer.new()
	var d_title = Label.new()
	d_title.text = "DRIVER"
	d_title.add_theme_font_size_override("font_size", 10)
	d_title.modulate = Color(0.55, 0.55, 0.55)
	d_vbox.add_child(d_title)
	var d_row = HBoxContainer.new()
	d_row.add_theme_constant_override("separation", 6)
	var lbl_driver = Label.new()
	if car.driver_id != "":
		var d = GameState.all_drivers.get(car.driver_id)
		lbl_driver.text = d.full_name() if d else "Unknown"
	else:
		lbl_driver.text = "— unassigned —"
		lbl_driver.modulate = Color(0.9, 0.5, 0.15)
	d_row.add_child(lbl_driver)
	var btn_assign_driver = Button.new()
	btn_assign_driver.text = "Assign" if car.driver_id == "" else "Change"
	btn_assign_driver.pressed.connect(func(): _open_driver_popup(_cid))
	d_row.add_child(btn_assign_driver)
	if car.driver_id != "":
		var btn_unassign_driver = Button.new()
		btn_unassign_driver.text = "Unassign"
		btn_unassign_driver.pressed.connect(func(): _on_unassign_driver(_cid))
		d_row.add_child(btn_unassign_driver)
	d_vbox.add_child(d_row)
	row3.add_child(d_vbox)

	# Mechanic column
	var m_vbox = VBoxContainer.new()
	var m_title = Label.new()
	m_title.text = "MECHANIC"
	m_title.add_theme_font_size_override("font_size", 10)
	m_title.modulate = Color(0.55, 0.55, 0.55)
	m_vbox.add_child(m_title)
	var m_row = HBoxContainer.new()
	m_row.add_theme_constant_override("separation", 6)
	var lbl_mech = Label.new()
	if car.mechanic_id != "" and car.mechanic_id in GameState.all_staff:
		lbl_mech.text = GameState.all_staff[car.mechanic_id].full_name()
	else:
		lbl_mech.text = "— unassigned —"
		lbl_mech.modulate = Color(0.9, 0.5, 0.15)
	m_row.add_child(lbl_mech)
	var btn_assign = Button.new()
	btn_assign.text = "Assign" if car.mechanic_id == "" else "Change"
	btn_assign.pressed.connect(func(): _open_mechanic_popup(_cid))
	btn_assign.pressed.connect(func(): _open_mechanic_popup(_cid))
	m_row.add_child(btn_assign)
	if car.mechanic_id != "":
		var btn_unassign = Button.new()
		btn_unassign.text = "Unassign"
		btn_unassign.pressed.connect(func(): _on_unassign_mechanic(_cid))
		m_row.add_child(btn_unassign)
	m_vbox.add_child(m_row)
	row3.add_child(m_vbox)

	# Pit Crew column — only for non-GK championships
	if GameState.get_pit_crew_required(car.championship_id):
		var pc_vbox = VBoxContainer.new()
		var pc_title = Label.new()
		pc_title.text = "PIT CREW"
		pc_title.add_theme_font_size_override("font_size", 10)
		pc_title.modulate = Color(0.55, 0.55, 0.55)
		pc_vbox.add_child(pc_title)
		var pc_row = HBoxContainer.new()
		pc_row.add_theme_constant_override("separation", 6)
		var lbl_crew = Label.new()
		if car.pit_crew_id != "" and car.pit_crew_id != "N/A" and car.pit_crew_id in GameState.all_staff:
			lbl_crew.text = GameState.all_staff[car.pit_crew_id].display_name()
			lbl_crew.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		elif car.pit_crew_id == "N/A":
			lbl_crew.text = "N/A (GK)"
			lbl_crew.modulate = Color(0.5, 0.5, 0.5)
		else:
			lbl_crew.text = "⚠ unassigned — DNS"
			lbl_crew.modulate = Color(1.0, 0.4, 0.4)
		pc_row.add_child(lbl_crew)
		# Quick-assign button to navigate to PitCrewArena
		var btn_crew = Button.new()
		btn_crew.text = "→ Pit Crew Arena"
		btn_crew.add_theme_font_size_override("font_size", 11)
		btn_crew.pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/buildings/PitCrewArena.tscn"))
		pc_row.add_child(btn_crew)
		pc_vbox.add_child(pc_row)
		row3.add_child(pc_vbox)

	vbox.add_child(row3)

	# Row 4 — telemetry stats
	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 24)
	for stat in [
		["TOP SPEED", "%.0f km/h" % car.top_speed],
		["ACCEL",     "%.1f m/s²" % car.acceleration],
		["GRIP",      "%.2f G"    % car.cornering_grip],
		["HP",        "%d hp"     % _calc_hp(car)],
	]:
		var sv = VBoxContainer.new()
		var st = Label.new()
		st.text = stat[0]
		st.add_theme_font_size_override("font_size", 9)
		st.modulate = Color(0.5, 0.5, 0.5)
		sv.add_child(st)
		var sv2 = Label.new()
		sv2.text = stat[1]
		sv2.add_theme_font_size_override("font_size", 13)
		sv.add_child(sv2)
		stats_row.add_child(sv)
	vbox.add_child(stats_row)

	# Row 5 — repair buttons (only if damaged)
	var damage = 100.0 - car.condition
	if damage > 0.0:
		var repair_row = HBoxContainer.new()
		repair_row.add_theme_constant_override("separation", 8)
		var sp_rate = GameState.active_championship.sp_per_10_pct_damage
		var sp_full = int(ceil(damage / 10.0) * sp_rate)
		var btn_full = Button.new()
		btn_full.text = "Full Repair  (-%d SP)" % sp_full
		btn_full.disabled = GameState.spare_parts < sp_full or car.mechanic_id == ""
		btn_full.pressed.connect(func(): _on_repair_full(car))
		repair_row.add_child(btn_full)
		var lbl_sp = Label.new()
		lbl_sp.text = "SP: %d" % GameState.spare_parts
		lbl_sp.modulate = Color(0.65, 0.65, 0.65)
		repair_row.add_child(lbl_sp)
		if car.mechanic_id == "":
			var lbl_warn = Label.new()
			lbl_warn.text = "⚠ Assign mechanic to repair"
			lbl_warn.modulate = Color(0.9, 0.5, 0.1)
			repair_row.add_child(lbl_warn)
		vbox.add_child(repair_row)

	# Row 6 — part conditions
	var parts_row = HBoxContainer.new()
	parts_row.add_theme_constant_override("separation", 12)
	for part_name in car.part_conditions:
		var pv = VBoxContainer.new()
		var pt = Label.new()
		pt.text = part_name.left(3).to_upper()
		pt.add_theme_font_size_override("font_size", 9)
		pt.modulate = Color(0.5, 0.5, 0.5)
		pv.add_child(pt)
		var pval = Label.new()
		pval.text = "%.0f%%" % car.part_conditions[part_name]
		pval.modulate = _condition_color(car.part_conditions[part_name])
		pval.add_theme_font_size_override("font_size", 11)
		pv.add_child(pval)
		parts_row.add_child(pv)
	vbox.add_child(parts_row)

	return panel

# ── Parts bar ─────────────────────────────────────────────────────────────────
func _refresh_parts() -> void:
	for child in _parts_container.get_children():
		child.queue_free()
	## Note: these are provider spare parts (race consumables), not CNC manufactured parts
	## Provider parts are pre-stocked (3 per type). CNC parts appear in the Installation section below.
	for part in GameState.PARTS_LIST:
		var stock = GameState.get_part_stock(part)
		var vb = VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		var lbl_name = Label.new()
		lbl_name.text = part.to_upper()
		lbl_name.add_theme_font_size_override("font_size", 9)
		lbl_name.modulate = Color(0.6, 0.6, 0.6)
		lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(lbl_name)
		var lbl_stock = Label.new()
		lbl_stock.text = str(stock)
		lbl_stock.add_theme_font_size_override("font_size", 16)
		lbl_stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if stock <= GameState.CFO_PART_WARNING_THRESHOLD:
			lbl_stock.modulate = Color(1.0, 0.35, 0.35)
		elif stock <= 4:
			lbl_stock.modulate = Color(1.0, 0.75, 0.2)
		vb.add_child(lbl_stock)
		_parts_container.add_child(vb)

# ── Rename popup ──────────────────────────────────────────────────────────────
func _open_rename_popup(car_id: String) -> void:
	_rename_car_id = car_id
	var car = GameState.get_car_by_id(car_id)
	_rename_input.text = _car_display_name(car) if car else ""
	_rename_input.select_all()
	_rename_popup.visible = true

func _on_rename_confirm() -> void:
	if GameState.rename_car(_rename_car_id, _rename_input.text):
		_rename_popup.visible = false
		refresh()

# ── Driver popup ──────────────────────────────────────────────────────────────
func _open_driver_popup(car_id: String) -> void:
	_assigning_car_id = car_id
	_popup_mode = "driver"
	var car = GameState.get_car_by_id(car_id)
	var name = _car_display_name(car) if car else "Car"
	_popup_title.text = "Assign Driver — %s" % name

	for child in _popup_list.get_children():
		child.queue_free()

	var my_drivers = GameState.get_player_drivers()
	if my_drivers.is_empty():
		var lbl = Label.new()
		lbl.text = "No drivers signed.\nHire drivers from the Drivers screen."
		lbl.modulate = Color(0.65, 0.65, 0.65)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_popup_list.add_child(lbl)
	else:
		for driver in my_drivers:
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var lbl = Label.new()
			lbl.text = "%s  (Ovr: %.0f)" % [driver.full_name(), driver.get_overall_skill()]
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(lbl)
			var assigned_car = _find_car_for_driver(driver.id)
			if assigned_car and assigned_car.id != car_id:
				var lbl_cur = Label.new()
				lbl_cur.text = "→ %s" % _car_display_name(assigned_car)
				lbl_cur.modulate = Color(0.55, 0.55, 0.55)
				row.add_child(lbl_cur)
			var btn = Button.new()
			var already_here = assigned_car != null and assigned_car.id == car_id
			btn.text = "Assigned ✅" if already_here else "Assign"
			btn.disabled = already_here
			var d_id_cap = driver.id
			btn.pressed.connect(func(): _on_assign_driver(d_id_cap, car_id))
			row.add_child(btn)
			_popup_list.add_child(row)

	_popup.visible = true

func _on_assign_driver(driver_id: String, car_id: String) -> void:
	GameState.assign_driver_to_car(driver_id, car_id)
	_popup.visible = false
	refresh()

func _on_unassign_driver(car_id: String) -> void:
	var car = GameState.get_car_by_id(car_id)
	if car and car.driver_id != "":
		var driver = GameState.all_drivers.get(car.driver_id)
		car.driver_id = ""
		if driver:
			GameState.add_log("👤 %s unassigned from %s." % [
				driver.full_name(), _car_display_name(car)])
	refresh()

func _find_car_for_driver(driver_id: String):
	for car in GameState.player_team_cars:
		if car.driver_id == driver_id:
			return car
	return null

# ── Mechanic popup ────────────────────────────────────────────────────────────
func _open_mechanic_popup(car_id: String) -> void:
	_assigning_car_id = car_id
	var car = GameState.get_car_by_id(car_id)
	_popup_title.text = "Assign Mechanic — %s" % (_car_display_name(car) if car else "Car")

	for child in _popup_list.get_children():
		child.queue_free()

	var hired_mechs = GameState.get_player_staff_by_role("Race Mechanic")
	if hired_mechs.is_empty():
		var lbl = Label.new()
		lbl.text = "No Race Mechanics hired.\nHire one from the Staff screen."
		lbl.modulate = Color(0.65, 0.65, 0.65)
		_popup_list.add_child(lbl)
	else:
		for mech in hired_mechs:
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			var lbl = Label.new()
			lbl.text = "%s  (Setup: %.0f)" % [mech.full_name(), mech.car_setup]
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(lbl)
			var assigned_car = _find_car_for_mechanic(mech.id)
			if assigned_car and assigned_car.id != car_id:
				var lbl_cur = Label.new()
				lbl_cur.text = "→ Car %d" % assigned_car.car_number
				lbl_cur.modulate = Color(0.55, 0.55, 0.55)
				row.add_child(lbl_cur)
			var btn = Button.new()
			var already_assigned = assigned_car != null and assigned_car.id == car_id
			btn.text = "Assigned ✅" if already_assigned else "Assign"
			btn.disabled = already_assigned
			var mech_id_cap = mech.id
			btn.pressed.connect(func(): _on_assign_mechanic(mech_id_cap, car_id))
			row.add_child(btn)
			_popup_list.add_child(row)

	_popup.visible = true

func _on_assign_mechanic(mech_id: String, car_id: String) -> void:
	for car in GameState.player_team_cars:
		if car.mechanic_id == mech_id and car.id != car_id:
			car.mechanic_id = ""
	GameState.assign_staff_to_car(mech_id, car_id)
	_popup.visible = false
	refresh()

func _on_unassign_mechanic(car_id: String) -> void:
	var car = GameState.get_car_by_id(car_id)
	if car and car.mechanic_id != "" and car.mechanic_id in GameState.all_staff:
		GameState.all_staff[car.mechanic_id].assigned_car_id = ""
		car.mechanic_id = ""
		GameState.add_log("🔧 Mechanic unassigned from Car %d." % car.car_number)
	refresh()

func _find_car_for_mechanic(mech_id: String):
	for car in GameState.player_team_cars:
		if car.mechanic_id == mech_id:
			return car
	return null

# ── Repair ────────────────────────────────────────────────────────────────────
func _on_repair_full(car) -> void:
	if car.driver_id != "":
		GameState.repair_car_full(car.driver_id)
	else:
		var damage = 100.0 - car.condition
		var sp_rate = GameState.active_championship.sp_per_10_pct_damage
		var sp_cost = int(ceil(damage / 10.0) * sp_rate)
		if GameState.spare_parts >= sp_cost:
			GameState.spare_parts -= sp_cost
			car.condition = 100.0
			GameState.add_log("🔧 Car %d repaired to 100%% (-%d SP)" % [car.car_number, sp_cost])
		else:
			GameState.add_notification("High",
				"Not enough SP to repair Car %d." % car.car_number)
	refresh()

# ── Remove car ────────────────────────────────────────────────────────────────
func _on_remove_car(car_id: String) -> void:
	GameState.remove_car(car_id)
	refresh()

# ── Navigation ────────────────────────────────────────────────────────────────
func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/campus.tscn")

# ── Helpers ───────────────────────────────────────────────────────────────────
func _condition_color(pct: float) -> Color:
	if pct >= 70.0:   return Color(0.3, 0.9, 0.4)
	elif pct >= 40.0: return Color(1.0, 0.75, 0.1)
	else:             return Color(1.0, 0.3, 0.3)

func _calc_hp(car) -> int:
	var telemetry = GameState.CAR_TELEMETRY.get(car.car_type_id, {})
	var perf = telemetry.get("perf_index", 1)
	return perf * 15 + 15

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

func _spacer() -> Control:
	var s = Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s

func _car_display_name(car) -> String:
	if car and car.car_name != null and car.car_name != "":
		return car.car_name
	return "Car %d" % car.car_number

## ═══════════════════════════════════════════════════════════════════════════
## S16 — CNC PARTS INSTALLATION
## ═══════════════════════════════════════════════════════════════════════════

func _build_parts_installation(parent: VBoxContainer) -> void:
	if GameState.player_team_cars.is_empty():
		var e = Label.new()
		e.text = "No cars in garage."
		e.modulate = Color(0.45, 0.45, 0.45)
		parent.add_child(e)
		return
	for car in GameState.player_team_cars:
		parent.add_child(_build_car_parts_panel(car))

func _build_car_parts_panel(car) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.13)
	style.border_width_left = 3
	style.border_color = Color(0.3, 0.55, 0.9)
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 8; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var reg = GameState.CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
	var lbl_car = Label.new()
	lbl_car.text = "🏎 %s  —  %s" % [
		car.car_name if car.car_name != "" else "Car %d" % car.car_number,
		reg.get("name", car.championship_id)]
	lbl_car.add_theme_font_size_override("font_size", 13)
	lbl_car.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vbox.add_child(lbl_car)

	const PART_CODES = ["AER","ENG","GRB","SUS","BRK","CHS"]
	const PART_NAMES = {
		"AER":"Aerodynamics","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"
	}
	const PART_SPEC_MAP = {
		"C-001":[true,true,true,false,false,true],"C-002":[true,true,true,false,true,false],
		"C-003":[true,false,true,false,false,false],"C-004":[true,false,false,false,false,false],
		"C-005":[true,true,true,false,false,true],"C-006":[false,true,true,false,false,false],
		"C-007":[false,false,false,false,false,false],"C-008":[false,false,false,false,false,false],
		"C-009":[true,true,true,true,true,true],"C-010":[true,true,true,true,true,true],
		"C-011":[true,true,true,true,true,true],"C-012":[true,true,true,true,true,true],
		"C-013":[true,false,true,false,true,true],"C-014":[true,false,true,false,false,true],
		"C-015":[true,false,false,false,false,true],"C-016":[true,false,false,false,false,true],
		"C-017":[true,false,false,false,false,true],"C-018":[true,true,true,true,true,true],
		"C-019":[true,true,true,false,false,true],"C-020":[false,false,false,false,false,false],
		"C-021":[true,true,true,true,true,true],"C-022":[true,true,true,true,true,true],
		"C-023":[true,true,true,true,true,true],"C-024":[false,false,false,false,false,false],
	}
	var spec_arr = PART_SPEC_MAP.get(car.championship_id, [false,false,false,false,false,false])
	var installed = GameState.get_installed_parts_for_car(car.id)  ## Now returns {} or {pcode: {reliability, quality, ...}}

	for i in range(PART_CODES.size()):
		var pcode = PART_CODES[i]
		var pname = PART_NAMES[pcode]
		var is_spec = spec_arr[i]
		## New inventory key format: "CHAMP_ID|PCODE"
		var inv_key = "%s|%s" % [car.championship_id, pcode]
		var inv_item = GameState.cnc_parts_inventory.get(inv_key, null)
		var in_inventory = inv_item != null and (inv_item.get("quantity", 0) if inv_item is Dictionary else int(inv_item)) > 0
		var is_installed = pcode in installed

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var lbl_p = Label.new()
		lbl_p.text = pname
		lbl_p.custom_minimum_size = Vector2(130, 0)
		lbl_p.add_theme_font_size_override("font_size", 12)
		row.add_child(lbl_p)

		var lbl_t = Label.new()
		lbl_t.text = "SPEC" if is_spec else "OPEN"
		lbl_t.custom_minimum_size = Vector2(46, 0)
		lbl_t.add_theme_font_size_override("font_size", 10)
		lbl_t.add_theme_color_override("font_color",
			Color(1.0, 0.6, 0.2) if is_spec else Color(0.4, 0.88, 0.55))
		row.add_child(lbl_t)

		if is_installed:
			var pd = installed[pcode]
			var rel:  float = pd.get("reliability", 60.0) if pd is Dictionary else 60.0
			var qual: float = pd.get("quality",     1.0)  if pd is Dictionary else 1.0
			var ls = Label.new()
			ls.text = "✅ Rel:%.0f%%  Qual:%.2f×" % [rel, qual]
			ls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ls.add_theme_font_size_override("font_size", 11)
			ls.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			row.add_child(ls)
			var btn_r = Button.new()
			btn_r.text = "Remove"
			btn_r.custom_minimum_size = Vector2(72, 24)
			btn_r.modulate = Color(1.0, 0.5, 0.5)
			btn_r.pressed.connect(func():
				GameState.remove_part_from_car(car.id, pcode)
				_build_ui())
			row.add_child(btn_r)
		elif in_inventory:
			var item = GameState.cnc_parts_inventory[inv_key]
			var qty:  int   = item.get("quantity",    1)    if item is Dictionary else int(item)
			var rel:  float = item.get("reliability", 60.0) if item is Dictionary else 60.0
			var qual: float = item.get("quality",     1.0)  if item is Dictionary else 1.0
			var la = Label.new()
			la.text = "×%d  Rel:%.0f%%  Qual:%.2f×" % [qty, rel, qual]
			la.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			la.add_theme_font_size_override("font_size", 11)
			la.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
			row.add_child(la)
			var btn_i = Button.new()
			btn_i.text = "Install →"
			btn_i.custom_minimum_size = Vector2(72, 24)
			btn_i.pressed.connect(func():
				GameState.install_part_on_car(car.id, car.championship_id, pcode)
				_build_ui())
			row.add_child(btn_i)
		else:
			var ln = Label.new()
			ln.text = "Provider part (no CNC part available)"
			ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ln.add_theme_font_size_override("font_size", 11)
			ln.modulate = Color(0.45, 0.45, 0.45)
			row.add_child(ln)
			var btn_c = Button.new()
			btn_c.text = "Make Part →"
			btn_c.custom_minimum_size = Vector2(85, 24)
			btn_c.pressed.connect(func():
				get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn"))
			row.add_child(btn_c)

	return panel
