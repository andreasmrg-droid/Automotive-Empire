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

	# Column headers using HBoxContainer
	var header_row = HBoxContainer.new()
	header_row.custom_minimum_size = Vector2(900, 0)
	results_box.add_child(header_row)

	for col in [["POS", 80], ["DRIVER", 200], ["TEAM", 180], ["TIME", 120], ["GAP", 120], ["PTS", 60]]:
		var lbl = Label.new()
		lbl.text = col[0]
		lbl.custom_minimum_size = Vector2(col[1], 0)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		header_row.add_child(lbl)

	var sep = HSeparator.new()
	results_box.add_child(sep)

	var leader_time = 0.0
	if GameState.last_race_results.size() > 0:
		leader_time = GameState.last_race_results[0]["total_time"]

	var player_ids = GameState.player_team.drivers

	for i in range(GameState.last_race_results.size()):
		var entry = GameState.last_race_results[i]
		var driver = entry["driver"]
		var standing_position = i + 1
		var total_time = entry["total_time"]
		var points = entry["points"]

		var gap_text = ""
		if standing_position == 1:
			gap_text = "LEADER"
		else:
			gap_text = "+%.3fs" % (total_time - leader_time)

		var team_name = "Unknown"
		for team in GameState.all_teams:
			if driver.id in team.drivers:
				team_name = team.team_name
				break

		var pos_text = ""
		if standing_position == 1:
			pos_text = "🥇"
		elif standing_position == 2:
			pos_text = "🥈"
		elif standing_position == 3:
			pos_text = "🥉"
		else:
			pos_text = "P%d" % standing_position

		var is_player = driver.id in player_ids

		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(900, 0)

		var color = Color.WHITE
		if is_player:
			color = Color(0.4, 0.8, 1.0)
		elif standing_position == 1:
			color = Color(1.0, 0.84, 0.0)
		elif standing_position == 2:
			color = Color(0.75, 0.75, 0.75)
		elif standing_position == 3:
			color = Color(0.8, 0.5, 0.2)

		for col in [
			[pos_text, 80],
			[driver.full_name(), 200],
			[team_name, 180],
			[_format_race_time(total_time), 120],
			[gap_text, 120],
			["%d pts" % points, 60]
		]:
			var lbl = Label.new()
			lbl.text = col[0]
			lbl.custom_minimum_size = Vector2(col[1], 0)
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", color)
			row.add_child(lbl)

		results_box.add_child(row)

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _format_race_time(seconds: float) -> String:
	var h = int(seconds / 3600)
	var m = int(fmod(seconds, 3600) / 60)
	var s = int(fmod(seconds, 60))
	var ms = int(fmod(seconds, 1) * 1000)
	if h > 0:
		return "%d:%02d:%02d.%03d" % [h, m, s, ms]
	else:
		return "%d:%02d.%03d" % [m, s, ms]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			var screenshot = get_viewport().get_texture().get_image()
			var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
			var path = "user://screenshot_%s.png" % timestamp
			screenshot.save_png(path)
			print("Screenshot saved: " + path)
