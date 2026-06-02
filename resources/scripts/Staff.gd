class_name Staff
extends Resource

# ── Identity ──────────────────────────────────────────────────────────────────
@export var id: String = ""
@export var first_name: String = ""
@export var last_name: String = ""
@export var nationality: String = ""
@export var age: int = 30
@export var sex: String = "Male"

# ── Role ──────────────────────────────────────────────────────────────────────
## Valid roles: "Race Mechanic" | "Pit Crew" | "Team Principal" |
##              "CFO" | "Designer" | "Race Strategist"
@export var role: String = ""

# ── Hidden ────────────────────────────────────────────────────────────────────
@export var talent: float = 50.0   # NEVER shown to player — growth ceiling

# ── Shown ─────────────────────────────────────────────────────────────────────
@export var reputation: float = 0.0
@export var morale: float = 100.0
@export var weekly_salary: float = 0.0
@export var contract_seasons_remaining: int = 5
@export var contract_team: String = ""       # team_id; "" = available for hire
@export var assigned_championship: String = "" # championship_id; "" = unassigned
@export var assigned_car_id: String = ""     # car_id; for Mechanic and Pit Crew

# Discipline adaptation (shared by Mechanic, Designer, Strategist)
@export var discipline_adaptation: Dictionary = {
	"GK": 1.0, "Rally": 1.0, "TC": 1.0,
	"OWC": 1.0, "SC": 1.0, "EPC": 1.0, "GP": 1.0
}

# ── Race Mechanic attributes ──────────────────────────────────────────────────
@export var car_setup: float = 0.0       # Quality of setup work — affects lap time
@export var pit_stops: float = 0.0       # Pit stop execution quality
@export var car_knowledge: float = 0.0   # Understanding of car systems
@export var track_knowledge: float = 0.0 # Track-specific setup knowledge; grows per event

# ── Pit Crew attributes ───────────────────────────────────────────────────────
@export var pit_stop_speed: float = 0.0  # Speed of pit stop operations
@export var repair_skill: float = 0.0    # Quality and speed of repairs
@export var teamwork: float = 0.0        # Coordination with rest of crew
@export var fitness: float = 100.0       # Physical condition; drops after events, recovers weekly

# ── Team Principal attributes ─────────────────────────────────────────────────
## TP attributes act as MULTIPLIERS on other staff's values (per spec)
@export var race_strategy: float = 0.0         # Amplifies strategist's race_strategy
@export var practice_management: float = 0.0   # Amplifies strategist's practice_scheduling
@export var qualifying_management: float = 0.0 # Amplifies strategist's qualifying_timing
@export var race_pace_reading: float = 0.0     # Amplifies strategist's race_pace_reading
@export var car_setup_oversight: float = 0.0   # Amplifies mechanic's car_setup
@export var pit_stop_management: float = 0.0   # Amplifies pit crew's pit_stop_speed
@export var pr_skill: float = 0.0              # Boosts team reputation and marketability

# ── CFO attributes ────────────────────────────────────────────────────────────
@export var loan_management: float = 0.0     # Improves loan amount available
@export var interest_rates: float = 0.0      # Reduces loan interest rate
@export var sales_skill: float = 0.0         # Boosts commercial car sales revenue
@export var sponsor_negotiation: float = 0.0 # Improves sponsor deal value
@export var resource_management: float = 0.0 # Improves SP/fuel warning thresholds and cost
@export var budget_planning: float = 0.0     # Accuracy of financial projections

# ── Designer attributes ───────────────────────────────────────────────────────
@export var engine: float = 0.0      # Engine development skill
@export var aero: float = 0.0        # Aerodynamics development skill
@export var brakes: float = 0.0      # Brakes development skill
@export var suspension: float = 0.0  # Suspension development skill
@export var chassis: float = 0.0     # Chassis development skill
@export var gearbox: float = 0.0     # Gearbox development skill
@export var reliability: float = 0.0 # Reduces part failure probability
@export var parts_knowledge: float = 0.0 # Knowledge of available parts market

# ── Race Strategist attributes ────────────────────────────────────────────────
# race_strategy, race_pace_reading, track_knowledge shared with TP fields above
@export var practice_scheduling: float = 0.0  # Optimises practice session programs
@export var qualifying_timing: float = 0.0    # Optimises qualifying lap release timing

## Pit Crew unit number — set at hire time (1, 2, 3...).
## Crew is displayed as "Crew #N" with individual as "Crew Chief".
@export var crew_number: int = 0

# ── Helpers ───────────────────────────────────────────────────────────────────

func full_name() -> String:
	return first_name + " " + last_name

## Display name: Pit Crew shown as "Crew #N" with chief name.
## All other roles use full_name().
func display_name() -> String:
	if role == "Pit Crew" and crew_number > 0:
		return "Crew #%d  (Chief: %s)" % [crew_number, full_name()]
	return full_name()

func is_available() -> bool:
	return contract_team == ""

func is_hired() -> bool:
	return contract_team != ""

## Returns the single most representative skill for this role.
## Used for quick display in staff list rows and sorting.
func get_primary_skill() -> float:
	match role:
		"Race Mechanic":    return car_setup
		"Pit Crew":         return pit_stop_speed
		"Team Principal":   return race_strategy
		"CFO":              return resource_management
		"Designer":         return (engine + aero + chassis + gearbox + brakes + suspension) / 6.0
		"Race Strategist":  return race_strategy
	return 0.0

## Returns display label for primary skill.
func get_primary_skill_label() -> String:
	match role:
		"Race Mechanic":    return "Car Setup"
		"Pit Crew":         return "Pit Speed"
		"Team Principal":   return "Strategy"
		"CFO":              return "Resources"
		"Designer":         return "Avg Design"
		"Race Strategist":  return "Strategy"
	return "Skill"

## Returns repair efficiency multiplier (0.5–1.0) based on car_setup.
## Used by GameState._get_repair_efficiency() when this mechanic is assigned.
func get_repair_efficiency() -> float:
	if role != "Race Mechanic":
		return 1.0
	# car_setup 0→0.5 efficiency, car_setup 100→1.0 efficiency
	return 0.5 + (car_setup / 100.0) * 0.5

## Returns TP multiplier for a given skill area (0.9–1.2 range).
## Applied to other staff's attributes when TP is present.
## tp_skill should be one of the TP's relevant attributes (0-100).
static func tp_multiplier(tp_skill: float) -> float:
	return 0.9 + (tp_skill / 100.0) * 0.3
