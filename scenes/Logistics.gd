extends Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	# Root layout
	var layout = VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 20
	layout.offset_top = 20
	layout.offset_right = -20
	layout.offset_bottom = -20
	layout.add_theme_constant_override("separation", 16)
	add_child(layout)

	# Header row
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

	var sep = HSeparator.new()
	layout.add_child(sep)

	# Current stocks panel
	var stocks_title = Label.new()
	stocks_title.text = "CURRENT STOCKS"
	stocks_title.add_theme_font_size_override("font_size", 16)
	stocks_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	layout.add_child(stocks_title)

	var stocks_row = HBoxContainer.new()
	stocks_row.add_theme_constant_override("separation", 40)
	layout.add_child(stocks_row)

	# CR
	var cr_box = _make_stock_box(
		"💰 Credits (CR)",
		"$%s" % _fmt(GameState.player_team.balance),
		Color(0.4, 0.9, 0.4) if GameState.player_team.balance >= 0 else Color(1.0, 0.3, 0.3)
	)
	stocks_row.add_child(cr_box)

	# SP
	var sp_color = Color(1.0, 0.3, 0.3) if GameState.spare_parts < 120 else Color(1.0, 0.8, 0.4)
	var sp_box = _make_stock_box(
		"🔧 Spare Parts (SP)",
		"%d units" % GameState.spare_parts,
		sp_color
	)
	stocks_row.add_child(sp_box)

	# FU
	var fu_color = Color(1.0, 0.3, 0.3) if GameState.fuel_kg < 15.0 else Color(1.0, 0.5, 0.3)
	var fu_box = _make_stock_box(
		"⛽ Fuel (FU)",
		"%.1f kg" % GameState.fuel_kg,
		fu_color
	)
	stocks_row.add_child(fu_box)

	var sep2 = HSeparator.new()
	layout.add_child(sep2)

	# Purchase section
	var purchase_title = Label.new()
	purchase_title.text = "PURCHASE"
	purchase_title.add_theme_font_size_override("font_size", 16)
	purchase_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	layout.add_child(purchase_title)

	var champ_note = Label.new()
	champ_note.text = "GK Regional Championship  —  SP: $1/unit  |  Fuel: $2/kg"
	champ_note.add_theme_font_size_override("font_size", 13)
	champ_note.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	layout.add_child(champ_note)

	var purchase_row = HBoxContainer.new()
	purchase_row.add_theme_constant_override("separation", 30)
	layout.add_child(purchase_row)

	# SP purchase card
	purchase_row.add_child(_make_purchase_card_sp())

	# Fuel purchase card
	purchase_row.add_child(_make_purchase_card_fuel())

	# CFO note
	var sep3 = HSeparator.new()
	layout.add_child(sep3)

	var cfo_note = Label.new()
	cfo_note.text = "💼 CFO proposals for fuel hedging and bulk part ordering coming in a future update."
	cfo_note.add_theme_font_size_override("font_size", 13)
	cfo_note.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	cfo_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(cfo_note)

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

func _make_purchase_card_sp() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🔧 Buy Spare Parts"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	vbox.add_child(title)

	var info = Label.new()
	info.text = "Each race consumes 120 units base.\n+100 units per 10% car damage."
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)

	# Quick buy buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	for amount in [120, 240, 480]:
		var btn = Button.new()
		btn.text = "+%d units\n$%d" % [amount, amount]
		btn.custom_minimum_size = Vector2(95, 55)
		btn.pressed.connect(_on_buy_sp.bind(amount))
		btn_row.add_child(btn)

	return panel

func _make_purchase_card_fuel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(340, 0)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "⛽ Buy Fuel"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	vbox.add_child(title)

	var info = Label.new()
	info.text = "GK Regional uses 15 kg per car per race.\n2 cars = 30 kg per race weekend."
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(info)

	# Quick buy buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	for kg in [30, 60, 120]:
		var btn = Button.new()
		btn.text = "+%d kg\n$%d" % [kg, kg * 2]
		btn.custom_minimum_size = Vector2(95, 55)
		btn.pressed.connect(_on_buy_fuel.bind(float(kg)))
		btn_row.add_child(btn)

	return panel

func _on_buy_sp(amount: int) -> void:
	var success = GameState.buy_spare_parts(amount)
	if success:
		get_tree().change_scene_to_file("res://scenes/Logistics.tscn")

func _on_buy_fuel(kg: float) -> void:
	var success = GameState.buy_fuel(kg)
	if success:
		get_tree().change_scene_to_file("res://scenes/Logistics.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

func _fmt(n: float) -> String:
	if abs(n) >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif abs(n) >= 1000:
		return "%.1fK" % (n / 1000.0)
	else:
		return "%.0f" % n

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			var screenshot = get_viewport().get_texture().get_image()
			var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
			var path = "user://screenshot_%s.png" % timestamp
			screenshot.save_png(path)
			print("Screenshot saved: " + path)
