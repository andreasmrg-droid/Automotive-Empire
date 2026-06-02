extends Control

@onready var title_label = $Layout/HeaderRow/TitleLabel
@onready var back_button = $Layout/HeaderRow/BackButton
@onready var zones_box = $Layout/ScrollContainer/ZonesBox

const ZONE_COLORS = {
	"Command":          Color(0.2, 0.4, 0.6),
	"Engineering":      Color(0.4, 0.2, 0.6),
	"Simulation":       Color(0.2, 0.5, 0.4),
	"Commercial":       Color(0.5, 0.4, 0.1),
	"Human Performance":Color(0.5, 0.2, 0.2),
	"Test Tracks":      Color(0.2, 0.4, 0.2),
}

const BUILDING_ICONS = {
	"Headquarters":           "🏛",
	"Logistics Center":       "📦",
	"Garage":                 "🔧",
	"Racing Department":      "🏎",
	"R&D Design Studio":      "🔬",
	"CNC Parts Plant":        "⚙",
	"Ops Sim & Telemetry":    "📡",
	"Aerodynamic Wind Tunnel":"💨",
	"Vehicle Assembly Factory":"🏭",
	"Museum":                 "🏆",
	"Theme Park":             "🎡",
	"Public Racing Club":     "🏁",
	"Merchandise Store":      "👕",
	"Fitness Clinic":         "💪",
	"Pit Crew Arena":         "⏱",
	"Academy":                "🎓",
	"Karting Track":          "🔵",
	"Gravel Track":           "🟤",
	"Oval Track":             "🟡",
	"Race Track":             "🔴",
}

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var layout = $Layout
	layout.anchor_right = 1.0
	layout.anchor_bottom = 1.0
	layout.offset_left = 16
	layout.offset_top = 16
	layout.offset_right = -16
	layout.offset_bottom = -16

	# Header
	title_label.text = "🏗 CAMPUS"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	back_button.text = "← Back to Hub"
	back_button.custom_minimum_size = Vector2(150, 40)
	back_button.pressed.connect(_on_back_pressed)

	# ScrollContainer fills remaining space — full width
	var scroll = $Layout/ScrollContainer
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	# ZonesBox — full width, cards wrap naturally
	zones_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zones_box.add_theme_constant_override("separation", 16)

	_build_campus()

func _build_campus() -> void:
	for child in zones_box.get_children():
		child.queue_free()

	for zone_name in GameState.campus_zones:
		_build_zone(zone_name, GameState.campus_zones[zone_name])

func _build_zone(zone_name: String, buildings: Array) -> void:
	# Zone header — full width label
	var zone_label = Label.new()
	zone_label.text = "━━━  %s  ━━━" % zone_name.to_upper()
	zone_label.add_theme_font_size_override("font_size", 14)
	zone_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var zone_color = ZONE_COLORS.get(zone_name, Color(0.5, 0.5, 0.5))
	zone_label.add_theme_color_override("font_color", zone_color)
	zones_box.add_child(zone_label)

	# Building cards wrap across full width
	var grid = HFlowContainer.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	zones_box.add_child(grid)

	for building_id in buildings:
		var card = _build_card(building_id)
		grid.add_child(card)

func _build_card(building_id: String) -> PanelContainer:
	var building = GameState.get_building(building_id)
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 0)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	# Building name row
	var name_row = HBoxContainer.new()
	vbox.add_child(name_row)

	var icon_label = Label.new()
	var icon = BUILDING_ICONS.get(building["name"], "🏢")
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 20)
	name_row.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = " " + building["name"]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)

	# Level / status
	var status_label = Label.new()
	if building["built"]:
		if building["construction_weeks_remaining"] > 0:
			status_label.text = "🔨 Under Construction — %d weeks remaining" % building["construction_weeks_remaining"]
			status_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		else:
			status_label.text = "Level %d / %d" % [building["level"], building["max_level"]]
			status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		status_label.text = "Not Built"
		status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(status_label)

	# Effects
	if building["built"] and building["construction_weeks_remaining"] == 0:
		var effects_label = Label.new()
		effects_label.text = building["effects"]
		effects_label.add_theme_font_size_override("font_size", 11)
		effects_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effects_label.custom_minimum_size = Vector2(260, 0)
		vbox.add_child(effects_label)

	# Finance row
	var finance_label = Label.new()
	var finance_text = ""
	if building["built"] and building["level"] >= 1:
		var cur_maintenance = GameState.get_building_maintenance(building)
		var cur_income      = GameState.get_building_income(building)
		if cur_maintenance > 0:
			finance_text += "💸 -CR %d/wk" % cur_maintenance
		if cur_income > 0:
			finance_text += "  💰 +CR %d/wk" % cur_income
	if finance_text != "":
		finance_label.text = finance_text
		finance_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(finance_label)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Action button
	var action_btn = Button.new()
	action_btn.custom_minimum_size = Vector2(260, 35)

	if not building["built"]:
		var can_afford = GameState.player_team.balance >= building["build_cost"]
		action_btn.text = "Build — CR %d (%d wks)" % [building["build_cost"], building["build_time"]]
		action_btn.disabled = not can_afford
		if not can_afford:
			action_btn.text += " [Need CR %d more]" % (building["build_cost"] - int(GameState.player_team.balance))
		action_btn.pressed.connect(_on_build_pressed.bind(building_id))

	elif building["construction_weeks_remaining"] > 0:
		action_btn.text = "Under Construction..."
		action_btn.disabled = true

	elif building["level"] >= building["max_level"]:
		action_btn.text = "✅ Max Level Reached"
		action_btn.disabled = true

	else:
		var scaled_cost = GameState.get_upgrade_cost(building)
		var scaled_time = GameState.get_upgrade_time(building)
		var can_afford  = GameState.player_team.balance >= scaled_cost
		action_btn.text = "Upgrade to Lv%d — CR %d (%d wks)" % [
			building["level"] + 1,
			scaled_cost,
			scaled_time
		]
		action_btn.disabled = not can_afford
		action_btn.pressed.connect(_on_upgrade_pressed.bind(building_id))

	vbox.add_child(action_btn)

	# ── Building-specific action buttons ─────────────────────

	# Logistics Center — always accessible once built
	if building["name"] == "Logistics Center" and building["built"] and building["level"] >= 1:
		var open_btn = Button.new()
		open_btn.text = "📦 Enter Logistics Center"
		open_btn.custom_minimum_size = Vector2(260, 35)
		open_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/Logistics.tscn"))
		vbox.add_child(open_btn)

	# HQ — Enter building scene
	if building["name"] == "Headquarters" and building["built"] and building["level"] >= 1:
		var hq_btn = Button.new()
		hq_btn.text = "🏛 Enter HQ"
		hq_btn.custom_minimum_size = Vector2(260, 35)
		hq_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/HQ.tscn"))
		vbox.add_child(hq_btn)

	# Garage — Enter building scene
	if building["name"] == "Garage" and building["built"] and building["level"] >= 1:
		var garage_btn = Button.new()
		garage_btn.text = "🔧 Enter Garage"
		garage_btn.custom_minimum_size = Vector2(260, 35)
		garage_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/Garage.tscn"))
		vbox.add_child(garage_btn)

	# Racing Department — Enter building scene
	if building["name"] == "Racing Department" and building["built"] and building["level"] >= 1:
		var rd_btn = Button.new()
		rd_btn.text = "🏎 Enter Racing Department"
		rd_btn.custom_minimum_size = Vector2(260, 35)
		rd_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/RacingDept.tscn"))
		vbox.add_child(rd_btn)

	# ── All remaining buildings with scenes ──────────────────────────────────
	const BUILDING_SCENES = {
		"Ops Sim & Telemetry":     "res://scenes/buildings/OpsSim.tscn",
		"Pit Crew Arena":          "res://scenes/buildings/PitCrewArena.tscn",
		"Museum":                  "res://scenes/buildings/Museum.tscn",
		"Theme Park":              "res://scenes/buildings/ThemePark.tscn",
		"Public Racing Club":      "res://scenes/buildings/PublicRacingClub.tscn",
		"Merchandise Store":       "res://scenes/buildings/MerchandiseStore.tscn",
		"Fitness Clinic":          "res://scenes/buildings/FitnessClinic.tscn",
		"Academy":                 "res://scenes/buildings/Academy.tscn",
		"R&D Design Studio":       "res://scenes/buildings/RnDStudio.tscn",
		"CNC Parts Plant":         "res://scenes/buildings/CNCPlant.tscn",
		"Aerodynamic Wind Tunnel": "res://scenes/buildings/AeroWindTunnel.tscn",
		"Vehicle Assembly Factory":"res://scenes/buildings/VehicleFactory.tscn",
		"Karting Track":           "res://scenes/buildings/KartingTrack.tscn",
		"Gravel Track":            "res://scenes/buildings/GravelTrack.tscn",
		"Oval Track":              "res://scenes/buildings/OvalTrack.tscn",
		"Race Track":              "res://scenes/buildings/RaceTrack.tscn",
	}

	var bname = building["name"]
	if bname in BUILDING_SCENES and building["built"] and building["level"] >= 1:
		var bicon = BUILDING_ICONS.get(bname, "🏢")
		var enter_btn = Button.new()
		enter_btn.text = "%s Enter %s" % [bicon, bname]
		enter_btn.custom_minimum_size = Vector2(260, 35)
		var scene_path = BUILDING_SCENES[bname]
		enter_btn.pressed.connect(func(): get_tree().change_scene_to_file(scene_path))
		vbox.add_child(enter_btn)

	return card

func _on_build_pressed(building_id: String) -> void:
	GameState.start_building(building_id)
	_build_campus()

func _on_upgrade_pressed(building_id: String) -> void:
	GameState.start_upgrade(building_id)
	_build_campus()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			var screenshot = get_viewport().get_texture().get_image()
			var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
			var path = "user://screenshot_%s.png" % timestamp
			screenshot.save_png(path)
			print("Screenshot saved: " + path)
