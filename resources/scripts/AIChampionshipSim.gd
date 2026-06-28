class_name AIChampionshipSim
## Version: S37.47 — NEW lightweight "living world" result model (Brainstorm thread 3 /
##   FEATURE_AI_Championship_Sim.md). Every non-player, non-GK championship runs each race week via a
##   cheap strength scalar (NOT the full lap-by-lap physics) so its standings populate, Racing World
##   shows real tables, and the end-of-season screen can crown a champion. The player's own
##   championship still runs through the real RaceSimulator; GK runs through GKDiscipline's shadow
##   sim. This engine touches ONLY the previously-empty AI championships.
##
## WHY THIS EXISTS: after the S37.43 Bug-3 fix gated the real _simulate_race to player championships
##   (stopping the "DNS for every championship" spam), non-player championships stopped getting points
##   awarded — their standings (seeded at 0 by AIManager) never moved, so Racing World showed empty
##   tables. This restores a living world WITHOUT re-introducing the spam: it awards points directly
##   via the existing Championship.add_points / points_system, never running the player's race code.
##
## DESIGN (per spec): pure-ish RefCounted, Python-portable. car_strength() is a single pure function
##   isolated so the Phase-5 balance pass can swap its internals for economy-driven inputs (team
##   budgets / character) without touching the plumbing. Strength inputs mirror the REAL sim's
##   weighting (driver effective pace as the spine — see RaceSimulator pace_factor — plus car
##   performance index × condition and a mechanic multiplier), collapsed into one scalar instead of
##   simulating lap times.

var gs   # GameState reference (set in init)

func _init(game_state) -> void:
	gs = game_state

## ── Strength scalar ───────────────────────────────────────────────────────────
## Pure function: a single "race-day strength" for a car. Higher = faster. Mirrors the inputs the
## real lap-time model weights most heavily (Unified Lap Time Formula §4 + effective_pace §23), but
## as ONE cheap number. NO physics, no per-lap loop. Swap-point for the Phase-5 economic model.
func car_strength(car) -> float:
	if car == null:
		return 0.0
	# Driver skill is the spine (matches RaceSimulator: effective_pace dominates pace_factor).
	var driver = gs.all_drivers.get(car.driver_id, null)
	var drv_score := 50.0
	if driver != null:
		var eff_pace: float = driver.get_effective_pace()
		# Blend: pace dominant, consistency + racecraft as secondary contributors.
		drv_score = eff_pace * 0.7 + driver.consistency * 0.2 + driver.race_craft * 0.1
	# Car performance index (baseline from the Cars sheet) scaled by current condition.
	var car_perf: float = float(car.baseline_performance_index) * (car.condition / 100.0)
	# Mechanic multiplier — small, mirrors Staff_Synergy_Factor's direction (a good mechanic helps).
	var mech_mult := 1.0
	var mech = gs.all_staff.get(car.mechanic_id, null)
	if mech != null:
		mech_mult = 1.0 + (mech.car_setup - 50.0) / 500.0  # ±10% across the stat range
	# Combine: driver score (0..~100) + a car-index contribution, then the mechanic multiplier.
	return (drv_score + car_perf) * mech_mult

## ── One race round for ONE championship ───────────────────────────────────────
## Computes a finishing order from car_strength + race-day noise and awards points through the
## championship's existing points table. Skips the player's car (the real sim handles that) so a
## player who happens to share an AI championship isn't double-scored.
func simulate_round(champ) -> void:
	if champ == null:
		return
	var cars: Array = gs.ai_cars.get(champ.id, [])
	if cars.is_empty():
		return
	# Build (driver_id, score) for every AI car that can field a driver.
	var entries: Array = []
	for car in cars:
		if car == null:
			continue
		# Skip the player's own car in this championship — real sim owns that result.
		if car in gs.player_team_cars:
			continue
		if car.driver_id == "":
			continue
		var base: float = car_strength(car)
		# Race-day noise: ±8% so order isn't deterministic (gives plausible upsets without chaos).
		var noise: float = base * randf_range(-0.08, 0.08)
		entries.append({"driver_id": car.driver_id, "score": base + noise})
	if entries.is_empty():
		return
	# Higher score finishes higher.
	entries.sort_custom(func(a, b): return a["score"] > b["score"])
	# Award points via the existing points_system (same path the player's championship uses).
	var pts: Array = champ.points_system
	for i in range(entries.size()):
		if i < pts.size():
			champ.add_points(entries[i]["driver_id"], pts[i])
			# Team points: attribute to the driver's contracted team if present.
			var d = gs.all_drivers.get(entries[i]["driver_id"], null)
			if d != null and d.contract_team != "":
				champ.add_team_points(d.contract_team, pts[i])

## ── Catch-up: simulate all rounds a championship has run up to `target_round` ──
## Used if a championship is first viewed mid-season and somehow missed weekly ticks. Awards the
## missing rounds so standings are coherent. Idempotency is the caller's concern (only call for
## genuinely un-simulated rounds); normal weekly play advances one round at a time via simulate_round.
func simulate_season_to_date(champ, target_round: int) -> void:
	if champ == null:
		return
	var already: int = champ.current_round
	for _r in range(already, target_round):
		simulate_round(champ)
