extends Node
## Version: S18.3 — P4 special projects complete (100 entries); last_action_week set to current_week+1 on contract start so reply comes next week; cancel_sponsor with rep/mktg penalty.
##                    Driver.track_knowledge dict + update_track_knowledge(). Staff.track_knowledge_by_track
##                    + get_track_knowledge_for() + update_track_knowledge(). Lap time formula uses
##                    per-track knowledge for driver (-1% at TK100) and staff synergy.
##                    Post-race growth now keyed to track_id. Save/load extended for both resources.
##                    start_negotiation, submit_negotiation_offer, abandon_negotiation,
##                    _apply_negotiation_result. Driver weekly_salary now per-driver.
##                    Driver.gd/Staff.gd extended with bonus + release_clause fields.
##                    get_cnc_manufacturing_weeks/cr, calculate_final_reliability, _cnc_inv_key.
##                    Fixed _advance_cnc_production inventory format. RE completion now notifies WRA + P1 L2.

# Time
var current_week: int = 1
var current_season: int = 1
var max_weeks: int = 52

# Player team
var player_team: Team = null
var player_name: String = "Andreas"
var player_team_name: String = "My Racing Team"
var player_team_nationality: String = "British"
## P18 New Game fields — set via setup_new_game, used in HQ, race sim, CEO card
var ceo_sex:              String = "Male"
var ceo_age:              int    = 30
var team_color_primary:   Color  = Color(0.85, 0.15, 0.15)
var team_color_secondary: Color  = Color(0.95, 0.95, 0.95)
var game_difficulty:      String = "Realistic"
var _starting_champ_id:   String = "C-001"  ## Set by setup_new_game, used by _setup_championship

# All teams in the player's championship
var all_teams: Array = []

# All drivers in the player's championship
var all_drivers: Dictionary = {}

# The active championship
## Computed property — returns the first active championship, or a safe
## dummy Championship object if none are active (off-season with no registrations).
## This prevents null-access crashes in all building scenes and weekly processing.
var active_championship: Championship:
	get:
		if active_championships.size() > 0:
			return active_championships[0]
		# Return a safe dummy to prevent null crashes during off-season
		if _dummy_championship == null:
			_dummy_championship = Championship.new()
			_dummy_championship.id = ""
			_dummy_championship.championship_name = "No Active Championship"
			_dummy_championship.discipline = "GK"
			_dummy_championship.num_races = 0
			_dummy_championship.calendar = []
			_dummy_championship.standings = {}
			_dummy_championship.team_standings = {}
			_dummy_championship.points_system = []
			_dummy_championship.prize_1st = 0.0
			_dummy_championship.prize_2nd = 0.0
			_dummy_championship.prize_3rd = 0.0
			_dummy_championship.sp_per_10_pct_damage = 100
			_dummy_championship.fuel_per_car_per_race = 15.0
			_dummy_championship.condition_loss_per_lap = 0.5
			_dummy_championship.has_mid_race_repairs = false
			_dummy_championship.min_age = 0
			_dummy_championship.max_age = 99
			_dummy_championship.current_round = 0
		return _dummy_championship

var _dummy_championship: Championship = null

var active_championships: Array = []           # All Championship objects running this season
var player_registered_championships: Array = [] # IDs the player has paid entry fees for next season

# Last race data - for results screen
var last_race_round: int = 0
var last_race_laps:  int = 0
var last_race_name: String = ""
var last_race_wet: bool = false
var last_race_results: Array = []
var last_race_championship: String = ""
var last_race_championship_id: String = ""
var last_race_num_races: int = 0
var last_race_standings:    Array = []
var last_race_staff_deltas: Array = []

## Maps driver_id / staff_id → championship_id they ran in last season
## Used to show "Prev: GK Regional" badge in Drivers/Staff screens
var previous_season_championship: Dictionary = {}

# Hall of fame
var hall_of_fame: Array = []

# Campus buildings state
var campus_buildings: Dictionary = {}
var active_sponsor: Dictionary = {}
var sponsor_no_points_streak: int = 0

# UI navigation helpers — set before changing scene, read + cleared on arrival
var pending_staff_filter:   String = ""  # e.g. "Team Principal", "CFO" — StaffHub reads this on _ready
var pending_rnd_pillar:     int    = 1   # RnDStudio reads this to restore tab selection
var pending_rnd_champ_id:   String = ""  # RnDStudio reads this to restore championship selection
## Delayed championship assignments for TP/Strategist (applied at start of next week)
## Format: { staff_id: champ_id }
var pending_staff_assignments: Dictionary = {}

# Resources
var research_points: float = 0.0

## Active R&D tasks: Array of Dicts
## {id, name, pillar, part, weeks_total, weeks_remaining, rp_cost, cr_cost,
##  designer_id, championship_id, completed, effect_key, effect_value}
var active_rnd_tasks: Array = []
var completed_rnd_tasks: Array = []   # All completed task IDs — drives prerequisite checks
var completed_bp_tasks:  Array = []   # P1 + P3 blueprints — permanent until WRA cycle reset
var completed_upg_tasks: Array = []   # P2 upgrades — cleared each season start
var known_blueprints: Dictionary = {} # blueprint_id → full blueprint record, delivered to CNC
var wra_cycle_start_season: int = 1
const WRA_CYCLE_LENGTH: int = 4
const WRA_APPROVAL_WEEKS: Dictionary = { 1:2, 2:3, 3:5, 4:6 }
const WRA_SUBMISSION_FEE:  Dictionary = { 1:500, 2:1500, 3:4000, 4:10000 }
const CNC_BASE_WEEKS: Dictionary = {
	"Aero":3,"Engine":5,"Gearbox":4,"Suspension":3,"Brakes":2,"Chassis":6 }
const CNC_BASE_CR: Dictionary = {
	"Aero":8000,"Engine":15000,"Gearbox":10000,
	"Suspension":8000,"Brakes":6000,"Chassis":18000 }
const CNC_SLOTS_PER_LEVEL: Dictionary = { 1:1,2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9 }
var wra_cycle_starts: Dictionary = {
	"Formula":1,"Touring":1,"Karting":1,
	"Open Wheel":1,"Stock Car":1,"Rally":1,"Endurance":1
}
## WRA Approval
var active_wra_submissions:  Array = []
var wra_approved_blueprints: Array = []
var wra_rejected_blueprints: Array = []
## CNC
var car_installed_parts:  Dictionary = {}  ## CNC parts: { car_id: { pcode: {rel,qual,bp_id,part} } }
var car_provider_parts:   Dictionary = {}  ## Provider (L0) parts: { car_id: { pcode: {condition} } }
var pending_cnc_blueprint: String = ""
## Supply Contracts
var active_supply_contracts: Array = []
var supply_contract_history: Array = []
## Sponsors
var active_sponsors:             Array = []
var sponsor_offers:              Array = []
var cfo_search_active:           bool  = false
var cfo_search_weeks_remaining:  int   = 0
var cfo_search_results:          Array = []
## Financial / Economy
var ceo_accumulated_salary: float  = 0.0
var global_economy_state:   String = "Normal"
var current_fuel_price:     float  = 1200.0
var current_loan:           float  = 0.0
var _prev_week_balance:     float  = 0.0
## Navigation
var pending_hq_tab: String = ""
## Set by _end_season / start_new_season so MainHub knows which screen to show on next load.
## Values: "" (normal), "end_of_season", "begin_of_season"
var pending_season_screen: String = ""

## CNC Production Queue: Array of Dicts
## {id, part, championship_id, weeks_total, weeks_remaining, cr_cost, quantity}
var cnc_production_queue: Array = []
## Manufactured parts inventory: {"Aero": 2, "Engine": 1, ...}
var cnc_parts_inventory: Dictionary = {}

## R&D Task Catalog — built dynamically in _ready() via _build_rnd_tasks().
## P1/P2/P3 tasks are generated per-championship (144 P1 tasks, etc.)
## P4 Special Projects are hardcoded below and merged in at build time.
var RND_TASKS: Dictionary = {}

var spare_parts: int = 300        # units — used for repairs only, not auto-deducted per race
var fuel_kg: float = 30.0         # kg, starts with 2 races worth (15 kg × 1 car × 2)

# Car objects — replaces car_conditions dictionary
var player_team_cars: Array = []  # Array of Car objects

# Staff pool — all staff in the game world (hired + available)
var all_staff: Dictionary = {}    # staff_id → Staff

# Part inventory — stock of major car parts
# Keyed by championship_id then part name
# e.g. part_inventory["C-001"]["Aero"] = 3
var part_inventory: Dictionary = {}

# Part costs per championship (from CNC sheet — buy price per unit)
const PART_COSTS = {
	## GK series — small, inexpensive kart parts
	"C-001": {"Engine":  1950, "Aero":  1625, "Brakes":   487, "Suspension":   650, "Chassis":  1137, "Gearbox":   650},
	"C-002": {"Engine":  3200, "Aero":  2800, "Brakes":   750, "Suspension":  1100, "Chassis":  1900, "Gearbox":  1100},
	"C-003": {"Engine":  5500, "Aero":  4800, "Brakes":  1200, "Suspension":  1800, "Chassis":  3200, "Gearbox":  1800},
	"C-004": {"Engine":  9000, "Aero":  8000, "Brakes":  2000, "Suspension":  3000, "Chassis":  5500, "Gearbox":  3000},
	## Rally series
	"C-005": {"Engine": 18000, "Aero": 12000, "Brakes":  5000, "Suspension":  8000, "Chassis": 15000, "Gearbox":  9000},
	"C-006": {"Engine": 32000, "Aero": 22000, "Brakes":  9000, "Suspension": 14000, "Chassis": 27000, "Gearbox": 16000},
	"C-007": {"Engine": 55000, "Aero": 38000, "Brakes": 15000, "Suspension": 24000, "Chassis": 46000, "Gearbox": 28000},
	"C-008": {"Engine":120000, "Aero": 85000, "Brakes": 32000, "Suspension": 52000, "Chassis":100000, "Gearbox": 62000},
	## Touring Car series
	"C-009": {"Engine": 22000, "Aero": 18000, "Brakes":  7000, "Suspension": 11000, "Chassis": 19000, "Gearbox": 13000},
	"C-010": {"Engine": 48000, "Aero": 40000, "Brakes": 15000, "Suspension": 24000, "Chassis": 42000, "Gearbox": 28000},
	## Open Wheel series
	"C-011": {"Engine": 28000, "Aero": 32000, "Brakes":  9000, "Suspension": 15000, "Chassis": 24000, "Gearbox": 18000},
	"C-012": {"Engine": 65000, "Aero": 72000, "Brakes": 20000, "Suspension": 34000, "Chassis": 58000, "Gearbox": 42000},
	"C-013": {"Engine":140000, "Aero":160000, "Brakes": 44000, "Suspension": 72000, "Chassis":128000, "Gearbox": 92000},
	## Stock Car series
	"C-014": {"Engine": 35000, "Aero": 15000, "Brakes": 12000, "Suspension": 18000, "Chassis": 28000, "Gearbox": 22000},
	"C-015": {"Engine": 62000, "Aero": 26000, "Brakes": 21000, "Suspension": 32000, "Chassis": 50000, "Gearbox": 40000},
	"C-016": {"Engine":110000, "Aero": 45000, "Brakes": 36000, "Suspension": 56000, "Chassis": 88000, "Gearbox": 70000},
	"C-017": {"Engine":200000, "Aero": 80000, "Brakes": 65000, "Suspension":100000, "Chassis":160000, "Gearbox":125000},
	## Endurance series
	"C-018": {"Engine": 42000, "Aero": 36000, "Brakes": 14000, "Suspension": 22000, "Chassis": 38000, "Gearbox": 26000},
	"C-019": {"Engine": 90000, "Aero": 78000, "Brakes": 30000, "Suspension": 48000, "Chassis": 82000, "Gearbox": 56000},
	"C-020": {"Engine":200000, "Aero":175000, "Brakes": 66000, "Suspension":108000, "Chassis":185000, "Gearbox":125000},
	## Formula series
	"C-021": {"Engine": 45000, "Aero": 52000, "Brakes": 14000, "Suspension": 24000, "Chassis": 40000, "Gearbox": 30000},
	"C-022": {"Engine":100000, "Aero":115000, "Brakes": 30000, "Suspension": 52000, "Chassis": 88000, "Gearbox": 66000},
	"C-023": {"Engine":220000, "Aero":255000, "Brakes": 66000, "Suspension":115000, "Chassis":195000, "Gearbox":145000},
	"C-024": {"Engine":520000, "Aero":600000, "Brakes":155000, "Suspension":270000, "Chassis":460000, "Gearbox":340000},
}

const PARTS_LIST = ["Aero", "Engine", "Gearbox", "Suspension", "Brakes", "Chassis"]

## CNC data per championship — Excel CNC sheet.
## design_weeks  : weeks to design new season car. Entry deadline = 52 - design_weeks.
## engine_weeks  : longest part build time (Engine). Car delivery = max(engine_weeks, race1-1).
## base_total_cost: full car unit cost at Season 1 (scales +5%/season from providers).
## sale_multiplier: recommended markup when player sells own-built cars.
const CNC_DATA = {
	"C-001": {"design_weeks":  2, "engine_weeks": 1, "base_total_cost":    6500, "sale_multiplier": 1.5},
	"C-002": {"design_weeks":  2, "engine_weeks": 1, "base_total_cost":   12500, "sale_multiplier": 1.6},
	"C-003": {"design_weeks":  2, "engine_weeks": 1, "base_total_cost":   16000, "sale_multiplier": 1.7},
	"C-004": {"design_weeks":  3, "engine_weeks": 1, "base_total_cost":   24000, "sale_multiplier": 1.8},
	"C-005": {"design_weeks":  8, "engine_weeks": 2, "base_total_cost":   85000, "sale_multiplier": 1.6},
	"C-006": {"design_weeks":  8, "engine_weeks": 2, "base_total_cost":  125000, "sale_multiplier": 1.7},
	"C-007": {"design_weeks": 12, "engine_weeks": 3, "base_total_cost":  340000, "sale_multiplier": 1.8},
	"C-008": {"design_weeks": 24, "engine_weeks": 3, "base_total_cost": 1400000, "sale_multiplier": 2.0},
	"C-009": {"design_weeks": 14, "engine_weeks": 3, "base_total_cost":  260000, "sale_multiplier": 1.8},
	"C-010": {"design_weeks": 20, "engine_weeks": 4, "base_total_cost":  800000, "sale_multiplier": 1.9},
	"C-011": {"design_weeks": 10, "engine_weeks": 2, "base_total_cost":  145000, "sale_multiplier": 1.6},
	"C-012": {"design_weeks": 12, "engine_weeks": 3, "base_total_cost":  285000, "sale_multiplier": 1.7},
	"C-013": {"design_weeks": 16, "engine_weeks": 4, "base_total_cost":  750000, "sale_multiplier": 1.8},
	"C-014": {"design_weeks":  8, "engine_weeks": 2, "base_total_cost":  140000, "sale_multiplier": 1.5},
	"C-015": {"design_weeks": 12, "engine_weeks": 3, "base_total_cost":  185000, "sale_multiplier": 1.6},
	"C-016": {"design_weeks": 14, "engine_weeks": 3, "base_total_cost":  245000, "sale_multiplier": 1.7},
	"C-017": {"design_weeks": 12, "engine_weeks": 3, "base_total_cost":  550000, "sale_multiplier": 1.7},
	"C-018": {"design_weeks": 12, "engine_weeks": 3, "base_total_cost":  315000, "sale_multiplier": 1.7},
	"C-019": {"design_weeks": 16, "engine_weeks": 4, "base_total_cost":  690000, "sale_multiplier": 1.9},
	"C-020": {"design_weeks": 32, "engine_weeks": 8, "base_total_cost": 6000000, "sale_multiplier": 2.1},
	"C-021": {"design_weeks":  8, "engine_weeks": 2, "base_total_cost":  110000, "sale_multiplier": 1.6},
	"C-022": {"design_weeks": 10, "engine_weeks": 2, "base_total_cost":  165000, "sale_multiplier": 1.7},
	"C-023": {"design_weeks": 16, "engine_weeks": 4, "base_total_cost":  650000, "sale_multiplier": 1.8},
	"C-024": {"design_weeks": 40, "engine_weeks": 9, "base_total_cost":20000000, "sale_multiplier": 2.2},
}

## First race week per championship — from Excel Race Calendar sheet.
const FIRST_RACE_WEEK = {
	"C-001": 6,  "C-002": 6,  "C-003": 6,  "C-004": 6,
	"C-005": 5,  "C-006": 5,  "C-007": 4,  "C-008": 5,
	"C-009": 6,  "C-010": 6,
	"C-011": 6,  "C-012": 6,  "C-013": 6,
	"C-014": 7,  "C-015": 7,  "C-016": 6,  "C-017": 6,
	"C-018": 6,  "C-019": 6,  "C-020": 6,
	"C-021": 6,  "C-022": 6,  "C-023": 6,  "C-024": 10,
}

## Drivers required per car — from Team Car & Driver Limit Matrix (Brainstorming doc)
## GK/GP/OWC/SC: 1 driver | Rally (WRC) / TC (GT3/GT4): 2 drivers | EPC (WEC/LMP): 3 drivers
const DRIVERS_PER_CAR = {
	"GK":    1,  # All GK championships
	"Rally": 2,  # WRC, RALLY2, RALLY3, RALLY4 (co-driver)
	"TC":    2,  # GT3 / GT4 (driver pairs in endurance)
	"OWC":   1,  # IndyCar series
	"SC":    1,  # NASCAR series
	"EPC":   3,  # WEC Hypercars, LMP2, LMP3 (driver trios)
	"GP":    1,  # Formula 1/2/3/4
}

## Pit crew required per car — 1 per car for all non-GK championships
## GK championships: no pit crew required (karts don't pit)
const PIT_CREW_REQUIRED = {
	"GK":    false,
	"Rally": true,
	"TC":    true,
	"OWC":   true,
	"SC":    true,
	"EPC":   true,
	"GP":    true,
}

## Notification destination scene paths (S20)
const NOTIFICATION_DESTINATIONS: Dictionary = {
	"hq":             "res://scenes/buildings/HQ.tscn",
	"logistics":      "res://scenes/buildings/Logistics.tscn",
	"garage":         "res://scenes/buildings/Garage.tscn",
	"rnd_studio":     "res://scenes/buildings/RnDStudio.tscn",
	"cnc_plant":      "res://scenes/buildings/CNCPlant.tscn",
	"staff_hub":      "res://scenes/Staff.tscn",
	"drivers":        "res://scenes/Drivers.tscn",
	"wra_office":     "res://scenes/buildings/HQ.tscn",
	"racing_center":  "res://scenes/buildings/RacingDept.tscn",
	"campus":         "res://scenes/campus.tscn",
	"financial_dept": "res://scenes/FinancialDept.tscn",
}
const NOTIFICATION_DESTINATION_LABELS: Dictionary = {
	"hq":             "Go to HQ \u2192",
	"logistics":      "Go to Logistics \u2192",
	"garage":         "Go to Garage \u2192",
	"rnd_studio":     "Go to R&D Studio \u2192",
	"cnc_plant":      "Go to CNC Plant \u2192",
	"staff_hub":      "Go to Staff Hub \u2192",
	"drivers":        "Go to Drivers \u2192",
	"wra_office":     "Go to WRA Office \u2192",
	"racing_center":  "Go to Racing Center \u2192",
	"campus":         "Go to Campus \u2192",
	"financial_dept": "Go to Financial Dept \u2192",
}

## Championship short codes — used in RnD task ID generation
const CHAMP_CODES: Dictionary = {
	"C-001":"GKR","C-002":"GKN","C-003":"GKC","C-004":"GKW",
	"C-005":"RL4","C-006":"RL3","C-007":"RL2","C-008":"RLP",
	"C-009":"TCS","C-010":"TCE",
	"C-011":"OWN","C-012":"OWD","C-013":"OWP",
	"C-014":"SCD","C-015":"SCT","C-016":"SCC","C-017":"SCU",
	"C-018":"EPS","C-019":"EPL","C-020":"EPH",
	"C-021":"GP4","C-022":"GP3","C-023":"GP2","C-024":"GP1",
}

## Full championship registry — from Excel Championships sheet.
## entry_fee: one-time registration fee (not per race)
## entry_fee_per_race is the old field — kept for race prize calculations only
const CHAMPIONSHIP_REGISTRY = {
	"C-001": {"name":"GK Regional Championship",    "discipline":"GK",    "tier":1, "min_age":8,  "max_age":16, "entry_fee":9000,     "num_races":6,  "rep":15},
	"C-002": {"name":"GK National Championship",    "discipline":"GK",    "tier":2, "min_age":10, "max_age":16, "entry_fee":85000,    "num_races":10, "rep":24},
	"C-003": {"name":"GK Continental Championship", "discipline":"GK",    "tier":3, "min_age":12, "max_age":16, "entry_fee":40000,    "num_races":4,  "rep":31},
	"C-004": {"name":"GK World Championship",       "discipline":"GK",    "tier":4, "min_age":14, "max_age":16, "entry_fee":12000,    "num_races":1,  "rep":39},
	"C-005": {"name":"RALLY4",                      "discipline":"Rally", "tier":1, "min_age":16, "max_age":99, "entry_fee":30000,    "num_races":5,  "rep":36},
	"C-006": {"name":"RALLY3",                      "discipline":"Rally", "tier":2, "min_age":16, "max_age":99, "entry_fee":140000,   "num_races":7,  "rep":42},
	"C-007": {"name":"RALLY2",                      "discipline":"Rally", "tier":3, "min_age":16, "max_age":99, "entry_fee":700000,   "num_races":14, "rep":52},
	"C-008": {"name":"Premier Rally Championship",  "discipline":"Rally", "tier":4, "min_age":18, "max_age":99, "entry_fee":1680000,  "num_races":14, "rep":79},
	"C-009": {"name":"TC Sport Series",             "discipline":"TC",    "tier":2, "min_age":16, "max_age":99, "entry_fee":162000,   "num_races":6,  "rep":58},
	"C-010": {"name":"TC Elite Championship",       "discipline":"TC",    "tier":3, "min_age":17, "max_age":99, "entry_fee":375000,   "num_races":6,  "rep":82},
	"C-011": {"name":"OWC Next Gen",                "discipline":"OWC",   "tier":2, "min_age":15, "max_age":99, "entry_fee":115200,   "num_races":8,  "rep":49},
	"C-012": {"name":"OWC Development Series",      "discipline":"OWC",   "tier":3, "min_age":16, "max_age":99, "entry_fee":1078000,  "num_races":14, "rep":65},
	"C-013": {"name":"OWC Pro Series",              "discipline":"OWC",   "tier":4, "min_age":17, "max_age":99, "entry_fee":6800000,  "num_races":17, "rep":91},
	"C-014": {"name":"SC Dev Series",               "discipline":"SC",    "tier":1, "min_age":15, "max_age":99, "entry_fee":600000,   "num_races":20, "rep":46},
	"C-015": {"name":"SC Truck Series",             "discipline":"SC",    "tier":2, "min_age":16, "max_age":99, "entry_fee":2010200,  "num_races":23, "rep":61},
	"C-016": {"name":"SC Challenge",                "discipline":"SC",    "tier":3, "min_age":17, "max_age":99, "entry_fee":7095000,  "num_races":33, "rep":68},
	"C-017": {"name":"SC Cup",                      "discipline":"SC",    "tier":4, "min_age":18, "max_age":99, "entry_fee":32400000, "num_races":36, "rep":89},
	"C-018": {"name":"EPC Series",                  "discipline":"EPC",   "tier":2, "min_age":16, "max_age":99, "entry_fee":115200,   "num_races":6,  "rep":55},
	"C-019": {"name":"EPC League",                  "discipline":"EPC",   "tier":3, "min_age":17, "max_age":99, "entry_fee":420000,   "num_races":7,  "rep":71},
	"C-020": {"name":"EPC Hyper League",            "discipline":"EPC",   "tier":4, "min_age":18, "max_age":99, "entry_fee":1600000,  "num_races":8,  "rep":94},
	"C-021": {"name":"GP4",                         "discipline":"GP",    "tier":1, "min_age":15, "max_age":99, "entry_fee":66000,    "num_races":6,  "rep":44},
	"C-022": {"name":"GP3",                         "discipline":"GP",    "tier":2, "min_age":16, "max_age":99, "entry_fee":1250000,  "num_races":10, "rep":63},
	"C-023": {"name":"GP2",                         "discipline":"GP",    "tier":3, "min_age":17, "max_age":99, "entry_fee":4410000,  "num_races":14, "rep":74},
	"C-024": {"name":"GP1",                         "discipline":"GP",    "tier":4, "min_age":18, "max_age":99, "entry_fee":31680000, "num_races":24, "rep":100},
}

## Full race calendars for all 24 championships — from Brainstorming doc Race Calendar section.
## Rally (C-005 to C-008): "laps" = total race distance km (staged rally format).
## Endurance (C-018 to C-020 / EPC): "laps" = hours of racing.
## All others: "laps" = number of racing laps, "lap_km" = km per lap.
## Converts a track name to a stable lowercase slug used as track_id.
## "Super Karting Raceway" → "super_karting_raceway"
static func track_slug(name: String) -> String:
	return name.to_lower().replace(" ", "_").replace("-", "_").replace("'", "").replace(",", "")

const CHAMPIONSHIP_CALENDARS = {
	"C-001": [ # GK Regional
		{"round":1,"name":"Super Karting Raceway","track_id":"super_karting_raceway",    "week":6, "rain":0,  "laps":20,"lap_km":0.42,"audience":120},
		{"round":2,"name":"Riverside Kart Park","track_id":"riverside_kart_park",       "week":12,"rain":20, "laps":20,"lap_km":0.51,"audience":95},
		{"round":3,"name":"The Brickyard Junior","track_id":"the_brickyard_junior",      "week":18,"rain":0,  "laps":24,"lap_km":0.40,"audience":150},
		{"round":4,"name":"Ocean Breeze Arena","track_id":"ocean_breeze_arena",         "week":24,"rain":100,"laps":20,"lap_km":0.39,"audience":40},
		{"round":5,"name":"Pinnacle Heights","track_id":"pinnacle_heights",             "week":32,"rain":10, "laps":20,"lap_km":0.55,"audience":180},
		{"round":6,"name":"Metro Kart Complex","track_id":"metro_kart_complex",         "week":40,"rain":40, "laps":20,"lap_km":0.66,"audience":310},
	],
	"C-002": [ # GK National
		{"round":1, "name":"Super Karting Raceway",        "track_id":"super_karting_raceway",        "week":4, "rain":0,  "laps":18,"lap_km":0.90,"audience":1200},
		{"round":2, "name":"Valley International Karting", "track_id":"valley_international_karting", "week":8, "rain":5,  "laps":18,"lap_km":1.05,"audience":1450},
		{"round":3, "name":"Ocean Breeze Arena",           "track_id":"ocean_breeze_arena",           "week":12,"rain":0,  "laps":16,"lap_km":1.10,"audience":1900},
		{"round":4, "name":"Black Tarmac Challenge",       "track_id":"black_tarmac_challenge",       "week":16,"rain":15, "laps":20,"lap_km":0.80,"audience":1650},
		{"round":5, "name":"Speedway Center",              "track_id":"speedway_center",              "week":20,"rain":0,  "laps":20,"lap_km":0.95,"audience":2100},
		{"round":6, "name":"High Plains Raceway",          "track_id":"high_plains_raceway",          "week":24,"rain":0,  "laps":20,"lap_km":1.00,"audience":2300},
		{"round":7, "name":"Kartland",                     "track_id":"kartland",                     "week":28,"rain":45, "laps":15,"lap_km":1.02,"audience":850},
		{"round":8, "name":"Metro Kart Complex",           "track_id":"metro_kart_complex",           "week":32,"rain":100,"laps":16,"lap_km":0.90,"audience":550},
		{"round":9, "name":"PF International Kart Circuit","track_id":"pf_international_kart_circuit","week":36,"rain":0,  "laps":20,"lap_km":1.10,"audience":3400},
		{"round":10,"name":"Trackhouse Motorplex","track_id":"trackhouse_motorplex",        "week":40,"rain":0,  "laps":24,"lap_km":1.20,"audience":4800},
	],
	"C-003": [ # GK Continental
		{"round":1,"name":"Le Castellet","track_id":"le_castellet","week":9, "rain":0, "laps":27,"lap_km":5.80,"audience":6500},
		{"round":2,"name":"Spa","track_id":"spa",        "week":17,"rain":20,"laps":25,"lap_km":7.00,"audience":7200},
		{"round":3,"name":"Chemnitz","track_id":"chemnitz",   "week":25,"rain":15,"laps":24,"lap_km":4.20,"audience":8900},
		{"round":4,"name":"Le Mans","track_id":"le_mans",    "week":33,"rain":25,"laps":26,"lap_km":13.60,"audience":14500},
	],
	"C-004": [ # GK World
		{"round":1,"name":"Lemans Karting International","track_id":"lemans_karting_international","week":40,"rain":0,"laps":28,"lap_km":1.20,"audience":22000},
	],
	"C-005": [ # RALLY4
		{"round":1,"name":"Sweden","track_id":"sweden", "week":7, "rain":100,"laps":305,"lap_km":1.0,"audience":45000},
		{"round":2,"name":"Croatia","track_id":"croatia","week":15,"rain":80, "laps":289,"lap_km":1.0,"audience":62000},
		{"round":3,"name":"Portugal","track_id":"portugal","week":19,"rain":0,  "laps":345,"lap_km":1.0,"audience":88000},
		{"round":4,"name":"Finland","track_id":"finland","week":31,"rain":20, "laps":320,"lap_km":1.0,"audience":115000},
		{"round":5,"name":"Chile","track_id":"chile",  "week":37,"rain":60, "laps":313,"lap_km":1.0,"audience":38000},
	],
	"C-006": [ # RALLY3
		{"round":1,"name":"Monte-Carlo","track_id":"monte_carlo",   "week":4, "rain":0, "laps":325,"lap_km":1.0,"audience":95000},
		{"round":2,"name":"Kenya","track_id":"kenya",         "week":11,"rain":0, "laps":368,"lap_km":1.0,"audience":140000},
		{"round":3,"name":"Croatia","track_id":"croatia",       "week":15,"rain":80,"laps":300,"lap_km":1.0,"audience":85000},
		{"round":4,"name":"Islas Canarias","track_id":"islas_canarias","week":17,"rain":10,"laps":225,"lap_km":1.0,"audience":110000},
		{"round":5,"name":"Greece","track_id":"greece",        "week":26,"rain":0, "laps":310,"lap_km":1.0,"audience":78000},
		{"round":6,"name":"Paraguay","track_id":"paraguay",      "week":35,"rain":0, "laps":319,"lap_km":1.0,"audience":64000},
		{"round":7,"name":"Sardegna","track_id":"sardegna",      "week":41,"rain":50,"laps":332,"lap_km":1.0,"audience":125000},
	],
	"C-007": [ # RALLY2
		{"round":1, "name":"Monte-Carlo",    "track_id":"monte_carlo",    "week":4, "rain":50,"laps":339,"lap_km":1.0,"audience":185000},
		{"round":2, "name":"Sweden",         "track_id":"sweden",         "week":7, "rain":80,"laps":301,"lap_km":1.0,"audience":120000},
		{"round":3, "name":"Kenya",          "track_id":"kenya",          "week":11,"rain":0, "laps":351,"lap_km":1.0,"audience":260000},
		{"round":4, "name":"Croatia",        "track_id":"croatia",        "week":15,"rain":30,"laps":300,"lap_km":1.0,"audience":145000},
		{"round":5, "name":"Islas Canarias", "track_id":"islas_canarias", "week":17,"rain":0, "laps":322,"lap_km":1.0,"audience":165000},
		{"round":6, "name":"Portugal",       "track_id":"portugal",       "week":19,"rain":0, "laps":330,"lap_km":1.0,"audience":310000},
		{"round":7, "name":"Japan",          "track_id":"japan",          "week":22,"rain":20,"laps":303,"lap_km":1.0,"audience":190000},
		{"round":8, "name":"Greece",         "track_id":"greece",         "week":26,"rain":0, "laps":329,"lap_km":1.0,"audience":155000},
		{"round":9, "name":"Estonia",        "track_id":"estonia",        "week":29,"rain":30,"laps":315,"lap_km":1.0,"audience":135000},
		{"round":10,"name":"Finland","track_id":"finland",       "week":31,"rain":0, "laps":317,"lap_km":1.0,"audience":380000},
		{"round":11,"name":"Paraguay","track_id":"paraguay",      "week":35,"rain":0, "laps":310,"lap_km":1.0,"audience":110000},
		{"round":12,"name":"Chile","track_id":"chile",         "week":37,"rain":60,"laps":312,"lap_km":1.0,"audience":95000},
		{"round":13,"name":"Sardegna","track_id":"sardegna",      "week":40,"rain":40,"laps":320,"lap_km":1.0,"audience":175000},
		{"round":14,"name":"Saudi Arabia","track_id":"saudi_arabia",  "week":46,"rain":0, "laps":335,"lap_km":1.0,"audience":115000},
	],
	"C-008": [ # Premier Rally (WRC)
		{"round":1,"name":"Monte-Carlo","track_id":"monte_carlo","week":4,"rain":50,"laps":339,"lap_km":1.0,"audience":310000},
		{"round":2,"name":"Sweden","track_id":"sweden","week":7,"rain":80,"laps":301,"lap_km":1.0,"audience":220000},
		{"round":3,"name":"Kenya","track_id":"kenya","week":11,"rain":0,"laps":351,"lap_km":1.0,"audience":480000},
		{"round":4,"name":"Croatia","track_id":"croatia","week":15,"rain":30,"laps":300,"lap_km":1.0,"audience":245000},
		{"round":5,"name":"Islas Canarias","track_id":"islas_canarias","week":17,"rain":0,"laps":322,"lap_km":1.0,"audience":285000},
		{"round":6,"name":"Portugal","track_id":"portugal","week":19,"rain":0,"laps":330,"lap_km":1.0,"audience":520000},
		{"round":7,"name":"Japan","track_id":"japan","week":22,"rain":20,"laps":303,"lap_km":1.0,"audience":340000},
		{"round":8,"name":"Greece","track_id":"greece","week":26,"rain":0,"laps":329,"lap_km":1.0,"audience":290000},
		{"round":9,"name":"Estonia","track_id":"estonia","week":29,"rain":30,"laps":315,"lap_km":1.0,"audience":260000},
		{"round":10,"name":"Finland","track_id":"finland","week":31,"rain":0,"laps":317,"lap_km":1.0,"audience":680000},
		{"round":11,"name":"Paraguay","track_id":"paraguay","week":35,"rain":0,"laps":310,"lap_km":1.0,"audience":215000},
		{"round":12,"name":"Chile","track_id":"chile","week":37,"rain":60,"laps":312,"lap_km":1.0,"audience":185000},
		{"round":13,"name":"Sardegna","track_id":"sardegna","week":40,"rain":40,"laps":320,"lap_km":1.0,"audience":345000},
		{"round":14,"name":"Saudi Arabia","track_id":"saudi_arabia","week":46,"rain":0,"laps":335,"lap_km":1.0,"audience":240000},
	],
	"C-009": [ # TC Sport (GT4)
		{"round":1,"name":"Paul Ricard Opening Cup","track_id":"paul_ricard_opening_cup","week":8,"rain":0,"laps":32,"lap_km":5.8,"audience":12500},
		{"round":2,"name":"Brands Hatch GP Challenge","track_id":"brands_hatch_gp_challenge","week":14,"rain":30,"laps":37,"lap_km":3.9,"audience":18200},
		{"round":3,"name":"Misano Night Sprint","track_id":"misano_night_sprint","week":20,"rain":0,"laps":35,"lap_km":4.2,"audience":14900},
		{"round":4,"name":"Spa Mid-Season Classic","track_id":"spa_mid_season_classic","week":26,"rain":70,"laps":26,"lap_km":7.0,"audience":28000},
		{"round":5,"name":"Hockenheimring Ring Battle","track_id":"hockenheimring_ring_battle","week":34,"rain":0,"laps":34,"lap_km":4.5,"audience":21500},
		{"round":6,"name":"Barcelona","track_id":"barcelona","week":42,"rain":0,"laps":33,"lap_km":4.6,"audience":34200},
	],
	"C-010": [ # TC Elite (GT3)
		{"round":1,"name":"Bathurst 12 Hour","track_id":"bathurst_12_hour","week":5,"rain":0,"laps":12,"lap_km":6.2,"audience":53000},
		{"round":2,"name":"24h Nürburgring","track_id":"24h_nürburgring","week":22,"rain":75,"laps":24,"lap_km":25.4,"audience":235000},
		{"round":3,"name":"24h Le Mans","track_id":"24h_le_mans","week":24,"rain":35,"laps":24,"lap_km":13.6,"audience":332000},
		{"round":4,"name":"24h Spa","track_id":"24h_spa","week":26,"rain":45,"laps":24,"lap_km":7.0,"audience":85000},
		{"round":5,"name":"Indianapolis 8 Hour","track_id":"indianapolis_8_hour","week":40,"rain":20,"laps":8,"lap_km":3.9,"audience":38000},
		{"round":6,"name":"Kyalami 9 Hour","track_id":"kyalami_9_hour","week":48,"rain":30,"laps":9,"lap_km":4.5,"audience":42500},
	],
	"C-011": [ # OWC Next Gen (USF Pro 2000)
		{"round":1,"name":"St. Petersburg","track_id":"st_petersburg","week":10,"rain":0,"laps":25,"lap_km":1.8,"audience":42000},
		{"round":2,"name":"Louisiana","track_id":"louisiana","week":14,"rain":10,"laps":15,"lap_km":4.3,"audience":11500},
		{"round":3,"name":"Indianapolis","track_id":"indianapolis","week":19,"rain":20,"laps":15,"lap_km":4.1,"audience":28000},
		{"round":4,"name":"Freedom 90","track_id":"freedom_90","week":21,"rain":0,"laps":75,"lap_km":1.1,"audience":14000},
		{"round":5,"name":"Elkhart Lake","track_id":"elkhart_lake","week":25,"rain":0,"laps":12,"lap_km":6.4,"audience":55000},
		{"round":6,"name":"Lexington","track_id":"lexington","week":27,"rain":50,"laps":20,"lap_km":3.4,"audience":32400},
		{"round":7,"name":"Toronto","track_id":"toronto","week":31,"rain":0,"laps":21,"lap_km":2.8,"audience":48000},
		{"round":8,"name":"Portland","track_id":"portland","week":33,"rain":0,"laps":23,"lap_km":3.2,"audience":22500},
	],
	"C-012": [ # OWC Dev (Indy NXT)
		{"round":1,"name":"Sakhir","track_id":"sakhir","week":9,"rain":0,"laps":22,"lap_km":5.4,"audience":95000},
		{"round":2,"name":"Albert Park","track_id":"albert_park","week":11,"rain":20,"laps":23,"lap_km":5.3,"audience":125000},
		{"round":3,"name":"Imola","track_id":"imola","week":20,"rain":15,"laps":22,"lap_km":4.9,"audience":88000},
		{"round":4,"name":"Monaco","track_id":"monaco","week":21,"rain":5,"laps":27,"lap_km":3.4,"audience":110000},
		{"round":5,"name":"Barcelona","track_id":"barcelona","week":22,"rain":0,"laps":25,"lap_km":4.7,"audience":92000},
		{"round":6,"name":"Spielberg","track_id":"spielberg","week":26,"rain":15,"laps":24,"lap_km":4.3,"audience":105000},
		{"round":7,"name":"Silverstone","track_id":"silverstone","week":27,"rain":45,"laps":22,"lap_km":5.9,"audience":140000},
		{"round":8,"name":"Spa-Francorchamps","track_id":"spa_francorchamps","week":30,"rain":45,"laps":15,"lap_km":7.0,"audience":115000},
		{"round":9,"name":"Hungaroring","track_id":"hungaroring","week":31,"rain":0,"laps":24,"lap_km":4.4,"audience":98000},
		{"round":10,"name":"Monza","track_id":"monza","week":35,"rain":5,"laps":22,"lap_km":5.8,"audience":135000},
		{"round":11,"name":"Baku","track_id":"baku","week":37,"rain":0,"laps":20,"lap_km":6.0,"audience":68000},
		{"round":12,"name":"Lusail","track_id":"lusail","week":47,"rain":0,"laps":21,"lap_km":5.4,"audience":42000},
		{"round":13,"name":"Yas Marina","track_id":"yas_marina","week":48,"rain":0,"laps":22,"lap_km":5.3,"audience":95000},
		{"round":14,"name":"Sakhir Sprint","track_id":"sakhir_sprint","week":15,"rain":0,"laps":19,"lap_km":5.4,"audience":90000},
	],
	"C-013": [ # OWC Pro (Indy NTT)
		{"round":1,"name":"St. Petersburg","track_id":"st_petersburg","week":9,"rain":0,"laps":100,"lap_km":1.8,"audience":145000},
		{"round":2,"name":"Long Beach","track_id":"long_beach","week":16,"rain":0,"laps":85,"lap_km":3.1,"audience":192000},
		{"round":3,"name":"Alabama","track_id":"alabama","week":17,"rain":15,"laps":90,"lap_km":3.5,"audience":82000},
		{"round":4,"name":"Sonsio","track_id":"sonsio","week":19,"rain":0,"laps":85,"lap_km":4.1,"audience":68000},
		{"round":5,"name":"Indianapolis 500","track_id":"indianapolis_500","week":21,"rain":0,"laps":200,"lap_km":4.0,"audience":345000},
		{"round":6,"name":"Detroit","track_id":"detroit","week":22,"rain":100,"laps":100,"lap_km":2.6,"audience":110000},
		{"round":7,"name":"XPEL Grand Prix","track_id":"xpel_grand_prix","week":23,"rain":0,"laps":55,"lap_km":6.4,"audience":125000},
		{"round":8,"name":"Monterey","track_id":"monterey","week":25,"rain":0,"laps":95,"lap_km":3.6,"audience":84000},
		{"round":9,"name":"Toronto","track_id":"toronto","week":29,"rain":50,"laps":85,"lap_km":2.8,"audience":95000},
		{"round":10,"name":"Homefront 250","track_id":"homefront_250","week":32,"rain":0,"laps":250,"lap_km":1.4,"audience":48000},
		{"round":11,"name":"One Step 250","track_id":"one_step_250","week":33,"rain":0,"laps":250,"lap_km":1.4,"audience":52000},
		{"round":12,"name":"GOMEX Indy 250","track_id":"gomex_indy_250","week":34,"rain":0,"laps":260,"lap_km":1.5,"audience":41000},
		{"round":13,"name":"Portland Grand","track_id":"portland_grand","week":35,"rain":0,"laps":110,"lap_km":3.2,"audience":46000},
		{"round":14,"name":"Milwaukee Mile 1","track_id":"milwaukee_mile_1","week":36,"rain":0,"laps":250,"lap_km":1.6,"audience":31000},
		{"round":15,"name":"Milwaukee Mile 2","track_id":"milwaukee_mile_2","week":37,"rain":0,"laps":250,"lap_km":1.6,"audience":35000},
		{"round":16,"name":"Music City Grand Prix","track_id":"music_city_grand_prix","week":38,"rain":0,"laps":206,"lap_km":1.6,"audience":68000},
		{"round":17,"name":"Nashville Fall","track_id":"nashville_fall","week":46,"rain":0,"laps":180,"lap_km":2.1,"audience":72000},
	],
	"C-014": [ # SC Dev (ARCA)
		{"round":1,"name":"Florida 250","track_id":"florida_250","week":7,"rain":0,"laps":100,"lap_km":4.0,"audience":68000},
		{"round":2,"name":"Fr8Auctions 208","track_id":"fr8auctions_208","week":8,"rain":0,"laps":135,"lap_km":1.6,"audience":41000},
		{"round":3,"name":"Foundation 200","track_id":"foundation_200","week":9,"rain":0,"laps":134,"lap_km":2.4,"audience":34500},
		{"round":4,"name":"Bristol Dirt Track","track_id":"bristol_dirt_track","week":11,"rain":0,"laps":150,"lap_km":0.9,"audience":52000},
		{"round":5,"name":"XPEL 225","track_id":"xpel_225","week":12,"rain":10,"laps":42,"lap_km":5.5,"audience":64000},
		{"round":6,"name":"SpeedyCash 250","track_id":"speedycash_250","week":15,"rain":0,"laps":167,"lap_km":2.4,"audience":38000},
		{"round":7,"name":"Long John Silvers 200","track_id":"long_john_silvers_200","week":16,"rain":0,"laps":200,"lap_km":0.8,"audience":43000},
		{"round":8,"name":"Heart of America 200","track_id":"heart_of_america_200","week":18,"rain":0,"laps":134,"lap_km":2.4,"audience":29000},
		{"round":9,"name":"South Carolina 200","track_id":"south_carolina_200","week":19,"rain":0,"laps":147,"lap_km":2.2,"audience":58000},
		{"round":10,"name":"North Wilkesboro 250","track_id":"north_wilkesboro_250","week":20,"rain":100,"laps":250,"lap_km":1.0,"audience":22500},
		{"round":11,"name":"NC Education 200","track_id":"nc_education_200","week":21,"rain":0,"laps":134,"lap_km":2.4,"audience":47000},
		{"round":12,"name":"Toyota 200","track_id":"toyota_200","week":22,"rain":0,"laps":160,"lap_km":1.5,"audience":39000},
		{"round":13,"name":"Clean Harbors 250","track_id":"clean_harbors_250","week":25,"rain":0,"laps":250,"lap_km":0.5,"audience":24000},
		{"round":14,"name":"Rackley Roofing 200","track_id":"rackley_roofing_200","week":26,"rain":0,"laps":150,"lap_km":1.6,"audience":31500},
		{"round":15,"name":"CRC Brakleen 150","track_id":"crc_brakleen_150","week":29,"rain":0,"laps":60,"lap_km":4.0,"audience":55000},
		{"round":16,"name":"Worldwide Express 250","track_id":"worldwide_express_250","week":31,"rain":0,"laps":250,"lap_km":0.9,"audience":36000},
		{"round":17,"name":"Lucas Oil 200","track_id":"lucas_oil_200","week":32,"rain":10,"laps":200,"lap_km":1.1,"audience":18200},
		{"round":18,"name":"Clean Harbors 175","track_id":"clean_harbors_175","week":35,"rain":0,"laps":175,"lap_km":1.6,"audience":21000},
		{"round":19,"name":"UNOH 200","track_id":"unoh_200","week":38,"rain":0,"laps":200,"lap_km":0.9,"audience":62000},
		{"round":20,"name":"Kansas Fall 200","track_id":"kansas_fall_200","week":39,"rain":0,"laps":134,"lap_km":2.4,"audience":33000},
	],
	"C-015": [ # SC Truck (Craftsman Trucks) — abbreviated
		{"round":1,"name":"Florida 250","track_id":"florida_250","week":6,"rain":0,"laps":100,"lap_km":4.0,"audience":62000},
		{"round":2,"name":"Fr8Auctions 208","track_id":"fr8auctions_208","week":8,"rain":0,"laps":135,"lap_km":1.6,"audience":38000},
		{"round":3,"name":"Focused Health 250","track_id":"focused_health_250","week":9,"rain":10,"laps":46,"lap_km":5.5,"audience":74000},
		{"round":4,"name":"Phoenix 200","track_id":"phoenix_200","week":10,"rain":0,"laps":200,"lap_km":1.6,"audience":62000},
		{"round":5,"name":"Las Vegas 300","track_id":"las_vegas_300","week":11,"rain":0,"laps":134,"lap_km":2.4,"audience":48000},
		{"round":6,"name":"Darlington 200","track_id":"darlington_200","week":12,"rain":0,"laps":147,"lap_km":2.0,"audience":68000},
		{"round":7,"name":"Martinsville 250","track_id":"martinsville_250","week":13,"rain":0,"laps":250,"lap_km":0.8,"audience":46000},
		{"round":8,"name":"Rockingham 200","track_id":"rockingham_200","week":14,"rain":0,"laps":200,"lap_km":1.6,"audience":38000},
		{"round":9,"name":"Bristol 300","track_id":"bristol_300","week":15,"rain":0,"laps":300,"lap_km":0.9,"audience":72000},
		{"round":10,"name":"Kansas 300","track_id":"kansas_300","week":16,"rain":0,"laps":200,"lap_km":2.4,"audience":39000},
		{"round":11,"name":"Talladega 300","track_id":"talladega_300","week":17,"rain":0,"laps":113,"lap_km":4.3,"audience":115000},
		{"round":12,"name":"Charlotte 300","track_id":"charlotte_300","week":21,"rain":0,"laps":200,"lap_km":2.4,"audience":78000},
		{"round":13,"name":"Nashville 250","track_id":"nashville_250","week":22,"rain":0,"laps":250,"lap_km":1.6,"audience":48000},
		{"round":14,"name":"Pocono 225","track_id":"pocono_225","week":24,"rain":0,"laps":90,"lap_km":4.0,"audience":62000},
		{"round":15,"name":"San Diego 200","track_id":"san_diego_200","week":25,"rain":0,"laps":60,"lap_km":4.1,"audience":82000},
		{"round":16,"name":"Sonoma 250","track_id":"sonoma_250","week":26,"rain":10,"laps":79,"lap_km":3.2,"audience":41500},
		{"round":17,"name":"Chicagoland 300","track_id":"chicagoland_300","week":27,"rain":0,"laps":200,"lap_km":1.6,"audience":59000},
		{"round":18,"name":"Atlanta 300","track_id":"atlanta_300","week":28,"rain":0,"laps":163,"lap_km":2.5,"audience":61000},
		{"round":19,"name":"Iowa 250","track_id":"iowa_250","week":32,"rain":0,"laps":250,"lap_km":1.4,"audience":24000},
		{"round":20,"name":"Wawa 250","track_id":"wawa_250","week":35,"rain":0,"laps":100,"lap_km":4.0,"audience":86000},
		{"round":21,"name":"Darlington Fall 200","track_id":"darlington_fall_200","week":36,"rain":0,"laps":147,"lap_km":2.0,"audience":71000},
		{"round":22,"name":"Homestead-Miami","track_id":"homestead_miami","week":45,"rain":0,"laps":200,"lap_km":2.4,"audience":58000},
		{"round":23,"name":"Phoenix Playoff","track_id":"phoenix_playoff","week":47,"rain":0,"laps":200,"lap_km":1.6,"audience":68000},
	],
	"C-016": [ # SC Challenge (Xfinity) — key rounds
		{"round":1,"name":"Daytona","track_id":"daytona","week":6,"rain":0,"laps":120,"lap_km":4.0,"audience":145000},
		{"round":2,"name":"Las Vegas","track_id":"las_vegas","week":11,"rain":0,"laps":200,"lap_km":2.4,"audience":85000},
		{"round":3,"name":"Phoenix","track_id":"phoenix","week":12,"rain":0,"laps":200,"lap_km":1.6,"audience":72000},
		{"round":4,"name":"Bristol","track_id":"bristol","week":15,"rain":0,"laps":300,"lap_km":0.9,"audience":95000},
		{"round":5,"name":"Talladega","track_id":"talladega","week":17,"rain":0,"laps":113,"lap_km":4.3,"audience":125000},
		{"round":6,"name":"Charlotte","track_id":"charlotte","week":21,"rain":0,"laps":200,"lap_km":2.4,"audience":92000},
		{"round":7,"name":"Nashville","track_id":"nashville","week":22,"rain":0,"laps":300,"lap_km":1.6,"audience":68000},
		{"round":8,"name":"Chicagoland","track_id":"chicagoland","week":27,"rain":0,"laps":200,"lap_km":1.6,"audience":78000},
		{"round":9,"name":"Indianapolis","track_id":"indianapolis","week":29,"rain":0,"laps":100,"lap_km":4.0,"audience":115000},
		{"round":10,"name":"Michigan","track_id":"michigan","week":30,"rain":0,"laps":100,"lap_km":3.2,"audience":58000},
		{"round":11,"name":"Iowa","track_id":"iowa","week":32,"rain":0,"laps":250,"lap_km":1.4,"audience":32000},
		{"round":12,"name":"Pocono","track_id":"pocono","week":34,"rain":0,"laps":90,"lap_km":4.0,"audience":74000},
		{"round":13,"name":"Darlington","track_id":"darlington","week":36,"rain":0,"laps":200,"lap_km":2.0,"audience":88000},
		{"round":14,"name":"Talladega Fall","track_id":"talladega_fall","week":43,"rain":0,"laps":113,"lap_km":4.3,"audience":135000},
		{"round":15,"name":"Martinsville Fall","track_id":"martinsville_fall","week":44,"rain":0,"laps":250,"lap_km":0.8,"audience":62000},
		{"round":16,"name":"Phoenix Finale","track_id":"phoenix_finale","week":45,"rain":0,"laps":200,"lap_km":1.6,"audience":85000},
		{"round":17,"name":"Homestead Finale","track_id":"homestead_finale","week":46,"rain":0,"laps":200,"lap_km":2.4,"audience":74000},
	],
	"C-017": [ # SC Cup (NASCAR Cup) — key rounds
		{"round":1,"name":"Daytona 500","track_id":"daytona_500","week":6,"rain":0,"laps":200,"lap_km":4.0,"audience":285000},
		{"round":2,"name":"Las Vegas","track_id":"las_vegas","week":11,"rain":0,"laps":267,"lap_km":2.4,"audience":145000},
		{"round":3,"name":"Phoenix","track_id":"phoenix","week":12,"rain":0,"laps":312,"lap_km":1.6,"audience":125000},
		{"round":4,"name":"Bristol","track_id":"bristol","week":15,"rain":0,"laps":500,"lap_km":0.9,"audience":165000},
		{"round":5,"name":"Talladega","track_id":"talladega","week":17,"rain":0,"laps":188,"lap_km":4.3,"audience":205000},
		{"round":6,"name":"Charlotte 600","track_id":"charlotte_600","week":21,"rain":0,"laps":400,"lap_km":2.4,"audience":175000},
		{"round":7,"name":"Nashville","track_id":"nashville","week":22,"rain":0,"laps":300,"lap_km":1.6,"audience":128000},
		{"round":8,"name":"Indianapolis","track_id":"indianapolis","week":29,"rain":0,"laps":200,"lap_km":4.0,"audience":215000},
		{"round":9,"name":"Michigan","track_id":"michigan","week":30,"rain":0,"laps":200,"lap_km":3.2,"audience":98000},
		{"round":10,"name":"Daytona Summer","track_id":"daytona_summer","week":33,"rain":10,"laps":160,"lap_km":4.0,"audience":185000},
		{"round":11,"name":"Pocono","track_id":"pocono","week":34,"rain":0,"laps":160,"lap_km":4.0,"audience":115000},
		{"round":12,"name":"Darlington","track_id":"darlington","week":36,"rain":0,"laps":367,"lap_km":2.0,"audience":145000},
		{"round":13,"name":"Talladega Fall","track_id":"talladega_fall","week":43,"rain":0,"laps":188,"lap_km":4.3,"audience":220000},
		{"round":14,"name":"Martinsville Fall","track_id":"martinsville_fall","week":44,"rain":0,"laps":500,"lap_km":0.8,"audience":145000},
		{"round":15,"name":"Phoenix Championship","track_id":"phoenix_championship","week":45,"rain":0,"laps":312,"lap_km":1.6,"audience":185000},
		{"round":16,"name":"Homestead Finale","track_id":"homestead_finale","week":46,"rain":0,"laps":267,"lap_km":2.4,"audience":165000},
	],
	"C-018": [ # EPC Series (LMP3 / F4)
		{"round":1,"name":"Brands Hatch Indy","track_id":"brands_hatch_indy","week":14,"rain":0,"laps":24,"lap_km":1.9,"audience":14000},
		{"round":2,"name":"Donington National","track_id":"donington_national","week":18,"rain":20,"laps":18,"lap_km":3.2,"audience":12200},
		{"round":3,"name":"Thruxton High-Speed","track_id":"thruxton_high_speed","week":22,"rain":60,"laps":17,"lap_km":3.8,"audience":16500},
		{"round":4,"name":"Oulton Park Island","track_id":"oulton_park_island","week":26,"rain":45,"laps":15,"lap_km":3.6,"audience":18900},
		{"round":5,"name":"Croft Circuit Shootout","track_id":"croft_circuit_shootout","week":32,"rain":0,"laps":16,"lap_km":3.4,"audience":11000},
		{"round":6,"name":"Silverstone National","track_id":"silverstone_national","week":38,"rain":20,"laps":21,"lap_km":2.6,"audience":28500},
	],
	"C-019": [ # EPC League (LMP2 / F3)
		{"round":1,"name":"Sakhir","track_id":"sakhir","week":9,"rain":0,"laps":19,"lap_km":5.4,"audience":95000},
		{"round":2,"name":"Albert Park","track_id":"albert_park","week":11,"rain":20,"laps":20,"lap_km":5.3,"audience":125000},
		{"round":3,"name":"Imola","track_id":"imola","week":20,"rain":15,"laps":18,"lap_km":4.9,"audience":88000},
		{"round":4,"name":"Monaco","track_id":"monaco","week":21,"rain":5,"laps":23,"lap_km":3.4,"audience":110000},
		{"round":5,"name":"Barcelona","track_id":"barcelona","week":22,"rain":0,"laps":21,"lap_km":4.7,"audience":92000},
		{"round":6,"name":"Spielberg","track_id":"spielberg","week":26,"rain":15,"laps":21,"lap_km":4.3,"audience":105000},
		{"round":7,"name":"Silverstone","track_id":"silverstone","week":27,"rain":45,"laps":18,"lap_km":5.9,"audience":140000},
		{"round":8,"name":"Spa-Francorchamps","track_id":"spa_francorchamps","week":30,"rain":45,"laps":12,"lap_km":7.0,"audience":115000},
		{"round":9,"name":"Hungaroring","track_id":"hungaroring","week":31,"rain":0,"laps":19,"lap_km":4.4,"audience":98000},
		{"round":10,"name":"Monza","track_id":"monza","week":35,"rain":5,"laps":18,"lap_km":5.8,"audience":135000},
	],
	"C-020": [ # EPC Hyper (WEC)
		{"round":1,"name":"Bathurst 12 Hour","track_id":"bathurst_12_hour","week":5,"rain":0,"laps":12,"lap_km":6.2,"audience":53000},
		{"round":2,"name":"Sebring 1000","track_id":"sebring_1000","week":10,"rain":20,"laps":18,"lap_km":5.9,"audience":48000},
		{"round":3,"name":"Spa 6 Hour","track_id":"spa_6_hour","week":18,"rain":50,"laps":6,"lap_km":7.0,"audience":65000},
		{"round":4,"name":"24h Le Mans","track_id":"24h_le_mans","week":24,"rain":35,"laps":24,"lap_km":13.6,"audience":385000},
		{"round":5,"name":"Monza 6 Hour","track_id":"monza_6_hour","week":33,"rain":10,"laps":6,"lap_km":5.8,"audience":78000},
		{"round":6,"name":"Fuji 6 Hour","track_id":"fuji_6_hour","week":39,"rain":20,"laps":6,"lap_km":4.6,"audience":42000},
		{"round":7,"name":"Bahrain 8 Hour","track_id":"bahrain_8_hour","week":49,"rain":0,"laps":8,"lap_km":5.4,"audience":38000},
	],
	"C-021": [ # GP4 (F4)
		{"round":1,"name":"Brands Hatch Indy","track_id":"brands_hatch_indy","week":14,"rain":0,"laps":24,"lap_km":1.9,"audience":14000},
		{"round":2,"name":"Donington National","track_id":"donington_national","week":18,"rain":20,"laps":18,"lap_km":3.2,"audience":12200},
		{"round":3,"name":"Thruxton High-Speed","track_id":"thruxton_high_speed","week":22,"rain":60,"laps":17,"lap_km":3.8,"audience":16500},
		{"round":4,"name":"Oulton Park Island","track_id":"oulton_park_island","week":26,"rain":45,"laps":15,"lap_km":3.6,"audience":18900},
		{"round":5,"name":"Croft Circuit Shootout","track_id":"croft_circuit_shootout","week":32,"rain":0,"laps":16,"lap_km":3.4,"audience":11000},
		{"round":6,"name":"Silverstone National","track_id":"silverstone_national","week":38,"rain":20,"laps":21,"lap_km":2.6,"audience":28500},
	],
	"C-022": [ # GP3 (F3)
		{"round":1,"name":"Sakhir","track_id":"sakhir","week":9,"rain":0,"laps":19,"lap_km":5.4,"audience":95000},
		{"round":2,"name":"Albert Park","track_id":"albert_park","week":11,"rain":20,"laps":20,"lap_km":5.3,"audience":125000},
		{"round":3,"name":"Imola","track_id":"imola","week":20,"rain":15,"laps":18,"lap_km":4.9,"audience":88000},
		{"round":4,"name":"Monaco","track_id":"monaco","week":21,"rain":5,"laps":23,"lap_km":3.4,"audience":110000},
		{"round":5,"name":"Barcelona","track_id":"barcelona","week":22,"rain":0,"laps":21,"lap_km":4.7,"audience":92000},
		{"round":6,"name":"Spielberg","track_id":"spielberg","week":26,"rain":15,"laps":21,"lap_km":4.3,"audience":105000},
		{"round":7,"name":"Silverstone","track_id":"silverstone","week":27,"rain":45,"laps":18,"lap_km":5.9,"audience":140000},
		{"round":8,"name":"Spa-Francorchamps","track_id":"spa_francorchamps","week":30,"rain":45,"laps":12,"lap_km":7.0,"audience":115000},
		{"round":9,"name":"Hungaroring","track_id":"hungaroring","week":31,"rain":0,"laps":19,"lap_km":4.4,"audience":98000},
		{"round":10,"name":"Monza","track_id":"monza","week":35,"rain":5,"laps":18,"lap_km":5.8,"audience":135000},
	],
	"C-023": [ # GP2 (F2)
		{"round":1,"name":"Sakhir","track_id":"sakhir","week":9,"rain":0,"laps":23,"lap_km":5.4,"audience":97000},
		{"round":2,"name":"Jeddah","track_id":"jeddah","week":10,"rain":0,"laps":20,"lap_km":6.2,"audience":85000},
		{"round":3,"name":"Albert Park","track_id":"albert_park","week":11,"rain":20,"laps":22,"lap_km":5.3,"audience":131000},
		{"round":4,"name":"Imola","track_id":"imola","week":20,"rain":15,"laps":25,"lap_km":4.9,"audience":92000},
		{"round":5,"name":"Monaco","track_id":"monaco","week":21,"rain":5,"laps":30,"lap_km":3.4,"audience":115000},
		{"round":6,"name":"Barcelona","track_id":"barcelona","week":22,"rain":0,"laps":26,"lap_km":4.7,"audience":96000},
		{"round":7,"name":"Spielberg","track_id":"spielberg","week":26,"rain":15,"laps":28,"lap_km":4.3,"audience":108000},
		{"round":8,"name":"Silverstone","track_id":"silverstone","week":27,"rain":45,"laps":21,"lap_km":5.9,"audience":144000},
		{"round":9,"name":"Spa-Francorchamps","track_id":"spa_francorchamps","week":30,"rain":45,"laps":18,"lap_km":7.0,"audience":120000},
		{"round":10,"name":"Hungaroring","track_id":"hungaroring","week":31,"rain":0,"laps":28,"lap_km":4.4,"audience":99000},
		{"round":11,"name":"Monza","track_id":"monza","week":35,"rain":5,"laps":21,"lap_km":5.8,"audience":140000},
		{"round":12,"name":"Baku","track_id":"baku","week":37,"rain":0,"laps":21,"lap_km":6.0,"audience":72000},
		{"round":13,"name":"Lusail","track_id":"lusail","week":47,"rain":0,"laps":22,"lap_km":5.4,"audience":45000},
		{"round":14,"name":"Yas Marina","track_id":"yas_marina","week":48,"rain":0,"laps":23,"lap_km":5.3,"audience":115000},
	],
	"C-024": [ # GP1 (F1)
		{"round":1,"name":"Australian Grand Prix","track_id":"australian_grand_prix","week":10,"rain":0,"laps":58,"lap_km":5.3,"audience":145000},
		{"round":2,"name":"Chinese Grand Prix","track_id":"chinese_grand_prix","week":11,"rain":10,"laps":56,"lap_km":5.5,"audience":110000},
		{"round":3,"name":"Suzuka","track_id":"suzuka","week":13,"rain":35,"laps":53,"lap_km":5.8,"audience":125000},
		{"round":4,"name":"Sakhir","track_id":"sakhir","week":15,"rain":0,"laps":57,"lap_km":5.4,"audience":98000},
		{"round":5,"name":"Jeddah","track_id":"jeddah","week":16,"rain":0,"laps":50,"lap_km":6.2,"audience":85000},
		{"round":6,"name":"Imola","track_id":"imola","week":18,"rain":20,"laps":57,"lap_km":4.9,"audience":92000},
		{"round":7,"name":"Montréal","track_id":"montréal","week":21,"rain":40,"laps":70,"lap_km":4.4,"audience":135000},
		{"round":8,"name":"Monaco","track_id":"monaco","week":23,"rain":5,"laps":78,"lap_km":3.4,"audience":68000},
		{"round":9,"name":"Barcelona","track_id":"barcelona","week":24,"rain":0,"laps":66,"lap_km":4.7,"audience":115000},
		{"round":10,"name":"Spielberg","track_id":"spielberg","week":26,"rain":0,"laps":71,"lap_km":4.3,"audience":105000},
		{"round":11,"name":"Silverstone","track_id":"silverstone","week":27,"rain":45,"laps":52,"lap_km":5.9,"audience":145000},
		{"round":12,"name":"Hungaroring","track_id":"hungaroring","week":31,"rain":0,"laps":70,"lap_km":4.4,"audience":95000},
		{"round":13,"name":"Spa-Francorchamps","track_id":"spa_francorchamps","week":32,"rain":45,"laps":44,"lap_km":7.0,"audience":105000},
		{"round":14,"name":"Zandvoort","track_id":"zandvoort","week":33,"rain":30,"laps":72,"lap_km":4.3,"audience":105000},
		{"round":15,"name":"Monza","track_id":"monza","week":35,"rain":5,"laps":53,"lap_km":5.8,"audience":140000},
		{"round":16,"name":"Baku","track_id":"baku","week":37,"rain":0,"laps":51,"lap_km":6.0,"audience":72000},
		{"round":17,"name":"Singapore","track_id":"singapore","week":39,"rain":20,"laps":62,"lap_km":5.1,"audience":125000},
		{"round":18,"name":"Austin","track_id":"austin","week":41,"rain":30,"laps":56,"lap_km":5.5,"audience":138000},
		{"round":19,"name":"Mexico City","track_id":"mexico_city","week":42,"rain":10,"laps":71,"lap_km":4.3,"audience":115000},
		{"round":20,"name":"São Paulo","track_id":"são_paulo","week":43,"rain":40,"laps":71,"lap_km":4.3,"audience":108000},
		{"round":21,"name":"Las Vegas","track_id":"las_vegas","week":46,"rain":0,"laps":50,"lap_km":6.2,"audience":95000},
		{"round":22,"name":"Lusail","track_id":"lusail","week":47,"rain":0,"laps":57,"lap_km":5.4,"audience":62000},
		{"round":23,"name":"Yas Marina","track_id":"yas_marina","week":48,"rain":0,"laps":58,"lap_km":5.3,"audience":115000},
		{"round":24,"name":"Abu Dhabi","track_id":"abu_dhabi","week":49,"rain":0,"laps":58,"lap_km":5.3,"audience":110000},
	],
}
func get_car_delivery_week(champ_id: String) -> int:
	var cnc    = CNC_DATA.get(champ_id, {})
	var eng_wk = cnc.get("engine_weeks", 1)
	var race1  = FIRST_RACE_WEEK.get(champ_id, 6)
	return max(eng_wk, race1 - 1)

## Entry deadline week in the prior season = 52 - design_weeks.
func get_entry_deadline_week(champ_id: String) -> int:
	return 52 - CNC_DATA.get(champ_id, {}).get("design_weeks", 2)

## Provider car cost scaled by season: base × 1.05^(season-1), rounded to CR 500.
func get_provider_car_cost(champ_id: String) -> int:
	var base   = CNC_DATA.get(champ_id, {}).get("base_total_cost", 10000)
	var scaled = base * pow(1.05, current_season - 1)
	return int(round(scaled / 500.0) * 500)
const CFO_PART_WARNING_THRESHOLD = 2  # CFO warns when any part stock ≤ this

# Notifications
var notifications: Array = []
var dismissed_todo_items: Array = []  ## Items player has dismissed from to-do list
var weeks_in_negative:       int   = 0
var bankruptcy_screen_shown: bool  = false
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
signal bankruptcy_triggered()

func _ready() -> void:
	RND_TASKS = _build_rnd_tasks()

## Builds RND_TASKS — called in _ready() for initial load.
func _build_rnd_tasks() -> Dictionary:
	return _build_rnd_tasks_for_season(current_season)

## Regenerates season-specific tasks. Called on start_new_season() and after load().
func _rebuild_seasonal_rnd_tasks() -> void:
	var p4_tasks: Dictionary = {}
	for k in RND_TASKS:
		if RND_TASKS[k].get("pillar", 0) == 4:
			p4_tasks[k] = RND_TASKS[k]
	RND_TASKS = _build_rnd_tasks_for_season(current_season)
	for k in p4_tasks:
		if not k in RND_TASKS:
			RND_TASKS[k] = p4_tasks[k]

## Generates P1/P2/P3/P4 tasks for a given season.
## IDs: BP-{CHAMP}-{PART}-S{n}-L{lv} | UPG-... | RE-...-L1
## Part codes: AER ENG GRB SUS BRK CHS
func _build_rnd_tasks_for_season(season: int) -> Dictionary:
	var tasks: Dictionary = {}
	var s = str(season)

	const CHAMP_TIER = {
		"C-001":1,"C-002":1,"C-003":2,"C-004":2,
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
		"C-001":[true,true,true,false,false,true], "C-002":[true,true,true,false,true,false],
		"C-003":[true,false,true,false,false,false],"C-004":[true,false,false,false,false,false],
		"C-005":[true,true,true,false,false,true],  "C-006":[false,true,true,false,false,false],
		"C-007":[false,false,false,false,false,false],"C-008":[false,false,false,false,false,false],
		"C-009":[true,true,true,true,true,true],    "C-010":[true,true,true,true,true,true],
		"C-011":[true,true,true,true,true,true],    "C-012":[true,true,true,true,true,true],
		"C-013":[true,false,true,false,true,true],  "C-014":[true,false,true,false,false,true],
		"C-015":[true,false,false,false,false,true], "C-016":[true,false,false,false,false,true],
		"C-017":[true,false,false,false,false,true], "C-018":[true,true,true,true,true,true],
		"C-019":[true,true,true,false,false,true],  "C-020":[false,false,false,false,false,false],
		"C-021":[true,true,true,true,true,true],    "C-022":[true,true,true,true,true,true],
		"C-023":[true,true,true,true,true,true],    "C-024":[false,false,false,false,false,false],
	}
	const PART_NAMES_ORDER = ["Aero","Engine","Gearbox","Suspension","Brakes","Chassis"]
	const UPG_LEVEL_MULTS = [1.0, 1.5, 2.2, 3.0, 4.0]

	for cid in CHAMP_CODES.keys():
		var code = CHAMP_CODES[cid]
		var tier = CHAMP_TIER.get(cid, 1)
		var tier_mult = 1.0 + (tier - 1) * 0.5
		var spec_arr = PART_SPEC_MAP.get(cid, [false,false,false,false,false,false])
		var reg = CHAMPIONSHIP_REGISTRY.get(cid, {})
		var champ_name = reg.get("name", cid)

		for i in range(PART_NAMES_ORDER.size()):
			var part    = PART_NAMES_ORDER[i]
			var pcode   = PART_CODES[part]
			var is_spec = spec_arr[i]

			# P1: Blueprint Design
			var p1b   = PART_BASE_P1[part]
			var p1_id = "BP-%s-%s-S%s-L1" % [code, pcode, s]
			var p1_l2 = "BP-%s-%s-S%s-L2" % [code, pcode, s]
			tasks[p1_id] = {
				"name": "%s — %s Blueprint" % [champ_name, part],
				"pillar":1,"part":part,"part_code":pcode,"championship_id":cid,
				"season":season,"level":1,"blueprint_id":p1_id,
				"weeks":max(1,int(p1b[0]*tier_mult)),"rp":int(p1b[1]*tier_mult),
				"cr":int(p1b[2]*tier_mult),"effect":p1b[3],"value":p1b[4],
			}
			tasks[p1_l2] = {
				"name": "%s — %s Blueprint L2" % [champ_name, part],
				"pillar":1,"part":part,"part_code":pcode,"championship_id":cid,
				"season":season,"level":2,"blueprint_id":p1_l2,
				"weeks":max(1,int(p1b[0]*tier_mult*2.0)),"rp":int(p1b[1]*tier_mult*2.5),
				"cr":int(p1b[2]*tier_mult*2.8),"effect":p1b[3],"value":p1b[4]*2.0,
				"requires":p1_id,
			}

			# P2: Upgrade — 5 levels, Open parts only
			if not is_spec:
				var p2b = PART_BASE_P2[part]
				var prev_id = ""
				for lv in range(1, 6):
					var lm = UPG_LEVEL_MULTS[lv - 1]
					var upg_id = "UPG-%s-%s-S%s-L%d" % [code, pcode, s, lv]
					var entry: Dictionary = {
						"name": "%s — %s Upgrade L%d" % [champ_name, part, lv],
						"pillar":2,"part":part,"part_code":pcode,"championship_id":cid,
						"season":season,"level":lv,"blueprint_id":upg_id,
						"weeks":max(1,int(p2b[0]*tier_mult*lm)),"rp":int(p2b[1]*tier_mult*lm),
						"cr":int(p2b[2]*tier_mult*lm),"effect":p2b[3],"value":p2b[4]*lm,
					}
					if prev_id != "":
						entry["requires"] = prev_id
					tasks[upg_id] = entry
					prev_id = upg_id

			# P3: Reverse Engineering — Spec parts only, always L1
			if is_spec:
				var p3b = PART_BASE_P3[part]
				var re_id = "RE-%s-%s-S%s-L1" % [code, pcode, s]
				tasks[re_id] = {
					"name": "%s — RE %s" % [champ_name, part],
					"pillar":3,"part":part,"part_code":pcode,"championship_id":cid,
					"season":season,"level":1,"blueprint_id":re_id,
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
	wra_cycle_start_season = current_season
	var wiped = completed_bp_tasks.size()
	completed_bp_tasks.clear()
	completed_rnd_tasks = completed_rnd_tasks.filter(
		func(tid): return not (tid.begins_with("BP-") or tid.begins_with("RE-")))
	var to_wipe: Array = []
	for bp_id in known_blueprints:
		if known_blueprints[bp_id].get("pillar", 0) in [1, 3]:
			to_wipe.append(bp_id)
	for bp_id in to_wipe:
		known_blueprints.erase(bp_id)
	add_notification("Critical",
		"WRA NEW REGULATIONS — Season %d! All Design and RE blueprints invalidated. %d blueprints lost. Teams must redesign from scratch." % [current_season, wiped])
	add_log("WRA Regulation Change — Season %d. %d blueprints wiped." % [current_season, wiped])

func _setup_campus() -> void:
	campus_buildings = {
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
	add_log("📋 Sponsor signed: %s — CR 1,000/week" % picked["name"])

func add_notification(priority: String, message: String, destination: String = "") -> void:
	# Deduplicate — skip only if identical priority+message already added this exact week
	# Exception: Critical notifications always show (bankruptcy risk needs to fire every week)
	if priority != "Critical":
		for n in notifications:
			if n["message"] == message and n["week"] == current_week and n["season"] == current_season:
				return
	# priority: "Critical", "High", "Normal"
	notifications.append({
		"priority":    priority,
		"message":     message,
		"destination": destination,
		"week":        current_week,
		"season":      current_season,
		"read":        false,
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

## Dismiss a single notification by index — removes it entirely.
func dismiss_notification(index: int) -> void:
	if index >= 0 and index < notifications.size():
		notifications.remove_at(index)
		unread_notification_count = 0
		for n in notifications:
			if not n["read"]:
				unread_notification_count += 1
		emit_signal("notifications_updated")

## Snooze a notification — pushes its week forward so it won't show until then.
func snooze_notification(index: int, weeks: int) -> void:
	if index >= 0 and index < notifications.size():
		notifications[index]["week"] = current_week + weeks
		notifications[index]["read"] = true
		unread_notification_count = 0
		for n in notifications:
			if not n["read"]:
				unread_notification_count += 1
		emit_signal("notifications_updated")

## Returns count of unread Critical notifications specifically.
func get_critical_count() -> int:
	var count = 0
	for n in notifications:
		if not n["read"] and n["priority"] == "Critical":
			count += 1
	return count

## Removes notifications that have been read AND are older than keep_weeks.
## Called each week to prevent pile-up.
func _purge_old_notifications(keep_weeks: int = 2) -> void:
	var cutoff_week = current_week - keep_weeks
	notifications = notifications.filter(func(n):
		return not n["read"] or n["week"] >= cutoff_week
	)
	unread_notification_count = 0
	for n in notifications:
		if not n["read"]:
			unread_notification_count += 1
	emit_signal("notifications_updated")

func _apply_sponsor_income() -> void:
	if active_sponsor.is_empty():
		return
	var payment = active_sponsor["current_weekly"]
	player_team.balance += payment
	add_log("💼 %s: +CR %d" % [active_sponsor["name"], payment])

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
		add_log("🌟 %s bonus: +CR %d this week!" % [active_sponsor["name"], active_sponsor["current_weekly"]])
	elif player_scored:
		active_sponsor["current_weekly"] = active_sponsor["base_weekly"]
		sponsor_no_points_streak = 0
	else:
		sponsor_no_points_streak += 1
		if sponsor_no_points_streak >= 3:
			active_sponsor["current_weekly"] = 500
			add_log("⚠ %s unhappy — reduced to CR 500/week (no points in 3 races)" % active_sponsor["name"])

func _apply_weekly_expenses() -> void:
	var player_expenses = 0.0

	# Driver salaries — use per-driver negotiated salary, fall back to championship rate
	for driver_id in player_team.drivers:
		var driver = all_drivers.get(driver_id)
		if driver == null: continue
		var sal = driver.weekly_salary if driver.weekly_salary > 0 \
				else _get_championship_driver_salary()
		player_expenses += sal

	# Staff salaries — sum all hired staff
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.contract_team == player_team.id:
			player_expenses += staff.weekly_salary

	player_team.balance -= player_expenses
	## P&L summary logged in advance_week() after all income/expense functions run

	# Bankruptcy — escalating warnings, screen after 8 consecutive weeks negative
	if player_team.balance < 0:
		weeks_in_negative += 1
		if weeks_in_negative >= 6:
			add_notification("Critical",
				"🚨 CRITICAL: %d weeks insolvent (CR %s). Team collapse imminent!" % [
					weeks_in_negative, _fmt_int(int(player_team.balance))])
		elif weeks_in_negative >= 3:
			add_notification("Critical",
				"🚨 BANKRUPTCY RISK: %d weeks negative (CR %s). Sell assets or find sponsors now." % [
					weeks_in_negative, _fmt_int(int(player_team.balance))])
		else:
			add_notification("High",
				"⚠ Balance negative (CR %s). Address this urgently." % _fmt_int(int(player_team.balance)))
		if weeks_in_negative >= 8 and not bankruptcy_screen_shown:
			bankruptcy_screen_shown = true
			emit_signal("bankruptcy_triggered")
	else:
		weeks_in_negative = 0
		bankruptcy_screen_shown = false
		if player_expenses > 0 and player_team.balance < player_expenses * 4:
			add_notification("High",
				"⚠ Low funds: CR %s covers ~%d weeks. Consider selling assets or finding sponsors." % [
					_fmt_int(int(player_team.balance)),
					int(player_team.balance / player_expenses)])

	# AI teams — simple salary model (unchanged)
	for team in all_teams:
		if team.is_player_team:
			continue
		var driver_count = team.drivers.size()
		var ai_expenses = (team.weekly_driver_salary * driver_count) + team.weekly_mechanic_salary
		team.balance -= ai_expenses

func _get_championship_driver_salary() -> float:
	if active_championship == null:
		return 50.0
	match active_championship.id:
		"C-001": return 50.0
		"C-002": return 180.0
		"C-021": return 420.0
		"C-024": return 2850.0
	return 50.0

func _consume_race_resources() -> void:
	if active_championship == null:
		return
	# Only consume fuel for player cars that actually started this race
	# (have a driver assigned AND are not DNS).
	# Cars with no driver, no car for this championship, or DNS = no fuel used.
	var cars_raced = 0
	for car in player_team_cars:
		if car.championship_id != active_championship.id:
			continue
		if car.driver_id == "":
			continue
		# Check if this driver was DNS — if so no fuel consumed
		var was_dns = false
		for entry in last_race_results:
			if entry["driver"].id == car.driver_id and entry.get("dns", false):
				was_dns = true
				break
		if not was_dns:
			cars_raced += 1
	var fuel_used = active_championship.fuel_per_car_per_race * cars_raced
	if fuel_used > 0.0:
		fuel_kg -= fuel_used
		fuel_kg = max(fuel_kg, 0.0)
		add_log("⛽ Fuel used: %.1f kg × %d car%s (stock: %.1f kg)" % [
			active_championship.fuel_per_car_per_race, cars_raced,
			"s" if cars_raced != 1 else "", fuel_kg])
	else:
		add_log("⛽ Fuel used: 0.0 kg (no cars started)")

	# SP is NOT auto-deducted per race.
	# SP is spent only on repairs — see _auto_repair_cars_post_race() below.

func _earn_race_rp(laps: int) -> void:
	# RP only accumulates if the team has an R&D Design Studio AND at least one Designer.
	var rnd_studio = campus_buildings.get("R&D Design Studio", {})
	if not rnd_studio.get("built", false):
		return
	var designers = get_player_staff_by_role("Designer")
	if designers.is_empty():
		return
	# Each Designer contributes proportionally to their average design skill
	var design_power = 0.0
	for d in designers:
		var avg = (d.engine + d.aero + d.chassis + d.gearbox + d.brakes + d.suspension) / 6.0
		design_power += avg / 100.0
	var rp_gained = laps * 1 * design_power
	var rp_cap = get_rnd_rp_storage_cap()
	research_points = min(research_points + rp_gained, float(rp_cap))
	add_log("🔬 RP gained: %.0f (total: %.0f / %d)" % [rp_gained, research_points, rp_cap])

func _check_resource_notifications() -> void:
	# SP warnings
	if spare_parts <= 0:
		add_notification("Critical", "No spare parts remaining! Buy more at the Logistics Center to repair your car.")
	elif active_championship != null and spare_parts < active_championship.sp_per_10_pct_damage:
		add_notification("High", "Spare parts low (%d units). Not enough to repair 10%% damage." % spare_parts)

	# Fuel warnings
	if active_championship != null:
		var fuel_needed = active_championship.fuel_per_car_per_race
		if fuel_kg <= 0.0:
			add_notification("Critical", "No fuel remaining! Buy more at the Logistics Center before next race.")
		elif fuel_kg < fuel_needed:
			add_notification("High", "Fuel running low (%.1f kg). Less than 1 race worth remaining." % fuel_kg)

	# No car for running championship warning
	for champ in active_championships:
		var reg = CHAMPIONSHIP_REGISTRY.get(champ.id, {})
		var champ_name = reg.get("name", champ.id)
		var cars_for_champ = player_team_cars.filter(func(c): return c.championship_id == champ.id)
		if cars_for_champ.is_empty():
			var race1_week = FIRST_RACE_WEEK.get(champ.id, 6)
			if current_week >= race1_week - 4:
				add_notification("Critical",
					"🚨 No car entered for %s! Race 1 is Week %d — buy a car at the Logistics Center or you will DNS all races." % [champ_name, race1_week])

	# Bankruptcy warning
	var weekly_expenses = 1250
	if player_team.balance < 0:
		add_notification("Critical", "BANKRUPTCY RISK: Balance is negative (CR %.0f)!" % player_team.balance)
	elif player_team.balance < weekly_expenses * 2:
		add_notification("High", "Low funds warning: Less than 2 weeks of expenses remaining.")

func buy_spare_parts(units: int) -> bool:
	var cost_per_unit = 1  # CR 1 per unit for GK Regional (120 units = CR 120/race)
	var total_cost = units * cost_per_unit
	if player_team.balance < total_cost:
		add_notification("High", "Not enough credits to buy spare parts.")
		return false
	player_team.balance -= total_cost
	spare_parts += units
	add_log("🛒 Bought %d spare parts for CR %d (stock: %d)" % [units, total_cost, spare_parts])
	return true

func buy_fuel(kg: float) -> bool:
	var cost_per_kg = 2.0  # placeholder price
	var total_cost = kg * cost_per_kg
	if player_team.balance < total_cost:
		add_notification("High", "Not enough credits to buy fuel.")
		return false
	player_team.balance -= total_cost
	fuel_kg += kg
	add_log("🛒 Bought %.1f kg fuel for CR %.0f (stock: %.1f kg)" % [kg, total_cost, fuel_kg])
	return true

## ═══════════════════════════════════════════════════════════════════════════
## SLOT CAP HELPERS
## ═══════════════════════════════════════════════════════════════════════════

## Max drivers the player can sign — 1 per Racing Department level.
func get_max_drivers() -> int:
	return campus_buildings.get("Racing Department", {}).get("level", 1)

## Max cars the player can field — 1 per Garage level.
func get_max_cars() -> int:
	return campus_buildings.get("Garage", {}).get("level", 1)

## ═══════════════════════════════════════════════════════════════════════════
## CAR SYSTEM
## ═══════════════════════════════════════════════════════════════════════════

## Car telemetry data keyed by car_type_id (from Excel Cars sheet)
const CAR_TELEMETRY = {
	"A_01": {"top_speed": 75.0,  "acceleration": 7.5,  "deceleration": 9.0,  "cornering_grip": 2.5,  "fuel_per_km": 0.045, "tire_wear": 0.65, "perf_index": 1},   # GK Regional
	"A_02": {"top_speed": 115.0, "acceleration": 4.8,  "deceleration": 10.0, "cornering_grip": 2.8,  "fuel_per_km": 0.055, "tire_wear": 0.72, "perf_index": 10},  # GK National/Continental/World
	"A_05": {"top_speed": 175.0, "acceleration": 7.0,  "deceleration": 10.5, "cornering_grip": 3.0,  "fuel_per_km": 0.28,  "tire_wear": 1.20, "perf_index": 30},  # Rally
	"A_09": {"top_speed": 290.0, "acceleration": 3.5,  "deceleration": 12.0, "cornering_grip": 3.4,  "fuel_per_km": 0.30,  "tire_wear": 1.05, "perf_index": 40},  # GT3/GT4
	"A_11": {"top_speed": 273.0, "acceleration": 3.4,  "deceleration": 12.2, "cornering_grip": 3.3,  "fuel_per_km": 0.22,  "tire_wear": 0.95, "perf_index": 40},  # OWC
	"A_14": {"top_speed": 310.0, "acceleration": 3.3,  "deceleration": 10.8, "cornering_grip": 2.9,  "fuel_per_km": 0.38,  "tire_wear": 1.10, "perf_index": 42},  # NASCAR/SC
	"A_18": {"top_speed": 290.0, "acceleration": 3.2,  "deceleration": 12.5, "cornering_grip": 3.5,  "fuel_per_km": 0.35,  "tire_wear": 1.15, "perf_index": 45},  # EPC/WEC/LMP
	"A_21": {"top_speed": 320.0, "acceleration": 2.9,  "deceleration": 13.5, "cornering_grip": 3.8,  "fuel_per_km": 0.32,  "tire_wear": 1.20, "perf_index": 50},  # GP Formula
}

func _setup_cars() -> void:
	player_team_cars = []
	_give_starting_assets(_starting_champ_id)

func _give_starting_assets(champ_id: String) -> void:
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var discipline = reg.get("discipline", "GK")

	## ── 1. Car + entry fee deducted ─────────────────────────────────────────
	var car_cost  = get_provider_car_cost(champ_id)
	var entry_fee = reg.get("entry_fee", 0)
	player_team.balance -= float(car_cost + entry_fee)
	add_car(champ_id)

	## ── 2. Campus buildings per discipline ──────────────────────────────────
	if discipline in ["Rally", "SC", "GP"]:
		if "Pit Crew Arena" in campus_buildings:
			campus_buildings["Pit Crew Arena"]["built"] = true
			campus_buildings["Pit Crew Arena"]["level"] = 1
	if discipline in ["SC", "GP"]:
		if "Ops Sim" in campus_buildings:
			campus_buildings["Ops Sim"]["built"] = true
			campus_buildings["Ops Sim"]["level"] = 1

	## ── 3. Starting TP ───────────────────────────────────────────────────────
	var tp = _create_starting_staff("Team Principal", 55.0, 70.0)
	tp.contract_team = player_team.id
	tp.contract_seasons_remaining = 3
	tp.assigned_championship = champ_id
	all_staff[tp.id] = tp

	## ── 4. Starting Driver ───────────────────────────────────────────────────
	var driver = _find_and_sign_starting_driver(discipline, champ_id)

	## ── 5. Starting Mechanic ─────────────────────────────────────────────────
	var mech = _create_starting_staff("Race Mechanic", 40.0, 65.0)
	mech.contract_team = player_team.id
	mech.contract_seasons_remaining = 3
	all_staff[mech.id] = mech
	if not player_team_cars.is_empty():
		player_team_cars[0].mechanic_id = mech.id

	## ── 6. Pit Crew (Rally, SC, GP) ─────────────────────────────────────────
	if discipline in ["Rally", "SC", "GP"]:
		var crew = _create_starting_staff("Pit Crew", 35.0, 55.0)
		crew.contract_team = player_team.id
		crew.contract_seasons_remaining = 3
		all_staff[crew.id] = crew
		if not player_team_cars.is_empty():
			player_team_cars[0].pit_crew_id = crew.id

	## ── 7. Strategist (SC, GP) ───────────────────────────────────────────────
	if discipline in ["SC", "GP"]:
		var strat = _create_starting_staff("Race Strategist", 45.0, 65.0)
		strat.contract_team = player_team.id
		strat.contract_seasons_remaining = 3
		strat.assigned_championship = champ_id
		all_staff[strat.id] = strat

	## ── 8. Assign driver to car ──────────────────────────────────────────────
	if driver != null and not player_team_cars.is_empty():
		player_team_cars[0].driver_id = driver.id

	add_log("🏎 Starting assets ready for %s." % reg.get("name", champ_id))
	add_log("💰 Remaining balance: CR %s" % _fmt_int(int(player_team.balance)))


func _create_starting_staff(role: String, skill_min: float, skill_max: float) -> Staff:
	var nats = ["British","Italian","German","French","Spanish","Finnish","Brazilian"]
	var nat  = nats[randi() % nats.size()]
	var sex  = "Male" if randf() > 0.35 else "Female"
	var name_data = NameGenerator.get_full_name(nat, sex)
	var s = Staff.new()
	s.id         = "S-START-%s-%d" % [role.replace(" ","_").to_lower(), randi() % 9999]
	s.first_name = name_data["first"]
	s.last_name  = name_data["last"]
	s.nationality = nat
	s.sex        = sex
	s.age        = randi_range(24, 38)
	s.role       = role
	var skill    = randf_range(skill_min, skill_max)
	match role:
		"Team Principal":
			s.race_strategy     = skill
			s.race_pace_reading = skill * 0.9
			s.car_setup_oversight = skill * 0.8
		"Race Mechanic":
			s.car_setup        = skill
			s.track_knowledge  = randf_range(10.0, 30.0)
			s.repair_skill     = skill * 0.85
		"Pit Crew":
			s.pit_stop_speed   = skill
			s.teamwork         = skill * 0.9
		"Race Strategist":
			s.race_strategy    = skill
			s.qualifying_timing= skill * 0.85
			s.race_pace_reading= skill * 0.8
	var sal_range = STAFF_BASE_SALARIES.get(role, {"min": 200.0, "max": 500.0})
	s.weekly_salary = sal_range["min"] + \
		(sal_range["max"] - sal_range["min"]) * (skill / 100.0)
	return s


func _find_and_sign_starting_driver(discipline: String, champ_id: String) -> Driver:
	var reg     = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var min_age = reg.get("min_age", 8)
	var max_age = reg.get("max_age", 99)
	var candidates: Array = []
	for d_id in all_drivers:
		var d = all_drivers[d_id]
		if d.contract_team != "": continue
		if d.age < min_age or d.age > max_age: continue
		if d.active_discipline != discipline: continue
		candidates.append(d)
	if candidates.is_empty():
		push_warning("[GameState] No starting driver for discipline %s" % discipline)
		return null
	candidates.sort_custom(func(a, b): return a.get_overall_skill() < b.get_overall_skill())
	var pick = candidates[clamp(candidates.size() / 3, 0, candidates.size() - 1)]
	pick.contract_team = player_team.id
	pick.contract_seasons_remaining = 1
	var sal = _get_championship_driver_salary()
	pick.weekly_salary = sal * 1.2
	pick.win_bonus     = int(sal * 52 * 0.3)
	pick.podium_bonus  = int(sal * 52 * 0.1)
	player_team.drivers.append(pick.id)
	if active_championship != null:
		active_championship.standings[pick.id] = 0
	return pick

func get_car_for_driver(driver_id: String) -> Car:
	for car in player_team_cars:
		if car.driver_id == driver_id:
			return car
	return null

func get_car_by_id(car_id: String) -> Car:
	for car in player_team_cars:
		if car.id == car_id:
			return car
	return null

func get_car_condition(driver_id: String) -> float:
	var car = get_car_for_driver(driver_id)
	return car.condition if car else 100.0

## ═══════════════════════════════════════════════════════════════════════════
## PART INVENTORY SYSTEM
## ═══════════════════════════════════════════════════════════════════════════

func _setup_part_inventory() -> void:
	part_inventory = {}
	var champ_id = active_championship.id
	part_inventory[champ_id] = {}
	for part in PARTS_LIST:
		part_inventory[champ_id][part] = 3  # Start with 3 of each

func get_part_stock(part_name: String, champ_id: String = "") -> int:
	if champ_id == "":
		if active_championship == null: return 0
		champ_id = active_championship.id
	if not champ_id in part_inventory:
		return 0
	return part_inventory[champ_id].get(part_name, 0)

func buy_part(part_name: String, quantity: int, champ_id: String = "") -> bool:
	if champ_id == "":
		champ_id = active_championship.id
	var costs = PART_COSTS.get(champ_id, {})
	if part_name not in costs:
		add_notification("High", "No part cost data for %s in this championship." % part_name)
		return false
	# Apply Logistics Center discount (-1% per level, max -50%)
	var discount = get_logistics_parts_discount()
	var unit_cost = int(round(costs[part_name] * discount))
	var total_cost = unit_cost * quantity
	if player_team.balance < total_cost:
		add_notification("High", "Not enough credits to buy %d× %s (need CR %d, have CR %d)." % [
			quantity, part_name, total_cost, int(player_team.balance)])
		return false
	player_team.balance -= total_cost
	if not champ_id in part_inventory:
		part_inventory[champ_id] = {}
	part_inventory[champ_id][part_name] = part_inventory[champ_id].get(part_name, 0) + quantity
	var discount_str = " (%.0f%% discount)" % ((1.0 - discount) * 100) if discount < 1.0 else ""
	add_log("🔩 Bought %d× %s parts for CR %d%s (stock: %d)" % [
		quantity, part_name, total_cost, discount_str, part_inventory[champ_id][part_name]])
	return true

func _check_part_inventory_notifications() -> void:
	## CFO reminds player if any part stock is at or below warning threshold.
	## Only fires if player has a CFO hired.
	var has_cfo = get_player_staff_by_role("CFO").size() > 0
	if not has_cfo:
		return
	var champ_id = active_championship.id
	if not champ_id in part_inventory:
		return
	for part in PARTS_LIST:
		var stock = part_inventory[champ_id].get(part, 0)
		if stock <= CFO_PART_WARNING_THRESHOLD:
			add_notification("High",
				"💼 CFO: %s parts stock critically low (%d remaining). A part failure means DNF — buy replacements at Logistics Center." % [part, stock])

## ═══════════════════════════════════════════════════════════════════════════
## STAFF SYSTEM
## ═══════════════════════════════════════════════════════════════════════════

const STAFF_ROLES = ["Race Mechanic", "Pit Crew", "Team Principal", "CFO", "Designer", "Race Strategist"]

## Salary ranges per role (weekly, in CR) — GK Regional tier
const STAFF_BASE_SALARIES = {
	"Race Mechanic":   {"min": 180.0,  "max": 450.0},
	"Pit Crew":        {"min": 150.0,  "max": 380.0},
	"Team Principal":  {"min": 280.0,  "max": 650.0},
	"CFO":             {"min": 250.0,  "max": 580.0},
	"Designer":        {"min": 350.0,  "max": 750.0},
	"Race Strategist": {"min": 220.0,  "max": 520.0},
}

var _staff_id_counter: int = 0

func _generate_available_staff(count: int) -> void:
	## Generates `count` staff spread across all roles and nationalities.
	## All start as available (contract_team = "").
	var role_distribution = {
		"Race Mechanic":   int(count * 0.25),  # 15
		"Pit Crew":        int(count * 0.20),  # 12
		"Team Principal":  int(count * 0.12),  # 7
		"CFO":             int(count * 0.10),  # 6
		"Designer":        int(count * 0.18),  # 11
		"Race Strategist": int(count * 0.15),  # 9
	}

	var nationalities = ["British", "Italian", "German", "French", "Spanish",
		"Finnish", "Brazilian", "Japanese", "American", "Australian",
		"Dutch", "Belgian", "Swiss", "Austrian", "Swedish"]

	for role in role_distribution:
		var role_count = role_distribution[role]
		for i in range(role_count):
			var staff = _create_staff(role, nationalities[randi() % nationalities.size()])
			all_staff[staff.id] = staff

func _create_staff(role: String, nationality: String) -> Staff:
	_staff_id_counter += 1
	var staff = Staff.new()
	staff.id = "ST-%04d" % _staff_id_counter
	staff.nationality = nationality
	staff.role = role
	staff.age = randi_range(22, 58)
	staff.sex = "Male" if randf() > 0.3 else "Female"
	staff.contract_team = ""
	staff.contract_seasons_remaining = 0

	# Generate name
	var name_data = NameGenerator.get_full_name(nationality, staff.sex)
	staff.first_name = name_data["first"]
	staff.last_name = name_data["last"]

	# Talent — bell curve distribution
	var raw_talent = randf_range(20.0, 95.0)
	# Most staff cluster around 40-70, fewer at extremes
	staff.talent = clamp((raw_talent + randf_range(20.0, 80.0)) / 2.0, 20.0, 95.0)

	# Starting quality is ~65-85% of talent (from Excel: Overall_Quality_vs_Talent_Ratio ≈ 0.7)
	var quality_ratio = randf_range(0.55, 0.85)
	var base_quality = staff.talent * quality_ratio

	# Reputation scales with quality
	staff.reputation = clamp(base_quality * 0.8, 5.0, 90.0)
	staff.morale = randf_range(70.0, 100.0)

	# Salary — scales with talent
	var salary_range = STAFF_BASE_SALARIES.get(role, {"min": 200.0, "max": 500.0})
	var talent_factor = staff.talent / 100.0
	staff.weekly_salary = salary_range["min"] + (salary_range["max"] - salary_range["min"]) * talent_factor

	# Generate role-specific attributes
	_generate_staff_attributes(staff, base_quality)

	return staff

func _generate_staff_attributes(staff: Staff, base_quality: float) -> void:
	## Generates role-specific attributes around base_quality with variance.
	var q = base_quality

	match staff.role:
		"Race Mechanic":
			staff.car_setup      = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.pit_stops      = clamp(q + randf_range(-20.0, 20.0), 5.0, 95.0)
			staff.car_knowledge  = clamp(q + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.track_knowledge = clamp(randf_range(5.0, 40.0), 5.0, 95.0) # Grows with events
			staff.discipline_adaptation["GK"] = clamp(q * 0.5, 1.0, 100.0)

		"Pit Crew":
			staff.pit_stop_speed = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.repair_skill   = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.teamwork       = clamp(q + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.fitness        = randf_range(70.0, 100.0)

		"Team Principal":
			staff.race_strategy        = clamp(q + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.practice_management  = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.qualifying_management = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.race_pace_reading    = clamp(q + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.car_setup_oversight  = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.pit_stop_management  = clamp(q + randf_range(-20.0, 20.0), 5.0, 95.0)
			staff.pr_skill             = clamp(q + randf_range(-20.0, 20.0), 5.0, 95.0)
			staff.car_knowledge        = clamp(q + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.track_knowledge      = clamp(randf_range(10.0, 50.0), 5.0, 95.0)

		"CFO":
			staff.loan_management     = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.interest_rates      = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.sales_skill         = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.sponsor_negotiation = clamp(q + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.resource_management = clamp(q + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.budget_planning     = clamp(q + randf_range(-10.0, 10.0), 5.0, 95.0)

		"Designer":
			# Each designer has a specialisation — one stat is notably higher
			var specialisms = ["engine", "aero", "brakes", "suspension", "chassis", "gearbox"]
			var specialism = specialisms[randi() % specialisms.size()]
			staff.engine     = clamp(q * 0.7 + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.aero       = clamp(q * 0.7 + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.brakes     = clamp(q * 0.7 + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.suspension = clamp(q * 0.7 + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.chassis    = clamp(q * 0.7 + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.gearbox    = clamp(q * 0.7 + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.reliability    = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.parts_knowledge = clamp(q + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.discipline_adaptation["GK"] = clamp(q * 0.4, 1.0, 100.0)
			# Boost specialism by 15-25 points
			match specialism:
				"engine":     staff.engine     = min(95.0, staff.engine + randf_range(15.0, 25.0))
				"aero":       staff.aero       = min(95.0, staff.aero + randf_range(15.0, 25.0))
				"brakes":     staff.brakes     = min(95.0, staff.brakes + randf_range(15.0, 25.0))
				"suspension": staff.suspension = min(95.0, staff.suspension + randf_range(15.0, 25.0))
				"chassis":    staff.chassis    = min(95.0, staff.chassis + randf_range(15.0, 25.0))
				"gearbox":    staff.gearbox    = min(95.0, staff.gearbox + randf_range(15.0, 25.0))

		"Race Strategist":
			staff.race_strategy       = clamp(q + randf_range(-10.0, 10.0), 5.0, 95.0)
			staff.race_pace_reading   = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.practice_scheduling = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.qualifying_timing   = clamp(q + randf_range(-15.0, 15.0), 5.0, 95.0)
			staff.track_knowledge     = clamp(randf_range(5.0, 35.0), 5.0, 95.0)
			staff.discipline_adaptation["GK"] = clamp(q * 0.4, 1.0, 100.0)

## ═══════════════════════════════════════════════════════════════════════════
## CONTRACT NEGOTIATION SYSTEM (S16.1)
## GDD §6: 3-5 rounds, plain text counters, "Not Interested" from round 1.
## Used by Driver contracts, Staff contracts, and Sponsor renegotiation.
## ═══════════════════════════════════════════════════════════════════════════

## Active negotiation state. One at a time.
var active_negotiation: Dictionary = {}

## ── Approach / Bond / Weekly Negotiation System (S18) ────────────────────────
## Each entry is a Dictionary — see _make_approach() for structure.
var active_approaches: Array = []

## Signals for the UI
signal negotiation_updated()
signal negotiation_concluded(accepted: bool, subject_id: String, subject_type: String)
signal approach_updated()   ## fired whenever active_approaches changes

## ── Opening offer generation ─────────────────────────────────────────────────

## Generate the opening offer for a Driver contract negotiation.
## Returns a Dictionary with all contract terms at the driver's "ask" level.
func generate_driver_opening_offer(driver_id: String) -> Dictionary:
	var driver = all_drivers.get(driver_id)
	if driver == null: return {}
	var skill = driver.get_overall_skill()
	var tier = _get_active_championship_tier()
	## Base weekly salary: skill-scaled, tier-adjusted
	var base_sal = _calc_driver_ask_salary(skill, tier)
	## Bonus asks: scale with skill
	var win_ask       = int(base_sal * 52 * clamp(skill / 100.0, 0.1, 1.0) * 0.6)
	var podium_ask    = int(win_ask * 0.35)
	var champ_ask     = int(win_ask * 1.5)
	var release_ask   = int(base_sal * 52 * 0.8)
	## Duration: better drivers want shorter contracts (more options)
	var duration_ask  = 3 if skill >= 70 else (2 if skill >= 50 else 1)
	## CFO improves our opening position
	var cfo = get_cfo()
	var cfo_bonus = (cfo.sponsor_negotiation / 100.0) * 0.15 if cfo else 0.0
	return {
		"subject_id":    driver_id,
		"subject_type":  "driver",
		"round":         1,
		"max_rounds":    randi_range(3, 5),
		"their_ask": {
			"weekly_salary":        base_sal,
			"win_bonus":            win_ask,
			"podium_bonus":         podium_ask,
			"championship_bonus":   champ_ask,
			"release_clause":       release_ask,
			"duration_seasons":     duration_ask,
		},
		"player_offer": {
			"weekly_salary":        round(base_sal * (0.75 - cfo_bonus)),
			"win_bonus":            round(win_ask * 0.5),
			"podium_bonus":         round(podium_ask * 0.5),
			"championship_bonus":   round(champ_ask * 0.5),
			"release_clause":       round(release_ask * 0.5),
			"duration_seasons":     duration_ask,
		},
		"status":  "active",  ## active | accepted | rejected
		"history": [],
		"cfo_bonus": cfo_bonus,
	}

## Generate opening offer for a Staff contract.
func generate_staff_opening_offer(staff_id: String) -> Dictionary:
	var staff = all_staff.get(staff_id)
	if staff == null: return {}
	var skill = staff.get_primary_skill()
	var salary_range = STAFF_BASE_SALARIES.get(staff.role, {"min": 200.0, "max": 500.0})
	var ask_sal = salary_range["min"] + (salary_range["max"] - salary_range["min"]) * (skill / 100.0)
	## If this is a currently hired staff we're renewing, their existing salary is the floor
	if staff.contract_team == player_team.id:
		ask_sal = max(ask_sal, staff.weekly_salary * 1.05)
	var champ_ask   = int(ask_sal * 52 * 0.3)
	var perf_ask    = int(ask_sal * 52 * 0.2)
	var release_ask = int(ask_sal * 52 * 0.6)
	var duration_ask = 3 if skill >= 70 else (2 if skill >= 50 else 1)
	var cfo = get_cfo()
	var cfo_bonus = (cfo.sponsor_negotiation / 100.0) * 0.15 if cfo else 0.0
	return {
		"subject_id":    staff_id,
		"subject_type":  "staff",
		"round":         1,
		"max_rounds":    randi_range(3, 5),
		"their_ask": {
			"weekly_salary":      ask_sal,
			"championship_bonus": champ_ask,
			"performance_bonus":  perf_ask,
			"release_clause":     release_ask,
			"duration_seasons":   duration_ask,
		},
		"player_offer": {
			"weekly_salary":      round(ask_sal * (0.75 - cfo_bonus)),
			"championship_bonus": round(champ_ask * 0.5),
			"performance_bonus":  round(perf_ask * 0.5),
			"release_clause":     round(release_ask * 0.5),
			"duration_seasons":   duration_ask,
		},
		"status":   "active",
		"history":  [],
		"cfo_bonus": cfo_bonus,
	}

## Generate opening offer for a Sponsor (counter-offer negotiation).
func generate_sponsor_negotiation(sponsor_id: String) -> Dictionary:
	var offer = null
	for o in sponsor_offers:
		if o.get("sponsor_id","") == sponsor_id: offer = o; break
	if offer == null: return {}
	var cfo = get_cfo()
	var cfo_bonus = (cfo.sponsor_negotiation / 100.0) * 0.2 if cfo else 0.0
	var base: Dictionary = {}
	match offer.get("type", 1):
		1: base = {"weekly_payment": offer.get("weekly_payment", 0), "seasons_remaining": offer.get("seasons_remaining", 1)}
		2: base = {"win_bonus": offer.get("win_bonus", 0), "podium_bonus": offer.get("podium_bonus", 0),
				"season_bonus": offer.get("season_bonus", 0), "seasons_remaining": offer.get("seasons_remaining", 1)}
		3: base = {"commitment_total": offer.get("commitment_total", 0), "seasons_remaining": offer.get("seasons_remaining", 1)}
	var player_counter = {}
	for k in base:
		if k == "seasons_remaining":
			player_counter[k] = base[k]
		elif k.ends_with("_total") or k.ends_with("_payment") or k.ends_with("_bonus"):
			player_counter[k] = int(base[k] * (1.0 + cfo_bonus))
	return {
		"subject_id":   sponsor_id,
		"subject_type": "sponsor",
		"round":        1,
		"max_rounds":   randi_range(2, 4),
		"their_ask":    base,
		"player_offer": player_counter,
		"status":       "active",
		"history":      [],
		"cfo_bonus":    cfo_bonus,
		"offer_data":   offer,
	}

## ── Negotiation flow ─────────────────────────────────────────────────────────

## Start a negotiation. Stores state in active_negotiation.
func start_negotiation(neg: Dictionary) -> void:
	active_negotiation = neg
	emit_signal("negotiation_updated")

## Player submits their current offer. Returns the outcome.
## outcome: "accepted" | "counter" | "rejected"
func submit_negotiation_offer(player_offer: Dictionary) -> String:
	if active_negotiation.is_empty(): return "rejected"
	active_negotiation["player_offer"] = player_offer
	active_negotiation["history"].append({
		"round": active_negotiation["round"],
		"player": player_offer.duplicate(),
		"their": active_negotiation["their_ask"].duplicate(),
	})
	var outcome = _evaluate_offer(active_negotiation)
	active_negotiation["round"] += 1
	if outcome == "accepted" or active_negotiation["round"] > active_negotiation["max_rounds"]:
		if outcome != "accepted": outcome = "rejected"
		active_negotiation["status"] = outcome
		_apply_negotiation_result(active_negotiation, outcome == "accepted")
		emit_signal("negotiation_concluded", outcome == "accepted",
			active_negotiation["subject_id"], active_negotiation["subject_type"])
	else:
		## Generate counter-offer: they move slightly toward player
		_apply_counter_offer(active_negotiation)
		emit_signal("negotiation_updated")
	return outcome

## Walk away — player ends negotiation.
## Subjects who walked away from negotiation — unavailable for N seasons
## Format: { subject_id: season_available_again }
var walked_away_subjects: Dictionary = {}

func abandon_negotiation() -> void:
	if active_negotiation.is_empty(): return
	var subject_id   = active_negotiation.get("subject_id", "")
	var subject_type = active_negotiation.get("subject_type", "")
	## Mark unavailable for 2 seasons
	if subject_id != "":
		walked_away_subjects[subject_id] = current_season + 2
		var name_str = _get_subject_display_name(subject_id, subject_type)
		add_notification("Normal", "%s is no longer interested for 2 seasons." % name_str)
	active_negotiation["status"] = "rejected"
	emit_signal("negotiation_concluded", false, subject_id, subject_type)
	active_negotiation = {}
	emit_signal("log_updated")

func is_subject_available(subject_id: String) -> bool:
	if subject_id not in walked_away_subjects: return true
	return current_season >= walked_away_subjects[subject_id]

# ══════════════════════════════════════════════════════════════════════════════
# APPROACH / BOND / WEEKLY NEGOTIATION SYSTEM  (S18)
# ══════════════════════════════════════════════════════════════════════════════

## ── Data structure ────────────────────────────────────────────────────────────
## Creates a new approach record. subject_type: "driver" | "staff"
func _make_approach(subject_id: String, subject_type: String,
		current_team_id: String, start_date: String) -> Dictionary:
	var name_str = _get_subject_display_name(subject_id, subject_type)
	var current_team_name = ""
	for t in all_teams:
		if t.id == current_team_id: current_team_name = t.team_name; break
	return {
		"neg_id":            "%s_%d_%d" % [subject_id, current_season, current_week],
		"type":              "approach",
		"subject_id":        subject_id,
		"subject_type":      subject_type,
		"subject_name":      name_str,
		"current_team_id":   current_team_id,
		"current_team_name": current_team_name,
		"approaching_team":  player_team.id,

		## Interest check
		"interest_checked":  false,
		"subject_interested": false,

		## Bond phase (skipped for free agents or last-season contracts)
		"needs_bond":         current_team_id != "",
		"bond_estimate":      0.0,
		"bond_player_offer":  0.0,
		"bond_team_ask":      0.0,
		"bond_round":         0,     ## 0=not started, 1=awaiting reply, 2=counter reply
		"bond_reply_week":    0,
		"bond_status":        "pending",  ## pending|offered|countered|agreed|rejected

		## Contract negotiation phase
		"start_date":         start_date,  ## "immediate" | "next_season"
		"contract_round":     0,
		"max_contract_rounds": randi_range(3, 5),
		"last_action_week":   current_week,
		"patience_weeks":     3,
		"terms":              {},   ## populated when contract phase starts
		"their_current_ask":  {},
		"locked_fields":      [],   ## fields both sides have agreed on

		"status": "interest_check",
		## interest_check → approaching → bond_offered → bond_countered
		## → negotiating → agreed → failed → rejected → expired
	}

## ── Interest check ────────────────────────────────────────────────────────────
## Returns true if the subject is willing to be approached.
## Uses hidden talent + rep gap + TP reputation.
func _check_subject_interest(subject_id: String, subject_type: String,
		current_team_id: String) -> bool:
	var talent = 50.0
	if subject_type == "driver":
		var d = all_drivers.get(subject_id)
		if d: talent = d.potential if d.potential > 0 else 50.0
	else:
		var s = all_staff.get(subject_id)
		if s: talent = s.talent if s.talent > 0 else 50.0

	var base_chance = talent * 0.5 + 50.0

	## Reputation gap: subject wants to move up, not down
	var their_team_rep = 50.0
	for t in all_teams:
		if t.id == current_team_id:
			their_team_rep = t.reputation if t.has_method("get_reputation") else 50.0
			break
	var rep_gap = player_team.reputation - their_team_rep
	var rep_mod = clamp(rep_gap * 0.5, -25.0, 25.0)

	## TP modifier
	var tp_mod = 0.0
	for champ in active_championships:
		var tp = _get_tp_for_championship(champ.id)
		if tp:
			tp_mod = max(tp_mod, tp.reputation * 0.3)
			break

	var final_chance = clamp(base_chance + rep_mod + tp_mod, 5.0, 95.0)
	return randf() * 100.0 < final_chance

## ── Bond estimate ─────────────────────────────────────────────────────────────
## Returns the CFO's estimate of what the bond should cost.
## No hard limits — this is informational only.
func get_bond_estimate(subject_id: String, subject_type: String,
		start_date: String) -> Dictionary:
	var weekly_sal = 0.0
	var weeks_remaining = 0
	var talent = 50.0

	if subject_type == "driver":
		var d = all_drivers.get(subject_id)
		if d:
			weekly_sal = d.weekly_salary if d.weekly_salary > 0 else _calc_driver_ask_salary(
				d.get_overall_skill(), _get_active_championship_tier())
			weeks_remaining = d.contract_seasons_remaining * 52
			talent = d.potential if d.potential > 0 else 50.0
	else:
		var s = all_staff.get(subject_id)
		if s:
			weekly_sal = s.weekly_salary if s.weekly_salary > 0 else 300.0
			weeks_remaining = s.contract_seasons_remaining * 52
			talent = s.talent if s.talent > 0 else 50.0

	## If next season signing, weeks = from season start not from now
	if start_date == "next_season":
		weeks_remaining = max(0, weeks_remaining - (max_weeks - current_week))

	## Talent factor
	var talent_factor = 0.8
	if talent > 80:   talent_factor = 1.8
	elif talent > 60: talent_factor = 1.3
	elif talent > 30: talent_factor = 1.0

	var raw_estimate = weekly_sal * float(weeks_remaining) * talent_factor

	## CFO accuracy
	var cfo = get_cfo()
	var accuracy = 0.30 if cfo == null else 0.08
	var lo = raw_estimate * (1.0 - accuracy)
	var hi = raw_estimate * (1.0 + accuracy)

	## Immediate mid-contract costs 1.5× + 25% disruption
	if start_date == "immediate" and weeks_remaining > 52:
		raw_estimate *= 1.5 * 1.25
		lo *= 1.5 * 1.25
		hi *= 1.5 * 1.25

	return {
		"estimate":  int(raw_estimate),
		"low":       int(lo),
		"high":      int(hi),
		"accuracy":  accuracy,
		"has_cfo":   cfo != null,
	}

## ── Slot projection ───────────────────────────────────────────────────────────
## Returns { "now": int, "next_season": int } available slots for drivers or staff role.
func get_slot_projection(subject_type: String, role: String = "") -> Dictionary:
	var now_used = 0
	var now_max = 0
	var next_used = 0
	var next_max = 0

	if subject_type == "driver":
		now_used = player_team.drivers.size()
		now_max = get_max_drivers()
		## Next season: subtract expiring contracts
		var expiring = 0
		for d_id in player_team.drivers:
			var d = all_drivers.get(d_id)
			if d and d.contract_seasons_remaining <= 1: expiring += 1
		next_used = now_used - expiring
		next_max = now_max
	else:
		var all_hired = get_player_staff_by_role(role)
		now_used = all_hired.size()
		now_max = _get_max_slots_for_role(role)
		var expiring = 0
		for s in all_hired:
			if s.contract_seasons_remaining <= 1: expiring += 1
		next_used = now_used - expiring
		next_max = now_max

	return {
		"now_used":    now_used,
		"now_max":     now_max,
		"now_free":    now_max - now_used,
		"next_used":   next_used,
		"next_max":    next_max,
		"next_free":   next_max - next_used,
	}

func _get_max_slots_for_role(role: String) -> int:
	match role:
		"Team Principal": return get_hq_tp_slots()
		"CFO":            return 1
		"Race Mechanic":  return player_team_cars.size()
		"Race Strategist":return 1
		"Designer":
			var bld = campus_buildings.get("R&D Design Studio", {})
			return max(1, bld.get("level", 1))
		"Pit Crew":       return player_team_cars.size()
	return 1

func _get_tp_for_championship(champ_id: String):
	for sid in all_staff:
		var s = all_staff[sid]
		if s.role == "Team Principal" and s.contract_team == player_team.id \
				and s.assigned_championship == champ_id:
			return s
	return null

## ── Initiate approach ─────────────────────────────────────────────────────────
## Called when player clicks Approach on a driver or staff member.
## Requires a TP assigned to an active championship.
## Returns "" on success, or an error string.
func initiate_approach(subject_id: String, subject_type: String,
		start_date: String) -> String:
	## TP check
	var has_tp = false
	for champ in active_championships:
		if _get_tp_for_championship(champ.id) != null:
			has_tp = true; break
	if not has_tp:
		return "Assign a Team Principal before making an approach."

	## Already approaching this person?
	for ap in active_approaches:
		if ap["subject_id"] == subject_id and ap["status"] not in ["agreed","failed","rejected","expired"]:
			return "You already have an active approach for this person."

	var current_team_id = ""
	if subject_type == "driver":
		var d = all_drivers.get(subject_id)
		if d == null: return "Driver not found."
		if d.contract_team == player_team.id: return "Already on your team."
		current_team_id = d.contract_team
	else:
		var s = all_staff.get(subject_id)
		if s == null: return "Staff not found."
		if s.contract_team == player_team.id: return "Already on your team."
		current_team_id = s.contract_team

	## Interest check — hidden roll
	var interested = _check_subject_interest(subject_id, subject_type, current_team_id)

	if not interested:
		var name_str = _get_subject_display_name(subject_id, subject_type)
		## TP hint
		var tp_hint = ""
		for champ in active_championships:
			var tp = _get_tp_for_championship(champ.id)
			if tp:
				tp_hint = " %s's assessment: not the right time." % tp.full_name()
				break
		add_notification("Normal",
			"%s is not interested in joining your team at this time.%s" % [name_str, tp_hint])
		add_log("📋 Approach to %s: declined (not interested)." % name_str)
		return "not_interested"

	var ap = _make_approach(subject_id, subject_type, current_team_id, start_date)
	ap["interest_checked"] = true
	ap["subject_interested"] = true

	var name_str = _get_subject_display_name(subject_id, subject_type)

	if current_team_id == "":
		## Free agent — skip bond, go straight to contract negotiation
		ap["status"] = "negotiating"
		ap["needs_bond"] = false
		_start_contract_phase(ap)
		add_log("📋 Approach to free agent %s — contract negotiation begins." % name_str)
		add_notification("Normal", "%s is interested! Contract negotiation begins." % name_str)
	else:
		## Contracted — send bond approach to their team
		var bond_info = get_bond_estimate(subject_id, subject_type, start_date)
		ap["bond_estimate"] = bond_info["estimate"]
		ap["bond_player_offer"] = bond_info["estimate"]  ## default offer = estimate
		ap["bond_reply_week"] = current_week + 1
		ap["status"] = "approaching"
		add_log("📋 Approach sent to %s's team. Bond estimate: CR %s. Reply next week." % [
			name_str, _fmt_int(bond_info["estimate"])])
		add_notification("Normal",
			"Approach sent for %s. Their team will reply next week." % name_str,
			"drivers" if subject_type == "driver" else "staff_hub")

	active_approaches.append(ap)
	emit_signal("approach_updated")
	return ""

## ── Send bond offer ───────────────────────────────────────────────────────────
## Player sets their bond offer amount and sends it.
func send_bond_offer(neg_id: String, offer_amount: float) -> void:
	var ap = _get_approach(neg_id)
	if ap == null or ap["status"] != "approaching": return
	ap["bond_player_offer"] = offer_amount
	ap["bond_round"] = 1
	ap["bond_reply_week"] = current_week + 1
	ap["bond_status"] = "offered"
	emit_signal("approach_updated")

## Player responds to a bond counter from the other team.
func respond_bond_counter(neg_id: String, accept: bool, counter_amount: float = 0.0) -> void:
	var ap = _get_approach(neg_id)
	if ap == null or ap["bond_status"] != "countered": return
	if accept:
		ap["bond_status"] = "agreed"
		ap["bond_amount_final"] = ap["bond_team_ask"]
		ap["status"] = "negotiating"
		_start_contract_phase(ap)
		var name_str = ap["subject_name"]
		add_notification("Normal",
			"Bond agreed for %s (CR %s). Contract negotiation begins." % [
			name_str, _fmt_int(int(ap["bond_team_ask"]))])
		emit_signal("approach_updated")
	elif counter_amount > 0:
		ap["bond_player_offer"] = counter_amount
		ap["bond_round"] = 2
		ap["bond_reply_week"] = current_week + 1
		ap["bond_status"] = "offered"
		emit_signal("approach_updated")
	else:
		ap["bond_status"] = "rejected"
		ap["status"] = "rejected"
		add_notification("Normal", "Bond negotiation with %s's team failed." % ap["subject_name"])
		emit_signal("approach_updated")

## ── Player's own staff approached by AI ──────────────────────────────────────
## Called when AI approaches one of the player's contracted personnel.
func handle_incoming_approach(subject_id: String, subject_type: String,
		ai_team_id: String, ai_team_name: String, proposed_bond: float) -> void:
	var neg_id = "incoming_%s_%d_%d" % [subject_id, current_season, current_week]
	var ap = {
		"neg_id":            neg_id,
		"type":              "bond_incoming",
		"subject_id":        subject_id,
		"subject_type":      subject_type,
		"subject_name":      _get_subject_display_name(subject_id, subject_type),
		"current_team_id":   player_team.id,
		"current_team_name": player_team.team_name,
		"approaching_team":  ai_team_id,
		"approaching_team_name": ai_team_name,
		"bond_team_ask":     proposed_bond,
		"bond_player_offer": proposed_bond,
		"bond_status":       "incoming",
		"status":            "bond_incoming",
		"reply_due_week":    current_week + 1,
	}
	active_approaches.append(ap)
	emit_signal("approach_updated")
	add_notification("High",
		"%s (%s) wants to approach %s. Proposed bond: CR %s — respond in HQ." % [
		ai_team_name, ai_team_id,
		_get_subject_display_name(subject_id, subject_type),
		_fmt_int(int(proposed_bond))], "hq")

## Player responds to an incoming approach for their own staff.
func respond_incoming_approach(neg_id: String, accept: bool, counter_amount: float = 0.0) -> void:
	var ap = _get_approach(neg_id)
	if ap == null or ap["type"] != "bond_incoming": return
	if accept:
		ap["bond_status"] = "agreed"
		ap["status"] = "agreed"
		## Bond payment comes to player team
		var bond = ap["bond_team_ask"]
		player_team.balance += bond
		add_log("💰 Bond received: CR %s for %s transfer." % [_fmt_int(int(bond)), ap["subject_name"]])
		add_notification("Normal",
			"Bond accepted: CR %s received for %s." % [_fmt_int(int(bond)), ap["subject_name"]])
		## The subject will leave at the agreed start_date — handled in advance_week
	elif counter_amount > 0:
		ap["bond_team_ask"] = counter_amount
		ap["bond_status"] = "countered"
		ap["reply_due_week"] = current_week + 1
		add_notification("Normal", "Counter-bond sent for %s. Awaiting reply." % ap["subject_name"])
	else:
		ap["status"] = "rejected"
		add_notification("Normal", "Approach for %s rejected." % ap["subject_name"])
	emit_signal("approach_updated")

## ── Contract phase ────────────────────────────────────────────────────────────
## Populates terms from the existing generate_X_opening_offer logic.
func _start_contract_phase(ap: Dictionary) -> void:
	var neg: Dictionary
	if ap["subject_type"] == "driver":
		neg = generate_driver_opening_offer(ap["subject_id"])
	else:
		neg = generate_staff_opening_offer(ap["subject_id"])
	if neg.is_empty(): return
	## Add start_date and lock support to terms
	ap["terms"] = {}
	for key in neg["their_ask"]:
		ap["terms"][key] = {
			"their_ask":    neg["their_ask"][key],
			"player_offer": neg["player_offer"][key],
			"locked":       false,
			"agreed":       false,
		}
	ap["their_current_ask"] = neg["their_ask"].duplicate()
	ap["max_contract_rounds"] = neg["max_rounds"]
	ap["contract_round"] = 1
	ap["last_action_week"] = current_week + 1  ## First check fires next week — no rounds lost on initiation
	ap["locked_fields"] = []
	## Add start_date as a lockable term
	ap["terms"]["start_date"] = {
		"their_ask":    ap["start_date"],
		"player_offer": ap["start_date"],
		"locked":       false,
		"agreed":       false,
	}

## Player submits a contract offer with per-field values and lock states.
func submit_approach_contract_offer(neg_id: String,
		field_offers: Dictionary, locked_fields: Array) -> String:
	var ap = _get_approach(neg_id)
	if ap == null or ap["status"] != "negotiating": return "error"

	## Update player offers and locks
	for key in field_offers:
		if key in ap["terms"]:
			ap["terms"][key]["player_offer"] = field_offers[key]
	ap["locked_fields"] = locked_fields
	for key in locked_fields:
		if key in ap["terms"]:
			ap["terms"][key]["locked"] = true

	ap["last_action_week"] = current_week + 1  ## Next silence check starts next week
	ap["contract_round"] += 1

	## Evaluate this round
	var outcome = _evaluate_approach_offer(ap)

	if outcome == "accepted":
		ap["status"] = "agreed"
		_apply_approach_result(ap)
		emit_signal("approach_updated")
		return "accepted"
	elif outcome == "rejected" or ap["contract_round"] > ap["max_contract_rounds"]:
		ap["status"] = "failed"
		var name_str = ap["subject_name"]
		add_notification("Normal", "Contract negotiations with %s have broken down." % name_str)
		emit_signal("approach_updated")
		return "rejected"
	else:
		## Counter: they adjust unlocked fields
		_apply_approach_counter(ap)
		emit_signal("approach_updated")
		return "counter"

## Accept all their current asks outright.
func accept_approach_terms(neg_id: String) -> void:
	var ap = _get_approach(neg_id)
	if ap == null or ap["status"] != "negotiating": return
	for key in ap["terms"]:
		ap["terms"][key]["player_offer"] = ap["terms"][key]["their_ask"]
	ap["status"] = "agreed"
	_apply_approach_result(ap)
	emit_signal("approach_updated")

func walk_away_approach(neg_id: String) -> void:
	var ap = _get_approach(neg_id)
	if ap == null: return
	ap["status"] = "rejected"
	walked_away_subjects[ap["subject_id"]] = current_season + 2
	add_notification("Normal",
		"You walked away from negotiations with %s." % ap["subject_name"])
	emit_signal("approach_updated")

## ── Evaluate approach offer ───────────────────────────────────────────────────
func _evaluate_approach_offer(ap: Dictionary) -> String:
	var total_ratio = 0.0
	var count = 0
	for key in ap["terms"]:
		if key in ["duration_seasons", "start_date"]: continue
		var term = ap["terms"][key]
		if term["locked"] or term["agreed"]: continue
		var ask = float(term["their_ask"])
		if ask <= 0: continue
		var offer = float(term["player_offer"])
		total_ratio += clamp(offer / ask, 0.0, 1.0)
		count += 1
	if count == 0: return "accepted"
	var ratio = total_ratio / float(count)
	var round_n = ap["contract_round"]
	var max_r = ap["max_contract_rounds"]
	var threshold = lerp(0.80, 0.65, float(round_n - 1) / float(max(max_r - 1, 1)))
	if ratio >= threshold: return "accepted"
	if ratio < 0.40 and round_n >= max_r - 1: return "rejected"
	return "counter"

func _apply_approach_counter(ap: Dictionary) -> void:
	var progress = float(ap["contract_round"]) / float(ap["max_contract_rounds"])
	for key in ap["terms"]:
		var term = ap["terms"][key]
		if term["locked"] or term["agreed"] or key in ["duration_seasons","start_date"]: continue
		var ask = float(term["their_ask"])
		var offer = float(term["player_offer"])
		if ask <= 0: continue
		var gap = ask - offer
		if gap > 0:
			var concession = gap * 0.10 * progress
			ap["terms"][key]["their_ask"] = max(offer, ask - concession)

## ── Apply agreed approach result ──────────────────────────────────────────────
func _apply_approach_result(ap: Dictionary) -> void:
	var subject_id = ap["subject_id"]
	var subject_type = ap["subject_type"]
	var start_date = ap.get("start_date", "immediate")
	var name_str = ap["subject_name"]

	## Pay bond if there was one
	if ap.get("bond_status", "") == "agreed" and ap.get("bond_amount_final", 0) > 0:
		var bond = ap["bond_amount_final"]
		player_team.balance -= bond
		add_log("💰 Bond paid: CR %s to %s for %s." % [
			_fmt_int(int(bond)), ap["current_team_name"], name_str])

	if start_date == "next_season":
		## Queue for next season — don't apply yet
		ap["type"] = "pre_signed"
		add_log("✅ %s pre-signed — joins Season %d." % [name_str, current_season + 1])
		add_notification("Normal",
			"%s pre-signed and will join at the start of Season %d." % [name_str, current_season + 1],
			"drivers" if subject_type == "driver" else "staff_hub")
		return

	## Immediate — apply contract now using existing _apply_negotiation_result
	var fake_neg = {
		"subject_id":   subject_id,
		"subject_type": subject_type,
		"player_offer": {},
	}
	for key in ap["terms"]:
		fake_neg["player_offer"][key] = ap["terms"][key]["player_offer"]
	_apply_negotiation_result(fake_neg, true)

## ── Weekly advance hooks ──────────────────────────────────────────────────────
## Called from advance_week() to process all active approaches.
func _advance_approaches() -> void:
	var changed = false
	for ap in active_approaches:
		if ap["status"] in ["agreed","failed","rejected","expired"]: continue

		## ── Bond phase: waiting for team reply ──────────────────────────────
		if ap["type"] == "approach" and ap["status"] == "approaching" \
				and ap["bond_status"] == "offered" \
				and current_week >= ap["bond_reply_week"]:
			_process_bond_reply(ap)
			changed = true

		## ── Incoming bond: player hasn't replied ────────────────────────────
		elif ap["type"] == "bond_incoming" and ap["status"] == "bond_incoming" \
				and current_week >= ap.get("reply_due_week", 0):
			## Auto-reject after 2 weeks of silence
			if current_week >= ap.get("reply_due_week", 0) + 2:
				ap["status"] = "rejected"
				add_notification("Normal",
					"Incoming approach for %s auto-rejected (no response)." % ap["subject_name"])
				changed = true

		## ── Contract negotiation: patience counter ──────────────────────────
		elif ap["status"] == "negotiating":
			var weeks_silent = current_week - ap["last_action_week"]
			if weeks_silent >= ap["patience_weeks"]:
				ap["status"] = "expired"
				add_notification("High",
					"Negotiations with %s have expired — no response given." % ap["subject_name"])
				changed = true
			elif weeks_silent >= 1:
				## Round advances each week with no response
				ap["contract_round"] += 1
				ap["last_action_week"] = current_week
				if ap["contract_round"] > ap["max_contract_rounds"]:
					ap["status"] = "failed"
					add_notification("Normal",
						"Contract negotiations with %s have concluded without a deal." % ap["subject_name"])
				else:
					## They also make a counter each week of silence
					_apply_approach_counter(ap)
					add_notification("High",
						"Contract round %d/%d with %s — respond in Drivers/Staff Hub." % [
						ap["contract_round"], ap["max_contract_rounds"], ap["subject_name"]],
						"drivers" if ap["subject_type"] == "driver" else "staff_hub")
				changed = true

		## ── Pre-signed: activate at season start ────────────────────────────
		elif ap["type"] == "pre_signed" and current_season > ap.get("signed_season", current_season):
			_apply_approach_result(ap)   ## now apply with immediate
			ap["start_date"] = "immediate"
			ap["status"] = "agreed"
			changed = true

	## Activate pre-signed contracts at season start (called from start_new_season too)
	_activate_presigned_contracts()

	if changed:
		emit_signal("approach_updated")

func _activate_presigned_contracts() -> void:
	for ap in active_approaches:
		if ap.get("type") == "pre_signed" and ap.get("status") == "agreed":
			var fake_neg = {
				"subject_id":   ap["subject_id"],
				"subject_type": ap["subject_type"],
				"player_offer": {},
			}
			for key in ap["terms"]:
				fake_neg["player_offer"][key] = ap["terms"][key]["player_offer"]
			_apply_negotiation_result(fake_neg, true)
			ap["status"] = "activated"

## ── Bond reply from AI team ───────────────────────────────────────────────────
func _process_bond_reply(ap: Dictionary) -> void:
	## AI team decision: accept, counter, or reject
	## Simple AI: if offer >= 80% of estimate, accept; 50-80% counter; <50% reject
	var estimate = ap["bond_estimate"]
	var offer = ap["bond_player_offer"]
	var ratio = offer / max(estimate, 1.0)

	if ratio >= 0.80:
		ap["bond_status"] = "agreed"
		ap["bond_amount_final"] = offer
		ap["status"] = "negotiating"
		_start_contract_phase(ap)
		add_notification("Normal",
			"%s's team accepted the bond (CR %s). Contract negotiation begins." % [
			ap["subject_name"], _fmt_int(int(offer))],
			"drivers" if ap["subject_type"] == "driver" else "staff_hub")
	elif ratio >= 0.50 and ap["bond_round"] < 2:
		## Counter: ask for estimate × 1.1
		ap["bond_team_ask"] = int(estimate * 1.1)
		ap["bond_status"] = "countered"
		ap["bond_round"] += 1
		ap["bond_reply_week"] = current_week + 1
		add_notification("High",
			"%s's team countered: CR %s for the bond. Accept, counter or reject in Drivers/Staff Hub." % [
			ap["subject_name"], _fmt_int(int(ap["bond_team_ask"]))],
			"drivers" if ap["subject_type"] == "driver" else "staff_hub")
	else:
		ap["bond_status"] = "rejected"
		ap["status"] = "rejected"
		add_notification("Normal",
			"%s's team rejected the bond offer." % ap["subject_name"])

## ── Helpers ───────────────────────────────────────────────────────────────────
func _get_approach(neg_id: String) -> Dictionary:
	for ap in active_approaches:
		if ap["neg_id"] == neg_id: return ap
	return {}

func _get_approach_by_subject(subject_id: String) -> Dictionary:
	for ap in active_approaches:
		if ap["subject_id"] == subject_id and \
				ap["status"] not in ["failed","rejected","expired","activated"]:
			return ap
	return {}

func get_active_approaches_for_display() -> Array:
	## Returns all approaches that should show in HQ Pending Activity
	return active_approaches.filter(func(ap):
		return ap["status"] not in ["activated", "expired"] or \
			(ap["status"] == "agreed" and ap.get("type") == "pre_signed"))

func get_pending_contract_negotiation() -> Dictionary:
	## Returns the first approach in "negotiating" status (for popup display)
	for ap in active_approaches:
		if ap["status"] == "negotiating": return ap
	return {}

func _get_subject_display_name(subject_id: String, subject_type: String) -> String:
	match subject_type:
		"driver":
			var d = all_drivers.get(subject_id)
			return d.full_name() if d else subject_id
		"staff":
			var s = all_staff.get(subject_id)
			return s.full_name() if s else subject_id
		"sponsor":
			for o in sponsor_offers:
				if o.get("sponsor_id","") == subject_id: return o.get("name", subject_id)
	return subject_id

## ── Internal helpers ─────────────────────────────────────────────────────────

func _get_active_championship_tier() -> int:
	if active_championship == null: return 1
	return active_championship.tier

func _calc_driver_ask_salary(skill: float, tier: int) -> float:
	## Base weekly: tier 1 starts at ~50, tier 4 at ~2850
	const TIER_BASES = {1: 50.0, 2: 250.0, 3: 900.0, 4: 2850.0}
	var base = TIER_BASES.get(tier, 50.0)
	return round((base + base * (skill / 100.0) * 1.5) / 10.0) * 10.0

## Evaluate whether the player's offer is acceptable.
## Returns "accepted", "counter", or "rejected".
func _evaluate_offer(neg: Dictionary) -> String:
	var player = neg["player_offer"]
	var ask    = neg["their_ask"]
	var round_n = neg["round"]
	var max_r   = neg["max_rounds"]
	## Calculate how close the offer is to their ask (0=nothing, 1=full ask)
	var ratio = _calc_offer_ratio(player, ask)
	## Acceptance threshold: 80% of ask at round 1, drops to 65% by last round
	var threshold = lerp(0.80, 0.65, float(round_n - 1) / float(max(max_r - 1, 1)))
	if ratio >= threshold: return "accepted"
	## Hard reject: below 40% and in last 2 rounds
	if ratio < 0.40 and round_n >= max_r - 1: return "rejected"
	return "counter"

func _calc_offer_ratio(player: Dictionary, ask: Dictionary) -> float:
	var total_ratio = 0.0
	var count = 0
	for key in ask:
		if key == "duration_seasons": continue
		if ask[key] <= 0: continue
		var p_val = float(player.get(key, 0))
		var a_val = float(ask[key])
		total_ratio += clamp(p_val / a_val, 0.0, 1.0)
		count += 1
	return total_ratio / float(max(count, 1))

## Move their ask slightly toward player's offer.
func _apply_counter_offer(neg: Dictionary) -> void:
	var player = neg["player_offer"]
	var ask    = neg["their_ask"]
	var progress = float(neg["round"]) / float(neg["max_rounds"])
	## They concede up to 25% of the gap over the full negotiation
	for key in ask:
		if key == "duration_seasons": continue
		if ask[key] <= 0: continue
		var gap = ask[key] - player.get(key, 0)
		if gap > 0:
			var concession = gap * 0.10 * progress
			neg["their_ask"][key] = max(player.get(key, 0), ask[key] - concession)

## Apply the result — actually hire/set contract terms.
func _apply_negotiation_result(neg: Dictionary, accepted: bool) -> void:
	if not accepted: return
	var terms = neg["player_offer"]
	match neg["subject_type"]:
		"driver":
			var driver = all_drivers.get(neg["subject_id"])
			if driver == null: return
			## Check slot first
			var max_d = get_max_drivers()
			if driver.contract_team == "" and player_team.drivers.size() >= max_d:
				add_notification("High", "Racing Dept full — can't sign %s." % driver.full_name())
				return
			driver.contract_team = player_team.id
			driver.contract_seasons_remaining = terms.get("duration_seasons", 1)
			driver.weekly_salary       = terms.get("weekly_salary", 50.0)
			driver.win_bonus           = terms.get("win_bonus", 0)
			driver.podium_bonus        = terms.get("podium_bonus", 0)
			driver.championship_bonus  = terms.get("championship_bonus", 0)
			driver.release_clause      = terms.get("release_clause", 0)
			if not neg["subject_id"] in player_team.drivers:
				player_team.drivers.append(neg["subject_id"])
				if active_championship:
					active_championship.standings[neg["subject_id"]] = 0
			add_log("✅ %s signed: CR %.0f/wk, %d seasons, Win:CR %s, Podium:CR %s" % [
				driver.full_name(), driver.weekly_salary, driver.contract_seasons_remaining,
				_fmt_int(driver.win_bonus), _fmt_int(driver.podium_bonus)])
			add_notification("Normal", "%s signed. Assign them to a car in the Garage." % driver.full_name())
		"staff":
			var staff = all_staff.get(neg["subject_id"])
			if staff == null: return
			## Slot checks (same as hire_staff)
			if staff.contract_team == "":
				if staff.role == "Team Principal":
					var existing = get_player_staff_by_role("Team Principal")
					if existing.size() >= get_hq_tp_slots():
						add_notification("High", "TP slots full. Upgrade HQ."); return
				elif staff.role == "CFO":
					if get_player_staff_by_role("CFO").size() >= 1:
						add_notification("High", "You already have a CFO."); return
			staff.contract_team = player_team.id
			staff.contract_seasons_remaining = terms.get("duration_seasons", 1)
			staff.weekly_salary        = terms.get("weekly_salary", staff.weekly_salary)
			staff.championship_bonus   = terms.get("championship_bonus", 0)
			staff.performance_bonus    = terms.get("performance_bonus", 0)
			staff.release_clause       = terms.get("release_clause", 0)
			if staff.role == "Pit Crew" and staff.crew_number == 0:
				staff.crew_number = get_player_staff_by_role("Pit Crew").size()
			add_log("✅ %s (%s) signed: CR %.0f/wk, %d seasons" % [
				staff.full_name(), staff.role, staff.weekly_salary, staff.contract_seasons_remaining])
			add_notification("Normal", "%s (%s) joined your team." % [staff.full_name(), staff.role])
		"sponsor":
			sign_sponsor(neg["subject_id"])
	emit_signal("log_updated")

## ── Weekly salary payment (driver) ──────────────────────────────────────────
## Called from advance_week. Replaces the old flat weekly_driver_salary approach.
## If driver has no individual weekly_salary set, falls back to championship rate.
func _pay_driver_salaries_weekly() -> void:
	for driver_id in player_team.drivers:
		var driver = all_drivers.get(driver_id)
		if driver == null: continue
		var sal = driver.weekly_salary if driver.weekly_salary > 0 \
				else _get_championship_driver_salary()
		player_team.balance -= sal

## Pay driver race bonuses after a race result.
func pay_driver_race_bonuses(race_results: Array) -> void:
	for entry in race_results:
		var driver = entry.get("driver")
		if driver == null: continue
		if driver.contract_team != player_team.id: continue
		var pos = entry.get("position", 99)
		var bonus = 0
		if pos == 1:   bonus = driver.win_bonus
		elif pos <= 3: bonus = driver.podium_bonus
		if bonus > 0:
			player_team.balance -= bonus
			add_log("🏆 Race bonus paid: %s — CR %s (P%d)" % [
				driver.full_name(), _fmt_int(bonus), pos])

func hire_staff(staff_id: String) -> bool:
	if not staff_id in all_staff:
		return false
	var staff = all_staff[staff_id]
	if staff.is_hired():
		return false
	## TP slots = 1 per HQ level. CFO: always 1.
	if staff.role == "Team Principal":
		var existing_tp = get_player_staff_by_role("Team Principal")
		var max_tp = get_hq_tp_slots()
		if existing_tp.size() >= max_tp:
			add_notification("High",
				"TP slots full (%d/%d). Upgrade the HQ to unlock more slots." % [existing_tp.size(), max_tp])
			return false
	if staff.role == "CFO":
		var existing_cfo = get_player_staff_by_role("CFO")
		if existing_cfo.size() >= 1:
			add_notification("High", "You already have a CFO. Release them first.")
			return false
	staff.contract_team = player_team.id
	staff.contract_seasons_remaining = 5
	# Assign crew number for Pit Crew units
	if staff.role == "Pit Crew":
		var existing_crews = get_player_staff_by_role("Pit Crew")
		staff.crew_number = existing_crews.size() + 1
		add_log("✅ Hired %s — CR %.0f/week" % [staff.display_name(), staff.weekly_salary])
		add_notification("Normal", "Pit Crew #%d hired. Assign them to a non-GK car in the Pit Crew Arena." % staff.crew_number)
	else:
		add_log("✅ Hired %s (%s) — CR %.0f/week" % [staff.full_name(), staff.role, staff.weekly_salary])
		add_notification("Normal", "%s (%s) joined your team." % [staff.full_name(), staff.role])
		_clear_notifications_containing("No CFO hired")
		_clear_notifications_containing("No Team Principal")
	emit_signal("log_updated")
	return true

func release_staff(staff_id: String) -> void:
	if not staff_id in all_staff:
		return
	var staff = all_staff[staff_id]
	var clause = staff.release_clause if staff.release_clause > 0 else 0
	if clause > 0 and staff.contract_seasons_remaining > 0:
		player_team.balance -= clause
		add_log("💰 Release clause paid: CR %s for %s." % [_fmt_int(clause), staff.full_name()])
		add_notification("High",
			"Released %s — CR %s release clause paid." % [staff.full_name(), _fmt_int(clause)])
	staff.contract_team = ""
	staff.assigned_championship = ""
	staff.assigned_car_id = ""
	staff.contract_seasons_remaining = 0
	staff.release_clause = 0
	add_log("👋 Released %s (%s)" % [staff.full_name(), staff.role])
	emit_signal("log_updated")

func renew_staff_contract(staff_id: String, seasons: int = 5) -> void:
	if not staff_id in all_staff:
		return
	var staff = all_staff[staff_id]
	if staff.contract_team != player_team.id:
		return
	staff.contract_seasons_remaining = seasons
	add_log("📋 Contract renewed: %s (%s) — %d seasons" % [staff.full_name(), staff.role, seasons])
	emit_signal("log_updated")

## ── Driver management ────────────────────────────────────────────────────────

## Returns all drivers not contracted to any team (available for hire).
func get_available_drivers() -> Array:
	var result = []
	for driver_id in all_drivers:
		var driver = all_drivers[driver_id]
		if driver.contract_team == "":
			result.append(driver)
	return result

## Returns all drivers contracted to the player team.
func get_player_drivers() -> Array:
	var result = []
	for driver_id in player_team.drivers:
		if driver_id in all_drivers:
			result.append(all_drivers[driver_id])
	return result

## Hire a driver — adds to player roster only. Does NOT create a car.
## Cars are managed independently via add_car() in the Garage.
func hire_driver(driver_id: String) -> bool:
	if not driver_id in all_drivers:
		return false
	var driver = all_drivers[driver_id]
	if driver.contract_team != "":
		add_notification("High", "%s is already contracted to another team." % driver.full_name())
		return false
	# Enforce Racing Department slot cap
	var max_d = get_max_drivers()
	if player_team.drivers.size() >= max_d:
		add_notification("High",
			"Racing Department full (%d/%d slots). Upgrade it to sign more drivers." % [
			player_team.drivers.size(), max_d])
		return false
	driver.contract_team = player_team.id
	driver.contract_seasons_remaining = 5
	player_team.drivers.append(driver_id)
	active_championship.standings[driver_id] = 0
	add_log("✅ Signed %s — contract: 5 seasons. Assign them to a car in the Drivers screen." % driver.full_name())
	add_notification("Normal", "%s signed. Build a car in the Garage, then assign them." % driver.full_name())
	emit_signal("log_updated")
	return true

## Release a driver from the player team.
## Clears their assignment from any car but does NOT delete the car.
func release_driver(driver_id: String) -> void:
	if not driver_id in all_drivers:
		return
	var driver = all_drivers[driver_id]
	## Deduct release clause if driver is under contract and clause > 0
	var clause = driver.release_clause if driver.release_clause > 0 else 0
	if clause > 0 and driver.contract_seasons_remaining > 0:
		player_team.balance -= clause
		add_log("💰 Release clause paid: CR %s for %s." % [_fmt_int(clause), driver.full_name()])
		add_notification("High",
			"Released %s — CR %s release clause paid." % [driver.full_name(), _fmt_int(clause)])
	driver.contract_team = ""
	driver.contract_seasons_remaining = 0
	driver.release_clause = 0
	player_team.drivers.erase(driver_id)
	for car in player_team_cars:
		if car.driver_id == driver_id:
			car.driver_id = ""
			add_log("🏎 Car %d now has no driver." % car.car_number)
			break
	add_log("👋 Released driver: %s" % driver.full_name())
	emit_signal("log_updated")

## Renew a driver's contract.
func renew_driver_contract(driver_id: String, seasons: int = 5) -> void:
	if not driver_id in all_drivers:
		return
	var driver = all_drivers[driver_id]
	if driver.contract_team != player_team.id:
		return
	driver.contract_seasons_remaining = seasons
	add_log("📋 Contract renewed: %s — %d seasons" % [driver.full_name(), seasons])
	emit_signal("log_updated")

## Assign a driver to a specific car by car_id.
func assign_driver_to_car(driver_id: String, car_id: String) -> void:
	var car = get_car_by_id(car_id)
	if not car:
		return
	# Age eligibility check for this championship
	var driver = all_drivers.get(driver_id)
	if driver:
		var reg = CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
		var min_age = reg.get("min_age", 0)
		var max_age = reg.get("max_age", 99)
		if driver.age < min_age or driver.age > max_age:
			add_notification("High",
				"⚠ Cannot assign %s (age %d) to %s — age limit is %d–%s." % [
				driver.full_name(), driver.age, reg.get("name", car.championship_id),
				min_age, str(max_age) if max_age < 99 else "+"])
			emit_signal("log_updated")
			return
	# Unassign from any current car first
	for c in player_team_cars:
		if c.driver_id == driver_id:
			c.driver_id = ""
	if car:
		# Unassign whoever was in this car
		if car.driver_id != "" and car.driver_id != driver_id:
			var old_driver = all_drivers.get(car.driver_id)
			if old_driver:
				add_log("↩ %s unassigned from Car %d" % [old_driver.full_name(), car.car_number])
		car.driver_id = driver_id
		var assigned_driver = all_drivers.get(driver_id)
		add_log("🏎 %s assigned to %s" % [assigned_driver.full_name() if assigned_driver else driver_id, car.car_name if car.car_name != "" else "Car %d" % car.car_number])
		# Add driver to this championship's standings if not already there
		for champ in active_championships:
			if champ.id == car.championship_id and not driver_id in champ.standings:
				champ.standings[driver_id] = 0
			if champ.id == car.championship_id and not player_team.id in champ.team_standings:
				champ.team_standings[player_team.id] = 0
		# Record which championship this driver is running — shown next season
		previous_season_championship[driver_id] = car.championship_id
		emit_signal("log_updated")

## Creates a new empty car slot. Capped by Garage level.
## Called from the Garage scene — independent of driver hire.
## Generates a car display name: e.g. GKR-S1-A, GKN-S3-B
## Must be called BEFORE appending the new car to player_team_cars.
func generate_car_name(for_champ_id: String = "") -> String:
	# Use provided champ_id, or fall back
	var champ_id = for_champ_id
	if champ_id == "":
		champ_id = active_championship.id
	if champ_id == "" and not player_registered_championships.is_empty():
		champ_id = player_registered_championships[0]

	const CHAMP_CODES = {
		"C-001": "GKR", "C-002": "GKN", "C-003": "GKC", "C-004": "GKW",
		"C-005": "RL4", "C-006": "RL3", "C-007": "RL2", "C-008": "RLP",
		"C-009": "TCS", "C-010": "TCE",
		"C-011": "OWN", "C-012": "OWD", "C-013": "OWP",
		"C-014": "SCD", "C-015": "SCT", "C-016": "SCC", "C-017": "SCU",
		"C-018": "EPS", "C-019": "EPL", "C-020": "EPH",
		"C-021": "GP4", "C-022": "GP3", "C-023": "GP2", "C-024": "GP1",
	}
	var code = CHAMP_CODES.get(champ_id, "CAR")
	var season = "S%d" % current_season
	# Letter counts cars assigned to THIS championship only (A = first, B = second...)
	var same_champ_count = 0
	for car in player_team_cars:
		if car.championship_id == champ_id:
			same_champ_count += 1
	var letter = char(65 + same_champ_count)
	return "%s-%s-%s" % [code, season, letter]

func add_car(for_champ_id: String = "") -> bool:
	var max_c = get_max_cars()
	if player_team_cars.size() >= max_c:
		add_notification("High",
			"Garage full (%d/%d slots). Upgrade the Garage to field more cars." % [
			player_team_cars.size(), max_c])
		return false

	# Determine which championship this car is for
	var champ_id = for_champ_id
	if champ_id == "":
		champ_id = active_championship.id
		if champ_id == "" and not player_registered_championships.is_empty():
			champ_id = player_registered_championships[0]

	var car_number = player_team_cars.size() + 1
	var car        = Car.new()
	car.id         = "CAR-P%03d" % car_number
	car.car_type_id    = "A_01"
	car.championship_id = champ_id
	car.car_number = car_number
	car.car_name   = generate_car_name(champ_id)
	car.driver_id  = ""
	car.mechanic_id = ""
	# Pit crew: not required for GK, required for all others
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var discipline = reg.get("discipline", "GK")
	car.pit_crew_id = "N/A" if not PIT_CREW_REQUIRED.get(discipline, true) else ""
	car.condition   = 100.0
	car.part_conditions = {"Aero": 100.0, "Engine": 100.0, "Gearbox": 100.0,
		"Suspension": 100.0, "Brakes": 100.0, "Chassis": 100.0}
	# Use championship-appropriate telemetry
	const CHAMP_CAR_TYPE = {
		"C-001": "A_01", "C-002": "A_02", "C-003": "A_02", "C-004": "A_02",
		"C-005": "A_05", "C-006": "A_05", "C-007": "A_05", "C-008": "A_05",
		"C-009": "A_09", "C-010": "A_09",
		"C-011": "A_11", "C-012": "A_11", "C-013": "A_11",
		"C-014": "A_14", "C-015": "A_14", "C-016": "A_14", "C-017": "A_14",
		"C-018": "A_18", "C-019": "A_18", "C-020": "A_18",
		"C-021": "A_21", "C-022": "A_21", "C-023": "A_21", "C-024": "A_21",
	}
	var car_type = CHAMP_CAR_TYPE.get(champ_id, "A_01")
	car.car_type_id = car_type
	var telemetry = CAR_TELEMETRY.get(car_type, CAR_TELEMETRY.get("A_01", {}))
	if not telemetry.is_empty():
		car.top_speed = telemetry["top_speed"]
		car.acceleration = telemetry["acceleration"]
		car.deceleration = telemetry["deceleration"]
		car.cornering_grip = telemetry["cornering_grip"]
		car.fuel_consumption_per_km = telemetry["fuel_per_km"]
		car.tire_wear_rate = telemetry["tire_wear"]
		car.baseline_performance_index = telemetry["perf_index"]
	player_team_cars.append(car)
	add_log("🏎 %s added to garage for %s — assign a driver and mechanic before racing." % [
		car.car_name, reg.get("name", champ_id)])
	if get_pit_crew_required(champ_id):
		add_notification("High",
			"🔧 %s needs a Pit Crew assigned before Race 1 or it will DNS. Hire at Pit Crew Arena." % car.car_name)
	add_notification("Normal", "%s ready. Assign a driver via the Garage." % car.car_name)
	emit_signal("log_updated")
	return true

## Removes a car by car_id. Clears any driver/mechanic assignments first.
## Does NOT release the driver — they remain on the roster.
func remove_car(car_id: String) -> bool:
	for i in range(player_team_cars.size()):
		var car = player_team_cars[i]
		if car.id == car_id:
			if car.driver_id != "":
				add_log("🏎 Car %d removed — %s is now without a car." % [
					car.car_number, all_drivers[car.driver_id].full_name() if car.driver_id in all_drivers else car.driver_id])
			# Clear mechanic assignment
			if car.mechanic_id != "" and car.mechanic_id in all_staff:
				all_staff[car.mechanic_id].assigned_car_id = ""
			player_team_cars.remove_at(i)
			# Re-number remaining cars
			for j in range(player_team_cars.size()):
				player_team_cars[j].car_number = j + 1
			add_log("🗑 Car removed. %d car(s) remaining." % player_team_cars.size())
			emit_signal("log_updated")
			return true
	return false

## Renames a car. Validates the name is non-empty and max 12 chars.
## Returns true on success, false if validation fails.
func rename_car(car_id: String, new_name: String) -> bool:
	var name = new_name.strip_edges()
	if name == "":
		add_notification("Normal", "Car name cannot be empty.")
		return false
	if name.length() > 12:
		add_notification("Normal", "Car name must be 12 characters or fewer.")
		return false
	var car = get_car_by_id(car_id)
	if not car:
		return false
	var old_name = car.car_name
	car.car_name = name
	add_log("✏ Car renamed: %s → %s" % [old_name, name])
	emit_signal("log_updated")
	return true

func assign_staff_to_car(staff_id: String, car_id: String) -> void:
	if not staff_id in all_staff:
		return
	var staff = all_staff[staff_id]
	var car = get_car_by_id(car_id)
	staff.assigned_car_id = car_id
	staff.assigned_championship = car.championship_id if car else active_championship.id
	# Record which championship this staff member is running
	if car:
		previous_season_championship[staff_id] = car.championship_id
	# Wire mechanic/pit crew to car
	if car:
		if staff.role == "Race Mechanic":
			car.mechanic_id = staff_id
		elif staff.role == "Pit Crew":
			car.pit_crew_id = staff_id
	add_log("🔧 %s assigned to Car %s" % [staff.full_name(), car_id])

func unassign_driver_from_car(car_id: String) -> void:
	var car = get_car_by_id(car_id)
	if not car: return
	if car.driver_id == "": return
	var drv = all_drivers.get(car.driver_id)
	add_log("↩ %s unassigned from %s" % [
		drv.full_name() if drv else car.driver_id,
		car.car_name if car.car_name != "" else "Car %d" % car.car_number])
	car.driver_id = ""
	emit_signal("log_updated")

func unassign_mechanic_from_car(car_id: String) -> void:
	var car = get_car_by_id(car_id)
	if not car: return
	if car.mechanic_id == "": return
	var mech = all_staff.get(car.mechanic_id)
	if mech:
		mech.assigned_car_id = ""
		add_log("↩ %s unassigned from %s" % [
			mech.full_name(),
			car.car_name if car.car_name != "" else "Car %d" % car.car_number])
	car.mechanic_id = ""
	emit_signal("log_updated")

func assign_staff_to_championship(staff_id: String, champ_id: String) -> void:
	if not staff_id in all_staff: return
	var staff = all_staff[staff_id]
	## Guard: TP slot — only one TP per championship
	if staff.role == "Team Principal":
		for sid2 in all_staff:
			var s2 = all_staff[sid2]
			if s2.id == staff_id: continue
			if s2.role == "Team Principal" and s2.contract_team == player_team.id \
					and s2.assigned_championship == champ_id:
				add_notification("High",
					"Championship already has a Team Principal assigned.")
				return
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var champ_name = reg.get("name", champ_id)
	## TP and Strategist: queue for next week (prevents mid-race exploitation)
	if staff.role in ["Team Principal", "Race Strategist"]:
		pending_staff_assignments[staff_id] = champ_id
		add_log("📋 %s queued to join %s — effective next week." % [staff.full_name(), champ_name])
		add_notification("Normal",
			"%s will be assigned to %s from next week." % [staff.full_name(), champ_name])
	else:
		## Mechanic / Pit Crew: immediate (no advantage to delay)
		staff.assigned_championship = champ_id
		add_log("📋 %s assigned to %s" % [staff.full_name(), champ_name])

func _apply_pending_staff_assignments() -> void:
	if pending_staff_assignments.is_empty(): return
	for sid in pending_staff_assignments.keys():
		if not sid in all_staff: continue
		var s = all_staff[sid]
		var cid: String = pending_staff_assignments[sid]
		s.assigned_championship = cid
		var reg = CHAMPIONSHIP_REGISTRY.get(cid, {})
		add_log("📋 %s now active at %s." % [s.full_name(), reg.get("name", cid)])
	pending_staff_assignments.clear()

func get_pending_assignment_for(sid: String) -> String:
	return pending_staff_assignments.get(sid, "")



func get_player_staff_by_role(role: String) -> Array:
	var result = []
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.contract_team == player_team.id and staff.role == role:
			result.append(staff)
	return result

func get_available_staff_by_role(role: String) -> Array:
	var result = []
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.contract_team == "" and staff.role == role:
			result.append(staff)
	return result

func get_all_available_staff() -> Array:
	var result = []
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.contract_team == "":
			result.append(staff)
	return result

func get_all_player_staff() -> Array:
	var result = []
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.contract_team == player_team.id:
			result.append(staff)
	return result

## Returns the mechanic assigned to a specific car, or null.
func get_mechanic_for_car(car_id: String) -> Staff:
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.role == "Race Mechanic" and staff.assigned_car_id == car_id \
				and staff.contract_team == player_team.id:
			return staff
	return null

## Returns the Team Principal assigned to active championship, or null.
func get_team_principal() -> Staff:
	var tps = get_player_staff_by_role("Team Principal")
	for tp in tps:
		if tp.assigned_championship == active_championship.id or tp.assigned_championship == "":
			return tp
	return null

## Returns the CFO, or null.
func get_cfo() -> Staff:
	var cfos = get_player_staff_by_role("CFO")
	return cfos[0] if cfos.size() > 0 else null

## Returns only tasks that would cause a DNS or prevent racing entirely.
## Used by the Next Race skip button — advisory warnings don't block the skip.
func get_race_blocking_tasks() -> Array[String]:
	var tasks: Array[String] = []
	if active_championship == null:
		return tasks
	var next_race = active_championship.get_next_race()
	if not next_race:
		return tasks

	# No drivers at all
	if player_team.drivers.is_empty():
		tasks.append("👤 No drivers signed — cannot race.")
		return tasks

	# Cars with DNS conditions — check per active championship
	for car in player_team_cars:
		var champ_name = ""
		for champ in active_championships:
			if champ.id == car.championship_id:
				champ_name = " [%s]" % champ.championship_name
				break
		var cn = (car.car_name if car.car_name != "" else "Car %d" % car.car_number) + champ_name
		if car.driver_id == "":
			tasks.append("🏎 %s has no driver — will DNS." % cn)
		if car.mechanic_id == "":
			tasks.append("🔧 %s has no Race Mechanic — will DNS." % cn)
		if get_pit_crew_required(car.championship_id):
			if car.pit_crew_id == "" or car.pit_crew_id == "N/A":
				tasks.append("⏱ %s has no Pit Crew — will DNS. Assign in Pit Crew Arena." % cn)

	# No fuel
	if fuel_kg < active_championship.fuel_per_car_per_race:
		tasks.append("⛽ Not enough fuel (%.0f kg) — car will DNS." % fuel_kg)

	# Negative balance — can't pay entry fees
	if player_team.balance < 0:
		tasks.append("💸 Negative balance — cannot pay race entry fees.")

	return tasks
## 1.0 if no mechanic (still repairs, just at base rate — staff gate comes later).
func _get_repair_efficiency() -> float:
	# For now, find the first hired mechanic assigned to any player car
	for car in player_team_cars:
		var mechanic = get_mechanic_for_car(car.id)
		if mechanic:
			return mechanic.get_repair_efficiency()
	return 1.0

## Pre-race check — warns if TP is missing but does NOT block the race.
func _check_race_requirements() -> void:
	_check_race_requirements_for(active_championship)

func _check_race_requirements_for(champ: Championship) -> void:
	var tp = get_team_principal()
	if tp == null:
		add_notification("High",
			"⚠ No Team Principal for %s! Racing without tactical oversight." % champ.championship_name)
	var has_cfo = get_cfo() != null
	if not has_cfo:
		add_notification("Normal",
			"💼 No CFO on staff. Financial optimisation unavailable.")

## Returns an array of pending task strings the player should review before advancing.
## Used by MainHub to prompt the player before advancing the week.
func get_pending_tasks() -> Array[String]:
	var tasks: Array[String] = []

	## Step 1 — No car for ACTIVE championships (not next-season registrations)
	var active_champ_ids: Array = []
	for champ in active_championships:
		active_champ_ids.append(champ.id)

	for reg_champ_id in player_registered_championships:
		if not reg_champ_id in active_champ_ids:
			continue  ## Next-season registration — BeginOfSeason handles it
		var has_car = false
		for car in player_team_cars:
			if car.championship_id == reg_champ_id:
				has_car = true
				break
		if not has_car:
			var reg = CHAMPIONSHIP_REGISTRY.get(reg_champ_id, {})
			tasks.append("🏎 No car for %s — buy one at Logistics Center." % reg.get("name", reg_champ_id))

	## Step 2 — Cars exist: check driver/mechanic/pit crew assignment
	## Only show these if the car exists (don't pile on when car not bought yet)
	for car in player_team_cars:
		## Skip if this car's championship has no car task above (redundant check — car exists)
		var reg = CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
		var champ_name = reg.get("name", car.championship_id)
		var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
		if car.driver_id == "":
			if player_team.drivers.is_empty():
				tasks.append("👤 No drivers signed — hire one from Drivers screen.")
			else:
				tasks.append("🏎 %s [%s] — no driver assigned. Go to Garage." % [car_label, champ_name])
		if car.mechanic_id == "":
			var has_mechanic = false
			for sid in all_staff:
				var s = all_staff[sid]
				if s.role == "Race Mechanic" and s.contract_team == player_team.id:
					has_mechanic = true
					break
			if not has_mechanic:
				tasks.append("🔧 No Race Mechanic hired — hire one from Staff screen.")
			else:
				tasks.append("🔧 %s [%s] — no mechanic assigned. Go to Garage." % [car_label, champ_name])
		if get_pit_crew_required(car.championship_id):
			if car.pit_crew_id == "" or car.pit_crew_id == "N/A":
				tasks.append("⏱ %s [%s] — no Pit Crew. Assign in Pit Crew Arena." % [car_label, champ_name])

	## Step 3 — Staff roles missing
	if get_team_principal() == null:
		tasks.append("⚠ No Team Principal — hire one from Staff screen.")
	if get_cfo() == null:
		tasks.append("💼 No CFO hired — hire one from Staff screen.")

	## Step 4 — Resources
	## Low SP — only warn when races are still coming
	if has_remaining_races_this_season():
		if spare_parts < 20:
			tasks.append("🔧 Spare parts low (%d units) — buy at Logistics." % spare_parts)
		## Low fuel — only warn when race approaching
		if active_championship != null:
			var next_race = active_championship.get_next_race()
			if next_race:
				var weeks_until = next_race["week"] - current_week
				if weeks_until <= 2 and fuel_kg < active_championship.fuel_per_car_per_race:
					tasks.append("⛽ Fuel below race minimum (%.0f kg) — buy at Logistics." % fuel_kg)

	## Step 5 — Financial
	if player_team.balance < 0:
		tasks.append("💸 Balance negative (CR %s). Bankruptcy risk." % _fmt_int(int(player_team.balance)))

	## Step 6 — Car condition
	for car in player_team_cars:
		if car.condition < 30.0:
			tasks.append("🔩 %s condition critical (%.0f%%) — repair in Garage." % [
				car.car_name if car.car_name != "" else "Car %d" % car.car_number, car.condition])

	## Step 7 — Expiring contracts
	for driver_id in player_team.drivers:
		var driver = all_drivers.get(driver_id)
		if driver and driver.contract_seasons_remaining <= 1:
			tasks.append("📋 %s contract expires soon." % driver.full_name())
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.contract_team == player_team.id and staff.contract_seasons_remaining <= 1:
			tasks.append("📋 %s (%s) contract expires soon." % [staff.full_name(), staff.role])

	## Step 7b — Pending negotiations awaiting player response
	for ap in active_approaches:
		if ap["status"] in ["failed","rejected","expired","activated","agreed"]: continue
		match ap["status"]:
			"bond_incoming":
				tasks.append("💰 %s wants %s — respond to their bond offer." % [
					ap.get("approaching_team_name","AI Team"), ap["subject_name"]])
			"negotiating":
				var weeks_silent = current_week - ap.get("last_action_week", current_week)
				if weeks_silent >= 1:
					var rounds_left = ap.get("max_contract_rounds",4) - ap.get("contract_round",1)
					tasks.append("📋 Contract Round %d/%d with %s — respond before it expires (%d rounds left)." % [
						ap.get("contract_round",1), ap.get("max_contract_rounds",4),
						ap["subject_name"], rounds_left])

	## Step 8 — R&D → WRA → CNC → Garage pipeline
	## 8a: Blueprints ready but not yet submitted to WRA
	## - Next-season blueprints (P1/P3): always remind
	## - Current-season P2 upgrades: also remind (need WRA this season)
	for bp_id in known_blueprints:
		if not is_blueprint_submitted(bp_id) and not is_blueprint_approved(bp_id):
			var bp = known_blueprints[bp_id]
			var bp_season = bp.get("season", current_season)
			var bp_pillar = bp.get("pillar", 1)
			var is_next_season = bp_season > current_season
			var is_current_p2  = bp_pillar == 2 and bp_season == current_season
			if is_next_season or is_current_p2:
				tasks.append("📐 Blueprint ready: '%s' — submit to WRA for approval." % bp.get("name", bp_id))
				break

	## 8b: WRA-approved blueprints waiting to be manufactured
	var unqueued_approvals = wra_approved_blueprints.filter(func(app):
		for job in cnc_production_queue:
			if job.get("blueprint_id","") == app.blueprint_id: return false
		return true)
	if not unqueued_approvals.is_empty():
		var bp = known_blueprints.get(unqueued_approvals[0].blueprint_id, {})
		tasks.append("⚙ WRA approved: '%s' — queue manufacturing in CNC Plant." % bp.get("name", unqueued_approvals[0].blueprint_id))

	## 8c: CNC parts in inventory not yet installed on any car
	for inv_key in cnc_parts_inventory:
		var item = cnc_parts_inventory[inv_key]
		var qty = item.get("quantity", 0) if item is Dictionary else int(item)
		if qty > 0:
			var part = item.get("part", inv_key) if item is Dictionary else inv_key
			## Check if already installed on every car
			var all_installed = true
			for car in player_team_cars:
				if car.championship_id == item.get("championship_id",""):
					var inst = get_installed_parts_for_car(car.id)
					var pcode = item.get("part_code","") if item is Dictionary else ""
					if pcode == "" or not pcode in inst:
						all_installed = false
						break
			if not all_installed:
				tasks.append("🔩 CNC part in warehouse: %s — install it in Garage." % part)
				break  ## One reminder per week

	## Step 9 — New game: no car bought yet, no championships active
	if player_team_cars.is_empty() and active_championships.size() <= 1 \
			and player_registered_championships.is_empty():
		tasks.append("🏎 Welcome! Buy your first car at the Logistics Center to get started.")

	return tasks.filter(func(t): return not t in dismissed_todo_items)

func dismiss_todo_item(item_text: String) -> void:
	if not item_text in dismissed_todo_items:
		dismissed_todo_items.append(item_text)
	emit_signal("log_updated")

func clear_dismissed_todo_items() -> void:
	dismissed_todo_items.clear()
	emit_signal("log_updated")

## Weekly pit crew fitness recovery.
func _recover_pit_crew_fitness() -> void:
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.role == "Pit Crew" and staff.contract_team == player_team.id:
			staff.fitness = min(100.0, staff.fitness + 8.0)

## ═══════════════════════════════════════════════════════════════════════════
## CAR CONDITION SYSTEM (now Car-object based)
## ═══════════════════════════════════════════════════════════════════════════

func _setup_car_conditions() -> void:
	## Legacy stub — car conditions now live on Car objects via _setup_cars().
	## Kept to avoid breaking any remaining references during transition.
	pass

## Public entry point — called by RaceResults._on_continue().
## Repairs applied on exit so RaceResults shows true post-race damage.
## Returns true if any active championship has at least one race remaining this season.
func has_remaining_races_this_season() -> bool:
	for champ in active_championships:
		var next_race = champ.get_next_race()
		if not next_race.is_empty():
			return true
	return false

func apply_post_race_repairs() -> void:
	_auto_repair_cars_post_race()

func _degrade_car_conditions(laps: int, dns_driver_ids: Array = []) -> void:
	var loss = active_championship.condition_loss_per_lap * float(laps)
	for car in player_team_cars:
		if car.driver_id == "" or car.driver_id in dns_driver_ids:
			add_log("🔩 Car %d condition unchanged (DNS)" % car.car_number)
			continue
		car.condition = max(0.0, car.condition - loss)
		## Degrade per-part condition for CNC installed parts
		if car.id in car_installed_parts:
			for pcode in car_installed_parts[car.id]:
				var pd = car_installed_parts[car.id][pcode]
				pd["condition"] = max(0.0, pd.get("condition", 100.0) - loss)
				if pd["condition"] <= 0.0:
					add_notification("Critical",
						"🔩 %s TERMINAL DAMAGE on %s! Slot empty — car cannot race." % [
						pcode, car.car_name if car.car_name != "" else "Car %d" % car.car_number])
					car_installed_parts[car.id].erase(pcode)
		## Degrade per-part condition for provider parts
		if car.id in car_provider_parts:
			for pcode in car_provider_parts[car.id].keys():
				var pd = car_provider_parts[car.id][pcode]
				pd["condition"] = max(0.0, pd.get("condition", 100.0) - loss)
				if pd["condition"] <= 0.0:
					add_notification("Critical",
						"🔩 %s TERMINAL DAMAGE on %s! Slot empty — buy provider parts at Logistics." % [
						pcode, car.car_name if car.car_name != "" else "Car %d" % car.car_number])
					car_provider_parts[car.id].erase(pcode)
		add_log("🔩 Car %d condition after race: %.0f%% (−%.1f%% over %d laps)" % [
			car.car_number, car.condition, loss, laps])

func _auto_repair_cars_post_race() -> void:
	if player_team_cars.is_empty():
		return

	## Do not auto-repair after the last race of the season (Bugs doc)
	## Check if there are any more races remaining after this one
	if not has_remaining_races_this_season():
		add_log("🔧 Season's last race — no auto-repair. Cars will be serviced in the off-season.")
		return

	var sp_rate = active_championship.sp_per_10_pct_damage
	var any_failed = false
	var failed_car_names: Array = []

	for car in player_team_cars:
		var damage = 100.0 - car.condition
		if damage <= 0.0:
			continue

		# No mechanic = no repair
		if car.mechanic_id == "":
			add_notification("High",
				"Car %d cannot be repaired — no Race Mechanic assigned!" % car.car_number)
			any_failed = true
			failed_car_names.append("Car %d (no mechanic)" % car.car_number)
			continue

		var sp_needed = int(ceil(damage / 10.0) * sp_rate)

		if spare_parts >= sp_needed:
			spare_parts -= sp_needed
			car.condition = 100.0
			add_log("🔧 Car %d auto-repaired to 100%% (-%d SP, %d remaining)" % [
				car.car_number, sp_needed, spare_parts])
		elif spare_parts > 0:
			var repair_pct = float(spare_parts) / float(sp_rate) * 10.0
			car.condition = min(100.0, car.condition + repair_pct)
			add_log("🔧 Car %d partial repair: %.0f%% condition (SP exhausted)" % [
				car.car_number, car.condition])
			spare_parts = 0
			any_failed = true
			failed_car_names.append("Car %d" % car.car_number)
		else:
			any_failed = true
			failed_car_names.append("Car %d" % car.car_number)

	if any_failed:
		var names = ", ".join(failed_car_names)
		add_notification("Critical" if spare_parts == 0 else "High",
			"SP insufficient to fully repair %s. Buy more SP at Logistics Center." % names)
	# Resource warning notifications are fired by _consume_race_resources()
	# which always runs after this function — no need to call here.

func repair_car(driver_id: String, repair_pct: float) -> bool:
	var car = get_car_for_driver(driver_id)
	if not car:
		return false
	var current = car.condition
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
	car.condition = min(100.0, current + actual_repair)
	add_log("🔧 Manual repair +%.0f%% → %.0f%% condition (-%d SP, %d remaining)" % [
		actual_repair, car.condition, sp_cost, spare_parts])
	emit_signal("log_updated")
	return true

func repair_car_full(driver_id: String) -> bool:
	var car = get_car_for_driver(driver_id)
	if not car:
		return false
	var damage = 100.0 - car.condition
	if damage <= 0.0:
		add_notification("Normal", "Car is already at full condition.")
		return false
	return repair_car(driver_id, damage)


## DNS check — returns true if the car CAN race, false if DNS.
func _can_car_race(driver_id: String) -> bool:
	var car = get_car_for_driver(driver_id)

	# DNS: no fuel
	var fuel_needed = active_championship.fuel_per_car_per_race
	if fuel_kg < fuel_needed:
		add_notification("Critical",
			"DNS: Not enough fuel (%.1f kg). Need %.1f kg. Buy fuel at Logistics Center." % [
				fuel_kg, fuel_needed])
		add_log("🚫 DNS — Insufficient fuel for race start.")
		return false

	if car == null:
		return false

	# DNS: no race mechanic
	if car.mechanic_id == "":
		add_notification("Critical",
			"DNS: %s has no Race Mechanic! Assign one in the Garage before racing." % (car.car_name if car.car_name != "" else "Car %d" % car.car_number))
		add_log("🚫 DNS — No Race Mechanic on %s." % (car.car_name if car.car_name != "" else "Car %d" % car.car_number))
		return false

	# DNS: no pit crew for non-GK championships
	if get_pit_crew_required(car.championship_id):
		if car.pit_crew_id == "" or car.pit_crew_id == "N/A":
			add_notification("Critical",
				"DNS: %s has no Pit Crew! Assign one in the Pit Crew Arena before racing." % (car.car_name if car.car_name != "" else "Car %d" % car.car_number))
			add_log("🚫 DNS — No Pit Crew on %s." % (car.car_name if car.car_name != "" else "Car %d" % car.car_number))
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

## Returns the scaled upgrade cost for the next level.
## Formula: base_cost * 1.5^current_level, rounded to nearest CR 500.
## ── Championship Registration ────────────────────────────────────────────────

## Returns true if the player can still register for a championship this season.
func can_register_for_championship(champ_id: String) -> bool:
	if champ_id in player_registered_championships:
		return false  # already registered
	var deadline = get_entry_deadline_week(champ_id)
	if current_week > deadline:
		return false  # missed deadline
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	if reg.is_empty():
		return false
	var fee = reg.get("entry_fee", 0)
	if player_team.balance < fee:
		return false  # can't afford
	return true

## Register the player for a championship. Deducts one-time entry fee.
## Returns true on success, false with notification on failure.
func register_for_championship(champ_id: String) -> bool:
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	if reg.is_empty():
		add_notification("High", "Unknown championship ID: %s" % champ_id)
		return false
	if champ_id in player_registered_championships:
		add_notification("Normal", "Already registered for %s." % reg["name"])
		return false
	var deadline = get_entry_deadline_week(champ_id)
	if current_week > deadline:
		add_notification("High", "Registration deadline for %s passed (Week %d)." % [reg["name"], deadline])
		return false
	var fee = reg.get("entry_fee", 0)
	if player_team.balance < fee:
		add_notification("High", "Cannot afford entry fee for %s (need CR %s)." % [
			reg["name"], _fmt_int(fee)])
		return false
	player_team.balance -= fee
	player_registered_championships.append(champ_id)
	add_log("✅ Registered for %s — Entry fee: CR %s" % [reg["name"], _fmt_int(fee)])

	# ── Requirements advisory ─────────────────────────────────────────────────
	# Check if the team can actually field a car. Warn but never block registration.
	# No refunds if requirements aren't met before Race 1 — DNS applies.
	var warnings: Array = []
	var delivery_wk = get_car_delivery_week(champ_id)
	var car_cost    = get_provider_car_cost(champ_id)

	if player_team_cars.size() == 0 and player_team.balance < car_cost:
		warnings.append("⚠ No car and insufficient funds (need CR %s for a %s car)" % [
			_fmt_int(car_cost), reg["name"]])
	elif player_team_cars.size() == 0:
		warnings.append("🏎 No car yet — buy one from Logistics before Week %d" % delivery_wk)

	if player_team.drivers.is_empty():
		warnings.append("👤 No drivers signed — hire a driver eligible for %s (age %d–%s)" % [
			reg["name"], reg["min_age"],
			str(reg["max_age"]) if reg["max_age"] < 99 else "+"])

	var mechs = get_player_staff_by_role("Race Mechanic")
	if mechs.is_empty():
		warnings.append("🔧 No Race Mechanic — DNS risk without one assigned to each car")

	if reg["discipline"] != "GK":
		var strats = get_player_staff_by_role("Race Strategist")
		if strats.is_empty():
			warnings.append("📡 No Race Strategist — recommended for non-GK championships")

	if not warnings.is_empty():
		var warn_text = "Registered for %s. ⚠ ADVISORY — DNS risk if unresolved before Race 1 (no refunds):\n" % reg["name"]
		warn_text += "\n".join(warnings)
		add_notification("High", warn_text)
	else:
		add_notification("Normal", "Registered for %s. Buy/build a car before Week %d." % [
			reg["name"], delivery_wk])

	## ── Blueprint design reminder ─────────────────────────────────────────────
	var next_season = current_season + 1
	var is_formula = champ_id in ["C-021","C-022","C-023","C-024"]
	var code = CHAMP_CODES.get(champ_id, "")
	## Check if any next-season L1 blueprints are already done for this championship
	var has_any_next_bp = false
	for bp_id in completed_rnd_tasks:
		if bp_id.begins_with("BP-%s-" % code) and "S%d-L1" % next_season in bp_id:
			has_any_next_bp = true
			break
	if not has_any_next_bp:
		if is_formula:
			add_notification("Critical",
				"🚨 You registered for %s Season %d. Formula teams MUST design a new car each season. Start designing Season %d blueprints in the R&D Design Studio — P1 DESIGN tab." % [
					reg["name"], next_season, next_season],
				"rnd_studio")
		else:
			## Only warn about WRA reset if actually approaching — compute based on next_season
			var wra_group = _get_wra_group_for_championship(champ_id)
			if wra_group != "":
				var wra_len = {"Formula":4,"Touring":5,"Karting":6,"Open Wheel":7,
					"Stock Car":8,"Rally":9,"Endurance":10}.get(wra_group, 6)
				var wra_start = wra_cycle_starts.get(wra_group, 1)
				## Use next_season (what they're registering for) to compute distance to reset
				var seasons_in_cycle = (next_season - wra_start) % wra_len
				var seasons_until_reset = wra_len - seasons_in_cycle
				## Only notify when the registered season itself is in the last 2 of the cycle
				if seasons_until_reset <= 2 and seasons_in_cycle > 0:
					add_notification("High",
						"⚠ WRA regulation reset for %s in %d season%s. Consider designing Season %d blueprints now before your current ones are wiped." % [
							wra_group, seasons_until_reset,
							"s" if seasons_until_reset != 1 else "",
							next_season],
						"rnd_studio")

	emit_signal("log_updated")
	return true

## Championship registrations are final — no withdrawals once entered.
## Teams are contractually bound to participate. DNS applies if requirements aren't met.
func unregister_from_championship(_champ_id: String) -> void:
	add_notification("High",
		"Championship registrations are binding. Teams cannot withdraw once entered. DNS applies if car/driver requirements are not met.")

## Returns all championship IDs the player is currently registered for next season.
## Does NOT include already-running championships (those are in active_championships).
func get_pending_registrations() -> Array:
	var pending = []
	for cid in player_registered_championships:
		var already_running = false
		for champ in active_championships:
			if champ.id == cid:
				already_running = true
				break
		if not already_running:
			pending.append(cid)
	return pending

## Helper: format int with comma thousands separator
func _get_wra_group_for_championship(cid: String) -> String:
	const CID_TO_GROUP = {
		"C-001":"Karting","C-002":"Karting","C-003":"Karting","C-004":"Karting",
		"C-005":"Rally","C-006":"Rally","C-007":"Rally","C-008":"Rally",
		"C-009":"Touring","C-010":"Touring",
		"C-011":"Open Wheel","C-012":"Open Wheel","C-013":"Open Wheel",
		"C-014":"Stock Car","C-015":"Stock Car","C-016":"Stock Car","C-017":"Stock Car",
		"C-018":"Endurance","C-019":"Endurance","C-020":"Endurance",
		"C-021":"Formula","C-022":"Formula","C-023":"Formula","C-024":"Formula",
	}
	return CID_TO_GROUP.get(cid, "Karting")

## Shared weekly expense total (staff + drivers + building maintenance)
func get_weekly_expenses() -> float:
	var total = 0.0
	for s_id in all_staff:
		var s = all_staff[s_id]
		if s.contract_team == player_team.id:
			total += s.weekly_salary
	## Use per-driver negotiated salary; fall back to championship rate
	for driver_id in player_team.drivers:
		var driver = all_drivers.get(driver_id)
		if driver == null: continue
		total += driver.weekly_salary if driver.weekly_salary > 0 \
				else _get_championship_driver_salary()
	for bname in campus_buildings:
		var b = campus_buildings[bname]
		if b.get("level", 0) > 0:
			total += b.get("weekly_maintenance", 0)
	return total

## Runway in weeks at current expense rate
func get_runway_weeks() -> int:
	var bal = player_team.balance
	if bal <= 0: return 0
	var weekly = get_weekly_expenses()
	if weekly <= 0: return 999
	return int(bal / weekly)

## Remove notifications containing a substring
func _clear_notifications_containing(substring: String) -> void:
	notifications = notifications.filter(func(n): return not substring in n["message"])
	unread_notification_count = 0
	for n in notifications:
		if not n["read"]: unread_notification_count += 1
	emit_signal("notifications_updated")

## Small chance of sponsor approach after a good race
func _maybe_generate_race_sponsor_offer(player_position: int) -> void:
	var chance = 0.0
	if player_position == 1:   chance = 0.30
	elif player_position <= 3: chance = 0.15
	elif player_position <= 5: chance = 0.05
	if chance <= 0.0 or randf() > chance: return
	var max_tier = _get_sponsor_tier_for_team()
	var offer = _generate_sponsor_offer(randi_range(1, 2), randi_range(1, max_tier))
	offer.expires_season = current_season + 1
	sponsor_offers.append(offer)
	add_notification("Normal",
		"Your P%d finish attracted %s — sponsor offer received." % [player_position, offer.name],
		"hq")

func _fmt_int(n: int) -> String:
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

## Sells a building — refunds 30% of build cost, resets to unbuilt state.
## Staff assigned to this building are unassigned but not fired.
func sell_building(building_id: String) -> void:
	var building = campus_buildings.get(building_id, {})
	if building.is_empty() or not building["built"]:
		return
	var refund = int(building["build_cost"] * 0.3)
	player_team.balance += refund
	building["built"] = false
	building["level"] = 0
	building["construction_weeks_remaining"] = 0
	add_log("🏚 %s sold — CR %s refunded (30%% of build cost)." % [building["name"], _fmt_int(refund)])
	add_notification("Normal", "%s sold for CR %s." % [building["name"], _fmt_int(refund)])
	emit_signal("log_updated")

## Returns true if the player has a blueprint (completed R&D) for a part type.
func has_blueprint(part: String) -> bool:
	for tid in completed_rnd_tasks:
		var t = RND_TASKS.get(tid, {})
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
		add_notification("High", "No blueprint for %s. Research it in R&D Studio first." % part)
		return false
	var building = campus_buildings.get("CNC Parts Plant", {})
	if not building.get("built", false):
		add_notification("High", "CNC Parts Plant not built.")
		return false
	var cnc = CNC_DATA.get(champ_id, CNC_DATA.get("C-001", {}))
	var base_cost = cnc.get("base_total_cost", 10000)
	# Part cost: fraction of full car cost (Aero 20%, Engine 35%, Chassis 25%, others 10%)
	const PART_COST_RATIO = {"Aero":0.20,"Engine":0.35,"Chassis":0.25,
		"Gearbox":0.08,"Brakes":0.06,"Suspension":0.06}
	var unit_cost = int(base_cost * PART_COST_RATIO.get(part, 0.10) * float(quantity))
	if player_team.balance < unit_cost:
		add_notification("High", "Insufficient funds for CNC production. Need CR %s." % _fmt_int(unit_cost))
		return false
	# Manufacture time: design_weeks scaled by part complexity
	const PART_TIME_RATIO = {"Aero":0.4,"Engine":0.6,"Chassis":0.5,
		"Gearbox":0.25,"Brakes":0.2,"Suspension":0.25}
	var weeks = max(1, int(cnc.get("design_weeks", 4) * PART_TIME_RATIO.get(part, 0.3) * quantity))
	player_team.balance -= unit_cost
	cnc_production_queue.append({
		"id":        "%s_%s_%d" % [part, champ_id, current_week],
		"part":      part,
		"championship_id": champ_id,
		"weeks_total":     weeks,
		"weeks_remaining": weeks,
		"cr_cost":         unit_cost,
		"quantity":        quantity,
	})
	add_log("⚙ CNC production started: %dx %s for %s (%d wks)" % [
		quantity, part, CHAMPIONSHIP_REGISTRY.get(champ_id,{}).get("name", champ_id), weeks])
	add_notification("Normal", "CNC: %dx %s in production. Ready in %d weeks." % [quantity, part, weeks])
	emit_signal("log_updated")
	return true

## Called each advance_week — ticks CNC production queue.
func _advance_cnc_production() -> void:
	var finished = []
	for job in cnc_production_queue:
		job["weeks_remaining"] -= 1
		if job["weeks_remaining"] <= 0:
			finished.append(job)
	for job in finished:
		cnc_production_queue.erase(job)
		var part   = job.get("part", "")
		var pcode  = job.get("part_code", "")
		var cid    = job.get("championship_id", "")
		var qty    = job.get("quantity", 1)
		var rel    = job.get("reliability", 60.0)
		var qual   = job.get("quality", 1.0)
		var bp_id  = job.get("blueprint_id", "")
		## Store using canonical key: "CHAMP_ID|PCODE"
		var inv_key = _cnc_inv_key(cid, pcode) if (cid != "" and pcode != "") else part
		if inv_key in cnc_parts_inventory:
			cnc_parts_inventory[inv_key]["quantity"] += qty
		else:
			cnc_parts_inventory[inv_key] = {
				"quantity":       qty,
				"reliability":    rel,
				"quality":        qual,
				"blueprint_id":   bp_id,
				"part":           part,
				"part_code":      pcode,
				"championship_id": cid,
			}
		## Remove from wra_approved_blueprints so TDL step 8b clears
		wra_approved_blueprints = wra_approved_blueprints.filter(
			func(app): return app.get("blueprint_id","") != bp_id)
		add_log("✅ CNC complete: %dx %s (%s) — Rel:%.0f%% Qual:%.2f× → warehouse." % [
			qty, part, pcode, rel, qual])
		add_notification("High",
			"CNC complete: %dx %s ready in warehouse. Go to Garage to install it." % [qty, part],
			"garage")
	if not finished.is_empty():
		emit_signal("log_updated")

## Assigns a CNC-manufactured part from inventory to a specific car.
func assign_cnc_part_to_car(car_id: String, part: String) -> bool:
	var car = null
	for c in player_team_cars:
		if c.id == car_id: car = c; break
	if car == null:
		add_notification("High", "Car not found: %s" % car_id)
		return false
	var available = cnc_parts_inventory.get(part, 0)
	if available <= 0:
		add_notification("High", "No %s in CNC inventory. Manufacture one first." % part)
		return false
	cnc_parts_inventory[part] = available - 1
	if cnc_parts_inventory[part] <= 0:
		cnc_parts_inventory.erase(part)
	if not car_id in car_installed_parts:
		car_installed_parts[car_id] = {}
	car_installed_parts[car_id][part] = car_installed_parts[car_id].get(part, 0) + 1
	var cname = car.car_name if car.car_name != "" else "Car %d" % car.car_number
	add_log("🔩 %s CNC part installed on %s." % [part, cname])
	add_notification("Normal", "%s CNC part installed on %s." % [part, cname])
	emit_signal("log_updated")
	return true

## Removes a CNC part from a car and returns it to inventory.
func remove_cnc_part_from_car(car_id: String, part: String) -> bool:
	if not car_id in car_installed_parts: return false
	var installed = car_installed_parts[car_id]
	if not part in installed or installed[part] <= 0: return false
	installed[part] -= 1
	if installed[part] <= 0: installed.erase(part)
	cnc_parts_inventory[part] = cnc_parts_inventory.get(part, 0) + 1
	var car = null
	for c in player_team_cars:
		if c.id == car_id: car = c; break
	var cname = car.car_name if car and car.car_name != "" else "Car"
	add_log("🔩 %s CNC part removed from %s → back to inventory." % [part, cname])
	emit_signal("log_updated")
	return true

## Returns a lap-time improvement fraction (0.0–0.08) for a car based on CNC parts installed.
func get_cnc_part_bonus(car_id: String) -> float:
	var installed = car_installed_parts.get(car_id, {})
	if installed.is_empty(): return 0.0
	var total = 0.0
	for part in installed:
		var qty: int = installed[part]
		total += 0.005
		if qty > 1: total += (qty - 1) * 0.002
	return clamp(total, 0.0, 0.08)

## ── CNC Blueprint-based manufacturing (WRA-gated) ────────────────────────────

## Key format for cnc_parts_inventory: "CHAMP_ID|PCODE"
## Each value: { quantity, reliability, quality, blueprint_id }

func _cnc_inv_key(champ_id: String, pcode: String) -> String:
	return "%s|%s" % [champ_id, pcode]

## Compute manufacturing weeks from a blueprint (Formula doc §3).
func get_cnc_manufacturing_weeks(blueprint_id: String, extra_weeks: int = 0) -> int:
	var bp = known_blueprints.get(blueprint_id, {})
	var cid = bp.get("championship_id", "C-001")
	var part = bp.get("part", "Aero")
	var cnc = CNC_DATA.get(cid, CNC_DATA.get("C-001", {}))
	const TIME_RATIO = {"Aero":0.4,"Engine":0.6,"Chassis":0.5,
		"Gearbox":0.25,"Brakes":0.2,"Suspension":0.25}
	var base = max(1, int(cnc.get("design_weeks", 4) * TIME_RATIO.get(part, 0.3)))
	return base + extra_weeks

## Compute manufacturing CR from a blueprint.
func get_cnc_manufacturing_cr(blueprint_id: String, quantity: int = 1, extra_cr: int = 0) -> int:
	var bp = known_blueprints.get(blueprint_id, {})
	var cid = bp.get("championship_id", "C-001")
	var part = bp.get("part", "Aero")
	var cnc = CNC_DATA.get(cid, CNC_DATA.get("C-001", {}))
	const COST_RATIO = {"Aero":0.20,"Engine":0.35,"Chassis":0.25,
		"Gearbox":0.08,"Brakes":0.06,"Suspension":0.06}
	var unit = int(cnc.get("base_total_cost", 10000) * COST_RATIO.get(part, 0.10))
	return unit * quantity + extra_cr

## Compute final reliability (Formula doc §3).
## Base_Reliability = 60 + (seasons_since_wra_reset * 10), capped at 100.
func calculate_final_reliability(blueprint_id: String, extra_cr: int = 0, extra_weeks: int = 0) -> float:
	var bp = known_blueprints.get(blueprint_id, {})
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
		"Karting":["C-001","C-002","C-003","C-004"],
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
			return ((current_season - 1) % cycle) + 1
	return 1

## Start a WRA-approved blueprint CNC job. Called from CNCPlant.
func start_cnc_job(blueprint_id: String, quantity: int = 1,
		extra_cr: int = 0, extra_weeks: int = 0) -> bool:
	if not is_blueprint_approved(blueprint_id):
		add_notification("High", "Blueprint not WRA-approved. Submit it at the WRA Office in HQ first.")
		return false
	var building = campus_buildings.get("CNC Parts Plant", {})
	if not building.get("built", false):
		add_notification("High", "CNC Parts Plant not built.")
		return false
	var total_cr = get_cnc_manufacturing_cr(blueprint_id, quantity, extra_cr)
	if player_team.balance < total_cr:
		add_notification("High", "Insufficient funds. Need CR %s." % _fmt_int(total_cr))
		return false
	var weeks = get_cnc_manufacturing_weeks(blueprint_id, extra_weeks)
	var reliability = calculate_final_reliability(blueprint_id, extra_cr, extra_weeks)
	var bp = known_blueprints[blueprint_id]
	var quality = bp.get("quality", 1.0)
	player_team.balance -= total_cr
	cnc_production_queue.append({
		"id":            "%s_q%d" % [blueprint_id, current_week],
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
	add_log("⚙ CNC job queued: %dx %s — %dwks, CR %s, Rel %.0f%%, Qual %.2f×" % [
		quantity, bp.get("name", blueprint_id), weeks, _fmt_int(total_cr), reliability, quality])
	add_notification("Normal", "CNC: %dx %s in production. Ready in %d weeks." % [
		quantity, bp.get("part", blueprint_id), weeks])
	emit_signal("log_updated")
	return true

## Returns the installed CNC parts dict for a car.
## Format: { "AER": {reliability, quality, blueprint_id}, ... }
func get_installed_parts_for_car(car_id: String) -> Dictionary:
	return car_installed_parts.get(car_id, {})

## Install a CNC part from inventory onto a car.
func install_part_on_car(car_id: String, champ_id: String, pcode: String) -> bool:
	var inv_key = _cnc_inv_key(champ_id, pcode)
	if not inv_key in cnc_parts_inventory:
		add_notification("High", "No %s in CNC inventory." % pcode)
		return false
	var item = cnc_parts_inventory[inv_key]
	if item.get("quantity", 0) <= 0:
		add_notification("High", "No %s in CNC inventory." % pcode)
		return false
	var car = null
	for c in player_team_cars:
		if c.id == car_id: car = c; break
	if car == null: return false
	item["quantity"] -= 1
	if item["quantity"] <= 0:
		cnc_parts_inventory.erase(inv_key)
	if not car_id in car_installed_parts:
		car_installed_parts[car_id] = {}
	car_installed_parts[car_id][pcode] = {
		"reliability":  item.get("reliability", 60.0),
		"quality":      item.get("quality", 1.0),
		"blueprint_id": item.get("blueprint_id", ""),
		"part":         item.get("part", ""),
	}
	var cname = car.car_name if car.car_name != "" else "Car %d" % car.car_number
	add_log("🔩 %s CNC part installed on %s. Rel:%.0f%% Qual:%.2f×" % [
		pcode, cname, item.get("reliability", 60.0), item.get("quality", 1.0)])
	add_notification("Normal", "%s installed on %s." % [pcode, cname])
	emit_signal("log_updated")
	return true

## Remove a CNC part from a car and return it to inventory.
func remove_part_from_car(car_id: String, pcode: String) -> bool:
	if not car_id in car_installed_parts: return false
	var installed = car_installed_parts[car_id]
	if not pcode in installed: return false
	var part_data = installed[pcode]
	installed.erase(pcode)
	var car = null
	for c in player_team_cars:
		if c.id == car_id: car = c; break
	## Return to inventory
	var champ_id = car.championship_id if car else part_data.get("championship_id", "")
	var inv_key = _cnc_inv_key(champ_id, pcode) if champ_id != "" else pcode
	if inv_key in cnc_parts_inventory:
		cnc_parts_inventory[inv_key]["quantity"] += 1
	else:
		cnc_parts_inventory[inv_key] = {
			"quantity":       1,
			"reliability": part_data.get("reliability", 60.0),
			"quality":     part_data.get("quality", 1.0),
			"blueprint_id": part_data.get("blueprint_id", ""),
			"part":         part_data.get("part", ""),
			"part_code":   pcode,
			"championship_id": champ_id,
		}
	var cname = car.car_name if car and car.car_name != "" else "Car"
	add_log("🔩 %s CNC part removed from %s → back in warehouse." % [pcode, cname])
	emit_signal("log_updated")
	return true

## Install a provider (L0) part from part_inventory into a car slot.
func install_provider_part(car_id: String, champ_id: String, pcode: String) -> bool:
	const PCODE_TO_NAME = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	var part_name = PCODE_TO_NAME.get(pcode, pcode)
	if get_part_stock(part_name, champ_id) <= 0:
		add_notification("High", "No %s provider parts in stock." % part_name)
		return false
	var car = null
	for c in player_team_cars:
		if c.id == car_id: car = c; break
	if car == null: return false
	## If a CNC part is already in this slot, remove it first (back to warehouse)
	if car_id in car_installed_parts and pcode in car_installed_parts[car_id]:
		remove_part_from_car(car_id, pcode)
	## If a provider part is already in slot, return it to stock
	if car_id in car_provider_parts and pcode in car_provider_parts[car_id]:
		part_inventory[champ_id][part_name] = part_inventory.get(champ_id, {}).get(part_name, 0) + 1
	## Deduct from stock and slot it
	part_inventory[champ_id][part_name] -= 1
	if not car_id in car_provider_parts:
		car_provider_parts[car_id] = {}
	## Provider part starts at condition based on current WRA cycle baseline
	var base_rel = _get_provider_part_base_rel(champ_id)
	car_provider_parts[car_id][pcode] = {
		"condition": 100.0,
		"reliability": base_rel,
		"quality": _get_provider_part_base_qual(champ_id),
		"part": part_name,
		"part_code": pcode,
	}
	var cname = car.car_name if car.car_name != "" else "Car %d" % car.car_number
	add_log("🔩 L0 %s provider part installed on %s." % [part_name, cname])
	emit_signal("log_updated")
	return true

## Remove a provider part from a car slot and return to stock.
func remove_provider_part(car_id: String, pcode: String) -> bool:
	if not car_id in car_provider_parts: return false
	if not pcode in car_provider_parts[car_id]: return false
	const PCODE_TO_NAME = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	var part_name = PCODE_TO_NAME.get(pcode, pcode)
	var car = null
	for c in player_team_cars:
		if c.id == car_id: car = c; break
	var champ_id = car.championship_id if car else ""
	car_provider_parts[car_id].erase(pcode)
	if champ_id != "":
		if not champ_id in part_inventory: part_inventory[champ_id] = {}
		part_inventory[champ_id][part_name] = part_inventory[champ_id].get(part_name, 0) + 1
	var cname = car.car_name if car and car.car_name != "" else "Car"
	add_log("🔩 L0 %s removed from %s → back in stock." % [part_name, cname])
	emit_signal("log_updated")
	return true

## Swap a CNC part onto a car — removes whatever is in the slot first (back to stock/inventory).
func swap_part_on_car(car_id: String, champ_id: String, pcode: String) -> bool:
	## Remove existing CNC part in slot (if any)
	if car_id in car_installed_parts and pcode in car_installed_parts[car_id]:
		remove_part_from_car(car_id, pcode)
	## Remove existing provider part in slot (if any)
	elif car_id in car_provider_parts and pcode in car_provider_parts[car_id]:
		remove_provider_part(car_id, pcode)
	## Install the new CNC part
	return install_part_on_car(car_id, champ_id, pcode)

## Get all parts for a car — merges CNC installed + provider installed.
## Returns { pcode: { type:"cnc"|"provider", rel, qual, level, part_name, condition } }
func get_all_parts_for_car(car_id: String) -> Dictionary:
	var result: Dictionary = {}
	var cnc = car_installed_parts.get(car_id, {})
	var prov = car_provider_parts.get(car_id, {})
	const PCODE_TO_NAME = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	for pcode in ["AER","ENG","GRB","SUS","BRK","CHS"]:
		if pcode in cnc:
			var d = cnc[pcode]
			var lvl = 0
			var bp_id = d.get("blueprint_id", "")
			if bp_id != "":
				lvl = known_blueprints.get(bp_id, {}).get("level", 1)
			result[pcode] = {
				"type": "cnc",
				"part_name": PCODE_TO_NAME.get(pcode, pcode),
				"level": lvl,
				"reliability": d.get("reliability", 60.0),
				"quality": d.get("quality", 1.0),
				"condition": d.get("condition", 100.0),
				"blueprint_id": bp_id,
			}
		elif pcode in prov:
			var d = prov[pcode]
			result[pcode] = {
				"type": "provider",
				"part_name": PCODE_TO_NAME.get(pcode, pcode),
				"level": 0,
				"reliability": d.get("reliability", 60.0),
				"quality": d.get("quality", 1.0),
				"condition": d.get("condition", 100.0),
				"blueprint_id": "",
			}
	return result

## Returns the provider part base reliability for a championship this season.
## Season 1 of cycle = 60, +5 per season, capped at 90.
func _get_provider_part_base_rel(champ_id: String) -> float:
	var season_in_cycle = current_season - wra_cycle_start_season
	return clamp(60.0 + season_in_cycle * 5.0, 60.0, 90.0)

## Returns the provider part base quality for a championship this season.
func _get_provider_part_base_qual(_champ_id: String) -> float:
	var season_in_cycle = current_season - wra_cycle_start_season
	return clamp(0.90 + season_in_cycle * 0.02, 0.90, 1.10)

## Returns available CNC inventory items for a given pcode + championship as array of inv_keys.
func get_cnc_stock_for_slot(champ_id: String, pcode: String) -> Array:
	const PCODE_TO_PART = {"AER":"Aero","ENG":"Engine","GRB":"Gearbox",
		"SUS":"Suspension","BRK":"Brakes","CHS":"Chassis"}
	var part_name = PCODE_TO_PART.get(pcode, pcode)
	var result: Array = []
	for inv_key in cnc_parts_inventory:
		var item = cnc_parts_inventory[inv_key]
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
	var item = cnc_parts_inventory.get(inv_key, {})
	if not item is Dictionary: return inv_key
	var bp_id = item.get("blueprint_id", "")
	var lvl = 0
	var bp_name = item.get("part", inv_key)
	if bp_id != "" and bp_id in known_blueprints:
		var bp = known_blueprints[bp_id]
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
	for bp_id in known_blueprints:
		var bp = known_blueprints[bp_id]
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
	for task in active_rnd_tasks:
		var tid = task.get("task_id", "")
		var tdata = RND_TASKS.get(tid, {})
		if tdata.get("championship_id", task.get("championship_id","")) != champ_id: continue
		var pcode = _part_name_to_pcode(tdata.get("part", ""))
		if pcode == "" or pcode not in result: continue
		result[pcode]["in_progress"].append(tid)

	## Scan WRA submissions
	for sub in active_wra_submissions:
		var bp_id = sub.get("blueprint_id", "")
		if not bp_id in known_blueprints: continue
		var bp = known_blueprints[bp_id]
		if bp.get("championship_id", "") != champ_id: continue
		var pcode = _part_name_to_pcode(bp.get("part", ""))
		if pcode == "" or pcode not in result: continue
		result[pcode]["wra_pending"].append(bp_id)

	## Scan WRA approved
	for app in wra_approved_blueprints:
		var bp_id = app.get("blueprint_id", "")
		if not bp_id in known_blueprints: continue
		var bp = known_blueprints[bp_id]
		if bp.get("championship_id", "") != champ_id: continue
		var pcode = _part_name_to_pcode(bp.get("part", ""))
		if pcode == "" or pcode not in result: continue
		result[pcode]["wra_approved"].append(bp_id)

	return result

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
func get_rnd_perf_bonus_summary() -> String:
	var parts = ["aero_perf","engine_perf","chassis_perf","gearbox_perf","brakes_perf","susp_perf"]
	var total = 0.0
	for k in parts: total += get_rnd_bonus(k)
	if total <= 0.0: return "No R&D bonuses"
	return "+%.1f%% combined part performance" % (total * 100.0)

## ── R&D System ────────────────────────────────────────────────────────────────

## Returns true if a task's prerequisite is completed AND (for Pillar 4) the linked building is at the required level.
func rnd_task_unlocked(task_id: String) -> bool:
	var task = RND_TASKS.get(task_id, {})
	if task.is_empty(): return false
	# Prerequisite task check (all pillars)
	var req = task.get("requires", "")
	if req != "" and not req in completed_rnd_tasks:
		return false
	# Pillar 4: building level gate
	if task.get("pillar", 0) == 4:
		var bname  = task.get("building", "")
		var min_lv = task.get("min_building_level", 1)
		if bname != "":
			var bld = campus_buildings.get(bname, {})
			if not bld.get("built", false) or bld.get("level", 0) < min_lv:
				return false
	return true

## Returns true if a task is already running or completed.
func rnd_task_active_or_done(task_id: String) -> bool:
	if task_id in completed_rnd_tasks: return true
	for t in active_rnd_tasks:
		if t["id"] == task_id: return true
	return false

## Starts a new R&D task. Returns false with notification on failure.
func start_rnd_task(task_id: String, designer_id: String, championship_id: String = "") -> bool:
	var task = RND_TASKS.get(task_id, {})
	if task.is_empty():
		add_notification("High", "Unknown R&D task: %s" % task_id)
		return false
	if rnd_task_active_or_done(task_id):
		add_notification("Normal", "'%s' is already researched or in progress." % task["name"])
		return false
	if not rnd_task_unlocked(task_id):
		var req = task.get("requires", "")
		add_notification("High", "Prerequisite not met: complete '%s' first." % RND_TASKS.get(req, {}).get("name", req))
		return false
	if research_points < task["rp"]:
		add_notification("High", "Not enough RP. Need %d, have %.0f." % [task["rp"], research_points])
		return false
	if player_team.balance < task["cr"]:
		add_notification("High", "Not enough CR. Need %s, have %s." % [_fmt_int(task["cr"]), _fmt_int(int(player_team.balance))])
		return false
	if not designer_id in all_staff:
		add_notification("High", "Invalid designer.")
		return false
	for t in active_rnd_tasks:
		if t["designer_id"] == designer_id:
			var other = RND_TASKS.get(t["id"], {})
			add_notification("High", "Designer already working on '%s'." % other.get("name", t["id"]))
			return false

	research_points -= task["rp"]
	player_team.balance -= task["cr"]

	active_rnd_tasks.append({
		"id":              task_id,
		"name":            task["name"],
		"pillar":          task["pillar"],
		"part":            task["part"],
		"championship_id": championship_id,
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
		var reg = CHAMPIONSHIP_REGISTRY.get(championship_id, {})
		champ_label = " [%s]" % reg.get("name", championship_id)

	add_log("🔬 R&D started: %s%s (%d weeks)" % [task["name"], champ_label, task["weeks"]])
	add_notification("Normal", "R&D started: %s%s. Est. completion: Week %d." % [
		task["name"], champ_label, current_week + task["weeks"]])
	emit_signal("log_updated")
	return true

## Cancel an active R&D task — no refund.
func cancel_rnd_task(task_id: String) -> void:
	for i in range(active_rnd_tasks.size()):
		if active_rnd_tasks[i]["id"] == task_id:
			add_log("❌ R&D cancelled: %s" % active_rnd_tasks[i]["name"])
			active_rnd_tasks.remove_at(i)
			emit_signal("log_updated")
			return

## Called each advance_week — ticks all active R&D tasks.
func _advance_rnd_tasks() -> void:
	var finished = []
	for task in active_rnd_tasks:
		task["weeks_remaining"] -= 1
		if task["weeks_remaining"] <= 0:
			finished.append(task)

	for task in finished:
		active_rnd_tasks.erase(task)
		var tid = task["id"]
		var pillar = task.get("pillar", 0)

		if not tid in completed_rnd_tasks:
			completed_rnd_tasks.append(tid)

		if pillar == 1 or pillar == 3:
			if not tid in completed_bp_tasks:
				completed_bp_tasks.append(tid)
			var bp_quality = 1.0
			if pillar == 3:
				## RE blueprint penalty: 25% quality reduction vs own design (GDD Bugs §1)
				bp_quality = 0.75
			known_blueprints[tid] = {
				"blueprint_id": tid, "name": task["name"],
				"part": task.get("part",""), "part_code": task.get("part_code",""),
				"championship_id": task.get("championship_id",""),
				"season": task.get("season", current_season),
				"level": task.get("level", 1), "pillar": pillar,
				"effect": task.get("effect_key",""), "value": task.get("effect_value", 0.0),
				"quality": bp_quality,
			}
			add_log("📋 Blueprint stored: %s → R&D + CNC database.%s" % [
				tid, " [RE: 75%% quality]" if pillar == 3 else ""])
		elif pillar == 2:
			if not tid in completed_upg_tasks:
				completed_upg_tasks.append(tid)
			known_blueprints[tid] = {
				"blueprint_id": tid, "name": task["name"],
				"part": task.get("part",""), "part_code": task.get("part_code",""),
				"championship_id": task.get("championship_id",""),
				"season": task.get("season", current_season),
				"level": task.get("level", 1), "pillar": pillar, "seasonal": true,
				"effect": task.get("effect_key",""), "value": task.get("effect_value", 0.0),
			}
			add_log("📋 Upgrade blueprint stored (Season %d only): %s → CNC." % [current_season, tid])

		_apply_rnd_effect(task)
		var champ_label = ""
		if task.get("championship_id", "") != "":
			var reg = CHAMPIONSHIP_REGISTRY.get(task["championship_id"], {})
			champ_label = " [%s]" % reg.get("name", task["championship_id"]).left(14)
		add_log("✅ R&D complete: %s%s" % [task["name"], champ_label])
		if pillar == 3:
			## RE complete — notify that WRA submission is now available AND P1 L2 is unlocked
			add_notification("High",
				"RE complete: '%s'%s. Blueprint ready — submit to WRA Office in HQ. Also unlocks P1 Design L2 for this part." % [task["name"], champ_label],
				"wra_office")
		else:
			add_notification("High", "R&D complete: '%s'%s. Submit to WRA Office in HQ to manufacture." % [task["name"], champ_label], "wra_office")
	emit_signal("log_updated")

## Applies the effect of a completed R&D task.
## Effects are stored as car_performance_bonuses — applied in race sim.
func _apply_rnd_effect(task: Dictionary) -> void:
	var key = task["effect_key"]
	var value = task["effect_value"]
	if key == "": return
	# Store as cumulative bonus — race sim reads car_performance_bonuses
	if not "rnd_bonuses" in player_team:
		player_team.set_meta("rnd_bonuses", {})
	var bonuses = player_team.get_meta("rnd_bonuses")
	bonuses[key] = bonuses.get(key, 0.0) + value
	player_team.set_meta("rnd_bonuses", bonuses)
	add_log("📈 R&D effect: %s +%.1f%%" % [key, value * 100.0])

## Returns total R&D performance bonus for a given effect key.
func get_rnd_bonus(effect_key: String) -> float:
	if not player_team.has_meta("rnd_bonuses"):
		return 0.0
	return player_team.get_meta("rnd_bonuses").get(effect_key, 0.0)

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
	## Public Racing Club: income = upkeep × 1.02, scales with level
	if bname == "Public Racing Club":
		var maintenance = get_building_maintenance(building)
		return int(maintenance * 1.02)
	# Museum: income scales with player race wins — 0 wins = 0 income
	if bname == "Museum":
		if not building.get("built", false):
			return 0
		var team_wins = 0
		for entry in hall_of_fame:
			if entry.get("team_id", "") == player_team.id:
				team_wins += 1
		if team_wins == 0:
			return 0
		var base = building["weekly_income"]
		var per_level = BUILDING_INCOME_PER_LEVEL.get("Museum", 380)
		var level_income = base + per_level * max(0, building["level"] - 1)
		return int(level_income * (1.0 + team_wins * 0.1))
	if bname in TRACK_BUILDINGS:
		var prc = campus_buildings.get("Public Racing Club", {})
		if not prc.get("built", false):
			return 0
		var level     = building["level"]
		var base      = building["weekly_income"]
		var per_level = BUILDING_INCOME_PER_LEVEL.get(bname, 0)
		var raw_income = base + per_level * max(0, level - 1)
		# PRC level bonus: +10% per PRC level
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
func get_drivers_per_car(champ_id: String) -> int:
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var disc = reg.get("discipline", "GK")
	return DRIVERS_PER_CAR.get(disc, 1)

## Returns whether a pit crew is required per car for a given championship.
func get_pit_crew_required(champ_id: String) -> bool:
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var disc = reg.get("discipline", "GK")
	return PIT_CREW_REQUIRED.get(disc, true)

func get_hq_marketability_bonus() -> float:
	var hq = campus_buildings.get("Headquarters", {})
	if not hq.get("built", false): return 0.0
	return float(hq.get("level", 1))

## TP slots = 1 per HQ level (level 1 = 1 slot, level 5 = 5 slots)
func get_hq_tp_slots() -> int:
	var hq = campus_buildings.get("Headquarters", {})
	if not hq.get("built", false): return 1
	return max(1, hq.get("level", 1))

func get_hq_sponsor_slots() -> int:
	var hq = campus_buildings.get("Headquarters", {})
	if not hq.get("built", false): return 1
	return 1 + int(hq.get("level", 1) / 2)

func get_logistics_parts_discount() -> float:
	var lc = campus_buildings.get("Logistics Center", {})
	if not lc.get("built", false): return 1.0
	return max(0.5, 1.0 - lc.get("level", 1) * 0.01)

func get_fitness_fatigue_reduction() -> float:
	var fc = campus_buildings.get("Fitness Clinic", {})
	if not fc.get("built", false): return 0.0
	var level = fc.get("level", 1)
	return 0.10 + (level - 1) * 0.005

func get_pit_crew_time_bonus() -> float:
	var pca = campus_buildings.get("Pit Crew Arena", {})
	if not pca.get("built", false): return 0.0
	var level = pca.get("level", 1)
	return 0.1 * pow(1.01, level - 1)

func get_wind_tunnel_aero_bonus() -> float:
	var wt = campus_buildings.get("Aerodynamic Wind Tunnel", {})
	if not wt.get("built", false): return 0.0
	var level = wt.get("level", 1)
	return 0.10 + (level - 1) * 0.05

func get_ops_sim_track_knowledge_base() -> float:
	var ops = campus_buildings.get("Ops Sim & Telemetry", {})
	if not ops.get("built", false): return 0.0
	return 25.0 + float(ops.get("level", 1) - 1)

func get_racing_dept_driver_bonus() -> float:
	var rd = campus_buildings.get("Racing Department", {})
	if not rd.get("built", false): return 0.0
	return 10.0 + (rd.get("level", 1) - 1) * 5.0

func get_rnd_rp_storage_cap() -> int:
	var rnd = campus_buildings.get("R&D Design Studio", {})
	if not rnd.get("built", false): return 0
	return 800 + (rnd.get("level", 1) - 1) * 400

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
	var cost = get_upgrade_cost(building)
	var weeks = get_upgrade_time(building)
	if player_team.balance < cost:
		return
	player_team.balance -= cost
	building["construction_weeks_remaining"] = weeks
	add_log("⬆ Upgrade started: %s to Level %d (CR %d, %d weeks)" % [
		building["name"],
		building["level"] + 1,
		cost,
		weeks,
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
		# Income and maintenance continue during upgrades (level >= 1).
		if building["built"] and building["level"] >= 1:
			total_income      += get_building_income(building)
			total_maintenance += get_building_maintenance(building)
	if total_income > 0:
		player_team.balance += total_income
	player_team.balance -= total_maintenance
	## Suppressed from log — shown as part of weekly P&L summary instead

func setup_new_game(p_team_name: String, p_nationality: String, p_player_name: String,
		p_starting_budget: int = 50000,
		p_ceo_sex: String = "Male", p_ceo_age: int = 30,
		p_color_primary: Color = Color(0.85, 0.15, 0.15),
		p_color_secondary: Color = Color(0.95, 0.95, 0.95),
		p_difficulty: String = "Realistic",
		p_starting_champ: String = "C-001") -> void:
	current_week = 1
	current_season = 1
	weekly_log = []
	last_race_results = []
	hall_of_fame = []
	dismissed_todo_items = []
	active_rnd_tasks = []
	completed_rnd_tasks = []
	completed_bp_tasks  = []
	completed_upg_tasks = []
	known_blueprints    = {}
	wra_cycle_start_season = 1
	cnc_production_queue = []
	cnc_parts_inventory = {}
	car_provider_parts  = {}
	research_points = 0.0
	all_teams = []
	all_drivers = {}
	all_staff = {}
	## Assign all params BEFORE calling setup functions that depend on them
	player_name              = p_player_name
	player_team_name         = p_team_name
	player_team_nationality  = p_nationality
	ceo_sex                  = p_ceo_sex
	ceo_age                  = p_ceo_age
	team_color_primary       = p_color_primary
	team_color_secondary     = p_color_secondary
	game_difficulty          = p_difficulty
	_starting_champ_id       = p_starting_champ
	_setup_championship()
	_setup_player_team()
	player_team.balance = float(p_starting_budget)
	_generate_drivers()
	_generate_ai_teams()
	_setup_campus()
	## Sponsor system initialized — passive offers generated at season start
	## No hardcoded starting sponsor
	_setup_cars()
	_setup_part_inventory()
	_generate_available_staff(60)
	add_log("Welcome to Automotive Empire!")
	var start_champ_name = CHAMPIONSHIP_REGISTRY.get(_starting_champ_id, {}).get("name", "Championship")
	add_log("Season %d — %s" % [current_season, start_champ_name])

func _setup_championship() -> void:
	active_championships.clear()
	var cid = _starting_champ_id
	var reg = CHAMPIONSHIP_REGISTRY.get(cid, CHAMPIONSHIP_REGISTRY["C-001"])
	var champ = Championship.new()
	champ.id = cid
	champ.championship_name = reg["name"]
	champ.discipline        = reg.get("discipline", "GK")
	champ.tier              = reg.get("tier", 1)
	champ.min_age           = reg.get("min_age", 8)
	champ.max_age           = reg.get("max_age", 99)
	champ.entry_fee_per_race = float(reg.get("entry_fee", 9000)) / max(reg.get("num_races", 6), 1)
	champ.num_races          = reg.get("num_races", 6)
	champ.points_system      = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
	champ.prize_1st  = 300.0
	champ.prize_2nd  = 150.0
	champ.prize_3rd  = 75.0
	champ.sp_per_10_pct_damage   = 100
	champ.fuel_per_car_per_race  = 15.0
	champ.condition_loss_per_lap = 0.5
	champ.condition_loss_per_stage    = 0.0
	champ.repair_time_per_1pct        = 0.0
	champ.has_mid_race_repairs        = false
	champ.service_park_every_n_stages = 0
	champ.pit_stop_repair_pct         = 0.0
	champ.calendar = []
	for race in CHAMPIONSHIP_CALENDARS.get(cid, CHAMPIONSHIP_CALENDARS.get("C-001", [])):
		champ.calendar.append({
			"round": race["round"], "name": race["name"], "week": race["week"],
			"rain_probability": race["rain"], "laps": race["laps"],
			"lap_km": race.get("lap_km", 1.0), "audience": race["audience"],
		})
	active_championships.append(champ)
	player_registered_championships = []

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
	## Generates a free agent pool covering ALL championships.
	## Player starts with no driver — must hire from this pool.
	## Pool covers: GK (age 8-16), Rally/TC/OWC/SC/EPC (16-35), GP (16-35)
	## Each discipline gets ~15 free agents at varying skill levels.
	var nats = ["British","Italian","German","French","Spanish","Finnish",
		"Brazilian","Japanese","American","Australian","Dutch","Belgian",
		"Mexican","Canadian","Austrian","Swedish","Norwegian","Portuguese"]

	var driver_idx = 0

	# GK free agents — ages 8-15, 20 drivers
	for i in range(20):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.3 else "Female"
		var age = randi_range(8, 15)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "GK", 1)
		all_drivers[d.id] = d
		driver_idx += 1

	# Rally free agents — ages 17-32, 12 drivers
	for i in range(12):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.25 else "Female"
		var age = randi_range(17, 32)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "Rally", 1)
		all_drivers[d.id] = d
		driver_idx += 1

	# TC (GT) free agents — ages 18-40, 12 drivers
	for i in range(12):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.2 else "Female"
		var age = randi_range(18, 40)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "TC", 1)
		all_drivers[d.id] = d
		driver_idx += 1

	# OWC (Indy/Open Wheel) free agents — ages 16-35, 12 drivers
	for i in range(12):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.25 else "Female"
		var age = randi_range(16, 35)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "OWC", 1)
		all_drivers[d.id] = d
		driver_idx += 1

	# SC (NASCAR) free agents — ages 18-45, 12 drivers
	for i in range(12):
		var nat = ["American","Canadian","Mexican"][randi() % 3]
		var sex = "Male" if randf() > 0.15 else "Female"
		var age = randi_range(18, 45)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "SC", 1)
		all_drivers[d.id] = d
		driver_idx += 1

	# EPC (Endurance/LMP) free agents — ages 18-45, 10 drivers
	for i in range(10):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.2 else "Female"
		var age = randi_range(18, 45)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "EPC", 1)
		all_drivers[d.id] = d
		driver_idx += 1

	# GP (Formula) free agents — ages 16-35, 15 drivers
	for i in range(15):
		var nat = nats[randi() % nats.size()]
		var sex = "Male" if randf() > 0.25 else "Female"
		var age = randi_range(16, 35)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var d = _create_driver_for_discipline(
			"D-FA-%03d" % driver_idx, name_data["first"], name_data["last"],
			nat, age, sex, "GP", 1)
		all_drivers[d.id] = d
		driver_idx += 1

## Creates a driver suited for a specific discipline and tier.
## Tier 1 = entry level skills, Tier 4 = elite skills.
func _create_driver_for_discipline(id: String, first: String, last: String,
		nationality: String, age: int, sex: String,
		discipline: String, tier: int) -> Driver:
	var d = Driver.new()
	d.id = id
	d.first_name = first
	d.last_name = last
	d.nationality = nationality
	d.age = age
	d.sex = sex
	d.contract_team = ""  # free agent
	d.active_discipline = discipline
	d.discipline_change_season = current_season

	# Skill scaling: age peak 24-32, tier boosts base skills
	var age_factor = clamp(float(age - 8) / 20.0, 0.0, 1.0)
	var peak_factor = 1.0 - abs(float(age) - 28.0) / 28.0  # peaks at 28
	peak_factor = clamp(peak_factor, 0.3, 1.0)
	var tier_bonus = (tier - 1) * 15.0  # T1=0, T2=+15, T3=+30, T4=+45

	d.pace        = clamp(randf_range(20.0, 55.0) + age_factor * 30.0 + tier_bonus + peak_factor * 10.0, 5.0, 99.0)
	d.wet         = clamp(randf_range(15.0, 45.0) + age_factor * 25.0 + tier_bonus * 0.8, 5.0, 99.0)
	d.focus       = clamp(randf_range(20.0, 50.0) + age_factor * 25.0 + tier_bonus * 0.9, 5.0, 99.0)
	d.race_craft  = clamp(randf_range(15.0, 45.0) + age_factor * 30.0 + tier_bonus, 5.0, 99.0)
	d.consistency = clamp(randf_range(15.0, 45.0) + age_factor * 25.0 + tier_bonus * 0.8, 5.0, 99.0)
	d.feedback    = clamp(randf_range(20.0, 55.0) + age_factor * 20.0 + tier_bonus * 0.7, 5.0, 99.0)
	d.marketability = clamp(randf_range(5.0, 30.0) + age_factor * 15.0 + tier_bonus * 0.5, 1.0, 99.0)
	d.fitness     = randf_range(75.0, 100.0)
	d.potential   = randf_range(40.0, 95.0)
	d.aggression  = randf_range(20.0, 80.0)
	d.experience  = age_factor * 40.0
	d.morale      = 100.0

	# Discipline adaptation — good in their primary discipline, low elsewhere
	for disc in d.discipline_adaptation.keys():
		if disc == discipline:
			var starting = 5.0 + age_factor * 20.0 + tier_bonus * 0.3
			d.discipline_adaptation[disc] = clamp(starting, 1.0, 60.0)
			d.peak_adaptation[disc] = d.discipline_adaptation[disc]
		else:
			d.discipline_adaptation[disc] = 1.0
			d.peak_adaptation[disc] = 1.0

	# AI drivers start with 3 season contracts; free agents have 0
	d.contract_seasons_remaining = 3 if d.contract_team != "" else 0

	return d

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
	d.pace        = randf_range(20.0, 50.0) + age_factor * 25.0
	d.wet         = randf_range(15.0, 45.0) + age_factor * 20.0
	d.focus       = randf_range(20.0, 50.0) + age_factor * 20.0
	d.race_craft  = randf_range(15.0, 45.0) + age_factor * 25.0
	d.consistency = randf_range(15.0, 45.0) + age_factor * 20.0  # NEW
	d.feedback    = randf_range(20.0, 60.0) + age_factor * 15.0  # NEW
	d.marketability = randf_range(5.0, 25.0) + age_factor * 10.0 # NEW — low at start
	d.fitness     = randf_range(70.0, 100.0)
	d.potential   = randf_range(50.0, 95.0)
	d.aggression  = randf_range(20.0, 80.0)
	d.experience  = age_factor * 30.0
	d.morale      = 100.0

	var talent_factor = d.potential / 100.0
	var starting_gk = 5.0 + (talent_factor * 10.0) + (age_factor * 5.0)
	d.discipline_adaptation["GK"] = starting_gk
	d.peak_adaptation["GK"] = starting_gk

	return d

func _generate_ai_teams() -> void:
	## Real teams from Excel AI Teams Championship Participation Matrix.
	## Each team gets drivers appropriate for their championships.
	## Minimum cars per championship enforced.

	# Map Excel column names to championship IDs
	const TEAM_PARTICIPATION = {
		"Mercedes":    ["C-001","C-002","C-003","C-004","C-009","C-010","C-024"],
		"Ferrari":     ["C-001","C-002","C-003","C-004","C-009","C-010","C-020","C-024"],
		"McLaren":     ["C-001","C-002","C-003","C-004","C-009","C-010","C-013","C-018","C-024"],
		"Red Bull":    ["C-024"],
		"Alpine":      ["C-020","C-024"],
		"Haas":        ["C-016","C-024"],
		"Racing Bulls":["C-024"],
		"Williams":    ["C-024"],
		"Audi":        ["C-024"],
		"Cadillac":    ["C-020","C-024"],
		"Aston Martin":["C-010","C-020","C-024"],
		"Invicta":     ["C-022","C-023"],
		"Hitech":      ["C-021","C-022","C-023"],
		"Campos":      ["C-021","C-022","C-023"],
		"DAMS":        ["C-022","C-023"],
		"MP":          ["C-021","C-022","C-023"],
		"Prema":       ["C-001","C-002","C-003","C-004","C-021","C-022","C-023"],
		"Rodin":       ["C-021","C-022"],
		"ART":         ["C-021","C-022","C-023"],
		"Trident":     ["C-022","C-023"],
		"Charouz":     ["C-022","C-023"],
		"Carlin":      ["C-021","C-022","C-023"],
	}

	# Budget tiers — scales initial balance and driver quality
	const TEAM_TIER = {
		"Mercedes": 4, "Ferrari": 4, "McLaren": 4, "Red Bull": 4,
		"Alpine": 3, "Haas": 3, "Racing Bulls": 3, "Williams": 3,
		"Audi": 3, "Cadillac": 3, "Aston Martin": 3,
		"Invicta": 2, "Hitech": 2, "Campos": 2, "DAMS": 2,
		"MP": 2, "ART": 2, "Trident": 2, "Charouz": 1, "Carlin": 2,
		"Prema": 3, "Rodin": 2,
	}

	const TEAM_NAT = {
		"Mercedes": "German", "Ferrari": "Italian", "McLaren": "British",
		"Red Bull": "Austrian", "Alpine": "French", "Haas": "American",
		"Racing Bulls": "Italian", "Williams": "British", "Audi": "German",
		"Cadillac": "American", "Aston Martin": "British",
		"Invicta": "British", "Hitech": "British", "Campos": "Spanish",
		"DAMS": "French", "MP": "Dutch", "Prema": "Italian",
		"Rodin": "British", "ART": "French", "Trident": "Italian",
		"Charouz": "Czech", "Carlin": "British",
	}

	var ai_idx = 0
	for team_name in TEAM_PARTICIPATION:
		var team = Team.new()
		team.id = "T-AI-%02d" % ai_idx
		team.team_name = team_name
		team.nationality = TEAM_NAT.get(team_name, "British")
		team.is_player_team = false
		var tier = TEAM_TIER.get(team_name, 2)
		team.balance = randf_range(50000.0, 200000.0) * float(tier)
		team.reputation = 15.0 + tier * 15.0 + randf_range(-5.0, 5.0)
		team.weekly_driver_salary = 50.0 * float(tier)
		team.weekly_mechanic_salary = 200.0 + float(tier) * 100.0
		all_teams.append(team)

		# Register team in ALL their championships' standings
		var champ_ids = TEAM_PARTICIPATION[team_name]
		for champ_id in champ_ids:
			for champ in active_championships:
				if champ.id == champ_id:
					champ.team_standings[team.id] = 0

		# Generate 2 drivers per championship this team runs (age-appropriate)
		# Each driver is specific to ONE championship — no cross-contamination
		var drv_idx = 0
		for primary_champ_id in champ_ids:
			var reg = CHAMPIONSHIP_REGISTRY.get(primary_champ_id, {})
			var discipline = reg.get("discipline", "GK")
			var min_age = reg.get("min_age", 8)
			var max_age = min(reg.get("max_age", 99), min_age + 20)
			if max_age < min_age:
				max_age = min_age + 5
			# Always 2 drivers per championship for competitive grids
			for j in range(2):
				var driver_id = "D-AI-%02d-%d" % [ai_idx, drv_idx]
				var nat = NameGenerator.get_nationality_for_team(team.nationality)
				var sex = "Male" if randf() > 0.25 else "Female"
				var age = randi_range(min_age, max_age)
				var name_data = NameGenerator.get_full_name(nat, sex)
				var driver = _create_driver_for_discipline(
					driver_id, name_data["first"], name_data["last"],
					nat, age, sex, discipline, tier)
				driver.contract_team = team.id
				all_drivers[driver_id] = driver
				team.drivers.append(driver_id)
				# Add ONLY to this specific championship's standings
				for champ in active_championships:
					if champ.id == primary_champ_id:
						champ.standings[driver_id] = 0
				drv_idx += 1

		ai_idx += 1

	# Ensure GK Regional has enough drivers (minimum 15 for a good grid)
	_ensure_minimum_gk_drivers()

## Ensures GK Regional has a competitive grid (minimum 15 AI drivers).
## Generates anonymous local karting teams to fill the grid if needed.
func _ensure_minimum_gk_drivers() -> void:
	var gk_champ = null
	for champ in active_championships:
		if champ.id == "C-001":
			gk_champ = champ
			break
	if gk_champ == null:
		return

	var current_gk_count = gk_champ.standings.size()
	var needed = max(0, 15 - current_gk_count)
	if needed == 0:
		return

	var local_nats = ["British","Italian","German","French","Spanish","Finnish",
		"Brazilian","Japanese","American","Australian"]
	var local_teams_data = [
		["Karting Italia","Italian"],["Speed Academy","Spanish"],
		["Nordic Kart","Finnish"],["British Racing","British"],
		["German Motorsport","German"],["French Kart Team","French"],
		["Brazilian Speed","Brazilian"],["Japanese Racing","Japanese"],
		["USA Kart Pro","American"],
	]

	var fill_idx = 0
	var teams_used = 0
	while fill_idx < needed:
		var tdata = local_teams_data[teams_used % local_teams_data.size()]
		var team_id = "T-GK-%02d" % teams_used
		var existing_team = null
		for t in all_teams:
			if t.id == team_id:
				existing_team = t
				break
		if existing_team == null:
			var team = Team.new()
			team.id = team_id
			team.team_name = tdata[0]
			team.nationality = tdata[1]
			team.is_player_team = false
			team.balance = randf_range(20000.0, 60000.0)
			team.reputation = randf_range(5.0, 15.0)
			team.weekly_driver_salary = 50.0
			team.weekly_mechanic_salary = 200.0
			all_teams.append(team)
			gk_champ.team_standings[team.id] = 0
			existing_team = team
		teams_used += 1

		var driver_id = "D-GK-FILL-%03d" % fill_idx
		var nat = local_nats[randi() % local_nats.size()]
		var sex = "Male" if randf() > 0.3 else "Female"
		var age = randi_range(8, 14)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var driver = _create_driver_for_discipline(
			driver_id, name_data["first"], name_data["last"],
			nat, age, sex, "GK", 1)
		driver.contract_team = existing_team.id
		all_drivers[driver_id] = driver
		existing_team.drivers.append(driver_id)
		gk_champ.standings[driver_id] = 0
		fill_idx += 1

func advance_week() -> void:
	weekly_log = []
	_purge_old_notifications(2)

	# Guard: never advance past max_weeks
	if current_week >= max_weeks:
		_end_season()
		return

	current_week += 1

	## Apply any pending TP/Strategist championship assignments (queued last week)
	_apply_pending_staff_assignments()

	## Advance approach/bond/negotiation rounds
	_advance_approaches()

	## Autosave every 13 weeks — 4 rotating slots
	if current_week % 13 == 0:
		_autosave()

	## Snapshot balance before all changes for P&L calculation
	var _balance_before = player_team.balance

	# Weekly fitness recovery (drivers)
	_apply_weekly_fitness_recovery()

	# Weekly pit crew fitness recovery
	_recover_pit_crew_fitness()

	# Campus construction progress
	_update_campus_construction()

	# Campus income and maintenance
	_apply_campus_income()

	# Sponsor income
	## New sponsor system handled by _process_sponsors_weekly()

	# Full staff expenses
	_apply_weekly_expenses()

	# CFO part inventory check (weekly reminder if stock is low)
	_check_part_inventory_notifications()
	# Resource level warnings (SP, fuel) — once per week only
	_check_resource_notifications()
	# Advance R&D tasks
	_advance_rnd_tasks()
	# Advance WRA submissions
	_advance_wra_submissions()
	# Advance CNC production
	_advance_cnc_production()
	# Sponsor and CFO
	_advance_cfo_search()
	_process_sponsors_weekly()
	_process_supply_contracts_weekly()
	_update_ceo_salary()

	# Check for races this week across ALL active championships
	for champ in active_championships:
		var next_race = champ.get_next_race()
		if next_race and next_race["week"] == current_week:
			_check_race_requirements_for(champ)
			_simulate_race(next_race, champ)
	## Sponsor race bonuses handled by apply_sponsor_race_bonuses()
			champ.current_round += 1

	add_log("--- Week %d ---" % current_week)

	# ── Championship registration deadline warnings ───────────────────────────
	for champ_id in CHAMPIONSHIP_REGISTRY:
		# Skip already registered or already running
		if champ_id in player_registered_championships:
			continue
		var already_running = false
		for champ in active_championships:
			if champ.id == champ_id:
				already_running = true
				break
		if already_running:
			continue
		var deadline = get_entry_deadline_week(champ_id)
		var reg = CHAMPIONSHIP_REGISTRY[champ_id]
		if deadline == current_week + 1:
			add_notification("High",
				"⚠ LAST CHANCE: %s registration deadline is NEXT WEEK (Week %d)! Entry fee: CR %s." % [
				reg["name"], deadline, _fmt_int(reg["entry_fee"])])
		elif deadline == current_week:
			add_notification("High",
				"🚨 TODAY is the last day to register for %s! After this week the deadline is missed." % reg["name"])

	## Weekly P&L summary — single line showing net change
	var _net = player_team.balance - _balance_before
	var _runway = get_runway_weeks()
	add_log("📊 Week %d — Net: %sCR %s  |  Balance: CR %s  |  Runway: %s" % [
		current_week,
		"+" if _net >= 0 else "",
		_fmt_int(int(_net)),
		_fmt_int(int(player_team.balance)),
		"%d wks" % _runway if _runway < 999 else "Stable"])
		
	if player_team.balance < 0:
		weeks_in_negative += 1
		if weeks_in_negative >= 8 and not bankruptcy_screen_shown:
			bankruptcy_screen_shown = true
			emit_signal("bankruptcy_triggered")
	else:
		if weeks_in_negative > 0:
			add_log("✅ Balance recovered. Bankruptcy counter reset.")
			weeks_in_negative = 0

	emit_signal("week_advanced", current_week)
	emit_signal("log_updated")

func _apply_weekly_fitness_recovery() -> void:
	var fatigue_reduction = get_fitness_fatigue_reduction()
	var base_recovery = 8.0
	# Fitness Clinic reduces fatigue — means faster recovery each week
	var actual_recovery = base_recovery * (1.0 + fatigue_reduction)
	for driver_id in all_drivers:
		var driver = all_drivers[driver_id]
		driver.fitness = min(100.0, driver.fitness + actual_recovery)

func _simulate_race(race_data: Dictionary, champ: Championship = null) -> void:
	# Use provided championship or fall back to active_championship (backward compat)
	var c: Championship = champ if champ != null else active_championship
	add_log("=== RACE %d: %s [%s] ===" % [c.current_round + 1, race_data["name"], c.championship_name])

	# ── Staff Synergy Factor (simulated races only) ───────────────────────────
	# From formula doc section 4: lap_time /= Staff_Synergy_Factor
	# TP attributes multiply the corresponding Mechanic and Strategist attributes.
	# Effective_staff_attr = staff_attr × (1 + tp_matching_attr / 200)
	#   → TP skill 100 boosts staff attribute by 50%; TP skill 0 = no boost (×1.0)
	# Staff_Synergy_Factor = 1.0
	#   + (mechanic_effective_setup   / 100) × 0.08   → up to +8% at mechanic 100 + TP 100
	#   + (strategist_effective_pace  / 100) × 0.06   → up to +6% at strategist 100 + TP 100
	#   + (mechanic_track_knowledge   / 100) × 0.03   → up to +3%
	#   + (strategist_track_knowledge / 100) × 0.03   → up to +3%
	# Total possible range: 1.0 (no staff) → ~1.30 (all skills maxed with TP 100)
	# Applied only to player drivers — AI teams run at their own flat factor.
	var tp = get_team_principal()

	# Gather player's mechanic and strategist for the active championship
	# Use first assigned mechanic for now (multi-car will average later)
	var mechanic: Staff   = null
	var strategist: Staff = null
	for car in player_team_cars:
		if car.mechanic_id != "" and car.mechanic_id in all_staff:
			mechanic = all_staff[car.mechanic_id]
			break
	var strats = get_player_staff_by_role("Race Strategist")
	if strats.size() > 0:
		strategist = strats[0]

	# TP multiplier on each staff attribute (0 TP = factor 1.0, no boost)
	var tp_factor: float = 1.0
	if tp != null:
		# TP boosts each staff pool by its matching attribute / 200
		# Using race_pace_reading as the general TP race-day multiplier
		tp_factor = 1.0 + tp.race_pace_reading / 200.0

	## Get the track_id for this race — used for per-track knowledge lookups
	var current_track_id: String = race_data.get("track_id", "")

	# Effective attributes — use per-track knowledge when track_id is known
	var mech_setup:  float = 0.0
	var mech_track:  float = 0.0
	var strat_pace:  float = 0.0
	var strat_track: float = 0.0
	if mechanic != null:
		mech_setup = mechanic.car_setup * tp_factor
		## Use per-track knowledge if available, fall back to flat track_knowledge
		var mech_tk = mechanic.get_track_knowledge_for(current_track_id) \
				if current_track_id != "" else mechanic.track_knowledge
		mech_track = mech_tk * tp_factor
	if strategist != null:
		strat_pace  = strategist.race_strategy * tp_factor
		var strat_tk = strategist.get_track_knowledge_for(current_track_id) \
				if current_track_id != "" else strategist.track_knowledge
		strat_track = strat_tk * tp_factor

	# Final Staff_Synergy_Factor for player cars
	var staff_synergy: float = 1.0 \
		+ (mech_setup  / 100.0) * 0.08 \
		+ (strat_pace  / 100.0) * 0.06 \
		+ (mech_track  / 100.0) * 0.03 \
		+ (strat_track / 100.0) * 0.03

	if tp != null or mechanic != null or strategist != null:
		add_log("👥 Staff synergy: %.3f (mech %.0f, strat %.0f, TP %s)" % [
			staff_synergy,
			mech_setup if mechanic else 0.0,
			strat_pace if strategist else 0.0,
			tp.full_name() if tp else "none"])
 
	# ── DNS check: player needs a car assigned to THIS championship ──────────
	var dns_driver_ids: Array = []
	# Find player cars for this specific championship
	var cars_for_champ = player_team_cars.filter(func(car): return car.championship_id == c.id)
	if cars_for_champ.is_empty():
		# No car for this championship — all player drivers DNS
		for d_id in player_team.drivers:
			dns_driver_ids.append(d_id)
		add_log("🚫 DNS [%s]: No car assigned to this championship." % c.championship_name)
	else:
		# Check each car's race eligibility (driver, mechanic, pit crew, fuel)
		for car in cars_for_champ:
			var car_dns = false
			var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number

			if car.driver_id == "":
				add_log("🚫 DNS [%s] %s — no driver assigned." % [c.championship_name, car_label])
				car_dns = true
			elif not _can_car_race(car.driver_id):
				car_dns = true

			# Pit crew check for non-GK
			if get_pit_crew_required(c.id):
				if car.pit_crew_id == "" or car.pit_crew_id == "N/A":
					add_log("🚫 DNS [%s] %s — no Pit Crew assigned." % [c.championship_name, car_label])
					add_notification("Critical",
						"DNS: %s has no Pit Crew for %s! Assign one in Pit Crew Arena." % [
						car_label, c.championship_name])
					car_dns = true

			if car_dns and car.driver_id != "":
				dns_driver_ids.append(car.driver_id)
 
	# ── Collect all drivers, skipping DNS cars ────────────────
	var race_drivers = []
	for driver_id in c.standings:
		if driver_id in all_drivers and not driver_id in dns_driver_ids:
			race_drivers.append(all_drivers[driver_id])
 
	# Determine weather
	var is_wet = randf() * 100.0 < race_data["rain_probability"]
 
	# ── Track discipline bonus ────────────────────────────────────────────────
	# Track buildings improve pace for matching disciplines (player only, sim only).
	# GK → Karting Track: +5% base, +3%/level
	# Rally → Gravel Track: +5% base, +3%/level
	# SC/OWC → Oval Track: +5% base, +3%/level
	# GP/EPC/TC → Race Track: +3% base, +3%/level
	var track_perf_bonus: float = 0.0
	const TRACK_BONUS_MAP = {
		"GK": "Karting Track", "Rally": "Gravel Track",
		"SC": "Oval Track", "OWC": "Oval Track",
		"GP": "Race Track", "EPC": "Race Track", "TC": "Race Track",
	}
	var disc = c.discipline
	if disc in TRACK_BONUS_MAP:
		var tname = TRACK_BONUS_MAP[disc]
		var tbld  = campus_buildings.get(tname, {})
		if tbld.get("built", false):
			var tlevel = tbld.get("level", 1)
			var base_b = 0.03 if disc in ["GP", "EPC", "TC"] else 0.05
			track_perf_bonus = base_b + (tlevel - 1) * 0.03
			add_log("🏟 %s bonus: +%.0f%% pace" % [tname, track_perf_bonus * 100.0])

	# Calculate lap times
	# Formula: base_time × skill_factors + noise
	# Pace range 20-99 should produce ±1.5% lap time spread (realistic F1: ~1-2%)
	# Base time is notional seconds/lap — only differences matter for ordering
	var driver_times = []
	for driver in race_drivers:
		var base_time = 60.0  # notional seconds per lap
		var effective_pace  = driver.get_effective_pace()
		var effective_wet   = driver.get_effective_wet()
		var effective_focus = driver.get_effective_focus()

		# Pace factor: compress to ±1.5% around base (pace 60 = neutral)
		# pace 99 → ×0.985, pace 20 → ×1.015
		var pace_factor = 1.0 - ((effective_pace - 60.0) / 60.0) * 0.015
		pace_factor = clamp(pace_factor, 0.97, 1.03)

		var wet_factor = 1.0
		if is_wet:
			# Wet skill 99 = no penalty, wet skill 20 = +3% penalty
			wet_factor = 1.0 + ((100.0 - effective_wet) / 100.0) * 0.03

		# Focus: small effect ±0.5%
		var focus_factor = 1.0 - ((effective_focus - 50.0) / 50.0) * 0.005
		focus_factor = clamp(focus_factor, 0.995, 1.005)

		var fitness_factor = driver.fitness_penalty()
		# Fitness penalty max +1% for exhausted driver
		var fitness_penalty = (1.0 - fitness_factor) * 0.01

		var lap_time = base_time * pace_factor * wet_factor * focus_factor * (1.0 + fitness_penalty)

		## Driver track knowledge bonus — up to -1% for a fully known track (100 TK)
		## A driver who has raced here before is naturally quicker through confidence.
		if current_track_id != "" and driver.id in player_team.drivers:
			var driver_tk = driver.get_track_knowledge(current_track_id)
			var tk_bonus = (driver_tk / 100.0) * 0.01   ## 0→0%, 100→1%
			lap_time *= (1.0 - tk_bonus)

		# Apply Staff_Synergy_Factor for player drivers — max ±0.8%
		if driver.id in player_team.drivers:
			lap_time /= (1.0 + (staff_synergy - 1.0) * 0.5)
			var aero_bonus = get_wind_tunnel_aero_bonus()
			if aero_bonus > 0.0:
				lap_time /= (1.0 + aero_bonus * 0.5)
			if track_perf_bonus > 0.0:
				lap_time /= (1.0 + track_perf_bonus * 0.5)
			# R&D Pillar 1/2/3 part performance bonuses
			var rnd_combined = (get_rnd_bonus("aero_perf") + get_rnd_bonus("engine_perf") + get_rnd_bonus("chassis_perf")) * 0.33
			if rnd_combined > 0.0:
				lap_time /= (1.0 + rnd_combined)
			# CNC parts bonus (per-car)
			for pcar in player_team_cars:
				if pcar.driver_id == driver.id:
					var cnc_bonus = get_cnc_part_bonus(pcar.id)
					if cnc_bonus > 0.0:
						lap_time /= (1.0 + cnc_bonus)
					break

		# Lap noise: based on consistency (high = tight laps)
		# Noise range ±0.3% to ±1.0% of lap time
		var noise_pct = 0.01 - (driver.consistency / 100.0) * 0.007
		var noise = lap_time * noise_pct
		lap_time += randf_range(-noise, noise)

		driver_times.append({
			"driver": driver,
			"lap_time": lap_time,
			"total_time": lap_time * race_data["laps"],
			"points": 0
		})
 
	# Snapshot pre-race driver stats for delta display in RaceResults
	var pre_race_stats: Dictionary = {}
	for entry in driver_times:
		var d = entry["driver"]
		pre_race_stats[d.id] = {
			"pace": d.pace, "wet": d.wet, "focus": d.focus,
			"experience": d.experience, "fitness": d.fitness
		}

	# Sort by total time
	driver_times.sort_custom(func(a, b): return a["total_time"] < b["total_time"])
 
	# Award points and prizes
	var points_system = c.points_system
	for i in range(driver_times.size()):
		var entry = driver_times[i]
		var driver = entry["driver"]
		var standing_position = i + 1
		var pts = 0
 
		if i < points_system.size():
			pts = points_system[i]
			c.add_points(driver.id, pts)
			driver_times[i]["points"] = pts
 
		# Find team and award team points + prize money
		var entry_prize = 0.0
		for team in all_teams:
			if driver.id in team.drivers:
				c.add_team_points(team.id, pts)
				if standing_position == 1:
					entry_prize = c.prize_1st
				elif standing_position == 2:
					entry_prize = c.prize_2nd
				elif standing_position == 3:
					entry_prize = c.prize_3rd
				team.balance += entry_prize
				break
		driver_times[i]["prize"] = entry_prize
		driver_times[i]["is_player"] = driver.id in player_team.drivers
 
		# Update driver stats
		_update_driver_stats_after_race(driver, standing_position, race_data["laps"], is_wet, race_drivers.size(), race_data.get("track_id", ""))

		# Record stat deltas for RaceResults display
		if driver.id in pre_race_stats:
			var pre = pre_race_stats[driver.id]
			driver_times[i]["stat_deltas"] = {
				"pace": driver.pace - pre["pace"],
				"wet": driver.wet - pre["wet"],
				"focus": driver.focus - pre["focus"],
				"experience": driver.experience - pre["experience"],
				"fitness": driver.fitness - pre["fitness"],
			}
 
	# ── Update mechanic + strategist stats ───────────────────────────────────
	_update_staff_stats_after_race(race_data["laps"], race_data.get("track_id", ""))

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
	last_race_round = c.current_round + 1
	last_race_laps  = race_data["laps"]
	last_race_name  = race_data["name"]
	last_race_wet = is_wet
	last_race_results = driver_times
	last_race_championship = c.championship_name

	## Race-triggered sponsor offer
	for i in range(driver_times.size()):
		var entry = driver_times[i]
		if entry.get("dns", false): continue
		if entry["driver"].id in player_team.drivers:
			_maybe_generate_race_sponsor_offer(i + 1)
			break
	last_race_championship_id = c.id
	last_race_num_races = c.num_races

	# Snapshot current standings for display in RaceResults
	last_race_standings = c.get_standings_sorted()
 
	# Hall of fame (only if at least one car finished)
	if driver_times.size() > 0:
		# Find first non-DNS entry
		var winner = null
		for entry in driver_times:
			if not entry.get("dns", false):
				winner = entry["driver"]
				break
		if winner:
			var winner_team_id = ""
			var winner_team_name = "Unknown"
			for team in all_teams:
				if winner.id in team.drivers:
					winner_team_id = team.id
					winner_team_name = team.team_name
					break
			hall_of_fame.append({
				"season": current_season,
				"round": last_race_round,
				"championship": c.championship_name,
				"track": race_data["name"],
				"winner": winner.full_name(),
				"team": winner_team_name,
				"team_id": winner_team_id
			})
 
	# ── Car condition: degrade only cars that raced, skip DNS ────────────────
	_degrade_car_conditions(race_data["laps"], dns_driver_ids)
	# Repairs applied on Continue in RaceResults — NOT here.

	# Consume fuel and earn RP (always happens, DNS or not)
	_consume_race_resources()
	_earn_race_rp(race_data["laps"])

	# Season ends at week 52 regardless. After the last race the game
	# continues to week 52 for off-season management.
	if current_week >= max_weeks:
		_end_season()
		return

	# Switch to race results scene
	get_tree().change_scene_to_file("res://scenes/RaceResults.tscn")

func _update_driver_stats_after_race(driver: Driver, standing_position: int, laps: int, is_wet: bool, grid_size: int, track_id: String = "") -> void:
	# Fitness drops
	var fitness_drop = laps * 0.4
	driver.fitness = max(0.0, driver.fitness - fitness_drop)

	# Experience grows
	var exp_gain = randf_range(0.5, 1.5)
	driver.experience = min(100.0, driver.experience + exp_gain)

	# Consistency grows slowly with experience
	if driver.consistency < driver.potential:
		driver.consistency = min(driver.potential, driver.consistency + exp_gain * 0.15)

	# Feedback improves slightly with experience
	if driver.feedback < driver.potential:
		driver.feedback = min(driver.potential, driver.feedback + exp_gain * 0.08)

	## Per-track knowledge — driver learns this specific track each visit
	if track_id != "":
		var tk_gain = 4.0 + randf_range(0.0, 4.0)
		## Better finishing positions = more learning (focused race)
		if standing_position == 1:   tk_gain *= 1.3
		elif standing_position <= 3: tk_gain *= 1.15
		driver.update_track_knowledge(track_id, tk_gain)

	# Marketability — affected by result
	driver.update_marketability_after_race(standing_position, grid_size, false)

	# Update discipline adaptation
	var total_races = active_championship.num_races
	driver.update_adaptation_after_race(current_season, total_races)

	# Core stats improve
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


func _update_staff_stats_after_race(_laps: int, track_id: String = "") -> void:
	last_race_staff_deltas = []
	var improvement = 0.08 + randf_range(0.0, 0.12)
	for car in player_team_cars:
		if car.mechanic_id != "" and car.mechanic_id in all_staff:
			var mech = all_staff[car.mechanic_id]
			var pre_setup = mech.car_setup
			var pre_track = mech.track_knowledge
			if mech.car_setup < 100.0:
				mech.car_setup = min(100.0, mech.car_setup + improvement * 0.6)
			## Per-track knowledge: grows faster at a known track, slower at new ones
			if track_id != "":
				mech.update_track_knowledge(track_id, improvement * 6.0)
			elif mech.track_knowledge < 100.0:
				## Fallback: flat growth (legacy path, no track_id)
				mech.track_knowledge = min(100.0, mech.track_knowledge + improvement * 0.4)
			var d_setup = mech.car_setup - pre_setup
			var d_track = mech.track_knowledge - pre_track
			if d_setup > 0.01 or d_track > 0.01:
				last_race_staff_deltas.append({
					"name": mech.full_name(), "role": "Race Mechanic",
					"deltas": {"car_setup": d_setup, "track_knowledge": d_track, "race_strategy": 0.0}
				})
	for strat in get_player_staff_by_role("Race Strategist"):
		var pre_strat = strat.race_strategy
		var pre_track = strat.track_knowledge
		if strat.race_strategy < 100.0:
			strat.race_strategy = min(100.0, strat.race_strategy + improvement * 0.5)
		if track_id != "":
			strat.update_track_knowledge(track_id, improvement * 5.0)
		elif strat.track_knowledge < 100.0:
			strat.track_knowledge = min(100.0, strat.track_knowledge + improvement * 0.3)
		var d_strat = strat.race_strategy - pre_strat
		var d_track = strat.track_knowledge - pre_track
		if d_strat > 0.01 or d_track > 0.01:
			last_race_staff_deltas.append({
				"name": strat.full_name(), "role": "Race Strategist",
				"deltas": {"car_setup": 0.0, "track_knowledge": d_track, "race_strategy": d_strat}
			})



































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
	_process_sponsors_season_end()
	_process_supply_contracts_season_end()
	pending_season_screen = "end_of_season"

func start_new_season() -> void:
	current_season += 1
	current_week = 1
	weekly_log = []
	pending_season_screen = "begin_of_season"

	_process_off_season()

	# ── Wipe ALL player cars ─────────────────────────────────────────────────
	player_team_cars.clear()
	# Clear car assignments on all staff — cars no longer exist
	for staff_id in all_staff:
		var s = all_staff[staff_id]
		if s.assigned_car_id != "":
			s.assigned_car_id = ""
	## Wipe all installed parts (CNC and provider) and warehouse inventory
	car_installed_parts.clear()
	car_provider_parts.clear()
	cnc_parts_inventory.clear()
	add_log("🏎 All cars retired for Season %d. Buy or build new cars before Race 1." % current_season)

	# ── AI team car regeneration ─────────────────────────────────────────────
	for team in all_teams:
		if team.id == player_team.id:
			continue
		_regenerate_ai_team_cars(team)

	# ── Reset and activate championships ─────────────────────────────────────
	# ── Rebuild active_championships from player_registered_championships ────
	# Championships the player didn't re-register for are dropped.
	# Existing registered ones carry over (reset for new season).
	var prev_by_id: Dictionary = {}
	for champ in active_championships:
		prev_by_id[champ.id] = champ

	active_championships.clear()

	if player_registered_championships.is_empty():
		add_notification("High",
			"⚠ No championships registered for Season %d! Use the Championships screen to register." % current_season)
	else:
		for champ_id in player_registered_championships:
			if champ_id in prev_by_id:
				var existing = prev_by_id[champ_id]
				existing.reset_for_new_season()
				active_championships.append(existing)
			else:
				var new_champ = _create_championship(champ_id)
				if new_champ:
					active_championships.append(new_champ)
					add_log("🏆 Now competing in: %s" % new_champ.championship_name)
		## Fire no-car notification for any registered champ without a car
		for champ_id in player_registered_championships:
			var has_car = false
			for car in player_team_cars:
				if car.championship_id == champ_id: has_car = true; break
			if not has_car:
				var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
				add_notification("High",
					"🏎 No car for %s — buy or manufacture one before Race 1." % reg.get("name", champ_id),
					"logistics")

	# Delivery deadline notifications
	for champ in active_championships:
		var delivery_wk = get_car_delivery_week(champ.id)
		var race1_wk    = FIRST_RACE_WEEK.get(champ.id, 6)
		add_notification("High",
			"Season %d [%s]: New car needed. Delivery: Week %d. Race 1: Week %d." % [
			current_season, champ.championship_name, delivery_wk, race1_wk])

	# Re-register all eligible AI drivers and teams
	# Player drivers enter standings when assigned to a car for that championship
	for champ in active_championships:
		for team in all_teams:
			if team.id == player_team.id:
				continue  # Player drivers added via car assignment, not here
			for driver_id in team.drivers:
				if driver_id in all_drivers:
					var driver = all_drivers[driver_id]
					if driver.age >= champ.min_age and driver.age <= champ.max_age:
						champ.standings[driver_id] = 0
		for team in all_teams:
			champ.team_standings[team.id] = 0

	add_log("=== SEASON %d BEGINS ===" % current_season)

	## Activate any pre-signed contracts from last season
	_activate_presigned_contracts()

	# ── R&D: seasonal maintenance ─────────────────────────────────────────────
	var expired_upg = completed_upg_tasks.size()
	completed_upg_tasks.clear()
	completed_rnd_tasks = completed_rnd_tasks.filter(
		func(tid): return not tid.begins_with("UPG-"))
	if expired_upg > 0:
		add_log("📋 %d upgrade blueprints expired for Season %d. Upgrades reset to L1." % [expired_upg, current_season])

	if current_season > wra_cycle_start_season and \
	   (current_season - wra_cycle_start_season) % WRA_CYCLE_LENGTH == 0:
		_apply_wra_regulation_change()

	_rebuild_seasonal_rnd_tasks()
	add_log("🔬 R&D catalog updated for Season %d." % current_season)

	# Clear registrations AFTER activation — player re-registers for next season
	var prev_champ_names_s = []
	for champ in active_championships:
		prev_champ_names_s.append(champ.championship_name)
	player_registered_championships.clear()
	if not prev_champ_names_s.is_empty():
		add_notification("Normal",
			"Season %d active: %s. Re-register during off-season for Season %d." % [
			current_season, ", ".join(prev_champ_names_s), current_season + 1])
	emit_signal("week_advanced", current_week)
	emit_signal("log_updated")

func _create_championship(champ_id: String) -> Championship:
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	if reg.is_empty():
		return null
	var champ = Championship.new()
	champ.id = champ_id
	champ.championship_name = reg["name"]
	champ.discipline = reg["discipline"]
	champ.tier = reg["tier"]
	champ.min_age = reg["min_age"]
	champ.max_age = reg["max_age"]
	champ.num_races = reg["num_races"]
	const PRIZE_MONEY = {
		"C-001": [300.0, 150.0, 75.0],   "C-002": [1200.0, 600.0, 300.0],
		"C-003": [2000.0, 1000.0, 500.0], "C-004": [20000.0, 10000.0, 5000.0],
		"C-005": [2500.0, 1250.0, 625.0], "C-006": [5000.0, 2500.0, 1250.0],
		"C-007": [28000.0, 14000.0, 7000.0], "C-008": [85000.0, 42500.0, 21250.0],
		"C-009": [4000.0, 2000.0, 1000.0], "C-010": [40000.0, 20000.0, 10000.0],
		"C-011": [3000.0, 1500.0, 750.0], "C-012": [8000.0, 4000.0, 2000.0],
		"C-013": [30000.0, 15000.0, 7500.0], "C-014": [3000.0, 1500.0, 750.0],
		"C-015": [14000.0, 7000.0, 3500.0], "C-016": [25000.0, 12500.0, 6250.0],
		"C-017": [250000.0, 125000.0, 72500.0],
		"C-018": [1500.0, 750.0, 375.0], "C-019": [8000.0, 4000.0, 2000.0],
		"C-020": [250000.0, 125000.0, 62500.0],
		"C-021": [1500.0, 750.0, 375.0], "C-022": [8000.0, 4000.0, 2000.0],
		"C-023": [15000.0, 7000.0, 3750.0], "C-024": [250000.0, 125000.0, 72500.0],
	}
	var prize = PRIZE_MONEY.get(champ_id, [1000.0, 500.0, 250.0])
	champ.prize_1st = prize[0]
	champ.prize_2nd = prize[1]
	champ.prize_3rd = prize[2]
	champ.sp_per_10_pct_damage = 100
	champ.fuel_per_car_per_race = 15.0
	champ.condition_loss_per_lap = 0.5
	champ.has_mid_race_repairs = false
	# Load real calendar from CHAMPIONSHIP_CALENDARS
	var cal = CHAMPIONSHIP_CALENDARS.get(champ_id, [])
	champ.calendar = []
	for race in cal:
		champ.calendar.append({
			"round": race["round"],
			"name": race["name"],
			"week": race["week"],
			"rain_probability": race["rain"],
			"laps": race["laps"],
			"lap_km": race.get("lap_km", 1.0),
			"audience": race["audience"],
		})
	champ.num_races = champ.calendar.size()
	return champ

func _regenerate_ai_team_cars(team) -> void:
	var driver_count = team.drivers.size()
	if driver_count == 0:
		return
	for i in range(driver_count):
		var car = Car.new()
		car.id = "CAR-%s-%03d" % [team.id, i + 1]
		car.car_type_id = "A_01"
		car.championship_id = "C-001"
		car.car_number = i + 1
		car.car_name = ""
		car.driver_id = team.drivers[i] if i < team.drivers.size() else ""
		car.mechanic_id = ""
		car.pit_crew_id = "N/A"  # AI cars start in C-001 (GK) — no pit crew needed
		car.condition = 100.0
		car.part_conditions = {"Aero": 100.0, "Engine": 100.0, "Gearbox": 100.0,
			"Suspension": 100.0, "Brakes": 100.0, "Chassis": 100.0}
		var telemetry = CAR_TELEMETRY.get("A_01", {})
		if not telemetry.is_empty():
			car.top_speed = telemetry["top_speed"]
			car.acceleration = telemetry["acceleration"]
			car.deceleration = telemetry["deceleration"]
			car.cornering_grip = telemetry["cornering_grip"]
			car.fuel_consumption_per_km = telemetry["fuel_per_km"]
			car.tire_wear_rate = telemetry["tire_wear"]
			car.baseline_performance_index = telemetry["perf_index"]

func _process_off_season() -> void:
	# Age all drivers, recover fitness, accumulate experience
	for driver_id in all_drivers:
		var driver = all_drivers[driver_id]
		driver.age += 1
		driver.fitness = 100.0
		driver.experience = min(100.0, driver.experience + 1.0)
		driver.seasons_without_contract += 1
		# Decrement contract
		if driver.contract_seasons_remaining > 0:
			driver.contract_seasons_remaining -= 1
			if driver.contract_seasons_remaining == 0 and driver.contract_team == player_team.id:
				add_notification("High",
					"⚠ %s's contract has expired! Re-sign them or they will leave." % driver.full_name())

	# Decrement staff contracts
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.contract_seasons_remaining > 0:
			staff.contract_seasons_remaining -= 1
			if staff.contract_seasons_remaining == 0 and staff.contract_team == player_team.id:
				add_notification("High",
					"⚠ %s (%s) contract expired! Re-sign or they will leave." % [
					staff.full_name(), staff.role])

	var driver_counter = all_drivers.size()
	for team in all_teams:
		# Never auto-remove player team drivers — player manages their own roster
		if team.id == player_team.id:
			continue

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
					add_log("%s aged out of %s — replaced by %s" % [
						driver.full_name(), team.team_name, new_driver.full_name()])

		for driver_id in drivers_to_remove:
			team.drivers.erase(driver_id)
			all_drivers.erase(driver_id)

		for new_driver in drivers_to_add:
			all_drivers[new_driver.id] = new_driver
			team.drivers.append(new_driver.id)

func _autosave() -> void:
	## Save to main slot first, then copy to rotating autosave slot
	## 4 rotating slots: autosave_0.json … autosave_3.json
	save_game()
	var total_weeks = (current_season - 1) * max_weeks + current_week
	var slot = (total_weeks / 13) % 4
	var src_path  = "user://save_game.json"
	var dest_path = "user://autosave_%d.json" % slot
	if FileAccess.file_exists(src_path):
		var data = FileAccess.get_file_as_string(src_path)
		var file = FileAccess.open(dest_path, FileAccess.WRITE)
		if file:
			file.store_string(data)
			file.close()
	add_log("💾 Autosave slot %d — S%d W%d" % [slot, current_season, current_week])
	add_notification("Normal", "💾 Game autosaved (slot %d)." % slot)

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
		"part_inventory": part_inventory,
		"active_rnd_tasks":     active_rnd_tasks,
		"completed_rnd_tasks":  completed_rnd_tasks,
		"completed_bp_tasks":   completed_bp_tasks,
		"completed_upg_tasks":  completed_upg_tasks,
		"known_blueprints":     known_blueprints,
		"wra_cycle_start_season": wra_cycle_start_season,
		"rnd_bonuses":          player_team.get_meta("rnd_bonuses") if player_team.has_meta("rnd_bonuses") else {},
		"cnc_production_queue": cnc_production_queue,
		"cnc_parts_inventory":  cnc_parts_inventory,
		"car_installed_parts":  car_installed_parts,
		"car_provider_parts":   car_provider_parts,
		"research_points":      research_points,
		"player_team_cars": _serialize_cars(),
		"all_staff": _serialize_staff(),
		"walked_away_subjects":      walked_away_subjects,
		"pending_staff_assignments": pending_staff_assignments,
		"active_approaches":         active_approaches,
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
			"contract_seasons_remaining": d.contract_seasons_remaining,
			"weekly_salary":      d.weekly_salary,
			"win_bonus":          d.win_bonus,
			"podium_bonus":       d.podium_bonus,
			"championship_bonus": d.championship_bonus,
			"release_clause":     d.release_clause,
			"active_discipline": d.active_discipline,
			"discipline_change_season": d.discipline_change_season,
			"pace": d.pace,
			"wet": d.wet,
			"focus": d.focus,
			"race_craft": d.race_craft,
			"consistency": d.consistency,
			"feedback": d.feedback,
			"marketability": d.marketability,
			"fitness": d.fitness,
			"potential": d.potential,
			"aggression": d.aggression,
			"experience": d.experience,
			"morale": d.morale,
			"seasons_without_contract": d.seasons_without_contract,
			"discipline_adaptation": d.discipline_adaptation,
			"peak_adaptation": d.peak_adaptation,
			"track_knowledge": d.track_knowledge,
		}

	# Write to file
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[Save] Game saved successfully")
	else:
		push_error("[Save] Could not open save file for writing")

func load_game(path: String = "user://save_game.json") -> void:
	if not FileAccess.file_exists(path):
		add_log("No save file found at: %s" % path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[Load] Could not open save file: %s" % path)
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
	if "active_rnd_tasks"     in data: active_rnd_tasks     = data["active_rnd_tasks"]
	if "completed_rnd_tasks"   in data: completed_rnd_tasks   = data["completed_rnd_tasks"]
	if "completed_bp_tasks"    in data: completed_bp_tasks    = data["completed_bp_tasks"]
	if "completed_upg_tasks"   in data: completed_upg_tasks   = data["completed_upg_tasks"]
	if "known_blueprints"      in data: known_blueprints      = data["known_blueprints"]
	if "wra_cycle_start_season" in data: wra_cycle_start_season = data["wra_cycle_start_season"]
	_rebuild_seasonal_rnd_tasks()
	if "cnc_production_queue" in data: cnc_production_queue = data["cnc_production_queue"]
	if "cnc_parts_inventory"  in data: cnc_parts_inventory  = data["cnc_parts_inventory"]
	if "car_installed_parts"  in data: car_installed_parts  = data["car_installed_parts"]
	if "car_provider_parts"   in data: car_provider_parts   = data["car_provider_parts"]
	if "research_points"      in data: research_points      = float(data["research_points"])
	if "walked_away_subjects"      in data: walked_away_subjects      = data["walked_away_subjects"]
	if "pending_staff_assignments" in data: pending_staff_assignments = data["pending_staff_assignments"]
	if "active_approaches"         in data: active_approaches         = data["active_approaches"]

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
		d.contract_seasons_remaining = dd.get("contract_seasons_remaining", 0)
		d.weekly_salary       = dd.get("weekly_salary", 0.0)
		d.win_bonus           = dd.get("win_bonus", 0)
		d.podium_bonus        = dd.get("podium_bonus", 0)
		d.championship_bonus  = dd.get("championship_bonus", 0)
		d.release_clause      = dd.get("release_clause", 0)
		d.active_discipline = dd["active_discipline"]
		d.discipline_change_season = dd["discipline_change_season"]
		d.pace = dd["pace"]
		d.wet = dd["wet"]
		d.focus = dd["focus"]
		d.race_craft = dd["race_craft"]
		d.consistency = dd.get("consistency", 20.0)
		d.feedback = dd.get("feedback", 20.0)
		d.marketability = dd.get("marketability", 10.0)
		d.fitness = dd["fitness"]
		d.potential = dd["potential"]
		d.aggression = dd["aggression"]
		d.experience = dd["experience"]
		d.morale = dd["morale"]
		d.seasons_without_contract = dd["seasons_without_contract"]
		d.discipline_adaptation = dd["discipline_adaptation"]
		d.peak_adaptation = dd["peak_adaptation"]
		d.track_knowledge = dd.get("track_knowledge", {})
		all_drivers[driver_id] = d

	# Restore cars
	if "player_team_cars" in data:
		_deserialize_cars(data["player_team_cars"])
	else:
		_setup_cars()  # backwards compat

	# Restore staff
	if "all_staff" in data:
		_deserialize_staff(data["all_staff"])
	else:
		_generate_available_staff(60)  # backwards compat

	# Restore part inventory
	if "part_inventory" in data:
		part_inventory = data["part_inventory"]
	else:
		_setup_part_inventory()  # backwards compat

	if "rnd_bonuses" in data and player_team != null:
		player_team.set_meta("rnd_bonuses", data["rnd_bonuses"])

	print("[Load] Game loaded successfully — Season %d Week %d" % [current_season, current_week])
	emit_signal("week_advanced", current_week)
	emit_signal("log_updated")

## ═══════════════════════════════════════════════════════════════════════════
## SERIALIZATION HELPERS
## ═══════════════════════════════════════════════════════════════════════════

func _serialize_cars() -> Array:
	var result = []
	for car in player_team_cars:
		result.append({
			"id": car.id, "car_type_id": car.car_type_id,
			"championship_id": car.championship_id, "car_number": car.car_number,
			"driver_id": car.driver_id, "mechanic_id": car.mechanic_id,
			"pit_crew_id": car.pit_crew_id, "condition": car.condition,
			"part_conditions": car.part_conditions,
			"top_speed": car.top_speed, "acceleration": car.acceleration,
			"deceleration": car.deceleration, "cornering_grip": car.cornering_grip,
			"fuel_consumption_per_km": car.fuel_consumption_per_km,
			"tire_wear_rate": car.tire_wear_rate,
			"baseline_performance_index": car.baseline_performance_index,
		})
	return result

func _deserialize_cars(data_array: Array) -> void:
	player_team_cars = []
	for cd in data_array:
		var car = Car.new()
		car.id = cd["id"]
		car.car_type_id = cd["car_type_id"]
		car.championship_id = cd["championship_id"]
		car.car_number = cd["car_number"]
		car.driver_id = cd["driver_id"]
		car.mechanic_id = cd["mechanic_id"]
		car.pit_crew_id = cd["pit_crew_id"]
		car.condition = cd["condition"]
		car.part_conditions = cd["part_conditions"]
		car.top_speed = cd["top_speed"]
		car.acceleration = cd["acceleration"]
		car.deceleration = cd["deceleration"]
		car.cornering_grip = cd["cornering_grip"]
		car.fuel_consumption_per_km = cd["fuel_consumption_per_km"]
		car.tire_wear_rate = cd["tire_wear_rate"]
		car.baseline_performance_index = cd["baseline_performance_index"]
		player_team_cars.append(car)

func _serialize_staff() -> Dictionary:
	var result = {}
	for staff_id in all_staff:
		var s = all_staff[staff_id]
		result[staff_id] = {
			"id": s.id, "first_name": s.first_name, "last_name": s.last_name,
			"nationality": s.nationality, "age": s.age, "sex": s.sex,
			"role": s.role, "talent": s.talent, "reputation": s.reputation,
			"morale": s.morale, "weekly_salary": s.weekly_salary,
			"contract_seasons_remaining": s.contract_seasons_remaining,
			"contract_team": s.contract_team,
			"assigned_championship": s.assigned_championship,
			"assigned_car_id": s.assigned_car_id,
			"discipline_adaptation": s.discipline_adaptation,
			# Role attributes
			"car_setup": s.car_setup, "pit_stops": s.pit_stops,
			"car_knowledge": s.car_knowledge, "track_knowledge": s.track_knowledge,
			"pit_stop_speed": s.pit_stop_speed, "repair_skill": s.repair_skill,
			"teamwork": s.teamwork, "fitness": s.fitness,
			"race_strategy": s.race_strategy, "practice_management": s.practice_management,
			"qualifying_management": s.qualifying_management,
			"race_pace_reading": s.race_pace_reading,
			"car_setup_oversight": s.car_setup_oversight,
			"pit_stop_management": s.pit_stop_management, "pr_skill": s.pr_skill,
			"loan_management": s.loan_management, "interest_rates": s.interest_rates,
			"sales_skill": s.sales_skill, "sponsor_negotiation": s.sponsor_negotiation,
			"resource_management": s.resource_management, "budget_planning": s.budget_planning,
			"engine": s.engine, "aero": s.aero, "brakes": s.brakes,
			"suspension": s.suspension, "chassis": s.chassis, "gearbox": s.gearbox,
			"reliability": s.reliability, "parts_knowledge": s.parts_knowledge,
			"practice_scheduling": s.practice_scheduling,
			"qualifying_timing": s.qualifying_timing,
			"championship_bonus": s.championship_bonus,
			"performance_bonus":  s.performance_bonus,
			"release_clause":     s.release_clause,
			"crew_number": s.crew_number,
			"track_knowledge_by_track": s.track_knowledge_by_track,
		}
	return result

func _deserialize_staff(data_dict: Dictionary) -> void:
	all_staff = {}
	_staff_id_counter = 0
	for staff_id in data_dict:
		var sd = data_dict[staff_id]
		var s = Staff.new()
		s.id = sd["id"]
		s.first_name = sd["first_name"]
		s.last_name = sd["last_name"]
		s.nationality = sd["nationality"]
		s.age = sd["age"]
		s.sex = sd["sex"]
		s.role = sd["role"]
		s.talent = sd["talent"]
		s.reputation = sd["reputation"]
		s.morale = sd["morale"]
		s.weekly_salary = sd["weekly_salary"]
		s.contract_seasons_remaining = sd["contract_seasons_remaining"]
		s.contract_team = sd["contract_team"]
		s.assigned_championship = sd["assigned_championship"]
		s.assigned_car_id = sd["assigned_car_id"]
		s.discipline_adaptation = sd["discipline_adaptation"]
		s.car_setup = sd.get("car_setup", 0.0)
		s.pit_stops = sd.get("pit_stops", 0.0)
		s.car_knowledge = sd.get("car_knowledge", 0.0)
		s.track_knowledge = sd.get("track_knowledge", 0.0)
		s.pit_stop_speed = sd.get("pit_stop_speed", 0.0)
		s.repair_skill = sd.get("repair_skill", 0.0)
		s.teamwork = sd.get("teamwork", 0.0)
		s.fitness = sd.get("fitness", 100.0)
		s.race_strategy = sd.get("race_strategy", 0.0)
		s.practice_management = sd.get("practice_management", 0.0)
		s.qualifying_management = sd.get("qualifying_management", 0.0)
		s.race_pace_reading = sd.get("race_pace_reading", 0.0)
		s.car_setup_oversight = sd.get("car_setup_oversight", 0.0)
		s.pit_stop_management = sd.get("pit_stop_management", 0.0)
		s.pr_skill = sd.get("pr_skill", 0.0)
		s.loan_management = sd.get("loan_management", 0.0)
		s.interest_rates = sd.get("interest_rates", 0.0)
		s.sales_skill = sd.get("sales_skill", 0.0)
		s.sponsor_negotiation = sd.get("sponsor_negotiation", 0.0)
		s.resource_management = sd.get("resource_management", 0.0)
		s.budget_planning = sd.get("budget_planning", 0.0)
		s.engine = sd.get("engine", 0.0)
		s.aero = sd.get("aero", 0.0)
		s.brakes = sd.get("brakes", 0.0)
		s.suspension = sd.get("suspension", 0.0)
		s.chassis = sd.get("chassis", 0.0)
		s.gearbox = sd.get("gearbox", 0.0)
		s.reliability = sd.get("reliability", 0.0)
		s.parts_knowledge = sd.get("parts_knowledge", 0.0)
		s.practice_scheduling = sd.get("practice_scheduling", 0.0)
		s.qualifying_timing   = sd.get("qualifying_timing", 0.0)
		s.championship_bonus  = sd.get("championship_bonus", 0)
		s.performance_bonus   = sd.get("performance_bonus", 0)
		s.release_clause      = sd.get("release_clause", 0)
		s.crew_number         = sd.get("crew_number", 0)
		s.track_knowledge_by_track = sd.get("track_knowledge_by_track", {})
		all_staff[staff_id] = s
		# Track counter for future generation
		var num_part = sd["id"].trim_prefix("ST-").to_int()
		if num_part > _staff_id_counter:
			_staff_id_counter = num_part

func add_log(message: String) -> void:
	weekly_log.append(message)
	print(message)

## ScreenShot Function
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		var screenshot = get_viewport().get_texture().get_image()
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
		var path = "user://screenshot_%s.png" % timestamp
		screenshot.save_png(path)
		add_notification("Normal", "📸 Screenshot saved: %s" % path)
		add_log("📸 Screenshot saved: %s" % path)

## ═══════════════════════════════════════════════════════════════════════════
## DEV PROFILES — Testing starting points
## Call apply_dev_profile(id) AFTER setup_new_game() to inject state.
## Remove before release or gate behind a DEV_MODE const.
## ═══════════════════════════════════════════════════════════════════════════

const DEV_PROFILES = {
	"starter": {
		"label": "🏁 Starter",
		"desc":  "Default start — GK Regional, CR 50K, blank slate.",
	},
	"mid_tier": {
		"label": "🏆 Mid-Tier Team",
		"desc":  "Season 3, CR 2M, F3 + GT4 registered, R&D Studio L2, 500 RP, full staff.",
	},
	"top_team": {
		"label": "🚀 Top-Tier Team",
		"desc":  "Season 6, CR 15M, F2 + LMP2 active, all Engineering L3, 2000 RP, full roster.",
	},
	"rnd_focus": {
		"label": "🔬 R&D Focus",
		"desc":  "Season 2, CR 800K, GK + F4, R&D L3 + CNC L2, 2 designers, 300 RP, 3 blueprints done.",
	},
}

func apply_dev_profile(profile_id: String) -> void:
	match profile_id:
		"starter":
			pass  # default — no changes
		"mid_tier":
			_dev_mid_tier()
		"top_team":
			_dev_top_team()
		"rnd_focus":
			_dev_rnd_focus()

func _dev_mid_tier() -> void:
	current_season = 3
	player_team.balance = 2000000.0
	player_team.reputation = 35.0
	research_points = 500.0
	# Upgrade key buildings
	for bname in ["R&D Design Studio", "CNC Parts Plant", "Garage", "Racing Department", "Headquarters"]:
		var b = campus_buildings.get(bname, {})
		if b.get("built", false):
			b["level"] = 2
		elif b.get("build_cost", 999999) < 200000:
			b["built"] = true; b["level"] = 1; b["construction_weeks_remaining"] = 0
	# Register F3 and GT4
	for cid in ["C-022", "C-009"]:
		if not cid in player_registered_championships:
			player_registered_championships.append(cid)
	# Inject a capable designer and race strategist
	_dev_inject_staff("Designer", 70.0)
	_dev_inject_staff("Race Strategist", 65.0)
	_dev_inject_staff("Race Mechanic", 60.0)
	_dev_inject_staff("Team Principal", 65.0)
	add_log("🛠 DEV: Mid-Tier profile applied — Season 3, CR 2M, F3 + GT4 registered.")

func _dev_top_team() -> void:
	current_season = 6
	player_team.balance = 15000000.0
	player_team.reputation = 65.0
	research_points = 2000.0
	# Upgrade all engineering buildings to L3
	for bname in ["R&D Design Studio", "CNC Parts Plant", "Aerodynamic Wind Tunnel",
			"Ops Sim & Telemetry", "Garage", "Racing Department", "Headquarters",
			"Logistics Center", "Pit Crew Arena"]:
		var b = campus_buildings.get(bname, {})
		if not b.is_empty():
			b["built"] = true; b["level"] = 3; b["construction_weeks_remaining"] = 0
	for cid in ["C-023", "C-019"]:  # F2 + LMP2
		if not cid in player_registered_championships:
			player_registered_championships.append(cid)
	# Pre-complete some R&D tasks
	for tid in ["BP_AERO_1", "BP_ENGINE_1", "BP_CHASSIS_1", "UPG_AERO_1", "UPG_ENGINE_1"]:
		if not tid in completed_rnd_tasks:
			completed_rnd_tasks.append(tid)
			_apply_rnd_effect({"effect_key": RND_TASKS[tid].get("effect",""), "effect_value": RND_TASKS[tid].get("value",0.0)})
	# Full staff
	for role_data in [["Designer",80.0],["Designer",75.0],["Race Strategist",78.0],
			["Race Mechanic",75.0],["Team Principal",80.0],["CFO",70.0]]:
		_dev_inject_staff(role_data[0], role_data[1])
	add_log("🛠 DEV: Top-Team profile applied — Season 6, CR 15M, F2 + LMP2.")

func _dev_rnd_focus() -> void:
	current_season = 2
	player_team.balance = 800000.0
	player_team.reputation = 20.0
	research_points = 300.0
	# Build and level R&D specific buildings
	var rnd = campus_buildings.get("R&D Design Studio", {})
	if not rnd.is_empty(): rnd["built"] = true; rnd["level"] = 3; rnd["construction_weeks_remaining"] = 0
	var cnc = campus_buildings.get("CNC Parts Plant", {})
	if not cnc.is_empty(): cnc["built"] = true; cnc["level"] = 2; cnc["construction_weeks_remaining"] = 0
	# Register F4 alongside GK
	if not "C-021" in player_registered_championships:
		player_registered_championships.append("C-021")
	# Two designers
	_dev_inject_staff("Designer", 72.0)
	_dev_inject_staff("Designer", 68.0)
	_dev_inject_staff("Race Mechanic", 60.0)
	# Pre-complete 3 blueprints
	for tid in ["BP_AERO_1", "BP_ENGINE_1", "BP_GEAR_1"]:
		if not tid in completed_rnd_tasks:
			completed_rnd_tasks.append(tid)
			_apply_rnd_effect({"effect_key": RND_TASKS[tid].get("effect",""), "effect_value": RND_TASKS[tid].get("value",0.0)})
	add_log("🛠 DEV: R&D Focus profile applied — Season 2, CR 800K, R&D L3 + CNC L2.")

## Injects a staff member with given role and talent directly to player team.
func _dev_inject_staff(role: String, talent: float) -> void:
	var s = _create_staff(role, "British")
	s.talent = talent
	var q = talent * 0.8
	_generate_staff_attributes(s, q)
	s.contract_team = player_team.id
	s.contract_seasons_remaining = 5
	all_staff[s.id] = s
	add_log("🛠 DEV: Injected %s %s (talent %.0f)" % [role, s.full_name(), talent])

## ═══════════════════════════════════════════════════════════════════════════
## SPONSOR SYSTEM (S18)
## ═══════════════════════════════════════════════════════════════════════════

const SPONSOR_NAME_PREFIXES = [
	"Apex","Vortex","Nexus","Titan","Falcon","Summit","Horizon",
	"Vector","Fusion","Pulse","Quantum","Eclipse","Nova","Zenith"
]
const SPONSOR_NAME_SUFFIXES = [
	"Racing","Motorsport","Energy","Tech","Systems","Industries",
	"Performance","Dynamics","Engineering","Solutions","Group","Corp"
]

func _generate_sponsor_id() -> String:
	return "SP_%d_%d" % [current_season, randi() % 99999]

func _generate_sponsor_name() -> String:
	return "%s %s" % [
		SPONSOR_NAME_PREFIXES[randi() % SPONSOR_NAME_PREFIXES.size()],
		SPONSOR_NAME_SUFFIXES[randi() % SPONSOR_NAME_SUFFIXES.size()]]

func _get_sponsor_tier_for_team() -> int:
	if player_team.reputation >= 75: return 3
	if player_team.reputation >= 40: return 2
	return 1

func _generate_sponsor_offer(type: int, tier: int) -> Dictionary:
	var mult = 1.0 + (tier - 1) * 2.5
	var offer = {
		"sponsor_id":       _generate_sponsor_id(),
		"name":             _generate_sponsor_name(),
		"type":             type,
		"tier":             tier,
		"championship_id":  "",
		"weekly_payment":   0,
		"win_bonus":        0,
		"podium_bonus":     0,
		"season_bonus":     0,
		"commitment_total": 0,
		"seasons_remaining": randi_range(1, 3),
		"season_signed":    current_season,
		"expires_season":   current_season + 2,
		## Offer expires in 2–4 weeks if not acted on (Bugs doc §10)
		"expires_week":     current_week + randi_range(2, 4),
	}
	match type:
		1: offer.weekly_payment = int(randi_range(500, 2000) * mult)
		2:
			offer.win_bonus    = int(randi_range(2000, 8000) * mult)
			offer.podium_bonus = int(randi_range(500, 2000) * mult)
			offer.season_bonus = int(randi_range(5000, 20000) * mult)
		3:
			if not active_championships.is_empty():
				var champ = active_championships[randi() % active_championships.size()]
				offer.championship_id = champ.id
				offer.commitment_total = int(randi_range(20000, 80000) * mult)
	return offer

func _generate_passive_sponsor_offers() -> void:
	var max_tier = _get_sponsor_tier_for_team()
	for i in range(randi_range(1, 3)):
		var offer = _generate_sponsor_offer(randi_range(1, 3), randi_range(1, max_tier))
		sponsor_offers.append(offer)
		pending_hq_tab = "sponsors"
		add_notification("Normal", "New sponsor offer: %s. View in Sponsors tab." % offer.name, "hq")

func start_cfo_sponsor_search() -> bool:
	if cfo_search_active: return false
	var cfo = null
	for sid in all_staff:
		var s = all_staff[sid]
		if s.role == "CFO" and s.contract_team == player_team.id:
			cfo = s
			break
	if not cfo:
		add_notification("High", "No CFO hired. Hire a CFO to search for sponsors.")
		return false
	## Rolling search — weeks_remaining is the interval between offers, not a one-time countdown
	## CFO skill determines how quickly each offer arrives (1-3 weeks between offers)
	var weeks = int(3.0 - (cfo.talent / 100.0) * 2.0)
	weeks = max(1, weeks)
	cfo_search_active = true
	cfo_search_weeks_remaining = weeks
	cfo_search_results = []
	add_log("🔍 CFO sponsor search started. New offers every %d week%s." % [weeks, "s" if weeks != 1 else ""])
	add_notification("Normal", "CFO sponsor search active. Offers will arrive every %d week%s. Stop search in HQ." % [weeks, "s" if weeks != 1 else ""])
	return true

func stop_cfo_sponsor_search() -> void:
	cfo_search_active = false
	cfo_search_weeks_remaining = 0
	add_log("🔍 CFO sponsor search stopped.")
	add_notification("Normal", "CFO sponsor search stopped.")

func _advance_cfo_search() -> void:
	if not cfo_search_active: return
	cfo_search_weeks_remaining -= 1
	if cfo_search_weeks_remaining > 0: return
	## Generate 1-2 new offers this week
	var max_tier = min(3, _get_sponsor_tier_for_team() + 1)
	var num = randi_range(1, 2)
	for i in range(num):
		var offer = _generate_sponsor_offer(randi_range(1, 3), randi_range(1, max_tier))
		offer.expires_season = current_season + 1
		sponsor_offers.append(offer)
		cfo_search_results.append(offer.sponsor_id)
	## Notify player each time a new offer arrives
	pending_hq_tab = "sponsors"
	if num == 1:
		add_notification("High",
			"CFO found a new sponsor offer: %s. View in Sponsors tab." % sponsor_offers[-1].name, "hq")
	else:
		add_notification("High",
			"CFO found %d new sponsor offers this week. View in Sponsors tab." % num, "hq")
	add_log("📋 CFO: %d new sponsor offer%s this week." % [num, "s" if num != 1 else ""])
	## Reset countdown for next offer cycle
	var cfo = null
	for sid in all_staff:
		var s = all_staff[sid]
		if s.role == "CFO" and s.contract_team == player_team.id:
			cfo = s
			break
	if cfo:
		var weeks = int(3.0 - (cfo.talent / 100.0) * 2.0)
		cfo_search_weeks_remaining = max(1, weeks)
	else:
		## CFO was released — stop search
		cfo_search_active = false
		add_notification("Normal", "CFO sponsor search stopped — CFO no longer on team.")

func dismiss_sponsor_offer(sponsor_id: String) -> void:
	for i in range(sponsor_offers.size()):
		if sponsor_offers[i].sponsor_id == sponsor_id:
			sponsor_offers.remove_at(i)
			emit_signal("log_updated")
			return

func sign_sponsor(sponsor_id: String) -> bool:
	var offer = null
	var offer_idx = -1
	for i in range(sponsor_offers.size()):
		if sponsor_offers[i].sponsor_id == sponsor_id:
			offer = sponsor_offers[i]
			offer_idx = i
			break
	if not offer: return false
	## Enforce HQ sponsor slot cap
	var max_slots = get_hq_sponsor_slots()
	if active_sponsors.size() >= max_slots:
		add_notification("High",
			"Sponsor slots full (%d/%d). Upgrade HQ to unlock more slots." % [
				active_sponsors.size(), max_slots])
		return false
	if offer.type == 3 and offer.championship_id != "":
		player_team.balance += offer.commitment_total
		add_log("💰 Commitment sponsor: %s. CR %s." % [offer.name, _fmt_int(offer.commitment_total)])
	active_sponsors.append(offer)
	sponsor_offers.remove_at(offer_idx)
	add_log("🤝 Sponsor signed: %s (Type %d)." % [offer.name, offer.type])
	add_notification("High", "Sponsor signed: %s." % offer.name, "hq")
	return true

## Cancel an active sponsor deal early. Applies rep and marketability penalty.
func cancel_sponsor(sponsor_id: String) -> void:
	var sp_idx = -1
	var sp = null
	for i in range(active_sponsors.size()):
		if active_sponsors[i].get("sponsor_id", "") == sponsor_id:
			sp = active_sponsors[i]
			sp_idx = i
			break
	if sp == null: return

	active_sponsors.remove_at(sp_idx)

	## Penalty: -5 reputation, -8 marketability (scaled by seasons remaining)
	var seasons_left = sp.get("seasons_remaining", 1)
	var rep_penalty = clamp(5 * seasons_left, 5, 20)
	var mktg_penalty = clamp(8 * seasons_left, 8, 30)
	player_team.reputation = max(0.0, player_team.reputation - rep_penalty)
	player_team.marketability = max(0.0, player_team.get("marketability", 50.0) - mktg_penalty)

	add_log("❌ Sponsor deal cancelled: %s. Rep −%d, Marketability −%d." % [
		sp.get("name", "?"), rep_penalty, mktg_penalty])
	add_notification("High",
		"Cancelled %s deal. Penalty: −%d reputation, −%d marketability." % [
		sp.get("name", "?"), rep_penalty, mktg_penalty], "hq")
	emit_signal("log_updated")

func _process_sponsors_weekly() -> void:
	## Expire pending offers that have timed out (2–4 week window)
	var expired_offers = sponsor_offers.filter(func(o):
		return o.get("expires_week", 9999) <= current_week)
	for o in expired_offers:
		sponsor_offers.erase(o)
		add_log("📋 Sponsor offer expired: %s" % o.name)
	if not expired_offers.is_empty():
		emit_signal("log_updated")
	## Pay active sponsors
	for sp in active_sponsors:
		if sp.type == 1:
			player_team.balance += sp.weekly_payment

## Applies sponsor bonuses for podiums/win.
## Can be called with or without a position.
## If no position is passed, it automatically finds the best position
## of any player driver in the last race.
func apply_sponsor_race_bonuses(position: int = -1) -> void:
	if last_race_results.is_empty():
		return
		
	var final_position = position
	# If no position was passed, calculate the best player position automatically
	if final_position == -1:
		final_position = 99
		for i in range(last_race_results.size()):
			var result = last_race_results[i]
			if result.get("dns", false):
				continue
			if result["driver"].id in player_team.drivers:
				final_position = min(final_position, i + 1)

	# No podium achieved
	if final_position > 3:
		return

	for sp in active_sponsors:
		if sp.type != 2:
			continue

		var bonus = 0
		if final_position == 1:
			bonus = sp.win_bonus
		elif final_position <= 3:
			bonus = sp.podium_bonus

		if bonus > 0:
			player_team.balance += bonus
			add_log("💰 Sponsor bonus: CR %s from %s (P%d)." % [_fmt_int(bonus), sp.name, final_position])

func _process_sponsors_season_end() -> void:
	var to_remove: Array = []
	for sp in active_sponsors:
		if sp.type == 3 and sp.championship_id != "":
			var still_active = false
			for champ in active_championships:
				if champ.id == sp.championship_id:
					still_active = true
					break
			if not still_active:
				player_team.balance -= sp.commitment_total
				add_log("⚠ Sponsor penalty: CR %s. Dropped %s." % [_fmt_int(sp.commitment_total), sp.name])
				add_notification("Critical", "Sponsor penalty CR %s: %s (championship exit)." % [
					_fmt_int(sp.commitment_total), sp.name])
				to_remove.append(sp)
				continue
		sp.seasons_remaining -= 1
		if sp.seasons_remaining <= 0:
			to_remove.append(sp)
			add_notification("Normal", "Sponsor contract expired: %s." % sp.name)
	for sp in to_remove:
		active_sponsors.erase(sp)
	sponsor_offers = sponsor_offers.filter(func(o): return o.expires_season > current_season)
	_generate_passive_sponsor_offers()

## ═══════════════════════════════════════════════════════════════════════════
## FINANCIAL HELPERS (S19)
## ═══════════════════════════════════════════════════════════════════════════

func _calculate_company_value() -> float:
	var value = player_team.balance
	for bname in campus_buildings:
		var b = campus_buildings[bname]
		if b.get("level", 0) > 0:
			value += b.get("build_cost", 0) * b.get("level", 1)
	for car in player_team_cars:
		var car_value = get_provider_car_cost(car.championship_id) * 0.6 \
			if car.championship_id != "" else 10000
		value += car_value
	return value

func _calculate_max_loan() -> float:
	var company_val = _calculate_company_value()
	var rep_factor = 0.5 + (player_team.reputation / 100.0) * 0.5
	var hq_level = campus_buildings.get("Headquarters", {}).get("level", 1)
	return company_val * (0.1 + hq_level * 0.05) * rep_factor

func _update_ceo_salary() -> void:
	var weekly_profit = player_team.balance - _prev_week_balance
	if weekly_profit > 0:
		ceo_accumulated_salary += weekly_profit * 0.01  ## GDD: 1% of weekly net profit
	_prev_week_balance = player_team.balance

## ═══════════════════════════════════════════════════════════════════════════
## WRA APPROVAL (S14)
## ═══════════════════════════════════════════════════════════════════════════

func _advance_wra_submissions() -> void:
	var approved: Array = []
	for sub in active_wra_submissions:
		sub.weeks_remaining -= 1
		if sub.weeks_remaining <= 0:
			approved.append(sub)
	for sub in approved:
		active_wra_submissions.erase(sub)
		wra_approved_blueprints.append({
			"blueprint_id":    sub.blueprint_id,
			"championship_id": sub.championship_id,
			"pillar":          sub.pillar,
			"approved_season": current_season,
			"approved_week":   current_week,
		})
		var bp = known_blueprints.get(sub.blueprint_id, {})
		add_log("✅ WRA approved: %s" % bp.get("name", sub.blueprint_id))
		add_notification("High",
			"WRA approved: '%s'. Ready for CNC manufacturing." % bp.get("name", sub.blueprint_id),
			"wra_office")

func submit_to_wra(blueprint_id: String) -> bool:
	if not blueprint_id in known_blueprints: return false
	for sub in active_wra_submissions:
		if sub.blueprint_id == blueprint_id: return false
	for app in wra_approved_blueprints:
		if app.blueprint_id == blueprint_id: return false
	var bp = known_blueprints[blueprint_id]
	var cid = bp.get("championship_id", "")
	var tier = _get_championship_tier(cid)
	var weeks = {1:2,2:3,3:5,4:6}.get(tier, 2)
	active_wra_submissions.append({
		"blueprint_id":    blueprint_id,
		"championship_id": cid,
		"pillar":          bp.get("pillar", 1),
		"submitted_season": current_season,
		"submitted_week":  current_week,
		"weeks_remaining": weeks,
		"tier":            tier,
	})
	add_log("📋 WRA submission: %s. Decision in %d weeks." % [
		bp.get("name", blueprint_id), weeks])
	add_notification("Normal",
		"Blueprint submitted to WRA: '%s'. Decision in %d weeks." % [
			bp.get("name", blueprint_id), weeks])
	emit_signal("log_updated")
	return true

func is_blueprint_approved(blueprint_id: String) -> bool:
	for app in wra_approved_blueprints:
		if app.blueprint_id == blueprint_id: return true
	return false

func is_blueprint_submitted(blueprint_id: String) -> bool:
	for sub in active_wra_submissions:
		if sub.blueprint_id == blueprint_id: return true
	return false

func _get_championship_tier(cid: String) -> int:
	return CHAMPIONSHIP_REGISTRY.get(cid, {}).get("tier", 1)

## ═══════════════════════════════════════════════════════════════════════════
## SUPPLY CONTRACTS (S17)
## ═══════════════════════════════════════════════════════════════════════════

func _process_supply_contracts_weekly() -> void:
	for sc in active_supply_contracts:
		if not sc.active: continue
		var weekly_parts = max(1, int(sc.parts_per_season / 52.0))
		var inv_key = "%s_%s" % [sc.championship_id, sc.part_code]
		if inv_key in cnc_parts_inventory and \
		   cnc_parts_inventory[inv_key].quantity >= weekly_parts:
			cnc_parts_inventory[inv_key].quantity -= weekly_parts
			if cnc_parts_inventory[inv_key].quantity <= 0:
				cnc_parts_inventory.erase(inv_key)
			player_team.balance += weekly_parts * sc.cr_per_part
			sc.parts_delivered += weekly_parts

func _process_supply_contracts_season_end() -> void:
	var to_remove: Array = []
	for sc in active_supply_contracts:
		if not sc.active: continue
		if sc.parts_delivered < sc.parts_per_season:
			var shortfall = sc.parts_per_season - sc.parts_delivered
			var penalty = shortfall * sc.penalty_per_dns
			player_team.balance -= penalty
			add_notification("High",
				"Supply penalty: CR %s. Short %d parts to %s." % [
					_fmt_int(penalty), shortfall, sc.ai_team_name])
		sc.parts_delivered = 0
		sc.seasons_remaining -= 1
		if sc.seasons_remaining <= 0:
			sc.active = false
			supply_contract_history.append(sc)
			to_remove.append(sc)
	for sc in to_remove:
		active_supply_contracts.erase(sc)
