extends Control

@onready var header_label = $Layout/HeaderLabel
@onready var track_label = $Layout/TrackLabel
@onready var weather_label = $Layout/WeatherLabel
@onready var results_box = $Layout/ResultsContainer/ResultsBox
@onready var continue_button = $Layout/ContinueButton

# Data passed from GameState
var race_data: Dictionary = {}
var results: Array = []
var is_wet: bool = false

func _ready() -> void:
	# Fill screen
	anchor_right = 1.0
	anchor_bottom = 1.0

	var layout = $Layout
	layout.anchor_right = 1.0
	layout.anchor_bottom = 1.0
	layout.offset_left = 20
	layout.offset_top = 20
	layout.offset_right = -20
	layout.offset_bottom = -20

	# Header styling
	header_label.add_theme_font_size_override("font_size", 28)
	header_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))

	# Results container expands
	var results_container = $Layout/ResultsContainer
	results_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# ResultsBox minimum width
	results_box.custom_minimum_size = Vector2(800, 0)

	# Continue button
	continue_button.custom_minimum_size = Vector2(200, 50)
	continue_button.add_theme_font_size_override("font_size", 18)
	continue_button.text = "Continue ▶"
	continue_button.pressed.connect(_on_continue_pressed)

	# Load data from GameState
	_display_results()

func _display_results() -> void:
	var round_num = GameState.last_race_round
	var track_name = GameState.last_race_name

	header_label.text = "🏁 RACE %d RESULTS" % round_num
	track_label.text = "📍 %s" % track_name

	if GameState.last_race_wet:
		weather_label.text = "🌧 Wet Race Conditions"
		weather_label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
	else:
		weather_label.text = "☀ Dry Conditions"
		weather_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))

	# Clear results box
	for child in results_box.get_children():
		child.queue_free()

	# Column header
	var header = Label.new()
	header.text = "%-4s  %-25s  %-20s  %-12s  %-8s  %s" % [
		"POS", "DRIVER", "TEAM", "TIME", "GAP", "PTS"
	]
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	header.custom_minimum_size = Vector2(800, 0)
	results_box.add_child(header)

	# Separator line
	var sep = HSeparator.new()
	results_box.add_child(sep)

	# Results rows
	var leader_time = 0.0
	if GameState.last_race_results.size() > 0:
		leader_time = GameState.last_race_results[0]["total_time"]

	var player_driver_id = ""
	if GameState.player_team.drivers.size() > 0:
		player_driver_id = GameState.player_team.drivers[0]

	for i in range(GameState.last_race_results.size()):
		var entry = GameState.last_race_results[i]
		var driver = entry["driver"]
		var standing_position = i + 1
		var total_time = entry["total_time"]
		var points = entry["points"]

		# Gap to leader
		var gap_text = ""
		if standing_position == 1:
			gap_text = "%.2fs" % total_time
		else:
			gap_text = "+%.2fs" % (total_time - leader_time)

		# Find team name
		var team_name = "Unknown"
		for team in GameState.all_teams:
			if driver.id in team.drivers:
				team_name = team.team_name
				break

		# Position medal/number
		var pos_text = ""
		if standing_position == 1:
			pos_text = "🥇"
		elif standing_position == 2:
			pos_text = "🥈"
		elif standing_position == 3:
			pos_text = "🥉"
		else:
			pos_text = "P%-2d" % standing_position

		var row = Label.new()
		row.text = "%-4s  %-25s  %-20s  %-12s  %-8s  %s pts" % [
			pos_text,
			driver.full_name(),
			team_name,
			"%.2fs" % total_time,
			gap_text,
			str(points)
		]
		row.custom_minimum_size = Vector2(800, 0)
		row.add_theme_font_size_override("font_size", 13)

		# Color coding
		var is_player = driver.id == player_driver_id
		if is_player:
			row.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		elif standing_position == 1:
			row.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		elif standing_position == 2:
			row.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		elif standing_position == 3:
			row.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))

		results_box.add_child(row)

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			var screenshot = get_viewport().get_texture().get_image()
			var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
			var path = "user://screenshot_%s.png" % timestamp
			screenshot.save_png(path)
			print("Screenshot saved: " + path)
