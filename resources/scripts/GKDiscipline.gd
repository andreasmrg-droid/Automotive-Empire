extends Resource
class_name GKDiscipline
## Version: S37.2 — Added get_round_count() accessor (total GK rounds) for the Racing World world
##   card "GK Round X / N" display. No behavioural change to the sim.
## Version: S37.1 — CP4 follow-up: populate_season() no longer forces every player driver into GK
##   group 0. It now seeds group 0 only with drivers that ACTUALLY race GK — the player must be
##   registered in C-001 AND the driver must be on a GK car (discipline fallback during the season-
##   rollover car-wipe window). New player_in_gk flag records whether the player races GK this
##   season; when false, group 0 is an ordinary AI group: shadow_simulate_week() no longer skips it
##   as "the real sim handles it", so it (and the Grand Final) are simulated by the shadow sim. This
##   stops a non-GK (e.g. GP4) career from seeing a stray GK result screen. player_in_gk persisted.
## Version: S36.18 — GK final-weekend redesign. ROUNDS now 8/7/5/2 races; final round carries
##   semi_qualify_per_group:10. New apply_semifinal_cut(): after the Semi-Final, keep the top 10
##   per group across the 2 final groups and collapse them into ONE 20-driver Grand Final group
##   (points reset). get_champion() = the Grand Final group's top driver = the race winner (the
##   player's real Grand Final result is synced in via RaceSimulator, so a player win crowns the
##   player). get_all_standings() clamps to the last populated round (S36.16b, re-applied).
## Version: S36.15 — CP3 (#28): shadow_simulate_week() now RETURNS {team_id: points_earned} for the
##   non-player groups so GameState can fold them into the GK flat constructors table (the GK team
##   champion counts all 21 races; driver champion still uses elimination). Signature change: was
##   void, now returns Dictionary.
## Version: S35.3 — Added player_elimination_announced flag. The "your driver was eliminated…
##   Season over for GK" notification used to re-fire at the END OF EVERY subsequent round once
##   the player was out (eliminated stays true forever), so a Round-1 exit produced duplicate
##   "eliminated at Round 2 / Round 3" notices (all irrelevant — the player is already out). The
##   flag (reset each season alongside `eliminated`) lets GameState fire the notice exactly ONCE,
##   at the round of actual elimination. See GameState advance_week GK block.
## --- S28.3 — Added get_champion()/is_complete() (Bug 1: GK champion now derivable for
##   the EndOfSeason screen). get_champion() returns the top driver of the final round.
## --- S24.1 — Rewritten for single GK Championship (C-001).
## 4 progressive rounds: R1=32 groups, R2=16 groups×20, R3=4 groups×32, Final=2 groups×30.
## Player auto-assigned to a Round 1 group. Eliminated drivers sit out the rest of season.
## Non-player groups: lightweight simulation (standings only, no lap-by-lap).
## Race counts per round: 8 / 7 / 5 / 2 (the final round's 2 races run the SAME weekend —
## Semi-Final then Grand Final). semi_qualify_per_group = how many advance from EACH of the 2
## final groups into the single Grand Final field (10 each → 20-car final; winner = champion).

const CHAMP_ID: String = "C-001"

const ROUNDS: Array = [
	{"round": 1, "groups": 32, "max_per_group": 0,  "qualify_per_group": 10, "races": 8, "gk_round": 1},
	{"round": 2, "groups": 16, "max_per_group": 20, "qualify_per_group": 8,  "races": 7, "gk_round": 2},
	{"round": 3, "groups": 4,  "max_per_group": 32, "qualify_per_group": 15, "races": 5, "gk_round": 3},
	{"round": 4, "groups": 2,  "max_per_group": 30, "qualify_per_group": 10, "races": 2, "gk_round": 4, "semi_qualify_per_group": 10},
]

## group_drivers[round_idx][group_idx] = Array of driver_ids
var group_drivers: Array = []

## shadow_standings[round_idx][group_idx] = Array of {driver_id, points, wins, races}
var shadow_standings: Array = []

## Current round (0-indexed)
var current_round: int = 0

## Player's group index within current round
var player_group: int = 0

## CP4 follow-up — true only when the player ACTUALLY races GK this season (has a GK car with a
## driver). When false, group 0 is an ordinary all-AI group: the shadow sim simulates it like any
## other (it is NOT skipped as "the real sim handles it"), and no GK result screen is queued for
## the player. Set in populate_season; persisted in save/load.
var player_in_gk: bool = false

## Eliminated driver ids — cannot advance
var eliminated: Dictionary = {}

## S35.3 — set true once the player's GK elimination has been announced this season, so the
## "Season over for GK" notification fires exactly once (not every subsequent round). Reset
## each season in populate_season alongside `eliminated`.
var player_elimination_announced: bool = false

## ── Init ──────────────────────────────────────────────────────────────────────

func _init() -> void:
	group_drivers  = []
	shadow_standings = []
	current_round  = 0
	player_group   = 0
	player_in_gk   = false
	eliminated     = {}
	player_elimination_announced = false


## ── populate_season ───────────────────────────────────────────────────────────

func populate_season(
		all_drivers:              Dictionary,
		_all_staff:               Dictionary,
		player_driver_ids:        Array,
		registered_champ_ids:     Array,
		_calendars:               Dictionary,
		_season:                  int,
		player_cars:              Array) -> void:

	## Reset for new season
	group_drivers    = []
	shadow_standings = []
	current_round    = 0
	eliminated       = {}
	player_elimination_announced = false
	player_in_gk     = false

	## CP4 follow-up — only place player drivers into a GK group if the player ACTUALLY races GK.
	## Previously ALL player_driver_ids were forced into group 0 regardless of the player's
	## discipline, so a GP4 (or any non-GK) career still had its drivers seeded into GK group 0.
	## That made the GK championship's standings contain a player driver, which in turn made
	## RaceSimulator queue a GK result screen for a non-GK player (the "GK is still there" symptom).
	##
	## A player driver belongs in a GK group only when the player is registered in GK (C-001) AND
	## that driver actually races GK. "Races GK" is read from the car assignment when cars exist
	## (the authoritative signal), with a discipline fallback for the season-rollover window where
	## the previous season's cars have been / are about to be wiped (populate runs around the car
	## reset). If the player isn't registered in GK, the set is empty and the player never enters GK.
	var gk_player_driver_ids: Array = []
	if "C-001" in registered_champ_ids:
		var gk_assigned_driver_ids: Array = []
		for car in player_cars:
			if car.championship_id == "C-001" and car.driver_id != "":
				gk_assigned_driver_ids.append(car.driver_id)
		var have_gk_car = not gk_assigned_driver_ids.is_empty()
		for pid in player_driver_ids:
			if have_gk_car:
				## Cars present: trust the explicit GK car assignment.
				if pid in gk_assigned_driver_ids:
					gk_player_driver_ids.append(pid)
			else:
				## No GK car yet (rollover window): fall back to the driver's active discipline so a
				## GK career isn't dropped from its own groups just because cars haven't been rebought.
				var d = all_drivers.get(pid)
				if d != null and d.active_discipline == "GK":
					gk_player_driver_ids.append(pid)
	player_in_gk = not gk_player_driver_ids.is_empty()

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

	## Player drivers go into group 0 first (only those that actually race GK — see filter above).
	var flat: Array = candidates.map(func(c): return c["driver_id"])
	for pid in gk_player_driver_ids:
		flat.erase(pid)

	## Fill group 0 with player + some AI
	var g0_target = base + (1 if 0 < extras else 0)
	for pid in gk_player_driver_ids:
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

func shadow_simulate_week(week: int, all_drivers: Dictionary) -> Dictionary:
	## Returns {team_id: points_earned_this_week} for the non-player shadow groups, so the caller
	## (GameState) can fold them into the GK championship's flat team_standings table. CP3: the GK
	## TEAM champion is decided by a straightforward cumulative table across ALL 21 races (driver
	## champion still uses the elimination system). The player's own group feeds team points via
	## the normal _simulate_race path; this covers every other group.
	var team_points: Dictionary = {}
	if current_round >= group_drivers.size(): return team_points
	var grp_list   = group_drivers[current_round]
	var stand_list = shadow_standings[current_round]

	for g in range(grp_list.size()):
		## Skip the player's group ONLY when the player actually races GK — then the real race sim
		## handles group 0. When the player is NOT in GK, group 0 is an ordinary AI group and must
		## be simulated here, or it would go unraced all season.
		if player_in_gk and g == player_group: continue
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
			## CP3: accrue team points for this driver's team (flat GK constructors table).
			if p > 0 and did in all_drivers:
				var tid = all_drivers[did].contract_team
				if tid != "":
					team_points[tid] = team_points.get(tid, 0) + p
			for entry in stand_list[g]:
				if entry["driver_id"] == did:
					entry["points"] += p
					entry["races"]  += 1
					if i == 0: entry["wins"] += 1
					break
	return team_points


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


## ── Final weekend (race-aware, FINAL ROUND ONLY) ─────────────────────────────
## The final weekend is 2 races in the same week, both gk_round 4:
##   Race 1 (Semi-Final): run within the 2 final groups; top semi_qualify_per_group from EACH
##     group advance. Race 2 (Grand Final): the survivors (single group) race; winner = champion.
## apply_semifinal_cut() is called by GameState BETWEEN the two races: it takes the current
## final-round standings (Semi results — player's real result already synced into group 0),
## keeps the top N per group, and collapses them into ONE Grand Final group with fresh points.
func apply_semifinal_cut() -> void:
	if current_round != ROUNDS.size() - 1: return  ## final round only
	if current_round >= shadow_standings.size(): return
	var r_data = ROUNDS[current_round]
	var keep_n = r_data.get("semi_qualify_per_group", 10)
	var stand_list = shadow_standings[current_round]
	var grp_list   = group_drivers[current_round]

	## Collect top-N survivors from each group (by Semi points). Eliminate the rest.
	var finalists: Array = []           ## driver_ids advancing to the Grand Final
	var player_in_final = false
	var player_ids := {}                ## set of player driver ids (from group membership)
	for g in range(stand_list.size()):
		var sorted_group = stand_list[g].duplicate()
		sorted_group.sort_custom(func(a, b): return a["points"] > b["points"])
		for i in range(sorted_group.size()):
			var did = sorted_group[i]["driver_id"]
			if i < keep_n:
				finalists.append(did)
			else:
				eliminated[did] = true

	## Build a SINGLE Grand Final group of all finalists, points reset to 0 (the Grand Final is
	## a clean race — its result alone decides the champion).
	var final_group: Array = []
	var final_stand: Array = []
	for did in finalists:
		final_group.append(did)
		final_stand.append({"driver_id": did, "points": 0, "wins": 0, "races": 0})

	## Replace the final round's groups with the single collapsed Grand Final group.
	group_drivers[current_round] = [final_group]
	shadow_standings[current_round] = [final_stand]
	## The player's driver (if it survived) is now in group 0 of the final round.
	player_group = 0
	print("[GKDiscipline] Semi-Final cut: %d finalists into the Grand Final" % finalists.size())


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
	## Returns Array of Arrays — one per group in the round.
	## Used by RacingWorld (mid-season) and EOS (season end) to display GK group standings.
	if champ_id != CHAMP_ID: return []
	if shadow_standings.is_empty(): return []
	## At season end current_round advances PAST the last round, which used to return [] →
	## "GK season standings unavailable" on the EOS screen. Clamp to the last populated round.
	var idx = min(current_round, shadow_standings.size() - 1)
	return shadow_standings[idx].duplicate()

func get_group_count(_champ_id: String) -> int:
	if current_round >= ROUNDS.size(): return 0
	return ROUNDS[current_round]["groups"]


func get_current_round() -> int:
	return current_round + 1  ## 1-indexed for display


## Total number of GK rounds in a season (for "Round X / N" display).
func get_round_count() -> int:
	return ROUNDS.size()


## S28.3 (Bug 1): true once the final round has been completed (current_round past last).
func is_complete() -> bool:
	return current_round >= ROUNDS.size()


## Returns the GK champion {driver_id, points, ...} = the WINNER of the Grand Final (the last
## race). After apply_semifinal_cut() the final round holds a single 20-driver group; once the
## Grand Final has run, that group's top-points driver is the race winner = champion. (The
## player's real Grand Final result is synced into this group via RaceSimulator, so a player win
## here crowns the player.)
func get_champion() -> Dictionary:
	var final_idx = shadow_standings.size() - 1
	if final_idx < 0:
		return {}
	## Only declare a champion once we've reached the final round.
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
		"player_in_gk":    player_in_gk,
		"group_drivers":   group_drivers,
		"shadow_standings":shadow_standings,
		"eliminated":      eliminated,
	}


func deserialize(data: Dictionary) -> void:
	current_round    = data.get("current_round",   0)
	player_group     = data.get("player_group",    0)
	player_in_gk     = data.get("player_in_gk",    false)
	group_drivers    = data.get("group_drivers",   [])
	shadow_standings = data.get("shadow_standings",[])
	eliminated       = data.get("eliminated",      {})
