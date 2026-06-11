extends Resource
class_name GKDiscipline
## Version: S22.2 — Conflict check corrected: same week + same track = GREEN LIGHT
##                    (driver CAN race both tiers at same venue). Same week + different
##                    track = BLOCK (can't be in two places). Different weeks = no conflict.
##   Holds all group state for all 4 GK tiers (Regional/National/Continental/World).
##   Groups: Regional=20, National=10, Continental=2, World=1.
##   Group 1 of each tier = deep-simulated (player's group).
##   All other groups = shadow-simulated (standings only, no lap-by-lap).
##   populate_season(): fills groups from eligible GK drivers each season start.
##   shadow_simulate_race(): fast result generation for non-player groups.
##   get_tp_proposals(): produces TP auto-assignment suggestions for the player.
##   conflict_check(): ensures no driver races same week at same track_id in two tiers.

## ── Constants ─────────────────────────────────────────────────────────────────

## Group counts per tier
const GROUPS_PER_TIER: Dictionary = {
	"C-001": 20,   ## Regional
	"C-002": 10,   ## National
	"C-003": 2,    ## Continental
	"C-004": 1,    ## World
}

## Optimum drivers per tier (from Excel)
const OPTIMUM_TOTAL: Dictionary = {
	"C-001": 440,
	"C-002": 350,
	"C-003": 250,
	"C-004": 125,
}

## Age gates (player-preferred design)
## Regional: 8-16  National: 10-18  Continental: 12-20  World: 14-22
const TIER_MIN_AGE: Dictionary = {"C-001": 8,  "C-002": 10, "C-003": 12, "C-004": 14}
const TIER_MAX_AGE: Dictionary = {"C-001": 16, "C-002": 18, "C-003": 20, "C-004": 22}

## Tier order from lowest to highest (used for population priority)
const TIER_ORDER: Array = ["C-001", "C-002", "C-003", "C-004"]

## Tier labels for display
const TIER_NAMES: Dictionary = {
	"C-001": "Regional", "C-002": "National",
	"C-003": "Continental", "C-004": "World",
}

## ── State ─────────────────────────────────────────────────────────────────────

## groups[champ_id][group_index] = Array of driver_ids
## group_index 0 = player's group (deep simulated)
var groups: Dictionary = {}

## shadow_standings[champ_id][group_index] = Array of {driver_id, points, wins}
var shadow_standings: Dictionary = {}

## driver_tier_assignments[driver_id] = Array of champ_ids they are active in this season
var driver_tier_assignments: Dictionary = {}

## mechanic_tier_assignments[mechanic_id] = Array of champ_ids they are covering this season
## Mechanics have no age restriction — they follow driver assignments
var mechanic_tier_assignments: Dictionary = {}

## week_race_map[champ_id] = Array of {week, track_id} — races for this tier this season
## Populated from GameState.CHAMPIONSHIP_CALENDARS on season start
var week_race_map: Dictionary = {}

## TP proposals for current season — Array of {type, driver_id, champ_ids, mechanic_id, note}
var tp_proposals: Array = []

## Whether the player has reviewed proposals this season
var proposals_reviewed: bool = false

## ── Initialisation ────────────────────────────────────────────────────────────

func _init() -> void:
	for cid in TIER_ORDER:
		groups[cid] = []
		shadow_standings[cid] = []
	driver_tier_assignments = {}
	mechanic_tier_assignments = {}
	tp_proposals = []
	proposals_reviewed = false

## ── Season Population ─────────────────────────────────────────────────────────

## populate_season: fills groups for all 4 tiers.
## CRITICAL CAR RULE: a driver races by being in a car. A car is registered to one
## championship. Player drivers are only placed in a tier if the player has a car
## registered to that championship. AI drivers follow their team's car registrations.
func populate_season(
		all_drivers: Dictionary,
		all_staff: Dictionary,
		player_driver_ids: Array,
		registered_champ_ids: Array,
		calendars: Dictionary,
		current_season: int,
		player_team_cars: Array = []) -> void:

	## Build week-race map for conflict detection
	week_race_map = {}
	for cid in TIER_ORDER:
		week_race_map[cid] = []
		var cal = calendars.get(cid, [])
		for race in cal:
			week_race_map[cid].append({"week": race["week"], "track_id": race.get("track_id","")})

	## Build set of GK tiers the player actually has a car for
	var player_car_tiers: Array = []
	for car in player_team_cars:
		var cid = car.championship_id
		if cid in TIER_ORDER and not cid in player_car_tiers:
			player_car_tiers.append(cid)

	## Collect all GK-eligible drivers scored by skill
	var candidates: Array = []
	for did in all_drivers:
		var d = all_drivers[did]
		if d.active_discipline != "GK": continue
		candidates.append({
			"driver_id": did,
			"driver": d,
			"score": _driver_score(d),
			"age": d.age,
		})
	candidates.sort_custom(func(a, b): return a["score"] > b["score"])

	## Reset assignments
	driver_tier_assignments = {}
	mechanic_tier_assignments = {}
	for cid in TIER_ORDER:
		groups[cid] = []
		shadow_standings[cid] = []

	## Assign drivers to tiers — World first (best), then down.
	## Player drivers: only assigned to tiers where player has a car.
	## AI drivers: assigned based on their team's car registrations.

	var _assign = func(cid: String) -> void:
		for entry in candidates:
			if groups[cid].size() >= OPTIMUM_TOTAL[cid]: break
			var d = entry["driver"]
			var did = entry["driver_id"]
			if d.age < TIER_MIN_AGE[cid] or d.age > TIER_MAX_AGE[cid]: continue

			## Car rule check
			var is_player_driver = did in player_driver_ids
			if is_player_driver:
				## Player driver: only assign if player has a car in this tier
				if not cid in player_car_tiers: continue
			## else AI driver: no car restriction in GKDiscipline population
			## (AI cars are handled by AI team logic)

			## Conflict check against already-assigned higher tiers
			var has_conf = false
			for other_cid in TIER_ORDER:
				if other_cid == cid: break  ## only check higher tiers (earlier in list)
				if _has_conflict(did, cid, other_cid):
					has_conf = true; break
			if has_conf: continue

			groups[cid].append(did)
			if not driver_tier_assignments.has(did): driver_tier_assignments[did] = []
			driver_tier_assignments[did].append(cid)

	for cid in ["C-004","C-003","C-002","C-001"]:  ## World → Regional
		_assign.call(cid)

	## Split each tier's flat list into groups
	## Group 0 is reserved for the real championship race (player's group)
	## Shadow groups (1..N) must NOT contain drivers already in the real championship
	for cid in TIER_ORDER:
		var flat: Array = groups[cid].duplicate()
		var n_groups: int = GROUPS_PER_TIER[cid]

		var group_list: Array = []
		for _g in range(n_groups): group_list.append([])

		## Group 0: player drivers only (real championship handles the rest)
		if cid in registered_champ_ids:
			for did in player_driver_ids:
				if did in flat:
					group_list[0].append(did)
					flat.erase(did)

		## Remove ALL player-registered championship drivers from shadow groups
		## (they race in the real championship, not in shadow groups)
		## For the registered tier, the real championship handles all Group 1 drivers
		## Shadow groups (1+) only get drivers NOT in any active championship for this tier

		## Distribute remaining to groups 1..N (NOT group 0 for registered tiers)
		var start_idx = 1 if cid in registered_champ_ids else 0
		var g_idx = start_idx
		for did in flat:
			group_list[g_idx].append(did)
			g_idx += 1
			if g_idx >= n_groups: g_idx = start_idx

		groups[cid] = group_list

	## Initialise shadow standings
	for cid in TIER_ORDER:
		shadow_standings[cid] = []
		for g_idx in range(groups[cid].size()):
			var group_stand: Array = []
			for did in groups[cid][g_idx]:
				group_stand.append({"driver_id": did, "points": 0, "wins": 0, "races": 0})
			shadow_standings[cid].append(group_stand)

	## Assign mechanics
	for sid in all_staff:
		var s = all_staff[sid]
		if s.role != "Race Mechanic": continue
		if s.contract_team == "": continue
		var covered_tiers: Array = []
		for did in driver_tier_assignments:
			var d = all_drivers.get(did)
			if d and d.contract_team == s.contract_team:
				for cid in driver_tier_assignments[did]:
					if not cid in covered_tiers:
						covered_tiers.append(cid)
		if covered_tiers.size() > 0:
			mechanic_tier_assignments[sid] = covered_tiers

	## Generate TP proposals and snapshot
	_generate_tp_proposals(all_drivers, all_staff, player_driver_ids,
		registered_champ_ids, player_car_tiers)
	snapshot_roster(all_drivers)
	proposals_reviewed = false

## ── Driver Score ──────────────────────────────────────────────────────────────

func _driver_score(d) -> float:
	## Weighted score for tier placement. Uses pace, consistency, potential.
	## Driver is a Resource — use direct property access with fallback via 'in' check.
	var pace_attr = 50.0
	if "pace" in d:       pace_attr = float(d.pace)
	elif "race_craft" in d: pace_attr = float(d.race_craft)
	var cons_attr = float(d.consistency) if "consistency" in d else 50.0
	var pot_attr  = float(d.potential)   if "potential"   in d else 50.0
	return pace_attr * 0.45 + cons_attr * 0.35 + pot_attr * 0.20

## ── Conflict Detection ────────────────────────────────────────────────────────

## Returns true if assigning a driver to check_cid would create an IMPOSSIBLE conflict
## with their existing assignment in other_cid.
##
## GK MULTI-TIER RULE:
## Same week + SAME track  → NO conflict (driver races both tiers at same venue) ✅
## Same week + DIFF track  → CONFLICT (can't be in two places at once) ❌
## Different weeks         → NO conflict regardless of track ✅
func _has_conflict(driver_id: String, check_cid: String, other_cid: String) -> bool:
	if not driver_tier_assignments.has(driver_id): return false
	if not other_cid in driver_tier_assignments[driver_id]: return false
	var check_races = week_race_map.get(check_cid, [])
	var other_races = week_race_map.get(other_cid, [])
	for cr in check_races:
		for or_ in other_races:
			if cr["week"] == or_["week"] and cr["track_id"] != or_["track_id"]:
				## Same week, DIFFERENT track = impossible conflict
				return true
	return false

## ── Shadow Simulation ─────────────────────────────────────────────────────────

## Fast race result for a non-player group. Called from GameState._simulate_race()
## when the race is in a shadow group (group_index > 0).
## Updates shadow_standings for that group.
## Returns Array of {driver_id, position, points} — just enough for news/logging.
func shadow_simulate_race(champ_id: String, group_index: int, all_drivers: Dictionary) -> Array:
	if not groups.has(champ_id): return []
	if group_index >= groups[champ_id].size(): return []

	var driver_ids: Array = groups[champ_id][group_index]
	if driver_ids.is_empty(): return []

	## Score each driver with small random noise
	var scored: Array = []
	for did in driver_ids:
		var d = all_drivers.get(did)
		if not d: continue
		var base = _driver_score(d)
		var noise = randf_range(-8.0, 8.0)
		scored.append({"driver_id": did, "score": base + noise})

	scored.sort_custom(func(a, b): return a["score"] > b["score"])

	## Standard 25-18-15-12-10-8-6-4-2-1 points
	const PTS = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]

	var results: Array = []
	for i in range(scored.size()):
		var pts = PTS[i] if i < PTS.size() else 0
		results.append({"driver_id": scored[i]["driver_id"], "position": i + 1, "points": pts})

	## Update shadow standings
	if group_index < shadow_standings[champ_id].size():
		for res in results:
			for entry in shadow_standings[champ_id][group_index]:
				if entry["driver_id"] == res["driver_id"]:
					entry["points"] += res["points"]
					entry["races"]  += 1
					if res["position"] == 1:
						entry["wins"] += 1
					break

	## Small reputation bump for shadow winners (ecosystem feel)
	if results.size() > 0:
		var winner = all_drivers.get(results[0]["driver_id"])
		if winner:
			winner.marketability = clamp(winner.marketability + 0.3, 0.0, 100.0)

	return results

## Shadow-simulate an entire season for all non-player groups.
## Called once at season start to pre-populate standings (lazy option)
## OR incrementally each race week (realistic option — used here).
## This method is for the incremental approach: call per race week.
func shadow_simulate_week(champ_id: String, week: int, all_drivers: Dictionary) -> void:
	## Find races this week for this tier
	var races_this_week: Array = []
	for race in week_race_map.get(champ_id, []):
		if race["week"] == week:
			races_this_week.append(race)
	if races_this_week.is_empty(): return

	## Shadow-simulate all groups except group 0 (player's group)
	var n_groups = groups[champ_id].size()
	for g_idx in range(1, n_groups):
		shadow_simulate_race(champ_id, g_idx, all_drivers)

## ── TP Proposals ──────────────────────────────────────────────────────────────

func _generate_tp_proposals(
		all_drivers: Dictionary,
		all_staff: Dictionary,
		player_driver_ids: Array,
		registered_champ_ids: Array,
		player_car_tiers: Array = []) -> void:

	tp_proposals = []

	for did in player_driver_ids:
		var d = all_drivers.get(did)
		if not d: continue

		## Find which GK tiers this driver is age-eligible for
		var eligible_tiers: Array = []
		for cid in TIER_ORDER:
			if cid in registered_champ_ids and \
					d.age >= TIER_MIN_AGE[cid] and d.age <= TIER_MAX_AGE[cid]:
				eligible_tiers.append(cid)

		if eligible_tiers.is_empty(): continue

		## Split into tiers with a car vs tiers missing a car
		var has_car_tiers: Array = []
		var no_car_tiers: Array = []
		for cid in eligible_tiers:
			if cid in player_car_tiers:
				has_car_tiers.append(cid)
			else:
				no_car_tiers.append(cid)

		## Proposal for tiers where car exists
		if has_car_tiers.size() > 0:
			var tier_names: Array = []
			for cid in has_car_tiers: tier_names.append(TIER_NAMES.get(cid, cid))
			var driver_name = d.full_name() if d.has_method("full_name") else str(d)
			tp_proposals.append({
				"type":       "driver_assignment",
				"driver_id":  did,
				"driver_name": driver_name,
				"champ_ids":  has_car_tiers,
				"tier_names": tier_names,
				"note":       "TP suggests: %s → %s" % [driver_name, ", ".join(tier_names)],
			})

		## Advisory for tiers missing a car
		for cid in no_car_tiers:
			var tier_name = TIER_NAMES.get(cid, cid)
			var driver_name = d.full_name() if d.has_method("full_name") else str(d)
			tp_proposals.append({
				"type":       "car_needed",
				"driver_id":  did,
				"driver_name": driver_name,
				"champ_ids":  [cid],
				"tier_names": [tier_name],
				"note":       "TP: %s is eligible for GK %s but you need a car registered there." % [
					driver_name, tier_name],
			})

	## Mechanic proposals — unchanged
	for sid in all_staff:
		var s = all_staff[sid]
		if s.contract_team == "": continue
		if s.role != "Race Mechanic": continue
		var covered = mechanic_tier_assignments.get(sid, [])
		if covered.is_empty(): continue
		var eligible: Array = []
		for cid in covered:
			if cid in registered_champ_ids:
				eligible.append(cid)
		if eligible.is_empty(): continue
		var tier_names: Array = []
		for cid in eligible: tier_names.append(TIER_NAMES.get(cid, cid))
		var mech_name = s.full_name() if s.has_method("full_name") else str(s)
		tp_proposals.append({
			"type":        "mechanic_assignment",
			"mechanic_id": sid,
			"mechanic_name": mech_name,
			"champ_ids":   eligible,
			"tier_names":  tier_names,
			"note":        "TP suggests mechanic %s covers: %s" % [
				mech_name, ", ".join(tier_names)],
		})

## ── Getters ───────────────────────────────────────────────────────────────────

## Returns Group 0 driver list for a given tier (player's group).
func get_player_group(champ_id: String) -> Array:
	if not groups.has(champ_id): return []
	if groups[champ_id].is_empty(): return []
	return groups[champ_id][0]

## Returns all group standings for a tier, sorted by points desc within each group.
func get_standings(champ_id: String) -> Array:
	if not shadow_standings.has(champ_id): return []
	var result: Array = []
	for g_idx in range(shadow_standings[champ_id].size()):
		var g_copy = shadow_standings[champ_id][g_idx].duplicate(true)
		g_copy.sort_custom(func(a, b): return a["points"] > b["points"])
		result.append(g_copy)
	return result

## Returns the overall discipline standings across all groups (merged, sorted by pts).
func get_overall_standings(champ_id: String) -> Array:
	var merged: Array = []
	for g_idx in range(shadow_standings.get(champ_id, []).size()):
		for entry in shadow_standings[champ_id][g_idx]:
			merged.append(entry.duplicate())
	merged.sort_custom(func(a, b): return a["points"] > b["points"])
	return merged

## Returns pending TP proposals (not yet reviewed).
func get_pending_proposals() -> Array:
	if proposals_reviewed: return []
	return tp_proposals

## Returns total driver count across all groups for a tier.
func get_total_drivers(champ_id: String) -> int:
	var count = 0
	for g in groups.get(champ_id, []):
		count += g.size()
	return count

## Returns number of groups for a tier.
func get_group_count(champ_id: String) -> int:
	return groups.get(champ_id, []).size()

## ── Roster Change Detection ──────────────────────────────────────────────────

## Snapshot of driver IDs + ages at last proposal generation.
## Format: {driver_id: age}
var _last_proposal_roster: Dictionary = {}

## Takes a snapshot of the current GK driver pool for change detection.
func snapshot_roster(all_drivers: Dictionary) -> void:
	_last_proposal_roster = {}
	for did in driver_tier_assignments:
		var d = all_drivers.get(did)
		if d:
			_last_proposal_roster[did] = d.age

## Returns true if the GK driver roster has materially changed since
## the last proposal snapshot — new drivers, departures, or age crossings.
func has_roster_changes(all_drivers: Dictionary, player_driver_ids: Array) -> bool:
	## New or departed player drivers
	for did in player_driver_ids:
		if not did in _last_proposal_roster:
			return true
	for did in _last_proposal_roster:
		var d = all_drivers.get(did)
		## Driver left or aged out of all tiers
		if not d: return true
		if d.age != _last_proposal_roster[did]:
			## Check if age crossing changes tier eligibility
			for cid in TIER_ORDER:
				var was_eligible = _last_proposal_roster[did] >= TIER_MIN_AGE[cid] \
					and _last_proposal_roster[did] <= TIER_MAX_AGE[cid]
				var now_eligible = d.age >= TIER_MIN_AGE[cid] \
					and d.age <= TIER_MAX_AGE[cid]
				if was_eligible != now_eligible:
					return true
	return false

## Returns weekly TP proposals for upcoming GK races.
## Only returns proposals if the race is within the next 2 weeks
## AND the roster has changed since last review.
## all_drivers: GameState.all_drivers
## current_week: int
## player_driver_ids: Array
func get_weekly_proposals(all_drivers: Dictionary, current_week: int,
		player_driver_ids: Array) -> Array:
	if not has_roster_changes(all_drivers, player_driver_ids):
		return []
	## Check if any GK tier has a race in the next 1-2 weeks
	var has_upcoming = false
	for cid in TIER_ORDER:
		for race in week_race_map.get(cid, []):
			if race["week"] > current_week and race["week"] <= current_week + 2:
				has_upcoming = true
				break
		if has_upcoming: break
	if not has_upcoming:
		return []
	return tp_proposals

## ── Save / Load ───────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"groups":                    groups,
		"shadow_standings":          shadow_standings,
		"driver_tier_assignments":   driver_tier_assignments,
		"mechanic_tier_assignments": mechanic_tier_assignments,
		"week_race_map":             week_race_map,
		"tp_proposals":              tp_proposals,
		"proposals_reviewed":        proposals_reviewed,
		"last_proposal_roster":      _last_proposal_roster,
	}

func deserialize(data: Dictionary) -> void:
	if "groups"                    in data: groups                    = data["groups"]
	if "shadow_standings"          in data: shadow_standings          = data["shadow_standings"]
	if "driver_tier_assignments"   in data: driver_tier_assignments   = data["driver_tier_assignments"]
	if "mechanic_tier_assignments" in data: mechanic_tier_assignments = data["mechanic_tier_assignments"]
	if "week_race_map"             in data: week_race_map             = data["week_race_map"]
	if "tp_proposals"              in data: tp_proposals              = data["tp_proposals"]
	if "proposals_reviewed"        in data: proposals_reviewed        = data["proposals_reviewed"]
	if "last_proposal_roster"      in data: _last_proposal_roster     = data["last_proposal_roster"]
