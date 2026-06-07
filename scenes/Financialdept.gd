## Automotive Empire — FinancialDept.gd
## Version: S19.1
## Last modified: 2026-06-04
## Changes: Financial Department scene — income/expense dashboard, CFO proposals
extends Control

func _ready() -> void:
	_build_ui()
	GameState.log_updated.connect(_build_ui)

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 20)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	_build_header(root)

	var columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	columns.add_child(_build_income_panel())
	columns.add_child(_build_expense_panel())
	columns.add_child(_build_indicators_panel())

	root.add_child(HSeparator.new())

	var prop_panel = _make_section_panel(Color(1.0, 0.8, 0.2))
	prop_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(prop_panel)
	_build_cfo_proposals(prop_panel.get_child(0))

func _build_header(parent: VBoxContainer) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = "FINANCIAL DEPARTMENT"
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var bal = GameState.player_team.balance
	var lbl_bal = Label.new()
	lbl_bal.text = "Balance: CR %s" % _fmt(int(bal))
	lbl_bal.add_theme_font_size_override("font_size", 18)
	lbl_bal.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if bal >= 0 else Color(1.0, 0.3, 0.3))
	row.add_child(lbl_bal)

	var btn_back = Button.new()
	btn_back.text = "\u2190 Back"
	btn_back.custom_minimum_size = Vector2(90, 34)
	btn_back.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/MainHub.tscn"))
	row.add_child(btn_back)

func _make_section_panel(border_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.13)
	style.border_width_left = 3; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 8; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)
	return panel

func _build_income_panel() -> PanelContainer:
	var panel = _make_section_panel(Color(0.3, 0.7, 0.3))
	var vbox = panel.get_child(0)

	var lbl = Label.new()
	lbl.text = "WEEKLY INCOME"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	vbox.add_child(lbl)
	vbox.add_child(HSeparator.new())

	var sponsor_weekly = 0
	for sp in GameState.active_sponsors:
		if sp.type == 1:
			sponsor_weekly += sp.weekly_payment

	var supply_weekly = 0
	for sc in GameState.active_supply_contracts:
		if sc.active:
			supply_weekly += int(sc.parts_per_season / 52.0) * sc.cr_per_part

	var building_income = 0
	for bname in GameState.campus_buildings:
		var b = GameState.campus_buildings[bname]
		if b.get("level", 0) > 0:
			building_income += b.get("weekly_income", 0)

	var prize_est = _estimate_weekly_prize()
	var items = [
		["Race Prizes (est.)", prize_est, prize_est > 0],
		["Sponsors (Type 1)",  sponsor_weekly, sponsor_weekly > 0],
		["Parts Sales",        supply_weekly, supply_weekly > 0],
		["Building Income",    building_income, building_income > 0],
	]
	var total = 0
	for item in items:
		vbox.add_child(_income_row(item[0], item[1], item[2]))
		if item[2]: total += item[1]
	vbox.add_child(HSeparator.new())
	vbox.add_child(_income_row("TOTAL (est.)", total, true))
	return panel

func _estimate_weekly_prize() -> int:
	if GameState.last_race_results.is_empty(): return 0
	for entry in GameState.last_race_results:
		if entry.get("is_player", false) or \
		   entry["driver"].id in GameState.player_team.drivers:
			return int(entry.get("prize", 0))
	return 0

func _income_row(label: String, amount: int, active: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	if not active: lbl.modulate = Color(0.35, 0.35, 0.35)
	row.add_child(lbl)
	var val = Label.new()
	val.text = "+CR %s" % _fmt(amount) if amount > 0 else "\u2014"
	val.add_theme_font_size_override("font_size", 12)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.custom_minimum_size = Vector2(120, 0)
	val.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if amount > 0 else Color(0.35, 0.35, 0.35))
	row.add_child(val)
	return row

func _build_expense_panel() -> PanelContainer:
	var panel = _make_section_panel(Color(0.8, 0.3, 0.3))
	var vbox = panel.get_child(0)

	var lbl = Label.new()
	lbl.text = "WEEKLY EXPENSES"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(lbl)
	vbox.add_child(HSeparator.new())

	var driver_sal = 0
	for d_id in GameState.player_team.drivers:
		var d = GameState.all_drivers.get(d_id)
		if d: driver_sal += int(d.salary / 52.0) if "salary" in d else 0

	var staff_sal = 0
	for s_id in GameState.all_staff:
		var s = GameState.all_staff[s_id]
		if s.contract_team == GameState.player_team.id:
			staff_sal += int(s.weekly_salary)

	var maintenance = 0
	for bname in GameState.campus_buildings:
		var b = GameState.campus_buildings[bname]
		if b.get("level", 0) > 0:
			maintenance += b.get("weekly_maintenance", 0)

	var rnd_costs = 0
	for task in GameState.active_rnd_tasks:
		rnd_costs += int(task.get("cr", 0) / max(1, task.get("weeks", 1)))

	var items = [
		["Driver Salaries",       driver_sal],
		["Staff Salaries",        staff_sal],
		["Building Maintenance",  maintenance],
		["R&D Projects",          rnd_costs],
		["Fuel (est.)",           GameState.player_team_cars.size() * 200],
		["Loan Interest",         int(GameState.current_loan * 0.002)],
	]
	var total = 0
	for item in items:
		vbox.add_child(_expense_row(item[0], item[1]))
		total += item[1]
	vbox.add_child(HSeparator.new())
	vbox.add_child(_expense_row("TOTAL (est.)", total))
	return panel

func _expense_row(label: String, amount: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	if amount == 0: lbl.modulate = Color(0.35, 0.35, 0.35)
	row.add_child(lbl)
	var val = Label.new()
	val.text = "-CR %s" % _fmt(amount) if amount > 0 else "\u2014"
	val.add_theme_font_size_override("font_size", 12)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.custom_minimum_size = Vector2(120, 0)
	val.add_theme_color_override("font_color",
		Color(1.0, 0.4, 0.4) if amount > 0 else Color(0.35, 0.35, 0.35))
	row.add_child(val)
	return row

func _build_indicators_panel() -> PanelContainer:
	var panel = _make_section_panel(Color(0.3, 0.55, 0.9))
	var vbox = panel.get_child(0)

	var lbl = Label.new()
	lbl.text = "KEY INDICATORS"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	vbox.add_child(lbl)
	vbox.add_child(HSeparator.new())

	var company_val = GameState._calculate_company_value()
	var max_loan = GameState._calculate_max_loan()
	var runway = GameState.get_runway_weeks()

	var indicators = [
		["Company Value",    "CR %s" % _fmt(int(company_val)),     Color(0.8,0.8,0.8)],
		["Max Loan",         "CR %s" % _fmt(int(max_loan)),        Color(0.6,0.6,0.6)],
		["Reputation",       "%.0f / 100" % GameState.player_team.reputation,
			_stat_color(GameState.player_team.reputation)],
		["CEO Wealth",       "CR %s" % _fmt(int(GameState.ceo_accumulated_salary)),
			Color(1.0, 0.84, 0.0)],
		["Economy",          GameState.global_economy_state,
			Color(0.4,0.9,0.4) if GameState.global_economy_state == "Boom"
			else Color(1.0,0.6,0.1) if GameState.global_economy_state == "Normal"
			else Color(1.0,0.3,0.3)],
		["Fuel Price",       "CR %s/unit" % _fmt(int(GameState.current_fuel_price)), Color(0.7,0.7,0.7)],
		["Runway",
			"%d weeks" % runway if runway < 52 else "Stable",
			Color(0.4,0.9,0.4) if runway >= 8 else
			Color(1.0,0.6,0.1) if runway >= 4 else Color(1.0,0.3,0.3)],
	]
	for ind in indicators:
		var row = HBoxContainer.new()
		vbox.add_child(row)
		var ll = Label.new()
		ll.text = ind[0]
		ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ll.add_theme_font_size_override("font_size", 12)
		ll.modulate = Color(0.6, 0.6, 0.6)
		row.add_child(ll)
		var lv = Label.new()
		lv.text = ind[1]
		lv.add_theme_font_size_override("font_size", 12)
		lv.add_theme_color_override("font_color", ind[2])
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lv.custom_minimum_size = Vector2(140, 0)
		row.add_child(lv)

	## Runway explanation
	var lbl_rw = Label.new()
	lbl_rw.text = "Runway = weeks of expenses covered by current balance (no income assumed)"
	lbl_rw.add_theme_font_size_override("font_size", 10)
	lbl_rw.modulate = Color(0.4, 0.4, 0.4)
	lbl_rw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_rw)
	return panel

func _stat_color(v: float) -> Color:
	if v >= 70: return Color(0.4, 0.9, 0.4)
	if v >= 40: return Color(1.0, 0.8, 0.2)
	return Color(1.0, 0.4, 0.4)

func _build_cfo_proposals(parent: VBoxContainer) -> void:
	var lbl = Label.new()
	lbl.text = "CFO PROPOSALS"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	parent.add_child(lbl)

	var cfo = null
	for s_id in GameState.all_staff:
		var s = GameState.all_staff[s_id]
		if s.role == "CFO" and s.contract_team == GameState.player_team.id:
			cfo = s
			break

	if not cfo:
		var e = Label.new()
		e.text = "No CFO hired. Hire a CFO in HQ to receive financial proposals."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 12)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(e)
		return

	var proposals = _gen_proposals()
	if proposals.is_empty():
		var ok = Label.new()
		ok.text = "✅ CFO: All financial indicators healthy this week."
		ok.add_theme_font_size_override("font_size", 12)
		ok.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		parent.add_child(ok)
		return

	for prop in proposals:
		var lp = Label.new()
		lp.text = prop.text
		lp.add_theme_font_size_override("font_size", 12)
		lp.add_theme_color_override("font_color", prop.color)
		lp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(lp)

func _gen_proposals() -> Array:
	var out = []
	var runway = GameState.get_runway_weeks()
	if runway < 4:
		out.append({"text":"🚨 CRITICAL: Only %d weeks runway. Immediate action required." % runway,
			"color":Color(1.0,0.3,0.3)})
	elif runway < 8:
		out.append({"text":"⚠ WARNING: %d weeks runway. Reduce expenses or secure income." % runway,
			"color":Color(1.0,0.6,0.1)})
	if GameState.fuel_kg < 100:
		out.append({"text":"⛽ Fuel low (%.0f kg). Recommend buying 2 weeks supply." % GameState.fuel_kg,
			"color":Color(1.0,0.6,0.1)})
	if GameState.spare_parts < 20:
		out.append({"text":"🔧 Spare parts low (%d units). Restock before next race." % GameState.spare_parts,
			"color":Color(1.0,0.6,0.1)})
	if GameState.active_sponsors.is_empty() and not GameState.cfo_search_active:
		out.append({"text":"📋 No active sponsors. Recommend initiating a sponsor search.",
			"color":Color(0.7,0.7,0.7)})
	return out

func _fmt(n: int) -> String:
	return GameState._fmt_int(n)
