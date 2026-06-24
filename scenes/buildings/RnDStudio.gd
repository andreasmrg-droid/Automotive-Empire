extends Control
## Version: S35.15 — Scroll moved to wrap ONLY the blueprint cards; pillar header + champ
##   tab grid are now fixed above it (per Andreas). The whole-column wrap was the wrong target.
## Version: S35.14 — (was S35.13) 2D tab grid + single ScrollContainer wrap around the whole
##   catalog column so it scrolls. If you see this version's print, the grid+scroll build is live.
## Version: S35.13 — Championship tabs are now a 2D GRID (was a single horizontal scrolling
##   strip): one ROW per discipline in principle order (GP…GK), tiers laid out horizontally
##   within each row (pinnacle → entry). Driven by GameState.championship_tab_grid().
## Version: S35.12b — BLUEPRINT STATUS panel ordered by the shared principle (GP1…GK) instead of
##   activation order; catalog scroll min-height 400→120 so SIZE_EXPAND_FILL bounds it and the
##   vertical scrollbar engages (cards were running off-screen with no scrollbar).
## Version: S35.12 — Championship tab strip (scrollable, shared GP1…GK order) in the catalog
##   column; Pillar 1/2/3 catalogs now show only the selected championship (P4 is building-gated,
##   champ-agnostic). Plus the L2-unlock fix moved to RnDEngine (_has_l1_blueprint_for now also
##   matches by completed L1 task id, so a legacy mis-stamped L1 no longer locks L2).
## Version: S35.11c — Two R&D Studio fixes: (1) the per-card Assign row now ALWAYS renders;
##   it used to appear only when RP+CR+free-designer were ALL satisfied, so with 0 RP (normal
##   before the first race — RP is earned only by racing) the assign buttons vanished and the
##   feature looked broken. Now buttons show disabled with a reason ("need N RP (have 0)").
##   (2) The long catalog card name now wraps — unwrapped it forced the catalog column past the
##   viewport and crushed the BLUEPRINT STATUS grid (col_d) to an invisible sliver.
## Version: S35.11 — (1) P1 Design catalog double-shift fix: the generator now stamps P1/P3
##   at design_season = current+1, so the live RND_TASKS already holds next-season blueprints.
##   The P1 catalog was regenerating with _build_rnd_tasks_for_season(next_season) → S{current+2}
##   → id lookup miss → NO research card/button. Now sources next_tasks from RND_TASKS directly.
##   (P2/P3 catalogs already sourced correctly — unaffected.)
##   (2) Localized R&D lock/hint strings (rnd_lock_*, rnd_re_hint_*) + L2 unlock-from-either-path
##   lock message.
## --- S29.12 — Localized Pillar 5 strings (p5_* keys): popup, catalog stub, and
##   name/desc via _pillar_name/_pillar_desc helpers (1–4 still use const dicts).
## --- S29.10 — Added Pillar 5 "COMMERCIAL CARS" button (stub): clicking shows a
##   coming-soon popup; reserved for the commercial car R&D system (future update).
## --- S29.9 — Pillar 1 next-season only (#5); catalog scroll min-height (#6).
## Version: S17.2 — Blueprint ownership grid added per championship (P1+P3 combined visual).
## R&D Design Studio
## P1 — All part blueprints, all championships, no filter
## P2 — Upgrade Open parts of owned cars only
## P3 — Reverse Engineer Spec parts the team owns (in part_inventory)
## P4 — Special Projects linked to buildings

const PILLAR_COLORS = {
	1: Color(0.2,  0.6,  1.0),
	2: Color(1.0,  0.65, 0.1),
	3: Color(0.55, 0.35, 1.0),
	4: Color(0.15, 0.85, 0.55),
	5: Color(0.9,  0.3,  0.55),  ## S29.10 — Commercial Cars R&D (future)
}
const PILLAR_NAMES = {
	1: "DESIGN",
	2: "UPGRADE",
	3: "REV. ENGINEERING",
	4: "SPECIAL PROJECTS",
	5: "COMMERCIAL CARS",
}
const PILLAR_DESCS = {
	1: "Design blueprints for any part.\nUnlocks CNC manufacturing once approved by WRA.",
	2: "Upgrade Open parts on your owned cars.\nIn-season improvements carry to next season.",
	3: "Reverse-engineer Spec parts you own.\nTeam must have the part in the warehouse.",
	4: "Building-linked special projects.\nUnlocks unique team capabilities and bonuses.",
	5: "Research for the commercial car business.\nComing in a future update.",
}
const PART_COLORS = {
	"Aero":       Color(0.25, 0.65, 1.0),
	"Engine":     Color(1.0,  0.4,  0.2),
	"Chassis":    Color(0.85, 0.55, 0.1),
	"Gearbox":    Color(0.65, 0.3,  0.9),
	"Brakes":     Color(1.0,  0.25, 0.25),
	"Suspension": Color(0.25, 0.85, 0.5),
}
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
const PART_NAMES = ["Aero", "Engine", "Gearbox", "Suspension", "Brakes", "Chassis"]

var _selected_pillar: int = 1
var _selected_champ_id: String = ""   ## S35.12 — active championship tab

func _ready() -> void:
	print(">>> RnDStudio S35.15 LOADED (scroll wraps blueprints only) <<<")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_selected_pillar = GameState.pending_rnd_pillar
	## S35.12 — default the championship tab to the first in the shared order (GP1…GK).
	if _selected_champ_id == "":
		var order = GameState.championship_tab_order()
		_selected_champ_id = order[0] if not order.is_empty() else "C-001"
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 20 if s in ["margin_left","margin_right"] else 14)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# ── Header ────────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)

	var lbl_title = Label.new()
	lbl_title.text = "🔬  R&D DESIGN STUDIO"
	lbl_title.add_theme_font_size_override("font_size", 42)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	var rp_box = _make_panel(Color(0.07, 0.10, 0.16))
	var rp_inner = HBoxContainer.new()
	rp_inner.add_theme_constant_override("separation", 8)
	rp_box.add_child(rp_inner)
	var lbl_rp_icon = Label.new()
	lbl_rp_icon.text = "🔵 RP"
	lbl_rp_icon.add_theme_font_size_override("font_size", 24)
	rp_inner.add_child(lbl_rp_icon)
	var rp_bar = ProgressBar.new()
	rp_bar.custom_minimum_size = Vector2(120, 16)
	rp_bar.min_value = 0
	rp_bar.max_value = max(1, GameState.get_rnd_rp_storage_cap())
	rp_bar.value = GameState.research_points
	rp_bar.show_percentage = false
	rp_inner.add_child(rp_bar)
	var lbl_rp = Label.new()
	lbl_rp.text = "%.0f / %d" % [GameState.research_points, GameState.get_rnd_rp_storage_cap()]
	lbl_rp.add_theme_font_size_override("font_size", 24)
	lbl_rp.add_theme_color_override("font_color", Color(0.45, 0.75, 1.0))
	rp_inner.add_child(lbl_rp)
	header.add_child(rp_box)

	var lbl_bal = Label.new()
	lbl_bal.text = "💰 %s" % _fmt(int(GameState.player_team.balance))
	lbl_bal.add_theme_font_size_override("font_size", 26)
	lbl_bal.add_theme_color_override("font_color", Color(0.5, 0.9, 0.4))
	header.add_child(lbl_bal)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(90, 34)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)

	root.add_child(_hsep())

	var bld = GameState.campus_buildings.get("R&D Design Studio", {})
	if not bld.get("built", false):
		var warn = Label.new()
		warn.text = "⚠  R&D Design Studio not built."
		warn.modulate = Color(1.0, 0.55, 0.2)
		root.add_child(warn)
		return

	# ── Pillar tab bar ─────────────────────────────────────────────────────────
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 6)
	root.add_child(tab_bar)

	for p in [1, 2, 3, 4, 5]:
		var btn = Button.new()
		btn.text = _pillar_name(p)
		btn.custom_minimum_size = Vector2(0, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 24)
		if p == _selected_pillar:
			btn.modulate = PILLAR_COLORS[p]
		var pid = p
		if pid == 5:
			## S29.10 — Pillar 5 (Commercial Cars R&D) is a stub for a future update.
			btn.modulate = PILLAR_COLORS[5].darkened(0.15)
			btn.pressed.connect(_show_p5_coming_soon)
		else:
			btn.pressed.connect(func():
				GameState.pending_rnd_pillar = pid
				get_tree().change_scene_to_file("res://scenes/buildings/RnDStudio.tscn")
			)
		tab_bar.add_child(btn)

	root.add_child(_hsep())

	# ── Three-column body ──────────────────────────────────────────────────────
	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var col_a = VBoxContainer.new()
	col_a.custom_minimum_size = Vector2(210, 0)
	col_a.add_theme_constant_override("separation", 8)
	body.add_child(col_a)
	_build_designer_column(col_a)

	var col_b = VBoxContainer.new()
	col_b.custom_minimum_size = Vector2(260, 0)
	col_b.add_theme_constant_override("separation", 8)
	body.add_child(col_b)
	_build_active_column(col_b)

	var col_c = VBoxContainer.new()
	col_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_c.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col_c.clip_contents = true   ## S35.13 — bound the column so its scroll actually scrolls
	col_c.add_theme_constant_override("separation", 8)
	body.add_child(col_c)
	_build_catalog_column(col_c)

	## Blueprint ownership grid — right-most column
	var col_d = VBoxContainer.new()
	col_d.custom_minimum_size = Vector2(220, 0)
	col_d.add_theme_constant_override("separation", 8)
	body.add_child(col_d)
	_build_blueprint_grid_column(col_d)


# ─── Column A ─────────────────────────────────────────────────────────────────
func _build_designer_column(parent: VBoxContainer) -> void:
	parent.add_child(_section_header("DESIGNERS", Color(1.0, 0.8, 0.0)))

	var building = GameState.campus_buildings.get("R&D Design Studio", {})
	var lv = building.get("level", 1)
	var lbl_slots = Label.new()
	lbl_slots.text = "Studio Lvl %d — %d concurrent task%s" % [lv, lv, "s" if lv != 1 else ""]
	lbl_slots.add_theme_font_size_override("font_size", 22)
	lbl_slots.modulate = Color(0.55, 0.55, 0.55)
	parent.add_child(lbl_slots)

	var designers = GameState.get_player_staff_by_role("Designer")
	if designers.is_empty():
		var lbl = Label.new()
		lbl.text = "No Designers hired."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 24)
		parent.add_child(lbl)
	else:
		for d in designers:
			parent.add_child(_build_designer_card(d))

	# Always-visible hire button
	var btn_hire = Button.new()
	btn_hire.text = "👤 Hire Designer  →  Staff"
	btn_hire.custom_minimum_size = Vector2(180, 32)
	btn_hire.add_theme_font_size_override("font_size", 24)
	btn_hire.pressed.connect(func():
		GameState.pending_staff_filter = "Designer"
		get_tree().change_scene_to_file("res://scenes/Staff.tscn")
	)
	parent.add_child(btn_hire)

	parent.add_child(_hsep())

	var lbl_comp = Label.new()
	lbl_comp.text = "COMPLETED  (%d)" % GameState.completed_rnd_tasks.size()
	lbl_comp.add_theme_font_size_override("font_size", 22)
	lbl_comp.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
	parent.add_child(lbl_comp)

	var comp_scroll = ScrollContainer.new()
	comp_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	comp_scroll.custom_minimum_size = Vector2(0, 60)
	parent.add_child(comp_scroll)
	var comp_vbox = VBoxContainer.new()
	comp_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comp_scroll.add_child(comp_vbox)
	for tid in GameState.completed_rnd_tasks:
		var td = GameState.RND_TASKS.get(tid, {})
		if td.is_empty(): continue
		var lbl_done = Label.new()
		lbl_done.text = "✅ %s" % td.get("name", tid)
		lbl_done.add_theme_font_size_override("font_size", 20)
		lbl_done.modulate = Color(0.42, 0.72, 0.42)
		lbl_done.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		comp_vbox.add_child(lbl_done)

func _build_designer_card(d) -> PanelContainer:
	var busy_task_name = ""
	var busy_wks = 0
	var busy_pct = 0.0
	var busy_champ = ""
	for t in GameState.active_rnd_tasks:
		if t["designer_id"] == d.id:
			busy_task_name = t["name"]
			busy_wks = t["weeks_remaining"]
			busy_pct = 1.0 - float(t["weeks_remaining"]) / float(t["weeks_total"])
			if t.get("championship_id", "") != "":
				var reg = GameState.CHAMPIONSHIP_REGISTRY.get(t["championship_id"], {})
				busy_champ = reg.get("name", "").left(16)
			break
	var is_busy = busy_task_name != ""

	var panel = _make_panel(Color(0.08, 0.14, 0.08) if is_busy else Color(0.07, 0.12, 0.09))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	vbox.add_child(row1)
	var icon = Label.new()
	icon.text = "🔧" if is_busy else "●"
	icon.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2) if is_busy else Color(0.3, 0.9, 0.4))
	row1.add_child(icon)
	var lbl_name = Label.new()
	lbl_name.text = d.full_name()
	lbl_name.add_theme_font_size_override("font_size", 24)
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2) if is_busy else Color(0.85, 0.85, 0.85))
	row1.add_child(lbl_name)
	var lbl_tal = Label.new()
	lbl_tal.text = "⭐%.0f" % d.talent
	lbl_tal.add_theme_font_size_override("font_size", 20)
	lbl_tal.modulate = Color(0.7, 0.7, 0.4)
	row1.add_child(lbl_tal)

	if is_busy:
		var lbl_task = Label.new()
		lbl_task.text = busy_task_name + (" · %s" % busy_champ if busy_champ != "" else "")
		lbl_task.add_theme_font_size_override("font_size", 20)
		lbl_task.modulate = Color(0.7, 0.7, 0.7)
		lbl_task.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_task)
		var bar = ProgressBar.new()
		bar.min_value = 0; bar.max_value = 100
		bar.value = busy_pct * 100.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 12)
		vbox.add_child(bar)
		var lbl_wks = Label.new()
		lbl_wks.text = "%d weeks left" % busy_wks
		lbl_wks.add_theme_font_size_override("font_size", 20)
		lbl_wks.modulate = Color(0.55, 0.55, 0.55)
		vbox.add_child(lbl_wks)
	else:
		var lbl_avail = Label.new()
		lbl_avail.text = "Available"
		lbl_avail.add_theme_font_size_override("font_size", 20)
		lbl_avail.modulate = Color(0.3, 0.9, 0.4)
		vbox.add_child(lbl_avail)

	return panel


# ─── Column B: Active Tasks ───────────────────────────────────────────────────
func _build_active_column(parent: VBoxContainer) -> void:
	parent.add_child(_section_header("ACTIVE TASKS", Color(1.0, 0.8, 0.0)))

	if GameState.active_rnd_tasks.is_empty():
		var lbl = Label.new()
		lbl.text = "No active research.\nSelect a task from the catalog →"
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(lbl)
		return

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 7)
	scroll.add_child(vbox)

	for task in GameState.active_rnd_tasks:
		vbox.add_child(_build_active_task_card(task))

func _build_active_task_card(task: Dictionary) -> PanelContainer:
	var p_color = PILLAR_COLORS.get(task.get("pillar", 1), Color.WHITE)
	var panel = _make_panel(Color(0.07, 0.12, 0.20))
	var style = panel.get_theme_stylebox("panel").duplicate()
	style.border_color = p_color.darkened(0.3)
	style.border_width_left = 3
	panel.add_theme_stylebox_override("panel", style)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)
	var lbl_p = Label.new()
	lbl_p.text = "P%d" % task.get("pillar", 1)
	lbl_p.add_theme_font_size_override("font_size", 20)
	lbl_p.add_theme_color_override("font_color", p_color)
	row1.add_child(lbl_p)
	var lbl_name = Label.new()
	lbl_name.text = task["name"]
	lbl_name.add_theme_font_size_override("font_size", 26)
	lbl_name.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row1.add_child(lbl_name)

	# Championship tag if set
	if task.get("championship_id", "") != "":
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(task["championship_id"], {})
		var lbl_c = Label.new()
		lbl_c.text = reg.get("name", task["championship_id"]).left(14)
		lbl_c.add_theme_font_size_override("font_size", 20)
		lbl_c.modulate = Color(0.55, 0.55, 0.55)
		vbox.add_child(lbl_c)

	var pct = 1.0 - float(task["weeks_remaining"]) / float(task["weeks_total"])
	var bar = ProgressBar.new()
	bar.min_value = 0; bar.max_value = 100
	bar.value = pct * 100.0
	bar.custom_minimum_size = Vector2(0, 14)
	bar.show_percentage = false
	vbox.add_child(bar)

	var lbl_prog = Label.new()
	lbl_prog.text = "Week %d / %d  (%d remaining)" % [
		task["weeks_total"] - task["weeks_remaining"], task["weeks_total"], task["weeks_remaining"]]
	lbl_prog.add_theme_font_size_override("font_size", 20)
	lbl_prog.modulate = Color(0.55, 0.55, 0.55)
	vbox.add_child(lbl_prog)

	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	vbox.add_child(row2)
	var designer = GameState.all_staff.get(task["designer_id"])
	var lbl_who = Label.new()
	lbl_who.text = "👤 %s" % (designer.full_name() if designer else "Unknown")
	lbl_who.add_theme_font_size_override("font_size", 20)
	lbl_who.modulate = Color(0.55, 0.55, 0.55)
	lbl_who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(lbl_who)
	var btn_cancel = Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.add_theme_font_size_override("font_size", 20)
	btn_cancel.modulate = Color(0.75, 0.35, 0.35)
	btn_cancel.custom_minimum_size = Vector2(58, 24)
	var tid = task["id"]
	btn_cancel.pressed.connect(func():
		GameState.cancel_rnd_task(tid)
		get_tree().change_scene_to_file("res://scenes/buildings/RnDStudio.tscn")
	)
	row2.add_child(btn_cancel)
	return panel


# ─── Column C: Catalog ────────────────────────────────────────────────────────
func _build_catalog_column(parent: VBoxContainer) -> void:
	## S35.14 — headers + championship tab grid are FIXED at the top of the column; only the
	## blueprint cards below scroll. (Per Andreas: the ScrollContainer belongs around the
	## blueprints, not the whole column / not the championship tabs.)
	var p_color = PILLAR_COLORS[_selected_pillar]

	var lbl_hdr = Label.new()
	lbl_hdr.text = "PILLAR %d — %s" % [_selected_pillar, _pillar_name(_selected_pillar)]
	lbl_hdr.add_theme_font_size_override("font_size", 28)
	lbl_hdr.add_theme_color_override("font_color", p_color)
	parent.add_child(lbl_hdr)

	var lbl_desc = Label.new()
	lbl_desc.text = _pillar_desc(_selected_pillar)
	lbl_desc.add_theme_font_size_override("font_size", 22)
	lbl_desc.modulate = Color(0.5, 0.5, 0.5)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(lbl_desc)

	parent.add_child(_hsep())

	## Championship tab grid (2D: disciplines as rows, tiers across) — FIXED, does not scroll.
	parent.add_child(_build_champ_tab_strip())
	parent.add_child(_hsep())

	## ScrollContainer wraps ONLY the blueprint list. It fills the remaining column height
	## (SIZE_EXPAND_FILL) below the fixed headers/tabs, so the cards scroll within it.
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 7)
	scroll.add_child(inner)

	var free_designers = GameState.get_player_staff_by_role("Designer").filter(func(d):
		for t in GameState.active_rnd_tasks:
			if t["designer_id"] == d.id: return false
		return true
	)

	match _selected_pillar:
		1: _build_p1_catalog(inner, free_designers)
		2: _build_p2_catalog(inner, free_designers)
		3: _build_p3_catalog(inner, free_designers)
		4: _build_p4_catalog(inner, free_designers)
		5: inner.add_child(_lbl_empty(Locale.t("p5_catalog_stub")))



# ── P1: All blueprints for all parts, all championships ───────────────────────
func _build_p1_catalog(parent: VBoxContainer, free_designers: Array) -> void:
	var season     = GameState.current_season
	var next_season = season + 1

	## Find all P1 tasks grouped by championship and part
	## Show per championship: Current S L1 → (if done) Current S L2
	##                        Next S L1    → (if done) Next S L2

	## Group tasks by championship_id
	var by_champ: Dictionary = {}
	for task_id in GameState.RND_TASKS:
		var t = GameState.RND_TASKS[task_id]
		if t["pillar"] != 1: continue
		var cid = t.get("championship_id", "")
		if not cid in by_champ:
			by_champ[cid] = []
		by_champ[cid].append({"id": task_id, "task": t})

	## S35.11 — The generator now stamps P1/P3 at design_season = current+1, so the live
	## RND_TASKS ALREADY contains next-season blueprints (ids carry S{current+1}). The old
	## code regenerated with _build_rnd_tasks_for_season(next_season), which double-shifted
	## to S{current+2} and broke the id lookup → no research card/button appeared. Source
	## directly from RND_TASKS now; no on-the-fly regeneration.
	var next_tasks = GameState.RND_TASKS

	if by_champ.is_empty():
		parent.add_child(_lbl_empty("No blueprint tasks defined."))
		return

	## S35.12 — show only the selected championship tab (multi-champ tabbed UI).
	var sorted_champs = [_selected_champ_id] if _selected_champ_id in by_champ else []
	if sorted_champs.is_empty():
		parent.add_child(_lbl_empty("No blueprint tasks for this championship."))
		return

	## For each championship show current season then next season
	for cid in sorted_champs:
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var champ_name = reg.get("name", cid)
		var is_formula = cid in ["C-021","C-022","C-023","C-024"]

		## Championship header
		var lbl_champ = Label.new()
		lbl_champ.text = champ_name
		lbl_champ.add_theme_font_size_override("font_size", 26)
		lbl_champ.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		parent.add_child(lbl_champ)

		## ── Current-season blueprints removed (S29.9, issue #5): the current
		## season's car is already locked in / not actionable, so only NEXT
		## season's blueprints are shown here. We still derive parts_seen from
		## the current-season task list so the next-season section knows which
		## parts this championship uses.
		var parts_seen: Array = []
		for entry in by_champ[cid]:
			var t = entry["task"]
			if t.get("level", 1) == 1:
				var part = t.get("part", "")
				if not part in parts_seen:
					parts_seen.append(part)

		## ── Next season tasks ─────────────────────────────────────────
		var next_lbl = Label.new()
		if is_formula:
			next_lbl.text = "▶ Next Season (S%d) — ⚠ MANDATORY for Formula" % next_season
			next_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		else:
			next_lbl.text = "▶ Next Season (S%d)" % next_season
			next_lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
		next_lbl.add_theme_font_size_override("font_size", 24)
		parent.add_child(next_lbl)

		for part in parts_seen:
			## Build next season L1 task_id
			var pcode = {"Aero":"AER","Engine":"ENG","Gearbox":"GRB",
				"Suspension":"SUS","Brakes":"BRK","Chassis":"CHS"}.get(part, "AER")
			var code = GameState.CHAMP_CODES.get(cid, "")
			var ns_l1_id = "BP-%s-%s-S%d-L1" % [code, pcode, next_season]
			var ns_l2_id = "BP-%s-%s-S%d-L2" % [code, pcode, next_season]

			if ns_l1_id in next_tasks:
				var t = next_tasks[ns_l1_id]
				## Next season L1 has no prerequisite — always unlocked
				## Pass next_tasks so _build_task_card can resolve any requires text
				parent.add_child(_build_task_card_with_unlock(
					ns_l1_id, t, free_designers, cid, next_tasks, true))
				## Show next season L2 only if next season L1 is done
				var ns_l1_done = ns_l1_id in GameState.completed_rnd_tasks
				if ns_l1_done and ns_l2_id in next_tasks:
					parent.add_child(_build_task_card_with_unlock(
						ns_l2_id, next_tasks[ns_l2_id], free_designers, cid, next_tasks, false))

		parent.add_child(_hsep())


# ── P2: Open parts of owned cars only — show ONLY next available upgrade level ─
func _build_p2_catalog(parent: VBoxContainer, free_designers: Array) -> void:
	if GameState.player_team_cars.is_empty():
		parent.add_child(_lbl_empty("No cars owned. Buy a car at the Logistics Center."))
		return

	var any_shown = false
	for car in GameState.player_team_cars:
		var cid = car.championship_id
		if cid == "": continue
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var spec_arr = PART_SPEC.get(cid, [false,false,false,false,false,false])
		var open_parts: Array = []
		for i in range(PART_NAMES.size()):
			if not spec_arr[i]:
				open_parts.append(PART_NAMES[i])

		if open_parts.is_empty():
			var lbl = Label.new()
			lbl.text = "🏎 %s  [%s] — All parts are Spec. No upgrades available." % [
				car.car_name if car.car_name != "" else "Car %d" % car.car_number,
				reg.get("name", cid)]
			lbl.add_theme_font_size_override("font_size", 24)
			lbl.modulate = Color(0.5, 0.5, 0.5)
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			parent.add_child(lbl)
			parent.add_child(_hsep())
			continue

		# Car header
		var lbl_car = Label.new()
		lbl_car.text = "🏎 %s  —  %s" % [
			car.car_name if car.car_name != "" else "Car %d" % car.car_number,
			reg.get("name", cid)]
		lbl_car.add_theme_font_size_override("font_size", 26)
		lbl_car.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		parent.add_child(lbl_car)

		var lbl_open = Label.new()
		lbl_open.text = "Open parts (upgradeable): %s" % ", ".join(open_parts)
		lbl_open.add_theme_font_size_override("font_size", 22)
		lbl_open.modulate = Color(0.4, 0.88, 0.55)
		parent.add_child(lbl_open)

		# For each open part, find and show ONLY the next available upgrade level
		for part in open_parts:
			# Get part code for ID matching
			const PART_CODES_MAP = {
				"Aero":"AER","Engine":"ENG","Gearbox":"GRB",
				"Suspension":"SUS","Brakes":"BRK","Chassis":"CHS"
			}
			var pcode = PART_CODES_MAP.get(part, part.to_upper().left(3))
			var season = GameState.current_season

			# Find the highest completed upgrade level for this part/champ/season
			var highest_done = 0
			for lv in range(1, 6):
				var check_id = "UPG-%s-%s-S%d-L%d" % [
					GameState.CHAMP_CODES.get(cid, cid), pcode, season, lv]
				if check_id in GameState.completed_rnd_tasks:
					highest_done = lv
				else:
					break  # Levels must be sequential

			# Next level to research
			var next_lv = highest_done + 1
			if next_lv > 5:
				# All 5 levels done for this part
				var lbl_max = Label.new()
				lbl_max.text = "  %s — Max upgrade (L5) complete ✅" % part
				lbl_max.add_theme_font_size_override("font_size", 22)
				lbl_max.add_theme_color_override("font_color", Color(0.4, 0.82, 0.4))
				parent.add_child(lbl_max)
				any_shown = true
				continue

			var next_id = "UPG-%s-%s-S%d-L%d" % [
				GameState.CHAMP_CODES.get(cid, cid), pcode, season, next_lv]

			if next_id in GameState.RND_TASKS:
				var t = GameState.RND_TASKS[next_id]
				# Show current progress indicator
				if highest_done > 0:
					var lbl_prog = Label.new()
					lbl_prog.text = "  %s — L%d complete, researching L%d" % [part, highest_done, next_lv]
					lbl_prog.add_theme_font_size_override("font_size", 22)
					lbl_prog.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
					parent.add_child(lbl_prog)
				parent.add_child(_build_task_card(next_id, t, free_designers, cid))
				any_shown = true

		parent.add_child(_hsep())

	if not any_shown:
		parent.add_child(_lbl_empty("No upgrade tasks available for your current cars."))


# ── P3: Spec parts the team owns (in part_inventory) ─────────────────────────
func _build_p3_catalog(parent: VBoxContainer, free_designers: Array) -> void:
	if GameState.player_team_cars.is_empty():
		parent.add_child(_lbl_empty("No cars owned. Buy a car at the Logistics Center."))
		return

	var any_shown = false
	for car in GameState.player_team_cars:
		var cid = car.championship_id
		if cid == "": continue
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var spec_arr = PART_SPEC.get(cid, [true,true,true,true,true,true])
		var inv = GameState.part_inventory.get(cid, {})

		# Spec parts that the team HAS in warehouse
		var owned_spec: Array = []
		for i in range(PART_NAMES.size()):
			if spec_arr[i] and inv.get(PART_NAMES[i], 0) > 0:
				owned_spec.append(PART_NAMES[i])

		# Spec parts the team does NOT have
		var missing_spec: Array = []
		for i in range(PART_NAMES.size()):
			if spec_arr[i] and inv.get(PART_NAMES[i], 0) <= 0:
				missing_spec.append(PART_NAMES[i])

		var all_open = true
		for v in PART_SPEC.get(cid, [false,false,false,false,false,false]):
			if v: all_open = false; break
		if all_open:
			var lbl = Label.new()
			lbl.text = "🏎 %s  [%s] — All parts Open. Nothing to Reverse Engineer." % [
				car.car_name if car.car_name != "" else "Car %d" % car.car_number,
				reg.get("name", cid)]
			lbl.add_theme_font_size_override("font_size", 24)
			lbl.modulate = Color(0.5, 0.5, 0.5)
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			parent.add_child(lbl)
			parent.add_child(_hsep())
			continue

		var lbl_car = Label.new()
		lbl_car.text = "🏎 %s  —  %s" % [
			car.car_name if car.car_name != "" else "Car %d" % car.car_number,
			reg.get("name", cid)]
		lbl_car.add_theme_font_size_override("font_size", 26)
		lbl_car.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		parent.add_child(lbl_car)

		if not owned_spec.is_empty():
			var lbl_ok = Label.new()
			lbl_ok.text = "✅ Can RE: %s" % ", ".join(owned_spec)
			lbl_ok.add_theme_font_size_override("font_size", 22)
			lbl_ok.modulate = Color(0.4, 0.88, 0.55)
			parent.add_child(lbl_ok)

		if not missing_spec.is_empty():
			var lbl_miss = Label.new()
			lbl_miss.text = "🔒 Need to buy: %s" % ", ".join(missing_spec)
			lbl_miss.add_theme_font_size_override("font_size", 22)
			lbl_miss.modulate = Color(0.65, 0.45, 0.2)
			parent.add_child(lbl_miss)

		if owned_spec.is_empty():
			var lbl_no = Label.new()
			lbl_no.text = "Buy spec parts at Logistics Center to unlock RE."
			lbl_no.add_theme_font_size_override("font_size", 22)
			lbl_no.modulate = Color(0.5, 0.5, 0.5)
			parent.add_child(lbl_no)
		else:
			var lbl_re_hint = Label.new()
			lbl_re_hint.text = Locale.t("rnd_re_hint_long")
			lbl_re_hint.add_theme_font_size_override("font_size", 20)
			lbl_re_hint.modulate = Color(0.5, 0.75, 1.0)
			lbl_re_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			parent.add_child(lbl_re_hint)
			for task_id in GameState.RND_TASKS:
				var t = GameState.RND_TASKS[task_id]
				if t["pillar"] != 3: continue
				if t.get("championship_id", "") != cid: continue
				if not t["part"] in owned_spec: continue
				parent.add_child(_build_task_card(task_id, t, free_designers, cid))
				any_shown = true

		parent.add_child(_hsep())

	if not any_shown:
		parent.add_child(_lbl_empty(
			"No Spec parts owned yet. Buy parts at the Logistics Center warehouse to unlock Reverse Engineering."))


## S29.12 — Pillar 5 name/desc come from Locale; 1–4 remain in the const dicts
## (pre-existing strings, not part of this localization pass).
func _pillar_name(p: int) -> String:
	if p == 5: return Locale.t("p5_name")
	return PILLAR_NAMES.get(p, "")

func _pillar_desc(p: int) -> String:
	if p == 5: return Locale.t("p5_desc")
	return PILLAR_DESCS.get(p, "")

# ── P5: Commercial Cars R&D (stub — future update) ────────────────────────────
## S29.10 — Pillar 5 is reserved for the commercial car business R&D. The button
## exists now so the pillar bar is stable; clicking it shows this notice.
func _show_p5_coming_soon() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = Locale.t("p5_popup_title")
	dialog.dialog_text = Locale.t("p5_popup_body")
	dialog.ok_button_text = Locale.t("btn_close")
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


# ── P4: Special Projects ───────────────────────────────────────────────────────
func _build_p4_catalog(parent: VBoxContainer, free_designers: Array) -> void:
	var any = false
	for task_id in GameState.RND_TASKS:
		var t = GameState.RND_TASKS[task_id]
		if t["pillar"] != 4: continue
		parent.add_child(_build_task_card(task_id, t, free_designers, ""))
		any = true
	if not any:
		parent.add_child(_lbl_empty("No special projects available yet."))


# ── Generic task card ──────────────────────────────────────────────────────────
func _build_task_card(task_id: String, task: Dictionary, free_designers: Array, champ_id: String, extra_tasks: Dictionary = {}) -> PanelContainer:
	return _build_task_card_with_unlock(task_id, task, free_designers, champ_id, extra_tasks, GameState.rnd_task_unlocked(task_id))

## Allows forcing unlock state — used for next-season tasks not in RND_TASKS
func _build_task_card_with_unlock(task_id: String, task: Dictionary, free_designers: Array, champ_id: String, extra_tasks: Dictionary, force_unlocked: bool) -> PanelContainer:
	var is_done   = task_id in GameState.completed_rnd_tasks
	var is_active = false
	for t in GameState.active_rnd_tasks:
		if t["id"] == task_id: is_active = true; break

	var unlocked = force_unlocked
	var can_rp   = GameState.research_points >= task["rp"]
	var can_cr   = GameState.player_team.balance >= task["cr"]
	var has_free = not free_designers.is_empty()

	var bg = Color(0.09, 0.12, 0.16)
	if is_done:        bg = Color(0.07, 0.14, 0.07)
	elif is_active:    bg = Color(0.07, 0.12, 0.22)
	elif not unlocked: bg = Color(0.09, 0.09, 0.11)

	var panel = _make_panel(bg)
	var style = panel.get_theme_stylebox("panel").duplicate()
	var p_color = PILLAR_COLORS.get(task["pillar"], Color.WHITE)
	style.border_width_left = 4
	style.border_color = p_color.darkened(0.4) if is_done else p_color
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Row 1: name + level badge + part badge + status
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)
	var lbl_name = Label.new()
	lbl_name.text = task["name"]
	lbl_name.add_theme_font_size_override("font_size", 26)
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	## S35.11b — wrap: the long card name was unwrapped + EXPAND_FILL, forcing the catalog
	## column wider than the viewport and crushing the BLUEPRINT STATUS grid (col_d) to a
	## sliver. Wrapping bounds the name to the column's share.
	lbl_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if is_done: lbl_name.add_theme_color_override("font_color", Color(0.4, 0.82, 0.4))
	elif not unlocked: lbl_name.modulate = Color(0.4, 0.4, 0.4)
	row1.add_child(lbl_name)

	## Level badge — L1 / L2 / L3 etc
	var level = task.get("level", 0)
	if level > 0:
		var lbl_lv = Label.new()
		lbl_lv.text = "L%d" % level
		lbl_lv.add_theme_font_size_override("font_size", 20)
		var lv_colors = {1: Color(0.4, 0.88, 0.55), 2: Color(0.55, 0.75, 1.0),
			3: Color(1.0, 0.75, 0.3), 4: Color(1.0, 0.45, 0.45), 5: Color(0.85, 0.4, 1.0)}
		lbl_lv.add_theme_color_override("font_color", lv_colors.get(level, Color(0.7, 0.7, 0.7)))
		row1.add_child(lbl_lv)

	var lbl_part = Label.new()
	lbl_part.text = task["part"]
	lbl_part.add_theme_font_size_override("font_size", 20)
	lbl_part.add_theme_color_override("font_color", PART_COLORS.get(task["part"], Color.WHITE))
	row1.add_child(lbl_part)
	if is_done:
		var lbl_ok = Label.new(); lbl_ok.text = "✅"; row1.add_child(lbl_ok)
	elif is_active:
		var lbl_p = Label.new(); lbl_p.text = "🔬 In progress"
		lbl_p.add_theme_font_size_override("font_size", 20); lbl_p.modulate = Color(0.4, 0.7, 1.0)
		row1.add_child(lbl_p)

	# Row 2: costs / lock / assign
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	vbox.add_child(row2)

	if is_done:
		## Show WRA submission status
		var bp_id = task_id
		if GameState.is_blueprint_approved(bp_id):
			var lbl_wra = Label.new()
			lbl_wra.text = "✅ WRA Approved — ready for CNC manufacturing"
			lbl_wra.add_theme_font_size_override("font_size", 22)
			lbl_wra.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			row2.add_child(lbl_wra)
		elif GameState.is_blueprint_submitted(bp_id):
			var lbl_wra = Label.new()
			lbl_wra.text = "⏳ Submitted to WRA — awaiting approval"
			lbl_wra.add_theme_font_size_override("font_size", 22)
			lbl_wra.modulate = Color(0.7, 0.7, 0.4)
			row2.add_child(lbl_wra)
		elif bp_id in GameState.known_blueprints:
			var btn_wra = Button.new()
			btn_wra.text = "📋 Send to WRA for Approval →"
			btn_wra.custom_minimum_size = Vector2(0, 28)
			btn_wra.add_theme_font_size_override("font_size", 22)
			btn_wra.pressed.connect(func():
				GameState.pending_hq_tab = "wra_office"
				get_tree().change_scene_to_file("res://scenes/buildings/HQ.tscn"))
			row2.add_child(btn_wra)
		## P3 RE hint: completing RE unlocks P1 L2
		if task.get("pillar", 0) == 3:
			var lbl_hint = Label.new()
			lbl_hint.text = Locale.t("rnd_re_hint_short")
			lbl_hint.add_theme_font_size_override("font_size", 20)
			lbl_hint.modulate = Color(0.5, 0.75, 1.0)
			vbox.add_child(lbl_hint)
	elif is_active:
		pass
	elif not unlocked:
		var lbl_lock = Label.new()
		var req_l1 = task.get("requires_l1_for", "")
		var req_id = task.get("requires", "")
		if req_l1 != "":
			## S35.11 — P1 L2 gates on an L1 blueprint existing from EITHER P1 or P3.
			lbl_lock.text = Locale.t("rnd_lock_needs_l1")
		else:
			var req = GameState.RND_TASKS.get(req_id, extra_tasks.get(req_id, {}))
			var req_name = req.get("name", "") if not req.is_empty() else ""
			if req_name != "":
				lbl_lock.text = Locale.t("rnd_lock_requires") % req_name
			else:
				lbl_lock.text = Locale.t("rnd_lock_complete_l1") % GameState.current_season
		lbl_lock.add_theme_font_size_override("font_size", 22)
		lbl_lock.modulate = Color(0.5, 0.5, 0.5)
		lbl_lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_lock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(lbl_lock)
	else:
		for pair in [
			["🔵 %d RP" % task["rp"],       can_rp],
			["💰 CR %s" % _fmt(task["cr"]), can_cr],
			["⏱ %d wks" % task["weeks"],    true],
			[_fmt_effect(task),              true],
		]:
			var cl = Label.new()
			cl.text = pair[0]
			cl.add_theme_font_size_override("font_size", 22)
			cl.add_theme_color_override("font_color",
				Color(0.45, 0.88, 0.45) if pair[1] else Color(1.0, 0.35, 0.35))
			row2.add_child(cl)

		## S35.11b — always render the Assign row. Previously it only appeared when
		## has_free AND can_rp AND can_cr were all true, so with 0 RP (or no free designer)
		## the controls vanished entirely and looked broken. Now the row always shows, with
		## buttons disabled and a clear reason when research can't start.
		var btn_row = HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 6)
		vbox.add_child(btn_row)
		var lbl_a = Label.new(); lbl_a.text = "Assign:"
		lbl_a.add_theme_font_size_override("font_size", 22)
		lbl_a.modulate = Color(0.55, 0.55, 0.55)
		btn_row.add_child(lbl_a)

		var blockers: Array = []
		if not can_rp: blockers.append("need %d RP (have %d)" % [task["rp"], GameState.research_points])
		if not can_cr: blockers.append("need CR %s" % _fmt(task["cr"]))
		if not has_free: blockers.append("no free designer")
		var can_start = can_rp and can_cr and has_free

		if has_free:
			for designer in free_designers:
				var btn = Button.new()
				btn.text = designer.full_name().split(" ")[0]
				btn.custom_minimum_size = Vector2(72, 26)
				btn.add_theme_font_size_override("font_size", 22)
				btn.disabled = not can_start
				btn.modulate = p_color.lightened(0.1) if can_start else Color(0.4,0.4,0.4)
				var did = designer.id
				var tid = task_id
				var cid = champ_id
				var etasks = extra_tasks
				btn.pressed.connect(func():
					if not tid in GameState.RND_TASKS and tid in etasks:
						GameState.RND_TASKS[tid] = etasks[tid]
					GameState.start_rnd_task(tid, did, cid)
					get_tree().change_scene_to_file("res://scenes/buildings/RnDStudio.tscn")
				)
				btn_row.add_child(btn)

		if not blockers.is_empty():
			var lbl_block = Label.new()
			lbl_block.text = "⚠ " + ", ".join(blockers)
			lbl_block.add_theme_font_size_override("font_size", 20)
			lbl_block.modulate = Color(0.75, 0.5, 0.2)
			lbl_block.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn_row.add_child(lbl_block)

	return panel


# ─── Helpers ──────────────────────────────────────────────────────────────────
func _fmt_effect(task: Dictionary) -> String:
	var key   = task.get("effect", "")
	var value = task.get("value",  0.0)
	if task.get("desc", "") != "": return task["desc"].left(40)
	match key:
		"aero_perf","engine_perf","chassis_perf","gearbox_perf","brakes_perf","susp_perf":
			return "+%.0f%% %s perf" % [value * 100.0, task.get("part","")]
		"car_top_speed":       return "+%.0f km/h top speed" % value
		"car_cornering_grip":  return "+%.0f%% cornering" % (value * 100.0)
		"car_acceleration":    return "+%.1f m/s² accel" % value
		"car_deceleration":    return "+%.1f m/s² braking" % value
		"car_baseline_perf":   return "+%.1f perf index" % value
		_:
			if key.begins_with("unlock_"): return "🔓 Unlocks CNC mfg"
			return key

func _lbl_empty(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.modulate = Color(0.5, 0.5, 0.5)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

func _section_header(text: String, color: Color) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _hsep() -> HSeparator: return HSeparator.new()

## S35.13 — Championship tab GRID: one ROW per discipline (ordered by principle GP…GK),
## tiers laid out horizontally within each row (pinnacle → entry). Clicking a tab rebuilds the
## Studio scoped to that championship. Replaces the old single horizontal scrolling strip.
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
				_rebuild_studio())
			row.add_child(btn)
	return grid_box

## S35.12 — Rebuild the Studio in place (preserves _selected_champ_id + _selected_pillar)
## after a championship tab change.
func _rebuild_studio() -> void:
	for c in get_children(): c.queue_free()
	_build_ui()


func _make_panel(bg: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 3; style.border_width_right  = 1
	style.border_width_top  = 1; style.border_width_bottom = 1
	style.border_color = Color(0.22, 0.32, 0.48)
	style.corner_radius_top_left    = 4; style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	style.content_margin_left  = 10; style.content_margin_right  = 10
	style.content_margin_top   = 8;  style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.0fK" % (n / 1000.0)
	return str(n)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

# ─── Blueprint Ownership Grid ─────────────────────────────────────────────────
## Shows P1 (BP) and P3 (RE) status per part per championship.
## Legend: ✅ owned  🔬 in progress  ⏳ WRA pending  🟢 WRA approved  ⬜ not started
func _build_blueprint_grid_column(parent: VBoxContainer) -> void:
	parent.add_child(_section_header("BLUEPRINT STATUS", Color(0.7, 0.8, 1.0)))

	## Legend
	var legend = Label.new()
	legend.text = "✅ owned  🔬 active  ⏳ WRA  🟢 approved"
	legend.add_theme_font_size_override("font_size", 18)
	legend.modulate = Color(0.5, 0.5, 0.5)
	parent.add_child(legend)

	## S35.12 — order the status panel by the shared principle order (GP1…GK), same as the
	## tab strip, instead of activation order.
	var champ_ids = GameState.championship_tab_order()
	if champ_ids.is_empty():
		parent.add_child(_lbl_empty("No championships."))
		return

	for cid in champ_ids:
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var grid_data = GameState.get_blueprint_grid(cid)

		## Championship header
		var lbl_champ = Label.new()
		lbl_champ.text = reg.get("name", cid)
		lbl_champ.add_theme_font_size_override("font_size", 22)
		lbl_champ.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
		parent.add_child(lbl_champ)

		## Grid: header row
		var grid = GridContainer.new()
		grid.columns = 8  ## part name + L1 L2 L3 L4 L5 + RE + spacer
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 3)
		parent.add_child(grid)

		## Header labels
		for hdr_text in ["", "L1","L2","L3","L4","L5","RE",""]:
			var h = Label.new()
			h.text = hdr_text
			h.add_theme_font_size_override("font_size", 18)
			h.add_theme_color_override("font_color", Color(0.5,0.5,0.5))
			h.custom_minimum_size = Vector2(22, 0)
			h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			grid.add_child(h)

		## Part rows
		const PCODES = ["AER","ENG","GRB","SUS","BRK","CHS"]
		const PSHORT = {"AER":"AER","ENG":"ENG","GRB":"GRB","SUS":"SUS","BRK":"BRK","CHS":"CHS"}
		for pcode in PCODES:
			var pd = grid_data.get(pcode, {})
			var p_color = PART_COLORS.get(CONST_PCODE_TO_PART.get(pcode,""), Color(0.6,0.6,0.6))

			## Part name cell
			var lbl_p = Label.new()
			lbl_p.text = PSHORT.get(pcode, pcode)
			lbl_p.add_theme_font_size_override("font_size", 18)
			lbl_p.add_theme_color_override("font_color", p_color)
			lbl_p.custom_minimum_size = Vector2(30, 0)
			grid.add_child(lbl_p)

			## L1–L5 cells
			for lvl in [1,2,3,4,5]:
				var cell = Label.new()
				cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cell.custom_minimum_size = Vector2(22, 0)
				cell.add_theme_font_size_override("font_size", 22)
				var owned_levels: Array = pd.get("bp_levels", [])
				if lvl in owned_levels:
					cell.text = "✅"
				elif _is_level_wra_approved(pcode, lvl, cid):
					cell.text = "🟢"
				elif _is_level_wra_pending(pcode, lvl, cid):
					cell.text = "⏳"
				elif _is_level_in_progress(pcode, lvl, cid):
					cell.text = "🔬"
				else:
					cell.text = "⬜"
					cell.modulate = Color(0.4,0.4,0.4)
				grid.add_child(cell)

			## RE cell
			var re_cell = Label.new()
			re_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			re_cell.custom_minimum_size = Vector2(22, 0)
			re_cell.add_theme_font_size_override("font_size", 22)
			var re_done: bool = pd.get("re", false)
			if re_done:
				re_cell.text = "✅"
			elif _is_re_wra_approved(pcode, cid):
				re_cell.text = "🟢"
			elif _is_re_wra_pending(pcode, cid):
				re_cell.text = "⏳"
			elif _is_re_in_progress(pcode, cid):
				re_cell.text = "🔬"
			else:
				re_cell.text = "⬜"
				re_cell.modulate = Color(0.4,0.4,0.4)
			grid.add_child(re_cell)

			## Empty spacer cell
			grid.add_child(Control.new())

		parent.add_child(_hsep())

const CONST_PCODE_TO_PART = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
	"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}

func _is_level_wra_approved(pcode: String, lvl: int, champ_id: String) -> bool:
	for app in GameState.wra_approved_blueprints:
		var bp = GameState.known_blueprints.get(app.get("blueprint_id",""), {})
		if bp.get("championship_id","") == champ_id and bp.get("pillar",0) == 1 \
				and GameState._part_name_to_pcode(bp.get("part","")) == pcode \
				and bp.get("level",0) == lvl: return true
	return false

func _is_level_wra_pending(pcode: String, lvl: int, champ_id: String) -> bool:
	for sub in GameState.active_wra_submissions:
		var bp = GameState.known_blueprints.get(sub.get("blueprint_id",""), {})
		if bp.get("championship_id","") == champ_id and bp.get("pillar",0) == 1 \
				and GameState._part_name_to_pcode(bp.get("part","")) == pcode \
				and bp.get("level",0) == lvl: return true
	return false

func _is_level_in_progress(pcode: String, lvl: int, champ_id: String) -> bool:
	for t in GameState.active_rnd_tasks:
		var tid = t.get("task_id","")
		var td = GameState.RND_TASKS.get(tid, {})
		if td.get("championship_id","") == champ_id and td.get("pillar",0) == 1 \
				and GameState._part_name_to_pcode(td.get("part","")) == pcode \
				and td.get("level",0) == lvl: return true
	return false

func _is_re_wra_approved(pcode: String, champ_id: String) -> bool:
	for app in GameState.wra_approved_blueprints:
		var bp = GameState.known_blueprints.get(app.get("blueprint_id",""), {})
		if bp.get("championship_id","") == champ_id and bp.get("pillar",0) == 3 \
				and GameState._part_name_to_pcode(bp.get("part","")) == pcode: return true
	return false

func _is_re_wra_pending(pcode: String, champ_id: String) -> bool:
	for sub in GameState.active_wra_submissions:
		var bp = GameState.known_blueprints.get(sub.get("blueprint_id",""), {})
		if bp.get("championship_id","") == champ_id and bp.get("pillar",0) == 3 \
				and GameState._part_name_to_pcode(bp.get("part","")) == pcode: return true
	return false

func _is_re_in_progress(pcode: String, champ_id: String) -> bool:
	for t in GameState.active_rnd_tasks:
		var tid = t.get("task_id","")
		var td = GameState.RND_TASKS.get(tid, {})
		if td.get("championship_id","") == champ_id and td.get("pillar",0) == 3 \
				and GameState._part_name_to_pcode(td.get("part","")) == pcode: return true
	return false
