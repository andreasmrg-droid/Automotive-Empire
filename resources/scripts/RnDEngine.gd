class_name RnDEngine
## Version: S35.19 — P4 unlock now ALSO enforces Required_RnD_Studio_Level (the R&D Design Studio
##   building level). The data carried this on every Special Project but it was never checked; now
##   a project needs both its target building AND the Studio at/above the required level. Gate
##   order: prerequisite task → target building → Studio level.
## Version: S35.11c — start_rnd_task now carries `season` + `level` on the active task. They were
##   absent, so at completion the stored blueprint fell back to gs.current_season → P1/P3
##   next-season blueprints were stamped with the CURRENT season. That broke TWO things: TDL 8a
##   "submit to WRA" never fired for them, and the CNC season-gate never blocked them (player
##   could build next-season parts in the current season). Now stamped correctly as next season.
## Version: S35.11b — CNC part performance + blueprint persistence:
##   • get_cnc_part_bonus reworked: per-part on-track bonus = value × quality (was a flat
##     0.005/part that ignored everything AND mis-read the part dict as an int). Capped at
##     CNC_BONUS_CAP=0.15. ⚠ FORMULA FLAGGED FOR FUTURE REVIEW (GDD §8). Reliability excluded.
##   • CNC completion no longer deletes the WRA approval (issue 3) — a blueprint stays a
##     manufacturing licence so the player can build spares; cleared only at rollover/WRA reset.
## Version: S35.11 — R&D chain season-rollover correctness:
##   • P1 (Design) + P3 (Reverse Engineering) now stamp design_season = current+1 and embed
##     S{n+1} in id AND name; P2 (Upgrade) embeds its current S{n} in the name (id already did).
##     Naming is load-bearing: the rollover identifies which blueprints to purge vs. activate.
##   • P1 L2 unlocks when an L1 blueprint exists from EITHER P1 or P3 (part-level prereq via
##     requires_l1_for / _has_l1_blueprint_for), so RE genuinely opens L2.
##   • RE penalty is designer-scaled (formula ii, floor 0.75: 0.75 + 0.25×stat/100) and baked
##     into `quality` ONCE; P1 L2 inherits the lineage quality (_lineage_quality_for) so the
##     penalty rides the whole percentage chain. resolve_active_l1_blueprint() picks the
##     better of a P1 vs P3 L1 (value×quality) as the valid build source.
## --- S31.1 — Bug 8: start_cnc_job blocks manufacturing of a blueprint whose target
##   season is in the future (bp.season > current_season) — a next-season part can no longer
##   be built in the current season. Single choke point, so it also covers Build Whole Car.
## --- S28.3 — CNC production now slot-limited (get_cnc_slots from plant level): jobs
##   beyond the slot count queue and only start when a slot frees (issue 4).
## --- S27.0 — Extracted from GameState.gd (P57)
##   R&D tasks, WRA submissions, CNC production, blueprint management.
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

func _build_rnd_tasks() -> Dictionary:
	return _build_rnd_tasks_for_season(gs.current_season)

## Regenerates season-specific tasks. Called on start_new_season() and after load().


func _rebuild_seasonal_rnd_tasks() -> void:
	var p4_tasks: Dictionary = {}
	for k in gs.RND_TASKS:
		if gs.RND_TASKS[k].get("pillar", 0) == 4:
			p4_tasks[k] = gs.RND_TASKS[k]
	gs.RND_TASKS = _build_rnd_tasks_for_season(gs.current_season)
	for k in p4_tasks:
		if not k in gs.RND_TASKS:
			gs.RND_TASKS[k] = p4_tasks[k]

## Generates P1/P2/P3/P4 tasks for a given season.
## IDs: BP-{CHAMP}-{PART}-S{n}-L{lv} | UPG-... | RE-...-L1
## Part codes: AER ENG GRB SUS BRK CHS


func _build_rnd_tasks_for_season(season: int) -> Dictionary:
	var tasks: Dictionary = {}
	var s = str(season)

	const CHAMP_TIER = {
		"C-001":1,
		"C-005":1,"C-006":1,"C-007":2,"C-008":4,
		"C-009":2,"C-010":3,
		"C-011":1,"C-012":2,"C-013":4,
		"C-014":1,"C-015":2,"C-016":3,"C-017":4,
		"C-018":2,"C-019":3,"C-020":4,
		"C-021":1,"C-022":2,"C-023":3,"C-024":4,
	}
	const PART_CODES = {
		"Aero":"AER","Engine":"ENG","Gearbox":"GRB",
		"Suspension":"SUS","Brakes":"BRK","Chassis":"CHS"
	}
	const PART_BASE_P1 = {
		"Aero":       [4,  120, 15000,  "aero_perf",    0.02],
		"Engine":     [6,  180, 25000,  "engine_perf",  0.02],
		"Chassis":    [8,  200, 30000,  "chassis_perf", 0.02],
		"Gearbox":    [4,  100, 12000,  "gearbox_perf", 0.02],
		"Brakes":     [3,  80,  10000,  "brakes_perf",  0.02],
		"Suspension": [4,  100, 12000,  "susp_perf",    0.02],
	}
	const PART_BASE_P2 = {
		"Aero":       [3,  80,  8000,   "aero_perf",    0.015],
		"Engine":     [4,  120, 15000,  "engine_perf",  0.015],
		"Chassis":    [5,  140, 18000,  "chassis_perf", 0.015],
		"Gearbox":    [3,  80,  8000,   "gearbox_perf", 0.015],
		"Brakes":     [2,  60,  6000,   "brakes_perf",  0.015],
		"Suspension": [3,  80,  8000,   "susp_perf",    0.015],
	}
	const PART_BASE_P3 = {
		"Aero":       [6,  160, 20000,  "unlock_aero_cnc",    1.0],
		"Engine":     [10, 280, 40000,  "unlock_engine_cnc",  1.0],
		"Chassis":    [12, 320, 50000,  "unlock_chassis_cnc", 1.0],
		"Gearbox":    [5,  120, 15000,  "unlock_gear_cnc",    1.0],
		"Brakes":     [4,  100, 12000,  "unlock_brakes_cnc",  1.0],
		"Suspension": [5,  120, 15000,  "unlock_susp_cnc",    1.0],
	}
	const PART_SPEC_MAP = {
		"C-001":[true,true,true,false,false,true],
		"C-005":[true,true,true,false,false,true],  "C-006":[false,true,true,false,false,false],
		"C-007":[false,false,false,false,false,false],"C-008":[false,false,false,false,false,false],
		"C-009":[true,true,true,true,true,true],    "C-010":[true,true,true,true,true,true],
		"C-011":[true,true,true,true,true,true],    "C-012":[true,true,true,true,true,true],
		"C-013":[true,false,true,false,true,true],  "C-014":[true,false,true,false,false,true],
		"C-015":[true,false,false,false,false,true], "C-016":[true,false,false,false,false,true],
		"C-017":[true,false,true,true,true,true], "C-018":[true,true,true,true,true,true],
		"C-019":[true,true,true,false,false,true],  "C-020":[false,false,false,false,false,false],
		"C-021":[true,true,true,true,true,true],    "C-022":[true,true,true,true,true,true],
		"C-023":[true,true,true,true,true,true],    "C-024":[false,false,false,false,false,false],
	}
	const PART_NAMES_ORDER = ["Aero","Engine","Gearbox","Suspension","Brakes","Chassis"]
	const UPG_LEVEL_MULTS = [1.0, 1.5, 2.2, 3.0, 4.0]

	for cid in gs.CHAMP_CODES.keys():
		var code = gs.CHAMP_CODES[cid]
		var tier = CHAMP_TIER.get(cid, 1)
		var tier_mult = 1.0 + (tier - 1) * 0.5
		var spec_arr = PART_SPEC_MAP.get(cid, [false,false,false,false,false,false])
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var champ_name = reg.get("name", cid)

		## S35.11 — Season anchoring split:
		##   • P1 (Design) and P3 (Reverse Engineering) build NEXT season's car → stamped
		##     design_season = season + 1, and their id/name carry that S{n+1} token.
		##   • P2 (Upgrade) improves the CURRENT season's car → stays on `season`/`s`.
		## The season token in the id is the part's TARGET season; with this split an S4
		## design (for S5) and an S5 design (for S6) never collide, and the season-rollover
		## can tell P1/P3 next-season blueprints apart from P2 current-season ones by id+name.
		var design_season = season + 1
		var ns = str(design_season)

		for i in range(PART_NAMES_ORDER.size()):
			var part    = PART_NAMES_ORDER[i]
			var pcode   = PART_CODES[part]
			var is_spec = spec_arr[i]

			# P1: Blueprint Design — designs NEXT season's part (L1 + L2)
			var p1b   = PART_BASE_P1[part]
			var p1_id = "BP-%s-%s-S%s-L1" % [code, pcode, ns]
			var p1_l2 = "BP-%s-%s-S%s-L2" % [code, pcode, ns]
			tasks[p1_id] = {
				"name": "%s — %s S%s Blueprint L1" % [champ_name, part, ns],
				"pillar":1,"part":part,"part_code":pcode,"championship_id":cid,
				"season":design_season,"level":1,"blueprint_id":p1_id,
				"weeks":max(1,int(p1b[0]*tier_mult)),"rp":int(p1b[1]*tier_mult),
				"cr":int(p1b[2]*tier_mult),"effect":p1b[3],"value":p1b[4],
			}
			tasks[p1_l2] = {
				"name": "%s — %s S%s Blueprint L2" % [champ_name, part, ns],
				"pillar":1,"part":part,"part_code":pcode,"championship_id":cid,
				"season":design_season,"level":2,"blueprint_id":p1_l2,
				"weeks":max(1,int(p1b[0]*tier_mult*2.0)),"rp":int(p1b[1]*tier_mult*2.5),
				"cr":int(p1b[2]*tier_mult*2.8),"effect":p1b[3],"value":p1b[4]*2.0,
				## L2 unlocks when an L1 blueprint for this [champ][part][season] exists from
				## EITHER P1 OR P3 — resolved at part level in rnd_task_unlocked(), not by a
				## single task id. This marker tells that check which L1 lineage to look for.
				"requires_l1_for": "%s|%s|%d" % [cid, pcode, design_season],
			}

			# P2: Upgrade — 5 levels, Open parts only. CURRENT season's car.
			if not is_spec:
				var p2b = PART_BASE_P2[part]
				var prev_id = ""
				for lv in range(1, 6):
					var lm = UPG_LEVEL_MULTS[lv - 1]
					var upg_id = "UPG-%s-%s-S%s-L%d" % [code, pcode, s, lv]
					var entry: Dictionary = {
						"name": "%s — %s S%s Upgrade L%d" % [champ_name, part, s, lv],
						"pillar":2,"part":part,"part_code":pcode,"championship_id":cid,
						"season":season,"level":lv,"blueprint_id":upg_id,
						"weeks":max(1,int(p2b[0]*tier_mult*lm)),"rp":int(p2b[1]*tier_mult*lm),
						"cr":int(p2b[2]*tier_mult*lm),"effect":p2b[3],"value":p2b[4]*lm,
					}
					if prev_id != "":
						entry["requires"] = prev_id
					tasks[upg_id] = entry
					prev_id = upg_id

			# P3: Reverse Engineering — Spec parts only, always L1. NEXT season's part.
			if is_spec:
				var p3b = PART_BASE_P3[part]
				var re_id = "RE-%s-%s-S%s-L1" % [code, pcode, ns]
				tasks[re_id] = {
					"name": "%s — %s S%s RE L1" % [champ_name, part, ns],
					"pillar":3,"part":part,"part_code":pcode,"championship_id":cid,
					"season":design_season,"level":1,"blueprint_id":re_id,
					"weeks":max(1,int(p3b[0]*tier_mult)),"rp":int(p3b[1]*tier_mult),
					"cr":int(p3b[2]*tier_mult),"effect":p3b[3],"value":p3b[4],
				}

	# P4: Special Projects — not season-specific
	var p4: Dictionary = {
		"SP_ACA_1": {"name":"Curriculum-Based Biometric Cadet Coaching","pillar":4,"part":"Academy","weeks":42,"rp":4500,"cr":8000000,"effect":"cadet_starting_attributes","value":0.05,"Required_RnD_Studio_Level":2,"building":"Academy","min_building_level":1,"desc":"+5% starting attributes for new cadets."},
		"SP_ACA_2": {"name":"Elite Single-Seater Cadet Progression Framework","pillar":4,"part":"Academy","weeks":50,"rp":9000,"cr":15000000,"effect":"cadet_salary_demand_reduction","value":0.15,"Required_RnD_Studio_Level":3,"building":"Academy","min_building_level":2,"desc":"−15% salary demand from academy graduates."},
		"SP_ACA_3": {"name":"Global Scouting Telemetry Bot Grid","pillar":4,"part":"Academy","weeks":72,"rp":16500,"cr":28000000,"effect":"five_star_cadet_rate","value":0.25,"Required_RnD_Studio_Level":4,"building":"Academy","min_building_level":3,"desc":"+25% chance to spawn 5-star cadets."},
		"SP_ACA_4": {"name":"Pinnacle Clone Driver Contract Pipeline","pillar":4,"part":"Academy","weeks":104,"rp":40000,"cr":75000000,"effect":"new_cadet_attributes","value":0.30,"Required_RnD_Studio_Level":4,"building":"Academy","min_building_level":4,"desc":"+30% starting attributes for new cadets."},
		"SP_TUN_1": {"name":"Ground Effect & Venturi Tunnel Science","pillar":4,"part":"Tunnel","weeks":44,"rp":8000,"cr":14000000,"effect":"downforce_efficiency","value":0.12,"Required_RnD_Studio_Level":4,"building":"Aerodynamic Wind Tunnel","min_building_level":3,"desc":"+12% downforce efficiency."},
		"SP_TUN_2": {"name":"Computational Fluid Dynamics (CFD) Clusters","pillar":4,"part":"Tunnel","weeks":66,"rp":15000,"cr":28000000,"effect":"blueprint_research_time_reduction","value":0.30,"Required_RnD_Studio_Level":6,"building":"Aerodynamic Wind Tunnel","min_building_level":4,"desc":"−30% blueprint research time."},
		"SP_TUN_3": {"name":"Aerothermal Structural Balancing Grid","pillar":4,"part":"Tunnel","weeks":74,"rp":26000,"cr":45000000,"effect":"cooling_drag_reduction","value":0.10,"Required_RnD_Studio_Level":8,"building":"Aerodynamic Wind Tunnel","min_building_level":6,"desc":"−10% cooling drag."},
		"SP_TUN_4": {"name":"Boundary Layer Laser Profiling Arrays","pillar":4,"part":"Tunnel","weeks":98,"rp":38000,"cr":65000000,"effect":"drag_reduction","value":0.08,"Required_RnD_Studio_Level":9,"building":"Aerodynamic Wind Tunnel","min_building_level":7,"desc":"−8% aerodynamic drag."},
		"SP_TUN_5": {"name":"Plasma Flow Actuator Aero Synthesis","pillar":4,"part":"Tunnel","weeks":114,"rp":55000,"cr":95000000,"effect":"clean_downforce","value":0.30,"Required_RnD_Studio_Level":9,"building":"Aerodynamic Wind Tunnel","min_building_level":8,"desc":"+30% clean downforce."},
		"SP_TUN_6": {"name":"Ultimate Aerodynamic Wake Matrix","pillar":4,"part":"Tunnel","weeks":160,"rp":90000,"cr":160000000,"effect":"drafting_downforce_loss_reduction","value":0.10,"Required_RnD_Studio_Level":9,"building":"Aerodynamic Wind Tunnel","min_building_level":9,"desc":"−10% downforce loss in drafting."},
		"SP_TUN_7": {"name":"Flow-Visualization Airflow Drag Diagnostics","pillar":4,"part":"Tunnel","weeks":38,"rp":4500,"cr":7500000,"effect":"aero_drag_reduction","value":0.04,"Required_RnD_Studio_Level":5,"building":"Aerodynamic Wind Tunnel","min_building_level":5,"desc":"−4% aero drag."},
		"SP_CNC_1": {"name":"Computer-Aided Manufacturing (CAM) Scripts","pillar":4,"part":"CNC","weeks":34,"rp":7000,"cr":12000000,"effect":"production_time_reduction","value":0.25,"Required_RnD_Studio_Level":6,"building":"CNC Parts Plant","min_building_level":9,"desc":"−25% production time."},
		"SP_CNC_2": {"name":"High-Tensile Titanium Machining Feed Loops","pillar":4,"part":"CNC","weeks":50,"rp":11500,"cr":19500000,"effect":"engine_production_cost","value":0.18,"Required_RnD_Studio_Level":9,"building":"CNC Parts Plant","min_building_level":12,"desc":"−18% engine production cost."},
		"SP_CNC_3": {"name":"Micro-Tolerance Component Optimization","pillar":4,"part":"CNC","weeks":72,"rp":18000,"cr":32000000,"effect":"breakdown_risk_reduction","value":0.22,"Required_RnD_Studio_Level":12,"building":"CNC Parts Plant","min_building_level":18,"desc":"−22% mechanical breakdown risk."},
		"SP_CNC_4": {"name":"Sub-Atomic Laser Edge Component Shaving","pillar":4,"part":"CNC","weeks":102,"rp":32000,"cr":55000000,"effect":"production_cost_reduction","value":0.40,"Required_RnD_Studio_Level":18,"building":"CNC Parts Plant","min_building_level":21,"desc":"−40% production cost."},
		"SP_CNC_5": {"name":"Molecular Metal Sintering Cells","pillar":4,"part":"CNC","weeks":116,"rp":50000,"cr":85000000,"effect":"ultra_complex_manufacturing","value":0.20,"Required_RnD_Studio_Level":21,"building":"CNC Parts Plant","min_building_level":22,"desc":"Unlocks ultra-complex manufacturing."},
		"SP_CNC_6": {"name":"Pinnacle Nano-Tolerance Production Line","pillar":4,"part":"CNC","weeks":148,"rp":75000,"cr":140000000,"effect":"part_sale_value_boost","value":0.25,"Required_RnD_Studio_Level":24,"building":"CNC Parts Plant","min_building_level":24,"desc":"+25% part sale value."},
		"SP_CNC_7": {"name":"Heavy Sheet-Metal Stock Car Stamping","pillar":4,"part":"CNC","weeks":35,"rp":3000,"cr":5000000,"effect":"inhouse_body_panel_production","value":0.05,"Required_RnD_Studio_Level":4,"building":"CNC Parts Plant","min_building_level":4,"desc":"+5% in-house body panel production."},
		"SP_CNC_8": {"name":"Multi-Axis CNC Machine Floor Integration","pillar":4,"part":"CNC","weeks":42,"rp":6500,"cr":11000000,"effect":"manufacturing_waste_reduction","value":0.15,"Required_RnD_Studio_Level":7,"building":"CNC Parts Plant","min_building_level":12,"desc":"−15% manufacturing waste."},
		"SP_FIT_1": {"name":"Sports Science G-Force Fatigue Mitigation","pillar":4,"part":"Clinic","weeks":34,"rp":4000,"cr":7000000,"effect":"driver_fatigue_reduction","value":0.15,"Required_RnD_Studio_Level":3,"building":"Fitness Clinic","min_building_level":25,"desc":"−15% driver fatigue."},
		"SP_FIT_2": {"name":"Advanced Reflex Cognitive Simulation Units","pillar":4,"part":"Clinic","weeks":46,"rp":8500,"cr":14500000,"effect":"gforce_accuracy","value":0.12,"Required_RnD_Studio_Level":8,"building":"Fitness Clinic","min_building_level":55,"desc":"+12% accuracy under G-force."},
		"SP_FIT_3": {"name":"Cryogenic Bio-Regenerative Restoration Tanks","pillar":4,"part":"Clinic","weeks":78,"rp":16000,"cr":28000000,"effect":"fatigue_recovery","value":0.20,"Required_RnD_Studio_Level":25,"building":"Fitness Clinic","min_building_level":75,"desc":"+20% fatigue recovery."},
		"SP_FIT_4": {"name":"Hyperbaric Oxygen Apex Athlete Suites","pillar":4,"part":"Clinic","weeks":108,"rp":38000,"cr":65000000,"effect":"concentration_and_reflex","value":0.10,"Required_RnD_Studio_Level":60,"building":"Fitness Clinic","min_building_level":109,"desc":"Major boost to concentration and reflexes."},
		"SP_GAR_1": {"name":"Sequential Transmission Cleanroom Workshop","pillar":4,"part":"Garage","weeks":42,"rp":6000,"cr":9000000,"effect":"repair_profit","value":0.25,"Required_RnD_Studio_Level":5,"building":"Garage","min_building_level":30,"desc":"+25% repair profit."},
		"SP_GAR_2": {"name":"Automated Powertrain Teardown Cells","pillar":4,"part":"Garage","weeks":56,"rp":9500,"cr":16000000,"effect":"repair_time_reduction","value":0.25,"Required_RnD_Studio_Level":12,"building":"Garage","min_building_level":45,"desc":"−25% repair time."},
		"SP_GAR_3": {"name":"High-Volume Carbon Monocoque Autoclave","pillar":4,"part":"Garage","weeks":82,"rp":22000,"cr":38000000,"effect":"inhouse_major_repairs","value":0.15,"Required_RnD_Studio_Level":25,"building":"Garage","min_building_level":80,"desc":"Unlocks in-house major repairs."},
		"SP_GAR_4": {"name":"Structural Monocoque Carbon Optimization","pillar":4,"part":"Garage","weeks":118,"rp":45000,"cr":75000000,"effect":"chassis_weight_reduction","value":0.05,"Required_RnD_Studio_Level":35,"building":"Garage","min_building_level":89,"desc":"−5% chassis weight."},
		"SP_GAR_5": {"name":"Tubular Spaceframe Welding Arrays","pillar":4,"part":"Garage","weeks":34,"rp":2000,"cr":4000000,"effect":"chassis_repair_speed","value":0.20,"Required_RnD_Studio_Level":4,"building":"Garage","min_building_level":25,"desc":"+20% chassis repair speed."},
		"SP_GAR_6": {"name":"Sequential Transmission Blueprint Overhauls","pillar":4,"part":"Garage","weeks":46,"rp":6500,"cr":11500000,"effect":"transmission_failure_reduction","value":0.15,"Required_RnD_Studio_Level":10,"building":"Garage","min_building_level":47,"desc":"−15% transmission failure risk."},
		"SP_GAR_7": {"name":"Structural Tube Frame Fabrication Jigs","pillar":4,"part":"Garage","weeks":68,"rp":14000,"cr":24000000,"effect":"stock_car_durability","value":0.12,"Required_RnD_Studio_Level":20,"building":"Garage","min_building_level":64,"desc":"+12% stock car durability."},
		"SP_GAR_8": {"name":"Advanced Sub-Assembly Stress-Testing Rigs","pillar":4,"part":"Garage","weeks":74,"rp":21000,"cr":35000000,"effect":"mechanical_dnf_reduction","value":0.35,"Required_RnD_Studio_Level":35,"building":"Garage","min_building_level":85,"desc":"−35% pre-event mechanical DNFs."},
		"SP_GRAVEL_1": {"name":"WRC4 Loose Soil Shakedown Calibration","pillar":4,"part":"Gravel","weeks":35,"rp":3500,"cr":6000000,"effect":"rally_loose_grip","value":0.08,"Required_RnD_Studio_Level":2,"building":"Gravel Track","min_building_level":1,"desc":"+8% grip on loose surfaces."},
		"SP_GRAVEL_2": {"name":"High-Travel Damper Variable-Surface Shaker Rigs","pillar":4,"part":"Gravel","weeks":46,"rp":7500,"cr":12500000,"effect":"rally_unpaved_handling","value":0.10,"Required_RnD_Studio_Level":3,"building":"Gravel Track","min_building_level":2,"desc":"+10% handling on unpaved."},
		"SP_GRAVEL_3": {"name":"Sub-Surface Radar Terrain Mapping","pillar":4,"part":"Gravel","weeks":98,"rp":25000,"cr":45000000,"effect":"gravel_suspension_durability","value":0.35,"Required_RnD_Studio_Level":3,"building":"Gravel Track","min_building_level":3,"desc":"−35% suspension damage on gravel."},
		"SP_HQ_1": {"name":"Enterprise Conglomerate Resource Architecture","pillar":4,"part":"HQ","weeks":48,"rp":8500,"cr":14500000,"effect":"maintenance_reduction","value":0.15,"Required_RnD_Studio_Level":4,"building":"Headquarters","min_building_level":8,"desc":"−15% all campus maintenance costs."},
		"SP_HQ_2": {"name":"Cross-Border Brand Licensing Syndicate","pillar":4,"part":"HQ","weeks":74,"rp":12000,"cr":22000000,"effect":"marketability_boost","value":0.15,"Required_RnD_Studio_Level":6,"building":"Headquarters","min_building_level":12,"desc":"+15% global marketability."},
		"SP_HQ_3": {"name":"Sovereign Holding Company Conversion","pillar":4,"part":"HQ","weeks":96,"rp":35000,"cr":65000000,"effect":"tax_reduction","value":0.30,"Required_RnD_Studio_Level":12,"building":"Headquarters","min_building_level":22,"desc":"−30% corporate tax."},
		"SP_HQ_4": {"name":"Ultimate Championship Control Core","pillar":4,"part":"HQ","weeks":162,"rp":60000,"cr":120000000,"effect":"marketability_boost","value":0.25,"Required_RnD_Studio_Level":18,"building":"Headquarters","min_building_level":26,"desc":"+25% global marketability."},
		"SP_HQ_5": {"name":"Corporate Public Relations Framework","pillar":4,"part":"HQ","weeks":34,"rp":2500,"cr":4500000,"effect":"marketability_boost","value":0.10,"Required_RnD_Studio_Level":3,"building":"Headquarters","min_building_level":7,"desc":"+10% marketability from PR."},
		"SP_KART_1": {"name":"Rotax Championship Track Layout Optimization","pillar":4,"part":"KartTrack","weeks":30,"rp":3000,"cr":5500000,"effect":"gokart_agility","value":0.10,"Required_RnD_Studio_Level":2,"building":"Karting Track","min_building_level":2,"desc":"+10% go-kart agility."},
		"SP_KART_2": {"name":"Micro-Chassis Elasticity Calibration Arrays","pillar":4,"part":"KartTrack","weeks":54,"rp":6500,"cr":11000000,"effect":"gokart_telemetry","value":0.15,"Required_RnD_Studio_Level":3,"building":"Karting Track","min_building_level":3,"desc":"+15% go-kart telemetry."},
		"SP_LOG_1": {"name":"Predictive Global Freight Shipping Matrix","pillar":4,"part":"Logistics","weeks":50,"rp":5000,"cr":8500000,"effect":"parts_shipping_discount","value":0.15,"Required_RnD_Studio_Level":4,"building":"Logistics Center","min_building_level":8,"desc":"−15% shipping costs."},
		"SP_LOG_2": {"name":"Just-In-Time (JIT) Supply Chain Integration","pillar":4,"part":"Logistics","weeks":68,"rp":11000,"cr":18500000,"effect":"cnc_build_time_reduction","value":3.0,"Required_RnD_Studio_Level":8,"building":"Logistics Center","min_building_level":19,"desc":"−3 weeks build time on parts."},
		"SP_LOG_3": {"name":"WorldWIde Distribution Network","pillar":4,"part":"Logistics","weeks":112,"rp":25000,"cr":42000000,"effect":"logistics_cost_reduction","value":0.30,"Required_RnD_Studio_Level":14,"building":"Logistics Center","min_building_level":21,"desc":"−30% logistics cost."},
		"SP_LOG_4": {"name":"Pinnacle Quantum Logistics Grid","pillar":4,"part":"Logistics","weeks":150,"rp":50000,"cr":95000000,"effect":"shipping_time_reduction","value":0.50,"Required_RnD_Studio_Level":20,"building":"Logistics Center","min_building_level":24,"desc":"−50% shipping time."},
		"SP_LOG_5": {"name":"Regional Supplier Integration Matrix","pillar":4,"part":"Logistics","weeks":38,"rp":3000,"cr":5000000,"effect":"external_shipping_cost_reduction","value":0.10,"Required_RnD_Studio_Level":4,"building":"Logistics Center","min_building_level":4,"desc":"−10% external shipping cost."},
		"SP_LOG_6": {"name":"Cross-Border Freight Coordination Node","pillar":4,"part":"Logistics","weeks":44,"rp":5500,"cr":9500000,"effect":"transport_delay_reduction","value":0.15,"Required_RnD_Studio_Level":6,"building":"Logistics Center","min_building_level":10,"desc":"−15% transport delays."},
		"SP_LOG_7": {"name":"International Freight Network Integration","pillar":4,"part":"Logistics","weeks":50,"rp":8000,"cr":14000000,"effect":"heavy_part_shipping_cost","value":0.18,"Required_RnD_Studio_Level":9,"building":"Logistics Center","min_building_level":17,"desc":"−18% heavy part shipping cost."},
		"SP_LOG_8": {"name":"Advanced Spares Component Sourcing","pillar":4,"part":"Logistics","weeks":52,"rp":11000,"cr":19000000,"effect":"emergency_part_cost_reduction","value":0.20,"Required_RnD_Studio_Level":11,"building":"Logistics Center","min_building_level":21,"desc":"−20% emergency part cost."},
		"SP_LOG_9": {"name":"Intercontinental Distribution Loop Architecture","pillar":4,"part":"Logistics","weeks":60,"rp":19000,"cr":32000000,"effect":"part_sale_margin","value":0.15,"Required_RnD_Studio_Level":14,"building":"Logistics Center","min_building_level":23,"desc":"+15% part sale margin."},
		"SP_STORE_1": {"name":"Global E-Commerce Merchandize Networks","pillar":4,"part":"Store","weeks":35,"rp":3500,"cr":6500000,"effect":"merch_profit_margin","value":0.12,"Required_RnD_Studio_Level":2,"building":"Merchandize Store","min_building_level":7,"desc":"+12% merch profit margin."},
		"SP_STORE_2": {"name":"Flagship Showroom Luxury Apparel Atriums","pillar":4,"part":"Store","weeks":48,"rp":8000,"cr":14000000,"effect":"apparel_revenue","value":0.15,"Required_RnD_Studio_Level":3,"building":"Merchandize Store","min_building_level":7,"desc":"+15% apparel revenue."},
		"SP_STORE_3": {"name":"Global Airport Duty-Free Retail Outlets","pillar":4,"part":"Store","weeks":74,"rp":14000,"cr":24000000,"effect":"passive_income_boost","value":0.10,"Required_RnD_Studio_Level":4,"building":"Merchandize Store","min_building_level":7,"desc":"+10% passive income."},
		"SP_STORE_4": {"name":"Infinite Corporate Licensing Syndicates","pillar":4,"part":"Store","weeks":102,"rp":35000,"cr":65000000,"effect":"merch_profit_boost","value":0.25,"Required_RnD_Studio_Level":5,"building":"Merchandize Store","min_building_level":7,"desc":"+25% merch profit."},
		"SP_MUS_1": {"name":"Heritage Preservation Showroom Atrium","pillar":4,"part":"Museum","weeks":36,"rp":4500,"cr":8500000,"effect":"passive_income_boost","value":0.15,"Required_RnD_Studio_Level":3,"building":"Museum","min_building_level":2,"desc":"+15% passive income."},
		"SP_MUS_2": {"name":"Blue-Chip Automotive Heritage Auctions","pillar":4,"part":"Museum","weeks":50,"rp":8000,"cr":15000000,"effect":"asset_conversion_rate","value":0.12,"Required_RnD_Studio_Level":4,"building":"Museum","min_building_level":4,"desc":"+12% asset conversion rate."},
		"SP_MUS_3": {"name":"Global Legacy Asset Syndicate Nodes","pillar":4,"part":"Museum","weeks":100,"rp":28000,"cr":55000000,"effect":"brand_prestige","value":0.20,"Required_RnD_Studio_Level":5,"building":"Museum","min_building_level":5,"desc":"+20% brand prestige."},
		"SP_MUS_4": {"name":"Curated Heritage Exhibit Showrooms","pillar":4,"part":"Museum","weeks":40,"rp":2500,"cr":4000000,"effect":"passive_income_boost","value":0.05,"Required_RnD_Studio_Level":3,"building":"Museum","min_building_level":1,"desc":"+5% passive income."},
		"SP_OST_1": {"name":"Hardware-In-The-Loop (HIL) Powertrain Modeling","pillar":4,"part":"Ops","weeks":40,"rp":6500,"cr":11000000,"effect":"fuel_efficiency","value":0.06,"Required_RnD_Studio_Level":5,"building":"Ops Sim & Telemetry","min_building_level":4,"desc":"+6% fuel efficiency."},
		"SP_OST_2": {"name":"Infrared Thermal Tire Contact Tracking","pillar":4,"part":"Ops","weeks":52,"rp":9000,"cr":16500000,"effect":"tire_degradation_reduction","value":0.12,"Required_RnD_Studio_Level":8,"building":"Ops Sim & Telemetry","min_building_level":9,"desc":"−12% tire degradation."},
		"SP_OST_3": {"name":"Predictive Brake & Traction Control Monitors","pillar":4,"part":"Ops","weeks":76,"rp":14000,"cr":24000000,"effect":"wet_lockup_reduction","value":0.15,"Required_RnD_Studio_Level":12,"building":"Ops Sim & Telemetry","min_building_level":13,"desc":"−15% lock-up mistakes in wet."},
		"SP_OST_4": {"name":"Predictive Neural Timing Grid Networks","pillar":4,"part":"Ops","weeks":80,"rp":25000,"cr":45000000,"effect":"undercut_success","value":0.18,"Required_RnD_Studio_Level":18,"building":"Ops Sim & Telemetry","min_building_level":19,"desc":"+18% undercut success."},
		"SP_OST_5": {"name":"Quantum Probability Sector Strategy Engine","pillar":4,"part":"Ops","weeks":106,"rp":40000,"cr":75000000,"effect":"track_knowledge_boost","value":0.75,"Required_RnD_Studio_Level":22,"building":"Ops Sim & Telemetry","min_building_level":26,"desc":"+75% track knowledge baseline."},
		"SP_OST_6": {"name":"Deep-Space Predictive Tracking Matrix","pillar":4,"part":"Ops","weeks":152,"rp":70000,"cr":130000000,"effect":"tactical_error_reduction","value":0.0,"Required_RnD_Studio_Level":27,"building":"Ops Sim & Telemetry","min_building_level":30,"desc":"Greatly reduces tactical errors."},
		"SP_OST_7": {"name":"Real-Time Telemetry Data Overlay Dashboards","pillar":4,"part":"Ops","weeks":34,"rp":4000,"cr":6500000,"effect":"strategy_data_quality","value":0.05,"Required_RnD_Studio_Level":4,"building":"Ops Sim & Telemetry","min_building_level":5,"desc":"+5% strategy data quality."},
		"SP_OVAL_1": {"name":"ARCA Short-Track Laser Setup Engineering","pillar":4,"part":"Oval","weeks":38,"rp":4000,"cr":7000000,"effect":"short_oval_turn_in","value":0.10,"Required_RnD_Studio_Level":2,"building":"Oval Track","min_building_level":1,"desc":"+10% turn-in on short ovals."},
		"SP_OVAL_2": {"name":"Dynamic High-Bank Telemetry Capture Loops","pillar":4,"part":"Oval","weeks":52,"rp":8500,"cr":14500000,"effect":"superspeedway_blowout_reduction","value":0.15,"Required_RnD_Studio_Level":3,"building":"Oval Track","min_building_level":2,"desc":"−15% tire blowout risk on superspeedways."},
		"SP_OVAL_3": {"name":"Boundary Slipstream Aerodynamic Optimizers","pillar":4,"part":"Oval","weeks":106,"rp":30000,"cr":55000000,"effect":"drafting_drag_reduction","value":0.12,"Required_RnD_Studio_Level":3,"building":"Oval Track","min_building_level":3,"desc":"−12% drag when drafting."},
		"SP_ARENA_1": {"name":"Mock Pit Lane Servicing Simulation Infrastructure","pillar":4,"part":"Arena","weeks":32,"rp":3500,"cr":6000000,"effect":"pit_stop_time_reduction","value":0.01,"Required_RnD_Studio_Level":3,"building":"Pit Crew Arena","min_building_level":6,"desc":"Small pit stop time reduction."},
		"SP_ARENA_2": {"name":"High-Pressure Pneumatic Tool Light-Systems","pillar":4,"part":"Arena","weeks":48,"rp":7000,"cr":12500000,"effect":"pit_stop_error_reduction","value":0.05,"Required_RnD_Studio_Level":6,"building":"Pit Crew Arena","min_building_level":9,"desc":"−5% pit stop errors."},
		"SP_ARENA_3": {"name":"Sub-Two-Second Choreographed Pit Stop Perfection","pillar":4,"part":"Arena","weeks":64,"rp":14500,"cr":24000000,"effect":"pit_stop_time_reduction","value":0.02,"Required_RnD_Studio_Level":10,"building":"Pit Crew Arena","min_building_level":14,"desc":"Further pit stop time reduction."},
		"SP_ARENA_4": {"name":"Predictive Biomechanical Exoskeleton Support","pillar":4,"part":"Arena","weeks":96,"rp":36000,"cr":65000000,"effect":"pit_stop_time_reduction","value":0.03,"Required_RnD_Studio_Level":18,"building":"Pit Crew Arena","min_building_level":20,"desc":"Final pit stop time reduction."},
		"SP_CLUB_1": {"name":"VIP Trackside Lounge Arena Facilities","pillar":4,"part":"Club","weeks":38,"rp":5000,"cr":9500000,"effect":"passive_income_multiplier","value":0.20,"Required_RnD_Studio_Level":3,"building":"Public Racing Club","min_building_level":7,"desc":"+20% passive income multiplier."},
		"SP_CLUB_2": {"name":"Sovereign Wealth Racing Syndicate Tracks","pillar":4,"part":"Club","weeks":94,"rp":24000,"cr":45000000,"effect":"off_season_income","value":0.40,"Required_RnD_Studio_Level":6,"building":"Public Racing Club","min_building_level":7,"desc":"+40% off-season passive income."},
		"SP_RND_1": {"name":"Volumetric Fluid Dynamics Engine Blueprinting","pillar":4,"part":"R&D","weeks":46,"rp":9000,"cr":15500000,"effect":"engine_power","value":0.05,"Required_RnD_Studio_Level":5,"building":"R&D Design Studio","min_building_level":9,"desc":"+5% engine power."},
		"SP_RND_2": {"name":"Proprietary Shock Absorber Fluid Research","pillar":4,"part":"R&D","weeks":64,"rp":12500,"cr":21000000,"effect":"tire_wear_reduction","value":0.10,"Required_RnD_Studio_Level":7,"building":"R&D Design Studio","min_building_level":12,"desc":"−10% tire wear."},
		"SP_RND_3": {"name":"High-Modulus Aerospace Carbon Composites","pillar":4,"part":"R&D","weeks":78,"rp":20000,"cr":34000000,"effect":"part_weight_reduction","value":0.15,"Required_RnD_Studio_Level":11,"building":"R&D Design Studio","min_building_level":18,"desc":"−15% part weight."},
		"SP_RND_4": {"name":"Exotic Metal Alloys Metallurgy Optimization","pillar":4,"part":"R&D","weeks":92,"rp":28000,"cr":48000000,"effect":"heat_resistance","value":0.20,"Required_RnD_Studio_Level":14,"building":"R&D Design Studio","min_building_level":21,"desc":"+20% heat resistance."},
		"SP_RND_5": {"name":"Pinnacle Aerothermal Flow Blueprinting","pillar":4,"part":"R&D","weeks":124,"rp":45000,"cr":80000000,"effect":"cooling_drag_reduction","value":0.12,"Required_RnD_Studio_Level":18,"building":"R&D Design Studio","min_building_level":24,"desc":"−12% cooling drag."},
		"SP_RND_6": {"name":"Generative AI Topology Optimization Core","pillar":4,"part":"R&D","weeks":156,"rp":80000,"cr":150000000,"effect":"reverse_engineering_speed","value":0.40,"Required_RnD_Studio_Level":24,"building":"R&D Design Studio","min_building_level":27,"desc":"+40% reverse engineering speed."},
		"SP_RND_7": {"name":"Infinite Generative Design Loop Synthesis","pillar":4,"part":"R&D","weeks":210,"rp":150000,"cr":250000000,"effect":"custom_part_efficiency","value":0.20,"Required_RnD_Studio_Level":27,"building":"R&D Design Studio","min_building_level":27,"desc":"+20% custom part efficiency."},
		"SP_RND_8": {"name":"Internal Combustion Fundamentals Cleanroom","pillar":4,"part":"R&D","weeks":32,"rp":4000,"cr":6500000,"effect":"engine_power","value":0.04,"Required_RnD_Studio_Level":3,"building":"R&D Design Studio","min_building_level":4,"desc":"+4% engine power."},
		"SP_RND_9": {"name":"Volumetric Fluid Dynamics Intake Porting","pillar":4,"part":"R&D","weeks":48,"rp":7000,"cr":12000000,"effect":"engine_fuel_efficiency","value":0.08,"Required_RnD_Studio_Level":5,"building":"R&D Design Studio","min_building_level":10,"desc":"+8% engine fuel efficiency."},
		"SP_RACE_1": {"name":"Formula 4 Flat Road Tracking Optimization","pillar":4,"part":"RaceTrack","weeks":36,"rp":4500,"cr":8000000,"effect":"track_awareness","value":0.12,"Required_RnD_Studio_Level":2,"building":"Race Track","min_building_level":1,"desc":"+12% track awareness."},
		"SP_RACE_2": {"name":"Tire Thermal Physics Contact-Patch Surface Mapping","pillar":4,"part":"RaceTrack","weeks":48,"rp":9500,"cr":16000000,"effect":"tire_degradation_reduction","value":0.10,"Required_RnD_Studio_Level":3,"building":"Race Track","min_building_level":2,"desc":"−10% tire degradation."},
		"SP_RACE_3": {"name":"High-Output Powertrain Kinetic Energy Capture","pillar":4,"part":"RaceTrack","weeks":66,"rp":18000,"cr":32000000,"effect":"hybrid_deployment_efficiency","value":0.15,"Required_RnD_Studio_Level":3,"building":"Race Track","min_building_level":3,"desc":"+15% hybrid deployment."},
		"SP_RACE_4": {"name":"Cryogenic Synthetic Compound Contact Strips","pillar":4,"part":"RaceTrack","weeks":110,"rp":50000,"cr":85000000,"effect":"tire_durability_testing","value":0.18,"Required_RnD_Studio_Level":3,"building":"Race Track","min_building_level":4,"desc":"+18% tire durability."},
		"SP_RAC_1": {"name":"High-Performance Athlete Housing Complex","pillar":4,"part":"Racing","weeks":38,"rp":4000,"cr":7500000,"effect":"driver_fatigue_reduction","value":0.20,"Required_RnD_Studio_Level":8,"building":"Racing Department","min_building_level":30,"desc":"−20% driver fatigue."},
		"SP_RAC_2": {"name":"Neural Cognitive Driver Synapse Calibration","pillar":4,"part":"Racing","weeks":54,"rp":8000,"cr":14000000,"effect":"driver_mistake_reduction","value":0.15,"Required_RnD_Studio_Level":18,"building":"Racing Department","min_building_level":45,"desc":"−15% driver mistakes."},
		"SP_RAC_3": {"name":"Biometric Telemetry Hydration Loops","pillar":4,"part":"Racing","weeks":70,"rp":15000,"cr":26000000,"effect":"wet_stamina_boost","value":0.18,"Required_RnD_Studio_Level":30,"building":"Racing Department","min_building_level":70,"desc":"+18% stamina in wet."},
		"SP_RAC_4": {"name":"Psychometric Reflex Synergy Optimization","pillar":4,"part":"Racing","weeks":104,"rp":30000,"cr":55000000,"effect":"overtaking_success","value":0.15,"Required_RnD_Studio_Level":50,"building":"Racing Department","min_building_level":89,"desc":"+15% overtaking success."},
		"SP_RAC_5": {"name":"Video Telemetry Driver Analysis Playback","pillar":4,"part":"Racing","weeks":38,"rp":2500,"cr":4500000,"effect":"driver_line_correction","value":0.05,"Required_RnD_Studio_Level":5,"building":"Racing Department","min_building_level":11,"desc":"+5% driver line correction."},
		"SP_RAC_6": {"name":"Press & Media Communications Training Suite","pillar":4,"part":"Racing","weeks":44,"rp":5000,"cr":8500000,"effect":"sponsor_podium_bonus","value":0.10,"Required_RnD_Studio_Level":9,"building":"Racing Department","min_building_level":28,"desc":"+10% sponsor bonus after podium."},
		"SP_PARK_1": {"name":"Immersive Destinational Resort Infrastructure","pillar":4,"part":"Park","weeks":40,"rp":7500,"cr":14000000,"effect":"marketability_buffer","value":0.10,"Required_RnD_Studio_Level":3,"building":"Theme Park","min_building_level":3,"desc":"+10% marketability buffer."},
		"SP_PARK_2": {"name":"High-Capacity Branded Roller Coasters","pillar":4,"part":"Park","weeks":68,"rp":14000,"cr":25000000,"effect":"theme_park_income","value":0.15,"Required_RnD_Studio_Level":4,"building":"Theme Park","min_building_level":4,"desc":"+15% theme park income."},
		"SP_PARK_3": {"name":"International Franchise Resort Expansion","pillar":4,"part":"Park","weeks":154,"rp":48000,"cr":85000000,"effect":"passive_income_boost","value":0.10,"Required_RnD_Studio_Level":5,"building":"Theme Park","min_building_level":5,"desc":"Strong passive income boost."},
		"SP_FAC_1": {"name":"Automated Robotic Assembly Line Engineering","pillar":4,"part":"Factory","weeks":45,"rp":10000,"cr":18000000,"effect":"commercial_production_cost_reduction","value":0.10,"Required_RnD_Studio_Level":4,"building":"Vehicle Assembly Factory","min_building_level":4,"desc":"−10% commercial production cost."},
		"SP_FAC_2": {"name":"Conveyor Mass Production Customization","pillar":4,"part":"Factory","weeks":62,"rp":18500,"cr":32000000,"effect":"msrp_pricing_flexibility","value":0.12,"Required_RnD_Studio_Level":6,"building":"Vehicle Assembly Factory","min_building_level":6,"desc":"+12% MSRP pricing flexibility."},
		"SP_FAC_3": {"name":"Monocoque Chassis Marriage Rig Arrays","pillar":4,"part":"Factory","weeks":86,"rp":30000,"cr":55000000,"effect":"weekly_commercial_output","value":0.15,"Required_RnD_Studio_Level":9,"building":"Vehicle Assembly Factory","min_building_level":9,"desc":"+15% weekly commercial output."},
		"SP_FAC_4": {"name":"Cybernetic Smart-Factory Swarm Architecture","pillar":4,"part":"Factory","weeks":144,"rp":65000,"cr":110000000,"effect":"weekly_output_and_pricing","value":0.30,"Required_RnD_Studio_Level":12,"building":"Vehicle Assembly Factory","min_building_level":12,"desc":"+30% output and pricing power."}
	}
	for k in p4: tasks[k] = p4[k]
	return tasks

## Called when WRA announces new technical regulations every WRA_CYCLE_LENGTH seasons.
## Destroys P1 (Design) and P3 (RE) blueprints. P4 Special Projects unaffected.


func _apply_wra_regulation_change() -> void:
	gs.wra_cycle_start_season = gs.current_season
	var wiped = gs.completed_bp_tasks.size()
	gs.completed_bp_tasks.clear()
	gs.completed_rnd_tasks = gs.completed_rnd_tasks.filter(
		func(tid): return not (tid.begins_with("BP-") or tid.begins_with("RE-")))
	var to_wipe: Array = []
	for bp_id in gs.known_blueprints:
		if gs.known_blueprints[bp_id].get("pillar", 0) in [1, 3]:
			to_wipe.append(bp_id)
	for bp_id in to_wipe:
		gs.known_blueprints.erase(bp_id)
	gs.add_notification("Critical",
		"WRA NEW REGULATIONS — Season %d! All Design and RE blueprints invalidated. %d blueprints lost. Teams must redesign from scratch." % [gs.current_season, wiped])
	gs.add_log("WRA Regulation Change — Season %d. %d blueprints wiped." % [gs.current_season, wiped])


func has_blueprint(part: String) -> bool:
	for tid in gs.completed_rnd_tasks:
		var t = gs.RND_TASKS.get(tid, {})
		if t.get("part","") == part and t.get("pillar",0) in [1, 3]:
			return true
	return false

## Returns list of parts the player can currently manufacture.


func get_manufacturable_parts() -> Array:
	var parts = []
	for part in ["Aero","Engine","Chassis","Gearbox","Brakes","Suspension"]:
		if has_blueprint(part) and not part in parts:
			parts.append(part)
	return parts

## Queue a CNC production run for a part.


func start_cnc_production(part: String, champ_id: String, quantity: int = 1) -> bool:
	if not has_blueprint(part):
		gs.add_notification("High", "No blueprint for %s. Research it in R&D Studio first." % part)
		return false
	var building = gs.campus_buildings.get("CNC Parts Plant", {})
	if not building.get("built", false):
		gs.add_notification("High", "CNC Parts Plant not built.")
		return false
	var cnc = gs.CNC_DATA.get(champ_id, gs.CNC_DATA.get("C-001", {}))
	var base_cost = cnc.get("base_total_cost", 10000)
	# Part cost: fraction of full car cost (Aero 20%, Engine 35%, Chassis 25%, others 10%)
	const PART_COST_RATIO = {"Aero":0.20,"Engine":0.35,"Chassis":0.25,
		"Gearbox":0.08,"Brakes":0.06,"Suspension":0.06}
	var unit_cost = int(base_cost * PART_COST_RATIO.get(part, 0.10) * float(quantity))
	if gs.player_team.balance < unit_cost:
		gs.add_notification("High", "Insufficient funds for CNC production. Need CR %s." % gs._fmt_int(unit_cost))
		return false
	# Manufacture time: design_weeks scaled by part complexity
	const PART_TIME_RATIO = {"Aero":0.4,"Engine":0.6,"Chassis":0.5,
		"Gearbox":0.25,"Brakes":0.2,"Suspension":0.25}
	var weeks = max(1, int(cnc.get("design_weeks", 4) * PART_TIME_RATIO.get(part, 0.3) * quantity))
	gs.player_team.balance -= unit_cost
	gs.cnc_production_queue.append({
		"id":        "%s_%s_%d" % [part, champ_id, gs.current_week],
		"part":      part,
		"championship_id": champ_id,
		"weeks_total":     weeks,
		"weeks_remaining": weeks,
		"cr_cost":         unit_cost,
		"quantity":        quantity,
	})
	gs.add_log("⚙ CNC production started: %dx %s for %s (%d wks)" % [
		quantity, part, gs.CHAMPIONSHIP_REGISTRY.get(champ_id,{}).get("name", champ_id), weeks])
	gs.add_notification("Normal", "CNC: %dx %s in production. Ready in %d weeks." % [quantity, part, weeks])
	gs.emit_signal("log_updated")
	return true

## Called each advance_week — ticks CNC production queue.


func _advance_cnc_production() -> void:
	## S28.3 (issue 4): CNC plant has a limited number of PARALLEL production slots.
	## Only the first N jobs in the queue (N = slots) are "active" and tick down each week;
	## jobs beyond that wait until an active slot frees up. This makes a 3rd part take
	## longer (it only starts after one of the first two finishes), not just cost more.
	var slots = get_cnc_slots()
	var finished = []
	var active = 0
	for job in gs.cnc_production_queue:
		if active >= slots:
			break  ## remaining jobs are queued, not yet in production
		active += 1
		job["weeks_remaining"] -= 1
		if job["weeks_remaining"] <= 0:
			finished.append(job)
	for job in finished:
		gs.cnc_production_queue.erase(job)
		var part   = job.get("part", "")
		var pcode  = job.get("part_code", "")
		var cid    = job.get("championship_id", "")
		var qty    = job.get("quantity", 1)
		var rel    = job.get("reliability", 60.0)
		var qual   = job.get("quality", 1.0)
		var bp_id  = job.get("blueprint_id", "")
		## Store using canonical key: "CHAMP_ID|PCODE"
		var inv_key = _cnc_inv_key(cid, pcode) if (cid != "" and pcode != "") else part
		if inv_key in gs.cnc_parts_inventory:
			gs.cnc_parts_inventory[inv_key]["quantity"] += qty
		else:
			gs.cnc_parts_inventory[inv_key] = {
				"quantity":       qty,
				"reliability":    rel,
				"quality":        qual,
				"blueprint_id":   bp_id,
				"part":           part,
				"part_code":      pcode,
				"championship_id": cid,
			}
		## S35.11 (issue 3) — DO NOT remove the blueprint from wra_approved_blueprints here.
		## A WRA approval is a manufacturing LICENSE for the season/cycle, not a one-shot: the
		## player must be able to build spares and replacements. It stays in the CNC "ready to
		## manufacture" list until season rollover (P2) / WRA regulation reset (P1/P3) clears it.
		## The TDL 8b "queue manufacturing" nag is keyed on queue/warehouse presence, not on the
		## approval being deleted, so it still clears correctly (see NotificationManager 8b).
		gs.add_log("✅ CNC complete: %dx %s (%s) — Rel:%.0f%% Qual:%.2f× → warehouse." % [
			qty, part, pcode, rel, qual])
		gs.add_notification("High",
			"CNC complete: %dx %s ready in warehouse. Go to Garage to install it." % [qty, part],
			"garage")
	if not finished.is_empty():
		gs.emit_signal("log_updated")

## Assigns a CNC-manufactured part from inventory to a specific car.


func assign_cnc_part_to_car(car_id: String, part: String) -> bool:
	var car = null
	for c in gs.player_team_cars:
		if c.id == car_id: car = c; break
	if car == null:
		gs.add_notification("High", "Car not found: %s" % car_id)
		return false
	var available = gs.cnc_parts_inventory.get(part, 0)
	if available <= 0:
		gs.add_notification("High", "No %s in CNC inventory. Manufacture one first." % part)
		return false
	gs.cnc_parts_inventory[part] = available - 1
	if gs.cnc_parts_inventory[part] <= 0:
		gs.cnc_parts_inventory.erase(part)
	if not car_id in gs.car_installed_parts:
		gs.car_installed_parts[car_id] = {}
	gs.car_installed_parts[car_id][part] = gs.car_installed_parts[car_id].get(part, 0) + 1
	var cname = car.car_name if car.car_name != "" else "Car %d" % car.car_number
	gs.add_log("🔩 %s CNC part installed on %s." % [part, cname])
	gs.add_notification("Normal", "%s CNC part installed on %s." % [part, cname])
	gs.emit_signal("log_updated")
	return true

## Removes a CNC part from a car and returns it to inventory.


func remove_cnc_part_from_car(car_id: String, part: String) -> bool:
	if not car_id in gs.car_installed_parts: return false
	var installed = gs.car_installed_parts[car_id]
	if not part in installed or installed[part] <= 0: return false
	installed[part] -= 1
	if installed[part] <= 0: installed.erase(part)
	gs.cnc_parts_inventory[part] = gs.cnc_parts_inventory.get(part, 0) + 1
	var car = null
	for c in gs.player_team_cars:
		if c.id == car_id: car = c; break
	var cname = car.car_name if car and car.car_name != "" else "Car"
	gs.add_log("🔩 %s CNC part removed from %s → back to inventory." % [part, cname])
	gs.emit_signal("log_updated")
	return true

## Returns a lap-time improvement fraction for a car based on CNC parts installed.
## ⚠⚠⚠ S35.11 — FORMULA UNDER REVIEW (see GDD §8 flag). Andreas is uneasy about this model;
## revisit before the Phase 5 balance pass. Current model:
##   per part:  part_bonus = value × quality
##     • value  = the R&D performance magnitude (already bakes in level via the P2 carry-over
##                chain + designer lift — do NOT also multiply by level, that double-counts).
##     • quality = the reverse-engineering penalty (1.0 own-design, ~0.75 RE). Makes the RE
##                penalty finally matter on track.
##   total = clamp(Σ part_bonus, 0.0, CNC_BONUS_CAP)
## Reliability is deliberately EXCLUDED — it governs failure/DNF risk, not lap time (the two
## boosts must stay separate). Legacy installed parts with no stored `value` fall back to a
## small flat contribution so they aren't silently worthless.
const CNC_BONUS_CAP := 0.15
const CNC_LEGACY_FLAT := 0.005

func get_cnc_part_bonus(car_id: String) -> float:
	var installed = gs.car_installed_parts.get(car_id, {})
	if installed.is_empty(): return 0.0
	var total = 0.0
	for pcode in installed:
		var pd = installed[pcode]
		if not pd is Dictionary:
			## Legacy/malformed entry — count a small flat bonus rather than crash.
			total += CNC_LEGACY_FLAT
			continue
		var value = float(pd.get("value", 0.0))
		var quality = float(pd.get("quality", 1.0))
		if value > 0.0:
			total += value * quality
		else:
			## Provider part or a part installed before value was stored → flat fallback.
			total += CNC_LEGACY_FLAT
	return clamp(total, 0.0, CNC_BONUS_CAP)

## ── CNC Blueprint-based manufacturing (WRA-gated) ────────────────────────────

## Key format for cnc_parts_inventory: "CHAMP_ID|PCODE"
## Each value: { quantity, reliability, quality, blueprint_id }


func _cnc_inv_key(champ_id: String, pcode: String) -> String:
	return "%s|%s" % [champ_id, pcode]

## S28.3 (issue 4): number of parallel CNC production slots, derived from plant level.
## Uses the existing CNC_SLOTS_PER_LEVEL table (L1=1, L2=2, ...). Jobs beyond the slot
## count queue and start when a slot frees.
func get_cnc_slots() -> int:
	var building = gs.campus_buildings.get("CNC Parts Plant", {})
	if not building.get("built", false):
		return 1
	var lvl = int(building.get("level", 1))
	return max(1, int(gs.CNC_SLOTS_PER_LEVEL.get(lvl, lvl)))

## Compute manufacturing weeks from a blueprint (Formula doc §3).


func get_cnc_manufacturing_weeks(blueprint_id: String, extra_weeks: int = 0) -> int:
	var bp = gs.known_blueprints.get(blueprint_id, {})
	var cid = bp.get("championship_id", "C-001")
	var part = bp.get("part", "Aero")
	var cnc = gs.CNC_DATA.get(cid, gs.CNC_DATA.get("C-001", {}))
	const TIME_RATIO = {"Aero":0.4,"Engine":0.6,"Chassis":0.5,
		"Gearbox":0.25,"Brakes":0.2,"Suspension":0.25}
	var base = max(1, int(cnc.get("design_weeks", 4) * TIME_RATIO.get(part, 0.3)))
	return base + extra_weeks

## Compute manufacturing CR from a blueprint.


func get_cnc_manufacturing_cr(blueprint_id: String, quantity: int = 1, extra_cr: int = 0) -> int:
	var bp = gs.known_blueprints.get(blueprint_id, {})
	var cid = bp.get("championship_id", "C-001")
	var part = bp.get("part", "Aero")
	var cnc = gs.CNC_DATA.get(cid, gs.CNC_DATA.get("C-001", {}))
	const COST_RATIO = {"Aero":0.20,"Engine":0.35,"Chassis":0.25,
		"Gearbox":0.08,"Brakes":0.06,"Suspension":0.06}
	var unit = int(cnc.get("base_total_cost", 10000) * COST_RATIO.get(part, 0.10))
	return unit * quantity + extra_cr

## Compute final reliability (Formula doc §3).
## Base_Reliability = 60 + (seasons_since_wra_reset * 10), capped at 100.


func calculate_final_reliability(blueprint_id: String, extra_cr: int = 0, extra_weeks: int = 0) -> float:
	var bp = gs.known_blueprints.get(blueprint_id, {})
	var cid = bp.get("championship_id", "C-001")
	var group_season = _get_wra_group_season(cid)
	var base_rel = clamp(60.0 + (group_season - 1) * 10.0, 60.0, 100.0)
	var bonus_cr  = float(extra_cr)  / 12000.0
	var bonus_wk  = float(extra_weeks) * 5.0
	return clamp(base_rel + bonus_cr + bonus_wk, 0.0, 100.0)

## Returns how many seasons into the current WRA cycle a championship is.


func _get_wra_group_season(cid: String) -> int:
	const GROUP_MAP = {
		"Formula":["C-021","C-022","C-023","C-024"],
		"Touring":["C-005","C-006"],
		"Karting":["C-001"],
		"Open Wheel":["C-007","C-008","C-009"],
		"Stock Car":["C-010","C-011","C-012","C-013"],
		"Rally":["C-014","C-015","C-016","C-017"],
		"Endurance":["C-018","C-019","C-020"],
	}
	const CYCLE_LEN = {"Formula":4,"Touring":5,"Karting":6,"Open Wheel":7,
		"Stock Car":8,"Rally":9,"Endurance":10}
	for group in GROUP_MAP:
		if cid in GROUP_MAP[group]:
			var cycle = CYCLE_LEN.get(group, 4)
			return ((gs.current_season - 1) % cycle) + 1
	return 1

## Start a WRA-approved blueprint CNC job. Called from CNCPlant.


func start_cnc_job(blueprint_id: String, quantity: int = 1,
		extra_cr: int = 0, extra_weeks: int = 0) -> bool:
	if not is_blueprint_approved(blueprint_id):
		gs.add_notification("High", "Blueprint not WRA-approved. Submit it at the WRA Office in HQ first.")
		return false
	## Bug 8: a blueprint designed for a FUTURE season cannot be manufactured yet —
	## the CNC only unlocks it once that season begins. Prevents a next-season part
	## from becoming available in the current season.
	var bp_season = int(gs.known_blueprints.get(blueprint_id, {}).get("season", gs.current_season))
	if bp_season > gs.current_season:
		gs.add_notification("High",
			"This blueprint is for Season %d — it unlocks for CNC manufacturing when that season begins." % bp_season,
			"cnc_plant")
		return false
	var building = gs.campus_buildings.get("CNC Parts Plant", {})
	if not building.get("built", false):
		gs.add_notification("High", "CNC Parts Plant not built.")
		return false
	var total_cr = get_cnc_manufacturing_cr(blueprint_id, quantity, extra_cr)
	if gs.player_team.balance < total_cr:
		gs.add_notification("High", "Insufficient funds. Need CR %s." % gs._fmt_int(total_cr))
		return false
	var weeks = get_cnc_manufacturing_weeks(blueprint_id, extra_weeks)
	var reliability = calculate_final_reliability(blueprint_id, extra_cr, extra_weeks)
	var bp = gs.known_blueprints[blueprint_id]
	var quality = bp.get("quality", 1.0)
	gs.player_team.balance -= total_cr
	gs.cnc_production_queue.append({
		"id":            "%s_q%d" % [blueprint_id, gs.current_week],
		"blueprint_id":  blueprint_id,
		"part":          bp.get("part", ""),
		"part_code":     bp.get("part_code", ""),
		"championship_id": bp.get("championship_id", ""),
		"weeks_total":     weeks,
		"weeks_remaining": weeks,
		"cr_cost":         total_cr,
		"quantity":        quantity,
		"reliability":     reliability,
		"quality":         quality,
	})
	gs.add_log("⚙ CNC job queued: %dx %s — %dwks, CR %s, Rel %.0f%%, Qual %.2f×" % [
		quantity, bp.get("name", blueprint_id), weeks, gs._fmt_int(total_cr), reliability, quality])
	gs.add_notification("Normal", "CNC: %dx %s in production. Ready in %d weeks." % [
		quantity, bp.get("part", blueprint_id), weeks])
	gs.emit_signal("log_updated")
	return true

## Returns the installed CNC parts dict for a car.
## Format: { "AER": {reliability, quality, blueprint_id}, ... }


func get_cnc_stock_for_slot(champ_id: String, pcode: String) -> Array:
	const PCODE_TO_PART = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	var part_name = PCODE_TO_PART.get(pcode, pcode)
	var result: Array = []
	for inv_key in gs.cnc_parts_inventory:
		var item = gs.cnc_parts_inventory[inv_key]
		if not item is Dictionary: continue
		if item.get("quantity", 0) <= 0: continue
		if item.get("championship_id", "") != champ_id: continue
		var item_pcode = item.get("part_code", "")
		var item_part  = item.get("part", "")
		if item_pcode == pcode or item_part == part_name:
			result.append(inv_key)
	return result

## Returns the display label for a CNC inventory item: "Blueprint Name  L2"


func get_cnc_part_label(inv_key: String) -> String:
	var item = gs.cnc_parts_inventory.get(inv_key, {})
	if not item is Dictionary: return inv_key
	var bp_id = item.get("blueprint_id", "")
	var lvl = 0
	var bp_name = item.get("part", inv_key)
	if bp_id != "" and bp_id in gs.known_blueprints:
		var bp = gs.known_blueprints[bp_id]
		lvl = bp.get("level", 0)
		bp_name = bp.get("name", bp_name)
	var qty = item.get("quantity", 1)
	return "%s  L%d  (×%d)" % [bp_name, lvl, qty]

## Returns the blueprint grid status for a championship.
## { pcode: { "BP": [done_levels], "RE": bool, "in_progress": [task_ids], "wra_pending": [bp_ids], "wra_approved": [bp_ids] } }


func get_blueprint_grid(champ_id: String) -> Dictionary:
	const PCODES = ["AER","ENG","GRB","SUS","BRK","CHS"]
	const PCODE_TO_PART = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	var result: Dictionary = {}
	for pcode in PCODES:
		result[pcode] = {"bp_levels": [], "re": false, "in_progress": [], "wra_pending": [], "wra_approved": []}

	## Scan known_blueprints
	for bp_id in gs.known_blueprints:
		var bp = gs.known_blueprints[bp_id]
		if bp.get("championship_id", "") != champ_id: continue
		var pcode = _part_name_to_pcode(bp.get("part", ""))
		if pcode == "": continue
		var pillar = bp.get("pillar", 1)
		var lvl = bp.get("level", 1)
		if pillar == 1:
			if lvl not in result[pcode]["bp_levels"]:
				result[pcode]["bp_levels"].append(lvl)
		elif pillar == 3:
			result[pcode]["re"] = true

	## Scan active R&D tasks
	for task in gs.active_rnd_tasks:
		var tid = task.get("task_id", "")
		var tdata = gs.RND_TASKS.get(tid, {})
		if tdata.get("championship_id", task.get("championship_id","")) != champ_id: continue
		var pcode = _part_name_to_pcode(tdata.get("part", ""))
		if pcode == "" or pcode not in result: continue
		result[pcode]["in_progress"].append(tid)

	## Scan WRA submissions
	for sub in gs.active_wra_submissions:
		var bp_id = sub.get("blueprint_id", "")
		if not bp_id in gs.known_blueprints: continue
		var bp = gs.known_blueprints[bp_id]
		if bp.get("championship_id", "") != champ_id: continue
		var pcode = _part_name_to_pcode(bp.get("part", ""))
		if pcode == "" or pcode not in result: continue
		result[pcode]["wra_pending"].append(bp_id)

	## Scan WRA approved
	for app in gs.wra_approved_blueprints:
		var bp_id = app.get("blueprint_id", "")
		if not bp_id in gs.known_blueprints: continue
		var bp = gs.known_blueprints[bp_id]
		if bp.get("championship_id", "") != champ_id: continue
		var pcode = _part_name_to_pcode(bp.get("part", ""))
		if pcode == "" or pcode not in result: continue
		result[pcode]["wra_approved"].append(bp_id)

	return result


func get_rnd_perf_bonus_summary() -> String:
	var parts = ["aero_perf","engine_perf","chassis_perf","gearbox_perf","brakes_perf","susp_perf"]
	var total = 0.0
	for k in parts: total += get_rnd_bonus(k)
	if total <= 0.0: return "No R&D bonuses"
	return "+%.1f%% combined part performance" % (total * 100.0)

## ── R&D System ────────────────────────────────────────────────────────────────

## Returns true if a task's prerequisite is completed AND (for Pillar 4) the linked building is at the required level.


func rnd_task_unlocked(task_id: String) -> bool:
	var task = gs.RND_TASKS.get(task_id, {})
	if task.is_empty(): return false
	# Prerequisite task check (all pillars)
	var req = task.get("requires", "")
	if req != "" and not req in gs.completed_rnd_tasks:
		return false
	## S35.11 — P1 L2 unlocks when an L1 blueprint for this [champ][part][season] exists
	## from EITHER P1 (Design) OR P3 (Reverse Engineering). Resolved at part level so RE
	## genuinely opens L2 (previously L2 hard-required the P1 L1 task id, so an RE-only
	## player could never reach L2).
	var req_l1 = task.get("requires_l1_for", "")
	if req_l1 != "" and not _has_l1_blueprint_for(req_l1):
		return false
	# Pillar 4: building level gate + R&D Design Studio level gate
	if task.get("pillar", 0) == 4:
		var bname  = task.get("building", "")
		var min_lv = task.get("min_building_level", 1)
		if bname != "":
			var bld = gs.campus_buildings.get(bname, {})
			if not bld.get("built", false) or bld.get("level", 0) < min_lv:
				return false
		## S35.19 — also gate on R&D Design Studio level. The data carried
		## Required_RnD_Studio_Level on every P4 task but it was never enforced; now it is.
		var min_studio = int(task.get("Required_RnD_Studio_Level", 1))
		if min_studio > 1:
			var studio = gs.campus_buildings.get("R&D Design Studio", {})
			if not studio.get("built", false) or int(studio.get("level", 0)) < min_studio:
				return false
	return true

## S35.11 — True if a completed L1 (level==1, pillar 1 or 3) blueprint exists matching the
## "cid|pcode|season" key. Used by rnd_task_unlocked to gate P1 L2 on either design path.
func _has_l1_blueprint_for(key: String) -> bool:
	var parts = key.split("|")
	if parts.size() != 3: return false
	var cid = parts[0]
	var pcode = parts[1]
	var season = int(parts[2])
	for bp_id in gs.known_blueprints:
		var bp = gs.known_blueprints[bp_id]
		if bp.get("pillar", 0) not in [1, 3]: continue
		if int(bp.get("level", 0)) != 1: continue
		if bp.get("championship_id", "") != cid: continue
		if bp.get("part_code", "") != pcode: continue
		if int(bp.get("season", -1)) != season: continue
		return true
	return false

## Returns true if a task is already running or completed.


func rnd_task_active_or_done(task_id: String) -> bool:
	if task_id in gs.completed_rnd_tasks: return true
	for t in gs.active_rnd_tasks:
		if t["id"] == task_id: return true
	return false

## Starts a new R&D task. Returns false with notification on failure.


func start_rnd_task(task_id: String, designer_id: String, championship_id: String = "") -> bool:
	var task = gs.RND_TASKS.get(task_id, {})
	if task.is_empty():
		gs.add_notification("High", "Unknown R&D task: %s" % task_id)
		return false
	if rnd_task_active_or_done(task_id):
		gs.add_notification("Normal", "'%s' is already researched or in progress." % task["name"])
		return false
	if not rnd_task_unlocked(task_id):
		var req = task.get("requires", "")
		gs.add_notification("High", "Prerequisite not met: complete '%s' first." % gs.RND_TASKS.get(req, {}).get("name", req))
		return false
	if gs.research_points < task["rp"]:
		gs.add_notification("High", "Not enough RP. Need %d, have %.0f." % [task["rp"], gs.research_points])
		return false
	if gs.player_team.balance < task["cr"]:
		gs.add_notification("High", "Not enough CR. Need %s, have %s." % [gs._fmt_int(task["cr"]), gs._fmt_int(int(gs.player_team.balance))])
		return false
	if not designer_id in gs.all_staff:
		gs.add_notification("High", "Invalid designer.")
		return false
	for t in gs.active_rnd_tasks:
		if t["designer_id"] == designer_id:
			var other = gs.RND_TASKS.get(t["id"], {})
			gs.add_notification("High", "Designer already working on '%s'." % other.get("name", t["id"]))
			return false

	gs.research_points -= task["rp"]
	gs.player_team.balance -= task["cr"]

	gs.active_rnd_tasks.append({
		"id":              task_id,
		"name":            task["name"],
		"pillar":          task["pillar"],
		"part":            task["part"],
		"part_code":       task.get("part_code", _part_name_to_pcode(task["part"])),
		"championship_id": championship_id,
		## S35.11 — carry season + level so the blueprint stored at completion gets the correct
		## TARGET season (P1/P3 = next season). Previously these were absent, so completion fell
		## back to gs.current_season → blueprints stamped with the current season → TDL 8a never
		## fired and the CNC season-gate never blocked next-season parts (built them in S1).
		"season":          task.get("season", gs.current_season),
		"level":           task.get("level", 1),
		"weeks_total":     task["weeks"],
		"weeks_remaining": task["weeks"],
		"rp_cost":         task["rp"],
		"cr_cost":         task["cr"],
		"designer_id":     designer_id,
		"effect_key":      task.get("effect", ""),
		"effect_value":    task.get("value", 0.0),
	})

	var champ_label = ""
	if championship_id != "":
		var reg = gs.CHAMPIONSHIP_REGISTRY.get(championship_id, {})
		champ_label = " [%s]" % reg.get("name", championship_id)

	gs.add_log("🔬 R&D started: %s%s (%d weeks)" % [task["name"], champ_label, task["weeks"]])
	gs.add_notification("Normal", "R&D started: %s%s. Est. completion: Week %d." % [
		task["name"], champ_label, gs.current_week + task["weeks"]])
	gs.emit_signal("log_updated")
	return true

## Cancel an active R&D task — no refund.


func cancel_rnd_task(task_id: String) -> void:
	for i in range(gs.active_rnd_tasks.size()):
		if gs.active_rnd_tasks[i]["id"] == task_id:
			gs.add_log("❌ R&D cancelled: %s" % gs.active_rnd_tasks[i]["name"])
			gs.active_rnd_tasks.remove_at(i)
			gs.emit_signal("log_updated")
			return

## Called each advance_week — ticks all active R&D tasks.


func _advance_rnd_tasks() -> void:
	var finished = []
	for task in gs.active_rnd_tasks:
		task["weeks_remaining"] -= 1
		if task["weeks_remaining"] <= 0:
			finished.append(task)

	for task in finished:
		gs.active_rnd_tasks.erase(task)
		var tid = task["id"]
		var pillar = task.get("pillar", 0)

		if not tid in gs.completed_rnd_tasks:
			gs.completed_rnd_tasks.append(tid)

		if pillar == 1 or pillar == 3:
			if not tid in gs.completed_bp_tasks:
				gs.completed_bp_tasks.append(tid)
			## S35.11 — RE penalty is designer-scaled and baked into `quality` ONCE.
			## Because every higher level is a percentage of the previous level's stats,
			## the penalty rides the whole chain automatically — we only compute it here.
			##   re_quality = 0.75 + 0.25 × (designer_part_stat / 100)   [floor 0.75]
			## A strong designer pulls the reverse-engineered part back toward 1.0; a poor
			## one sits near the 0.75 floor. Driven by the part-relevant design stat
			## (aero/engine/…), falling back to parts_knowledge. Designers get NO discipline
			## adaptation (GDD §9-F), so no adaptation multiplier is applied.
			var bp_quality = 1.0
			var bp_value = float(task.get("effect_value", 0.0))
			if pillar == 3:
				bp_quality = _compute_re_quality(task)
			else:
				## P1 design: inherit the lineage quality so an L2 built on an RE'd L1 keeps
				## the penalty (and a clean own-design L1 stays at 1.0). Looks up the existing
				## L1 blueprint for this [champ][part][season]; defaults to 1.0 if none.
				bp_quality = _lineage_quality_for(
					task.get("championship_id",""), task.get("part_code",""),
					int(task.get("season", gs.current_season)))
				## S35.11 — P2 carry-over: a P1 *L1* design starts from the highest WRA-APPROVED
				## P2 level for this part THIS season (continuous performance build-up). The
				## designer then lifts that base by formula ii (multiplicative, capped 0.25):
				##   final = base × (1 + (designer_part_stat/100) × 0.25)
				## If no approved P2 level exists (P2 level 0, or a Spec part — Spec parts have
				## no P2 ladder), base falls back to the bare L1 design value. Spec parts are
				## handled automatically: their approved-P2 lookup returns 0. The accumulated
				## build-up is cleansed at the WRA 4-season regulation reset (§11). Only L1
				## carries the P2 base; L2+ build on L1 via their own ×2.0 chain as before.
				if int(task.get("level", 1)) == 1:
					bp_value = _compute_p1_base_value(task)
			gs.known_blueprints[tid] = {
				"blueprint_id": tid, "name": task["name"],
				"part": task.get("part",""), "part_code": task.get("part_code",""),
				"championship_id": task.get("championship_id",""),
				"season": task.get("season", gs.current_season),
				"level": task.get("level", 1), "pillar": pillar,
				"effect": task.get("effect_key",""), "value": bp_value,
				"quality": bp_quality,
			}
			gs.add_log("📋 Blueprint stored: %s → R&D + CNC database. [Val %.4f, Qual %.2f×]%s" % [
				tid, bp_value, bp_quality, " [RE]" if pillar == 3 else ""])
		elif pillar == 2:
			if not tid in gs.completed_upg_tasks:
				gs.completed_upg_tasks.append(tid)
			gs.known_blueprints[tid] = {
				"blueprint_id": tid, "name": task["name"],
				"part": task.get("part",""), "part_code": task.get("part_code",""),
				"championship_id": task.get("championship_id",""),
				"season": task.get("season", gs.current_season),
				"level": task.get("level", 1), "pillar": pillar, "seasonal": true,
				"effect": task.get("effect_key",""), "value": task.get("effect_value", 0.0),
			}
			gs.add_log("📋 Upgrade blueprint stored (Season %d only): %s → CNC." % [gs.current_season, tid])

		_apply_rnd_effect(task)
		var champ_label = ""
		if task.get("championship_id", "") != "":
			var reg = gs.CHAMPIONSHIP_REGISTRY.get(task["championship_id"], {})
			champ_label = " [%s]" % reg.get("name", task["championship_id"]).left(14)
		gs.add_log("✅ R&D complete: %s%s" % [task["name"], champ_label])
		if pillar == 3:
			## RE complete — notify that WRA submission is now available AND P1 L2 is unlocked
			gs.add_notification("High",
				"RE complete: '%s'%s. Blueprint ready — submit to WRA Office in HQ. Also unlocks P1 Design L2 for this part." % [task["name"], champ_label],
				"wra_office")
		else:
			gs.add_notification("High", "R&D complete: '%s'%s. Submit to WRA Office in HQ to manufacture." % [task["name"], champ_label], "wra_office")
	gs.emit_signal("log_updated")

## S35.11 — Maps a part name to the Designer stat that governs its design quality.
const PART_TO_DESIGNER_STAT = {
	"Aero":"aero","Engine":"engine","Brakes":"brakes",
	"Suspension":"suspension","Chassis":"chassis","Gearbox":"gearbox"
}

## S35.11 — Designer-scaled reverse-engineering quality (formula ii, floor 0.75):
##   re_quality = 0.75 + 0.25 × (designer_part_stat / 100)
## Driven by the part-relevant design stat, fallback parts_knowledge. No discipline
## adaptation (Designers are exempt, GDD §9-F). Returns 0.75 if the designer is missing.
func _compute_re_quality(task: Dictionary) -> float:
	const FLOOR := 0.75
	if not task.get("designer_id", "") in gs.all_staff:
		return FLOOR
	var stat_val = _designer_part_stat(task.get("designer_id",""), task.get("part",""))
	return clamp(FLOOR + (1.0 - FLOOR) * (stat_val / 100.0), FLOOR, 1.0)

## S35.11 — Designer contribution cap for P1 L1 design (formula ii, multiplicative).
## At designer_stat=100 a perfect designer lifts the inherited base by +25%. Named so the
## Phase 5 balance pass can retune it in one place.
const DESIGNER_CAP := 0.25

## S35.11 — Computes a P1 *L1* design's starting `value` (the continuous performance build-up):
##   base = highest WRA-APPROVED P2 level value for this part THIS season (0 if none / Spec)
##   if base > 0: final = base × (1 + (designer_part_stat/100) × DESIGNER_CAP)
##   else:        final = bare_L1_value × (1 + (designer_part_stat/100) × DESIGNER_CAP)
## The accumulated build-up resets at the WRA regulation change (§11), which wipes P1/P3 BPs.
func _compute_p1_base_value(task: Dictionary) -> float:
	var cid   = task.get("championship_id", "")
	var pcode = task.get("part_code", "")
	var part  = task.get("part", "")
	var bare_l1 = float(task.get("effect_value", 0.0))
	## P2 carry-over is read at the CURRENT season (the car you upgraded this year), NOT the
	## design's next-season target. Spec parts have no P2 ladder → returns 0 → bare L1 base.
	var base = _highest_approved_p2_value(cid, pcode, gs.current_season)
	if base <= 0.0:
		base = bare_l1
	var designer_stat = _designer_part_stat(task.get("designer_id",""), part)
	var factor = (designer_stat / 100.0) * DESIGNER_CAP
	return base * (1.0 + factor)

## S35.11 — Highest WRA-APPROVED P2 (Upgrade) blueprint value for a part in a given season.
## "Approved" is the gate: a researched-but-unsubmitted upgrade does not count. Each P2 level's
## stored `value` is already cumulative-by-multiplier, so we take the max approved level's value
## (not a sum). Returns 0.0 if no approved P2 upgrade exists for the part that season.
func _highest_approved_p2_value(cid: String, pcode: String, season: int) -> float:
	var best := 0.0
	for app in gs.wra_approved_blueprints:
		var bp_id = app.get("blueprint_id", "")
		if not bp_id in gs.known_blueprints: continue
		var bp = gs.known_blueprints[bp_id]
		if bp.get("pillar", 0) != 2: continue
		if bp.get("championship_id", "") != cid: continue
		if bp.get("part_code", "") != pcode: continue
		if int(bp.get("season", -1)) != season: continue
		var v = float(bp.get("value", 0.0))
		if v > best: best = v
	return best

## S35.11 — Part-relevant Designer design stat (aero/engine/…), fallback parts_knowledge, 0 if
## the designer is missing. No discipline adaptation (Designers exempt, GDD §9-F).
func _designer_part_stat(designer_id: String, part: String) -> float:
	if not designer_id in gs.all_staff:
		return 0.0
	var designer = gs.all_staff[designer_id]
	var stat_name = PART_TO_DESIGNER_STAT.get(part, "parts_knowledge")
	var raw = designer.get(stat_name)
	if raw == null:
		raw = designer.get("parts_knowledge")
	return float(raw) if raw != null else 0.0

## S35.11 — Returns the quality of an EXISTING L1 blueprint for this [champ][part][season]
## lineage, so a P1 L2 (or any higher level) inherits the penalty baked into its L1 base.
## Prefers an own-design (P1) L1 if both a P1 and a P3 L1 exist for the part; defaults 1.0.
func _lineage_quality_for(cid: String, pcode: String, season: int) -> float:
	var re_q := -1.0
	for bp_id in gs.known_blueprints:
		var bp = gs.known_blueprints[bp_id]
		if int(bp.get("level", 0)) != 1: continue
		if bp.get("championship_id", "") != cid: continue
		if bp.get("part_code", "") != pcode: continue
		if int(bp.get("season", -1)) != season: continue
		var pil = bp.get("pillar", 0)
		if pil == 1:
			return float(bp.get("quality", 1.0))   # own-design L1 wins → its quality
		elif pil == 3:
			re_q = float(bp.get("quality", 0.75))   # remember RE L1 in case no P1 L1
	return re_q if re_q >= 0.0 else 1.0

## S35.11 — When BOTH a P1 (Design) and a P3 (RE) L1 blueprint exist for the same part,
## the one with the better effective stats (value × quality) is the valid build source.
## Returns the winning blueprint_id for a given [champ][part_code][season], or "" if none.
func resolve_active_l1_blueprint(cid: String, pcode: String, season: int) -> String:
	var best_id := ""
	var best_score := -1.0
	for bp_id in gs.known_blueprints:
		var bp = gs.known_blueprints[bp_id]
		if bp.get("pillar", 0) not in [1, 3]: continue
		if int(bp.get("level", 0)) != 1: continue
		if bp.get("championship_id", "") != cid: continue
		if bp.get("part_code", "") != pcode: continue
		if int(bp.get("season", -1)) != season: continue
		var score = float(bp.get("value", 0.0)) * float(bp.get("quality", 1.0))
		if score > best_score:
			best_score = score
			best_id = bp_id
	return best_id

## Applies the effect of a completed R&D task.
## Effects are stored as car_performance_bonuses — applied in race sim.


func _apply_rnd_effect(task: Dictionary) -> void:
	var key = task["effect_key"]
	var value = task["effect_value"]
	if key == "": return
	# Store as cumulative bonus — race sim reads car_performance_bonuses
	if not "rnd_bonuses" in gs.player_team:
		gs.player_team.set_meta("rnd_bonuses", {})
	var bonuses = gs.player_team.get_meta("rnd_bonuses")
	bonuses[key] = bonuses.get(key, 0.0) + value
	gs.player_team.set_meta("rnd_bonuses", bonuses)
	gs.add_log("📈 R&D effect: %s +%.1f%%" % [key, value * 100.0])

## Returns total R&D performance bonus for a given effect key.


func get_rnd_bonus(effect_key: String) -> float:
	if not gs.player_team.has_meta("rnd_bonuses"):
		return 0.0
	return gs.player_team.get_meta("rnd_bonuses").get(effect_key, 0.0)


func get_rnd_rp_storage_cap() -> int:
	var rnd = gs.campus_buildings.get("R&D Design Studio", {})
	if not rnd.get("built", false): return 0
	return 800 + (rnd.get("level", 1) - 1) * 400


func _advance_wra_submissions() -> void:
	var approved: Array = []
	for sub in gs.active_wra_submissions:
		sub.weeks_remaining -= 1
		if sub.weeks_remaining <= 0:
			approved.append(sub)
	for sub in approved:
		gs.active_wra_submissions.erase(sub)
		gs.wra_approved_blueprints.append({
			"blueprint_id":    sub.blueprint_id,
			"championship_id": sub.championship_id,
			"pillar":          sub.pillar,
			"approved_season": gs.current_season,
			"approved_week":   gs.current_week,
		})
		var bp = gs.known_blueprints.get(sub.blueprint_id, {})
		gs.add_log("✅ WRA approved: %s" % bp.get("name", sub.blueprint_id))
		gs.add_notification("High",
			"WRA approved: '%s'. Ready for CNC manufacturing." % bp.get("name", sub.blueprint_id),
			"wra_office")


func submit_to_wra(blueprint_id: String) -> bool:
	if not blueprint_id in gs.known_blueprints: return false
	for sub in gs.active_wra_submissions:
		if sub.blueprint_id == blueprint_id: return false
	for app in gs.wra_approved_blueprints:
		if app.blueprint_id == blueprint_id: return false
	var bp = gs.known_blueprints[blueprint_id]
	var cid = bp.get("championship_id", "")
	var tier = _get_championship_tier(cid)
	var weeks = {1:1,2:2,3:4,4:5}.get(tier, 1)
	gs.active_wra_submissions.append({
		"blueprint_id":    blueprint_id,
		"championship_id": cid,
		"pillar":          bp.get("pillar", 1),
		"submitted_season": gs.current_season,
		"submitted_week":  gs.current_week,
		"weeks_remaining": weeks,
		"tier":            tier,
	})
	gs.add_log("📋 WRA submission: %s. Decision in %d weeks." % [
		bp.get("name", blueprint_id), weeks])
	gs.add_notification("Normal",
		"Blueprint submitted to WRA: '%s'. Decision in %d weeks." % [
			bp.get("name", blueprint_id), weeks])
	gs.emit_signal("log_updated")
	return true


func is_blueprint_approved(blueprint_id: String) -> bool:
	for app in gs.wra_approved_blueprints:
		if app.blueprint_id == blueprint_id: return true
	return false


func is_blueprint_submitted(blueprint_id: String) -> bool:
	for sub in gs.active_wra_submissions:
		if sub.blueprint_id == blueprint_id: return true
	return false


func _get_championship_tier(cid: String) -> int:
	return gs.CHAMPIONSHIP_REGISTRY.get(cid, {}).get("tier", 1)

## ═══════════════════════════════════════════════════════════════════════════
## SUPPLY CONTRACTS (S17)
## ═══════════════════════════════════════════════════════════════════════════


func get_installed_parts_for_car(car_id: String) -> Dictionary:
	return gs.car_installed_parts.get(car_id, {})

## Install a CNC part from inventory onto a car.


func _get_wra_group_for_championship(cid: String) -> String:
	const CID_TO_GROUP = {
		"C-001":"Karting",
		"C-005":"Rally","C-006":"Rally","C-007":"Rally","C-008":"Rally",
		"C-009":"Touring","C-010":"Touring",
		"C-011":"Open Wheel","C-012":"Open Wheel","C-013":"Open Wheel",
		"C-014":"Stock Car","C-015":"Stock Car","C-016":"Stock Car","C-017":"Stock Car",
		"C-018":"Endurance","C-019":"Endurance","C-020":"Endurance",
		"C-021":"Formula","C-022":"Formula","C-023":"Formula","C-024":"Formula",
	}
	return CID_TO_GROUP.get(cid, "Karting")

## Shared weekly expense total (staff + drivers + building maintenance)


func _part_name_to_pcode(part_name: String) -> String:
	match part_name:
		"Aero":       return "AER"
		"Engine":     return "ENG"
		"Gearbox":    return "GRB"
		"Suspension": return "SUS"
		"Brakes":     return "BRK"
		"Chassis":    return "CHS"
	return ""

## Returns the combined Pillar 1/2/3 R&D lap bonus for a descriptive key.
