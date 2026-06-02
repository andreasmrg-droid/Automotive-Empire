extends Control

## Championship registration screen.
## Shown during off-season (weeks 40-52) via MainHub "Register for Championships" button.
## Player can browse all 24 championships, check deadlines and fees, and register/unregister.

var _list_container: VBoxContainer
var _filter_discipline: String = "All"
var _filter_tier: int = 0  # 0 = all tiers

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_refresh_list()

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

	# ── Header ────────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var lbl_title = Label.new()
	lbl_title.text = "🏆 CHAMPIONSHIP REGISTRATION  —  Season %d" % (GameState.current_season + 1)
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	var lbl_week = Label.new()
	lbl_week.text = "Week %d / 52" % GameState.current_week
	lbl_week.modulate = Color(0.6, 0.6, 0.6)
	lbl_week.add_theme_font_size_override("font_size", 13)
	header.add_child(lbl_week)

	var btn_back = Button.new()
	btn_back.text = "← Back to Hub"
	btn_back.custom_minimum_size = Vector2(140, 36)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)

	# Re-register all currently-running championships for next season
	var btn_rereg = Button.new()
	btn_rereg.text = "🔄 Re-register All Running"
	btn_rereg.custom_minimum_size = Vector2(220, 36)
	btn_rereg.modulate = Color(0.7, 1.0, 0.7)
	btn_rereg.pressed.connect(_on_reregister_all)
	header.add_child(btn_rereg)

	root.add_child(HSeparator.new())

	# ── Balance + registered summary ─────────────────────────────────────────
	var info_row = HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 24)
	root.add_child(info_row)

	var lbl_bal = Label.new()
	lbl_bal.text = "Balance: CR %s" % _fmt(int(GameState.player_team.balance))
	lbl_bal.add_theme_font_size_override("font_size", 14)
	lbl_bal.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if GameState.player_team.balance >= 0 else Color(1.0, 0.3, 0.3))
	info_row.add_child(lbl_bal)

	var reg_count = GameState.player_registered_championships.size()
	var lbl_reg = Label.new()
	lbl_reg.text = "%d championship%s registered for Season %d" % [
		reg_count, "s" if reg_count != 1 else "", GameState.current_season + 1]
	lbl_reg.modulate = Color(0.7, 0.7, 0.7)
	lbl_reg.add_theme_font_size_override("font_size", 13)
	info_row.add_child(lbl_reg)

	# ── Filter bar ────────────────────────────────────────────────────────────
	var filter_row = HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	root.add_child(filter_row)

	var lbl_filter = Label.new()
	lbl_filter.text = "Filter:"
	lbl_filter.modulate = Color(0.6, 0.6, 0.6)
	filter_row.add_child(lbl_filter)

	for disc in ["All", "GK", "Rally", "TC", "OWC", "SC", "EPC", "GP"]:
		var btn = Button.new()
		btn.text = disc
		btn.custom_minimum_size = Vector2(50, 28)
		btn.add_theme_font_size_override("font_size", 12)
		var d = disc
		btn.pressed.connect(func():
			_filter_discipline = d
			_refresh_list()
		)
		filter_row.add_child(btn)

	root.add_child(HSeparator.new())

	# ── Championship list ─────────────────────────────────────────────────────
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_list_container)

func _refresh_list() -> void:
	for child in _list_container.get_children():
		child.queue_free()

	# Group by tier
	var by_tier: Dictionary = {}
	for champ_id in GameState.CHAMPIONSHIP_REGISTRY:
		var reg = GameState.CHAMPIONSHIP_REGISTRY[champ_id]
		if _filter_discipline != "All" and reg["discipline"] != _filter_discipline:
			continue
		var tier = reg["tier"]
		if not tier in by_tier:
			by_tier[tier] = []
		by_tier[tier].append(champ_id)

	var tiers = by_tier.keys()
	tiers.sort()
	for tier in tiers:
		var tier_lbl = Label.new()
		tier_lbl.text = "TIER %d" % tier
		tier_lbl.add_theme_font_size_override("font_size", 11)
		tier_lbl.modulate = Color(0.5, 0.5, 0.5)
		_list_container.add_child(tier_lbl)

		for champ_id in by_tier[tier]:
			_list_container.add_child(_build_champ_row(champ_id))

func _build_champ_row(champ_id: String) -> PanelContainer:
	var reg = GameState.CHAMPIONSHIP_REGISTRY[champ_id]
	var is_registered = champ_id in GameState.player_registered_championships
	var is_running = false
	for champ in GameState.active_championships:
		if champ.id == champ_id:
			is_running = true
			break

	var deadline = GameState.get_entry_deadline_week(champ_id)
	var deadline_passed = GameState.current_week > deadline
	var delivery_wk = GameState.get_car_delivery_week(champ_id)
	var car_cost = GameState.get_provider_car_cost(champ_id)
	var entry_fee = reg["entry_fee"]
	var total_cost = entry_fee + car_cost
	var can_register = GameState.can_register_for_championship(champ_id)

	# Card style
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	if is_registered:
		style.bg_color = Color(0.10, 0.14, 0.22)
		style.border_color = Color(0.3, 0.55, 1.0)
	elif deadline_passed:
		style.bg_color = Color(0.12, 0.12, 0.12)
		style.border_color = Color(0.25, 0.25, 0.25)
	else:
		style.bg_color = Color(0.11, 0.12, 0.15)
		style.border_color = Color(0.25, 0.25, 0.30)
	if is_running:
		style.border_color = Color(0.3, 0.7, 0.3)  # green border if currently running
	style.border_width_left = 3
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	style.content_margin_left = 12; style.content_margin_right = 12
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	panel.add_child(hbox)

	# Left: name + details
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 4)
	hbox.add_child(left)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	var lbl_name = Label.new()
	lbl_name.text = reg["name"]
	lbl_name.add_theme_font_size_override("font_size", 15)
	if deadline_passed and not is_registered:
		lbl_name.modulate = Color(0.45, 0.45, 0.45)
	name_row.add_child(lbl_name)

	# Info tags — running and registered are informational only
	if is_running:
		name_row.add_child(_tag("RUNNING S%d" % GameState.current_season, Color(0.3, 0.8, 0.3)))
	if is_registered:
		name_row.add_child(_tag("REGISTERED S%d" % (GameState.current_season + 1), Color(0.4, 0.6, 1.0)))
	if deadline_passed and not is_registered:
		name_row.add_child(_tag("DEADLINE PASSED", Color(0.5, 0.5, 0.5)))
	left.add_child(name_row)

	var details_row = HBoxContainer.new()
	details_row.add_theme_constant_override("separation", 16)
	left.add_child(details_row)

	for item in [
		[reg["discipline"], Color(0.7, 0.85, 1.0)],
		["%d races" % reg["num_races"], Color(0.6, 0.6, 0.6)],
		["Age %d–%s" % [reg["min_age"], str(reg["max_age"]) if reg["max_age"] < 99 else "+"], Color(0.6, 0.6, 0.6)],
		["Entry: CR %s" % _fmt(entry_fee), Color(0.9, 0.7, 0.3)],
		["Car: CR %s" % _fmt(car_cost), Color(0.7, 0.7, 0.7)],
		["Total: CR %s" % _fmt(total_cost), Color(0.95, 0.95, 0.95)],
		["Delivery: Wk %d" % delivery_wk, Color(0.6, 0.9, 0.6)],
		["Deadline: Wk %d" % deadline, Color(1.0, 0.5, 0.15) if deadline_passed else Color(0.6, 0.6, 0.6)],
	]:
		var lbl = Label.new()
		lbl.text = str(item[0])
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", item[1])
		details_row.add_child(lbl)

	# Right: action button
	# Running = show register for next season (same as unregistered)
	# Registered for next season = show locked label
	# Deadline passed and not registered = too late
	var btn_col = VBoxContainer.new()
	btn_col.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(btn_col)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(160, 36)
	if is_registered:
		btn.text = "✅ S%d Registered" % (GameState.current_season + 1)
		btn.disabled = true
		btn.modulate = Color(0.6, 0.6, 0.6)
	elif deadline_passed:
		btn.text = "❌ Too Late"
		btn.disabled = true
	elif not can_register:
		var fee_short = total_cost - int(GameState.player_team.balance)
		btn.text = "Need CR %s" % _fmt(fee_short)
		btn.disabled = true
	else:
		btn.text = "Register S%d →" % (GameState.current_season + 1)
		if is_running:
			btn.text = "Re-register S%d →" % (GameState.current_season + 1)
		btn.pressed.connect(func():
			if GameState.register_for_championship(champ_id):
				_refresh_list()
		)
	btn_col.add_child(btn)

	return panel

func _tag(text: String, color: Color) -> PanelContainer:
	var chip = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.15)
	style.border_color = color
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.corner_radius_top_left = 3; style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3; style.corner_radius_bottom_right = 3
	style.content_margin_left = 6; style.content_margin_right = 6
	style.content_margin_top = 2; style.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", style)
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", color)
	chip.add_child(lbl)
	return chip

func _on_reregister_all() -> void:
	var registered_count = 0
	var failed = []
	for champ in GameState.active_championships:
		if champ.id == "":
			continue
		if champ.id in GameState.player_registered_championships:
			continue  # already registered
		if GameState.can_register_for_championship(champ.id):
			if GameState.register_for_championship(champ.id):
				registered_count += 1
		else:
			failed.append(champ.championship_name)
	_refresh_list()
	if registered_count > 0:
		GameState.add_notification("Normal",
			"Re-registered for %d championship%s." % [registered_count, "s" if registered_count != 1 else ""])
	if not failed.is_empty():
		GameState.add_notification("High",
			"Could not re-register for: %s (check deadline/funds)." % ", ".join(failed))

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _fmt(n: int) -> String:
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
