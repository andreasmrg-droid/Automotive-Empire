extends Control
## Version: S37.24 — DOUBLE-FIRE fix: _rebuild_list() now clears + rebuilds SYNCHRONOUSLY. The old
##   version awaited a frame between clear and re-add; two near-simultaneous calls (_ready→_build_ui
##   and open()) interleaved past the clear and both appended → 4 rows for 2 proposals. Race removed.
## Version: S32.2 — TP rebuild: renders all 4 player-assignable roles (driver, mechanic,
##   pit crew, strategist). Reads the new proposal model (person_id/scope/type). Accept
##   per-item / accept-all adopt the regenerated single source (_last_tp_proposals).
## --- S31.3 — Accept flow now adopts the single source (_last_tp_proposals) after
##   apply_tp_proposals regenerates it, instead of editing a divergent local copy or forcing
##   it empty. Fixes duplicate proposal rows and hidden warnings after accepting.
## --- S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## Version: S23.0 — TP Assignment Proposals popup.
##   Full-screen overlay listing all proposals with Accept All / per-item Accept / Skip.
##   Opened from RacingDept TP panel or directly from notification redirect.
##   Emits "closed" signal when dismissed.

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
	if is_inside_tree():
		_rebuild_list()

func _build_ui() -> void:
	## Dim background
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	## Centered panel
	var panel = PanelContainer.new()
	panel.set_anchor(SIDE_LEFT,   0.5); panel.set_anchor(SIDE_RIGHT,  0.5)
	panel.set_anchor(SIDE_TOP,    0.5); panel.set_anchor(SIDE_BOTTOM, 0.5)
	panel.offset_left = -380; panel.offset_right  = 380
	panel.offset_top  = -340; panel.offset_bottom = 340
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.09, 0.10, 0.13)
	pstyle.border_width_left = 2; pstyle.border_width_right  = 2
	pstyle.border_width_top  = 2; pstyle.border_width_bottom = 2
	pstyle.border_color = Color(0.35, 0.65, 1.0)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
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
	lbl_title.text = Locale.t("tp_popup_title")
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
	btn_accept_all.text = Locale.t("tp_popup_accept_all")
	btn_accept_all.custom_minimum_size = Vector2(130, 34)
	btn_accept_all.add_theme_font_size_override("font_size", 26)
	btn_accept_all.modulate = Color(0.4, 0.9, 0.5)
	btn_accept_all.pressed.connect(_on_accept_all)
	action_bar.add_child(btn_accept_all)

	var btn_skip_all = Button.new()
	btn_skip_all.text = Locale.t("tp_popup_skip_all")
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

	## Scrollable list
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
	## Clear + rebuild SYNCHRONOUSLY. The previous version awaited a frame between clearing and
	## re-adding rows; when _rebuild_list was called twice in quick succession (once from _ready→
	## _build_ui and once from open()), the two coroutines interleaved past the clear and both
	## appended → DOUBLED rows while the summary reflected a single pass. free_children() with
	## immediate removal + no await removes the race. (Fixes the doubled TP-proposal rows.)
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()

	var assignable = _proposals.filter(func(p): return p["type"] in [
		"assign_driver", "assign_mechanic", "assign_pit_crew", "assign_strategist"])
	var warnings   = _proposals.filter(func(p): return p["type"] in [
		"dns_warning", "missing_driver", "missing_mechanic", "missing_pit_crew", "missing_strategist"])

	_lbl_summary.text = "%d assignment%s · %d warning%s" % [
		assignable.size(), "s" if assignable.size() != 1 else "",
		warnings.size(),   "s" if warnings.size()   != 1 else ""]

	if _proposals.is_empty():
		var lbl = Label.new()
		lbl.text = Locale.t("tp_popup_empty")
		lbl.modulate = Color(0.4, 0.9, 0.4)
		lbl.add_theme_font_size_override("font_size", 26)
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

	## Note text
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

	## Buttons
	if ptype in ["assign_driver", "assign_mechanic", "assign_pit_crew", "assign_strategist"]:
		var btn_ok = Button.new()
		btn_ok.text = "✅"
		btn_ok.custom_minimum_size = Vector2(34, 28)
		btn_ok.modulate = Color(0.4, 0.9, 0.5)
		var p = prop.duplicate()
		btn_ok.pressed.connect(func():
			GameState.apply_tp_proposals([p])
			## apply_tp_proposals regenerates _last_tp_proposals (the just-assigned
			## proposal drops out). Adopt that single source instead of editing a local
			## copy — prevents the popup list diverging / showing duplicates.
			_proposals = GameState._last_tp_proposals.duplicate(true)
			_rebuild_list())
		hb.add_child(btn_ok)

		var btn_x = Button.new()
		btn_x.text = "✕"
		btn_x.custom_minimum_size = Vector2(28, 28)
		btn_x.modulate = Color(0.5, 0.5, 0.5)
		var p2 = prop.duplicate()
		btn_x.pressed.connect(func():
			_proposals.erase(p2)
			GameState._last_tp_proposals = GameState._last_tp_proposals.filter(
				func(x): return x.get("note","") != p2.get("note",""))
			_rebuild_list())
		hb.add_child(btn_x)

	elif ptype in ["missing_driver", "missing_mechanic", "missing_pit_crew", "missing_strategist"]:
		var btn_hire = Button.new()
		btn_hire.text = "→ Staff"
		btn_hire.custom_minimum_size = Vector2(70, 28)
		btn_hire.add_theme_font_size_override("font_size", 22)
		btn_hire.pressed.connect(func():
			_on_close()
			get_tree().change_scene_to_file("res://scenes/Staff.tscn"))
		hb.add_child(btn_hire)

	return row

func _on_accept_all() -> void:
	var assignable = _proposals.filter(func(p): return p["type"] in [
		"assign_driver", "assign_mechanic", "assign_pit_crew", "assign_strategist"])
	GameState.apply_tp_proposals(assignable)
	## apply_tp_proposals already regenerated _last_tp_proposals (assigned ones drop out;
	## any remaining warnings/missing-personnel stay). Adopt it rather than forcing [] —
	## forcing empty hid still-relevant warnings.
	_proposals = GameState._last_tp_proposals.duplicate(true)
	_rebuild_list()
	await get_tree().create_timer(0.3).timeout
	_on_close()

func _on_close() -> void:
	emit_signal("closed")
	queue_free()
