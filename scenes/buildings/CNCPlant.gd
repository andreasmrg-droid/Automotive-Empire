extends Control
## Version: S35.13 — Championship tabs are now a 2D GRID (disciplines as rows in principle
##   order GP…GK, tiers across each row), replacing the horizontal scrolling strip.
## Version: S35.12b — Columns wrapped in vertical ScrollContainers (tall content scrolls instead
##   of running off-screen); default championship tab = first in principle order (GP1), matching
##   the Studio.
## Version: S35.12 — Tabbed multi-championship CNC + current-season (model b) rework:
##   • Scrollable championship tab strip (all 21 champs, shared GP1…GK registry order); each
##     screen shows ONE championship.
##   • BLUEPRINT OWNERSHIP panel scoped to the selected champ; next-season approved parts now
##     read "🔒 S{n} (next season)" instead of the misleading "ready to mfg".
##   • Manufacture list shows only the selected champ's CURRENT-season approved blueprints.
##   • Build Whole Car: always shown for the selected champ, gated on all 6 CURRENT-season part
##     blueprints; greyed with a tooltip ("you need all 6 part blueprints") until then.
## Version: S35.11 — Fixed the body overflowing off-screen (col_d "BLUEPRINT OWNERSHIP"
##   clipped off the right). The 4-column body had col_c/col_d at fixed custom_minimum_size
##   (240/200) while col_a/col_b were unbounded expand-fill, and the WRA-approved card's long
##   blueprint-name label was a single unwrapped line — together summing past the 1920 design
##   width with no horizontal scroll. Now all four columns are expand-fill with stretch ratios
##   (A 1.5, B 1.3, C/D 1.0) + small min floors, and the approved-card name label wraps, so
##   width is shared proportionally and no column/label can force the body past the viewport.
## --- S31.1 — Bug 7: manufacture cards now show the blueprint's target Season; a
##   future-season blueprint is shown locked with the Start Manufacturing button disabled
##   (reinforces the RnDEngine S31.1 season gate). New strings localized (cnc_bp_season*).
## --- S30.5 — Phase 2 "Build Whole Car": one-pass build section at the top of the
##   MANUFACTURE PARTS column. Enabled per registered championship with no car yet once all
##   6 blueprints are WRA-approved; queues all 6 jobs + creates the in-build Car via
##   GameState.build_whole_car. New strings localized (cnc_bwc_* in Locale.gd S30.5);
##   pre-existing hardcoded strings in this file left for the deferred full sweep (GDD §16).
## --- S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## --- S28.3 — Production queue is slot-aware: shows slot count, marks QUEUED jobs, and
##   computes slot-aware ETAs (issue 4).
## --- S17.2 — Blueprint ownership panel added (col D); INSTALLED ON CARS uses get_installed_parts_for_car.
## CNC Parts Plant
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
	## S35.12 — default the championship tab to the first in the shared principle order (GP1…GK),
	## consistent with the R&D Studio, rather than activation order.
	if _selected_champ_id == "":
		var order = GameState.championship_tab_order()
		_selected_champ_id = order[0] if not order.is_empty() else "C-001"
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
	lbl_title.add_theme_font_size_override("font_size", 42)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	# Blueprint count badge — show WRA-approved (ready to manufacture)
	var bp_count = GameState.wra_approved_blueprints.size()
	var lbl_bp = Label.new()
	lbl_bp.text = "✅ %d WRA Approved" % bp_count if bp_count > 0 else "📋 No approved blueprints"
	lbl_bp.add_theme_font_size_override("font_size", 26)
	lbl_bp.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4) if bp_count > 0 else Color(0.45, 0.45, 0.45))
	header.add_child(lbl_bp)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(90, 34)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)

	root.add_child(_hsep())

	## S35.12 — championship tab strip (scrollable; all 21 championships, ordered by the
	## shared registry-driven order GP1…GK). Each screen now shows ONE championship at a time
	## so a multi-championship player isn't faced with every champ stacked vertically.
	root.add_child(_build_champ_tab_strip())
	root.add_child(_hsep())

	# ── Guard: building must be built ─────────────────────────────────────────
	if not building.get("built", false):
		var warn = Label.new()
		warn.text = "⚠  CNC Parts Plant not built.\nBuild it on Campus to manufacture parts."
		warn.modulate = Color(1.0, 0.55, 0.2)
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warn.add_theme_font_size_override("font_size", 28)
		root.add_child(warn)
		return

	# ── Four-column body (S35.11: responsive) ──────────────────────────────────
	## Previously col_c/col_d had fixed custom_minimum_size (240/200) while col_a/col_b were
	## unbounded expand-fill. With no horizontal scroll on a 1920 design (aspect=expand), the
	## two fixed columns + the action columns' unwrapped long labels summed past the viewport
	## and clipped col_d ("BLUEPRINT OWNERSHIP") off the right edge. Now ALL four are
	## expand-fill with stretch ratios + small min floors, so width is shared proportionally
	## and no column can force the body wider than the screen. Labels inside wrap (see column
	## builders) so content can't reintroduce a hidden minimum.
	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	## S35.12 — each column is now a vertical ScrollContainer wrapping its content VBox, so a
	## column with many cards (e.g. several manufacture cards) scrolls within the viewport
	## instead of running off the bottom of the screen.
	# Column A — WRA Approved Blueprints → manufacture (action; widest)
	var col_a = _make_scroll_column(1.5, 220)
	body.add_child(col_a[0])
	_build_wra_blueprints_column(col_a[1])

	# Column B — Inventory + assign to car (action; wide)
	var col_b = _make_scroll_column(1.3, 200)
	body.add_child(col_b[0])
	_build_inventory_column(col_b[1])

	# Column C — Building info + production queue (reference)
	var col_c = _make_scroll_column(1.0, 190)
	body.add_child(col_c[0])
	_build_info_column(col_c[1])

	# Column D — Blueprint ownership grid (reference)
	var col_d = _make_scroll_column(1.0, 180)
	body.add_child(col_d[0])
	_build_blueprint_ownership_column(col_d[1])


func _build_queue_card(job: Dictionary, idx: int = 0, slots: int = 1) -> PanelContainer:
	var pct = 1.0 - float(job["weeks_remaining"]) / float(job["weeks_total"])
	var part = job["part"]
	## S28.3 (issue 4): jobs at index >= slots are QUEUED (waiting for a free slot).
	var is_queued = idx >= slots
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
	lbl_p.add_theme_font_size_override("font_size", 26)
	lbl_p.add_theme_color_override("font_color", PART_COLORS.get(part, Color.WHITE))
	lbl_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(lbl_p)

	var lbl_wks = Label.new()
	if is_queued:
		lbl_wks.text = "QUEUED"
		lbl_wks.modulate = Color(1.0, 0.7, 0.3)
	else:
		lbl_wks.text = "%d wks left" % job["weeks_remaining"]
		lbl_wks.modulate = Color(0.6, 0.6, 0.6)
	lbl_wks.add_theme_font_size_override("font_size", 22)
	row1.add_child(lbl_wks)

	var bar = ProgressBar.new()
	bar.min_value = 0; bar.max_value = 100
	bar.value = 0.0 if is_queued else pct * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 13)
	vbox.add_child(bar)

	var lbl_eta = Label.new()
	## ETA: active jobs finish in weeks_remaining. Queued jobs must wait for the job
	## currently occupying their future slot — approximate as this job's own duration
	## plus the remaining time of the active job `slots` positions ahead.
	var wait = job["weeks_remaining"]
	if is_queued:
		var ahead_idx = idx - slots
		var ahead = GameState.cnc_production_queue[ahead_idx] if ahead_idx < GameState.cnc_production_queue.size() else null
		var ahead_wait = ahead["weeks_remaining"] if ahead else 0
		wait = ahead_wait + job["weeks_total"]
	var eta_week = GameState.current_week + wait
	lbl_eta.text = ("Starts after slot frees · ~Wk %d" % eta_week) if is_queued else \
		("Est. ready: Season %d, Week %d" % [GameState.current_season, eta_week])
	lbl_eta.add_theme_font_size_override("font_size", 20)
	lbl_eta.modulate = Color(0.5, 0.5, 0.5)
	vbox.add_child(lbl_eta)

	return panel


# ─── Column B: Inventory + Assign to Car ─────────────────────────────────────
func _build_inventory_column(parent: VBoxContainer) -> void:
	parent.add_child(_section_header("PARTS INVENTORY", Color(1.0, 0.8, 0.0)))

	var inventory = GameState.cnc_parts_inventory
	if inventory.is_empty():
		var lbl = Label.new()
		lbl.text = "No parts in stock.\nManufacture parts using WRA-approved blueprints above."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(lbl)
	else:
		for inv_key in inventory:
			var item = inventory[inv_key]
			var qty: int = item.get("quantity", 0) if item is Dictionary else int(item)
			if qty <= 0: continue
			parent.add_child(_build_inventory_card(inv_key, item))

	parent.add_child(_hsep())

	# ── Installed parts per car ────────────────────────────────────────────────
	parent.add_child(_section_header("INSTALLED ON CARS", Color(0.5, 0.9, 0.5)))

	var any_installed = false
	for car in GameState.player_team_cars:
		var installed = GameState.get_installed_parts_for_car(car.id)
		if installed.is_empty(): continue
		any_installed = true
		var car_name = car.car_name if car.car_name != "" else "Car %d" % car.car_number
		parent.add_child(_build_installed_car_panel(car, car_name, installed))

	if not any_installed:
		var lbl = Label.new()
		lbl.text = "No CNC parts installed on any car yet."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(lbl)


func _build_inventory_card(inv_key: String, item) -> PanelContainer:
	## item can be a Dictionary (new format) or an int (legacy)
	var qty:  int   = item.get("quantity",    0)  if item is Dictionary else int(item)
	var rel:  float = item.get("reliability", 60.0) if item is Dictionary else 60.0
	var qual: float = item.get("quality",     1.0)  if item is Dictionary else 1.0
	var part: String = item.get("part",       inv_key.split("|")[1] if "|" in inv_key else inv_key) if item is Dictionary else inv_key
	var pcode: String = item.get("part_code", "") if item is Dictionary else ""
	var champ_id: String = item.get("championship_id", "") if item is Dictionary else ""

	var panel = _make_panel(Color(0.08, 0.13, 0.09))
	var style = panel.get_theme_stylebox("panel")
	style.border_color = PART_COLORS.get(part, Color.WHITE).darkened(0.3)
	style.border_width_left = 4

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	var lbl_part = Label.new()
	lbl_part.text = part
	lbl_part.add_theme_font_size_override("font_size", 26)
	lbl_part.add_theme_color_override("font_color", PART_COLORS.get(part, Color.WHITE))
	lbl_part.custom_minimum_size = Vector2(90, 0)
	row.add_child(lbl_part)

	var lbl_qty = Label.new()
	lbl_qty.text = "× %d" % qty
	lbl_qty.add_theme_font_size_override("font_size", 26)
	lbl_qty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl_qty)

	var lbl_stats = Label.new()
	lbl_stats.text = "Rel:%.0f%%  Qual:%.2f×" % [rel, qual]
	lbl_stats.add_theme_font_size_override("font_size", 22)
	lbl_stats.modulate = Color(0.6, 0.6, 0.6)
	row.add_child(lbl_stats)

	## Install-to-car buttons
	var cars_for_assignment = GameState.player_team_cars.filter(
		func(c): return c.championship_id == champ_id or champ_id == "")
	if cars_for_assignment.is_empty():
		var lbl_no = Label.new()
		lbl_no.text = "No matching cars"
		lbl_no.add_theme_font_size_override("font_size", 20)
		lbl_no.modulate = Color(0.5, 0.5, 0.5)
		vbox.add_child(lbl_no)
	else:
		var btn_row = HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 6)
		vbox.add_child(btn_row)
		for car in cars_for_assignment:
			var cname = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			var btn = Button.new()
			btn.text = "Install → %s" % cname.left(14)
			btn.custom_minimum_size = Vector2(110, 26)
			btn.add_theme_font_size_override("font_size", 20)
			var cid_car = car.id
			var cid_champ = car.championship_id
			var pc = pcode
			btn.pressed.connect(func():
				GameState.install_part_on_car(cid_car, cid_champ, pc)
				get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn")
			)
			btn_row.add_child(btn)

	return panel


func _build_installed_car_panel(car, car_name: String, installed: Dictionary) -> PanelContainer:
	var panel = _make_panel(Color(0.07, 0.12, 0.09))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	var lbl_car = Label.new()
	lbl_car.text = "🏎 %s" % car_name
	lbl_car.add_theme_font_size_override("font_size", 24)
	lbl_car.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(lbl_car)

	# CNC bonus display
	var bonus = GameState.get_cnc_part_bonus(car.id)
	var lbl_bonus = Label.new()
	lbl_bonus.text = "⚡ CNC bonus: +%.1f%% lap time" % (bonus * 100.0)
	lbl_bonus.add_theme_font_size_override("font_size", 22)
	lbl_bonus.add_theme_color_override("font_color", Color(0.4, 0.88, 0.5))
	vbox.add_child(lbl_bonus)

	for pcode in installed:
		var pd = installed[pcode]
		var rel:  float = pd.get("reliability", 60.0) if pd is Dictionary else 60.0
		var qual: float = pd.get("quality",     1.0)  if pd is Dictionary else 1.0
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var lbl_p = Label.new()
		lbl_p.text = "  %s  Rel:%.0f%%  Qual:%.2f×" % [pcode, rel, qual]
		lbl_p.add_theme_font_size_override("font_size", 22)
		lbl_p.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
		lbl_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl_p)

		var btn_remove = Button.new()
		btn_remove.text = "Remove"
		btn_remove.custom_minimum_size = Vector2(65, 22)
		btn_remove.add_theme_font_size_override("font_size", 20)
		btn_remove.modulate = Color(0.7, 0.35, 0.35)
		var pc = pcode
		var cid = car.id
		btn_remove.pressed.connect(func():
			GameState.remove_part_from_car(cid, pc)
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
		lbl_fx.add_theme_font_size_override("font_size", 22)
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
		var in_inv = false
		for inv_key in GameState.cnc_parts_inventory:
			var item = GameState.cnc_parts_inventory[inv_key]
			var item_part = item.get("part", "") if item is Dictionary else inv_key
			var qty = item.get("quantity", 0) if item is Dictionary else int(item)
			if item_part == part and qty > 0:
				in_inv = true; break

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		parent.add_child(row)

		var lbl_icon = Label.new()
		if has_bp:
			lbl_icon.text = "✅" if not in_prod else "⚙"
		else:
			lbl_icon.text = "🔒"
		lbl_icon.add_theme_font_size_override("font_size", 24)
		row.add_child(lbl_icon)

		var lbl_p = Label.new()
		lbl_p.text = part
		lbl_p.add_theme_font_size_override("font_size", 24)
		lbl_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_p.add_theme_color_override("font_color",
			PART_COLORS.get(part, Color.WHITE) if has_bp else Color(0.45, 0.45, 0.45))
		row.add_child(lbl_p)

		if in_inv:
			var lbl_stk = Label.new()
			## Sum quantity across all inv keys matching this part name
			var total_qty = 0
			for inv_key in GameState.cnc_parts_inventory:
				var item = GameState.cnc_parts_inventory[inv_key]
				var item_part = item.get("part", "") if item is Dictionary else inv_key
				if item_part == part:
					total_qty += item.get("quantity", 0) if item is Dictionary else int(item)
			lbl_stk.text = "×%d" % total_qty
			lbl_stk.add_theme_font_size_override("font_size", 24)
			lbl_stk.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
			row.add_child(lbl_stk)
		elif not has_bp:
			var lbl_rnd = Label.new()
			lbl_rnd.text = "R&D"
			lbl_rnd.add_theme_font_size_override("font_size", 20)
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
		lbl_k.add_theme_font_size_override("font_size", 22)
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
		lbl_v.add_theme_font_size_override("font_size", 22)
		lbl_v.add_theme_color_override("font_color", Color(0.4, 0.88, 0.4))
		row.add_child(lbl_v)

	if not has_any:
		var lbl_no = Label.new()
		lbl_no.text = "No bonuses yet.\nComplete R&D tasks to gain them."
		lbl_no.add_theme_font_size_override("font_size", 22)
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
		lbl_sk.add_theme_font_size_override("font_size", 22)
		lbl_sk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_sk.modulate = Color(0.3, 0.85, 0.6)
		row_sim.add_child(lbl_sk)
		var lbl_sv = Label.new()
		lbl_sv.text = "+%.1f%%" % (sim_bonus * 100.0)
		lbl_sv.add_theme_font_size_override("font_size", 22)
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
	lbl.add_theme_font_size_override("font_size", 26)
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
	l.add_theme_font_size_override("font_size", 24)
	l.modulate = Color(0.55, 0.55, 0.55)
	row.add_child(l)
	var v = Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 24)
	row.add_child(v)
	return row

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.0fK" % (n / 1000.0)
	return str(n)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

## ═══════════════════════════════════════════════════════════════════════════
## S35.12 — Returns [ScrollContainer, inner VBox] for a body column: vertical scroll, expand-fill
## width with a stretch ratio + min-width floor (responsive columns), so tall content scrolls.
func _make_scroll_column(stretch: float, min_w: int) -> Array:
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = stretch
	scroll.custom_minimum_size = Vector2(min_w, 120)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.clip_contents = true
	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 10)
	scroll.add_child(inner)
	return [scroll, inner]

## S35.13 — Championship tab GRID: one ROW per discipline (principle order GP…GK), tiers laid
## out horizontally within each row (pinnacle → entry). Clicking a tab re-renders the screen
## scoped to that championship. Replaces the old single horizontal scrolling strip.
func _build_champ_tab_strip() -> Control:
	var grid_box = VBoxContainer.new()
	grid_box.add_theme_constant_override("separation", 3)
	grid_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for drow in GameState.championship_tab_grid():
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		grid_box.add_child(row)
		for cid in drow["champ_ids"]:
			var reg = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
			var btn = Button.new()
			btn.text = reg.get("name", cid)
			btn.add_theme_font_size_override("font_size", 18)
			btn.custom_minimum_size = Vector2(0, 30)
			var is_sel = (cid == _selected_champ_id)
			btn.disabled = is_sel
			btn.modulate = Color(0.55, 0.8, 1.0) if is_sel else Color(0.8, 0.8, 0.8)
			var picked = cid
			btn.pressed.connect(func():
				_selected_champ_id = picked
				_rebuild())
			row.add_child(btn)
	return grid_box

## S35.12 — Rebuild the whole screen (clears children, re-runs _build_ui) after a tab change.
func _rebuild() -> void:
	for c in get_children(): c.queue_free()
	_build_ui()

## S17.2 — BLUEPRINT OWNERSHIP PANEL
## Shows which blueprints are owned, in CNC queue, or manufactured.
## ═══════════════════════════════════════════════════════════════════════════

func _build_blueprint_ownership_column(parent: VBoxContainer) -> void:
	parent.add_child(_section_header("BLUEPRINT OWNERSHIP", Color(0.7, 0.8, 1.0)))

	var legend = Label.new()
	legend.text = "🔩 installed  📦 warehouse  ✅ ready to mfg (this season)  🔒 next season  🔧 owned  ⬜ none"
	legend.add_theme_font_size_override("font_size", 18)
	legend.modulate = Color(0.5, 0.5, 0.5)
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(legend)

	var cid = _selected_champ_id
	var reg = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
	var lbl_c = Label.new()
	lbl_c.text = reg.get("name", cid)
	lbl_c.add_theme_font_size_override("font_size", 22)
	lbl_c.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	parent.add_child(lbl_c)

	const PCODES = ["AER","ENG","GRB","SUS","BRK","CHS"]
	const PCODE_TO_PART = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}

	## Approved blueprints for this champ, split by season relative to current.
	## S35.12 — the CNC builds CURRENT-season blueprints only. A next-season blueprint is
	## shown as locked with its target season, NOT "ready to mfg" (that was misleading — a
	## next-season part can't be built until that season becomes current).
	var ready_now: Dictionary = {}   ## pcode → true (approved AND current-season)
	var next_season: Dictionary = {} ## pcode → target season int (approved but future)
	for app in GameState.wra_approved_blueprints:
		var bp_id = app.get("blueprint_id", "")
		var bp = GameState.known_blueprints.get(bp_id, {})
		if bp.get("championship_id", "") != cid: continue
		var pcode = bp.get("part_code", "")
		if pcode == "": pcode = GameState._part_name_to_pcode(bp.get("part", ""))
		if pcode == "": continue
		var bp_season = int(bp.get("season", GameState.current_season))
		if bp_season <= GameState.current_season:
			ready_now[pcode] = true
		else:
			if not pcode in next_season or bp_season < next_season[pcode]:
				next_season[pcode] = bp_season

	var warehouse_pcodes: Dictionary = {}
	for inv_key in GameState.cnc_parts_inventory:
		var item = GameState.cnc_parts_inventory[inv_key]
		if not item is Dictionary: continue
		if item.get("championship_id","") != cid: continue
		if item.get("quantity",0) <= 0: continue
		var wp = item.get("part_code","")
		if wp == "": wp = GameState._part_name_to_pcode(item.get("part",""))
		if wp != "": warehouse_pcodes[wp] = true

	var installed_pcodes: Dictionary = {}
	for car in GameState.player_team_cars:
		if car.championship_id != cid: continue
		var inst = GameState.get_installed_parts_for_car(car.id)
		for pc in inst: installed_pcodes[pc] = true

	for pcode in PCODES:
		var part_name = PCODE_TO_PART.get(pcode, pcode)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		parent.add_child(row)

		var lbl_p = Label.new()
		lbl_p.text = pcode
		lbl_p.add_theme_font_size_override("font_size", 20)
		lbl_p.custom_minimum_size = Vector2(32, 0)
		lbl_p.add_theme_color_override("font_color", PART_COLORS.get(part_name, Color(0.6,0.6,0.6)))
		row.add_child(lbl_p)

		var status = Label.new()
		status.add_theme_font_size_override("font_size", 22)
		status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if pcode in installed_pcodes:
			status.text = "🔩 installed"
			status.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		elif pcode in warehouse_pcodes:
			status.text = "📦 in warehouse"
			status.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
		elif pcode in ready_now:
			status.text = "✅ ready to mfg"
			status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		elif pcode in next_season:
			status.text = "🔒 S%d (next season)" % next_season[pcode]
			status.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
		else:
			var has_bp = false
			for bp_id in GameState.known_blueprints:
				var bp = GameState.known_blueprints[bp_id]
				if bp.get("championship_id","") == cid \
						and GameState._part_name_to_pcode(bp.get("part","")) == pcode:
					has_bp = true; break
			if has_bp:
				status.text = "🔧 bp owned"
				status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.4))
			else:
				status.text = "⬜ none"
				status.modulate = Color(0.4, 0.4, 0.4)
		row.add_child(status)

	parent.add_child(_hsep())

## ═══════════════════════════════════════════════════════════════════════════
## S15 — WRA APPROVED BLUEPRINTS COLUMN
## ═══════════════════════════════════════════════════════════════════════════

## Phase 2 — one-pass "Build Whole Car" section. Shows one card per registered
## championship the player has no car for yet. Enabled once all 6 blueprints are
## WRA-approved; queues all 6 jobs and creates the in-build Car in a single action.
func _build_whole_car_section(parent: VBoxContainer) -> void:
	## S35.12 — show the Build-Whole-Car card for the SELECTED championship only (tabbed UI).
	## Always shown (not just when the player has no car) so a new season's car can be built.
	parent.add_child(_section_header(Locale.t("cnc_bwc_header"), Color(0.3, 0.7, 1.0)))
	var intro = Label.new()
	intro.text = Locale.t("cnc_bwc_intro")
	intro.add_theme_font_size_override("font_size", 20)
	intro.modulate = Color(0.5, 0.5, 0.5)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(intro)
	parent.add_child(_build_whole_car_card(_selected_champ_id))
	parent.add_child(_hsep())

func _build_whole_car_card(champ_id: String) -> PanelContainer:
	var reg        = GameState.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var champ_name = reg.get("name", champ_id)
	var can_build  = GameState.can_build_whole_car(champ_id)
	var garage_full = GameState.player_team_cars.size() >= GameState.get_max_cars()

	var panel = _make_panel(Color(0.09, 0.11, 0.16))
	var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = Color(0.3, 0.7, 1.0) if can_build else Color(0.5, 0.5, 0.5)
		style.border_width_left = 3
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	panel.add_child(vb)

	var ln = Label.new()
	ln.text = "🏗 Build Whole Car — %s" % champ_name
	ln.add_theme_font_size_override("font_size", 24)
	ln.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vb.add_child(ln)

	var status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	## S35.12 — count CURRENT-season approved part blueprints (model b). Need all 6 to build.
	var approved = GameState._approved_car_blueprints(champ_id)
	var have = approved.size()
	if can_build:
		var dwk = GameState.get_build_whole_car_delivery_week(champ_id)
		var cost = GameState.get_build_whole_car_cost(champ_id)
		status.text = Locale.tf("cnc_bwc_ready", [dwk, _fmt(cost)])
		status.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	else:
		status.text = Locale.tf("cnc_bwc_need_all6", [have])
		status.modulate = Color(0.8, 0.6, 0.3)
	vb.add_child(status)

	var btn = Button.new()
	btn.text = Locale.t("cnc_bwc_btn")
	btn.custom_minimum_size = Vector2(0, 32)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 24)
	btn.disabled = not can_build or garage_full
	## S35.12 — greyed-out button carries a tooltip explaining why (your #2).
	if not can_build:
		btn.tooltip_text = Locale.t("cnc_bwc_need_all6_tip")
		btn.modulate = Color(0.5, 0.5, 0.5)
	if garage_full:
		btn.tooltip_text = Locale.t("cnc_bwc_garage_full")
		var gf = Label.new()
		gf.text = Locale.t("cnc_bwc_garage_full")
		gf.add_theme_font_size_override("font_size", 20)
		gf.modulate = Color(1.0, 0.5, 0.2)
		gf.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(gf)
	var _cid = champ_id
	btn.pressed.connect(func(): _on_build_whole_car(_cid))
	vb.add_child(btn)

	return panel

func _on_build_whole_car(champ_id: String) -> void:
	if GameState.build_whole_car(champ_id):
		get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn")

func _build_wra_blueprints_column(parent: VBoxContainer) -> void:
	_build_whole_car_section(parent)
	parent.add_child(_section_header("MANUFACTURE PARTS", Color(0.4, 0.9, 0.4)))

	var lbl_flow = Label.new()
	lbl_flow.text = "R&D → Send to WRA (HQ) → Approved here → Manufacture → Warehouse → Garage"
	lbl_flow.add_theme_font_size_override("font_size", 20)
	lbl_flow.modulate = Color(0.5, 0.5, 0.5)
	lbl_flow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lbl_flow)

	## Production queue summary
	if not GameState.cnc_production_queue.is_empty():
		var slots = GameState.get_cnc_slots()
		var q_lbl = Label.new()
		q_lbl.text = "IN PRODUCTION:   (%d slot%s)" % [slots, "s" if slots != 1 else ""]
		q_lbl.add_theme_font_size_override("font_size", 22)
		q_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		parent.add_child(q_lbl)
		var qi = 0
		for job in GameState.cnc_production_queue:
			parent.add_child(_build_queue_card(job, qi, slots))
			qi += 1
		parent.add_child(_hsep())

	parent.add_child(_section_header("WRA APPROVED — READY TO MANUFACTURE", Color(0.4, 0.9, 0.4)))

	var in_production = []
	for job in GameState.cnc_production_queue:
		in_production.append(job.get("blueprint_id", ""))

	if GameState.wra_approved_blueprints.is_empty():
		var e = Label.new()
		e.text = "No approved blueprints yet.\n\n1. Research a part in R&D Studio\n2. Submit blueprint to WRA Office in HQ\n3. Return here once approved to manufacture"
		e.modulate = Color(0.5, 0.5, 0.5)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.add_theme_font_size_override("font_size", 24)
		parent.add_child(e)
		var btn_hq = Button.new()
		btn_hq.text = "🏛 Go to WRA Office in HQ →"
		btn_hq.custom_minimum_size = Vector2(0, 30)
		btn_hq.pressed.connect(func():
			GameState.pending_hq_tab = "wra_office"
			get_tree().change_scene_to_file("res://scenes/buildings/HQ.tscn"))
		parent.add_child(btn_hq)
		return

	var preselected = GameState.pending_cnc_blueprint
	GameState.pending_cnc_blueprint = ""

	## S35.12 — show only the SELECTED championship's CURRENT-season approved blueprints. The
	## CNC builds current-season only (model b); next-season approvals appear in the BLUEPRINT
	## OWNERSHIP panel as "🔒 next season" and become manufacturable when that season arrives.
	var manufacturable: Array = []
	for app in GameState.wra_approved_blueprints:
		if app.get("championship_id","") != _selected_champ_id: continue
		var b = GameState.known_blueprints.get(app.blueprint_id, {})
		if int(b.get("season", GameState.current_season)) > GameState.current_season: continue
		manufacturable.append(app)

	if manufacturable.is_empty():
		var none = Label.new()
		none.text = "No current-season blueprints approved for this championship yet.\nNext-season blueprints will become available when that season begins."
		none.modulate = Color(0.5, 0.5, 0.5)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.add_theme_font_size_override("font_size", 22)
		parent.add_child(none)
		return

	for app in manufacturable:
		var bp_id = app.blueprint_id
		var bp = GameState.known_blueprints.get(bp_id, {})
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(app.championship_id, {})
		var already_queued = bp_id in in_production

		var panel = _make_panel(Color(0.08, 0.12, 0.09))
		var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.border_color = Color(0.3, 0.7, 0.45) if not already_queued \
				else Color(0.5, 0.5, 0.5)
			style.border_width_left = 3
		parent.add_child(panel)

		var vb = VBoxContainer.new()
		vb.add_theme_constant_override("separation", 5)
		panel.add_child(vb)

		## Header
		var hdr = HBoxContainer.new()
		hdr.add_theme_constant_override("separation", 6)
		vb.add_child(hdr)

		var ln = Label.new()
		ln.text = "✅ %s [%s]" % [
			bp.get("name", bp_id),
			reg.get("name", app.championship_id)]
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		## S35.11 — wrap: the long blueprint name was a single unwrapped line, forcing col_a's
		## minimum width to the full string and pushing the body past the viewport (clipping
		## col_d). Wrapping lets the responsive column bound the text to its allotted share.
		ln.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ln.add_theme_font_size_override("font_size", 24)
		ln.add_theme_color_override("font_color",
			Color(0.4, 0.9, 0.4) if not already_queued else Color(0.5,0.5,0.5))
		hdr.add_child(ln)

		## Bug 7: show which season this blueprint targets. Bug 8: a future-season
		## blueprint is locked for manufacturing until that season begins.
		var bp_season = int(bp.get("season", GameState.current_season))
		var season_locked = bp_season > GameState.current_season
		var season_badge = Label.new()
		season_badge.add_theme_font_size_override("font_size", 20)
		if season_locked:
			season_badge.text = Locale.tf("cnc_bp_season_locked", [bp_season])
			season_badge.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		else:
			season_badge.text = Locale.tf("cnc_bp_season", [bp_season])
			season_badge.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9))
		hdr.add_child(season_badge)

		if already_queued:
			var lq = Label.new()
			lq.text = "IN QUEUE"
			lq.add_theme_font_size_override("font_size", 20)
			lq.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
			hdr.add_child(lq)
			continue

		## Stats row
		var base_wk = GameState.get_cnc_manufacturing_weeks(bp_id)
		var base_cr = GameState.get_cnc_manufacturing_cr(bp_id, 1)
		var base_rel = GameState.calculate_final_reliability(bp_id)
		var quality = bp.get("quality", 1.0)

		var stats = Label.new()
		stats.text = "CR %s | %dwks | Rel:%.0f%% | Qual:%.2f×" % [
			_fmt(base_cr), base_wk, base_rel, quality]
		stats.add_theme_font_size_override("font_size", 20)
		stats.modulate = Color(0.6, 0.6, 0.6)
		vb.add_child(stats)

		## Controls
		var ctrl = HBoxContainer.new()
		ctrl.add_theme_constant_override("separation", 6)
		vb.add_child(ctrl)

		var qty_lbl = Label.new()
		qty_lbl.text = "Qty:"
		qty_lbl.add_theme_font_size_override("font_size", 22)
		ctrl.add_child(qty_lbl)

		var qty_spin = SpinBox.new()
		qty_spin.min_value = 1; qty_spin.max_value = 20; qty_spin.value = 1
		qty_spin.custom_minimum_size = Vector2(65, 0)
		ctrl.add_child(qty_spin)

		var ecr_lbl = Label.new()
		ecr_lbl.text = "+CR:"
		ecr_lbl.add_theme_font_size_override("font_size", 22)
		ctrl.add_child(ecr_lbl)

		var ecr_spin = SpinBox.new()
		ecr_spin.min_value = 0; ecr_spin.max_value = 200000; ecr_spin.step = 1000
		ecr_spin.value = 0; ecr_spin.custom_minimum_size = Vector2(85, 0)
		ctrl.add_child(ecr_spin)

		var ewk_lbl = Label.new()
		ewk_lbl.text = "+wks:"
		ewk_lbl.add_theme_font_size_override("font_size", 22)
		ctrl.add_child(ewk_lbl)

		var ewk_spin = SpinBox.new()
		ewk_spin.min_value = 0; ewk_spin.max_value = 20; ewk_spin.value = 0
		ewk_spin.custom_minimum_size = Vector2(60, 0)
		ctrl.add_child(ewk_spin)

		## Live preview
		var preview = Label.new()
		preview.add_theme_font_size_override("font_size", 20)
		preview.modulate = Color(0.7, 0.7, 0.7)
		vb.add_child(preview)

		var bid = bp_id
		var update_preview = func():
			var q = int(qty_spin.value)
			var ecr = int(ecr_spin.value)
			var ewk = int(ewk_spin.value)
			var tcr = GameState.get_cnc_manufacturing_cr(bid, q, ecr)
			var twk = GameState.get_cnc_manufacturing_weeks(bid, ewk)
			var rel = GameState.calculate_final_reliability(bid, ecr, ewk)
			preview.text = "Total: CR %s | %dwks | Rel:%.0f%%" % [_fmt(tcr), twk, rel]

		qty_spin.value_changed.connect(func(_v): update_preview.call())
		ecr_spin.value_changed.connect(func(_v): update_preview.call())
		ewk_spin.value_changed.connect(func(_v): update_preview.call())
		update_preview.call()

		var btn = Button.new()
		btn.text = "Start Manufacturing"
		btn.custom_minimum_size = Vector2(150, 30)
		btn.disabled = season_locked
		if season_locked:
			btn.tooltip_text = Locale.tf("cnc_bp_season_locked", [bp_season])
		btn.pressed.connect(func():
			if GameState.start_cnc_job(bid,
					int(qty_spin.value),
					int(ecr_spin.value),
					int(ewk_spin.value)):
				get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn"))
		vb.add_child(btn)

		## Auto-expand if preselected from WRA Office
		if preselected == bp_id:
			pass  ## Already expanded — all controls visible
