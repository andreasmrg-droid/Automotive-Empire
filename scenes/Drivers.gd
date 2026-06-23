## Version: S35.10c — Added ⭐ Shortlist entry button to the header (opens the unified Shortlist).
## Version: S35.10b — Alignment fix (matches StaffHub): proportional stretch-ratio columns using
##   the full screen width (no clipping); driver header is now a full-width panel matching the row
##   card border/margins; paged All-Drivers list shows the "Showing: …" summary too.
## Version: S35.10 — Hub UX pass (matches StaffHub): rows at 24px, 100s emphasized; TEAM + CONTRACT
##   as two aligned columns (header updated); ★ shortlist star on rows + in the card popup; active-
##   sort highlight + arrow + "Showing: …" summary.
## Version: S35.9 — "Interested Only" uses the shared deterministic interest predicate (binary)
##   + hides team-refusal-cooldown drivers; team-won't-release popup added on approach.
## Version: S35.7 — PERF: "Interested Only" filter invariants hoisted out of the per-driver loop
##   + team reps pre-indexed (same lag fix as StaffHub S35.7).
## Version: S29.0 — Not-interested popup (issue 1: visible AcceptDialog, not just a
## Version: S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
##   notification). Page-transition perf: _refresh_list detaches rows synchronously
##   (remove_child + queue_free) so freed rows don't render alongside new ones (issue 4).
## --- S28.3 — "Wet" stat relabeled "Car Control"/"Ctrl" in UI (data field already car_control).
## --- S28.2 — Search box + pagination (25/page) on All Drivers tab. Renders only the
##   current page of rows instead of every driver in the game (perf fix for large rosters).
##   Search filters by name/nationality; sort/tab/filter changes reset to page 1.
## --- S22.6 — Free agents show timing popup (not hardcoded immediate).
## Version: S22.8 — #4 expired contract release; #8 walk-away hides row; #14 TP gate removed.
extends Control

# ── State ─────────────────────────────────────────────────────────────────────
var current_tab: String = "my_drivers"
var sort_field: String = "overall"
var sort_ascending: bool = false
var role_filter: String = "All"
var free_agents_only: bool = false
var interested_only: bool = false  ## P33: show only drivers likely interested in joining

## S28.2 — search + pagination state (perf fix for large rosters)
var search_text: String = ""
var current_page: int = 0
const PAGE_SIZE: int = 25
var search_field_node: LineEdit = null
var page_nav_row: HBoxContainer = null

# ── Node references (built in code) ──────────────────────────────────────────
var tab_my_btn: Button
var tab_all_btn: Button
var list_container: VBoxContainer
var scroll: ScrollContainer
var sort_bar: HBoxContainer
var sort_fields_box: HBoxContainer  ## S35.10 — rebuildable field-button row (active highlight)
var filter_bar: HBoxContainer

# Card popup
var card_overlay: PanelContainer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var layout = VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 20
	layout.offset_top = 20
	layout.offset_right = -20
	layout.offset_bottom = -20
	layout.add_theme_constant_override("separation", 10)
	add_child(layout)

	# ── Header ────────────────────────────────────────────────
	var header = HBoxContainer.new()
	layout.add_child(header)

	var title = Label.new()
	title.text = "👤 DRIVERS"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	## S35.10c — entry to the unified Shortlist screen.
	var shortlist_btn = Button.new()
	shortlist_btn.text = "⭐ Shortlist"
	shortlist_btn.custom_minimum_size = Vector2(140, 40)
	shortlist_btn.tooltip_text = "View your shortlisted drivers & staff"
	shortlist_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/Shortlist.tscn"))
	header.add_child(shortlist_btn)

	var back_btn = Button.new()
	back_btn.text = "← Back to Hub"
	back_btn.custom_minimum_size = Vector2(150, 40)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	layout.add_child(HSeparator.new())

	# ── Tab row ───────────────────────────────────────────────
	var tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	layout.add_child(tab_row)

	tab_my_btn = Button.new()
	tab_my_btn.text = "🏎 My Drivers (%d)" % GameState.player_team.drivers.size()
	tab_my_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_my_btn.pressed.connect(func(): _show_tab("my_drivers"))
	tab_row.add_child(tab_my_btn)

	tab_all_btn = Button.new()
	tab_all_btn.text = "🌍 All Drivers (%d)" % GameState.all_drivers.size()
	tab_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_all_btn.pressed.connect(func(): _show_tab("all_drivers"))
	tab_row.add_child(tab_all_btn)

	var btn_fa = Button.new()
	btn_fa.name = "BtnFreeAgents"
	btn_fa.text = "Free Agents Only"
	btn_fa.toggle_mode = true
	btn_fa.button_pressed = false
	btn_fa.pressed.connect(func():
		free_agents_only = btn_fa.button_pressed
		btn_fa.text = "✅ Free Agents Only" if free_agents_only else "Free Agents Only"
		_show_tab("all_drivers")
	)
	tab_row.add_child(btn_fa)

	# ── Sort/filter bar ───────────────────────────────────────
	sort_bar = HBoxContainer.new()
	sort_bar.add_theme_constant_override("separation", 4)
	layout.add_child(sort_bar)

	var sort_lbl = Label.new()
	sort_lbl.text = "Sort:"
	sort_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	sort_bar.add_child(sort_lbl)

	## S35.10 — field buttons live in their own container so they can be rebuilt (to show the
	## active sort highlight + direction arrow) without touching the toggle/search.
	sort_fields_box = HBoxContainer.new()
	sort_fields_box.add_theme_constant_override("separation", 4)
	sort_bar.add_child(sort_fields_box)
	_rebuild_sort_buttons()

	## Spacer
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sort_bar.add_child(sp)

	## Interested Only toggle — only relevant on All Drivers tab
	var btn_interested = Button.new()
	btn_interested.text = "⭐ Interested Only"
	btn_interested.custom_minimum_size = Vector2(140, 26)
	btn_interested.add_theme_font_size_override("font_size", 22)
	btn_interested.toggle_mode = true
	btn_interested.button_pressed = interested_only
	btn_interested.tooltip_text = "Show only drivers likely to be interested in joining your team."
	btn_interested.toggled.connect(func(on: bool):
		interested_only = on
		current_page = 0
		_refresh_list())
	sort_bar.add_child(btn_interested)

	# ── Search bar (S28.2) ────────────────────────────────────
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
		current_page = 0  ## reset to first page on new search
		_refresh_list())
	search_row.add_child(search_field_node)

	# ── Scroll + list ─────────────────────────────────────────
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 6)
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_container)

	# ── Page navigation row (S28.2) ───────────────────────────
	page_nav_row = HBoxContainer.new()
	page_nav_row.add_theme_constant_override("separation", 8)
	page_nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(page_nav_row)

	_show_tab("my_drivers")

# ── Tab switching ─────────────────────────────────────────────────────────────

func _show_tab(tab: String) -> void:
	current_tab = tab
	current_page = 0
	tab_my_btn.flat = (tab != "my_drivers")
	tab_all_btn.flat = (tab != "all_drivers")
	_refresh_list()

## S35.10 — (re)build the sort field buttons, highlighting the active one + its direction arrow.
func _rebuild_sort_buttons() -> void:
	if sort_fields_box == null: return
	for c in sort_fields_box.get_children(): c.queue_free()
	for field in [
		["Ovr", "overall"], ["Pace", "pace"], ["Ctrl", "wet"],
		["Focus", "focus"], ["Craft", "craft"], ["Cons", "consistency"],
		["Fit", "fitness"], ["Age", "age"], ["Salary", "salary"]
	]:
		var btn = Button.new()
		var f = field[1]
		var is_active: bool = (sort_field == f)
		var arrow: String = ("  ▲" if sort_ascending else "  ▼") if is_active else ""
		btn.text = field[0] + arrow
		btn.custom_minimum_size = Vector2(52, 26)
		btn.add_theme_font_size_override("font_size", 22)
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
			current_page = 0
			_refresh_list())
		sort_fields_box.add_child(btn)

func _refresh_list() -> void:
	_rebuild_sort_buttons()  ## S35.10 — keep the active-sort highlight in sync
	for child in list_container.get_children():
		list_container.remove_child(child)
		child.queue_free()

	var drivers: Array = []
	if current_tab == "my_drivers":
		drivers = GameState.get_player_drivers()
		drivers = _apply_search(drivers)
		_build_my_drivers_list(drivers)
		_clear_page_nav()  ## my-drivers list is small; no pagination needed
	else:
		drivers = _get_sorted_all_drivers()
		drivers = _apply_search(drivers)
		_build_all_drivers_list_paged(drivers)

## S28.2 — filter a driver array by the search text (name or nationality, case-insensitive).
func _apply_search(drivers: Array) -> Array:
	if search_text == "":
		return drivers
	var q = search_text.to_lower()
	return drivers.filter(func(d):
		return q in d.full_name().to_lower() or q in d.nationality.to_lower())

## S28.2 — render only the current page (PAGE_SIZE rows), plus a nav row.
func _build_all_drivers_list_paged(drivers: Array) -> void:
	if drivers.is_empty():
		var lbl = Label.new()
		lbl.text = "No drivers match." if search_text != "" else "No drivers available."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list_container.add_child(lbl)
		_clear_page_nav()
		return

	var total = drivers.size()
	var max_page = int(ceil(float(total) / PAGE_SIZE)) - 1
	current_page = clamp(current_page, 0, max_page)
	var start = current_page * PAGE_SIZE
	var end = min(start + PAGE_SIZE, total)

	_add_showing_summary()              ## S35.10 — what filter/sort is applied, in plain words
	list_container.add_child(_make_driver_header())
	for i in range(start, end):
		list_container.add_child(_make_all_driver_row(drivers[i]))

	_build_page_nav(total, start, end, max_page)

func _clear_page_nav() -> void:
	if page_nav_row == null: return
	for c in page_nav_row.get_children():
		c.queue_free()

func _build_page_nav(total: int, start: int, end: int, max_page: int) -> void:
	_clear_page_nav()
	if total <= PAGE_SIZE:
		return  ## single page — no nav needed
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

# ── My Drivers ────────────────────────────────────────────────────────────────

func _build_my_drivers_list(drivers: Array) -> void:
	if drivers.is_empty():
		var lbl = Label.new()
		lbl.text = "No drivers signed. Hire drivers from the All Drivers tab."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list_container.add_child(lbl)
		return

	# Column headers
	list_container.add_child(_make_driver_header())

	for driver in drivers:
		list_container.add_child(_make_my_driver_row(driver))

func _make_my_driver_row(driver) -> PanelContainer:
	var card = _make_card_panel(true)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Row 1 — identity + status
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)

	_add_col(row1, driver.full_name(), 180, Color(0.4, 0.8, 1.0), 14)
	_add_col(row1, "Age %d" % driver.age, 55)
	_add_col(row1, driver.nationality, 100)
	_add_col(row1, "Ovr %.0f" % driver.get_overall_skill(), 55,
		_skill_color(driver.get_overall_skill()))

	# Car assignment
	var car = GameState.get_car_for_driver(driver.id)
	var car_text = (car.car_name if car.car_name != "" else "Car %d" % car.car_number) if car else "⚠ No Car"
	_add_col(row1, car_text, 70,
		Color(0.4, 0.9, 0.4) if car else Color(1.0, 0.6, 0.2))

	# Previous season championship indicator
	var prev_champ_id = GameState.previous_season_championship.get(driver.id, "")
	if prev_champ_id != "":
		var prev_reg = GameState.CHAMPIONSHIP_REGISTRY.get(prev_champ_id, {})
		var prev_lbl = Label.new()
		prev_lbl.text = "↩ %s" % prev_reg.get("name", prev_champ_id)
		prev_lbl.add_theme_font_size_override("font_size", 22)
		prev_lbl.add_theme_color_override("font_color", Color(0.5, 0.75, 0.5))
		vbox.add_child(prev_lbl)

	# Contract + salary
	var contract_color = Color(1.0, 0.4, 0.4) if driver.contract_seasons_remaining <= 1 \
		else Color(0.7, 0.7, 0.7)
	var seasons_text = "Free Agent" if driver.contract_seasons_remaining == 0 and driver.contract_team == "" \
		else "%d season%s left" % [driver.contract_seasons_remaining, "s" if driver.contract_seasons_remaining != 1 else ""]
	_add_col(row1, seasons_text, 100, contract_color)

	# Salary — show weekly and yearly
	var weekly = _driver_salary(driver)
	var yearly = weekly * 52
	_add_col(row1, "CR %s/yr" % _fmt_sal(yearly), 90, Color(0.6, 0.9, 0.6))

	# Row 2 — stats bar
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	vbox.add_child(row2)

	for stat in [["Pace", driver.pace], ["Car Control", driver.car_control], ["Focus", driver.focus],
			["Craft", driver.race_craft], ["Cons", driver.consistency],
			["Fit", driver.fitness]]:
		_add_stat_chip(row2, stat[0], stat[1])

	# Row 3 — action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	var d_id = driver.id

	var view_btn = Button.new()
	view_btn.text = "📋 View Card"
	view_btn.custom_minimum_size = Vector2(100, 28)
	view_btn.pressed.connect(func(): _show_driver_card(d_id))
	btn_row.add_child(view_btn)

	var assign_btn = Button.new()
	assign_btn.text = "🏎 Assign Car"
	assign_btn.custom_minimum_size = Vector2(105, 28)
	assign_btn.pressed.connect(func(): _show_assign_car_popup(d_id))
	btn_row.add_child(assign_btn)

	var renew_btn = Button.new()
	renew_btn.text = "📋 Renegotiate"
	renew_btn.custom_minimum_size = Vector2(140, 28)
	renew_btn.pressed.connect(func():
		var ap = GameState.make_renegotiation_approach(d_id, "driver")
		if ap.is_empty(): return
		var panel = preload("res://scenes/ContractNegotiation.tscn").instantiate()
		get_tree().current_scene.add_child(panel)
		panel.open_approach(ap)
		panel.closed.connect(func(): _refresh_list()))
	btn_row.add_child(renew_btn)

	var release_btn = Button.new()
	release_btn.text = "👋 Release"
	release_btn.custom_minimum_size = Vector2(90, 28)
	release_btn.pressed.connect(func(): _confirm_release_driver(d_id))
	btn_row.add_child(release_btn)

	return card

# ── All Drivers ───────────────────────────────────────────────────────────────

func _get_sorted_all_drivers() -> Array:
	var drivers = []

	## S35.9 — shared deterministic interest predicate (matches the approach), with the context
	## built once for the pass (perf). Binary, no percentage; also hides team-refusal-cooldown.
	var interest_ctx := {}
	if interested_only:
		interest_ctx = GameState.build_interest_context()

	for driver_id in GameState.all_drivers:
		var driver = GameState.all_drivers[driver_id]
		## Skip player's own drivers
		if driver.contract_team == GameState.player_team.id:
			continue
		if free_agents_only and driver.contract_team != "":
			continue
		if interested_only:
			if not GameState.is_subject_interested(driver.id, "driver", driver.contract_team, interest_ctx):
				continue
			if not GameState.is_team_refusal_cooled_down(driver.id):
				continue
		drivers.append(driver)

	drivers.sort_custom(func(a, b):
		var va = _sort_value(a)
		var vb = _sort_value(b)
		return va > vb if not sort_ascending else va < vb
	)
	return drivers

func _sort_value(driver) -> float:
	match sort_field:
		"pace":        return driver.pace
		"wet":         return driver.car_control
		"focus":       return driver.focus
		"craft":       return driver.race_craft
		"consistency": return driver.consistency
		"fitness":     return driver.fitness
		"age":         return float(driver.age)
		"salary":      return float(_driver_salary(driver))
		_:             return driver.get_overall_skill()

func _driver_salary(driver) -> int:
	# Estimated weekly salary — base from active championship + skill scaling
	var base = GameState._get_championship_driver_salary()
	return int(base + driver.get_overall_skill() * 3.0)

func _build_all_drivers_list(drivers: Array) -> void:
	if drivers.is_empty():
		var lbl = Label.new()
		lbl.text = "No drivers available."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list_container.add_child(lbl)
		return

	_add_showing_summary()              ## S35.10 — what's applied right now, in plain words
	list_container.add_child(_make_driver_header())

	for driver in drivers:
		list_container.add_child(_make_all_driver_row(driver))

## S35.10 — plain-language line of the active filter + sort so the list state is never a mystery.
func _add_showing_summary() -> void:
	var parts: Array = []
	if free_agents_only:
		parts.append("free agents only")
	if interested_only:
		parts.append("interested only")
	if search_text != "":
		parts.append("search \"%s\"" % search_text)
	if parts.is_empty():
		parts.append("all drivers")
	var dir_arrow: String = "▲" if sort_ascending else "▼"
	parts.append("sorted by %s %s" % [_sort_field_label(), dir_arrow])
	var lbl = Label.new()
	lbl.text = "Showing: " + " · ".join(parts)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.78, 0.95))
	list_container.add_child(lbl)

func _sort_field_label() -> String:
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
		_: return sort_field.capitalize()

func _make_all_driver_row(driver) -> PanelContainer:
	var is_mine = driver.contract_team == GameState.player_team.id
	var is_taken = driver.contract_team != "" and not is_mine

	var card = _make_card_panel(is_mine)
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var row1 = HBoxContainer.new()
	row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)

	var name_color = Color(0.4, 0.8, 1.0) if is_mine else \
		(Color(0.5, 0.5, 0.5) if is_taken else Color.WHITE)
	_add_col(row1, driver.full_name(), 200, name_color, 24)
	_add_col(row1, "Age %d" % driver.age, 70)
	_add_col(row1, driver.nationality, 120)
	_add_col(row1, "Ovr %.0f" % driver.get_overall_skill(), 90,
		_skill_color(driver.get_overall_skill()))

	## S35.10 — TEAM column then CONTRACT column (aligned grid).
	_add_col(row1, _team_name_for(driver.contract_team), 180, Color(0.8, 0.8, 0.85))

	# Status — check approach state first
	var ap_status = _get_approach_status(driver.id)
	var status: String
	var status_color: Color
	if is_mine:
		status = "On your team"; status_color = Color(0.4, 0.8, 1.0)
	elif ap_status == "approaching" or ap_status == "bond_offered":
		status = "⏳ Approached"; status_color = Color(0.7, 0.7, 0.4)
	elif ap_status == "bond_countered":
		status = "💰 Bond Counter"; status_color = Color(1.0, 0.75, 0.2)
	elif ap_status == "negotiating":
		status = "📋 Negotiating"; status_color = Color(0.4, 0.85, 0.55)
	elif ap_status == "pre_signed":
		status = "✅ Next Season"; status_color = Color(0.4, 0.85, 0.55)
	elif is_taken:
		var d_seasons = driver.contract_seasons_remaining
		status = "%d season%s" % [d_seasons, "s" if d_seasons != 1 else ""]
		status_color = Color(1.0, 0.55, 0.2) if d_seasons <= 1 else Color(0.6, 0.85, 0.6)
	else:
		status = "Free agent"; status_color = Color(0.4, 0.9, 0.4)
	_add_col(row1, status, 150, status_color)

	# Salary estimate
	_add_col(row1, "CR %s/yr" % _fmt_sal(_driver_salary(driver) * 52), 130, Color(0.7, 0.7, 0.7))

	# Stats row
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	vbox.add_child(row2)
	for stat in [["Pace", driver.pace], ["Car Control", driver.car_control], ["Focus", driver.focus],
			["Craft", driver.race_craft], ["Cons", driver.consistency],
			["Fit", driver.fitness]]:
		_add_stat_chip(row2, stat[0], stat[1])

	# Buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	var d_id = driver.id

	var view_btn = Button.new()
	view_btn.text = "📋 View Card"
	view_btn.custom_minimum_size = Vector2(100, 28)
	view_btn.pressed.connect(func(): _show_driver_card(d_id))
	btn_row.add_child(view_btn)

	if is_mine:
		var assign_btn = Button.new()
		assign_btn.text = "🏎 Assign Car"
		assign_btn.custom_minimum_size = Vector2(105, 28)
		assign_btn.pressed.connect(func(): _show_assign_car_popup(d_id))
		btn_row.add_child(assign_btn)
	else:
		_add_approach_button(btn_row, d_id, "driver", driver)

	## S35.10 — ★ shortlist star on the RIGHT of the action row.
	var star_sp = Control.new(); star_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(star_sp)
	_add_shortlist_star(btn_row, d_id)

	return card

# ── Driver Card popup ─────────────────────────────────────────────────────────

func _show_driver_card(driver_id: String) -> void:
	if card_overlay:
		card_overlay.queue_free()

	var driver = GameState.all_drivers.get(driver_id)
	if not driver:
		return

	card_overlay = PanelContainer.new()
	card_overlay.anchor_left   = 1.0
	card_overlay.anchor_top    = 0.0
	card_overlay.anchor_right  = 1.0
	card_overlay.anchor_bottom = 0.0
	card_overlay.offset_left   = -600
	card_overlay.offset_top    = 190
	card_overlay.offset_right  = -50
	card_overlay.offset_bottom = 60
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16, 0.98)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.8, 1.0)
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
	name_lbl.text = "👤 %s" % driver.full_name()
	name_lbl.add_theme_font_size_override("font_size", 48)
	name_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_lbl)
	## S35.10 — ★ shortlist toggle in the card header (synced with the row star).
	var card_star = Button.new()
	var star_on: bool = GameState.is_shortlisted(driver_id, "driver")
	card_star.text = "★" if star_on else "☆"
	card_star.custom_minimum_size = Vector2(44, 36)
	card_star.add_theme_font_size_override("font_size", 26)
	card_star.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2) if star_on else Color(0.6, 0.6, 0.6))
	card_star.tooltip_text = "Remove from shortlist" if star_on else "Add to shortlist"
	card_star.pressed.connect(func():
		GameState.toggle_shortlist(driver_id, "driver")
		_show_driver_card(driver_id)  ## rebuild card to reflect new star state
		_refresh_list())              ## and the row behind it
	header.add_child(card_star)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(func(): card_overlay.queue_free(); card_overlay = null)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# Identity
	_card_row(vbox, "Age / Sex / Nationality",
		"%d  |  %s  |  %s" % [driver.age, driver.sex, driver.nationality])
	_card_row(vbox, "Discipline", "%s  (Adapt: %.1f)" % [
		driver.active_discipline, driver.get_active_adaptation()])

	# Championship position
	var sorted = GameState.active_championship.get_standings_sorted()
	var pos = 0
	var pts = 0
	for i in range(sorted.size()):
		if sorted[i]["driver_id"] == driver_id:
			pos = i + 1
			pts = sorted[i]["points"]
			break
	if pos > 0:
		_card_row(vbox, "Championship", "P%d — %d pts" % [pos, pts])

	# Contract
	var car = GameState.get_car_for_driver(driver_id)
	_card_row(vbox, "Contract",
		"%d seasons remaining  |  Car: %s" % [
			driver.contract_seasons_remaining,
			(car.car_name if car.car_name != "" else "Car %d" % car.car_number) if car else "Unassigned"])

	vbox.add_child(HSeparator.new())

	# Stats
	var stats_title = Label.new()
	stats_title.text = "ATTRIBUTES"
	stats_title.add_theme_font_size_override("font_size", 30)
	stats_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(stats_title)

	var stats = [
		["🚀 Pace", driver.pace, driver.get_effective_pace()],
		["🌧 Car Control / Traction", driver.car_control, driver.get_effective_wet()],
		["🎯 Focus", driver.focus, driver.get_effective_focus()],
		["⚔ Race Craft", driver.race_craft, driver.get_effective_race_craft()],
		["🔄 Consistency", driver.consistency, driver.get_effective_consistency()],
		["💬 Feedback", driver.feedback, -1.0],
		["⭐ Reputation", driver.marketability, -1.0],
		["💪 Fitness", driver.fitness, -1.0],
	]
	for stat in stats:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		var lbl = Label.new()
		lbl.text = stat[0]
		lbl.custom_minimum_size = Vector2(200, 0)
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		row.add_child(lbl)
		var bar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = stat[1]
		bar.custom_minimum_size = Vector2(160, 18)
		bar.show_percentage = false
		row.add_child(bar)
		var val_lbl = Label.new()
		val_lbl.text = "%.1f" % stat[1]
		if stat[2] >= 0:
			val_lbl.text += "  (eff: %.1f)" % stat[2]
		val_lbl.add_theme_font_size_override("font_size", 30)
		val_lbl.add_theme_color_override("font_color", _skill_color(stat[1]))
		row.add_child(val_lbl)

	vbox.add_child(HSeparator.new())

	# Overall
	_card_row(vbox, "Overall Skill", "%.1f / 100" % driver.get_overall_skill(),
		_skill_color(driver.get_overall_skill()))

	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var is_mine = driver.contract_team == GameState.player_team.id
	if is_mine:
		var assign_btn = Button.new()
		assign_btn.text = "🏎 Assign to Car"
		assign_btn.custom_minimum_size = Vector2(130, 32)
		assign_btn.pressed.connect(func():
			card_overlay.queue_free()
			card_overlay = null
			_show_assign_car_popup(driver_id)
		)
		btn_row.add_child(assign_btn)

		var renew_btn = Button.new()
		renew_btn.text = "📋 Renegotiate Contract"
		renew_btn.custom_minimum_size = Vector2(180, 32)
		renew_btn.pressed.connect(func():
			var neg = GameState.generate_driver_opening_offer(driver_id)
			if neg.is_empty(): return
			GameState.start_negotiation(neg)
			card_overlay.queue_free(); card_overlay = null
			var panel = preload("res://scenes/ContractNegotiation.tscn").instantiate()
			get_tree().current_scene.add_child(panel)
			panel.open(GameState.active_negotiation)
			panel.closed.connect(func(): _refresh_list()))
		btn_row.add_child(renew_btn)
	elif driver.contract_team == "":
		var hire_btn = Button.new()
		hire_btn.text = "📋 Negotiate Contract"
		hire_btn.custom_minimum_size = Vector2(180, 32)
		hire_btn.pressed.connect(func():
			var neg = GameState.generate_driver_opening_offer(driver_id)
			if neg.is_empty(): return
			GameState.start_negotiation(neg)
			card_overlay.queue_free(); card_overlay = null
			var panel = preload("res://scenes/ContractNegotiation.tscn").instantiate()
			get_tree().current_scene.add_child(panel)
			panel.open(GameState.active_negotiation)
			panel.closed.connect(func():
				tab_my_btn.text = "🏎 My Drivers (%d)" % GameState.player_team.drivers.size()
				_refresh_list()))
		btn_row.add_child(hire_btn)

# ── Assign car popup ──────────────────────────────────────────────────────────

func _show_assign_car_popup(driver_id: String) -> void:
	if card_overlay:
		card_overlay.queue_free()

	var driver = GameState.all_drivers.get(driver_id)
	if not driver:
		return

	card_overlay = PanelContainer.new()
	card_overlay.set_anchors_preset(Control.PRESET_CENTER)
	card_overlay.custom_minimum_size = Vector2(360, 0)
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
	title.text = "Assign %s to car:" % driver.full_name()
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(32, 32)
	close_btn.pressed.connect(func(): card_overlay.queue_free(); card_overlay = null)
	header.add_child(close_btn)

	if GameState.player_team_cars.is_empty():
		var lbl = Label.new()
		lbl.text = "No cars available. Hire a driver first to create a car slot."
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)
		return

	for car in GameState.player_team_cars:
		var current_driver = GameState.all_drivers.get(car.driver_id)
		var car_btn = Button.new()
		var current_name = current_driver.full_name() if current_driver else "Empty"
		var car_display = car.car_name if car.car_name != "" else "Car %d" % car.car_number
		car_btn.text = "%s  —  %s" % [car_display, current_name]
		car_btn.custom_minimum_size = Vector2(320, 38)
		if car.driver_id == driver_id:
			car_btn.text += "  ✅ (current)"
			car_btn.disabled = true
		var _car_id = car.id
		car_btn.pressed.connect(func():
			GameState.assign_driver_to_car(driver_id, _car_id)
			card_overlay.queue_free()
			card_overlay = null
			_refresh_list()
		)
		vbox.add_child(car_btn)

# ── Release confirmation ───────────────────────────────────────────────────────

func _confirm_release_driver(driver_id: String) -> void:
	GameState.release_driver(driver_id)
	tab_my_btn.text = "🏎 My Drivers (%d)" % GameState.player_team.drivers.size()
	_refresh_list()

## ── Approach button logic ─────────────────────────────────────────────────────

func _add_approach_button(btn_row: HBoxContainer, subject_id: String,
		subject_type: String, subject) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(180, 28)
	btn.add_theme_font_size_override("font_size", 22)

	## Check existing approach state
	var ap_status = _get_approach_status(subject_id)

	if not GameState.is_subject_available(subject_id):
		## Hide walked-away subjects from the list entirely — don't show the row
		return

	match ap_status:
		"approaching":
			btn.text = "⏳ Awaiting Reply"
			btn.disabled = true
			btn.modulate = Color(0.7, 0.7, 0.4)
		"bond_offered":
			btn.text = "⏳ Bond Reply Pending"
			btn.disabled = true
			btn.modulate = Color(0.7, 0.7, 0.4)
		"bond_countered":
			btn.text = "💰 Bond Counter — Decide"
			btn.modulate = Color(1.0, 0.75, 0.2)
			btn.pressed.connect(func(): _show_bond_response_popup(subject_id, subject_type))
		"negotiating":
			btn.text = "📋 Contract Round %d" % _get_approach_round(subject_id)
			btn.modulate = Color(0.4, 0.85, 0.55)
			btn.pressed.connect(func(): _show_contract_negotiation_popup(subject_id, subject_type))
		"pre_signed":
			btn.text = "✅ Pre-signed (Next Season)"
			btn.disabled = true
			btn.modulate = Color(0.4, 0.85, 0.55)
		_:
			## No active approach — show what's possible
			var slot = GameState.get_slot_projection("driver")
			var is_free_agent = subject.contract_team == ""
			var on_last_contract = subject.contract_seasons_remaining <= 1 and not is_free_agent

			if slot["now_free"] > 0 and (is_free_agent or on_last_contract):
				btn.text = "📋 Negotiate Contract"
				btn.pressed.connect(func(): _show_timing_popup(subject_id, subject_type))
			elif slot["next_free"] > 0 or is_free_agent:
				btn.text = "📋 Sign for Next Season"
				btn.pressed.connect(func(): _initiate_approach(subject_id, subject_type, "next_season"))
				btn.modulate = Color(0.7, 0.85, 1.0)
			else:
				btn.text = "⚠ No Slot"
				btn.disabled = true
				btn.tooltip_text = "No driver slots available now or next season."

	btn_row.add_child(btn)

func _get_approach_status(subject_id: String) -> String:
	for ap in GameState.active_approaches:
		if ap["subject_id"] == subject_id and ap["status"] not in ["failed","rejected","expired","activated"]:
			match ap["status"]:
				"approaching": return "approaching" if ap["bond_status"] != "countered" else "bond_countered"
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
		if ap["subject_id"] == subject_id:
			return ap["neg_id"]
	return ""

func _has_assigned_tp() -> bool:
	for champ in GameState.active_championships:
		if GameState._get_tp_for_championship(champ.id) != null:
			return true
	return false

func _initiate_approach(subject_id: String, subject_type: String, start_date: String) -> void:
	var err = GameState.initiate_approach(subject_id, subject_type, start_date)
	if err == "not_interested":
		_show_not_interested_popup(subject_id, subject_type)  ## S29.0 — visible popup, not just notification
	elif err == "team_refused" or err == "team_refused_cooldown":
		_show_team_refused_popup(subject_id, subject_type)  ## S35.9 — team won't release
	elif err != "":
		GameState.add_notification("High", err)
	else:
		## Check if we went straight to negotiating (free agent) — open popup immediately
		var ap = GameState._get_approach_by_subject(subject_id)
		if not ap.is_empty() and ap["status"] == "negotiating":
			_show_contract_negotiation_popup(subject_id, subject_type)
			return
	_refresh_list()

## S35.9 — Visible modal when the target's TEAM refuses to release them (distinct from the person
## not being interested). The person wanted to come; their team said no. Triggers a 26-week cooldown.
func _show_team_refused_popup(subject_id: String, subject_type: String) -> void:
	var subject = GameState.all_drivers.get(subject_id) if subject_type == "driver" \
		else GameState.all_staff.get(subject_id)
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

## S29.0 — Visible modal shown when a target declines an approach.
## Previously this only fired a Normal notification (easy to miss); now a popup appears.
func _show_not_interested_popup(subject_id: String, subject_type: String) -> void:
	var subject = GameState.all_drivers.get(subject_id) if subject_type == "driver" \
		else GameState.all_staff.get(subject_id)
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
	## Popup asking: Immediate or Next Season?
	## Guard: if subject is now a free agent, skip popup and go straight to approach
	var subject_obj = GameState.all_drivers.get(subject_id) if subject_type == "driver" \
		else GameState.all_staff.get(subject_id)
	if subject_obj == null: return
	var is_free = subject_obj.contract_team == ""
	if is_free:
		_initiate_approach(subject_id, subject_type, "immediate")
		return

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

	var subject = GameState.all_drivers.get(subject_id) if subject_type == "driver" \
		else GameState.all_staff.get(subject_id)
	var name_str = subject.full_name() if subject else subject_id

	var lbl = Label.new()
	lbl.text = "Approach %s" % name_str
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	vb.add_child(lbl)

	## Bond estimate
	var bond_info = GameState.get_bond_estimate(subject_id, subject_type, "immediate")
	var lbl_est = Label.new()
	lbl_est.text = "Bond estimate: CR %s – %s" % [
		_fmt_sal(bond_info["low"]), _fmt_sal(bond_info["high"])]
	lbl_est.add_theme_font_size_override("font_size", 24)
	lbl_est.modulate = Color(0.7, 0.7, 0.4)
	if not bond_info["has_cfo"]:
		lbl_est.text += "\n⚠ No CFO — estimate ±30%"
	vb.add_child(lbl_est)

	vb.add_child(HSeparator.new())

	var slot = GameState.get_slot_projection(subject_type)
	for timing in [["immediate", "🚀 Immediate Transfer", "Costs 1.5× + 25% disruption fee"],
			["next_season", "📅 Next Season", "Standard bond — joins at season start"]]:
		var btn = Button.new()
		btn.text = timing[1]
		btn.tooltip_text = timing[2]
		btn.custom_minimum_size = Vector2(0, 36)
		var t = timing[0]
		## Disable Immediate if no current slots
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
	## Show the counter offer from the other team and let player respond
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
	lbl_ask.text = "%s's team asks: CR %s" % [ap["current_team_name"], _fmt_sal(int(ap["bond_team_ask"]))]
	lbl_ask.add_theme_font_size_override("font_size", 26)
	vb.add_child(lbl_ask)

	var lbl_est = Label.new()
	lbl_est.text = "CFO estimate: CR %s" % _fmt_sal(int(ap["bond_estimate"]))
	lbl_est.add_theme_font_size_override("font_size", 22)
	lbl_est.modulate = Color(0.6, 0.6, 0.6)
	vb.add_child(lbl_est)

	var spin_lbl = Label.new()
	spin_lbl.text = "Your counter offer:"
	spin_lbl.add_theme_font_size_override("font_size", 24)
	vb.add_child(spin_lbl)

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
	## Open the ContractNegotiation overlay with the approach data
	if card_overlay: card_overlay.queue_free(); card_overlay = null
	var panel = preload("res://scenes/ContractNegotiation.tscn").instantiate()
	get_tree().current_scene.add_child(panel)
	panel.open_approach(ap)
	panel.closed.connect(func():
		tab_my_btn.text = "🏎 My Drivers (%d)" % GameState.player_team.drivers.size()
		_refresh_list())

# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_driver_header() -> PanelContainer:
	## S35.10b — full-width header panel matching the row card's left border + margins, with
	## proportional columns using the SAME weights as _make_all_driver_row, so columns align and
	## the grid uses the whole screen width.
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
	for col in [["Name", 200], ["Age", 70], ["Nationality", 120],
			["Overall", 90], ["Team", 180], ["Contract", 150], ["Salary", 130]]:
		_add_col(row, col[0], col[1], hc, 20)
	return panel

func _make_card_panel(highlight: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.20, 1.0) if highlight else Color(0.11, 0.11, 0.13, 1.0)
	style.border_width_left = 3
	style.border_color = Color(0.4, 0.8, 1.0) if highlight else Color(0.25, 0.25, 0.3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	return card

## S35.10b — proportional column (stretch ratio, not fixed px) — see StaffHub _add_col. Uses the
## full row width, never clips, header uses the same weights for alignment.
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

## S35.10 — team display name for a driver's contract_team, or "—" for a free agent.
func _team_name_for(contract_team_id: String) -> String:
	if contract_team_id == "":
		return "—"
	if contract_team_id == GameState.player_team.id:
		return GameState.player_team.team_name
	for t in GameState.all_teams:
		if t.id == contract_team_id:
			return t.team_name
	return contract_team_id

## S35.10 — ★ shortlist toggle (icon + tooltip), synced via is_shortlisted.
func _add_shortlist_star(parent: HBoxContainer, subject_id: String) -> void:
	var star = Button.new()
	var on: bool = GameState.is_shortlisted(subject_id, "driver")
	star.text = "★" if on else "☆"
	star.custom_minimum_size = Vector2(40, 28)
	star.add_theme_font_size_override("font_size", 22)
	star.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2) if on else Color(0.6, 0.6, 0.6))
	star.tooltip_text = "Remove from shortlist" if on else "Add to shortlist"
	star.pressed.connect(func():
		GameState.toggle_shortlist(subject_id, "driver")
		_refresh_list())
	parent.add_child(star)

func _add_stat_chip(parent: HBoxContainer, label: String, value: float) -> void:
	var chip = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.18, 0.22)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)
	var lbl = Label.new()
	lbl.text = "%s %.0f" % [label, value]
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", _skill_color(value))
	## S35.10 — emphasize a maxed (100) stat with a brighter green.
	if value >= 100.0:
		lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.45))
	chip.add_child(lbl)
	parent.add_child(chip)

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
	row.add_child(val)

func _skill_color(value: float) -> Color:
	if value >= 75.0:  return Color(0.3, 1.0, 0.3)
	elif value >= 50.0: return Color(1.0, 0.84, 0.0)
	elif value >= 30.0: return Color(1.0, 0.6, 0.2)
	else:               return Color(0.7, 0.4, 0.4)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _fmt_sal(n: int) -> String:
	if n >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif n >= 1000:
		return "%.0fK" % (n / 1000.0)
	return str(n)

func _input(event: InputEvent) -> void:
	# Close card on Escape
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if card_overlay:
			card_overlay.queue_free()
			card_overlay = null
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		var screenshot = get_viewport().get_texture().get_image()
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
		screenshot.save_png("user://screenshot_%s.png" % timestamp)
