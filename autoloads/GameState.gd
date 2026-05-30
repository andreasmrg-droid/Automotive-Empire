extends Node

# Time
var current_week: int = 1
var current_season: int = 1
var max_weeks: int = 52

# Player team
var player_team: Team = null

# All teams in the player's championship
var all_teams: Array = []

# All drivers in the player's championship
var all_drivers: Dictionary = {}

# The active championship
var active_championship: Championship = null

# Last race data - for results screen
var last_race_round: int = 0
var last_race_name: String = ""
var last_race_wet: bool = false
var last_race_results: Array = []

# Hall of fame
var hall_of_fame: Array = []

# Campus buildings state
var campus_buildings: Dictionary = {}

# Campus zones - defines layout order
var campus_zones: Dictionary = {
	"Command": ["Headquarters", "Logistics Center", "Garage", "Racing Department"],
	"Engineering": ["R&D Design Studio", "CNC Parts Plant"],
	"Simulation": ["Ops Sim & Telemetry", "Aerodynamic Wind Tunnel"],
	"Commercial": ["Vehicle Assembly Factory", "Museum", "Theme Park", "Public Racing Club", "Merchandise Store"],
	"Human Performance": ["Fitness Clinic", "Pit Crew Arena", "Academy"],
	"Test Tracks": ["Karting Track", "Gravel Track", "Oval Track", "Race Track"],
}

# Weekly log
var weekly_log: Array[String] = []

# Signals
signal week_advanced(week: int)
signal season_ended(season: int)
signal log_updated()

func _ready() -> void:
	setup_new_game()

func _setup_campus() -> void:
	campus_buildings = {
		"Headquarters": {
			"name": "Headquarters",
			"built": true,
			"level": 1,
			"max_level": 26,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1200,
			"weekly_income": 0,
			"build_cost": 0,
			"build_time": 0,
			"upgrade_cost": 45000,
			"upgrade_time": 8,
			"effects": "+1% Marketability per level\n+1 Sponsor Slot every 2 levels"
		},
		"Logistics Center": {
			"name": "Logistics Center",
			"built": true,
			"level": 1,
			"max_level": 24,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 950,
			"weekly_income": 0,
			"build_cost": 0,
			"build_time": 0,
			"upgrade_cost": 38000,
			"upgrade_time": 6,
			"effects": "+1% reduced price of spare parts per level"
		},
		"Garage": {
			"name": "Garage",
			"built": true,
			"level": 1,
			"max_level": 89,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1100,
			"weekly_income": 1800,
			"build_cost": 0,
			"build_time": 0,
			"upgrade_cost": 42000,
			"upgrade_time": 6,
			"effects": "+$1800 weekly repair profit\n+$450 per level"
		},
		"Racing Department": {
			"name": "Racing Department",
			"built": true,
			"level": 1,
			"max_level": 89,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 850,
			"weekly_income": 0,
			"build_cost": 0,
			"build_time": 0,
			"upgrade_cost": 30000,
			"upgrade_time": 5,
			"effects": "+10% Driver Morale & Focus\n+5% per level"
		},
		"R&D Design Studio": {
			"name": "R&D Design Studio",
			"built": false,
			"level": 0,
			"max_level": 27,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1600,
			"weekly_income": 0,
			"build_cost": 120000,
			"build_time": 40,
			"upgrade_cost": 65000,
			"upgrade_time": 12,
			"effects": "Unlocks R&D (800 RP storage)\n+400 RP & +1% R&D speed per level"
		},
		"CNC Parts Plant": {
			"name": "CNC Parts Plant",
			"built": false,
			"level": 0,
			"max_level": 24,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 2200,
			"weekly_income": 0,
			"build_cost": 150000,
			"build_time": 52,
			"upgrade_cost": 85000,
			"upgrade_time": 16,
			"effects": "Unlocks CNC production\n+4% speed & -1% material cost per level"
		},
		"Ops Sim & Telemetry": {
			"name": "Ops Sim & Telemetry",
			"built": false,
			"level": 0,
			"max_level": 30,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1350,
			"weekly_income": 0,
			"build_cost": 95000,
			"build_time": 24,
			"upgrade_cost": 52000,
			"upgrade_time": 10,
			"effects": "+25% baseline Track Knowledge\n+1% Track Knowledge gain per level"
		},
		"Aerodynamic Wind Tunnel": {
			"name": "Aerodynamic Wind Tunnel",
			"built": false,
			"level": 0,
			"max_level": 9,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1750,
			"weekly_income": 0,
			"build_cost": 140000,
			"build_time": 78,
			"upgrade_cost": 72000,
			"upgrade_time": 20,
			"effects": "+10% Aero efficiency\n+5% per level"
		},
		"Vehicle Assembly Factory": {
			"name": "Vehicle Assembly Factory",
			"built": false,
			"level": 0,
			"max_level": 12,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 2400,
			"weekly_income": 0,
			"build_cost": 220000,
			"build_time": 65,
			"upgrade_cost": 95000,
			"upgrade_time": 24,
			"effects": "Unlocks commercial car production\n+250 units/wk & +3% margin per level"
		},
		"Museum": {
			"name": "Museum",
			"built": false,
			"level": 0,
			"max_level": 5,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 750,
			"weekly_income": 2400,
			"build_cost": 50000,
			"build_time": 18,
			"upgrade_cost": 28000,
			"upgrade_time": 6,
			"effects": "+$2400 weekly passive income\n+$380 per level"
		},
		"Theme Park": {
			"name": "Theme Park",
			"built": false,
			"level": 0,
			"max_level": 5,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1100,
			"weekly_income": 5000,
			"build_cost": 180000,
			"build_time": 104,
			"upgrade_cost": 78000,
			"upgrade_time": 26,
			"effects": "+$5000 weekly passive income\n+$650 per level"
		},
		"Public Racing Club": {
			"name": "Public Racing Club",
			"built": false,
			"level": 0,
			"max_level": 7,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 850,
			"weekly_income": 1600,
			"build_cost": 60000,
			"build_time": 14,
			"upgrade_cost": 32000,
			"upgrade_time": 8,
			"effects": "+$1600 weekly passive income\n+$280 per level"
		},
		"Merchandise Store": {
			"name": "Merchandise Store",
			"built": false,
			"level": 0,
			"max_level": 5,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 650,
			"weekly_income": 3000,
			"build_cost": 40000,
			"build_time": 10,
			"upgrade_cost": 22000,
			"upgrade_time": 5,
			"effects": "+$3000 weekly passive income\n+$420 per level"
		},
		"Fitness Clinic": {
			"name": "Fitness Clinic",
			"built": false,
			"level": 0,
			"max_level": 109,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 980,
			"weekly_income": 0,
			"build_cost": 70000,
			"build_time": 16,
			"upgrade_cost": 35000,
			"upgrade_time": 8,
			"effects": "-10% Driver & Crew fatigue\n-0.5% per level"
		},
		"Pit Crew Arena": {
			"name": "Pit Crew Arena",
			"built": false,
			"level": 0,
			"max_level": 20,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1150,
			"weekly_income": 0,
			"build_cost": 90000,
			"build_time": 20,
			"upgrade_cost": 45000,
			"upgrade_time": 10,
			"effects": "-0.1s pit stop time\n-1% pit stop time per level"
		},
		"Academy": {
			"name": "Academy",
			"built": false,
			"level": 0,
			"max_level": 4,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 980,
			"weekly_income": 0,
			"build_cost": 85000,
			"build_time": 22,
			"upgrade_cost": 42000,
			"upgrade_time": 10,
			"effects": "Unlocks 5 cadet slots\n+1 cadet slot & +3% rookie quality per level"
		},
		"Karting Track": {
			"name": "Karting Track",
			"built": false,
			"level": 0,
			"max_level": 3,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 480,
			"weekly_income": 800,
			"build_cost": 28000,
			"build_time": 12,
			"upgrade_cost": 15000,
			"upgrade_time": 4,
			"effects": "+5% Go-Kart performance\n+$800 weekly income"
		},
		"Gravel Track": {
			"name": "Gravel Track",
			"built": false,
			"level": 0,
			"max_level": 3,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 620,
			"weekly_income": 700,
			"build_cost": 42000,
			"build_time": 14,
			"upgrade_cost": 22000,
			"upgrade_time": 6,
			"effects": "+5% Rally performance\n+$700 weekly income"
		},
		"Oval Track": {
			"name": "Oval Track",
			"built": false,
			"level": 0,
			"max_level": 3,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 680,
			"weekly_income": 850,
			"build_cost": 55000,
			"build_time": 16,
			"upgrade_cost": 28000,
			"upgrade_time": 6,
			"effects": "+5% Oval performance\n+$850 weekly income"
		},
		"Race Track": {
			"name": "Race Track",
			"built": false,
			"level": 0,
			"max_level": 4,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1250,
			"weekly_income": 1300,
			"build_cost": 95000,
			"build_time": 52,
			"upgrade_cost": 48000,
			"upgrade_time": 12,
			"effects": "+3% Road course performance\n+$1300 weekly income"
		},
	}

func get_building(building_id: String) -> Dictionary:
	return campus_buildings.get(building_id, {})

func start_building(building_id: String) -> void:
	if not building_id in campus_buildings:
		return
	var building = campus_buildings[building_id]
	if building["built"]:
		return
	if player_team.balance < building["build_cost"]:
		return
	player_team.balance -= building["build_cost"]
	building["built"] = true
	building["construction_weeks_remaining"] = building["build_time"]
	building["level"] = 0
	add_log("🏗 Construction started: %s (%d weeks)" % [building["name"], building["build_time"]])
	emit_signal("log_updated")

func start_upgrade(building_id: String) -> void:
	if not building_id in campus_buildings:
		return
	var building = campus_buildings[building_id]
	if not building["built"]:
		return
	if building["construction_weeks_remaining"] > 0:
		return
	if building["level"] >= building["max_level"]:
		return
	if player_team.balance < building["upgrade_cost"]:
		return
	player_team.balance -= building["upgrade_cost"]
	building["construction_weeks_remaining"] = building["upgrade_time"]
	add_log("⬆ Upgrade started: %s to Level %d (%d weeks)" % [
		building["name"],
		building["level"] + 1,
		building["upgrade_time"]
	])
	emit_signal("log_updated")

func _update_campus_construction() -> void:
	for building_id in campus_buildings:
		var building = campus_buildings[building_id]
		if building["built"] and building["construction_weeks_remaining"] > 0:
			building["construction_weeks_remaining"] -= 1
			if building["construction_weeks_remaining"] == 0:
				building["level"] += 1
				add_log("✅ %s complete! Now Level %d" % [building["name"], building["level"]])

func _apply_campus_income() -> void:
	var total_income = 0
	var total_maintenance = 0
	for building_id in campus_buildings:
		var building = campus_buildings[building_id]
		if building["built"] and building["construction_weeks_remaining"] == 0:
			total_income += building["weekly_income"]
			total_maintenance += building["weekly_maintenance"]
	if total_income > 0:
		player_team.balance += total_income
	player_team.balance -= total_maintenance
	if total_income > 0 or total_maintenance > 0:
		add_log("🏗 Campus: +$%d income / -$%d maintenance" % [total_income, total_maintenance])

func setup_new_game() -> void:
	current_week = 1
	current_season = 1
	weekly_log = []
	last_race_results = []
	hall_of_fame = []
	all_teams = []
	all_drivers = {}
	_setup_championship()
	_setup_player_team()
	_generate_drivers()
	_generate_ai_teams()
	_setup_campus()
	add_log("Welcome to Automotive Empire!")
	add_log("Season %d — GK Regional Championship" % current_season)

func _setup_championship() -> void:
	active_championship = Championship.new()
	active_championship.id = "C-001"
	active_championship.championship_name = "GK Regional Championship"
	active_championship.tier = 1
	active_championship.min_age = 8
	active_championship.max_age = 16
	active_championship.entry_fee_per_race = 1500.0
	active_championship.num_races = 6
	active_championship.points_system = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
	active_championship.prize_1st = 300.0
	active_championship.prize_2nd = 150.0
	active_championship.prize_3rd = 75.0
	active_championship.calendar = [
		{"round": 1, "name": "Super Karting Raceway", "week": 6,  "rain_probability": 0,   "laps": 20, "lap_km": 0.42, "audience": 120},
		{"round": 2, "name": "Riverside Kart Park",   "week": 12, "rain_probability": 20,  "laps": 20, "lap_km": 0.51, "audience": 95},
		{"round": 3, "name": "The Brickyard Junior",  "week": 18, "rain_probability": 0,   "laps": 24, "lap_km": 0.40, "audience": 150},
		{"round": 4, "name": "Ocean Breeze Arena",    "week": 24, "rain_probability": 100, "laps": 20, "lap_km": 0.39, "audience": 40},
		{"round": 5, "name": "Pinnacle Heights",      "week": 32, "rain_probability": 10,  "laps": 20, "lap_km": 0.55, "audience": 180},
		{"round": 6, "name": "Metro Kart Complex",    "week": 40, "rain_probability": 40,  "laps": 20, "lap_km": 0.66, "audience": 310},
	]

func _setup_player_team() -> void:
	player_team = Team.new()
	player_team.id = "T-PLAYER"
	player_team.team_name = "My Racing Team"
	player_team.is_player_team = true
	player_team.balance = 50000.0
	player_team.reputation = 15.0
	player_team.weekly_driver_salary = 50.0
	player_team.weekly_mechanic_salary = 250.0
	all_teams.append(player_team)
	active_championship.team_standings[player_team.id] = 0

func _generate_drivers() -> void:
	var d1 = _create_driver("D-P001", "Alex", "Rivera", "Spanish", 10, "Male", "T-PLAYER")
	var d2_name = NameGenerator.get_full_name("Spanish", "Female")
	var d2 = _create_driver("D-P002", d2_name["first"], d2_name["last"], "Spanish", 12, "Female", "T-PLAYER")
	all_drivers[d1.id] = d1
	all_drivers[d2.id] = d2
	player_team.drivers.append(d1.id)
	player_team.drivers.append(d2.id)
	active_championship.standings[d1.id] = 0
	active_championship.standings[d2.id] = 0

func _create_driver(id: String, first: String, last: String, nationality: String, age: int, sex: String, team_id: String) -> Driver:
	var d = Driver.new()
	d.id = id
	d.first_name = first
	d.last_name = last
	d.nationality = nationality
	d.age = age
	d.sex = sex
	d.contract_team = team_id
	d.active_championships = ["C-001"]
	d.active_discipline = "GK"
	d.discipline_change_season = current_season

	var age_factor = float(age - 8) / 8.0
	d.pace = randf_range(20.0, 50.0) + age_factor * 25.0
	d.wet = randf_range(15.0, 45.0) + age_factor * 20.0
	d.focus = randf_range(20.0, 50.0) + age_factor * 20.0
	d.race_craft = randf_range(15.0, 45.0) + age_factor * 25.0
	d.fitness = randf_range(70.0, 100.0)
	d.potential = randf_range(50.0, 95.0)
	d.aggression = randf_range(20.0, 80.0)
	d.experience = age_factor * 30.0
	d.morale = 100.0

	var talent_factor = d.potential / 100.0
	var starting_gk = 5.0 + (talent_factor * 10.0) + (age_factor * 5.0)
	d.discipline_adaptation["GK"] = starting_gk
	d.peak_adaptation["GK"] = starting_gk

	return d

func _generate_ai_teams() -> void:
	var ai_data = [
		{"name": "Karting Italia",     "nationality": "Italian"},
		{"name": "Speed Academy",      "nationality": "Spanish"},
		{"name": "Nordic Kart",        "nationality": "Finnish"},
		{"name": "British Racing",     "nationality": "British"},
		{"name": "German Motorsport",  "nationality": "German"},
		{"name": "French Kart Team",   "nationality": "French"},
		{"name": "Brazilian Speed",    "nationality": "Brazilian"},
		{"name": "Japanese Racing",    "nationality": "Japanese"},
		{"name": "USA Kart Pro",       "nationality": "American"},
	]

	for i in range(ai_data.size()):
		var team = Team.new()
		team.id = "T-AI-%02d" % i
		team.team_name = ai_data[i]["name"]
		team.nationality = ai_data[i]["nationality"]
		team.is_player_team = false
		team.balance = randf_range(30000.0, 80000.0)
		team.reputation = randf_range(10.0, 25.0)
		team.weekly_driver_salary = 50.0
		team.weekly_mechanic_salary = 250.0
		all_teams.append(team)
		active_championship.team_standings[team.id] = 0

		for j in range(2):
			var driver_id = "D-AI-%02d-%d" % [i, j]
			var nat = NameGenerator.get_nationality_for_team(ai_data[i]["nationality"])
			var sex = "Male" if randf() > 0.3 else "Female"
			var age = randi_range(8, 14)
			var name_data = NameGenerator.get_full_name(nat, sex)
			var driver = _create_driver(
				driver_id,
				name_data["first"],
				name_data["last"],
				nat,
				age,
				sex,
				team.id
			)
			all_drivers[driver_id] = driver
			team.drivers.append(driver_id)
			active_championship.standings[driver_id] = 0

func advance_week() -> void:
	weekly_log = []
	current_week += 1

	# Weekly fitness recovery
	_apply_weekly_fitness_recovery()

	# Campus construction progress
	_update_campus_construction()

	# Campus income and maintenance
	_apply_campus_income()

	# Check for race this week
	var next_race = active_championship.get_next_race()
	if next_race and next_race["week"] == current_week:
		_simulate_race(next_race)
		active_championship.current_round += 1
		return

	# Apply weekly expenses
	_apply_weekly_expenses()

	# Check season end
	if active_championship.is_season_finished() or current_week > max_weeks:
		_end_season()
		return

	add_log("--- Week %d ---" % current_week)
	emit_signal("week_advanced", current_week)
	emit_signal("log_updated")

func _apply_weekly_fitness_recovery() -> void:
	for driver_id in all_drivers:
		var driver = all_drivers[driver_id]
		driver.fitness = min(100.0, driver.fitness + 8.0)

func _apply_weekly_expenses() -> void:
	for team in all_teams:
		# Expenses scale with number of drivers
		var driver_count = team.drivers.size()
		var expenses = (team.weekly_driver_salary * driver_count) + team.weekly_mechanic_salary
		team.balance -= expenses
		if team.is_player_team:
			add_log("Weekly expenses paid: -$%.0f" % expenses)

func _simulate_race(race_data: Dictionary) -> void:
	add_log("=== RACE %d: %s ===" % [active_championship.current_round + 1, race_data["name"]])

	# Collect all drivers
	var race_drivers = []
	for driver_id in active_championship.standings:
		if driver_id in all_drivers:
			race_drivers.append(all_drivers[driver_id])

	# Determine weather
	var is_wet = randf() * 100.0 < race_data["rain_probability"]

	# Calculate lap times
	var driver_times = []
	for driver in race_drivers:
		var base_time = 28.5
		var effective_pace = driver.get_effective_pace()
		var effective_wet = driver.get_effective_wet()
		var effective_focus = driver.get_effective_focus()

		var pace_factor = 1.0 - (effective_pace / 1000.0)
		var wet_factor = 1.0
		if is_wet:
			wet_factor = 1.0 + ((100.0 - effective_wet) / 200.0)
		var focus_factor = 1.0 - (effective_focus / 2000.0)
		var fitness_factor = driver.fitness_penalty()
		var lap_time = base_time * pace_factor * wet_factor * focus_factor * (2.0 - fitness_factor)
		lap_time += randf_range(-0.5, 0.5)
		driver_times.append({
			"driver": driver,
			"lap_time": lap_time,
			"total_time": lap_time * race_data["laps"],
			"points": 0
		})

	# Sort by total time
	driver_times.sort_custom(func(a, b): return a["total_time"] < b["total_time"])

	# Award points and prizes
	var points_system = active_championship.points_system
	for i in range(driver_times.size()):
		var entry = driver_times[i]
		var driver = entry["driver"]
		var standing_position = i + 1
		var pts = 0

		if i < points_system.size():
			pts = points_system[i]
			active_championship.add_points(driver.id, pts)
			driver_times[i]["points"] = pts

		# Find team and award team points + prize money
		for team in all_teams:
			if driver.id in team.drivers:
				active_championship.add_team_points(team.id, pts)
				var prize = 0.0
				if standing_position == 1:
					prize = active_championship.prize_1st
				elif standing_position == 2:
					prize = active_championship.prize_2nd
				elif standing_position == 3:
					prize = active_championship.prize_3rd
				team.balance += prize
				break

		# Update driver stats
		_update_driver_stats_after_race(driver, standing_position, race_data["laps"], is_wet)

	# Apply weekly expenses
	_apply_weekly_expenses()

	# Store last race data
	last_race_round = active_championship.current_round + 1
	last_race_name = race_data["name"]
	last_race_wet = is_wet
	last_race_results = driver_times

	# Hall of fame
	if driver_times.size() > 0:
		var winner = driver_times[0]["driver"]
		var winner_team = "Unknown"
		for team in all_teams:
			if winner.id in team.drivers:
				winner_team = team.team_name
				break
		hall_of_fame.append({
			"season": current_season,
			"round": last_race_round,
			"track": race_data["name"],
			"winner": winner.full_name(),
			"team": winner_team
		})

	# Check season end
	if active_championship.is_season_finished() or current_week >= max_weeks:
		_end_season()
		return

	# Switch to race results scene
	get_tree().change_scene_to_file("res://scenes/RaceResults.tscn")

func _update_driver_stats_after_race(driver: Driver, standing_position: int, laps: int, is_wet: bool) -> void:
	# Fitness drops
	var fitness_drop = laps * 0.4
	driver.fitness = max(0.0, driver.fitness - fitness_drop)

	# Experience grows
	var exp_gain = randf_range(0.5, 1.5)
	driver.experience = min(100.0, driver.experience + exp_gain)

	# Update discipline adaptation
	var total_races = active_championship.num_races
	driver.update_adaptation_after_race(current_season, total_races)

	# Stats improve
	var improvement = 0.1 + randf_range(0.0, 0.2)
	if standing_position <= 3:
		improvement += 0.1

	if driver.pace < driver.potential:
		driver.pace = min(driver.potential, driver.pace + improvement * 0.5)
	if driver.focus < driver.potential:
		driver.focus = min(driver.potential, driver.focus + improvement * 0.3)
	if driver.race_craft < driver.potential:
		driver.race_craft = min(driver.potential, driver.race_craft + improvement * 0.4)
	if is_wet and driver.wet < driver.potential:
		driver.wet = min(driver.potential, driver.wet + improvement * 0.6)

	# Morale
	if standing_position == 1:
		driver.morale = min(100.0, driver.morale + 10.0)
	elif standing_position <= 3:
		driver.morale = min(100.0, driver.morale + 5.0)
	elif standing_position >= 8:
		driver.morale = max(0.0, driver.morale - 5.0)

func _end_season() -> void:
	add_log("=== SEASON %d COMPLETE ===" % current_season)

	# Log driver standings top 3
	var sorted_drivers = active_championship.get_standings_sorted()
	add_log("DRIVERS CHAMPIONSHIP:")
	for i in range(min(3, sorted_drivers.size())):
		var entry = sorted_drivers[i]
		var driver = all_drivers.get(entry["driver_id"])
		if driver:
			add_log("P%d: %s — %d pts" % [i + 1, driver.full_name(), entry["points"]])

	# Log team standings top 3
	var sorted_teams = active_championship.get_team_standings_sorted()
	add_log("TEAMS CHAMPIONSHIP:")
	for i in range(min(3, sorted_teams.size())):
		var entry = sorted_teams[i]
		var team_name = "Unknown"
		for team in all_teams:
			if team.id == entry["team_id"]:
				team_name = team.team_name
				break
		add_log("P%d: %s — %d pts" % [i + 1, team_name, entry["points"]])

	emit_signal("season_ended", current_season)
	emit_signal("log_updated")

func start_new_season() -> void:
	current_season += 1
	current_week = 1
	weekly_log = []

	# Age all drivers and check eligibility
	_process_off_season()

	# Reset championship for new season
	active_championship.reset_for_new_season()

	# Re-register all eligible drivers
	for team in all_teams:
		for driver_id in team.drivers:
			if driver_id in all_drivers:
				var driver = all_drivers[driver_id]
				if driver.is_eligible_for_gk_regional():
					active_championship.standings[driver_id] = 0

	# Re-register all teams
	for team in all_teams:
		active_championship.team_standings[team.id] = 0

	add_log("=== SEASON %d BEGINS ===" % current_season)
	add_log("GK Regional Championship")
	emit_signal("week_advanced", current_week)
	emit_signal("log_updated")

func _process_off_season() -> void:
	for driver_id in all_drivers:
		var driver = all_drivers[driver_id]
		driver.age += 1
		driver.fitness = 100.0
		driver.experience = min(100.0, driver.experience + 1.0)
		driver.seasons_without_contract += 1

	var driver_counter = all_drivers.size()
	for team in all_teams:
		var drivers_to_remove = []
		var drivers_to_add = []

		for driver_id in team.drivers:
			if driver_id in all_drivers:
				var driver = all_drivers[driver_id]
				if not driver.is_eligible_for_gk_regional():
					drivers_to_remove.append(driver_id)
					var new_id = "D-GEN-%04d" % driver_counter
					driver_counter += 1
					var nat = NameGenerator.get_nationality_for_team(team.nationality)
					var sex = "Male" if randf() > 0.3 else "Female"
					var name_data = NameGenerator.get_full_name(nat, sex)
					var new_driver = _create_driver(
						new_id,
						name_data["first"],
						name_data["last"],
						nat,
						8,
						sex,
						team.id
					)
					drivers_to_add.append(new_driver)
					NameGenerator.release_name(driver.full_name())
					add_log("%s aged out — replaced by %s" % [driver.full_name(), new_driver.full_name()])

		for driver_id in drivers_to_remove:
			team.drivers.erase(driver_id)
			all_drivers.erase(driver_id)

		for new_driver in drivers_to_add:
			all_drivers[new_driver.id] = new_driver
			team.drivers.append(new_driver.id)

func add_log(message: String) -> void:
	weekly_log.append(message)
	print(message)
