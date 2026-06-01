extends Control

var sp_input: LineEdit
var fuel_input: LineEdit
var part_inputs: Dictionary = {}  # part_name → LineEdit

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
	layout.add_theme_constant_override("separation", 16)
	add_child(layout)

	# Header
	var header_row = HBoxContainer.new()
	layout.add_child(header_row)

	var title = Label.new()
	title.text = "📦 LOGISTICS CENTER"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(title)

	var back_btn = Button.new()
	back_btn.text = "← Back to Campus"
	back_btn.custom_minimum_size = Vector2(150, 40)
	back_btn.pressed.connect(_on_back_pressed)
	header_row.add_child(back_btn)

	layout.add_child(HSeparator.new())

	# Current stocks
	var stocks_title = Label.new()
	stocks_title.text = "CURRENT STOCKS"
	stocks_title.add_theme_font_size_override("font_size", 16)
	stocks_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	layout.add_child(stocks_title)

	var stocks_row = HBoxContainer.new()
	stocks_row.add_theme_constant_override("separation", 40)
	layout.add_child(stocks_row)

	var cr_color = Color(0.4, 0.9, 0.4) if GameState.player_team.balance >= 0 else Color(1.0, 0.3, 0.3)
	stocks_row.add_child(_make_stock_box("💰 Credits (CR)",
		"$%s" % _fmt(GameState.player_team.balance), cr_color))

	var sp_warn = GameState.spare_parts < GameState.active_championship.sp_per_10_pct_damage
	stocks_row.add_child(_make_stock_box("🔧 Spare Parts (SP)",
		"%d units" % GameState.spare_parts,
		Color(1.0, 0.3, 0.3) if sp_warn else Color(1.0, 0.8, 0.4)))

	var fuel_warn = GameState.fuel_kg < GameState.active_championship.fuel_per_car_per_race
	stocks_row.add_child(_make_stock_box("⛽ Fuel (FU)",
		"%.1f kg" % GameState.fuel_kg,
		Color(1.0, 0.3, 0.3) if fuel_warn else Color(1.0, 0.5, 0.3)))

	layout.add_child(HSeparator.new())

	# Purchase title
	var purchase_title = Label.new()
	purchase_title.text = "PURCHASE"
	purchase_title.add_theme_font_size_override("font_size", 16)
	purchase_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	layout.add_child(purchase_title)

	# Championship context line
	var cars = GameState.player_team.drivers.size()
	var fuel_per_race = GameState.active_championship.fuel_per_car_per_race
	var sp_per_10 = GameState.active_championship.sp_per_10_pct_damage
	var champ_note = Label.new()
	champ_note.text = "%s  —  SP: $1/unit  |  Fuel: $2/kg  |  %d car%s × %.0f kg/race = %.0f kg per weekend" % [
		GameState.active_championship.championship_name,
		cars, "s" if cars != 1 else "",
		fuel_per_race, fuel_per_race * cars]
	champ_note.add_theme_font_size_override("font_size", 13)
	champ_note.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	champ_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(champ_note)

	var purchase_row = HBoxContainer.new()
	purchase_row.add_theme_constant_override("separation", 30)
	layout.add_child(purchase_row)

	purchase_row.add_child(_make_purchase_card_sp(sp_per_10, cars))
	purchase_row.add_child(_make_purchase_card_fuel(fuel_per_race, cars))
	purchase_row.add_child(_make_purchase_card_parts())

	layout.add_child(HSeparator.new())

	var cfo_note = Label.new()
	cfo_note.text = "💼 CFO proposals for fuel hedging and bulk part ordering coming in a future update."
	cfo_note.add_theme_font_size_override("font_size", 13)
	cfo_note.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	cfo_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(cfo_note)


func _make_purchase_card_sp(sp_per_10: int, _cars: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🔧 Buy Spare Parts"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	vbox.add_child(title)

	var info = Label.new()
	info.text = "Used for car repairs after races. %d SP repairs 10%% damage." % sp_per_10
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)

	# Input row
	var input_row = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	vbox.add_child(input_row)

	var input_label = Label.new()
	input_label.text = "Amount:"
	input_label.add_theme_font_size_override("font_size", 13)
	input_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	input_row.add_child(input_label)

	sp_input = LineEdit.new()
	sp_input.placeholder_text = "e.g. 500"
	sp_input.custom_minimum_size = Vector2(120, 32)
	input_row.add_child(sp_input)

	var units_label = Label.new()
	units_label.text = "units"
	units_label.add_theme_font_size_override("font_size", 13)
	units_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	input_row.add_child(units_label)

	# Cost preview
	var cost_label = Label.new()
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	vbox.add_child(cost_label)

	sp_input.text_changed.connect(func(new_text: String):
		var amt = int(new_text) if new_text.is_valid_int() and int(new_text) > 0 else 0
		cost_label.text = "Cost: $%d" % amt if amt > 0 else ""
	)

	# Presets
	var preset_label = Label.new()
	preset_label.text = "Quick fill:"
	preset_label.add_theme_font_size_override("font_size", 12)
	preset_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(preset_label)

	var preset_row = HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	vbox.add_child(preset_row)

	var repair_1car: int = sp_per_10 * 10
	var repair_3: int = repair_1car * 3
	var season_stock: int = repair_1car * GameState.active_championship.num_races

	var btn1 = _make_preset_btn("1 Repair\n%d SP" % repair_1car, func():
		sp_input.text = str(repair_1car)
		sp_input.text_changed.emit(sp_input.text)
	)
	preset_row.add_child(btn1)

	var btn3 = _make_preset_btn("3 Repairs\n%d SP" % repair_3, func():
		sp_input.text = str(repair_3)
		sp_input.text_changed.emit(sp_input.text)
	)
	preset_row.add_child(btn3)

	var btn_season = _make_preset_btn("Season\n%d SP" % season_stock, func():
		sp_input.text = str(season_stock)
		sp_input.text_changed.emit(sp_input.text)
	)
	preset_row.add_child(btn_season)

	# Buy button
	var buy_btn = Button.new()
	buy_btn.text = "Buy Spare Parts →"
	buy_btn.custom_minimum_size = Vector2(260, 38)
	buy_btn.add_theme_font_size_override("font_size", 14)
	buy_btn.pressed.connect(_on_buy_sp_pressed)
	vbox.add_child(buy_btn)

	return panel


func _make_purchase_card_fuel(fuel_per_race: float, cars: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "⛽ Buy Fuel"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	vbox.add_child(title)

	var info = Label.new()
	info.text = "%.0f kg per car per race. %d car%s = %.0f kg per weekend." % [
		fuel_per_race, cars, "s" if cars != 1 else "", fuel_per_race * cars]
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)

	# Input row
	var input_row = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 8)
	vbox.add_child(input_row)

	var input_label = Label.new()
	input_label.text = "Amount:"
	input_label.add_theme_font_size_override("font_size", 13)
	input_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	input_row.add_child(input_label)

	fuel_input = LineEdit.new()
	fuel_input.placeholder_text = "e.g. 60"
	fuel_input.custom_minimum_size = Vector2(120, 32)
	input_row.add_child(fuel_input)

	var units_label = Label.new()
	units_label.text = "kg"
	units_label.add_theme_font_size_override("font_size", 13)
	units_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	input_row.add_child(units_label)

	# Cost preview
	var cost_label = Label.new()
	cost_label.add_theme_font_size_override("font_size", 12)
	cost_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	vbox.add_child(cost_label)

	fuel_input.text_changed.connect(func(new_text: String):
		var amt = float(new_text) if new_text.is_valid_float() and float(new_text) > 0.0 else 0.0
		cost_label.text = "Cost: $%.0f" % (amt * 2.0) if amt > 0.0 else ""
	)

	# Presets
	var preset_label = Label.new()
	preset_label.text = "Quick fill:"
	preset_label.add_theme_font_size_override("font_size", 12)
	preset_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(preset_label)

	var preset_row = HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	vbox.add_child(preset_row)

	var one_race: float = fuel_per_race * cars
	var three_races: float = one_race * 3.0
	var season_fuel: float = one_race * GameState.active_championship.num_races

	var btn1 = _make_preset_btn("1 Race\n%.0f kg" % one_race, func():
		fuel_input.text = "%.0f" % one_race
		fuel_input.text_changed.emit(fuel_input.text)
	)
	preset_row.add_child(btn1)

	var btn3 = _make_preset_btn("3 Races\n%.0f kg" % three_races, func():
		fuel_input.text = "%.0f" % three_races
		fuel_input.text_changed.emit(fuel_input.text)
	)
	preset_row.add_child(btn3)

	var btn_season = _make_preset_btn("Season\n%.0f kg" % season_fuel, func():
		fuel_input.text = "%.0f" % season_fuel
		fuel_input.text_changed.emit(fuel_input.text)
	)
	preset_row.add_child(btn_season)

	# Buy button
	var buy_btn = Button.new()
	buy_btn.text = "Buy Fuel →"
	buy_btn.custom_minimum_size = Vector2(260, 38)
	buy_btn.add_theme_font_size_override("font_size", 14)
	buy_btn.pressed.connect(_on_buy_fuel_pressed)
	vbox.add_child(buy_btn)

	return panel


func _make_preset_btn(label: String, on_press: Callable) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(90, 50)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(on_press)
	return btn


func _make_stock_box(label_text: String, value_text: String, value_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 80)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(lbl)

	var val = Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 22)
	val.add_theme_color_override("font_color", value_color)
	vbox.add_child(val)

	return panel


func _fmt(n: float) -> String:
	if abs(n) >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif abs(n) >= 1000:
		return "%.1fK" % (n / 1000.0)
	else:
		return "%.0f" % n


func _on_buy_sp_pressed() -> void:
	var text = sp_input.text.strip_edges()
	if not text.is_valid_int() or int(text) <= 0:
		_show_error("Please enter a valid amount of spare parts.")
		return
	if GameState.buy_spare_parts(int(text)):
		get_tree().change_scene_to_file("res://scenes/Logistics.tscn")


func _on_buy_fuel_pressed() -> void:
	var text = fuel_input.text.strip_edges()
	if not text.is_valid_float() or float(text) <= 0.0:
		_show_error("Please enter a valid fuel amount in kg.")
		return
	if GameState.buy_fuel(float(text)):
		get_tree().change_scene_to_file("res://scenes/Logistics.tscn")


func _make_purchase_card_parts() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🔩 Buy Car Parts"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(title)

	var info = Label.new()
	info.text = "Stock replacement parts. CFO warns when any part ≤ 2.\nPart failure with no stock = DNF."
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)

	vbox.add_child(HSeparator.new())

	var costs = GameState.PART_COSTS.get(GameState.active_championship.id, {})
	var champ_id = GameState.active_championship.id

	for part in GameState.PARTS_LIST:
		var stock = GameState.get_part_stock(part)
		var cost = costs.get(part, 0)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		# Part name + stock
		var name_lbl = Label.new()
		name_lbl.text = part
		name_lbl.custom_minimum_size = Vector2(85, 0)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.35, 0.35) if stock <= 2 else Color(0.85, 0.85, 0.85))
		row.add_child(name_lbl)

		# Stock badge
		var stock_lbl = Label.new()
		stock_lbl.text = "x%d" % stock
		stock_lbl.custom_minimum_size = Vector2(28, 0)
		stock_lbl.add_theme_font_size_override("font_size", 12)
		stock_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.4, 0.4) if stock <= 2 else Color(0.5, 0.9, 0.5))
		row.add_child(stock_lbl)

		# Cost label
		var cost_lbl = Label.new()
		cost_lbl.text = "$%s ea" % _fmt(float(cost))
		cost_lbl.custom_minimum_size = Vector2(72, 0)
		cost_lbl.add_theme_font_size_override("font_size", 11)
		cost_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		row.add_child(cost_lbl)

		# Qty input
		var input = LineEdit.new()
		input.placeholder_text = "qty"
		input.custom_minimum_size = Vector2(48, 28)
		input.text = ""
		row.add_child(input)
		part_inputs[part] = input

		# Buy button
		var buy_btn = Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(48, 28)
		var _part = part
		buy_btn.pressed.connect(func(): _on_buy_part_pressed(_part))
		row.add_child(buy_btn)

	vbox.add_child(HSeparator.new())

	# Preset row — buy N of all parts at once
	var preset_lbl = Label.new()
	preset_lbl.text = "Buy all parts:"
	preset_lbl.add_theme_font_size_override("font_size", 12)
	preset_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(preset_lbl)

	var preset_row = HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	vbox.add_child(preset_row)

	for qty in [1, 3, 5]:
		var btn = _make_preset_btn("+%d each" % qty, func():
			for p in GameState.PARTS_LIST:
				if p in part_inputs:
					part_inputs[p].text = str(qty)
		)
		preset_row.add_child(btn)

	return panel


func _on_buy_part_pressed(part_name: String) -> void:
	if not part_name in part_inputs:
		return
	var text = part_inputs[part_name].text.strip_edges()
	if not text.is_valid_int() or int(text) <= 0:
		_show_error("Enter a valid quantity for %s." % part_name)
		return
	if GameState.buy_part(part_name, int(text)):
		get_tree().change_scene_to_file("res://scenes/Logistics.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")


func _show_error(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Invalid Input"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			var screenshot = get_viewport().get_texture().get_image()
			var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
			var path = "user://screenshot_%s.png" % timestamp
			screenshot.save_png(path)
			print("Screenshot saved: " + path)
