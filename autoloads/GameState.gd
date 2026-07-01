## Version: S40.1 — LEAD DESIGNER REWORK (thread #6) wiring: declared + instantiated
## Version: S40.13 — P4 accessor delegations: rnd_perf_bonus / rnd_reliability_bonus / rnd_fatigue_bonus
##   / rnd_tax_reduction / rnd_maintenance_reduction / rnd_passive_income_bonus (→ RnDEngine cluster getters).
##   _lead_designer_engine (LeadDesignerProposalEngine) in all init paths; _last_design_proposals
##   cache; public delegations (generate/peek/apply_design_proposals + get_design_line_capacity /
##   get_free_design_lines / get_lead_designer_id / can_run_rnd). Engine logic lives in RnDEngine
##   (capacity = Studio level, C=f(skill), soft over-stretch penalty on quality AND speed) and the
##   new LeadDesignerProposalEngine (advisor proposals, mirrors TPProposalEngine). UI rework of the
##   R&D Studio "free designer" picker + the JSON surgery (3098→172+~100 FAs) are SEPARATE sessions.
## Version: S40.0 — Phase 3 tail: (1) market-share milestone NEWS (10/20/30/50%) per active segment via
##   _check_commercial_share_milestones in the weekly tick; ledger commercial_share_milestone_hit saved/
##   loaded/reset. (2) No-CFO TDL row now appends an informative "Financial Department is not
##   optimized." note to the existing CFO line (in NotificationManager).
## Version: S39.7 — commercial model naming + Facelift/Next-Gen as R&D mini-projects: start_commercial_refresh, pending_commercial_rename (saved/loaded), build_commercial_line takes a chosen name
## Version: S39.6 — stop_commercial_line API (frees line, keeps blueprint)
## Version: S39.5 — commercial_line_economics single source of truth (net matches FinancialEngine + UI); segment-unlock now Studio-level based (racing gate removed); build_commercial_line racing check removed
## Version: S38.7 — News/notification routing fix (per design owner): segment-UNLOCK breadcrumb →
##   notification (event), not news; START OF PRODUCTION (build_commercial_line) → news (a team
##   entering a market). Blueprint-research-complete stays a notification (RnDEngine).
## Version: S38.5 — Pillar-5 commercial models: championships_ever_raced ledger (permanent unlock
##   breadcrumb; recorded at new-game/season-activation, saved/loaded, backfilled on old saves) +
##   unlock notification. Commercial line API: build_commercial_line / facelift / nextgen /
##   set_commercial_marketing + is_commercial_segment_unlocked / _blueprint_researched /
##   commercial_free_lines. RnDEngine holds the 12 P5 blueprints; this owns the lines they create.
## Version: S38.4 — Economy RE-TUNE (GDD §4.5, Option A): replaced the flat mean-reversion-to-50 drift
##   in _update_economy_and_fuel with a slow ~5-season sine regime (centre ~28..72) + light noise +
##   rare shocks, pulling the index toward the moving regime centre. The index now genuinely reaches
##   Boom(>70)/Recession(<30) ~3–4× each per 25-season career (~92% Normal), reviving the dormant
##   fuel/loan/speculation systems AND the commercial demand swings. _economy_phase0 desyncs careers;
##   saved/loaded (pre-S38.4 saves get a fresh phase). Boom/recession state notifications now fire.
## Version: S38.3 — Phase 3 cap anchor: rolling 4-week racing-income window (sponsors + race prizes
##   + EOS) via register_racing_income() at every payout (RaceSimulator prize, all 5 SponsorManager
##   sites) + get_avg_weekly_racing_income(); FinancialEngine's Factory 2× cap now tracks TOTAL
##   racing income, not sponsor-only. Window saved/loaded. Also S38.2: commercial_lines + weekly
##   market tick + CFO sales_factor; S38.1: owns/persists CommercialMarketSim.
## Version: S38.1 — Phase 3 wiring: GameState now owns CommercialMarketSim (_commercial_market).
##   Instantiated in _ready (restored via load) and in setup_new_game (seed_market(true) → staggered
##   mid-life AI models). Serialized into save under "commercial_market"; load restores it, or seeds a
##   fresh market for pre-Phase-3 saves so an in-progress career still gains the road-car industry.
##   No income/UI yet — FinancialEngine (next) reads the engine's credits.
## Version: S37.64 — Week divider removed from NEWS (empty "--- Week N ---" lines were noise);
##   weekly dividers stay in the operational log only.
## Version: S37.63 — NEWS vs LOG split: added news_feed (curated world-news the NEWS panel renders)
##   + log_news(); operational chatter stays on add_log/weekly_log. news_feed persists across weeks
##   (capped 60), clears per season, saved/loaded. Week divider routed to news.
## Version: S37.61 — Bug #38 CREW MODEL: new-game registers only the seat-0 representative; added
##   crew_label_for_driver() ("Smith / Jones") for standings/results display.
## Version: S37.60 — Bug #38 (multi-driver per car): Car.driver_ids[] is canonical; save/load
##   serializes driver_ids with legacy-driver_id migration; new-game provisions a FULL crew
##   (Rally/TC=2, EPC=3) and seats them; AI regen + readiness TDL are seat-aware. ALSO:
## Version: S37.60 — Added get_gk_final_json_round(): the JSON's highest GK round (for the Results
##   screen to fetch the remapped city for the GK Grand Final, since the engine adds a round 22 the
##   JSON doesn't have). No persisted-state change.
## Version: S37.59 — Added get_calendar_city(cid, round): UI helper that returns the display city
##   for a championship+round from race_calendar.json, so the Main Hub can show JSON place names
##   instead of the engine constant's branded names. Engine race logic unchanged.
##   (S37.60) Added get_gk_final_json_round(): the JSON's highest GK round, used by the Results screen
##   to fetch the remapped city for GK's engine-only Grand Final (engine round 22 ∉ 21-round JSON).
## Version: S37.56 — Removed the temporary S37.53 #22 diagnostic (_debug_dump_championship_rosters)
##   now that the engine roster build from teams.json is verified. No functional change vs S37.50.
## Version: S37.50 — NEW-GAME provisioning fixes (_give_starting_assets): (1) Ops Sim key typo —
##   "Ops Sim" → "Ops Sim & Telemetry" (the real key everywhere else), so SC Dev / GP4 actually
##   build the Ops Sim building at start and the starting Race Strategist gets its slot (the
##   strategist was created but stranded — no building = no slot). (2) GP now also starts with the
##   R&D Design Studio + CNC Parts Plant built AND a starting Designer (team-level, R&D-Studio slot),
##   so a GP4 career can design+produce parts from week 1. Budgets were tuned manually for the upkeep.
## Version: S37.47 — LIVING WORLD: wired the new AIChampionshipSim engine into the weekly race loop.
##   Non-player, non-GK championships now run a lightweight result model each race week (else-branch
##   of is_player_champ; GK excluded), so their standings populate and Racing World / EOS show real
##   champions. Restores the world that the S37.43 Bug-3 fix had inadvertently left empty (it stopped
##   awarding AI points), WITHOUT re-introducing the DNS spam. Engine declared + instantiated at all
##   3 init sites. (Place AIChampionshipSim.gd in resources/scripts/ for class_name registration.)
##   Also carries the S37.46 notification migration (below).
## Version: S37.46 — Notification & News Roadmap, Phase 3 (events→notify_event). All ~24 GameState
##   notifications migrated: 3 → "news" (drivers + constructors titles, GK champion); 4 → "standing"
##   (economy state, fuel shock, GK player-eliminated, registration deadline — collapse via subject);
##   6 → show_popup (build-car errors: missing blueprints / garage full / insufficient funds;
##   strategist-not-in-GK; already-assigned; binding-registration on unregister attempt); screenshot
##   notification DELETED (log-only); autosave → "event" (non-blocking panel notice, no toast channel
##   exists); rest → "event" (car delivered/in-build, registration warn/confirm, formula-design,
##   WRA-reset, counter-offer, GK round complete). Framework add_notification (notify_event impl) kept.
## Version: S37.41 — Added "pit_arena" to NOTIFICATION_DESTINATIONS/_LABELS (Phase 3: CarManager's
##   pit-crew-DNS event routes there).
## Version: S37.39 — DRAFT negotiations: discard_draft_negotiation() wrapper; save strips draft
##   approaches from active_approaches so an un-acted draft never persists.
## Version: S37.38 — clear_all_notifications() wrapper (Main Hub "Delete All").
## Version: S37.37 — show_popup() added: shared AcceptDialog for on-the-spot blocking-error feedback
##   (Notification & News Roadmap, Phase 0). Engines/scenes call gs.show_popup(message, title);
##   parented to get_tree().current_scene so RefCounted engines can pop it. Phase 1 (started):
##   buy_fuel / buy_spare_parts / buy_part insufficient-funds + no-cost-data errors now pop on the
##   spot instead of routing to the notification panel. show_popup guards against stacking (one modal
##   at a time; bulk-buy failures fold into a single dialog). register_for_championship guards
##   (unknown ID / already registered / deadline passed / cannot afford fee) also pop. Remaining
##   blocking errors migrate next.
## Version: S37.34 — pending_campus_zone (transient): Campus restores the last-viewed zone tab when
##   returning from a building (set in _show_zone, read in _ready). new-game reset + load clear.
## Version: S37.32 — Part purchase prices: load res://data/part_costs.json (Excel CNC base costs ×
##   manufacturer profit 8% × quality 1.0) via get_part_unit_price/get_part_prices; buy_part uses
##   it. Fixes the 'buying parts doesn't deduct credits' bug (hardcoded PART_COSTS had GK at 0).
## Version: S37.29 — #52 full audit: ALL 129 GameState vars cross-checked vs the 3 state handlers.
##   Added save/load + new-game resets for the remaining leaks: WRA pipeline (active_wra_submissions,
##   wra_approved/rejected_blueprints), bankruptcy counters (weeks_in_negative, bankruptcy_screen_shown),
##   dismissed_todo_items, ceo_accumulated_salary, and player identity (player_name/nationality/ceo_*/
##   game_difficulty). See GDD 'State Handler Checklist' — every new persistent var must touch all three.
## Version: S37.28 — #52 fix: setup_new_game now clears leaked session state (sponsors/offers/
##   approaches/notifications/SP/fuel/pending_* + fresh GK); load_game clears transient routing and
##   restores notifications (now also saved). Prevents New-Game state leak + cross-load bleed.
## Version: S37.26 — Calendar: race_calendar.json loader (_load_race_calendar) +
##   custom_calendar_events store (save/load/new-game reset) + get_calendar_manager()
##   accessor (preload-based, no class_name dependency).
## Version: S37.19 — #50: _setup_part_inventory() removed the 3 free starting parts (seeds EMPTY)
##   and fixed a GK relic (seeded active_championship=legacy GK; now seeds the player's real
##   starting + car championships).
## Version: S37.16 — #41: assign_driver_to_car() wrapper now propagates the String result.
extends Node
## Version: S37.22 — #40 TP/Strategist manual assignment: assign_staff_to_championship() now
##   applies IMMEDIATELY (was queued to 'next week' → assigned_championship stayed stale → HQ card
##   showed the old series → non-GK championship read as no-TP → DNS → soft-locked into GK). Added
##   per-role slot guard + strategist GK/Rally block + clear_stranded_player_championship_staff()
##   (rollover auto-unassign of player TP/Strategist on a no-longer-raced championship).
## Version: S37.15 — #18 hidden-gems: talent_scouting added to staff save/load serialization.
## Version: S37.10 — (1) Sponsor system: added _process_sponsor_annual_payments() wrapper (commitment
##   sponsors pay/penalise at season start) and pending_race_result_count() (Skip button). (2) Save/
##   load now persist active_sponsors + sponsor_offers (previously NOT saved — a signed multi-season
##   commitment vanished on reload). Back-compatible with older saves (defaults to empty).
## Version: S37.9 — Added cancel_renegotiation_by_subject_name() wrapper for the TDL X button on
##   player-initiated renegotiation rows (removes an un-submitted round-1 renegotiation approach).
## Version: S37.8 — Registration-deadline notification: widened the trigger from exactly "1 week
##   out" to "this week OR next" (dl_gap 0 or 1) so a week-step can't slip past it, fires for ALL
##   championships regardless of budget (player funds it however they like), and added an add_log()
##   line ("🔔 Registration deadline imminent...") so the weekly log gives definitive proof it fired.
##   (The block was already relocated before the race-result early-return in S37.7.)
## Version: S37.7 — Notification framework (1-event model) + two real fixes. Added notify_event()
##   with modes once/standing/event/news (NotificationManager) and wrappers here. (1) CFO: the
##   per-RACE "No CFO" emitter in RaceSimulator (the actual W10/W12 spam source) is removed; CFO is
##   now a read-only TO-DO row + ONE notify_event("no_cfo", once) with a Staff-screen button.
##   (2) ROOT CAUSE of "no deadline / erratic CFO notifications": both blocks sat AFTER the
##   race-result early-return in advance_week(), so on any week the player raced they were skipped.
##   Moved both BEFORE that return so they run every week. TO-DO list is read-only and never notifies.
## Version: S37.6 — Two notification fixes. (1) CFO hint: CFO is optional, so the recurring "No CFO"
##   TDL task was removed; a single one-time hint notification fires instead (cfo_hint_shown flag).
##   (2) Registration deadline: the warning never fired because the loop skipped any championship in
##   active_championships (= the whole 21-champ world → skipped everything). Removed that broken
##   skip; now ONE consolidated "closes next week" notification lists the championships whose
##   next-season deadline is one week out (skip only those already in the next-season ledger). No
##   4/2/1 tiering, no affordability filter.
## Version: S37.5 — Bug #20 revision: removed the affordability filter on deadline warnings (the
##   player can take a loan to cover an entry-fee gap, so a cash shortfall must not hide a deadline)
##   — now warns for every championship whose deadline is still open. Added repair_car_max_sp()
##   wrapper (proportional all-SP repair for the Garage button).
## Version: S37.4 — Bug #20: registration-deadline warnings reworked. Was a single-week blip
##   (fired only when deadline == week+1), easily missed — now a tiered window (4 / 2 / 1 weeks +
##   last day) with a per-championship subject (collapses to one standing notice, no spam), and
##   GATED to championships the player can actually register for (affordable + deadline open) so
##   the panel isn't flooded with out-of-budget series. Added repair_car_affordable() +
##   get_affordable_repair_pct() wrappers for the new "repair what I can afford" buttons.
## Version: S37.1 — CP4 follow-up: fixed "GK is still there" for non-GK careers. Root cause was in
##   GKDiscipline.populate_season(), which forced ALL player drivers into GK group 0 regardless of
##   discipline — so a GP4 player still had a driver in GK's standings, and the weekly loop both
##   ran the player's "GK race" AND queued a GK result screen. Now: (1) GKDiscipline only seeds GK
##   group 0 with drivers that actually race GK (new player_in_gk flag); (2) the weekly loop skips
##   the real _simulate_race for C-001 when the player isn't in GK (the shadow sim covers group 0,
##   avoiding double-sim and the stray result screen); (3) the GK final weekend still resolves for
##   non-GK careers — the semifinal hook runs, and the collapsed Grand Final group is shadow-simmed
##   so the GK champion is decided by a real race. player_in_gk is persisted in save/load.
## Version: S37.0 — CP4 (closes cluster A): the singular active_championship getter now returns the
##   player's ACTUAL racing championship (first player_registered_championships entry → first owned
##   car's championship → legacy active_championships[0] → safe dummy) instead of always
##   active_championships[0] (= GK). This was the root of the "picked GP4 but saw GK races/results"
##   symptom: every legacy single-championship read (fuel/SP/condition, standings init, hiring gates)
##   silently resolved to GK. Paired edits this session: RaceSimulator threads the raced `champ`
##   through per-race fuel/SP/condition reads; DriverManager/ContractEngine stop writing newly-signed
##   drivers into GK standings (they join the correct championship at car assignment, per Rule #6 —
##   cars race, drivers are assigned to cars); CarManager reads SP rate per-car from each car's
##   championship. UI (active_championships plural / get_player_championships) is unaffected.
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
## S40.14 — balance snapshot at season start; seasonal profit = current balance − this. Basis for
## the end-of-season corporate tax. Saved/loaded/reset with the rest of the season state.
var season_start_balance: float = 0.0

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
## S37.47 AI Championship Sim — lightweight result model for non-player, non-GK championships
var _ai_championship_sim: AIChampionshipSim = null
## S38.1 Commercial Market Sim — Phase 3 road-car market engine (attractiveness/redistribution,
## 12 segments, lifecycle, demand). Pure RefCounted; GameState owns it and persists it via save/load.
var _commercial_market: CommercialMarketSim = null
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
## S40.0 — Lead Designer advisor: proposes blueprint queues for idle design lines (thread #6).
var _lead_designer_engine: LeadDesignerProposalEngine = null

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
		notify_event("drv_title_%s" % champ.id, "High",
			"🏆 %s wins Drivers Championship! Team +%.0f reputation." % [driver.full_name(), team_boost], "hq", "news")
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
		notify_event("con_title_%s" % champ.id, "High",
			"🏆 Constructors Championship won! Team +%.0f reputation." % team_boost, "hq", "news")
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
## Computed property — returns the player's ACTUAL racing championship (CP4, closes cluster A).
## Previously returned active_championships[0], which is ALWAYS GK (C-001) because the world
## always runs GK. That produced the "picked GP4 but saw GK races/results" symptom across every
## legacy single-championship call site (fuel/SP/condition reads, standings init, hiring gates).
##
## Resolution order (most-specific first):
##   1. The first championship the player is REGISTERED to race this season
##      (player_registered_championships — the authoritative "what I actually race" list).
##   2. The first championship the player owns a delivered/assigned car for (covers the brief
##      window during setup before registrations are activated, and car-only edge cases).
##   3. Any active championship (legacy fallback — keeps off-season-with-world-running safe).
##   4. A safe dummy Championship (off-season, nothing registered) to prevent null-access crashes
##      in building scenes and weekly processing.
## NOTE: this is still a SINGULAR convenience accessor for legacy single-champ sites. UI that must
## show ALL the player's entries uses get_player_championships(); the world loop uses
## active_championships directly. Neither is affected by this change.
var active_championship: Championship:
	get:
		# 1. The player's actual registered racing championship.
		for cid in player_registered_championships:
			var rc = get_championship_by_id(cid)
			if rc != null:
				return rc
		# 2. The championship of the first car the player owns (setup / car-only window).
		for car in player_team_cars:
			if car.championship_id != "":
				var cc = get_championship_by_id(car.championship_id)
				if cc != null:
					return cc
		# 3. Legacy fallback — any running championship (keeps off-season-with-world safe).
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

## S38.5 — Pillar-5 unlock breadcrumb ledger: every championship the player has EVER raced (persists
## across seasons/tier moves). Racing a championship with a Factory_Unlock permanently unlocks that
## segment's commercial blueprint — so a player who climbed past RALLY4 keeps Economy Hatchbacks.
var championships_ever_raced: Array = []

## Record current registrations into the permanent ever-raced ledger (call whenever the player's
## active registrations are (re)established — new game, season activation, mid-season registration).
func _record_ever_raced() -> void:
	for cid in player_registered_championships:
		if not cid in championships_ever_raced:
			championships_ever_raced.append(cid)
			## Unlock breadcrumb: if this championship unlocks a commercial segment, nudge the player.
			if _commercial_market != null:
				var seg: String = _commercial_market.segment_for_championship(cid)
				if seg != "":
					notify_event("commercial_unlock_%s" % seg, "Normal",
						"🏭 Racing %s unlocked the %s commercial segment — research its blueprint in the R&D Studio to build it on a Factory line." % [
							CHAMPIONSHIP_REGISTRY.get(cid, {}).get("name", cid),
							_commercial_market.segment_name(seg)], "rnd_studio", "event")
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
## S40.0 — cached Lead Designer proposals for the R&D Studio display (mirrors _last_tp_proposals).
var _last_design_proposals: Array = []
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
## S38.4 — random phase offset for the economy regime sine, so careers don't share a cycle.
## Set once at new-game; persisted in save/load.
var _economy_phase0:        float  = 0.0

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
## S38.2 — CFO sales_factor for commercial income & share growth (GDD §4.0).
## sales_factor = 0.75 + sales_skill/200  → 0.75 (no/weak CFO band) … 1.0 @50 … 1.25 @100.
## NO CFO → Factory is OFF (handled by FinancialEngine: full upkeep, zero output), so this returns
## the 0.75 floor only as a safe default; callers gate on get_cfo() != null first.
func get_commercial_sales_factor() -> float:
	var cfo := get_cfo()
	if cfo == null:
		return 0.75
	return 0.75 + cfo.sales_skill / 200.0

## S39.5 — Single source of truth for a line's weekly economics, so the Commercial Department preview
## and the Financial Department match what FinancialEngine.apply_commercial_income() actually applies
## (same 50K racing-income floor + 2× cap). Returns a breakdown the UI can show: demand/capacity/sales
## units, gross, marketing spend, and the capped net. Returns zeros if the line/segment isn't valid.
func commercial_line_economics(seg_key: String) -> Dictionary:
	var blank := {"demand": 0.0, "capacity": 0.0, "sales_units": 0.0, "share": 0.0,
		"gross": 0.0, "marketing": 0.0, "net": 0.0, "capped": false}
	if _commercial_market == null or get_cfo() == null:
		return blank
	var line: Dictionary = {}
	for l in commercial_lines:
		if l.get("segment", "") == seg_key:
			line = l; break
	if line.is_empty():
		return blank
	var factory = campus_buildings.get("Vehicle Assembly Factory", {})
	if not factory.get("built", false) or int(factory.get("level", 0)) < 1:
		return blank
	var lvl: int = int(factory.get("level", 1))
	var sf: float = get_commercial_sales_factor()
	var obonus: float = _rnd_engine.get_rnd_bonus("weekly_commercial_output")
	var share: float = _commercial_market.get_player_share(seg_key)
	var demand: float = _commercial_market.player_weekly_demand(seg_key, economy_index)
	var capacity: float = _commercial_market.line_capacity(lvl) * (1.0 + obonus)
	var sales_units: float = min(demand, capacity)
	var gross: float = _commercial_market.line_weekly_credits(seg_key, economy_index, lvl, sf, obonus)
	var recommended: float = _commercial_market.recommended_marketing(seg_key, economy_index, lvl, sf)
	var marketing: float = recommended * float(line.get("marketing", 1.0))
	var net: float = gross - marketing
	## Match the apply path: floor the racing reference at 50K, then cap net at 2× it.
	var racing_ref: float = max(get_avg_weekly_racing_income(), 50000.0)
	var cap: float = racing_ref * _commercial_market.FACTORY_CAP_MULT
	var capped := false
	if net > cap:
		net = cap; capped = true
	return {"demand": demand, "capacity": capacity, "sales_units": sales_units, "share": share,
		"gross": gross, "marketing": marketing, "net": net, "capped": capped}

## Total weekly commercial net across all lines (for the Financial Department summary).
func commercial_weekly_net_total() -> float:
	var t := 0.0
	for l in commercial_lines:
		t += float(commercial_line_economics(l.get("segment", "")).get("net", 0.0))
	return t


## S38.2 — Weekly commercial-market tick. Builds the player's per-segment inputs from the active
## production lines and advances the attractiveness/redistribution engine one week. Pure share
## dynamics only; credits are realized separately by FinancialEngine.process_weekly().
func _tick_commercial_market() -> void:
	if _commercial_market == null:
		return
	var sales_factor := get_commercial_sales_factor()
	## No CFO → the Factory produces nothing and earns no share growth (GDD §4.0): advance the
	## world market with NO player inputs so AI/giants still evolve, but the player stays static.
	var player_inputs: Dictionary = {}
	if get_cfo() != null:
		var team_rep: float = float(player_team.reputation) if player_team != null else 50.0
		for line in commercial_lines:
			var seg: String = line.get("segment", "")
			if seg == "":
				continue
			var age: float = float(line.get("age_seasons", 0.0))
			player_inputs[seg] = {
				"reputation": team_rep,
				"marketing": float(line.get("marketing", 1.0)),
				"age_seasons": age,
				"freshness": CommercialMarketSim._freshness_for_age(age),
				"active": true
			}
	_commercial_market.advance_week(player_inputs, sales_factor)
	_check_commercial_share_milestones()

## S40.0 — Phase 3 tail (Phase3_Commercial_Validation §8): after the weekly market tick, announce when
## the player's share in a segment they actively produce in crosses an upward milestone (10/20/30/50%).
## Classified as NEWS (a meaningful world event, per Notification_News_Roadmap). Each rung fires once
## per ascent; if share later drops below a rung the ledger lowers, so a genuine re-climb re-announces.
## A segment with no active player line is skipped (and its ledger cleared) — nothing to celebrate.
func _check_commercial_share_milestones() -> void:
	if _commercial_market == null:
		return
	## Build the set of segments the player currently produces in.
	var active_segs: Dictionary = {}
	for line in commercial_lines:
		var s: String = line.get("segment", "")
		if s != "":
			active_segs[s] = true
	## Drop ledger entries for segments we no longer produce in (so re-entry re-announces cleanly).
	for k in commercial_share_milestone_hit.keys():
		if not active_segs.has(k):
			commercial_share_milestone_hit.erase(k)

	for seg_key in active_segs.keys():
		var share_pct: float = _commercial_market.get_player_share(seg_key) * 100.0
		var prev_best: int = int(commercial_share_milestone_hit.get(seg_key, 0))
		## Highest milestone the current share now qualifies for.
		var new_best: int = 0
		for m in COMMERCIAL_SHARE_MILESTONES:
			if share_pct >= float(m):
				new_best = m
		if new_best > prev_best:
			## Crossed UP to a higher rung — announce the top rung reached this week.
			var seg_name: String = _commercial_market.segment_name(seg_key)
			var msg: String = ""
			if new_best >= 50:
				msg = "🏆 Market milestone: your %s now command a commanding %d%% share — the segment's leading marque." % [seg_name, new_best]
			else:
				msg = "📈 Market milestone: your %s passed %d%% market share." % [seg_name, new_best]
			notify_event("commercial_share_%s_%d" % [seg_key, new_best], "Normal", msg, "res://scenes/buildings/VehicleFactory.tscn", "news")
			commercial_share_milestone_hit[seg_key] = new_best
		elif new_best < prev_best:
			## Slipped below the previously-announced rung — lower the ledger so a re-climb re-fires.
			commercial_share_milestone_hit[seg_key] = new_best


# ═══════════════════════════════════════════════════════════════════════════
# PILLAR-5 — COMMERCIAL LINE MANAGEMENT  (build / facelift / next-gen)  (S38.5)
# ═══════════════════════════════════════════════════════════════════════════
## A segment is UNLOCKED for commercial production once the player has raced its Factory_Unlock
## championship (permanent, via the ever-raced ledger).
## S39.5 — "Unlocked" now means the R&D Studio is at the level needed to RESEARCH this segment's
## blueprint (the racing gate was removed). The Factory is still needed to build/produce, separately.
func is_commercial_segment_unlocked(seg_key: String) -> bool:
	if _commercial_market == null:
		return false
	var task = RND_TASKS.get("P5_MODEL_%s" % seg_key, {})
	if task.is_empty():
		return false
	var need: int = int(task.get("Required_RnD_Studio_Level", 1))
	var studio = campus_buildings.get("R&D Design Studio", {})
	if not studio.get("built", false):
		return need <= 1
	return int(studio.get("level", 0)) >= need

## True once the Pillar-5 base blueprint for this segment has been researched (R&D task done).
func is_commercial_blueprint_researched(seg_key: String) -> bool:
	return ("P5_MODEL_%s" % seg_key) in completed_rnd_tasks

## Free production lines = Factory level − lines already in use.
func commercial_free_lines() -> int:
	var factory = campus_buildings.get("Vehicle Assembly Factory", {})
	if not factory.get("built", false) or factory.get("level", 0) < 1:
		return 0
	return int(factory.get("level", 1)) - commercial_lines.size()

func has_commercial_line_for(seg_key: String) -> bool:
	for line in commercial_lines:
		if line.get("segment", "") == seg_key:
			return true
	return false

## Build a new production line for a researched, unlocked segment (needs a CFO + a free line).
## Returns "" on success or an error string for the caller to surface.
func build_commercial_line(seg_key: String, model_name: String = "") -> String:
	if _commercial_market == null or not _commercial_market.SEGMENTS.has(seg_key):
		return "Unknown segment."
	if get_cfo() == null:
		return "A CFO is required to operate the Factory."
	if not is_commercial_blueprint_researched(seg_key):
		return "Research the model blueprint in the R&D Studio first."
	if has_commercial_line_for(seg_key):
		return "A line is already running this segment."
	if commercial_free_lines() <= 0:
		return "No free production lines — upgrade the Factory."
	var nm: String = model_name if model_name != "" else _commercial_market.segment_name(seg_key)
	commercial_lines.append({
		"segment": seg_key, "model_name": nm, "age_seasons": 0.0,
		"marketing": 1.0, "researched_unlock": _commercial_market.unlock_championship(seg_key)
	})
	notify_event("commercial_line_built_%s" % seg_key, "Normal",
		"🏭 New production line: %s (%s) is now manufacturing." % [nm, _commercial_market.segment_name(seg_key)],
		"commercial_dept", "news")
	return ""

## S39.7 — Start a Facelift or Next-Gen as an R&D mini-project (RP + CR + weeks, like any research).
## Facelift ≈ 25% of the blueprint cost, Next-Gen ≈ 60%; weeks/RP scale the same way. Requires: a
## producing line for the segment, a free Designer, and enough RP/CR. On completion (_advance_rnd_
## tasks) the refresh applies and a rename popup is queued. Returns "" on success or an error string.
func start_commercial_refresh(seg_key: String, nextgen: bool, designer_id: String) -> String:
	if not has_commercial_line_for(seg_key):
		return "No production line is running this segment."
	var prefix = "P5_NEXTGEN_" if nextgen else "P5_FACELIFT_"
	var tid = prefix + seg_key
	for t in active_rnd_tasks:
		if t.get("id", "") == tid:
			return "That refresh is already in progress."
	if not designer_id in all_staff:
		return "Invalid designer."
	for t in active_rnd_tasks:
		if t.get("designer_id", "") == designer_id:
			return "That designer is already busy."
	var bp = RND_TASKS.get("P5_MODEL_%s" % seg_key, {})
	if bp.is_empty():
		return "Blueprint not found."
	var frac = 0.60 if nextgen else 0.25
	var cr_cost = int(bp.get("cr", 25000000) * frac)
	var rp_cost = int(bp.get("rp", 4000) * frac)
	var weeks = int(ceil(bp.get("weeks", 40) * frac))
	if research_points < rp_cost:
		return "Not enough RP. Need %d, have %.0f." % [rp_cost, research_points]
	if player_team.balance < cr_cost:
		return "Not enough CR. Need %s." % _fmt_int(cr_cost)
	research_points -= rp_cost
	player_team.balance -= cr_cost
	var seg_name = _commercial_market.segment_name(seg_key)
	active_rnd_tasks.append({
		"id": tid,
		"name": "%s — %s" % [seg_name, ("Next-Gen" if nextgen else "Facelift")],
		"pillar": 5,
		"part": "Commercial",
		"segment": seg_key,
		"championship_id": "",
		"season": current_season,
		"level": 1,
		"weeks_total": weeks,
		"weeks_remaining": weeks,
		"rp_cost": rp_cost,
		"cr_cost": cr_cost,
		"designer_id": designer_id,
		"effect_key": "",
		"effect_value": 0.0,
	})
	return ""

## True if a facelift/nextgen R&D project is currently running for this segment.
func commercial_refresh_in_progress(seg_key: String) -> bool:
	for t in active_rnd_tasks:
		var tid = t.get("id", "")
		if tid == ("P5_FACELIFT_" + seg_key) or tid == ("P5_NEXTGEN_" + seg_key):
			return true
	return false


## and clears the player's producer from the market so the share decays away naturally. The researched
## blueprint is retained, so the player can restart production later.
func stop_commercial_line(seg_key: String) -> String:
	var idx := -1
	for i in range(commercial_lines.size()):
		if commercial_lines[i].get("segment", "") == seg_key:
			idx = i; break
	if idx < 0:
		return "No line is producing that segment."
	commercial_lines.remove_at(idx)
	## Drop the player's producer from the market (share will be redistributed to rivals/Others).
	if _commercial_market != null:
		_commercial_market.remove_player_producer(seg_key)
	return ""

## Facelift — cheap mid-life refresh: knocks the model's age back, restoring competitiveness (§4.2).
func facelift_commercial_line(seg_key: String) -> String:
	for line in commercial_lines:
		if line.get("segment", "") == seg_key:
			line["age_seasons"] = max(0.0, float(line.get("age_seasons", 0.0)) - 6.0)
			return ""
	return "No line for that segment."

## Next-Gen — expensive successor: fully resets the lifecycle clock (Escort→Focus).
func nextgen_commercial_line(seg_key: String, new_model_name: String = "") -> String:
	for line in commercial_lines:
		if line.get("segment", "") == seg_key:
			line["age_seasons"] = 0.0
			if new_model_name != "":
				line["model_name"] = new_model_name
			return ""
	return "No line for that segment."

## Set the per-model marketing ratio (1.0 = recommended spend); clamped to a sane band.
func set_commercial_marketing(seg_key: String, ratio: float) -> void:
	for line in commercial_lines:
		if line.get("segment", "") == seg_key:
			line["marketing"] = clamp(ratio, 0.0, 2.0)
			return


func _update_economy_and_fuel() -> void:
	## ── Economy index drift ───────────────────────────────────────────────────
	var prev_state = global_economy_state  ## read derived property before update

	## S38.4 — Economy RE-TUNE (GDD §4.5, Option A). The old pure mean-reversion-to-50 kept the index
	## trapped in a 35–67 band — it never reached Boom(>70) or Recession(<30) across a career, leaving
	## the economy (and the fuel/loan/speculation systems that read it) practically flat. Replaced with
	## a slow ~5-season sine "regime" whose CENTRE drifts between ~28 and ~72, plus light weekly noise
	## and rare shocks. The index is pulled toward the moving regime centre rather than a fixed 50.
	## Validated over 25-season careers: ~3–4 booms + ~3–4 recessions, ~92% of weeks Normal — genuine
	## but rare cycles. Constants below are the tuned values; re-validate if changed.
	const REGIME_PERIOD_WEEKS: float = 5.0 * 52.0   ## ~5 in-game seasons per full economic wave
	const REGIME_AMPLITUDE: float    = 22.0          ## centre swings 50 ± 22 → ~28..72
	const REGIME_PULL: float         = 0.05          ## how hard the index tracks the regime centre
	const SHOCK_CHANCE: float        = 0.012         ## ~rare; a sharp ±7 jolt on top of the noise

	## Continuous global week drives the sine phase. _economy_phase0 (set at new-game) desyncs careers
	## so two playthroughs don't share the same cycle.
	var global_week: float = float((current_season - 1) * 52 + current_week)
	var phase: float = _economy_phase0 + (global_week / REGIME_PERIOD_WEEKS) * TAU
	var regime_centre: float = 50.0 + REGIME_AMPLITUDE * sin(phase)

	## Pull toward the slowly-moving regime centre (replaces the old fixed-50 mean-reversion).
	var pull: float = (regime_centre - economy_index) * REGIME_PULL

	## Light weekly noise, with a rare shock week.
	var noise: float = randf_range(-0.5, 0.5)
	if randf() < SHOCK_CHANCE:
		noise += randf_range(-7.0, 7.0)   ## shock week

	## Momentum carries direction (smooths out jitter)
	_economy_momentum = _economy_momentum * 0.8 + noise * 0.2
	economy_index = clamp(economy_index + pull + _economy_momentum, 0.0, 100.0)
	current_loan_rate = clamp(4.0 + (economy_index / 100.0) * 8.0, 1.0, 12.0)
	current_loan_rate = round(current_loan_rate * 10.0) / 10.0

	## Notify on state change — S35.3: CFO-gated. Economy intelligence is what the player pays
	## the CFO for (GDD §9-E: `speculation` = economy_index predictions). No CFO → the economy
	## still moves (index/prices update below regardless), the player just gets no heads-up.
	var new_state = global_economy_state
	if new_state != prev_state and get_cfo() != null:
		notify_event("economy_state", "Normal", "📊 Economy shifted to %s (index %.0f)." % [new_state, economy_index],
			"", "standing")

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
			notify_event("economy_fuel_shock", "Normal", "⛽ Fuel price fluctuation — global supply shift.",
				"", "standing")

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
var pending_campus_zone: String = ""   ## S37.34 transient — Campus restores last-viewed zone tab
## Set by _end_season / start_new_season so MainHub knows which screen to show on next load.
## Values: "" (normal), "end_of_season", "begin_of_season"
var pending_season_screen: String = ""

## CNC Production Queue: Array of Dicts
## {id, part, championship_id, weeks_total, weeks_remaining, cr_cost, quantity}
var cnc_production_queue: Array = []

## ── Season Calendar (S37.26) ─────────────────────────────────────────────────────
## race_calendar_data: loaded once from res://data/race_calendar.json (static schedule for all
##   21 championships). Read-only at runtime, NOT saved (reloaded from JSON each launch).
## custom_calendar_events: the ONLY persisted calendar state. Player-created reminders.
##   Each entry: { "week": int, "title": String, "note": String }.
var race_calendar_data: Dictionary = {}
## S37.32 — part PURCHASE prices (Base_Cost × (1+Manufacturer_Profit) × Manufacturer_Quality),
## loaded from res://data/part_costs.json (generated from Excel CNC sheet). Replaces the
## stale hardcoded PART_COSTS (which had GK at 0 → the 'parts don't cost credits' bug).
var part_costs_data: Dictionary = {}
var custom_calendar_events: Array = []
const _CalendarManagerScript = preload("res://resources/scripts/CalendarManager.gd")
var _calendar_manager = null   ## CalendarManager (untyped — avoids global-class parse-order error)
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

## S38.2 — Phase 3 player commercial production lines (the road-car business).
## Factory level = number of available lines; each entry here is ONE active line running ONE model.
## Populated by the Commercial Department screen (later unit) when the player researches a Pillar-5
## blueprint and assigns it to a free line. Read by FinancialEngine for weekly income + company value.
##   commercial_lines = [ {
##      "segment": "supercars",        # CommercialMarketSim segment key
##      "model_name": "Aria GT",       # player-named model (flavor)
##      "age_seasons": 0.0,            # model lifecycle age (drives freshness)
##      "marketing": 1.0,             # marketing_ratio the player set (1.0 = recommended spend)
##      "researched_unlock": "C-010"  # the championship that unlocked it (breadcrumb/validation)
##   }, ... ]
var commercial_lines: Array = []
## S39.7 — pending rename requests from completed Facelift/Next-Gen R&D projects. Each = {segment,
## nextgen:bool}. The Commercial Department drains this and pops the naming popup for the player.
var pending_commercial_rename: Array = []

## S40.0 — market-share milestone ledger (Phase3_Commercial_Validation §8: share milestones → news).
## Per segment, the highest threshold (%) the player has already been congratulated for, so each rung
## fires once per ascent and can only re-fire if share falls back below it and climbs again. Saved.
const COMMERCIAL_SHARE_MILESTONES: Array = [10, 20, 30, 50]
var commercial_share_milestone_hit: Dictionary = {}   ## { seg_key: int highest_pct_announced }

## S38.3 — Rolling racing-income window (sponsors + race prizes + EOS), used by FinancialEngine to
## anchor the Factory's hard 2× cap (GDD §4.4) to TOTAL racing income rather than sponsor-only.
## register_racing_income() is called at every racing-credit payout; advance_week rolls the window.
## A 4-week sum smooths out lumpy per-race/EOS payouts so the cap doesn't jump week to week.
var _racing_income_window: Array = [0.0, 0.0, 0.0, 0.0]   ## last 4 weeks; [0] = current week
var _racing_income_this_week: float = 0.0

## Add a racing-income credit to the current week's tally (call AT each payout site).
func register_racing_income(amount: float) -> void:
	if amount > 0.0:
		_racing_income_this_week += amount

## Average weekly racing income over the rolling window (used as the cap anchor).
func get_avg_weekly_racing_income() -> float:
	var total: float = _racing_income_this_week
	for v in _racing_income_window:
		total += v
	return total / float(_racing_income_window.size() + 1)

## Roll the window forward one week (called once per advance_week, before income is registered).
func _roll_racing_income_window() -> void:
	_racing_income_window.push_front(_racing_income_this_week)
	if _racing_income_window.size() > 4:
		_racing_income_window.resize(4)
	_racing_income_this_week = 0.0
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
	"pit_arena":      "res://scenes/buildings/PitCrewArena.tscn",
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
	"pit_arena":      "Go to Pit Crew Arena \u2192",
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
## S40.17 — Registration deadline. Normally 52 − CNC design_weeks − 1. Two pinnacle series (EPC
## Hyper League C-020, GP1 C-024) have very long CNC manufacture lead times (design_weeks 32/40) that
## would leave only 19/11 weeks to DESIGN next season's car — too little to complete six from-scratch
## L1 blueprints (which pack to ~20 weeks at a competitive studio). Rather than shorten their CNC
## lead time (which would also speed up manufacturing — a separate, correctly-tuned system), we give
## ONLY their registration deadline a floor of week 31 (→ a 20-week design window), so a from-scratch
## pinnacle car is designable in one season. CNC manufacture time is unchanged.
const REG_DEADLINE_OVERRIDE := {"C-020": 31, "C-024": 31}
func get_entry_deadline_week(champ_id: String) -> int:
	if champ_id in REG_DEADLINE_OVERRIDE:
		return REG_DEADLINE_OVERRIDE[champ_id]
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

# Weekly log (developer / operational event log — DNS, repairs, assignments, balances).
# NOT shown in the NEWS panel; this is the raw event stream.
var weekly_log: Array[String] = []

# News feed (S37.63) — the curated WORLD-NEWS stream the NEWS panel renders. Only genuine news
# events go here (race outcomes, titles, signings/releases/retirements, R&D/building completions,
# regulation changes). Operational reminders/state (DNS, "added to garage", balances, sponsor
# signed, bankruptcy risk, development ticks) do NOT — those are notifications/log only. See GDD §12.
var news_feed: Array[String] = []

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
	_ai_championship_sim = AIChampionshipSim.new(self)
	_commercial_market = CommercialMarketSim.new()   ## S38.1 — seeded in setup_new_game / restored in load_game
	_contract_engine = ContractEngine.new(self)
	_rnd_engine = RnDEngine.new(self)
	_notification_manager = NotificationManager.new(self)
	_campus_manager = CampusManager.new(self)
	_sponsor_manager = SponsorManager.new(self)
	_staff_manager = StaffManager.new(self)
	_car_manager = CarManager.new(self)
	_driver_manager = DriverManager.new(self)
	_tp_engine = TPProposalEngine.new(self)
	_lead_designer_engine = LeadDesignerProposalEngine.new(self)   ## S40.0
	_calendar_manager = _CalendarManagerScript.new(self)   ## S37.26
	_load_race_calendar()                                  ## S37.26
	_load_part_costs()                                     ## S37.32
	_sponsor_manager = SponsorManager.new(self)
	_staff_manager = StaffManager.new(self)
	_car_manager = CarManager.new(self)
	_driver_manager = DriverManager.new(self)
	_tp_engine = TPProposalEngine.new(self)
	_lead_designer_engine = LeadDesignerProposalEngine.new(self)   ## S40.0
	_sponsor_manager = SponsorManager.new(self)
	_staff_manager = StaffManager.new(self)
	_car_manager = CarManager.new(self)
	_driver_manager = DriverManager.new(self)
	_tp_engine = TPProposalEngine.new(self)
	_lead_designer_engine = LeadDesignerProposalEngine.new(self)   ## S40.0
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
			notify_event("delivered_%s" % car.id, "Normal",
				"🏎 %s delivered — ready to race in %s. Assign crew in the Garage." % [
				car_label, champ_name], "garage", "event")
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
		show_popup("Cannot build car yet — missing approved blueprints: %s." % ", ".join(miss), "Cannot Build Car")
		return false
	if player_team_cars.size() >= get_max_cars():
		show_popup("Garage full (%d/%d). Upgrade the Garage to build more cars." % [
			player_team_cars.size(), get_max_cars()], "Garage Full")
		return false
	var total_cr = get_build_whole_car_cost(champ_id)
	if player_team.balance < total_cr:
		show_popup("Insufficient funds to build the car. Need CR %s for all 6 parts." % _fmt_int(total_cr),
			"Insufficient Funds")
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
	notify_event("inbuild_%s" % car.id, "Normal",
		"🏗 %s car in build — all 6 parts queued, arrives Week %d. Pre-assign crew in the Garage." % [
		champ_name, car.delivery_week], "garage", "event")
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

## S40.13 — P4 effect accessor delegations (cluster getters the wired systems call through gs).
func rnd_perf_bonus() -> float:        return _rnd_engine.perf_bonus()
func rnd_reliability_bonus() -> float: return _rnd_engine.reliability_bonus()
func rnd_fatigue_bonus() -> float:     return _rnd_engine.fatigue_bonus()
func rnd_tax_reduction() -> float:            return _rnd_engine.economy_tax_reduction()
func rnd_maintenance_reduction() -> float:    return _rnd_engine.economy_maintenance_reduction()
func rnd_passive_income_bonus() -> float:     return _rnd_engine.economy_passive_income_bonus()

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

## S37.10 — commitment (type-3) sponsor annual payment / penalty, run at SEASON START.
func _process_sponsor_annual_payments() -> void:
	_sponsor_manager._process_sponsor_annual_payments()

## S37.10 — number of race-result screens still queued this week (Skip button label).
func pending_race_result_count() -> int:
	return _pending_race_results.size()

func _maybe_generate_race_sponsor_offer(player_position: int) -> void:
	_sponsor_manager._maybe_generate_race_sponsor_offer(player_position)


func add_notification(priority: String, message: String, destination: String = "", subject: String = "") -> void:
	_notification_manager.add_notification(priority, message, destination, subject)

## Framework entry point (S37.7) — see NotificationManager.notify_event.
func notify_event(event_id: String, priority: String, message: String, destination: String = "", mode: String = "event") -> void:
	_notification_manager.notify_event(event_id, priority, message, destination, mode)

## S37.37 — On-the-spot blocking-error popup (Notification & News Roadmap, Phase 0).
## Shared AcceptDialog for "you can't do that right now" feedback. Replaces routing blocking
## errors through the notification panel (which the player, mid-action on another screen, easily
## misses). Any engine or scene calls gs.show_popup(...); parented to the active scene so it works
## even when called from RefCounted engines that have no node of their own. Generalises the inline
## AcceptDialog pattern first used in S29.0 / bug #41.
## A blocking popup must never STACK: Godot allows only one exclusive child window at a time, and a
## bulk action (e.g. Logistics "+N each" looping buy_part over every part) would otherwise spawn one
## dialog per failed item. If a popup is already showing, fold the new message into it instead.
var _active_popup: AcceptDialog = null

func show_popup(message: String, title: String = "Notice") -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		push_warning("show_popup: no current scene — " + message)
		return
	# One popup at a time — append the new line rather than stacking a second modal.
	if is_instance_valid(_active_popup):
		if not _active_popup.dialog_text.contains(message):
			_active_popup.dialog_text += "\n" + message
		return
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.ok_button_text = "OK"
	_active_popup = dialog
	scene.add_child(dialog)
	dialog.popup_centered()
	var _clear := func():
		_active_popup = null
		dialog.queue_free()
	dialog.confirmed.connect(_clear)
	dialog.canceled.connect(_clear)

func reset_notification_once(event_id: String) -> void:
	_notification_manager.reset_once(event_id)

func mark_all_notifications_read() -> void:
	_notification_manager.mark_all_notifications_read()

func dismiss_notification(index: int) -> void:
	_notification_manager.dismiss_notification(index)

func clear_all_notifications() -> void:
	_notification_manager.clear_all_notifications()

func snooze_notification(index: int, weeks: int) -> void:
	_notification_manager.snooze_notification(index, weeks)

func _purge_old_notifications(keep_weeks: int = 2) -> void:
	_notification_manager._purge_old_notifications(keep_weeks)

func get_critical_count() -> int:
	return _notification_manager.get_critical_count()

func add_log(message: String) -> void:
	_notification_manager.add_log(message)

## S37.63 — record a genuine WORLD-NEWS event. Appends to news_feed (rendered by the NEWS panel)
## and also to weekly_log (so the raw event stream stays complete). Use this ONLY for real news
## per GDD §12; operational chatter stays on add_log().
func log_news(message: String) -> void:
	news_feed.append(message)
	_notification_manager.add_log(message)
	emit_signal("log_updated")

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
		show_popup("Not enough credits to buy spare parts (need CR %.0f, have CR %.0f)." % [total_cost, player_team.balance], "Insufficient Funds")
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
		show_popup("Not enough credits to buy fuel (need CR %.0f, have CR %.0f)." % [total_cost, player_team.balance], "Insufficient Funds")
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
		if "Ops Sim & Telemetry" in campus_buildings:
			campus_buildings["Ops Sim & Telemetry"]["built"] = true
			campus_buildings["Ops Sim & Telemetry"]["level"] = 1

	## S37.50 — GP starts with the design+manufacturing chain (R&D Design Studio + CNC Parts Plant)
	## so a GP4 career can develop and produce parts from week 1. The Designer is provisioned in
	## section 7a below (the R&D Studio supplies the Designer hiring slot). Other disciplines build
	## these later. (Budgets were tuned manually to cover the added upkeep.)
	if discipline == "GP":
		if "R&D Design Studio" in campus_buildings:
			campus_buildings["R&D Design Studio"]["built"] = true
			campus_buildings["R&D Design Studio"]["level"] = 1
		if "CNC Parts Plant" in campus_buildings:
			campus_buildings["CNC Parts Plant"]["built"] = true
			campus_buildings["CNC Parts Plant"]["level"] = 1

	## ── 3. Starting TP ───────────────────────────────────────────────────────
	var tp = _create_starting_staff("Team Principal", 55.0, 70.0)
	tp.contract_team = player_team.id
	tp.contract_seasons_remaining = 3
	tp.assigned_championship = champ_id
	all_staff[tp.id] = tp

	## ── 4. Starting Driver(s) ────────────────────────────────────────────────
	## S37.60 — multi-driver disciplines (Rally/TC = 2, EPC = 3) start with a FULL crew of
	## co-equal drivers so the starting car is race-ready (every seat must be filled or the
	## car DNS's). GK/GP/OWC/SC start with one as before.
	var seats_needed = get_drivers_per_car(champ_id)
	var starting_drivers: Array = []
	for _s in range(seats_needed):
		var d = _find_and_sign_starting_driver(discipline, champ_id)
		if d != null:
			starting_drivers.append(d)

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

	## ── 7a. Designer (GP) ────────────────────────────────────────────────────
	## S37.50 — GP starts with a Designer to staff the R&D Design Studio (built above). The Designer
	## is team-level staff (operates in the R&D Studio only; no discipline adaptation, GDD §F), so it
	## follows the TP/Strategist pattern: contract_team set, no per-car assignment.
	if discipline == "GP":
		var designer = _create_starting_staff("Designer", 45.0, 65.0)
		designer.contract_team = player_team.id
		designer.contract_seasons_remaining = 3
		all_staff[designer.id] = designer

	## ── 8. Assign driver(s) to car ───────────────────────────────────────────
	## S37.60 — seat every starting driver (co-equal). We seat directly (not via
	## assign_driver_to_car) to avoid the standings re-sync pruning a co-driver that is
	## registered-but-not-yet-seated mid-loop; then register all seated drivers once.
	if not player_team_cars.is_empty():
		var car0 = player_team_cars[0]
		for si in range(starting_drivers.size()):
			if si < car0.seat_count():
				car0.driver_ids[si] = starting_drivers[si].id
		var champ0 = get_championship_by_id(car0.championship_id)
		if champ0 != null:
			## S37.61 crew model — register only the car REPRESENTATIVE (seat 0) into standings.
			var rep0: String = car0.driver_ids[0] if car0.driver_ids.size() > 0 and car0.driver_ids[0] != "" else ""
			if rep0 != "" and not rep0 in champ0.standings:
				champ0.standings[rep0] = 0
			if not player_team.id in champ0.team_standings:
				champ0.team_standings[player_team.id] = 0

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

func assign_driver_to_car(driver_id: String, car_id: String) -> String:
	return _car_manager.assign_driver_to_car(driver_id, car_id)

func unassign_driver_from_car(car_id: String, only_driver_id: String = "") -> void:
	_car_manager.unassign_driver_from_car(car_id, only_driver_id)

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

func get_affordable_repair_pct(driver_id: String) -> float:
	return _car_manager.get_affordable_repair_pct(driver_id)

func repair_car_affordable(driver_id: String) -> bool:
	return _car_manager.repair_car_affordable(driver_id)

func repair_car_max_sp(driver_id: String) -> bool:
	return _car_manager.repair_car_max_sp(driver_id)

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
	## #50 — The warehouse no longer starts with 3 free parts of each type. Cars + loose parts are
	## scrapped at season end, and the player must BUY (or CNC) every part — no freebies at setup.
	## GK-relic fix: seed the inventory dict for the player's ACTUAL car championships (and the
	## starting championship), NOT active_championship — which at this point in setup can still
	## resolve to the legacy GK (C-001) default because player_registered_championships isn't
	## populated until just after this call. Empty (0) dicts keep the structure so installs/buys
	## that index part_inventory[champ_id][part] don't error.
	part_inventory = {}
	var champ_ids: Array = []
	if _starting_champ_id != "" and not _starting_champ_id in champ_ids:
		champ_ids.append(_starting_champ_id)
	for car in player_team_cars:
		if car.championship_id != "" and not car.championship_id in champ_ids:
			champ_ids.append(car.championship_id)
	for cid in champ_ids:
		part_inventory[cid] = {}
		for part in PARTS_LIST:
			part_inventory[cid][part] = 0  ## start EMPTY — no free parts (#50)

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
	var base_unit_price = get_part_unit_price(champ_id, part_name)
	if base_unit_price <= 0:
		show_popup("No part cost data for %s in this championship." % part_name, "Cannot Buy Part")
		return false
	# Apply Logistics Center discount (-1% per level, max -50%)
	var discount = get_logistics_parts_discount()
	var unit_cost = int(round(base_unit_price * discount))
	var total_cost = unit_cost * quantity
	if player_team.balance < total_cost:
		show_popup("Not enough credits to buy %d× %s (need CR %d, have CR %d)." % [
			quantity, part_name, total_cost, int(player_team.balance)], "Insufficient Funds")
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

func discard_draft_negotiation(neg_id: String = "") -> void:
	_contract_engine.discard_draft_negotiation(neg_id)

func cancel_approach_before_submit(neg_id: String) -> void:
	_contract_engine.cancel_approach_before_submit(neg_id)

## S37.9 — TDL X button: dismiss a player-initiated renegotiation the player never submitted.
func cancel_renegotiation_by_subject_name(subject_name: String) -> bool:
	return _contract_engine.cancel_renegotiation_by_subject_name(subject_name)

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
	var disc = reg.get("discipline", "")

	## Strategist is NOT used in GK or Rally — block the assignment outright.
	if staff.role == "Race Strategist" and disc in ["GK", "Rally"]:
		show_popup("Race Strategists are not used in GK or Rally championships.", "Not Applicable")
		return

	## Slot guard — only ONE Team Principal / Race Strategist per championship.
	## The SAME person may be reassigned (their old assignment is cleared below); a DIFFERENT
	## same-role staffer already on this championship blocks the assignment.
	if staff.role in ["Team Principal", "Race Strategist"]:
		for sid2 in all_staff:
			var s2 = all_staff[sid2]
			if s2.id == staff_id: continue
			if s2.role == staff.role and s2.contract_team == player_team.id \
					and s2.assigned_championship == champ_id:
				show_popup("%s already has a %s assigned." % [champ_name, staff.role], "Already Assigned")
				return

	## Log the move off an old championship (reassignment, e.g. GK → Rally4).
	if staff.assigned_championship != "" and staff.assigned_championship != champ_id:
		var old_reg = CHAMPIONSHIP_REGISTRY.get(staff.assigned_championship, {})
		add_log("📋 %s unassigned from %s." % [staff.full_name(), old_reg.get("name", staff.assigned_championship)])

	## #40 — Manual TP / Strategist reassignment now applies IMMEDIATELY (was queued to "next
	## week" via pending_staff_assignments, which left assigned_championship stale → the HQ card
	## showed the OLD championship → looked like "nothing happened" → a non-GK championship read
	## as having no TP → DNS → the game soft-locked into GK only). Driver/mechanic already apply
	## immediately; TP/Strategist now match. (pending_staff_assignments is retained for the
	## season-transition pipeline only.)
	## Also clear any stale queued entry for this staffer so a prior queue can't re-fire next week.
	if staff_id in pending_staff_assignments:
		pending_staff_assignments.erase(staff_id)
	staff.assigned_championship = champ_id
	add_log("📋 %s assigned to %s." % [staff.full_name(), champ_name])
	invalidate_player_staff_cache()
	emit_signal("log_updated")

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

## #40 — At season rollover, clear any PLAYER Team Principal / Strategist still assigned to a
## championship the player no longer races this season. Without this a TP stays stranded on (e.g.)
## GK after switching to Rally, the HQ card shows the old series, and the new championship reads as
## having no TP → DNS. After this runs, a stranded overseer shows "Not assigned" and the player
## reassigns them. AI teams manage their own via ai_auto_assign — this touches the player only.
func clear_stranded_player_championship_staff() -> void:
	for sid in all_staff:
		var s = all_staff[sid]
		if s.contract_team != player_team.id: continue
		if s.role not in ["Team Principal", "Race Strategist"]: continue
		if s.assigned_championship != "" and s.assigned_championship not in player_registered_championships:
			var reg = CHAMPIONSHIP_REGISTRY.get(s.assigned_championship, {})
			add_log("📋 %s unassigned — %s is not on this season's calendar. Reassign in HQ." % [
				s.full_name(), reg.get("name", s.assigned_championship)])
			s.assigned_championship = ""
	invalidate_player_staff_cache()

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
		if not car.all_seats_filled():
			if car.seat_count() <= 1:
				tasks.append("🏎 %s has no driver — will DNS." % cn)
			else:
				var _e = car.seat_count() - car.assigned_driver_ids().size()
				tasks.append("🏎 %s has %d of %d driver seats empty — will DNS." % [cn, _e, car.seat_count()])
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
		show_popup("Unknown championship ID: %s" % champ_id, "Cannot Register")
		return false
	if champ_id in next_season_registrations:
		show_popup("Already registered for %s (Season %d)." % [reg["name"], current_season + 1], "Already Registered")
		return false
	var deadline = get_entry_deadline_week(champ_id)
	if current_week > deadline:
		show_popup("Registration deadline for %s passed (Week %d)." % [reg["name"], deadline], "Deadline Passed")
		return false
	var fee = reg.get("entry_fee", 0)
	if player_team.balance < fee:
		show_popup("Cannot afford entry fee for %s (need CR %s)." % [
			reg["name"], _fmt_int(fee)], "Insufficient Funds")
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
		notify_event("reg_warn_%s" % reg["name"], "High", warn_text, "", "event")
	else:
		notify_event("reg_ok_%s" % reg["name"], "Normal", "Registered for %s. Buy/build a car before Week %d." % [
			reg["name"], delivery_wk], "", "event")

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
			notify_event("formula_design_%s_s%d" % [champ_id, next_season], "Critical",
				"🚨 You registered for %s Season %d. Formula teams MUST design a new car each season. Start designing Season %d blueprints in the R&D Design Studio — P1 DESIGN tab." % [
					reg["name"], next_season, next_season],
				"rnd_studio", "event")
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
					notify_event("wra_reset_%s_s%d" % [wra_group, next_season], "High",
						"⚠ WRA regulation reset for %s in %d season%s. Consider designing Season %d blueprints now before your current ones are wiped." % [
							wra_group, seasons_until_reset,
							"s" if seasons_until_reset != 1 else "",
							next_season],
						"rnd_studio", "event")

	emit_signal("log_updated")
	return true

## Championship registrations are final — no withdrawals once entered.
## Teams are contractually bound to participate. DNS applies if requirements aren't met.
func unregister_from_championship(_champ_id: String) -> void:
	show_popup("Championship registrations are binding. Teams cannot withdraw once entered. DNS applies if car/driver requirements are not met.", "Registration Binding")

## Returns all championship IDs the player has registered for NEXT season (the ledger).
## S28.1: this is simply the NextSeasonLedger contents.
func get_pending_registrations() -> Array:
	return next_season_registrations.duplicate()
func get_weekly_expenses() -> float:
	return _financial_engine.get_weekly_expenses()

## Runway in weeks at current expense rate
func get_runway_weeks() -> int:
	return _financial_engine.get_runway_weeks()

## S40.14 — corporate tax delegations (HQ Financial Department reads these; SeasonManager applies).
func get_season_profit() -> float:          return _financial_engine.get_season_profit()
func get_effective_tax_rate() -> float:     return _financial_engine.get_effective_tax_rate()
func get_projected_season_tax() -> int:     return _financial_engine.get_projected_season_tax()
func apply_season_end_tax() -> void:        _financial_engine.apply_season_end_tax()
func snapshot_season_start_balance() -> void: _financial_engine.snapshot_season_start_balance()

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

## S37.61 — combined crew label for a championship standings entry. Given a representative driver
## id (seat 0 of a car), returns "Smith / Jones" for a multi-driver car, or the driver's full name
## for a single-seat car / lone driver. Searches player cars first, then AI cars.
func crew_label_for_driver(rep_id: String) -> String:
	var rep = all_drivers.get(rep_id)
	if rep == null:
		return rep_id
	var car = get_car_for_driver(rep_id)
	if car == null:
		for cid in ai_cars:
			for ac in ai_cars[cid]:
				if ac != null and ac.has_driver(rep_id):
					car = ac
					break
			if car != null:
				break
	if car == null or car.seat_count() <= 1:
		return rep.full_name()
	var parts: Array = []
	for did in car.assigned_driver_ids():
		var d = all_drivers.get(did)
		if d != null:
			parts.append(d.last_name if d.last_name != "" else d.full_name())
	if parts.size() <= 1:
		return rep.full_name()
	return " / ".join(parts)

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
	news_feed = []
	last_race_results = []
	hall_of_fame = []
	retired_personnel = []
	dismissed_todo_items = []
	custom_todo_items    = []
	custom_calendar_events = []   ## S37.26
	## ── S37.28 (#52): clear leaked session state so a New Game doesn't inherit the previous one. ──
	## These persistent collections had no reset → they carried over from a prior game in-session.
	active_sponsors           = []
	sponsor_offers            = []
	active_approaches         = []
	pending_staff_assignments = {}
	notifications             = []
	unread_notification_count = 0
	spare_parts               = 300     ## starting SP (matches var default)
	fuel_kg                   = 30.0    ## starting fuel — 2 races worth (matches var default)
	## Transient routing strings — must not survive into a fresh game.
	pending_season_screen     = ""
	pending_hq_tab            = ""
	pending_campus_zone       = ""
	pending_staff_filter      = ""
	pending_rnd_champ_id      = ""
	pending_rnd_pillar        = 1
	pending_cnc_blueprint     = ""
	## GK state is recreated fresh below (the old `if gk_discipline == null` left stale GK data).
	gk_discipline             = null
	## S37.29 (#52 follow-up audit): more persistent state that had no new-game reset.
	active_wra_submissions    = []
	wra_approved_blueprints   = []
	wra_rejected_blueprints   = []
	dismissed_todo_items      = []
	weeks_in_negative         = 0
	bankruptcy_screen_shown   = false
	ceo_accumulated_salary    = 0.0
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
	_ai_championship_sim = AIChampionshipSim.new(self)
	_commercial_market = CommercialMarketSim.new()   ## S38.1
	_commercial_market.seed_market(true)             ## staggered mid-life AI models → mature industry on day one
	## S39.7 — state-handler discipline (§15.2): reset all commercial player-state on new game so a
	## prior game's lines/renames/unlock-ledger can't leak into a fresh career in the same session.
	commercial_lines = []
	pending_commercial_rename = []
	commercial_share_milestone_hit = {}   ## S40.0 — clear milestone ledger for a fresh career
	championships_ever_raced = []
	_racing_income_window = [0.0, 0.0, 0.0, 0.0]   ## S38.3 cap-anchor window — fresh per career
	_racing_income_this_week = 0.0
	_contract_engine = ContractEngine.new(self)
	_rnd_engine = RnDEngine.new(self)
	_notification_manager = NotificationManager.new(self)
	_campus_manager = CampusManager.new(self)
	_setup_championship()
	_setup_player_team()
	player_team.balance = float(p_starting_budget)
	season_start_balance = player_team.balance   ## S40.14 — season-1 profit basis
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
	_record_ever_raced()   ## S38.5 — seed the Pillar-5 unlock ledger
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
	_economy_phase0 = randf() * TAU   ## S38.4 — desync each career's economic cycle
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
	## S37.63 — news_feed is NOT cleared weekly (news persists so the player can see recent race
	## results, signings, titles). Cap it so it can't grow unbounded over a long season.
	if news_feed.size() > 60:
		news_feed = news_feed.slice(news_feed.size() - 60, news_feed.size())
	_purge_old_notifications(2)

	# Guard: never advance past max_weeks
	if current_week >= max_weeks:
		_end_season()
		return

	current_week += 1

	## S38.3 — roll the racing-income window so this week's prizes/sponsor credits accumulate fresh.
	_roll_racing_income_window()

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
			notify_event("counter_%s" % subj, "High",
				"📋 %s has counter-offered — return to negotiate." % subj, "hq", "event")
			emit_signal("negotiation_updated")

	## Record weekly snapshot for P32 graphs
	_record_weekly_history()

	## Update economy state and fuel price fluctuations
	_update_economy_and_fuel()
	## S38.2 — advance the commercial market AFTER the economy updates (demand reads economy_index).
	_tick_commercial_market()
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
			## CP4 follow-up — GK special case: the player's REAL GK race is run via _simulate_race
			## ONLY when the player actually races GK (group 0 = the player's group). When the player
			## is NOT in GK, group 0 is an ordinary AI group covered by the shadow sim below, so the
			## real sim is skipped for C-001 to avoid (a) double-simulating group 0 and (b) queuing a
			## GK result screen for a non-GK player (the reported "GK is still there" symptom). The GK
			## world still advances: the semifinal hook (below) and the shadow-sim / round-advance
			## blocks after this loop drive every GK group, including group 0.
			var gk_skip_real_sim = (champ.id == "C-001" and gk_discipline != null
				and not gk_discipline.player_in_gk)
			if not gk_skip_real_sim:
				if is_player_champ:
					## S35.3: when fast-forwarding to season end, the CFO keeps the cars race-ready
					## (buys exact fuel/SP shortfall, if hired + affordable) BEFORE the requirement
					## check and simulation — so a skipped season doesn't DNS purely for un-bought
					## logistics. No effect in hands-on weekly play (flag is false then).
					if simulating_to_season_end:
						cfo_auto_buy_for_race(champ)
					_check_race_requirements_for(champ)
					## S37.43 — BUGFIX: _simulate_race is the PLAYER's race (it filters to
					## player_team_cars for this champ). It was OUTSIDE this is_player_champ guard, so
					## it ran for EVERY championship the player isn't in → spurious "DNS: No car
					## assigned [RALLY3/TC/EPC…]" spam each race week. Gate it on is_player_champ; AI
					## championships still advance via champ.current_round below and the AI/shadow path.
					_simulate_race(race, champ)
				elif champ.id != "C-001":
					## S37.47 — LIVING WORLD: non-player, non-GK championships run the lightweight
					## AIChampionshipSim (strength scalar → finishing order → points via the existing
					## points table) so their standings populate and Racing World shows real tables.
					## This does NOT run the player's race code (no DNS spam — the S37.43 fix stands);
					## it only awards AI results. GK (C-001) is excluded — it has its own shadow sim
					## below. The player's championship is handled by _simulate_race above.
					_ai_championship_sim.simulate_round(champ)
			## Sponsor race bonuses handled by apply_sponsor_race_bonuses()
			champ.current_round += 1

			## GK final weekend (race-aware, final round only): when the SEMI-FINAL has just run,
			## simulate the AI groups' semi, then cut top-N-per-group into a single Grand Final
			## group, and re-sync the player's GK race field to those finalists — so the very next
			## race (the Grand Final, same week) is contested by the 20 survivors. The player's real
			## semi result is already synced into GK group 0 by _simulate_race (Option B). This runs
			## regardless of whether the player is in GK — the GK world's final weekend must resolve.
			if champ.id == "C-001" and gk_discipline != null and race.get("is_semifinal", false):
				## AI semi for the non-player final groups (so their results exist before the cut).
				var semi_team_pts = gk_discipline.shadow_simulate_week(current_week, all_drivers)
				for tid in semi_team_pts:
					champ.add_team_points(tid, semi_team_pts[tid])
				## Cut to the finalists and collapse into one Grand Final group.
				gk_discipline.apply_semifinal_cut()
				## Re-sync the player's GK standings/field to the finalists (group 0 now = final 20).
				_sync_gk_group0_to_standings()
				## CP4 follow-up — when the player is NOT in GK, the real sim doesn't run the Grand
				## Final (group 0). Simulate the collapsed final group here so the GK champion is
				## decided by an actual race rather than the reset (all-zero) standings order. When the
				## player IS in GK, the Grand Final runs via _simulate_race below as before.
				if not gk_discipline.player_in_gk:
					var final_team_pts = gk_discipline.shadow_simulate_week(current_week, all_drivers)
					for tid in final_team_pts:
						champ.add_team_points(tid, final_team_pts[tid])

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
			## Bug 9 / CP4 follow-up: only surface GK round notifications to the player if they
			## ACTUALLY race GK this season (registered AND fielding a GK driver) — not merely
			## registered. The shadow world still advances above; a non-GK career (e.g. Rally/GP4)
			## must not receive GK elimination/round messages.
			var player_in_gk = gk_discipline.player_in_gk
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
						notify_event("gk_player_eliminated", "High",
							"🏁 Your driver was eliminated at the end of GK Round %d. Season over for GK." % this_gk_round,
							"", "standing")
				elif this_gk_round >= 4 or gk_discipline.is_complete():
					## S28.3 (Bug 2): Round 4 is the final — no "Round 5". Announce the champion.
					var champ = gk_discipline.get_champion()
					if not champ.is_empty():
						var cd = all_drivers.get(champ.get("driver_id", ""), null)
						var cname = cd.full_name() if cd else "Unknown"
						notify_event("gk_champion_s%d" % current_season, "Normal",
							"🏆 GK Championship complete — Champion: %s (%d pts)." % [cname, champ.get("points", 0)], "", "news")
					else:
						notify_event("gk_season_done", "Normal", "🏁 GK Championship complete for the season.", "", "event")
				elif not player_eliminated and new_round <= 4:
					notify_event("gk_round_%d" % this_gk_round, "Normal",
						"✅ GK Round %d complete — advancing to Round %d!" % [this_gk_round, new_round], "", "event")

	# ── CFO optional hint (one-time, framework) ───────────────────────────────
	## CFO is good-to-have, not required. Fire ONE notification ever if the player has none
	## (notify_event "once" tracks this) — with a button to the Staff screen. The standing
	## "no CFO" reminder lives in the read-only TO-DO list, which never notifies. Placed BEFORE
	## the race-result early-return below so it runs even on weeks the player races.
	if get_cfo() == null:
		notify_event("no_cfo", "Normal",
			"💼 No CFO on staff (optional). A CFO improves contract terms, financial intel and "
			+ "auto-buys race logistics. Hire one from the Staff screen if you want those.",
			"staff_hub", "once")

	# ── Championship registration deadline warnings ───────────────────────────
	## ONE consolidated notification for championships whose NEXT-SEASON registration deadline is
	## imminent (this week or next). Runs every week BEFORE the race-result early-return so a race
	## week can't skip it. Fires for ALL such championships regardless of budget — the player
	## decides how to fund the entry (loan, sell, etc.).
	var closing_next_week: Array = []
	for champ_id in CHAMPIONSHIP_REGISTRY:
		if champ_id in next_season_registrations:
			continue  ## already secured for next season
		var dl_gap = get_entry_deadline_week(champ_id) - current_week
		if dl_gap == 0 or dl_gap == 1:   ## the week before, or the deadline week itself
			closing_next_week.append(CHAMPIONSHIP_REGISTRY[champ_id].get("name", champ_id))
	if not closing_next_week.is_empty():
		var list_txt = ", ".join(closing_next_week)
		add_log("🔔 Registration deadline imminent (wk %d) for: %s" % [current_week, list_txt])
		notify_event("reg_deadline_all", "High",
			"⚠ Championship registration closes this week or next for: %s. Register at HQ → WRA." % list_txt,
			"hq", "standing")

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
	## S38.2 — age the commercial market one season (AI auto-refresh near end-of-life) and age the
	## player's own models so their freshness/lifecycle advances (§4.2).
	if _commercial_market != null:
		_commercial_market.advance_season()
	for line in commercial_lines:
		line["age_seasons"] = float(line.get("age_seasons", 0.0)) + 1.0

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
	var driver_total = team.drivers.size()
	if driver_total == 0:
		return
	## Bug 9: use the team's ACTUAL championship, not a hardcoded GK (C-001).
	## Falls back to C-001 only if the team has no registered championship.
	var team_champ_id = "C-001"
	if team.active_championships.size() > 0:
		team_champ_id = team.active_championships[0]
	var champ_reg = CHAMPIONSHIP_REGISTRY.get(team_champ_id, {})
	var champ_disc = champ_reg.get("discipline", "GK")
	## S37.60 — a multi-driver discipline packs `dpc` drivers per car, so the car count is
	## the driver pool divided by seats-per-car (not one car per driver).
	var dpc = get_drivers_per_car(team_champ_id)
	var driver_count = int(ceil(float(driver_total) / float(max(1, dpc))))
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
		## S37.60 — seat the car to the discipline rule and pack consecutive drivers in.
		car.set_seat_count(dpc)
		for s in range(dpc):
			var di = i * dpc + s
			car.driver_ids[s] = team.drivers[di] if di < team.drivers.size() else ""
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
	notify_event("autosave_s%d_w%d" % [current_season, current_week], "Normal", "💾 Game autosaved (slot %d)." % slot, "", "event")

## S37.26 — loads the static race calendar (all championships' schedules) from the data JSON.
## Called once at engine init. Safe no-op if the file is missing.
func _load_part_costs() -> void:
	var path := "res://data/part_costs.json"
	if not FileAccess.file_exists(path):
		push_warning("part_costs.json not found — falling back to hardcoded PART_COSTS.")
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) == TYPE_DICTIONARY:
		part_costs_data = parsed
	else:
		push_warning("part_costs.json did not parse to a Dictionary.")

## Per-unit PURCHASE price for a part in a championship (already includes manufacturer
## profit + quality). Falls back to the legacy hardcoded PART_COSTS if the JSON is absent.
func get_part_unit_price(champ_id: String, part_name: String) -> int:
	if not part_costs_data.is_empty():
		var prices: Dictionary = part_costs_data.get("unit_prices", {})
		if champ_id in prices and part_name in prices[champ_id]:
			return int(prices[champ_id][part_name])
	return int(PART_COSTS.get(champ_id, {}).get(part_name, 0))

## Full per-championship price map { part: unit_price } (for warehouse display).
func get_part_prices(champ_id: String) -> Dictionary:
	if not part_costs_data.is_empty():
		var prices: Dictionary = part_costs_data.get("unit_prices", {})
		if champ_id in prices:
			return prices[champ_id].duplicate()
	return PART_COSTS.get(champ_id, {}).duplicate()

func _load_race_calendar() -> void:
	var path := "res://data/race_calendar.json"
	if not FileAccess.file_exists(path):
		push_warning("race_calendar.json not found at %s — calendar races will be empty." % path)
		return
	var txt := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		race_calendar_data = parsed
	else:
		push_warning("race_calendar.json did not parse to a Dictionary.")

## S37.59 — Returns the display CITY for a given championship+round from race_calendar.json
## (the canonical visual schedule). The race ENGINE still runs off CHAMPIONSHIP_CALENDARS, but the
## UI should show the JSON's place names (e.g. "Tours", not the engine's branded "Le Mans"). Returns
## "" if the round isn't present in the JSON (e.g. GK's engine-only round 22 Grand Final), so callers
## can fall back to the engine entry's own name.
func get_calendar_city(cid: String, round_num: int) -> String:
	var champs: Dictionary = race_calendar_data.get("championships", {})
	var champ: Dictionary = champs.get(cid, {})
	for rd in champ.get("rounds", []):
		if int(rd.get("round", -1)) == round_num:
			return str(rd.get("city", ""))
	return ""

## S37.60 — Highest round number present for GK (C-001) in race_calendar.json. The engine numbers GK
## with an extra Grand Final round (semi=21, final=22) that the JSON doesn't have (JSON final=21), so
## the Results screen uses this to fetch the JSON city for the GK final (so the remap applies).
func get_gk_final_json_round() -> int:
	var champs: Dictionary = race_calendar_data.get("championships", {})
	var champ: Dictionary = champs.get("C-001", {})
	var hi: int = 0
	for rd in champ.get("rounds", []):
		hi = max(hi, int(rd.get("round", 0)))
	return hi

## S37.26 — cached CalendarManager accessor (preload-based, no class_name dependency).
func get_calendar_manager():
	if _calendar_manager == null:
		_calendar_manager = _CalendarManagerScript.new(self)
	return _calendar_manager

func save_game() -> void:
	var save_data = {
		"version": 1,
		"current_week": current_week,
		"current_season": current_season,
		"season_start_balance": season_start_balance,   ## S40.14 — tax profit basis
		"weekly_log": weekly_log,
		"news_feed": news_feed,
		"hall_of_fame": hall_of_fame,
		"retired_personnel": retired_personnel,
		"player_registered_championships": player_registered_championships,
		"next_season_registrations": next_season_registrations,
		"sponsor_no_points_streak": sponsor_no_points_streak,
		"active_sponsor": active_sponsor,
		## S37.10 — persist the multi-season sponsor system (was previously NOT saved, so a signed
		## commitment vanished on save/load). Arrays of plain dicts → JSON-safe as-is.
		"active_sponsors": active_sponsors,
		"sponsor_offers": sponsor_offers,
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
		"active_approaches":         active_approaches.filter(func(ap): return not ap.get("draft", false)),
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
		"economy_phase0":            _economy_phase0,   ## S38.4
		"commercial_market":         _commercial_market.to_dict() if _commercial_market else {},   ## S38.1
		"commercial_lines":          commercial_lines,   ## S38.2 — player production lines
		"pending_commercial_rename":  pending_commercial_rename,   ## S39.7 — pending facelift/nextgen renames
		"commercial_share_milestone_hit": commercial_share_milestone_hit,   ## S40.0 — market-share milestone ledger
		"championships_ever_raced":  championships_ever_raced,   ## S38.5 — Pillar-5 unlock ledger
		"racing_income_window":      _racing_income_window,   ## S38.3 — cap anchor window
		"racing_income_this_week":   _racing_income_this_week,
		"sp_market_pressure":        sp_market_pressure,
		"active_loans":              active_loans,
		"loan_next_id":              _loan_next_id,
		"consecutive_win_counts":    consecutive_win_counts,
		"gk_discipline":             gk_discipline.serialize() if gk_discipline else {},
		"custom_todo_items":         custom_todo_items,
		"custom_calendar_events":    custom_calendar_events,   ## S37.26
		"notifications":             notifications,                 ## S37.28 (#52)
		"unread_notification_count": unread_notification_count,     ## S37.28 (#52)
		## S37.29 (#52 audit): persistent state that was being lost on save/load.
		"active_wra_submissions":    active_wra_submissions,
		"wra_approved_blueprints":   wra_approved_blueprints,
		"wra_rejected_blueprints":   wra_rejected_blueprints,
		"dismissed_todo_items":      dismissed_todo_items,
		"weeks_in_negative":         weeks_in_negative,
		"bankruptcy_screen_shown":   bankruptcy_screen_shown,
		"ceo_accumulated_salary":    ceo_accumulated_salary,
		## Player identity / config (were resetting to defaults on load).
		"player_name":               player_name,
		"player_team_name":          player_team_name,
		"player_team_nationality":   player_team_nationality,
		"ceo_age":                   ceo_age,
		"ceo_sex":                   ceo_sex,
		"game_difficulty":           game_difficulty,
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
	## S40.14 — tax profit basis. Sentinel -1 marks an old save with no stored basis; we snapshot it
	## to the player's balance once the team is loaded (below), so no retroactive tax on load.
	season_start_balance = data.get("season_start_balance", -1.0)
	weekly_log.clear()
	for entry in data["weekly_log"]:
		weekly_log.append(str(entry))
	news_feed.clear()
	for entry in data.get("news_feed", []):	## S37.63 — default empty for pre-S37.63 saves
		news_feed.append(str(entry))
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
	## S37.10 — restore the multi-season sponsor system (back-compatible: older saves omit these).
	active_sponsors = data.get("active_sponsors", [])
	sponsor_offers = data.get("sponsor_offers", [])
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
	## S38.4 — regime phase; pre-S38.4 saves get a fresh random phase so their economy starts cycling.
	_economy_phase0 = float(data["economy_phase0"]) if "economy_phase0" in data else randf() * TAU
	## S38.1 — Commercial market: restore if present; pre-Phase-3 saves get a fresh staggered seed
	## so an in-progress career still gains the road-car industry.
	if _commercial_market == null:
		_commercial_market = CommercialMarketSim.new()
	if "commercial_market" in data and data["commercial_market"] is Dictionary and not data["commercial_market"].is_empty():
		_commercial_market.from_dict(data["commercial_market"])
	else:
		_commercial_market.seed_market(true)
	commercial_lines = data.get("commercial_lines", [])   ## S38.2 (empty for pre-Phase-3 / no-Factory saves)
	pending_commercial_rename = data.get("pending_commercial_rename", [])   ## S39.7
	commercial_share_milestone_hit = data.get("commercial_share_milestone_hit", {})   ## S40.0 (empty pre-S40.0)
	## S38.5 — Pillar-5 unlock ledger; backfill from current registrations for pre-S38.5 saves.
	championships_ever_raced = data.get("championships_ever_raced", [])
	for cid in player_registered_championships:
		if not cid in championships_ever_raced:
			championships_ever_raced.append(cid)
	_racing_income_window = data.get("racing_income_window", [0.0, 0.0, 0.0, 0.0])   ## S38.3
	_racing_income_this_week = float(data.get("racing_income_this_week", 0.0))
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
	if "custom_calendar_events" in data: custom_calendar_events = data["custom_calendar_events"]   ## S37.26
	## ── S37.28 (#52): clear transient session state the save does NOT carry, so a loaded game
	## doesn't inherit the CURRENT session's leftovers. Notifications + the pending_* routing
	## strings aren't serialized; without this they'd bleed across a load.
	notifications             = data.get("notifications", [])
	unread_notification_count = int(data.get("unread_notification_count", 0))
	pending_season_screen     = ""
	pending_hq_tab            = ""
	pending_campus_zone       = ""
	pending_staff_filter      = ""
	pending_rnd_champ_id      = ""
	pending_rnd_pillar        = 1
	pending_cnc_blueprint     = ""
	## S37.29 (#52 audit): restore persistent state that previously reset on load.
	active_wra_submissions    = data.get("active_wra_submissions", [])
	wra_approved_blueprints   = data.get("wra_approved_blueprints", [])
	wra_rejected_blueprints   = data.get("wra_rejected_blueprints", [])
	dismissed_todo_items      = data.get("dismissed_todo_items", [])
	weeks_in_negative         = int(data.get("weeks_in_negative", 0))
	bankruptcy_screen_shown   = bool(data.get("bankruptcy_screen_shown", false))
	ceo_accumulated_salary    = float(data.get("ceo_accumulated_salary", 0.0))
	## Player identity / config.
	player_name               = data.get("player_name", player_name)
	player_team_name          = data.get("player_team_name", player_team_name)
	player_team_nationality   = data.get("player_team_nationality", player_team_nationality)
	ceo_age                   = int(data.get("ceo_age", ceo_age))
	ceo_sex                   = data.get("ceo_sex", ceo_sex)
	game_difficulty           = data.get("game_difficulty", game_difficulty)

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

	## S40.14 — old saves (no stored tax basis): anchor to the current balance so the next season-end
	## only taxes profit earned from here, not the whole accumulated balance.
	if season_start_balance < 0.0:
		season_start_balance = player_team.balance if player_team != null else 0.0

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
	_ai_championship_sim = AIChampionshipSim.new(self)
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
			"driver_ids": car.driver_ids.duplicate(), "driver_id": car.driver_id,
			"mechanic_id": car.mechanic_id,
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
		## S37.60 — restore the multi-seat driver array. New saves carry "driver_ids";
		## pre-S37.60 saves carry only the scalar "driver_id" → migrate it onto seat 0 and
		## size the array to the championship's drivers-per-car rule so co-driver seats exist.
		var _seats := get_drivers_per_car(cd.get("championship_id", car.championship_id))
		if cd.has("driver_ids") and cd["driver_ids"] is Array:
			car.driver_ids = (cd["driver_ids"] as Array).duplicate()
			car.set_seat_count(max(_seats, car.driver_ids.size()))
		else:
			car._migrate_legacy_driver(cd.get("driver_id", ""), _seats)
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
			"talent_scouting": s.talent_scouting,
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
		s.talent_scouting = sd.get("talent_scouting", 0.0)
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
		## S37.46 — screenshot notification removed (log-only, per design); add_log below keeps it.
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

## ═══ LEAD DESIGNER PROPOSAL ENGINE — delegated to LeadDesignerProposalEngine.gd (S40.0) ═══

## Generates + fires the Lead Designer proposal (notification + TDL), caches the result.
func generate_design_proposals() -> Array:
	_last_design_proposals = _lead_designer_engine.generate_design_proposals()
	return _last_design_proposals

## Read-only compute for the R&D Studio panel — no notification/TDL fire (mirrors peek_tp_proposals).
func peek_design_proposals() -> Array:
	return _lead_designer_engine.compute_design_queue(player_team, player_team_cars)

## Applies accepted Lead Designer proposals (starts the queued blueprints on the Lead).
func apply_design_proposals(proposals: Array) -> void:
	_lead_designer_engine.apply_design_proposals(proposals)

## Convenience pass-throughs to the capacity system (UI: show lines, comfort, idle-line state).
func get_design_line_capacity() -> int:
	return _rnd_engine.get_design_line_capacity()

func get_free_design_lines() -> int:
	return _rnd_engine.get_free_design_lines()

func get_lead_designer_id() -> String:
	return _rnd_engine.get_lead_designer_id()

## S40.15 — Lead comfort C + active-line count, for the R&D Studio status panel.
func get_comfort_lines(designer_id: String) -> int:
	return _rnd_engine.get_comfort_lines(designer_id)

func get_active_lines_for(designer_id: String) -> int:
	return _rnd_engine.get_active_lines_for(designer_id)

func can_run_rnd() -> bool:
	return _rnd_engine.can_run_rnd()

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
