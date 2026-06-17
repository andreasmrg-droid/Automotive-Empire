extends Resource
class_name GKDiscipline
## Version: S28.3 — Added get_champion()/is_complete() (Bug 1: GK champion now derivable for
##   the EndOfSeason screen). get_champion() returns the top driver of the final round.
## --- S24.1 — Rewritten for single GK Championship (C-001).
## 4 progressive rounds: R1=32 groups, R2=16 groups×20, R3=4 groups×32, Final=2 groups×30.
## Player auto-assigned to a Round 1 group. Eliminated drivers sit out the rest of season.
## Non-player groups: lightweight simulation (standings only, no lap-by-lap).

const CHAMP_ID: String = "C-001"

## Round structure
const ROUNDS: Array = [
	{"round": 1, "groups": 32, "max_per_group": 0,  "qualify_per_group": 10, "races": 8,  "gk_round": 1},
	{"round": 2, "groups": 16, "max_per_group": 20, "qualify_per_group": 8,  "races": 10, "gk_round": 2},
	{"round": 3, "groups": 4,  "max_per_group": 32, "qualify_per_group": 15, "races": 5,  "gk_round": 3},
	{"round": 4, "groups": 2,  "max_per_group": 30, "qualify_per_group": 10, "races": 2,  "gk_round": 4},
]

## group_drivers[round_idx][group_idx] = Array of driver_ids
var group_drivers: Array = []

## shadow_standings[round_idx][group_idx] = Array of {driver_id, points, wins, races}
var shadow_standings: Array = []

## Current round (0-indexed)
var current_round: int = 0

## Player's group index within current round
var player_group: int = 0

## Eliminated driver ids — cannot advance
var eliminated: Dictionary = {}

## ── Init ──────────────────────────────────────────────────────────────────────

func _init() -> void:
	group_drivers  = []
	shadow_standings = []
	current_round  = 0
	player_group   = 0
	eliminated     = {}


## ── populate_season ───────────────────────────────────────────────────────────

func populate_season(
		all_drivers:              Dictionary,
		_all_staff:               Dictionary,
		player_driver_ids:        Array,
		_registered_champ_ids:    Array,
		_calendars:               Dictionary,
		_season:                  int,
		_player_cars:             Array) -> void:

	## Reset for new season
	group_drivers    = []
	shadow_standings = []
	current_round    = 0
	eliminated       = {}

	## Collect all eligible GK drivers — exclude filler drivers (T-FILL/D-FILL)
	var candidates: Array = []
	for did in all_drivers:
		var d = all_drivers[did]
		if d.active_discipline != "GK": continue
		if eliminated.has(did): continue
		## Skip filler drivers and uncontracted FA pool drivers
		if did.begins_with("D-FILL") or d.contract_team.begins_with("T-FILL"):
			continue
		## Skip GK free agents (D-GK-FA) — they exist only for player hiring, not group racing
		if did.begins_with("D-GK-FA") or d.contract_team == "":
			continue
		candidates.append({"driver_id": did, "score": _driver_score(d), "age": d.age})

	candidates.sort_custom(func(a, b): return a["score"] > b["score"])

	## Build Round 1 groups
	var r1      = ROUNDS[0]
	var n_grps  = r1["groups"]  ## 32

	## Distribute candidates evenly — no empty groups
	var total   = candidates.size()
	var base    = total / n_grps if n_grps > 0 else 0
	var extras  = total % n_grps

	var grp_list: Array = []
	var stand_list: Array = []
	for g in range(n_grps):
		grp_list.append([])
		stand_list.append([])

	## Player drivers go into group 0 first
	var flat: Array = candidates.map(func(c): return c["driver_id"])
	for pid in player_driver_ids:
		flat.erase(pid)

	## Fill group 0 with player + some AI
	var g0_target = base + (1 if 0 < extras else 0)
	for pid in player_driver_ids:
		grp_list[0].append(pid)
		stand_list[0].append({"driver_id": pid, "points": 0, "wins": 0, "races": 0})

	## Fill rest of group 0 with AI up to target
	var ai_for_g0 = flat.slice(0, max(0, g0_target - grp_list[0].size()))
	for did in ai_for_g0:
		grp_list[0].append(did)
		stand_list[0].append({"driver_id": did, "points": 0, "wins": 0, "races": 0})
		flat.erase(did)

	## Assign player group
	player_group = 0

	## Distribute remaining to groups 1..31
	var current_pos = 0
	for g in range(1, n_grps):
		var count = base + (1 if g < extras else 0)
		for i in range(count):
			if current_pos >= flat.size(): break
			var did = flat[current_pos]
			grp_list[g].append(did)
			stand_list[g].append({"driver_id": did, "points": 0, "wins": 0, "races": 0})
			current_pos += 1

	group_drivers.append(grp_list)
	shadow_standings.append(stand_list)

	print("[GKDiscipline] Season populated: %d drivers in %d R1 groups" % [total, n_grps])
	print("[GKDiscipline] Player in group %d with %d drivers" % [player_group, grp_list[player_group].size()])


## ── Shadow simulate (non-player groups) ──────────────────────────────────────

func shadow_simulate_week(week: int, all_drivers: Dictionary) -> void:
	if current_round >= group_drivers.size(): return
	var grp_list   = group_drivers[current_round]
	var stand_list = shadow_standings[current_round]

	for g in range(grp_list.size()):
		if g == player_group: continue  ## Skip player's group — real sim handles it
		if grp_list[g].is_empty(): continue

		## Score each driver and shuffle slightly for randomness
		var scored: Array = []
		for did in grp_list[g]:
			if not did in all_drivers: continue
			var d     = all_drivers[did]
			var score = _driver_score(d) + randf_range(-5.0, 5.0)
			scored.append({"driver_id": did, "score": score})
		scored.sort_custom(func(a, b): return a["score"] > b["score"])

		## Award points (25-18-15-12-10-8-6-4-2-1)
		var pts = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]
		for i in range(scored.size()):
			var did = scored[i]["driver_id"]
			var p   = pts[i] if i < pts.size() else 0
			for entry in stand_list[g]:
				if entry["driver_id"] == did:
					entry["points"] += p
					entry["races"]  += 1
					if i == 0: entry["wins"] += 1
					break


## ── Round advancement ─────────────────────────────────────────────────────────

func advance_round(all_drivers: Dictionary) -> void:
	## Called at end of each round's last race
	## Qualifies top N from each group into next round
	if current_round >= ROUNDS.size(): return

	var r_data    = ROUNDS[current_round]
	var qualify_n = r_data["qualify_per_group"]
	var stand_list = shadow_standings[current_round]
	var grp_list   = group_drivers[current_round]

	## Collect qualifiers from each group
	var qualifiers: Array = []
	var player_qualified = false

	for g in range(stand_list.size()):
		var sorted_group = stand_list[g].duplicate()
		sorted_group.sort_custom(func(a, b): return a["points"] > b["points"])
		var q_count = 0
		for entry in sorted_group:
			if q_count >= qualify_n: break
			var did = entry["driver_id"]
			if not eliminated.has(did):
				qualifiers.append(did)
				if did in _get_player_driver_ids(all_drivers):
					player_qualified = true
				q_count += 1

		## Eliminate non-qualifiers from this group
		for entry in sorted_group:
			if entry not in sorted_group.slice(0, qualify_n):
				eliminated[entry["driver_id"]] = true

	## Notify if player not qualified
	if not player_qualified:
		## Player eliminated — season over for GK
		print("[GKDiscipline] Player eliminated at end of Round %d" % (current_round + 1))

	current_round += 1
	if current_round >= ROUNDS.size(): return

	## Build next round groups
	var next_r     = ROUNDS[current_round]
	var next_grps  = next_r["groups"]
	var next_max   = next_r["max_per_group"]

	var next_grp_list:   Array = []
	var next_stand_list: Array = []
	for g in range(next_grps):
		next_grp_list.append([])
		next_stand_list.append([])

	## Find player's group
	var player_ids = _get_player_driver_ids(all_drivers)
	var player_new_group = 0

	## Distribute qualifiers round-robin
	var q_idx = 0
	for did in qualifiers:
		var g = q_idx % next_grps
		if did in player_ids: player_new_group = g
		next_grp_list[g].append(did)
		next_stand_list[g].append({"driver_id": did, "points": 0, "wins": 0, "races": 0})
		q_idx += 1

	group_drivers.append(next_grp_list)
	shadow_standings.append(next_stand_list)
	player_group = player_new_group

	print("[GKDiscipline] Round %d: %d qualifiers in %d groups" % [current_round + 1, qualifiers.size(), next_grps])


func _get_player_driver_ids(all_drivers: Dictionary) -> Array:
	var result: Array = []
	for did in all_drivers:
		var d = all_drivers[did]
		if d.contract_team == "T-PLAYER":
			result.append(did)
	return result


## ── Helpers ───────────────────────────────────────────────────────────────────

func _driver_score(d) -> float:
	## Adaptation is critical — a new driver with 5% GK adapt performs at 50% stats
	## Formula: 0.5 + (adapt/200) keeps minimum at 50% even at 0 adapt
	## but academy drivers with 60%+ adapt will be significantly faster
	var adapt   = d.discipline_adaptation.get("GK", 1.0)
	var adapt_m = 0.5 + (adapt / 200.0)  ## 0% adapt → 0.50x, 60% adapt → 0.80x, 100% → 1.00x
	var raw     = d.pace * 0.35 + d.car_control * 0.25 + d.race_craft * 0.20 + d.focus * 0.20
	return raw * adapt_m


## ── Accessors ─────────────────────────────────────────────────────────────────

func get_player_group(champ_id: String) -> Array:
	if champ_id != CHAMP_ID: return []
	if current_round >= group_drivers.size(): return []
	if player_group >= group_drivers[current_round].size(): return []
	return group_drivers[current_round][player_group]


func get_standings(champ_id: String) -> Array:
	if champ_id != CHAMP_ID: return []
	if current_round >= shadow_standings.size(): return []
	if player_group >= shadow_standings[current_round].size(): return []
	return shadow_standings[current_round][player_group].duplicate()



func get_all_standings(champ_id: String) -> Array:
	## Returns Array of Arrays — one per group in current round.
	## Used by RacingWorld to display shadow group standings.
	if champ_id != CHAMP_ID: return []
	if current_round >= shadow_standings.size(): return []
	return shadow_standings[current_round].duplicate()

func get_group_count(_champ_id: String) -> int:
	if current_round >= ROUNDS.size(): return 0
	return ROUNDS[current_round]["groups"]


func get_current_round() -> int:
	return current_round + 1  ## 1-indexed for display


## S28.3 (Bug 1): true once the final round has been completed (current_round past last).
func is_complete() -> bool:
	return current_round >= ROUNDS.size()


## S28.3 (Bug 1): returns the GK champion {driver_id, points} after the final round,
## or {} if the season hasn't reached a champion yet.
## The champion is the highest-points driver across the FINAL round's groups.
func get_champion() -> Dictionary:
	## Final round standings live at the last populated index.
	var final_idx = shadow_standings.size() - 1
	if final_idx < 0:
		return {}
	## Only declare a champion once we've actually run the final round (index 3 / round 4).
	if final_idx < ROUNDS.size() - 1:
		return {}
	var best := {}
	for group in shadow_standings[final_idx]:
		for entry in group:
			if best.is_empty() or entry["points"] > best.get("points", -1):
				best = entry
	return best.duplicate() if not best.is_empty() else {}


func is_eliminated(driver_id: String) -> bool:
	return eliminated.has(driver_id)


## Stub — GK TP proposals now handled by standard system like all other championships
func get_total_drivers(_champ_id: String) -> int:
	if current_round >= group_drivers.size(): return 0
	var total = 0
	for g in group_drivers[current_round]:
		total += g.size()
	return total


func get_pending_proposals() -> Array:
	return []


## ── Serialize / Deserialize ───────────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"current_round":   current_round,
		"player_group":    player_group,
		"group_drivers":   group_drivers,
		"shadow_standings":shadow_standings,
		"eliminated":      eliminated,
	}


func deserialize(data: Dictionary) -> void:
	current_round    = data.get("current_round",   0)
	player_group     = data.get("player_group",    0)
	group_drivers    = data.get("group_drivers",   [])
	shadow_standings = data.get("shadow_standings",[])
	eliminated       = data.get("eliminated",      {})
