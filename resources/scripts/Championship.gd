## Version: S36.18 — Added get_races_for_week(week): returns ALL calendar entries scheduled for a
##   given week (usually one; multiple for same-week events like the GK final weekend, and future
##   Rally/Endurance multi-event weekends). Enables the multi-event weekly loop in GameState.
## Version: S29.8 — Default championship_name "GK Regional Championship"->"GK Championship".
## --- S19.9 — Added drivers_champion_history and teams_champion_history for competition_factor.
class_name Championship
extends Resource

# Identity
@export var id: String = "C-001"
@export var championship_name: String = "GK Championship"
@export var discipline: String = "GK"  # Short codes: GK, Rally, TC, OWC, SC, EPC, GP
@export var tier: int = 1

# Rules
@export var min_age: int = 8
@export var max_age: int = 16
@export var drivers_per_car: int = 1
@export var min_cars: int = 400
@export var optimum_cars: int = 440
@export var max_cars: int = 500
@export var entry_fee_per_race: float = 1500.0
@export var num_races: int = 6

# Points system
@export var points_system: Array = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]

# Prize money
@export var prize_1st: float = 300.0
@export var prize_2nd: float = 150.0
@export var prize_3rd: float = 75.0

# ── Resources ─────────────────────────────────────────────────────────────────
# SP cost to repair 10% car damage.
# Source: Excel Variables Map, Championships sheet,
#         column "Spares_per_Race_Weekend_Per_10_percent_damage"
@export var sp_per_10_pct_damage: int = 100

# Fuel consumed per car per race weekend (kg).
# Source: Excel Variables Map, Championships sheet, column "Fuel per Weekend_per_Car"
@export var fuel_per_car_per_race: float = 15.0

# ── Car condition degradation ──────────────────────────────────────────────────
# % condition lost per lap under normal racing (no incidents).
# Applies to: GK, GP, OWC, TC, SC, EPC.
# Tuning values (to be refined during race testing):
#   GK=0.5, GP=0.6, OWC=0.6, TC=0.8, SC=0.9, EPC=0.4
@export var condition_loss_per_lap: float = 0.5

# % condition lost per rally stage (Rally only; 0.0 for all other disciplines).
# Tuning value: Rally=1.5
@export var condition_loss_per_stage: float = 0.0

# ── Repair ─────────────────────────────────────────────────────────────────────
# Seconds to repair 1% damage during a timed repair window.
# Used for: TC (14s), SC (16s), EPC (13s), Rally (18s).
# 0.0 for GK, GP, OWC — no time-pressured repair windows for these disciplines.
@export var repair_time_per_1pct: float = 0.0

# Whether this championship has mid-race repair windows (pit stops or service parks).
# true:  TC, SC, EPC, Rally
# false: GK, GP, OWC
@export var has_mid_race_repairs: bool = false

# Rally only: a service park occurs every N completed stages.
# Example: 5 means a 30-min service park after stages 5, 10, 15, etc.
# 0 for all non-Rally disciplines.
@export var service_park_every_n_stages: int = 0

# % condition restored per pit stop for TC / SC / EPC.
# Calculated at runtime: repair_time_per_1pct drives how much fits in the stop duration.
# Stored here as a pre-calculated cap for the current championship's standard stop length.
# 0.0 for GK, GP, OWC (no bodywork repairs during pit stops).
# 0.0 for Rally (uses service park system instead).
@export var pit_stop_repair_pct: float = 0.0

# ── Calendar ───────────────────────────────────────────────────────────────────
@export var calendar: Array = []

# Driver standings  — driver_id : points
@export var standings: Dictionary = {}

# Team standings — team_id : points
@export var team_standings: Dictionary = {}

# Results per round
@export var results: Dictionary = {}

## Winner history — last N seasons for competition_factor calculation
## Each entry: {"season": int, "driver_id": String, "driver_name": String}
@export var drivers_champion_history: Array = []
## Each entry: {"season": int, "team_id": String, "team_name": String}
@export var teams_champion_history: Array = []

@export var current_round: int = 0
@export var season: int = 1

# ── Methods ────────────────────────────────────────────────────────────────────

func get_next_race() -> Dictionary:
	if current_round < calendar.size():
		return calendar[current_round]
	return {}

## Returns ALL calendar entries scheduled for `week`, starting at current_round, in calendar
## order. Usually one race; two or more for same-week events (GK final weekend = Semi + Grand
## Final; later: Rally multi-stage weekends, Endurance). General capability — any championship
## can declare multiple same-week calendar entries and they all run that week, in sequence.
## Does NOT advance current_round — the caller advances past each race it processes.
func get_races_for_week(week: int) -> Array:
	var races: Array = []
	var idx = current_round
	while idx < calendar.size() and calendar[idx]["week"] == week:
		races.append(calendar[idx])
		idx += 1
	return races

func is_season_finished() -> bool:
	return current_round >= num_races

func add_points(driver_id: String, points: int) -> void:
	if driver_id in standings:
		standings[driver_id] += points
	else:
		standings[driver_id] = points

func add_team_points(team_id: String, points: int) -> void:
	if team_id in team_standings:
		team_standings[team_id] += points
	else:
		team_standings[team_id] = points

func get_standings_sorted() -> Array:
	var sorted = []
	for driver_id in standings:
		sorted.append({"driver_id": driver_id, "points": standings[driver_id]})
	sorted.sort_custom(func(a, b): return a["points"] > b["points"])
	return sorted

func get_team_standings_sorted() -> Array:
	var sorted = []
	for team_id in team_standings:
		sorted.append({"team_id": team_id, "points": team_standings[team_id]})
	sorted.sort_custom(func(a, b): return a["points"] > b["points"])
	return sorted

func reset_for_new_season() -> void:
	standings = {}
	team_standings = {}
	results = {}
	current_round = 0
	season += 1

## Competition factor: how exciting is this championship?
## Based on unique drivers champion in last 3 seasons.
## 1 unique winner (dominance) → 0.82. 2 → 1.00. 3+ → 1.18.
func get_competition_factor() -> float:
	if drivers_champion_history.is_empty(): return 1.0
	var last_3 = drivers_champion_history.slice(max(0, drivers_champion_history.size() - 3))
	var unique_winners = {}
	for entry in last_3:
		unique_winners[entry.get("driver_id", "")] = true
	match unique_winners.size():
		1: return 0.82
		2: return 1.00
		_: return 1.18
