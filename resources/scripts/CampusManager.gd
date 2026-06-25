class_name CampusManager
## Version: S37.3 — Bug #5: HQ sponsor slots now increase at ODD levels (1,3,5...) not even —
##   get_hq_sponsor_slots() = 1 + int((level-1)/2). L1=1, L3=2, L5=3, ... L26=13.
## Version: S27.0 — Extracted from GameState.gd (P57)
##   Buildings, upgrades, construction, income/maintenance, stat bonuses.
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

func _setup_campus() -> void:
	gs.campus_buildings = {
		# ── COMMAND ZONE ─────────────────────────────────────────────────────
		# HQ: pre-built, Level 1. Upgrade cost reflects expanding admin infrastructure.
		# Real small motorsport HQ renovation: CR 40K-CR 150K per phase.
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
		# Real small logistics depot fit-out: CR 15K-CR 60K.
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
		# Real motorsport garage bay fit-out: CR 20K-CR 80K per expansion.
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
			"effects": "+CR 1800 weekly repair profit\n+CR 450 per level"
		},
		# Racing Dept: pre-built. Upgrade = strategy tools, data systems, staff desks.
		# Real motorsport operations room setup: CR 15K-CR 50K.
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
		# Real small engineering design studio: CR 80K-CR 200K. Mid-game goal.
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
		# CNC Plant: serious manufacturing investment. Real small CNC shop: CR 150K-CR 400K.
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
		# Ops Sim: simulator rigs + telemetry servers. Real setup: CR 60K-CR 180K.
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
		# Wind Tunnel: endgame prestige facility. Real F1-grade: CR 20M-CR 80M.
		# Scaled down but still a major late-game milestone. CR 800K feels right
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
		# CR 2M-CR 10M. This is a true endgame building — long save goal.
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
		# Museum: motorsport heritage display. Real small museum fit-out: CR 80K-CR 250K.
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
			"effects": "+CR 2400 weekly passive income\n+CR 380 per level"
		},
		# Theme Park: major entertainment complex. Real small motorsport theme park:
		# CR 2M-CR 15M. Scaled to be a late-game passive income machine.
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
			"effects": "+CR 12000 weekly passive income\n+CR 1500 per level"
		},
		# Public Racing Club: track day/member club. Enables income from all track buildings.
		# No direct income — its value is unlocking Karting/Gravel/Oval/Race Track income.
		"Public Racing Club": {
			"name": "Public Racing Club",
			"built": false,
			"level": 0,
			"max_level": 7,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 850,
			"weekly_income": 0,  ## Calculated dynamically: upkeep × 1.02 (see get_building_income)
			"build_cost": 55000,
			"build_time": 12,
			"upgrade_cost": 18000,
			"upgrade_time": 6,
			"effects": "Enables income from Karting, Gravel, Oval and Race Track buildings.\n+10% track income per PRC level.\nProvides Passive income "
		},
		# Merchandise Store: team shop. Real small branded retail fit-out: CR 20K-CR 60K.
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
			"effects": "+CR 1800 weekly passive income\n+CR 280 per level"
		},
		# ── HUMAN PERFORMANCE ZONE ───────────────────────────────────────────
		# Fitness Clinic: driver/crew gym and physio suite. Real sports clinic: CR 80K-CR 200K.
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
		# Pit Crew Arena: dedicated pit stop practice rig. Real setup: CR 30K-CR 150K.
		# Tangible race performance investment — mid-game priority.
		"Pit Crew Arena": {
			"name": "Pit Crew Arena",
			"built": false,
			"level": 0,
			"max_level": 20,
			"construction_weeks_remaining": 0,
			"weekly_maintenance": 1150,
			"weekly_income": 0,
			"build_cost": 30000,
			"build_time": 10,
			"upgrade_cost": 15000,
			"upgrade_time": 4,
			"effects": "-0.1s pit stop time\n-1% pit stop time per level"
		},
		# Academy: driver development program facility. Real junior academy setup:
		# CR 100K-CR 300K including simulators, coaching infrastructure.
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
		# Karting Track: real outdoor kart circuit construction: CR 150K-CR 600K.
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
			"effects": "+5% Go-Kart performance\n+CR 2500 weekly income"
		},
		# Gravel Track: rally stage with gravel surface, spectator areas, safety zones.
		# Real rally stage construction: CR 200K-CR 800K.
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
			"effects": "+5% Rally performance\n+CR 2200 weekly income"
		},
		# Oval Track: banked oval with concrete surface. Real small oval: CR 400K-CR 1.5M.
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
			"effects": "+5% Oval performance\n+CR 3000 weekly income"
		},
		# Race Track: full tarmac road course with pit lane, marshal posts, timing.
		# Real small circuit (2-3km): CR 1.5M-CR 8M. Major endgame investment.
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
			"effects": "+3% Road course performance\n+CR 8500 weekly income"
		},
	}


func get_building(building_id: String) -> Dictionary:
	return gs.campus_buildings.get(building_id, {})


func start_building(building_id: String) -> void:
	if not building_id in gs.campus_buildings:
		return
	var building = gs.campus_buildings[building_id]
	if building["built"]:
		return
	if gs.player_team.balance < building["build_cost"]:
		return
	gs.player_team.balance -= building["build_cost"]
	building["built"] = true
	building["construction_weeks_remaining"] = building["build_time"]
	building["level"] = 0
	gs.add_log("🏗 Construction started: %s (%d weeks)" % [building["name"], building["build_time"]])
	gs.emit_signal("log_updated")

## Returns the scaled upgrade cost for the next level.
## Formula: base_cost * 1.5^current_level, rounded to nearest CR 500.
## ── Championship Registration ────────────────────────────────────────────────

## Returns true if the player can still register for a championship this season.


func sell_building(building_id: String) -> void:
	var building = gs.campus_buildings.get(building_id, {})
	if building.is_empty() or not building["built"]:
		return
	var refund = int(building["build_cost"] * 0.3)
	gs.player_team.balance += refund
	building["built"] = false
	building["level"] = 0
	building["construction_weeks_remaining"] = 0
	gs.add_log("🏚 %s sold — CR %s refunded (30%% of build cost)." % [building["name"], gs._fmt_int(refund)])
	gs.add_notification("Normal", "%s sold for CR %s." % [building["name"], gs._fmt_int(refund)])
	gs.emit_signal("log_updated")

## Returns true if the player has a blueprint (completed R&D) for a part type.


func start_upgrade(building_id: String) -> void:
	if not building_id in gs.campus_buildings:
		return
	var building = gs.campus_buildings[building_id]
	if not building["built"]:
		return
	if building["construction_weeks_remaining"] > 0:
		return
	if building["level"] >= building["max_level"]:
		return
	var cost = get_upgrade_cost(building)
	var weeks = get_upgrade_time(building)
	if gs.player_team.balance < cost:
		return
	gs.player_team.balance -= cost
	building["construction_weeks_remaining"] = weeks
	gs.add_log("⬆ Upgrade started: %s to Level %d (CR %d, %d weeks)" % [
		building["name"],
		building["level"] + 1,
		cost,
		weeks,
	])
	gs.emit_signal("log_updated")


func _update_campus_construction() -> void:
	for building_id in gs.campus_buildings:
		var building = gs.campus_buildings[building_id]
		if building["built"] and building["construction_weeks_remaining"] > 0:
			building["construction_weeks_remaining"] -= 1
			if building["construction_weeks_remaining"] == 0:
				building["level"] += 1
				gs.add_log("✅ %s complete! Now Level %d" % [building["name"], building["level"]])


func get_upgrade_cost(building: Dictionary) -> int:
	var base  = building["upgrade_cost"]
	var level = max(0, building["level"] - 1)  ## L1→2 = base, L2→3 = base×1.5, etc.
	var scaled = base * pow(1.5, level)
	return int(round(scaled / 500.0) * 500)

## Returns the scaled upgrade time for the next level.


func get_upgrade_time(building: Dictionary) -> int:
	var base  = building["upgrade_time"]
	var level = max(0, building["level"] - 1)  ## L1→2 = base, scales from there
	return max(base, int(ceil(base * (1.0 + level * 0.3))))

## Weekly income increment per level — from Excel Buildings sheet Effects_Per_Level column.
const BUILDING_INCOME_PER_LEVEL = {
	"Garage":              450,   # repair profit per level
	"Museum":              380,
	"Theme Park":          650,
	"Merchandise Store":   420,
	"Karting Track":       160,
	"Gravel Track":        140,
	"Oval Track":          170,
	"Race Track":          220,
}

## Track buildings only generate income when Public Racing Club is built.
## PRC level also multiplies track income by +10% per level.
const TRACK_BUILDINGS = ["Karting Track", "Gravel Track", "Oval Track", "Race Track"]

## Returns current weekly income: income_level1 + income_per_level × (level - 1).
## Track buildings return 0 unless Public Racing Club is built.
## PRC level multiplies track income by (1 + prc_level × 0.10).


func get_building_income(building: Dictionary) -> int:
	var bname = building["name"]
	if not building.get("built", false) or building.get("level", 0) <= 0:
		return 0

	var active_fans = gs.get_team_active_fans()
	var mktg = gs.get_team_marketability()
	## log10 of fans keeps numbers sensible across the massive fan range
	## (169 fans → 2.2, 28M fans → 7.4)
	var fan_log = log(active_fans + 10.0) / log(10.0)

	## Public Racing Club: income = upkeep × 1.02, scales with level + fan bonus
	if bname == "Public Racing Club":
		var maintenance = get_building_maintenance(building)
		var base_income = int(maintenance * 1.02)
		## Small local fan bonus: +1 CR per 5000 active fans, capped at 5× base
		var fan_bonus = clamp(int(active_fans / 5000.0), 0, base_income * 4)
		return base_income + fan_bonus

	## Museum: heritage prestige × fans × reputation
	if bname == "Museum":
		if not building.get("built", false): return 0
		var team_wins = 0
		for entry in gs.hall_of_fame:
			if entry.get("team_id", "") == gs.player_team.id:
				team_wins += 1
		if team_wins == 0: return 0
		var base = building["weekly_income"]
		var per_level = BUILDING_INCOME_PER_LEVEL.get("Museum", 380)
		var level_income = base + per_level * max(0, building["level"] - 1)
		## Fan multiplier: log10(fans) × reputation/50
		var fan_mult = fan_log * (gs.player_team.reputation / 50.0)
		return int(level_income * max(1.0, fan_mult) * (1.0 + team_wins * 0.1))

	## Theme Park: biggest fan-driven income
	if bname == "Theme Park":
		var base = building["weekly_income"]
		var per_level = BUILDING_INCOME_PER_LEVEL.get("Theme Park", 0)
		var level_income = base + per_level * max(0, building["level"] - 1)
		## log10^1.5 scales faster with fans; needs marketability
		var fan_mult = pow(fan_log, 1.5) * (mktg / 60.0)
		return int(level_income * max(0.5, fan_mult))

	## Merchandise Store: fans × marketability
	if bname == "Merchandise Store":
		var base = building["weekly_income"]
		var per_level = BUILDING_INCOME_PER_LEVEL.get("Merchandise Store", 420)
		var level_income = base + per_level * max(0, building["level"] - 1)
		var fan_mult = fan_log * (mktg / 50.0)
		return int(level_income * max(0.5, fan_mult))

	if bname in TRACK_BUILDINGS:
		var prc = gs.campus_buildings.get("Public Racing Club", {})
		if not prc.get("built", false): return 0
		var level     = building["level"]
		var base      = building["weekly_income"]
		var per_level = BUILDING_INCOME_PER_LEVEL.get(bname, 0)
		var raw_income = base + per_level * max(0, level - 1)
		var prc_level = prc.get("level", 1)
		return int(raw_income * (1.0 + prc_level * 0.10))

	var level     = building["level"]
	var base      = building["weekly_income"]
	var per_level = BUILDING_INCOME_PER_LEVEL.get(bname, 0)
	return base + per_level * max(0, level - 1)

## Returns current weekly maintenance: maintenance_level1 × 1.10^(level-1), rounded to CR 50.


func get_building_maintenance(building: Dictionary) -> int:
	var level  = building["level"]
	var base   = building["weekly_maintenance"]
	var scaled = base * pow(1.10, max(0, level - 1))
	return int(round(scaled / 50.0) * 50)

## ── Building bonus helpers ────────────────────────────────────────────────────

## Returns how many drivers are required per car for a given championship.


func get_logistics_parts_discount() -> float:
	var lc = gs.campus_buildings.get("Logistics Center", {})
	if not lc.get("built", false): return 1.0
	return max(0.5, 1.0 - lc.get("level", 1) * 0.01)


func get_fitness_fatigue_reduction() -> float:
	var fc = gs.campus_buildings.get("Fitness Clinic", {})
	if not fc.get("built", false): return 0.0
	var level = fc.get("level", 1)
	return 0.10 + (level - 1) * 0.005


func get_pit_crew_time_bonus() -> float:
	var pca = gs.campus_buildings.get("Pit Crew Arena", {})
	if not pca.get("built", false): return 0.0
	var level = pca.get("level", 1)
	return 0.1 * pow(1.01, level - 1)


func get_wind_tunnel_aero_bonus() -> float:
	var wt = gs.campus_buildings.get("Aerodynamic Wind Tunnel", {})
	if not wt.get("built", false): return 0.0
	var level = wt.get("level", 1)
	return 0.10 + (level - 1) * 0.05


func get_ops_sim_track_knowledge_base() -> float:
	var ops = gs.campus_buildings.get("Ops Sim & Telemetry", {})
	if not ops.get("built", false): return 0.0
	return 25.0 + float(ops.get("level", 1) - 1)


func get_racing_dept_driver_bonus() -> float:
	var rd = gs.campus_buildings.get("Racing Department", {})
	if not rd.get("built", false): return 0.0
	return 10.0 + (rd.get("level", 1) - 1) * 5.0


func get_hq_marketability_bonus() -> float:
	var hq = gs.campus_buildings.get("Headquarters", {})
	if not hq.get("built", false): return 0.0
	return float(hq.get("level", 1))

## TP slots = 1 per HQ level (level 1 = 1 slot, level 5 = 5 slots)


func get_hq_tp_slots() -> int:
	var hq = gs.campus_buildings.get("Headquarters", {})
	if not hq.get("built", false): return 1
	return max(1, hq.get("level", 1))


func get_hq_sponsor_slots() -> int:
	var hq = gs.campus_buildings.get("Headquarters", {})
	if not hq.get("built", false): return 1
	## Bug #5: sponsor slots increase at ODD levels (1,3,5...), not even.
	## L1=1, L2=1, L3=2, L4=2, L5=3, L6=3 ...  (formula: 1 + int((level-1)/2))
	return 1 + int((hq.get("level", 1) - 1) / 2)
