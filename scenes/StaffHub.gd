## Version: S37.37 — Notification & News Roadmap, Phase 1: generic error add_notification(err)
##   passthrough converted to GameState.show_popup() (on-the-spot AcceptDialog), consistent with the
##   existing scene popups (#41 / S29.0). Specific cases (not_interested / team_refused) unchanged.
## Version: S37.36 — Standard minimal header [Name][Resource Bar][Back][Main Hub]; Shortlist entry
##   moved to a sub-row below the header (Main Hub concept).
## Version: S37.24 — popup-position: staff cards CENTERED on screen (anchors 0.5, symmetric
##   offsets) instead of hugging the right edge; both card builders updated.
## Version: S37.18 — #1 screenshot follow-ups: CFO row "Fin Mgmt 0" (read removed
##   financial_management) → loan_management; CFO Skill-column label "Resources"→"Negotiation"
##   (matched the value); finmgmt sort key fixed. Card popup WIDENED + pulled in from the right
##   edge (was clipping) + value labels clip/ellipsis; card now closes on role-tab switch.
## Version: S37.17 — #1 CFO attributes showed all 0: detail card read the REMOVED field
##   `interest_rates` (broke the attribute-list build). Now reads the real `speculation` stat.
##   Also fixed Mechanic `car_knowledge`→`parts_knowledge` (detail list, row, sort key) and added
##   the TP `talent_scouting` stat to the TP detail list.
extends Control
## Version: S37.9 — Bug #43: removed the live count from the My/Available Staff tab labels (the
##   "(2)"/"(179)" parentheses) per design. Tab buttons now read plain "👥 My Staff" /
##   "🌍 Available Staff".
## Version: S36.10 — Bug (cluster A): the "Assign to championship" popup now lists only the player's
##   REGISTERED championships (via get_player_championships), not all 21 world championships. Also
##   fixed the tiny My-Staff name font (14 → 24) to match the Available list and be readable.
##   (NOTE: _has_assigned_tp() still scans all championships — deferred to the TP/staff-assignment
##   cluster. The Ops Sim assign button bug is also in that cluster; this popup is the working path.)
## Version: S35.10c — Added ⭐ Shortlist entry button (opens the unified Shortlist screen) and a
##   "Free Agents Only" toggle (matches the Drivers hub) next to "Interested Only".
## Version: S35.10b — Alignment fix: columns are now PROPORTIONAL (stretch ratios via
##   size_flags_stretch_ratio) instead of fixed pixel widths, so the grid uses the FULL screen
##   width and no longer clips ("Age 3⋮", truncated team/role names). Header panel matches the row
##   card's left border + margins so columns line up. Rows/headers expand-fill.
## Version: S35.10 — Hub UX pass: available rows at 24px (was 13px), 100s emphasized; TEAM and
##   CONTRACT split into two aligned columns (+ column header); ★ shortlist star on each row and in
##   the View Card popup (synced via is_shortlisted); active-sort highlight + ▼/▲ arrow + a
##   "Showing: …" summary line so the applied filter/sort is always clear.
## Version: S35.9 — "Interested Only" now uses the shared DETERMINISTIC interest predicate
##   (matches the approach; binary, no percentage) + hides team-refusal-cooldown people. Added a
##   team-won't-release popup on approach. Context built once per pass (keeps perf).
## Version: S35.7 — PERF: "Interested Only" filter no longer recomputes TP rep / champ tier and
##   scans all_teams for each of 5000+ staff (the button lag) — invariants hoisted out of the loop,
##   team reps pre-indexed for O(1) lookup.
## Version: S33.2 — Race Strategist slot check now reads Ops Sim & Telemetry building level
##   (was hardcoded to 1), matching the canonical building-based slot rule and the engine.
## Version: S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## Version: S29.0 — Not-interested popup (issue 1). Page-transition perf: _refresh_list
##   detaches rows synchronously (issue 4).
## --- S28.3 — Fixed crash risk: Pit Crew "teamwork" (removed) → "fatigue_resistance"
##   across stat display + sort. Re-applied "Wet"→"Car Control".
## --- S28.2 — Search box + pagination (25/page) on Available Staff tab. Renders only the
##   current page instead of the whole staff pool (perf fix). Search filters by name/nationality.
## --- S22.8 — #8 walk-away hides row; #14 TP gate for free agents only for bond approach.
##                    Free agents signable for next season when slots full (or is_free_agent).
##                    View Card hire button: timing popup + next-season fallback.

# ── State ─────────────────────────────────────────────────────────────────────
var current_tab: String = "my_staff"
var sort_field: String = "skill"
var sort_ascending: bool = false
var role_filter: String = "All"
var interested_only: bool = false  ## P33: show only staff likely interested in joining
var free_agents_only: bool = false  ## S35.10c — show only uncontracted staff (Drivers-hub parity)

## S28.2 — search + pagination state (perf fix for large staff pools)
var search_text: String = ""
var current_page: int = 0
const PAGE_SIZE: int = 25
var search_field_node: LineEdit = null
var page_nav_row: HBoxContainer = null

const ROLE_ICONS = {
	"Race Mechanic":   "🔧",
	"Pit Crew":        "⏱",
	"Team Principal":  "🧑‍💼",
	"CFO":             "💼",
	"Designer":        "🔬",
	"Race Strategist": "📡",
}

const ROLE_SHORT = {
	"Race Mechanic":   "Mechanic",
	"Pit Crew":        "Pit Crew",
	"Team Principal":  "Principal",
	"CFO":             "CFO",
	"Designer":        "Designer",
	"Race Strategist": "Strategist",
}

# ── Node refs ─────────────────────────────────────────────────────────────────
var tab_my_btn: Button
var tab_all_btn: Button
var list_container: VBoxContainer
var filter_btns: Dictionary = {}
var card_overlay: PanelContainer = null
var sort_row_node: HBoxContainer = null  ## ref for dynamic sort bar rebuild

var _resource_bar = null   ## S37.36 shared ResourceBar
const ResourceBarScript = preload("res://scenes/components/ResourceBar.gd")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	# Apply pre-filter if set by another scene (e.g. Garage sets "Race Mechanic")
	if GameState.pending_staff_filter != "":
		role_filter = GameState.pending_staff_filter
		GameState.pending_staff_filter = ""
		_show_tab("available_staff")

func _build_ui() -> void:
	var layout = VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 20
	layout.offset_top = 20
	layout.offset_right = -20
	layout.offset_bottom = -20
	layout.add_theme_constant_override("separation", 10)
	add_child(layout)

	# Header
	var header = HBoxContainer.new()
	layout.add_child(header)
	var title = Label.new()
	title.text = "🧑‍🔧 STAFF"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	# Standard header: [Name][Resource Bar][Back][Main Hub]
	_resource_bar = ResourceBarScript.new()
	_resource_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(_resource_bar)

	var back_btn = Button.new()
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(100, 40)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	var btn_hub = Button.new()
	btn_hub.text = "🏠 Main Hub"
	btn_hub.custom_minimum_size = Vector2(140, 40)
	btn_hub.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainHub.tscn"))
	header.add_child(btn_hub)

	layout.add_child(HSeparator.new())

	# Sub-header row: scene-specific Shortlist entry below the header (Main Hub concept)
	var subrow = HBoxContainer.new()
	subrow.add_theme_constant_override("separation", 12)
	layout.add_child(subrow)
	var shortlist_btn = Button.new()
	shortlist_btn.text = "⭐ Shortlist"
	shortlist_btn.custom_minimum_size = Vector2(140, 40)
	shortlist_btn.tooltip_text = "View your shortlisted drivers & staff"
	shortlist_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Shortlist.tscn"))
	subrow.add_child(shortlist_btn)

	# Tabs
	var tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	layout.add_child(tab_row)

	tab_my_btn = Button.new()
	tab_my_btn.text = "👥 My Staff"
	tab_my_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_my_btn.pressed.connect(func(): _show_tab("my_staff"))
	tab_row.add_child(tab_my_btn)

	tab_all_btn = Button.new()
	tab_all_btn.text = "🌍 Available Staff"
	tab_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_all_btn.pressed.connect(func(): _show_tab("available_staff"))
	tab_row.add_child(tab_all_btn)

	# Role filter bar
	var filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 4)
	layout.add_child(filter_row)
	var filter_lbl = Label.new()
	filter_lbl.text = "Role:"
	filter_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	filter_row.add_child(filter_lbl)

	for role in ["All", "Race Mechanic", "Pit Crew", "Team Principal",
			"CFO", "Designer", "Race Strategist"]:
		var btn = Button.new()
		btn.text = role if role == "All" else ROLE_ICONS.get(role, "") + " " + ROLE_SHORT.get(role, role)
		btn.custom_minimum_size = Vector2(0, 28)
		var _r = role
		btn.pressed.connect(func():
			role_filter = _r
			sort_field = "skill" if _r != "All" else "age"  ## All has no Skill sort
			## Close any open card — it belongs to the previous role's staff (stale-card fix).
			if card_overlay:
				card_overlay.queue_free()
				card_overlay = null
			_rebuild_sort_bar()
			_refresh_list()
		)
		filter_row.add_child(btn)
		filter_btns[role] = btn

	# Sort bar — dynamic, rebuilt when role filter changes
	sort_row_node = HBoxContainer.new()
	sort_row_node.add_theme_constant_override("separation", 4)
	layout.add_child(sort_row_node)
	_rebuild_sort_bar()

	# Search bar (S28.2)
	var search_row = HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 6)
	layout.add_child(search_row)
	var search_lbl = Label.new()
	search_lbl.text = "🔍 Search:"
	search_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	search_row.add_child(search_lbl)
	search_field_node = LineEdit.new()
	search_field_node.placeholder_text = "Filter by name or nationality…"
	search_field_node.custom_minimum_size = Vector2(280, 26)
	search_field_node.text = search_text
	search_field_node.text_changed.connect(func(t: String):
		search_text = t.strip_edges()
		current_page = 0
		_refresh_list())
	search_row.add_child(search_field_node)

	# Scroll + list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 5)
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_container)

	# Page navigation row (S28.2)
	page_nav_row = HBoxContainer.new()
	page_nav_row.add_theme_constant_override("separation", 8)
	page_nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(page_nav_row)

	_show_tab("my_staff")

## Rebuild sort bar with fields relevant to the current role_filter
func _rebuild_sort_bar() -> void:
	if sort_row_node == null: return
	for c in sort_row_node.get_children(): c.free()

	var sort_lbl = Label.new()
	sort_lbl.text = "Sort:"
	sort_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	sort_row_node.add_child(sort_lbl)

	## Fields per role
	var fields: Array
	match role_filter:
		"Team Principal":
			fields = [["Strategy","strategy"],["Practice","practice"],["Qualifying","qualifying"],
				["Race Pace","race_pace"],["Pit Mgmt","pit_mgmt"],["PR","pr"],["Rep","reputation"],
				["Age","age"],["Salary","salary"]]
		"Race Mechanic":
			fields = [["Car Setup","setup"],["Pit Stops","pit_stops"],["Car Know","car_know"],
				["Track Know","track_know"],["Age","age"],["Salary","salary"]]
		"Pit Crew":
			fields = [["Pit Speed","pit_stop"],["Repair","repair"],["Fatigue Res","fatigue_resistance"],
				["Fitness","fitness"],["Age","age"],["Salary","salary"]]
		"CFO":
			fields = [["Fin Mgmt","finmgmt"],["Negotiation","negotiation"],["Sales","sales"],
				["Resource","resource"],["Age","age"],["Salary","salary"]]
		"Designer":
			fields = [["Aero","aero"],["Engine","engine"],["Chassis","chassis"],
				["Gearbox","gearbox"],["Suspension","suspension"],["Brakes","brakes"],
				["Parts Know","parts_know"],["Reliability","reliability"],
				["Age","age"],["Salary","salary"]]
		"Race Strategist":
			fields = [["Strategy","strategy"],["Race Pace","race_pace"],["Practice","practice"],
				["Quali Timing","quali_timing"],["Track Know","track_know"],
				["Age","age"],["Salary","salary"]]
		_: ## All
			fields = [["Age","age"],["Salary","salary"],["Rep","reputation"]]

	for field in fields:
		var btn = Button.new()
		var f = field[1]
		## S35.10 — show which sort is active + its direction (▼ high→low, ▲ low→high).
		var is_active: bool = (sort_field == f)
		var arrow: String = ""
		if is_active:
			arrow = "  ▲" if sort_ascending else "  ▼"
		btn.text = field[0] + arrow
		btn.custom_minimum_size = Vector2(0, 26)
		btn.add_theme_font_size_override("font_size", 22)
		if is_active:
			## Highlight the active sort button so the player can see what's applied at a glance.
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
			current_page = 0
			_refresh_list())
		sort_row_node.add_child(btn)

	## Spacer
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sort_row_node.add_child(sp)

	## Interested Only toggle
	var btn_interested = Button.new()
	btn_interested.text = "⭐ Interested Only"
	btn_interested.custom_minimum_size = Vector2(140, 26)
	btn_interested.add_theme_font_size_override("font_size", 22)
	btn_interested.toggle_mode = true
	btn_interested.button_pressed = interested_only
	btn_interested.tooltip_text = "Show only staff likely interested in joining your team."
	btn_interested.toggled.connect(func(on: bool):
		interested_only = on
		current_page = 0
		_refresh_list())
	sort_row_node.add_child(btn_interested)

	## S35.10c — Free Agents Only toggle (matches the Drivers hub).
	var btn_fa = Button.new()
	btn_fa.text = "Free Agents Only"
	btn_fa.custom_minimum_size = Vector2(140, 26)
	btn_fa.add_theme_font_size_override("font_size", 22)
	btn_fa.toggle_mode = true
	btn_fa.button_pressed = free_agents_only
	btn_fa.tooltip_text = "Show only uncontracted (free agent) staff."
	btn_fa.toggled.connect(func(on: bool):
		free_agents_only = on
		current_page = 0
		_refresh_list())
	sort_row_node.add_child(btn_fa)

# ── Tab switching ─────────────────────────────────────────────────────────────

func _show_tab(tab: String) -> void:
	current_tab = tab
	current_page = 0
	tab_my_btn.flat = (tab != "my_staff")
	tab_all_btn.flat = (tab != "available_staff")
	_refresh_list()

func _refresh_list() -> void:
	for child in list_container.get_children():
		list_container.remove_child(child)
		child.queue_free()

	if current_tab == "my_staff":
		_build_my_staff_list()
		_clear_page_nav()  ## my-staff list is small; no pagination
	else:
		_build_available_staff_list()

## S28.2 — filter a staff array by search text (name or nationality, case-insensitive).
func _apply_search(staff_list: Array) -> Array:
	if search_text == "":
		return staff_list
	var q = search_text.to_lower()
	return staff_list.filter(func(s):
		return q in s.full_name().to_lower() or q in s.nationality.to_lower())

func _clear_page_nav() -> void:
	if page_nav_row == null: return
	for c in page_nav_row.get_children():
		c.queue_free()

func _build_page_nav(total: int, start: int, end: int, max_page: int) -> void:
	_clear_page_nav()
	if total <= PAGE_SIZE:
		return
	var prev_btn = Button.new()
	prev_btn.text = "◀ Prev"
	prev_btn.custom_minimum_size = Vector2(80, 28)
	prev_btn.disabled = current_page <= 0
	prev_btn.pressed.connect(func():
		current_page -= 1
		_refresh_list())
	page_nav_row.add_child(prev_btn)
	var info = Label.new()
	info.text = "Showing %d–%d of %d  (page %d/%d)" % [
		start + 1, end, total, current_page + 1, max_page + 1]
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	page_nav_row.add_child(info)
	var next_btn = Button.new()
	next_btn.text = "Next ▶"
	next_btn.custom_minimum_size = Vector2(80, 28)
	next_btn.disabled = current_page >= max_page
	next_btn.pressed.connect(func():
		current_page += 1
		_refresh_list())
	page_nav_row.add_child(next_btn)

# ── My Staff ──────────────────────────────────────────────────────────────────

func _build_my_staff_list() -> void:
	var all_my = GameState.get_all_player_staff()
	var filtered = _filter_and_sort(all_my)

	if filtered.is_empty():
		var lbl = Label.new()
		lbl.text = "No staff hired yet. Browse available staff to hire."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list_container.add_child(lbl)
		return

	# Group by role for My Staff view
	var by_role: Dictionary = {}
	for staff in filtered:
		if not staff.role in by_role:
			by_role[staff.role] = []
		by_role[staff.role].append(staff)

	for role in GameState.STAFF_ROLES:
		if not role in by_role:
			continue
		# Role header
		var role_hdr = Label.new()
		role_hdr.text = "%s %s" % [ROLE_ICONS.get(role, ""), role.to_upper()]
		role_hdr.add_theme_font_size_override("font_size", 26)
		role_hdr.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
		list_container.add_child(role_hdr)

		for staff in by_role[role]:
			list_container.add_child(_make_my_staff_row(staff))

## Returns array of [label, value] for all visible attributes of a staff member by role.
func _get_role_stats(staff) -> Array:
	match staff.role:
		"Team Principal":
			return [
				["Strat", staff.race_strategy if "race_strategy" in staff else 0.0],
				["Practice", staff.practice_management if "practice_management" in staff else 0.0],
				["Quali", staff.qualifying_management if "qualifying_management" in staff else 0.0],
				["Race", staff.race_pace_reading if "race_pace_reading" in staff else 0.0],
				["Pit", staff.pit_stop_management if "pit_stop_management" in staff else 0.0],
				["PR", staff.pr_skill if "pr_skill" in staff else 0.0],
				["Rep", staff.reputation if "reputation" in staff else 0.0],
			]
		"Race Mechanic":
			return [
				["Setup", staff.car_setup if "car_setup" in staff else 0.0],
				["Pit Stops", staff.pit_stops if "pit_stops" in staff else 0.0],
				["Parts Know", staff.parts_knowledge if "parts_knowledge" in staff else 0.0],
				["Rep", staff.reputation if "reputation" in staff else 0.0],
			]
		"Pit Crew":
			return [
				["Pit Speed", staff.pit_stop_speed if "pit_stop_speed" in staff else 0.0],
				["Repair", staff.repair_skill if "repair_skill" in staff else 0.0],
				["Fatigue Res", staff.fatigue_resistance],
				["Fitness", staff.fitness if "fitness" in staff else 0.0],
			]
		"CFO":
			return [
				["Fin Mgmt", staff.loan_management if "loan_management" in staff else 0.0],
				["Negot", staff.sponsor_negotiation if "sponsor_negotiation" in staff else 0.0],
				["Sales", staff.sales_skill if "sales_skill" in staff else 0.0],
				["Resource", staff.resource_management if "resource_management" in staff else 0.0],
				["Rep", staff.reputation if "reputation" in staff else 0.0],
			]
		"Designer":
			return [
				["Aero", staff.aero if "aero" in staff else 0.0],
				["Eng", staff.engine if "engine" in staff else 0.0],
				["Chassis", staff.chassis if "chassis" in staff else 0.0],
				["Gearbox", staff.gearbox if "gearbox" in staff else 0.0],
				["Susp", staff.suspension if "suspension" in staff else 0.0],
				["Brakes", staff.brakes if "brakes" in staff else 0.0],
				["P.Know", staff.parts_knowledge if "parts_knowledge" in staff else 0.0],
			]
		"Race Strategist":
			return [
				["Strat", staff.race_strategy if "race_strategy" in staff else 0.0],
				["Race", staff.race_pace_reading if "race_pace_reading" in staff else 0.0],
				["Practice", staff.practice_management if "practice_management" in staff else 0.0],
				["Q.Timing", staff.qualifying_timing if "qualifying_timing" in staff else 0.0],
				["Rep", staff.reputation if "reputation" in staff else 0.0],
			]
	return []

## Adds a coloured stat chip label to a container.
func _add_stat_chip(container: HBoxContainer, label: String, value: float) -> void:
	var lbl = Label.new()
	lbl.text = "%s %.0f" % [label, value]
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", _skill_color(value))
	## S35.10 — emphasize a maxed (100) stat with a brighter green so the eye finds it instantly.
	if value >= 100.0:
		lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.45))
	container.add_child(lbl)

func _make_my_staff_row(staff) -> PanelContainer:
	var card = _make_card_panel(true)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Row 1 — identity
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)
	_add_col(row1, staff.display_name(), 170, Color(0.9, 0.9, 0.9), 24)
	_add_col(row1, "Age %d" % staff.age, 55)
	_add_col(row1, staff.nationality, 100)
	_add_col(row1, "%s %.0f" % [staff.get_primary_skill_label(), staff.get_primary_skill()], 100,
		_skill_color(staff.get_primary_skill()))

	# Assignment status
	var assign_text = ""
	if staff.role == "CFO" or staff.role == "Designer":
		assign_text = "Team Level"
	elif staff.assigned_car_id != "":
		var car = GameState.get_car_by_id(staff.assigned_car_id)
		assign_text = _car_display_name(car) if car else "Car ?"
	elif staff.assigned_championship != "":
		var _reg = GameState.CHAMPIONSHIP_REGISTRY.get(staff.assigned_championship, {})
		assign_text = _reg.get("name", staff.assigned_championship)
	else:
		var pending_champ = GameState.get_pending_assignment_for(staff.id)
		if pending_champ != "":
			var _preg = GameState.CHAMPIONSHIP_REGISTRY.get(pending_champ, {})
			assign_text = "⏳ %s (next wk)" % _preg.get("name", pending_champ)
		else:
			assign_text = "⚠ Unassigned"
	var assign_color = Color(0.6, 0.6, 0.6) if assign_text == "Team Level" \
		else (Color(0.4, 0.9, 0.4) if assign_text != "⚠ Unassigned" \
		else Color(1.0, 0.6, 0.2))
	_add_col(row1, assign_text, 130, assign_color)

	# Previous season championship indicator
	var prev_champ_id = GameState.previous_season_championship.get(staff.id, "")
	if prev_champ_id != "":
		var prev_reg = GameState.CHAMPIONSHIP_REGISTRY.get(prev_champ_id, {})
		_add_col(row1, "↩ %s" % prev_reg.get("name", prev_champ_id).left(18), 140, Color(0.5, 0.75, 0.5))

	# Contract
	var contract_color = Color(1.0, 0.4, 0.4) if staff.contract_seasons_remaining <= 1 \
		else Color(0.7, 0.7, 0.7)
	_add_col(row1, "%d season%s" % [staff.contract_seasons_remaining, "s" if staff.contract_seasons_remaining != 1 else ""], 100, contract_color)
	_add_col(row1, "CR %s/yr" % _fmt_sal(int(staff.weekly_salary * 52)), 90, Color(0.6, 0.9, 0.6))

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	var s_id = staff.id

	var view_btn = Button.new()
	view_btn.text = "📋 View Card"
	view_btn.custom_minimum_size = Vector2(100, 28)
	view_btn.pressed.connect(func(): _show_staff_card(s_id))
	btn_row.add_child(view_btn)

	# Assign button — not shown for CFO (team-level role, no assignment needed)
	if staff.role != "CFO":
		var assign_btn = Button.new()
		assign_btn.text = "📌 Assign"
		assign_btn.custom_minimum_size = Vector2(85, 28)
		assign_btn.pressed.connect(func(): _show_assign_popup(s_id))
		btn_row.add_child(assign_btn)

	var renew_btn = Button.new()
	renew_btn.text = "📋 Renegotiate"
	renew_btn.custom_minimum_size = Vector2(145, 28)
	renew_btn.pressed.connect(func():
		var ap = GameState.make_renegotiation_approach(s_id, "staff")
		if ap.is_empty(): return
		var panel = preload("res://scenes/ContractNegotiation.tscn").instantiate()
		get_tree().current_scene.add_child(panel)
		panel.open_approach(ap)
		panel.closed.connect(func(): _refresh_list()))
	btn_row.add_child(renew_btn)

	var release_btn = Button.new()
	release_btn.text = "👋 Release"
	release_btn.custom_minimum_size = Vector2(85, 28)
	release_btn.pressed.connect(func(): _confirm_release_staff(s_id))
	btn_row.add_child(release_btn)

	## Row 2 — role-specific stat chips
	var stats = _get_role_stats(staff)
	if not stats.is_empty():
		var row2 = HBoxContainer.new()
		row2.add_theme_constant_override("separation", 12)
		vbox.add_child(row2)
		for stat in stats:
			_add_stat_chip(row2, stat[0], stat[1])

	return card

# ── Available Staff ───────────────────────────────────────────────────────────

func _build_available_staff_list() -> void:
	## Show all non-player staff — free agents AND contracted (approachable)
	var all_non_player: Array = []

	## S35.9 — build the interest context ONCE for the whole filter pass (player rep, TP modifier,
	## team-rep index), so the shared deterministic predicate stays cheap per candidate (preserves
	## the S35.7 perf win — no per-staff re-looping of championships/teams).
	var interest_ctx := {}
	if interested_only:
		interest_ctx = GameState.build_interest_context()

	for sid in GameState.all_staff:
		var s = GameState.all_staff[sid]
		if s.contract_team == GameState.player_team.id:
			continue
		## S35.10c — Free Agents Only: skip contracted staff.
		if free_agents_only and s.contract_team != "":
			continue
		## S35.9 — Interested Only uses the SHARED deterministic predicate (the same one the approach
		## honours), so the filter is truthful: everyone shown personally wants to join. Binary, no
		## percentage. Also hides anyone under an active team-refusal cooldown (can't be approached).
		if interested_only:
			if not GameState.is_subject_interested(s.id, "staff", s.contract_team, interest_ctx):
				continue
			if not GameState.is_team_refusal_cooled_down(s.id):
				continue
		all_non_player.append(s)
	var filtered = _filter_and_sort(all_non_player)
	filtered = _apply_search(filtered)

	if filtered.is_empty():
		var lbl = Label.new()
		lbl.text = "No available staff match." if search_text != "" else "No available staff match the current filter."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list_container.add_child(lbl)
		_clear_page_nav()
		return

	var total = filtered.size()
	var max_page = int(ceil(float(total) / PAGE_SIZE)) - 1
	current_page = clamp(current_page, 0, max_page)
	var start = current_page * PAGE_SIZE
	var end = min(start + PAGE_SIZE, total)
	_add_showing_summary()    ## S35.10 — plain-language "what's applied right now" line
	_add_available_header()  ## S35.10 — aligned column labels above the rows
	for i in range(start, end):
		list_container.add_child(_make_available_staff_row(filtered[i]))
	_build_page_nav(total, start, end, max_page)

## S35.10 — a plain-language line telling the player exactly what filter + sort are applied, so the
## state of the list is never a mystery. e.g. "Showing: Mechanics · interested only · sorted by Pit Stops ▼"
func _add_showing_summary() -> void:
	var parts: Array = []
	if role_filter == "All":
		parts.append("all roles")
	else:
		parts.append(ROLE_SHORT.get(role_filter, role_filter) + "s")
	if interested_only:
		parts.append("interested only")
	if free_agents_only:
		parts.append("free agents only")
	if search_text != "":
		parts.append("search \"%s\"" % search_text)
	var dir_arrow: String = "▲" if sort_ascending else "▼"
	parts.append("sorted by %s %s" % [_sort_field_label(), dir_arrow])
	var lbl = Label.new()
	lbl.text = "Showing: " + " · ".join(parts)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.78, 0.95))
	list_container.add_child(lbl)

## Human-readable label for the active sort field.
func _sort_field_label() -> String:
	match sort_field:
		"skill": return "Skill"
		"age": return "Age"
		"salary": return "Salary"
		"reputation": return "Reputation"
		"strategy": return "Strategy"
		"practice": return "Practice"
		"qualifying": return "Qualifying"
		"race_pace": return "Race Pace"
		"pit_mgmt": return "Pit Mgmt"
		"pr": return "PR"
		"setup": return "Car Setup"
		"pit_stops": return "Pit Stops"
		"car_know": return "Car Know"
		"track_know": return "Track Know"
		"pit_stop": return "Pit Speed"
		"repair": return "Repair"
		"fatigue_resistance": return "Fatigue Res"
		"fitness": return "Fitness"
		"finmgmt": return "Fin Mgmt"
		"negotiation": return "Negotiation"
		"sales": return "Sales"
		"resource": return "Resource"
		"aero": return "Aero"
		"engine": return "Engine"
		"chassis": return "Chassis"
		"gearbox": return "Gearbox"
		"suspension": return "Suspension"
		"brakes": return "Brakes"
		"parts_know": return "Parts Know"
		"reliability": return "Reliability"
		"quali_timing": return "Quali Timing"
		_: return sort_field.capitalize()

## S35.10b — column header for the available-staff grid. Uses the SAME proportional weights as
## _make_available_staff_row so columns line up; expands to full width like the rows.
func _add_available_header() -> void:
	var hdr_panel = PanelContainer.new()
	hdr_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hstyle = StyleBoxFlat.new()
	hstyle.bg_color = Color(0.10, 0.10, 0.13, 0.9)
	## Match the row card's left border (3px) + content margins so header columns align with rows.
	hstyle.border_width_left = 3
	hstyle.border_color = Color(0.25, 0.25, 0.3)
	hstyle.content_margin_left = 8; hstyle.content_margin_right = 8
	hstyle.content_margin_top = 4; hstyle.content_margin_bottom = 4
	hdr_panel.add_theme_stylebox_override("panel", hstyle)
	var hrow = HBoxContainer.new()
	hrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_theme_constant_override("separation", 8)
	hdr_panel.add_child(hrow)
	var hc = Color(0.55, 0.55, 0.6)
	_add_col(hrow, "Name", 200, hc, 20)
	_add_col(hrow, "Age", 70, hc, 20)
	_add_col(hrow, "Nationality", 120, hc, 20)
	_add_col(hrow, "Role", 175, hc, 20)
	_add_col(hrow, "Skill", 120, hc, 20)
	_add_col(hrow, "Team", 180, hc, 20)
	_add_col(hrow, "Contract", 150, hc, 20)
	_add_col(hrow, "Salary", 130, hc, 20)
	list_container.add_child(hdr_panel)

func _make_available_staff_row(staff) -> PanelContainer:
	var is_contracted = staff.contract_team != ""
	var card = _make_card_panel(false)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var row1 = HBoxContainer.new()
	row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)
	_add_col(row1, staff.display_name(), 200, Color(0.85, 0.85, 0.85), 24)
	_add_col(row1, "Age %d" % staff.age, 70)
	_add_col(row1, staff.nationality, 120)
	_add_col(row1, "%s %s" % [ROLE_ICONS.get(staff.role, ""), staff.role], 175,
		Color(0.7, 0.85, 1.0))
	_add_col(row1, "%s %.0f" % [staff.get_primary_skill_label(), staff.get_primary_skill()], 120,
		_skill_color(staff.get_primary_skill()))

	## S35.10 — TEAM column (team name or "—") then CONTRACT column (duration / status), aligned.
	_add_col(row1, _team_name_for(staff.contract_team), 180, Color(0.8, 0.8, 0.85))

	var ap_status = _get_approach_status(staff.id)
	var status_text: String
	var status_col: Color
	if ap_status == "approaching" or ap_status == "bond_offered":
		status_text = "⏳ Approached"; status_col = Color(0.7, 0.7, 0.4)
	elif ap_status == "bond_countered":
		status_text = "💰 Bond Counter"; status_col = Color(1.0, 0.75, 0.2)
	elif ap_status == "negotiating":
		status_text = "📋 Negotiating"; status_col = Color(0.4, 0.85, 0.55)
	elif ap_status == "pre_signed":
		status_text = "✅ Next Season"; status_col = Color(0.4, 0.85, 0.55)
	elif is_contracted:
		var seasons = staff.contract_seasons_remaining
		status_text = "%d season%s" % [seasons, "s" if seasons != 1 else ""]
		status_col = Color(1.0, 0.55, 0.2) if seasons <= 1 else Color(0.6, 0.85, 0.6)
	else:
		status_text = "Free agent"; status_col = Color(0.4, 0.9, 0.4)
	_add_col(row1, status_text, 150, status_col)

	_add_col(row1, "CR %s/yr" % _fmt_sal(int(staff.weekly_salary * 52)), 130, Color(0.6, 0.6, 0.6))

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	var s_id = staff.id

	var view_btn = Button.new()
	view_btn.text = "📋 View Card"
	view_btn.custom_minimum_size = Vector2(100, 28)
	view_btn.pressed.connect(func(): _show_staff_card(s_id))
	btn_row.add_child(view_btn)

	_add_approach_button(btn_row, s_id, "staff", staff)

	## S35.10 — ★ shortlist star on the RIGHT of the action row.
	var star_sp = Control.new(); star_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(star_sp)
	_add_shortlist_star(btn_row, s_id, "staff")

	## Row 2 — role-specific stat chips
	var stats = _get_role_stats(staff)
	if not stats.is_empty():
		var row2 = HBoxContainer.new()
		row2.add_theme_constant_override("separation", 12)
		vbox.add_child(row2)
		for stat in stats:
			_add_stat_chip(row2, stat[0], stat[1])

	return card

# ── Staff Card popup ──────────────────────────────────────────────────────────

func _show_staff_card(staff_id: String) -> void:
	if card_overlay:
		card_overlay.queue_free()

	var staff = GameState.all_staff.get(staff_id)
	if not staff:
		return

	card_overlay = PanelContainer.new()
	## Centered on screen (anchors at 0.5) with a fixed ~640px width and symmetric offsets, so the
	## card sits in the middle rather than hugging the right edge. Vertically centered too. (Popup
	## position pass — keeps long values fully on-screen.)
	card_overlay.anchor_left   = 0.5
	card_overlay.anchor_top    = 0.5
	card_overlay.anchor_right  = 0.5
	card_overlay.anchor_bottom = 0.5
	card_overlay.offset_left   = -320
	card_overlay.offset_top    = -380
	card_overlay.offset_right  = 320
	card_overlay.offset_bottom = 380
	card_overlay.custom_minimum_size = Vector2(640, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 0.98)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.7, 0.85, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	card_overlay.add_theme_stylebox_override("panel", style)
	add_child(card_overlay)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card_overlay.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	var name_lbl = Label.new()
	name_lbl.text = "%s %s" % [ROLE_ICONS.get(staff.role, ""), _staff_display_name(staff)]
	name_lbl.add_theme_font_size_override("font_size", 48)
	name_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_lbl)
	## S35.10 — ★ shortlist toggle in the card header (synced with the row star via is_shortlisted).
	var card_star = Button.new()
	var star_on: bool = GameState.is_shortlisted(staff_id, "staff")
	card_star.text = "★" if star_on else "☆"
	card_star.custom_minimum_size = Vector2(44, 36)
	card_star.add_theme_font_size_override("font_size", 26)
	card_star.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2) if star_on else Color(0.6, 0.6, 0.6))
	card_star.tooltip_text = "Remove from shortlist" if star_on else "Add to shortlist"
	card_star.pressed.connect(func():
		GameState.toggle_shortlist(staff_id, "staff")
		_show_staff_card(staff_id)  ## rebuild card to reflect new star state
		_refresh_list())            ## and update the row behind it
	header.add_child(card_star)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(func(): card_overlay.queue_free(); card_overlay = null)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	_card_row(vbox, "Role", staff.role, Color(0.7, 0.85, 1.0))
	_card_row(vbox, "Age / Sex / Nationality",
		"%d  |  %s  |  %s" % [staff.age, staff.sex, staff.nationality])
	_card_row(vbox, "Reputation", "%.0f / 100" % staff.reputation,
		_skill_color(staff.reputation))
	_card_row(vbox, "Salary", "CR %s/yr  (CR %.0f/wk)" % [_fmt_sal(int(staff.weekly_salary * 52)), staff.weekly_salary])
	_card_row(vbox, "Contract",
		"%d season%s remaining" % [staff.contract_seasons_remaining, "s" if staff.contract_seasons_remaining != 1 else ""],
		Color(1.0, 0.4, 0.4) if staff.contract_seasons_remaining <= 1 else Color.WHITE)

	var assign_text = "Unassigned"
	if staff.role == "CFO" or staff.role == "Designer":
		assign_text = "Team Level (no assignment needed)"
	elif staff.assigned_car_id != "":
		var car = GameState.get_car_by_id(staff.assigned_car_id)
		assign_text = _car_display_name(car) if car else "Car ?"
	elif staff.assigned_championship != "":
		var _reg = GameState.CHAMPIONSHIP_REGISTRY.get(staff.assigned_championship, {})
		assign_text = _reg.get("name", staff.assigned_championship)
	_card_row(vbox, "Assignment", assign_text)

	vbox.add_child(HSeparator.new())

	# Role-specific attributes
	var attrs_title = Label.new()
	attrs_title.text = "ATTRIBUTES"
	attrs_title.add_theme_font_size_override("font_size", 30)
	attrs_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(attrs_title)

	var attrs = _get_staff_attrs(staff)
	for attr in attrs:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		var lbl = Label.new()
		lbl.text = attr[0]
		lbl.custom_minimum_size = Vector2(200, 0)
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		row.add_child(lbl)
		var bar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = attr[1]
		bar.custom_minimum_size = Vector2(160, 18)
		bar.show_percentage = false
		row.add_child(bar)
		var val_lbl = Label.new()
		val_lbl.text = "%.1f" % attr[1]
		val_lbl.add_theme_font_size_override("font_size", 30)
		val_lbl.add_theme_color_override("font_color", _skill_color(attr[1]))
		row.add_child(val_lbl)

	vbox.add_child(HSeparator.new())

	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var is_mine = staff.contract_team == GameState.player_team.id
	if is_mine:
		var assign_btn = Button.new()
		assign_btn.text = "📌 Assign"
		assign_btn.custom_minimum_size = Vector2(100, 32)
		assign_btn.pressed.connect(func():
			card_overlay.queue_free()
			card_overlay = null
			_show_assign_popup(staff_id)
		)
		btn_row.add_child(assign_btn)

		var renew_btn = Button.new()
		renew_btn.text = "📋 Renegotiate"
		renew_btn.custom_minimum_size = Vector2(140, 32)
		renew_btn.pressed.connect(func():
			var ap = GameState.make_renegotiation_approach(staff_id, "staff")
			if ap.is_empty(): return
			card_overlay.queue_free(); card_overlay = null
			var panel = preload("res://scenes/ContractNegotiation.tscn").instantiate()
			get_tree().current_scene.add_child(panel)
			panel.open_approach(ap)
			panel.closed.connect(func(): _refresh_list()))
		btn_row.add_child(renew_btn)
	elif staff.contract_team == "":
		var hire_btn = Button.new()
		hire_btn.custom_minimum_size = Vector2(160, 32)
		var slot_msg = _get_slot_message(staff.role)
		var slot = GameState.get_slot_projection("staff", staff.role)
		var is_unavailable = not GameState.is_subject_available(staff_id)
		if is_unavailable:
			hire_btn.text = "🚫 Not Interested"
			hire_btn.disabled = true
			hire_btn.tooltip_text = "Not available for 2 seasons after walking away."
		elif staff.role not in ["CFO", "Designer"] and not _has_assigned_tp():
			hire_btn.text = "⚠ No Team Principal"
			hire_btn.disabled = true
			hire_btn.tooltip_text = "Assign a Team Principal first."
		elif slot["now_free"] > 0:
			hire_btn.text = "📋 Negotiate Contract"
			hire_btn.pressed.connect(func():
				card_overlay.queue_free(); card_overlay = null
				_show_timing_popup(staff_id, "staff"))
		elif slot["next_free"] > 0 or staff.contract_team == "":
			## Free agents always signable for next season
			hire_btn.text = "📋 Sign for Next Season"
			hire_btn.modulate = Color(0.7, 0.85, 1.0)
			hire_btn.pressed.connect(func():
				card_overlay.queue_free(); card_overlay = null
				_initiate_approach(staff_id, "staff", "next_season"))
		else:
			hire_btn.text = "⚠ No Slot"
			hire_btn.disabled = true
			hire_btn.tooltip_text = slot_msg
		btn_row.add_child(hire_btn)
	else:
		## Contracted staff — approach button
		var ap_btn = Button.new()
		ap_btn.custom_minimum_size = Vector2(160, 32)
		var ap_status = _get_approach_status(staff_id)
		match ap_status:
			"approaching", "bond_offered":
				ap_btn.text = "⏳ Awaiting Reply"
				ap_btn.disabled = true
			"bond_countered":
				ap_btn.text = "💰 Bond Counter"
				ap_btn.pressed.connect(func():
					card_overlay.queue_free(); card_overlay = null
					_show_bond_response_popup(staff_id, "staff"))
			"negotiating":
				ap_btn.text = "📋 Round %d" % _get_approach_round(staff_id)
				ap_btn.pressed.connect(func():
					card_overlay.queue_free(); card_overlay = null
					_show_contract_negotiation_popup(staff_id, "staff"))
			"pre_signed":
				ap_btn.text = "✅ Pre-signed"
				ap_btn.disabled = true
			_:
				var _needs_tp2 = staff.role not in ["CFO", "Designer"]
				if _needs_tp2 and not _has_assigned_tp():
					ap_btn.text = "⚠ No Team Principal"
					ap_btn.disabled = true
				else:
					ap_btn.text = "📤 Approach"
					ap_btn.pressed.connect(func():
						card_overlay.queue_free(); card_overlay = null
						_show_timing_popup(staff_id, "staff"))
		btn_row.add_child(ap_btn)

# ── Assign popup ──────────────────────────────────────────────────────────────

func _show_assign_popup(staff_id: String) -> void:
	if card_overlay:
		card_overlay.queue_free()

	var staff = GameState.all_staff.get(staff_id)
	if not staff:
		return

	card_overlay = PanelContainer.new()
	## Centered on screen (popup-position pass) — was hugging the right edge and clipping.
	card_overlay.anchor_left   = 0.5
	card_overlay.anchor_top    = 0.5
	card_overlay.anchor_right  = 0.5
	card_overlay.anchor_bottom = 0.5
	card_overlay.offset_left   = -320
	card_overlay.offset_top    = -380
	card_overlay.offset_right  = 320
	card_overlay.offset_bottom = 380
	card_overlay.custom_minimum_size = Vector2(640, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 0.98)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.9, 0.4)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	card_overlay.add_theme_stylebox_override("panel", style)
	add_child(card_overlay)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card_overlay.add_child(vbox)

	var header = HBoxContainer.new()
	vbox.add_child(header)
	var title = Label.new()
	title.text = "Assign %s:" % staff.display_name()
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.pressed.connect(func(): card_overlay.queue_free(); card_overlay = null)
	header.add_child(close_btn)

	var s_id = staff_id

	# Car-assigned roles: Mechanic, Pit Crew
	if staff.role in ["Race Mechanic", "Pit Crew"]:
		var lbl = Label.new()
		lbl.text = "Assign to car:"
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(lbl)
		for car in GameState.player_team_cars:
			var btn = Button.new()
			var current = ""
			if staff.role == "Race Mechanic" and car.mechanic_id != "":
				var m = GameState.all_staff.get(car.mechanic_id)
				current = "  (has: %s)" % m.full_name() if m else ""
			elif staff.role == "Pit Crew" and car.pit_crew_id != "" and car.pit_crew_id != "N/A":
				var p = GameState.all_staff.get(car.pit_crew_id)
				current = "  (has: %s)" % p.full_name() if p else ""
			btn.text = "%s%s" % [_car_display_name(car), current]
			btn.custom_minimum_size = Vector2(340, 36)
			var _car_id = car.id
			btn.pressed.connect(func():
				GameState.assign_staff_to_car(s_id, _car_id)
				card_overlay.queue_free()
				card_overlay = null
				_refresh_list()
			)
			vbox.add_child(btn)

	# Championship-assigned roles: TP, Strategist — show picker for all active championships
	elif staff.role in ["Team Principal", "Race Strategist"]:
		var lbl = Label.new()
		lbl.text = "Assign to championship:"
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(lbl)

		## Strategist not needed for GK or Rally disciplines
		const NO_STRATEGIST = ["GK", "Rally"]
		## Only the player's REGISTERED championships (bug — popup was listing all 21 world
		## championships; you can only assign staff to series you actually race).
		var eligible_champs = []
		for champ in GameState.get_player_championships():
			var reg = GameState.CHAMPIONSHIP_REGISTRY.get(champ.id, {})
			var disc = reg.get("discipline", "")
			if staff.role == "Race Strategist" and disc in NO_STRATEGIST:
				continue
			eligible_champs.append(champ)

		if eligible_champs.is_empty():
			var lbl_none = Label.new()
			lbl_none.text = "No eligible championships.\n(Strategist not needed for GK or Rally.)" \
				if staff.role == "Race Strategist" else "No active championships."
			lbl_none.modulate = Color(0.5, 0.5, 0.5)
			lbl_none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(lbl_none)
		else:
			for champ in eligible_champs:
				var reg = GameState.CHAMPIONSHIP_REGISTRY.get(champ.id, {})
				var champ_name = reg.get("name", champ.id)

				## For TP: disable if another TP is already assigned here
				var already_has_tp = false
				if staff.role == "Team Principal":
					for sid2 in GameState.all_staff:
						var s2 = GameState.all_staff[sid2]
						if s2.id == staff_id: continue
						if s2.role == "Team Principal" \
								and s2.contract_team == GameState.player_team.id \
								and s2.assigned_championship == champ.id:
							already_has_tp = true
							break

				var is_assigned_here = staff.assigned_championship == champ.id

				var btn = Button.new()
				btn.custom_minimum_size = Vector2(340, 36)
				if is_assigned_here:
					btn.text = "✅ %s (current)" % champ_name
					btn.disabled = true
					btn.modulate = Color(0.6, 1.0, 0.6)
				elif already_has_tp:
					btn.text = "🔒 %s (TP slot taken)" % champ_name
					btn.disabled = true
					btn.modulate = Color(0.5, 0.5, 0.5)
				else:
					btn.text = "→ %s" % champ_name
					var cid = champ.id
					btn.pressed.connect(func():
						GameState.assign_staff_to_championship(staff_id, cid)
						card_overlay.queue_free()
						card_overlay = null
						_refresh_list())
				vbox.add_child(btn)

		## Unassign option
		if staff.assigned_championship != "":
			var btn_unassign = Button.new()
			btn_unassign.text = "✕ Unassign"
			btn_unassign.modulate = Color(0.9, 0.4, 0.4)
			btn_unassign.pressed.connect(func():
				staff.assigned_championship = ""
				card_overlay.queue_free()
				card_overlay = null
				_refresh_list())
			vbox.add_child(btn_unassign)

	# Team-level roles: CFO, Designer — no specific assignment needed
	else:
		var lbl = Label.new()
		lbl.text = "%s works at team level — no specific assignment needed.\nThey are active as long as they are on your staff." % staff.role
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)
		var ok_btn = Button.new()
		ok_btn.text = "OK"
		ok_btn.custom_minimum_size = Vector2(100, 32)
		ok_btn.pressed.connect(func(): card_overlay.queue_free(); card_overlay = null)
		vbox.add_child(ok_btn)

## ── Approach button logic ─────────────────────────────────────────────────────

func _add_approach_button(btn_row: HBoxContainer, subject_id: String,
		subject_type: String, subject) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(180, 28)
	btn.add_theme_font_size_override("font_size", 22)

	var ap_status = _get_approach_status(subject_id)

	if not GameState.is_subject_available(subject_id):
		return  ## Hide walked-away subjects entirely

	match ap_status:
		"approaching", "bond_offered":
			btn.text = "⏳ Awaiting Reply"
			btn.disabled = true
			btn.modulate = Color(0.7, 0.7, 0.4)
		"bond_countered":
			btn.text = "💰 Bond Counter — Decide"
			btn.modulate = Color(1.0, 0.75, 0.2)
			btn.pressed.connect(func(): _show_bond_response_popup(subject_id, subject_type))
		"negotiating":
			btn.text = "📋 Round %d" % _get_approach_round(subject_id)
			btn.modulate = Color(0.4, 0.85, 0.55)
			btn.pressed.connect(func(): _show_contract_negotiation_popup(subject_id, subject_type))
		"pre_signed":
			btn.text = "✅ Pre-signed (Next Season)"
			btn.disabled = true
			btn.modulate = Color(0.4, 0.85, 0.55)
		_:
			var is_free_agent = subject.contract_team == ""
			var on_last_contract = subject.contract_seasons_remaining <= 1 and not is_free_agent
			## CFO and Designer are team-level roles — no TP needed
			var needs_tp = subject.role not in ["CFO", "Designer"]
			var has_tp = (not needs_tp) or _has_assigned_tp()
			var slot = GameState.get_slot_projection("staff", subject.role)
			var slot_msg = _get_slot_message(subject.role)

			if not has_tp and not is_free_agent:
				## TP required for bond approach on contracted staff, not for free agents
				btn.text = "⚠ No Team Principal"
				btn.disabled = true
				btn.tooltip_text = "Assign a Team Principal first."
			elif slot_msg != "" and slot["now_free"] <= 0 and slot["next_free"] <= 0 \
					and not is_free_agent:
				btn.text = "⚠ No Slot"
				btn.disabled = true
				btn.tooltip_text = slot_msg
			elif is_free_agent or on_last_contract:
				if slot["now_free"] > 0:
					btn.text = "📋 Negotiate Contract"
					## Show timing popup — free agents can sign now OR next season
					btn.pressed.connect(func(): _show_timing_popup(subject_id, subject_type))
				elif slot["next_free"] > 0 or is_free_agent:
					btn.text = "📋 Sign for Next Season"
					btn.modulate = Color(0.7, 0.85, 1.0)
					btn.pressed.connect(func(): _initiate_approach(subject_id, subject_type, "next_season"))
				else:
					btn.text = "⚠ No Slot"
					btn.disabled = true
			else:
				## Mid-contract — approach with bond
				if slot["now_free"] > 0 or slot["next_free"] > 0:
					btn.text = "📤 Approach"
					btn.pressed.connect(func(): _show_timing_popup(subject_id, subject_type))
				else:
					btn.text = "⚠ No Slot"
					btn.disabled = true

	btn_row.add_child(btn)

func _get_approach_status(subject_id: String) -> String:
	for ap in GameState.active_approaches:
		if ap["subject_id"] == subject_id and \
				ap["status"] not in ["failed","rejected","expired","activated"]:
			match ap["status"]:
				"approaching":
					return "approaching" if ap.get("bond_status","") != "countered" else "bond_countered"
				"negotiating": return "negotiating"
				"agreed":
					if ap.get("type") == "pre_signed": return "pre_signed"
	return ""

func _get_approach_round(subject_id: String) -> int:
	for ap in GameState.active_approaches:
		if ap["subject_id"] == subject_id and ap["status"] == "negotiating":
			return ap.get("contract_round", 1)
	return 1

func _get_approach_neg_id(subject_id: String) -> String:
	for ap in GameState.active_approaches:
		if ap["subject_id"] == subject_id: return ap["neg_id"]
	return ""

func _has_assigned_tp() -> bool:
	for champ in GameState.active_championships:
		if GameState._get_tp_for_championship(champ.id) != null: return true
	return false

func _initiate_approach(subject_id: String, subject_type: String, start_date: String) -> void:
	var err = GameState.initiate_approach(subject_id, subject_type, start_date)
	if err == "not_interested":
		_show_not_interested_popup(subject_id)  ## S29.0 — visible popup, not just notification
	elif err == "team_refused" or err == "team_refused_cooldown":
		_show_team_refused_popup(subject_id)  ## S35.9 — team won't release
	elif err != "":
		GameState.show_popup(err, "Action Failed")
	else:
		## Free agent → negotiating immediately — open popup now
		var ap = GameState._get_approach_by_subject(subject_id)
		if not ap.is_empty() and ap["status"] == "negotiating":
			_show_contract_negotiation_popup(subject_id, subject_type)
			return
	_refresh_list()

## S35.9 — Visible modal when the staff member's TEAM refuses to release them (distinct from the
## person not being interested). Triggers a 26-week cooldown before re-approach.
func _show_team_refused_popup(subject_id: String) -> void:
	var subject = GameState.all_staff.get(subject_id)
	var name_str = subject.full_name() if subject else subject_id
	var dialog = AcceptDialog.new()
	dialog.title = Locale.t("ap_team_refused_title")
	dialog.dialog_text = "%s\n\n%s" % [
		Locale.tf("ap_team_refused_body", [name_str]), Locale.t("ap_team_refused_hint")]
	dialog.ok_button_text = Locale.t("btn_close")
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

## S29.0 — Visible modal shown when staff declines an approach (was a silent notification).
func _show_not_interested_popup(subject_id: String) -> void:
	var subject = GameState.all_staff.get(subject_id)
	var name_str = subject.full_name() if subject else subject_id
	var dialog = AcceptDialog.new()
	dialog.title = Locale.t("ap_ni_popup_title")
	dialog.dialog_text = "%s\n\n%s" % [
		Locale.tf("ap_ni_popup_body", [name_str]), Locale.t("ap_ni_popup_hint")]
	dialog.ok_button_text = Locale.t("btn_close")
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

func _show_timing_popup(subject_id: String, subject_type: String) -> void:
	var subject_obj = GameState.all_staff.get(subject_id)
	if subject_obj == null: return

	if card_overlay: card_overlay.queue_free()
	card_overlay = PanelContainer.new()
	card_overlay.set_anchors_preset(Control.PRESET_CENTER)
	card_overlay.custom_minimum_size = Vector2(360, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.18, 0.98)
	for side in ["left","right","top","bottom"]: style.set("border_width_%s" % side, 2)
	style.border_color = Color(0.35, 0.65, 1.0)
	for corner in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_%s" % corner, 6)
	for side in ["left","right","top","bottom"]: style.set("content_margin_%s" % side, 16)
	card_overlay.add_theme_stylebox_override("panel", style)
	add_child(card_overlay)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	card_overlay.add_child(vb)

	var lbl = Label.new()
	lbl.text = "Approach %s" % subject_obj.display_name()
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vb.add_child(lbl)

	var bond_info = GameState.get_bond_estimate(subject_id, subject_type, "immediate")
	var lbl_est = Label.new()
	lbl_est.text = "Bond estimate: CR %s – %s" % [
		_fmt_sal(bond_info["low"]), _fmt_sal(bond_info["high"])]
	lbl_est.add_theme_font_size_override("font_size", 24)
	lbl_est.modulate = Color(0.7, 0.7, 0.4)
	if not bond_info["has_cfo"]: lbl_est.text += "\n⚠ No CFO — estimate ±30%"
	vb.add_child(lbl_est)

	vb.add_child(HSeparator.new())

	var slot = GameState.get_slot_projection("staff", subject_obj.role)
	for timing in [["immediate", "🚀 Immediate Transfer", "1.5× + 25% disruption fee"],
			["next_season", "📅 Next Season", "Standard bond"]]:
		var btn = Button.new()
		btn.text = timing[1]
		btn.tooltip_text = timing[2]
		btn.custom_minimum_size = Vector2(0, 36)
		var t = timing[0]
		if t == "immediate" and slot["now_free"] <= 0:
			btn.disabled = true
			btn.tooltip_text = "No slots available for immediate signing — choose Next Season."
			btn.modulate = Color(0.5, 0.5, 0.5)
		btn.pressed.connect(func():
			card_overlay.queue_free(); card_overlay = null
			_initiate_approach(subject_id, subject_type, t))
		vb.add_child(btn)

	var btn_cancel = Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.modulate = Color(0.7, 0.4, 0.4)
	btn_cancel.pressed.connect(func(): card_overlay.queue_free(); card_overlay = null)
	vb.add_child(btn_cancel)

func _show_bond_response_popup(subject_id: String, subject_type: String) -> void:
	var neg_id = _get_approach_neg_id(subject_id)
	var ap = GameState._get_approach(neg_id)
	if ap.is_empty(): return

	if card_overlay: card_overlay.queue_free()
	card_overlay = PanelContainer.new()
	card_overlay.set_anchors_preset(Control.PRESET_CENTER)
	card_overlay.custom_minimum_size = Vector2(400, 0)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.18, 0.98)
	for side in ["left","right","top","bottom"]: style.set("border_width_%s" % side, 2)
	style.border_color = Color(1.0, 0.75, 0.2)
	for corner in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_%s" % corner, 6)
	for side in ["left","right","top","bottom"]: style.set("content_margin_%s" % side, 16)
	card_overlay.add_theme_stylebox_override("panel", style)
	add_child(card_overlay)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card_overlay.add_child(vb)

	var lbl_title = Label.new()
	lbl_title.text = "💰 Bond Counter — %s" % ap["subject_name"]
	lbl_title.add_theme_font_size_override("font_size", 32)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	vb.add_child(lbl_title)

	var lbl_ask = Label.new()
	lbl_ask.text = "%s's team asks: CR %s" % [
		ap["current_team_name"], _fmt_sal(int(ap["bond_team_ask"]))]
	lbl_ask.add_theme_font_size_override("font_size", 26)
	vb.add_child(lbl_ask)

	var spin = SpinBox.new()
	spin.min_value = 0
	spin.max_value = ap["bond_team_ask"] * 3.0
	spin.step = 1000
	spin.value = ap["bond_team_ask"]
	spin.custom_minimum_size = Vector2(160, 36)
	vb.add_child(spin)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vb.add_child(btn_row)

	var btn_accept = Button.new()
	btn_accept.text = "✅ Accept CR %s" % _fmt_sal(int(ap["bond_team_ask"]))
	btn_accept.pressed.connect(func():
		GameState.respond_bond_counter(neg_id, true)
		card_overlay.queue_free(); card_overlay = null
		_refresh_list())
	btn_row.add_child(btn_accept)

	var btn_counter = Button.new()
	btn_counter.text = "↩ Counter"
	btn_counter.pressed.connect(func():
		GameState.respond_bond_counter(neg_id, false, spin.value)
		card_overlay.queue_free(); card_overlay = null
		_refresh_list())
	btn_row.add_child(btn_counter)

	var btn_reject = Button.new()
	btn_reject.text = "✕ Walk Away"
	btn_reject.modulate = Color(1.0, 0.4, 0.4)
	btn_reject.pressed.connect(func():
		GameState.walk_away_approach(neg_id)
		card_overlay.queue_free(); card_overlay = null
		_refresh_list())
	btn_row.add_child(btn_reject)

func _show_contract_negotiation_popup(subject_id: String, _subject_type: String) -> void:
	var neg_id = _get_approach_neg_id(subject_id)
	var ap = GameState._get_approach(neg_id)
	if ap.is_empty(): return
	if card_overlay: card_overlay.queue_free(); card_overlay = null
	var panel = preload("res://scenes/ContractNegotiation.tscn").instantiate()
	get_tree().current_scene.add_child(panel)
	panel.open_approach(ap)
	panel.closed.connect(func():
		tab_my_btn.text = "👥 My Staff"
		_refresh_list())

# ── Release confirmation ───────────────────────────────────────────────────────

func _confirm_release_staff(staff_id: String) -> void:
	## No confirmation dialog per design spec
	GameState.release_staff(staff_id)
	tab_my_btn.text = "👥 My Staff"
	_refresh_list()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _filter_and_sort(staff_list: Array) -> Array:
	var filtered = staff_list.filter(func(s):
		return role_filter == "All" or s.role == role_filter
	)
	filtered.sort_custom(func(a, b):
		var va = _sort_val(a)
		var vb = _sort_val(b)
		return va > vb if not sort_ascending else va < vb
	)
	return filtered

func _sort_val(staff) -> float:
	match sort_field:
		"age":         return float(staff.age)
		"salary":      return staff.weekly_salary
		"reputation":  return staff.reputation if "reputation" in staff else 50.0
		## Team Principal / Strategist
		"strategy":    return staff.race_strategy if "race_strategy" in staff else 0.0
		"practice":    return staff.practice_management if "practice_management" in staff else 0.0
		"qualifying":  return staff.qualifying_management if "qualifying_management" in staff else 0.0
		"race_pace":   return staff.race_pace_reading if "race_pace_reading" in staff else 0.0
		"pit_mgmt":    return staff.pit_stop_management if "pit_stop_management" in staff else 0.0
		"pr":          return staff.pr_skill if "pr_skill" in staff else 0.0
		"quali_timing":return staff.qualifying_timing if "qualifying_timing" in staff else 0.0
		## Race Mechanic
		"setup":       return staff.car_setup if "car_setup" in staff else 0.0
		"pit_stops":   return staff.pit_stops if "pit_stops" in staff else 0.0
		"car_know":    return staff.parts_knowledge if "parts_knowledge" in staff else 0.0
		"track_know":  return staff.track_knowledge if "track_knowledge" in staff else 0.0
		## Pit Crew
		"pit_stop":    return staff.pit_stop_speed if "pit_stop_speed" in staff else 0.0
		"repair":      return staff.repair_skill if "repair_skill" in staff else 0.0
		"fatigue_resistance": return staff.fatigue_resistance
		"fitness":     return staff.fitness if "fitness" in staff else 0.0
		## CFO
		"finmgmt":     return staff.loan_management if "loan_management" in staff else 0.0
		"negotiation": return staff.sponsor_negotiation if "sponsor_negotiation" in staff else 0.0
		"sales":       return staff.sales_skill if "sales_skill" in staff else 0.0
		"resource":    return staff.resource_management if "resource_management" in staff else 0.0
		## Designer
		"aero":        return staff.aero if "aero" in staff else 0.0
		"engine":      return staff.engine if "engine" in staff else 0.0
		"chassis":     return staff.chassis if "chassis" in staff else 0.0
		"gearbox":     return staff.gearbox if "gearbox" in staff else 0.0
		"suspension":  return staff.suspension if "suspension" in staff else 0.0
		"brakes":      return staff.brakes if "brakes" in staff else 0.0
		"parts_know":  return staff.parts_knowledge if "parts_knowledge" in staff else 0.0
		"reliability": return staff.reliability if "reliability" in staff else 0.0
		_:             return staff.get_primary_skill()

func _get_staff_attrs(staff) -> Array:
	match staff.role:
		"Race Mechanic":
			return [["Car Setup", staff.car_setup], ["Pit Stops", staff.pit_stops],
				["Parts Knowledge", staff.parts_knowledge], ["Track Knowledge", staff.track_knowledge]]
		"Pit Crew":
			return [["Pit Stop Speed", staff.pit_stop_speed], ["Repair Skill", staff.repair_skill],
				["Fatigue Res", staff.fatigue_resistance], ["Fitness", staff.fitness]]
		"Team Principal":
			return [["Race Strategy", staff.race_strategy],
				["Practice Management", staff.practice_management],
				["Qualifying Management", staff.qualifying_management],
				["Race Pace Reading", staff.race_pace_reading],
				["Car Setup Oversight", staff.car_setup_oversight],
				["Pit Stop Management", staff.pit_stop_management],
				["PR Skill", staff.pr_skill],
				["Talent Scouting", staff.talent_scouting]]
		"CFO":
			return [["Loan Management", staff.loan_management],
				["Speculation", staff.speculation],
				["Sales Skill", staff.sales_skill],
				["Sponsor Negotiation", staff.sponsor_negotiation],
				["Resource Management", staff.resource_management],
				["Budget Planning", staff.budget_planning]]
		"Designer":
			return [["Engine", staff.engine], ["Aero", staff.aero],
				["Chassis", staff.chassis], ["Gearbox", staff.gearbox],
				["Suspension", staff.suspension], ["Brakes", staff.brakes],
				["Reliability", staff.reliability], ["Parts Knowledge", staff.parts_knowledge]]
		"Race Strategist":
			return [["Race Strategy", staff.race_strategy],
				["Race Pace Reading", staff.race_pace_reading],
				["Practice Scheduling", staff.practice_scheduling],
				["Qualifying Timing", staff.qualifying_timing],
				["Track Knowledge", staff.track_knowledge]]
	return []

func _make_card_panel(highlight: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.20, 1.0) if highlight else Color(0.11, 0.11, 0.13, 1.0)
	style.border_width_left = 3
	style.border_color = Color(0.7, 0.85, 1.0) if highlight else Color(0.25, 0.25, 0.3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	return card

## S35.10b — proportional column. `weight` is a STRETCH RATIO (not a fixed pixel width): columns
## share the full row width in proportion to their weights, so the table uses the WHOLE screen and
## never clips at any resolution. A small min-width floor keeps very narrow columns readable. The
## header row uses the SAME weights, so columns stay aligned.
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

## S35.10 — display name of the team a person belongs to, or "—" for a free agent.
func _team_name_for(contract_team_id: String) -> String:
	if contract_team_id == "":
		return "—"
	if contract_team_id == GameState.player_team.id:
		return GameState.player_team.team_name
	for t in GameState.all_teams:
		if t.id == contract_team_id:
			return t.team_name
	return contract_team_id

## S35.10 — a ★ shortlist toggle (icon only + tooltip). Reflects is_shortlisted; clicking toggles
## and refreshes the list so the star state updates everywhere.
func _add_shortlist_star(parent: HBoxContainer, subject_id: String, subject_type: String) -> void:
	var star = Button.new()
	var on: bool = GameState.is_shortlisted(subject_id, subject_type)
	star.text = "★" if on else "☆"
	star.custom_minimum_size = Vector2(40, 28)
	star.add_theme_font_size_override("font_size", 22)
	star.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2) if on else Color(0.6, 0.6, 0.6))
	star.tooltip_text = "Remove from shortlist" if on else "Add to shortlist"
	star.pressed.connect(func():
		GameState.toggle_shortlist(subject_id, subject_type)
		_refresh_list())
	parent.add_child(star)

func _card_row(parent: VBoxContainer, label: String, value: String,
		value_color: Color = Color.WHITE) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(200, 0)
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	row.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 30)
	val.add_theme_color_override("font_color", value_color)
	## Expand into the remaining width and clip rather than overflow the panel edge (#1 fix).
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.clip_text = true
	val.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(val)

func _skill_color(value: float) -> Color:
	if value >= 75.0:   return Color(0.3, 1.0, 0.3)
	elif value >= 50.0: return Color(1.0, 0.84, 0.0)
	elif value >= 30.0: return Color(1.0, 0.6, 0.2)
	else:               return Color(0.7, 0.4, 0.4)

## Returns an error message if there is no open slot for this role, "" if hiring is allowed.
func _get_slot_message(role: String) -> String:
	match role:
		"Team Principal":
			var current = GameState.get_player_staff_by_role("Team Principal").size()
			var max_tp = GameState.get_hq_tp_slots()
			if current >= max_tp:
				return "TP slots full (%d/%d). Upgrade HQ to unlock more slots." % [current, max_tp]
		"CFO":
			if GameState.get_player_staff_by_role("CFO").size() >= 1:
				return "You already have a CFO. Release them first."
		"Race Strategist":
			# Slots = Ops Sim & Telemetry level (canonical rule). Assignment is 1 per
			# non-GK/Rally championship — a separate downstream check, not the hiring cap.
			if GameState.active_championship.discipline == "GK":
				return "Race Strategist not required for GK championships."
			var ops = GameState.get_building("Ops Sim & Telemetry")
			if ops.is_empty() or not ops.get("built", false) or ops.get("level", 0) < 1:
				return "Build the Ops Sim & Telemetry to hire Race Strategists."
			var max_strat = max(1, ops.get("level", 1))
			if GameState.get_player_staff_by_role("Race Strategist").size() >= max_strat:
				return "Strategist slots full (Ops Sim Lv%d = %d slot%s). Upgrade for more." % [
					max_strat, max_strat, "s" if max_strat != 1 else ""]
		"Race Mechanic":
			# Slot limit = max cars allowed = garage level (min 1 if built)
			# Allow hiring even during upgrade — building still operational
			var garage = GameState.get_building("Garage")
			var max_mechanics = max(1, garage.get("level", 1))
			if GameState.get_player_staff_by_role("Race Mechanic").size() >= max_mechanics:
				return "Mechanic slots full (Garage Lv%d = %d slot%s). Upgrade Garage for more." % [
					max_mechanics, max_mechanics, "s" if max_mechanics != 1 else ""]
		"Pit Crew":
			if GameState.active_championship.discipline == "GK":
				return "Pit Crew not required for GK championships."
			else:
				var arena = GameState.get_building("Pit Crew Arena")
				if not arena.get("built", false) or arena.get("level", 0) < 1:
					return "Build the Pit Crew Arena first to hire Pit Crew."
				var max_crews = max(1, arena.get("level", 1))
				if GameState.get_player_staff_by_role("Pit Crew").size() >= max_crews:
					return "Pit Crew slots full (Arena Lv%d = %d slot%s). Upgrade Arena for more." % [
						max_crews, max_crews, "s" if max_crews != 1 else ""]
		"Designer":
			# Slot limited by R&D Studio level. If not built, 0 slots.
			var rnd = GameState.get_building("R&D Design Studio")
			if rnd.is_empty() or not rnd.get("built", false) or rnd.get("level", 0) < 1:
				return "Build and level up the R&D Design Studio to hire Designers."
			var max_designers = rnd.get("level", 0)
			if GameState.get_player_staff_by_role("Designer").size() >= max_designers:
				return "Designer slots full (Level %d = %d slot%s). Upgrade R&D Studio for more." % [
					max_designers, max_designers, "s" if max_designers != 1 else ""]
	return ""

func _staff_display_name(staff) -> String:
	if staff.role == "Pit Crew":
		var num = staff.crew_number if "crew_number" in staff else 1
		return "Pit Crew %d" % num
	return staff.display_name()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if card_overlay:
			card_overlay.queue_free()
			card_overlay = null
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		var screenshot = get_viewport().get_texture().get_image()
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
		screenshot.save_png("user://screenshot_%s.png" % timestamp)

func _car_display_name(car) -> String:
	if car.car_name != null and car.car_name != "":
		return car.car_name
	return "Car %d" % car.car_number

func _fmt_sal(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif n >= 1000:
		return "%.0fK" % (n / 1000.0)
	return str(n)
