extends Control
## Version: S41.16b — LEAD-DESIGNER PROPOSALS POPUP (point 3). Instantiated SCRIPT-ONLY via
##   preload("res://scenes/DesignProposalsPopup.gd").new() from RnDStudio (repo precedent:
##   VehicleFactory→ModelNamePopup); NO .tscn — the first attempt shipped a .tscn whose ext_resource
##   referenced an invented uid Godot's import cache didn't have, so the script failed to attach and the
##   node stayed a bare Control ("open() not found"). This node builds its ENTIRE UI in _ready()/
##   _build_ui() (sets its own full-rect anchors), so it needs no scene file. Mirrors TPProposalsPopup:
##   full-rect dim + centred PanelContainer, header + summary, Accept-All / Close, a VERTICAL-ONLY scroll
##   list (horizontal disabled per owner: "no horizontal bar, vertical scroll so it never extends past
##   the screen bottom"), per-row Accept that adopts the regenerated single source (_last_design_
##   proposals). Reads the design-proposal model: type ∈ {queue_blueprint, no_lead, info}, priority ∈
##   {normal, warning, critical}. queue_blueprint → Accept (→ apply_design_proposals) + skip; no_lead
##   (critical) → "→ Staff"; info → text only. Height anchor-based (6%→94%) so a long list scrolls INSIDE
##   the panel. Emits "closed" when dismissed. Analysis-checked; NOT Godot-parsed.

signal closed

var _proposals: Array = []
var _scroll: ScrollContainer
var _list: VBoxContainer
var _lbl_summary: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func open(proposals: Array) -> void:
	_proposals = proposals.duplicate(true)
	## Defensive: normally add_child fires _ready() (→ _build_ui) synchronously before this runs, so
	## _list exists. If the caller ever opens before the node is in the tree (or _ready hasn't fired),
	## build the UI here so open() is self-sufficient (matches the ModelNamePopup precedent).
	if _list == null and is_inside_tree():
		_build_ui()
	if is_inside_tree():
		_rebuild_list()

func _build_ui() -> void:
	## Dim background
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	## Centred panel. WIDTH is fixed-generous so the longer design notes fit without a horizontal
	## bar. HEIGHT is anchor-based (top 6% → bottom 6% of the screen) rather than a fixed pixel offset,
	## so on any screen the panel stops short of the edges and the list scrolls INSIDE it — never past
	## the bottom (owner requirement). The inner ScrollContainer takes the overflow vertically.
	var panel = PanelContainer.new()
	panel.set_anchor(SIDE_LEFT,   0.5); panel.set_anchor(SIDE_RIGHT,  0.5)
	panel.set_anchor(SIDE_TOP,    0.06); panel.set_anchor(SIDE_BOTTOM, 0.94)
	panel.offset_left = -460; panel.offset_right = 460   ## wider than TP (±380) for the design text
	panel.offset_top  = 0;    panel.offset_bottom = 0
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.09, 0.10, 0.13)
	pstyle.border_width_left = 2; pstyle.border_width_right  = 2
	pstyle.border_width_top  = 2; pstyle.border_width_bottom = 2
	pstyle.border_color = Color(0.35, 0.65, 1.0)
	for c in ["top_left", "top_right", "bottom_left", "bottom_right"]:
		pstyle.set("corner_radius_%s" % c, 8)
	pstyle.content_margin_left = 20; pstyle.content_margin_right  = 20
	pstyle.content_margin_top  = 16; pstyle.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", pstyle)
	add_child(panel)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	## Header
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	root.add_child(hdr)

	var lbl_title = Label.new()
	lbl_title.text = "🧪 Lead Designer Proposals"
	lbl_title.add_theme_font_size_override("font_size", 36)
	lbl_title.add_theme_color_override("font_color", Color(0.5, 0.78, 1.0))
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(lbl_title)

	_lbl_summary = Label.new()
	_lbl_summary.add_theme_font_size_override("font_size", 24)
	_lbl_summary.modulate = Color(0.55, 0.55, 0.55)
	hdr.add_child(_lbl_summary)

	root.add_child(HSeparator.new())

	## Action bar
	var action_bar = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 8)
	root.add_child(action_bar)

	var btn_accept_all = Button.new()
	btn_accept_all.text = "✅ Accept All"
	btn_accept_all.custom_minimum_size = Vector2(150, 34)
	btn_accept_all.add_theme_font_size_override("font_size", 26)
	btn_accept_all.modulate = Color(0.4, 0.9, 0.5)
	btn_accept_all.pressed.connect(_on_accept_all)
	action_bar.add_child(btn_accept_all)

	var btn_skip_all = Button.new()
	btn_skip_all.text = "Close"
	btn_skip_all.custom_minimum_size = Vector2(100, 34)
	btn_skip_all.add_theme_font_size_override("font_size", 24)
	btn_skip_all.modulate = Color(0.6, 0.6, 0.6)
	btn_skip_all.pressed.connect(_on_close)
	action_bar.add_child(btn_skip_all)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_bar.add_child(spacer)

	var btn_close = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(34, 34)
	btn_close.modulate = Color(0.55, 0.55, 0.55)
	btn_close.pressed.connect(_on_close)
	action_bar.add_child(btn_close)

	root.add_child(HSeparator.new())

	## Scrollable list — VERTICAL ONLY (horizontal disabled). Expands to fill the panel's remaining
	## height, so a long proposal list scrolls here instead of pushing the panel past the screen.
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	_scroll.add_child(_list)

	_rebuild_list()

func _rebuild_list() -> void:
	if not is_inside_tree(): return
	## Clear + rebuild SYNCHRONOUSLY (no await between clear and re-add) — the same double-fire race
	## TPProposalsPopup fixed: _ready→_build_ui and open() can both call this in quick succession, and
	## an awaited frame between clear and append would interleave and double the rows.
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()

	var queueable = _proposals.filter(func(p): return p.get("type", "") == "queue_blueprint")
	var criticals = _proposals.filter(func(p): return p.get("priority", "") == "critical")

	_lbl_summary.text = "%d proposal%s · %d critical%s" % [
		queueable.size(), "s" if queueable.size() != 1 else "",
		criticals.size(), "s" if criticals.size() != 1 else ""]

	if _proposals.is_empty():
		var lbl = Label.new()
		lbl.text = "No proposals right now — all design lines are busy or nothing new is unlockable. ✅"
		lbl.modulate = Color(0.4, 0.9, 0.4)
		lbl.add_theme_font_size_override("font_size", 26)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(lbl)
		return

	for prop in _proposals:
		_list.add_child(_build_proposal_row(prop))

func _build_proposal_row(prop: Dictionary) -> PanelContainer:
	var priority = prop.get("priority", "normal")
	var ptype    = prop.get("type", "")

	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rstyle = StyleBoxFlat.new()
	match priority:
		"critical": rstyle.bg_color = Color(0.18, 0.07, 0.07)
		"warning":  rstyle.bg_color = Color(0.15, 0.12, 0.06)
		_:          rstyle.bg_color = Color(0.10, 0.13, 0.10)
	rstyle.border_width_left = 3
	match priority:
		"critical": rstyle.border_color = Color(0.9, 0.2, 0.2)
		"warning":  rstyle.border_color = Color(1.0, 0.65, 0.1)
		_:          rstyle.border_color = Color(0.3, 0.75, 0.4)
	rstyle.content_margin_left = 10; rstyle.content_margin_right  = 10
	rstyle.content_margin_top  =  7; rstyle.content_margin_bottom =  7
	row.add_theme_stylebox_override("panel", rstyle)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	row.add_child(hb)

	## Note text — wraps within the panel width (horizontal scroll is disabled), so long design
	## advice reads top-to-bottom without a horizontal bar.
	var lbl = Label.new()
	lbl.text = prop.get("note", "")
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	match priority:
		"critical": lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		"warning":  lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		_:          lbl.add_theme_color_override("font_color", Color(0.8, 0.95, 0.8))
	hb.add_child(lbl)

	## Buttons per proposal type.
	if ptype == "queue_blueprint":
		var btn_ok = Button.new()
		btn_ok.text = "✅"
		btn_ok.custom_minimum_size = Vector2(34, 28)
		btn_ok.modulate = Color(0.4, 0.9, 0.5)
		var p = prop.duplicate()
		btn_ok.pressed.connect(func():
			GameState.apply_design_proposals([p])
			## apply_design_proposals regenerates _last_design_proposals (the just-started task drops
			## out). Adopt that single source rather than editing a local copy (prevents divergence).
			_proposals = GameState._last_design_proposals.duplicate(true)
			_rebuild_list())
		hb.add_child(btn_ok)

		var btn_x = Button.new()
		btn_x.text = "✕"
		btn_x.custom_minimum_size = Vector2(28, 28)
		btn_x.modulate = Color(0.5, 0.5, 0.5)
		var p2 = prop.duplicate()
		btn_x.pressed.connect(func():
			_proposals.erase(p2)
			GameState._last_design_proposals = GameState._last_design_proposals.filter(
				func(x): return x.get("note", "") != p2.get("note", ""))
			_rebuild_list())
		hb.add_child(btn_x)

	elif ptype == "no_lead":
		var btn_hire = Button.new()
		btn_hire.text = "→ Staff"
		btn_hire.custom_minimum_size = Vector2(80, 28)
		btn_hire.add_theme_font_size_override("font_size", 22)
		btn_hire.pressed.connect(func():
			GameState.pending_staff_filter = "Designer"
			_on_close()
			get_tree().change_scene_to_file("res://scenes/Staff.tscn"))
		hb.add_child(btn_hire)

	return row

func _on_accept_all() -> void:
	var queueable = _proposals.filter(func(p): return p.get("type", "") == "queue_blueprint")
	GameState.apply_design_proposals(queueable)
	## apply_design_proposals already regenerated _last_design_proposals (started tasks drop out; any
	## remaining criticals/info stay). Adopt it rather than forcing [] — forcing empty would hide a
	## still-relevant "hire a Lead Designer" critical.
	_proposals = GameState._last_design_proposals.duplicate(true)
	_rebuild_list()
	await get_tree().create_timer(0.3).timeout
	_on_close()

func _on_close() -> void:
	emit_signal("closed")
	queue_free()
