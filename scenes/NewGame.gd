extends Control

var team_name_input: LineEdit
var player_name_input: LineEdit
var nationality_option: OptionButton
var start_button: Button
var preview_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Root layout
	var layout = VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 0
	layout.offset_top = 0
	layout.offset_right = 0
	layout.offset_bottom = 0
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 20)
	add_child(layout)

	# Title
	var title = Label.new()
	title.text = "🏁 AUTOMOTIVE EMPIRE"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Found your motorsport empire"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(subtitle)

	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	layout.add_child(spacer1)

	# Form container - centered column
	var form_center = HBoxContainer.new()
	form_center.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(form_center)

	var form_box = VBoxContainer.new()
	form_box.custom_minimum_size = Vector2(500, 0)
	form_box.add_theme_constant_override("separation", 16)
	form_center.add_child(form_box)

	# Team name
	var team_label = Label.new()
	team_label.text = "🏎  Team Name"
	team_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	form_box.add_child(team_label)

	team_name_input = LineEdit.new()
	team_name_input.placeholder_text = "e.g. Apex Racing"
	team_name_input.custom_minimum_size = Vector2(500, 45)
	team_name_input.add_theme_font_size_override("font_size", 18)
	form_box.add_child(team_name_input)

	# CEO name
	var ceo_label = Label.new()
	ceo_label.text = "👤  Your Name (CEO)"
	ceo_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	form_box.add_child(ceo_label)

	player_name_input = LineEdit.new()
	player_name_input.placeholder_text = "Your name"
	player_name_input.custom_minimum_size = Vector2(500, 45)
	player_name_input.add_theme_font_size_override("font_size", 18)
	form_box.add_child(player_name_input)

	# Nationality
	var nat_label = Label.new()
	nat_label.text = "🌍  Team Nationality"
	nat_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	form_box.add_child(nat_label)

	nationality_option = OptionButton.new()
	nationality_option.custom_minimum_size = Vector2(500, 45)
	nationality_option.add_theme_font_size_override("font_size", 16)
	form_box.add_child(nationality_option)

	# Populate nationalities
	var nats = NameData.data.keys()
	nats.sort()
	for nat in nats:
		nationality_option.add_item(nat)
	for i in range(nats.size()):
		if nats[i] == "British":
			nationality_option.select(i)
			break

	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	form_box.add_child(spacer2)

	# Preview box
	var preview_bg = PanelContainer.new()
	preview_bg.custom_minimum_size = Vector2(500, 0)
	form_box.add_child(preview_bg)

	var preview_vbox = VBoxContainer.new()
	preview_vbox.add_theme_constant_override("separation", 6)
	preview_bg.add_child(preview_vbox)

	var preview_title = Label.new()
	preview_title.text = "PREVIEW"
	preview_title.add_theme_font_size_override("font_size", 12)
	preview_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	preview_vbox.add_child(preview_title)

	preview_label = Label.new()
	preview_label.add_theme_font_size_override("font_size", 15)
	preview_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_vbox.add_child(preview_label)

	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	layout.add_child(spacer3)

	# Start button
	var btn_center = HBoxContainer.new()
	btn_center.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(btn_center)

	start_button = Button.new()
	start_button.text = "🏁  START GAME"
	start_button.custom_minimum_size = Vector2(300, 60)
	start_button.add_theme_font_size_override("font_size", 22)
	btn_center.add_child(start_button)

	# Connect signals
	team_name_input.text_changed.connect(_on_input_changed)
	player_name_input.text_changed.connect(_on_input_changed)
	nationality_option.item_selected.connect(_on_nationality_changed)
	start_button.pressed.connect(_on_start_pressed)

	_update_preview()

func _on_input_changed(_text: String) -> void:
	_update_preview()

func _on_nationality_changed(_index: int) -> void:
	_update_preview()

func _update_preview() -> void:
	var nat = nationality_option.get_item_text(nationality_option.selected)
	var d1 = NameGenerator.get_full_name(nat, "Male")
	var d2 = NameGenerator.get_full_name(nat, "Female")
	NameGenerator.release_name(d1["full"])
	NameGenerator.release_name(d2["full"])

	var team = team_name_input.text.strip_edges()
	if team == "":
		team = "Your Team"
	var ceo = player_name_input.text.strip_edges()
	if ceo == "":
		ceo = "CEO"

	preview_label.text = "Team:      %s\nCEO:       %s\n\nDriver 1:  %s\nDriver 2:  %s\n\nStarting:  GK Regional Championship" % [
		team, ceo, d1["full"], d2["full"]
	]

func _on_start_pressed() -> void:
	var team_name = team_name_input.text.strip_edges()
	var player_name = player_name_input.text.strip_edges()
	var nat = nationality_option.get_item_text(nationality_option.selected)

	if team_name == "":
		team_name = "My Racing Team"
	if player_name == "":
		player_name = "CEO"

	GameState.setup_new_game(team_name, nat, player_name)
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")
