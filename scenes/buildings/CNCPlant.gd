extends Control
## CNC Parts Plant — Session 11 rewrite
## Layout: Header | 3-column body
##   Left   — Production queue + Start new job
##   Center — Parts inventory + Assign to car
##   Right  — Building stats + Blueprints available

const PART_COLORS = {
	"Aero":       Color(0.25, 0.65, 1.0),
	"Engine":     Color(1.0,  0.4,  0.2),
	"Chassis":    Color(0.85, 0.55, 0.1),
	"Gearbox":    Color(0.65, 0.3,  0.9),
	"Brakes":     Color(1.0,  0.25, 0.25),
	"Suspension": Color(0.25, 0.85, 0.5),
}

# Championship selection for production cost context
var _selected_champ_id: String = ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Default to first active championship that has a player car
	for car in GameState.player_team_cars:
		if car.championship_id != "":
			_selected_champ_id = car.championship_id
			break
	if _selected_champ_id == "" and GameState.active_championships.size() > 0:
		_selected_champ_id = GameState.active_championships[0].id
	if _selected_champ_id == "":
		_selected_champ_id = "C-001"
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right"]:
		margin.add_theme_constant_override(s, 20)
	for s in ["margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 14)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# ── Header ────────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)

	var building = GameState.campus_buildings.get("CNC Parts Plant", {})
	var lbl_title = Label.new()
	lbl_title.text = "⚙  CNC PARTS PLANT   ·   Level %d" % building.get("level", 1)
	lbl_title.add_theme_font_size_override("font_size", 21)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	# Blueprint count badge
	var bp_count = GameState.get_manufacturable_parts().size()
	var lbl_bp = Label.new()
	lbl_bp.text = "📋 %d Blueprint%s" % [bp_count, "s" if bp_count != 1 else ""]
	lbl_bp.add_theme_font_size_override("font_size", 13)
	lbl_bp.add_theme_color_override("font_color", Color(0.45, 0.75, 1.0) if bp_count > 0 else Color(0.45, 0.45, 0.45))
	header.add_child(lbl_bp)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(90, 34)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)

	root.add_child(_hsep())

	# ── Guard: building must be built ─────────────────────────────────────────
	if not building.get("built", false):
		var warn = Label.new()
		warn.text = "⚠  CNC Parts Plant not built.\nBuild it on Campus to manufacture parts."
		warn.modulate = Color(1.0, 0.55, 0.2)
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warn.add_theme_font_size_override("font_size", 14)
		root.add_child(warn)
		return

	# ── Three-column body ──────────────────────────────────────────────────────
	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	# Column A — Production queue + New job
	var col_a = VBoxContainer.new()
	col_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_a.add_theme_constant_override("separation", 10)
	body.add_child(col_a)
	_build_production_column(col_a)

	# Column B — Inventory + assign to car
	var col_b = VBoxContainer.new()
	col_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_b.add_theme_constant_override("separation", 10)
	body.add_child(col_b)
	_build_inventory_column(col_b)

	# Column C — Building info + blueprints list
	var col_c = VBoxContainer.new()
	col_c.custom_minimum_size = Vector2(240, 0)
	col_c.add_theme_constant_override("separation", 10)
	body.add_child(col_c)
	_build_info_column(col_c)


# ─── Column A: Production Queue + New Job ────────────────────────────────────
func _build_production_column(parent: VBoxContainer) -> void:
	parent.add_child(_section_header("PRODUCTION QUEUE", Color(1.0, 0.8, 0.0)))

	var queue = GameState.cnc_production_queue
	if queue.is_empty():
		var lbl = Label.new()
		lbl.text = "Queue is empty.\nStart a new production run below."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(lbl)
	else:
		for job in queue:
			parent.add_child(_build_queue_card(job))

	parent.add_child(_hsep())

	# ── New Production Job UI ─────────────────────────────────────────────────
	parent.add_child(_section_header("NEW PRODUCTION RUN", Color(0.85, 0.65, 0.2)))

	var mfg_parts = GameState.get_manufacturable_parts()
	if mfg_parts.is_empty():
		var lbl_no = Label.new()
		lbl_no.text = "No blueprints available.\nResearch parts in R&D Studio first."
		lbl_no.modulate = Color(0.5, 0.5, 0.5)
		lbl_no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_no.add_theme_font_size_override("font_size", 12)
		parent.add_child(lbl_no)
		return

	# Championship cost context
	var champ_row = HBoxContainer.new()
	champ_row.add_theme_constant_override("separation", 8)
	parent.add_child(champ_row)
	var lbl_champ_info = Label.new()
	var champ_name = GameState.CHAMPIONSHIP_REGISTRY.get(_selected_champ_id, {}).get("name", _selected_champ_id)
	lbl_champ_info.text = "Cost basis:  %s" % champ_name
	lbl_champ_info.add_theme_font_size_override("font_size", 11)
	lbl_champ_info.modulate = Color(0.55, 0.55, 0.55)
	lbl_champ_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	champ_row.add_child(lbl_champ_info)

	# Part buttons
	for part in mfg_parts:
		var cost_info = _get_part_cost_info(part, _selected_champ_id)
		var can_afford = GameState.player_team.balance >= cost_info["cost"]

		var panel = _make_panel(Color(0.07, 0.11, 0.16))
		var style = panel.get_theme_stylebox("panel")
		style.border_color = PART_COLORS.get(part, Color.WHITE).darkened(0.4)
		style.border_width_left = 4
		parent.add_child(panel)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)

		# Part label
		var lbl_part = Label.new()
		lbl_part.text = part
		lbl_part.add_theme_font_size_override("font_size", 13)
		lbl_part.add_theme_color_override("font_color", PART_COLORS.get(part, Color.WHITE))
		lbl_part.custom_minimum_size = Vector2(90, 0)
		row.add_child(lbl_part)

		# Cost / time
		var lbl_cost = Label.new()
		lbl_cost.text = "💰 CR %s" % _fmt(cost_info["cost"])
		lbl_cost.add_theme_font_size_override("font_size", 12)
		lbl_cost.add_theme_color_override("font_color",
			Color(0.45, 0.88, 0.45) if can_afford else Color(1.0, 0.35, 0.35))
		lbl_cost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl_cost)

		var lbl_time = Label.new()
		lbl_time.text = "⏱ %d wks" % cost_info["weeks"]
		lbl_time.add_theme_font_size_override("font_size", 12)
		lbl_time.modulate = Color(0.7, 0.7, 0.7)
		row.add_child(lbl_time)

		var btn_produce = Button.new()
		btn_produce.text = "Manufacture ×1"
		btn_produce.custom_minimum_size = Vector2(120, 28)
		btn_produce.add_theme_font_size_override("font_size", 11)
		btn_produce.disabled = not can_afford
		var p = part
		var cid = _selected_champ_id
		btn_produce.pressed.connect(func():
			GameState.start_cnc_production(p, cid, 1)
			get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn")
		)
		row.add_child(btn_produce)


func _build_queue_card(job: Dictionary) -> PanelContainer:
	var pct = 1.0 - float(job["weeks_remaining"]) / float(job["weeks_total"])
	var part = job["part"]
	var panel = _make_panel(Color(0.09, 0.14, 0.10))
	var style = panel.get_theme_stylebox("panel")
	style.border_color = PART_COLORS.get(part, Color.WHITE).darkened(0.4)
	style.border_width_left = 4

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)

	var lbl_p = Label.new()
	lbl_p.text = "⚙ %dx %s" % [job["quantity"], part]
	lbl_p.add_theme_font_size_override("font_size", 13)
	lbl_p.add_theme_color_override("font_color", PART_COLORS.get(part, Color.WHITE))
	lbl_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(lbl_p)

	var lbl_wks = Label.new()
	lbl_wks.text = "%d wks left" % job["weeks_remaining"]
	lbl_wks.add_theme_font_size_override("font_size", 11)
	lbl_wks.modulate = Color(0.6, 0.6, 0.6)
	row1.add_child(lbl_wks)

	var bar = ProgressBar.new()
	bar.min_value = 0; bar.max_value = 100
	bar.value = pct * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 13)
	vbox.add_child(bar)

	var lbl_eta = Label.new()
	var eta_week = GameState.current_week + job["weeks_remaining"]
	lbl_eta.text = "Est. ready: Season %d, Week %d" % [GameState.current_season, eta_week]
	lbl_eta.add_theme_font_size_override("font_size", 10)
	lbl_eta.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(lbl_eta)

	return panel


# ─── Column B: Inventory + Assign to Car ─────────────────────────────────────
func _build_inventory_column(parent: VBoxContainer) -> void:
	parent.add_child(_section_header("PARTS INVENTORY", Color(1.0, 0.8, 0.0)))

	var inventory = GameState.cnc_parts_inventory
	if inventory.is_empty():
		var lbl = Label.new()
		lbl.text = "No parts in stock.\nManufacture parts in the Production Queue."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(lbl)
	else:
		for part in inventory:
			var qty: int = inventory[part]
			if qty <= 0: continue
			parent.add_child(_build_inventory_card(part, qty))

	parent.add_child(_hsep())

	# ── Installed parts per car ────────────────────────────────────────────────
	parent.add_child(_section_header("INSTALLED ON CARS", Color(0.5, 0.9, 0.5)))

	var any_installed = false
	for car in GameState.player_team_cars:
		if not car.has_meta("installed_cnc_parts"): continue
		var installed = car.get_meta("installed_cnc_parts")
		if installed.is_empty(): continue
		any_installed = true
		var car_name = car.car_name if car.car_name != "" else "Car %d" % car.car_number
		parent.add_child(_build_installed_car_panel(car, car_name, installed))

	if not any_installed:
		var lbl = Label.new()
		lbl.text = "No CNC parts installed on any car yet."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(lbl)


func _build_inventory_card(part: String, qty: int) -> PanelContainer:
	var panel = _make_panel(Color(0.08, 0.13, 0.09))
	var style = panel.get_theme_stylebox("panel")
	style.border_color = PART_COLORS.get(part, Color.WHITE).darkened(0.3)
	style.border_width_left = 4

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var lbl_part = Label.new()
	lbl_part.text = part
	lbl_part.add_theme_font_size_override("font_size", 13)
	lbl_part.add_theme_color_override("font_color", PART_COLORS.get(part, Color.WHITE))
	lbl_part.custom_minimum_size = Vector2(90, 0)
	row.add_child(lbl_part)

	var lbl_qty = Label.new()
	lbl_qty.text = "× %d in stock" % qty
	lbl_qty.add_theme_font_size_override("font_size", 13)
	lbl_qty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl_qty)

	# Assign-to-car dropdown area
	var cars_for_assignment = GameState.player_team_cars.filter(func(c): return c.championship_id != "")
	if cars_for_assignment.is_empty():
		var lbl_no = Label.new()
		lbl_no.text = "No cars"
		lbl_no.add_theme_font_size_override("font_size", 11)
		lbl_no.modulate = Color(0.5, 0.5, 0.5)
		row.add_child(lbl_no)
	else:
		for car in cars_for_assignment:
			var cname = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			var btn = Button.new()
			btn.text = "→ %s" % cname.left(16)
			btn.custom_minimum_size = Vector2(100, 26)
			btn.add_theme_font_size_override("font_size", 10)
			var p = part
			var cid = car.id
			btn.pressed.connect(func():
				GameState.assign_cnc_part_to_car(cid, p)
				get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn")
			)
			row.add_child(btn)

	return panel


func _build_installed_car_panel(car, car_name: String, installed: Dictionary) -> PanelContainer:
	var panel = _make_panel(Color(0.07, 0.12, 0.09))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	var lbl_car = Label.new()
	lbl_car.text = "🏎 %s" % car_name
	lbl_car.add_theme_font_size_override("font_size", 12)
	lbl_car.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(lbl_car)

	# CNC bonus display
	var bonus = GameState.get_cnc_part_bonus(car.id)
	var lbl_bonus = Label.new()
	lbl_bonus.text = "⚡ CNC bonus: +%.1f%% lap time" % (bonus * 100.0)
	lbl_bonus.add_theme_font_size_override("font_size", 11)
	lbl_bonus.add_theme_color_override("font_color", Color(0.4, 0.88, 0.5))
	vbox.add_child(lbl_bonus)

	for part in installed:
		var qty: int = installed[part]
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var lbl_p = Label.new()
		lbl_p.text = "  %s × %d" % [part, qty]
		lbl_p.add_theme_font_size_override("font_size", 11)
		lbl_p.add_theme_color_override("font_color", PART_COLORS.get(part, Color(0.7, 0.7, 0.7)))
		lbl_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl_p)

		var btn_remove = Button.new()
		btn_remove.text = "Remove"
		btn_remove.custom_minimum_size = Vector2(65, 22)
		btn_remove.add_theme_font_size_override("font_size", 10)
		btn_remove.modulate = Color(0.7, 0.35, 0.35)
		var p = part
		var cid = car.id
		btn_remove.pressed.connect(func():
			GameState.remove_cnc_part_from_car(cid, p)
			get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn")
		)
		row.add_child(btn_remove)

	return panel


# ─── Column C: Building Info + Blueprints ────────────────────────────────────
func _build_info_column(parent: VBoxContainer) -> void:
	var building = GameState.campus_buildings.get("CNC Parts Plant", {})
	var level    = building.get("level", 1)
	var maint    = GameState.get_building_maintenance(building)
	var inc      = GameState.get_building_income(building)
	var effects  = building.get("effects", "")

	parent.add_child(_section_header("BUILDING INFO", Color(0.55, 0.55, 0.55)))

	var info_panel = _make_panel(Color(0.08, 0.10, 0.12))
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 6)
	info_panel.add_child(info_vbox)
	parent.add_child(info_panel)

	for row_data in [
		["Level",       "%d / %d" % [level, building.get("max_level", 10)]],
		["Maintenance", "CR %s/wk" % _fmt(maint)],
		["Income",      "CR %s/wk" % _fmt(inc) if inc > 0 else "—"],
	]:
		info_vbox.add_child(_stat_row(row_data[0], row_data[1]))

	if effects != "":
		info_vbox.add_child(_hsep())
		var lbl_fx = Label.new()
		lbl_fx.text = effects
		lbl_fx.add_theme_font_size_override("font_size", 11)
		lbl_fx.modulate = Color(0.6, 0.85, 1.0)
		lbl_fx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(lbl_fx)

	parent.add_child(_hsep())

	# ── Available Blueprints ───────────────────────────────────────────────────
	parent.add_child(_section_header("AVAILABLE BLUEPRINTS", Color(0.45, 0.75, 1.0)))

	var all_parts = ["Aero", "Engine", "Chassis", "Gearbox", "Brakes", "Suspension"]
	for part in all_parts:
		var has_bp  = GameState.has_blueprint(part)
		var in_prod = false
		for job in GameState.cnc_production_queue:
			if job["part"] == part: in_prod = true; break
		var in_inv  = GameState.cnc_parts_inventory.get(part, 0) > 0

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		parent.add_child(row)

		var lbl_icon = Label.new()
		if has_bp:
			lbl_icon.text = "✅" if not in_prod else "⚙"
		else:
			lbl_icon.text = "🔒"
		lbl_icon.add_theme_font_size_override("font_size", 12)
		row.add_child(lbl_icon)

		var lbl_p = Label.new()
		lbl_p.text = part
		lbl_p.add_theme_font_size_override("font_size", 12)
		lbl_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_p.add_theme_color_override("font_color",
			PART_COLORS.get(part, Color.WHITE) if has_bp else Color(0.45, 0.45, 0.45))
		row.add_child(lbl_p)

		if in_inv:
			var lbl_stk = Label.new()
			lbl_stk.text = "×%d" % GameState.cnc_parts_inventory.get(part, 0)
			lbl_stk.add_theme_font_size_override("font_size", 12)
			lbl_stk.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
			row.add_child(lbl_stk)
		elif not has_bp:
			var lbl_rnd = Label.new()
			lbl_rnd.text = "R&D"
			lbl_rnd.add_theme_font_size_override("font_size", 10)
			lbl_rnd.modulate = Color(0.45, 0.45, 0.45)
			row.add_child(lbl_rnd)

	parent.add_child(_hsep())

	# ── R&D bonus summary ──────────────────────────────────────────────────────
	parent.add_child(_section_header("R&D PERFORMANCE BONUSES", Color(0.5, 0.85, 0.5)))
	var bonus_panel = _make_panel(Color(0.07, 0.10, 0.09))
	var bvbox = VBoxContainer.new()
	bvbox.add_theme_constant_override("separation", 5)
	bonus_panel.add_child(bvbox)
	parent.add_child(bonus_panel)

	var effects_map = {
		"aero_perf":    "Aero  perf",
		"engine_perf":  "Engine perf",
		"chassis_perf": "Chassis perf",
		"car_top_speed":"Top speed",
		"car_cornering_grip": "Cornering",
		"car_baseline_perf":  "Perf index",
	}
	var has_any = false
	for key in effects_map:
		var val = GameState.get_rnd_bonus(key)
		if val <= 0.0: continue
		has_any = true
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		bvbox.add_child(row)
		var lbl_k = Label.new()
		lbl_k.text = effects_map[key]
		lbl_k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_k.add_theme_font_size_override("font_size", 11)
		lbl_k.modulate = Color(0.6, 0.6, 0.6)
		row.add_child(lbl_k)
		var lbl_v = Label.new()
		# Format depending on unit
		if key == "car_top_speed":
			lbl_v.text = "+%.0f km/h" % val
		elif key in ["car_acceleration", "car_deceleration"]:
			lbl_v.text = "+%.1f m/s²" % val
		elif key == "car_baseline_perf":
			lbl_v.text = "+%.1f pts" % val
		else:
			lbl_v.text = "+%.0f%%" % (val * 100.0)
		lbl_v.add_theme_font_size_override("font_size", 11)
		lbl_v.add_theme_color_override("font_color", Color(0.4, 0.88, 0.4))
		row.add_child(lbl_v)

	if not has_any:
		var lbl_no = Label.new()
		lbl_no.text = "No bonuses yet.\nComplete R&D tasks to gain them."
		lbl_no.add_theme_font_size_override("font_size", 11)
		lbl_no.modulate = Color(0.45, 0.45, 0.45)
		lbl_no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bvbox.add_child(lbl_no)

	# Overall sim lap bonus
	var sim_bonus = GameState.get_sim_lap_bonus() if GameState.has_method("get_sim_lap_bonus") else 0.0
	if sim_bonus > 0.0:
		bvbox.add_child(_hsep())
		var row_sim = HBoxContainer.new()
		row_sim.add_theme_constant_override("separation", 6)
		bvbox.add_child(row_sim)
		var lbl_sk = Label.new()
		lbl_sk.text = "Sim lap bonus"
		lbl_sk.add_theme_font_size_override("font_size", 11)
		lbl_sk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_sk.modulate = Color(0.3, 0.85, 0.6)
		row_sim.add_child(lbl_sk)
		var lbl_sv = Label.new()
		lbl_sv.text = "+%.1f%%" % (sim_bonus * 100.0)
		lbl_sv.add_theme_font_size_override("font_size", 11)
		lbl_sv.add_theme_color_override("font_color", Color(0.3, 0.9, 0.55))
		row_sim.add_child(lbl_sv)


# ─── Helpers ──────────────────────────────────────────────────────────────────
func _get_part_cost_info(part: String, champ_id: String) -> Dictionary:
	var cnc = GameState.CNC_DATA.get(champ_id, GameState.CNC_DATA.get("C-001", {}))
	var base_cost = cnc.get("base_total_cost", 10000)
	const PART_COST_RATIO = {"Aero":0.20,"Engine":0.35,"Chassis":0.25,
		"Gearbox":0.08,"Brakes":0.06,"Suspension":0.06}
	const PART_TIME_RATIO = {"Aero":0.4,"Engine":0.6,"Chassis":0.5,
		"Gearbox":0.25,"Brakes":0.2,"Suspension":0.25}
	var cost  = int(base_cost * PART_COST_RATIO.get(part, 0.10))
	var weeks = max(1, int(cnc.get("design_weeks", 4) * PART_TIME_RATIO.get(part, 0.3)))
	return {"cost": cost, "weeks": weeks}

func _section_header(text: String, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _hsep() -> HSeparator:
	return HSeparator.new()

func _make_panel(bg: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 3; style.border_width_right  = 1
	style.border_width_top  = 1; style.border_width_bottom = 1
	style.border_color = Color(0.22, 0.28, 0.36)
	style.corner_radius_top_left    = 4; style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	style.content_margin_left  = 10; style.content_margin_right  = 10
	style.content_margin_top   = 8;  style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _stat_row(label: String, value: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	var l = Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(120, 0)
	l.add_theme_font_size_override("font_size", 12)
	l.modulate = Color(0.55, 0.55, 0.55)
	row.add_child(l)
	var v = Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 12)
	row.add_child(v)
	return row

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.0fK" % (n / 1000.0)
	return str(n)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")
