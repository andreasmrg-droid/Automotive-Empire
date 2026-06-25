class_name Staff
## Version: S37.18 — #1: CFO get_primary_skill_label() "Resources"→"Negotiation" to match the
##   returned stat (sponsor_negotiation); the Skill column was mislabeled.
## Version: S37.15 — #18 hidden-gems: added talent_scouting TP stat ("eye for talent") + included
## it in the TP get_overall_skill() average (now /10); grow_talent_scouting() sharpens it each
## season toward the TP's talent ceiling (employed TPs faster). Loaded from JSON, saved/loaded.
extends Resource
## Version: S35.10 — added is_shortlisted (UI shortlist flag, saved/loaded; viewable in the
##   role-tabbed Shortlist screen).
## Version: S32.0 — Added get_overall_skill(): role-aware aggregate rating (mirrors
##   Driver.get_overall_skill()). Used to rank Team Principals for AI allocation (overseers
##   whose value is broad amplification). Per-role optimiser scoring still uses each role's
##   performance-driving stat; only TP allocation uses this aggregate.
## --- S24.1 — Added peak_adaptation dict for TP/Mechanic/Strategist.
##                    get_adaptation_floor(), update_peak_adaptation() added.
##                    race_pace (Mechanic), fatigue_resistance (Pit Crew),
##                    speculation (CFO), parts_knowledge (TP/Mechanic/Designer).

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
@export var contract_team: String = ""
## S35.10 — player's personal shortlist flag (★ in Staff hub). UI bookmark only, not
## gameplay-affecting; viewable in the Shortlisted tab.
@export var is_shortlisted: bool = false
## Contract bonus terms — set during negotiation
@export var championship_bonus: int = 0
@export var performance_bonus: int = 0
@export var release_clause: int = 0       # team_id; "" = available for hire
@export var assigned_championship: String = "" # championship_id; "" = unassigned
@export var assigned_car_id: String = ""     # car_id; for Mechanic and Pit Crew

# Discipline adaptation — applies to TP, Race Mechanic, Race Strategist ONLY.
# CFO and Designer do NOT use discipline adaptation.
@export var discipline_adaptation: Dictionary = {
	"GK": 1.0, "Rally": 1.0, "TC": 1.0,
	"OWC": 1.0, "SC": 1.0, "EPC": 1.0, "GP": 1.0
}

# Peak adaptation ever reached per discipline (floor = peak × 0.35).
# Primary discipline grows toward 100. Same system as Driver.
# Only meaningful for TP, Race Mechanic, Race Strategist.
@export var peak_adaptation: Dictionary = {
	"GK": 1.0, "Rally": 1.0, "TC": 1.0,
	"OWC": 1.0, "SC": 1.0, "EPC": 1.0, "GP": 1.0
}

# ── Race Mechanic attributes ──────────────────────────────────────────────────
@export var car_setup: float = 0.0        # Quality of setup work — primary Setup_Gain_per_Lap stat
@export var pit_stops: float = 0.0        # Pit stop execution quality — reduces Base_Service_Time
@export var parts_knowledge: float = 0.0  # Shared field. Mechanic: repair/degradation awareness.
											   # TP: in-race multiplier for Mechanic+Strategist.
											   # Designer: improves design process via race telemetry.
@export var track_knowledge: float = 0.0  # Track-specific setup knowledge; grows per event, drops over time
@export var race_pace: float = 0.0        # Feeds Staff_Synergy_Factor in lap time — multiplied by TP
## Per-track knowledge — keyed by track_id. Same system as Driver.
## Flat track_knowledge above = max of all known tracks (for UI display).
@export var track_knowledge_by_track: Dictionary = {}

# ── Pit Crew attributes ───────────────────────────────────────────────────────
@export var pit_stop_speed: float = 0.0      # Speed of pit stop operations — affects Base_Service_Time
@export var repair_skill: float = 0.0        # Quality and speed of repairs — inside and between sessions
@export var fitness: float = 100.0           # DYNAMIC. Drops per action, partial recovery between sessions
@export var fatigue_resistance: float = 0.0  # Reduces fitness drop rate. Slightly improved by Fitness Clinic

# ── Team Principal attributes ─────────────────────────────────────────────────
## TP attributes act as MULTIPLIERS on other staff's values (per spec)
@export var race_strategy: float = 0.0         # Amplifies strategist's race_strategy
@export var practice_management: float = 0.0   # Amplifies strategist's practice_scheduling
@export var qualifying_management: float = 0.0 # Amplifies strategist's qualifying_timing
@export var race_pace_reading: float = 0.0     # Amplifies strategist's race_pace_reading
@export var car_setup_oversight: float = 0.0   # Amplifies mechanic's car_setup
@export var pit_stop_management: float = 0.0   # Amplifies pit crew's pit_stop_speed
@export var pr_skill: float = 0.0              # Boosts team reputation and marketability
@export var talent_scouting: float = 0.0       # TP's "eye for talent" — accuracy of driver potential reads (#18)

# ── CFO attributes ────────────────────────────────────────────────────────────
@export var loan_management: float = 0.0     # All loan decisions — amount, interest rate, early repayment
@export var sales_skill: float = 0.0         # Boosts commercial car sales revenue
@export var sponsor_negotiation: float = 0.0 # Improves all contract negotiations (drivers, staff, sponsors)
@export var resource_management: float = 0.0 # Reduces weekly expenses — materials, maintenance
@export var budget_planning: float = 0.0     # Decision insights for team expansion or contraction
@export var speculation: float = 0.0         # Economy index predictions — fuel contracts, market timing

# ── Designer attributes ───────────────────────────────────────────────────────
@export var engine: float = 0.0      # Engine development skill
@export var aero: float = 0.0        # Aerodynamics development skill
@export var brakes: float = 0.0      # Brakes development skill
@export var suspension: float = 0.0  # Suspension development skill
@export var chassis: float = 0.0     # Chassis development skill
@export var gearbox: float = 0.0     # Gearbox development skill
@export var reliability: float = 0.0 # Reduces part failure probability

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
		"CFO":              return sponsor_negotiation
		"Designer":         return (engine + aero + chassis + gearbox + brakes + suspension) / 6.0
		"Race Strategist":  return race_strategy
	return 0.0

## Aggregate "overall" rating for a staff member — mean of the stats relevant to the role.
## Mirrors Driver.get_overall_skill(). Primarily used to rank Team Principals (overseers whose
## value is broad amplification, so no single stat dominates), but defined for all roles for any
## future "overall" display. Per-role optimiser scoring still uses the role's performance-driving
## stat(s); only TP allocation uses this aggregate.
func get_overall_skill() -> float:
	match role:
		"Team Principal":
			return (race_strategy + practice_management + qualifying_management
				+ race_pace_reading + car_setup_oversight + pit_stop_management
				+ pr_skill + parts_knowledge + track_knowledge + talent_scouting) / 10.0
		"Race Strategist":
			return (race_strategy + race_pace_reading + practice_scheduling
				+ qualifying_timing + track_knowledge) / 5.0
		"Race Mechanic":
			return (car_setup + pit_stops + parts_knowledge + track_knowledge + race_pace) / 5.0
		"Pit Crew":
			return (pit_stop_speed + repair_skill + fatigue_resistance) / 3.0
		"CFO":
			return (sales_skill + sponsor_negotiation + resource_management
				+ budget_planning + speculation + loan_management) / 6.0
		"Designer":
			return (engine + aero + chassis + gearbox + brakes + suspension) / 6.0
	return get_primary_skill()

## Returns display label for primary skill.
func get_primary_skill_label() -> String:
	match role:
		"Race Mechanic":    return "Car Setup"
		"Pit Crew":         return "Pit Speed"
		"Team Principal":   return "Strategy"
		"CFO":              return "Negotiation"
		"Designer":         return "Avg Design"
		"Race Strategist":  return "Strategy"
	return "Skill"

## Returns repair efficiency multiplier (0.5–1.0) based on car_setup.
## Used by GameState._get_repair_efficiency() when this mechanic is assigned.
func get_repair_efficiency() -> float:
	if role != "Race Mechanic":
		return 1.0
	## parts_knowledge 0→0.5 efficiency, 100→1.0 efficiency
	return 0.5 + (parts_knowledge / 100.0) * 0.5

## Returns TP multiplier for a given skill area (0.9–1.2 range).
## Applied to other staff's attributes when TP is present.
## tp_skill should be one of the TP's relevant attributes (0-100).
static func tp_multiplier(tp_skill: float) -> float:
	return 0.9 + (tp_skill / 100.0) * 0.3



## ── Adaptation helpers ───────────────────────────────────────────────────────

## Returns adaptation floor for a discipline: peak × 0.35
func get_adaptation_floor(discipline: String) -> float:
	return peak_adaptation.get(discipline, 1.0) * 0.35

## Updates peak after each race event
func update_peak_adaptation(discipline: String) -> void:
	var current = discipline_adaptation.get(discipline, 1.0)
	if current > peak_adaptation.get(discipline, 1.0):
		peak_adaptation[discipline] = current

## ── Fitness / Fatigue (Pit Crew and Drivers) ─────────────────────────────────

## Degradation per pit stop action.
func apply_pitstop_fatigue(pit_stop_time_seconds: float) -> void:
	var drop = (pit_stop_time_seconds / 2.0) * (1.0 - fatigue_resistance / 100.0)
	fitness = max(0.0, fitness - drop)

## Degradation per repair action.
func apply_repair_fatigue(repair_time_minutes: float) -> void:
	var drop = (repair_time_minutes * 0.5) * (1.0 - fatigue_resistance / 100.0)
	fitness = max(0.0, fitness - drop)

## Partial recovery between sessions within same race weekend.
## recovery_rate: Practice→Qualifying = 0.30, Qualifying→Race = 0.60
func recover_fitness(recovery_rate: float) -> void:
	var recovered = (100.0 - fitness) * recovery_rate
	fitness = min(100.0, fitness + recovered)

## Full reset at the start of a new race weekend.
func reset_fitness() -> void:
	fitness = 100.0

## Returns per-track knowledge (0–100) for a specific track_id.
func get_track_knowledge_for(track_id: String) -> float:
	return clamp(track_knowledge_by_track.get(track_id, 0.0), 0.0, 100.0)

## Called after a race — grows knowledge at this track, updates flat display value.
func update_track_knowledge(track_id: String, growth_amount: float) -> void:
	var current = track_knowledge_by_track.get(track_id, 0.0)
	track_knowledge_by_track[track_id] = min(100.0, current + growth_amount)
	## Update flat track_knowledge to the maximum known track (used for UI + old code)
	var best = 0.0
	for v in track_knowledge_by_track.values():
		if v > best: best = v
	track_knowledge = best

## ── Talent scouting growth (#18) ─────────────────────────────────────────────
## A TP's eye for talent sharpens with experience. Called once per season (SeasonManager
## aging loop). Grows toward the TP's own hidden `talent` ceiling; an EMPLOYED TP (watching
## his own drivers develop) grows faster than an idle free agent. Only Team Principals scout.
func grow_talent_scouting() -> void:
	if role != "Team Principal":
		return
	var ceiling = max(talent, talent_scouting)   ## never shrink; talent caps growth
	if talent_scouting >= ceiling:
		return
	var rate = 3.0 if contract_team != "" else 1.0   ## employed eye sharpens faster
	talent_scouting = min(ceiling, talent_scouting + rate)
