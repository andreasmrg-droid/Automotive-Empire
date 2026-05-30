class_name Championship
extends Resource

# Identity
@export var id: String = "C-001"
@export var championship_name: String = "GK Regional Championship"
@export var discipline: String = "Go-Karting"
@export var tier: int = 1

# Rules
@export var min_age: int = 8
@export var max_age: int = 16
@export var drivers_per_car: int = 1
@export var min_cars: int = 400
@export var optimum_cars: int = 440
@export var max_cars: int = 500
@export var entry_fee_per_race: float = 1500.0
@export var num_races: int = 6

# Points system
@export var points_system: Array[int] = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]

# Prize money
@export var prize_1st: float = 300.0
@export var prize_2nd: float = 150.0
@export var prize_3rd: float = 75.0

# Calendar
@export var calendar: Array[Dictionary] = []

# Driver standings - driver_id : points
@export var standings: Dictionary = {}

# Team standings - team_id : points
@export var team_standings: Dictionary = {}

# Results per round
@export var results: Dictionary = {}

@export var current_round: int = 0
@export var season: int = 1

func get_next_race() -> Dictionary:
	if current_round < calendar.size():
		return calendar[current_round]
	return {}

func is_season_finished() -> bool:
	return current_round >= num_races

func add_points(driver_id: String, points: int) -> void:
	if driver_id in standings:
		standings[driver_id] += points
	else:
		standings[driver_id] = points

func add_team_points(team_id: String, points: int) -> void:
	if team_id in team_standings:
		team_standings[team_id] += points
	else:
		team_standings[team_id] = points

func get_standings_sorted() -> Array:
	var sorted = []
	for driver_id in standings:
		sorted.append({"driver_id": driver_id, "points": standings[driver_id]})
	sorted.sort_custom(func(a, b): return a["points"] > b["points"])
	return sorted

func get_team_standings_sorted() -> Array:
	var sorted = []
	for team_id in team_standings:
		sorted.append({"team_id": team_id, "points": team_standings[team_id]})
	sorted.sort_custom(func(a, b): return a["points"] > b["points"])
	return sorted

func reset_for_new_season() -> void:
	standings = {}
	team_standings = {}
	results = {}
	current_round = 0
	season += 1
