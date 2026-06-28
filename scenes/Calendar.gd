extends Control
## Version: S37.26 — NEW. Season Calendar viewer scene.
##   Read-only full-season agenda: a vertical scroll of 4-week BLOCKS (Weeks 1–4, 5–8, …), each
##   block a row of 4 week-cells. Every dated event in the world is shown as a colored chip:
##     • RACE (yours)        — blue   — "Championship · Round X/N" + city
##     • RACE (other)        — gray   — same, dimmer (all 21 championships shown)
##     • REG. DEADLINE       — red    — "Championship · registration deadline"
##     • BUILDING / R&D / CNC— amber  — completion this week
##     • CUSTOM REMINDER     — teal   — player-created (＋ to add, − to remove)
##   Data comes from CalendarManager (aggregates race_calendar.json + live engine state).
##   The ＋ button (global + per-week) opens an Add-Event popup (week picker + title + note).
##   Custom chips carry a − button. Both ＋ and − have tooltips. Current week is highlighted.
##
##   NOTE: this is the FULL-season view. The Main Hub shows only the 4–5 weeks ahead (separate).
##   Mandatory resource bar included per GDD v6.2 §15.

const COLS := 4                      ## weeks per block row
const WEEKS_PER_SEASON := 52

# Type → (fill color, text color, human label for legend/tooltip prefix)
const TYPE_STYLE := {
	"race_mine":  {"c": Color(0.22, 0.54, 0.87), "label": "Your race"},
	"race_other": {"c": Color(0.55, 0.55, 0.52), "label": "Other championship"},
	"deadline":   {"c": Color(0.89, 0.29, 0.29), "label": "Registration deadline"},
	"building":   {"c": Color(0.73, 0.46, 0.09), "label": "Building"},
	"rnd":        {"c": Color(0.73, 0.46, 0.09), "label": "R&D"},
	"cnc":        {"c": Color(0.73, 0.46, 0.09), "label": "CNC"},
	"custom":     {"c": Color(0.11, 0.62, 0.46), "label": "Reminder"},
}

var _cal  ## CalendarManager (untyped to avoid global-class parse-order resolution; assigned in _ready)
var _scroll_root: VBoxContainer
var _popup_layer: CanvasLayer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cal = GameState.get_calendar_manager()
	_build_ui()


func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	# ── Resource bar (mandatory, v6.2 §15) ──
	root.add_child(_build_resource_bar())

	# ── Header ──
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var title := Label.new()
	title.text = "📅 SEASON CALENDAR  ·  Season %d" % GameState.current_season
	title.add_theme_font_size_override("font_size", 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var btn_add := Button.new()
	btn_add.text = "＋ Add event"
	btn_add.tooltip_text = "Create a custom reminder on any upcoming week."
	btn_add.custom_minimum_size = Vector2(170, 40)
	btn_add.pressed.connect(func(): _open_add_popup(GameState.current_week))
	header.add_child(btn_add)

	var btn_back := Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(110, 40)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)

	# ── Legend ──
	root.add_child(_build_legend())
	root.add_child(HSeparator.new())

	# ── Scrollable calendar body ──
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_scroll_root = VBoxContainer.new()
	_scroll_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_root.add_theme_constant_override("separation", 12)
	scroll.add_child(_scroll_root)

	# Popup overlay — a CanvasLayer so it floats ABOVE the calendar regardless of scroll
	# position. Children are added on open and freed on close.
	_popup_layer = CanvasLayer.new()
	_popup_layer.layer = 100
	add_child(_popup_layer)

	_rebuild_calendar()


func _build_resource_bar() -> PanelContainer:
	var panel := PanelContainer.new()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 28)
	panel.add_child(hb)
	hb.add_child(_res_label("Season %d · Week %d" % [GameState.current_season, GameState.current_week]))
	## player_team is null until a game is set up. Guard so the calendar can render even when
	## opened without an active game (e.g. running the scene directly in the editor).
	var balance = GameState.player_team.balance if GameState.player_team != null else 0
	hb.add_child(_res_label("💰 CR %s" % _fmt(balance)))
	hb.add_child(_res_label("🔬 RP %s" % _fmt(GameState.research_points)))
	hb.add_child(_res_label("🔧 SP %d" % GameState.spare_parts))
	hb.add_child(_res_label("⛽ FU %d kg" % int(GameState.fuel_kg)))
	return panel


func _res_label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 22)
	return l


func _build_legend() -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	var seen := {}
	for key in ["race_mine", "race_other", "deadline", "building", "custom"]:
		var st = TYPE_STYLE[key]
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 6)
		var dot := ColorRect.new()
		dot.color = st["c"]
		dot.custom_minimum_size = Vector2(14, 14)
		item.add_child(dot)
		var lbl := Label.new()
		var txt = st["label"]
		if key == "building":
			txt = "Building / R&D / CNC"
		lbl.text = txt
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.modulate = Color(0.75, 0.75, 0.75)
		item.add_child(lbl)
		hb.add_child(item)
	return hb


func _rebuild_calendar() -> void:
	for c in _scroll_root.get_children():
		c.queue_free()

	var by_week: Dictionary = _cal.get_events_by_week()

	var start := 1
	while start <= WEEKS_PER_SEASON:
		var end: int = min(start + COLS - 1, WEEKS_PER_SEASON)
		_scroll_root.add_child(_build_block(start, end, by_week))
		start += COLS


func _build_block(start: int, end: int, by_week: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	panel.add_child(vb)

	var head := Label.new()
	head.text = "  Weeks %d – %d" % [start, end]
	head.add_theme_font_size_override("font_size", 18)
	head.modulate = Color(0.7, 0.7, 0.7)
	vb.add_child(head)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)

	for w in range(start, end + 1):
		row.add_child(_build_cell(w, by_week.get(w, [])))
	# pad short final row so cells keep width
	for _i in range(end - start + 1, COLS):
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)

	return panel


func _build_cell(week: int, events: Array) -> Control:
	var is_now: bool = (week == GameState.current_week)

	var cell := PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.custom_minimum_size = Vector2(0, 150)
	if is_now:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.22, 0.54, 0.87, 0.12)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.22, 0.54, 0.87)
		sb.set_corner_radius_all(8)
		cell.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	cell.add_child(vb)

	# week header row: "Wk N" + ＋
	var wh := HBoxContainer.new()
	wh.add_theme_constant_override("separation", 4)
	vb.add_child(wh)
	var wl := Label.new()
	wl.text = "Wk %d%s" % [week, "  · now" if is_now else ""]
	wl.add_theme_font_size_override("font_size", 18)
	wl.modulate = Color(0.22, 0.54, 0.87) if is_now else Color(0.6, 0.6, 0.6)
	wl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wh.add_child(wl)

	var add_btn := Button.new()
	add_btn.text = "＋"
	add_btn.flat = true
	add_btn.tooltip_text = "Add a custom reminder in week %d" % week
	add_btn.custom_minimum_size = Vector2(28, 28)
	add_btn.pressed.connect(func(): _open_add_popup(week))
	wh.add_child(add_btn)

	# event chips
	for ev in events:
		vb.add_child(_build_chip(ev))

	return cell


func _build_chip(ev: Dictionary) -> Control:
	var style = TYPE_STYLE.get(ev["type"], TYPE_STYLE["race_other"])
	var base: Color = style["c"]

	var chip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(base.r, base.g, base.b, 0.16)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(5)
	chip.add_theme_stylebox_override("panel", sb)
	chip.tooltip_text = ev.get("tooltip", "")

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	chip.add_child(hb)

	var dot := ColorRect.new()
	dot.color = base
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(dot)

	var txtbox := VBoxContainer.new()
	txtbox.add_theme_constant_override("separation", 0)
	txtbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(txtbox)

	var t := Label.new()
	t.text = ev.get("title", "")
	t.add_theme_font_size_override("font_size", 15)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txtbox.add_child(t)

	var sub: String = ev.get("subtitle", "")
	if sub != "":
		var s := Label.new()
		s.text = sub
		s.add_theme_font_size_override("font_size", 13)
		s.modulate = Color(0.65, 0.65, 0.65)
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txtbox.add_child(s)

	# custom events get a − remove button
	if ev["type"] == "custom" and ev.get("source", "").begins_with("custom:"):
		var idx := int(ev["source"].substr(7))
		var rm := Button.new()
		rm.text = "−"
		rm.flat = true
		rm.tooltip_text = "Remove this reminder"
		rm.custom_minimum_size = Vector2(26, 26)
		rm.pressed.connect(func(): _remove_custom(idx))
		hb.add_child(rm)

	return chip


func _remove_custom(index: int) -> void:
	_cal.remove_custom_event(index)
	_rebuild_calendar()


# ── Add-event popup ──────────────────────────────────────────────────────────────

func _open_add_popup(preset_week: int) -> void:
	# Root overlay control fills the whole viewport (CanvasLayer renders it on top of all else).
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup_layer.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _close_popup())
	overlay.add_child(dim)

	# Centering wrapper so the card sits dead-center of the viewport.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(440, 0)
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color(0.13, 0.13, 0.15)
	card_sb.set_border_width_all(1)
	card_sb.border_color = Color(0.3, 0.3, 0.34)
	card_sb.set_corner_radius_all(10)
	card_sb.set_content_margin_all(4)
	card.add_theme_stylebox_override("panel", card_sb)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 22)
	mc.add_theme_constant_override("margin_right", 22)
	mc.add_theme_constant_override("margin_top", 20)
	mc.add_theme_constant_override("margin_bottom", 20)
	mc.add_child(vb)
	card.add_child(mc)

	var h := Label.new()
	h.text = "Add custom event"
	h.add_theme_font_size_override("font_size", 28)
	vb.add_child(h)

	# week picker
	vb.add_child(_field_label("Week"))
	var week_opt := OptionButton.new()
	var sel_idx := 0
	var cnt := 0
	for w in range(GameState.current_week, WEEKS_PER_SEASON + 1):
		week_opt.add_item("Week %d" % w, w)
		if w == preset_week:
			sel_idx = cnt
		cnt += 1
	week_opt.select(sel_idx)
	week_opt.custom_minimum_size = Vector2(0, 40)
	vb.add_child(week_opt)

	# title
	vb.add_child(_field_label("Title"))
	var title_edit := LineEdit.new()
	title_edit.placeholder_text = "Scout a Rally driver"
	title_edit.custom_minimum_size = Vector2(0, 40)
	vb.add_child(title_edit)

	# note
	vb.add_child(_field_label("Note (optional)"))
	var note_edit := LineEdit.new()
	note_edit.placeholder_text = "Before the transfer window"
	note_edit.custom_minimum_size = Vector2(0, 40)
	vb.add_child(note_edit)

	# buttons
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_END
	btns.add_theme_constant_override("separation", 10)
	vb.add_child(btns)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(110, 40)
	cancel.pressed.connect(_close_popup)
	btns.add_child(cancel)

	var save := Button.new()
	save.text = "Add"
	save.custom_minimum_size = Vector2(110, 40)
	save.pressed.connect(func():
		var w: int = week_opt.get_item_id(week_opt.selected)
		_cal.add_custom_event(w, title_edit.text, note_edit.text)
		_close_popup()
		_rebuild_calendar()
	)
	btns.add_child(save)


func _close_popup() -> void:
	for c in _popup_layer.get_children():
		c.queue_free()


func _field_label(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 18)
	l.modulate = Color(0.7, 0.7, 0.7)
	return l


# ── Helpers ──────────────────────────────────────────────────────────────────────

func _fmt(n) -> String:
	var v := int(round(float(n)))
	var s := str(abs(v))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if v < 0 else "") + out


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
