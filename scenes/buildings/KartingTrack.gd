## Version: S37.35 — Standard minimal header [Name·Level][Resource Bar][Back][Main Hub] (Main Hub
##   concept). Bar refreshes via _build_ui. Scene-specific controls (if any) live below the header.
extends Control
## Version: S37.20 — #30 text audit: "Go-Kart"→"Go-Karting" (discipline-name consistency).
## Version: S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.

var _resource_bar = null   ## S37.35 shared ResourceBar
const ResourceBarScript = preload("res://scenes/components/ResourceBar.gd")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	if _resource_bar != null and _resource_bar.has_method("refresh"):
		_resource_bar.refresh()
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
	var building = GameState.campus_buildings.get("Karting Track", {})
	var lbl_title = Label.new()
	lbl_title.text = "🔵 KARTING TRACK  ·  Level %d" % building.get("level", 1)
	lbl_title.add_theme_font_size_override("font_size", 44)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)
	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(100, 36)
	btn_back.pressed.connect(_on_back)
	# Shared resource bar — standard header [Name·Level][Bar][Back][Main Hub]
	_resource_bar = ResourceBarScript.new()
	_resource_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(_resource_bar)
	header.add_child(btn_back)
	var btn_hub = Button.new()
	btn_hub.text = "🏠 Main Hub"
	btn_hub.custom_minimum_size = Vector2(130, 36)
	btn_hub.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainHub.tscn"))
	header.add_child(btn_hub)
	root.add_child(HSeparator.new())

	# Two columns
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	cols.add_child(left)

	# Description
	var lbl_desc = Label.new()
	# PRC income gate notice
	var prc = GameState.campus_buildings.get("Public Racing Club", {})
	var prc_built = prc.get("built", false)
	if not prc_built:
		var lbl_prc = Label.new()
		lbl_prc.text = "⚠ Build the Public Racing Club to unlock track income."
		lbl_prc.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		lbl_prc.add_theme_font_size_override("font_size", 24)
		left.add_child(lbl_prc)
	lbl_desc.text = "Tight technical karting circuit. Improves Go-Karting discipline stats. Generates income via Public Racing Club."
	lbl_desc.modulate = Color(0.7, 0.7, 0.7)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 26)
	left.add_child(lbl_desc)

	left.add_child(HSeparator.new())

	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(260, 0)
	right.add_theme_constant_override("separation", 14)
	cols.add_child(right)

	right.add_child(_section_label("BUILDING EFFECTS"))
	right.add_child(_build_effects_panel())

func _build_effects_panel() -> PanelContainer:
	var panel = _card_panel()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var building = GameState.campus_buildings.get("Karting Track", {})
	var level = building.get("level", 1)
	var inc = GameState.get_building_income(building)
	var maint = GameState.get_building_maintenance(building)
	var effects_str = building.get("effects", "")
	# Header stat: level
	var rows = [
		["Level",       "%d / %d" % [level, building.get("max_level", 10)]],
		["Maintenance", "CR %d/wk" % maint],
	]
	if inc > 0:
		rows.append(["Weekly Income", "CR %d/wk" % inc])
	for e in rows:
		vbox.add_child(_stat_row(e[0], e[1]))
	# Effects text
	if effects_str != "":
		vbox.add_child(HSeparator.new())
		var lbl = Label.new()
		lbl.text = effects_str
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.modulate = Color(0.6, 0.85, 1.0)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)
	return panel

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
	var l = Label.new(); l.text = label; l.custom_minimum_size = Vector2(140, 0)
	l.add_theme_font_size_override("font_size", 24); l.modulate = Color(0.55, 0.55, 0.55)
	row.add_child(l)
	var v = Label.new(); v.text = value; v.add_theme_font_size_override("font_size", 24)
	row.add_child(v)
	return row

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
