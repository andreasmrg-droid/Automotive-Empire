extends Control
## Version: S35.11b — Install popup widened 440→620 + rows wrap/use acronyms so the Install
##   button is no longer clipped off the popup edge. Empty slot shows "L0" (not "L0 — empty").
##   Warehouse panel now ALSO reflects the Logistics warehouse (provider L0 spares from
##   part_inventory), with a Source column, so the Garage shows ALL installable stock.
## Version: S35.11 — Parts UX pass: part acronyms (AER/ENG/…) instead of full names (issue);
##   empty slot shows "L0 — empty" not "EMPTY SLOT" (issue 5); persistent WAREHOUSE panel lists
##   installable CNC parts per championship (issue 4); car header shows "⚡ Parts: +X% pace" from
##   get_cnc_part_bonus so installs make a visible change (issue 7). Install button unchanged —
##   it now finds stock via the S35.11 part_code keying fix (issue 6).
## Version: S30.6 — Phase 2 car delivery: car card shows an "In build — arrives Week X
##   (Y left)" banner while undelivered (car.is_in_build). Driver/mechanic/pit-crew
##   assignment stays AVAILABLE (pre-assign while it builds); part slots are LOCKED until
##   delivery (Change/Remove/Install disabled + a "Parts locked" note). New strings
##   localized (gar_* in Locale.gd S30.6); pre-existing hardcoded strings left for the
##   deferred full sweep (GDD §16).
## --- S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## --- S28.4 — Pit Crew assignment slot + popup in Garage (Bug 6). CNC/provider install
##   buttons check success before closing popup;
##   show failure notice. "Wet"→"Ctrl" stat label.
## --- S22.8 — #5 Assign popup shows all with current assignment status and reassign.
##                    so the player can make an informed choice.
## --- S17.2 — Full redesign: championship tabs; car cards with 6 part slots;
##                    provider (L0) and CNC parts unified; Change popup (any level from stock);
##                    per-part condition bars; Remove returns part to stock/inventory.

# ── Constants ─────────────────────────────────────────────────────────────────
const PART_CODES  = ["AER","ENG","GRB","SUS","BRK","CHS"]
const PART_NAMES  = {"AER":"Aerodynamics","ENG":"Engine","GRB":"Gearbox",
	"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
const PART_COLORS = {"AER":Color(0.25,0.65,1.0),"ENG":Color(1.0,0.4,0.2),
	"GRB":Color(0.65,0.3,0.9),"SUS":Color(0.25,0.85,0.5),
	"BRK":Color(1.0,0.25,0.25),"CHS":Color(0.85,0.55,0.1)}
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

# ── State ─────────────────────────────────────────────────────────────────────
var _selected_tab: String = ""   ## championship id of active tab
var _popup: PanelContainer       ## reusable overlay (mechanic/driver/change-part)
var _popup_title: Label
var _popup_list: VBoxContainer
var _assigning_car_id: String = ""
var _assigning_pcode:  String = ""
var _popup_mode: String = "mechanic"   ## "mechanic" | "driver" | "part"

# ── Node refs ─────────────────────────────────────────────────────────────────
var _lbl_level:  Label
var _lbl_slots:  Label
var _lbl_income: Label
var _tab_bar:    HBoxContainer
var _content:    VBoxContainer   ## swapped per tab
var _tab_btns:   Dictionary = {} ## champ_id → Button

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	## Default tab = first active championship that has a car, else first champ
	for car in GameState.player_team_cars:
		if _selected_tab == "": _selected_tab = car.championship_id
	if _selected_tab == "" and GameState.player_team_cars.size() > 0:
		_selected_tab = GameState.player_team_cars[0].championship_id
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right"]: margin.add_theme_constant_override(s, 20)
	for s in ["margin_top","margin_bottom"]: margin.add_theme_constant_override(s, 14)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# ── Header ────────────────────────────────────────────────────────────────
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 14)
	root.add_child(hdr)

	_lbl_level = Label.new()
	_lbl_level.add_theme_font_size_override("font_size", 44)
	_lbl_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(_lbl_level)

	_lbl_slots = Label.new()
	_lbl_slots.add_theme_font_size_override("font_size", 26)
	_lbl_slots.modulate = Color(0.7,0.7,0.7)
	hdr.add_child(_lbl_slots)

	_lbl_income = Label.new()
	_lbl_income.add_theme_font_size_override("font_size", 26)
	_lbl_income.modulate = Color(0.4,0.9,0.5)
	hdr.add_child(_lbl_income)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(90, 34)
	btn_back.pressed.connect(_on_back)
	hdr.add_child(btn_back)

	root.add_child(HSeparator.new())

	# ── Action bar ────────────────────────────────────────────────────────────
	var abar = HBoxContainer.new()
	abar.add_theme_constant_override("separation", 12)
	root.add_child(abar)

	var btn_buy = Button.new()
	btn_buy.text = "🛒 Buy Car  →  Logistics"
	btn_buy.custom_minimum_size = Vector2(200, 34)
	btn_buy.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/Logistics.tscn"))
	abar.add_child(btn_buy)

	var btn_mech = Button.new()
	btn_mech.text = "🔧 Hire Mechanic  →  Staff"
	btn_mech.custom_minimum_size = Vector2(200, 34)
	btn_mech.pressed.connect(func():
		GameState.pending_staff_filter = "Race Mechanic"
		get_tree().change_scene_to_file("res://scenes/Staff.tscn"))
	abar.add_child(btn_mech)

	var lbl_hint = Label.new()
	lbl_hint.text = "Buy a full car at Logistics (L0 provider parts) or build one at CNC."
	lbl_hint.add_theme_font_size_override("font_size", 22)
	lbl_hint.modulate = Color(0.5,0.5,0.5)
	lbl_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	abar.add_child(lbl_hint)

	root.add_child(HSeparator.new())

	# ── Championship tabs ─────────────────────────────────────────────────────
	_tab_bar = HBoxContainer.new()
	_tab_bar.add_theme_constant_override("separation", 4)
	root.add_child(_tab_bar)

	# ── Content area ──────────────────────────────────────────────────────────
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 14)
	scroll.add_child(_content)

	# ── Popup overlay ─────────────────────────────────────────────────────────
	_popup = PanelContainer.new()
	_popup.set_anchors_preset(Control.PRESET_CENTER)
	_popup.custom_minimum_size = Vector2(620, 0)
	_popup.visible = false
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.10,0.10,0.14,0.98)
	for side in ["left","right","top","bottom"]: ps.set("border_width_%s" % side, 2)
	ps.border_color = Color(0.35,0.65,1.0)
	for corner in ["top_left","top_right","bottom_left","bottom_right"]: ps.set("corner_radius_%s" % corner, 6)
	for side in ["left","right","top","bottom"]: ps.set("content_margin_%s" % side, 16)
	_popup.add_theme_stylebox_override("panel", ps)
	add_child(_popup)

	var pvbox = VBoxContainer.new()
	pvbox.add_theme_constant_override("separation", 10)
	_popup.add_child(pvbox)

	var phdr = HBoxContainer.new()
	pvbox.add_child(phdr)
	_popup_title = Label.new()
	_popup_title.add_theme_font_size_override("font_size", 32)
	_popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phdr.add_child(_popup_title)
	var pbtn_close = Button.new()
	pbtn_close.text = "✕"
	pbtn_close.custom_minimum_size = Vector2(30,30)
	pbtn_close.pressed.connect(func(): _popup.visible = false)
	phdr.add_child(pbtn_close)
	pvbox.add_child(HSeparator.new())

	var pscroll = ScrollContainer.new()
	pscroll.custom_minimum_size = Vector2(0,180)
	pvbox.add_child(pscroll)
	_popup_list = VBoxContainer.new()
	_popup_list.add_theme_constant_override("separation", 6)
	_popup_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pscroll.add_child(_popup_list)

	_refresh_header()
	_build_tabs()
	_show_tab(_selected_tab)

# ── Header refresh ────────────────────────────────────────────────────────────
func _refresh_header() -> void:
	var bld = GameState.campus_buildings.get("Garage", {})
	_lbl_level.text  = "🔧 GARAGE  ·  Level %d" % bld.get("level", 1)
	_lbl_slots.text  = "Cars: %d / %d" % [GameState.player_team_cars.size(), GameState.get_max_cars()]
	var inc = bld.get("weekly_income", 0)
	_lbl_income.text = "CR %s / wk" % _fmt(inc) if inc > 0 else ""

# ── Tab bar ───────────────────────────────────────────────────────────────────
func _build_tabs() -> void:
	for c in _tab_bar.get_children(): c.queue_free()
	_tab_btns.clear()

	## Only show championships where player has a car
	var player_cids: Array = []
	for car in GameState.player_team_cars:
		if not car.championship_id in player_cids:
			player_cids.append(car.championship_id)
	var champs = GameState.active_championships.filter(func(c): return c.id in player_cids)
	if champs.is_empty():
		var lbl = Label.new()
		lbl.text = "No active championships."
		lbl.modulate = Color(0.5,0.5,0.5)
		_tab_bar.add_child(lbl)
		return

	for champ in champs:
		var btn = Button.new()
		btn.text = champ.championship_name
		btn.custom_minimum_size = Vector2(0,32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 24)
		if champ.id == _selected_tab:
			btn.modulate = Color(0.4,0.85,1.0)
		var cid = champ.id
		btn.pressed.connect(func(): _show_tab(cid))
		_tab_bar.add_child(btn)
		_tab_btns[champ.id] = btn

func _show_tab(champ_id: String) -> void:
	_selected_tab = champ_id
	## Update tab button colours
	for cid in _tab_btns:
		_tab_btns[cid].modulate = Color(0.4,0.85,1.0) if cid == champ_id else Color(1,1,1)
	## Rebuild content
	for c in _content.get_children(): c.queue_free()

	## S35.11 (issue 4) — persistent warehouse panel so the player can see, without opening
	## each slot's popup, which CNC parts are in stock and available to install for this champ.
	_content.add_child(_build_warehouse_panel(champ_id))

	var cars = GameState.player_team_cars.filter(func(c): return c.championship_id == champ_id)

	if cars.is_empty():
		var lbl = Label.new()
		lbl.text = "No cars for this championship.\nBuy a car at Logistics or manufacture one at the CNC Plant."
		lbl.modulate = Color(0.5,0.5,0.5)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 26)
		_content.add_child(lbl)
	else:
		for car in cars:
			_content.add_child(_build_car_card(car))

# ── Warehouse panel (S35.11, issue 4) ─────────────────────────────────────────
## Persistent read-only summary of CNC parts in the warehouse for this championship, so the
## player isn't blind to what they can install. Grouped by part code, showing level/qty/stats.
func _build_warehouse_panel(champ_id: String) -> PanelContainer:
	var panel = _make_panel(Color(0.08,0.11,0.09), Color(0.3,0.7,0.4), 2)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var hdr = Label.new()
	hdr.text = "📦 WAREHOUSE — CNC parts ready to install"
	hdr.add_theme_font_size_override("font_size", 24)
	hdr.add_theme_color_override("font_color", Color(0.45,0.9,0.5))
	vbox.add_child(hdr)

	## Collect CNC inventory items for this championship.
	var rows: Array = []
	for inv_key in GameState.cnc_parts_inventory:
		var item = GameState.cnc_parts_inventory[inv_key]
		if not item is Dictionary: continue
		if item.get("championship_id","") != champ_id: continue
		if item.get("quantity",0) <= 0: continue
		rows.append(item)

	## Collect provider L0 stock (Logistics warehouse) for this championship.
	## S35.11 — the Garage must reflect the Logistics warehouse, which holds provider L0 spares
	## (part_inventory[champ_id][part_name]). Shown as L0 rows so the player sees ALL installable
	## stock — CNC parts AND provider spares — in one place.
	const PCODE_TO_NAME = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	var prov: Array = []
	for pcode in PART_CODES:
		var pname = PCODE_TO_NAME.get(pcode, pcode)
		var qty = GameState.get_part_stock(pname, champ_id)
		if qty > 0:
			prov.append({"pcode": pcode, "qty": qty})

	if rows.is_empty() and prov.is_empty():
		var empty = Label.new()
		empty.text = "No parts in stock. Manufacture parts at the CNC Plant or buy provider spares at Logistics, then install them here."
		empty.add_theme_font_size_override("font_size", 20)
		empty.modulate = Color(0.55,0.55,0.55)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(empty)
		return panel

	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)
	for h in ["Part", "Level", "Qty", "Rel / Qual", "Source"]:
		var lh = Label.new()
		lh.text = h
		lh.add_theme_font_size_override("font_size", 18)
		lh.modulate = Color(0.5,0.5,0.5)
		grid.add_child(lh)

	for item in rows:
		var pcode = item.get("part_code","")
		if pcode == "":
			pcode = GameState._part_name_to_pcode(item.get("part",""))
		var lvl = 0
		var bp_id = item.get("blueprint_id","")
		if bp_id != "" and bp_id in GameState.known_blueprints:
			lvl = GameState.known_blueprints[bp_id].get("level", 0)
		var col = PART_COLORS.get(pcode, Color(0.7,0.7,0.7))
		_warehouse_row(grid, pcode, col, "L%d" % lvl, item.get("quantity",0),
			"%.0f%% / %.2f×" % [item.get("reliability",60.0), item.get("quality",1.0)], "CNC")

	for p in prov:
		var col = PART_COLORS.get(p.pcode, Color(0.7,0.7,0.7))
		_warehouse_row(grid, p.pcode, col, "L0", p.qty, "— / —", "Provider")

	return panel

## S35.11 — one warehouse table row.
func _warehouse_row(grid: GridContainer, pcode: String, col: Color, lvl_txt: String,
		qty: int, stats: String, source: String) -> void:
	var l_part = Label.new()
	l_part.text = pcode
	l_part.add_theme_font_size_override("font_size", 22)
	l_part.add_theme_color_override("font_color", col)
	grid.add_child(l_part)
	var l_lvl = Label.new()
	l_lvl.text = lvl_txt
	l_lvl.add_theme_font_size_override("font_size", 22)
	grid.add_child(l_lvl)
	var l_qty = Label.new()
	l_qty.text = "×%d" % qty
	l_qty.add_theme_font_size_override("font_size", 22)
	l_qty.modulate = Color(0.7,0.7,0.7)
	grid.add_child(l_qty)
	var l_stats = Label.new()
	l_stats.text = stats
	l_stats.add_theme_font_size_override("font_size", 20)
	l_stats.modulate = Color(0.6,0.6,0.6)
	grid.add_child(l_stats)
	var l_src = Label.new()
	l_src.text = source
	l_src.add_theme_font_size_override("font_size", 18)
	l_src.modulate = Color(0.45,0.7,0.9) if source == "CNC" else Color(0.6,0.6,0.6)
	grid.add_child(l_src)

# ── Car card ──────────────────────────────────────────────────────────────────
func _build_car_card(car) -> PanelContainer:
	var panel = _make_panel(Color(0.09,0.10,0.14), Color(0.3,0.55,0.9), 3)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# ── Car header row ────────────────────────────────────────────────────────
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vbox.add_child(hdr)

	var lbl_name = Label.new()
	lbl_name.text = "🏎 %s" % _car_name(car)
	lbl_name.add_theme_font_size_override("font_size", 30)
	lbl_name.add_theme_color_override("font_color", Color(0.7,0.9,1.0))
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(lbl_name)

	## Overall condition bar
	var cond_lbl = Label.new()
	cond_lbl.text = "Condition: %.0f%%" % car.condition
	cond_lbl.add_theme_font_size_override("font_size", 24)
	var cc = Color(0.3,0.9,0.3) if car.condition > 60 else (Color(1.0,0.75,0.1) if car.condition > 30 else Color(1.0,0.3,0.3))
	cond_lbl.add_theme_color_override("font_color", cc)
	hdr.add_child(cond_lbl)

	## S35.11 (issue 7) — visible CNC performance bonus from installed parts. Updates whenever
	## a part is installed/removed (the tab rebuilds), so the player sees the effect on the car.
	var perf = GameState.get_cnc_part_bonus(car.id)
	var perf_lbl = Label.new()
	perf_lbl.text = "⚡ Parts: +%.1f%% pace" % (perf * 100.0)
	perf_lbl.add_theme_font_size_override("font_size", 24)
	perf_lbl.add_theme_color_override("font_color",
		Color(0.45,0.9,0.5) if perf > 0.0 else Color(0.5,0.5,0.5))
	hdr.add_child(perf_lbl)

	# ── Delivery banner (Phase 2) ─────────────────────────────────────────────
	## While the car is in build (bought or built but not yet delivered) show when it
	## arrives. Assignments below remain available so the player can pre-crew the car.
	if car.is_in_build():
		var weeks_left = car.weeks_until_delivery(GameState.current_week)
		var left_txt: String
		if weeks_left <= 0:
			left_txt = Locale.t("gar_in_build_due")
		elif weeks_left == 1:
			left_txt = Locale.tf("gar_in_build_wleft", [weeks_left])
		else:
			left_txt = Locale.tf("gar_in_build_wsleft", [weeks_left])

		var banner = _make_panel(Color(0.10,0.13,0.20), Color(0.3,0.6,1.0), 4)
		banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bvb = VBoxContainer.new()
		bvb.add_theme_constant_override("separation", 3)
		banner.add_child(bvb)
		var blbl = Label.new()
		blbl.text = Locale.tf("gar_in_build_week", [car.delivery_week, left_txt])
		blbl.add_theme_font_size_override("font_size", 24)
		blbl.add_theme_color_override("font_color", Color(0.55,0.78,1.0))
		bvb.add_child(blbl)
		var bhint = Label.new()
		bhint.text = Locale.t("gar_in_build_hint")
		bhint.add_theme_font_size_override("font_size", 20)
		bhint.modulate = Color(0.6,0.6,0.6)
		bhint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bvb.add_child(bhint)
		vbox.add_child(banner)

	# ── Driver & Mechanic row ─────────────────────────────────────────────────
	var staff_row = HBoxContainer.new()
	staff_row.add_theme_constant_override("separation", 20)
	vbox.add_child(staff_row)

	## Driver
	var drv_box = _make_staff_slot(car, "DRIVER")
	staff_row.add_child(drv_box)

	## Mechanic
	var mech_box = _make_staff_slot(car, "MECHANIC")
	staff_row.add_child(mech_box)

	## Pit Crew — only for disciplines that require one (Rally, SC, GP). S28.3 (Bug 6).
	if GameState.get_pit_crew_required(car.championship_id):
		var crew_box = _make_staff_slot(car, "PIT CREW")
		staff_row.add_child(crew_box)

	vbox.add_child(HSeparator.new())

	# ── Parts grid (2 rows × 3 cols) ──────────────────────────────────────────
	var parts_title = Label.new()
	parts_title.text = "PARTS"
	parts_title.add_theme_font_size_override("font_size", 22)
	parts_title.modulate = Color(0.55,0.55,0.55)
	vbox.add_child(parts_title)

	## Parts cannot be installed/changed/removed while the car is in build.
	if car.is_in_build():
		var lock_lbl = Label.new()
		lock_lbl.text = Locale.t("gar_parts_locked")
		lock_lbl.add_theme_font_size_override("font_size", 20)
		lock_lbl.add_theme_color_override("font_color", Color(1.0,0.7,0.3))
		vbox.add_child(lock_lbl)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	var spec_arr = PART_SPEC_MAP.get(car.championship_id, [false,false,false,false,false,false])
	var all_parts = GameState.get_all_parts_for_car(car.id)

	for i in range(PART_CODES.size()):
		var pcode = PART_CODES[i]
		var is_spec = spec_arr[i]
		var part_data = all_parts.get(pcode, {})
		grid.add_child(_build_part_slot(car, pcode, is_spec, part_data))

	return panel

# ── Staff slot (driver / mechanic) ────────────────────────────────────────────
func _make_staff_slot(car, role: String) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl_role = Label.new()
	lbl_role.text = role
	lbl_role.add_theme_font_size_override("font_size", 20)
	lbl_role.modulate = Color(0.5,0.5,0.5)
	box.add_child(lbl_role)

	var is_driver = role == "DRIVER"
	var is_pit_crew = role == "PIT CREW"
	var assigned_id = ""
	var person = null
	if is_driver:
		assigned_id = car.driver_id
		person = GameState.all_drivers.get(assigned_id)
	elif is_pit_crew:
		assigned_id = car.pit_crew_id
		person = GameState.all_staff.get(assigned_id)
	else:
		assigned_id = car.mechanic_id
		person = GameState.all_staff.get(assigned_id)

	var lbl_name = Label.new()
	lbl_name.add_theme_font_size_override("font_size", 26)
	if person:
		lbl_name.text = person.full_name()
		lbl_name.add_theme_color_override("font_color", Color(0.9,0.9,0.9))
	else:
		lbl_name.text = "⚠ None assigned"
		lbl_name.add_theme_color_override("font_color", Color(1.0,0.55,0.2))
	box.add_child(lbl_name)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	box.add_child(btn_row)

	var btn_assign = Button.new()
	btn_assign.text = "Change" if person else "Assign"
	btn_assign.custom_minimum_size = Vector2(72, 26)
	btn_assign.add_theme_font_size_override("font_size", 22)
	var cap_car_id = car.id
	var cap_role = role
	btn_assign.pressed.connect(func(): _open_staff_popup(cap_car_id, cap_role))
	btn_row.add_child(btn_assign)

	if person:
		var btn_un = Button.new()
		btn_un.text = "Unassign"
		btn_un.custom_minimum_size = Vector2(72, 26)
		btn_un.add_theme_font_size_override("font_size", 22)
		btn_un.modulate = Color(1.0,0.5,0.5)
		btn_un.pressed.connect(func():
			if cap_role == "DRIVER": GameState.unassign_driver_from_car(cap_car_id)
			elif cap_role == "PIT CREW": GameState.unassign_pit_crew_from_car(cap_car_id)
			else: GameState.unassign_mechanic_from_car(cap_car_id)
			_show_tab(_selected_tab))
		btn_row.add_child(btn_un)

	return box

# ── Part slot card ────────────────────────────────────────────────────────────
func _build_part_slot(car, pcode: String, is_spec: bool, part_data: Dictionary) -> PanelContainer:
	var col = PART_COLORS.get(pcode, Color(0.5,0.5,0.5))
	var is_empty = part_data.is_empty()
	var bg = Color(0.07,0.08,0.11) if not is_empty else Color(0.10,0.08,0.08)
	var panel = _make_panel(bg, col if not is_empty else Color(0.4,0.2,0.2), 3)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# Part name + SPEC/OPEN badge
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	vbox.add_child(row1)

	var lbl_name = Label.new()
	## S35.11 — display the canonical part acronym (AER/ENG/GRB/SUS/BRK/CHS), the agreed
	## naming convention, instead of the long full name.
	lbl_name.text = pcode
	lbl_name.add_theme_font_size_override("font_size", 24)
	lbl_name.add_theme_color_override("font_color", col)
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(lbl_name)

	var lbl_spec = Label.new()
	lbl_spec.text = "SPEC" if is_spec else "OPEN"
	lbl_spec.add_theme_font_size_override("font_size", 18)
	lbl_spec.add_theme_color_override("font_color",
		Color(1.0,0.6,0.2) if is_spec else Color(0.4,0.88,0.55))
	row1.add_child(lbl_spec)

	# Installed part info
	if is_empty:
		## S35.11 (issue 5) — an empty slot is Level 0 (no part), shown as "L0" for consistency
		## with the level labels on filled slots and the "L0 (Provider)" picker entries.
		var lbl_empty = Label.new()
		lbl_empty.text = "L0"
		lbl_empty.add_theme_font_size_override("font_size", 22)
		lbl_empty.add_theme_color_override("font_color", Color(0.55,0.55,0.55))
		vbox.add_child(lbl_empty)
	else:
		var ptype  = part_data.get("type", "provider")
		var level  = part_data.get("level", 0)
		var rel    = part_data.get("reliability", 60.0)
		var qual   = part_data.get("quality", 1.0)
		var cond   = part_data.get("condition", 100.0)

		## Level label
		var lv_row = HBoxContainer.new()
		lv_row.add_theme_constant_override("separation", 6)
		vbox.add_child(lv_row)
		var lbl_lv = Label.new()
		lbl_lv.text = "L%d" % level
		lbl_lv.add_theme_font_size_override("font_size", 26)
		var lv_colors = {0:Color(0.55,0.55,0.55),1:Color(0.4,0.88,0.55),
			2:Color(0.55,0.75,1.0),3:Color(1.0,0.75,0.3),
			4:Color(1.0,0.45,0.45),5:Color(0.85,0.4,1.0)}
		lbl_lv.add_theme_color_override("font_color", lv_colors.get(level, Color(0.7,0.7,0.7)))
		lv_row.add_child(lbl_lv)
		if ptype == "provider":
			var lbl_prov = Label.new()
			lbl_prov.text = "Provider"
			lbl_prov.add_theme_font_size_override("font_size", 20)
			lbl_prov.modulate = Color(0.6,0.6,0.6)
			lv_row.add_child(lbl_prov)
		else:
			var lbl_cnc = Label.new()
			lbl_cnc.text = "CNC"
			lbl_cnc.add_theme_font_size_override("font_size", 20)
			lbl_cnc.add_theme_color_override("font_color", Color(0.4,0.9,0.4))
			lv_row.add_child(lbl_cnc)

		## Stats row
		var stats = Label.new()
		stats.text = "Rel: %.0f%%  Qual: %.2f×" % [rel, qual]
		stats.add_theme_font_size_override("font_size", 20)
		stats.modulate = Color(0.65,0.65,0.65)
		vbox.add_child(stats)

		## Condition bar
		var cond_row = HBoxContainer.new()
		cond_row.add_theme_constant_override("separation", 4)
		vbox.add_child(cond_row)
		var cond_lbl = Label.new()
		cond_lbl.text = "%.0f%%" % cond
		cond_lbl.add_theme_font_size_override("font_size", 20)
		var cc = Color(0.3,0.9,0.3) if cond > 60 else (Color(1.0,0.75,0.1) if cond > 30 else Color(1.0,0.3,0.3))
		cond_lbl.add_theme_color_override("font_color", cc)
		cond_row.add_child(cond_lbl)
		var bar = ProgressBar.new()
		bar.min_value = 0; bar.max_value = 100; bar.value = cond
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cond_row.add_child(bar)

	# Buttons row
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 4)
	vbox.add_child(btn_row)

	var cap_car_id = car.id
	var cap_pcode  = pcode
	var cap_cid    = car.championship_id
	## Parts are locked while the car is in build (cannot install/change/remove until delivered).
	var locked = car.is_in_build()

	if not is_empty:
		## Change button — opens part picker popup
		var btn_change = Button.new()
		btn_change.text = "Change"
		btn_change.custom_minimum_size = Vector2(62, 24)
		btn_change.add_theme_font_size_override("font_size", 20)
		btn_change.disabled = locked
		btn_change.pressed.connect(func(): _open_part_popup(cap_car_id, cap_pcode, cap_cid))
		btn_row.add_child(btn_change)
		## Remove button
		var btn_remove = Button.new()
		btn_remove.text = "Remove"
		btn_remove.custom_minimum_size = Vector2(62, 24)
		btn_remove.add_theme_font_size_override("font_size", 20)
		btn_remove.modulate = Color(1.0,0.5,0.5)
		btn_remove.disabled = locked
		var ptype2 = part_data.get("type","provider")
		btn_remove.pressed.connect(func():
			if ptype2 == "cnc": GameState.remove_part_from_car(cap_car_id, cap_pcode)
			else: GameState.remove_provider_part(cap_car_id, cap_pcode)
			_show_tab(_selected_tab))
		btn_row.add_child(btn_remove)
	else:
		## Install button — opens part picker popup
		var btn_install = Button.new()
		btn_install.text = "Install →"
		btn_install.custom_minimum_size = Vector2(72, 24)
		btn_install.add_theme_font_size_override("font_size", 20)
		btn_install.disabled = locked
		btn_install.pressed.connect(func(): _open_part_popup(cap_car_id, cap_pcode, cap_cid))
		btn_row.add_child(btn_install)

	return panel

# ── Part picker popup ─────────────────────────────────────────────────────────
func _open_part_popup(car_id: String, pcode: String, champ_id: String) -> void:
	_assigning_car_id = car_id
	_assigning_pcode  = pcode
	_popup_mode       = "part"
	_popup_title.text = "Install %s" % pcode

	for c in _popup_list.get_children(): c.queue_free()

	const PCODE_TO_NAME = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	var part_name = PCODE_TO_NAME.get(pcode, pcode)

	## ── CNC options ──────────────────────────────────────────────────────────
	var cnc_keys = GameState.get_cnc_stock_for_slot(champ_id, pcode)
	if not cnc_keys.is_empty():
		var sec = Label.new()
		sec.text = "CNC PARTS IN WAREHOUSE"
		sec.add_theme_font_size_override("font_size", 22)
		sec.add_theme_color_override("font_color", Color(0.4,0.9,0.4))
		_popup_list.add_child(sec)
		for inv_key in cnc_keys:
			var item = GameState.cnc_parts_inventory.get(inv_key, {})
			var bp_id = item.get("blueprint_id","")
			var lvl = 0
			if bp_id != "" and bp_id in GameState.known_blueprints:
				lvl = GameState.known_blueprints[bp_id].get("level", 0)
			var qty = item.get("quantity", 0)
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			_popup_list.add_child(row)
			var lbl = Label.new()
			## S35.11 — acronym + level keeps the row short so the Install button stays in view;
			## wrap as a safety net against long names clipping the button off the popup edge.
			lbl.text = "%s  L%d" % [pcode, lvl]
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.add_theme_font_size_override("font_size", 24)
			row.add_child(lbl)
			var lbl_qty = Label.new()
			lbl_qty.text = "×%d" % qty
			lbl_qty.add_theme_font_size_override("font_size", 22)
			lbl_qty.modulate = Color(0.6,0.6,0.6)
			row.add_child(lbl_qty)
			var btn = Button.new()
			btn.text = "Install"
			btn.custom_minimum_size = Vector2(64, 26)
			var cap_car = car_id; var cap_cid = champ_id; var cap_pc = pcode
			btn.pressed.connect(func():
				var ok = GameState.swap_part_on_car(cap_car, cap_cid, cap_pc)
				if ok:
					_popup.visible = false
					_show_tab(_selected_tab)
				else:
					GameState.add_notification("High", "Could not install that part — see log."))
			row.add_child(btn)

	## ── Provider (L0) options ─────────────────────────────────────────────────
	var prov_stock = GameState.get_part_stock(part_name, champ_id)
	if prov_stock > 0:
		_popup_list.add_child(HSeparator.new())
		var sec2 = Label.new()
		sec2.text = "PROVIDER PARTS (L0)"
		sec2.add_theme_font_size_override("font_size", 22)
		sec2.add_theme_color_override("font_color", Color(0.7,0.7,0.7))
		_popup_list.add_child(sec2)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_popup_list.add_child(row)
		var lbl = Label.new()
		lbl.text = "%s  L0  (Provider)" % part_name
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 24)
		row.add_child(lbl)
		var lbl_qty = Label.new()
		lbl_qty.text = "×%d" % prov_stock
		lbl_qty.add_theme_font_size_override("font_size", 22)
		lbl_qty.modulate = Color(0.6,0.6,0.6)
		row.add_child(lbl_qty)
		var btn = Button.new()
		btn.text = "Install"
		btn.custom_minimum_size = Vector2(64, 26)
		var cap_car = car_id; var cap_cid = champ_id; var cap_pc = pcode
		btn.pressed.connect(func():
			var ok = GameState.install_provider_part(cap_car, cap_cid, cap_pc)
			if ok:
				_popup.visible = false
				_show_tab(_selected_tab)
			else:
				GameState.add_notification("High", "Could not install that part — see log."))
		row.add_child(btn)

	if cnc_keys.is_empty() and prov_stock <= 0:
		var lbl_none = Label.new()
		lbl_none.text = "No parts available.\nBuy provider parts at Logistics or manufacture CNC parts."
		lbl_none.modulate = Color(0.5,0.5,0.5)
		lbl_none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_none.add_theme_font_size_override("font_size", 24)
		_popup_list.add_child(lbl_none)
		var btn_logi = Button.new()
		btn_logi.text = "→ Logistics"
		btn_logi.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/Logistics.tscn"))
		_popup_list.add_child(btn_logi)

	_popup.visible = true

# ── Staff assignment popup ────────────────────────────────────────────────────
func _open_staff_popup(car_id: String, role: String) -> void:
	_assigning_car_id = car_id
	_popup_mode = role.to_lower()
	_popup_title.text = "Assign %s" % role.capitalize()
	for c in _popup_list.get_children(): c.queue_free()

	var is_driver = role == "DRIVER"
	var is_pit_crew = role == "PIT CREW"
	## Show ALL team members of this type, not just unassigned
	var people: Array = []
	if is_driver:
		people = GameState.all_drivers.values()
	elif is_pit_crew:
		people = GameState.get_player_staff_by_role("Pit Crew")
	else:
		people = GameState.get_player_staff_by_role("Race Mechanic")
	var eligible = people.filter(func(p):
		return p.contract_team == GameState.player_team.id)

	if eligible.is_empty():
		var lbl = Label.new()
		var noun = "drivers"
		if is_pit_crew: noun = "pit crews"
		elif not is_driver: noun = "mechanics"
		lbl.text = "No %s on your team. Hire at %s." % [
			noun, "Pit Crew Arena" if is_pit_crew else "the Staff screen"]
		lbl.modulate = Color(0.5,0.5,0.5)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_popup_list.add_child(lbl)
		return

	## Sort: unassigned first, then assigned
	eligible.sort_custom(func(a, b):
		var a_assigned = _get_assignment_label(a, role) != ""
		var b_assigned = _get_assignment_label(b, role) != ""
		return int(a_assigned) < int(b_assigned))

	for p in eligible:
		var assignment_label = _get_assignment_label(p, role)
		var is_assigned_here = _is_assigned_to_car(p, car_id, role)

		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cstyle = StyleBoxFlat.new()
		cstyle.bg_color = Color(0.12, 0.16, 0.12) if is_assigned_here else Color(0.11, 0.12, 0.15)
		cstyle.border_width_left = 2
		cstyle.border_color = Color(0.3, 0.8, 0.35) if is_assigned_here \
			else (Color(0.5, 0.5, 0.5) if assignment_label != "" else Color(0.3, 0.55, 0.85))
		for corner in ["top_left","top_right","bottom_left","bottom_right"]:
			cstyle.set("corner_radius_%s" % corner, 4)
		cstyle.content_margin_left = 8; cstyle.content_margin_right = 8
		cstyle.content_margin_top = 6; cstyle.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", cstyle)
		_popup_list.add_child(card)

		var cvb = VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 3)
		card.add_child(cvb)

		## Name row
		var name_row = HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 8)
		cvb.add_child(name_row)

		var lbl_name = Label.new()
		lbl_name.text = p.full_name()
		lbl_name.add_theme_font_size_override("font_size", 26)
		lbl_name.add_theme_color_override("font_color",
			Color(0.4, 0.95, 0.5) if is_assigned_here else Color(0.9, 0.9, 1.0))
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_row.add_child(lbl_name)

		var lbl_age = Label.new()
		lbl_age.text = "Age %d" % p.age
		lbl_age.add_theme_font_size_override("font_size", 22)
		lbl_age.modulate = Color(0.5, 0.5, 0.5)
		name_row.add_child(lbl_age)

		## Assignment status badge
		if assignment_label != "":
			var lbl_assign = Label.new()
			lbl_assign.text = "← %s" % assignment_label
			lbl_assign.add_theme_font_size_override("font_size", 20)
			lbl_assign.add_theme_color_override("font_color",
				Color(0.4, 0.9, 0.4) if is_assigned_here else Color(0.6, 0.6, 0.6))
			name_row.add_child(lbl_assign)

		## Assign/Reassign button
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(70, 26)
		var cap_car = car_id; var cap_pid = p.id; var cap_role = role
		if is_assigned_here:
			btn.text = "✅ Assigned"
			btn.modulate = Color(0.4, 0.8, 0.45)
			btn.disabled = true
		else:
			btn.text = "Reassign" if assignment_label != "" else "Assign"
			btn.pressed.connect(func():
				if cap_role == "DRIVER": GameState.assign_driver_to_car(cap_pid, cap_car)
				elif cap_role == "PIT CREW": GameState.assign_pit_crew_to_car(cap_pid, cap_car)
				else: GameState.assign_staff_to_car(cap_pid, cap_car)
				_popup.visible = false
				_show_tab(_selected_tab))
		name_row.add_child(btn)

		## Stats row
		var stats_row = HBoxContainer.new()
		stats_row.add_theme_constant_override("separation", 10)
		cvb.add_child(stats_row)

		if is_driver:
			var ovr = int((p.pace + p.consistency + p.focus + p.race_craft + p.fitness) / 5.0)
			for pair in [["Ovr", ovr], ["Pace", int(p.pace)],
					["Cons", int(p.consistency)], ["Ctrl", int(p.car_control)], ["Fit", int(p.fitness)]]:
				_add_stat_chip(stats_row, pair[0], pair[1])
		elif is_pit_crew:
			var pspeed = int(p.pit_stop_speed) if "pit_stop_speed" in p else 50
			var prep   = int(p.repair_skill)   if "repair_skill"   in p else 50
			var pfat   = int(p.fatigue_resistance) if "fatigue_resistance" in p else 50
			for pair in [["Pit Speed", pspeed], ["Repair", prep], ["Fatigue", pfat]]:
				_add_stat_chip(stats_row, pair[0], pair[1])
		else:
			var setup = int(p.car_setup_skill)  if "car_setup_skill" in p else 50
			var pit   = int(p.pit_stop_skill)   if "pit_stop_skill"  in p else 50
			var know  = int(p.car_knowledge)    if "car_knowledge"   in p else 50
			for pair in [["Setup", setup], ["Pit", pit], ["Know", know]]:
				_add_stat_chip(stats_row, pair[0], pair[1])

	_popup.visible = true

func _get_assignment_label(person, role: String) -> String:
	for car in GameState.player_team_cars:
		var match_id = ""
		match role:
			"DRIVER":   match_id = car.driver_id
			"PIT CREW": match_id = car.pit_crew_id
			_:          match_id = car.mechanic_id
		if match_id == person.id:
			return car.car_name if car.car_name != "" else "Car %d" % car.car_number
	return ""

func _is_assigned_to_car(person, car_id: String, role: String) -> bool:
	var car = GameState.get_car_by_id(car_id)
	if not car: return false
	match role:
		"DRIVER":   return car.driver_id == person.id
		"PIT CREW": return car.pit_crew_id == person.id
		_:          return car.mechanic_id == person.id

func _add_stat_chip(parent: HBoxContainer, label: String, value: int) -> void:
	var chip = HBoxContainer.new()
	chip.add_theme_constant_override("separation", 2)
	parent.add_child(chip)
	var ll = Label.new()
	ll.text = label
	ll.add_theme_font_size_override("font_size", 20)
	ll.modulate = Color(0.45, 0.45, 0.45)
	chip.add_child(ll)
	var lv = Label.new()
	lv.text = str(value)
	lv.add_theme_font_size_override("font_size", 22)
	lv.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if value >= 70
		else Color(1.0, 0.85, 0.3) if value >= 50
		else Color(0.9, 0.4, 0.4))
	chip.add_child(lv)

# ── Navigation ────────────────────────────────────────────────────────────────
func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

# ── Helpers ───────────────────────────────────────────────────────────────────
func _car_name(car) -> String:
	return car.car_name if car.car_name != "" else "Car %d" % car.car_number

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.0fK" % (n / 1000.0)
	return str(n)

func _make_panel(bg: Color, border: Color, bw: int = 2) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = bw; style.border_width_right = 1
	style.border_width_top = 1;   style.border_width_bottom = 1
	style.border_color = border
	for corner in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_%s" % corner, 5)
	style.content_margin_left = 10; style.content_margin_right  = 10
	style.content_margin_top  = 8;  style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel
