extends Control
## Version: S36.7 — Bug #9/#19 (cluster A): the "Race Strategist not required" gate now checks the
##   player's ACTUAL championships (via get_player_championships) instead of active_championship
##   (=world-[0]=GK). Strategists are shown unless every championship the player races is GK or Rally
##   (per GDD §9-G) — fixes both the GP-player-told-not-required case and the Rally exclusion the old
##   GK-only gate missed. The per-championship ASSIGNMENT button is DEFERRED to the staff-assignment
##   cluster (with TP #40) and still binds to active_championship for now (marked in-code).
## Version: S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## Version: S15.2 — Effects panel clarifies Strategist vs Designer slots.

var _strategist_container: VBoxContainer
var _popup: PanelContainer
var _popup_title: Label
var _popup_list: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	refresh()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   28)
	margin.add_theme_constant_override("margin_right",  28)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	var building = GameState.campus_buildings.get("Ops Sim & Telemetry", {})
	var lbl = Label.new()
	lbl.text = "📡 OPS SIM & TELEMETRY  ·  Level %d" % building.get("level", 1)
	lbl.add_theme_font_size_override("font_size", 44)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl)
	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(100, 36)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)
	root.add_child(HSeparator.new())

	# Two columns
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	# Left — strategist slots
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	cols.add_child(left)

	var lbl_sec = _section_label("RACE STRATEGIST")
	left.add_child(lbl_sec)

	var btn_hire = Button.new()
	btn_hire.text = "Hire Race Strategist →"
	btn_hire.custom_minimum_size = Vector2(220, 34)
	btn_hire.pressed.connect(func():
		GameState.pending_staff_filter = "Race Strategist"
		get_tree().change_scene_to_file("res://scenes/Staff.tscn")
	)
	left.add_child(btn_hire)

	left.add_child(HSeparator.new())

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)

	_strategist_container = VBoxContainer.new()
	_strategist_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_strategist_container.add_theme_constant_override("separation", 10)
	scroll.add_child(_strategist_container)

	# Right — effects + track knowledge
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(280, 0)
	right.add_theme_constant_override("separation", 14)
	cols.add_child(right)

	right.add_child(_section_label("BUILDING EFFECTS"))
	right.add_child(_build_effects_panel())

	right.add_child(HSeparator.new())

	right.add_child(_section_label("TRACK KNOWLEDGE"))
	right.add_child(_build_track_knowledge_panel())

	# Popup
	_popup = _build_popup()
	add_child(_popup)

func refresh() -> void:
	_refresh_strategists()

func _refresh_strategists() -> void:
	for c in _strategist_container.get_children():
		c.queue_free()

	## Display gate (cluster A, Bug #9/#19): "Strategist not required" should reflect whether the
	## player ACTUALLY races only GK — not whether active_championship (=world-[0]) is GK. Strategists
	## aren't used in GK or Rally (per the staff spec). If every championship the player races is
	## GK/Rally, the strategist screen isn't relevant; otherwise show the strategists.
	## NOTE: the per-championship ASSIGNMENT button below is deferred to the staff-assignment cluster
	## (with TP #40) — it still binds to active_championship for now.
	var player_champs = GameState.get_player_championships()
	var needs_strategist = false
	for champ in player_champs:
		if champ.discipline != "GK" and champ.discipline != "Rally":
			needs_strategist = true
			break
	if not needs_strategist:
		var lbl = Label.new()
		lbl.text = "Race Strategist not required for your current championships (GK / Rally)."
		lbl.modulate = Color(0.55, 0.55, 0.55)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_strategist_container.add_child(lbl)
		return

	var strats = GameState.get_player_staff_by_role("Race Strategist")
	if strats.is_empty():
		var lbl = Label.new()
		lbl.text = "No Race Strategist hired.\nUse 'Hire Race Strategist' above."
		lbl.modulate = Color(0.55, 0.55, 0.55)
		_strategist_container.add_child(lbl)
		return

	for strat in strats:
		_strategist_container.add_child(_build_strategist_card(strat))

func _build_strategist_card(strat) -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	var lbl_name = Label.new()
	lbl_name.text = strat.full_name()
	lbl_name.add_theme_font_size_override("font_size", 30)
	lbl_name.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(lbl_name)
	var lbl_sal = Label.new()
	lbl_sal.text = "CR %d/wk" % int(strat.weekly_salary)
	lbl_sal.modulate = Color(0.6, 0.6, 0.6)
	row1.add_child(lbl_sal)
	vbox.add_child(row1)

	# Stats chips
	var stats_row = HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 6)
	for stat in [["Strategy", strat.race_strategy], ["Pace", strat.race_pace_reading],
			["Practice", strat.practice_scheduling], ["Track", strat.track_knowledge]]:
		stats_row.add_child(_stat_chip(stat[0], stat[1]))
	vbox.add_child(stats_row)

	# Assignment
	## DEFERRED (staff-assignment cluster, with TP #40): this binds the strategist to
	## active_championship (= world-[0] = GK). Correct behaviour is per-championship assignment
	## (the player picks which of their championships). Left as-is intentionally for that pass.
	var champ = GameState.active_championship
	var assigned = strat.assigned_championship == champ.id
	var assign_row = HBoxContainer.new()
	assign_row.add_theme_constant_override("separation", 8)
	var lbl_assign = Label.new()
	lbl_assign.text = "Assignment: %s" % (champ.championship_name if assigned else "Unassigned")
	lbl_assign.modulate = Color(0.4, 0.9, 0.4) if assigned else Color(0.9, 0.5, 0.15)
	lbl_assign.add_theme_font_size_override("font_size", 24)
	lbl_assign.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	assign_row.add_child(lbl_assign)
	var btn = Button.new()
	btn.text = "Unassign" if assigned else "Assign"
	var sid = strat.id
	btn.pressed.connect(func():
		if assigned:
			strat.assigned_championship = ""
			GameState.add_log("📡 %s unassigned." % strat.full_name())
		else:
			GameState.assign_staff_to_championship(sid, champ.id)
		refresh()
	)
	assign_row.add_child(btn)
	vbox.add_child(assign_row)

	return panel

func _build_effects_panel() -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var building = GameState.campus_buildings.get("Ops Sim & Telemetry", {})
	var level = building.get("level", 1)
	var effects = [
		["Track Knowledge Base", "+%d%%" % (25 + (level - 1))],
		["Strategist Slots",     "%d" % level],
		["Maintenance",          "CR %d/wk" % GameState.get_building_maintenance(building)],
		["Level",                "%d / %d" % [level, building.get("max_level", 30)]],
	]
	for e in effects:
		vbox.add_child(_stat_row(e[0], e[1]))
	var rnd = GameState.campus_buildings.get("R&D Design Studio", {})
	var designer_slots = rnd.get("level", 0)
	var note = Label.new()
	note.text = "Designer slots: %d (from R&D Studio Lv%d)" % [designer_slots, designer_slots]
	note.add_theme_font_size_override("font_size", 20)
	note.modulate = Color(0.5, 0.5, 0.5)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(note)
	return panel

func _build_track_knowledge_panel() -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	var lbl = Label.new()
	lbl.text = "Track knowledge improves race strategy accuracy and qualifying timing.\nOps Sim raises the baseline to 25% without any practice sessions."
	lbl.modulate = Color(0.6, 0.6, 0.6)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 24)
	vbox.add_child(lbl)
	return panel

func _build_popup() -> PanelContainer:
	var p = PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(400, 0)
	p.visible = false
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.13, 0.98)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.65, 1.0)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 16; style.content_margin_right = 16
	style.content_margin_top = 16; style.content_margin_bottom = 16
	p.add_theme_stylebox_override("panel", style)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	p.add_child(vbox)
	var hdr = HBoxContainer.new()
	vbox.add_child(hdr)
	_popup_title = Label.new()
	_popup_title.add_theme_font_size_override("font_size", 32)
	_popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(_popup_title)
	var btn_close = Button.new()
	btn_close.text = "✕"
	btn_close.custom_minimum_size = Vector2(32, 32)
	btn_close.pressed.connect(func(): _popup.visible = false)
	hdr.add_child(btn_close)
	vbox.add_child(HSeparator.new())
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 160)
	vbox.add_child(scroll)
	_popup_list = VBoxContainer.new()
	_popup_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_popup_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_popup_list)
	return p

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

func _section_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.modulate = Color(0.5, 0.5, 0.5)
	return lbl

func _stat_row(label: String, value: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	var l = Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(160, 0)
	l.add_theme_font_size_override("font_size", 24)
	l.modulate = Color(0.55, 0.55, 0.55)
	row.add_child(l)
	var v = Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 24)
	row.add_child(v)
	return row

func _stat_chip(label: String, value: float) -> PanelContainer:
	var chip = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22)
	style.corner_radius_top_left = 3; style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3; style.corner_radius_bottom_right = 3
	style.content_margin_left = 5; style.content_margin_right = 5
	style.content_margin_top = 2; style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)
	var lbl = Label.new()
	lbl.text = "%s %.0f" % [label, value]
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", _skill_color(value))
	chip.add_child(lbl)
	return chip

func _card_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.12, 0.15)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.22, 0.22, 0.26)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 12; style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _skill_color(v: float) -> Color:
	if v >= 75: return Color(0.3, 1.0, 0.3)
	elif v >= 50: return Color(1.0, 0.84, 0.0)
	elif v >= 30: return Color(1.0, 0.6, 0.2)
	return Color(0.7, 0.4, 0.4)
