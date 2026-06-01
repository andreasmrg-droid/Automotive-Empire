extends Node

# Time
var current_week: int = 1
var current_season: int = 1
var max_weeks: int = 52

# Player team
var player_team: Team = null
var player_name: String = "Andreas"
var player_team_name: String = "My Racing Team"
var player_team_nationality: String = "British"

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
var active_sponsor: Dictionary = {}
var sponsor_no_points_streak: int = 0

# Resources
var research_points: float = 0.0
var spare_parts: int = 300        # units — used for repairs only, not auto-deducted per race
var fuel_kg: float = 30.0         # kg, starts with 2 races worth (15 kg × 1 car × 2)
var car_conditions: Dictionary = {}

# Notifications
var notifications: Array = []
var unread_notification_count: int = 0
signal notifications_updated()

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

# Note: CAR_CONDITION_DEGRADATION_PER_RACE removed — degradation is now per-lap,
# stored on Championship as condition_loss_per_lap.
# Note: FUEL_PER_CAR_PER_RACE removed — stored on Championship as fuel_per_car_per_race.
# Note: CAR_CONDITION_SP_PER_10_PCT removed — stored on Championship as sp_per_10_pct_damage.

# Signals
signal week_advanced(week: int)
signal season_ended(season: int)
signal log_updated()

func _ready() -> void:
	pass

func _setup_campus() -> void:
	campus_buildings = {
		# ── COMMAND ZONE ─────────────────────────────────────────────────────
		# HQ: pre-built, Level 1. Upgrade cost reflects expanding admin infrastructure.
		# Real small motorsport HQ renovation: $40K-$150K per phase.
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
			"upgrade_cost": 18000,
			"upgrade_time": 6,
			"effects": "+1% Marketability per level\n+1 Sponsor Slot every 2 levels"
		},
		# Logistics Center: pre-built. Upgrade = better warehouse/inventory systems.
		# Real small logistics depot fit-out: $15K-$60K.
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
			"upgrade_cost": 12000,
			"upgrade_time": 4,
			"effects": "+1% reduced price of spare parts per level"
		},
		# Garage: pre-built, earns repair income. Upgrade = more bays, better tools.
		# Real motorsport garage bay fit-out: $20K-$80K per expansion.
		"Garage": {
			"name": "Garage",
			"built": true,
			"level": 1,
			"max_level": 89,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1100,
			"weekly_income": 3000,
			"build_cost": 0,
			"build_time": 0,
			"upgrade_cost": 15000,
			"upgrade_time": 4,
			"effects": "+$1800 weekly repair profit\n+$450 per level"
		},
		# Racing Dept: pre-built. Upgrade = strategy tools, data systems, staff desks.
		# Real motorsport operations room setup: $15K-$50K.
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
			"upgrade_cost": 12000,
			"upgrade_time": 4,
			"effects": "+10% Driver Morale & Focus\n+5% per level"
		},
		# ── ENGINEERING ZONE ─────────────────────────────────────────────────
		# R&D Studio: first major investment. Custom CAD/simulation room build-out.
		# Real small engineering design studio: $80K-$200K. Mid-game goal.
		"R&D Design Studio": {
			"name": "R&D Design Studio",
			"built": false,
			"level": 0,
			"max_level": 27,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1600,
			"weekly_income": 0,
			"build_cost": 85000,
			"build_time": 20,
			"upgrade_cost": 28000,
			"upgrade_time": 8,
			"effects": "Unlocks R&D (800 RP storage)\n+400 RP & +1% R&D speed per level"
		},
		# CNC Plant: serious manufacturing investment. Real small CNC shop: $150K-$400K.
		# Late mid-game. Requires significant financial commitment.
		"CNC Parts Plant": {
			"name": "CNC Parts Plant",
			"built": false,
			"level": 0,
			"max_level": 24,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 2200,
			"weekly_income": 0,
			"build_cost": 220000,
			"build_time": 34,
			"upgrade_cost": 55000,
			"upgrade_time": 12,
			"effects": "Unlocks CNC production\n+4% speed & -1% material cost per level"
		},
		# ── SIMULATION ZONE ──────────────────────────────────────────────────
		# Ops Sim: simulator rigs + telemetry servers. Real setup: $60K-$180K.
		# Early mid-game, reachable after a good first season.
		"Ops Sim & Telemetry": {
			"name": "Ops Sim & Telemetry",
			"built": false,
			"level": 0,
			"max_level": 30,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1350,
			"weekly_income": 0,
			"build_cost": 65000,
			"build_time": 16,
			"upgrade_cost": 22000,
			"upgrade_time": 7,
			"effects": "+25% baseline Track Knowledge\n+1% Track Knowledge gain per level"
		},
		# Wind Tunnel: endgame prestige facility. Real F1-grade: $20M-$80M.
		# Scaled down but still a major late-game milestone. $800K feels right
		# for a small-scale tunnel — think GP2/GP3 team level.
		"Aerodynamic Wind Tunnel": {
			"name": "Aerodynamic Wind Tunnel",
			"built": false,
			"level": 0,
			"max_level": 9,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 8500,
			"weekly_income": 0,
			"build_cost": 800000,
			"build_time": 78,
			"upgrade_cost": 180000,
			"upgrade_time": 26,
			"effects": "+10% Aero efficiency\n+5% per level"
		},
		# ── COMMERCIAL ZONE ──────────────────────────────────────────────────
		# Vehicle Assembly Factory: major commercial venture. Real small auto factory:
		# $2M-$10M. This is a true endgame building — long save goal.
		"Vehicle Assembly Factory": {
			"name": "Vehicle Assembly Factory",
			"built": false,
			"level": 0,
			"max_level": 12,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 6500,
			"weekly_income": 0,
			"build_cost": 1200000,
			"build_time": 78,
			"upgrade_cost": 250000,
			"upgrade_time": 26,
			"effects": "Unlocks commercial car production\n+250 units/wk & +3% margin per level"
		},
		# Museum: motorsport heritage display. Real small museum fit-out: $80K-$250K.
		# Good early income investment once you have some history.
		"Museum": {
			"name": "Museum",
			"built": false,
			"level": 0,
			"max_level": 5,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 900,
			"weekly_income": 2400,
			"build_cost": 90000,
			"build_time": 16,
			"upgrade_cost": 35000,
			"upgrade_time": 6,
			"effects": "+$2400 weekly passive income\n+$380 per level"
		},
		# Theme Park: major entertainment complex. Real small motorsport theme park:
		# $2M-$15M. Scaled to be a late-game passive income machine.
		"Theme Park": {
			"name": "Theme Park",
			"built": false,
			"level": 0,
			"max_level": 5,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 4500,
			"weekly_income": 12000,
			"build_cost": 950000,
			"build_time": 104,
			"upgrade_cost": 200000,
			"upgrade_time": 26,
			"effects": "+$12000 weekly passive income\n+$1500 per level"
		},
		# Public Racing Club: track day/member club. Real club setup: $40K-$120K.
		# Accessible mid-game income stream.
		"Public Racing Club": {
			"name": "Public Racing Club",
			"built": false,
			"level": 0,
			"max_level": 7,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 850,
			"weekly_income": 2200,
			"build_cost": 55000,
			"build_time": 12,
			"upgrade_cost": 18000,
			"upgrade_time": 6,
			"effects": "+$2200 weekly passive income\n+$350 per level"
		},
		# Merchandise Store: team shop. Real small branded retail fit-out: $20K-$60K.
		# Cheapest income building — first thing a player should consider building.
		"Merchandise Store": {
			"name": "Merchandise Store",
			"built": false,
			"level": 0,
			"max_level": 5,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 650,
			"weekly_income": 1800,
			"build_cost": 22000,
			"build_time": 6,
			"upgrade_cost": 10000,
			"upgrade_time": 3,
			"effects": "+$1800 weekly passive income\n+$280 per level"
		},
		# ── HUMAN PERFORMANCE ZONE ───────────────────────────────────────────
		# Fitness Clinic: driver/crew gym and physio suite. Real sports clinic: $80K-$200K.
		"Fitness Clinic": {
			"name": "Fitness Clinic",
			"built": false,
			"level": 0,
			"max_level": 109,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 980,
			"weekly_income": 0,
			"build_cost": 75000,
			"build_time": 14,
			"upgrade_cost": 18000,
			"upgrade_time": 6,
			"effects": "-10% Driver & Crew fatigue\n-0.5% per level"
		},
		# Pit Crew Arena: dedicated pit stop practice rig. Real setup: $30K-$150K.
		# Tangible race performance investment — mid-game priority.
		"Pit Crew Arena": {
			"name": "Pit Crew Arena",
			"built": false,
			"level": 0,
			"max_level": 20,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1150,
			"weekly_income": 0,
			"build_cost": 55000,
			"build_time": 14,
			"upgrade_cost": 22000,
			"upgrade_time": 8,
			"effects": "-0.1s pit stop time\n-1% pit stop time per level"
		},
		# Academy: driver development program facility. Real junior academy setup:
		# $100K-$300K including simulators, coaching infrastructure.
		"Academy": {
			"name": "Academy",
			"built": false,
			"level": 0,
			"max_level": 4,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1800,
			"weekly_income": 0,
			"build_cost": 120000,
			"build_time": 20,
			"upgrade_cost": 45000,
			"upgrade_time": 10,
			"effects": "Unlocks 5 cadet slots\n+1 cadet slot & +3% rookie quality per level"
		},
		# ── TEST TRACKS ZONE ─────────────────────────────────────────────────
		# Karting Track: real outdoor kart circuit construction: $150K-$600K.
		# Includes safety barriers, pit lane, timing, surface. Early-mid game.
		"Karting Track": {
			"name": "Karting Track",
			"built": false,
			"level": 0,
			"max_level": 3,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1200,
			"weekly_income": 2500,
			"build_cost": 160000,
			"build_time": 20,
			"upgrade_cost": 55000,
			"upgrade_time": 8,
			"effects": "+5% Go-Kart performance\n+$2500 weekly income"
		},
		# Gravel Track: rally stage with gravel surface, spectator areas, safety zones.
		# Real rally stage construction: $200K-$800K.
		"Gravel Track": {
			"name": "Gravel Track",
			"built": false,
			"level": 0,
			"max_level": 3,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1400,
			"weekly_income": 2200,
			"build_cost": 200000,
			"build_time": 22,
			"upgrade_cost": 65000,
			"upgrade_time": 10,
			"effects": "+5% Rally performance\n+$2200 weekly income"
		},
		# Oval Track: banked oval with concrete surface. Real small oval: $400K-$1.5M.
		"Oval Track": {
			"name": "Oval Track",
			"built": false,
			"level": 0,
			"max_level": 3,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1800,
			"weekly_income": 3000,
			"build_cost": 380000,
			"build_time": 30,
			"upgrade_cost": 95000,
			"upgrade_time": 12,
			"effects": "+5% Oval performance\n+$3000 weekly income"
		},
		# Race Track: full tarmac road course with pit lane, marshal posts, timing.
		# Real small circuit (2-3km): $1.5M-$8M. Major endgame investment.
		"Race Track": {
			"name": "Race Track",
			"built": false,
			"level": 0,
			"max_level": 4,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 4500,
			"weekly_income": 8500,
			"build_cost": 1500000,
			"build_time": 78,
			"upgrade_cost": 320000,
			"upgrade_time": 20,
			"effects": "+3% Road course performance\n+$8500 weekly income"
		},
	}

func _setup_sponsor() -> void:
	var national_sponsors = [
		{"id": "SP-006", "name": "Velocity Spark", "category": "Energy Drink"},
		{"id": "SP-016", "name": "Precision Fluids", "category": "Lubricants"},
		{"id": "SP-026", "name": "Velocity Parts", "category": "Auto Parts"},
		{"id": "SP-033", "name": "Apex Finance", "category": "Finance"},
		{"id": "SP-039", "name": "Atlas Bank", "category": "Finance"},
		{"id": "SP-046", "name": "Precision Tech", "category": "Tech"},
		{"id": "SP-049", "name": "Dynamic Systems", "category": "Tech"},
		{"id": "SP-053", "name": "Apex Grip", "category": "Tires"},
		{"id": "SP-059", "name": "Helix Tires", "category": "Tires"},
		{"id": "SP-062", "name": "Velocity Style", "category": "Fashion"},
		{"id": "SP-073", "name": "Legacy Shield", "category": "Insurance"},
		{"id": "SP-083", "name": "Stellar Connect", "category": "Telecom"},
		{"id": "SP-089", "name": "Helix Mobile", "category": "Telecom"},
		{"id": "SP-095", "name": "Core Distillery", "category": "Beverage"},
		{"id": "SP-098", "name": "Dynamic Spirits", "category": "Beverage"},
	]
	var picked = national_sponsors[randi() % national_sponsors.size()]
	active_sponsor = {
		"id": picked["id"],
		"name": picked["name"],
		"category": picked["category"],
		"base_weekly": 1000,
		"current_weekly": 1000,
		"performance_bonus": 500,
		"seasons_remaining": 1,
	}
	add_log("📋 Sponsor signed: %s — $1,000/week" % picked["name"])

func add_notification(priority: String, message: String) -> void:
	# priority: "Critical", "High", "Normal"
	notifications.append({
		"priority": priority,
		"message": message,
		"week": current_week,
		"season": current_season,
		"read": false,
	})
	unread_notification_count += 1
	emit_signal("notifications_updated")
	# Also log critical ones
	if priority == "Critical":
		add_log("🔴 CRITICAL: %s" % message)
	elif priority == "High":
		add_log("🟠 %s" % message)

func mark_all_notifications_read() -> void:
	for n in notifications:
		n["read"] = true
	unread_notification_count = 0
	emit_signal("notifications_updated")

func _apply_sponsor_income() -> void:
	if active_sponsor.is_empty():
		return
	var payment = active_sponsor["current_weekly"]
	player_team.balance += payment
	add_log("💼 %s: +$%d" % [active_sponsor["name"], payment])

func _update_sponsor_performance(race_results: Array) -> void:
	if active_sponsor.is_empty():
		return

	var player_scored = false
	var player_top5 = false

	for i in range(race_results.size()):
		var result = race_results[i]
		var driver = result["driver"]
		if driver.id in player_team.drivers:
			if result["points"] > 0:
				player_scored = true
			if i < 5:
				player_top5 = true

	if player_top5:
		active_sponsor["current_weekly"] = active_sponsor["base_weekly"] + active_sponsor["performance_bonus"]
		sponsor_no_points_streak = 0
		add_log("🌟 %s bonus: +$%d this week!" % [active_sponsor["name"], active_sponsor["current_weekly"]])
	elif player_scored:
		active_sponsor["current_weekly"] = active_sponsor["base_weekly"]
		sponsor_no_points_streak = 0
	else:
		sponsor_no_points_streak += 1
		if sponsor_no_points_streak >= 3:
			active_sponsor["current_weekly"] = 500
			add_log("⚠ %s unhappy — reduced to $500/week (no points in 3 races)" % active_sponsor["name"])

func _apply_weekly_expenses() -> void:
	# Player team — full staff costs
	var player_expenses = 0
	player_expenses += player_team.drivers.size() * 50        # Driver salaries
	player_expenses += 350                                     # Team Principal
	player_expenses += 300                                     # CFO
	player_expenses += player_team.drivers.size() * 250       # Race mechanics
	player_team.balance -= player_expenses
	add_log("Weekly expenses paid: -$%d" % player_expenses)

	# AI teams — simple salary model
	for team in all_teams:
		if team.is_player_team:
			continue
		var driver_count = team.drivers.size()
		var ai_expenses = (team.weekly_driver_salary * driver_count) + team.weekly_mechanic_salary
		team.balance -= ai_expenses

func _consume_race_resources() -> void:
	# Fuel: per car per race — championship-specific rate
	var cars = player_team.drivers.size()
	var fuel_used = active_championship.fuel_per_car_per_race * cars
	fuel_kg -= fuel_used
	fuel_kg = max(fuel_kg, 0.0)
	add_log("⛽ Fuel used: %.1f kg (stock: %.1f kg)" % [fuel_used, fuel_kg])

	# SP is NOT auto-deducted per race.
	# SP is spent only on repairs — see _auto_repair_cars_post_race() below.

	# Check resource warnings
	_check_resource_notifications()

func _earn_race_rp(laps: int) -> void:
	var rp_gained = laps * 0.5
	research_points += rp_gained
	add_log("🔬 RP gained: %.0f (total: %.0f)" % [rp_gained, research_points])

func _check_resource_notifications() -> void:
	# SP warnings — SP is for repairs only
	if spare_parts <= 0:
		add_notification("Critical", "No spare parts remaining! Buy more at the Logistics Center to repair your car.")
	elif spare_parts < active_championship.sp_per_10_pct_damage:
		add_notification("High", "Spare parts low (%d units). Not enough to repair 10%% damage." % spare_parts)

	# Fuel warnings — championship-specific threshold
	var fuel_needed = active_championship.fuel_per_car_per_race
	if fuel_kg <= 0.0:
		add_notification("Critical", "No fuel remaining! Buy more at the Logistics Center before next race.")
	elif fuel_kg < fuel_needed:
		add_notification("High", "Fuel running low (%.1f kg). Less than 1 race worth remaining." % fuel_kg)

	# Bankruptcy warning
	var weekly_expenses = 1250
	if player_team.balance < 0:
		add_notification("Critical", "BANKRUPTCY RISK: Balance is negative ($%.0f)!" % player_team.balance)
	elif player_team.balance < weekly_expenses * 2:
		add_notification("High", "Low funds warning: Less than 2 weeks of expenses remaining.")

func buy_spare_parts(units: int) -> bool:
	var cost_per_unit = 1  # $1 per unit for GK Regional (120 units = $120/race)
	var total_cost = units * cost_per_unit
	if player_team.balance < total_cost:
		add_notification("High", "Not enough credits to buy spare parts.")
		return false
	player_team.balance -= total_cost
	spare_parts += units
	add_log("🛒 Bought %d spare parts for $%d (stock: %d)" % [units, total_cost, spare_parts])
	return true

func buy_fuel(kg: float) -> bool:
	var cost_per_kg = 2.0  # placeholder price
	var total_cost = kg * cost_per_kg
	if player_team.balance < total_cost:
		add_notification("High", "Not enough credits to buy fuel.")
		return false
	player_team.balance -= total_cost
	fuel_kg += kg
	add_log("🛒 Bought %.1f kg fuel for $%.0f (stock: %.1f kg)" % [kg, total_cost, fuel_kg])
	return true

## Initialise condition for every driver in player_team. Call from setup_new_game().
func _setup_car_conditions() -> void:
	car_conditions.clear()
	for driver_id in player_team.drivers:
		car_conditions[driver_id] = 100.0


## Returns the condition for a specific car (by driver_id). Safe — returns 100 if missing.
func get_car_condition(driver_id: String) -> float:
	return car_conditions.get(driver_id, 100.0)


## Degrade all player cars based on laps raced.
## Called from _simulate_race() immediately after the race loop completes.
## Uses championship condition_loss_per_lap — no flat constant.
func _degrade_car_conditions(laps: int) -> void:
	var loss = active_championship.condition_loss_per_lap * float(laps)
	for driver_id in player_team.drivers:
		if not driver_id in car_conditions:
			car_conditions[driver_id] = 100.0
		car_conditions[driver_id] = max(0.0, car_conditions[driver_id] - loss)
		add_log("🔩 Car condition after race: %.0f%% (-%0.1f%% over %d laps)" % [
			car_conditions[driver_id], loss, laps])


## Auto-repair all player cars after a race, silently, using championship SP rate.
## Sorts cars by soonest next race (most urgent first).
## Fires notifications only when SP is insufficient — player does not need to act otherwise.
## Called from _simulate_race() after _degrade_car_conditions().
func _auto_repair_cars_post_race() -> void:
	if player_team.drivers.is_empty():
		return

	# Sort cars by soonest next race round
	# For now with 1 car this is trivial; with 2 cars it picks the one racing soonest
	var cars_sorted = player_team.drivers.duplicate()
	# Future: sort by next race week when multi-championship is implemented

	var sp_rate = active_championship.sp_per_10_pct_damage  # SP per 10% damage
	var any_failed = false
	var failed_cars: Array = []

	for driver_id in cars_sorted:
		var condition = get_car_condition(driver_id)
		var damage = 100.0 - condition
		if damage <= 0.0:
			continue  # already at 100%, nothing to do

		var sp_needed = int(ceil(damage / 10.0) * sp_rate)

		if spare_parts >= sp_needed:
			# Silent full repair
			spare_parts -= sp_needed
			car_conditions[driver_id] = 100.0
			add_log("🔧 Auto-repair: Car fully restored to 100%% (-%d SP, %d remaining)" % [
				sp_needed, spare_parts])
		elif spare_parts > 0:
			# Partial repair — use all remaining SP
			var sp_available = spare_parts
			var repair_pct = float(sp_available) / float(sp_rate) * 10.0
			car_conditions[driver_id] = min(100.0, condition + repair_pct)
			spare_parts = 0
			add_log("🔧 Partial repair: Car at %.0f%% (SP exhausted)" % car_conditions[driver_id])
			any_failed = true
			failed_cars.append(driver_id)
		else:
			# No SP at all
			any_failed = true
			failed_cars.append(driver_id)

	if any_failed:
		var driver_names = []
		for d_id in failed_cars:
			var d = all_drivers.get(d_id)
			if d:
				driver_names.append(d.full_name())
		var names_str = ", ".join(driver_names)
		var sp_for_full = 0
		for d_id in failed_cars:
			var dmg = 100.0 - get_car_condition(d_id)
			sp_for_full += int(ceil(dmg / 10.0) * sp_rate)

		if spare_parts == 0:
			add_notification("Critical",
				"Not enough SP to repair %s's car. Need %d SP — buy more at Logistics Center." % [
					names_str, sp_for_full])
		else:
			add_notification("High",
				"SP insufficient for full repair of %s's car (%.0f%% condition). Buy more SP." % [
					names_str, get_car_condition(failed_cars[0])])

## Manual repair: repair a car by repair_pct points using SP.
## Called from the Cars tab repair buttons. Returns true if repair was applied.
func repair_car(driver_id: String, repair_pct: float) -> bool:
	if not driver_id in car_conditions:
		return false
	var current = car_conditions[driver_id]
	var actual_repair = min(repair_pct, 100.0 - current)
	if actual_repair <= 0.0:
		add_notification("Normal", "Car is already at full condition.")
		return false
	var sp_rate = active_championship.sp_per_10_pct_damage
	var sp_cost = int(ceil(actual_repair / 10.0) * sp_rate)
	if spare_parts < sp_cost:
		add_notification("High",
			"Not enough SP to repair car. Need %d SP, have %d." % [sp_cost, spare_parts])
		return false
	spare_parts -= sp_cost
	car_conditions[driver_id] = min(100.0, current + actual_repair)
	add_log("🔧 Manual repair +%.0f%% → %.0f%% condition (-%d SP, %d remaining)" % [
		actual_repair, car_conditions[driver_id], sp_cost, spare_parts])
	emit_signal("log_updated")
	return true


## Convenience: repair a car to full condition in one click (Cars tab).
func repair_car_full(driver_id: String) -> bool:
	var current = get_car_condition(driver_id)
	var damage = 100.0 - current
	if damage <= 0.0:
		add_notification("Normal", "Car is already at full condition.")
		return false
	return repair_car(driver_id, damage)


## Repair efficiency multiplier (0.0–1.0).
## Returns 1.0 until the staff hiring system is implemented.
## Will be wired to Race Mechanic + Pit Crew attributes when staff is built.
func _get_repair_efficiency() -> float:
	return 1.0


## Reserved hook for mid-race pit stop repairs (TC, SC, EPC).
## Currently empty — will be called from race simulation when pit stop system is built.
## stop_duration: seconds available for repairs in this pit stop.
func apply_pitstop_repair(_car_driver_id: String, _stop_duration: float) -> void:
	pass  # TODO: implement when pit stop system is designed


## DNS check — returns true if the car CAN race, false if DNS.
## A car is DNS if there is not enough fuel for one race.
func _can_car_race(driver_id: String) -> bool:
	var fuel_needed = active_championship.fuel_per_car_per_race
	if fuel_kg < fuel_needed:
		add_notification("Critical",
			"DNS: Not enough fuel (%.1f kg). Need %.1f kg. Buy fuel at Logistics Center." % [
				fuel_kg, fuel_needed])
		add_log("🚫 DNS — Insufficient fuel for race start.")
		return false
	return true

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

func setup_new_game(p_team_name: String, p_nationality: String, p_player_name: String) -> void:
	current_week = 1
	current_season = 1
	weekly_log = []
	last_race_results = []
	hall_of_fame = []
	all_teams = []
	all_drivers = {}
	_setup_championship()
	player_name = p_player_name
	player_team_name = p_team_name
	player_team_nationality = p_nationality
	_setup_player_team()
	_generate_drivers()
	_generate_ai_teams()
	_setup_campus()
	_setup_sponsor()
	_setup_car_conditions()
	add_log("Welcome to Automotive Empire!")
	add_log("Season %d — GK Regional Championship" % current_season)

func _setup_championship() -> void:
	active_championship = Championship.new()
	active_championship.id = "C-001"
	active_championship.championship_name = "GK Regional Championship"
	active_championship.discipline = "GK"
	active_championship.tier = 1
	active_championship.min_age = 8
	active_championship.max_age = 16
	active_championship.entry_fee_per_race = 1500.0
	active_championship.num_races = 6
	active_championship.points_system = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
	active_championship.prize_1st = 300.0
	active_championship.prize_2nd = 150.0
	active_championship.prize_3rd = 75.0

	# Resources — from Excel Variables Map, Championships sheet
	active_championship.sp_per_10_pct_damage = 100
	active_championship.fuel_per_car_per_race = 15.0

	# Car condition — GK: smooth tarmac, light kart, 0.5% per lap
	active_championship.condition_loss_per_lap = 0.5
	active_championship.condition_loss_per_stage = 0.0

	# Repair — GK: post-race only, no timed windows, mechanic only
	active_championship.repair_time_per_1pct = 0.0
	active_championship.has_mid_race_repairs = false
	active_championship.service_park_every_n_stages = 0
	active_championship.pit_stop_repair_pct = 0.0

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
	player_team.team_name = player_team_name
	player_team.is_player_team = true
	player_team.balance = 50000.0
	player_team.reputation = 15.0
	player_team.weekly_driver_salary = 50.0
	player_team.weekly_mechanic_salary = 250.0
	all_teams.append(player_team)
	active_championship.team_standings[player_team.id] = 0

func _generate_drivers() -> void:
	var d1_name = NameGenerator.get_full_name(player_team_nationality, "Male")
	var d1 = _create_driver("D-P001", d1_name["first"], d1_name["last"], player_team_nationality, 10, "Male", "T-PLAYER")
	all_drivers[d1.id] = d1
	player_team.drivers.append(d1.id)
	active_championship.standings[d1.id] = 0

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

		var driver_count = 3 if i == 0 else 2
		for j in range(driver_count):
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
	
	# Sponsor income
	_apply_sponsor_income()

	# Full staff expenses
	_apply_weekly_expenses()

	# Check for race this week
	var next_race = active_championship.get_next_race()
	if next_race and next_race["week"] == current_week:
		_simulate_race(next_race)
		_update_sponsor_performance(last_race_results)
		active_championship.current_round += 1
		return

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

func _simulate_race(race_data: Dictionary) -> void:
	add_log("=== RACE %d: %s ===" % [active_championship.current_round + 1, race_data["name"]])
 
	# ── DNS check: player cars need enough fuel to start ──────
	var dns_driver_ids: Array = []
	if player_team.drivers.size() > 0:
		if not _can_car_race(player_team.drivers[0]):
			for d_id in player_team.drivers:
				dns_driver_ids.append(d_id)
 
	# ── Collect all drivers, skipping DNS cars ────────────────
	var race_drivers = []
	for driver_id in active_championship.standings:
		if driver_id in all_drivers and not driver_id in dns_driver_ids:
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
 
	# ── DNS entries: add to last_race_results with 0 pts ─────
	# This ensures they appear in the Results screen (last place, DNS label)
	for d_id in dns_driver_ids:
		var driver = all_drivers.get(d_id)
		if driver:
			driver_times.append({
				"driver": driver,
				"lap_time": 0.0,
				"total_time": 0.0,
				"points": 0,
				"dns": true
			})
 
	# Store last race data
	last_race_round = active_championship.current_round + 1
	last_race_name = race_data["name"]
	last_race_wet = is_wet
	last_race_results = driver_times
 
	# Hall of fame (only if at least one car finished)
	if driver_times.size() > 0:
		# Find first non-DNS entry
		var winner = null
		for entry in driver_times:
			if not entry.get("dns", false):
				winner = entry["driver"]
				break
		if winner:
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
 
	# ── Car condition: degrade based on laps raced, then auto-repair ─────────
	_degrade_car_conditions(race_data["laps"])
	_auto_repair_cars_post_race()

	# Consume fuel and earn RP (always happens, DNS or not)
	_consume_race_resources()
	_earn_race_rp(race_data["laps"])

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

func save_game() -> void:
	var save_data = {
		"version": 1,
		"current_week": current_week,
		"current_season": current_season,
		"weekly_log": weekly_log,
		"hall_of_fame": hall_of_fame,
		"sponsor_no_points_streak": sponsor_no_points_streak,
		"active_sponsor": active_sponsor,
		"player_team": {
			"id": player_team.id,
			"team_name": player_team.team_name,
			"balance": player_team.balance,
			"reputation": player_team.reputation,
			"drivers": player_team.drivers,
		},
		"all_teams": [],
		"all_drivers": {},
		"championship": {
			"current_round": active_championship.current_round,
			"standings": active_championship.standings,
			"team_standings": active_championship.team_standings,
		},
		"campus_buildings": campus_buildings,
		"car_conditions": car_conditions,
	}

	# Save all teams
	for team in all_teams:
		save_data["all_teams"].append({
			"id": team.id,
			"team_name": team.team_name,
			"nationality": team.nationality if "nationality" in team else "British",
			"is_player_team": team.is_player_team,
			"balance": team.balance,
			"reputation": team.reputation,
			"drivers": team.drivers,
			"weekly_driver_salary": team.weekly_driver_salary,
			"weekly_mechanic_salary": team.weekly_mechanic_salary,
		})

	# Save all drivers
	for driver_id in all_drivers:
		var d = all_drivers[driver_id]
		save_data["all_drivers"][driver_id] = {
			"id": d.id,
			"first_name": d.first_name,
			"last_name": d.last_name,
			"nationality": d.nationality,
			"age": d.age,
			"sex": d.sex,
			"contract_team": d.contract_team,
			"active_discipline": d.active_discipline,
			"discipline_change_season": d.discipline_change_season,
			"pace": d.pace,
			"wet": d.wet,
			"focus": d.focus,
			"race_craft": d.race_craft,
			"fitness": d.fitness,
			"potential": d.potential,
			"aggression": d.aggression,
			"experience": d.experience,
			"morale": d.morale,
			"seasons_without_contract": d.seasons_without_contract,
			"discipline_adaptation": d.discipline_adaptation,
			"peak_adaptation": d.peak_adaptation,
		}

	# Write to file
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[Save] Game saved successfully")
	else:
		push_error("[Save] Could not open save file for writing")

func load_game() -> void:
	if not FileAccess.file_exists("user://save_game.json"):
		add_log("No save file found.")
		return

	var file = FileAccess.open("user://save_game.json", FileAccess.READ)
	if not file:
		push_error("[Load] Could not open save file")
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("[Load] JSON parse error: %s" % json.get_error_message())
		return

	var data = json.get_data()

	# Restore basic state
	current_week = data["current_week"]
	current_season = data["current_season"]
	weekly_log.clear()
	for entry in data["weekly_log"]:
		weekly_log.append(str(entry))
	hall_of_fame = data["hall_of_fame"]
	sponsor_no_points_streak = data["sponsor_no_points_streak"]
	active_sponsor = data["active_sponsor"]
	campus_buildings = data["campus_buildings"]
	if "car_conditions" in data:
		car_conditions = data["car_conditions"]
	else:
		_setup_car_conditions()   # backwards-compat for old saves

	# Restore championship
	_setup_championship()
	active_championship.current_round = data["championship"]["current_round"]
	active_championship.standings = data["championship"]["standings"]
	active_championship.team_standings = data["championship"]["team_standings"]

	# Restore teams
	all_teams = []
	all_drivers = {}
	player_team = null

	for team_data in data["all_teams"]:
		var team = Team.new()
		team.id = team_data["id"]
		team.team_name = team_data["team_name"]
		team.nationality = team_data["nationality"]
		team.is_player_team = team_data["is_player_team"]
		team.balance = team_data["balance"]
		team.reputation = team_data["reputation"]
		team.drivers.clear()
		for d in team_data["drivers"]:
			team.drivers.append(str(d))
		team.weekly_driver_salary = team_data["weekly_driver_salary"]
		team.weekly_mechanic_salary = team_data["weekly_mechanic_salary"]
		all_teams.append(team)
		if team.is_player_team:
			player_team = team

	# Restore drivers
	for driver_id in data["all_drivers"]:
		var dd = data["all_drivers"][driver_id]
		var d = Driver.new()
		d.id = dd["id"]
		d.first_name = dd["first_name"]
		d.last_name = dd["last_name"]
		d.nationality = dd["nationality"]
		d.age = dd["age"]
		d.sex = dd["sex"]
		d.contract_team = dd["contract_team"]
		d.active_discipline = dd["active_discipline"]
		d.discipline_change_season = dd["discipline_change_season"]
		d.pace = dd["pace"]
		d.wet = dd["wet"]
		d.focus = dd["focus"]
		d.race_craft = dd["race_craft"]
		d.fitness = dd["fitness"]
		d.potential = dd["potential"]
		d.aggression = dd["aggression"]
		d.experience = dd["experience"]
		d.morale = dd["morale"]
		d.seasons_without_contract = dd["seasons_without_contract"]
		d.discipline_adaptation = dd["discipline_adaptation"]
		d.peak_adaptation = dd["peak_adaptation"]
		all_drivers[driver_id] = d

	print("[Load] Game loaded successfully — Season %d Week %d" % [current_season, current_week])
	emit_signal("week_advanced", current_week)
	emit_signal("log_updated")

func add_log(message: String) -> void:
	weekly_log.append(message)
	print(message)
