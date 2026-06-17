extends Control
## Version: S24.0 — Added Championships browser button on title screen. — Budget = CHAMP_BASE_BUDGETS × DIFFICULTY_ECONOMY multiplier.
##                    GKR 50K · Rally4 250K · SC Dev 1.5M · GP4 350K (at Realistic).
##                    Screen 4 no longer gates by budget. Screen 5 shows champ-specific budget.
## Screen 1: Title  →  2: CEO  →  3: Team  →  4: Championship  →  5: Difficulty  →  6: Summary

# ── Shared state across all screens ───────────────────────────────────────────
var _screen: int = 1  # 1-6

## CEO data
var _ceo_name:        String = ""
var _ceo_sex:         String = "Male"
var _ceo_age:         int    = 30
var _ceo_nationality: String = "British"

## Team data
var _team_name:    String = ""
var _color_primary:   Color = Color(0.85, 0.15, 0.15)
var _color_secondary: Color = Color(0.95, 0.95, 0.95)

## Championship
var _selected_champ: String = "C-001"  # Default: GK Regional

## Difficulty
var _difficulty: String = "Realistic"

## Budget (set by difficulty)
## Base budget per starting championship (before difficulty multiplier)
const CHAMP_BASE_BUDGETS: Dictionary = {
	"C-001":   150000,   ## GK Regional
	"C-005":   350000,   ## RALLY4
	"C-014":  2200000,   ## SC Dev Series
	"C-021":   600000,   ## GP4
}

## Difficulty economy multipliers (applied to championship base budget)
const DIFFICULTY_ECONOMY: Dictionary = {
	"Rookie":    1.30,
	"Amateur":   1.15,
	"Realistic": 1.00,
	"Expert":    0.90,
	"Master":    0.80,
}

## Difficulty budget labels shown on Screen 5 cards (relative description)
const DIFFICULTY_BUDGETS: Dictionary = {
	"Rookie":    0,   ## placeholder — calculated dynamically
	"Amateur":   0,
	"Realistic": 0,
	"Expert":    0,
	"Master":    0,
}

## Returns the actual starting budget for the current champ + difficulty combination
func _calc_budget() -> int:
	var base = CHAMP_BASE_BUDGETS.get(_selected_champ, 50000)
	var mult = DIFFICULTY_ECONOMY.get(_difficulty, 1.0)
	return int(base * mult)
const DIFFICULTY_DESC = {
	"Rookie":    ["AI Performance ×0.75", "Player Economy ×1.30", "Player R&D ×0.80", "Recommended for first-timers."],
	"Amateur":   ["AI Performance ×0.85", "Player Economy ×1.15", "Player R&D ×0.90", "A comfortable learning curve."],
	"Realistic": ["AI Performance ×1.00", "Player Economy ×1.00", "Player R&D ×1.00", "The intended experience."],
	"Expert":    ["AI Performance ×1.15", "Player Economy ×0.90", "Player R&D ×1.10", "Tight budgets, fierce rivals."],
	"Master":    ["AI Performance ×1.25", "Player Economy ×0.80", "Player R&D ×1.20", "No margin for error."],
}

## Tier 1 championships available at start
const TIER1_CHAMPS = {
	"C-001": {"name": "GK Regional",  "discipline": "Go-Karting", "entry_fee": 9000,   "races": 6,  "age": "8–16",
		"desc": "The classic starting point. Low cost, pure driving skill. Talent scouts watch closely.",
		"icon": "🏎",
		"includes": ["1 Car", "1 Driver", "1 Mechanic", "1 Team Principal"],
		"buildings": ["Standard Campus"]},
	"C-005": {"name": "RALLY4",        "discipline": "Rally",      "entry_fee": 30000,  "races": 5,  "age": "16+",
		"desc": "Gravel and tarmac stages. High attrition, high reward. A true driver's championship.",
		"icon": "🪨",
		"includes": ["1 Car", "1 Driver", "1 Mechanic", "1 Pit Crew", "1 Team Principal"],
		"buildings": ["Standard Campus", "Pit Crew Arena"]},
	"C-014": {"name": "SC Dev Series", "discipline": "Stock Car",  "entry_fee": 600000, "races": 20, "age": "15+",
		"desc": "The most races, the toughest budget ask. Oval and superspeedway glory awaits.",
		"icon": "🔄",
		"includes": ["1 Car", "1 Driver", "1 Mechanic", "1 Pit Crew", "1 Strategist", "1 Team Principal"],
		"buildings": ["Standard Campus", "Pit Crew Arena", "Ops Sim"]},
	"C-021": {"name": "GP4",           "discipline": "Formula",    "entry_fee": 66000,  "races": 6,  "age": "15+",
		"desc": "The bottom rung of the single-seater ladder. New car required every season.",
		"icon": "🏁",
		"includes": ["1 Car", "1 Driver", "1 Mechanic", "1 Pit Crew", "1 Strategist", "1 Team Principal"],
		"buildings": ["Standard Campus", "Pit Crew Arena", "Ops Sim"]},
}

## Root container — all screens render here
var _root: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_show_screen(1)


# ══════════════════════════════════════════════════════════════════════════════
# SCREEN ROUTER
# ══════════════════════════════════════════════════════════════════════════════

func _show_screen(n: int) -> void:
	_screen = n
	for c in _root.get_children():
		c.queue_free()
	await get_tree().process_frame
	match n:
		1: _build_title()
		2: _build_ceo()
		3: _build_team()
		4: _build_championship()
		5: _build_difficulty()
		6: _build_summary()


# ══════════════════════════════════════════════════════════════════════════════
# SCREEN 1 — TITLE
# ══════════════════════════════════════════════════════════════════════════════

func _build_title() -> void:
	var bg = _full_panel(Color(0.06, 0.06, 0.08))
	_root.add_child(bg)

	var center = VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 28)
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(520, 0)
	bg.add_child(center)

	## Decorative top accent bar
	var accent = ColorRect.new()
	accent.color = Color(0.9, 0.2, 0.15)
	accent.custom_minimum_size = Vector2(520, 4)
	center.add_child(accent)

	var lbl_title = Label.new()
	lbl_title.text = "AUTOMOTIVE\nEMPIRE"
	lbl_title.add_theme_font_size_override("font_size", 58)
	lbl_title.add_theme_color_override("font_color", Color.WHITE)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(lbl_title)

	var lbl_sub = Label.new()
	lbl_sub.text = "Build a motorsport dynasty from grassroots karting\nto the pinnacle of Formula racing."
	lbl_sub.add_theme_font_size_override("font_size", 15)
	lbl_sub.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(lbl_sub)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	center.add_child(spacer)

	var btn_new = _big_button("🏁  NEW GAME", Color(0.85, 0.15, 0.15))
	btn_new.pressed.connect(func(): _show_screen(2))
	center.add_child(btn_new)

	var btn_cont = _big_button("▶  LOAD GAME", Color(0.18, 0.22, 0.28))
	btn_cont.pressed.connect(_on_continue_pressed)
	center.add_child(btn_cont)

	var btn_champs = _big_button("🏆  CHAMPIONSHIPS", Color(0.10, 0.18, 0.30))
	btn_champs.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/Championships.tscn"))
	center.add_child(btn_champs)

	var btn_quit = Button.new()
	btn_quit.text = "Quit to Desktop"
	btn_quit.custom_minimum_size = Vector2(200, 36)
	btn_quit.modulate = Color(0.5, 0.5, 0.5)
	btn_quit.pressed.connect(func(): get_tree().quit())
	center.add_child(btn_quit)

#Game Version Shown in the beginning of the Game
	var lbl_ver = Label.new()
	lbl_ver.text = "v0.19  ·  Godot 4.6.2"
	lbl_ver.add_theme_font_size_override("font_size", 11)
	lbl_ver.modulate = Color(0.3, 0.3, 0.3)
	lbl_ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(lbl_ver)


# ══════════════════════════════════════════════════════════════════════════════
# SCREEN 2 — CEO CREATION
# ══════════════════════════════════════════════════════════════════════════════

func _build_ceo() -> void:
	var layout = _screen_layout("👤  CEO CREATION", 2)

	var card = _card_panel()
	layout["body"].add_child(card)
	var form = VBoxContainer.new()
	form.add_theme_constant_override("separation", 20)
	card.add_child(form)

	## Name
	form.add_child(_field_label("Your Name"))
	var name_input = _line_edit(_ceo_name, "e.g. Ambitious CEO")
	name_input.text_changed.connect(func(t): _ceo_name = t)
	form.add_child(name_input)

	## Sex
	form.add_child(_field_label("Sex"))
	var sex_row = HBoxContainer.new()
	sex_row.add_theme_constant_override("separation", 10)
	form.add_child(sex_row)
	for s in ["Male", "Female"]:
		var btn = _toggle_btn(s, _ceo_sex == s)
		var sv = s
		btn.pressed.connect(func():
			_ceo_sex = sv
			_show_screen(2))
		sex_row.add_child(btn)

	## Age
	form.add_child(_field_label("Starting Age  (%d)" % _ceo_age))
	var age_slider = HSlider.new()
	age_slider.min_value = 25
	age_slider.max_value = 45
	age_slider.step = 1
	age_slider.value = _ceo_age
	age_slider.custom_minimum_size = Vector2(400, 32)
	age_slider.value_changed.connect(func(v):
		_ceo_age = int(v)
		_show_screen(2))
	form.add_child(age_slider)
	var age_hint = Label.new()
	age_hint.text = "Above 65 you must retire or promote a staff member as successor."
	age_hint.add_theme_font_size_override("font_size", 11)
	age_hint.modulate = Color(0.45, 0.45, 0.45)
	age_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form.add_child(age_hint)

	## Nationality
	form.add_child(_field_label("Nationality"))
	var nat_btn = OptionButton.new()
	nat_btn.custom_minimum_size = Vector2(400, 40)
	nat_btn.add_theme_font_size_override("font_size", 15)
	var nats = NameData.data.keys()
	nats.sort()
	for nat in nats:
		nat_btn.add_item(nat)
	for i in range(nats.size()):
		if nats[i] == _ceo_nationality:
			nat_btn.select(i); break
	nat_btn.item_selected.connect(func(i): _ceo_nationality = nats[i])
	form.add_child(nat_btn)

	_nav_footer(layout["footer"], func(): _show_screen(1), func(): _show_screen(3), "Team Setup →")


# ══════════════════════════════════════════════════════════════════════════════
# SCREEN 3 — TEAM CREATION
# ══════════════════════════════════════════════════════════════════════════════

func _build_team() -> void:
	var layout = _screen_layout("🏎  TEAM CREATION", 3)

	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout["body"].add_child(cols)

	## Left: inputs
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 20)
	cols.add_child(left)

	var card = _card_panel()
	left.add_child(card)
	var form = VBoxContainer.new()
	form.add_theme_constant_override("separation", 20)
	card.add_child(form)

	form.add_child(_field_label("Team Name"))
	var name_input = _line_edit(_team_name, "e.g. Apex Racing")
	name_input.text_changed.connect(func(t):
		_team_name = t
		_refresh_badge(cols))
	form.add_child(name_input)

	## Primary color
	form.add_child(_field_label("Primary Color"))
	var primary_row = _build_color_row(_color_primary, func(c):
		_color_primary = c
		_refresh_badge(cols))
	form.add_child(primary_row)

	## Secondary color
	form.add_child(_field_label("Secondary Color"))
	var secondary_row = _build_color_row(_color_secondary, func(c):
		_color_secondary = c
		_refresh_badge(cols))
	form.add_child(secondary_row)

	## Right: badge preview
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(240, 0)
	right.add_theme_constant_override("separation", 12)
	cols.add_child(right)

	var lbl_prev = Label.new()
	lbl_prev.text = "BADGE PREVIEW"
	lbl_prev.add_theme_font_size_override("font_size", 11)
	lbl_prev.modulate = Color(0.45, 0.45, 0.45)
	right.add_child(lbl_prev)

	var badge_card = _card_panel()
	badge_card.name = "BadgeCard"
	badge_card.custom_minimum_size = Vector2(240, 240)
	right.add_child(badge_card)
	_draw_badge(badge_card)

	_nav_footer(layout["footer"], func(): _show_screen(2), func(): _show_screen(4), "Pick Championship →")


func _refresh_badge(cols: HBoxContainer) -> void:
	## Find BadgeCard and redraw — only update badge, not the whole screen
	var badge_card = cols.find_child("BadgeCard", true, false)
	if badge_card:
		_draw_badge(badge_card)


func _draw_badge(container: PanelContainer) -> void:
	for c in container.get_children():
		c.queue_free()

	var inner = VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 6)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(inner)

	## Shield shape via nested colored panels
	var shield = PanelContainer.new()
	shield.custom_minimum_size = Vector2(130, 140)
	shield.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var style = StyleBoxFlat.new()
	style.bg_color = _color_primary
	style.border_width_left = 5; style.border_width_right = 5
	style.border_width_top = 5; style.border_width_bottom = 5
	style.border_color = _color_secondary
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 40; style.corner_radius_bottom_right = 40
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 14; style.content_margin_bottom = 14
	shield.add_theme_stylebox_override("panel", style)
	inner.add_child(shield)

	## Initials inside shield
	var shield_inner = VBoxContainer.new()
	shield_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	shield.add_child(shield_inner)
	var initials = _get_initials(_team_name if _team_name != "" else "?")
	var lbl_init = Label.new()
	lbl_init.text = initials
	lbl_init.add_theme_font_size_override("font_size", 36)
	lbl_init.add_theme_color_override("font_color", _color_secondary)
	lbl_init.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shield_inner.add_child(lbl_init)

	## Team name below
	var lbl_name = Label.new()
	lbl_name.text = (_team_name if _team_name != "" else "Your Team").to_upper()
	lbl_name.add_theme_font_size_override("font_size", 12)
	lbl_name.add_theme_color_override("font_color", Color.WHITE)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(lbl_name)

	## Color swatches
	var swatch_row = HBoxContainer.new()
	swatch_row.alignment = BoxContainer.ALIGNMENT_CENTER
	swatch_row.add_theme_constant_override("separation", 6)
	inner.add_child(swatch_row)
	for col in [_color_primary, _color_secondary]:
		var sw = ColorRect.new()
		sw.color = col
		sw.custom_minimum_size = Vector2(28, 28)
		var sw_style = StyleBoxFlat.new()
		sw_style.bg_color = col
		sw_style.corner_radius_top_left = 4; sw_style.corner_radius_top_right = 4
		sw_style.corner_radius_bottom_left = 4; sw_style.corner_radius_bottom_right = 4
		swatch_row.add_child(sw)


func _get_initials(name: String) -> String:
	var parts = name.strip_edges().split(" ")
	if parts.size() == 0 or parts[0] == "": return "?"
	if parts.size() == 1: return parts[0].left(2).to_upper()
	return (parts[0].left(1) + parts[-1].left(1)).to_upper()


func _build_color_row(current: Color, on_change: Callable) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	## Preset swatches
	const PRESETS = [
		Color(0.85, 0.12, 0.12), Color(0.1, 0.35, 0.85),  Color(0.1, 0.65, 0.25),
		Color(0.9, 0.65, 0.05),  Color(0.6, 0.1, 0.85),   Color(0.0, 0.0, 0.0),
		Color(1.0, 1.0, 1.0),    Color(0.85, 0.45, 0.05),  Color(0.05, 0.65, 0.75),
	]
	for preset in PRESETS:
		var sw = PanelContainer.new()
		sw.custom_minimum_size = Vector2(30, 30)
		var style = StyleBoxFlat.new()
		style.bg_color = preset
		style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
		if preset.is_equal_approx(current):
			style.border_width_left = 2; style.border_width_right = 2
			style.border_width_top = 2; style.border_width_bottom = 2
			style.border_color = Color.WHITE
		sw.add_theme_stylebox_override("panel", style)
		var p = preset
		var btn = Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(30, 30)
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.pressed.connect(func(): on_change.call(p))
		sw.add_child(btn)
		row.add_child(sw)

	return row


# ══════════════════════════════════════════════════════════════════════════════
# SCREEN 4 — CHAMPIONSHIP SELECTION
# ══════════════════════════════════════════════════════════════════════════════

func _build_championship() -> void:
	var layout = _screen_layout("🏆  CHOOSE YOUR ENTRY POINT", 4)

	var budget = _calc_budget()
	var lbl_info = Label.new()
	lbl_info.text = "Select the discipline you want to start in. Starting budget depends on your championship and difficulty choice. Pick a championship, then set your difficulty on the next screen."
	lbl_info.add_theme_font_size_override("font_size", 13)
	lbl_info.modulate = Color(0.6, 0.6, 0.6)
	lbl_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout["body"].add_child(lbl_info)

	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 14)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout["body"].add_child(grid)

	for cid in TIER1_CHAMPS:
		grid.add_child(_build_champ_card(cid, budget))

	## Live cost summary
	var summary = _build_cost_summary(budget)
	summary.name = "CostSummary"
	layout["body"].add_child(summary)

	_nav_footer(layout["footer"], func(): _show_screen(3), func(): _show_screen(5), "Difficulty →")


func _build_champ_card(cid: String, budget: int) -> PanelContainer:
	var data = TIER1_CHAMPS[cid]
	var is_selected = _selected_champ == cid
	var entry_fee = data["entry_fee"]
	var car_cost = GameState.get_provider_car_cost(cid)
	var total = entry_fee + car_cost
	var can_afford = budget >= total  ## used for colour only, not gating

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.22) if is_selected else Color(0.09, 0.10, 0.13)
	style.border_width_left = 3; style.border_width_right = 3
	style.border_width_top = 3; style.border_width_bottom = 3
	style.border_color = _color_primary if is_selected else Color(0.22, 0.26, 0.32)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 14; style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	## Header
	var lbl_icon = Label.new()
	lbl_icon.text = data["icon"]
	lbl_icon.add_theme_font_size_override("font_size", 32)
	lbl_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_icon)

	var lbl_name = Label.new()
	lbl_name.text = data["name"]
	lbl_name.add_theme_font_size_override("font_size", 16)
	lbl_name.add_theme_color_override("font_color",
		_color_primary if is_selected else Color(0.85, 0.85, 0.85))
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_name)

	var lbl_disc = Label.new()
	lbl_disc.text = data["discipline"]
	lbl_disc.add_theme_font_size_override("font_size", 11)
	lbl_disc.modulate = Color(0.5, 0.5, 0.5)
	lbl_disc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_disc)

	vbox.add_child(HSeparator.new())

	var lbl_desc = Label.new()
	lbl_desc.text = data["desc"]
	lbl_desc.add_theme_font_size_override("font_size", 11)
	lbl_desc.modulate = Color(0.6, 0.6, 0.6)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_desc)

	## Stats
	for row_data in [
		["Races", "%d" % data["races"]],
		["Age", data["age"]],
		["Entry Fee", "CR %s" % _fmt(entry_fee)],
		["Car Cost", "CR %s" % _fmt(car_cost)],
		["Total", "CR %s" % _fmt(total)],
	]:
		var row = HBoxContainer.new()
		var l = Label.new(); l.text = row_data[0]
		l.custom_minimum_size = Vector2(70, 0)
		l.add_theme_font_size_override("font_size", 11)
		l.modulate = Color(0.45, 0.45, 0.45)
		row.add_child(l)
		var v = Label.new(); v.text = row_data[1]
		v.add_theme_font_size_override("font_size", 11)
		if row_data[0] == "Total":
			v.add_theme_color_override("font_color",
				Color(0.4, 0.9, 0.4) if can_afford else Color(1.0, 0.4, 0.4))
		row.add_child(v)
		vbox.add_child(row)

	## Includes — staff and buildings pre-provided
	var lbl_inc_hdr = Label.new()
	lbl_inc_hdr.text = "COMES WITH:"
	lbl_inc_hdr.add_theme_font_size_override("font_size", 10)
	lbl_inc_hdr.modulate = Color(0.4, 0.4, 0.4)
	vbox.add_child(lbl_inc_hdr)
	for item in data.get("includes", []):
		var li = Label.new()
		li.text = "  ✓ %s" % item
		li.add_theme_font_size_override("font_size", 11)
		li.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5))
		vbox.add_child(li)
	for bld in data.get("buildings", []):
		var lb = Label.new()
		lb.text = "  🏗 %s" % bld
		lb.add_theme_font_size_override("font_size", 11)
		lb.add_theme_color_override("font_color", Color(0.55, 0.7, 1.0))
		vbox.add_child(lb)

	## Spacer to push button to bottom
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	## Select button — always enabled, no budget gating
	var btn = Button.new()
	if is_selected:
		btn.text = "✅ Selected"
		btn.disabled = true
	else:
		btn.text = "Select →"
		var c = cid
		btn.pressed.connect(func():
			_selected_champ = c
			_show_screen(4))
	btn.custom_minimum_size = Vector2(0, 34)
	vbox.add_child(btn)

	return panel


func _build_cost_summary(budget: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14)
	style.border_width_top = 1
	style.border_color = Color(0.22, 0.26, 0.32)
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)

	var data = TIER1_CHAMPS.get(_selected_champ, {})
	var entry_fee = data.get("entry_fee", 0)
	var car_cost = GameState.get_provider_car_cost(_selected_champ)
	var total = entry_fee + car_cost
	var remaining = budget - total

	for item in [
		["Starting Budget", "CR %s" % _fmt(budget), Color(0.7, 0.7, 0.7)],
		["Entry Fee", "− CR %s" % _fmt(entry_fee), Color(1.0, 0.6, 0.4)],
		["Car (provider)", "− CR %s" % _fmt(car_cost), Color(1.0, 0.6, 0.4)],
		["Remaining", "CR %s" % _fmt(remaining),
			Color(0.4, 0.9, 0.4) if remaining >= 0 else Color(1.0, 0.35, 0.35)],
	]:
		var col = VBoxContainer.new()
		var l = Label.new(); l.text = item[0]
		l.add_theme_font_size_override("font_size", 10)
		l.modulate = Color(0.45, 0.45, 0.45)
		col.add_child(l)
		var v = Label.new(); v.text = item[1]
		v.add_theme_font_size_override("font_size", 14)
		v.add_theme_color_override("font_color", item[2])
		col.add_child(v)
		row.add_child(col)

	return panel


# ══════════════════════════════════════════════════════════════════════════════
# SCREEN 5 — DIFFICULTY
# ══════════════════════════════════════════════════════════════════════════════

func _build_difficulty() -> void:
	var layout = _screen_layout("⚙  DIFFICULTY", 5)

	var lbl_hint = Label.new()
	lbl_hint.text = "Can be increased at any time. Can only be DECREASED once per career."
	lbl_hint.add_theme_font_size_override("font_size", 12)
	lbl_hint.modulate = Color(0.5, 0.5, 0.5)
	layout["body"].add_child(lbl_hint)

	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout["body"].add_child(cols)

	for diff in ["Rookie", "Amateur", "Realistic", "Expert", "Master"]:
		cols.add_child(_build_difficulty_card(diff))

	_nav_footer(layout["footer"], func(): _show_screen(4), func(): _show_screen(6), "Review & Start →")


func _build_difficulty_card(diff: String) -> PanelContainer:
	var is_selected = _difficulty == diff
	var desc = DIFFICULTY_DESC[diff]

	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.22) if is_selected else Color(0.09, 0.10, 0.13)
	style.border_width_left = 3; style.border_width_right = 3
	style.border_width_top = 3; style.border_width_bottom = 3

	const DIFF_COLORS = {
		"Rookie": Color(0.3, 0.85, 0.4), "Amateur": Color(0.5, 0.8, 0.3),
		"Realistic": Color(0.9, 0.75, 0.1), "Expert": Color(0.95, 0.5, 0.15),
		"Master": Color(0.9, 0.15, 0.15),
	}
	var diff_color = DIFF_COLORS.get(diff, Color.WHITE)
	style.border_color = diff_color if is_selected else Color(0.22, 0.26, 0.32)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 12; style.content_margin_right = 12
	style.content_margin_top = 14; style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var lbl_name = Label.new()
	lbl_name.text = diff.to_upper()
	lbl_name.add_theme_font_size_override("font_size", 15)
	lbl_name.add_theme_color_override("font_color", diff_color)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_name)

	var lbl_budget = Label.new()
	var base = CHAMP_BASE_BUDGETS.get(_selected_champ, 50000)
	var mult = DIFFICULTY_ECONOMY.get(diff, 1.0)
	lbl_budget.text = "CR %s starting" % _fmt(int(base * mult))
	lbl_budget.add_theme_font_size_override("font_size", 11)
	lbl_budget.modulate = Color(0.6, 0.6, 0.6)
	lbl_budget.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_budget)

	vbox.add_child(HSeparator.new())

	for line in desc:
		var lbl = Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.modulate = Color(0.65, 0.65, 0.65) if not line.begins_with("Recommended") \
			and not line.begins_with("A ") and not line.begins_with("The ") \
			and not line.begins_with("Tight") and not line.begins_with("No ") \
			else Color(0.5, 0.75, 1.0)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn = Button.new()
	if is_selected:
		btn.text = "✅ Selected"
		btn.disabled = true
	else:
		btn.text = "Select"
		var d = diff
		btn.pressed.connect(func():
			_difficulty = d
			_show_screen(5))
	btn.custom_minimum_size = Vector2(0, 32)
	vbox.add_child(btn)

	return panel


# ══════════════════════════════════════════════════════════════════════════════
# SCREEN 6 — SUMMARY & CONFIRM
# ══════════════════════════════════════════════════════════════════════════════

func _build_summary() -> void:
	var layout = _screen_layout("🏁  READY TO RACE", 6)

	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout["body"].add_child(cols)

	## Left: summary cards
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 14)
	cols.add_child(left)

	## CEO card
	var ceo_card = _card_panel()
	left.add_child(ceo_card)
	var ceo_vbox = VBoxContainer.new(); ceo_vbox.add_theme_constant_override("separation", 6)
	ceo_card.add_child(ceo_vbox)
	ceo_vbox.add_child(_summary_section("👤  CEO"))
	for row in [
		["Name", _ceo_name if _ceo_name != "" else "CEO"],
		["Sex", _ceo_sex],
		["Age", "%d" % _ceo_age],
		["Nationality", _ceo_nationality],
	]:
		ceo_vbox.add_child(_summary_row(row[0], row[1]))

	## Team card
	var team_card = _card_panel()
	left.add_child(team_card)
	var team_vbox = VBoxContainer.new(); team_vbox.add_theme_constant_override("separation", 6)
	team_card.add_child(team_vbox)
	team_vbox.add_child(_summary_section("🏎  TEAM"))
	team_vbox.add_child(_summary_row("Name", _team_name if _team_name != "" else "My Racing Team"))
	## Color swatches inline
	var color_row = HBoxContainer.new()
	color_row.add_theme_constant_override("separation", 8)
	var lbl_c = Label.new(); lbl_c.text = "Colors"
	lbl_c.custom_minimum_size = Vector2(130, 0)
	lbl_c.add_theme_font_size_override("font_size", 12)
	lbl_c.modulate = Color(0.45, 0.45, 0.45)
	color_row.add_child(lbl_c)
	for col in [_color_primary, _color_secondary]:
		var sw = ColorRect.new()
		sw.color = col
		sw.custom_minimum_size = Vector2(24, 24)
		color_row.add_child(sw)
	team_vbox.add_child(color_row)

	## Championship card
	var champ_data = TIER1_CHAMPS.get(_selected_champ, {})
	var champ_card = _card_panel()
	left.add_child(champ_card)
	var champ_vbox = VBoxContainer.new(); champ_vbox.add_theme_constant_override("separation", 6)
	champ_card.add_child(champ_vbox)
	champ_vbox.add_child(_summary_section("🏆  CHAMPIONSHIP"))
	champ_vbox.add_child(_summary_row("Series", champ_data.get("name", _selected_champ)))
	champ_vbox.add_child(_summary_row("Discipline", champ_data.get("discipline", "")))
	champ_vbox.add_child(_summary_row("Races", "%d" % champ_data.get("races", 0)))

	## Right: badge + financials
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(260, 0)
	right.add_theme_constant_override("separation", 14)
	cols.add_child(right)

	## Badge
	var badge_card = _card_panel()
	badge_card.custom_minimum_size = Vector2(260, 200)
	right.add_child(badge_card)
	_draw_badge(badge_card)

	## Financials
	var fin_card = _card_panel()
	right.add_child(fin_card)
	var fin_vbox = VBoxContainer.new(); fin_vbox.add_theme_constant_override("separation", 6)
	fin_card.add_child(fin_vbox)
	fin_vbox.add_child(_summary_section("💰  FINANCES"))

	var budget = _calc_budget()
	var entry_fee = champ_data.get("entry_fee", 0)
	var car_cost = GameState.get_provider_car_cost(_selected_champ)
	var remaining = budget - entry_fee - car_cost

	fin_vbox.add_child(_summary_row("Difficulty", _difficulty))
	fin_vbox.add_child(_summary_row("Starting Budget", "CR %s" % _fmt(budget)))
	fin_vbox.add_child(_summary_row("Entry Fee", "− CR %s" % _fmt(entry_fee)))
	fin_vbox.add_child(_summary_row("Car", "− CR %s" % _fmt(car_cost)))
	var lbl_rem = _summary_row("After Registration", "CR %s" % _fmt(remaining))
	lbl_rem.get_child(1).add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if remaining >= 0 else Color(1.0, 0.4, 0.4))
	fin_vbox.add_child(lbl_rem)

	## Back left, Start right — consistent with all other screens
	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(100, 40)
	back_btn.pressed.connect(func(): _show_screen(5))
	layout["footer"].add_child(back_btn)

	var start_btn = _big_button("🏁  START YOUR EMPIRE", Color(0.15, 0.55, 0.18))
	start_btn.pressed.connect(_on_start_pressed)
	layout["footer"].add_child(start_btn)


# ══════════════════════════════════════════════════════════════════════════════
# ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

func _on_continue_pressed() -> void:
	if FileAccess.file_exists("user://save_game.json"):
		GameState.load_game()
		get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
	else:
		## Show message on the title screen itself
		_show_screen(1)  ## Rebuild to ensure we're on title
		GameState.add_notification("Normal", "No saved game found. Start a New Game.")

func _on_start_pressed() -> void:
	var team_name  = _team_name  if _team_name  != "" else "My Racing Team"
	var ceo_name   = _ceo_name   if _ceo_name   != "" else "CEO"
	var budget     = _calc_budget()

	GameState.setup_new_game(
		team_name,
		_ceo_nationality,
		ceo_name,
		budget,
		_ceo_sex,
		_ceo_age,
		_color_primary,
		_color_secondary,
		_difficulty,
		_selected_champ
	)
	GameState.emit_signal("log_updated")
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")


# ══════════════════════════════════════════════════════════════════════════════
# LAYOUT HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _screen_layout(title: String, step: int) -> Dictionary:
	var bg = _full_panel(Color(0.06, 0.07, 0.09))
	_root.add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right"]: margin.add_theme_constant_override(s, 60)
	for s in ["margin_top","margin_bottom"]: margin.add_theme_constant_override(s, 30)
	bg.add_child(margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(root_vbox)

	## Step indicator
	var step_row = HBoxContainer.new()
	step_row.add_theme_constant_override("separation", 6)
	root_vbox.add_child(step_row)
	const STEPS = ["Title","CEO","Team","Series","Difficulty","Summary"]
	for i in range(STEPS.size()):
		var lbl = Label.new()
		lbl.text = "%d %s" % [i + 1, STEPS[i]]
		lbl.add_theme_font_size_override("font_size", 10)
		var is_cur = (i + 1) == step
		var is_done = (i + 1) < step
		lbl.add_theme_color_override("font_color",
			Color.WHITE if is_cur else
			Color(0.4, 0.85, 0.4) if is_done else
			Color(0.3, 0.3, 0.3))
		step_row.add_child(lbl)
		if i < STEPS.size() - 1:
			var sep = Label.new(); sep.text = "›"
			sep.modulate = Color(0.25, 0.25, 0.25)
			sep.add_theme_font_size_override("font_size", 10)
			step_row.add_child(sep)

	## Title
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.add_theme_font_size_override("font_size", 26)
	lbl_title.add_theme_color_override("font_color", Color.WHITE)
	root_vbox.add_child(lbl_title)

	## Accent line
	var accent = ColorRect.new()
	accent.color = _color_primary
	accent.custom_minimum_size = Vector2(0, 2)
	root_vbox.add_child(accent)

	## Body — expand to fill
	var body = VBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	root_vbox.add_child(body)

	## Footer
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.alignment = BoxContainer.ALIGNMENT_END
	root_vbox.add_child(footer)

	return {"body": body, "footer": footer}


func _nav_footer(footer: HBoxContainer, back_fn, next_fn, next_label: String) -> void:
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	if back_fn:
		var btn_back = Button.new()
		btn_back.text = "← Back"
		btn_back.custom_minimum_size = Vector2(110, 40)
		btn_back.pressed.connect(back_fn)
		footer.add_child(btn_back)

	if next_fn:
		var btn_next = Button.new()
		btn_next.text = next_label
		btn_next.custom_minimum_size = Vector2(180, 40)
		btn_next.add_theme_font_size_override("font_size", 14)
		var style = StyleBoxFlat.new()
		style.bg_color = _color_primary
		style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
		btn_next.add_theme_stylebox_override("normal", style)
		btn_next.pressed.connect(next_fn)
		footer.add_child(btn_next)


# ══════════════════════════════════════════════════════════════════════════════
# WIDGET HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _full_panel(bg: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _card_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.16)
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.border_color = Color(0.20, 0.24, 0.30)
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.content_margin_left = 16; style.content_margin_right = 16
	style.content_margin_top = 14; style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _big_button(label: String, bg: Color) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(340, 56)
	btn.add_theme_font_size_override("font_size", 20)
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.content_margin_top = 4; style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	var style_hover = style.duplicate()
	style_hover.bg_color = bg.lightened(0.12)
	btn.add_theme_stylebox_override("hover", style_hover)
	return btn

func _toggle_btn(label: String, selected: bool) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(120, 40)
	btn.add_theme_font_size_override("font_size", 14)
	var style = StyleBoxFlat.new()
	style.bg_color = _color_primary if selected else Color(0.14, 0.16, 0.20)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = _color_primary
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	return btn

func _field_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	return lbl

func _line_edit(current: String, placeholder: String) -> LineEdit:
	var le = LineEdit.new()
	le.text = current
	le.placeholder_text = placeholder
	le.custom_minimum_size = Vector2(400, 44)
	le.add_theme_font_size_override("font_size", 18)
	return le

func _summary_section(title: String) -> Label:
	var lbl = Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.45, 0.65, 0.9))
	return lbl

func _summary_row(key: String, value: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	var l = Label.new(); l.text = key
	l.custom_minimum_size = Vector2(130, 0)
	l.add_theme_font_size_override("font_size", 12)
	l.modulate = Color(0.45, 0.45, 0.45)
	row.add_child(l)
	var v = Label.new(); v.text = value
	v.add_theme_font_size_override("font_size", 12)
	v.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	row.add_child(v)
	return row

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.2fM" % (n / 1000000.0)
	if n >= 1000:    return "%dK" % (n / 1000)
	return str(n)
