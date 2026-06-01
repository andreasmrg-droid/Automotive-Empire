extends Control

# ── State ─────────────────────────────────────────────────────────────────────
var current_tab: String = "my_drivers"
var sort_field: String = "overall"    # overall | pace | age | salary
var sort_ascending: bool = false
var role_filter: String = "All"

# ── Node references (built in code) ──────────────────────────────────────────
var tab_my_btn: Button
var tab_all_btn: Button
var list_container: VBoxContainer
var scroll: ScrollContainer
var sort_bar: HBoxContainer
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
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

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

	# ── Sort/filter bar ───────────────────────────────────────
	sort_bar = HBoxContainer.new()
	sort_bar.add_theme_constant_override("separation", 6)
	layout.add_child(sort_bar)

	var sort_lbl = Label.new()
	sort_lbl.text = "Sort:"
	sort_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	sort_bar.add_child(sort_lbl)

	for field in [["Overall", "overall"], ["Pace", "pace"], ["Age", "age"], ["Salary", "salary"]]:
		var btn = Button.new()
		btn.text = field[0]
		btn.custom_minimum_size = Vector2(75, 28)
		var f = field[1]
		btn.pressed.connect(func():
			if sort_field == f:
				sort_ascending = !sort_ascending
			else:
				sort_field = f
				sort_ascending = false
			_refresh_list()
		)
		sort_bar.add_child(btn)

	# ── Scroll + list ─────────────────────────────────────────
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)

	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 6)
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_container)

	_show_tab("my_drivers")

# ── Tab switching ─────────────────────────────────────────────────────────────

func _show_tab(tab: String) -> void:
	current_tab = tab
	tab_my_btn.flat = (tab != "my_drivers")
	tab_all_btn.flat = (tab != "all_drivers")
	_refresh_list()

func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	var drivers: Array = []
	if current_tab == "my_drivers":
		drivers = GameState.get_player_drivers()
		_build_my_drivers_list(drivers)
	else:
		drivers = _get_sorted_all_drivers()
		_build_all_drivers_list(drivers)

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

	# Contract
	var contract_color = Color(1.0, 0.4, 0.4) if driver.contract_seasons_remaining <= 1 \
		else Color(0.7, 0.7, 0.7)
	_add_col(row1, "%d seasons" % driver.contract_seasons_remaining, 80, contract_color)

	# Row 2 — stats bar
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	vbox.add_child(row2)

	for stat in [["Pace", driver.pace], ["Wet", driver.wet], ["Focus", driver.focus],
			["Craft", driver.race_craft], ["Cons", driver.consistency],
			["Fit", driver.fitness], ["Mktg", driver.marketability]]:
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
	renew_btn.text = "📋 Renew (5 seasons)"
	renew_btn.custom_minimum_size = Vector2(140, 28)
	renew_btn.pressed.connect(func():
		GameState.renew_driver_contract(d_id, 5)
		_refresh_list()
	)
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
	for driver_id in GameState.all_drivers:
		drivers.append(GameState.all_drivers[driver_id])

	drivers.sort_custom(func(a, b):
		var va = _sort_value(a)
		var vb = _sort_value(b)
		return va > vb if not sort_ascending else va < vb
	)
	return drivers

func _sort_value(driver) -> float:
	match sort_field:
		"pace":    return driver.pace
		"age":     return float(driver.age)
		"salary":  return float(_driver_salary(driver))
		_:         return driver.get_overall_skill()

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

	list_container.add_child(_make_driver_header())

	for driver in drivers:
		list_container.add_child(_make_all_driver_row(driver))

func _make_all_driver_row(driver) -> PanelContainer:
	var is_mine = driver.contract_team == GameState.player_team.id
	var is_taken = driver.contract_team != "" and not is_mine

	var card = _make_card_panel(is_mine)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	vbox.add_child(row1)

	var name_color = Color(0.4, 0.8, 1.0) if is_mine else \
		(Color(0.5, 0.5, 0.5) if is_taken else Color.WHITE)
	_add_col(row1, driver.full_name(), 180, name_color, 14)
	_add_col(row1, "Age %d" % driver.age, 55)
	_add_col(row1, driver.nationality, 100)
	_add_col(row1, "Ovr %.0f" % driver.get_overall_skill(), 55,
		_skill_color(driver.get_overall_skill()))

	# Status
	var status = "On your team" if is_mine else ("Contracted" if is_taken else "Free agent")
	var status_color = Color(0.4, 0.8, 1.0) if is_mine else \
		(Color(0.5, 0.5, 0.5) if is_taken else Color(0.4, 0.9, 0.4))
	_add_col(row1, status, 100, status_color)

	# Salary estimate
	_add_col(row1, "$%d/wk" % _driver_salary(driver), 75, Color(0.7, 0.7, 0.7))

	# Stats row
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	vbox.add_child(row2)
	for stat in [["Pace", driver.pace], ["Wet", driver.wet], ["Focus", driver.focus],
			["Craft", driver.race_craft], ["Cons", driver.consistency],
			["Fit", driver.fitness], ["Mktg", driver.marketability]]:
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

	if not is_mine and not is_taken:
		var hire_btn = Button.new()
		hire_btn.text = "✅ Hire Driver"
		hire_btn.custom_minimum_size = Vector2(110, 28)
		hire_btn.pressed.connect(func():
			if GameState.hire_driver(d_id):
				tab_my_btn.text = "🏎 My Drivers (%d)" % GameState.player_team.drivers.size()
				_refresh_list()
		)
		btn_row.add_child(hire_btn)
	elif is_mine:
		var assign_btn = Button.new()
		assign_btn.text = "🏎 Assign Car"
		assign_btn.custom_minimum_size = Vector2(105, 28)
		assign_btn.pressed.connect(func(): _show_assign_car_popup(d_id))
		btn_row.add_child(assign_btn)

	return card

# ── Driver Card popup ─────────────────────────────────────────────────────────

func _show_driver_card(driver_id: String) -> void:
	if card_overlay:
		card_overlay.queue_free()

	var driver = GameState.all_drivers.get(driver_id)
	if not driver:
		return

	card_overlay = PanelContainer.new()
	card_overlay.set_anchors_preset(Control.PRESET_CENTER)
	card_overlay.custom_minimum_size = Vector2(480, 0)
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
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	card_overlay.add_theme_stylebox_override("panel", style)
	add_child(card_overlay)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card_overlay.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	var name_lbl = Label.new()
	name_lbl.text = "👤 %s" % driver.full_name()
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_lbl)
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(32, 32)
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
	stats_title.add_theme_font_size_override("font_size", 13)
	stats_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(stats_title)

	var stats = [
		["🚀 Pace", driver.pace, driver.get_effective_pace()],
		["🌧 Wet / Traction", driver.wet, driver.get_effective_wet()],
		["🎯 Focus", driver.focus, driver.get_effective_focus()],
		["⚔ Race Craft", driver.race_craft, driver.get_effective_race_craft()],
		["🔄 Consistency", driver.consistency, driver.get_effective_consistency()],
		["💬 Feedback", driver.feedback, -1.0],
		["📣 Marketability", driver.marketability, -1.0],
		["💪 Fitness", driver.fitness, -1.0],
	]
	for stat in stats:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		var lbl = Label.new()
		lbl.text = stat[0]
		lbl.custom_minimum_size = Vector2(160, 0)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		row.add_child(lbl)
		var bar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = stat[1]
		bar.custom_minimum_size = Vector2(160, 14)
		bar.show_percentage = false
		row.add_child(bar)
		var val_lbl = Label.new()
		val_lbl.text = "%.1f" % stat[1]
		if stat[2] >= 0:
			val_lbl.text += "  (eff: %.1f)" % stat[2]
		val_lbl.add_theme_font_size_override("font_size", 12)
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
		renew_btn.text = "📋 Renew Contract"
		renew_btn.custom_minimum_size = Vector2(140, 32)
		renew_btn.pressed.connect(func():
			GameState.renew_driver_contract(driver_id, 5)
			card_overlay.queue_free()
			card_overlay = null
			_refresh_list()
		)
		btn_row.add_child(renew_btn)
	elif driver.contract_team == "":
		var hire_btn = Button.new()
		hire_btn.text = "✅ Hire Driver"
		hire_btn.custom_minimum_size = Vector2(120, 32)
		hire_btn.pressed.connect(func():
			if GameState.hire_driver(driver_id):
				card_overlay.queue_free()
				card_overlay = null
				tab_my_btn.text = "🏎 My Drivers (%d)" % GameState.player_team.drivers.size()
				_refresh_list()
		)
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
	title.add_theme_font_size_override("font_size", 15)
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
	var driver = GameState.all_drivers.get(driver_id)
	if not driver:
		return
	var dialog = ConfirmationDialog.new()
	dialog.title = "Release Driver"
	dialog.dialog_text = "Release %s from the team?\nThey will become a free agent." % driver.full_name()
	dialog.ok_button_text = "Release"
	dialog.cancel_button_text = "Cancel"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func():
		GameState.release_driver(driver_id)
		tab_my_btn.text = "🏎 My Drivers (%d)" % GameState.player_team.drivers.size()
		_refresh_list()
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_driver_header() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for col in [["Name", 180], ["Age", 55], ["Nationality", 100],
			["Overall", 55], ["Car", 70], ["Contract", 80]]:
		var lbl = Label.new()
		lbl.text = col[0]
		lbl.custom_minimum_size = Vector2(col[1], 0)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		row.add_child(lbl)
	return row

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

func _add_col(parent: HBoxContainer, text: String, width: int,
		color: Color = Color.WHITE, font_size: int = 13) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(width, 0)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.clip_text = true
	parent.add_child(lbl)

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
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", _skill_color(value))
	chip.add_child(lbl)
	parent.add_child(chip)

func _card_row(parent: VBoxContainer, label: String, value: String,
		value_color: Color = Color.WHITE) -> void:
	var row = HBoxContainer.new()
	parent.add_child(row)
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(160, 0)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	row.add_child(lbl)
	var val = Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", value_color)
	row.add_child(val)

func _skill_color(value: float) -> Color:
	if value >= 75.0:  return Color(0.3, 1.0, 0.3)
	elif value >= 50.0: return Color(1.0, 0.84, 0.0)
	elif value >= 30.0: return Color(1.0, 0.6, 0.2)
	else:               return Color(0.7, 0.4, 0.4)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

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
