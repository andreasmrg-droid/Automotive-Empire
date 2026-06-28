## Version: S37.36 — Standard header [Name][Resource Bar][Back][Main Hub].
extends Control
## Version: S35.10d — Added an "All" tab (first): one combined view of every shortlisted person
##   (drivers + all staff), with a Role column to tell them apart and universal sort fields
##   (Overall/Age/Salary). Row type is detected per-row. Per-role tabs unchanged.
## Version: S35.10c — Unified SHORTLIST screen (Stage B). One view spanning BOTH drivers and staff,
##   organised by ROLE TABS (Driver + the 6 staff roles). Reads the GameState shortlist API
##   (get_shortlisted_by_role / get_shortlist_counts, is_shortlisted, toggle_shortlist). Reuses the
##   hub visual language: 24px proportional columns, 100s emphasised, ★ star to remove, active-sort
##   highlight + ▼/▲ arrow + a "Showing: …" summary. Reachable from Staff hub, Drivers hub, Main
##   Hub and HQ. "Back" returns to Main Hub (same as the other hubs).

const ROLE_ICONS := {
	"All": "📋", "Driver": "🏎", "Race Mechanic": "🔧", "Pit Crew": "⏱", "Team Principal": "👔",
	"CFO": "💼", "Designer": "🔬", "Race Strategist": "📡"
}

## Tab order: All first, then Driver, then the staff roles.
var role_tabs: Array = ["All", "Driver", "Race Mechanic", "Pit Crew", "Team Principal",
	"CFO", "Designer", "Race Strategist"]

var current_role: String = "All"
var sort_field: String = "overall"   ## overall works for both drivers and staff (get_overall_skill)
var sort_ascending: bool = false

var list_container: VBoxContainer
var tab_bar: HBoxContainer
var sort_fields_box: HBoxContainer

var _resource_bar = null   ## S37.36 shared ResourceBar
const ResourceBarScript = preload("res://scenes/components/ResourceBar.gd")

func _ready() -> void:
	var layout = VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 8)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 24; layout.offset_top = 16
	layout.offset_right = -24; layout.offset_bottom = -16
	add_child(layout)

	# ── Header ──
	var header = HBoxContainer.new()
	layout.add_child(header)
	var title = Label.new()
	title.text = "⭐ SHORTLIST"
	title.add_theme_font_size_override("font_size", 48)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_resource_bar = ResourceBarScript.new()
	_resource_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(_resource_bar)

	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.add_theme_font_size_override("font_size", 26)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainHub.tscn"))
	header.add_child(back_btn)

	var btn_hub = Button.new()
	btn_hub.text = "🏠 Main Hub"
	btn_hub.add_theme_font_size_override("font_size", 26)
	btn_hub.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainHub.tscn"))
	header.add_child(btn_hub)

	layout.add_child(HSeparator.new())

	# ── Role tabs ──
	tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 6)
	layout.add_child(tab_bar)

	# ── Sort row ──
	var sort_row = HBoxContainer.new()
	sort_row.add_theme_constant_override("separation", 6)
	layout.add_child(sort_row)
	var sort_lbl = Label.new()
	sort_lbl.text = "Sort:"
	sort_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	sort_row.add_child(sort_lbl)
	sort_fields_box = HBoxContainer.new()
	sort_fields_box.add_theme_constant_override("separation", 4)
	sort_row.add_child(sort_fields_box)

	# ── Scrollable list ──
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	list_container = VBoxContainer.new()
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.add_theme_constant_override("separation", 6)
	scroll.add_child(list_container)

	_rebuild_tabs()
	_refresh()

## ── Tabs (with shortlist counts as badges) ───────────────────────────────────
func _rebuild_tabs() -> void:
	for c in tab_bar.get_children():
		c.queue_free()
	var counts = GameState.get_shortlist_counts()
	for role in role_tabs:
		var n: int = counts.get(role, 0)
		var btn = Button.new()
		var short_label: String
		if role == "All":
			short_label = "All"
		elif role == "Driver":
			short_label = "Driver"
		else:
			short_label = role.replace("Race ", "").replace("Team ", "")
		btn.text = "%s %s (%d)" % [ROLE_ICONS.get(role, ""), short_label, n]
		btn.add_theme_font_size_override("font_size", 22)
		btn.flat = (role != current_role)
		var r = role
		btn.pressed.connect(func():
			current_role = r
			## reset sort to a sensible default for the tab type
			sort_field = "overall" if (r == "Driver" or r == "All") else "skill"
			sort_ascending = false
			_rebuild_tabs()
			_refresh())
		tab_bar.add_child(btn)

## ── Sort buttons (active highlight + direction arrow) ────────────────────────
func _rebuild_sort_buttons() -> void:
	for c in sort_fields_box.get_children():
		c.queue_free()
	var fields: Array
	if current_role == "All":
		## Mixed list — only universally-comparable fields.
		fields = [["Overall", "overall"], ["Age", "age"], ["Salary", "salary"]]
	elif current_role == "Driver":
		fields = [["Ovr", "overall"], ["Pace", "pace"], ["Ctrl", "wet"], ["Focus", "focus"],
			["Craft", "craft"], ["Cons", "consistency"], ["Fit", "fitness"], ["Age", "age"],
			["Salary", "salary"]]
	else:
		fields = [["Skill", "skill"], ["Age", "age"], ["Salary", "salary"], ["Rep", "reputation"]]
	for field in fields:
		var btn = Button.new()
		var f = field[1]
		var is_active: bool = (sort_field == f)
		var arrow: String = ("  ▲" if sort_ascending else "  ▼") if is_active else ""
		btn.text = field[0] + arrow
		btn.add_theme_font_size_override("font_size", 22)
		btn.custom_minimum_size = Vector2(0, 26)
		if is_active:
			var astyle = StyleBoxFlat.new()
			astyle.bg_color = Color(0.20, 0.42, 0.65)
			astyle.set_corner_radius_all(4)
			astyle.set_content_margin_all(6)
			btn.add_theme_stylebox_override("normal", astyle)
			btn.add_theme_stylebox_override("hover", astyle)
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
		btn.pressed.connect(func():
			if sort_field == f:
				sort_ascending = !sort_ascending
			else:
				sort_field = f
				sort_ascending = false
			_refresh())
		sort_fields_box.add_child(btn)

## ── List build ───────────────────────────────────────────────────────────────
func _refresh() -> void:
	if _resource_bar != null and _resource_bar.has_method("refresh"):
		_resource_bar.refresh()
	_rebuild_sort_buttons()
	for c in list_container.get_children():
		c.queue_free()

	var people: Array = GameState.get_shortlisted_by_role(current_role)
	people = _sorted(people)

	# Showing summary
	var dir_arrow: String = "▲" if sort_ascending else "▼"
	var summary = Label.new()
	var tab_name: String
	if current_role == "All":
		tab_name = "everyone"
	elif current_role == "Driver":
		tab_name = "Drivers"
	else:
		tab_name = current_role + "s"
	summary.text = "Showing: shortlisted %s · sorted by %s %s" % [tab_name, _sort_label(), dir_arrow]
	summary.add_theme_font_size_override("font_size", 20)
	summary.add_theme_color_override("font_color", Color(0.65, 0.78, 0.95))
	list_container.add_child(summary)

	if people.is_empty():
		var empty = Label.new()
		var noun = "anyone" if current_role == "All" else tab_name.to_lower()
		empty.text = "No shortlisted %s yet. Tap the ★ on anyone in the Drivers or Staff hub to add them here." % noun
		empty.add_theme_font_size_override("font_size", 22)
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list_container.add_child(empty)
		return

	list_container.add_child(_make_header())
	for p in people:
		list_container.add_child(_make_row(p))

func _make_header() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hstyle = StyleBoxFlat.new()
	hstyle.bg_color = Color(0.10, 0.10, 0.13, 0.9)
	hstyle.border_width_left = 3
	hstyle.border_color = Color(0.25, 0.25, 0.3)
	hstyle.content_margin_left = 8; hstyle.content_margin_right = 8
	hstyle.content_margin_top = 4; hstyle.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", hstyle)
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var hc = Color(0.55, 0.55, 0.6)
	_add_col(row, "Name", 200, hc, 20)
	_add_col(row, "Age", 70, hc, 20)
	_add_col(row, "Nationality", 120, hc, 20)
	## S35.10d — show a Role column whenever the list can contain non-drivers (All + staff tabs),
	## so the mixed "All" view tells you who's who. The pure Driver tab omits it.
	if current_role != "Driver":
		_add_col(row, "Role", 160, hc, 20)
	_add_col(row, "Skill", 110, hc, 20)
	_add_col(row, "Team", 180, hc, 20)
	_add_col(row, "Contract", 150, hc, 20)
	_add_col(row, "Salary", 130, hc, 20)
	_add_col(row, "", 60, hc, 20)   ## star column header (blank)
	return panel

func _make_row(p) -> PanelContainer:
	## S35.10d — detect type PER ROW (the All tab mixes drivers + staff). Drivers have no `role`.
	var is_driver: bool = not ("role" in p)
	var show_role_col: bool = (current_role != "Driver")
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.11, 0.13, 1.0)
	style.border_width_left = 3
	style.border_color = Color(1.0, 0.82, 0.2)   ## gold border — it's a shortlisted person
	style.content_margin_left = 8; style.content_margin_right = 8
	style.content_margin_top = 8; style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var row1 = HBoxContainer.new()
	row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)

	_add_col(row1, p.full_name(), 200, Color(0.9, 0.9, 0.9), 24)
	_add_col(row1, "Age %d" % p.age, 70)
	_add_col(row1, p.nationality, 120)

	## Role column (shown for All + staff tabs). Drivers display "🏎 Driver".
	if show_role_col:
		if is_driver:
			_add_col(row1, "%s Driver" % ROLE_ICONS.get("Driver", ""), 160, Color(0.7, 0.85, 1.0))
		else:
			_add_col(row1, "%s %s" % [ROLE_ICONS.get(p.role, ""), p.role], 160, Color(0.7, 0.85, 1.0))

	## Skill column — Overall for drivers, primary-skill for staff.
	var skill_val: float
	var skill_text: String
	if is_driver:
		skill_val = p.get_overall_skill()
		skill_text = "Ovr %.0f" % skill_val
	else:
		skill_val = p.get_primary_skill()
		skill_text = "%s %.0f" % [p.get_primary_skill_label(), skill_val]
	_add_col(row1, skill_text, 110, _skill_color(skill_val))

	_add_col(row1, _team_name_for(p.contract_team), 180, Color(0.8, 0.8, 0.85))

	var status_text: String
	var status_col: Color
	if p.contract_team == "":
		status_text = "Free agent"; status_col = Color(0.4, 0.9, 0.4)
	else:
		var seasons = p.contract_seasons_remaining
		status_text = "%d season%s" % [seasons, "s" if seasons != 1 else ""]
		status_col = Color(1.0, 0.55, 0.2) if seasons <= 1 else Color(0.6, 0.85, 0.6)
	_add_col(row1, status_text, 150, status_col)

	var yearly = int(p.weekly_salary * 52)
	_add_col(row1, "CR %s/yr" % _fmt_sal(yearly), 130, Color(0.6, 0.6, 0.6))

	## ★ remove-from-shortlist star (right column)
	var star = Button.new()
	star.text = "★"
	star.custom_minimum_size = Vector2(50, 28)
	star.add_theme_font_size_override("font_size", 22)
	star.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
	star.tooltip_text = "Remove from shortlist"
	star.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	star.size_flags_stretch_ratio = 60.0
	var sid = p.id
	var stype = "driver" if is_driver else "staff"
	star.pressed.connect(func():
		GameState.toggle_shortlist(sid, stype)
		_rebuild_tabs()   ## counts changed
		_refresh())       ## row disappears from this list
	row1.add_child(star)

	# Stat chips line
	var chips = HBoxContainer.new()
	chips.add_theme_constant_override("separation", 10)
	vbox.add_child(chips)
	if is_driver:
		_chip(chips, "Pace", p.pace)
		_chip(chips, "Car Control", p.car_control)
		_chip(chips, "Focus", p.focus)
		_chip(chips, "Craft", p.race_craft)
		_chip(chips, "Cons", p.consistency)
		_chip(chips, "Fit", p.fitness)
	else:
		for pair in _staff_chip_stats(p):
			_chip(chips, pair[0], pair[1])

	return card

## Staff stat chips per role (a couple of the role's signature stats).
func _staff_chip_stats(s) -> Array:
	match s.role:
		"Team Principal":
			return [["Strat", _g(s, "race_strategy")], ["Practice", _g(s, "practice_management")],
				["Race", _g(s, "race_pace_reading")], ["Pit", _g(s, "pit_stop_management")],
				["PR", _g(s, "pr_skill")], ["Rep", _g(s, "reputation")]]
		"Race Mechanic":
			return [["Setup", _g(s, "car_setup")], ["Pit Stops", _g(s, "pit_stops")],
				["Car Know", _g(s, "parts_knowledge")], ["Rep", _g(s, "reputation")]]
		"Pit Crew":
			return [["Pit Speed", _g(s, "pit_stop_speed")], ["Repair", _g(s, "repair_skill")],
				["Fatigue Res", _g(s, "fatigue_resistance")], ["Fitness", _g(s, "fitness")]]
		"CFO":
			return [["Fin Mgmt", _g(s, "budget_planning")], ["Negot", _g(s, "sponsor_negotiation")],
				["Sales", _g(s, "sales_skill")], ["Resource", _g(s, "resource_management")],
				["Rep", _g(s, "reputation")]]
		"Designer":
			return [["Engine", _g(s, "engine")], ["Aero", _g(s, "aero")], ["Chassis", _g(s, "chassis")],
				["Reliability", _g(s, "reliability")], ["Parts Know", _g(s, "parts_knowledge")]]
		"Race Strategist":
			return [["Strat", _g(s, "race_strategy")], ["Pace Read", _g(s, "race_pace_reading")],
				["Quali", _g(s, "qualifying_timing")], ["Rep", _g(s, "reputation")]]
		_:
			return [["Rep", _g(s, "reputation")]]

func _g(obj, prop: String) -> float:
	return float(obj.get(prop)) if prop in obj else 0.0

## ── Sorting ──────────────────────────────────────────────────────────────────
func _sorted(people: Array) -> Array:
	var arr = people.duplicate()
	arr.sort_custom(func(a, b):
		var va = _sort_val(a)
		var vb = _sort_val(b)
		if sort_ascending:
			return va < vb
		return va > vb)
	return arr

func _sort_val(p) -> float:
	match sort_field:
		"age":        return float(p.age)
		"salary":     return float(p.weekly_salary)
		"reputation": return _g(p, "reputation")
		"overall":    return p.get_overall_skill() if p.has_method("get_overall_skill") else 0.0
		"pace":       return _g(p, "pace")
		"wet":        return _g(p, "car_control")
		"focus":      return _g(p, "focus")
		"craft":      return _g(p, "race_craft")
		"consistency":return _g(p, "consistency")
		"fitness":    return _g(p, "fitness")
		"skill":      return p.get_primary_skill() if p.has_method("get_primary_skill") else 0.0
		_:            return 0.0

func _sort_label() -> String:
	match sort_field:
		"overall": return "Overall"
		"pace": return "Pace"
		"wet": return "Car Control"
		"focus": return "Focus"
		"craft": return "Craft"
		"consistency": return "Consistency"
		"fitness": return "Fitness"
		"age": return "Age"
		"salary": return "Salary"
		"reputation": return "Reputation"
		"skill": return "Skill"
		_: return sort_field.capitalize()

## ── Small UI helpers (mirror the hub visual language) ────────────────────────
func _add_col(parent: HBoxContainer, text: String, weight: int,
		color: Color = Color.WHITE, font_size: int = 24) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_stretch_ratio = float(weight)
	lbl.custom_minimum_size = Vector2(40, 0)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.clip_text = true
	parent.add_child(lbl)

func _chip(parent: HBoxContainer, label: String, value: float) -> void:
	var lbl = Label.new()
	lbl.text = "%s %.0f" % [label, value]
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.45) if value >= 100.0 else _skill_color(value))
	parent.add_child(lbl)

func _skill_color(v: float) -> Color:
	if v >= 90: return Color(0.3, 0.9, 0.3)
	if v >= 75: return Color(0.6, 0.9, 0.4)
	if v >= 55: return Color(0.9, 0.85, 0.4)
	if v >= 35: return Color(0.9, 0.6, 0.3)
	return Color(0.9, 0.4, 0.4)

func _team_name_for(contract_team_id: String) -> String:
	if contract_team_id == "":
		return "—"
	if contract_team_id == GameState.player_team.id:
		return GameState.player_team.team_name
	for t in GameState.all_teams:
		if t.id == contract_team_id:
			return t.team_name
	return contract_team_id

func _fmt_sal(amount: int) -> String:
	if amount >= 1000:
		return "%dK" % int(amount / 1000.0)
	return str(amount)
