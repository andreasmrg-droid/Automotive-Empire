extends Node
## Version: S36.20 — Fixed TWO GK final-weekend/scoring bugs surfaced by playtesting. (1) NO
##   ELIMINATION: the two calendar-copy loops (setup + load paths) rebuilt each race entry copying
##   only 7 keys, STRIPPING gk_round/is_semifinal/is_final. So the running calendar had no
##   is_semifinal flag → the final-weekend hook never fired → the Grand Final ran on a full
##   30-driver group (no cut). Both copies now preserve those flags. (2) POINTS INFLATION: the P26
##   shadow-sim ran shadow_simulate_week() EVERY week regardless of whether GK raced, so AI groups
##   scored ~2× the player's race count (group leaders at 100-162 by mid-season). Now it runs only
##   on weeks GK actually races, and skips the Semi-Final week (already shadow-simmed in the hook).
##   Also removed the S36.18b [GK-DEBUG] prints.
## Version: S36.18 — GK final-weekend redesign + multi-event engine. (1) GENERAL: the weekly loop
##   now runs EVERY race a championship has this week via get_races_for_week() (was one race per
##   champ per week) — reusable for future Rally/Endurance multi-event weekends; single-race
##   championships are unaffected. (2) GK: calendar rebuilt to 8/7/5/2 = 22 races; the final 2
##   (Semi-Final + Grand Final) run the SAME week (46). After the Semi, apply_semifinal_cut() keeps
##   top-10 per group → a single 20-driver Grand Final; the player's REAL semi/final results feed
##   it (Option B). Round-advance detection scans to the LAST same-week race so the season
##   completes. Also re-applied S36.16: no team_standings.clear() each round (CP3 table survives).
## Version: S36.15 — Bug #28/#31 (cluster A core, CP3): GK shadow groups now feed the GK
##   championship's flat team_standings (constructors) table each week, so the GK TEAM champion
##   counts ALL 21 races (driver champion still via the elimination system). Folds the
##   {team_id: points} returned by gk_discipline.shadow_simulate_week() into C-001 team_standings.
## Version: S36.14 — Bug #31 (cluster A core, checkpoint 1): save/load now persists EVERY
##   championship's standings, keyed by id (_serialize_all_championship_standings /
##   _deserialize_all_championship_standings), instead of only the singular active_championship
##   (= GK). The weekly loop simulates all championships, so all 20+ accrue standings — persisting
##   one dropped the rest on save (= the "standings wiped" symptom #31). SAVE-BREAKING: old single-
##   "championship" saves are not migrated (per design decision — start a fresh game).
## Version: S36.2 — Per-championship logistics data fix: added CHAMP_LOGISTICS side-table
##   (real fuel "per weekend per car" + Spares_per_Race +10% damage buffer, from the Variables
##   Map "Championships" sheet) and assigned it in _setup_championship(), replacing the hardcoded
##   uniform 15 kg / 100 SP that made every championship show identical needs (Logistics screenshot).
## Version: S36.0 — Bug #14/#2 fix: get_team_active_fans() & get_team_marketability() now derive
##   the team's fan pool from player_registered_championships (the player's ACTUAL entries),
##   not active_championships (the whole 21-championship world). A brand-new GK team no longer
##   gets scored at the world's top tier (was ~891k fans → now correctly tiny). New shared helper
##   _player_global_fan_pool() SUMS each registered championship's global fans ("more
##   championships = more publicity"). Returns 0 fans when registered in nothing. Stale "24
##   championships" comments corrected to 21. (Richer within-discipline pyramid + horizontal
##   news bleed flagged for GDD — separate design pass, not implemented here.)
## Version: S35.13 — Added championship_tab_grid() (disciplines as rows by principle, tiers as
##   columns) for the 2D CNC + Studio tab grids.
## Version: S35.12 — Added championship_tab_order() (shared CNC + Studio tab ordering, derived
##   from registry rep/tier/discipline → GP1…GK). _approved_car_blueprints() is now CURRENT-season
##   only (model b), so Build Whole Car gates on current-season part blueprints.
## Version: S35.10d — Shortlist "All" aggregation: get_shortlisted_by_role("All") returns every
##   shortlisted person (drivers first); get_shortlist_counts() includes an "All" total.
## Version: S35.10 — Shortlist support: is_shortlisted serialized/deserialized for drivers + staff
##   (default false for old saves); shortlist API toggle_shortlist / is_shortlisted /
##   get_shortlisted_by_role / get_shortlist_counts (unified across drivers + the 6 staff roles).
## Version: S35.9 — Interest model: added team_refused_subjects cooldown dict (save/load) and
##   wrappers is_subject_interested / is_team_refusal_cooled_down / build_interest_context. See
##   ContractEngine S35.9.
## Version: S35.8 — Preload heavy scenes at startup. The HQ scene (large .tscn + 2600-line script)
##   was loaded from disk on FIRST navigation, causing a one-time first-open hitch (fine after, as
##   Godot caches the PackedScene). GameState (the first autoload) now preloads HQ.tscn +
##   ContractNegotiation.tscn into constants at init, so they're cached before any gameplay and the
##   first open is smooth. No circular-dependency risk (HQ uses GameState as a runtime singleton).
##   This is the inherent first-time LOADING cost — distinct from the S35.6/S35.7 per-render scan
##   fixes (those removed the repeated lag; this removes the one-time hitch). Load-game's object
##   reconstruction (~6600 objects) remains an inherent one-time cost, accepted by the owner.
## --- S35.7 — clear_walked_away_approaches() wrapper + called in advance_week (walk-away
##   entries clear after one week). See ContractEngine/HQ S35.7.
## Version: S35.6 — Player-staff cache (perf). all_staff holds ~5000+ entries; HQ (esp. the WRA/
##   overview tab), StaffHub and the finance strip used to scan ALL of them — sometimes in nested
##   loops (TP-slot check was 6 champs × 5000+ = ~30k iterations per render) — to find the player's
##   handful of staff. Added _player_staff_by_role / _player_staff_flat caches, rebuilt lazily on a
##   dirty flag set via invalidate_player_staff_cache() at the roster-mutation funnels (hire,
##   release, sign-activation, load, starting-setup, lifecycle cull). get_all_player_staff() and
##   get_player_staff_by_role() now read the cache. Fixes the HQ/WRA scene lag at its root.
## --- S35.5 — Living spare-parts price. SP is now economy-priced like fuel but as a
##   manufactured-goods commodity: get_sp_cost_per_unit() = BASE(1.0) × economy_mult (TIGHT
##   0.6–1.5 band, cf. Parts_Sale_Price_Multiplier) × sp_market_pressure (gentle mean-reverting
##   supply/demand wobble, ±15% bound, far calmer than fuel — small weekly move, rare mild shock
##   on the sheet's 0.04 cadence). buy_spare_parts + CFO auto-buy now charge it; Logistics shows
##   the live rate. sp_market_pressure is saved/loaded (default 1.0 for old saves) and updated
##   weekly in advance_week alongside the economy. Buy-only (no SP selling/hedging by design).
## --- S35.3 — (1) GK elimination notice fires ONCE (player_elimination_announced flag) —
##   was re-firing every subsequent round. (2) Economy notifications (state shift, fuel-price
##   shock) are CFO-gated — no CFO, no financial intelligence (the economy still moves). (3) Living
##   fuel price: get_fuel_cost_per_kg() = BASE(2.0) × Fuel_Price_Multiplier (economy-driven 0.5–3.0,
##   neutral 1.0 at index 50, per the Global Variables sheet); buy_fuel now charges it (was a dead
##   hardcoded CR 2/kg). (4) CFO auto-buy: cfo_auto_buy_for_race(champ) tops fuel+SP to EXACTLY the
##   next race's need at the living price, only if a CFO is hired and affordable, and ONLY while
##   simulating_to_season_end (the Skip-to-End fast-forward) — never in hands-on weekly play.
## --- S33.0 — TP Phase 2 (AI auto-assign). Added TEAM-SCOPED championship-role getters
##   _get_tp_for_championship_team()/_get_strategist_for_championship_team() (the player-scoped
##   versions are now thin wrappers passing player_team.id) so compute_optimal_assignments can
##   detect already-assigned championship roles for ANY team, not just the player's. Added
##   get_cars_for_team(team): resolves a team's cars (player → player_team_cars; AI → ai_cars
##   filtered by the CAR-{team.id}- id prefix). Added ai_auto_assign_all_teams() entry used by
##   SeasonManager at season rollover (S2+ only). Pairs with TPProposalEngine S33.0 +
##   AIManager S33.0 + SeasonManager S33.0.
## --- S32.3 — Added peek_tp_proposals(): read-only TP proposal compute (no notification/
##   TDL side effects) for the Racing Dept panel display. Pairs with TPProposalEngine S32.3.
## --- S31.0 — Bug 9 (discipline bleed): GK round notifications (elimination, round
##   complete, champion) now gated on the player being registered in GK — a non-GK career
##   (e.g. Rally) no longer receives GK messages. _regenerate_ai_team_cars no longer
##   hardcodes C-001/GK: it uses the team's actual championship for car_type, telemetry,
##   and pit-crew requirement. GK world shadow-sim still runs (living world), just no longer
##   leaks player-facing GK content into other disciplines.
## --- S30.7 — Fix: build_whole_car sets car.delivered=false explicitly (Option B),
##   no longer relying on CarManager to have done so. Pairs with restored CarManager.gd
##   S30.3 (which was missing from commit f5b8a48, leaving bought/built cars instantly
##   delivered — no in-build banner, no DNS).
## --- S30.4 — Phase 2 "Build Whole Car": one-pass own-build path. New engine API
##   can_build_whole_car / missing_car_blueprints / build_whole_car queues all 6 approved
##   part jobs, creates the in-build Car (acquisition="built") with a slot-aware delivery
##   week, and fires assignment + TP proposals via add_car. Delivery fields now serialized.
## --- S30.2 — Phase 2 car delivery clock: _process_car_deliveries() runs each
##   weekly tick (after CNC advance, before the race-check loop) and flips undelivered
##   player cars to delivered once current_week >= car.delivery_week. Paired with the
##   Car.gd delivery state (S30.0) and RaceSimulator DNS-until-ready (S30.1).
## --- S29.8 — GK: registry num_races 29->21 to match the 21-round calendar
##   (display-only; logic reads calendar size). Name already "GK Championship".
## --- S29.0 — C-014 SC Dev Series car cap 5 -> 4 (explicit max_cars:4/min_cars:1
##   added to registry; was falling back to default 2 in Logistics). Per GDD handoff
##   2026-06-18 §1: SC Dev was the only non-GK championship allowing 5; now ≤4 like the
##   rest. All OTHER per-championship cap imports remain backlogged (handoff §2).
## --- S28.4 — Pit crew assign/unassign wrappers (Bug 6).
## --- S28.3 — GK fixes: champion announced at final round (no "Round 5" — Bug 2);
##   GK team_standings now reset between rounds (Bug: was accumulating).
## --- S28.1: NextSeasonLedger registration model (GDD §16.3, §23.1) — fixes the
##   Season-2 car/registration collapse. Registrations now go to next_season_registrations
##   (the ledger) instead of player_registered_championships (current season). At season
##   transition the ledger is ACTIVATED into player_registered_championships, then cleared —
##   never blind-wiped. register_for_championship()/can_register_for_championship() operate
##   on the ledger. Added next_season_registrations (saved/loaded/reset). Deadline −1 week
##   for WRA approval (§23.3). Stale TP proposals cleared at transition (§23, shot 14 fix).
## --- S28.0: Added retired_personnel archive (driver/staff age retirements).
##   Reset on new game, persisted in save, defaulted on load for old saves.
##   Paired with SeasonManager S28.0 driver/staff lifecycle rewrite (Bug 2 fix).
## --- S27.0: P57 Phase 1: Season transition extracted to SeasonManager.gd.
##   _end_season(), start_new_season(), _process_off_season() now delegate to SeasonManager.
##   SeasonManager follows the 15-step order from GDD §16.3.
## --- S23.0 base: TP Auto-Assignment Proposals (P31 complete):
##   generate_tp_assignment_proposals(): sorts cars by prestige, assigns best drivers/
##   mechanics by effective skill (raw × discipline_adaptation/100). GK multi-tier:
##   same driver covers multiple cars if no different-track same-week conflict.
##   Non-GK: exclusive 1:1 assignment. DNS warnings for unavoidable conflicts.
##   Cross-discipline adaptation warnings. _fire_tp_proposal_notification().
##   apply_tp_proposals(): applies accepted assignments.
##   _check_tp_proposal_notifications(): regenerates 3 weeks before race, on roster change.
##   _last_tp_proposals cached for Racing Department display.
## --- S22.8 base: 16-issue batch fix session.
##   #2 GKDiscipline populated at setup_new_game (Season 1); GK Group 0 standings synced from race.
##   #3 RacingDept Renew triggers negotiation.  #4 Expired contracts release drivers/staff.
##   #8 Walk-away hides subject from list.  #10 Rally excluded from Strategist requirement.
##   #11 TDL auto-resolves completed items; _is_todo_item_resolved helper.
##   #12 Multi-race queue: _pending_race_results; consume_next_race_result().
##   #13 TDL entry when no next-season championships registered after Week 20.
##   #14 TP gate removed from Drivers/StaffHub UI; only applied for bond approach in GameState.
##   #15 assign_staff_to_championship allows TP reassignment (clears old, warns on conflict).
##   #16 Negotiation tightened: threshold 0.95→0.82; counter concessions 2-6% (was 10%).
## --- S22.7 base: weekly gate on sponsor negotiation, free agent timing popup.
##                    20/10/2/1 groups per tier. Shadow sim for non-player groups.
##                    Age gates: Regional 8-16, National 10-18, Continental 12-20, World 14-22.
##                    GK World moved to Week 42. CHAMPIONSHIP_REGISTRY age gates corrected.
##                    GKDiscipline populated each season start, shadow-simmed each race week.
##                    TP proposals generated for GK multi-tier driver+mechanic assignments.
##                    P31 expanded: get_tp_proposals_all() covers all disciplines.
## --- S21.0 base: Economy continuous index, fuel cap 600-2000 CR, P44 Loan system.

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

## P26 GK Discipline manager — groups, shadow sim, TP proposals
var gk_discipline: GKDiscipline = null
## P57 Season Manager — owns season lifecycle (end/start/off-season)
var _season_manager: SeasonManager = null
## P57 Financial Engine — owns weekly financial processing + loans
var _financial_engine: FinancialEngine = null
## P57 Race Simulator — owns race simulation + post-race processing
var _race_simulator: RaceSimulator = null
## P57 Contract Engine — owns negotiation, approach/bond, contracts
var _contract_engine: ContractEngine = null
## P57 R&D Engine — owns R&D tasks, WRA, CNC production
var _rnd_engine: RnDEngine = null
## P57 Notification Manager — owns notifications, TDL, logging
var _notification_manager: NotificationManager = null
## P57 Campus Manager — owns buildings, upgrades, stat bonuses
var _campus_manager: CampusManager = null
## P57 Sponsor Manager — owns sponsor generation, CFO search, sign/cancel
var _sponsor_manager: SponsorManager = null
## P57 Staff Manager — owns staff/driver generation, hiring, queries
var _staff_manager: StaffManager = null
## P57 Car Manager — owns car lifecycle, assignment, repairs, parts
var _car_manager: CarManager = null
## P57 Driver Manager — owns driver generation, hiring, queries
var _driver_manager: DriverManager = null
## P57 TP Proposal Engine — owns TP auto-assignment proposals
var _tp_engine: TPProposalEngine = null

## ═══════════════════════════════════════════════════════════════════════════
## STAFF SYSTEM CONSTANTS (data stays on GameState)
## ═══════════════════════════════════════════════════════════════════════════
const STAFF_ROLES = ["Race Mechanic", "Pit Crew", "Team Principal", "CFO", "Designer", "Race Strategist"]
const STAFF_BASE_SALARIES = {
	"Race Mechanic":   {"min": 180.0,  "max": 450.0},
	"Pit Crew":        {"min": 150.0,  "max": 380.0},
	"Team Principal":  {"min": 280.0,  "max": 650.0},
	"CFO":             {"min": 250.0,  "max": 580.0},
	"Designer":        {"min": 350.0,  "max": 750.0},
	"Race Strategist": {"min": 220.0,  "max": 520.0},
}
var _staff_id_counter: int = 0

## ═══════════════════════════════════════════════════════════════════════════
## CONTRACT DATA (data stays on GameState, logic in ContractEngine)
## ═══════════════════════════════════════════════════════════════════════════
var active_negotiation: Dictionary = {}
var active_approaches: Array = []
var walked_away_subjects: Dictionary = {}
## S35.9 — subjects whose current team refused to release them: subject_id → absolute week
## (season*52 + week) when they can be re-approached. Set on team refusal (26-week cooldown).
var team_refused_subjects: Dictionary = {}
signal negotiation_updated()
signal negotiation_concluded(accepted: bool, subject_id: String, subject_type: String)
signal approach_updated()
## Reputation inertia: team reputation moves toward target_reputation each season
var target_reputation:    float  = 15.0   ## What the team has earned this season
var reputation_velocity:  float  = 0.0    ## How fast rep moves toward target

## Legacy bonus: when a star driver leaves, their fame lingers for 3 seasons
## Array of {seasons_remaining: int, bonus: float}
var reputation_legacy_bonuses: Array = []

## Consecutive drivers champion tracking per discipline (for competition_factor)
## keyed by championship_id: how many seasons same driver has won
var consecutive_win_counts: Dictionary = {}

## Returns all difficulty multipliers for the current game_difficulty setting.
## ai_performance: multiplier on AI lap times (>1 = AI faster, <1 = AI slower)
## player_economy:  multiplier on player prize money and income bonuses
## player_rnd:      multiplier on research points gained per session
func get_difficulty_mult() -> Dictionary:
	match game_difficulty:
		"Rookie":    return {"ai_performance": 0.75, "player_economy": 1.30, "player_rnd": 0.80}
		"Amateur":   return {"ai_performance": 0.85, "player_economy": 1.15, "player_rnd": 0.90}
		"Expert":    return {"ai_performance": 1.15, "player_economy": 0.90, "player_rnd": 1.10}
		"Master":    return {"ai_performance": 1.25, "player_economy": 0.80, "player_rnd": 1.20}
		_:           return {"ai_performance": 1.00, "player_economy": 1.00, "player_rnd": 1.00}

## ── P32 History recording ─────────────────────────────────────────────────────
func _record_weekly_history() -> void:
	var merch_income = 0
	var merch_b = campus_buildings.get("Merchandise Store", {})
	if merch_b.get("built", false):
		merch_income = get_building_income(merch_b)

	var entry = {"week": current_week, "season": current_season}
	history_balance.append(    entry.merged({"value": player_team.balance}))
	history_fuel_price.append( entry.merged({"value": current_fuel_price}))
	history_economy.append(    entry.merged({"value": economy_index}))
	history_active_fans.append(entry.merged({"value": get_team_active_fans()}))
	history_merchandise.append(entry.merged({"value": float(merch_income)}))
	history_reputation.append( entry.merged({"value": player_team.reputation}))

	## Cap all arrays at HISTORY_MAX_ENTRIES
	for arr in [history_balance, history_fuel_price, history_economy,
			history_active_fans, history_merchandise, history_reputation]:
		while arr.size() > HISTORY_MAX_ENTRIES:
			arr.remove_at(0)

## Base global fans per discipline at top tier (tier 4), based on real-world data.
const BASE_GLOBAL_FANS: Dictionary = {
	"GP":    750000000,
	"EPC":   150000000,
	"Rally": 200000000,
	"SC":     85000000,
	"OWC":    28000000,
	"TC":     18000000,
	"GK":      6000000,
}

## Tier multipliers: tier 1=entry, tier 4=top
const TIER_FAN_MULT: Dictionary = {1: 0.008, 2: 0.04, 3: 0.18, 4: 1.0}

## Returns current global fan count for a given discipline and tier.
func get_global_fans(discipline: String, tier: int) -> float:
	var base = float(BASE_GLOBAL_FANS.get(discipline, 6000000))
	var tier_mult = TIER_FAN_MULT.get(tier, 0.008)

	## Competition factor from championship winner history
	var competition_factor = 1.0
	for champ in active_championships:
		var reg = CHAMPIONSHIP_REGISTRY.get(champ.id, {})
		if reg.get("discipline","") == discipline and reg.get("tier", 1) == tier:
			competition_factor = champ.get_competition_factor()
			break

	## Star power — average reputation of top 3 drivers in this discipline
	var driver_reps: Array = []
	for did in all_drivers:
		var d = all_drivers[did]
		if d.active_discipline == discipline:
			driver_reps.append(d.marketability)
	driver_reps.sort()
	driver_reps.reverse()
	var top3_avg = 0.0
	for i in range(min(3, driver_reps.size())):
		top3_avg += driver_reps[i]
	if driver_reps.size() > 0:
		top3_avg /= float(min(3, driver_reps.size()))
	var star_power_factor = 0.7 + (top3_avg / 100.0) * 0.6

	## Economy factor — derived from continuous index
	var economy_factor = 0.9 + (economy_index / 100.0) * 0.2  ## 0.9 at recession, 1.1 at boom

	## Long-term organic growth via natural log curve
	var long_term = 1.0 + log(1.0 + float(current_season) * 0.05)

	return base * tier_mult * competition_factor * star_power_factor * economy_factor * long_term

## Returns the player's combined GLOBAL fan pool across the championships they are
## ACTUALLY registered in this season. (Bug #14/#2 fix — was scanning active_championships,
## i.e. the whole 21-championship world, so a brand-new GK team was scored at the world's
## top tier → absurd ~891k fans. Now reads player_registered_championships only.)
## "More championships = more publicity" → contributions are SUMMED across the player's entries.
## NOTE (flagged for GDD): the richer within-discipline pyramid / unique-slice model and the
## horizontal (cross-discipline) news bleed are a SEPARATE design pass, not implemented here.
func _player_global_fan_pool() -> float:
	var pool := 0.0
	for cid in player_registered_championships:
		var reg = CHAMPIONSHIP_REGISTRY.get(cid, {})
		if reg.is_empty(): continue
		var disc = reg.get("discipline", "GK")
		var tier = reg.get("tier", 1)
		pool += get_global_fans(disc, tier)
	return pool

## Returns team active fans.
## team_active_fans = global_fan_pool x (reputation/100)^2 x 0.15
func get_team_active_fans() -> float:
	if player_registered_championships.is_empty(): return 0.0
	var global_fans = _player_global_fan_pool()
	var rep_ratio = player_team.reputation / 100.0
	return global_fans * rep_ratio * rep_ratio * 0.15

## Returns team marketability (0-100) — derived, never stored.
func get_team_marketability() -> float:
	var rep_component = player_team.reputation * 0.6
	## Fan share component (Bug #14/#2 fix — was scanning active_championships, the whole
	## world; now uses the player's REGISTERED fan pool, consistent with get_team_active_fans).
	var fan_share_component = 0.0
	if not player_registered_championships.is_empty():
		var global_fans = _player_global_fan_pool()
		var active_fans = get_team_active_fans()
		if global_fans > 0:
			fan_share_component = clamp((active_fans / global_fans) * 40.0, 0.0, 20.0)
	## Building bonuses
	var building_bonus = 0.0
	for bname in ["Museum", "Theme Park", "Merchandise Store", "Public Racing Club"]:
		var b = campus_buildings.get(bname, {})
		if b.get("built", false):
			building_bonus += b.get("level", 1) * 0.5
	building_bonus = clamp(building_bonus, 0.0, 15.0)
	## Sponsor bonus
	var sponsor_bonus = clamp(float(active_sponsors.size()) * 2.0, 0.0, 10.0)
	## P4 R&D marketability boosts
	var rnd_mktg = get_rnd_bonus("marketability_boost") * 100.0
	## Legacy bonuses from departed star drivers
	var legacy_total = 0.0
	for lb in reputation_legacy_bonuses:
		legacy_total += lb.get("bonus", 0.0)
	return clamp(rep_component + fan_share_component + building_bonus + sponsor_bonus + rnd_mktg + legacy_total, 0.0, 100.0)

## ── Reputation Inertia ────────────────────────────────────────────────────────

## Apply reputation inertia at season end: reputation moves toward earned value slowly.
func _apply_reputation_inertia() -> void:
	## Soft pull from signed drivers avg reputation
	var driver_rep_sum = 0.0
	var driver_count = 0
	for did in player_team.drivers:
		var d = all_drivers.get(did)
		if d:
			driver_rep_sum += d.marketability
			driver_count += 1
	var avg_driver_rep = (driver_rep_sum / float(driver_count)) if driver_count > 0 else 0.0
	target_reputation = clamp(player_team.reputation * 0.8 + avg_driver_rep * 0.3 * 0.2, 0.0, 100.0)
	var diff = target_reputation - player_team.reputation
	var inertia = 0.25 if diff > 0 else 0.15
	player_team.reputation = clamp(player_team.reputation + diff * inertia, 0.0, 100.0)
	## Decay legacy bonuses by one season
	var kept: Array = []
	for lb in reputation_legacy_bonuses:
		lb["seasons_remaining"] -= 1
		if lb["seasons_remaining"] > 0:
			kept.append(lb)
	reputation_legacy_bonuses = kept

## Called when a star driver (rep > 70) leaves. Their fame props up marketability for 3 seasons.
func apply_departure_legacy(driver: Driver) -> void:
	var bonus = max(0.0, (driver.marketability - 50.0) * 0.1)
	if bonus > 0.0:
		reputation_legacy_bonuses.append({
			"seasons_remaining": 3,
			"bonus": bonus,
			"driver_name": driver.full_name()
		})

## ── Championship Win Awards ───────────────────────────────────────────────────

## Award drivers championship at season end.
func _award_drivers_championship(driver_id: String, champ: Championship) -> void:
	var driver = all_drivers.get(driver_id)
	if driver == null: return
	var reg = CHAMPIONSHIP_REGISTRY.get(champ.id, {})
	var tier = reg.get("tier", 1)
	var driver_rep_boost = 5.0 + tier * 2.5
	driver.marketability = clamp(driver.marketability + driver_rep_boost, 0.0, 100.0)
	add_log("🏆 %s wins Drivers Championship! +%.0f reputation." % [driver.full_name(), driver_rep_boost])
	if driver.contract_team == player_team.id:
		var team_boost = 3.0 + float(tier) * 1.0
		player_team.reputation = clamp(player_team.reputation + team_boost, 0.0, 100.0)
		add_notification("High",
			"🏆 %s wins Drivers Championship! Team +%.0f reputation." % [driver.full_name(), team_boost], "hq")
	champ.drivers_champion_history.append({
		"season": current_season, "driver_id": driver_id, "driver_name": driver.full_name()})
	if champ.drivers_champion_history.size() > 5:
		champ.drivers_champion_history = champ.drivers_champion_history.slice(
			champ.drivers_champion_history.size() - 5)

## Award teams/constructors championship at season end.
func _award_teams_championship(team_id: String, champ: Championship) -> void:
	var reg = CHAMPIONSHIP_REGISTRY.get(champ.id, {})
	var tier = reg.get("tier", 1)
	var team_boost = 5.0 + float(tier) * 1.5
	var champ_team_name = "Unknown"
	for t in all_teams:
		if t.id == team_id: champ_team_name = t.team_name; break
	if team_id == player_team.id:
		player_team.reputation = clamp(player_team.reputation + team_boost, 0.0, 100.0)
		add_notification("High",
			"🏆 Constructors Championship won! Team +%.0f reputation." % team_boost, "hq")
	add_log("🏆 %s wins Constructors Championship." % champ_team_name)
	champ.teams_champion_history.append({
		"season": current_season, "team_id": team_id, "team_name": champ_team_name})
	if champ.teams_champion_history.size() > 5:
		champ.teams_champion_history = champ.teams_champion_history.slice(
			champ.teams_champion_history.size() - 5)


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
var player_registered_championships: Array = [] # IDs the player RACES this season (current). Activated from the ledger at season transition.
## NextSeasonLedger (S28.1, GDD §23.1): IDs the player has registered + paid for NEXT season.
## Populated by register_for_championship() during the current season. At start_new_season()
## this is copied into player_registered_championships, then cleared. NEVER raced from directly.
var next_season_registrations: Array = []

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
## Last generated TP assignment proposals — displayed in Racing Department
var _last_tp_proposals: Array = []
## Queue for multiple same-week races — each entry is a snapshot dict of all last_race_* vars
var _pending_race_results: Array = []

## Maps driver_id / staff_id → championship_id they ran in last season
## Used to show "Prev: GK Championship" badge in Drivers/Staff screens
var previous_season_championship: Dictionary = {}

# Hall of fame
var hall_of_fame: Array = []
## Retirement archive (S28) — drivers/staff who retired by age. Used by
## History (§19) and News (§13). Entries: {season,name,kind,role,age,was_player}.
var retired_personnel: Array = []

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
## S28.3 (issue 2 / GDD §23.3): WRA approval shortened by 1 week across tiers.
## Was {1:2,2:3,3:5,4:6}. Tier 1 (GK) now approves in 1 week as expected.
const WRA_APPROVAL_WEEKS: Dictionary = { 1:1, 2:2, 3:4, 4:5 }
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
## Continuous economy index 0-100 (0=deep recession, 50=normal, 100=boom)
## State label derived: 0-30=Recession, 30-70=Normal, 70-100=Boom
var economy_index:          float  = 50.0
var current_fuel_price:     float  = 1200.0
var current_loan_rate:      float  = 5.0    ## % interest rate for loans (follows economy)

## S35.3 — Living fuel pricing. The per-kg cost = BASE × Fuel_Price_Multiplier, where the
## multiplier is economy-driven within the range the variables sheet defines
## (Global Variables → Fuel_Price_Multiplier: default 1.0, min 0.5, max 3.0). BASE keeps the
## original CR 2/kg scale so existing balance holds at a normal economy (index 50 → ×1.0).
const BASE_FUEL_COST_PER_KG: float = 2.0
const FUEL_PRICE_MULT_MIN: float = 0.5
const FUEL_PRICE_MULT_MAX: float = 3.0

## S35.5 — Living spare-parts pricing. SP is a manufactured industrial consumable, NOT a volatile
## traded commodity like fuel — so it tracks the global economy cycle CLOSELY in a TIGHT band
## (mirrors the variables sheet's Parts_Sale_Price_Multiplier range 0.6–1.5, the manufactured-goods
## family) and carries only a GENTLE supply/demand "market pressure" wobble on top — far milder
## than fuel's ±2% weekly / 3% shock volatility. Per-unit cost = BASE × economy_mult × market_mult.
## BASE keeps the original CR 1/unit so existing balance holds at a normal economy (index 50 → ×1.0).
const BASE_SP_COST_PER_UNIT: float = 1.0
const SP_PRICE_MULT_MIN: float = 0.6   ## tight manufactured-goods band (cf. Parts_Sale_Price_Multiplier)
const SP_PRICE_MULT_MAX: float = 1.5
## Market-pressure bounds — a small multiplicative wobble around the economy anchor (±15% max),
## so the economy term stays dominant. Mean-reverts toward 1.0; rare, mild shocks.
const SP_MARKET_PRESSURE_MIN: float = 0.85
const SP_MARKET_PRESSURE_MAX: float = 1.15
## Current SP market-pressure factor (the slow supply/demand drift). Persisted in save.
var sp_market_pressure: float = 1.0

## S35.3 — set true only while the player is fast-forwarding to season end (Skip to End of
## Season). The CFO auto-buy fires ONLY in this mode: during hands-on weekly play the player
## manages SP/FU themselves; when they opt out by skipping, the CFO keeps the cars race-ready.
var simulating_to_season_end: bool = false

## Economy fluctuation internals
var _economy_momentum:      float  = 0.0   ## carries weekly drift direction

## Derived read-only property: economy state label from economy_index
var global_economy_state: String:
	get:
		if economy_index < 30.0: return "Recession"
		if economy_index > 70.0: return "Boom"
		return "Normal"

## P44 Active loans — Array of Dicts:
## {id, amount_original, balance_remaining, weekly_payment, annual_rate,
##  seasons_duration, weeks_remaining, taken_season, taken_week, cfo_name}
var active_loans: Array = []
var _loan_next_id: int = 1

## ── Economy & Fuel Fluctuation (S21 redesign) ────────────────────────────────
##
## Economy: continuous economy_index 0-100, drifts ±0.3-1.5/week with momentum.
## Full Recession→Boom cycle takes ~150-250 weeks (3-5 seasons). Mean-reverts to 50.
## State label (global_economy_state) is derived from the index (no longer stored).
##
## Fuel: base = 800 + economy_index × 8 (range 800-1600 normally).
## Weekly move ±1-2% normally, ±5% shock at 3% chance. Hard cap 600-2000 CR.
func _update_economy_and_fuel() -> void:
	## ── Economy index drift ───────────────────────────────────────────────────
	var prev_state = global_economy_state  ## read derived property before update

	## Mean-reversion pull toward 50 — stronger when further away
	var mean_pull = (50.0 - economy_index) * 0.008

	## Random weekly drift ±0.5 with occasional shock week (2% chance) ±3-5
	var drift = randf_range(-0.5, 0.5)
	if randf() < 0.02:
		drift = randf_range(-5.0, 5.0)   ## shock week

	## Momentum carries direction (smooths out jitter)
	_economy_momentum = _economy_momentum * 0.85 + drift * 0.15
	economy_index = clamp(economy_index + mean_pull + _economy_momentum, 0.0, 100.0)
	current_loan_rate = clamp(4.0 + (economy_index / 100.0) * 8.0, 1.0, 12.0)
	current_loan_rate = round(current_loan_rate * 10.0) / 10.0

	## Notify on state change — S35.3: CFO-gated. Economy intelligence is what the player pays
	## the CFO for (GDD §9-E: `speculation` = economy_index predictions). No CFO → the economy
	## still moves (index/prices update below regardless), the player just gets no heads-up.
	var new_state = global_economy_state
	if new_state != prev_state and get_cfo() != null:
		add_notification("Normal", "📊 Economy shifted to %s (index %.0f)." % [new_state, economy_index],
			"", "economy_state")

	## ── Fuel price ───────────────────────────────────────────────────────────
	## Smooth base derived from economy_index
	var base_fuel = 800.0 + economy_index * 8.0  ## range 800-1600

	## Mean-reversion pull toward base
	var fuel_mean_pull = (base_fuel - current_fuel_price) * 0.06

	## Normal weekly move ±1-2%
	var fuel_move = current_fuel_price * randf_range(-0.02, 0.02)

	## Shock week: ±5% (3% chance). S35.3: the price ALWAYS moves; the notification is CFO-gated
	## (no CFO → no alert, but the price shock still applies below).
	if randf() < 0.03:
		fuel_move += current_fuel_price * randf_range(-0.05, 0.05)
		if get_cfo() != null:
			add_notification("Normal", "⛽ Fuel price fluctuation — global supply shift.",
				"", "economy_fuel_shock")

	current_fuel_price = clamp(
		current_fuel_price + fuel_mean_pull + fuel_move,
		600.0, 2000.0)
	current_fuel_price = round(current_fuel_price / 10.0) * 10.0

## ── S35.3 Living fuel price ───────────────────────────────────────────────────
## Fuel_Price_Multiplier (Global Variables sheet): economy-driven, default 1.0, range 0.5–3.0.
## Mapped linearly from economy_index (0–100, neutral 50). At index 50 → ×1.0 (current balance
## preserved); recession (low index) → cheaper toward ×0.5; boom (high index) → pricier toward
## ×3.0. This is the single source of the living price used by buy_fuel and the CFO auto-buy.
func get_fuel_price_multiplier() -> float:
	## index 50 is neutral. Below 50 scales down toward MIN, above 50 scales up toward MAX.
	var mult: float
	if economy_index <= 50.0:
		mult = lerp(FUEL_PRICE_MULT_MIN, 1.0, economy_index / 50.0)
	else:
		mult = lerp(1.0, FUEL_PRICE_MULT_MAX, (economy_index - 50.0) / 50.0)
	return clamp(mult, FUEL_PRICE_MULT_MIN, FUEL_PRICE_MULT_MAX)

## The live per-kg fuel cost the player actually pays (base × economy multiplier).
func get_fuel_cost_per_kg() -> float:
	return BASE_FUEL_COST_PER_KG * get_fuel_price_multiplier()

## ── S35.5 Living spare-parts price ────────────────────────────────────────────
## SP economy multiplier: TIGHT manufactured-goods band (0.6–1.5), economy-DOMINANT. Maps from
## economy_index (neutral 50 → ×1.0); recession → cheaper toward 0.6, boom → pricier toward 1.5.
## Deliberately a much tighter swing than fuel (0.5–3.0): spare parts are industrial goods, not a
## speculative commodity.
func get_sp_price_multiplier() -> float:
	var mult: float
	if economy_index <= 50.0:
		mult = lerp(SP_PRICE_MULT_MIN, 1.0, economy_index / 50.0)
	else:
		mult = lerp(1.0, SP_PRICE_MULT_MAX, (economy_index - 50.0) / 50.0)
	return clamp(mult, SP_PRICE_MULT_MIN, SP_PRICE_MULT_MAX)

## The live per-unit SP cost the player actually pays:
##   BASE × economy_multiplier × market_pressure
## The economy term sets the cycle level; market_pressure is the gentle supply/demand wobble
## (mean-reverting, ±15% bound) updated weekly in _update_sp_market_pressure(). Rounded to 2 dp.
func get_sp_cost_per_unit() -> float:
	var raw: float = BASE_SP_COST_PER_UNIT * get_sp_price_multiplier() * sp_market_pressure
	return max(0.1, round(raw * 100.0) / 100.0)   ## never free; 2-dp display-friendly

## Weekly gentle market-pressure drift for SP — the "supply & demand" feel WITHOUT a real
## consumption model. Mean-reverts toward 1.0, small weekly move, rare mild shock. Far calmer
## than fuel by design (SP is more bound to the economy cycle than to speculative swings).
func _update_sp_market_pressure() -> void:
	## Mean-reversion pull back toward neutral 1.0 (keeps the economy term dominant over time).
	var pull: float = (1.0 - sp_market_pressure) * 0.10
	## Normal weekly wobble ±0.8% (vs fuel's ±2%).
	var move: float = randf_range(-0.008, 0.008)
	## Rare mild shock, cadence from the sheet (Random_Economic_Event_Chance_Per_Week ≈ 0.04),
	## magnitude ±3% (vs fuel's ±5%) — a "parts shortage / surplus" blip.
	if randf() < 0.04:
		move += randf_range(-0.03, 0.03)
	sp_market_pressure = clamp(sp_market_pressure + pull + move,
		SP_MARKET_PRESSURE_MIN, SP_MARKET_PRESSURE_MAX)

## ── P32 Weekly History recording ──────────────────────────────────────────────
## Each entry: {week, season, value}. Capped at 52×5 = 260 entries (5 seasons).
var history_balance:      Array = []  ## player_team.balance
var history_fuel_price:   Array = []  ## current_fuel_price
var history_economy:      Array = []  ## economy_index (0-100 continuous float)
var history_active_fans:  Array = []  ## get_team_active_fans()
var history_merchandise:  Array = []  ## merchandise store income that week
var history_reputation:   Array = []  ## player_team.reputation
const HISTORY_MAX_ENTRIES: int = 260  ## 5 seasons × 52 weeks
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
## AI Team Manager — instantiated in _ready(), owns all AI generation logic
var ai_manager: RefCounted = null

## AI team cars keyed by championship_id → Array of Car objects
var ai_cars: Dictionary = {}

# Staff pool — all staff in the game world (hired + available)
var all_staff: Dictionary = {}    # staff_id → Staff

## S35.6 — Player-staff cache (perf). all_staff holds ~5000+ entries; HQ/StaffHub/Drivers used to
## scan ALL of them (sometimes in nested loops) to find the player's handful, causing scene lag.
## This cache holds ONLY the player's staff, keyed by role, rebuilt whenever the roster changes
## (hire/release/sign-activation/load/rollover) via _rebuild_player_staff_cache(). Accessors read
## from it instead of scanning all_staff. Kept a Dictionary{role:Array} + a flat list.
var _player_staff_by_role: Dictionary = {}   # role(String) → Array[Staff]
var _player_staff_flat: Array = []           # all player staff, any role
var _player_staff_cache_dirty: bool = true   # rebuild on next read if true

# Part inventory — stock of major car parts
# Keyed by championship_id then part name
# e.g. part_inventory["C-001"]["Aero"] = 3
var part_inventory: Dictionary = {}

# Part costs per championship (from CNC sheet — buy price per unit)
const PART_COSTS = {
	## GK series — small, inexpensive kart parts
	"C-001": {"Engine": 0, "Aero": 0, "Brakes": 0, "Suspension": 0, "Chassis": 0, "Gearbox": 0},  ## GK: spec parts, cost is per-race spares only
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
	"C-001": {"design_weeks": 2, "engine_weeks": 1, "base_total_cost": 6500, "sale_multiplier": 1.5},
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
	"C-001": 6,
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
	"C-001":"GK",
	"C-005":"RL4","C-006":"RL3","C-007":"RL2","C-008":"RLP",
	"C-009":"TCS","C-010":"TCE",
	"C-011":"OWN","C-012":"OWD","C-013":"OWP",
	"C-014":"SCD","C-015":"SCT","C-016":"SCC","C-017":"SCU",
	"C-018":"EPS","C-019":"EPL","C-020":"EPH",
	"C-021":"GP4","C-022":"GP3","C-023":"GP2","C-024":"GP1",
}

## S35.13 — Championships grouped for the 2D tab GRID: an ordered list of disciplines (by the
## same principle as championship_tab_order — top-tier rep descending, GP…GK) where each entry
## is { "discipline": String, "champ_ids": Array }, and champ_ids run pinnacle → entry (rep desc).
## The UI renders one ROW per discipline, tiers across the row.
func championship_tab_grid() -> Array:
	var ordered = championship_tab_order()   ## flat GP1…GK
	var rows: Array = []
	var index: Dictionary = {}   ## discipline → row index in `rows`
	for cid in ordered:
		var disc = CHAMPIONSHIP_REGISTRY.get(cid, {}).get("discipline", "")
		if not disc in index:
			index[disc] = rows.size()
			rows.append({"discipline": disc, "champ_ids": []})
		rows[index[disc]]["champ_ids"].append(cid)
	return rows


## registry (single source of truth): disciplines ranked by their TOP-TIER reputation
## (= max rep across the discipline) descending; within a discipline, tiers run pinnacle →
## entry (rep descending). With the current registry this yields GP1,GP2,GP3,GP4, EPC…, OWC…,
## SC…, TC…, Rally…, GK. The order is stable because the registry rep values are constants.
func championship_tab_order() -> Array:
	## Best (max) rep per discipline.
	var disc_best: Dictionary = {}
	for cid in CHAMPIONSHIP_REGISTRY:
		var reg = CHAMPIONSHIP_REGISTRY[cid]
		var disc = reg.get("discipline", "")
		var rep = int(reg.get("rep", 0))
		if not disc in disc_best or rep > disc_best[disc]:
			disc_best[disc] = rep
	var ids = CHAMPIONSHIP_REGISTRY.keys()
	ids.sort_custom(func(a, b):
		var ra = CHAMPIONSHIP_REGISTRY[a]
		var rb = CHAMPIONSHIP_REGISTRY[b]
		var da = ra.get("discipline", "")
		var db = rb.get("discipline", "")
		if da != db:
			## Different disciplines → order by discipline's top-tier rep (desc).
			return disc_best.get(da, 0) > disc_best.get(db, 0)
		## Same discipline → pinnacle first (higher rep / higher tier first).
		return int(ra.get("rep", 0)) > int(rb.get("rep", 0))
	)
	return ids


## Full championship registry — from Excel Championships sheet.
## entry_fee: one-time registration fee (not per race)
## entry_fee_per_race is the old field — kept for race prize calculations only
const CHAMPIONSHIP_REGISTRY = {
	"C-001": {
		"name":"GK Championship", "discipline":"GK", "tier":1,
		"min_age":8, "max_age":17, "max_cars":9, "min_cars":1,
		"entry_fee":10000, "num_races":22, "rep":15,
		"car_type_id":"A_01",
		"drivers_per_car":1,
		"min_participation":352, "optimum_participation":640,
		"spec_aero":true, "spec_engine":true, "spec_gearbox":true,
		"spec_suspension":false, "spec_brakes":false, "spec_chassis":true,
		"has_playoffs":false, "has_mandatory_pit":false,
		"has_driver_changes":false, "has_stages":false,
		"prize_1st":1200, "prize_2nd":600, "prize_3rd":300,
		"end_season_prize_1st":20000, "end_season_prize_2nd":10000,
		"end_season_prize_3rd":5000, "end_season_prize_4th":2500,
		"end_season_prize_5th":1250, "end_season_prize_6th":1000,
		"end_season_prize_7th":800, "end_season_prize_8th":750,
		"end_season_prize_9th":650, "end_season_prize_10th":500,
		"fuel_per_weekend":20, "spares_per_race":200,
		"spares_per_10pct_damage":100,
		"base_driver_salary":300, "base_mechanic_salary":420,
		"base_tp_salary":580,
		"yellow_flag":true, "full_yellow":true, "safety_car":false, "vsc":false,
		"max_overtake_gap":2.1,
		"practice":"15 min free practice",
		"qualifying":"8 min one-shot",
		"race_format":"Sprint - Standing Start",
		"avg_audience":2200,
		"base_service_time":0,
	},
	"C-005": {"name":"RALLY4",                      "discipline":"Rally", "tier":1, "min_age":16, "max_age":99, "entry_fee":30000,    "num_races":5,  "rep":36},
	"C-006": {"name":"RALLY3",                      "discipline":"Rally", "tier":2, "min_age":16, "max_age":99, "entry_fee":140000,   "num_races":7,  "rep":42},
	"C-007": {"name":"RALLY2",                      "discipline":"Rally", "tier":3, "min_age":16, "max_age":99, "entry_fee":700000,   "num_races":14, "rep":52},
	"C-008": {"name":"Premier Rally Championship",  "discipline":"Rally", "tier":4, "min_age":18, "max_age":99, "entry_fee":1680000,  "num_races":14, "rep":79},
	"C-009": {"name":"TC Sport Series",             "discipline":"TC",    "tier":2, "min_age":16, "max_age":99, "entry_fee":162000,   "num_races":6,  "rep":58},
	"C-010": {"name":"TC Elite Championship",       "discipline":"TC",    "tier":3, "min_age":17, "max_age":99, "entry_fee":375000,   "num_races":6,  "rep":82},
	"C-011": {"name":"OWC Next Gen",                "discipline":"OWC",   "tier":2, "min_age":15, "max_age":99, "entry_fee":115200,   "num_races":8,  "rep":49},
	"C-012": {"name":"OWC Development Series",      "discipline":"OWC",   "tier":3, "min_age":16, "max_age":99, "entry_fee":1078000,  "num_races":14, "rep":65},
	"C-013": {"name":"OWC Pro Series",              "discipline":"OWC",   "tier":4, "min_age":17, "max_age":99, "entry_fee":6800000,  "num_races":17, "rep":91},
	"C-014": {"name":"SC Dev Series",               "discipline":"SC",    "tier":1, "min_age":15, "max_age":99, "entry_fee":600000,   "num_races":20, "rep":46, "max_cars":4, "min_cars":1},
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

## Per-championship logistics needs — sourced from the Master Championship Variables Map
## ("Championships" sheet). Replaces the old hardcoded uniform 15 kg / 100 SP that made every
## championship look identical (Bug — see Logistics screenshot S36.x).
##   fuel = "Fuel per Weekend" (kg per car, covers the whole race weekend incl. practice/quali).
##   sp   = "Spares_per_Race" + 10% damage buffer (rounded), stored as sp_per_10_pct_damage.
const CHAMP_LOGISTICS = {
	"C-001": {"fuel": 20.0,  "sp": 110},    ## GK
	"C-005": {"fuel": 85.0,  "sp": 418},    ## RALLY4
	"C-006": {"fuel": 110.0, "sp": 495},    ## RALLY3
	"C-007": {"fuel": 135.0, "sp": 638},    ## RALLY2
	"C-008": {"fuel": 160.0, "sp": 935},    ## Premier Rally
	"C-009": {"fuel": 210.0, "sp": 715},    ## TC Sport
	"C-010": {"fuel": 240.0, "sp": 1012},   ## TC Elite
	"C-011": {"fuel": 260.0, "sp": 572},    ## OWC Next Gen
	"C-012": {"fuel": 290.0, "sp": 748},    ## OWC Development
	"C-013": {"fuel": 340.0, "sp": 1375},   ## OWC Pro
	"C-014": {"fuel": 360.0, "sp": 572},    ## SC Dev
	"C-015": {"fuel": 390.0, "sp": 792},    ## SC Truck
	"C-016": {"fuel": 410.0, "sp": 1012},   ## SC Challenge
	"C-017": {"fuel": 420.0, "sp": 1375},   ## SC Cup
	"C-018": {"fuel": 480.0, "sp": 638},    ## EPC Series
	"C-019": {"fuel": 520.0, "sp": 858},    ## EPC League
	"C-020": {"fuel": 580.0, "sp": 1375},   ## EPC Hyper
	"C-021": {"fuel": 180.0, "sp": 418},    ## GP4
	"C-022": {"fuel": 240.0, "sp": 638},    ## GP3
	"C-023": {"fuel": 280.0, "sp": 858},    ## GP2
	"C-024": {"fuel": 320.0, "sp": 1815},   ## GP1
}

## Full race calendars for all 21 championships — from Brainstorming doc Race Calendar section.
## Rally (C-005 to C-008): "laps" = total race distance km (staged rally format).
## Endurance (C-018 to C-020 / EPC): "laps" = hours of racing.
## All others: "laps" = number of racing laps, "lap_km" = km per lap.
## Converts a track name to a stable lowercase slug used as track_id.
## "Super Karting Raceway" → "super_karting_raceway"
static func track_slug(name: String) -> String:
	return name.to_lower().replace(" ", "_").replace("-", "_").replace("'", "").replace(",", "")

const CHAMPIONSHIP_CALENDARS = {
	"C-001": [ ## GK Championship — 22 races (8/7/5/2). Final weekend = 2 races SAME week (46):
		## Semi-Final (top 10 per group → 20 advance) then Grand Final (race winner = champion).
		{"round":1,"gk_round":1,"name":"Chemnitz","track_id":"chemnitz","week":6,"rain":15,"laps":15,"lap_km":4.2,"audience":8900},
		{"round":2,"gk_round":1,"name":"Le Castellet","track_id":"le_castellet","week":8,"rain":0,"laps":27,"lap_km":5.8,"audience":6500},
		{"round":3,"gk_round":1,"name":"Le Mans","track_id":"le_mans","week":10,"rain":25,"laps":26,"lap_km":13.6,"audience":14500},
		{"round":4,"gk_round":1,"name":"Spa","track_id":"spa","week":12,"rain":20,"laps":25,"lap_km":7.0,"audience":7200},
		{"round":5,"gk_round":1,"name":"Arlington","track_id":"arlington","week":14,"rain":0,"laps":20,"lap_km":0.9,"audience":2100},
		{"round":6,"gk_round":1,"name":"Charlotte","track_id":"charlotte","week":16,"rain":10,"laps":24,"lap_km":1.2,"audience":4800},
		{"round":7,"gk_round":1,"name":"Charlotte","track_id":"charlotte","week":18,"rain":10,"laps":24,"lap_km":1.2,"audience":4800},
		{"round":8,"gk_round":1,"name":"Daytona","track_id":"daytona","week":20,"rain":5,"laps":20,"lap_km":1.5,"audience":8000},
		{"round":9,"gk_round":2,"name":"Indianapolis","track_id":"indianapolis","week":22,"rain":0,"laps":20,"lap_km":2.5,"audience":12000},
		{"round":10,"gk_round":2,"name":"Las Vegas","track_id":"las_vegas","week":24,"rain":5,"laps":20,"lap_km":1.8,"audience":6000},
		{"round":11,"gk_round":2,"name":"Los Angeles","track_id":"los_angeles","week":26,"rain":0,"laps":20,"lap_km":1.0,"audience":5000},
		{"round":12,"gk_round":2,"name":"Silverstone","track_id":"silverstone","week":28,"rain":30,"laps":25,"lap_km":5.9,"audience":9500},
		{"round":13,"gk_round":2,"name":"Arlington","track_id":"arlington","week":30,"rain":0,"laps":20,"lap_km":0.9,"audience":2100},
		{"round":14,"gk_round":2,"name":"Daytona","track_id":"daytona","week":32,"rain":5,"laps":20,"lap_km":1.5,"audience":8000},
		{"round":15,"gk_round":2,"name":"Indianapolis","track_id":"indianapolis","week":34,"rain":0,"laps":20,"lap_km":2.5,"audience":12000},
		{"round":16,"gk_round":3,"name":"Los Angeles","track_id":"los_angeles","week":36,"rain":0,"laps":20,"lap_km":1.0,"audience":5000},
		{"round":17,"gk_round":3,"name":"Miami","track_id":"miami","week":38,"rain":20,"laps":20,"lap_km":1.4,"audience":7000},
		{"round":18,"gk_round":3,"name":"Spielberg","track_id":"spielberg","week":40,"rain":10,"laps":24,"lap_km":4.3,"audience":8000},
		{"round":19,"gk_round":3,"name":"Charlotte","track_id":"charlotte","week":42,"rain":10,"laps":24,"lap_km":1.2,"audience":4800},
		{"round":20,"gk_round":3,"name":"Silverstone","track_id":"silverstone","week":44,"rain":30,"laps":25,"lap_km":5.9,"audience":9500},
		{"round":21,"gk_round":4,"is_semifinal":true,"name":"GK Semi-Final — Las Vegas","track_id":"las_vegas","week":46,"rain":5,"laps":20,"lap_km":1.8,"audience":6000},
		{"round":22,"gk_round":4,"is_final":true,"name":"GK Grand Final — Le Mans","track_id":"le_mans","week":46,"rain":25,"laps":26,"lap_km":13.6,"audience":14500},
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

## Entry/design deadline week in the prior season.
## Base = 52 - design_weeks (last week blueprints can still finish in-season).
## S28.1 (§23.3): shifted 1 week earlier to leave room for WRA approval of next-season regs.
func get_entry_deadline_week(champ_id: String) -> int:
	return 52 - CNC_DATA.get(champ_id, {}).get("design_weeks", 2) - 1

## Provider car cost scaled by season: base × 1.05^(season-1), rounded to CR 500.
func get_provider_car_cost(champ_id: String) -> int:
	var base   = CNC_DATA.get(champ_id, {}).get("base_total_cost", 10000)
	var scaled = base * pow(1.05, current_season - 1)
	return int(round(scaled / 500.0) * 500)
const CFO_PART_WARNING_THRESHOLD = 2  # CFO warns when any part stock ≤ this

# Notifications
var notifications: Array = []
var dismissed_todo_items: Array = []  ## Items player has dismissed from to-do list
var custom_todo_items:    Array = []  ## TP proposals and other injected TDL items
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
	## P57: Initialize all engines early — _ready() runs before setup_new_game/load_game
	_season_manager = SeasonManager.new(self)
	_financial_engine = FinancialEngine.new(self)
	_race_simulator = RaceSimulator.new(self)
	_contract_engine = ContractEngine.new(self)
	_rnd_engine = RnDEngine.new(self)
	_notification_manager = NotificationManager.new(self)
	_campus_manager = CampusManager.new(self)
	_sponsor_manager = SponsorManager.new(self)
	_staff_manager = StaffManager.new(self)
	_car_manager = CarManager.new(self)
	_driver_manager = DriverManager.new(self)
	_tp_engine = TPProposalEngine.new(self)
	_sponsor_manager = SponsorManager.new(self)
	_staff_manager = StaffManager.new(self)
	_car_manager = CarManager.new(self)
	_driver_manager = DriverManager.new(self)
	_tp_engine = TPProposalEngine.new(self)
	_sponsor_manager = SponsorManager.new(self)
	_staff_manager = StaffManager.new(self)
	_car_manager = CarManager.new(self)
	_driver_manager = DriverManager.new(self)
	_tp_engine = TPProposalEngine.new(self)
	RND_TASKS = _build_rnd_tasks()
	ai_manager = load("res://autoloads/AIManager.gd").new()

	## S35.8 — Warm the heavy HQ scene so its first open doesn't hitch. HQ.tscn + its large script
	## are loaded from disk on first navigation (Godot caches the PackedScene after). Touching the
	## preloaded constants below forces that load to happen ONCE during GameState init (the first
	## autoload, before any gameplay), so the first click into HQ finds it already cached — the
	## first-open freeze is gone. Plain preload constants (resolved at compile time) avoid any
	## threaded-request lifecycle to manage.
	_warm_heavy_scenes()

## S35.8 — reference the preloaded heavy scenes so Godot caches them up front.
const _HQ_SCENE: PackedScene = preload("res://scenes/buildings/HQ.tscn")
const _NEGOTIATION_SCENE: PackedScene = preload("res://scenes/ContractNegotiation.tscn")
func _warm_heavy_scenes() -> void:
	## Touching the constants is enough — preload already cached them at compile time. This keeps
	## a live reference so they stay resident, and gives HQ-open code a cached PackedScene to use.
	var _warm := [_HQ_SCENE, _NEGOTIATION_SCENE]

## ═══ R&D ENGINE — delegated to RnDEngine.gd (S27) ═══

func _build_rnd_tasks() -> Dictionary:
	return _rnd_engine._build_rnd_tasks()

func _rebuild_seasonal_rnd_tasks() -> void:
	_rnd_engine._rebuild_seasonal_rnd_tasks()

func _build_rnd_tasks_for_season(season: int) -> Dictionary:
	return _rnd_engine._build_rnd_tasks_for_season(season)

func _apply_wra_regulation_change() -> void:
	_rnd_engine._apply_wra_regulation_change()

func has_blueprint(part: String) -> bool:
	return _rnd_engine.has_blueprint(part)

func get_manufacturable_parts() -> Array:
	return _rnd_engine.get_manufacturable_parts()

func start_cnc_production(part: String, champ_id: String, quantity: int = 1) -> bool:
	return _rnd_engine.start_cnc_production(part, champ_id, quantity)

func _advance_cnc_production() -> void:
	_rnd_engine._advance_cnc_production()

## Phase 2 — weekly car delivery clock.
## Flips any in-build player car to delivered once the season week reaches its
## delivery_week. Runs each tick in advance_week() right after CNC production, before
## the race-check loop, so a car delivered on a race week is raceable that same week.
## Idempotent: only undelivered cars are touched; legacy/instant cars (delivered=true,
## delivery_week=0) are skipped.
func _process_car_deliveries() -> void:
	for car in player_team_cars:
		if car.delivered:
			continue
		if current_week >= car.delivery_week:
			car.delivered = true
			var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			var reg = CHAMPIONSHIP_REGISTRY.get(car.championship_id, {})
			var champ_name = reg.get("name", car.championship_id)
			add_notification("Normal",
				"🏎 %s delivered — ready to race in %s. Assign crew in the Garage." % [
				car_label, champ_name], "garage")
			add_log("🏎 %s delivered (Week %d) for %s." % [car_label, current_week, champ_name])

# ── Build Whole Car (Phase 2) ─────────────────────────────────────────────────
## Maps each of the 6 car parts to the WRA-approved blueprint_id for a championship.
## Returns { part_name: blueprint_id } containing only parts that HAVE an approved
## blueprint in CNC for that championship.
func _approved_car_blueprints(champ_id: String) -> Dictionary:
	var result: Dictionary = {}
	for app in wra_approved_blueprints:
		if app.get("championship_id", "") != champ_id:
			continue
		var bp_id = app.get("blueprint_id", "")
		var bp = known_blueprints.get(bp_id, {})
		## S35.12 — CNC builds the CURRENT season only (model b). A next-season blueprint
		## (season > current) is NOT eligible to build a car until that season becomes current.
		if int(bp.get("season", current_season)) > current_season:
			continue
		var part = bp.get("part", "")
		if part in PARTS_LIST and not result.has(part):
			result[part] = bp_id
	return result

## Parts still missing an approved blueprint for this championship (for UI hinting).
func missing_car_blueprints(champ_id: String) -> Array:
	var approved = _approved_car_blueprints(champ_id)
	var missing: Array = []
	for part in PARTS_LIST:
		if not approved.has(part):
			missing.append(part)
	return missing

## True only if ALL 6 part blueprints for champ_id are WRA-approved & in CNC.
func can_build_whole_car(champ_id: String) -> bool:
	return _approved_car_blueprints(champ_id).size() == PARTS_LIST.size()

## Slot-aware completion offset (weeks from now) for a set of job durations, given
## the number of parallel CNC slots. List-scheduling: each freed slot takes the next
## job; the answer is the latest slot-end. With slots >= jobs this is max(weeks).
func _slot_aware_completion(weeks_list: Array, slots: int) -> int:
	if weeks_list.is_empty():
		return 0
	var s = max(1, slots)
	var slot_ends: Array = []
	for _i in range(s):
		slot_ends.append(0)
	# Longest-first improves packing realism and matches a busy plant's behaviour.
	var sorted_weeks = weeks_list.duplicate()
	sorted_weeks.sort()
	sorted_weeks.reverse()
	for w in sorted_weeks:
		# assign to the earliest-free slot
		var min_idx = 0
		for i in range(slot_ends.size()):
			if slot_ends[i] < slot_ends[min_idx]:
				min_idx = i
		slot_ends[min_idx] += w
	var latest = 0
	for e in slot_ends:
		latest = max(latest, e)
	return latest

## Total CR to manufacture all 6 parts once (base, no extra investment).
func get_build_whole_car_cost(champ_id: String) -> int:
	var approved = _approved_car_blueprints(champ_id)
	var total = 0
	for part in approved:
		total += get_cnc_manufacturing_cr(approved[part], 1)
	return total

## Projected delivery week if the whole car is built now (current_week + slot-aware
## completion of the 6 base jobs). Returns 0 if not buildable.
func get_build_whole_car_delivery_week(champ_id: String) -> int:
	var approved = _approved_car_blueprints(champ_id)
	if approved.size() != PARTS_LIST.size():
		return 0
	var weeks_list: Array = []
	for part in approved:
		weeks_list.append(get_cnc_manufacturing_weeks(approved[part]))
	return current_week + _slot_aware_completion(weeks_list, get_cnc_slots())

## One-pass car build. Creates the in-build Car (acquisition="built"), queues all 6
## CNC jobs, sets the slot-aware delivery week, and fires assignment + TP proposals
## (via add_car). Build/buy is independent of assignments — this only OFFERS them.
func build_whole_car(champ_id: String) -> bool:
	if not can_build_whole_car(champ_id):
		var miss = missing_car_blueprints(champ_id)
		add_notification("High",
			"Cannot build car yet — missing approved blueprints: %s." % ", ".join(miss), "cnc_plant")
		return false
	if player_team_cars.size() >= get_max_cars():
		add_notification("High",
			"Garage full (%d/%d). Upgrade the Garage to build more cars." % [
			player_team_cars.size(), get_max_cars()], "garage")
		return false
	var total_cr = get_build_whole_car_cost(champ_id)
	if player_team.balance < total_cr:
		add_notification("High",
			"Insufficient funds to build the car. Need CR %s for all 6 parts." % _fmt_int(total_cr),
			"cnc_plant")
		return false

	var approved = _approved_car_blueprints(champ_id)
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var champ_name = reg.get("name", champ_id)

	# Create the in-build car first (this fires assignment + TP proposals, like buying).
	if not add_car(champ_id, false):
		return false
	var car = player_team_cars[player_team_cars.size() - 1]
	# Self-sufficient delivery state: do not rely on add_car/CarManager to have set it.
	# A built car is in-build until its last part finishes (delivery_week set below).
	car.delivered   = false
	car.acquisition = "built"

	# Queue all 6 part jobs and collect their durations for the delivery calc.
	var weeks_list: Array = []
	for part in PARTS_LIST:
		var bp_id = approved[part]
		weeks_list.append(get_cnc_manufacturing_weeks(bp_id))
		start_cnc_job(bp_id, 1)

	# Slot-aware delivery: car ready when the LAST part finishes.
	car.delivery_week = current_week + _slot_aware_completion(weeks_list, get_cnc_slots())

	add_log("🏗 %s — whole car build started: 6 parts queued, arrives Week %d (CR %s)." % [
		champ_name, car.delivery_week, _fmt_int(total_cr)])
	add_notification("Normal",
		"🏗 %s car in build — all 6 parts queued, arrives Week %d. Pre-assign crew in the Garage." % [
		champ_name, car.delivery_week], "garage")
	return true

func assign_cnc_part_to_car(car_id: String, part: String) -> bool:
	return _rnd_engine.assign_cnc_part_to_car(car_id, part)

func remove_cnc_part_from_car(car_id: String, part: String) -> bool:
	return _rnd_engine.remove_cnc_part_from_car(car_id, part)

func get_cnc_part_bonus(car_id: String) -> float:
	return _rnd_engine.get_cnc_part_bonus(car_id)

func _cnc_inv_key(champ_id: String, pcode: String) -> String:
	return _rnd_engine._cnc_inv_key(champ_id, pcode)

func get_cnc_manufacturing_weeks(blueprint_id: String, extra_weeks: int = 0) -> int:
	return _rnd_engine.get_cnc_manufacturing_weeks(blueprint_id, extra_weeks)

func get_cnc_manufacturing_cr(blueprint_id: String, quantity: int = 1, extra_cr: int = 0) -> int:
	return _rnd_engine.get_cnc_manufacturing_cr(blueprint_id, quantity, extra_cr)

func calculate_final_reliability(blueprint_id: String, extra_cr: int = 0, extra_weeks: int = 0) -> float:
	return _rnd_engine.calculate_final_reliability(blueprint_id, extra_cr, extra_weeks)

func _get_wra_group_season(cid: String) -> int:
	return _rnd_engine._get_wra_group_season(cid)

func get_cnc_stock_for_slot(champ_id: String, pcode: String) -> Array:
	return _rnd_engine.get_cnc_stock_for_slot(champ_id, pcode)

## S28.3 (issue 4): number of parallel CNC production slots (from plant level).
func get_cnc_slots() -> int:
	return _rnd_engine.get_cnc_slots()

func get_cnc_part_label(inv_key: String) -> String:
	return _rnd_engine.get_cnc_part_label(inv_key)

func start_cnc_job(blueprint_id: String, quantity: int = 1, extra_cr: int = 0, extra_weeks: int = 0) -> bool:
	return _rnd_engine.start_cnc_job(blueprint_id, quantity, extra_cr, extra_weeks)

func get_blueprint_grid(champ_id: String) -> Dictionary:
	return _rnd_engine.get_blueprint_grid(champ_id)

func get_rnd_perf_bonus_summary() -> String:
	return _rnd_engine.get_rnd_perf_bonus_summary()

func rnd_task_unlocked(task_id: String) -> bool:
	return _rnd_engine.rnd_task_unlocked(task_id)

func rnd_task_active_or_done(task_id: String) -> bool:
	return _rnd_engine.rnd_task_active_or_done(task_id)

func start_rnd_task(task_id: String, designer_id: String, championship_id: String = "") -> bool:
	return _rnd_engine.start_rnd_task(task_id, designer_id, championship_id)

func cancel_rnd_task(task_id: String) -> void:
	_rnd_engine.cancel_rnd_task(task_id)

func _advance_rnd_tasks() -> void:
	_rnd_engine._advance_rnd_tasks()

func _apply_rnd_effect(task: Dictionary) -> void:
	_rnd_engine._apply_rnd_effect(task)

func get_rnd_bonus(effect_key: String) -> float:
	return _rnd_engine.get_rnd_bonus(effect_key)

func get_rnd_rp_storage_cap() -> int:
	return _rnd_engine.get_rnd_rp_storage_cap()

func _advance_wra_submissions() -> void:
	_rnd_engine._advance_wra_submissions()

func submit_to_wra(blueprint_id: String) -> bool:
	return _rnd_engine.submit_to_wra(blueprint_id)

func is_blueprint_approved(blueprint_id: String) -> bool:
	return _rnd_engine.is_blueprint_approved(blueprint_id)

func is_blueprint_submitted(blueprint_id: String) -> bool:
	return _rnd_engine.is_blueprint_submitted(blueprint_id)

func _get_championship_tier(cid: String) -> int:
	return _rnd_engine._get_championship_tier(cid)

func get_installed_parts_for_car(car_id: String) -> Dictionary:
	return _rnd_engine.get_installed_parts_for_car(car_id)

func _get_wra_group_for_championship(cid: String) -> String:
	return _rnd_engine._get_wra_group_for_championship(cid)

func _part_name_to_pcode(part_name: String) -> String:
	return _rnd_engine._part_name_to_pcode(part_name)


## ═══ CAMPUS MANAGER — delegated to CampusManager.gd (S27) ═══

func _setup_campus() -> void:
	_campus_manager._setup_campus()

func get_building(building_id: String) -> Dictionary:
	return _campus_manager.get_building(building_id)

func start_building(building_id: String) -> void:
	_campus_manager.start_building(building_id)

func sell_building(building_id: String) -> void:
	_campus_manager.sell_building(building_id)

func start_upgrade(building_id: String) -> void:
	_campus_manager.start_upgrade(building_id)

func _update_campus_construction() -> void:
	_campus_manager._update_campus_construction()

func get_upgrade_cost(building: Dictionary) -> int:
	return _campus_manager.get_upgrade_cost(building)

func get_upgrade_time(building: Dictionary) -> int:
	return _campus_manager.get_upgrade_time(building)

func get_building_income(building: Dictionary) -> int:
	return _campus_manager.get_building_income(building)

func get_building_maintenance(building: Dictionary) -> int:
	return _campus_manager.get_building_maintenance(building)

func get_logistics_parts_discount() -> float:
	return _campus_manager.get_logistics_parts_discount()

func get_fitness_fatigue_reduction() -> float:
	return _campus_manager.get_fitness_fatigue_reduction()

func get_pit_crew_time_bonus() -> float:
	return _campus_manager.get_pit_crew_time_bonus()

func get_wind_tunnel_aero_bonus() -> float:
	return _campus_manager.get_wind_tunnel_aero_bonus()

func get_ops_sim_track_knowledge_base() -> float:
	return _campus_manager.get_ops_sim_track_knowledge_base()

func get_racing_dept_driver_bonus() -> float:
	return _campus_manager.get_racing_dept_driver_bonus()

func get_hq_marketability_bonus() -> float:
	return _campus_manager.get_hq_marketability_bonus()

func get_hq_tp_slots() -> int:
	return _campus_manager.get_hq_tp_slots()

func get_hq_sponsor_slots() -> int:
	return _campus_manager.get_hq_sponsor_slots()

## ═══ SPONSOR MANAGER — delegated to SponsorManager.gd (S27) ═══

func _setup_sponsor() -> void:
	_sponsor_manager._setup_sponsor()

func _update_sponsor_performance(race_results: Array) -> void:
	_sponsor_manager._update_sponsor_performance(race_results)

func _apply_sponsor_income() -> void:
	_sponsor_manager._apply_sponsor_income()

func _generate_sponsor_id() -> String:
	return _sponsor_manager._generate_sponsor_id()

func _generate_sponsor_name() -> String:
	return _sponsor_manager._generate_sponsor_name()

func _get_sponsor_tier_for_team() -> int:
	return _sponsor_manager._get_sponsor_tier_for_team()

func _generate_sponsor_offer(type: int, tier: int) -> Dictionary:
	return _sponsor_manager._generate_sponsor_offer(type, tier)

func _generate_passive_sponsor_offers() -> void:
	_sponsor_manager._generate_passive_sponsor_offers()

func start_cfo_sponsor_search() -> bool:
	return _sponsor_manager.start_cfo_sponsor_search()

func stop_cfo_sponsor_search() -> void:
	_sponsor_manager.stop_cfo_sponsor_search()

func _advance_cfo_search() -> void:
	_sponsor_manager._advance_cfo_search()

func dismiss_sponsor_offer(sponsor_id: String) -> void:
	_sponsor_manager.dismiss_sponsor_offer(sponsor_id)

func sign_sponsor(sponsor_id: String) -> bool:
	return _sponsor_manager.sign_sponsor(sponsor_id)

func cancel_sponsor(sponsor_id: String) -> void:
	_sponsor_manager.cancel_sponsor(sponsor_id)

func _process_sponsors_weekly() -> void:
	_sponsor_manager._process_sponsors_weekly()

func apply_sponsor_race_bonuses(position: int = -1) -> void:
	_sponsor_manager.apply_sponsor_race_bonuses(position)

func _process_sponsors_season_end() -> void:
	_sponsor_manager._process_sponsors_season_end()

func _maybe_generate_race_sponsor_offer(player_position: int) -> void:
	_sponsor_manager._maybe_generate_race_sponsor_offer(player_position)


func add_notification(priority: String, message: String, destination: String = "", subject: String = "") -> void:
	_notification_manager.add_notification(priority, message, destination, subject)

func mark_all_notifications_read() -> void:
	_notification_manager.mark_all_notifications_read()

func dismiss_notification(index: int) -> void:
	_notification_manager.dismiss_notification(index)

func snooze_notification(index: int, weeks: int) -> void:
	_notification_manager.snooze_notification(index, weeks)

func _purge_old_notifications(keep_weeks: int = 2) -> void:
	_notification_manager._purge_old_notifications(keep_weeks)

func get_critical_count() -> int:
	return _notification_manager.get_critical_count()

func add_log(message: String) -> void:
	_notification_manager.add_log(message)

func _check_resource_notifications() -> void:
	_notification_manager._check_resource_notifications()

func _check_part_inventory_notifications() -> void:
	_notification_manager._check_part_inventory_notifications()

func get_pending_tasks() -> Array[String]:
	return _notification_manager.get_pending_tasks()

func _is_todo_item_resolved(item: String) -> bool:
	return _notification_manager._is_todo_item_resolved(item)

func add_todo_item(item_text: String) -> void:
	_notification_manager.add_todo_item(item_text)

func dismiss_todo_item(item_text: String) -> void:
	_notification_manager.dismiss_todo_item(item_text)

func clear_dismissed_todo_items() -> void:
	_notification_manager.clear_dismissed_todo_items()

func _clear_notifications_containing(substring: String) -> void:
	_notification_manager._clear_notifications_containing(substring)

func _apply_weekly_expenses() -> void:
	_financial_engine.apply_weekly_expenses()

func _get_championship_driver_salary() -> float:
	return _financial_engine.get_championship_driver_salary()

func _consume_race_resources() -> void:
	_race_simulator.consume_race_resources()

func _earn_race_rp(laps: int) -> void:
	_race_simulator.earn_race_rp(laps)

## ── S35.3 CFO auto-buy ────────────────────────────────────────────────────────
## When the player fast-forwards to season end (simulating_to_season_end), the CFO keeps the
## cars race-ready by topping up fuel (and spare parts) to EXACTLY what the next race needs —
## but only if a CFO is hired and only if the team can afford it. Returns true if it bought
## anything. Never fires during hands-on weekly play (the caller gates on the flag); during
## normal play the player manages logistics themselves.
func cfo_auto_buy_for_race(champ = null) -> bool:
	if get_cfo() == null:
		return false
	var c = champ if champ != null else active_championship
	if c == null:
		return false

	var bought_anything := false

	## Count the player's cars that will start the next race in THIS championship
	## (a car needs a driver to race; undelivered/crewless cars DNS regardless of fuel).
	var cars_racing := 0
	for car in player_team_cars:
		if car.championship_id == c.id and car.driver_id != "":
			cars_racing += 1
	if cars_racing == 0:
		return false

	## ── Fuel: buy EXACTLY the shortfall for the next race ──────────────────────
	var fuel_needed: float = c.fuel_per_car_per_race * cars_racing
	var fuel_short: float = fuel_needed - fuel_kg
	if fuel_short > 0.0:
		var fuel_cost: float = fuel_short * get_fuel_cost_per_kg()
		if player_team.balance >= fuel_cost:
			buy_fuel(fuel_short)   ## logs + deducts at the living price
			add_log("💼 CFO auto-bought %.1f kg fuel for the next race." % fuel_short)
			bought_anything = true
		else:
			add_log("💼 CFO could not afford fuel for the next race (need CR %.0f)." % fuel_cost)

	## ── Spare parts: top up to one race's repair reserve (sp_per_10_pct_damage) ─
	## S35.5: SP now has a living price (economy × market pressure) like fuel — use it here too.
	var sp_reserve: int = c.sp_per_10_pct_damage
	var sp_short: int = sp_reserve - spare_parts
	if sp_short > 0:
		var sp_cost: float = sp_short * get_sp_cost_per_unit()
		if player_team.balance >= sp_cost:
			buy_spare_parts(sp_short)
			add_log("💼 CFO auto-bought %d spare parts for the next race." % sp_short)
			bought_anything = true
		else:
			add_log("💼 CFO could not afford spare parts for the next race (need CR %.0f)." % sp_cost)

	return bought_anything

func buy_spare_parts(units: int) -> bool:
	## S35.5: living price (base × economy × market pressure), not the old hardcoded CR 1/unit.
	var cost_per_unit: float = get_sp_cost_per_unit()
	var total_cost: float = units * cost_per_unit
	if player_team.balance < total_cost:
		add_notification("High", "Not enough credits to buy spare parts.")
		return false
	player_team.balance -= total_cost
	spare_parts += units
	add_log("🛒 Bought %d spare parts for CR %.0f (CR %.2f/unit, stock: %d)" % [units, total_cost, cost_per_unit, spare_parts])
	return true

func buy_fuel(kg: float) -> bool:
	## S35.3: living price (base × economy multiplier), not the old hardcoded CR 2/kg.
	var cost_per_kg = get_fuel_cost_per_kg()
	var total_cost = kg * cost_per_kg
	if player_team.balance < total_cost:
		add_notification("High", "Not enough credits to buy fuel.")
		return false
	player_team.balance -= total_cost
	fuel_kg += kg
	add_log("🛒 Bought %.1f kg fuel for CR %.0f (CR %.2f/kg, stock: %.1f kg)" % [kg, total_cost, cost_per_kg, fuel_kg])
	return true

## ═══ DRIVER MANAGER — delegated to DriverManager.gd (S27) ═══

func get_max_drivers() -> int:
	return _driver_manager.get_max_drivers()

func _find_and_sign_starting_driver(discipline: String, champ_id: String) -> Driver:
	return _driver_manager._find_and_sign_starting_driver(discipline, champ_id)

func _generate_drivers() -> void:
	_driver_manager._generate_drivers()

func _create_driver_for_discipline(id: String, first: String, last: String, nationality: String, age: int, sex: String, discipline: String, tier: int) -> Driver:
	return _driver_manager._create_driver_for_discipline(id, first, last, nationality, age, sex, discipline, tier)

func _create_driver(id: String, first: String, last: String, nationality: String, age: int, sex: String, team_id: String) -> Driver:
	return _driver_manager._create_driver(id, first, last, nationality, age, sex, team_id)

func get_max_cars() -> int:
	return campus_buildings.get("Garage", {}).get("level", 1)

## ═══════════════════════════════════════════════════════════════════════════
## CAR SYSTEM
## ═══════════════════════════════════════════════════════════════════════════

## Car telemetry data keyed by car_type_id (from Excel Cars sheet)
const CAR_TELEMETRY = {
	"A_01": {"top_speed": 75.0,  "acceleration": 7.5,  "deceleration": 9.0,  "cornering_grip": 2.5,  "fuel_per_km": 0.045, "tire_wear": 0.65, "perf_index": 1},   # GK Championship
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
	add_car(champ_id, true)  ## S28.3 (issue 1): silent — driver/mechanic assigned right after

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
	invalidate_player_staff_cache()  ## S35.6 — starting roster populated

## ═══ STAFF MANAGER — delegated to StaffManager.gd (S27) ═══

func _generate_available_staff(count: int) -> void:
	_staff_manager._generate_available_staff(count)

## S28.3 (Bug 7) — season-end free-agent pool top-up.
func replenish_free_agent_pool() -> void:
	_staff_manager.replenish_free_agent_pool()

func _create_staff(role: String, nationality: String) -> Staff:
	return _staff_manager._create_staff(role, nationality)

func _generate_staff_attributes(staff: Staff, base_quality: float) -> void:
	_staff_manager._generate_staff_attributes(staff, base_quality)

func hire_staff(staff_id: String) -> bool:
	return _staff_manager.hire_staff(staff_id)

func release_staff(staff_id: String) -> void:
	_staff_manager.release_staff(staff_id)

func renew_staff_contract(staff_id: String, seasons: int = 5) -> void:
	_staff_manager.renew_staff_contract(staff_id, seasons)

func _create_starting_staff(role: String, skill_min: float, skill_max: float) -> Staff:
	return _staff_manager._create_starting_staff(role, skill_min, skill_max)

func get_available_drivers() -> Array:
	return _driver_manager.get_available_drivers()

## S33.1 — top up the GK feeder field with new young cadets at season rollover (GK is the
## only place new drivers are born; everyone else fills gaps from the existing pool).
func regenerate_gk_field(target_size: int = 510) -> int:
	return _driver_manager.regenerate_gk_field(target_size)

func get_player_drivers() -> Array:
	return _driver_manager.get_player_drivers()

func hire_driver(driver_id: String) -> bool:
	return _driver_manager.hire_driver(driver_id)

func release_driver(driver_id: String) -> void:
	_driver_manager.release_driver(driver_id)

func renew_driver_contract(driver_id: String, seasons: int = 5) -> void:
	_driver_manager.renew_driver_contract(driver_id, seasons)

func get_player_staff_by_role(role: String) -> Array:
	return _staff_manager.get_player_staff_by_role(role)

func get_team_principal() -> Staff:
	return _staff_manager.get_team_principal()

func get_mechanic_for_car(car_id: String) -> Staff:
	return _staff_manager.get_mechanic_for_car(car_id)

func get_cfo() -> Staff:
	return _staff_manager.get_cfo()

func generate_car_name(for_champ_id: String = "") -> String:
	return _car_manager.generate_car_name(for_champ_id)

func add_car(for_champ_id: String = "", silent: bool = false) -> bool:
	return _car_manager.add_car(for_champ_id, silent)

func remove_car(car_id: String) -> bool:
	return _car_manager.remove_car(car_id)

func rename_car(car_id: String, new_name: String) -> bool:
	return _car_manager.rename_car(car_id, new_name)

func assign_driver_to_car(driver_id: String, car_id: String) -> void:
	_car_manager.assign_driver_to_car(driver_id, car_id)

func unassign_driver_from_car(car_id: String) -> void:
	_car_manager.unassign_driver_from_car(car_id)

func assign_staff_to_car(staff_id: String, car_id: String) -> void:
	_car_manager.assign_staff_to_car(staff_id, car_id)

func unassign_mechanic_from_car(car_id: String) -> void:
	_car_manager.unassign_mechanic_from_car(car_id)

## S28.3 (Bug 6) — Pit Crew assignment wrappers.
func assign_pit_crew_to_car(staff_id: String, car_id: String) -> void:
	_car_manager.assign_pit_crew_to_car(staff_id, car_id)

func unassign_pit_crew_from_car(car_id: String) -> void:
	_car_manager.unassign_pit_crew_from_car(car_id)

func get_car_for_driver(driver_id: String) -> Car:
	return _car_manager.get_car_for_driver(driver_id)

func get_car_by_id(car_id: String) -> Car:
	return _car_manager.get_car_by_id(car_id)

## Returns the Championship object for a given ID, or null. (Cluster A shared helper — replaces
## the repeated "for champ in active_championships: if champ.id == cid" loop scattered across screens.)
func get_championship_by_id(champ_id: String) -> Championship:
	for champ in active_championships:
		if champ.id == champ_id:
			return champ
	return null

## Returns the Championship objects the player is actually involved in this season:
## every championship they own a car for + every one they're registered in. (Cluster A —
## the correct multi-championship replacement for the singular active_championship in UI.)
func get_player_championships() -> Array:
	var cids: Array = []
	for car in player_team_cars:
		if car.championship_id != "" and not car.championship_id in cids:
			cids.append(car.championship_id)
	for cid in player_registered_championships:
		if not cid in cids:
			cids.append(cid)
	var champs: Array = []
	for champ in active_championships:
		if champ.id in cids:
			champs.append(champ)
	return champs

func get_car_condition(driver_id: String) -> float:
	return _car_manager.get_car_condition(driver_id)

func repair_car(driver_id: String, repair_pct: float) -> bool:
	return _car_manager.repair_car(driver_id, repair_pct)

func repair_car_full(driver_id: String) -> bool:
	return _car_manager.repair_car_full(driver_id)

func install_part_on_car(car_id: String, champ_id: String, pcode: String) -> bool:
	return _car_manager.install_part_on_car(car_id, champ_id, pcode)

func remove_part_from_car(car_id: String, pcode: String) -> bool:
	return _car_manager.remove_part_from_car(car_id, pcode)

func install_provider_part(car_id: String, champ_id: String, pcode: String) -> bool:
	return _car_manager.install_provider_part(car_id, champ_id, pcode)

func remove_provider_part(car_id: String, pcode: String) -> bool:
	return _car_manager.remove_provider_part(car_id, pcode)

func get_all_parts_for_car(car_id: String) -> Dictionary:
	return _car_manager.get_all_parts_for_car(car_id)


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

func generate_driver_opening_offer(driver_id: String) -> Dictionary:
	return _contract_engine.generate_driver_opening_offer(driver_id)

func generate_staff_opening_offer(staff_id: String) -> Dictionary:
	return _contract_engine.generate_staff_opening_offer(staff_id)

func make_renegotiation_approach(subject_id: String, subject_type: String) -> Dictionary:
	return _contract_engine.make_renegotiation_approach(subject_id, subject_type)

func generate_sponsor_negotiation(sponsor_id: String) -> Dictionary:
	return _contract_engine.generate_sponsor_negotiation(sponsor_id)

func make_sponsor_approach(sponsor_id: String) -> Dictionary:
	return _contract_engine.make_sponsor_approach(sponsor_id)

func start_negotiation(neg: Dictionary) -> void:
	_contract_engine.start_negotiation(neg)

func submit_negotiation_offer(player_offer: Dictionary) -> String:
	return _contract_engine.submit_negotiation_offer(player_offer)

func abandon_negotiation() -> void:
	_contract_engine.abandon_negotiation()

func is_subject_available(subject_id: String) -> bool:
	return _contract_engine.is_subject_available(subject_id)

## S35.9 — deterministic interest predicate + cooldown check (used by the hub filters).
func is_subject_interested(subject_id: String, subject_type: String, current_team_id: String, ctx: Dictionary = {}) -> bool:
	return _contract_engine.is_subject_interested(subject_id, subject_type, current_team_id, ctx)

func is_team_refusal_cooled_down(subject_id: String) -> bool:
	return _contract_engine.is_team_refusal_cooled_down(subject_id)

func build_interest_context() -> Dictionary:
	return _contract_engine.build_interest_context()

func get_bond_estimate(subject_id: String, subject_type: String, start_date: String) -> Dictionary:
	return _contract_engine.get_bond_estimate(subject_id, subject_type, start_date)

func get_slot_projection(subject_type: String, role: String = "") -> Dictionary:
	return _contract_engine.get_slot_projection(subject_type, role)

func initiate_approach(subject_id: String, subject_type: String, start_date: String) -> String:
	return _contract_engine.initiate_approach(subject_id, subject_type, start_date)

func send_bond_offer(neg_id: String, offer_amount: float) -> void:
	_contract_engine.send_bond_offer(neg_id, offer_amount)

func respond_bond_counter(neg_id: String, accept: bool, counter_amount: float = 0.0) -> void:
	_contract_engine.respond_bond_counter(neg_id, accept, counter_amount)

func handle_incoming_approach(subject_id: String, subject_type: String, ai_team_id: String, ai_team_name: String, proposed_bond: float) -> void:
	_contract_engine.handle_incoming_approach(subject_id, subject_type, ai_team_id, ai_team_name, proposed_bond)

func respond_incoming_approach(neg_id: String, accept: bool, counter_amount: float = 0.0) -> void:
	_contract_engine.respond_incoming_approach(neg_id, accept, counter_amount)

func submit_approach_contract_offer(neg_id: String, field_offers: Dictionary, locked_fields: Array) -> String:
	return _contract_engine.submit_approach_contract_offer(neg_id, field_offers, locked_fields)

func accept_approach_terms(neg_id: String) -> void:
	_contract_engine.accept_approach_terms(neg_id)

func walk_away_approach(neg_id: String) -> void:
	_contract_engine.walk_away_approach(neg_id)

func cancel_approach_before_submit(neg_id: String) -> void:
	_contract_engine.cancel_approach_before_submit(neg_id)

func get_active_approaches_for_display() -> Array:
	return _contract_engine.get_active_approaches_for_display()

func get_pending_contract_negotiation() -> Dictionary:
	return _contract_engine.get_pending_contract_negotiation()

## S35.7 — clear stale "you walked away" entries (called from advance_week).
func clear_walked_away_approaches() -> void:
	_contract_engine.clear_walked_away_approaches()

func _get_subject_display_name(subject_id: String, subject_type: String) -> String:
	return _contract_engine._get_subject_display_name(subject_id, subject_type)

func _get_approach(neg_id: String) -> Dictionary:
	return _contract_engine._get_approach(neg_id)

func _get_approach_by_subject(subject_id: String) -> Dictionary:
	return _contract_engine._get_approach_by_subject(subject_id)

func _get_max_slots_for_role(role: String) -> int:
	return _contract_engine._get_max_slots_for_role(role)

func _get_active_championship_tier() -> int:
	return _contract_engine._get_active_championship_tier()

func _calc_driver_ask_salary(skill: float, tier: int) -> float:
	return _contract_engine._calc_driver_ask_salary(skill, tier)

func _advance_approaches() -> void:
	_contract_engine._advance_approaches()

func _activate_presigned_contracts() -> void:
	_contract_engine._activate_presigned_contracts()

func _get_tp_for_championship(champ_id: String):
	return _contract_engine._get_tp_for_championship(champ_id)

func _get_strategist_for_championship(champ_id: String):
	return _contract_engine._get_strategist_for_championship(champ_id)

## S33.0 — Team-scoped variants (used by the shared optimiser for AI auto-assign).
func _get_tp_for_championship_team(champ_id: String, team_id: String):
	return _contract_engine._get_tp_for_championship_team(champ_id, team_id)

func _get_strategist_for_championship_team(champ_id: String, team_id: String):
	return _contract_engine._get_strategist_for_championship_team(champ_id, team_id)

## S33.0 — Resolve the cars belonging to a team. Player cars live in the flat
## player_team_cars array; AI cars live in ai_cars keyed by championship with no team
## back-reference, but the seed encodes ownership in the car id: "CAR-{TEAM_ID}-{CHAMP}-{idx}".
## We match by that prefix so no Car field / save migration is needed.
func get_cars_for_team(team) -> Array:
	if team == null:
		return []
	if team.id == player_team.id:
		return player_team_cars
	var prefix: String = "CAR-%s-" % team.id
	var result: Array = []
	for cid in ai_cars:
		for car in ai_cars[cid]:
			if car.id.begins_with(prefix):
				result.append(car)
	return result

## S33.0 — TP Phase 2 entry: re-optimise EVERY AI team's 5-role allocation (driver/mechanic/
## pit-crew/strategist/TP), applied directly (no proposal UI, no player notifications). Called
## by SeasonManager at season rollover for Season >= 2 (Season 1 stays JSON-seeded). Also the
## hook the future Transfer Market (P51) can call per-team on a mid-season AI roster change.
func ai_auto_assign_all_teams() -> void:
	_tp_engine.ai_auto_assign_all_teams()

func ai_auto_assign(team) -> void:
	_tp_engine.ai_auto_assign(team)

func _apply_negotiation_result(neg: Dictionary, accepted: bool) -> void:
	_contract_engine._apply_negotiation_result(neg, accepted)

func _pay_driver_salaries_weekly() -> void:
	_contract_engine._pay_driver_salaries_weekly()

## Pay driver race bonuses after a race result.
func pay_driver_race_bonuses(race_results: Array) -> void:
	_race_simulator.pay_driver_race_bonuses(race_results)

func assign_staff_to_championship(staff_id: String, champ_id: String) -> void:
	if not staff_id in all_staff: return
	var staff = all_staff[staff_id]
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var champ_name = reg.get("name", champ_id)

	## Guard: TP slot — only one TP per championship, but:
	## - Same TP can be reassigned (clears old assignment)
	## - GK discipline: one TP covers all tiers — assigning to any GK champ covers all
	if staff.role == "Team Principal":
		## Clear old assignment if this TP is already assigned somewhere
		if staff.assigned_championship != "" and staff.assigned_championship != champ_id:
			var old_reg = CHAMPIONSHIP_REGISTRY.get(staff.assigned_championship, {})
			add_log("📋 %s unassigned from %s." % [staff.full_name(), old_reg.get("name", staff.assigned_championship)])
		## Check no OTHER TP is already on this championship
		for sid2 in all_staff:
			var s2 = all_staff[sid2]
			if s2.id == staff_id: continue
			if s2.role == "Team Principal" and s2.contract_team == player_team.id \
					and s2.assigned_championship == champ_id:
				add_notification("High",
					"Championship already has a Team Principal assigned.")
				return

	## TP and Strategist: queue for next week
	if staff.role in ["Team Principal", "Race Strategist"]:
		pending_staff_assignments[staff_id] = champ_id
		add_log("📋 %s queued for %s — effective next week." % [staff.full_name(), champ_name])
		add_notification("Normal",
			"%s will be assigned to %s from next week." % [staff.full_name(), champ_name])
	else:
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

## ── S35.10 Shortlist API ──────────────────────────────────────────────────────
## A UI bookmark spanning BOTH drivers and staff. The Shortlist screen groups by role tab
## ("Driver" + the 6 staff roles). Toggling is_shortlisted is the single source of truth; the
## row star and the View Card star both call toggle and reflect the same flag.
func toggle_shortlist(subject_id: String, subject_type: String) -> bool:
	var obj = all_drivers.get(subject_id) if subject_type == "driver" else all_staff.get(subject_id)
	if obj == null:
		return false
	obj.is_shortlisted = not obj.is_shortlisted
	return obj.is_shortlisted

func is_shortlisted(subject_id: String, subject_type: String) -> bool:
	var obj = all_drivers.get(subject_id) if subject_type == "driver" else all_staff.get(subject_id)
	return obj != null and obj.is_shortlisted

## Shortlisted people of one role tab. role_tab == "Driver" → drivers; otherwise a staff role.
func get_shortlisted_by_role(role_tab: String) -> Array:
	var result = []
	## S35.10d — "All" = every shortlisted person, drivers first then staff.
	if role_tab == "All" or role_tab == "Driver":
		for did in all_drivers:
			var d = all_drivers[did]
			if d.is_shortlisted:
				result.append(d)
		if role_tab == "Driver":
			return result
	if role_tab == "All":
		for sid in all_staff:
			var s = all_staff[sid]
			if s.is_shortlisted:
				result.append(s)
		return result
	for sid in all_staff:
		var s = all_staff[sid]
		if s.is_shortlisted and s.role == role_tab:
			result.append(s)
	return result

## Count of shortlisted people for each role tab (for badge counts on the tabs).
func get_shortlist_counts() -> Dictionary:
	var counts = {"All": 0, "Driver": 0}
	for r in STAFF_ROLES:
		counts[r] = 0
	for did in all_drivers:
		if all_drivers[did].is_shortlisted:
			counts["Driver"] += 1
			counts["All"] += 1
	for sid in all_staff:
		var s = all_staff[sid]
		if s.is_shortlisted:
			counts[s.role] = counts.get(s.role, 0) + 1
			counts["All"] += 1
	return counts

## S35.6 — rebuild the player-staff cache from all_staff. One full scan; only runs when dirty.
func _rebuild_player_staff_cache() -> void:
	_player_staff_by_role.clear()
	_player_staff_flat.clear()
	if player_team == null:
		_player_staff_cache_dirty = false
		return
	var pid = player_team.id
	for staff_id in all_staff:
		var staff = all_staff[staff_id]
		if staff.contract_team == pid:
			_player_staff_flat.append(staff)
			if not _player_staff_by_role.has(staff.role):
				_player_staff_by_role[staff.role] = []
			_player_staff_by_role[staff.role].append(staff)
	_player_staff_cache_dirty = false

## S35.6 — call after ANY change to who is on the player's roster (hire/release/sign/load/rollover).
## Cheap: just flags the cache; the next read rebuilds. Funnel all roster mutations through this
## so the cache can never silently go stale.
func invalidate_player_staff_cache() -> void:
	_player_staff_cache_dirty = true

func get_all_player_staff() -> Array:
	if _player_staff_cache_dirty:
		_rebuild_player_staff_cache()
	return _player_staff_flat
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

func _check_race_requirements() -> void:
	_race_simulator.check_race_requirements_for(active_championship)

func _check_race_requirements_for(champ: Championship) -> void:
	_race_simulator.check_race_requirements_for(champ)
func _recover_pit_crew_fitness() -> void:
	_race_simulator.recover_pit_crew_fitness()

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
	return _race_simulator.has_remaining_races_this_season()

func apply_post_race_repairs() -> void:
	_race_simulator.auto_repair_cars_post_race()

func _degrade_car_conditions(laps: int, dns_driver_ids: Array = []) -> void:
	_race_simulator.degrade_car_conditions(laps, dns_driver_ids)

func _auto_repair_cars_post_race() -> void:
	_race_simulator.auto_repair_cars_post_race()


func _can_car_race(driver_id: String) -> bool:
	return _race_simulator.can_car_race(driver_id)
func can_register_for_championship(champ_id: String) -> bool:
	## S28.1: registration targets the NEXT season → checks the ledger, not the active set.
	if champ_id in next_season_registrations:
		return false  # already registered for next season
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

## Register the player for a championship NEXT season. Deducts one-time entry fee.
## S28.1: writes to next_season_registrations (the ledger), NOT player_registered_championships.
## The ledger is activated into the current set at start_new_season() (GDD §23.1).
## Returns true on success, false with notification on failure.
func register_for_championship(champ_id: String) -> bool:
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	if reg.is_empty():
		add_notification("High", "Unknown championship ID: %s" % champ_id)
		return false
	if champ_id in next_season_registrations:
		add_notification("Normal", "Already registered for %s (Season %d)." % [reg["name"], current_season + 1])
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
	next_season_registrations.append(champ_id)
	add_log("✅ Registered for %s (Season %d) — Entry fee: CR %s" % [reg["name"], current_season + 1, _fmt_int(fee)])

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

	if reg["discipline"] not in ["GK", "Rally"]:
		var strats = get_player_staff_by_role("Race Strategist")
		if strats.is_empty():
			warnings.append("📡 No Race Strategist — recommended for non-GK/Rally championships")

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

## Returns all championship IDs the player has registered for NEXT season (the ledger).
## S28.1: this is simply the NextSeasonLedger contents.
func get_pending_registrations() -> Array:
	return next_season_registrations.duplicate()
func get_weekly_expenses() -> float:
	return _financial_engine.get_weekly_expenses()

## Runway in weeks at current expense rate
func get_runway_weeks() -> int:
	return _financial_engine.get_runway_weeks()

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
func swap_part_on_car(car_id: String, champ_id: String, pcode: String) -> bool:
	## Remove existing CNC part in slot (if any)
	if car_id in car_installed_parts and pcode in car_installed_parts[car_id]:
		remove_part_from_car(car_id, pcode)
	## Remove existing provider part in slot (if any)
	elif car_id in car_provider_parts and pcode in car_provider_parts[car_id]:
		remove_provider_part(car_id, pcode)
	## Install the new CNC part
	return install_part_on_car(car_id, champ_id, pcode)
func _get_provider_part_base_rel(champ_id: String) -> float:
	var season_in_cycle = current_season - wra_cycle_start_season
	return clamp(60.0 + season_in_cycle * 5.0, 60.0, 90.0)

## Returns the provider part base quality for a championship this season.
func _get_provider_part_base_qual(_champ_id: String) -> float:
	var season_in_cycle = current_season - wra_cycle_start_season
	return clamp(0.90 + season_in_cycle * 0.02, 0.90, 1.10)
func get_drivers_per_car(champ_id: String) -> int:
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var disc = reg.get("discipline", "GK")
	return DRIVERS_PER_CAR.get(disc, 1)

## Returns whether a pit crew is required per car for a given championship.
func get_pit_crew_required(champ_id: String) -> bool:
	var reg = CHAMPIONSHIP_REGISTRY.get(champ_id, {})
	var disc = reg.get("discipline", "GK")
	return PIT_CREW_REQUIRED.get(disc, true)

func _apply_campus_income() -> void:
	_financial_engine.apply_campus_income()

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
	retired_personnel = []
	dismissed_todo_items = []
	custom_todo_items    = []
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
	## P57: Initialize managers early — needed by _setup_cars() and other setup functions
	_season_manager = SeasonManager.new(self)
	_financial_engine = FinancialEngine.new(self)
	_race_simulator = RaceSimulator.new(self)
	_contract_engine = ContractEngine.new(self)
	_rnd_engine = RnDEngine.new(self)
	_notification_manager = NotificationManager.new(self)
	_campus_manager = CampusManager.new(self)
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
	## S28.1: the chosen starting championship is the player's CURRENT-season race set.
	## (next_season_registrations is the ledger for NEXT season; S1 needs this active now.)
	if not _starting_champ_id in player_registered_championships:
		player_registered_championships.append(_starting_champ_id)
	add_log("Welcome to Automotive Empire!")
	var start_champ_name = CHAMPIONSHIP_REGISTRY.get(_starting_champ_id, {}).get("name", "Championship")
	add_log("Season %d — %s" % [current_season, start_champ_name])

	## Populate GK groups for Season 1 (start_new_season not called for first season)
	if gk_discipline == null:
		gk_discipline = GKDiscipline.new()
	gk_discipline.populate_season(
		all_drivers, all_staff, player_team.drivers,
		player_registered_championships, CHAMPIONSHIP_CALENDARS,
		current_season, player_team_cars)
	_sync_gk_group0_to_standings()


func _sync_gk_group0_to_standings() -> void:
	## Writes player's GK group driver IDs into champ.standings
	## so _simulate_race() can find all competitors.
	if gk_discipline == null: return
	for champ in active_championships:
		if champ.id != "C-001": continue
		champ.standings.clear()  ## Driver standings: refreshed per round for the player's group
		## DO NOT clear team_standings — it's the SEASON-LONG cumulative GK constructors table
		## (CP3), accumulated across all 22 races. The old S28.3 "reset each round" was wrong: it
		## erased the team table every round, wiping the running totals (the GK team-wipe symptom).
		var group0 = gk_discipline.get_player_group("C-001")
		for did in group0:
			champ.standings[did] = 0
			var d = all_drivers.get(did)
			if d and d.contract_team != "":
				if not champ.team_standings.has(d.contract_team):
					champ.team_standings[d.contract_team] = 0
		break  ## Only one GK championship

func _setup_championship() -> void:
	## Creates ALL 21 championships at game start — the entire racing world exists from Season 1.
	## The player's starting championship is tracked via player_registered_championships.
	active_championships.clear()

	const PRIZE_MONEY: Dictionary = {
		"C-001": [1200, 600, 300],  ## per-race prizes
		"C-005": [2500, 1250, 625],    "C-006": [5000, 2500, 1250],
		"C-007": [7000, 3500, 1750],   "C-008": [28000, 14000, 7000],
		"C-009": [4000, 2000, 1000],   "C-010": [40000, 20000, 10000],
		"C-011": [3000, 1500, 750],    "C-012": [6000, 3000, 1500],
		"C-013": [30000, 15000, 7500], "C-014": [8000, 4000, 2000],
		"C-015": [14000, 7000, 3500],  "C-016": [28000, 14000, 7000],
		"C-017": [100000, 50000, 25000],"C-018": [4000, 2000, 1000],
		"C-019": [12000, 6000, 3000],  "C-020": [40000, 20000, 10000],
		"C-021": [1500, 750, 375],     "C-022": [8000, 4000, 2000],
		"C-023": [15000, 7000, 3750],  "C-024": [250000, 125000, 72500],
	}

	const END_SEASON_PRIZE: Dictionary = {
		"C-009": 86000,    "C-010": 240000,   "C-011": 100000,
		"C-012": 350000,   "C-013": 10500000, "C-014": 22500,
		"C-015": 1350000,  "C-016": 2150000,  "C-017": 12850000,
		"C-019": 144000,   "C-020": 550000,   "C-024": 140000000,
	}

	for cid in CHAMPIONSHIP_REGISTRY:
		var reg = CHAMPIONSHIP_REGISTRY[cid]
		var champ = Championship.new()
		champ.id = cid
		champ.championship_name = reg["name"]
		champ.discipline        = reg.get("discipline", "GK")
		champ.tier              = reg.get("tier", 1)
		champ.min_age           = reg.get("min_age", 8)
		champ.max_age           = reg.get("max_age", 99)
		champ.entry_fee_per_race = float(reg.get("entry_fee", 9000)) / max(reg.get("num_races", 6), 1)
		champ.num_races          = reg.get("num_races", 6)

		## Points system — discipline-specific
		match champ.discipline:
			"Rally":
				champ.points_system = [18, 15, 13, 10, 8, 6, 4, 3, 2, 1]
			"OWC":
				champ.points_system = [50, 40, 35, 32, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20]
			"SC":
				champ.points_system = [55, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17]
			_:
				champ.points_system = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1]

		var pm = PRIZE_MONEY.get(cid, [300, 150, 75])
		champ.prize_1st = float(pm[0])
		champ.prize_2nd = float(pm[1])
		champ.prize_3rd = float(pm[2])

		var logi = CHAMP_LOGISTICS.get(cid, {"fuel": 15.0, "sp": 100})
		champ.sp_per_10_pct_damage   = int(logi["sp"])
		champ.fuel_per_car_per_race  = float(logi["fuel"])
		champ.condition_loss_per_lap = 0.5
		champ.condition_loss_per_stage    = 0.0
		champ.repair_time_per_1pct        = 0.0
		champ.has_mid_race_repairs        = false
		champ.service_park_every_n_stages = 0
		champ.pit_stop_repair_pct         = 0.0
		champ.calendar = []
		for race in CHAMPIONSHIP_CALENDARS.get(cid, CHAMPIONSHIP_CALENDARS.get("C-001", [])):
			var entry = {
				"round": race["round"], "name": race["name"], "week": race["week"],
				"rain_probability": race["rain"], "laps": race["laps"],
				"lap_km": race.get("lap_km", 1.0), "audience": race["audience"],
			}
			## Preserve GK round/elimination flags (gk_round, is_semifinal, is_final) — the
			## final-weekend cut logic reads these off the calendar entry. Dropping them (the old
			## bug) meant the Semi-Final was never detected, so no elimination ran.
			if race.has("gk_round"): entry["gk_round"] = race["gk_round"]
			if race.has("is_semifinal"): entry["is_semifinal"] = race["is_semifinal"]
			if race.has("is_final"): entry["is_final"] = race["is_final"]
			champ.calendar.append(entry)
		active_championships.append(champ)

	print("[GameState] %d championships created" % active_championships.size())
	## Do NOT add to player_registered_championships here.
	## active_championships is the source of truth for the racing world.
	## player_registered_championships is the player's CURRENT-season race set.
	## next_season_registrations is the planning ledger for next season (§23.1).
	player_registered_championships = []
	next_season_registrations = []

func _setup_player_team() -> void:
	player_team = Team.new()
	player_team.id = "T-PLAYER"
	player_team.team_name = player_team_name
	player_team.is_player_team = true
	player_team.balance = 50000.0
	player_team.reputation = 15.0
	## Initialise economy — start at Normal (50)
	economy_index = 50.0
	_economy_momentum = 0.0
	current_fuel_price = 1200.0
	sp_market_pressure = 1.0   ## S35.5 — neutral SP market at game start
	current_loan_rate = 5.0
	active_loans.clear()
	_loan_next_id = 1
	## Initialise GK discipline manager
	gk_discipline = GKDiscipline.new()
	player_team.weekly_driver_salary = 50.0
	player_team.weekly_mechanic_salary = 250.0
	all_teams.append(player_team)
	active_championship.team_standings[player_team.id] = 0

func _generate_ai_teams() -> void:
	## Delegated to AIManager instance — see res://autoloads/AIManager.gd
	ai_manager.generate_teams()
	ai_manager.generate_ai_staff()
	ai_manager.load_ai_drivers()
	ai_manager.load_car_assignments()


func advance_week() -> void:
	weekly_log = []
	_purge_old_notifications(2)

	# Guard: never advance past max_weeks
	if current_week >= max_weeks:
		_end_season()
		return

	current_week += 1

	## S35.7 — clear any "you walked away" entries from last week now that a week has passed.
	clear_walked_away_approaches()
	## Sponsor negotiation: fire counter notification when waiting week arrives
	if not active_negotiation.is_empty():
		var waiting = active_negotiation.get("waiting_week", 0)
		if waiting > 0 and current_week >= waiting:
			active_negotiation["waiting_week"] = 0
			var subj = _get_subject_display_name(
				active_negotiation.get("subject_id",""),
				active_negotiation.get("subject_type","sponsor"))
			add_notification("High",
				"📋 %s has counter-offered — return to negotiate." % subj, "hq")
			emit_signal("negotiation_updated")

	## Record weekly snapshot for P32 graphs
	_record_weekly_history()

	## Update economy state and fuel price fluctuations
	_update_economy_and_fuel()
	## S35.5 — weekly SP market-pressure drift (gentle supply/demand wobble on top of the economy).
	_update_sp_market_pressure()

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
	# Phase 2: flip any in-build cars whose delivery week has arrived (BEFORE the
	# race-check loop below, so a car delivered this week can race this week).
	_process_car_deliveries()
	# Sponsor and CFO
	_advance_cfo_search()
	_process_sponsors_weekly()
	_process_supply_contracts_weekly()
	_process_loans_weekly()
	_update_ceo_salary()

	# Check for races this week across ALL active championships
	for champ in active_championships:
		## Multi-event support: run EVERY race this championship has scheduled this week, in
		## calendar order (usually one; two for a GK final weekend; more for future Rally/Endurance
		## weekends). Each race produces its own result (separate result screens, per design).
		var races_this_week = champ.get_races_for_week(current_week)
		var is_player_champ = champ.id in player_registered_championships
		for race in races_this_week:
			if is_player_champ:
				## S35.3: when fast-forwarding to season end, the CFO keeps the cars race-ready
				## (buys exact fuel/SP shortfall, if hired + affordable) BEFORE the requirement
				## check and simulation — so a skipped season doesn't DNS purely for un-bought
				## logistics. No effect in hands-on weekly play (flag is false then).
				if simulating_to_season_end:
					cfo_auto_buy_for_race(champ)
				_check_race_requirements_for(champ)
			_simulate_race(race, champ)
			## Sponsor race bonuses handled by apply_sponsor_race_bonuses()
			champ.current_round += 1

			## GK final weekend (race-aware, final round only): when the SEMI-FINAL has just run,
			## simulate the AI groups' semi, then cut top-N-per-group into a single Grand Final
			## group, and re-sync the player's GK race field to those finalists — so the very next
			## race (the Grand Final, same week) is contested by the 20 survivors. The player's real
			## semi result is already synced into GK group 0 by _simulate_race (Option B).
			if champ.id == "C-001" and gk_discipline != null and race.get("is_semifinal", false):
				## AI semi for the non-player final groups (so their results exist before the cut).
				var semi_team_pts = gk_discipline.shadow_simulate_week(current_week, all_drivers)
				for tid in semi_team_pts:
					champ.add_team_points(tid, semi_team_pts[tid])
				## Cut to the finalists and collapse into one Grand Final group.
				gk_discipline.apply_semifinal_cut()
				## Re-sync the player's GK standings/field to the finalists (group 0 now = final 20).
				_sync_gk_group0_to_standings()

	## P26: Shadow-simulate non-player GK groups — ONLY on weeks GK actually races.
	## Previously this ran every single week, so the AI groups scored a full points-award even on
	## weeks with no GK race (roughly double the player's race count), inflating early-round
	## standings (group leaders at 100+). Now it mirrors the real race cadence: run only when GK
	## has a race this week, and skip the Semi-Final week — that week's AI shadow sim is already
	## handled inside the final-weekend hook above (before the cut), so running it again here would
	## double-count it.
	if gk_discipline != null:
		## Determine whether GK has a race this week by scanning its STATIC calendar by week.
		## (We can't use champ.get_races_for_week here — the race loop above already advanced
		## champ.current_round past this week's races, so that would always come back empty.)
		var gk_cal_wk = CHAMPIONSHIP_CALENDARS.get("C-001", [])
		var gk_raced = false
		var is_semi_week = false
		for r in gk_cal_wk:
			if r["week"] == current_week:
				gk_raced = true
				if r.get("is_semifinal", false): is_semi_week = true
		if gk_raced and not is_semi_week:
			var gk_team_points = gk_discipline.shadow_simulate_week(current_week, all_drivers)
			## CP3: fold the shadow groups' team points into GK's flat constructors table, so the GK
			## team champion counts ALL races (player group already fed via _simulate_race).
			if not gk_team_points.is_empty():
				var gk_champ = get_championship_by_id("C-001")
				if gk_champ != null:
					for tid in gk_team_points:
						gk_champ.add_team_points(tid, gk_team_points[tid])

	## GK round advancement — check if this week was the last race of a gk_round
	if gk_discipline != null:
		var gk_cal = CHAMPIONSHIP_CALENDARS.get("C-001", [])
		## Find the gk_round of this week's LAST race. With multi-event weeks (the final weekend
		## runs 2 races at the same week), we must evaluate advancement from the LAST same-week
		## race — otherwise the first race sees the second sharing its gk_round and never advances,
		## so the season would not complete.
		var this_gk_round = -1
		var next_gk_round = -1
		for i in range(gk_cal.size()):
			if gk_cal[i]["week"] == current_week:
				this_gk_round = gk_cal[i].get("gk_round", -1)
				## Look past ALL same-week races to the next different week's race.
				var j = i + 1
				while j < gk_cal.size() and gk_cal[j]["week"] == current_week:
					j += 1
				if j < gk_cal.size():
					next_gk_round = gk_cal[j].get("gk_round", -1)
				## don't break early on the first match — but since all same-week races share the
				## week, the gk_round of the last one is what matters; keep scanning to the last.
		## If last race of a gk_round (next is different or doesn't exist)
		if this_gk_round > 0 and next_gk_round != this_gk_round:
			gk_discipline.advance_round(all_drivers)
			_sync_gk_group0_to_standings()
			var new_round = gk_discipline.get_current_round()
			## Bug 9: only surface GK round notifications to the player if they are
			## actually registered in GK. The shadow world still advances above, but a
			## non-GK career (e.g. Rally) must not receive GK elimination/round messages.
			var player_in_gk = "C-001" in player_registered_championships
			if player_in_gk:
				var player_eliminated = true
				for did in player_team.drivers:
					if not gk_discipline.is_eliminated(did):
						player_eliminated = false
						break
				if player_eliminated and this_gk_round < 4:
					## S35.3: fire the elimination notice EXACTLY ONCE. Without the flag,
					## `player_eliminated` stays true at the end of every later round (eliminated
					## never clears mid-season), so a Round-1 exit re-announced "Season over for
					## GK" at Rounds 2 and 3 — irrelevant duplicates (the player is already out).
					if not gk_discipline.player_elimination_announced:
						gk_discipline.player_elimination_announced = true
						add_notification("High",
							"🏁 Your driver was eliminated at the end of GK Round %d. Season over for GK." % this_gk_round,
							"", "gk_player_eliminated")
				elif this_gk_round >= 4 or gk_discipline.is_complete():
					## S28.3 (Bug 2): Round 4 is the final — no "Round 5". Announce the champion.
					var champ = gk_discipline.get_champion()
					if not champ.is_empty():
						var cd = all_drivers.get(champ.get("driver_id", ""), null)
						var cname = cd.full_name() if cd else "Unknown"
						add_notification("Normal",
							"🏆 GK Championship complete — Champion: %s (%d pts)." % [cname, champ.get("points", 0)])
					else:
						add_notification("Normal", "🏁 GK Championship complete for the season.")
				elif not player_eliminated and new_round <= 4:
					add_notification("Normal",
						"✅ GK Round %d complete — advancing to Round %d!" % [this_gk_round, new_round])

	## After all races processed this week — show first result screen
	if not _pending_race_results.is_empty():
		## S35.3: a skip that hits a player race is interrupted here by the scene change, so the
		## skip loop's post-loop flag reset never runs. Clear it here too so it can't stick true.
		simulating_to_season_end = false
		## Load the first result snapshot into last_race_* vars for RaceResults to read
		_apply_pending_race_snapshot(_pending_race_results[0])
		get_tree().change_scene_to_file("res://scenes/RaceResults.tscn")
		return  ## Don't continue advance_week processing until results are viewed

	## P31: Check for TP proposals (consolidated, roster-change-gated)
	_check_tp_proposal_notifications()

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
	_race_simulator.apply_weekly_fitness_recovery()

func _simulate_race(race_data: Dictionary, champ: Championship = null) -> void:
	_race_simulator.simulate_race(race_data, champ)

func _update_driver_stats_after_race(driver: Driver, standing_position: int, laps: int, is_wet: bool, grid_size: int, track_id: String = "") -> void:
	_race_simulator._update_driver_stats_after_race(driver, standing_position, laps, is_wet, grid_size, track_id)

func _update_staff_stats_after_race(_laps: int, track_id: String = "") -> void:
	_race_simulator._update_staff_stats_after_race(_laps, track_id)

func _end_season() -> void:
	_season_manager.end_season()

func start_new_season() -> void:
	_season_manager.start_new_season()

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
		"C-001": [1200.0, 600.0, 300.0],  ## per-race prizes
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
		var entry = {
			"round": race["round"],
			"name": race["name"],
			"week": race["week"],
			"rain_probability": race["rain"],
			"laps": race["laps"],
			"lap_km": race.get("lap_km", 1.0),
			"audience": race["audience"],
		}
		## Preserve GK round/elimination flags so the final-weekend cut can detect the Semi-Final.
		if race.has("gk_round"): entry["gk_round"] = race["gk_round"]
		if race.has("is_semifinal"): entry["is_semifinal"] = race["is_semifinal"]
		if race.has("is_final"): entry["is_final"] = race["is_final"]
		champ.calendar.append(entry)
	champ.num_races = champ.calendar.size()
	return champ

func _regenerate_ai_team_cars(team) -> void:
	var driver_count = team.drivers.size()
	if driver_count == 0:
		return
	## Bug 9: use the team's ACTUAL championship, not a hardcoded GK (C-001).
	## Falls back to C-001 only if the team has no registered championship.
	var team_champ_id = "C-001"
	if team.active_championships.size() > 0:
		team_champ_id = team.active_championships[0]
	var champ_reg = CHAMPIONSHIP_REGISTRY.get(team_champ_id, {})
	var champ_disc = champ_reg.get("discipline", "GK")
	## Pit crew required for all disciplines except GK.
	var pit_required = PIT_CREW_REQUIRED.get(champ_disc, true)
	## Telemetry / car_type for the team's discipline (mirrors CHAMP_CAR_TYPE in CarManager).
	const CHAMP_CAR_TYPE = {
		"C-001": "A_01",
		"C-005": "A_05", "C-006": "A_05", "C-007": "A_05", "C-008": "A_05",
		"C-009": "A_09", "C-010": "A_09",
		"C-011": "A_11", "C-012": "A_11", "C-013": "A_11",
		"C-014": "A_14", "C-015": "A_14", "C-016": "A_14", "C-017": "A_14",
		"C-018": "A_18", "C-019": "A_18", "C-020": "A_18",
		"C-021": "A_21", "C-022": "A_21", "C-023": "A_21", "C-024": "A_21",
	}
	var car_type = CHAMP_CAR_TYPE.get(team_champ_id, "A_01")
	for i in range(driver_count):
		var car = Car.new()
		car.id = "CAR-%s-%03d" % [team.id, i + 1]
		car.car_type_id = car_type
		car.championship_id = team_champ_id
		car.car_number = i + 1
		car.car_name = ""
		car.driver_id = team.drivers[i] if i < team.drivers.size() else ""
		car.mechanic_id = ""
		car.pit_crew_id = "" if pit_required else "N/A"
		car.condition = 100.0
		car.part_conditions = {"Aero": 100.0, "Engine": 100.0, "Gearbox": 100.0,
			"Suspension": 100.0, "Brakes": 100.0, "Chassis": 100.0}
		var telemetry = CAR_TELEMETRY.get(car_type, CAR_TELEMETRY.get("A_01", {}))
		if not telemetry.is_empty():
			car.top_speed = telemetry["top_speed"]
			car.acceleration = telemetry["acceleration"]
			car.deceleration = telemetry["deceleration"]
			car.cornering_grip = telemetry["cornering_grip"]
			car.fuel_consumption_per_km = telemetry["fuel_per_km"]
			car.tire_wear_rate = telemetry["tire_wear"]
			car.baseline_performance_index = telemetry["perf_index"]

## _process_off_season() — REMOVED: now lives in SeasonManager.gd (P57)

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
		"retired_personnel": retired_personnel,
		"player_registered_championships": player_registered_championships,
		"next_season_registrations": next_season_registrations,
		"sponsor_no_points_streak": sponsor_no_points_streak,
		"active_sponsor": active_sponsor,
		"player_team": {
			"id": player_team.id,
			"team_name": player_team.team_name,
			"balance": player_team.balance,
			"reputation": player_team.reputation,
			"drivers": player_team.drivers,
		},
		"team_color_primary": team_color_primary.to_html(),
		"team_color_secondary": team_color_secondary.to_html(),
		"all_teams": [],
		"all_drivers": {},
		## Save standings for EVERY championship (keyed by id), not just the singular
		## active_championship (= GK). The weekly race loop simulates all championships, so all
		## of them accrue standings — persisting only one dropped the other 20 on save (Bug #31).
		"championships": _serialize_all_championship_standings(),
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
		"team_refused_subjects":     team_refused_subjects,
		"pending_staff_assignments": pending_staff_assignments,
		"active_approaches":         active_approaches,
		"reputation_legacy_bonuses": reputation_legacy_bonuses,
		"history_balance":           history_balance,
		"history_fuel_price":        history_fuel_price,
		"history_economy":           history_economy,
		"history_active_fans":       history_active_fans,
		"history_merchandise":       history_merchandise,
		"history_reputation":        history_reputation,
		"current_loan_rate":         current_loan_rate,
		"economy_index":             economy_index,
		"economy_momentum":          _economy_momentum,
		"sp_market_pressure":        sp_market_pressure,
		"active_loans":              active_loans,
		"loan_next_id":              _loan_next_id,
		"consecutive_win_counts":    consecutive_win_counts,
		"gk_discipline":             gk_discipline.serialize() if gk_discipline else {},
		"custom_todo_items":         custom_todo_items,
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
			"is_shortlisted": d.is_shortlisted,
			"contract_seasons_remaining": d.contract_seasons_remaining,
			"weekly_salary":      d.weekly_salary,
			"win_bonus":          d.win_bonus,
			"podium_bonus":       d.podium_bonus,
			"championship_bonus": d.championship_bonus,
			"release_clause":     d.release_clause,
			"active_discipline": d.active_discipline,
			"discipline_change_season": d.discipline_change_season,
			"pace": d.pace,
			"car_control": d.car_control,
			"focus": d.focus,
			"race_craft": d.race_craft,
			"consistency": d.consistency,
			"feedback": d.feedback,
			"marketability": d.marketability,
			"fitness": d.fitness, "fatigue_resistance": d.fatigue_resistance,
			"potential": d.potential,
			"aggression": d.aggression,
			"experience": d.experience,
			"morale": d.morale, "is_cadet": d.is_cadet, "academy_team": d.academy_team, "contract_type": d.contract_type, "academy_upkeep_income": d.academy_upkeep_income,
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
	retired_personnel = data.get("retired_personnel", [])  ## S28 — default for old saves
	player_registered_championships = data.get("player_registered_championships", [])  ## S28.1
	next_season_registrations = data.get("next_season_registrations", [])  ## S28.1 ledger
	## S28.3 (Bug 5): persist team colors. Default to current values for old saves.
	if data.has("team_color_primary"):
		team_color_primary = Color(data["team_color_primary"])
	if data.has("team_color_secondary"):
		team_color_secondary = Color(data["team_color_secondary"])
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
	team_refused_subjects = data.get("team_refused_subjects", {})  ## S35.9 — default for old saves
	if "pending_staff_assignments" in data: pending_staff_assignments = data["pending_staff_assignments"]
	if "active_approaches"         in data: active_approaches         = data["active_approaches"]
	if "reputation_legacy_bonuses" in data: reputation_legacy_bonuses = data["reputation_legacy_bonuses"]
	if "history_balance"           in data: history_balance           = data["history_balance"]
	if "history_fuel_price"        in data: history_fuel_price        = data["history_fuel_price"]
	if "history_economy"           in data: history_economy           = data["history_economy"]
	if "history_active_fans"       in data: history_active_fans       = data["history_active_fans"]
	if "history_merchandise"       in data: history_merchandise       = data["history_merchandise"]
	if "history_reputation"        in data: history_reputation        = data["history_reputation"]
	if "current_loan_rate"         in data: current_loan_rate         = data["current_loan_rate"]
	if "economy_index"             in data: economy_index             = float(data["economy_index"])
	if "economy_momentum"          in data: _economy_momentum         = float(data["economy_momentum"])
	## S35.5 — SP market pressure; default 1.0 (neutral) for saves predating it.
	sp_market_pressure = float(data.get("sp_market_pressure", 1.0))
	if "active_loans"              in data: active_loans              = data["active_loans"]
	if "loan_next_id"              in data: _loan_next_id             = data["loan_next_id"]
	if "consecutive_win_counts"    in data: consecutive_win_counts    = data["consecutive_win_counts"]
	## Legacy save compat: old 3-state economy saves had no economy_index
	if not "economy_index" in data:
		var old_state = data.get("global_economy_state", "Normal")
		economy_index = 15.0 if old_state == "Recession" else (85.0 if old_state == "Boom" else 50.0)
	## P26: GK Discipline
	if gk_discipline == null:
		gk_discipline = GKDiscipline.new()
	if "gk_discipline" in data and not data["gk_discipline"].is_empty():
		gk_discipline.deserialize(data["gk_discipline"])
	if "custom_todo_items" in data: custom_todo_items = data["custom_todo_items"]

	# Restore championship standings (all championships, keyed by id — see _serialize_all_…).
	_setup_championship()
	_deserialize_all_championship_standings(data.get("championships", {}))

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
		d.is_shortlisted = dd.get("is_shortlisted", false)  ## S35.10 — default for old saves
		d.contract_seasons_remaining = dd.get("contract_seasons_remaining", 0)
		d.weekly_salary       = dd.get("weekly_salary", 0.0)
		d.win_bonus           = dd.get("win_bonus", 0)
		d.podium_bonus        = dd.get("podium_bonus", 0)
		d.championship_bonus  = dd.get("championship_bonus", 0)
		d.release_clause      = dd.get("release_clause", 0)
		d.active_discipline = dd["active_discipline"]
		d.discipline_change_season = dd["discipline_change_season"]
		d.pace = dd["pace"]
		d.car_control = dd.get("car_control", dd.get("wet", 50.0))
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
		d.track_knowledge          = dd.get("track_knowledge", {})
		d.contract_type            = dd.get("contract_type", "professional")
		d.academy_upkeep_income    = dd.get("academy_upkeep_income", 0)
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
	## S35.6 — staff/team restored; rebuild the player-staff cache from the loaded roster.
	invalidate_player_staff_cache()
	## P57: Initialize SeasonManager
	_season_manager = SeasonManager.new(self)
	## P57: Initialize FinancialEngine
	_financial_engine = FinancialEngine.new(self)
	## P57: Initialize RaceSimulator
	_race_simulator = RaceSimulator.new(self)
	## P57: Initialize ContractEngine
	_contract_engine = ContractEngine.new(self)
	_rnd_engine = RnDEngine.new(self)
	_notification_manager = NotificationManager.new(self)
	_campus_manager = CampusManager.new(self)
	emit_signal("week_advanced", current_week)
	emit_signal("log_updated")

## ═══════════════════════════════════════════════════════════════════════════
## SERIALIZATION HELPERS
## ═══════════════════════════════════════════════════════════════════════════

## ═══════════════════════════════════════════════════════════════════════════

## Serialize standings for ALL championships, keyed by championship id. (Fix #31 — the weekly
## loop simulates every championship, so every championship accrues standings; we must persist
## them all, not just the singular active_championship.)
func _serialize_all_championship_standings() -> Dictionary:
	var out: Dictionary = {}
	for champ in active_championships:
		out[champ.id] = {
			"current_round": champ.current_round,
			"standings": champ.standings,
			"team_standings": champ.team_standings,
		}
	return out

## Restore standings into each championship by id. Championships are freshly created by
## _setup_championship() before this runs, so any id missing from the save simply keeps its
## empty starting standings.
func _deserialize_all_championship_standings(saved: Dictionary) -> void:
	for champ in active_championships:
		var entry = saved.get(champ.id, {})
		if entry.is_empty(): continue
		champ.current_round = entry.get("current_round", 0)
		champ.standings = entry.get("standings", {})
		champ.team_standings = entry.get("team_standings", {})

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
			"delivered": car.delivered, "delivery_week": car.delivery_week,
			"acquisition": car.acquisition,
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
		## Phase 2 delivery state. Older saves predate these keys → default to a
		## delivered/legacy-safe state so a loaded car is never silently held in build.
		car.delivered     = cd.get("delivered", true)
		car.delivery_week = cd.get("delivery_week", 0)
		car.acquisition   = cd.get("acquisition", "delivered")
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
			"is_shortlisted": s.is_shortlisted,
			"assigned_championship": s.assigned_championship,
			"assigned_car_id": s.assigned_car_id,
			"discipline_adaptation": s.discipline_adaptation,
			# Role attributes
			"car_setup": s.car_setup, "pit_stops": s.pit_stops,
			"parts_knowledge": s.parts_knowledge, "track_knowledge": s.track_knowledge,
			"pit_stop_speed": s.pit_stop_speed, "repair_skill": s.repair_skill,
			"fitness": s.fitness, "fatigue_resistance": s.fatigue_resistance,
			"race_strategy": s.race_strategy, "practice_management": s.practice_management,
			"qualifying_management": s.qualifying_management,
			"race_pace_reading": s.race_pace_reading,
			"car_setup_oversight": s.car_setup_oversight,
			"pit_stop_management": s.pit_stop_management, "pr_skill": s.pr_skill,
			"loan_management": s.loan_management, "speculation": s.speculation,
			"sales_skill": s.sales_skill, "sponsor_negotiation": s.sponsor_negotiation,
			"resource_management": s.resource_management, "budget_planning": s.budget_planning,
			"engine": s.engine, "aero": s.aero, "brakes": s.brakes,
			"suspension": s.suspension, "chassis": s.chassis, "gearbox": s.gearbox,
			"reliability": s.reliability,
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
		s.is_shortlisted = sd.get("is_shortlisted", false)  ## S35.10 — default for old saves
		s.assigned_championship = sd["assigned_championship"]
		s.assigned_car_id = sd["assigned_car_id"]
		s.discipline_adaptation = sd["discipline_adaptation"]
		s.car_setup = sd.get("car_setup", 0.0)
		s.pit_stops = sd.get("pit_stops", 0.0)
		s.parts_knowledge = sd.get("parts_knowledge", sd.get("car_knowledge", 0.0))
		s.track_knowledge = sd.get("track_knowledge", 0.0)
		s.pit_stop_speed = sd.get("pit_stop_speed", 0.0)
		s.repair_skill = sd.get("repair_skill", 0.0)
		s.fatigue_resistance = sd.get("fatigue_resistance", sd.get("teamwork", 0.0))
		s.fitness = sd.get("fitness", 100.0)
		s.race_strategy = sd.get("race_strategy", 0.0)
		s.practice_management = sd.get("practice_management", 0.0)
		s.qualifying_management = sd.get("qualifying_management", 0.0)
		s.race_pace_reading = sd.get("race_pace_reading", 0.0)
		s.car_setup_oversight = sd.get("car_setup_oversight", 0.0)
		s.pit_stop_management = sd.get("pit_stop_management", 0.0)
		s.pr_skill = sd.get("pr_skill", 0.0)
		s.loan_management = sd.get("loan_management", 0.0)
		s.speculation = sd.get("speculation", sd.get("interest_rates", 0.0))
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
		"desc":  "Default start — GK Championship, CR 50K, blank slate.",
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
func _apply_pending_race_snapshot(snap: Dictionary) -> void:
	last_race_round          = snap.get("round", 0)
	last_race_laps           = snap.get("laps", 0)
	last_race_name           = snap.get("name", "")
	last_race_wet            = snap.get("is_wet", snap.get("wet", false))
	last_race_results        = snap.get("results", [])
	last_race_championship   = snap.get("championship", "")
	last_race_championship_id = snap.get("championship_id", "")
	last_race_num_races      = snap.get("num_races", 0)
	last_race_standings      = snap.get("standings", [])
	last_race_staff_deltas   = snap.get("staff_deltas", [])

## Called by RaceResults Continue button.
## If more races queued → show next result. Otherwise → return to MainHub.
## Returns true if another result was loaded (caller should go to RaceResults again).
## Returns false if queue is empty (caller should go to MainHub).
func consume_next_race_result() -> bool:
	if _pending_race_results.is_empty(): return false
	_pending_race_results.remove_at(0)
	if _pending_race_results.is_empty(): return false
	_apply_pending_race_snapshot(_pending_race_results[0])
	return true

func shadow_standings_has_group_0(cid: String) -> bool:
	if gk_discipline == null: return false
	if cid != "C-001": return false
	return gk_discipline.get_standings(cid).size() > 0

## ═══════════════════════════════════════════════════════════════════════════
## TP AUTO-ASSIGNMENT PROPOSALS (S23)
## ═══════════════════════════════════════════════════════════════════════════
##
## Generates a complete, ready-to-apply assignment plan for all cars/championships.
## Priority rules:
##   1. Sort championships by prestige (tier × discipline weight — GP > EPC > SC > OWC > TC > Rally > GK)
##   2. Assign best driver (by effective skill = raw × adaptation/100) to highest-prestige car first
##   3. GK multi-tier: same driver/mechanic can cover multiple GK cars IF no same-week different-track conflict
##   4. Non-GK: one driver per car, no cross-championship sharing
##   5. If no driver available → DNS warning proposal item
##   6. Cross-discipline assignment → adaptation warning in proposal

## Discipline prestige weights for priority sorting (higher = more important)
const DISC_PRESTIGE: Dictionary = {
	"GP": 7, "EPC": 6, "SC": 5, "OWC": 4, "TC": 3, "Rally": 2, "GK": 1
}

## ═══ TP PROPOSAL ENGINE — delegated to TPProposalEngine.gd (S27) ═══

func generate_tp_assignment_proposals() -> Array:
	return _tp_engine.generate_tp_assignment_proposals()

## Compute the player's proposals WITHOUT firing a notification/TDL. For read-only display
## (e.g. the Racing Dept panel) — calling generate_tp_assignment_proposals() there would
## re-fire the TP notification + TDL every time the panel is built.
func peek_tp_proposals() -> Array:
	return _tp_engine.compute_optimal_assignments(player_team, player_team_cars, false)

func _effective_stat(driver, disc: String, stat: String) -> float:
	return _tp_engine._effective_stat(driver, disc, stat)

func _effective_stat_staff(staff, disc: String, stat: String) -> float:
	return _tp_engine._effective_stat_staff(staff, disc, stat)

func _find_best_driver_for_car(car, disc: String, avail_drivers: Array, committed: Dictionary, car_races: Array, is_gk: bool) -> Dictionary:
	return _tp_engine._find_best_driver_for_car(car, disc, avail_drivers, committed, car_races, is_gk)

func _find_best_mechanic_for_car(car, disc: String, avail_mechanics: Array, committed: Dictionary, car_races: Array, is_gk: bool) -> Dictionary:
	return _tp_engine._find_best_mechanic_for_car(car, disc, avail_mechanics, committed, car_races, is_gk)

func _build_dns_proposals(car_races: Array, committed: Dictionary, avail_drivers: Array) -> Array:
	return _tp_engine._build_dns_proposals(car_races, committed, avail_drivers)

func _fire_tp_proposal_notification(proposals: Array) -> void:
	_tp_engine._fire_tp_proposal_notification(proposals)

func apply_tp_proposals(proposals: Array) -> void:
	_tp_engine.apply_tp_proposals(proposals)

func get_tp_proposals_all() -> Array:
	return _tp_engine.get_tp_proposals_all()

func _find_best_unassigned_staff_for_gk():
	return _tp_engine._find_best_unassigned_staff_for_gk()

func _find_best_unassigned_staff(role: String, champ_id: String):
	return _tp_engine._find_best_unassigned_staff(role, champ_id)

func _check_tp_proposal_notifications() -> void:
	_tp_engine._check_tp_proposal_notifications()

func _take_tp_roster_snapshot() -> Dictionary:
	return _tp_engine._take_tp_roster_snapshot()

func _tp_roster_changed() -> bool:
	return _tp_engine._tp_roster_changed()

func _fire_assignment_proposals() -> void:
	_tp_engine._fire_assignment_proposals()

func get_loan_tier() -> int:
	return _financial_engine.get_loan_tier()

func get_max_loan_amount(tier: int = -1) -> float:
	return _financial_engine.get_max_loan_amount(tier)

func get_loan_rate() -> float:
	return _financial_engine.get_loan_rate()

func get_max_loan_slots() -> int:
	return _financial_engine.get_max_loan_slots()

func _calc_weekly_payment(principal: float, annual_rate: float, n_weeks: int) -> float:
	return _financial_engine._calc_weekly_payment(principal, annual_rate, n_weeks)

func take_loan(amount: float, seasons: int) -> String:
	return _financial_engine.take_loan(amount, seasons)

func repay_loan_early(loan_id: int) -> String:
	return _financial_engine.repay_loan_early(loan_id)

func _process_loans_weekly() -> void:
	_financial_engine.process_loans_weekly()

## ═══════════════════════════════════════════════════════════════════════════
## FINANCIAL HELPERS — delegated to FinancialEngine (S27)
## ═══════════════════════════════════════════════════════════════════════════

func _calculate_company_value() -> float:
	return _financial_engine.calculate_company_value()

## Legacy helper used by HQ — now delegates to get_max_loan_amount().
func _calculate_max_loan() -> float:
	return get_max_loan_amount()

func _update_ceo_salary() -> void:
	_financial_engine.update_ceo_salary()

func _process_supply_contracts_weekly() -> void:
	_financial_engine.process_supply_contracts_weekly()

func _process_supply_contracts_season_end() -> void:
	_financial_engine.process_supply_contracts_season_end()
