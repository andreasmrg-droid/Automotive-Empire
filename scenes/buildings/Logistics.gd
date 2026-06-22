extends Control
## Version: S35.5 — Spare-parts card now shows the LIVING SP price (CR X.XX/unit) and its input
##   cost preview uses get_sp_cost_per_unit() instead of the old hardcoded × 1, matching what
##   buy_spare_parts actually charges (same pattern as the S35.4 fuel-preview fix).
## Version: S35.4 — Fuel cost preview fix. The live "= CR X" preview under the fuel input was
##   hardcoded to (kg × 2) — it didn't match the living per-kg price that buy_fuel actually charges
##   (S35.3). Now uses GameState.get_fuel_cost_per_kg() so the typed-amount preview and the real
##   charge agree (e.g. 100 kg at CR 2.26/kg now previews CR 226, not CR 200). The fuel card header
##   already showed the live rate (S35.3); only the input preview was stale.
## Version: S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## Version: S28.3 — Warehouse shows available CNC parts; section renamed "Available Parts (CNC)".
## --- S28.1 — Removed hardcoded ["C-001"] GK fallback in BUY RACING CAR tab.
##   The buy-car list now reflects the player's real registered set; empty → clear message.
## --- S15.2 — Car indicator uses championship max_cars not garage limit fallback.
## Logistics Center — Tab redesign
## Tabs: STOCKS & CONSUMABLES | PARTS WAREHOUSE | BUY RACING CAR

var sp_input:   LineEdit
var fuel_input: LineEdit
var part_inputs: Dictionary = {}

var _tab_bar:      HBoxContainer
var _tab_content:  PanelContainer
var _active_tab:   int = 0
var _lbl_cr:       Label
var _lbl_sp:       Label
var _lbl_fu:       Label

const DISC_COLORS = {
	"GK":    Color(0.2, 0.8, 0.2), "Rally": Color(0.8, 0.5, 0.1),
	"TC":    Color(0.1, 0.6, 1.0), "OWC":   Color(0.8, 0.2, 0.8),
	"SC":    Color(1.0, 0.2, 0.2), "EPC":   Color(0.1, 0.8, 0.8),
	"GP":    Color(1.0, 0.8, 0.0),
}

# Championships where the car must be designed in-house — no buy button
const OWN_BUILD_CHAMPS = ["C-007","C-008","C-020","C-024"]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right"]: margin.add_theme_constant_override(s, 24)
	for s in ["margin_top","margin_bottom"]:  margin.add_theme_constant_override(s, 16)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	# ── Header ────────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var title = Label.new()
	title.text = "📦 LOGISTICS CENTER"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	# Stock badges in header — stored as vars so _switch_tab can refresh them
	_lbl_cr = Label.new()
	_lbl_sp = Label.new()
	_lbl_fu = Label.new()
	for lbl in [_lbl_cr, _lbl_sp, _lbl_fu]:
		lbl.add_theme_font_size_override("font_size", 28)
		header.add_child(lbl)
	_refresh_header_labels()

	var back_btn = Button.new()
	back_btn.text = "← Back to Campus"
	back_btn.custom_minimum_size = Vector2(150, 38)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	root.add_child(HSeparator.new())

	# ── Tab bar ───────────────────────────────────────────────────────────────
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 4)
	root.add_child(_tab_bar)

	for pair in [
		["🔧⛽  STOCKS & CONSUMABLES", 0],
		["📦  PARTS WAREHOUSE",        1],
		["🏎  BUY RACING CAR",          2],
	]:
		var btn = Button.new()
		btn.text = pair[0]
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 26)
		var idx = pair[1]
		btn.pressed.connect(func(): _switch_tab(idx))
		_tab_bar.add_child(btn)

	# ── Tab content area ──────────────────────────────────────────────────────
	_tab_content = PanelContainer.new()
	_tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ts = StyleBoxFlat.new()
	ts.bg_color = Color(0.08, 0.09, 0.12)
	ts.corner_radius_top_left = 6; ts.corner_radius_top_right = 6
	ts.corner_radius_bottom_left = 6; ts.corner_radius_bottom_right = 6
	ts.content_margin_left = 20; ts.content_margin_right = 20
	ts.content_margin_top = 16; ts.content_margin_bottom = 16
	_tab_content.add_theme_stylebox_override("panel", ts)
	root.add_child(_tab_content)

	_switch_tab(0)

func _refresh_header_labels() -> void:
	if not is_instance_valid(_lbl_cr): return
	var cr_col = Color(0.4,0.9,0.4) if GameState.player_team.balance >= 0 else Color(1.0,0.3,0.3)
	var sp_warn = GameState.spare_parts < GameState.active_championship.sp_per_10_pct_damage
	var fu_warn = GameState.fuel_kg < GameState.active_championship.fuel_per_car_per_race
	_lbl_cr.text = "💰 CR %s" % _fmt(GameState.player_team.balance)
	_lbl_cr.add_theme_color_override("font_color", cr_col)
	_lbl_sp.text = "🔧 SP %d" % GameState.spare_parts
	_lbl_sp.add_theme_color_override("font_color", Color(1.0,0.3,0.3) if sp_warn else Color(1.0,0.8,0.4))
	_lbl_fu.text = "⛽ FU %.0f kg" % GameState.fuel_kg
	_lbl_fu.add_theme_color_override("font_color", Color(1.0,0.3,0.3) if fu_warn else Color(1.0,0.5,0.3))

func _switch_tab(idx: int) -> void:
	_active_tab = idx
	_refresh_header_labels()
	# Update tab button highlight
	var btns = _tab_bar.get_children()
	for i in range(btns.size()):
		btns[i].modulate = Color(1.0, 0.8, 0.3) if i == idx else Color(0.7, 0.7, 0.7)

	# Clear content
	for c in _tab_content.get_children(): c.queue_free()

	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_tab_content.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	scroll.add_child(content)

	match idx:
		0: _build_tab_stocks(content)
		1: _build_tab_warehouse(content)
		2: _build_tab_buy_car(content)

# ═══════════════════════════════════════════════════════════════════════════
# TAB 0: STOCKS & CONSUMABLES
# ═══════════════════════════════════════════════════════════════════════════
func _build_tab_stocks(parent: VBoxContainer) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	parent.add_child(row)

	var cars = GameState.player_team.drivers.size()
	var fuel_per_race = GameState.active_championship.fuel_per_car_per_race
	var sp_per_10     = GameState.active_championship.sp_per_10_pct_damage

	row.add_child(_make_sp_card(sp_per_10))
	row.add_child(_make_fuel_card(fuel_per_race, cars))

func _make_sp_card(sp_per_10: int) -> PanelContainer:
	var panel = _card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	_card_title(vbox, "🔧 Spare Parts")
	_card_info(vbox, "Used for post-race car repairs. %d SP repairs 10%% damage. CR %.2f/unit (live price).\nCurrent stock: %d units" % [sp_per_10, GameState.get_sp_cost_per_unit(), GameState.spare_parts])

	var input_row = HBoxContainer.new(); input_row.add_theme_constant_override("separation", 8)
	vbox.add_child(input_row)
	var il = Label.new(); il.text = "Amount:"; il.add_theme_font_size_override("font_size", 26)
	input_row.add_child(il)
	sp_input = LineEdit.new(); sp_input.placeholder_text = "e.g. 500"
	sp_input.custom_minimum_size = Vector2(140, 32)
	input_row.add_child(sp_input)
	var cost_lbl = Label.new(); cost_lbl.add_theme_font_size_override("font_size", 24)
	cost_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	input_row.add_child(cost_lbl)
	sp_input.text_changed.connect(func(t):
		var a = int(t) if t.is_valid_int() and int(t) > 0 else 0
		## S35.5: live preview matches the living per-unit price buy_spare_parts charges.
		cost_lbl.text = ("= CR %d" % int(round(a * GameState.get_sp_cost_per_unit()))) if a > 0 else "")

	var preset_lbl = Label.new(); preset_lbl.text = "Quick fill:"
	preset_lbl.add_theme_font_size_override("font_size", 24); preset_lbl.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(preset_lbl)
	var preset_row = HBoxContainer.new(); preset_row.add_theme_constant_override("separation", 8)
	vbox.add_child(preset_row)
	for pair in [["1 Repair\n%d SP" % sp_per_10, sp_per_10],
				 ["3 Repairs\n%d SP" % (sp_per_10*3), sp_per_10*3],
				 ["Season\n6000 SP", 6000]]:
		var b = _preset_btn(pair[0])
		var qty = pair[1]
		b.pressed.connect(func(): sp_input.text = str(qty))
		preset_row.add_child(b)

	var buy_btn = Button.new()
	buy_btn.text = "Buy Spare Parts →"
	buy_btn.custom_minimum_size = Vector2(0, 36)
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.add_theme_font_size_override("font_size", 26)
	buy_btn.pressed.connect(_on_buy_sp_pressed)
	vbox.add_child(buy_btn)
	return panel

func _make_fuel_card(fuel_per_race: float, cars: int) -> PanelContainer:
	var panel = _card_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	_card_title(vbox, "⛽ Fuel")
	_card_info(vbox, "CR %.2f/kg (live price). %d car%s × %.0f kg/race = %.0f kg per event.\nCurrent stock: %.1f kg" % [
		GameState.get_fuel_cost_per_kg(), cars, "s" if cars != 1 else "", fuel_per_race, fuel_per_race * cars, GameState.fuel_kg])

	var input_row = HBoxContainer.new(); input_row.add_theme_constant_override("separation", 8)
	vbox.add_child(input_row)
	var il = Label.new(); il.text = "Amount:"; il.add_theme_font_size_override("font_size", 26)
	input_row.add_child(il)
	fuel_input = LineEdit.new(); fuel_input.placeholder_text = "e.g. 60"
	fuel_input.custom_minimum_size = Vector2(140, 32)
	input_row.add_child(fuel_input)
	var cost_lbl = Label.new(); cost_lbl.add_theme_font_size_override("font_size", 24)
	cost_lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	input_row.add_child(cost_lbl)
	fuel_input.text_changed.connect(func(t):
		var a = int(t) if t.is_valid_int() and int(t) > 0 else 0
		## S35.4: live preview must match what buy_fuel actually charges (living per-kg price),
		## not the old hardcoded × 2. Rounded to whole CR for display.
		cost_lbl.text = ("= CR %d" % int(round(a * GameState.get_fuel_cost_per_kg()))) if a > 0 else "")

	var preset_lbl = Label.new(); preset_lbl.text = "Quick fill:"
	preset_lbl.add_theme_font_size_override("font_size", 24); preset_lbl.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(preset_lbl)
	var preset_row = HBoxContainer.new(); preset_row.add_theme_constant_override("separation", 8)
	vbox.add_child(preset_row)
	var race_qty = int(ceil(fuel_per_race * max(cars, 1)))
	for pair in [["1 Race\n%d kg" % race_qty, race_qty],
				 ["3 Races\n%d kg" % (race_qty*3), race_qty*3],
				 ["Season\n%d kg" % (race_qty*6), race_qty*6]]:
		var b = _preset_btn(pair[0])
		var qty = pair[1]
		b.pressed.connect(func(): fuel_input.text = str(qty))
		preset_row.add_child(b)

	var buy_btn = Button.new()
	buy_btn.text = "Buy Fuel →"
	buy_btn.custom_minimum_size = Vector2(0, 36)
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.add_theme_font_size_override("font_size", 26)
	buy_btn.pressed.connect(_on_buy_fuel_pressed)
	vbox.add_child(buy_btn)
	return panel

# ═══════════════════════════════════════════════════════════════════════════
# TAB 1: PARTS WAREHOUSE
# ═══════════════════════════════════════════════════════════════════════════
func _build_tab_warehouse(parent: VBoxContainer) -> void:
	# Only show championships where the player has a car
	var player_champ_ids: Array = []
	for car in GameState.player_team_cars:
		if car.championship_id != "" and not car.championship_id in player_champ_ids:
			player_champ_ids.append(car.championship_id)

	if player_champ_ids.is_empty():
		var lbl = Label.new()
		lbl.text = "No cars in garage yet. Go to BUY RACING CAR to purchase one."
		lbl.modulate = Color(0.55, 0.55, 0.55)
		lbl.add_theme_font_size_override("font_size", 28)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(lbl)
		return

	for cid in player_champ_ids:
		parent.add_child(_make_warehouse_champ_card(cid))

func _make_warehouse_champ_card(champ_id: String) -> PanelContainer:
	var reg   = GameState.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var disc  = reg.get("discipline", "GK")
	var cname = reg.get("name", champ_id)
	var inv   = GameState.part_inventory.get(champ_id, {})
	var costs = GameState.PART_COSTS.get(champ_id, {})

	var panel = _card_panel()
	var style = panel.get_theme_stylebox("panel").duplicate()
	style.border_color = DISC_COLORS.get(disc, Color(0.3, 0.3, 0.3))
	style.border_width_left = 4
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var lbl_champ = Label.new()
	lbl_champ.text = "🏆 %s" % cname
	lbl_champ.add_theme_font_size_override("font_size", 32)
	lbl_champ.add_theme_color_override("font_color", DISC_COLORS.get(disc, Color.WHITE))
	vbox.add_child(lbl_champ)

	# Column headers
	var hdr = HBoxContainer.new(); hdr.add_theme_constant_override("separation", 0)
	vbox.add_child(hdr)
	for pair in [["Part", 130], ["Stock", 60], ["Cost ea", 100], ["Qty", 70], ["Buy", 60]]:
		var lh = Label.new(); lh.text = pair[0]
		lh.add_theme_font_size_override("font_size", 22); lh.modulate = Color(0.45, 0.45, 0.45)
		lh.custom_minimum_size = Vector2(pair[1], 0)
		hdr.add_child(lh)

	vbox.add_child(HSeparator.new())

	part_inputs = {}
	for part in GameState.PARTS_LIST:
		var stock: int = inv.get(part, 0)
		var cost: int  = costs.get(part, 0)
		var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 0)
		vbox.add_child(row)

		# Part name
		var lbl_p = Label.new(); lbl_p.text = part
		lbl_p.custom_minimum_size = Vector2(130, 0)
		lbl_p.add_theme_font_size_override("font_size", 26)
		var pc = Color(1.0,0.3,0.3) if stock == 0 else (Color(1.0,0.65,0.2) if stock <= 2 else Color(0.85,0.85,0.85))
		lbl_p.add_theme_color_override("font_color", pc)
		row.add_child(lbl_p)

		# Stock
		var lbl_s = Label.new()
		lbl_s.text = ("×%d" % stock) if stock > 0 else "NONE"
		lbl_s.custom_minimum_size = Vector2(60, 0)
		lbl_s.add_theme_font_size_override("font_size", 26)
		lbl_s.add_theme_color_override("font_color", pc)
		row.add_child(lbl_s)

		# Cost
		var lbl_c = Label.new(); lbl_c.text = "CR %s" % _fmt(float(cost)) if cost > 0 else "—"
		lbl_c.custom_minimum_size = Vector2(100, 0)
		lbl_c.add_theme_font_size_override("font_size", 24); lbl_c.modulate = Color(0.55, 0.55, 0.55)
		row.add_child(lbl_c)

		# Qty input
		var input = LineEdit.new(); input.placeholder_text = "qty"
		input.custom_minimum_size = Vector2(70, 28)
		row.add_child(input)
		part_inputs[part] = input

		# Buy button
		var buy_btn = Button.new(); buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(60, 28)
		buy_btn.add_theme_font_size_override("font_size", 24)
		var _part = part; var _cid = champ_id
		buy_btn.pressed.connect(func(): _on_buy_part_pressed(_part, _cid))
		row.add_child(buy_btn)

	vbox.add_child(HSeparator.new())

	## S28.3 — CNC-manufactured parts in the warehouse for this championship (read-only).
	## Provider parts (above) are bought here; CNC parts come from the CNC Plant and are
	## installed at the Garage. Showing them here gives a single warehouse view.
	var cnc_rows: Array = []
	for inv_key in GameState.cnc_parts_inventory:
		var item = GameState.cnc_parts_inventory[inv_key]
		if not item is Dictionary: continue
		if item.get("championship_id", "") != champ_id: continue
		if item.get("quantity", 0) <= 0: continue
		cnc_rows.append(item)
	if not cnc_rows.is_empty():
		var cnc_hdr = Label.new()
		cnc_hdr.text = "⚙ Available Parts (CNC)"
		cnc_hdr.add_theme_font_size_override("font_size", 24)
		cnc_hdr.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		vbox.add_child(cnc_hdr)
		for item in cnc_rows:
			var crow = HBoxContainer.new(); crow.add_theme_constant_override("separation", 8)
			vbox.add_child(crow)
			var bp_name = item.get("part", "Part")
			var bp_id = item.get("blueprint_id", "")
			var lvl = 0
			if bp_id != "" and bp_id in GameState.known_blueprints:
				var bp = GameState.known_blueprints[bp_id]
				lvl = bp.get("level", 0)
				bp_name = bp.get("name", bp_name)
			var clbl = Label.new()
			clbl.text = "%s  L%d" % [bp_name, lvl]
			clbl.custom_minimum_size = Vector2(260, 0)
			clbl.add_theme_font_size_override("font_size", 24)
			clbl.add_theme_color_override("font_color", Color(0.8, 0.9, 0.8))
			crow.add_child(clbl)
			var cqty = Label.new()
			cqty.text = "×%d" % item.get("quantity", 0)
			cqty.add_theme_font_size_override("font_size", 24)
			cqty.modulate = Color(0.6, 0.6, 0.6)
			crow.add_child(cqty)
			var crel = Label.new()
			crel.text = "Rel %.0f%%  ·  Qual %.2f×" % [
				item.get("reliability", 0.0), item.get("quality", 1.0)]
			crel.add_theme_font_size_override("font_size", 22)
			crel.modulate = Color(0.55, 0.6, 0.7)
			crow.add_child(crel)
		vbox.add_child(HSeparator.new())

	# Bulk buy row
	var bulk_lbl = Label.new(); bulk_lbl.text = "Buy all parts at once:"
	bulk_lbl.add_theme_font_size_override("font_size", 24); bulk_lbl.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(bulk_lbl)
	var bulk_row = HBoxContainer.new(); bulk_row.add_theme_constant_override("separation", 8)
	vbox.add_child(bulk_row)
	for qty in [1, 3, 5]:
		var btn = Button.new()
		btn.text = "+%d each" % qty
		btn.custom_minimum_size = Vector2(80, 30)
		btn.add_theme_font_size_override("font_size", 24)
		var _qty = qty; var _cid = champ_id
		btn.pressed.connect(func():
			# Collect quantities BEFORE any buy (buying calls _switch_tab which wipes part_inputs)
			var to_buy: Dictionary = {}
			for p in GameState.PARTS_LIST:
				to_buy[p] = _qty
			# Now buy all parts without refreshing UI between each
			for p in GameState.PARTS_LIST:
				GameState.buy_part(p, to_buy[p], _cid)
			# Single refresh after all purchases
			_switch_tab(_active_tab)
		)
		bulk_row.add_child(btn)

	return panel

# ═══════════════════════════════════════════════════════════════════════════
# TAB 2: BUY RACING CAR
# ═══════════════════════════════════════════════════════════════════════════
func _build_tab_buy_car(parent: VBoxContainer) -> void:
	# ── Car slots & championship requirements ─────────────────────────────────
	var slots_panel = _card_panel()
	slots_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sv = VBoxContainer.new(); sv.add_theme_constant_override("separation", 8)
	slots_panel.add_child(sv)
	_card_title(sv, "🏎 Car Slots & Championship Requirements")

	var cur_cars = GameState.player_team_cars.size()
	var max_cars = GameState.get_max_cars()
	var garage = GameState.get_building("Garage")
	var slots_lbl = Label.new()
	slots_lbl.text = "Car Slots: %d / %d  (Garage Lv%d)" % [cur_cars, max_cars, garage.get("level", 1)]
	slots_lbl.add_theme_font_size_override("font_size", 28)
	slots_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.4, 0.4) if cur_cars >= max_cars else Color(0.4, 0.9, 0.4))
	sv.add_child(slots_lbl)

	## Only show championships where player has a car or is registered
	var player_cids: Array = []
	for car in GameState.player_team_cars:
		if not car.championship_id in player_cids:
			player_cids.append(car.championship_id)
	for cid in GameState.player_registered_championships:
		if not cid in player_cids:
			player_cids.append(cid)
	var player_champs_log: Array = []
	for champ in GameState.active_championships:
		if champ.id in player_cids:
			player_champs_log.append(champ)

	if not player_champs_log.is_empty():
		sv.add_child(HSeparator.new())
		for champ in player_champs_log:
			var reg = GameState.CHAMPIONSHIP_REGISTRY.get(champ.id, {})
			var champ_name = reg.get("name", champ.id)
			var cars_in_champ = GameState.player_team_cars.filter(
				func(c): return c.championship_id == champ.id).size()
			var min_c = reg.get("min_cars", 1)
			## Use the championship's own max_cars — do NOT fall back to garage limit here
			var max_c = reg.get("max_cars", 2)
			var crow = HBoxContainer.new()
			crow.add_theme_constant_override("separation", 10)
			sv.add_child(crow)
			var lbl_cn = Label.new()
			lbl_cn.text = champ_name
			lbl_cn.add_theme_font_size_override("font_size", 24)
			lbl_cn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_cn.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
			crow.add_child(lbl_cn)
			var req_ok = cars_in_champ >= min_c
			var lbl_req = Label.new()
			lbl_req.text = "Min %d / Max %d  ·  You have: %d" % [min_c, max_c, cars_in_champ]
			lbl_req.add_theme_font_size_override("font_size", 24)
			lbl_req.add_theme_color_override("font_color",
				Color(0.4, 0.9, 0.4) if req_ok else Color(1.0, 0.4, 0.4))
			crow.add_child(lbl_req)
			if not req_ok:
				var lbl_warn = Label.new()
				lbl_warn.text = "⚠ Need %d more car%s — buy below!" % [
					min_c - cars_in_champ, "s" if min_c - cars_in_champ != 1 else ""]
				lbl_warn.add_theme_font_size_override("font_size", 22)
				lbl_warn.modulate = Color(1.0, 0.5, 0.2)
				sv.add_child(lbl_warn)

	parent.add_child(slots_panel)

	# ── Championship car cards ─────────────────────────────────────────────────
	## Car cards: only the player's registered championships (current season) +
	## any championships they already own a car for. S28.1: removed the hardcoded
	## ["C-001"] GK fallback that masked the registration bug — if the player has
	## no registrations, show a clear empty-state message instead of a phantom GK car.
	var champ_ids: Array = player_cids.duplicate()
	if champ_ids.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No championships registered for this season. Register during the season for next season at Championship Registration."
		empty_lbl.add_theme_font_size_override("font_size", 26)
		empty_lbl.modulate = Color(0.8, 0.6, 0.3)
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(empty_lbl)
		return

	var flow = HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", 16)
	flow.add_theme_constant_override("v_separation", 14)
	parent.add_child(flow)

	for cid in champ_ids:
		flow.add_child(_make_buy_car_card(cid))

func _make_buy_car_card(champ_id: String) -> PanelContainer:
	var reg       = GameState.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var champ_name = reg.get("name", champ_id)
	var disc      = reg.get("discipline", "GK")

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.11, 0.14)
	style.border_width_left = 3; style.border_width_right = 1
	style.border_width_top = 1;  style.border_width_bottom = 1
	style.border_color = DISC_COLORS.get(disc, Color(0.4, 0.4, 0.4))
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 12; style.content_margin_right = 12
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 7)
	panel.add_child(vbox)

	var lbl_champ = Label.new(); lbl_champ.text = champ_name
	lbl_champ.add_theme_font_size_override("font_size", 28)
	lbl_champ.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	lbl_champ.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_champ)

	# Spec/Open summary
	const PART_SPEC = {
		"C-001":[true,true,true,false,false,true], "C-002":[true,true,true,false,true,false],
		"C-003":[true,false,true,false,false,false],"C-004":[true,false,false,false,false,false],
		"C-005":[true,true,true,false,false,true],  "C-006":[false,true,true,false,false,false],
		"C-007":[false,false,false,false,false,false],"C-008":[false,false,false,false,false,false],
		"C-009":[true,true,true,true,true,true],    "C-010":[true,true,true,true,true,true],
		"C-011":[true,true,true,true,true,true],    "C-012":[true,true,true,true,true,true],
		"C-013":[true,false,true,false,true,true],  "C-014":[true,false,true,false,false,true],
		"C-015":[true,false,false,false,false,true], "C-016":[true,false,false,false,false,true],
		"C-017":[true,false,false,false,false,true], "C-018":[true,true,true,true,true,true],
		"C-019":[true,true,true,false,false,true],  "C-020":[false,false,false,false,false,false],
		"C-021":[true,true,true,true,true,true],    "C-022":[true,true,true,true,true,true],
		"C-023":[true,true,true,true,true,true],    "C-024":[false,false,false,false,false,false],
	}
	const PNAMES = ["Aero","Engine","Gearbox","Suspension","Brakes","Chassis"]
	var sarr = PART_SPEC.get(champ_id, [true,true,true,true,true,true])
	var spec_p: Array = []; var open_p: Array = []
	for i in range(PNAMES.size()):
		if sarr[i]: spec_p.append(PNAMES[i])
		else: open_p.append(PNAMES[i])

	if spec_p.size() == 6:
		_spec_label(vbox, "🔒 All parts: Spec (provider supplied)", Color(0.6, 0.75, 1.0))
	elif open_p.size() == 6:
		_spec_label(vbox, "🔓 All parts: Open — team must design & manufacture", Color(0.4, 0.88, 0.55))
	else:
		if not spec_p.is_empty(): _spec_label(vbox, "🔒 Spec: %s" % ", ".join(spec_p), Color(0.6, 0.75, 1.0))
		if not open_p.is_empty(): _spec_label(vbox, "🔓 Open: %s" % ", ".join(open_p), Color(0.4, 0.88, 0.55))

	var is_own_build = champ_id in OWN_BUILD_CHAMPS

	if not is_own_build:
		# Standard buy path
		var lbl_contract = Label.new()
		lbl_contract.text = "Buying from provider delivers a full car. All parts locked — no modifications under provider contract. Own-designed parts must be manufactured at CNC Plant."
		lbl_contract.add_theme_font_size_override("font_size", 20)
		lbl_contract.modulate = Color(0.5, 0.5, 0.5)
		lbl_contract.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_contract)

		const PROVIDERS = {
			"C-001":"WRA Karting Supply Co.","C-002":"WRA Karting Supply Co.",
			"C-003":"Apex Kart Distribution","C-004":"Apex Kart Distribution",
			"C-005":"Rally Equipment Group", "C-006":"Rally Equipment Group",
			"C-007":"Rally Equipment Group", "C-008":"WRC Contracted Provider",
			"C-009":"TCM Touring Specialists","C-010":"TCM Touring Specialists",
			"C-011":"OWC Chassis Group",      "C-012":"OWC Chassis Group",
			"C-013":"IndyCar Contracted Provider",
			"C-014":"NASCAR Supply Alliance", "C-015":"NASCAR Supply Alliance",
			"C-016":"NASCAR Supply Alliance", "C-017":"NASCAR Contracted Provider",
			"C-018":"EPC Prototype Suppliers","C-019":"EPC Prototype Suppliers",
			"C-020":"WEC Contracted Provider",
			"C-021":"Formula Parts Direct",   "C-022":"Formula Parts Direct",
			"C-023":"Formula Parts Direct",   "C-024":"GP1 Contracted Provider",
		}
		var car_cost      = GameState.get_provider_car_cost(champ_id)
		var provider      = PROVIDERS.get(champ_id, "WRA Contracted Provider")
		var can_afford    = GameState.player_team.balance >= car_cost
		var slots_full    = GameState.player_team_cars.size() >= GameState.get_max_cars()
		var delivery_week = GameState.get_car_delivery_week(champ_id)
		var race1_week    = GameState.FIRST_RACE_WEEK.get(champ_id, 6)

		var lbl_prov = Label.new(); lbl_prov.text = provider
		lbl_prov.add_theme_font_size_override("font_size", 22); lbl_prov.modulate = Color(0.6, 0.6, 0.6)
		vbox.add_child(lbl_prov)

		var lbl_del = Label.new()
		lbl_del.text = "Delivery Wk %d  ·  Race 1 Wk %d" % [delivery_week, race1_week]
		lbl_del.add_theme_font_size_override("font_size", 22)
		lbl_del.add_theme_color_override("font_color", Color(0.6, 0.75, 1.0))
		vbox.add_child(lbl_del)

		var lbl_cost = Label.new()
		lbl_cost.text = "CR %s" % _fmt(float(car_cost))
		lbl_cost.add_theme_font_size_override("font_size", 32)
		lbl_cost.add_theme_color_override("font_color", Color(0.5,0.9,0.5) if can_afford else Color(1.0,0.35,0.35))
		vbox.add_child(lbl_cost)

		if slots_full:
			_spec_label(vbox, "⚠ Garage full — upgrade Garage building", Color(1.0, 0.5, 0.15))

		var buy_btn = Button.new()
		buy_btn.text = "Buy Car — %s" % champ_name.left(16)
		buy_btn.custom_minimum_size = Vector2(0, 34)
		buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buy_btn.add_theme_font_size_override("font_size", 24)
		buy_btn.disabled = slots_full or not can_afford
		buy_btn.pressed.connect(_on_buy_car_pressed.bind(car_cost, provider, champ_id))
		vbox.add_child(buy_btn)

		# GP1 engine contract extra
		if champ_id == "C-024":
			var engine_cost = 6900000
			var eng_btn = Button.new()
			eng_btn.text = "Buy Engine Contract  (CR %s/season)" % _fmt(float(engine_cost))
			eng_btn.custom_minimum_size = Vector2(0, 34)
			eng_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			eng_btn.add_theme_font_size_override("font_size", 24)
			eng_btn.disabled = GameState.player_team.balance < engine_cost
			eng_btn.pressed.connect(_on_buy_engine_contract_pressed.bind(engine_cost, "GP1 Contracted Provider", champ_id))
			vbox.add_child(eng_btn)
	else:
		# Own-build championship — no buy button, redirect to R&D / CNC
		var lbl_ob = Label.new()
		lbl_ob.text = "This championship requires the team to design and manufacture their own car. All parts are Open — no provider car available."
		lbl_ob.add_theme_font_size_override("font_size", 22)
		lbl_ob.modulate = Color(0.7, 0.7, 0.7)
		lbl_ob.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_ob)

		var lbl_steps = Label.new()
		lbl_steps.text = "① Research blueprints in R&D Studio  ②  Submit for WRA approval  ③  Manufacture at CNC Plant"
		lbl_steps.add_theme_font_size_override("font_size", 22)
		lbl_steps.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
		lbl_steps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_steps)

		var btn_rnd = Button.new()
		btn_rnd.text = "🔬 Go to R&D Design Studio"
		btn_rnd.custom_minimum_size = Vector2(0, 34)
		btn_rnd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_rnd.add_theme_font_size_override("font_size", 24)
		btn_rnd.modulate = Color(0.3, 0.7, 1.0)
		btn_rnd.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/RnDStudio.tscn"))
		vbox.add_child(btn_rnd)

		var btn_cnc = Button.new()
		btn_cnc.text = "⚙ Go to CNC Parts Plant"
		btn_cnc.custom_minimum_size = Vector2(0, 34)
		btn_cnc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_cnc.add_theme_font_size_override("font_size", 24)
		btn_cnc.modulate = Color(0.3, 0.85, 0.55)
		btn_cnc.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn"))
		vbox.add_child(btn_cnc)

	return panel

# ═══════════════════════════════════════════════════════════════════════════
# ACTIONS
# ═══════════════════════════════════════════════════════════════════════════
func _on_buy_sp_pressed() -> void:
	var t = sp_input.text.strip_edges()
	if not t.is_valid_int() or int(t) <= 0:
		_show_error("Enter a valid amount of spare parts.")
		return
	GameState.buy_spare_parts(int(t))
	sp_input.text = ""
	_refresh_header_labels()
	_switch_tab(_active_tab)

func _on_buy_fuel_pressed() -> void:
	var t = fuel_input.text.strip_edges()
	if not t.is_valid_int() or int(t) <= 0:
		_show_error("Enter a valid fuel amount in kg.")
		return
	GameState.buy_fuel(float(int(t)))
	fuel_input.text = ""
	_refresh_header_labels()
	_switch_tab(_active_tab)

func _on_buy_part_pressed(part_name: String, champ_id: String, silent: bool = false) -> void:
	if not part_name in part_inputs: return
	var text = part_inputs[part_name].text.strip_edges()
	if not text.is_valid_int() or int(text) <= 0:
		if not silent: _show_error("Enter a valid quantity for %s." % part_name)
		return
	GameState.buy_part(part_name, int(text), champ_id)
	part_inputs[part_name].text = ""
	_refresh_header_labels()
	# Rebuild the warehouse tab to show updated stock — but only once, not per-part in bulk
	if not silent:
		_switch_tab(_active_tab)

func _on_buy_car_pressed(car_cost: int, provider: String, champ_id: String) -> void:
	var reg = GameState.CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	if GameState.player_team.balance < car_cost:
		_show_error("Not enough credits. Need CR %s." % _fmt(float(car_cost)))
		return
	GameState.player_team.balance -= car_cost
	GameState.add_car(champ_id)
	GameState.add_log("🏎 Car purchased for %s from %s — CR %s" % [reg.get("name", champ_id), provider, _fmt(float(car_cost))])
	GameState.add_notification("Normal", "🏎 %s car purchased! Assign a driver in the Garage." % reg.get("name", champ_id))
	_switch_tab(_active_tab)

func _on_buy_engine_contract_pressed(engine_cost: int, provider: String, _champ_id: String) -> void:
	if GameState.player_team.balance < engine_cost:
		_show_error("Not enough credits for GP1 engine contract.")
		return
	GameState.player_team.balance -= engine_cost
	GameState.add_log("🔧 GP1 Engine contract signed with %s — CR %s/season" % [provider, _fmt(float(engine_cost))])
	GameState.add_notification("Normal", "GP1 engine secured. Now build your chassis at the CNC Plant.")
	_switch_tab(_active_tab)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════
func _card_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.11, 0.14)
	style.border_width_left = 3; style.border_width_right = 1
	style.border_width_top = 1;  style.border_width_bottom = 1
	style.border_color = Color(0.22, 0.28, 0.38)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 16; style.content_margin_right = 16
	style.content_margin_top = 14; style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _card_title(parent: VBoxContainer, text: String) -> void:
	var lbl = Label.new(); lbl.text = text
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	parent.add_child(lbl)

func _card_info(parent: VBoxContainer, text: String) -> void:
	var lbl = Label.new(); lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lbl)

func _spec_label(parent: VBoxContainer, text: String, color: Color) -> void:
	var lbl = Label.new(); lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lbl)

func _preset_btn(label: String) -> Button:
	var btn = Button.new(); btn.text = label
	btn.custom_minimum_size = Vector2(100, 46)
	btn.add_theme_font_size_override("font_size", 22)
	return btn

func _show_error(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Error"; dialog.dialog_text = message
	add_child(dialog); dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _fmt(n: float) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.0fK" % (n / 1000.0)
	return str(int(n))
