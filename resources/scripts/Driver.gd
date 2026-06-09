class_name Driver
extends Resource
## Version: S16.2 — Added track_knowledge dict keyed by track_id. Grows per event at that track.

# Identity
@export var id: String = ""
@export var first_name: String = ""
@export var last_name: String = ""
@export var nationality: String = ""
@export var age: int = 8
@export var sex: String = "Male"

# Academy / Team
@export var academy_team: String = ""
@export var contract_team: String = ""
@export var contract_seasons_remaining: int = 0
## Contract financial terms — set during negotiation
@export var weekly_salary: float = 0.0
@export var win_bonus: int = 0
@export var podium_bonus: int = 0
@export var championship_bonus: int = 0
@export var release_clause: int = 0

# Championships entered this season
@export var active_championships: Array = []

# Current active discipline
@export var active_discipline: String = "GK"

# Grace period tracking - season when discipline last changed
@export var discipline_change_season: int = 1

# Discipline adaptation values (0-100)
@export var discipline_adaptation: Dictionary = {
	"GK": 1.0, "Rally": 1.0, "TC": 1.0,
	"OWC": 1.0, "SC": 1.0, "EPC": 1.0, "GP": 1.0
}

# Peak adaptation ever reached per discipline (for floor calculation)
@export var peak_adaptation: Dictionary = {
	"GK": 1.0, "Rally": 1.0, "TC": 1.0,
	"OWC": 1.0, "SC": 1.0, "EPC": 1.0, "GP": 1.0
}

# Ceiling table
const ADAPTATION_CEILINGS = {
	"GK":    {"GK": 100, "Rally": 20, "TC": 40, "OWC": 50, "SC": 30, "EPC": 60, "GP": 85},
	"Rally": {"GK": 20,  "Rally": 100,"TC": 35, "OWC": 10, "SC": 15, "EPC": 40, "GP": 20},
	"TC":    {"GK": 40,  "Rally": 35, "TC": 100,"OWC": 30, "SC": 45, "EPC": 75, "GP": 50},
	"OWC":   {"GK": 50,  "Rally": 10, "TC": 30, "OWC": 100,"SC": 70, "EPC": 55, "GP": 75},
	"SC":    {"GK": 30,  "Rally": 15, "TC": 45, "OWC": 70, "SC": 100,"EPC": 40, "GP": 45},
	"EPC":   {"GK": 60,  "Rally": 40, "TC": 75, "OWC": 55, "SC": 40, "EPC": 100,"GP": 80},
	"GP":    {"GK": 85,  "Rally": 20, "TC": 50, "OWC": 75, "SC": 45, "EPC": 80, "GP": 100},
}

# ── Core visible stats (0-100) ────────────────────────────────────────────────
@export var pace: float = 0.0           # Raw speed over one lap
@export var wet: float = 0.0            # Performance in low-traction conditions
@export var focus: float = 0.0          # Mental concentration; drops with fatigue
@export var race_craft: float = 0.0     # Racecraft: positioning, defending, overtaking
@export var consistency: float = 0.0   # Technical lap-time repeatability; narrows noise
@export var feedback: float = 0.0      # Quality of car communication to mechanic
@export var marketability: float = 0.0 # Public appeal; shown, affected by results
@export var fitness: float = 100.0     # Physical condition; drops after races

# ── Hidden stats (never shown in UI) ─────────────────────────────────────────
@export var potential: float = 0.0     # Growth ceiling — HIDDEN from player
@export var aggression: float = 0.0    # Hidden racing style modifier
@export var experience: float = 0.0    # Hidden: grows with races, improves consistency

# ── Status ────────────────────────────────────────────────────────────────────
@export var morale: float = 100.0
@export var seasons_without_contract: int = 0

## Per-track knowledge — keyed by track_id (stable slug from track name).
## Grows each time this driver races at that track. Used in lap time formula.
## Format: { "super_karting_raceway": 12.5, "croatia": 45.0, ... }
@export var track_knowledge: Dictionary = {}

# ── Identity helpers ──────────────────────────────────────────────────────────

func full_name() -> String:
	return first_name + " " + last_name

func is_eligible_for_gk_regional() -> bool:
	return age >= 8 and age <= 16

# ── Computed skill (not stored — for UI sorting only) ─────────────────────────
## Average of all five visible racing attributes.
## Use for sorting driver lists. Never save this value.
func get_overall_skill() -> float:
	return (pace + wet + focus + race_craft + consistency) / 5.0

# ── Fitness ───────────────────────────────────────────────────────────────────

func fitness_penalty() -> float:
	return 0.85 + (fitness / 100.0) * 0.15

# ── Consistency noise modifier ────────────────────────────────────────────────
## Returns the max lap time noise range based on consistency.
## High consistency (100) → ±0.1s noise. Low consistency (0) → ±0.8s noise.
## Used in _simulate_race() to replace the flat randf_range(-0.5, 0.5).
func get_lap_noise_range() -> float:
	return 0.8 - (consistency / 100.0) * 0.7

# ── Marketability ─────────────────────────────────────────────────────────────
## Call after each race with the driver's finishing position and grid size.
## last_25pct_threshold = ceil(grid_size * 0.75) — positions below this lose marketability.
func update_marketability_after_race(position: int, grid_size: int, is_dns: bool) -> void:
	if is_dns:
		marketability = max(0.0, marketability - 2.0)
		return
	if position == 1:
		marketability = min(100.0, marketability + 4.0)
	elif position <= 3:
		marketability = min(100.0, marketability + 2.0)
	elif position <= grid_size / 2:
		marketability = min(100.0, marketability + 0.5)
	else:
		var bottom_25_threshold = int(ceil(grid_size * 0.75))
		if position > bottom_25_threshold:
			marketability = max(0.0, marketability - 0.5)
		# Positions between top half and bottom 25% are neutral — no change

# ── Adaptation ────────────────────────────────────────────────────────────────

func get_active_adaptation() -> float:
	return discipline_adaptation.get(active_discipline, 1.0)

func get_adaptation_multiplier() -> float:
	var adaptation = get_active_adaptation()
	return 0.5 + (adaptation / 200.0)

func get_floor(discipline: String) -> float:
	return peak_adaptation.get(discipline, 1.0) * 0.35

func get_talent_multiplier() -> float:
	if potential >= 85.0:
		return 1.2
	elif potential >= 70.0:
		return 1.0
	elif potential >= 40.0:
		return 0.8
	else:
		return 0.6

func update_adaptation_after_race(current_season: int, total_races_in_season: int) -> void:
	if not active_discipline in ADAPTATION_CEILINGS:
		return

	var ceilings = ADAPTATION_CEILINGS[active_discipline]
	var talent_mult = get_talent_multiplier()
	var in_grace_period = (current_season - discipline_change_season) <= 1

	for discipline in discipline_adaptation:
		var current = discipline_adaptation[discipline]
		var ceiling = float(ceilings.get(discipline, 1.0))
		var floor_val = get_floor(discipline)

		if discipline == active_discipline:
			var season_target = 55.0 * (1.0 - current / ceiling) * talent_mult
			var per_race_growth = season_target / float(total_races_in_season)
			current = min(ceiling, current + per_race_growth)

		elif current < ceiling:
			var synergy = ceiling / 100.0
			var passive = (synergy * 0.3 * talent_mult) / float(total_races_in_season)
			current = min(ceiling, current + passive)

		elif current > ceiling:
			if in_grace_period:
				pass
			else:
				var synergy = ceiling / 100.0
				var decay_mult = 1.2
				if synergy > 0.6:
					decay_mult = 0.6
				elif synergy > 0.3:
					decay_mult = 0.8
				var season_decay = 25.0 * ((current - ceiling) / current) * decay_mult
				var per_race_decay = season_decay / float(total_races_in_season)
				current = max(max(floor_val, ceiling), current - per_race_decay)

		if current > peak_adaptation.get(discipline, 1.0):
			peak_adaptation[discipline] = current

		discipline_adaptation[discipline] = current

func change_discipline(new_discipline: String, current_season: int) -> void:
	active_discipline = new_discipline
	discipline_change_season = current_season

# ── Effective stats (adaptation-adjusted) ────────────────────────────────────

func get_effective_pace() -> float:
	return pace * get_adaptation_multiplier()

func get_effective_wet() -> float:
	return wet * get_adaptation_multiplier()

func get_effective_focus() -> float:
	return focus * get_adaptation_multiplier()

func get_effective_race_craft() -> float:
	return race_craft * get_adaptation_multiplier()

func get_effective_consistency() -> float:
	return consistency * get_adaptation_multiplier()

## Returns this driver's knowledge of a specific track (0–100).
func get_track_knowledge(track_id: String) -> float:
	return clamp(track_knowledge.get(track_id, 0.0), 0.0, 100.0)

## Called after a race — grows knowledge at this specific track.
## growth_amount: 3–8 per event depending on result quality.
func update_track_knowledge(track_id: String, growth_amount: float) -> void:
	var current = track_knowledge.get(track_id, 0.0)
	track_knowledge[track_id] = min(100.0, current + growth_amount)
