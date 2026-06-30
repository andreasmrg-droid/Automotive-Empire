class_name CommercialMarketSim
## Version: S39.6 — remove_player_producer (share folds to Others when a line stops)
## Version: S39.4 — Lightweight per-season share HISTORY for the evolution line chart: _sample_history
##   captures one snapshot per segment per season (last HISTORY_SEASONS=5 kept), seeded at new-game and
##   persisted in save/load (pre-S39.4 saves start empty and fill in). get_segment_history() feeds the
##   Commercial Department line chart. Negligible memory/save cost; chart redraws only when open.
## Version: S39.0 — Halo volume boost (per design owner + re-sim): bespoke_hyper 800→2400/yr and
##   megacars 300→900/yr (×3). At real volumes these halo segments could never amortize a realistic
##   blueprint design cost (1–2 cars/wk); ×3 makes them viable (≈8-season payback, a prestige stretch)
##   while staying by far the rarest segments (exclusivity preserved). All other data unchanged.
## Version: S38.0 — Phase 3 CORE: the commercial-car market engine. Pure, Python-portable
##   RefCounted implementing the LOCKED v4 attractiveness / redistribution model (GDD §4.1,
##   Phase3_Commercial_Validation.md). 12 segments + seeded producers embedded from the Excel
##   "Commercial Cars Industry" tab (v2.9). Validated over 100 headless seasons: 0/12 runaway
##   monopolies, volume leaders 12–17%, cold-start player climbs 9–29% on merit, Others 2–7%.
##
## RESPONSIBILITY (this file ONLY): own the per-segment share dynamics + demand, and turn realized
##   sales into raw (pre-scale) commercial credits. It does NOT touch finances, save/load, UI, or
##   notifications — those integrate via FinancialEngine, GameState, the Commercial Department scene,
##   and NotificationManager respectively (Phase3_Commercial_Validation.md §10). Kept dependency-free
##   (no gs reference required for the pure math) so it stays Python-portable and headless-testable.
##
## USAGE:
##   var sim := CommercialMarketSim.new()
##   sim.seed_market(staggered_seed=true)          # new game (or restore via load_state)
##   sim.advance_week(economy_index, player_inputs) # each weekly tick
##   var credits := sim.weekly_player_credits(...)   # FinancialEngine reads this
extends RefCounted

# ─────────────────────────────────────────────────────────────────────────────
# LOCKED ENGINE CONSTANTS (GDD §4 calibrated table; do NOT retune without a
# fresh 100-season headless pass — see Phase3_Commercial_Validation.md §4/§9).
# ─────────────────────────────────────────────────────────────────────────────
const INERTIA: float        = 0.045     ## ~5–8 season climb for a newcomer
const OTHERS_ATTR: float    = 0.35      ## resisting residual bloc attractiveness
const GIANT_BONUS: float    = 0.15      ## volume-giant attractiveness bump
const CREDIT_SCALE: float   = 0.0054    ## real-$ margins → game credits (mature ≈1.18× racing)
const FACTORY_CAP_MULT: float = 2.0     ## hard max: Factory income ≤ 2× racing income
const MARKETING_GROSS_FRAC: float = 0.18 ## recommended marketing ≈ 18% of gross

# Lifecycle (seasons): ramp → plateau → death. Decline is competitiveness-driven (freshness),
# not a hard cutoff, but 25s is the practical death age for an un-refreshed model.
const RAMP_SEASONS: float    = 2.5
const PLATEAU_END: float     = 16.0
const DEATH_SEASON: float    = 25.0

# Per-segment economy cyclicality by market type (recession resistance scales with prestige).
const CYCLICALITY := {"Mass": 0.45, "Premium": 0.25, "Hyper": 0.08}

# ─────────────────────────────────────────────────────────────────────────────
# SEGMENT DATA — embedded from Excel "Commercial Cars Industry" (v2.9).
# margin = Margin_Per_Unit (real $), volume = Global_Annual_Market_Volume,
# l1_capacity from GDD (500 u/wk L1, +250/level). market_type drives cyclicality.
# producers[] = seeded AI incumbents with starting share; the residual is "Others".
# unlock = the Factory_Unlock championship ID (Championships col BF).
# ─────────────────────────────────────────────────────────────────────────────
const SEGMENTS := {
	"economy_hatch": {
		"name": "Economy Hatchbacks", "market_type": "Mass", "margin": 8500,
		"volume": 22000000, "difficulty": 1.4, "unlock": "C-005",
		"producers": [["Ironwood Motorsports", 0.048], ["Heartland Racing", 0.042], ["Texas Thunder Racing", 0.039]],
		"giants": ["Ironwood Motorsports", "Heartland Racing", "Texas Thunder Racing"]
	},
	"hot_hatch": {
		"name": "AWD Hot Hatches", "market_type": "Premium", "margin": 20000,
		"volume": 1200000, "difficulty": 1.15, "unlock": "C-006",
		"producers": [["Sakura Motorsport", 0.125], ["Valkyrie Racing", 0.108], ["Alpine Thunder", 0.092], ["Thunderbolt Team", 0.075]],
		"giants": []
	},
	"pickups": {
		"name": "Utility Pickups", "market_type": "Mass", "margin": 24000,
		"volume": 8500000, "difficulty": 1.25, "unlock": "C-015",
		"producers": [["Ironwood Motorsports", 0.112], ["Heartland Racing", 0.104], ["Texas Thunder Racing", 0.098]],
		"giants": ["Ironwood Motorsports", "Heartland Racing", "Texas Thunder Racing"]
	},
	"pony": {
		"name": "Pony Cars", "market_type": "Premium", "margin": 20500,
		"volume": 450000, "difficulty": 1.05, "unlock": "C-016",
		"producers": [["Ironwood Motorsports", 0.175], ["Heartland Racing", 0.158], ["Texas Thunder Racing", 0.142]],
		"giants": ["Ironwood Motorsports", "Heartland Racing", "Texas Thunder Racing"]
	},
	"rally_replica": {
		"name": "Rally Replica Sedans", "market_type": "Premium", "margin": 21000,
		"volume": 350000, "difficulty": 1.0, "unlock": "C-007",
		"producers": [["Sakura Motorsport", 0.180], ["Valkyrie Racing", 0.145]],
		"giants": []
	},
	"track_day": {
		"name": "Track Day Specials", "market_type": "Premium", "margin": 47500,
		"volume": 80000, "difficulty": 0.9, "unlock": "C-019",
		"producers": [["Valkyrie Racing", 0.22], ["Thunderbolt Team", 0.18], ["Sakura Motorsport", 0.15]],
		"giants": []
	},
	"entry_sports": {
		"name": "Entry Sports Cars", "market_type": "Premium", "margin": 13500,
		"volume": 850000, "difficulty": 0.85, "unlock": "C-009",
		"producers": [["Valkyrie Racing", 0.135], ["Thunderbolt Team", 0.118], ["Sakura Motorsport", 0.105], ["Alpine Thunder", 0.082]],
		"giants": []
	},
	"v8_sedan": {
		"name": "V8 Sports Sedans", "market_type": "Premium", "margin": 36500,
		"volume": 650000, "difficulty": 0.8, "unlock": "C-017",
		"producers": [["Thunderbolt Team", 0.215], ["Alpine Thunder", 0.120]],
		"giants": []
	},
	"supercars": {
		"name": "Supercars", "market_type": "Hyper", "margin": 185000,
		"volume": 35000, "difficulty": 0.6, "unlock": "C-010",
		"producers": [["Blackthorn Racing", 0.165], ["Redline Syndicate", 0.148], ["Obsidian Motorsport", 0.132], ["Eclipse Alliance", 0.115], ["Monarch Racing", 0.098], ["Excalibur Motorsport", 0.082]],
		"giants": []
	},
	"ev_flagship": {
		"name": "EV Hybrid Flagships", "market_type": "Premium", "margin": 68000,
		"volume": 1800000, "difficulty": 0.7, "unlock": "C-008",
		"producers": [["Blackthorn Racing", 0.138], ["Redline Syndicate", 0.125], ["Obsidian Motorsport", 0.112], ["Eclipse Alliance", 0.104], ["Monarch Racing", 0.098]],
		"giants": []
	},
	"bespoke_hyper": {
		"name": "Bespoke Hypercars", "market_type": "Hyper", "margin": 1575000,
		"volume": 2400, "difficulty": 0.45, "unlock": "C-020",
		"producers": [["Blackthorn Racing", 0.19], ["Obsidian Motorsport", 0.17], ["Excalibur Motorsport", 0.14], ["Monarch Racing", 0.12]],
		"giants": []
	},
	"megacars": {
		"name": "Limited Run Megacars", "market_type": "Hyper", "margin": 3150000,
		"volume": 900, "difficulty": 0.4, "unlock": "C-024",
		"producers": [["Blackthorn Racing", 0.22], ["Obsidian Motorsport", 0.18], ["Excalibur Motorsport", 0.15]],
		"giants": []
	}
}

# The 7 named volume giants that occupy mass/volume segments (replace faceless "Others" there).
const VOLUME_GIANTS := ["Meridian Motors", "Continental Auto", "Pacifica Group",
	"Aurora Vehicles", "Summit Automotive", "Northwind Motors", "Crestline Group"]

# ─────────────────────────────────────────────────────────────────────────────
# RUNTIME STATE  (all save/load-serialized via to_dict / from_dict)
# market[seg_key] = {
#   "producers": [ {name, reputation, freshness, marketing, is_giant, share, age_seasons, is_player} ],
#   "others": float
# }
# ─────────────────────────────────────────────────────────────────────────────
var market: Dictionary = {}
## S39.4 — lightweight share-history for the evolution line chart. Sampled ONCE PER SEASON (not per
## week) so it stays tiny: per segment we keep the last HISTORY_SEASONS snapshots, each a
## { "season": int, "shares": { brand_name: float, …, "Others": float } }. ~12 segments × ~6 brands ×
## 5 seasons ≈ a few hundred floats — negligible in memory and in the save, and the chart only redraws
## when the screen is open. Order is oldest → newest.
const HISTORY_SEASONS: int = 5
var _history: Dictionary = {}   ## seg_key -> Array[snapshot]
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

# ── Producer record helper ────────────────────────────────────────────────────
static func _make_producer(name: String, rep: float, fresh: float, marketing: float,
		is_giant: bool, share: float, age: float = 0.0, is_player: bool = false) -> Dictionary:
	return {
		"name": name, "reputation": rep, "freshness": fresh, "marketing": marketing,
		"is_giant": is_giant, "share": share, "age_seasons": age, "is_player": is_player
	}

# ─────────────────────────────────────────────────────────────────────────────
# SEEDING — new game. staggered_seed places AI models at varied mid-life ages so
# the industry looks mature on day one and avoids synchronized death waves (§4.2/§4.6).
# ─────────────────────────────────────────────────────────────────────────────
func seed_market(staggered_seed: bool = true) -> void:
	market.clear()
	for seg_key in SEGMENTS:
		var seg: Dictionary = SEGMENTS[seg_key]
		var producers: Array = []
		var giant_names: Array = seg.get("giants", [])
		for entry in seg["producers"]:
			var pname: String = entry[0]
			var pshare: float = float(entry[1])
			# Seed reputation roughly from starting share (leaders are well-known);
			# freshness staggered so models sit at different lifecycle points.
			var rep: float = clamp(45.0 + pshare * 180.0, 40.0, 92.0)
			var fresh: float = 0.55
			var age: float = 0.0
			if staggered_seed:
				age = _rng.randf_range(2.0, 14.0)              # mid-life spread
				fresh = _freshness_for_age(age)
			producers.append(_make_producer(
				pname, rep, fresh, 1.0, pname in giant_names, pshare, age))
		# Add a volume giant to mass-type segments that aren't already saturated,
		# replacing part of the faceless Others with a real beatable incumbent.
		if seg["market_type"] == "Mass":
			var taken: float = 0.0
			for p in producers: taken += p["share"]
			if taken < 0.55:
				var g: String = VOLUME_GIANTS[hash(seg_key) % VOLUME_GIANTS.size()]
				var already := false
				for p in producers:
					if p["name"] == g: already = true
				if not already:
					var gshare: float = _rng.randf_range(0.10, 0.16)
					var gage: float = _rng.randf_range(3.0, 12.0) if staggered_seed else 0.0
					producers.append(_make_producer(
						g, 80.0, _freshness_for_age(gage), 1.0, true, gshare, gage))
		var others: float = max(0.0, 1.0 - _sum_share(producers))
		market[seg_key] = {"producers": producers, "others": others}
	## Seed one initial history point so the evolution chart has a starting value from week 1.
	_history.clear()
	_sample_history()

# ── Lifecycle freshness curve ─────────────────────────────────────────────────
## Freshness 0..1 as a function of model age (seasons). Ramp up, long plateau, decline to death.
static func _freshness_for_age(age: float) -> float:
	if age <= RAMP_SEASONS:
		return lerp(0.4, 1.0, age / RAMP_SEASONS)          # ramp from launch
	if age <= PLATEAU_END:
		return 1.0 - (age - RAMP_SEASONS) / (PLATEAU_END - RAMP_SEASONS) * 0.15  # gentle plateau drift
	if age >= DEATH_SEASON:
		return 0.05
	# Decline phase
	return lerp(0.85, 0.05, (age - PLATEAU_END) / (DEATH_SEASON - PLATEAU_END))

# ─────────────────────────────────────────────────────────────────────────────
# ATTRACTIVENESS / REDISTRIBUTION  (the locked v4 core — GDD §4.1)
# ─────────────────────────────────────────────────────────────────────────────
static func _attractiveness(p: Dictionary, sales_factor: float) -> float:
	var a: float = (1.0 * (p["reputation"] / 100.0)
		+ 0.8 * p["freshness"]
		+ 0.6 * (p["marketing"] - 1.0)
		+ (GIANT_BONUS if p["is_giant"] else 0.0))
	if p["is_player"]:
		a *= sales_factor
	return max(a, 0.0)

## One weekly redistribution pass for a single segment, in place.
## Thinly-contested segments (≤3 incumbents) get a stronger Others bloc so a lone strong
## entrant can't over-claim — keeps the player within the validated 9–29% band (the v2→v4
## journey applied the same resisting-residual fix to sparse markets).
func _redistribute(seg_state: Dictionary, sales_factor: float) -> void:
	var producers: Array = seg_state["producers"]
	var ai_count: int = 0
	for p in producers:
		if not p["is_player"]:
			ai_count += 1
	var others_attr: float = OTHERS_ATTR
	if ai_count <= 2:
		others_attr = OTHERS_ATTR + 0.50      # very sparse (2 incumbents)
	elif ai_count == 3:
		others_attr = OTHERS_ATTR + 0.25      # sparse (3 incumbents)
	var total: float = others_attr
	var attrs: Array = []
	for p in producers:
		var a: float = _attractiveness(p, sales_factor)
		attrs.append(a)
		total += a
	if total <= 0.0:
		return
	for i in range(producers.size()):
		var deserved: float = attrs[i] / total
		producers[i]["share"] += (deserved - producers[i]["share"]) * INERTIA
		producers[i]["share"] = clamp(producers[i]["share"], 0.0, 1.0)
	seg_state["others"] = max(0.0, 1.0 - _sum_share(producers))

# ─────────────────────────────────────────────────────────────────────────────
# WEEKLY ADVANCE
# player_inputs[seg_key] = {"reputation": float, "marketing": float, "age_seasons": float,
#                           "active": bool}  — supplied by GameState/Factory for owned lines.
# sales_factor = CFO sales_factor (0.75…1.25); applies to the PLAYER producer only.
# ─────────────────────────────────────────────────────────────────────────────
func advance_week(player_inputs: Dictionary = {}, sales_factor: float = 1.0) -> void:
	for seg_key in market:
		var seg_state: Dictionary = market[seg_key]
		_sync_player_producer(seg_key, seg_state, player_inputs.get(seg_key, null))
		_redistribute(seg_state, sales_factor)

## Season tick — ages every model, AI auto-refreshes near end-of-life (§4.2).
func advance_season() -> void:
	## Snapshot the end-of-season share state for the evolution chart, then age models.
	_sample_history()
	for seg_key in market:
		for p in market[seg_key]["producers"]:
			p["age_seasons"] += 1.0
			if not p["is_player"]:
				# AI auto-refresh: a model nearing death has a chance to launch a successor.
				if p["age_seasons"] >= 18.0 and _rng.randf() < 0.45:
					p["age_seasons"] = 0.0
				p["freshness"] = _freshness_for_age(p["age_seasons"])

## Capture a per-segment share snapshot (one per season). Keeps only the last HISTORY_SEASONS.
func _sample_history(season_label: int = -1) -> void:
	for seg_key in market:
		var shares: Dictionary = {}
		for p in market[seg_key]["producers"]:
			shares[p["name"]] = float(p["share"])
		shares["Others"] = float(market[seg_key].get("others", 0.0))
		var snap = {"season": season_label, "shares": shares}
		if not _history.has(seg_key):
			_history[seg_key] = []
		_history[seg_key].append(snap)
		while _history[seg_key].size() > HISTORY_SEASONS:
			_history[seg_key].pop_front()

## Returns the recorded history for a segment: Array[ {season, shares{}} ], oldest → newest.
func get_segment_history(seg_key: String) -> Array:
	return _history.get(seg_key, [])

# ── Insert / update the player's producer record inside a segment ─────────────
func _sync_player_producer(seg_key: String, seg_state: Dictionary, pin) -> void:
	var producers: Array = seg_state["producers"]
	var existing: Dictionary = {}
	for p in producers:
		if p["is_player"]:
			existing = p
			break
	if pin == null:
		return  # player not in this segment; leave market untouched
	if existing.is_empty():
		# Cold-start entry at 0.5% (the player is always a new entrant).
		producers.append(_make_producer(
			"PLAYER", pin.get("reputation", 50.0), pin.get("freshness", _freshness_for_age(pin.get("age_seasons", 0.0))),
			pin.get("marketing", 1.0), false, 0.005, pin.get("age_seasons", 0.0), true))
		seg_state["others"] = max(0.0, seg_state["others"] - 0.005)
	else:
		existing["reputation"] = pin.get("reputation", existing["reputation"])
		existing["marketing"] = pin.get("marketing", existing["marketing"])
		existing["age_seasons"] = pin.get("age_seasons", existing["age_seasons"])
		existing["freshness"] = pin.get("freshness", _freshness_for_age(existing["age_seasons"]))

# ─────────────────────────────────────────────────────────────────────────────
# DEMAND & INCOME
# ─────────────────────────────────────────────────────────────────────────────
## Economy demand multiplier for a segment (§4.5). economy_index 0..100, neutral 50.
func demand_mult(seg_key: String, economy_index: float) -> float:
	var mt: String = SEGMENTS[seg_key]["market_type"]
	var cyc: float = CYCLICALITY.get(mt, 0.25)
	return 1.0 + ((economy_index - 50.0) / 50.0) * cyc

## Weekly unit demand reaching the PLAYER in a segment = (annual volume / 52) × share × demand_mult.
func player_weekly_demand(seg_key: String, economy_index: float) -> float:
	var share: float = get_player_share(seg_key)
	if share <= 0.0:
		return 0.0
	var weekly_volume: float = float(SEGMENTS[seg_key]["volume"]) / 52.0
	return weekly_volume * share * demand_mult(seg_key, economy_index)

## Per-line weekly capacity (GDD): 500 u/wk at L1, +250 per factory level.
static func line_capacity(factory_level: int) -> float:
	return 500.0 + 250.0 * float(max(0, factory_level - 1))

## Realized weekly commercial CREDITS for ONE player line in a segment.
## sales = min(demand, capacity); credits = sales × margin × CREDIT_SCALE × sales_factor.
func line_weekly_credits(seg_key: String, economy_index: float, factory_level: int,
		sales_factor: float = 1.0, output_bonus: float = 0.0) -> float:
	var demand: float = player_weekly_demand(seg_key, economy_index)
	var cap: float = line_capacity(factory_level) * (1.0 + output_bonus)
	var sales: float = min(demand, cap)
	var margin: float = float(SEGMENTS[seg_key]["margin"])
	return sales * margin * CREDIT_SCALE * sales_factor

## Recommended weekly marketing spend for a line (≈18% of gross at full demand).
func recommended_marketing(seg_key: String, economy_index: float, factory_level: int,
		sales_factor: float = 1.0) -> float:
	var gross: float = line_weekly_credits(seg_key, economy_index, factory_level, sales_factor)
	return gross * MARKETING_GROSS_FRAC

# ─────────────────────────────────────────────────────────────────────────────
# READ HELPERS (UI / FinancialEngine)
# ─────────────────────────────────────────────────────────────────────────────
func get_player_share(seg_key: String) -> float:
	if not market.has(seg_key):
		return 0.0
	for p in market[seg_key]["producers"]:
		if p["is_player"]:
			return p["share"]
	return 0.0

## S39.6 — Remove the player's producer from a segment (when a line is stopped). Its share is folded
## back into Others so the market re-normalises; rivals will reclaim it over subsequent weeks.
func remove_player_producer(seg_key: String) -> void:
	if not market.has(seg_key):
		return
	var producers: Array = market[seg_key]["producers"]
	for i in range(producers.size()):
		if producers[i]["is_player"]:
			market[seg_key]["others"] = float(market[seg_key].get("others", 0.0)) + float(producers[i]["share"])
			producers.remove_at(i)
			return

func get_segment_table(seg_key: String) -> Array:
	## Returns sorted [{name, share, is_player, is_giant}] + an "Others" row for UI.
	if not market.has(seg_key):
		return []
	var rows: Array = []
	for p in market[seg_key]["producers"]:
		rows.append({"name": p["name"], "share": p["share"],
			"is_player": p["is_player"], "is_giant": p["is_giant"]})
	rows.sort_custom(func(a, b): return a["share"] > b["share"])
	rows.append({"name": "Others", "share": market[seg_key]["others"],
		"is_player": false, "is_giant": false})
	return rows

func segment_keys() -> Array:
	return SEGMENTS.keys()

func segment_name(seg_key: String) -> String:
	return SEGMENTS.get(seg_key, {}).get("name", seg_key)

func unlock_championship(seg_key: String) -> String:
	return SEGMENTS.get(seg_key, {}).get("unlock", "")

## Reverse map: which segment a championship unlocks (or "" if none).
func segment_for_championship(cid: String) -> String:
	for seg_key in SEGMENTS:
		if SEGMENTS[seg_key]["unlock"] == cid:
			return seg_key
	return ""

static func _sum_share(producers: Array) -> float:
	var s: float = 0.0
	for p in producers:
		s += p["share"]
	return s

# ─────────────────────────────────────────────────────────────────────────────
# SAVE / LOAD
# ─────────────────────────────────────────────────────────────────────────────
func to_dict() -> Dictionary:
	return {"market": market, "history": _history}

func from_dict(data: Dictionary) -> void:
	if data.has("market") and data["market"] is Dictionary:
		market = data["market"]
	else:
		seed_market(true)
	## History is optional (pre-S39.4 saves won't have it) — start empty if absent; it fills in as
	## seasons roll over.
	if data.has("history") and data["history"] is Dictionary:
		_history = data["history"]
	else:
		_history = {}
