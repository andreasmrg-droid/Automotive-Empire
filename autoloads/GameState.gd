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
var last_race_name: String = ""
var last_race_wet: bool = false
var last_race_results: Array = []

# Hall of fame
var hall_of_fame: Array = []

# Campus buildings state
var campus_buildings: Dictionary = {}
var active_sponsor: Dictionary = {}
var sponsor_no_points_streak: int = 0

# UI navigation helpers — set before changing scene, read + cleared on arrival
var pending_staff_filter: String = ""  # e.g. "Team Principal", "CFO" — StaffHub reads this on _ready

# Resources
var research_points: float = 0.0
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
	"C-001": {"Engine": 1950, "Aero": 1625, "Brakes": 487, "Suspension": 650, "Chassis": 1137, "Gearbox": 650},
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
const CHAMPIONSHIP_CALENDARS = {
	"C-001": [ # GK Regional
		{"round":1,"name":"Super Karting Raceway","week":6,"rain":0,"laps":20,"lap_km":0.42,"audience":120},
		{"round":2,"name":"Riverside Kart Park","week":12,"rain":20,"laps":20,"lap_km":0.51,"audience":95},
		{"round":3,"name":"The Brickyard Junior","week":18,"rain":0,"laps":24,"lap_km":0.40,"audience":150},
		{"round":4,"name":"Ocean Breeze Arena","week":24,"rain":100,"laps":20,"lap_km":0.39,"audience":40},
		{"round":5,"name":"Pinnacle Heights","week":32,"rain":10,"laps":20,"lap_km":0.55,"audience":180},
		{"round":6,"name":"Metro Kart Complex","week":40,"rain":40,"laps":20,"lap_km":0.66,"audience":310},
	],
	"C-002": [ # GK National
		{"round":1,"name":"Super Karting Raceway","week":4,"rain":0,"laps":18,"lap_km":0.90,"audience":1200},
		{"round":2,"name":"Valley International Karting","week":8,"rain":5,"laps":18,"lap_km":1.05,"audience":1450},
		{"round":3,"name":"Ocean Breeze Arena","week":12,"rain":0,"laps":16,"lap_km":1.10,"audience":1900},
		{"round":4,"name":"Black Tarmac Challenge","week":16,"rain":15,"laps":20,"lap_km":0.80,"audience":1650},
		{"round":5,"name":"Speedway Center","week":20,"rain":0,"laps":20,"lap_km":0.95,"audience":2100},
		{"round":6,"name":"High Plains Raceway","week":24,"rain":0,"laps":20,"lap_km":1.00,"audience":2300},
		{"round":7,"name":"Kartland","week":28,"rain":45,"laps":15,"lap_km":1.02,"audience":850},
		{"round":8,"name":"Metro Kart Complex","week":32,"rain":100,"laps":16,"lap_km":0.90,"audience":550},
		{"round":9,"name":"PF International Kart Circuit","week":36,"rain":0,"laps":20,"lap_km":1.10,"audience":3400},
		{"round":10,"name":"Trackhouse Motorplex","week":40,"rain":0,"laps":24,"lap_km":1.20,"audience":4800},
	],
	"C-003": [ # GK Continental
		{"round":1,"name":"Le Castellet","week":9,"rain":0,"laps":27,"lap_km":5.80,"audience":6500},
		{"round":2,"name":"Spa","week":17,"rain":20,"laps":25,"lap_km":7.00,"audience":7200},
		{"round":3,"name":"Chemnitz","week":25,"rain":15,"laps":24,"lap_km":4.20,"audience":8900},
		{"round":4,"name":"Le Mans","week":33,"rain":25,"laps":26,"lap_km":13.60,"audience":14500},
	],
	"C-004": [ # GK World
		{"round":1,"name":"Lemans Karting International","week":40,"rain":0,"laps":28,"lap_km":1.20,"audience":22000},
	],
	"C-005": [ # RALLY4
		{"round":1,"name":"Sweden","week":7,"rain":100,"laps":305,"lap_km":1.0,"audience":45000},
		{"round":2,"name":"Croatia","week":15,"rain":80,"laps":289,"lap_km":1.0,"audience":62000},
		{"round":3,"name":"Portugal","week":19,"rain":0,"laps":345,"lap_km":1.0,"audience":88000},
		{"round":4,"name":"Finland","week":31,"rain":20,"laps":320,"lap_km":1.0,"audience":115000},
		{"round":5,"name":"Chile","week":37,"rain":60,"laps":313,"lap_km":1.0,"audience":38000},
	],
	"C-006": [ # RALLY3
		{"round":1,"name":"Monte-Carlo","week":4,"rain":0,"laps":325,"lap_km":1.0,"audience":95000},
		{"round":2,"name":"Kenya","week":11,"rain":0,"laps":368,"lap_km":1.0,"audience":140000},
		{"round":3,"name":"Croatia","week":15,"rain":80,"laps":300,"lap_km":1.0,"audience":85000},
		{"round":4,"name":"Islas Canarias","week":17,"rain":10,"laps":225,"lap_km":1.0,"audience":110000},
		{"round":5,"name":"Greece","week":26,"rain":0,"laps":310,"lap_km":1.0,"audience":78000},
		{"round":6,"name":"Paraguay","week":35,"rain":0,"laps":319,"lap_km":1.0,"audience":64000},
		{"round":7,"name":"Sardegna","week":41,"rain":50,"laps":332,"lap_km":1.0,"audience":125000},
	],
	"C-007": [ # RALLY2
		{"round":1,"name":"Monte-Carlo","week":4,"rain":50,"laps":339,"lap_km":1.0,"audience":185000},
		{"round":2,"name":"Sweden","week":7,"rain":80,"laps":301,"lap_km":1.0,"audience":120000},
		{"round":3,"name":"Kenya","week":11,"rain":0,"laps":351,"lap_km":1.0,"audience":260000},
		{"round":4,"name":"Croatia","week":15,"rain":30,"laps":300,"lap_km":1.0,"audience":145000},
		{"round":5,"name":"Islas Canarias","week":17,"rain":0,"laps":322,"lap_km":1.0,"audience":165000},
		{"round":6,"name":"Portugal","week":19,"rain":0,"laps":330,"lap_km":1.0,"audience":310000},
		{"round":7,"name":"Japan","week":22,"rain":20,"laps":303,"lap_km":1.0,"audience":190000},
		{"round":8,"name":"Greece","week":26,"rain":0,"laps":329,"lap_km":1.0,"audience":155000},
		{"round":9,"name":"Estonia","week":29,"rain":30,"laps":315,"lap_km":1.0,"audience":135000},
		{"round":10,"name":"Finland","week":31,"rain":0,"laps":317,"lap_km":1.0,"audience":380000},
		{"round":11,"name":"Paraguay","week":35,"rain":0,"laps":310,"lap_km":1.0,"audience":110000},
		{"round":12,"name":"Chile","week":37,"rain":60,"laps":312,"lap_km":1.0,"audience":95000},
		{"round":13,"name":"Sardegna","week":40,"rain":40,"laps":320,"lap_km":1.0,"audience":175000},
		{"round":14,"name":"Saudi Arabia","week":46,"rain":0,"laps":335,"lap_km":1.0,"audience":115000},
	],
	"C-008": [ # Premier Rally (WRC)
		{"round":1,"name":"Monte-Carlo","week":4,"rain":50,"laps":339,"lap_km":1.0,"audience":310000},
		{"round":2,"name":"Sweden","week":7,"rain":80,"laps":301,"lap_km":1.0,"audience":220000},
		{"round":3,"name":"Kenya","week":11,"rain":0,"laps":351,"lap_km":1.0,"audience":480000},
		{"round":4,"name":"Croatia","week":15,"rain":30,"laps":300,"lap_km":1.0,"audience":245000},
		{"round":5,"name":"Islas Canarias","week":17,"rain":0,"laps":322,"lap_km":1.0,"audience":285000},
		{"round":6,"name":"Portugal","week":19,"rain":0,"laps":330,"lap_km":1.0,"audience":520000},
		{"round":7,"name":"Japan","week":22,"rain":20,"laps":303,"lap_km":1.0,"audience":340000},
		{"round":8,"name":"Greece","week":26,"rain":0,"laps":329,"lap_km":1.0,"audience":290000},
		{"round":9,"name":"Estonia","week":29,"rain":30,"laps":315,"lap_km":1.0,"audience":260000},
		{"round":10,"name":"Finland","week":31,"rain":0,"laps":317,"lap_km":1.0,"audience":680000},
		{"round":11,"name":"Paraguay","week":35,"rain":0,"laps":310,"lap_km":1.0,"audience":215000},
		{"round":12,"name":"Chile","week":37,"rain":60,"laps":312,"lap_km":1.0,"audience":185000},
		{"round":13,"name":"Sardegna","week":40,"rain":40,"laps":320,"lap_km":1.0,"audience":345000},
		{"round":14,"name":"Saudi Arabia","week":46,"rain":0,"laps":335,"lap_km":1.0,"audience":240000},
	],
	"C-009": [ # TC Sport (GT4)
		{"round":1,"name":"Paul Ricard Opening Cup","week":8,"rain":0,"laps":32,"lap_km":5.8,"audience":12500},
		{"round":2,"name":"Brands Hatch GP Challenge","week":14,"rain":30,"laps":37,"lap_km":3.9,"audience":18200},
		{"round":3,"name":"Misano Night Sprint","week":20,"rain":0,"laps":35,"lap_km":4.2,"audience":14900},
		{"round":4,"name":"Spa Mid-Season Classic","week":26,"rain":70,"laps":26,"lap_km":7.0,"audience":28000},
		{"round":5,"name":"Hockenheimring Ring Battle","week":34,"rain":0,"laps":34,"lap_km":4.5,"audience":21500},
		{"round":6,"name":"Barcelona","week":42,"rain":0,"laps":33,"lap_km":4.6,"audience":34200},
	],
	"C-010": [ # TC Elite (GT3)
		{"round":1,"name":"Bathurst 12 Hour","week":5,"rain":0,"laps":12,"lap_km":6.2,"audience":53000},
		{"round":2,"name":"24h Nürburgring","week":22,"rain":75,"laps":24,"lap_km":25.4,"audience":235000},
		{"round":3,"name":"24h Le Mans","week":24,"rain":35,"laps":24,"lap_km":13.6,"audience":332000},
		{"round":4,"name":"24h Spa","week":26,"rain":45,"laps":24,"lap_km":7.0,"audience":85000},
		{"round":5,"name":"Indianapolis 8 Hour","week":40,"rain":20,"laps":8,"lap_km":3.9,"audience":38000},
		{"round":6,"name":"Kyalami 9 Hour","week":48,"rain":30,"laps":9,"lap_km":4.5,"audience":42500},
	],
	"C-011": [ # OWC Next Gen (USF Pro 2000)
		{"round":1,"name":"St. Petersburg","week":10,"rain":0,"laps":25,"lap_km":1.8,"audience":42000},
		{"round":2,"name":"Louisiana","week":14,"rain":10,"laps":15,"lap_km":4.3,"audience":11500},
		{"round":3,"name":"Indianapolis","week":19,"rain":20,"laps":15,"lap_km":4.1,"audience":28000},
		{"round":4,"name":"Freedom 90","week":21,"rain":0,"laps":75,"lap_km":1.1,"audience":14000},
		{"round":5,"name":"Elkhart Lake","week":25,"rain":0,"laps":12,"lap_km":6.4,"audience":55000},
		{"round":6,"name":"Lexington","week":27,"rain":50,"laps":20,"lap_km":3.4,"audience":32400},
		{"round":7,"name":"Toronto","week":31,"rain":0,"laps":21,"lap_km":2.8,"audience":48000},
		{"round":8,"name":"Portland","week":33,"rain":0,"laps":23,"lap_km":3.2,"audience":22500},
	],
	"C-012": [ # OWC Dev (Indy NXT)
		{"round":1,"name":"Sakhir","week":9,"rain":0,"laps":22,"lap_km":5.4,"audience":95000},
		{"round":2,"name":"Albert Park","week":11,"rain":20,"laps":23,"lap_km":5.3,"audience":125000},
		{"round":3,"name":"Imola","week":20,"rain":15,"laps":22,"lap_km":4.9,"audience":88000},
		{"round":4,"name":"Monaco","week":21,"rain":5,"laps":27,"lap_km":3.4,"audience":110000},
		{"round":5,"name":"Barcelona","week":22,"rain":0,"laps":25,"lap_km":4.7,"audience":92000},
		{"round":6,"name":"Spielberg","week":26,"rain":15,"laps":24,"lap_km":4.3,"audience":105000},
		{"round":7,"name":"Silverstone","week":27,"rain":45,"laps":22,"lap_km":5.9,"audience":140000},
		{"round":8,"name":"Spa-Francorchamps","week":30,"rain":45,"laps":15,"lap_km":7.0,"audience":115000},
		{"round":9,"name":"Hungaroring","week":31,"rain":0,"laps":24,"lap_km":4.4,"audience":98000},
		{"round":10,"name":"Monza","week":35,"rain":5,"laps":22,"lap_km":5.8,"audience":135000},
		{"round":11,"name":"Baku","week":37,"rain":0,"laps":20,"lap_km":6.0,"audience":68000},
		{"round":12,"name":"Lusail","week":47,"rain":0,"laps":21,"lap_km":5.4,"audience":42000},
		{"round":13,"name":"Yas Marina","week":48,"rain":0,"laps":22,"lap_km":5.3,"audience":95000},
		{"round":14,"name":"Sakhir Sprint","week":15,"rain":0,"laps":19,"lap_km":5.4,"audience":90000},
	],
	"C-013": [ # OWC Pro (Indy NTT)
		{"round":1,"name":"St. Petersburg","week":9,"rain":0,"laps":100,"lap_km":1.8,"audience":145000},
		{"round":2,"name":"Long Beach","week":16,"rain":0,"laps":85,"lap_km":3.1,"audience":192000},
		{"round":3,"name":"Alabama","week":17,"rain":15,"laps":90,"lap_km":3.5,"audience":82000},
		{"round":4,"name":"Sonsio","week":19,"rain":0,"laps":85,"lap_km":4.1,"audience":68000},
		{"round":5,"name":"Indianapolis 500","week":21,"rain":0,"laps":200,"lap_km":4.0,"audience":345000},
		{"round":6,"name":"Detroit","week":22,"rain":100,"laps":100,"lap_km":2.6,"audience":110000},
		{"round":7,"name":"XPEL Grand Prix","week":23,"rain":0,"laps":55,"lap_km":6.4,"audience":125000},
		{"round":8,"name":"Monterey","week":25,"rain":0,"laps":95,"lap_km":3.6,"audience":84000},
		{"round":9,"name":"Toronto","week":29,"rain":50,"laps":85,"lap_km":2.8,"audience":95000},
		{"round":10,"name":"Homefront 250","week":32,"rain":0,"laps":250,"lap_km":1.4,"audience":48000},
		{"round":11,"name":"One Step 250","week":33,"rain":0,"laps":250,"lap_km":1.4,"audience":52000},
		{"round":12,"name":"GOMEX Indy 250","week":34,"rain":0,"laps":260,"lap_km":1.5,"audience":41000},
		{"round":13,"name":"Portland Grand","week":35,"rain":0,"laps":110,"lap_km":3.2,"audience":46000},
		{"round":14,"name":"Milwaukee Mile 1","week":36,"rain":0,"laps":250,"lap_km":1.6,"audience":31000},
		{"round":15,"name":"Milwaukee Mile 2","week":37,"rain":0,"laps":250,"lap_km":1.6,"audience":35000},
		{"round":16,"name":"Music City Grand Prix","week":38,"rain":0,"laps":206,"lap_km":1.6,"audience":68000},
		{"round":17,"name":"Nashville Fall","week":46,"rain":0,"laps":180,"lap_km":2.1,"audience":72000},
	],
	"C-014": [ # SC Dev (ARCA)
		{"round":1,"name":"Florida 250","week":7,"rain":0,"laps":100,"lap_km":4.0,"audience":68000},
		{"round":2,"name":"Fr8Auctions 208","week":8,"rain":0,"laps":135,"lap_km":1.6,"audience":41000},
		{"round":3,"name":"Foundation 200","week":9,"rain":0,"laps":134,"lap_km":2.4,"audience":34500},
		{"round":4,"name":"Bristol Dirt Track","week":11,"rain":0,"laps":150,"lap_km":0.9,"audience":52000},
		{"round":5,"name":"XPEL 225","week":12,"rain":10,"laps":42,"lap_km":5.5,"audience":64000},
		{"round":6,"name":"SpeedyCash 250","week":15,"rain":0,"laps":167,"lap_km":2.4,"audience":38000},
		{"round":7,"name":"Long John Silvers 200","week":16,"rain":0,"laps":200,"lap_km":0.8,"audience":43000},
		{"round":8,"name":"Heart of America 200","week":18,"rain":0,"laps":134,"lap_km":2.4,"audience":29000},
		{"round":9,"name":"South Carolina 200","week":19,"rain":0,"laps":147,"lap_km":2.2,"audience":58000},
		{"round":10,"name":"North Wilkesboro 250","week":20,"rain":100,"laps":250,"lap_km":1.0,"audience":22500},
		{"round":11,"name":"NC Education 200","week":21,"rain":0,"laps":134,"lap_km":2.4,"audience":47000},
		{"round":12,"name":"Toyota 200","week":22,"rain":0,"laps":160,"lap_km":1.5,"audience":39000},
		{"round":13,"name":"Clean Harbors 250","week":25,"rain":0,"laps":250,"lap_km":0.5,"audience":24000},
		{"round":14,"name":"Rackley Roofing 200","week":26,"rain":0,"laps":150,"lap_km":1.6,"audience":31500},
		{"round":15,"name":"CRC Brakleen 150","week":29,"rain":0,"laps":60,"lap_km":4.0,"audience":55000},
		{"round":16,"name":"Worldwide Express 250","week":31,"rain":0,"laps":250,"lap_km":0.9,"audience":36000},
		{"round":17,"name":"Lucas Oil 200","week":32,"rain":10,"laps":200,"lap_km":1.1,"audience":18200},
		{"round":18,"name":"Clean Harbors 175","week":35,"rain":0,"laps":175,"lap_km":1.6,"audience":21000},
		{"round":19,"name":"UNOH 200","week":38,"rain":0,"laps":200,"lap_km":0.9,"audience":62000},
		{"round":20,"name":"Kansas Fall 200","week":39,"rain":0,"laps":134,"lap_km":2.4,"audience":33000},
	],
	"C-015": [ # SC Truck (Craftsman Trucks) — abbreviated
		{"round":1,"name":"Florida 250","week":6,"rain":0,"laps":100,"lap_km":4.0,"audience":62000},
		{"round":2,"name":"Fr8Auctions 208","week":8,"rain":0,"laps":135,"lap_km":1.6,"audience":38000},
		{"round":3,"name":"Focused Health 250","week":9,"rain":10,"laps":46,"lap_km":5.5,"audience":74000},
		{"round":4,"name":"Phoenix 200","week":10,"rain":0,"laps":200,"lap_km":1.6,"audience":62000},
		{"round":5,"name":"Las Vegas 300","week":11,"rain":0,"laps":134,"lap_km":2.4,"audience":48000},
		{"round":6,"name":"Darlington 200","week":12,"rain":0,"laps":147,"lap_km":2.0,"audience":68000},
		{"round":7,"name":"Martinsville 250","week":13,"rain":0,"laps":250,"lap_km":0.8,"audience":46000},
		{"round":8,"name":"Rockingham 200","week":14,"rain":0,"laps":200,"lap_km":1.6,"audience":38000},
		{"round":9,"name":"Bristol 300","week":15,"rain":0,"laps":300,"lap_km":0.9,"audience":72000},
		{"round":10,"name":"Kansas 300","week":16,"rain":0,"laps":200,"lap_km":2.4,"audience":39000},
		{"round":11,"name":"Talladega 300","week":17,"rain":0,"laps":113,"lap_km":4.3,"audience":115000},
		{"round":12,"name":"Charlotte 300","week":21,"rain":0,"laps":200,"lap_km":2.4,"audience":78000},
		{"round":13,"name":"Nashville 250","week":22,"rain":0,"laps":250,"lap_km":1.6,"audience":48000},
		{"round":14,"name":"Pocono 225","week":24,"rain":0,"laps":90,"lap_km":4.0,"audience":62000},
		{"round":15,"name":"San Diego 200","week":25,"rain":0,"laps":60,"lap_km":4.1,"audience":82000},
		{"round":16,"name":"Sonoma 250","week":26,"rain":10,"laps":79,"lap_km":3.2,"audience":41500},
		{"round":17,"name":"Chicagoland 300","week":27,"rain":0,"laps":200,"lap_km":1.6,"audience":59000},
		{"round":18,"name":"Atlanta 300","week":28,"rain":0,"laps":163,"lap_km":2.5,"audience":61000},
		{"round":19,"name":"Iowa 250","week":32,"rain":0,"laps":250,"lap_km":1.4,"audience":24000},
		{"round":20,"name":"Wawa 250","week":35,"rain":0,"laps":100,"lap_km":4.0,"audience":86000},
		{"round":21,"name":"Darlington Fall 200","week":36,"rain":0,"laps":147,"lap_km":2.0,"audience":71000},
		{"round":22,"name":"Homestead-Miami","week":45,"rain":0,"laps":200,"lap_km":2.4,"audience":58000},
		{"round":23,"name":"Phoenix Playoff","week":47,"rain":0,"laps":200,"lap_km":1.6,"audience":68000},
	],
	"C-016": [ # SC Challenge (Xfinity) — key rounds
		{"round":1,"name":"Daytona","week":6,"rain":0,"laps":120,"lap_km":4.0,"audience":145000},
		{"round":2,"name":"Las Vegas","week":11,"rain":0,"laps":200,"lap_km":2.4,"audience":85000},
		{"round":3,"name":"Phoenix","week":12,"rain":0,"laps":200,"lap_km":1.6,"audience":72000},
		{"round":4,"name":"Bristol","week":15,"rain":0,"laps":300,"lap_km":0.9,"audience":95000},
		{"round":5,"name":"Talladega","week":17,"rain":0,"laps":113,"lap_km":4.3,"audience":125000},
		{"round":6,"name":"Charlotte","week":21,"rain":0,"laps":200,"lap_km":2.4,"audience":92000},
		{"round":7,"name":"Nashville","week":22,"rain":0,"laps":300,"lap_km":1.6,"audience":68000},
		{"round":8,"name":"Chicagoland","week":27,"rain":0,"laps":200,"lap_km":1.6,"audience":78000},
		{"round":9,"name":"Indianapolis","week":29,"rain":0,"laps":100,"lap_km":4.0,"audience":115000},
		{"round":10,"name":"Michigan","week":30,"rain":0,"laps":100,"lap_km":3.2,"audience":58000},
		{"round":11,"name":"Iowa","week":32,"rain":0,"laps":250,"lap_km":1.4,"audience":32000},
		{"round":12,"name":"Pocono","week":34,"rain":0,"laps":90,"lap_km":4.0,"audience":74000},
		{"round":13,"name":"Darlington","week":36,"rain":0,"laps":200,"lap_km":2.0,"audience":88000},
		{"round":14,"name":"Talladega Fall","week":43,"rain":0,"laps":113,"lap_km":4.3,"audience":135000},
		{"round":15,"name":"Martinsville Fall","week":44,"rain":0,"laps":250,"lap_km":0.8,"audience":62000},
		{"round":16,"name":"Phoenix Finale","week":45,"rain":0,"laps":200,"lap_km":1.6,"audience":85000},
		{"round":17,"name":"Homestead Finale","week":46,"rain":0,"laps":200,"lap_km":2.4,"audience":74000},
	],
	"C-017": [ # SC Cup (NASCAR Cup) — key rounds
		{"round":1,"name":"Daytona 500","week":6,"rain":0,"laps":200,"lap_km":4.0,"audience":285000},
		{"round":2,"name":"Las Vegas","week":11,"rain":0,"laps":267,"lap_km":2.4,"audience":145000},
		{"round":3,"name":"Phoenix","week":12,"rain":0,"laps":312,"lap_km":1.6,"audience":125000},
		{"round":4,"name":"Bristol","week":15,"rain":0,"laps":500,"lap_km":0.9,"audience":165000},
		{"round":5,"name":"Talladega","week":17,"rain":0,"laps":188,"lap_km":4.3,"audience":205000},
		{"round":6,"name":"Charlotte 600","week":21,"rain":0,"laps":400,"lap_km":2.4,"audience":175000},
		{"round":7,"name":"Nashville","week":22,"rain":0,"laps":300,"lap_km":1.6,"audience":128000},
		{"round":8,"name":"Indianapolis","week":29,"rain":0,"laps":200,"lap_km":4.0,"audience":215000},
		{"round":9,"name":"Michigan","week":30,"rain":0,"laps":200,"lap_km":3.2,"audience":98000},
		{"round":10,"name":"Daytona Summer","week":33,"rain":10,"laps":160,"lap_km":4.0,"audience":185000},
		{"round":11,"name":"Pocono","week":34,"rain":0,"laps":160,"lap_km":4.0,"audience":115000},
		{"round":12,"name":"Darlington","week":36,"rain":0,"laps":367,"lap_km":2.0,"audience":145000},
		{"round":13,"name":"Talladega Fall","week":43,"rain":0,"laps":188,"lap_km":4.3,"audience":220000},
		{"round":14,"name":"Martinsville Fall","week":44,"rain":0,"laps":500,"lap_km":0.8,"audience":145000},
		{"round":15,"name":"Phoenix Championship","week":45,"rain":0,"laps":312,"lap_km":1.6,"audience":185000},
		{"round":16,"name":"Homestead Finale","week":46,"rain":0,"laps":267,"lap_km":2.4,"audience":165000},
	],
	"C-018": [ # EPC Series (LMP3 / F4)
		{"round":1,"name":"Brands Hatch Indy","week":14,"rain":0,"laps":24,"lap_km":1.9,"audience":14000},
		{"round":2,"name":"Donington National","week":18,"rain":20,"laps":18,"lap_km":3.2,"audience":12200},
		{"round":3,"name":"Thruxton High-Speed","week":22,"rain":60,"laps":17,"lap_km":3.8,"audience":16500},
		{"round":4,"name":"Oulton Park Island","week":26,"rain":45,"laps":15,"lap_km":3.6,"audience":18900},
		{"round":5,"name":"Croft Circuit Shootout","week":32,"rain":0,"laps":16,"lap_km":3.4,"audience":11000},
		{"round":6,"name":"Silverstone National","week":38,"rain":20,"laps":21,"lap_km":2.6,"audience":28500},
	],
	"C-019": [ # EPC League (LMP2 / F3)
		{"round":1,"name":"Sakhir","week":9,"rain":0,"laps":19,"lap_km":5.4,"audience":95000},
		{"round":2,"name":"Albert Park","week":11,"rain":20,"laps":20,"lap_km":5.3,"audience":125000},
		{"round":3,"name":"Imola","week":20,"rain":15,"laps":18,"lap_km":4.9,"audience":88000},
		{"round":4,"name":"Monaco","week":21,"rain":5,"laps":23,"lap_km":3.4,"audience":110000},
		{"round":5,"name":"Barcelona","week":22,"rain":0,"laps":21,"lap_km":4.7,"audience":92000},
		{"round":6,"name":"Spielberg","week":26,"rain":15,"laps":21,"lap_km":4.3,"audience":105000},
		{"round":7,"name":"Silverstone","week":27,"rain":45,"laps":18,"lap_km":5.9,"audience":140000},
		{"round":8,"name":"Spa-Francorchamps","week":30,"rain":45,"laps":12,"lap_km":7.0,"audience":115000},
		{"round":9,"name":"Hungaroring","week":31,"rain":0,"laps":19,"lap_km":4.4,"audience":98000},
		{"round":10,"name":"Monza","week":35,"rain":5,"laps":18,"lap_km":5.8,"audience":135000},
	],
	"C-020": [ # EPC Hyper (WEC)
		{"round":1,"name":"Bathurst 12 Hour","week":5,"rain":0,"laps":12,"lap_km":6.2,"audience":53000},
		{"round":2,"name":"Sebring 1000","week":10,"rain":20,"laps":18,"lap_km":5.9,"audience":48000},
		{"round":3,"name":"Spa 6 Hour","week":18,"rain":50,"laps":6,"lap_km":7.0,"audience":65000},
		{"round":4,"name":"24h Le Mans","week":24,"rain":35,"laps":24,"lap_km":13.6,"audience":385000},
		{"round":5,"name":"Monza 6 Hour","week":33,"rain":10,"laps":6,"lap_km":5.8,"audience":78000},
		{"round":6,"name":"Fuji 6 Hour","week":39,"rain":20,"laps":6,"lap_km":4.6,"audience":42000},
		{"round":7,"name":"Bahrain 8 Hour","week":49,"rain":0,"laps":8,"lap_km":5.4,"audience":38000},
	],
	"C-021": [ # GP4 (F4)
		{"round":1,"name":"Brands Hatch Indy","week":14,"rain":0,"laps":24,"lap_km":1.9,"audience":14000},
		{"round":2,"name":"Donington National","week":18,"rain":20,"laps":18,"lap_km":3.2,"audience":12200},
		{"round":3,"name":"Thruxton High-Speed","week":22,"rain":60,"laps":17,"lap_km":3.8,"audience":16500},
		{"round":4,"name":"Oulton Park Island","week":26,"rain":45,"laps":15,"lap_km":3.6,"audience":18900},
		{"round":5,"name":"Croft Circuit Shootout","week":32,"rain":0,"laps":16,"lap_km":3.4,"audience":11000},
		{"round":6,"name":"Silverstone National","week":38,"rain":20,"laps":21,"lap_km":2.6,"audience":28500},
	],
	"C-022": [ # GP3 (F3)
		{"round":1,"name":"Sakhir","week":9,"rain":0,"laps":19,"lap_km":5.4,"audience":95000},
		{"round":2,"name":"Albert Park","week":11,"rain":20,"laps":20,"lap_km":5.3,"audience":125000},
		{"round":3,"name":"Imola","week":20,"rain":15,"laps":18,"lap_km":4.9,"audience":88000},
		{"round":4,"name":"Monaco","week":21,"rain":5,"laps":23,"lap_km":3.4,"audience":110000},
		{"round":5,"name":"Barcelona","week":22,"rain":0,"laps":21,"lap_km":4.7,"audience":92000},
		{"round":6,"name":"Spielberg","week":26,"rain":15,"laps":21,"lap_km":4.3,"audience":105000},
		{"round":7,"name":"Silverstone","week":27,"rain":45,"laps":18,"lap_km":5.9,"audience":140000},
		{"round":8,"name":"Spa-Francorchamps","week":30,"rain":45,"laps":12,"lap_km":7.0,"audience":115000},
		{"round":9,"name":"Hungaroring","week":31,"rain":0,"laps":19,"lap_km":4.4,"audience":98000},
		{"round":10,"name":"Monza","week":35,"rain":5,"laps":18,"lap_km":5.8,"audience":135000},
	],
	"C-023": [ # GP2 (F2)
		{"round":1,"name":"Sakhir","week":9,"rain":0,"laps":23,"lap_km":5.4,"audience":97000},
		{"round":2,"name":"Jeddah","week":10,"rain":0,"laps":20,"lap_km":6.2,"audience":85000},
		{"round":3,"name":"Albert Park","week":11,"rain":20,"laps":22,"lap_km":5.3,"audience":131000},
		{"round":4,"name":"Imola","week":20,"rain":15,"laps":25,"lap_km":4.9,"audience":92000},
		{"round":5,"name":"Monaco","week":21,"rain":5,"laps":30,"lap_km":3.4,"audience":115000},
		{"round":6,"name":"Barcelona","week":22,"rain":0,"laps":26,"lap_km":4.7,"audience":96000},
		{"round":7,"name":"Spielberg","week":26,"rain":15,"laps":28,"lap_km":4.3,"audience":108000},
		{"round":8,"name":"Silverstone","week":27,"rain":45,"laps":21,"lap_km":5.9,"audience":144000},
		{"round":9,"name":"Spa-Francorchamps","week":30,"rain":45,"laps":18,"lap_km":7.0,"audience":120000},
		{"round":10,"name":"Hungaroring","week":31,"rain":0,"laps":28,"lap_km":4.4,"audience":99000},
		{"round":11,"name":"Monza","week":35,"rain":5,"laps":21,"lap_km":5.8,"audience":140000},
		{"round":12,"name":"Baku","week":37,"rain":0,"laps":21,"lap_km":6.0,"audience":72000},
		{"round":13,"name":"Lusail","week":47,"rain":0,"laps":22,"lap_km":5.4,"audience":45000},
		{"round":14,"name":"Yas Marina","week":48,"rain":0,"laps":23,"lap_km":5.3,"audience":115000},
	],
	"C-024": [ # GP1 (F1)
		{"round":1,"name":"Australian Grand Prix","week":10,"rain":0,"laps":58,"lap_km":5.3,"audience":145000},
		{"round":2,"name":"Chinese Grand Prix","week":11,"rain":10,"laps":56,"lap_km":5.5,"audience":110000},
		{"round":3,"name":"Suzuka","week":13,"rain":35,"laps":53,"lap_km":5.8,"audience":125000},
		{"round":4,"name":"Sakhir","week":15,"rain":0,"laps":57,"lap_km":5.4,"audience":98000},
		{"round":5,"name":"Jeddah","week":16,"rain":0,"laps":50,"lap_km":6.2,"audience":85000},
		{"round":6,"name":"Imola","week":18,"rain":20,"laps":57,"lap_km":4.9,"audience":92000},
		{"round":7,"name":"Montréal","week":21,"rain":40,"laps":70,"lap_km":4.4,"audience":135000},
		{"round":8,"name":"Monaco","week":23,"rain":5,"laps":78,"lap_km":3.4,"audience":68000},
		{"round":9,"name":"Barcelona","week":24,"rain":0,"laps":66,"lap_km":4.7,"audience":115000},
		{"round":10,"name":"Spielberg","week":26,"rain":0,"laps":71,"lap_km":4.3,"audience":105000},
		{"round":11,"name":"Silverstone","week":27,"rain":45,"laps":52,"lap_km":5.9,"audience":145000},
		{"round":12,"name":"Hungaroring","week":31,"rain":0,"laps":70,"lap_km":4.4,"audience":95000},
		{"round":13,"name":"Spa-Francorchamps","week":32,"rain":45,"laps":44,"lap_km":7.0,"audience":105000},
		{"round":14,"name":"Zandvoort","week":33,"rain":30,"laps":72,"lap_km":4.3,"audience":105000},
		{"round":15,"name":"Monza","week":35,"rain":5,"laps":53,"lap_km":5.8,"audience":140000},
		{"round":16,"name":"Baku","week":37,"rain":0,"laps":51,"lap_km":6.0,"audience":72000},
		{"round":17,"name":"Singapore","week":39,"rain":20,"laps":62,"lap_km":5.1,"audience":125000},
		{"round":18,"name":"Austin","week":41,"rain":30,"laps":56,"lap_km":5.5,"audience":138000},
		{"round":19,"name":"Mexico City","week":42,"rain":10,"laps":71,"lap_km":4.3,"audience":115000},
		{"round":20,"name":"São Paulo","week":43,"rain":40,"laps":71,"lap_km":4.3,"audience":108000},
		{"round":21,"name":"Las Vegas","week":46,"rain":0,"laps":50,"lap_km":6.2,"audience":95000},
		{"round":22,"name":"Lusail","week":47,"rain":0,"laps":57,"lap_km":5.4,"audience":62000},
		{"round":23,"name":"Yas Marina","week":48,"rain":0,"laps":58,"lap_km":5.3,"audience":115000},
		{"round":24,"name":"Abu Dhabi","week":49,"rain":0,"laps":58,"lap_km":5.3,"audience":110000},
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
			"weekly_income": 0,
			"build_cost": 55000,
			"build_time": 12,
			"upgrade_cost": 18000,
			"upgrade_time": 6,
			"effects": "Enables income from Karting, Gravel, Oval and Race Track buildings.\n+10% track income per PRC level."
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
			"build_cost": 55000,
			"build_time": 14,
			"upgrade_cost": 22000,
			"upgrade_time": 8,
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

	# Driver salaries — from championship base salary
	var driver_salary = 50.0
	if active_championship != null and active_championship.id != "":
		driver_salary = _get_championship_driver_salary()
	player_expenses += player_team.drivers.size() * driver_salary

	# Staff salaries — sum all hired staff
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.contract_team == player_team.id:
			player_expenses += staff.weekly_salary

	player_team.balance -= player_expenses
	add_log("Weekly expenses paid: -CR %d (drivers: CR %d + staff: CR %d)" % [
		int(player_expenses),
		int(player_team.drivers.size() * driver_salary),
		int(player_expenses - player_team.drivers.size() * driver_salary)
	])

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
	# RP only accumulates if the team has an R&D Design Studio AND at least one Designer.
	var rnd_studio = campus_buildings.get("R&D Design Studio", {})
	if not rnd_studio.get("built", false):
		return
	var designers = get_player_staff_by_role("Designer")
	if designers.is_empty():
		return
	# Each Designer contributes proportionally to their design_skill
	var design_power = 0.0
	for d in designers:
		design_power += d.design_skill / 100.0
	var rp_gained = laps * 0.5 * design_power
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
	"A_01": {"top_speed": 75.0,  "acceleration": 9.8,  "deceleration": 11.2, "cornering_grip": 2.9,  "fuel_per_km": 0.045, "tire_wear": 0.65, "perf_index": 1},
	"A_02": {"top_speed": 115.0, "acceleration": 10.5, "deceleration": 12.1, "cornering_grip": 2.95, "fuel_per_km": 0.055, "tire_wear": 0.72, "perf_index": 10},
	"A_21": {"top_speed": 315.0, "acceleration": 11.8, "deceleration": 12.7, "cornering_grip": 3.2,  "fuel_per_km": 0.32,  "tire_wear": 1.15, "perf_index": 50},
}

func _setup_cars() -> void:
	## Cars are created independently via add_car() — not tied to driver hire.
	## At game start, player has no cars. They must build cars via the Garage.
	player_team_cars = []

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

func get_part_stock(part_name: String) -> int:
	var champ_id = active_championship.id
	if not champ_id in part_inventory:
		return 0
	return part_inventory[champ_id].get(part_name, 0)

func buy_part(part_name: String, quantity: int) -> bool:
	var champ_id = active_championship.id
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

func hire_staff(staff_id: String) -> bool:
	if not staff_id in all_staff:
		return false
	var staff = all_staff[staff_id]
	if staff.is_hired():
		return false
	## One TP per team, one CFO per team — enforce limits
	if staff.role == "Team Principal":
		var existing_tp = get_player_staff_by_role("Team Principal")
		if existing_tp.size() >= 1:
			add_notification("High", "You already have a Team Principal. Release them first.")
			return false
	if staff.role == "CFO":
		var existing_cfo = get_player_staff_by_role("CFO")
		if existing_cfo.size() >= 1:
			add_notification("High", "You already have a CFO. Release them first.")
			return false
	staff.contract_team = player_team.id
	staff.contract_seasons_remaining = 5
	add_log("✅ Hired %s (%s) — CR %.0f/week" % [staff.full_name(), staff.role, staff.weekly_salary])
	add_notification("Normal", "%s (%s) joined your team." % [staff.full_name(), staff.role])
	emit_signal("log_updated")
	return true

func release_staff(staff_id: String) -> void:
	if not staff_id in all_staff:
		return
	var staff = all_staff[staff_id]
	staff.contract_team = ""
	staff.assigned_championship = ""
	staff.assigned_car_id = ""
	staff.contract_seasons_remaining = 0
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
	driver.contract_team = ""
	driver.contract_seasons_remaining = 0
	player_team.drivers.erase(driver_id)
	# Unassign from any car they were in
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
	# Unassign from any current car first
	for car in player_team_cars:
		if car.driver_id == driver_id:
			car.driver_id = ""
	# Assign to new car
	var car = get_car_by_id(car_id)
	if car:
		# Unassign whoever was in this car
		if car.driver_id != "" and car.driver_id != driver_id:
			var old_driver = all_drivers.get(car.driver_id)
			if old_driver:
				add_log("↩ %s unassigned from Car %d" % [old_driver.full_name(), car.car_number])
		car.driver_id = driver_id
		var driver = all_drivers.get(driver_id)
		add_log("🏎 %s assigned to Car %d" % [driver.full_name() if driver else driver_id, car.car_number])
		emit_signal("log_updated")

## Creates a new empty car slot. Capped by Garage level.
## Called from the Garage scene — independent of driver hire.
## Generates a car display name: e.g. GKR-S1-A, GKN-S3-B
## Must be called BEFORE appending the new car to player_team_cars.
func generate_car_name() -> String:
	# Use active championship ID, or first registered if off-season
	var champ_id = active_championship.id
	if champ_id == "" and not player_registered_championships.is_empty():
		champ_id = player_registered_championships[0]
	if champ_id == "" and not active_championships.is_empty():
		champ_id = active_championships[0].id
	const CHAMP_CODES = {
		"C-001": "GKR", "C-002": "GKN", "C-003": "GKC", "C-004": "GKW",
		"C-005": "RL4", "C-006": "RL3", "C-007": "RL2", "C-008": "RLP",
		"C-009": "TCS", "C-010": "TCE",
		"C-011": "OWN", "C-012": "OWD", "C-013": "OWP",
		"C-014": "SCD", "C-015": "SCT", "C-016": "SCC", "C-017": "SCU",
		"C-018": "EPS", "C-019": "EPL", "C-020": "EPH",
		"C-021": "GP4", "C-022": "GP3", "C-023": "GP2", "C-024": "GP1",
	}
	var code   = CHAMP_CODES.get(champ_id, "CAR")
	var season = "S%d" % current_season
	var letter = char(65 + player_team_cars.size())  # A, B, C... — call BEFORE append
	return "%s-%s-%s" % [code, season, letter]

func add_car() -> bool:
	var max_c = get_max_cars()
	if player_team_cars.size() >= max_c:
		add_notification("High",
			"Garage full (%d/%d slots). Upgrade the Garage to field more cars." % [
			player_team_cars.size(), max_c])
		return false
	var car_number = player_team_cars.size() + 1
	var car        = Car.new()
	car.id         = "CAR-P%03d" % car_number
	car.car_type_id    = "A_01"
	car.championship_id = active_championship.id
	car.car_number = car_number
	car.car_name   = generate_car_name()  # generated BEFORE append — size() gives correct letter
	car.driver_id  = ""
	car.mechanic_id = ""
	car.pit_crew_id = "N/A" if active_championship.discipline == "GK" else ""
	car.condition   = 100.0
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
	player_team_cars.append(car)
	add_log("🏎 %s added to garage — assign a driver and mechanic before racing." % car.car_name)
	add_notification("Normal", "%s ready. Assign a driver via the Garage or Drivers screen." % car.car_name)
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
	staff.assigned_car_id = car_id
	staff.assigned_championship = active_championship.id
	# Wire mechanic to car
	var car = get_car_by_id(car_id)
	if car:
		if staff.role == "Race Mechanic":
			car.mechanic_id = staff_id
		elif staff.role == "Pit Crew":
			car.pit_crew_id = staff_id
	add_log("🔧 %s assigned to Car %s" % [staff.full_name(), car_id])

func assign_staff_to_championship(staff_id: String, champ_id: String) -> void:
	if not staff_id in all_staff:
		return
	var staff = all_staff[staff_id]
	staff.assigned_championship = champ_id
	add_log("📋 %s assigned to %s" % [staff.full_name(), active_championship.championship_name])

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

	# Cars with DNS conditions
	for car in player_team_cars:
		if car.driver_id == "":
			tasks.append("🏎 Car %d has no driver — will DNS." % car.car_number)
		if car.mechanic_id == "":
			tasks.append("🔧 Car %d has no Race Mechanic — will DNS." % car.car_number)

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

	# No Team Principal
	if get_team_principal() == null:
		tasks.append("⚠ No Team Principal assigned — hire one at HQ or via Staff screen.")

	# No CFO
	if get_cfo() == null:
		tasks.append("💼 No CFO hired — financial monitoring and sponsor optimisation unavailable.")

	# Cars with no driver
	for car in player_team_cars:
		if car.driver_id == "":
			tasks.append("🏎 Car %d has no driver assigned." % car.car_number)

	# Cars with no mechanic — this causes DNS and blocks repairs
	for car in player_team_cars:
		if car.mechanic_id == "":
			tasks.append("🔧 Car %d has no Race Mechanic — DNS risk and repairs blocked!" % car.car_number)

	# No drivers hired at all
	if player_team.drivers.is_empty():
		tasks.append("👤 No drivers signed — hire a driver from the Drivers screen before racing.")

	# Low fuel — next race approaching
	if active_championship != null:
		var next_race = active_championship.get_next_race()
		if next_race:
			var weeks_until = next_race["week"] - current_week
			if weeks_until <= 2 and fuel_kg < active_championship.fuel_per_car_per_race:
				tasks.append("⛽ Fuel below race minimum (%.0f kg). DNS risk in %d week%s." % [
					fuel_kg, weeks_until, "s" if weeks_until != 1 else ""])

	# Low SP — next race approaching
	if active_championship != null:
		var next_race_sp = active_championship.get_next_race()
		if next_race_sp:
			var weeks_until = next_race_sp["week"] - current_week
			if weeks_until <= 2 and spare_parts < active_championship.sp_per_10_pct_damage:
				tasks.append("🔧 SP below repair minimum (%d units). Consider buying more." % spare_parts)

	# Negative balance
	if player_team.balance < 0:
		tasks.append("💸 Balance is negative (CR %.0f). Bankruptcy risk." % player_team.balance)

	# Car condition critically low
	for car in player_team_cars:
		if car.condition < 30.0:
			tasks.append("🔩 Car %d condition critical (%.0f%%) — repair before next race." % [
				car.car_number, car.condition])

	# Expiring contracts (1 season left)
	for driver_id in player_team.drivers:
		var driver = all_drivers.get(driver_id)
		if driver and driver.contract_seasons_remaining <= 1:
			tasks.append("📋 %s's contract expires soon — consider renewing." % driver.full_name())
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.contract_team == player_team.id and staff.contract_seasons_remaining <= 1:
			tasks.append("📋 %s (%s) contract expires soon." % [staff.full_name(), staff.role])

	return tasks

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

func _degrade_car_conditions(laps: int, dns_driver_ids: Array = []) -> void:
	var loss = active_championship.condition_loss_per_lap * float(laps)
	for car in player_team_cars:
		if car.driver_id in dns_driver_ids:
			add_log("🔩 Car %d condition unchanged (DNS)" % car.car_number)
			continue
		car.condition = max(0.0, car.condition - loss)
		add_log("🔩 Car %d condition after race: %.0f%% (-%0.1f%% over %d laps)" % [
			car.car_number, car.condition, loss, laps])

func _auto_repair_cars_post_race() -> void:
	if player_team_cars.is_empty():
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
	# DNS: no fuel
	var fuel_needed = active_championship.fuel_per_car_per_race
	if fuel_kg < fuel_needed:
		add_notification("Critical",
			"DNS: Not enough fuel (%.1f kg). Need %.1f kg. Buy fuel at Logistics Center." % [
				fuel_kg, fuel_needed])
		add_log("🚫 DNS — Insufficient fuel for race start.")
		return false
	# DNS: no race mechanic assigned to car
	var car = get_car_for_driver(driver_id)
	if car and car.mechanic_id == "":
		add_notification("Critical",
			"DNS: Car %d has no Race Mechanic assigned! Hire and assign a mechanic before racing." % car.car_number)
		add_log("🚫 DNS — No Race Mechanic assigned to Car %d." % car.car_number)
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

func get_upgrade_cost(building: Dictionary) -> int:
	var base = building["upgrade_cost"]
	var level = building["level"]
	var scaled = base * pow(1.5, level)
	return int(round(scaled / 500.0) * 500)

## Returns the scaled upgrade time for the next level.
## Adds 1 week every 3 levels on top of the base time.
func get_upgrade_time(building: Dictionary) -> int:
	return building["upgrade_time"] + int(building["level"] / 3)

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

func get_hq_marketability_bonus() -> float:
	var hq = campus_buildings.get("Headquarters (HQ)", {})
	if not hq.get("built", false): return 0.0
	return float(hq.get("level", 1))

func get_hq_sponsor_slots() -> int:
	var hq = campus_buildings.get("Headquarters (HQ)", {})
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
	if total_income > 0 or total_maintenance > 0:
		add_log("🏗 Campus: +CR %d income / -CR %d maintenance" % [total_income, total_maintenance])

func setup_new_game(p_team_name: String, p_nationality: String, p_player_name: String, p_starting_budget: int = 50000) -> void:
	current_week = 1
	current_season = 1
	weekly_log = []
	last_race_results = []
	hall_of_fame = []
	all_teams = []
	all_drivers = {}
	all_staff = {}
	_setup_championship()
	player_name = p_player_name
	player_team_name = p_team_name
	player_team_nationality = p_nationality
	_setup_player_team()
	player_team.balance = float(p_starting_budget)
	_generate_drivers()
	_generate_ai_teams()
	_setup_campus()
	_setup_sponsor()
	_setup_cars()
	_setup_part_inventory()
	_generate_available_staff(60)
	add_log("Welcome to Automotive Empire!")
	add_log("Season %d — GK Regional Championship" % current_season)

func _setup_championship() -> void:
	active_championships.clear()
	var champ = Championship.new()
	champ.id = "C-001"
	champ.championship_name = "GK Regional Championship"
	champ.discipline = "GK"
	champ.tier = 1
	champ.min_age = 8
	champ.max_age = 16
	champ.entry_fee_per_race = 1500.0
	champ.num_races = 6
	champ.points_system = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
	champ.prize_1st = 300.0
	champ.prize_2nd = 150.0
	champ.prize_3rd = 75.0
	champ.sp_per_10_pct_damage = 100
	champ.fuel_per_car_per_race = 15.0
	champ.condition_loss_per_lap = 0.5
	champ.condition_loss_per_stage = 0.0
	champ.repair_time_per_1pct = 0.0
	champ.has_mid_race_repairs = false
	champ.service_park_every_n_stages = 0
	champ.pit_stop_repair_pct = 0.0

	champ.calendar = []
	for race in CHAMPIONSHIP_CALENDARS.get("C-001", []):
		champ.calendar.append({
			"round": race["round"], "name": race["name"], "week": race["week"],
			"rain_probability": race["rain"], "laps": race["laps"],
			"lap_km": race.get("lap_km", 1.0), "audience": race["audience"],
		})
	active_championships.append(champ)
	# player_registered_championships starts empty — player must register via ChampionshipSelect
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
	## Player starts with NO driver — they must hire from the free agent pool.
	## Generate 8 young free agent drivers (ages 8-12) for the player to choose from.
	## They are NOT added to championship standings — only contracted drivers race.
	var nationalities = ["British", "Italian", "German", "French", "Spanish",
		"Finnish", "Brazilian", "Japanese", "American", "Australian"]
	for i in range(8):
		var nat = nationalities[randi() % nationalities.size()]
		var sex = "Male" if randf() > 0.3 else "Female"
		var age = randi_range(8, 12)
		var name_data = NameGenerator.get_full_name(nat, sex)
		var driver_id = "D-FA-%03d" % i
		var driver = _create_driver(driver_id, name_data["first"], name_data["last"],
			nat, age, sex, "")  # contract_team = "" = free agent, not racing
		all_drivers[driver_id] = driver
		# NOT added to active_championship.standings — free agents don't race

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

	# Guard: never advance past max_weeks
	if current_week >= max_weeks:
		_end_season()
		return

	current_week += 1

	# Weekly fitness recovery (drivers)
	_apply_weekly_fitness_recovery()

	# Weekly pit crew fitness recovery
	_recover_pit_crew_fitness()

	# Campus construction progress
	_update_campus_construction()

	# Campus income and maintenance
	_apply_campus_income()

	# Sponsor income
	_apply_sponsor_income()

	# Full staff expenses
	_apply_weekly_expenses()

	# CFO part inventory check (weekly reminder if stock is low)
	_check_part_inventory_notifications()

	# Check for races this week across ALL active championships
	for champ in active_championships:
		var next_race = champ.get_next_race()
		if next_race and next_race["week"] == current_week:
			_check_race_requirements_for(champ)
			_simulate_race(next_race, champ)
			_update_sponsor_performance(last_race_results)
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
		if deadline == current_week + 4:
			add_notification("Normal",
				"📋 4 weeks until %s registration closes (Week %d)." % [reg["name"], deadline])
		elif deadline == current_week + 1:
			add_notification("High",
				"⚠ LAST CHANCE: %s registration deadline is NEXT WEEK (Week %d)! Entry fee: CR %s." % [
				reg["name"], deadline, _fmt_int(reg["entry_fee"])])
		elif deadline == current_week:
			add_notification("High",
				"🚨 TODAY is the last day to register for %s! After this week the deadline is missed." % reg["name"])

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

	# Effective attributes
	var mech_setup:   float = 0.0
	var mech_track:   float = 0.0
	var strat_pace:   float = 0.0
	var strat_track:  float = 0.0
	if mechanic != null:
		mech_setup = mechanic.car_setup    * tp_factor
		mech_track = mechanic.track_knowledge * tp_factor
	if strategist != null:
		strat_pace  = strategist.race_strategy  * tp_factor
		strat_track = strategist.track_knowledge * tp_factor

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
 
	# ── DNS check: player cars need enough fuel to start ──────
	var dns_driver_ids: Array = []
	if player_team.drivers.size() > 0:
		if not _can_car_race(player_team.drivers[0]):
			for d_id in player_team.drivers:
				dns_driver_ids.append(d_id)
 
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
	var driver_times = []
	for driver in race_drivers:
		var base_time = 28.5
		var effective_pace  = driver.get_effective_pace()
		var effective_wet   = driver.get_effective_wet()
		var effective_focus = driver.get_effective_focus()

		var pace_factor    = 1.0 - (effective_pace / 1000.0)
		var wet_factor     = 1.0
		if is_wet:
			wet_factor = 1.0 + ((100.0 - effective_wet) / 200.0)
		var focus_factor   = 1.0 - (effective_focus / 2000.0)
		var fitness_factor = driver.fitness_penalty()
		var lap_time = base_time * pace_factor * wet_factor * focus_factor * (2.0 - fitness_factor)

		# Apply Staff_Synergy_Factor for player drivers (simulated races only).
		# Formula: lap_time /= staff_synergy → higher synergy = faster lap.
		if driver.id in player_team.drivers:
			lap_time /= staff_synergy
			# Wind Tunnel aero bonus
			var aero_bonus = get_wind_tunnel_aero_bonus()
			if aero_bonus > 0.0:
				lap_time /= (1.0 + aero_bonus)
			# Track discipline bonus
			if track_perf_bonus > 0.0:
				lap_time /= (1.0 + track_perf_bonus)

		# Noise based on consistency — high consistency = tight laps
		var noise = driver.get_lap_noise_range()
		lap_time += randf_range(-noise, noise)
		driver_times.append({
			"driver": driver,
			"lap_time": lap_time,
			"total_time": lap_time * race_data["laps"],
			"points": 0
		})
 
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
		for team in all_teams:
			if driver.id in team.drivers:
				c.add_team_points(team.id, pts)
				var prize = 0.0
				if standing_position == 1:
					prize = c.prize_1st
				elif standing_position == 2:
					prize = c.prize_2nd
				elif standing_position == 3:
					prize = c.prize_3rd
				team.balance += prize
				break
 
		# Update driver stats
		_update_driver_stats_after_race(driver, standing_position, race_data["laps"], is_wet, race_drivers.size())
 
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
 
	# ── Car condition: degrade only cars that raced, skip DNS ────────────────
	_degrade_car_conditions(race_data["laps"], dns_driver_ids)
	_auto_repair_cars_post_race()

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

func _update_driver_stats_after_race(driver: Driver, standing_position: int, laps: int, is_wet: bool, grid_size: int) -> void:
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

	_process_off_season()

	# ── Wipe ALL player cars ─────────────────────────────────────────────────
	player_team_cars.clear()
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
				# Re-use existing championship object, reset for new season
				var existing = prev_by_id[champ_id]
				existing.reset_for_new_season()
				active_championships.append(existing)
			else:
				# Newly registered championship
				var new_champ = _create_championship(champ_id)
				if new_champ:
					active_championships.append(new_champ)
					add_log("🏆 Now competing in: %s" % new_champ.championship_name)

	# Delivery deadline notifications
	for champ in active_championships:
		var delivery_wk = get_car_delivery_week(champ.id)
		var race1_wk    = FIRST_RACE_WEEK.get(champ.id, 6)
		add_notification("High",
			"Season %d [%s]: New car needed. Delivery: Week %d. Race 1: Week %d." % [
			current_season, champ.championship_name, delivery_wk, race1_wk])

	# Re-register all eligible drivers and teams
	for champ in active_championships:
		for team in all_teams:
			for driver_id in team.drivers:
				if driver_id in all_drivers:
					var driver = all_drivers[driver_id]
					if driver.age >= champ.min_age and driver.age <= champ.max_age:
						champ.standings[driver_id] = 0
		for team in all_teams:
			champ.team_standings[team.id] = 0

	add_log("=== SEASON %d BEGINS ===" % current_season)

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
		car.pit_crew_id = "N/A"
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
		"part_inventory": part_inventory,
		"player_team_cars": _serialize_cars(),
		"all_staff": _serialize_staff(),
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
		s.qualifying_timing = sd.get("qualifying_timing", 0.0)
		all_staff[staff_id] = s
		# Track counter for future generation
		var num_part = sd["id"].trim_prefix("ST-").to_int()
		if num_part > _staff_id_counter:
			_staff_id_counter = num_part

func add_log(message: String) -> void:
	weekly_log.append(message)
	print(message)
