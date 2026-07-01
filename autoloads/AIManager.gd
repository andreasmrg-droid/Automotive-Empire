extends RefCounted
## Version: S41.4 — AI R&D ECONOMY, PHASE 4: generate_teams() now seeds each AI team's rnd_ledger
##   studio_level from teams.json buildings["RnD Studio"] (previously unread here), CLAMPED to the
##   player's 1..27 R&D Design Studio scale so the RP faucet + design-line math match player and AI.
##   Only the Studio level is seeded; the rest of the ledger stays fresh-zero until the faucet/planner
##   touch it. The clamp/scale is the balance-tunable knob for AI development speed. Analysis-checked;
##   NOT Godot-parsed.
## Version: S41.0 — Designer loader reads the new `planning` attribute (R&D scheduling skill) from
##   staff_designer.json; wide random roll when absent (mirrors talent_scouting). Feeds the AI R&D
##   planner (Supporting Files/AI_RnD_Economy_Spec_v2.md §6). Analysis-checked only; NOT Godot-parsed.
## Version: S37.61 — Bug #38 CREW MODEL: AI standings register only the car representative (seat 0).
## Version: S37.60 — Bug #38 (multi-driver): AI cars get all seats sized (set_seat_count(dpc)) and
##   load_car_assignments fills EVERY seat from the JSON driver_ids array (was lead-only).
## Version: S37.52 — #22: teams.json loop now skips non-team keys (e.g. "_meta" version header)
##   via `if not tid.begins_with("T-")`. Lets the data files carry an inert _meta version stamp
##   without being mistaken for a team. No behavioural change for real T-xxx teams.
## --- S37.15 — #18: Team Principal loader reads talent_scouting from staff_tp.json
## attributes (defaults to a wide random roll when absent).
## Version: S24.2 — Driver loader wired. load_ai_drivers() loads
## drivers_professional.json and drivers_cadets.json.
## Cadets occupy Racing Department slots from day one.
## res://data/staff_tp.json, staff_mechanic.json, staff_pitcrew.json,
## staff_cfo.json, staff_designer.json, staff_strategist.json
## Free agents loaded into GameState.all_staff with contract_team = ""
## Runtime generator (_generate_staff_attributes) fills gaps only.

## Championship name (JSON key) → game championship ID
const CHAMP_MAP: Dictionary = {
	"GP1":            "C-024", "GP2":            "C-023",
	"GP3":            "C-022", "GP4":            "C-021",
	"EPC Hyper":      "C-020", "EPC League":     "C-019",
	"EPC Series":     "C-018",
	"SC Cup":         "C-017", "SC Challenge":   "C-016",
	"SC Truck":       "C-015", "SC Dev":         "C-014",
	"OWC Pro":        "C-013", "OWC Dev":        "C-012",
	"OWC Next Gen":   "C-011",
	"TC Elite":       "C-010", "TC Sport":       "C-009",
	"Premier Rally":  "C-008", "Rally2":         "C-007",
	"Rally3":         "C-006", "Rally4":         "C-005",
	"GK":             "C-001",
}

const DRIVERS_PER_CAR: Dictionary = {
	"C-001":1,
	"C-005":2,"C-006":2,"C-007":2,"C-008":2,
	"C-009":2,"C-010":2,
	"C-011":1,"C-012":1,"C-013":1,
	"C-014":1,"C-015":1,"C-016":1,"C-017":1,
	"C-018":3,"C-019":3,"C-020":3,
	"C-021":1,"C-022":1,"C-023":1,"C-024":1,
}

const OPTIMUM_CARS: Dictionary = {
	"C-001":640,
	"C-005":40, "C-006":30, "C-007":25, "C-008":14,
	"C-009":40, "C-010":30,
	"C-011":30, "C-012":30, "C-013":26,
	"C-014":30, "C-015":30, "C-016":32, "C-017":35,
	"C-018":20, "C-019":20, "C-020":18,
	"C-021":35, "C-022":30, "C-023":22, "C-024":22,
}

## Car assignments — explicit driver/mechanic/pitcrew per car
const CAR_ASSIGNMENTS_FILE: String = "res://data/car_assignments.json"

## Staff JSON files — one per role
const STAFF_FILES: Dictionary = {
	"Team Principal":  "res://data/staff_tp.json",
	"Race Mechanic":   "res://data/staff_mechanic.json",
	"Pit Crew":        "res://data/staff_pitcrew.json",
	"CFO":             "res://data/staff_cfo.json",
	"Designer":        "res://data/staff_designer.json",
	"Race Strategist": "res://data/staff_strategist.json",
}


## Driver JSON files
const DRIVER_FILES: Dictionary = {
	"professional": "res://data/drivers_professional.json",
	"cadets":       "res://data/drivers_cadets.json",
}

## Discipline adaptation applies to these roles only
const DISC_ROLES: Array = ["Team Principal", "Race Mechanic", "Race Strategist"]


## ── Entry Points ──────────────────────────────────────────────────────────────

func generate_teams() -> void:
	var team_data: Dictionary = _load_json("res://data/teams.json")
	if team_data.is_empty():
		push_error("AIManager: failed to load res://data/teams.json")
		return

	for tid in team_data:
		## Skip non-team metadata keys (e.g. "_meta" version header). Only T-xxx entries are teams.
		if not tid.begins_with("T-"):
			continue
		var td: Dictionary = team_data[tid]
		var champ_dict: Dictionary = td.get("championships", {})

		var cid_cars: Dictionary = {}
		for champ_name in champ_dict:
			var cid = CHAMP_MAP.get(champ_name, "")
			if cid == "": continue
			cid_cars[cid] = cid_cars.get(cid, 0) + int(champ_dict[champ_name])

		var active_cid_cars: Dictionary = {}
		for cid in cid_cars:
			for champ in GameState.active_championships:
				if champ.id == cid:
					active_cid_cars[cid] = cid_cars[cid]
					break

		if active_cid_cars.is_empty():
			continue

		var team        = Team.new()
		team.id         = tid
		team.team_name  = td.get("name", "Unknown")
		team.nationality = td.get("nat", "Unknown")
		team.is_player_team = false
		var rep: float  = float(td.get("rep", 50))
		team.reputation = clamp(rep + randf_range(-2.0, 2.0), 10.0, 100.0)
		team.balance    = _starting_balance(rep)
		team.weekly_driver_salary   = _scale(50.0,  500.0, rep)
		team.weekly_mechanic_salary = _scale(80.0, 450.0, rep)

		## S41.4 — AI R&D Economy Phase 4: seed the team's RP-ledger Studio level from teams.json.
		## The data carries a per-team buildings["RnD Studio"] level (previously unread here). The
		## player's R&D Design Studio building caps at level 27 (CampusManager), and design-line
		## capacity = that level, so we CLAMP the JSON value (which ranges well past 27) to 1..27 to
		## keep the RP faucet + line-capacity math on the SAME scale for player and AI. This is the one
		## balance-tunable mapping in the AI faucet — retune the clamp/scale in the Phase-5 pass if the
		## AI world develops too fast/slow. Only the Studio level is seeded now; the rest of the ledger
		## stays at its fresh-zero defaults until the faucet (racing) and planner (spending) touch it.
		var bld: Dictionary = td.get("buildings", {})
		var raw_studio: int = int(bld.get("RnD Studio", 0))
		if raw_studio > 0:
			var seeded_level: int = clampi(raw_studio, 1, 27)
			## Inline the canonical fresh ledger (mirrors RnDEngine._fresh_rnd_ledger) so team
			## generation carries no init-order dependency on _rnd_engine. _ledger_for backfills any
			## keys that drift, so this only needs the shape right + the seeded studio_level.
			team.set_meta("rnd_ledger", {
				"rp": 0.0, "active_tasks": [], "completed_rnd": [], "completed_bp": [],
				"completed_upg": [], "known_blueprints": {}, "wra_active": [], "wra_approved": [],
				"wra_rejected": [], "studio_level": seeded_level,
			})

		GameState.all_teams.append(team)

		for cid in active_cid_cars:
			var num_cars: int = active_cid_cars[cid]
			for champ in GameState.active_championships:
				if champ.id != cid: continue
				champ.team_standings[team.id] = 0
				var reg        = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
				var discipline = reg.get("discipline", "GP")
				var min_age    = reg.get("min_age", 8)
				var max_age    = reg.get("max_age", 35)
				var dpc        = DRIVERS_PER_CAR.get(cid, 1)

				for car_n in range(num_cars):
					var car = Car.new()
					car.id              = "CAR-%s-%s-%d" % [tid, cid, car_n]
					car.championship_id = cid
					car.car_number      = (int(tid.split("-")[1]) * 2 + car_n) % 99 + 1
					car.car_name        = "%s #%d" % [team.team_name, car.car_number]
					car.condition       = 100.0
					car.car_type_id     = reg.get("car_type_id", "A_01")
					car.driver_id       = ""
					car.mechanic_id     = ""
					car.pit_crew_id     = "N/A"
					car.set_seat_count(dpc)   ## S37.60 — size seats to the discipline rule (filled by load_car_assignments)
					car.part_conditions = {
						"Aero":100.0,"Engine":100.0,"Gearbox":100.0,
						"Suspension":100.0,"Brakes":100.0,"Chassis":100.0
					}

					## Drivers are loaded from drivers_professional.json by load_ai_drivers().
					## generate_teams() does NOT create drivers to avoid duplicates.
					## car.driver_id will be assigned after load_ai_drivers() runs.

					_register_ai_car(car, champ)
				break

	## _fill_championship_grids() disabled — JSON has correct driver counts
	## Enable only when optimum car counts need topping up
	## _fill_championship_grids()


func generate_ai_staff() -> void:
	## Loads all 6 staff JSON files.
	## For each team entry: creates Staff objects from JSON data.
	## For free_agents: creates Staff objects with contract_team = "".
	## Falls back to procedural generation if a file is missing.

	var total_loaded: int = 0
	var total_free:   int = 0

	for role in STAFF_FILES:
		var path: String = STAFF_FILES[role]
		var data: Dictionary = _load_json(path)

		if data.is_empty():
			push_error("AIManager: could not load %s — skipping role %s" % [path, role])
			continue

		## ── Team staff ────────────────────────────────────────────────────
		var teams_dict: Dictionary = data.get("teams", {})
		for tid in teams_dict:
			## Only load staff for teams that were actually created
			var team = _find_team(tid)
			if team == null:
				continue

			var staff_list: Array = teams_dict[tid]
			for sd in staff_list:
				var staff = _staff_from_dict(sd)
				if staff == null: continue
				staff.contract_team = tid
				GameState.all_staff[staff.id] = staff
				total_loaded += 1

		## ── Free agents ───────────────────────────────────────────────────
		var free_list: Array = data.get("free_agents", [])
		for sd in free_list:
			var staff = _staff_from_dict(sd)
			if staff == null: continue
			staff.contract_team = ""
			staff.contract_seasons_remaining = 0
			GameState.all_staff[staff.id] = staff
			total_free += 1

	print("[AIManager] Staff loaded: %d contracted + %d free agents" % [total_loaded, total_free])



func load_ai_drivers() -> void:
	## Loads professional drivers and cadets from JSON files.
	## Each driver is created as a Driver object and stored in GameState.all_drivers.
	## Cadets are linked to their academy team via contract_team AND academy_team.
	## Professional free agents have contract_team = "".

	var total_pro:    int = 0
	var total_cadet:  int = 0
	var total_fa:     int = 0

	## ── Professional drivers ────────────────────────────────────────────────
	var pro_data: Dictionary = _load_json(DRIVER_FILES["professional"])
	if not pro_data.is_empty():
		## Team drivers
		var teams_dict: Dictionary = pro_data.get("teams", {})
		for tid in teams_dict:
			var team = _find_team(tid)
			if team == null: continue
			for dd in teams_dict[tid]:
				var driver = _driver_from_dict(dd)
				if driver == null: continue
				driver.contract_team = tid
				GameState.all_drivers[driver.id] = driver
				team.drivers.append(driver.id)
				total_pro += 1

		## Free agents
		for dd in pro_data.get("free_agents", []):
			var driver = _driver_from_dict(dd)
			if driver == null: continue
			driver.contract_team = ""
			GameState.all_drivers[driver.id] = driver
			total_fa += 1

	## ── Cadet drivers ───────────────────────────────────────────────────────
	var cadet_data: Dictionary = _load_json(DRIVER_FILES["cadets"])
	if not cadet_data.is_empty():
		for tid in cadet_data.get("teams", {}):
			var team = _find_team(tid)
			## Only load if team is in active championships
			## Prevents GKDiscipline from being flooded with inactive cadets
			if team == null: continue
			for dd in cadet_data["teams"][tid]:
				var driver = _driver_from_dict(dd)
				if driver == null: continue
				driver.is_cadet      = true
				driver.academy_team  = tid
				driver.contract_team = tid
				GameState.all_drivers[driver.id] = driver
				team.drivers.append(driver.id)
				total_cadet += 1

	print("[AIManager] Drivers loaded: %d professional + %d cadets + %d free agents" \
		% [total_pro, total_cadet, total_fa])


## ── Driver Object Builder ─────────────────────────────────────────────────────

var _driver_id_counter: int = 20000  ## Above staff counter to avoid collisions

func _driver_from_dict(dd: Dictionary) -> Driver:
	if dd.is_empty(): return null

	_driver_id_counter += 1
	var d           = Driver.new()
	d.id            = dd.get("id", "DRV-AI-%05d" % _driver_id_counter)
	d.first_name    = dd.get("first", "Unknown")
	d.last_name     = dd.get("last",  "Driver")
	d.nationality   = NameGenerator.resolve_nationality(dd.get("nat", "GBR"))
	d.sex           = dd.get("sex", "Male")
	d.age           = int(dd.get("age", 25))
	d.contract_team = dd.get("contract_team", "")
	d.contract_seasons_remaining = int(dd.get("contract_seasons", 1))
	d.weekly_salary = float(dd.get("weekly_salary", 100))
	d.active_discipline = dd.get("active_discipline", dd.get("primary_disc", "GP4"))
	## Visible stats
	d.pace          = float(dd.get("pace",        50))
	d.car_control   = float(dd.get("car_control", 50))
	d.focus         = float(dd.get("focus",       50))
	d.race_craft    = float(dd.get("race_craft",  50))
	d.consistency   = float(dd.get("consistency", 50))
	d.feedback      = float(dd.get("feedback",    50))
	d.marketability = float(dd.get("reputation",  20))
	## Dynamic
	d.fitness       = 100.0
	d.morale        = 100.0
	## Hidden
	d.fatigue_resistance = float(dd.get("fatigue_resistance", 50))
	d.potential     = float(dd.get("potential",   50))
	d.aggression    = float(dd.get("aggression",  50))
	d.experience    = float(dd.get("experience",  0))
	## Cadet flags
	d.is_cadet               = bool(dd.get("is_cadet", false))
	d.academy_team           = dd.get("academy_team", "")
	d.contract_type          = dd.get("contract_type", "professional")
	d.academy_upkeep_income  = int(dd.get("academy_upkeep_income", 0))
	## Adaptation
	var da: Dictionary = dd.get("discipline_adaptation", {})
	var pa: Dictionary = dd.get("peak_adaptation", {})
	for disc in ["GP","EPC","SC","OWC","TC","Rally","GK"]:
		d.discipline_adaptation[disc] = float(da.get(disc, 1.0))
		d.peak_adaptation[disc]       = float(pa.get(disc, 1.0))
	## Track knowledge — starts empty, grows with races
	d.track_knowledge = {}
	return d

## ── Staff Object Builder ──────────────────────────────────────────────────────

var _staff_id_counter: int = 10000  ## Start above GameState counter to avoid collisions

func _staff_from_dict(sd: Dictionary) -> Staff:
	if sd.is_empty(): return null

	_staff_id_counter += 1
	var s          = Staff.new()
	s.id           = "ST-AI-%05d" % _staff_id_counter
	s.role         = sd.get("role", "Race Mechanic")
	s.first_name   = sd.get("first", "Unknown")
	s.last_name    = sd.get("last",  "Staff")
	s.nationality  = NameGenerator.resolve_nationality(sd.get("nat", "GBR"))
	s.sex          = sd.get("sex", "Male")
	s.age          = int(sd.get("age", 30))
	s.talent       = float(sd.get("talent", 50))
	s.reputation   = float(sd.get("reputation", 30))
	s.morale       = randf_range(70.0, 100.0)
	s.weekly_salary              = float(sd.get("weekly_salary", 200))
	s.contract_seasons_remaining = int(sd.get("contract_seasons", 1))
	s.release_clause             = int(sd.get("release_clause", 1000))

	## Discipline adaptation (TP, Mechanic, Strategist only)
	if s.role in DISC_ROLES:
		var da: Dictionary = sd.get("discipline_adaptation", {})
		for disc in ["GP","EPC","SC","OWC","TC","Rally","GK"]:
			s.discipline_adaptation[disc] = float(da.get(disc, 10.0))

	## Fitness (Pit Crew)
	if s.role == "Pit Crew":
		s.fitness            = 100.0
		s.fatigue_resistance = float(sd.get("fatigue_resistance", 50.0))

	## Role attributes
	var attrs: Dictionary = sd.get("attributes", {})

	match s.role:
		"Team Principal":
			s.race_strategy         = float(attrs.get("race_strategy",         50.0))
			s.practice_management   = float(attrs.get("practice_management",   50.0))
			s.qualifying_management = float(attrs.get("qualifying_management", 50.0))
			s.race_pace_reading     = float(attrs.get("race_pace_reading",     50.0))
			s.car_setup_oversight   = float(attrs.get("car_setup_oversight",   50.0))
			s.pit_stop_management   = float(attrs.get("pit_stop_management",   50.0))
			s.pr_skill              = float(attrs.get("pr_skill",              50.0))
			s.parts_knowledge       = float(attrs.get("parts_knowledge",       50.0))
			s.track_knowledge       = float(attrs.get("track_knowledge",       10.0))
			s.talent_scouting       = float(attrs.get("talent_scouting",       randf_range(10.0, 90.0)))

		"Race Mechanic":
			s.car_setup       = float(attrs.get("car_setup",       50.0))
			s.pit_stops       = float(attrs.get("pit_stops",       50.0))
			s.parts_knowledge = float(attrs.get("parts_knowledge", 50.0))
			s.track_knowledge = float(attrs.get("track_knowledge", 10.0))
			s.race_pace       = float(attrs.get("race_pace",       50.0))

		"Pit Crew":
			s.pit_stop_speed = float(attrs.get("pit_stop_speed", 50.0))
			s.repair_skill   = float(attrs.get("repair_skill",   50.0))

		"CFO":
			s.loan_management     = float(attrs.get("loan_management",     50.0))
			s.sales_skill         = float(attrs.get("sales_skill",         50.0))
			s.sponsor_negotiation = float(attrs.get("sponsor_negotiation", 50.0))
			s.resource_management = float(attrs.get("resource_management", 50.0))
			s.budget_planning     = float(attrs.get("budget_planning",     50.0))
			s.speculation         = float(attrs.get("speculation",         50.0))

		"Designer":
			s.engine          = float(attrs.get("engine",          50.0))
			s.aero            = float(attrs.get("aero",            50.0))
			s.brakes          = float(attrs.get("brakes",          50.0))
			s.suspension      = float(attrs.get("suspension",      50.0))
			s.chassis         = float(attrs.get("chassis",         50.0))
			s.gearbox         = float(attrs.get("gearbox",         50.0))
			s.reliability     = float(attrs.get("reliability",     50.0))
			s.parts_knowledge = float(attrs.get("parts_knowledge", 50.0))
			## S41.0 — R&D scheduling skill; wide random roll when the JSON omits it (mirrors how the
			## TP's talent_scouting defaults). Feeds the forecast-driven planner.
			s.planning        = float(attrs.get("planning",        randf_range(10.0, 90.0)))

		"Race Strategist":
			s.race_strategy       = float(attrs.get("race_strategy",       50.0))
			s.race_pace_reading   = float(attrs.get("race_pace_reading",   50.0))
			s.practice_scheduling = float(attrs.get("practice_scheduling", 50.0))
			s.qualifying_timing   = float(attrs.get("qualifying_timing",   50.0))
			s.track_knowledge     = float(attrs.get("track_knowledge",     10.0))

	return s



func load_car_assignments() -> void:
	## Reads car_assignments.json and sets driver_id, mechanic_id, pit_crew_id
	## on every AI car. No runtime logic — pure JSON read and apply.

	var data: Dictionary = _load_json(CAR_ASSIGNMENTS_FILE)
	if data.is_empty():
		push_error("AIManager: failed to load car_assignments.json")
		return

	var assigned_drivers:  int = 0
	var assigned_mechs:    int = 0
	var assigned_pit:      int = 0
	var not_found:         int = 0

	var teams_data: Dictionary = data.get("teams", {})

	for tid in teams_data:
		var car_list: Array = teams_data[tid]
		for car_entry in car_list:
			var car_id:   String = car_entry.get("car_id", "")
			var cid:      String = car_entry.get("championship_id", "")
			var drv_ids:  Array  = car_entry.get("driver_ids", [])
			var mech_id:  String = car_entry.get("mechanic_id", "")
			var pit_id:   String = car_entry.get("pit_crew_id", "")

			## Find the car object in ai_cars
			var car = _find_car(car_id, cid)
			if car == null:
				not_found += 1
				continue

			## Assign ALL drivers to their seats (S37.60 multi-driver). The JSON already
			## carries the full driver_ids array per car; size the car's seats to the
			## discipline rule, then seat each driver. (Previously only drv_ids[0] was set,
			## so Rally/TC/EPC AI cars showed a single driver despite the data.)
			if drv_ids.size() > 0:
				car.set_seat_count(GameState.get_drivers_per_car(cid))
				for si in range(min(drv_ids.size(), car.driver_ids.size())):
					car.driver_ids[si] = drv_ids[si]
				assigned_drivers += 1

			## Assign mechanic
			if mech_id != "":
				car.mechanic_id = mech_id
				assigned_mechs += 1

			## Assign pit crew
			if pit_id != "":
				car.pit_crew_id = pit_id
				assigned_pit += 1

			## Register the CAR REPRESENTATIVE (seat 0) in championship standings — skip GK.
			## S37.61 crew model: co-drivers share one car result, so only one entry per car.
			## GK standings managed exclusively by GKDiscipline.populate_season().
			var disc_check = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {}).get("discipline", "")
			if disc_check != "GK" and drv_ids.size() > 0:
				var rep_did: String = drv_ids[0]
				for champ in GameState.active_championships:
					if champ.id != cid: continue
					if not champ.standings.has(rep_did):
						champ.standings[rep_did] = 0
					break

	print("[AIManager] Cars assigned: %d drivers, %d mechanics, %d pit crews (%d cars not found)" \
		% [assigned_drivers, assigned_mechs, assigned_pit, not_found])


func _find_car(car_id: String, cid: String):
	## Finds a car object in GameState.ai_cars by its ID.
	for car in GameState.ai_cars.get(cid, []):
		if car.id == car_id:
			return car
	return null

## ── Helpers ───────────────────────────────────────────────────────────────────

func _register_ai_car(car, champ: Championship) -> void:
	if champ.id in GameState.ai_cars:
		GameState.ai_cars[champ.id].append(car)
	else:
		GameState.ai_cars[champ.id] = [car]


func _rep_to_tier(rep: float) -> int:
	if rep >= 85.0: return 4
	if rep >= 70.0: return 3
	if rep >= 55.0: return 2
	return 1


func _scale(low: float, high: float, rep: float) -> float:
	var t = clamp((rep - 20.0) / 80.0, 0.0, 1.0)
	return low + (high - low) * t


func _starting_balance(rep: float) -> float:
	return _scale(50000.0, 5000000.0, rep)


func _find_team(tid: String):
	for t in GameState.all_teams:
		if t.id == tid:
			return t
	return null


func _fill_championship_grids() -> void:
	for champ in GameState.active_championships:
		var cid      = champ.id
		var current  = champ.standings.size()
		var optimum  = OPTIMUM_CARS.get(cid, 20)

		## GK population is handled entirely by GKDiscipline.populate_season()
		## Do NOT generate filler drivers here — it causes duplicate GK drivers
		if GameState.CHAMPIONSHIP_REGISTRY.get(cid, {}).get("discipline","") == "GK":
			continue

		var needed = optimum - current
		if needed <= 0: continue

		var reg        = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var discipline = reg.get("discipline", "GP")
		var min_age    = reg.get("min_age", 8)
		var max_age    = reg.get("max_age", 35)

		for i in range(needed):
			var fteam_id = "T-FILL-%s-%03d" % [cid, i]
			var fteam    = _get_or_create_filler_team(fteam_id, discipline)
			var drv_id   = "D-FILL-%s-%03d" % [cid, i]
			var nat      = NameGenerator.get_nationality_for_team(fteam.nationality)
			var sex      = "Male" if randf() > 0.28 else "Female"
			var age      = randi_range(max(min_age, 8), min(max_age, min_age + 18))
			var name_data = NameGenerator.get_full_name(nat, sex)
			var driver   = GameState._create_driver_for_discipline(
				drv_id, name_data["first"], name_data["last"],
				nat, age, sex, discipline, 1)
			driver.contract_team = fteam.id
			GameState.all_drivers[drv_id] = driver
			fteam.drivers.append(drv_id)
			champ.standings[drv_id] = 0
			champ.team_standings[fteam.id] = champ.team_standings.get(fteam.id, 0)


func _get_or_create_filler_team(team_id: String, discipline: String):
	for t in GameState.all_teams:
		if t.id == team_id: return t

	const FILLER_NAMES: Dictionary = {
		"GK":    ["Leeds GK Garage","Brescia Karting","Lyon Kart Club","Bilbao Karting",
				  "Cologne Customizations","Osaka Track Days","Sydney Kart Club"],
		"Rally": ["Gravel Storm","Forest Stage Racing","Tarmac Collective",
				  "Dirt Road Team","Stage Fright Racing"],
		"TC":    ["Touring Club Racing","Regional GT","Local TC Team","Circuit Club"],
		"OWC":   ["Open Wheel Academy","Formula Privateer","Local OWC Team"],
		"SC":    ["Short Track Racing","Grassroots Stock","Local Speedway Team"],
		"EPC":   ["Endurance Club","Local Prototype","GT Privateer"],
		"GP":    ["Formula Academy","Junior GP Team","Regional Formula"],
	}
	const FILLER_NATS = [
	# Europe
	"GBR", "ITA", "GER", "FRA", "ESP", "NLD", "BEL", "PRT", "GRC",
	"SWE", "DNK", "FIN", "NOR", "CHE", "AUT", "POL", "CZE", "HUN",
	"ROU", "HRV", "SRB", "TUR", "UKR", "IRL", "SCO", "WAL", "LUX",
	"CAT", "MCO",

	# Americas
	"USA", "CAN", "MEX", "BRA", "ARG", "COL", "CHL", "VEN", "URY", "PER",

	# Asia & Middle East
	"JPN", "KOR", "CHN", "IND", "THA", "MYS", "IDN",
	"UAE", "KSA", "QAT", "KWT", "LBN", "MAR", "EGY",

	# Oceania & Africa
	"AUS", "NZL", "ZAF", "KEN",

	# Russia
	"RUS"
	]

	var names = FILLER_NAMES.get(discipline, ["Local Racing Team"])
	var team  = Team.new()
	team.id            = team_id
	team.team_name     = names[randi() % names.size()]
	team.nationality   = FILLER_NATS[randi() % FILLER_NATS.size()]
	team.is_player_team = false
	team.reputation    = randf_range(10.0, 35.0)
	team.balance       = randf_range(15000.0, 60000.0)
	team.weekly_driver_salary   = 50.0
	team.weekly_mechanic_salary = 120.0
	GameState.all_teams.append(team)
	return team


func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("AIManager: cannot open %s" % path)
		return {}
	var text   = file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if result == null:
		push_error("AIManager: failed to parse %s" % path)
		return {}
	if typeof(result) != TYPE_DICTIONARY:
		push_error("AIManager: %s is not a JSON object" % path)
		return {}
	return result
