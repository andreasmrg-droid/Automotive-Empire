# Automotive Empire — Game Design Document

**Version:** v7.14 (consolidated master) · **Engine:** Godot 4.7 / GDScript
<!-- v7.14: (S41.12) SEASON-BOUNDARY CRASH — FIXED, + rollover notification clear, + DIAG reverted.
	ROOT CAUSE PINNED (from the S7→S8 playtest crash, godot.log): the reproducible season-boundary SIGSEGV
	is a HUD-rebuild stack overflow in Godot's C++ container-layout pass (backtrace = a single frame
	self-recursing), NOT game logic — exactly where the v7.13 diagnosis localized it (MainHub post-skip
	rebuild). MECHANISM: news_feed was capped to 60 ONLY at the top of advance_week(); log_news() appended
	UNCAPPED. At W52 the rollover's Stage-E cull logs one log_news line PER retiree — 117 at the S7→S8
	boundary vs ~25 at every earlier boundary — so news_feed swelled to ~180 AFTER that tick's cap had
	already run. advance_week returned cleanly; then _on_skip_to_season_end → _refresh_log built ~180
	autowrap + fixed-min-width Labels into a VBox inside a ScrollContainer, and the layout solver recursed
	past the stack limit. The existing 60-cap would have trimmed it, but it only fires on the NEXT
	advance_week, which never runs. This is why it reproduced at EVERY boundary but only DEEP into a run
	(you need a retirement wave big enough to push the label count over the recursion limit — the earlier
	"scales with no_lead/world-growth" guess was wrong; no_lead was flat at 5, the driver is per-boundary
	retiree count). FIX (GameState.gd): log_news() now SELF-CAPS at NEWS_FEED_CAP (=20) on every append, so
	the feed can never reach the rebuild oversized regardless of caller or timing; the advance_week weekly
	cap is unified to the same constant as a cheap backstop. Only the news-panel DISPLAY is bounded —
	retirements, rosters, standings, and the retired_personnel History archive are all untouched. §13.2.1
	updated. (2) ROLLOVER NOTIFICATION CLEAR (SeasonManager.start_new_season): gs.clear_all_notifications()
	now runs at rollover start — BEFORE the Stage-E cull / aging pass — so last season's operational noise
	(low fuel, missed registration deadline, DNS readiness) is wiped while the genuine NEW-season
	notifications that pass generates ("your driver retired — sign a replacement", "car needs building") are
	preserved. §15 updated. (3) DIAG REVERTED: the S41.7-DIAG2 [WKDIAG] prints (GameState) and the
	S41.11-DIAG [ROLLDIAG] helper + all A→L call sites (SeasonManager) are removed now the crash is pinned.
	OBSERVED-BUT-NOT-FIXED (flagged, separate): the S7→S8 boundary retired 117 vs a steady ~25 — a
	retirement-wave spike from the staff hard-retire-at-65 cliff catching an age-clustered seed cohort. Not
	the crash (the cap fixes the crash at any wave size) but worth smoothing later (§12 aging). The v7.13
	from-scratch first-team weeks gap (§8.6) is STILL open — untouched this session, independent of the
	crash. Files: GameState.gd, SeasonManager.gd. Analysis-checked (brace-balance + type-inference audit);
	NOT Godot-parsed — verify by fast-forwarding through the S7→S8 boundary (and beyond) without a crash. -->
<!-- v7.13: (S41.11 diagnosis session) TWO FINDINGS FROM THE SEASON-ROLLOVER CRASH HUNT — no gameplay code
	changed this session; this is a diagnosis + documentation pass. [RESOLVED in v7.14 — crash fixed, DIAG
	reverted.] Temporary instrumentation existed in the tree (see below) and had to be reverted once fixed.

	(1) CRASH LOCALIZED — season-boundary SIGSEGV is a UI-rebuild stack overflow, NOT game logic.
	Symptom: reproducible crash-to-desktop (signal 11, C++ stack overflow; backtrace shows one function
	self-recursing — frame main+259f90e repeated, entered from the scene-tree/layout layer) at every
	season boundary when fast-forwarding to season end; triggers deeper into a run (seen S8, S9, S14→15,
	S15→16, S17→18). Method: flushed print breadcrumbs proved, in order, that (a) end_season/start_new_season
	run to completion (all [ROLLDIAG] stages Z0→L print), and (b) advance_week()'s W52 body runs to completion
	AND returns cleanly (all [WKDIAG] probes print, incl. "advance_week RETURNED cleanly"). The crash occurs
	AFTER advance_week returns, with no intervening log output. The only code there is MainHub._on_skip_to_
	season_end() → _update_display() + _refresh_log() (scenes/MainHub.gd ~L797-798). So the fault is in the
	post-skip HUD REBUILD, not the rollover, cull, prune, planner, autosave, or any saved data — all of which
	were falsified (save depth flat at 7, save size SHRINKING 7.25→6.2→5.37MB, all_staff DECREASING). Leading
	suspect: one of the refresh builders _update_display() calls — _refresh_notifications (the only self-
	referential builder; builds nested containers per notification), _refresh_todo, or _refresh_week_strip —
	recursing in the scene-tree layout pass. NOT yet pinned to the exact builder/line; next session instruments
	those 4 refresh calls to name it. Correlates with world growth: no_lead climbs 19→22→35→42→50→56 and
	reached_planner falls 167→…→116 across the run, so the recursing rebuild scales with accumulated state.

	(2) BLUEPRINT WEEKS — first-time-team from-scratch case NOT implemented (real code-vs-canon gap).
	Canon (§8.6): L1 design weeks are FULL from-scratch (WRA cycle start) and HALVED on a mid-cycle refresh.
	A team's FIRST-EVER design of a car should ALSO be full-weeks even mid-cycle (first time = from scratch),
	per the design owner. Code: RnDEngine._rebuild_seasonal_rnd_tasks() sets l1_wk_mult via
	_is_from_scratch_design(cid, design_season), which returns (_wra_group_season_for(cid, design_season)==1)
	— i.e. it checks ONLY the cycle boundary, has NO team parameter, and there is NO per-team first-design/
	entry-season tracking anywhere in the codebase. Also RND_TASKS[tid]["weeks"] is a single GLOBAL value per
	task, so two durations (full for a newcomer, half for incumbents) for the same blueprint/season cannot even
	be represented as structured today. Consequence (as flagged by the design owner): a team entering mid-cycle
	is scheduled by the planner (_latest_safe_start reads that halved weeks) at half the weeks it needs, starts
	too late, and fields NO next-season car. FIX (not yet done — needs an owner decision): add per-team first-
	design tracking and make the weeks decision team-aware (planner + RnD start path apply the first-time full-
	weeks multiplier per team, since the shared task can't). SEPARATE from the crash; no evidence they're linked.
	§8.6/§8.7 annotated below.
	NOTE: temporary DIAG instrumentation lives in SeasonManager.gd (S41.11-DIAG, [ROLLDIAG] prints) and
	GameState.gd (S41.7-DIAG2, [WKDIAG] prints). Both are print-only, no logic change; REVERT after the fix. -->
<!-- v7.12: (S41.7–S41.10) AI R&D ECONOMY — LOAD FIX, DESIGN-COST REBALANCE, INTERIM BUDGET, LEDGER PRUNE.
	(S41.7) CRITICAL LOAD-PATH FIX: ai_cars (the {championship_id → [Car]} dict linking every AI team to
	its championships) was never serialised and never rebuilt on load, so a loaded save left it empty →
	get_cars_for_team(ai_team) returned [] → the AI R&D planner early-outed "no_championships" for all 172
	teams every week AND AIChampionshipSim stopped awarding AI standings. FIX: save_game serialises ai_cars
	(new _serialize_ai_cars, verbatim incl. mid-season condition/parts per owner choice); load_game restores
	via _deserialize_ai_cars right after the player cars. Old saves without the key self-heal at the next
	rollover. §7/§8.7 updated. File: GameState.gd. CONFIRMED WORKING in-game by the user.
	(S41.8/S41.8b) DESIGN-COST REBALANCE (P1/P3 L1 CR only): the L1 blueprint design CR was a flat
	~104k/152k × tier_mult, decoupled from the car's value, so self-designing a GK car cost 16× its
	manufacturing cost while a GP1 car cost ~1%. Now whole-car P1 L1 design CR = CNC_DATA.base_total_cost ×
	DESIGN_RATIO[tier] (T1 0.6 / T2 1.0 / T3 1.8 / T4 3.5), split by locked per-part weights; P3 L1 CR =
	0.8 × the matching P1 (S41.8b — RE is the cheaper budget/survival route, replacing the old RE premium).
	WEEKS (incl. the §8.6 refresh half-weeks), RP, effects/values, L2 and all P2 tiers UNCHANGED. §8.6/§8.7
	updated. File: RnDEngine.gd.
	(S41.9) INTERIM AI BUDGET GRANT: AI teams have NO income wired (FinancialEngine only drains salaries),
	so balances bled to zero and the R&D CR/feasibility gates falsely locked teams out. start_new_season()
	now credits each non-player team, per championship it's registered in, (entry_fee + car_buy_cost +
	2-car season salaries + 6× P1 L1 design CR) × 1.30 — LIVE-sourced so it tracks cost tuning. STOPGAP for
	the missing §3 AI economy; remove when real income streams land. §13.3 updated. File: SeasonManager.gd.
	(S41.10) AI-LEDGER ROLLOVER PRUNE: the player's rollover P2/UPG purge was never mirrored to the 172 AI
	ledgers, so completed_upg / P2 blueprints / WRA entries accumulated unbounded each season (a modest
	memory leak). prune_ai_ledgers_for_new_season() now mirrors the player prune exactly, per AI ledger,
	each rollover. Files: RnDEngine.gd, SeasonManager.gd.
	KNOWN INTERIM IMBALANCES (flagged for revisit when the AI-CnC market is built — see §13.3): with the
	grant + generous double-cover in place, ~90% of AI teams now self-design every season (up from ~50%),
	and the grant injects ~4.2 BILLION CR/season across the grid (dominated by GP1 at ~158M/team). These are
	artifacts of an intentionally imbalanced stopgap economy created purely to unblock AI R&D; the real
	picture only emerges once the AI CnC buy-vs-build market exists. DO NOT read these as intended balance.
	FUTURE TASK (flagged, §7.1/§19): retired_personnel / history archives grow unbounded — at season 60–100
	this matters; filter archived entries to highly-rated personnel (threshold TBD) rather than everyone.
	All S41.7–S41.10 analysis-checked (brace-balance + type audit) EXCEPT S41.7 which is user-confirmed
	working; S41.8b/S41.9/S41.10 await the user's parse/playtest. A fast-forward-to-end playtest crashed to
	desktop at ~S8; log was truncated with no error captured — cause NOT yet identified (the ledger leak is
	real but ~MB-scale, too small to be the crash). User re-running with per-season output to diagnose. -->
<!-- v7.11: (S41.6) AI R&D ECONOMY — PHASE 5 (THE PLANNER). Activates the forecast-driven scheduler in
	LeadDesignerProposalEngine that SPENDS AI teams' banked RP, run every week from advance_week (after
	the race loop). Per team: computes the next-season car's latest-safe-start week; before it fills idle
	lines with surplus-gated P2 upgrades; at it switches to the 6-part P1/P3 next-season car; a
	FEASIBILITY GATE holds a team on its granted baseline rather than over-committing if the RP forecast
	can't land the car by deadline (full retreat/backfill = step 6). Per-part P3-vs-P1 is survival-first
	(P3 where Logistics-provenance allows, else P1) with P3→P1 upgrades on forecast surplus; the Lead's
	`planning` attribute modulates the safe-start buffer. P4/P5 stay inert (future AI ladder). ECONOMICS:
	AI cars are free-granted today so the research reads as on-track UPLIFT; the per-part decision is
	built forward-compatibly and the NEXT project (AI CnC) attaches buy-vs-build + part RESALE at
	_cnc_buy_vs_build_hook WITHOUT rewriting the planner. Debug-log only ([AIPlan] …), no player news, per
	owner. §13.3 updated. Files: LeadDesignerProposalEngine.gd, GameState.gd. Analysis-checked
	(brace-balance + type audit; cross-file arg-count + method-existence verified); user parses/playtests. -->
<!-- v7.10: (S41.5) LOAD-PATH ENGINE SYMMETRY FIX (resolves the v7.9 flagged item). load_game() now
	re-instantiates all 6 previously-missing engine singletons (_sponsor_manager, _staff_manager,
	_car_manager, _driver_manager, _tp_engine, _lead_designer_engine), matching _ready/setup_new_game.
	CORRECTION to the v7.9 note: nothing was actually null after a load — GameState is an autoload, so
	_ready() always runs first and creates all 16 engines; the real (narrow) issue was stale live cache
	carried across a load-after-play, notably TPProposalEngine._tp_roster_snapshot mis-firing
	_tp_roster_changed() on the first post-load week. Re-init clears it and gives the AI R&D planner
	(step 5) a fresh _lead_designer_engine after a load. (_commercial_market keeps its own
	restore-from-data path; _calendar_manager is stateless, left as-is.) File: GameState.gd.
	Analysis-checked; parse-verified against the 6 constructors' single-arg signatures; user playtests. -->
<!-- v7.9: (S41.4) AI R&D ECONOMY — PHASE 4 (RP faucet mirror). AI teams now EARN Research Points by
	the same distance-km faucet the player uses (§8.4): after AIChampionshipSim.simulate_round awards a
	round's points, _ai_earn_race_rp_for_champ credits each non-player team that fielded a running car,
	summed per running car, into its rnd_ledger.rp — capped by the team-aware RP storage cap.
	earn_race_rp gained an optional `team` (player path byte-identical). AI Studio level is seeded from
	teams.json buildings["RnD Studio"] at team generation, CLAMPED to the player's 1..27 R&D Design
	Studio scale (the one balance-tunable knob for AI development speed); the AI Lead is the team's
	highest-overall Designer; the difficulty knob is `ai_performance`. AI ledgers now FILL during racing
	but SPENDING still awaits the planner (build-order step 5) — so this phase changes no race results
	yet. §8.7 + §13.3 updated. Files: RaceSimulator.gd, GameState.gd, AIManager.gd, RnDEngine.gd
	(team-aware cap). Analysis-checked (brace-balance + type audit); user parses/playtests. RESOLVED in
	v7.10: the load_game() engine re-init gap noted here. -->
<!-- v7.8: (S41.2–S41.3) AI R&D ECONOMY — PHASE 3 (per-team RP ledger + routing). The storage
	substrate for AI research landed: every non-player team now has a parallel `rnd_ledger` meta
	(rp / active_tasks / completed_* / known_blueprints / wra_* / studio_level) that mirrors the
	player's six singular R&D globals — the "pattern B" decision (do NOT rewrite the ~170 player-global
	call-sites; give AI a parallel store like the existing rnd_bonuses meta). The R&D pipeline functions
	are now team-routed via an optional `team` param (default → player): rnd_task_unlocked (P3 provenance
	resolves against the requesting team's cars), rnd_task_active_or_done, start_rnd_task, submit_to_wra,
	_advance_wra_submissions, _advance_rnd_tasks, _apply_rnd_effect, is_blueprint_approved/submitted. The
	PLAYER path is byte-for-byte unchanged (every existing call omits `team` → hits the same globals).
	AI ledgers save/load per team (fresh-seed fallback for old saves). SCOPE: this is storage + routing
	ONLY — the AI RP FAUCET (spec §5), the forecast PLANNER that spends it (§6), retreat/backfill (§7),
	and on-track uplift (§8) are the remaining build-order steps; until they land an AI ledger exists and
	persists but stays EMPTY (intended). §8.7 (new) + §13.3 (new) document the ledger. Files:
	RnDEngine.gd, GameState.gd. Analysis-checked (brace-balance + type audit); user parses/playtests. -->
<!-- v7.7: (S41.0) AI R&D ECONOMY — PHASE 1 (player-facing prerequisites) + the design spec for the
	full build (Supporting Files/AI_RnD_Economy_Spec_v2.md — per-AI-team RP ledger, a shared
	forecast-driven Designer PLANNER, retreat-and-backfill to protect championship integrity, real
	on-track uplift via the §14 AIChampionshipSim swap-point; the AI CnC manufacture/install/RESALE
	mirror is the explicitly-scoped NEXT project). Phase 1 code landed: (1) P3 REVERSE ENGINEERING is
	now offered for ALL parts (spec + open), not spec-only — it was a bug that a team could never RE
	the open parts of a car it bought; startability is gated at runtime by PROVENANCE (the part must
	be on a garage car AND bought via the Logistics centre — not one the team already makes in-house).
	§8 pillar-3 line corrected. (2) WRA submission is a flat 1 week (was a per-tier {1,2,4,5} table).
	(3) WRA REJECTION is now real and scoped to P2 upgrades ONLY at a 10% chance (P1/P3 are ALWAYS
	approved — a late rejection of a next-season car would cause a full-season DNS); a rejected P2 is
	recorded, fires a notification + world news, and costs reputation scaled by championship tier.
	§11 updated. (4) RP_PER_LAP_BASE is now ACTUALLY 3.0 in RaceSimulator (the v7.6 doc anchored 3.0
	but the file still held 1.0; reconciled). Files: RnDEngine.gd, RaceSimulator.gd. Analysis-checked
	(brace-balance + type audit) only; user parses/playtests. AI-side pillars 2–7 of the spec (planning
	attribute, per-team ledger, RP faucet mirror, planner, retreat/backfill, uplift) are NEXT. -->
<!-- v7.6: (S40.5–S40.17) R&D ECONOMY, DESIGN-TIME & TAXATION pass — PARSED & PLAYTESTED (confirmed
	S41.0; the earlier "NOT YET GODOT-PARSED" note is now cleared). (1) RP faucet re-anchored:
	RaceSimulator RP_PER_LAP_BASE 1.0 → 3.0 — fixes the early-game starve on the everyday P1/P2/P3
	tree (fresh Studio L2 needed ~3.7 seasons for one P1 tree) without trivialising P4 (median P4 still
	2–20 seasons, hero 3–95); swept across all pillars, not P4-biased. §8.4 rewritten (the "earned only
	by racing / baseline RP undecided" open question is now RESOLVED — racing-only stays, faucet retuned).
	(2) DESIGN-TIME fix: P1 (and P3-spec) L1 blueprint WEEKS halve on a mid-cycle refresh year
	(P1_REFRESH_WEEKS_MULT 0.5); from-scratch cycle-start years keep full weeks; RP/CR cost unchanged.
	Guarantees every team finishes 6 L1 blueprints before its registration deadline (verified vs real
	budgets). EPC (C-020) & GP1 (C-024) get a registration-deadline override to week 31 so their
	from-scratch pinnacle car fits one season (CNC manufacture time untouched — deadline decoupled).
	New §8.6. (3) CORPORATE TAX added (§3 + new §24): 24% base on season profit, CFO-reduced toward a 15%
	floor, minus P4 tax_reduction; deducted at season end with a notification; shown in HQ Financial Dept.
	(4) P4 effect ACCESSOR LAYER + 4 wired clusters (perf/reliability/fatigue/economy); ~50 effects still
	banked-unwired. (5) One-Lead-per-team data model completed (staff_designer.json surgery: 172 Leads +
	100 FAs); R&D Studio shows Lead capacity/comfort. (6) §11 corrected: WRA cycle is PER-GROUP (4–10
	seasons), not a flat 4 — code was already per-group; doc now matches. [S41.0: parsed & playtested.] -->
<!-- v7.5: (S40.1) ROADMAP #2 — UI CLICK SOUND DONE. New §17.1 Audio. A `UISound` autoload plays a
	short click on every BaseButton press across all scenes via a global `node_added` auto-wire (no
	per-button code). Asset: a cleaned Pixabay "computer mouse click" (universfield) at
	res://resources/audio/ui_click.wav — trimmed/mono/44.1k/normalized ~72 ms; Pixabay License (free
	commercial, no attribution), human-made (not AI-generated, per the asset rule). Runtime synth
	fallback if the WAV is missing; dedicated "UI" audio bus at −6 dB; `enabled`/`volume_db` exposed for
	the future Settings menu (#21). Roadmap item #1 (commercial market news) was already closed at v7.4,
	so #2 is the next done. -->
<!-- v7.4: (S40.0) PHASE 3 TAIL CLOSED + TDL polish. (1) MARKET-SHARE MILESTONE NEWS implemented:
	after the weekly market tick, crossing an upward share threshold (10/20/30/50%) in a segment the
	player actively produces in posts a NEWS event (notification + news feed), routed to the Commercial
	Department; 50% reads as "leading marque." Fires once per ascent; the ledger lowers if share slips
	so a genuine re-climb re-announces; stopping a line clears that segment's ledger. Persisted via the
	new `commercial_share_milestone_hit` dict (saved/loaded/reset on new game — state-handler §15.2).
	Implemented in `GameState._check_commercial_share_milestones`. This was the last open item in
	Phase3_Commercial_Validation §8, so §4 Phase 3 is now fully feature-complete. (2) The optional no-CFO
	TDL row now appends an informative note — "Financial Department is not optimized." — to the same line
	(NOT a second row; the row stays read-only and dismissible, still routed to the Staff screen). (3)
	§18 ROADMAP trimmed to a single pointer line — Road_map.md (supporting files) is now the authority
	on what's next; the old inline roadmap/timeline content was removed to avoid two competing sources. -->
<!-- v7.3: (S38.0–S39.7) PHASE 3 COMMERCIAL CAR INDUSTRY — IMPLEMENTED & ITERATED. §4 moved from
	"designed, not coded" to feature-complete and playtested. Engine, income, economy re-tune, Pillar-5
	catalog + R&D Studio UI, the Commercial Department (list/detail with current-week pie + 5-season
	share-evolution chart), single-source-of-truth income, model naming on Start Production, and
	Facelift/Next-Gen as R&D mini-projects all shipped. KEY REVERSALS vs the v7.2 design: (1) the
	"race the linked championship to unlock a blueprint" gate was REMOVED — blueprints gate on R&D
	Studio level only (researching is already expensive/slow; the racing gate added friction without
	payoff). (2) The "commercial cars are cheaper/faster to design than racing cars" premise was found
	WRONG and inverted — costs are earning-tied (25M–96M CR), every road-car design exceeds the 20M
	GP1 car (see Phase3_Commercial_Validation.md §7B). (3) Halo segments got a ×3 volume boost so they
	can pay back. New §4.8 documents the as-built implementation. Financial Department + R&D-payment
	model flagged for a dedicated ECONOMY-SESSION redesign (see ⚑ near top of changelog). Full save/load
	audit: all 8 new state items saved + loaded + reset on new-game (state-handler §15.2 discipline). -->
<!-- v7.2: (S37.66) PHASE 3 COMMERCIAL CAR INDUSTRY — FULL DESIGN & CALIBRATION (no code yet). §4 rewritten
	from a stub into the complete Factory spec, validated over 100 headless Python seasons. KEY DECISIONS:
	(1) MARKET ENGINE = attractiveness/redistribution (share won by competitiveness, not multiplied from
	current share — the only model where a cold-start player can climb on merit); locked as "v4" with 7 named
	volume GIANTS occupying the mass segments; 0/12 runaways, player climbs 9–29%, monopolies self-cap.
	(2) FACTORY INCOME pegged to RACING income (mature ≈1.18×, hard cap 2× — McLaren-style; the Excel
	real-world margins are ~1000× the game scale so a CREDIT_SCALE≈0.0054 is applied; Excel MSRP/margins kept
	as on-screen flavor). (3) UPGRADE STAIRCASE replaces the broken flat 250K (12.08M…1.2M descending,
	~3-season payback/line, ~66.4M total capex); build cost stays 1.2M. (4) CFO MANDATORY (no CFO → Factory
	off); sales_factor=0.75+sales_skill/200 on Factory road-car sales ONLY. (5) PER-MODEL marketing (18% of
	gross, from revenue). (6) Hard ~25-season model LIFECYCLE (ramp→plateau→death; Facelift/Next-Gen refresh).
	(7) Factory level = production lines (1/level, 12=all segments). (8) ECONOMY CYCLES plug into the existing
	economy_index + per-segment cyclicality (Mass 0.45/Premium 0.25/Hyper 0.08) + sponsor offers soften in
	recessions; DISCOVERED the existing economy is near-flat (never hits Boom/Recession) → re-tune to a slow
	~4-season sine regime (Option A). (9) New COMMERCIAL DEPARTMENT in HQ (read-only market view for ALL
	players, interactive once a Factory is owned) + news/notifications. Full rationale + 100-season simulation
	proof in companion doc Phase3_Commercial_Validation.md. NOT YET CODED — next step is the GDScript port. -->
<!-- v7.1: (S37.65) KEYBOARD-VERIFICATION PASS + INTEREST REBALANCE. Car delivery pipeline (Phase 2, §6.0)
	confirmed working in play; the championship-registration (CP4) and roster-desync/contract-loop clusters
	marked keyboard-verified (§21). Interest model made STRICTER at low reputation (§12 / ContractEngine):
	a new GK garage now sees ~10 interested drivers / ~6–7 staff per role (was ~49 / ~74). Economy is now
	stable enough to begin ROADMAP PHASE 3 (Commercial Factory + R&D Pillar 5 — second income stream). -->
<!-- v7.0: (S37.60–S37.64) BUG #38 CLOSE-OUT (MULTI-DRIVER-PER-CAR / CREW MODEL) + NEWS-vs-NOTIFICATION SPLIT.
	(1) BUG #38 → multi-driver-per-car implemented as a CREW MODEL: a Car holds driver_ids[] sized by the
	discipline rule (Rally/TC = 2, EPC = 3, else 1); co-drivers share ONE car result and ONE points award
	(registered as the seat-0 representative), but ALL co-drivers gain fitness/stat growth and display as a
	combined "Surname / Surname" crew label everywhere (standings, results, Racing World). New game provisions
	a full starting crew; AI cars fill every seat from car_assignments.json. (2) NEWS vs NOTIFICATION SPLIT:
	a dedicated curated news_feed (the NEWS panel) is now separate from the operational weekly_log; only genuine
	world events are news (see §13.2 list). (3) TP-proposal consistency, building-completion notification, and a
	typed-array crash fix. See §20 changelog. — v6.9: (S37.51–S37.59) BUG #22 CLOSE-OUT (IP / NAME PASS) + CALENDAR-SOURCE / MAIN-HUB FIXES.
	(1) IP & NAME PASS (Bug #22 → ✅): real-athlete surnames scrubbed from the assigned JSON (13 fixes);
	teams.json name-variation + 4 dedupes + 23 real circuit/series/venue TEAM names fictionalized
	(0 duplicate team names, 172 teams intact, every championship still meets its minimum car count from
	JSON alone); driver dedup across 1244 drivers (0 first==last incl. "Lewis Lewis", 0 duplicate full
	names). (2) CHAMPIONSHIPS BROWSER REFACTOR (§16 / title-screen): retired the hardcoded
	CHAMP_TEAMS/CHAMP_STAFF/CHAMP_CARS/CAR_DRIVERS/CHAMP_KEY_IDX constants (1519→542 lines; the dead
	CAR_DRIVERS block alone was ~920 lines) — these held the last IP ("Andretti Collective",
	"IndyCar/NXT/USF/WRC/GT3/GT4-equivalent"). Browser now reads res://data/teams.json directly (works
	pre-game) and renders richer rows; all 21 championships populate, counts match the engine. Backup
	machinery (AIManager grid-fill / filler teams, personnel generation, bankruptcy) untouched. (3) TRACK
	NAMES: race_calendar.json display cities — 29 circuit-towns remapped to the nearest major city
	(Silverstone→Northampton, Monza→Milan, Spa→Liège, Le Mans→Tours, Suzuka→Osaka, Daytona→Jacksonville,
	Talladega→Montgomery, …); rally country-bracket entries left as-is (intentional rally formatting).
	(4) DUAL-CALENDAR CLARIFIED: the race ENGINE runs off the hardcoded CHAMPIONSHIP_CALENDARS constant
	(22-round GK incl. same-week semifinal+final via get_races_for_week — UNCHANGED); race_calendar.json
	is the VISUAL schedule (Calendar scene) and carries forward race-module metadata (practice/quali/
	sprint/double_race/stages/hours) that no code consumes yet. (5) MAIN HUB (§15.3): the Next-Race line
	+ Next-Race button now consider ONLY the player's own championships (get_player_championships()),
	and the line shows the JSON city via new GameState.get_calendar_city(cid, round) (falls back to the
	engine entry name for GK's engine-only Grand Final round 22). No save/load change — the helper is a
	pure read and player_registered_championships is already persisted. NOTE: branded EVENT names
	("Daytona 500", "24h Le Mans", "Spa-Francorchamps") still live in the CHAMPIONSHIP_CALENDARS constant
	as `name`; no longer shown on the Main Hub but a candidate future scrub for other screens. -->
<!-- v6.8: (S37.37–S37.50) LIVING WORLD + NOTIFICATION MIGRATION COMPLETE + NEW-GAME PROVISIONING.
	(1) NOTIFICATION/NEWS PHASE 3 COMPLETE: every add_notification across all engines + scenes migrated
	to the notify_event framework (event / standing / news / once) or show_popup — see §15.1. Signings &
	departures → news; recurring chores → standing (weekly-collapse); blocking errors → show_popup.
	(2) AI CHAMPIONSHIP SIM BUILT (§14 flipped DEFERRED→BUILT): new AIChampionshipSim RefCounted engine
	(resources/scripts/) runs every non-player, non-GK championship each race week via a lightweight
	strength scalar → finishing order → existing points table. car_strength() is an isolated pure
	function (driver effective_pace spine + consistency/race_craft + car index×condition × mechanic
	mult) — the SWAP-POINT for the Phase-5 economic model. Field = ai_cars[champ_id] (real rosters from
	car_assignments.json — multi-car teams, multi-driver EPC cars). Populates driver AND team standings.
	(3) RACING WORLD display: AI championship cards now show driver + team leader; GK card shows the
	driver+team CHAMPION even when the player raced a DIFFERENT discipline (reads GKDiscipline shadow
	standings + the CP3 cumulative team table). (4) NEW-GAME PROVISIONING FIX (§7.2): the Ops Sim key
	typo ("Ops Sim" → canonical "Ops Sim & Telemetry") meant SC Dev/GP4 never built the building → the
	starting Strategist was stranded (no slot). Fixed. GP now also starts with R&D Design Studio + CNC
	Parts Plant + a starting Designer (design+produce from week 1; budgets tuned manually for upkeep).
	(5) STRATEGIST = DNS (§9-G): a missing Race Strategist now DNS's the car (same ruling as the S37.45
	TP-DNS), enforced in can_car_race + flagged by a new readiness TDL, for every discipline except GK
	& Rally. (6) Bug run: release-staff now unassigns the mechanic/pit-crew from the car; false "no TP
	for GK" TDL for non-GK players fixed; "DNS for every championship" + "new car needed" season-rollover
	spam gated to player championships; 21-championships count corrected (was stale "24"). NOTE: §22
	manual idea — RECONSIDER the designer model (1-per-principle + per-special-project + 1 commercial)
	— is now live-relevant since GP starts with a Designer; carried in §19. -->
<!-- v6.7: (S37.31–S37.36) RESOURCE-BAR ROLLOUT COMPLETE + STANDARD HEADER finalized. The shared
	ResourceBar component is now on Campus, all 20 building scenes, and all non-building scenes
	(Drivers, StaffHub, Shortlist, Financialdept, ChampionshipSelect, Calendar — swapped from its
	hand-rolled bar — plus BeginOfSeason/EndOfSeason ceremony screens). §15.3 rewritten with the
	correct 'Main Hub concept' header: [Name·Level][Resource Bar][Back][Main Hub], scene-specific
	controls in a SUB-ROW below the header. Campus remembers last-viewed zone (pending_campus_zone).
	Key lesson recorded: header overflow came from oversized fonts + too many header elements, NOT
	the stretch aspect; fix = minimal header (title absorbs width, bar compact, extras in sub-row). -->
<!-- v6.6: (S37.31–S37.32) Reusable ResourceBar component + scene standard; part-purchase pricing.
	NEW §15.3 STANDARD SCENE LAYOUT: [Building Name][Building Level][Resource Bar][Back][Main Hub] —
	custom scenes (Main Hub, HQ team badge) may deviate. NEW §5.3 part PURCHASE pricing: unit_price =
	Base_Cost (Excel CNC) × (1 + Manufacturer_Profit) × Manufacturer_Quality; Profit=8%%, Quality=1.0
	for now (both TUNABLE). Loaded from res://data/part_costs.json. Fixed the 'buying parts doesn't
	deduct credits' bug (hardcoded PART_COSTS had GK at 0). -->
<!-- ⚑ PLANNED REDESIGN — ECONOMY SESSION (flagged S39.6): The FINANCIAL DEPARTMENT needs a rework,
	to be done together with the broader economy pass. Open issues to resolve there:
	(1) R&D PAYMENT MODEL: projects currently charge the FULL CR cost UPFRONT at start (RnDEngine
		.start_rnd_task: balance -= task.cr), so R&D is NOT a recurring weekly expense. The Financial
		"WEEKLY EXPENSES → R&D Projects" row therefore shows blank/—. Decide: keep upfront (and present
		active R&D as informational: total committed / remaining / amortized), OR switch to weekly
		instalments over the project duration. Until decided, the broken R&D weekly row is suppressed
		(it read non-existent keys cr/weeks; the real keys are cr_cost/weeks_total).
	(2) The breakdown is too coarse (maintenance is one lumped figure; commercial car sales now show
		but want per-segment detail; add company-value drivers, R&D committed, fuel hedging, etc.).
	(3) Commercial "Car Sales (market)" income line landed S39.5 — fold it into the redesign. -->
<!-- v6.5: STATE-HANDLER DISCIPLINE (S37.28–S37.29). #52 fixed (New-Game state leak + load bleed)
	and a FULL audit of all 129 GameState vars vs the three handlers (setup_new_game / save_game /
	load_game) closed the remaining leaks: WRA pipeline (active_wra_submissions, wra_approved/
	rejected_blueprints), bankruptcy counters (weeks_in_negative, bankruptcy_screen_shown),
	dismissed_todo_items, ceo_accumulated_salary, and player identity (player_name/nationality/ceo_*/
	game_difficulty). NEW §15.2 'STATE HANDLER CHECKLIST' codifies the rule so this can't recur. -->
<!-- v6.4: MAIN HUB REDESIGN shipped (S37.27) — the §18 hard-prerequisite is DONE, unblocking
	the notification-loop migration. New mockup-driven layout: Row1 nameplate (team + player name) ·
	resource bar · Menu (BELL REMOVED); Row2 Season|Week|Next-Race strip; Row3 nav (Campus · Calendar ·
	Drivers · Staff · Shortlist · Racing World); CENTRE three always-visible panels — TO-DO ·
	NOTIFICATIONS (now a permanent column, no bell/slide-in) · NEWS (doubles as the weekly event LOG
	until the news system exists); BOTTOM a 5-week strip (player-related events only, "+N more" overflow,
	from CalendarManager) + the three advance buttons. The side panel + its 4 tabs (drivers/teams/
	my-driver/cars) are DELETED — standings live in Racing World. MainHub.tscn simplified to root +
	Layout (body built in code); 10px screen-edge inset. Buglist #17 (hub total revamp) → done. -->
<!-- v6.3: SEASON CALENDAR feature (S37.26). NEW §14.1 — a read-only full-season agenda scene
	(res://scenes/Calendar.tscn) showing all 21 championships' races plus every other DATED event,
	laid out in 4-week blocks down a vertical scroll. Data-driven: NEW res://data/race_calendar.json
	(generated from the Excel "Race Calendar" sheet — all 295 rounds, keyed by championship id) is
	the new single source of truth for schedules; the hardcoded CHAMPIONSHIP_CALENDARS in GameState
	is now redundant (retire later). NEW CalendarManager engine (RefCounted, loaded via preload — no
	class_name) aggregates races + registration deadlines + building/R&D/CNC completions + custom
	player reminders into one week-indexed model. Custom reminders (＋ add / − remove, both with
	tooltips) are the ONLY persisted calendar state (custom_calendar_events on GameState, save/load).
	Race chip = "Championship · Round X/N" + city; GK = 21 rounds, Round 21 is the Week-46 two-race
	weekend (Le Mans). Centered modal add-event popup. Next: Calendar button on the hub + the hub's
	own 4–5-weeks-ahead strip (reuses CalendarManager.get_events_for_week). -->
<!-- v6.2: two design rules added (S37.25). §15 — RESOURCE BAR is now MANDATORY in every in-game
	scene (exceptions: modals + the four full-screen flow states); a scene missing it is a bug, and
	wiring it in is part of "done." §15.1 + §18 — the MAIN HUB REDESIGN is a HARD PREREQUISITE
	before the notification loop is constructed/finished: the bell/badge/panel/banner/TDL all live
	on the hub, so order is fixed (1) Main Hub redesign → (2) notification loop + legacy-
	add_notification migrations. Code state this session S37.22–S37.25: #40 TP soft-lock (immediate
	assign + rollover stranded-staff cleanup), #52b doubled TP rows (await-race in _rebuild_list),
	popup-position sweep (all cards centered; right column constrained). -->
<!-- v6.1: salary units (#8), interest rebalance (#2), sponsor commitment redesign (#13), results/
	standings UI (#11) — S37.9–S37.13. Annual salary negotiation with weekly read-out; interest gates
	reachable talent by reputation; type-3 sponsors tie to a reputation-band championship with annual
	payment + skip penalty + save/load persistence; race-results "Skip All" + Driver-fills column
	layout. Deferred/flagged: new-game state leak + load-game wrong-week (shared root cause; not fixed).
	See §20 changelog. -->
<!-- v6.0: Cluster A close-out + repair UX + the NOTIFICATION FRAMEWORK (S37.0–S37.8).
	§7.2 CP4 — the singular `active_championship` getter now resolves the player's REAL racing
	championship (registered → owned-car → legacy → dummy), not always GK; RaceSimulator threads the
	raced championship through per-race fuel/SP/condition/adaptation reads; standings registration
	follows Rule #6 (driver joins at car assignment, not at sign time); GK group-0 seeding gated to
	real GK drivers via a player_in_gk flag (a non-GK career no longer sees stray GK races/results).
	§15.1 NEW — the EVENT → TDL / NOTIFICATION+BUTTON / NEWS framework (notify_event, modes
	once/standing/event/news; the TO-DO list is read-only and never notifies). §6.11 Repair UX —
	per-car SP rate, a Garage "Repair" button with proportional all-SP repair, and the registration-
	deadline notification fixed (was sitting after the race-result early-return → skipped on race
	weeks). Misc: HQ sponsor-slot display, per-building income breakdown, sponsor slots at odd levels,
	SP-notification de-dup. BUGLIST reconciled: 10 fixed, see `Buglist_51_Reconciled.md`. -->
<!-- v5.9: §1 GK Championship final-weekend redesign (S36.18–S36.20), now confirmed in playtest.
	 GK is 22 races / 4 rounds (8/7/5/2); points RESET each round; the final weekend is two races
	 the SAME week — Semi-Final then Grand Final; the Semi cuts top-10-per-group into a single
	 20-driver Grand Final; the GRAND FINAL WINNER = World Champion (last race decides, champion
	 total = 25 pts, NOT cumulative); team champion = flat cumulative table across all 22 races.
	 General multi-event-per-week engine (get_races_for_week) introduced (reusable for Rally/
	 Endurance). Two scoring bugs fixed S36.20: (1) calendar-copy loops were stripping
	 gk_round/is_semifinal/is_final → no Semi detected → no elimination (Grand Final ran 30 drivers);
	 (2) shadow sim ran every week regardless of GK racing → AI points ~doubled. Both fixed. -->
<!-- v5.8: §8 R&D Studio polish (S35.16–S35.21) — catalog + Blueprint Status SCROLL fixes (shared
	 _make_scroll_column helper + right-side scrollbar gutter, mirrored in CNC Plant); championship
	 tab strip now PILLAR-1-ONLY (P2/P3 iterate the player's cars, P4 is champ-agnostic — the tabs
	 did nothing there); §8.4 P4 now gates on the target BUILDING level AND the R&D Design Studio
	 level (Required_RnD_Studio_Level was dead data, now enforced) with a single consolidated
	 "Required: 🏢 Building Lv X & 🔬 Studio Lv Y" line; §16 FULL R&D Studio localization incl. all
	 100 Special Project names/descs; licensing — user-facing "Formula" → "GP" (internal WRA-group
	 keys unchanged). NOTE: a companion BUGLIST.md now tracks 51 open defects (see §21). -->
<!-- v5.7: §5.1 CNC on-track part performance bonus (value×quality, cap 0.15) WITH a future-
	 review flag; §5.2 WRA approval = persistent manufacturing licence (+ HQ hand-off rule);
	 §8.1 2-D championship tab GRID (disciplines vertical by top-tier-rep principle, tiers
	 horizontal) for CNC + Studio; §8.2 current-season build rule + Build-Whole-Car all-6 gate;
	 §8.3 Garage warehouse reflects Logistics provider stock; §8.4 RP earned only by racing
	 (design note, under review). Built across S35.11–S35.13. -->
<!-- v5.6: §15 Personnel hubs & Shortlist (S35.10) — 24px readable rows with 100s emphasised,
	 full-width PROPORTIONAL aligned columns, Team + Contract as separate columns, active-sort
	 highlight + ▼/▲ arrow + "Showing: …" line, Staff free-agents toggle; and the unified
	 role-tabbed Shortlist screen (All + Driver + 6 staff roles) backed by is_shortlisted + the
	 GameState shortlist API, reachable from Staff/Drivers/Main Hub/HQ. -->
<!-- v5.5: §12-A rewritten to the live S35.6–S35.9 model — DETERMINISTIC binary person-interest
	 (shared by filter + approach), the random TEAM-RELEASE gate + 26-week refusal cooldown, the
	 _is_free_at_join rule (last-year/next-season = no gate/bond), and the Close vs Walk-Away
	 semantics. Plus a NOTED-FOR-FUTURE AI-poaching warning (last-contract-year case only). -->
<!-- v5.4: §3 living fuel price (BASE × economy Fuel_Price_Multiplier) + CFO race-logistics
	 auto-buy (skip-to-end only); §9-E CFO-gated economy notifications; §15 recurring-notification
	 collapse (subject supersede) + GK one-shot elimination notice. Built S35.1–S35.4. -->
<!-- v5.3: §7.1 Season Transition Pipeline (built S35.0) — the ordered A→E rollover sequence,
	 dual-ledger promotion, B-before-E fix, GK-as-sole-generation-source, Stage-E archive write. -->
<!-- v5.2: §12-A canonical approach flow (interest→bond→contract), release-clause vs buyout-bond
	 distinction, TP/CFO role split, join-date bond calc, immediate-transfer 1.5×+25% fee. -->
**Last updated:** 2026-07-02 · **Repo:** https://github.com/andreasmrg-droid/Automotive-Empire.git

> This is the single source of truth for the design of Automotive Empire. All prior
> session-handoff notes and manual "latest update" appendices have been absorbed into
> the relevant sections below; the document now reads as the *current* design of the game.
> Companion files (separate by intent, not superseded):
> - `Brainstorm_Threads.md` — design VISION & strategy rationale (the "why / what we want").
> - `FEATURE_AI_Championship_Sim.md` — full spec for the deferred living-world feature.
> - `Season_Transition_Pipeline_Spec_v1.md` — detailed companion to §7.1 (the built rollover).
> - `Master_Calculation___Formula_Document` — the authoritative formula/variable reference.
> - `BUGLIST.md` — the live defect/work queue (51 open items as of v5.8; see §21).
> Where this document and the code ever disagree, the CODE is truth; update this doc to match.

---

## 0. WHAT THIS GAME IS

Automotive Empire is a **motorsport-management tycoon sim**. The player runs a racing
team — and the wider business around it — across real motorsport disciplines, from
grassroots karting (GK) up to the pinnacle of Formula (GP1), plus Rally, Touring Cars
(TC), Open-Wheel (OWC), Stock Car (SC) and Endurance (EPC).

It is a **deep economic/management sim first, a race sim last.** Racing is ONE part of a
larger business: the player manages finances, R&D, staff, contracts, a commercial road-car
business, and a driver academy. The guiding build order is **economy first, race module last** —
the game must be fully playable as an economic simulation before the lap-by-lap race sim is
swapped in.

**Core fantasy:** build a motorsport empire from nothing to dominance — *Survive. Settle.
Develop. Establish. Conquer.* That five-stage arc is both the player's career and the motto
that drives the AI world (§13).

**Design philosophy (project owner's framing):** built MY way, for MYSELF first — optimised
for "the game I want," not "what sells." Scope discipline still matters, but in service of the
vision and of finishing, not a deadline. Engineering discipline is non-negotiable: clean
data-driven architecture, testable RefCounted engine classes, no orphaned dependencies,
version headers on every file.

---

## 1. CANONICAL MODEL — Cars, Drivers, Staff

Three orthogonal axes. Do not conflate them:

- **Cars** participate in championships. Capped per-championship by `Max_Cars_per_Team`.
- **Drivers** are assigned to cars. Count per car = `Driver_Per_Car`: **1** for most
  disciplines, **2** for Rally & TC, **3** for EPC (endurance rotation).
- **Staff** service the cars (a Race Mechanic per car; Pit Crew where required).

`Max_Cars_per_Team` and `Driver_Per_Car` are independent and multiply out to personnel need.

### Multi-driver CREW MODEL (Bug #38 — built S37.60–S37.61)

A `Car` holds **`driver_ids: Array`**, sized to its discipline's `Driver_Per_Car` via
`Car.set_seat_count()` (from `GameState.get_drivers_per_car(champ_id)`). The legacy scalar
`Car.driver_id` is kept as a **synced compatibility property** = seat 0 (the "lead seat"), so
single-seat code paths keep working; multi-driver-aware code reads `driver_ids` /
`assigned_driver_ids()` / `has_driver()` / `all_seats_filled()`. A car is **race-ready only when
EVERY seat is filled** (a Rally car missing its co-driver, or an EPC car missing a third, DNSes).

**The crew shares one result (this is the canonical rule):**
- **Standings & points** — only the car's **representative (seat 0)** is registered in
  `champ.standings`, so a multi-driver car is **one entry / one points award**, not one per driver.
  (Both the player path in `CarManager.assign_driver_to_car` and the AI path in
  `AIManager.load_car_assignments` / `AIChampionshipSim` register only the representative.)
- **Display** — standings, race results, and Racing World show the **combined crew label**
  `"Surname / Surname"` via `GameState.crew_label_for_driver(rep_id)` (single-seat cars show the
  full name unchanged).
- **Fitness & growth** — co-drivers are **co-equal**: every seated driver "raced", so post-race
  fitness drain and stat growth are applied to ALL of them (`RaceSimulator._crew_for_representative`
  fans the development out; the Race-Results DRIVER DEVELOPMENT panel lists every crew member).
- **New game** provisions a **full starting crew** (Rally/TC = 2, EPC = 3) and seats them; the
  RALLY4 starting-roster card lists 2 drivers. **AI cars** fill every seat from
  `car_assignments.json` (the JSON already carries the full `driver_ids` array per car).
- **Save/load** serializes `driver_ids`; pre-S37.60 saves migrate the scalar onto seat 0 and pad
  the remaining seats empty (`Car._migrate_legacy_driver`).

### Authoritative per-championship limits (CHAMPIONSHIP_REGISTRY / Excel Championships sheet)

| Champ | Name | Max cars/team | Drivers/car |
|---|---|---|---|
| C-001 | GK Championship | 9 (academy exception) | 1 |
| C-005 | RALLY4 | 4 | 2 |
| C-006 | RALLY3 | 4 | 2 |
| C-007 | RALLY2 | 4 | 2 |
| C-008 | Premier Rally | 2 | 2 |
| C-009 | TC Sport | 4 | 2 |
| C-010 | TC Elite | 4 | 2 |
| C-011 | OWC Next Gen | 4 | 1 |
| C-012 | OWC Dev | 4 | 1 |
| C-013 | OWC Pro | 3 | 1 |
| C-014 | SC Dev | **4** | 1 |
| C-015 | SC Truck | 4 | 1 |
| C-016 | SC Challenge | 4 | 1 |
| C-017 | SC Cup | 3 | 1 |
| C-018 | EPC Series | 4 | 3 |
| C-019 | EPC League | 4 | 3 |
| C-020 | EPC Hyper | 2 | 3 |
| C-021 | GP4 | 4 | 1 |
| C-022 | GP3 | 3 | 1 |
| C-023 | GP2 | 2 | 1 |
| C-024 | GP1 | 2 | 1 |

GK is the only high-count case (up to 9, academy). Outside GK, AI teams never field more
than ~2 cars — caps are only ever stress-tested by the player. The runtime
CHAMPIONSHIP_REGISTRY should carry the full Min/Max/Driver_Per_Car table (not just GK) so
Logistics displays correct caps; `get_max_cars()` reads the player's Garage car-slot cap and
is a SEPARATE mechanic from the per-championship cap.

**GK Championship** is a single progressive elimination championship of **22 races** across 4
rounds (Round 1: 32 groups, 8 races; Round 2: 16 groups of 20, 7 races; Round 3: 4 groups of
32, 5 races; Round 4 / Final weekend: 2 groups of 30, 2 races). **Points reset to 0 at the
start of each round** — every round is its own fresh mini-competition, so totals never carry
across rounds. The **final weekend is two races in the SAME calendar week**: a **Semi-Final**
(`is_semifinal`) followed by a **Grand Final** (`is_final`). After the Semi-Final, the **top 10
from EACH of the 2 final groups** advance (`apply_semifinal_cut()`), collapsing into a **single
20-driver Grand Final** with points reset to 0. The **Grand Final WINNER is the World Champion**
— the last race alone decides the title (NOT cumulative points); the champion's total is
therefore the single-race win (25 pts). The player's REAL raced Semi/Grand Final results feed
the elimination system (Option B), so a player win crowns the player. The **team champion** is
decided separately by a flat cumulative constructors table counting ALL 22 races (driver champion
via elimination, team champion via cumulative). The two final-weekend flags
(`gk_round`/`is_semifinal`/`is_final`) MUST be preserved through any calendar copy — dropping them
silently disables the cut (fixed S36.20). The shadow simulation that scores non-player groups runs
ONLY on weeks GK actually races (not every week — that bug doubled AI points, fixed S36.20). The
general multi-event-per-week engine (`get_races_for_week()`) that powers the two-race final weekend
is reusable for future Rally multi-stage / Endurance weekends. Note: `num_races` (22) is a DISPLAY
value; race-length logic reads the actual calendar (`calendar.size()`).

---

## 2. ENGINE ARCHITECTURE & DISCIPLINE

- **Pure RefCounted engine classes** hold the economic/simulation logic, kept OUT of UI, so
  every system is headless-testable (Python-portable) for multi-season drift before shipping.
- **Data-driven**: championships, buildings, R&D projects, names, etc. live in data
  (registries / JSON / the Excel master), so balance changes and modding are config edits.
- **Version headers** on every file; **define floors, refuse ceilings** (especially for AI
  "cleverness" and "make it feel alive").
- **Single source of truth**: the GDD for design; the code for runtime truth; the Excel
  master mirrors the data tables. When one changes, reconcile the others.
- **Localization**: every user-facing string goes through `Locale.t("key")` / `Locale.tf(...)`.
  See §16.

---

## 3. FINANCE — Weekly Calculation Cycle

The economic heartbeat. All values reference the Master Variables Excel.

```
Weekly_Total_Income   = Sponsor_Income + Race_Prize_Income + Commercial_Car_Sales_Income
					  + Racing_Parts_Sales_Income + Building_Passive_Income + Merchandise_Income

Weekly_Total_Expenses = Driver_Salaries + Staff_Salaries + Building_Maintenance
					  + R&D_Project_Costs + Manufacturing_Materials + Loan_Interest
					  + Race_Entry_Fees + Taxes + Fuel_Costs

Net_Weekly_Profit     = Weekly_Total_Income − Weekly_Total_Expenses
Current_Balance_new   = Current_Balance_old + Net_Weekly_Profit

Company_Value = Current_Balance + Value_of_All_Buildings + Value_of_All_Cars
			  + Value_of_Commercial_Inventory + Value_of_R&D_Assets − Current_Loan_Balance

Max_Loan_Amount = Company_Value × Loan_Multiplier × Reputation_Factor
```

**Loans (HQ → Finances tab):** a single loan entry point lives in the LOANS section (amount
slider, duration picker, live rate/payment). Rate depends on `current_loan_rate` and the
economy state. `Max_Loan_Amount` and loan terms are influenced by the CFO's `loan_management`
stat (§9-E).

**Fuel contracts & price fluctuation:** fuel price fluctuates weekly on global economy events.
Teams can lock multi-week contracts at the current price to hedge. Base fuel consumption
differs per championship (Cars sheet).

**Corporate tax (S40.14):** the `Taxes` term is a **seasonal** charge, not weekly — corporate tax on
the season's net profit, deducted once at season end (not in the weekly cycle). See §24 for the rate
formula, the CFO's role, and the season-profit basis.

**Living fuel price (S35.3):** the per-kg cost the player actually pays is
`BASE (CR 2.0/kg) × Fuel_Price_Multiplier`, where the multiplier is economy-driven within the
range the variables sheet defines (Global Variables → `Fuel_Price_Multiplier`: default 1.0, min
0.5, max 3.0). It maps from `economy_index` (0–100, neutral 50): index 50 → ×1.0 (base scale
preserved), recession → cheaper toward ×0.5, boom → pricier toward ×3.0. `get_fuel_cost_per_kg()`
is the single source of this price — used by both the manual buy and the CFO auto-buy, and shown
live in the Logistics fuel card and input preview. (Spare parts have no economy multiplier in the
current design — flat CR 1/unit.)

**CFO auto-buy (S35.3):** while the player fast-forwards to season end (Skip to End of Season),
the CFO keeps the cars race-ready by topping up fuel and spare parts to **exactly** the next
race's need, at the living price — but only if a CFO is hired and the team can afford it (it never
drives the balance negative). It fires **only** during the skip, never in hands-on weekly play:
when the player is present they manage logistics themselves; when they opt out by skipping, the
CFO covers the boring part so a season isn't lost to un-bought fuel. See §9-E.

---

## 4. COMMERCIAL CAR INDUSTRY — the Factory (Phase 3) — IMPLEMENTED & ITERATED (S38.0–S39.7)

The road-car business: a late-game, climb-gated second income stream that pairs with racing and makes the
game playable without the race module. **Designed and validated over 100 headless seasons** (the
attractiveness market engine, the racing-relative income cap, marketing, lifecycle, economy cycles, and ROI
were all proven in Python before coding — per the §2 rule), then **implemented and playtested across
S38.0–S39.7**. **Derivation & full rationale: companion doc `Phase3_Commercial_Validation.md`.** The
as-built implementation (with the design reversals noted below) is documented in **§4.8**. Two design
premises from v7.2 were overturned during build — see §4.8 and the v7.3 changelog note.

### 4.0 Core model

- **12 segments** (Excel "Commercial Cars Industry"): Economy Hatchbacks → Limited Run Megacars, each with
  volume, margin, complexity, market-type (Mass/Premium/Hyper), difficulty, and seeded AI producers/shares.
- **Unlock = R&D Studio level (S39.5 reversal).** The v7.2 design gated blueprints behind *racing the
  linked championship* (Excel `Factory_Unlock`, col BF: RALLY4→Economy Hatch … GP1→Megacars). In build this
  was found to add friction without payoff — researching a blueprint is already very expensive and slow — so
  the racing gate was REMOVED. A segment's Pillar-5 blueprint is now researchable once the **R&D Design
  Studio** reaches that segment's required level (`Required_RnD_Studio_Level`, e.g. Economy Hatch = Lv 4 …
  Megacars = Lv 12). The `Factory_Unlock` discipline→segment matrix is retained only as flavour/ordering. To
  PRODUCE still needs a built **Factory line** + a **CFO** (enforced separately). The old championship-raced
  ledger (`championships_ever_raced`) is still tracked but no longer gates blueprints.
- **Factory level = production lines** (1 per level, max 12). Each line runs ONE model; level 12 = all 12
  segments concurrently. A segment needs BOTH: blueprint researched AND a free line.
- **CnC is SEPARATE** — CnC = racing parts only; the Factory = commercial cars only. No shared inventory/code.
- **Pillar 4** = Factory-boosting special projects (robotic assembly, conveyor, monocoque rig, smart-factory
  — output/margin/cost). **Pillar 5** = the 12 per-segment car models + their improvement ladder.
- **CFO MANDATORY:** no CFO → Factory burns full upkeep, **zero output**. CFO `sales_skill` amplifies Factory
  commercial sales + market-share growth (Factory/road-car ONLY — NOT the Museum/Theme Park/Merch/PRC
  passive-income buildings, which stay marketability/fan income) via:
  `sales_factor = 0.75 + sales_skill/200` (0.75 … 1.0 @ skill 50 … 1.25). No TP multiplier on it.

### 4.1 The market engine — ATTRACTIVENESS / REDISTRIBUTION (locked: v4, 7 giants)

Share is won by **competitiveness, not multiplied from current share** (the latter froze new entrants —
including the player, who is always a new entrant). Each producer (player, racing-brand AI, volume giant,
and a resisting "Others" bloc) has an **attractiveness**; each week the segment's 100% is redistributed
toward the more attractive, moving gradually (inertia → ~5–8 season climb).

```
attractiveness = 1.0·(reputation/100) + 0.8·model_freshness + 0.6·(marketing_ratio − 1) + giant_bonus(0.15)
				 (× sales_factor for the player's CFO)
deserved_share = attractiveness / Σ(all attractiveness + OTHERS_ATTR 0.35)
new_share     += (deserved_share − share) × INERTIA(0.045)        # gradual move
```

- **"Others %"** = a resisting residual bloc (attractiveness 0.35) holding unclaimed share; every segment
  sums to 100%. Share you gain comes FROM Others or from weaker/aging rivals — never from nothing.
- **7 named volume giants** (Meridian Motors, Continental Auto, Pacifica Group, Aurora Vehicles, Summit
  Automotive, Northwind Motors, Crestline Group) occupy the mass/volume segments — real, beatable
  incumbents replacing the faceless "Others" there. Prestige segments stay racing-brand territory
  (Blackthorn, Obsidian, etc.).
- **Validated over 100 seasons:** 0/12 runaway monopolies; volume leaders 12–17% (realistic fragmentation);
  a cold-start player climbs to 9–29% on MERIT (good reputation + fresh model + marketing); leadership shifts
  as models age. Monopolies self-cap (the whole field pulls back + aging models decay).
- **Specialist rule emerges naturally:** attractiveness is per-model, so spreading marketing/effort thin
  across many segments underperforms committing lines to a few high-value segments.

### 4.2 Model lifecycle — hard ~25-season life

Each model: **ramp (to ~2.5 seasons) → plateau (to ~16) → decline → death at 25 seasons.** Decline is driven
by **competitiveness drift** (freshness falls; rivals refresh and you don't), not a hard age cap — a
diligently refreshed model stays strong its whole life. **Pillar-5 Facelift** (cheap, restores
competitiveness mid-life) and **Next-Gen** (expensive, launches a successor, resets the clock — Escort→Focus)
keep a line alive. AI auto-refreshes near end-of-life. New-game seeds AI models at **staggered mid-life ages**
(persisted) so the industry looks mature and avoids synchronized death waves.

### 4.3 Pricing, marketing & demand

- **Marketing budget PER MODEL:** the CFO recommends a budget; the player sets it. Cost ≈ **18% of gross** at
  the recommended spend, **paid from revenue**. Under-spend → marketing_ratio < 1 → lost share (cars sit
  unsold). Diminishing returns above recommended. CFO `sales_skill` makes the same budget reach further.
- **Price sensitivity:** per-segment elasticity (Mass elastic, Hyper rigid) — hook for the Pillar-4 "MSRP
  Pricing Bandwidth" bonus (pricing lever is a later refinement; v1 drives share via rep/marketing/freshness).
- **Economy cycle demand** (§4.5).

### 4.4 Income, the racing-relative CAP, and ROI (calibrated)

Real-world anchor: even Ferrari is only ~10% racing; road cars dominate everywhere. But this is a racing sim,
so the Factory is **deliberately capped below reality: mature Factory ≈ 1× racing income, hard max 2×**
(McLaren-style — the two businesses comparable).

- **Excel MSRP/margins are real-world dollars (~1000× the game's credit scale)** — kept as on-screen FLAVOR.
  Actual income = scaled: `commercial_credits = units × margin × CREDIT_SCALE(≈0.0054) × sales_factor`, tuned
  so a fully-built mature Factory lands at ~1.18× racing income (anchored to a representative late-career
  racing income ~CR 496K/wk; NOT the GP1-champion outlier). Because the cap is RELATIVE to racing income, it
  **auto-scales across the career and survives sponsor re-tuning** (validated ±30%).
- **Per-line capacity:** 500 units/wk at L1, +250/level (Excel). Realized sales = min(demand, capacity);
  overproduction is lost (the "unsold cars" pressure).
- **Validated ramp (with realistic share climb):** ~0.13× racing @ S10 → ~0.44× @ S50 → ~0.85× @ S75 →
  **~1.18× @ S100 (mature)** — gradual, never instant.
- **Build cost 1.2M** (code value — accessible entry; slow share-climb prevents instant riches).
- **Upgrade-cost STAIRCASE (replaces the broken flat 250K), ~3-season payback per line, descending:**
  L1→L2 12.08M, →L3 9.89M, →L4 7.94M, →L5 6.95M, →L6 6.79M, →L7 6.62M, →L8 4.84M, →L9 4.47M,
  →L10 2.81M, →L11 1.60M, →L12 1.20M. **Total Factory capex ~CR 66.4M.** Per-line ROI ~0.5–5 seasons —
  satisfying, never instant, never dead money.

### 4.5 Economy cycles (plug into the EXISTING economy_index)

Commercial demand reads the game's existing `economy_index` (§3 / `_update_economy_and_fuel`):
```
demand_mult = 1 + ((economy_index − 50)/50) × cyclicality      # Mass 0.45 / Premium 0.25 / Hyper 0.08
```
Hyper segments are recession-resistant (ultra-rich keep buying — matches real Ferrari/McLaren data); volume
segments swing hardest. Sponsor offers also soften in recessions: a ×`(1 + (idx−50)/50 × 0.20)` multiplier in
`SponsorManager._generate_sponsor_offer` (recession → leaner offers), tying racing + commerce to one pulse.
**Validated:** cycles do NOT destabilize the market (a boom/recession scales the whole pie equally; shares
still redistribute fairly — only credits-earned move).

**Economy RE-TUNE (Option A, adopted):** the current formula (mean-reversion 0.008 + drift ±0.5) keeps the
index in a 35–67 band — it **never reaches Boom(>70)/Recession(<30)** across a career (the economy is wired
up but practically flat). Replace the pure-drift line in `_update_economy_and_fuel` with a **slow ~4-season
sine "regime" + light noise + rare shocks**, giving genuine but rare cycles (~3–4 booms / ~3–4 recessions per
~25-season career, mostly Normal). This simultaneously revives the dormant fuel/loan/`speculation` systems.

### 4.6 Representation — the Commercial Department (visible to ALL players)

A new **"Commercial Department" building/screen in HQ**: read-only market view (12 segments, producers =
giants + racing brands, live shares, "Others", the economy's current commercial effect). **Visible to
everyone from the start** (aspirational + a scouting tool before you enter a segment); becomes interactive
(set per-model marketing, manage models/lifecycle) once a Factory is owned. The **economy graph stays in the
Financial dept** (it's a financial indicator); its commercial *consequences* show here. **News +
notifications** carry events: economy shifts (CFO-gated, exists), market-share milestones, and the
"you can research this segment's blueprint" unlock breadcrumbs.

**As-built (S40.0):** market-share milestones are now live. When the player's share in a segment they
actively produce in crosses an upward threshold — **10 / 20 / 30 / 50%** — the weekly market tick posts a
**news** event (notification + NEWS feed) routed to the Commercial Department; 50% is phrased as the
segment's "leading marque." Each rung fires once per ascent, the ledger lowers if share slips back (so a
real re-climb re-announces), and stopping a line clears that segment's ledger. See
`GameState._check_commercial_share_milestones` and the `commercial_share_milestone_hit` save field.

### 4.7 The base weekly formulas (legacy reference — superseded by the engine above)

The original §2-style formulas remain valid as the *visibility* layer (how racing feeds commercial buzz);
the attractiveness engine (§4.1) governs the actual share dynamics.
```
Weekly_Racing_Buzz = [(Points_Earned ÷ Max_Points) − 0.5] × Championship_Visibility × Discipline_Synergy
```
`Championship_Visibility` = the championship's `Reputation_0_100` (Excel col E; GP1 100 … GK 15) — GP1 success
drives far more commercial visibility than a Rally4 result. `Discipline_Synergy` is the Factory_Unlock link
(racing the segment's own championship boosts that model). "Others %" = 100% − Σ team shares in the segment.

**Roadmap link:** Phase 3. Pillar-5 "Commercial Cars" R&D button exists as a stub; the 12 model blueprints +
improvement ladder are data to author. Integration points listed in `Phase3_Commercial_Validation.md` §10.

### 4.8 IMPLEMENTATION — as-built (S38.0 → S39.7)

Phase 3 shipped and was playtested over several iteration rounds. This subsection records what the code
actually does, including the places it diverges from the §4.0–§4.7 design.

**Architecture.** `CommercialMarketSim.gd` (pure RefCounted market engine; 12 segments, attractiveness/
redistribution, lifecycle, history) owned by `GameState._commercial_market`. `FinancialEngine.apply_
commercial_income()` realises weekly credits. `RnDEngine` carries the Pillar-5 catalog + the Facelift/
Next-Gen completion hook. Screens: `VehicleFactory.gd` (the Commercial Department), `RnDStudio.gd` (Pillar-5
tab), plus components `SharePie.gd`, `ShareLines.gd`, `ModelNamePopup.gd`. Managers are plain `class_name`
RefCounted accessed via `gs._<name>` (not autoloads).

**Economics — final calibration (validated, 100-season Python).** The v7.2 premise that road cars are
cheaper/faster to design than racing cars was OVERTURNED: the game already prices a GP1 (F1) car at 20M CR
and an EPC-Hyper (Le Mans) car at 6M, and real road-car *design* dwarfs that. Costs are therefore
EARNING-TIED (≈3.5 mature seasons of a segment's net, floored at 25M so every road-car design exceeds the
20M GP1 car), RP = the full racing-car L1+L2 design RP × tier, and weeks track a real design-only timeline.
Authoritative per-segment table (in `RnDEngine`): economy_hatch 25M/4000RP/40wk/StudioLv4 · hot_hatch
28M/4350/43/5 · rally_replica 25M/4000/40/6 · ev_flagship 96M/12100/121/9 · entry_sports 25M/4000/40/5 ·
supercars 25M/4000/40/10 · pickups 34M/5050/50/5 · pony 25M/4000/40/6 · v8_sedan 51M/6950/70/8 · track_day
25M/4000/40/7 · bespoke_hyper 25M/4000/40/11 · megacars 25M/4000/40/12. **Halo ×3 volume boost** (bespoke
800→2,400/yr, megacars 300→900/yr) so the rarest segments can pay back (~8-season payback; exclusivity
preserved). All 12 segments validated to pay back in 3–8 seasons with a stable market. Supersedes the §4.4
ROI premise; see `Phase3_Commercial_Validation.md` §7B.

**Income — single source of truth (S39.5).** `GameState.commercial_line_economics(seg)` returns
{demand, capacity, sales_units, share, gross, marketing, net, capped} and is used by the Commercial
Department preview, the Financial Department income line, and `FinancialEngine` — so the displayed and the
applied numbers can never diverge. Net is floored/capped consistently (racing-income reference floored at
50K, then the 2× racing cap). Fixed the early bug where the preview showed "net CR 0/wk" because its cap
had no floor.

**Unlock gate (S39.5 reversal).** Blueprints gate on R&D Studio level ONLY (the race-the-championship
requirement was removed). `is_commercial_segment_unlocked` and the R&D card text are Studio-level based;
a Factory line + CFO are still required to PRODUCE.

**Commercial Department (S39.1–S39.6).** List-left / detail-right layout (per the `Cars_Market.pptx`
mock): a scrollable segment list; the selected segment shows a big current-week donut **pie** + a colour-
matched brand legend + a **share-over-time line chart** (last 5 seasons, sampled once per season — see
history below), the economy demand effect, and the interactive controls. Every named brand gets a distinct
colour across pie/legend/lines (giants no longer collapse to one gold). Reachable pre-build via the HQ
**Financial Department tab** ("📊 Commercial Market" button) as a scouting tool. A producing line shows a
sales/stock breakdown (demand · capacity · sold · gross − mktg = net), marketing ±, an ageing hint, **Stop
Production**, and Facelift/Next-Gen redirects to R&D.

**Share history (S39.4).** `CommercialMarketSim._history` keeps the last `HISTORY_SEASONS=5` per-segment
snapshots, sampled once per season (negligible memory/save cost; chart redraws only when open). Seeded at
new-game; persisted in save.

**Start / Stop Production + model naming (S39.6–S39.7).** A researched blueprint shows a **details box**
(class, unit margin, market size, line capacity) with an explicit **▶ Start Production** button (replacing
the ambiguous "▶ Build"). Pressing it opens `ModelNamePopup` — a centered modal listing all **5 fictional
name proposals** for the segment plus a free-text field; **Confirm** starts the line with that name,
**Cancel** backs out. Names are fully invented to evoke real naming patterns without trademark collision
(`CommercialMarketSim.MODEL_NAME_POOL`, 5 per segment). **Stop Production** frees the line and keeps the
blueprint.

**Facelift / Next-Gen = R&D mini-projects (S39.7).** Relocated from the Commercial Department to the R&D
Studio (they are redesigns). On a researched blueprint with a producing line, the Studio card shows
Facelift / Next-Gen buttons that start a real research task (RP+CR+weeks at 25% / 60% of the blueprint),
requiring a free Designer (`GameState.start_commercial_refresh`). On completion (`RnDEngine._advance_rnd_
tasks` intercepts `P5_FACELIFT_*` / `P5_NEXTGEN_*`), the refresh applies (Facelift knocks age back; Next-Gen
resets the lifecycle) and queues a rename; the Commercial Department drains the queue and re-opens the
naming popup so the refreshed/new-gen model is renamed. The Commercial Department has matching
🔧 Facelift (R&D) / 🚀 Next-Gen (R&D) redirect buttons.

**Dynamic RP storage cap (S39.2).** `get_rnd_rp_storage_cap()` is now dynamic = max(linear floor,
1.15 × the largest RP of any P4/P5 project unlockable at the current Studio level), so the expensive
commercial blueprints are always affordably storable. (Fixed a pre-existing cap bug affecting all R&D.)

**Save / load (audited S39.7).** All Phase-3 state is saved, loaded, AND reset on new-game (state-handler
§15.2): `commercial_lines`, `pending_commercial_rename`, `championships_ever_raced`, the market engine
(`market` + `_history`), `_economy_phase0`, `_racing_income_window`, `active_rnd_tasks` (an in-progress
Facelift/Next-Gen survives reload via its `segment` key), `completed_rnd_tasks`. Pre-Phase-3 saves load
with safe fallbacks.

**Deferred (not in Phase 3).** (1) **Financial Department / economy redesign** — incl. the R&D payment
model: projects charge the FULL CR cost UPFRONT at start, so there is no recurring weekly R&D expense; the
Financial "R&D Projects" row is suppressed until this is reworked. Flagged ⚑ at the top of the changelog for
a dedicated economy session. (2) **News-writing / hype pass** — better-written, hype-building news (a future
"sound-wave propagation" news filter is sketched in §13.2). (3) **Systemic header-overflow fix** — building
headers can run off the right edge; belongs in the shared header/ResourceBar component (only the Commercial
Department title is clipped so far). (4) **Localization** — all new commercial/UI strings are plain text,
awaiting the end-of-dev localization pass.



---

## 5. CNC PART PRODUCTION & RELIABILITY

### 5.3 Part PURCHASE pricing (player buying from another team) — S37.32

When the player BUYS ready-made parts (Logistics warehouse) rather than manufacturing them, they
are buying from another team's production, so a manufacturer margin applies:

```
unit_price = Base_Cost × (1 + Manufacturer_Profit) × Manufacturer_Quality
```

- **Base_Cost** — per part, per championship, from the Excel **CNC** sheet (`Base_*_Cost` columns).
- **Manufacturer_Profit** — the selling team's margin. **= 0.08 (8%) for now — TUNABLE / future:**
  could vary by manufacturer reputation, supply/demand, or a relationship discount.
- **Manufacturer_Quality** — a quality multiplier. **= 1.0 (neutral) for now — TUNABLE / future:**
  higher-quality manufacturers charge more (and could yield better part reliability).

Data lives in `res://data/part_costs.json` (generated from the CNC sheet), holding both `base_costs`
and the computed `unit_prices`, plus the two multipliers, so prices recompute if the multipliers
change. `GameState.get_part_unit_price(champ_id, part)` / `get_part_prices(champ_id)` are the
accessors; `buy_part()` uses them, then applies the Logistics Center discount on top. **FLAG (per
player request): the profit/quality split is a deliberate future tuning hook — when manufacturer
identity/relationships are modelled, wire them here.** This fixed the S37.32 bug where the old
hardcoded `PART_COSTS` priced GK parts at 0, so buying deducted nothing.


Base Reliability starts at **60** in Season 1 of a new WRA rules cycle and increases by **+10**
each subsequent season (until the next 4-season regulation reset, §11).

```
Final_Reliability = Base_Reliability + (Extra_Credits_Invested ÷ 12,000)
				  + (Extra_Weeks × 5)          [capped at 100]
```

Designer stats set a blueprint's *initial* reliability before CNC; the CNC process itself is
separate from Designer skill (§9-F).

### 5.1 On-track part performance bonus (S35.11)

Installed CNC parts give the car a lap-time bonus, computed in `RnDEngine.get_cnc_part_bonus`:

```
per installed part:  part_bonus = value × quality
   value   = the R&D performance magnitude (already bakes in level via the P2 carry-over
			 chain + designer lift — do NOT multiply by level again, that double-counts)
   quality = the reverse-engineering penalty (1.0 own-design, ~0.75 RE) — makes the RE
			 penalty matter on track
total bonus = clamp(Σ part_bonus, 0.0, CNC_BONUS_CAP=0.15)
applied in-race as:  lap_time /= (1.0 + total_bonus)
```

Reliability is **excluded** from this bonus — it governs DNF/failure risk, not lap time; the two
must stay separate. Legacy/provider parts with no stored `value` fall back to a small flat
contribution (`CNC_LEGACY_FLAT = 0.005`) so they aren't silently worthless. The Garage car
header shows the live total as "⚡ Parts: +X% pace". Installed parts store `level` + `value`
(`CarManager`) so the formula has the data to read.

> ⚠ **FORMULA FLAGGED FOR FUTURE REVIEW.** This `value × quality` model is provisional —
> Andreas is uneasy about it. Revisit and re-derive before the Phase 5 balance pass. Do not
> treat the cap, the legacy fallback, or the multiplicative form as settled.

### 5.2 A WRA approval is a manufacturing licence (S35.11)

Once a blueprint is WRA-approved, manufacturing it does **not** consume the approval. The
approval persists so the player can build spares/replacements; it is cleared only at season
rollover (P2 upgrades) or the 4-season WRA regulation reset (P1/P3 designs, §11). In the HQ
WRA tab an approved blueprint disappears once it has been **handed off to CNC** (queued, built,
or installed) — HQ's job (getting approval) is done and the blueprint now lives in the CNC
Plant. The CNC "ready to manufacture" / Build-Whole-Car gates remain current-season only (§8).

---

## 6. THE RACE WEEKEND

The race module is the LAST thing built (the economy ships first). The design below is the
target; until the full sim is swapped in, results are produced by the engine's existing logic.

### 6.0 Car Acquisition & Delivery (Phase 2) — ✅ VERIFIED WORKING (S37.65, keyboard)

The car acquisition + delivery pipeline (buy/build → delivery week → DNS-until-ready → in-build
banner → race-ready on delivery) is **play-tested and confirmed working**.

A team fields no cars at season start until it acquires them. Two paths:

- **(A) BUY a ready supplier car** — available only where buyable (not Grand Prix, and not the
  own-build championships C-007, C-008, C-020, C-024).
- **(B) DESIGN + BUILD** — R&D Pillars 1 (Design) + 3 (Rev. Eng.) → WRA approval → CNC manufacture.

Both paths: the car is **not raceable at season start**. It is delivered on the week the lengthiest
required part finishes (`get_car_delivery_week` = max of the per-part build weeks; one
`delivery_week` per car). **DNS-until-ready:** an undelivered car DNS's only the rounds before its
delivery week, then joins the championship the week it is delivered. **Every season scraps all cars**
(built *and* bought) — each team rebuilds or rebuys every season.

Car fields (Car.gd): `delivered`, `delivery_week`, `acquisition` ("delivered"/"bought"/"built");
legacy saves default delivered=true. `is_ready_for_race()` is false while undelivered. Garage shows
an in-build banner ("🏗 In build — arrives Week X"); crew can be pre-assigned; part slots are locked
until delivery.

**Build Whole Car** (CNC one-pass): when all 6 part blueprints for a championship are WRA-approved, a
single button queues all 6 parts; the car is created immediately (assign crew while it builds) and is
race-ready when the last part finishes. Gated on garage capacity and funds.

### 6.1 Unified Lap Time Formula

```
Final_Lap_Time = Base_Lap_Time × (1 / Accel_Decel_Factor) × Cornering_Factor
			   × (1 + Fuel_Time_Penalty) × Tire_Condition_Factor × Setup_Factor
			   × Driver_Factor × (1 / Staff_Synergy_Factor)
```

- `Setup_Factor = 1.0 − (Setup_Percentage ÷ 100) × 0.18`
- `Staff_Synergy_Factor` includes the **Team Principal multiplier** on Strategist and
  Mechanic stats.
- Track-specific part importance (aero, engine, gearbox, chassis, suspension — from the TRACKS
  sheet) feeds both performance AND degradation.

### 6.2 Practice — Setup Discovery

Player chooses **Qualification Trim Runs** or **Race Trim Runs**.
- Combined setup (Quali% + Race%) **< 80%** → any run improves BOTH trims.
- Combined setup **≥ 80%** → only the currently-running trim improves further.

```
Setup_Gain_per_Lap = Base_Gain × Track_Knowledge_Factor × Mechanic_Car_Setup_Skill
				   × Team_Principal_Practice_Bonus × Driver_Feedback_Factor
```

### 6.3 Qualifying

Uses the Qualification Trim setup% from Practice. AI timing decisions consider remaining time,
traction evolution, rain (Race Strategist + Team Principal), tire condition, and dirty air
(Race Mechanic + Team Principal).

### 6.4 Pit Stop

```
Pit_Stop_Total_Time = Pit_Lane_Base_Time + Base_Service_Time + Repair_Time
Service_Time includes the Team_Principal_Pit_Bonus multiplier.
```

`Base_Service_Time` is driven by Pit Crew `pit_stop_speed` (scaled by dynamic fitness, §9-C)
and the Mechanic `pit_stops` stat. `Repair_Time` is driven by Pit Crew `repair_skill`.

### 6.5 Part Degradation & Terminal Damage

```
Effective_Degradation_per_Lap = Parts_Degradation_per_Lap × (Track_Part_Importance ÷ 80)
```

`Part_Condition` reduces each lap; when it reaches **≤ 0** the part suffers **terminal damage**.

### 6.6 Overtake & Dirty Air Windows

- Overtake Window opens when `gap < Max_Overtake_Attempt_Gap` and the car is in an Overtake
  Opportunity zone.
- Dirty Air Window is active outside overtake zones when
  `gap < Dirty_Air_Threshold (= 1.65 × Max_Overtake_Attempt_Gap)`.

### 6.7 Race Session

Uses Race Trim setup%. Driving modes (Conserve / Normal / Attack) modify pace, fuel, tire
wear and part wear by **±15%**. All real-time systems (traction, tire wear, part condition,
dirty air, overtake windows, incidents, flags) run every lap. Staff influence (Strategist and
Mechanic) is multiplied by the Team Principal.

### 6.8 Race Module UI (paper design — built with the race sim)

- A **2D track** for visual presentation, plus a **Telemetry Wall** that shows the TRUTH (data).
- Telemetry Wall = 3 rotating tabs: (a) whole grid (positions, gaps, tyres); (b) our cars'
  detail (laps, sectors, trims); (c) all other deep data (strategy, pit, part condition).
- A **speed control** (− / ×1 / +) that SNAPS BACK to ×1 and NOTIFIES on critical events
  (part about to fail, pit window, incident); can auto-jump to the relevant telemetry tab.
- Per-car panels show part conditions + Quali/Race trim + pit; displays up to 4 cars (page
  if more). EPC needs 3 driver slots/car.

### 6.9 Post-Event Calculations

After every race: award final positions & points (Championships sheet); record part & tire
wear; update Track Knowledge and Parts Knowledge; increase Driver Feedback by performance;
compute commercial impact via Weekly Racing Buzz; update Reputation and Marketability.

### 6.10 Race Results screen (current implementation)

Three paged screens navigated with Back/Next (Continue stays in the header throughout):
1. **Race Results** — finishing order.
2. **Championship Standings** — driver standings and team standings side by side (two
   scrollable columns).
3. **Season Development** — car condition + driver development + staff development. Only
   present if the player actually raced; navigation auto-collapses to 2 pages otherwise.

**Crew display (S37.61–S37.62).** On all three pages, multi-driver cars show the combined crew label
`"Surname / Surname"` (race result rows and both standings columns via
`GameState.crew_label_for_driver`). The **DRIVER DEVELOPMENT** panel lists **every crew member** that
grew, not just the representative — the sim attaches a per-member `crew_devs[]` array to each result
entry (snapshotting pre-race stats for all co-drivers), so co-drivers' fitness drain and stat gains
are shown individually.

### 6.11 Manual repair & SP economy (S37.0–S37.5)

Cars accrue damage; repairs spend Spare Parts (SP) at a **per-championship rate**
(`sp_per_10_pct_damage` from `CHAMP_LOGISTICS` — e.g. GK = 110 SP per 10% damage, scaling up by
tier). The rate is always read from the car's OWN championship, never the singular
`active_championship` (CP4, §7.2). Three ways to repair, all routed through `CarManager`:
- **Auto-repair** after a race weekend (full if SP allows; partial if SP runs out, then a single
  de-duplicated "SP insufficient" notice — §15.1).
- **Manual buttons** (Main Hub "My Cars" + Garage car card): Fix 10% / Fix 50% / Full Repair,
  disabled when the relevant whole-chunk cost isn't affordable.
- **Proportional all-SP repair** (`repair_car_max_sp`): spends ALL currently-held SP for a fractional
  repair, so a player holding less than one full 10% chunk (very common at GK's 110-SP rate) is never
  fully blocked. The Garage "Repair" button uses full-when-affordable, else this; disabled only at
  0 SP. Buying SP is done at the Logistics Center.

---

## 7. CHAMPIONSHIPS, REGISTRATION & SEASON FLOW

- The engine auto-populates championships to maintain minimum/optimum car numbers
  (Team_Generation_Rules sheet).
- **Registration** (HQ → WRA panel; full scene = ChampionshipSelect): the Championship
  Registration button sits at the TOP of the WRA panel, above the "Racing this Season" box.
  The registration scene offers "Register All Affordable" and "Re-register All Running" bulk
  actions, plus per-championship requirement checklists.
- **Begin/End of Season** are dedicated full-screen flow states (resource bar hidden — see §15).
- Currently only the player's raced championship(s) get populated standings; all others are
  empty (end-of-season screen filters to raced championships to avoid empty-data crashes).
  The "living world" fix is the deferred AI Championship Sim (§14).

### 7.1 Season Transition Pipeline (built S35.0)

Every season rollover runs ONE ordered sequence inside `SeasonManager.start_new_season()`. The
pieces existed before but were interleaved in the wrong order — the integration is the design.
Detailed companion: `Season_Transition_Pipeline_Spec_v1.md`.

**The world model.** JSON is the season-1 seed (all drivers per team/car/championship + free
agents). During a season, player and AI bank decisions (expand championships, add cars, renew,
don't-renew, sign for next season). At rollover the next-season ledger becomes the current-season
ledger and a fresh next-season ledger opens; recorded signings/releases execute; TPs propose the
new roster for the player and assign directly for AI; the engine fills GK's gaps with new cadets;
finally it culls anyone out of contract for 2 full seasons (archiving them). This loop runs every
season.

**The driver pyramid.** GK is the feeder and the ONLY birthplace of new drivers — at rollover the
engine generates young cadets to fill GK's gaps. Every other championship fills gaps by drawing UP
from the existing pool (the cadet→professional promotion path); they never generate their own
drivers. If GK stops refilling, the whole pyramid's supply dries up — which is why the old
"wipe GK, regenerate nothing" behaviour was foundational, not cosmetic.

**The ordered stages (A→E):**

1. **Stage A — Promote the ledger.** The next-season registration ledger becomes this season's
   race set; the ledger is cleared for new planning. Runs first so every downstream check
   (car-needed, delivery, Logistics, TDL) sees the correct registrations.
2. **(Pre-B) Age & lapse.** Age drivers/staff, decrement contracts, lapse expired player
   contracts. Runs before Stage B so a contract expiring at this rollover frees its holder before
   signings are applied.
3. **Stage B — Apply signings & releases.** Activate every pre-signed contract whose effective
   join season is now (the person joins their new team) and flush queued TP/Strategist
   assignments. **Must run before Stage E** — see the critical-rule note below.
4. **Stage C — TP assignment.** AI teams re-allocate all 5 roles via the optimiser (Season 2+;
   Season 1 stays JSON-seeded). Player proposals are regenerated later, after the car wipe.
5. **Stage D — GK feeder generate-to-fill.** The contracted GK field persists across seasons; the
   engine only clears the stale GK free-agent pool and tops up the gap with new young cadets
   (generate `target − existing`, never a destructive wipe). Runs after rosters settle so the
   "existing" count is accurate. New cadets are created already contracted, so Stage E never
   touches them.
6. **Stage E — Lifecycle cull + archive.** Age retirement + the 2-season free-agent erase, run
   LAST so a just-released or just-activated (Stage B) person is not culled in the same tick they
   change status. A culled free agent is recorded in `retired_personnel` (reason `left_sport`)
   before erasure — **not** in `hall_of_fame`, which holds race-win records (a career-exit entry
   there would corrupt the win tally).

   > **FUTURE TASK (flagged S41.10) — bound the history archives.** `retired_personnel` (and any
   > history-book archive) currently grows **unbounded** — every retiree is archived regardless of
   > significance. This is harmless now but at season 60–100 it becomes real memory/scroll bloat.
   > Fix: filter archived entries to **highly-rated personnel only** (a champion, a title-winning
   > driver, or an elite-talent/high-reputation staffer) — nobody needs a permanent record of a
   > mid-pack RALLY2 driver or a journeyman mechanic. Threshold basis (peak reputation vs talent vs
   > titles) and the bar are TBD; decide when scheduled (§19).

Downstream of A→E sits presentation/reset (car wipe, championship reset, notifications, R&D
carry-over, WRA-cycle check, stale-state flush); order among those is cosmetic.

**CRITICAL RULE — B before E.** Activating pre-signed signings must precede the free-agent cull.
A driver pre-signed last season is still a free agent at the instant of rollover; if the 2-season
cull runs first, it erases them before the activation that would join them to the team, and the
signing silently evaporates. This ordering is the core fix of the pipeline (Stages B and D were
already individually fixed in S33.1/33.2; S35.0 put them in the correct sequence).

**Timing definition.** A pre-signing is stamped `signed_season` (the season it was struck) and
takes effect the FOLLOWING season. `ContractEngine.effective_join_season(ap)` is the single named
definition of that target season (`signed_season + 1`), so the pipeline reasons about an absolute
target rather than the fragile relative string "next_season" (the string-replay was the root of
the original "bounces back, never joins" activation bug). `signed_season` remains the only stored
field — the helper only names the derived value, so there is no parallel state to drift.

### 7.2 CP4 — the player's active championship (S37.0–S37.2)

`active_championships` is the WHOLE world (all 21 championships always run); the player's actual
entries live in `player_registered_championships` (and `next_season_registrations` is the ledger for
next season). The **singular** `active_championship` getter — read by many screens and the race sim
for "the player's current championship" — used to return `active_championships[0]`, which is ALWAYS
GK (C-001). That single wrong read was the root of a whole symptom cluster: a Rally-only career
showing GK races/results, GK-rate SP/fuel math on a non-GK car, and "registered in all championships"
contradictions.

The getter now resolves the player's REAL championship in priority order:
`player_registered_championships` (their entries) → the championship of an owned car → a legacy
explicit field → a safe **dummy** championship (so callers never get null). Consequences:
- `RaceSimulator` threads the **raced** championship through every per-race read (fuel, SP, condition,
  adaptation) rather than the singular getter — see §6.11.
- **Standings registration follows Rule #6:** a driver is registered to a championship at CAR
  ASSIGNMENT, not at sign time. Premature GK writes in `DriverManager` / `ContractEngine` were
  removed; the starting driver registers to the car's championship.
- **GK isolation:** `GKDiscipline.populate_season()` seeds GK group-0 with real GK drivers only, and a
  serialized `player_in_gk` flag gates the weekly GK simulation, round-advance and elimination notices
  — a non-GK player never receives them. The GK final weekend still resolves via the shadow sim, and
  RacingWorld reads the GK champion/leader from the shadow standings so GK remains visible in the
  world view.

### 7.3 New-game starting assets — per-discipline provisioning (S37.50)

`GameState._give_starting_assets(champ_id)` provisions the starting campus, staff and car for the
chosen Tier-1 championship. Buildings and staff are gated by the championship's **discipline**:

| Discipline | Buildings built at start | Starting staff (beyond TP + Driver) |
| --- | --- | --- |
| GK | Standard Campus | — (GK uses no Strategist/Pit-Crew) |
| Rally | + Pit Crew Arena | Pit Crew |
| SC | + Pit Crew Arena, Ops Sim & Telemetry | Pit Crew, Race Strategist |
| GP | + Pit Crew Arena, Ops Sim & Telemetry, **R&D Design Studio, CNC Parts Plant** | Pit Crew, Race Strategist, **Designer** |

Every career also starts with a Team Principal and a starting Driver assigned to the car.

**Two fixes that shipped here:**
- **Ops Sim key typo (the stranded-strategist bug).** The provisioning checked `"Ops Sim"` but the
  canonical building key is `"Ops Sim & Telemetry"` everywhere else, so the `in campus_buildings`
  test was always false → SC Dev / GP4 never built the building → the starting Strategist (created
  right after) had no slot and was stranded/unresolvable. Corrected to the canonical key; the
  strategist already sets `assigned_championship`, so it now resolves correctly once its slot exists.
- **GP gets the full design+manufacturing chain.** A GP4 career now starts with the R&D Design Studio
  + CNC Parts Plant built and a starting Designer (team-level, occupying the R&D-Studio slot; no
  discipline adaptation, §9-F), so it can design and produce parts from week 1. The other Tier-1 paths
  build these later. Starting budgets were tuned manually to cover the added upkeep.

> **§22 cross-ref:** the manual "reconsider the designer model" idea (1-per-principle + per-special-
> project + 1 commercial, instead of many) is now live-relevant — GP starting with a Designer is the
> current 1-per-team baseline. Revisit when the designer rework is scheduled (§19).

---


## 8. R&D SYSTEM

The R&D Studio is organised into **5 pillars** (tab bar):

1. **DESIGN** — design blueprints for any part (Reverse Engineering = Level 1, Own
   Development = Level 2; upgrade parts up to Level 6, each requiring the previous). The
   catalog shows **next-season blueprints only** — the current season's car is already
   locked in, so current-season design isn't actionable. A blueprint designed for a future
   season **cannot be manufactured until that season begins**: CNC is gated on
   `bp.season ≤ current_season` (single choke point in `start_cnc_job`, so it also covers
   Build Whole Car). The CNC plant shows each blueprint's target season and locks future cards.
2. **UPGRADE** — upgrade Open parts on owned cars; in-season improvements carry to next season.
3. **REV. ENGINEERING** — reverse-engineer parts of a car you race to produce your OWN copy next
   season instead of re-buying it. Offered for **ALL parts (spec + open)**, but a part is only
   RE-able if the car in your garage for that championship carries it as a **Logistics-bought
   (provider/L0) part** — you cannot reverse-engineer a part you already manufacture in your own CNC.
   (Runtime-gated in `rnd_task_unlocked` by `car_provider_parts` vs `car_installed_parts`; S41.0 —
   previously the catalog wrongly emitted RE for spec parts only.)
4. **SPECIAL PROJECTS** — **100** building-linked special projects (the "P4" set). Each is
   gated by a specific building's level (see §10 coupling) and unlocks unique team
   capabilities/bonuses. Each needs a Designer slot + time/credits.
5. **COMMERCIAL CARS** — *stub (future).* Button + popup exist; reserved for the road-car
   R&D system (Phase 3). Constants and helpers are wired so the real catalog drops in later.

General R&D develops blueprints and upgrades; specialized R&D (Pillar 4) is tied to buildings
and their max levels.

### 8.1 Championship tab GRID — CNC Plant & R&D Studio (S35.12–S35.13)

Both the CNC Plant and the R&D Studio (Pillar 1 catalog) scope their content to **one
championship at a time**, selected from a **2-D tab grid**:

- **Vertical = disciplines**, ordered by the "highest-reputation principle": each discipline is
  ranked by its **top-tier** championship reputation, descending.
- **Horizontal = tiers** within a discipline, pinnacle → entry.

With the current registry this yields, top to bottom:
`GP (GP1 GP2 GP3 GP4) → EPC (Hyper League, League, Series) → OWC (Pro, Dev, Next Gen) →
SC (Cup, Challenge, Truck, Dev) → TC (Elite, Sport) → Rally (Premier, R2, R3, R4) → GK`.

The order is derived at runtime from the registry (`GameState.championship_tab_order()` flat,
`championship_tab_grid()` grouped) — a single source of truth. The `rep` values are constants,
so the order is stable; editing a `rep` would reorder the tabs automatically. (Real-world note:
the data places OWC slightly above SC — the IndyCar-vs-NASCAR prestige reading — and that is
intentional and kept.)

### 8.2 Build Whole Car & current-season rule (S35.12)

The CNC builds **current-season** parts and cars only (model "b": a blueprint is buildable when
its target `season == current_season`; next-season designs sit visible-but-locked until that
season arrives). `_approved_car_blueprints` filters to current season, so:

- The CNC "BLUEPRINT OWNERSHIP" panel marks next-season approved parts as "🔒 S{n} (next
  season)" rather than "ready to mfg".
- **Build Whole Car** is shown per selected championship and is enabled only when all **6**
  current-season part blueprints are WRA-approved; otherwise the button is greyed with the
  tooltip "you need all 6 part blueprints". The slot-queue + delivery model (§6.0) is unchanged:
  all 6 jobs queue, N run in parallel (N = CNC slots), the car is delivered when the last
  finishes.

### 8.3 Garage warehouse reflects Logistics stock (S35.11)

The Garage's persistent WAREHOUSE panel lists **all installable stock** for the selected
championship — both manufactured CNC parts (`cnc_parts_inventory`) and provider L0 spares from
the Logistics warehouse (`part_inventory`, via `get_part_stock`) — with a Source column
(CNC / Provider). Empty part slots read "L0".

### 8.4 Research Points (RP) — earned by racing, faucet re-anchored (S40.16)

RP is earned in exactly one place: after a race (`RaceSimulator.earn_race_rp`). There is **no**
baseline weekly RP income from the Studio or idle designers — a team must race to develop (RP starts
at 0; the catalog shows the Assign row with disabled buttons + a reason, "need N RP (have 0)", so the
gate is legible). *The earlier open question — whether to add a baseline weekly RP — is RESOLVED:
racing-only is kept; instead the per-race faucet was retuned so racing generates enough.*

```
RP_gained = laps × RP_PER_LAP_BASE × Studio_Level × (Lead_Overall / 100) × Difficulty
			(summed across the player's running cars in the raced championship)
RP_PER_LAP_BASE = 3.0            # was 1.0 — applied in code S41.0 (v7.6 doc anchored 3.0; file lagged)
```

- Requires a built R&D Studio AND a hired **Lead** designer (the team's single highest-overall
designer — one-Lead-per-team model, S40.4). No Studio or no Lead → no RP. This replaced the old
"sum of every hired designer's skill" (which rewarded stacking designers).
- **Why 3.0 (S40.16):** the old 1.0 starved the early game — a fresh Studio L2 needed ~3.7 seasons of
racing to afford a single P1 blueprint tree, so R&D was effectively frozen for new players. Swept
1.0/2.0/3.0/4.0 across **all** pillars; 3.0 makes the everyday P1/P2/P3 tree affordable within a
season (early L2: single P2 part ~0.6 season, full P1 tree ~1.2) **without** trivialising P4 (median
P4 stays 2–20 seasons, hero 3–95 across the game). 4.0 overshot. The retune deliberately targeted the
everyday tree, NOT P4 affordability.
- **Combined check:** a tier-appropriate team covers its full seasonal R&D bill (design next-season
car via P1/P3 + upgrade current car via P2) in under one season, with surplus banking toward the
occasional P4 splurge.
- RP is capped by the dynamic storage cap (§4.8 "Dynamic RP storage cap" / `get_rnd_rp_storage_cap`).

### 8.5 R&D Studio — Pillar 4 gating, requirement display & UI (S35.16–S35.21)

**Pillar 4 (Special Projects) gating.** Each Special Project (100 total) gates, in priority order,
on (1) any prerequisite task, (2) the target **building** at/above `min_building_level`, and (3)
the **R&D Design Studio** at/above `Required_RnD_Studio_Level`. The Studio-level requirement was
present in the data from the start but unenforced until S35.19 — it now blocks like the building
gate (`RnDEngine.rnd_task_unlocked`). Enforcing it locks more projects earlier than before; factor
this into the Phase 5 balance pass.

**Consolidated requirement line.** Every P4 card shows a single line — "Required: 🏢 {Building}
Lv X  &  🔬 Studio Lv Y" — coloured green when all shown gates are met, amber otherwise. This
replaced the earlier split design (a separate two-chip requirements row plus a redundant lock
sentence that repeated the same thing). The lock area now only carries a *prerequisite-task*
message; when building/studio level is the sole blocker the amber Required line already says it.

**Championship tabs are Pillar-1-only.** The championship tab strip renders only on Pillar 1
(Design). Pillars 2 (Upgrade) and 3 (Reverse Engineering) iterate over the player's owned cars and
never read the selected championship, and Pillar 4 is champ-agnostic — so the tabs did nothing on
those pillars and were removed there.

### 8.6 Blueprint design time — from-scratch vs mid-cycle refresh (S40.17)

The season loop's continuity guarantee: **every participating team can design its next-season car in
time to register.** P1 (Design) and P3 (Reverse Engineering) build **next** season's car (stamped
`design_season = season + 1`); P2 (Upgrade) improves the **current** season's car.

- **L1 blueprint weeks** = `base_weeks × tier_mult × refresh_mult`, where `tier_mult = 1 + (tier−1)×0.5`
and `refresh_mult` = **1.0** on a from-scratch year (the start of that championship's WRA cycle — a new
team's first season or the first season after a regulation reset) or **0.5** mid-cycle. **Only WEEKS get
the discount — RP/CR cost is unchanged**, so tier still makes cars expensive, just not
un-buildable-in-time. From-scratch vs mid-cycle is detected per championship via
`RnDEngine._is_from_scratch_design(cid, design_season)` (cycle position; per-group cycle length 4–10, §11).

> **⚠ CODE-vs-CANON GAP (v7.13, confirmed by reading the code — UNFIXED).** The "a new team's first season"
> clause above is **canon but NOT implemented.** `_is_from_scratch_design(cid, design_season)` returns
> `(_wra_group_season_for(cid, design_season) == 1)` — it checks **only** the WRA cycle boundary. It has
> **no team parameter**, and there is **no per-team first-design / entry-season tracking anywhere** in the
> codebase. So a team designing a car for the **first time mid-cycle** is (wrongly) given the **halved**
> weeks instead of full. Because `RND_TASKS[tid]["weeks"]` is a **single global value per task**, two
> durations (full for the newcomer, half for incumbents) for the *same* blueprint/season cannot even be
> represented as the data stands. **Consequence:** the planner's `_latest_safe_start` reads the halved
> weeks, starts the newcomer's design too late, and the team fields **no next-season car**. **Fix (needs an
> owner decision on where first-design state lives):** add per-team first-design tracking and make the weeks
> decision team-aware in BOTH the planner and the RnD start path (the shared task can't hold two values).
> This is independent of the v7.13 season-boundary crash — no evidence they're linked.

- **L1 blueprint CR — car-anchored (S41.8 / S41.8b).** Separate from the weeks rule above (which is
unchanged): the L1 *design CR* used to be a flat `PART_BASE_P1.cr` sum (~104k, ×tier_mult), decoupled from
the car's actual value — so self-designing a GK car cost 16× its manufacturing cost while a GP1 car cost
~1% of it. L1 design CR is now **anchored to the car**: the whole-car P1 L1 CR =
`CNC_DATA.base_total_cost × DESIGN_RATIO[tier]` with `DESIGN_RATIO = {1:0.6, 2:1.0, 3:1.8, 4:3.5}`,
distributed across the six parts by the locked `P1_CR_WEIGHT` (the old per-part CR shares). This yields a
constant design:manufacturing ratio per tier (spec series cheap to self-design, prototype series a real
commitment — anchored to real-world NRE-vs-manufacturing ratios, which span <10% for spec parts up to
~5–8× for full prototypes). **P3 (Reverse Engineering) L1 CR = 0.8 × the matching P1 L1 CR** (S41.8b): RE
copies a physical reference, so it's the *cheaper* budget/survival route — this replaced the old RE
*premium* (P3 was ~1.2–1.67× P1), which had contradicted the planner's "pick P3 as the cheapest legal
part" survival logic. Only L1 CR changed; weeks, RP, effects/values, the L2 chain and all P2 upgrade tiers
are untouched. Championships with no `CNC_DATA` base fall back to the legacy flat CR. The design cost is a
**recurring annual** cost (P1 is rebuilt every season; the refresh discount touches weeks only, not cost).
- **Why:** the un-discounted weeks made a full car un-designable within a season at high tiers — the
Chassis L1+L2 chain alone reached 60 weeks at tier 4 (Chassis has the highest base design-weeks, 8; RP
was never the constraint, *time* was). The mid-cycle halving fixes this while keeping from-scratch years
appropriately heavy.
- **Registration budget** for a championship = `52 − CNC design_weeks − 1`, **except** EPC Hyper League
(C-020) and GP1 (C-024): their long CNC manufacture lead times left too little design runway, so they use
a fixed **registration-deadline override to week 31** (a 20-week design window). Their CNC manufacture
time is unchanged — the registration deadline is decoupled from the manufacturing lead time for these two.
- **Verified** against every championship's real budget: from-scratch fits with ≥7 weeks slack, mid-cycle
refresh with ≥17 weeks slack (the headroom that lets strong teams also push parts to L2). The guarantee
assumes a Studio level appropriate to the tier; a team racing above its resources may not fit (acceptable).

**Stat-snapshot carry-over (existing, S35.11 — restated).** A P1 L1 design's base value inherits the
**current** car's highest WRA-approved P2 value **at the moment the design completes** (`_compute_p1_base_value`
reads `current_season`). A P2 gain approved *after* the P1 design finished cannot retroactively enter that
next-season blueprint. This is the design-timing tension: research the new car early (safe continuity,
weaker baseline) vs late (better baseline, deadline risk).

### 8.7 Per-team RP ledger — the AI R&D economy substrate (S41.2, Phase 3)

The R&D pipeline above is written once and serves every team. The **player** keeps the six singular
R&D globals on `GameState` (`research_points`, `active_rnd_tasks`, `completed_rnd/bp/upg_tasks`,
`known_blueprints`, `active_wra_submissions` / `wra_approved` / `wra_rejected_blueprints`) exactly as
before — they are read by ~170 sites across 7 UI scenes + CarManager + NotificationManager, so they are
deliberately **not** rewritten. Every **non-player team** instead carries a parallel store on its own
meta, `team.get_meta("rnd_ledger")`, mirroring the shape of those globals (`rp`, `active_tasks`,
`completed_rnd/bp/upg`, `known_blueprints`, `wra_active/approved/rejected`, `studio_level`). This is the
same "pattern B" the existing `rnd_bonuses` effect meta already uses.

Routing is a single optional `team` parameter (default → player) on each pipeline function
(`rnd_task_unlocked`, `rnd_task_active_or_done`, `start_rnd_task`, `submit_to_wra`,
`_advance_wra_submissions`, `_advance_rnd_tasks`, `_apply_rnd_effect`, `is_blueprint_approved/submitted`).
When the team is the player (or omitted) the function reads/writes the globals as it always has; otherwise
it reads/writes that team's ledger via `RnDEngine._ledger_for(team)` (`_is_player_ledger` is the branch
point; a fresh ledger is seeded on first touch). The player path is therefore provably unchanged. AI
ledgers serialise into each team's save entry and restore on load, with a fresh-seed fallback for
pre-Phase-3 saves.

**Load-path completeness (S41.7 — critical fix).** The ledgers restoring was not sufficient on its own:
`ai_cars` — the `{championship_id → [Car]}` dict that *links* each AI team to the championships it races —
was never serialised and never rebuilt on load. On any loaded save it stayed empty, so
`get_cars_for_team(ai_team)` returned `[]`, `_team_championships()` returned `[]`, and the whole AI R&D
planner early-outed with `no_championships` for all 172 teams every week (confirmed in a loaded-save
playtest) — and `AIChampionshipSim.simulate_round` (which also reads `ai_cars`) stopped awarding AI
standings. FIX: `save_game` now serialises `ai_cars` verbatim (preserving exact mid-season condition/parts,
per owner decision) and `load_game` restores it right after the player cars; old saves without the key keep
the pre-fix empty state and self-heal at the next season rollover (which rebuilds `ai_cars`). This is
CONFIRMED WORKING in-game.

**Season-rollover prune (S41.10).** The player's R&D state is purged of current-season P2/UPG at every
rollover (see §7 pipeline: `completed_upg` cleared, P2 blueprints erased from `known_blueprints` + WRA).
The AI ledgers previously received NONE of this, so their `completed_upg` / P2 `known_blueprints` / WRA
entries accumulated unbounded every season — a real (if modest, ~MB-scale) memory leak that compounds now
that most AI teams self-design annually. `RnDEngine.prune_ai_ledgers_for_new_season()` now mirrors the
player prune EXACTLY across all AI ledgers, called from `start_new_season()` right after the player's own
prune. P1/P3 next-season blueprints are kept (same as the player).

- **P3 provenance** is now team-scoped: a part is reverse-engineerable if the *requesting team's* garage
  car for that championship carries it (granted/bought) and the team has not self-made it in CNC. (The
  `car_installed_parts` "self-made drops out" clause is player-singular today, so an AI team's granted
  car keeps every part RE-able until AI CnC exists — the explicitly-scoped next project.)
- **WRA for AI:** approvals are silent (the world does not headline every AI manufacturing licence);
  P2 rejections DO post world news + take a tier-scaled reputation hit, feeding the living world (§11).
- **Scope (Phase 3 = storage + routing + save/load; Phase 4 = the RP faucet).** As of S41.4 the AI
  **RP faucet** has landed (§8.4 formula applied to AI teams — see §13.3): AI ledgers now FILL with
  Research Points during racing, seeded off a Studio level from `teams.json` (clamped 1..27). What
  remains in `AI_RnD_Economy_Spec_v2.md`: the forecast **planner** that SPENDS the RP (step 5),
  retreat/backfill (step 6), and **on-track uplift** (step 7 — AI research → `car_strength`). Until the
  planner lands, an AI ledger accumulates RP but never spends it, and AI research still changes no race
  results — the intended interim state. AI blueprint quality also skips the P2-carry-over/lineage
  refinements for now (they read player-only approval globals); that fidelity arrives with the uplift
  step, where AI blueprint values first affect race results.



## 9. STAFF — Roles, Stats & Formulas

**Key hierarchy:** The **Team Principal** is the overseer — a multiplier on all racing staff.
The **Race Mechanic** is the core racing multiplier. The **Race Strategist** supports pace and
timing. **Designers** operate only in the R&D Studio (no race impact). The **CFO** handles all
financial operations and ALL contract negotiations independently.

**Discipline adaptation applies to:** Team Principal, Race Mechanic, Race Strategist.
**Does NOT apply to:** CFO, Designer, Pit Crew.
Disciplines: **GP, EPC, SC, OWC, TC, Rally, GK**. `effective_stat = raw_stat × (adaptation / 100)`.

### 9-A. Team Principal (Overseer)
Multiplies all racing staff effectiveness; does not replace roles, amplifies them. TP
reputation + team reputation reduce the "Not Interested" factor in hiring. Stats:
`race_strategy`, `practice_management`, `qualifying_management`, `race_pace_reading`,
`car_setup_oversight`, `pit_stop_management` (`Service_Time = Base_Service_Time ×
(1 − TP_Pit_Bonus)`), `pr_skill` (Reputation/Marketability + news impact), `parts_knowledge`
(in-race amplifier of Mechanic/Strategist), `track_knowledge`.

**Assigned per championship** (via `Staff.assigned_championship`). A TP's "overall" rating —
`Staff.get_overall_skill()` = mean of the 9 stats above — ranks TPs for allocation. The **player
assigns/changes TPs manually**; the assignment optimiser does **not** propose TPs to the player.
**AI teams auto-reassign their TPs at season start** (best overall → highest-prestige championship).
See §9-I.

### 9-B. Race Mechanic (Core racing multiplier)
`car_setup` (primary, Setup_Gain_per_Lap), `pit_stops` (reduces Base_Service_Time),
`parts_knowledge` (operational, degradation monitoring), `track_knowledge`, `race_pace`
(Staff_Synergy_Factor in lap time, ×TP).

### 9-C. Pit Crew (Physical execution — DYNAMIC fitness)
`pit_stop_speed`, `repair_skill`, `fitness` (dynamic), `fatigue_resistance` (static, slightly
improved by the Fitness Clinic). No discipline adaptation.

```
fitness_drop (per pit stop) = (pit_stop_time_seconds / 2) × (1 − fatigue_resistance/100)
fitness_drop (per repair)   = (repair_time_minutes × 0.5) × (1 − fatigue_resistance/100)
effective_pit_stop_speed    = pit_stop_speed × (fitness/100)
effective_repair_skill      = repair_skill   × (fitness/100)
Recovery between sessions   = (100 − current_fitness) × recovery_rate
   Practice→Quali 0.30 | Quali→Race 0.60 | Race end→next weekend: reset to 100
   (Fitness Clinic raises recovery_rate)
```

### 9-D. Driver Fitness (same dynamic model)
Driver fitness degrades per lap and affects ALL driver attributes proportionally
(`effective_attribute = raw_attribute × (fitness/100)`).

```
fitness_drop (per lap) = (lap_time_seconds / 90) × driving_mode_multiplier
					   × (1 − fatigue_resistance/100)
   driving_mode_multiplier: Conserve 0.80 | Normal 1.00 | Attack 1.30
Same recovery schedule as Pit Crew; reset to 100 each weekend.
```

Strategic implications: pushing Attack in practice arrives at quali fatigued; GK drivers
racing multiple tiers in a day carry fatigue forward; EPC mandates 3-driver rotation;
Conserve in practice preserves race fitness.

### 9-E. CFO (all finance + ALL contracts; no TP involvement except operational judgement)
Required to run a Factory team. Stats: `sales_skill` (commercial sales/market share),
`sponsor_negotiation` (ALL Driver/Staff/Sponsor contracts), `resource_management` (reduces
Weekly_Total_Expenses), `budget_planning` (expansion/contraction insights), `speculation`
(economy_index predictions only — doesn't move the economy), `loan_management`
(Max_Loan_Amount, rates, repayment).

**`sales_skill` scope (Phase 3, §4):** applies to the **Factory's road-car sales + market-share growth
ONLY** — `sales_factor = 0.75 + sales_skill/200` (0.75 … 1.25; no CFO → Factory off entirely). It does NOT
touch the Museum/Theme Park/Merch/Public-Racing-Club passive-income buildings (those are
marketability/fan-driven, a different lever). No TP multiplier on it. The CFO is MANDATORY for a Factory.

**Economy intelligence is CFO-gated (S35.3):** the economy notifications the player relies on —
economy state shifts and fuel-price shocks — fire **only if a CFO is hired** (it's the financial
intelligence they're paid for, per `speculation`). Without a CFO the economy still moves; the
player just gets no heads-up.

**Race-logistics auto-buy (S35.3):** during a fast-forward to season end the CFO tops up fuel and
spare parts to exactly the next race's need at the living price (§3), if hired and affordable —
only while skipping, never during hands-on weekly play.

### 9-F. Designer (R&D Studio only; TP does NOT multiply them)
Per-part design quality: `engine, aero, brakes, suspension, chassis, gearbox`; plus
`reliability` (initial blueprint reliability) and `parts_knowledge` (grows from race
telemetry per car type → faster iteration, higher initial values). All Designer stats have
equal ±10–15 random variance — specialised designers emerge organically.

### 9-G. Race Strategist (×TP; not used in GK or Rally)
`race_strategy` (primary), `race_pace_reading` (driving-mode recommendations),
`practice_scheduling`, `qualifying_timing`, `track_knowledge`. **Assigned per championship** (one
strategist shared across that championship's cars; via `Staff.assigned_championship`). Skipped for GK
and Rally. Included in the player's TP assignment proposal (§9-I). The strategist occupies an **Ops
Sim & Telemetry** building slot. **A missing Strategist is a DNS** (S37.50 — same design ruling as the
TP-DNS, §9-A / S37.45): enforced in `RaceSimulator.can_car_race()` and surfaced by a readiness TDL
("No Race Strategist for: … (car will DNS)"), for every discipline EXCEPT GK & Rally. The new-game
starting roster provisions one for SC/GP careers (§7.2).

### 9-H. Effective-stat floor (adaptation, muscle memory)
Adaptation never drops below a floor representing muscle memory.
```
effective_stat = raw_stat × (adaptation / 100)
effective_pace = pace × (0.5 + (active_adaptation / 200))   # softened: 0 adaptation → 50%
```
- Current discipline starts at ~`5 + (talent_factor × 10)`; all other disciplines start at 1.0.
- Floor = `peak_value_ever_reached × 0.35` (e.g. peak GK 80 → floor 28).
- Growth/decay per race: active +2.0..+4.0 (talent); related (synergy>50) +0.3..+0.8;
  low-synergy (<30) −0.5..−1.0 if above ceiling.
- Visible: current active discipline adaptation only. Hidden: the other 6 discipline values.

### 9-I. TP Assignment System (advisor model)

Team Principals are **advisors**: they compute the optimal personnel allocation and **propose** it to
the player (accept all / some / reject — never auto-assign). AI teams use the **same optimiser** but
**apply directly**. Engine: `TPProposalEngine.compute_optimal_assignments(team, cars, include_tp)` —
team-agnostic, pure (no side effects), headless-testable.

**Five roles, granularity & rules:**

| Role | Granularity | Adaptation | Skipped for | Player | AI |
|---|---|---|---|---|---|
| Driver | per car | yes | — | proposal | auto |
| Mechanic | per car | yes | — | proposal | auto |
| Pit Crew | per car | **no (raw)** | **GK** (not required) | proposal | auto |
| Strategist | per championship | yes | **GK & Rally** | proposal | auto |
| Team Principal | per championship | yes | — | **manual** | **auto (season start)** |

**Allocation:** prestige-ordered (best → highest-prestige championship/car first;
`DISC_PRESTIGE×10 + tier`). **Commitment rule** (anti-exploitation): one person → one championship; a
committed person is removed from the pool for all lower-prestige cars/championships, preventing one
ace covering multiple championships across non-overlapping race weeks. (The old GK multi-tier
exception is removed — GK is now one championship.)

**Scoring** (role-appropriate; effective = raw × adaptation/100, except pit crew = raw): driver
`eff_pace×0.6 + eff_consistency×0.4` (+ age eligibility); mechanic `eff_car_setup`; pit crew raw
`pit_stop_speed`; strategist `eff_race_strategy`; TP `eff` of `get_overall_skill()`.

**Player flow.** One **consolidated proposal** (driver + mechanic + pit crew + strategist; never TP)
covering all cars/championships — not one per TP. Single source of truth:
`GameState._last_tp_proposals`; the notification, the TDL item, and the Racing-Dept popup are all
**views** of it. The optimiser **skips already-assigned roles** (accepting doesn't re-propose
satisfied slots) and proposes **one driver PER empty seat** (multi-driver cars need a full crew).
**Partial accept re-optimises** the remaining cars over the reduced pool. Ignored proposals leave
cars unassigned → DNS (player's risk). The Racing-Dept panel uses `GameState.peek_tp_proposals()`
(read-only, no notification/TDL side effects).

**Proposal-surfacing consistency (S37.64).** The TP notification/TDL fires **only when there is
something to assign or a genuine critical** — it never surfaces a "0 assignments ready" item (the
old code did when the only proposals were `missing_*` criticals with a dry talent pool). The TDL
carries a **single stable item** `"🏁 TP assignments ready — Racing Department"` with **no embedded
count**, so a changing count no longer piles up multiple rows (`_clear_tp_tdl()` collapses any
prior/legacy `"TP has N …"` variants); the live count lives on the (subject-superseding)
notification. Dismissed by text on accept.

**AI flow (Phase 2 — pending).** `ai_auto_assign(team)` = `compute_optimal_assignments(team, cars,
include_tp=true)` applied directly, covering all five roles **including TP reassignment** at season
start and on roster change. `car_assignments.json` is the season-1 seed; the optimiser takes over
from the first roster change / new season.

**Future hook (not built):** a second proposal `kind="signing"` for driver-scouting recommendations.

---

## 10. BUILDINGS & THE BUILDING↔R&D COUPLING

Each building level provides some of: staff hiring slots, passive income / cost reduction,
stat bonuses, and unlocks for R&D projects or commercial upgrades. Exact effects live in the
Buildings sheet.

### THE CANONICAL SLOTS-vs-ASSIGNMENTS RULE (S33.2 — single source of truth)

Two SEPARATE concepts. The engine must never conflate them (conflating them was the root of the
"can't negotiate when garage full" and "driver joins early on level-up" bugs).

**SLOTS = hiring capacity = BUILDING LEVEL.** How many of each role you may EMPLOY. `slots =
building.level` (e.g. Garage Lv5 = 5 Race Mechanic slots). Stable across season rollover.

| Role | Slot-providing building |
|---|---|
| Team Principal | Headquarters (HQ) |
| Race Mechanic | Garage |
| Car | Garage |
| Driver | Racing Department |
| Cadet | Racing Department (Academy *produces* cadets, but they need a Racing Dept spot to race) |
| Designer | R&D Design Studio |
| Race Strategist | Ops Sim & Telemetry |
| Pit Crew | Pit Crew Arena |
| CFO | n/a — always exactly 1 |

**ASSIGNMENTS = deployment need = CARS & CHAMPIONSHIPS.** Where employed people are deployed; a
SEPARATE downstream check, NEVER the hiring cap:
- Each **car** needs: 1–3 drivers (per discipline `Driver_Per_Car`), 1 Race Mechanic, 1 Pit Crew
  (no Pit Crew for GK).
- Each **championship** needs: 1 Team Principal, 1 Race Strategist (no Strategist for GK or Rally).

**Consequence (S33.2 fix):** slot caps in `ContractEngine._get_max_slots_for_role` and
`get_slot_projection` read building level, not `player_team_cars.size()`. So next-season
negotiation works even at rollover when cars = 0 (building levels persist). Pre-signed contracts
activate ONLY when the season actually turns over (`current_season > signed_season`) — a
mid-season level-up never makes a pre-signed person join early.

### Slot-providing buildings (current)
| Building | Slots/level | Max level | Notes |
|---|---|---|---|
| Garage | +1 Race Mechanic (and +1 Car) | 89 | also +1800 weekly repair profit |
| Racing Department | +1 Driver | 89 | +10% driver morale/focus |
| Pit Crew Arena | +1 Pit Crew | 20 | −0.1s pit/level |
| Ops Sim & Telemetry | +1 Race Strategist | — | strategist hiring capacity |
| R&D Design Studio | +1 Designer | — | designer hiring capacity |
| Headquarters | TP slots (get_hq_tp_slots) | — | TP hiring capacity |
| Fitness Clinic | **0 slots** | 109 | fatigue-only (−10% fatigue); NOT a roster building |

Peak personnel demand at full capacity (after SC Dev→4): ~78 cars, ~120 drivers (Rally/TC ×2,
EPC ×3), ~78 mechanics. Building maxes are NOT sized to this peak (set somewhat arbitrarily) —
so changing a building max is a DESIGN choice, not a mechanical necessity.

### THE COUPLING (critical hidden rule)
Each slot-providing building's **MAX level hard-gates a top-tier Pillar-4 R&D project** (the
RnD sheet's `Connected_Building` column). The top project in each ladder is gated at the
building's CURRENT MAX.

| Building | Top R&D gated at max | Ladder below |
|---|---|---|
| Garage (89) | P3-012 @ Garage89 | P3-087(25), P3-009(30), P3-088(47), P3-089(64), P3-010(45), P3-090(85), P3-011(80) |
| Racing Dept (89) | P3-016 @ RacD89 | P3-091(11), P3-013(30), P3-092(28), P3-014(45), P3-015(70) |
| Fitness Clinic (109) | P3-060 @ clinic109 | P3-057(25), P3-058(55), P3-059(75) |
| Pit Crew Arena (20) | P3-064 @ Arena20 | P3-061(6), P3-062(9), P3-063(14) |

**RULE: a building's max level and its top R&D gate MOVE TOGETHER.** Change one without the
other and an R&D project orphans (unreachable, or trivially open) — a silent bug.

### Pending balance work (deferred to a focused balance session)
- **Building max rebalance** vs the real personnel peak (Racing Dept 89 is UNDER the 120
  driver demand; Garage/Pit Crew have headroom). Coordinate each change with its R&D gate.
- **Fitness Clinic rework:** max 109 + 0 slots = boring micromanagement. DECISION: slash its
  max level drastically AND automate allocation ("most tired served first" — recovery
  auto-applies to the most-fatigued driver/crew; player never hand-assigns). Re-gate/re-space
  P3-057/058/059/060 to follow the new max.

---

## 11. WRA REGULATION CYCLE

The World Racing Association periodically announces new technical regulations. **The cycle length is
PER DISCIPLINE GROUP, not a flat 4** (corrected S40.17 — the code was already per-group, the doc said
4): Formula 4 · Touring 5 · Karting 6 · Open Wheel 7 · Stock Car 8 · Rally 9 · Endurance 10 seasons
(`RnDEngine._wra_group_season_for` / `CYCLE_LEN`). At each cycle boundary, that group's existing part
knowledge is reset and teams must design a completely new car (a **from-scratch** design year — full
blueprint weeks, §8.6). New base reliability starts at 60 and climbs +10 each season until the next
cycle (§5). Seasons within a cycle are **mid-cycle refresh** years (half blueprint weeks, §8.6).

### 11.1 WRA submission & approval (S41.0)
A designed blueprint becomes a **manufacturing licence** only after WRA approval (§5.2). Rules:
- **No submission fee** (removed) and a **flat 1-week decision** for every tier (was a per-tier
  {1,2,4,5} table). The 1-week constant is what the AI planner's "latest safe start" backward-schedule
  relies on to guarantee a next-season car lands before week 52.
- **P1 (Design) and P3 (Reverse Engineering) are ALWAYS approved.** A late-season rejection of a
  next-season car would cause a full-season DNS (no car → no points → attrition out of the
  championship), so the pinnacle-integrity rule is: the car blueprints never reject.
- **P2 (Upgrade) blueprints carry a 10% rejection chance.** A rejected P2 is recorded
  (`wra_rejected_blueprints`), fires a **notification + world news**, and applies a **reputation hit
  scaled by championship tier** (higher tier = bigger hit; `WRA_REJECT_REP_PER_TIER × tier`). This is
  the only rejection in the system, by design.

---

## 12. CONTRACTS, GENERATION, AGING & ACADEMY

### Contract negotiation — overview
Driver/Staff/Sponsor contracts negotiate on: Base Salary, Performance Bonuses, Contract
Length, Release Clause, Buyout Bond. **Sponsor** deals are business deals — instant,
CFO-handled, no TP. **Driver and racing-staff** approaches follow the ordered approach flow
below (§12-A). When an approach target is **not interested**, a visible popup informs the
player (not just a silent news/notification).

**Two distinct protections — do not conflate them:**
- **Release clause** = security of the **PERSON**. The owner team must pay *this amount to the
  person* to release them early. (If an AI team poaches your driver via release clause, they
  trigger it and the clause is paid to the person on exit.)
- **Buyout bond** = security of the **OWNER TEAM**. Another team must pay *this amount to the
  owner team* to sign the person away while under contract. Compensates the team for the loss.

**Role split (authoritative — supersedes any "CFO handles all" text elsewhere):**
- **TP (Team Principal)** = racing/talent side. Makes the approach, gauges interest, negotiates
  contract terms for drivers and racing staff. A TP must be assigned before approaching a
  contracted person.
- **CFO** = financial side only. Sets bond-estimate accuracy and handles sponsor deals. The CFO
  has **no** effect on interest or contract terms.

### 12-A. Approach flow (ordered — THIS IS THE CANONICAL SEQUENCE)

Every approach runs in this exact order. Skipping or reordering steps is a bug. **Two separate
gates govern a signing: does the PERSON want to come (the TP's domain), and — if they're still
contracted at the join date — will their TEAM let them go (the CEO/owner-team's domain).**

1. **Cooldown check (first).** If this person's team recently **refused to release** them, they
   are blocked from re-approach for **26 weeks** (per person, week-granular). A still-cooling
   approach is rejected with "their team recently refused — try again."

2. **Person interest — DETERMINISTIC and binary (the TP's domain).** Score (S37.10) =
   `60 + (player_rep − talent)×0.7 + free_agent_bonus + clamp(rep_gap×0.4, −30, +15) + TP.reputation×0.3`,
   where `rep_gap` = player team reputation − the person's current team reputation. Free agents get
   `free_agent_bonus = 18` (and a low-talent (≤35) free agent is always at/above the threshold, so a
   brand-new team can field a car). The CORE GATE is `player_rep − talent`: a person is reachable only
   when the team's reputation is in range of their talent — so a rep-0 garage attracts only a handful of
   low-talent free agents, and the pool grows with reputation (rep-50 → ~371, rep-75+ → ~full grid).
   Drivers use hidden `potential`; staff use `talent`. The person is interested if the score
   **≥ 60** (`INTEREST_THRESHOLD`). **No dice** — this is the single source of truth shared by
   the "Interested Only" filter and the approach, so what the filter shows is exactly what the
   approach honours. No TP assigned → cannot approach a contracted person. **Not interested →
   approach ends** with a visible popup ("not the right time"). The filter shows only the
   genuinely-interested (100%), never a percentage.
   *(Earlier model, pre-S37.10: `talent×0.5 + 50 + clamp(rep_gap×0.5,±25) + TP.rep×0.3` — replaced
   because the talent term cleared the 60 threshold before reputation mattered, so a new garage
   attracted ~everyone.)*

3. **Determine contract status AT THE JOIN DATE** (immediate or next-season — player's choice):
   - **Free at join** = no contract now, OR (next-season signing AND ≤1 season remaining, i.e.
	 their contract expires by season start). These people are free agents by the time they'd
	 join → **no team-release gate, no bond** → straight to contract negotiation (step 5).
   - **Still contracted at the join date** → the team-release gate (step 4) applies.
   - *(One shared rule `_is_free_at_join` decides this, used by both the gate and the bond skip.)*

4. **Team-release gate — RANDOM (the owner team's domain; only if still contracted at join).**
   The person wants to come, but their current team may refuse to release them. Refusal chance =
   `clamp(45 − rep_gap×0.6, 10%, 80%)` — a stronger suitor is harder to refuse, but it's never
   certain. **On refusal:** a clear popup ("[Team] is not willing to release their [role] — you
   can try again in the future") + a **26-week cooldown** on that person (step 1). On success →
   the bond negotiation (the team's compensation) proceeds.

5. **Buyout bond negotiation with the OWNER TEAM** (only if still contracted at join date, and
   the team agreed to release in step 4):
   - 1 week per round, **max 3 rounds**: owner team replies accept / counter / reject.
   - CFO sets estimate accuracy shown to player: **±8% with CFO, ±30% without**. Informational
	 only — **no hard cap**; the market sets it.
   - **Bond (calculated AT THE JOIN DATE):** `weekly_salary × weeks_remaining × talent_factor`,
	 `weeks_remaining` counted from the season the contract STARTS.
   - `talent_factor`: 0–30 = ×0.8, 31–60 = ×1.0, 61–80 = ×1.3, 81–100 = ×1.8.
   - **Immediate mid-contract transfer:** **1.5× bond + 25% disruption fee.** Rare/expensive by
	 design — most signings are next-season.
   - If bond rejected / player walks → approach ends, no bond paid.

6. **Contract negotiation with the PERSON** (after bond agreed, or directly for free-at-join):
   - **1 round per week.** Player submits offer → other side replies next week.
   - **Per-item lock buttons** (🔓/🔒): lock agreed terms, counter the rest. The other side may
	 **unlock** a previously agreed item if the package becomes unacceptable.
   - **Patience:** 3 weeks of no response → expires ("Lapsed due to no response").
   - **Close** = closes the window, leaves the negotiation untouched in Pending Activity.
	 **Walk Away** = leaves a "you have walked away" entry that persists until the next week
	 advance, then clears.

7. **Bond paid ONLY on successful signing** (never when negotiations start). On success: bond
   paid to owner team, person transfers at the chosen start date (immediate or pre-signed).

8. **HQ overview PENDING ACTIVITY panel** surfaces every live item, both directions: interest
   checks, bond offers in/out (Accept | Counter | Reject), contract rounds due, pre-signed joins,
   walked-away entries, and expiring negotiations. Incoming AI approaches for the player's own
   personnel appear here too (player sets/accepts the bond — the team's security).

**NOTED FOR FUTURE (AI poaching — design ready, NOT yet coded):** when AI teams gain the ability
to approach the player's personnel (paired with the Transfer Market / AI world work), the player
must be **notified specifically in the LAST-CONTRACT-YEAR case** — i.e. an AI team approaches one
of the player's people who is in their final contract season, for next season. In that case the
person is free at join, so the player (their current team) **cannot refuse or charge a bond** —
the warning's purpose is to prompt the player to **re-sign them now** before losing them for free.
This notification fires ONLY for that last-year/next-season case, NOT for every AI approach (a
mid-contract AI approach already routes through the normal incoming-bond flow where the player has
a say). The existing `handle_incoming_approach` hook is the wiring point; no AI currently triggers
it.

### Team/Driver/Staff generation
The engine auto-populates championships to maintain min/optimum car numbers
(Team_Generation_Rules). New drivers/staff follow Driver_/Staff_Generation_Rules. Full staff
data for the 172 named teams is embedded in `teams.json` (modder-ready), plus a `free_agents`
pool topped up procedurally at season end. All staff effectiveness is multiplied by the
relevant Team Principal bonus.

### Discipline synergy
New drivers start all synergy values at 0; each race adds `1 + (1 × Feedback/100)`. Maxima are
defined in the Disciplines Synergy sheet and adjusted on championship change. (This same
adaptation matrix is reused as the distance metric for the News System, §13.)

### Aging / retirement / academy
Drivers have Age_Peak_Start / Age_Peak_End; after peak end, performance declines. A driver
without a contract for 2 seasons retires. Academy drivers get a **15% discount** on their first
professional contract with the academy owner.

---

## 13. AI TEAM BEHAVIOUR — the 5-stage ladder & News System

### 13.1 The ladder (the AI world's whole job is to STAY ALIVE & PLAUSIBLE — not play well)
A state machine; a team only pursues a higher stage when lower needs are secure; a fallen
giant drops back to Survive.
1. **Survive** — don't go bankrupt: take loans, cut discretionary spend, fill seats cheaply.
2. **Settle** — secure roster on contracts, basic buildings, reliable income.
3. **Develop** — R&D, upgrades, sign better (not just available) people.
4. **Establish** — optimise, defend key personnel, full programme, maybe a 2nd car.
5. **Conquer** — expand: BOTH vertical (climb tiers) AND horizontal (sideways into a parallel
   discipline at the same level, adjacent disciplines first via the adaptation matrix).

**Character = weights on the ladder**, not new logic: Frugal, Ambitious, Prestige, Balanced
(tuned in the Phase-5 balance pass). Build order: Survive + Settle FIRST (the world stops
dying) — cheap, reactive, must-have; Develop/Establish/Conquer are progressive polish. Each
economic system ships WITH its AI behaviour attached. Doubles as the player's career arc and
the trailer motto: **"Survive. Settle. Develop. Establish. Conquer."** STILL UNMAPPED: the
specific decision points WITHIN each stage (deferred until the economy systems exist).

### 13.2.1 NEWS FEED vs OPERATIONAL LOG — the curated split (S37.63–S37.64)

Until the full soundwave filter is built, there are **two distinct streams** and they must not be
conflated:

- **`weekly_log`** (`add_log`) — the raw OPERATIONAL/event log: DNS lines, "car condition unchanged",
  repairs, "added to garage", "starting assets ready", remaining-balance, weekly P&L, week dividers.
  Reset every week. **Not shown in the NEWS panel.**
- **`news_feed`** (`GameState.log_news`) — the curated WORLD-NEWS stream the **NEWS panel renders**.
  Persists across weeks, cleared per season, saved/loaded (old saves default empty). **Capped at
  `NEWS_FEED_CAP = 20` (S41.12): `log_news()` SELF-TRIMS on every append** — this is not just tidiness,
  it is a HARD SAFETY INVARIANT. The NEWS panel builds one autowrapping min-width `Label` per entry, and
  Godot's container-layout pass over enough of them self-recurses to a C++ stack overflow. Before S41.12
  the cap ran only at the top of `advance_week()`, so a big same-tick batch — the 100+ retirements the
  Stage-E cull logs at a season rollover — reached MainHub's `_refresh_log` uncapped and crashed the game
  at the season boundary. Capping inside `log_news` makes the feed size independent of caller/timing. The
  20-entry limit is display-only; the permanent per-person record lives in `retired_personnel` (§7.1).

**What IS news (routed via `log_news`, or `notify_event(mode:"news")` for the few notification-bearing
ones):**
- 🏁 **Race-result headline** — `"<CHAMP> — Winner: <crew label> (<team>)"`.
- 🏆 **Champions crowned** (driver + GK World Champion).
- 🏁 **Retirements** (driver/staff aged out).
- ✅ **Driver/staff signings** and 👋 **releases** / contract-expiry departures.
- **WRA regulation change** (a world rule event).
- `=== SEASON N BEGINS/COMPLETE ===` dividers (structural anchors).

**What is NOT news (operational `add_log` and/or notifications only):**
- All **DNS** lines and "car condition unchanged (DNS)".
- The whole **new-game setup block** ("added to garage", "starting assets ready", "Welcome", "Season
  N — <champ>", remaining balance).
- **Empty week dividers** (`--- Week N ---`) — removed from news (they were visual noise).
- **Commercial/economic**: sponsor deals, bankruptcy risk, car-sale milestones.
- **Development**: R&D / CNC / building completions, blueprints — these are notifications with action
  buttons (e.g. building completion → notification "→ Campus", S37.64), not news.
- Weekly net/P&L summary.

**No double-posting** — an event posts to news from exactly ONE source. Signings, which have both a
`log_news` line and an actionable notification, use `mode:"event"` on the notification so the news
line comes solely from `log_news`.

### 13.2 News System — sound-wave propagation (FUTURE filter — design, not yet built)
News is a wave from an origin point: propagates outward, DECAYS with distance, reaches a
reader only if magnitude still clears their threshold.
```
reach = importance − vertical_distance − horizontal_distance
```
- **importance** = intrinsic event magnitude (title win >> building upgrade).
- **vertical_distance** = reputation/tier gap, ASYMMETRIC: cheap DOWNWARD (prestige flows
  downhill), expensive UPWARD (small-team news needs high magnitude to climb — e.g. "the new
  Verstappen" GK champion).
- **horizontal_distance** = discipline gap, sourced from the existing discipline adaptation
  matrix (reuse it; don't author a second). **Tier COMPRESSES horizontal distance** — elite
  teams across disciplines form one peer community; compute horizontal distance using the
  HIGHER party's tier as the compression factor.
- Downward big-team news must be ASPIRATIONAL not operational (pinnacle drama, not routine
  status). The feed GROWS with the player as reputation rises. It's ONE scoring function over
  existing data — bounded, not an open-ended mandate.

The curated event list that actually feeds the news panel today (pre-filter) is the **NEWS FEED**
list in §13.2.1; the soundwave `reach` scoring above is the FUTURE filter that will rank/limit those
events by importance and distance once built.

### 13.3 AI R&D economy — the first concrete "Develop" behaviour (S41.2, Phase 3)

The ladder's **Develop** stage (§13.1) gets its first real system: a per-AI-team Research-Point
economy. Phase 3 lands the **substrate** — each non-player team's `rnd_ledger` meta and the team-routed
R&D pipeline (documented in §8.7). This is intentionally inert for now (no AI RP is earned or spent);
the behaviour that makes it visible arrives in the remaining steps of `AI_RnD_Economy_Spec_v2.md`:

- **RP faucet (§5 of spec) — LANDED S41.4:** AI teams earn RP by the same racing formula as the
  player (§8.4), hooked after `AIChampionshipSim.simulate_round`, credited per running car into the
  team's `rnd_ledger.rp` and capped by the team-aware storage cap. Studio level is seeded from
  `teams.json` (clamped to the player's 1..27 scale); the Lead is the team's highest-overall Designer;
  the difficulty knob is `ai_performance`. Fills ledgers only — spending awaits the planner below.
- **Planner (§6) — LANDED S41.6:** a forecast-driven scheduler in `LeadDesignerProposalEngine`, run
  weekly from `advance_week`. It walks the remaining calendar × the faucet to forecast RP, computes the
  next-season car's latest-safe-start week (minus a low-`planning` buffer), fills idle lines with
  surplus-gated P2 until then, switches to the 6-part P1/P3 car at the safe week, and feasibility-gates
  (a team that can't finish its car in time holds its granted baseline rather than over-committing —
  full retreat/backfill is step 6). Per-part P3-vs-P1 is survival-first (cheap P3 where Logistics
  provenance allows, else P1), upgrading P3→P1 only on fat forecast surplus. P4/P5 stay inert seams for
  the AI ladder session. The per-part decision is the seam the AI-CnC project attaches buy-vs-build to
  (`_cnc_buy_vs_build_hook`). AI R&D is debug-logged only, never player news.
- **Retreat & backfill (§7):** if a team's forecast can't finish next season's car in time it withdraws
  and retreats to a lighter championship rather than DNS-ing; a neighbouring team is fake-boosted only if
  the withdrawal would drop the championship below minimum participation. Every such event is world news.
- **On-track uplift (§8):** `car_strength` gains a `× (1 + perf_bonus(team))` factor so a team whose
  planner successfully researches performance blueprints fields a genuinely faster car.

The AI **CnC manufacture / install / resale** mirror is the explicitly-scoped project *after* that.

**Interim AI budget grant (S41.9) — a stopgap, explicitly flagged.** The AI economy (§3 income streams:
sponsor / prize / commercial) is not wired: `FinancialEngine` only *drains* AI salaries, with zero income,
so AI balances bled toward zero over a few seasons and the R&D CR/feasibility gates falsely locked teams
out (a team with ample RP but a poor balance failed the CR affordability gate — the real cause of the
"infeasible flood", not RP starvation). Until the real economy exists, `start_new_season()` credits each
non-player team a per-season budget, per championship it's registered in:
`(entry_fee + car_buy_cost + 2-car season salaries + 6× P1 L1 design CR) × 1.30`, all live-sourced from the
registry / `CNC_DATA` / current `RND_TASKS` so it tracks any cost tuning (e.g. the S41.8b rebalance). This
realises the ladder's **Survive** floor (§13.1 "don't go bankrupt") synthetically. **Remove it when the
real §3 AI income lands.**

> **KNOWN INTERIM IMBALANCES — revisit when the AI-CnC market is built.** With the grant + the deliberately
> generous double-cover (the grant sums BOTH the car-buy cost AND the design CR), the AI R&D economy is now
> intentionally *over*-funded to unblock development: **~90% of AI teams self-design their car every season**
> (up from ~50% before the fixes), and the grant injects **~4.2 billion CR/season across the grid**
> (dominated by GP1 at ~158M/team). Neither figure is intended balance — they are artifacts of a stopgap
> economy stood up purely so the R&D pipeline could be exercised and tested. The true buy-vs-build split,
> the right grant size, and whether low-tier teams *should* mostly buy-and-bank (per §13.1) only become
> answerable once the **AI CnC buy-vs-build market** exists and teams face a real cost trade-off. Treat the
> current numbers as scaffolding, not design intent; rebalance the grant and the design-cost ratios (§8.6)
> together at that point. The remaining genuine `INFEASIBLE` holds now concentrate in the low-km / short-
> calendar championships (GK, RALLY4/3, EPC Series, SC Truck) — those are the *honest* RP-constrained cases,
> not false positives.

---

## 14. AI CHAMPIONSHIP SIM — the "living world" (BUILT, lightweight v1 — S37.47)

**Status: BUILT.** Every non-player, non-GK championship now runs each race week via the
`AIChampionshipSim` RefCounted engine (`resources/scripts/`, Python-portable), so all 21
championships have live, moving standings instead of the old empty tables. (GK runs through
GKDiscipline's shadow sim; the player's championship through the real RaceSimulator.)

**How it works.** `car_strength(car)` → a single race-day scalar collapsing the inputs the real
lap-time model weights most heavily (driver `get_effective_pace()` as the spine + consistency +
race_craft, plus car `baseline_performance_index × condition`, × a mechanic `car_setup` multiplier)
— NOT the full lap-by-lap physics (too expensive for 20+ championships weekly). `simulate_round(champ)`
sorts strength + ±8% race-day noise → finishing order → awards points via the championship's existing
`points_system` / `add_points` / `add_team_points`, so it populates BOTH driver and team standings and
the EOS / Racing World screens need no data changes. Field source = `ai_cars[champ_id]` — the real
rosters loaded from `car_assignments.json` (multi-car teams, multi-driver EPC cars). Skips the player's
own car (real sim owns that result) and GK (shadow sim).

**Wiring.** Runs in the GameState weekly race loop as the `elif champ.id != "C-001"` branch after the
player `is_player_champ` branch — it does NOT reopen the S37.43 Bug-3 gate (no DNS spam). Engine
declared + instantiated at all 3 init sites (new-game / load / setup).

**`car_strength()` is the deliberate SWAP-POINT for Phase 5.** The strength model is currently a pure
function of existing stats. When the economy phases land, swap its internals to read economic outputs
(team budgets / character) so AI car strength reflects each team's financial state — without touching
the plumbing. Pairs with the Transfer Market (P51) for the fully-alive AI world. Full spec:
`FEATURE_AI_Championship_Sim.md`.

**Racing World display (S37.48).** AI championship cards show driver + team leader. The GK card shows
the driver AND team CHAMPION even when the player raced a different discipline (reads GKDiscipline
shadow standings for the driver champion + the CP3 cumulative `team_standings` table for the team
champion). The player's own championship uses the richer active card (full driver + team columns).

---

## 14.1 SEASON CALENDAR — full-season agenda (S37.26)

A read-only planning screen (`res://scenes/Calendar.tscn` + `Calendar.gd`) that aggregates every
DATED thing in the world onto one week-indexed view. Reached from the Main Hub (Calendar nav
button — *wiring pending*). Mandatory resource bar present (§15).

**Layout.** A vertical scroll of 4-week BLOCKS (Weeks 1–4, 5–8, … 49–52); each block is a row of
four week-cells. Every event in a week is a colored chip. The current week is highlighted. All 21
championships are shown in full (no collapsing) — the player may eventually field cars in all of
them, so "other" races are not hidden.

**Event types & colors.**
- **Your race** (blue) / **Other championship race** (gray) — `"Championship · Round X/N"` with the
  city as subtitle. "Your race" = a championship in `player_registered_championships`.
- **Registration deadline** (red) — from `get_entry_deadline_week(champ_id)`; these spread across
  the back half of the season (Wk 11 GP1 … Wk 49 GK) because each championship's `design_weeks`
  differs.
- **Building / R&D / CNC completion** (amber) — derived live as `current_week + weeks_remaining`
  from `campus_buildings`, `active_rnd_tasks`, `cnc_production_queue`.
- **Custom reminder** (teal) — player-created.

**Custom events.** A ＋ button (global, and per-week in each cell header) opens a CENTERED modal
(week picker + title + optional note). Custom chips carry a − button to remove them. Both ＋ and −
have tooltips. Custom reminders are **the only persisted calendar state** —
`GameState.custom_calendar_events` (saved/loaded; cleared on new game). Everything else is
recomputed on read, so it is never stale.

**Data source — `res://data/race_calendar.json`.** Generated from the Excel *Race Calendar* sheet
(all 295 rounds across 21 championships), keyed by championship id. Each round carries week, round,
city, track_id, laps, hours, rain_probability, audience, points_scheme, and the sprint/playoff/
double-race flags. This JSON is the intended single source of truth for schedules and is reused by
the race sim and the AI Championship Sim (§14); the hardcoded `CHAMPIONSHIP_CALENDARS` in
`GameState` is now redundant and should be retired in a focused pass. **GK** is 21 rounds; Round 21
is the Week-46 two-race weekend (Le Mans) — follow the Excel exactly (per Rule #4 the Excel/code is
truth, not an invented "Round 22").

**Engine — `CalendarManager` (RefCounted).** Pure/headless-testable. `get_events_by_week()` /
`get_all_events()` / `get_events_for_week(week)` build the unified event list; `add_custom_event` /
`remove_custom_event` mutate the store. Loaded via `preload(...)` from `GameState.get_calendar_
manager()` and the scene (no `class_name`, to avoid global-class parse-order errors). No new
autoload — engine class + scene + a store on the existing `GameState` autoload.

**Pending.** Add the Calendar button to the Main Hub nav; build the hub's own compact 4–5-weeks-
ahead strip (same `CalendarManager.get_events_for_week()` source, no new data work).

---

## 15. PLAYER NOTIFICATION & UI CONVENTIONS

### Notification system
**Bell** top-right of the Main Hub with an unread badge; opens a slide-in panel. Priority tiers:
| Tier | Color | Meaning | Auto-popup | Sound |
|---|---|---|---|---|
| Critical | Red | act this week or lose something | Yes (banner) | Urgent |
| High | Orange | act within 4 weeks | No | Soft chime |
| Normal | Blue | informational / opportunity | No | No |

Extras: weekly To-Do List (5 most important tasks), persistent log (Done/Dismissed), Smart
Snooze (1/2/4 weeks), critical banner, End-of-Season summary screen.

**Recurring-notification collapse (S35.1–S35.3):** standing notifications that re-fire each
week/race — resource warnings (no fuel, low spare parts, bankruptcy risk), pre-race DNS reasons
(no fuel, undelivered car, no driver/mechanic/pit crew), and the GK "season over" notice — carry
a `subject` key. A new notification supersedes any earlier one with the same subject, so the panel
keeps only the **current** instance instead of stacking one per advanced week (the old behaviour
made the panel boring and ignorable). This is text-independent, so a message whose text changes
week to week (e.g. a delivery week or deadline embedded in it) still collapses. Per-car/per-champ
subjects keep distinct items separate while each one collapses over time; the weekly log keeps the
full history (only the panel collapses). The GK elimination notice additionally fires exactly once
per season (a per-season flag), since a Round-1 exit otherwise re-announced at every later round.

**Season-rollover clear (S41.12):** `SeasonManager.start_new_season()` calls
`gs.clear_all_notifications()` at rollover start. Last season's operational notifications (low fuel,
missed registration deadline, DNS readiness gaps, etc.) are meaningless in the new season and only
clutter the panel, so the whole notification list is wiped at the boundary. **Ordering matters:** the
clear runs BEFORE the Stage-E cull / aging pass (§7.1), which is what generates the genuine new-season
notifications ("your driver retired — sign a replacement", "car needs building", academy/contract
expiries) — so only the pre-rollover backlog is cleared and the new season's real alerts survive
intact. (The curated `news_feed` is separately cleared per season in the same function; §13.2.1.)

### 15.1 Notification Framework — the 1-event model (S37.7)

The governing principle for **all** notifications. A single EVENT fires once and may produce up to
three distinct outputs — never a recurring nag:

1. **The event triggers a notification.** Entry point: `notify_event(event_id, priority, message,
   destination, mode)` on `NotificationManager` (wrapped on `GameState`). `event_id` is a stable key
   used for once-firing and supersede.
2. **The notification may lead somewhere.** It can carry a `destination` button that opens the screen
   where the player acts (a key in `NOTIFICATION_DESTINATIONS` — e.g. `staff_hub`, `hq`, `garage`,
   `logistics`, `financial_dept`). In parallel, if the underlying condition is a standing task, it is
   reflected as a **read-only row in the TO-DO list**.
3. **Meaningful world events also create news.** Big signings/releases, a championship win, a race
   result, a retirement → posted to the curated **`news_feed`** (the NEWS panel). Two entry points:
   `GameState.log_news(msg)` (the primary path) and `notify_event(…, mode="news")` (for events that
   also need a notification). The operational `weekly_log` (`add_log`) is a SEPARATE stream and is NOT
   shown as news — see §13.2.1 for the full news-vs-log split and the curated event list.

**Modes:**
| Mode | Behaviour | Use for |
|---|---|---|
| `once` | Fires exactly once ever (tracked by `event_id` in `_fired_once`). | Optional standing facts mentioned a single time (e.g. "no CFO"). |
| `standing` | Subject-superseded: one live instance, refreshed when the condition re-fires. | Sparingly — prefer the TDL for chores (e.g. low fuel before a race). |
| `event` | One-off event notice (no dedup beyond identical-text). | "Garage upgraded to L2" + a button to the Garage. |
| `news` | Posts to the curated `news_feed` (NEWS panel) via `_push_news`; also raises a notification. | Race results, titles, retirements, marquee signings (events that also need a bell notice). |

**THE CARDINAL RULE — the TO-DO LIST IS READ-ONLY AND NEVER EMITS NOTIFICATIONS.** The TDL is
rebuilt from current state each week (`get_pending_tasks`) and exists so the player can *see*
outstanding work; it must not also fire notifications, or standing chores spam the bell every week.
Operational "you should do X" reminders belong in the TDL; the notification fires once for the
*event*, not once per week for the *state*.

**Rationale / history.** The old code inverted this: the weekly TDL builder re-appended "No CFO"
every week (a recurring task) AND a separate per-race emitter in `RaceSimulator` fired the same
condition every race — so the player saw the same notice at W8/W10/W12. Under the framework, CFO is a
single read-only TDL row plus one `notify_event("no_cfo", once)` with a Staff-screen button. (CFO is
explicitly OPTIONAL — good-to-have, not required to field a team.) **S40.0:** that single CFO row now
appends an informative tail — "Financial Department is not optimized." — to the *same* line (not a
second row), so the cost of the empty CFO seat is explicit while the read-only/dismissible/Staff-routed
behaviour is unchanged.

**Migration status — PHASE 3 COMPLETE (S37.37–S37.49).** Every `add_notification` across all engines
and scenes has been migrated to `notify_event` (or `show_popup` for blocking errors). Files migrated:
ContractEngine, RnDEngine, SponsorManager, CarManager, SeasonManager, RaceSimulator, GameState,
FinancialEngine, DriverManager, StaffManager, TPProposalEngine, CampusManager, ChampionshipSelect,
Logistics, MainHub (the four already-Phase-1 scenes — RacingDept, Garage, StaffHub, Drivers — had
nothing left). Classification rules applied consistently:
- **Signings & departures → `news`** (driver/staff hired, signed, released, retired) — the news LINE
  comes from `log_news`; the accompanying notification uses `mode:"event"` so it is not double-posted
  (S37.64).
- **Recurring chores / distress → `standing`** (financial insolvency/bankruptcy/low-funds; DNS
  readiness gaps; resource shortfalls) — one live instance refreshed weekly, never a growing stack.
- **Blocking "can't do this" errors → `show_popup`** (an on-the-spot AcceptDialog).
- **Discrete one-offs → `event`** (loans, building sold, car purchased, **building upgrade complete →
  Campus** (S37.64), R&D/CNC ready), routed to the relevant building via `destination`.
- **Redundant-with-popup notices → deleted.**

**News-feed curation (S37.63–S37.64).** The NEWS panel was previously the raw `weekly_log`, so it
showed DNS spam, new-game setup chatter, and empty week dividers. It now renders a dedicated
**`news_feed`** (curated via `log_news`); see §13.2.1. The `_push_news` hook was also fixed to push a
**String** into the typed `news_feed: Array[String]` (it previously pushed a Dictionary, which threw a
runtime type error on retirements/signings).
Framework-internal `add_notification` (inside `notify_event` itself) and pre-existing subject-collapsed
resource warnings are intentionally retained. The full per-file ledger lives in
`Supporting Files/Notification_News_Roadmap_v1.md`. The news soundwave/propagation FILTER (§13.2)
remains a separate design pass — for now news is "everything visible."

**SEQUENCING — DONE.** This was a hard ordering: the Main Hub redesign (the bell/badge/panel/banner/
TDL surfaces) had to land before the notification loop could be built against it. Both are now
complete — Main Hub redesign (S37.27) → notification framework + full legacy-`add_notification`
migration (S37.7 → Phase 3 complete S37.49). The remaining notification-adjacent work is the news
SOUNDWAVE FILTER (§13.2), a separate design pass.

### Resource bar visibility (design rule — MANDATORY)
The persistent top resource bar is a **required, always-present element of every in-game scene.**
It MUST be visible in ALL scenes, with only these deliberate exceptions: popups/modal overlays,
New Game, Race Results, End of Season, Beginning of Season. Any scene that currently lacks it is a
bug to fix, not an accepted state. Implement as: the bar is shown by default and is explicitly
suppressed ONLY in the listed full-screen-flow / modal contexts — never omitted by accident. When
building or reworking any scene, wiring in the shared resource bar is part of "done."

### Layout conventions (large-font safety)
- Tall content is wrapped in a ScrollContainer with the action/footer row PINNED below it, so
  buttons never fall off-screen.
- Rows that risk horizontal overflow use grids or split rows rather than single wide HBoxes.
- The global window stretch is `canvas_items` / `aspect=expand` so the 1920×1080 UI scales to
  any window.

### Personnel hubs & the Shortlist (S35.10)
The Drivers and Staff hubs share a deliberate UX language so once you learn one, the other reads
the same:
- **Readable rows.** Available-row stat values render at 24px; a maxed stat (100) is shown in a
  brighter green so the eye finds it instantly.
- **Aligned grid using the full width.** Columns are PROPORTIONAL (a stretch ratio per column via
  `size_flags_stretch_ratio`), not fixed pixels — the table spans the whole screen and never clips
  at any resolution, and the column header (in a panel matching the row card's left border +
  margins) lines up straight down. Helper: `_add_col(parent, text, weight, color, font_size)`.
- **Team + Contract are two separate columns** — the person's current team (or "—" for a free
  agent) and, separately, the contract status/duration.
- **Obvious sorting.** The active sort button is highlighted and shows a direction arrow (▼ high→
  low, ▲ low→high); a plain-language **"Showing: …"** line states the active filter + sort (e.g.
  "Showing: Mechanics · interested only · sorted by Pit Stops ▼") so the list state is never a
  mystery.
- **Filters as toggles.** Both hubs carry "Interested Only" and "Free Agents Only" toggles (the
  Staff hub gained the free-agents toggle in S35.10 for parity with Drivers).

**Shortlist (a personal UI bookmark, not gameplay-affecting).** Every driver and staff member has
a persisted `is_shortlisted` flag (saved/loaded, default false on old saves). A ★ icon toggle
(filled/hollow, tooltip only — no text) appears on the right of each hub row AND in the View Card
popup; both write the same flag, so they stay in sync. A dedicated **Shortlist screen**
(`Shortlist.tscn`/`.gd`) shows the unified list — drivers AND staff together — organised by ROLE
TABS: **All** (everyone, with a Role column to tell them apart; sortable by the universal fields
Overall/Age/Salary), then **Driver**, then the six staff roles. Each tab shows a count badge; the ★
in the screen removes a person (row leaves, counts update). It's reachable from four entry points —
the Staff hub, the Drivers hub, the Main Hub top bar, and the HQ nav list — and "Back" returns to
the Main Hub (consistent with the other hubs). Shortlist API on GameState:
`toggle_shortlist`, `is_shortlisted`, `get_shortlisted_by_role` ("All" / "Driver" / a staff role),
`get_shortlist_counts`.

---

## 15.2 STATE HANDLER CHECKLIST — the three-handler rule (MANDATORY)

*Born from bug #52 (S37.28) + the full S37.29 audit. Read this before adding any GameState var.*

Persistent game state in `GameState` must be wired into **THREE handlers** or it leaks/breaks:
1. **`setup_new_game`** — reset it to its starting value (so a New Game does not inherit the
   previous one — the #52 leak).
2. **`save_game`** — write it into the `save_data` dict (so it survives to disk).
3. **`load_game`** — read it back with a default via `data.get(key, default)` (so a load restores
   it AND old saves do not crash).

**Decide the category of each new var, then wire the matching handlers:**

| Category | Example | new_game | save | load |
|---|---|---|---|---|
| **Persistent state** (collections, balances, counters, registrations, fuel/SP, GK data) | `active_wra_submissions`, `weeks_in_negative`, `custom_calendar_events` | reset | save | load |
| **Transient / UI routing** (momentary, meaningless on disk) | `pending_hq_tab`, `pending_season_screen`, the `pending_*` strings | reset | — (do NOT save) | clear to default |
| **Derived / rebuilt** (regenerated from other data at setup) | `active_championships` (rebuilt in `_setup_championship`), `_player_staff_*` caches, `ai_cars`, `last_race_*` | — | — | — |
| **Static-from-file** (loaded at init) | `race_calendar_data` (from `race_calendar.json`) | — | — | — (reloaded each launch) |
| **Pure constants / config tables** | `CHAMPIONSHIP_REGISTRY`, `CNC_DATA` | — | — | — |

**Illustration (same session, two vars, different handling):** the Calendar feature added
`custom_calendar_events` (player-created → persistent → all three handlers) and `race_calendar_data`
(loaded from JSON → static-from-file → none of the three). Same feature, opposite wiring.

**The audit habit:** when in doubt, the var is persistent state — wire all three. A missing
`save`/`load` pair silently loses player progress; a missing `new_game` reset silently leaks the
previous game. Both are invisible until a player hits them. The S37.29 audit cross-checked all 129
GameState vars this way; re-run it after any batch of new state.

---

## 15.3 STANDARD SCENE LAYOUT — the "Main Hub concept" header (MANDATORY) — S37.36

Every in-game scene uses the SAME minimal header. Scene-specific controls go in a SUB-ROW *below*
the header, never inside it. This is the pattern the Main Hub itself uses, and it is mandatory.

```
HEADER  (one row, fixed set):   [ Scene Name · Level ]   [ Resource Bar ]   [ Back ]   [ Main Hub ]
SUB-ROW (optional, below):      [ scene-specific labels / buttons … ]
BODY:                           [ the scene content ]
```

### Header rules (never overflow if you follow these)
- The header contains ONLY these four things, in this order: **title (Name · Level)**, **resource
  bar**, **Back**, **Main Hub**. Nothing else.
- The **title** is `SIZE_EXPAND_FILL` — it absorbs all the slack and forces the header to exactly the
  viewport width, pinning the bar + buttons to the right edge ON SCREEN.
- The **resource bar** is `SIZE_SHRINK_END` (compact, natural width). Do NOT make it EXPAND_FILL and
  do NOT add an expanding spacer before it — that consumed all the width and pushed the buttons off
  screen (the S37.34 mistake). The expanding *title* is what centres/pins everything.
- **Back** returns to the previous screen (usually Campus); **Main Hub** jumps straight to the hub.

### Resource bar component
The bar is the shared component `res://scenes/components/ResourceBar.gd` (§15). Instantiate the
SCRIPT — `const ResourceBarScript = preload(...)`, `var bar = ResourceBarScript.new()` — with NO
`.tscn`, NO `class_name`, and an UNTYPED var (a `class_name` + preload collides; a `.tscn` causes a
PanelContainer/Control type-mismatch). Add it to the header, then call `_resource_bar.refresh()` from
the scene's existing build/refresh function so values update immediately after any resource change.
The bar is compact (font 22, no per-item min width) so it never crowds a header.

### Scene-specific controls → SUB-ROW
Anything that is NOT the four header items (status labels, tab strips, "Add event", "Racing World",
"Shortlist", driver-slots/income, RP storage, blueprint counts, etc.) goes in a row BELOW the header,
exactly like the Main Hub's nav row sits under its top bar. This keeps the header a fixed width that
cannot overflow regardless of font size.

### Documented exceptions (allowed)
- **Main Hub** — has its own bar + nav and no Back/Main Hub buttons (it IS the hub).
- **HQ** — keeps its team-colour **badge** (team name) on the far left: `[badge][Name·Level][bar][Back][Main Hub]`.
- **BeginOfSeason / EndOfSeason** — ceremony screens: the bar sits top-right, and they keep their own
  Start/Continue flow buttons instead of Back/Main Hub.

### Why this exists (the overflow lesson)
Headers were running off the right edge with the right-hand content (e.g. RacingDept's whole right
column) cut off. Root cause was NOT the window stretch aspect (`expand` vs `keep` made no difference)
— it was **oversized fonts** (theme base 32px + 905 per-element overrides, titles 44–72px) plus too
many elements crammed into the header HBox, whose VBox parent then grew wider than the viewport and
dragged the body with it. The fix is structural: a minimal, fixed header (above) + a sub-row. Apply
it to every new scene.

---

## 16. LOCALIZATION (Rule 3)

Every user-facing string MUST go through `Locale.t("key")` or `Locale.tf("key", [args])`
(supports `{0}` placeholders and `%` formatting). Missing keys fall back to showing the key
text (no crash) and log a warning — so raw keys appearing on screen means a missing entry.

**Process rule:** when editing any UI file, localize its strings in the SAME pass and output an
updated `Locale.gd` alongside. **Session-start check:** scan that every `Locale.t("…")` key
referenced under `scenes/` exists in `Locale.gd` (a stacked merge once dropped 16 keys and
showed raw key text in-game).

**R&D Studio — fully localized (S35.20–S35.21).** The entire R&D Design Studio is now localized:
title bar, tab/pillar names + descriptions, section headers, designer & active-task panels, all
P1–P4 catalog strings, WRA status, assign blockers, the consolidated P4 requirement line, AND all
100 Pillar 4 Special Project names + descriptions (keys `sp_{id}_name` / `sp_{id}_desc`, resolved
via `RnDStudio._sp_name` / `_sp_desc` with a raw-value fallback for missing keys / old saves).

**Licensing rule — "Formula" → "GP".** No user-facing string may say "Formula" (licensing). Use
"GP". Fixed so far in the R&D Studio + `Locale.gd` (the next-season label, the REQUIRED tag, the
SP_RACE_1 name). **Still outstanding:** NewGame screen and HQ-WRA still show "Formula" (BUGLIST
#21). NOTE: internal `"Formula"` WRA-group dictionary keys (`["C-021"…]`, CYCLE_LEN, the reverse
map) are CODE IDENTIFIERS, never shown to the player — do NOT rename them.

**Outstanding localization DEBT (deferred, by choice):** PRE-EXISTING hardcoded strings remain
elsewhere (NewGame title/subtitle/hints, load-picker labels, and the P1/P2/P3 per-blueprint TASK
TITLES, which are string-interpolated rather than keyed — e.g. "GK Championship — Aero S2
Blueprint"). A full cross-scene sweep is its own future session — do not half-do it inline.

---

## 17. TYPOGRAPHY & THEME

- **Font: Inter (SIL OFL).** `resources/fonts/InterVariable.ttf` is the shipped variable font;
  `Inter-OFL-LICENSE.txt` ships with it (license compliance). Set as `default_font` in
  `resources/AppTheme.tres`, wired via `[gui] theme/custom` in `project.godot`.
- **Base size 32**; per-label sizes across the ~36 scene files were scaled ×2.0 from their
  original values (hierarchy preserved). A future typographic polish pass is a known
  nice-to-have now that Inter is live.

### 17.1 Audio (S40.1) — UI click sound (roadmap #2)

The project's first sound. A single autoload, **`UISound`** (`res://autoloads/UISound.gd`, registered
in `project.godot` by path like `Locale`), plays a short click whenever **any `BaseButton`** is pressed —
across all ~39 code-built scenes and anything added later — with **zero per-button wiring**. It works by
connecting to the scene tree's `node_added` signal and auto-attaching the `pressed` handler to every
current and future button (each connected once, guarded by `is_connected`).

- **Asset:** `res://resources/audio/ui_click.wav` — a Pixabay "computer mouse click" (uploader
  *universfield*), cleaned for the game: silence trimmed (original had ~900 ms trailing dead air), mono,
  44.1 kHz, normalized to ~−3.6 dBFS peak, micro-fades on both edges → a tight ~72 ms click. **Licensing:**
  Pixabay Content License — free for commercial use, no attribution required; it's a generic recorded
  click (not a system-sound rip) and ships embedded/modified inside the game (not redistributed as-is),
  so it's clean for Steam. Keep a provenance screenshot of the source page. (Consistent with the
  Brainstorm_Threads asset rule: shipped audio is human-made, not AI-generated.)
- **Fallback:** if the WAV is ever missing, `UISound` synthesizes an equivalent click at runtime, so the
  game is never silent or broken. Drop a replacement WAV at the same path and it's used automatically — no
  code change.
- **Routing & settings:** plays on a dedicated **"UI" audio bus** (created at runtime if the project has
  no bus layout) at **−6 dB** by default. Exposes `enabled` + `volume_db` with `set_enabled()` /
  `set_volume_db()` so the future **Settings menu (roadmap #21)** can wire a UI-volume slider/toggle
  directly. Disabled buttons stay silent automatically (Godot doesn't emit `pressed` while disabled).
- **Repo note:** commit the Godot-generated `ui_click.wav.import` and `UISound.gd.uid` alongside the
  source files (needed to resolve the asset in builds/other machines).

---

## 23. CORPORATE TAXATION (S40.14)

A seasonal tax on the company's net profit, charged once at season end (the `Taxes` term in §3 is this
— seasonal, not weekly).

```
Effective_Tax_Rate = 0.24 − (CFO.budget_planning / 100 × 0.09) − P4_tax_reduction   (floored 0.15)
Season_Tax = Effective_Tax_Rate × max(0, season_profit)
season_profit = balance_at_season_end − balance_at_season_start
```

- **Base 0.24** (OECD 2025 average statutory corporate rate). **Floor 0.15** (the global-minimum-tax
level) — the effective rate never drops below it.
- The **CFO's `budget_planning`** stat reduces the rate: a maxed CFO (100) reaches the 0.15 floor; no
CFO pays the full 0.24. The **P4 `tax_reduction`** special-project effect stacks on top (respecting the
floor).
- Applied to **net season profit only** — losses are not taxed. Profit basis = balance growth since
season start (`GameState.season_start_balance`, snapshotted at new-game and each `start_new_season`,
saved/loaded).
- **Deducted at season end** via `SeasonManager.end_season()` (after sponsor/supply settle, so the basis
is final), with a player **notification**. Projected tax is shown live in the **HQ Financial Department**.
- Engine: `FinancialEngine.get_season_profit / get_effective_tax_rate / get_projected_season_tax /
apply_season_end_tax`.

---

## 18. ROADMAP (economy first, race last)

The Road_map.md in the supporting files folder is the file the leads the way on what is next

---

## 19. STILL OPEN / CARRIED FORWARD

- **Bankruptcy-continue crash:** appeared fixed via the end-of-season "raced-only" standings
  filter, but observed surviving only once — re-test deliberately; if it recurs, capture the
  Godot error line (possible second cause).
- **AI Championship Sim / living world:** ~~all non-GK championships must simulate for all teams every
  season (currently only GK shadow-sims)~~ **STRUCK (BUILT, S37.47, §14):** `AIChampionshipSim` now
  runs every non-player, non-GK championship each race week (lightweight strength scalar). *Remaining
  for the FULL living world:* (a) Phase-5 economic strength model — swap `car_strength()` internals to
  read team budgets/character; (b) Transfer Market (P51) so AI rosters move between seasons; (c) the
  news SOUNDWAVE FILTER (§13.2) so champion/result news is filtered by reach instead of "everything
  visible" (champion news currently fires for player + GK only).
- **Designer model reconsideration (§22):** the current model gives each team many Designers, and the
  new-game GP path now starts with one (§7.3). Manual §22 idea: move to **1 Designer per principle +
  1 per special project + 1 for commercial cars** instead. Open — schedule a Designer-rework pass; it
  touches generation, hiring slots (R&D Studio), and the new-game starting roster.
- **New-game card display vs. provisioning (S37.50, partial S37.61):** `NewGame.gd` per-championship
  `buildings`/`includes` lists are DISPLAY-ONLY. The RALLY4 card now correctly lists 2 drivers
  (driver + co-driver, S37.61). Still understated: GP4 (real provisioning adds R&D Studio + CNC Plant
  + Designer, §7.3); EPC cards could likewise show 3 drivers. Cosmetic — finish aligning card text to
  what the player actually receives.
- **TP Assignment — Phase 2 (AI):** ~~`ai_auto_assign` incl. TP reassignment at season start /
  roster change~~ **STRUCK (resolved, S35.0):** `ai_auto_assign_all_teams()` is built and wired
  into the Season Transition Pipeline at Stage C (§7.1) — `compute_optimal_assignments(team, cars,
  include_tp=true)` applied directly for every AI team, Season 2+. Verified live.
- **TP engine cleanup:** legacy `get_tp_proposals_all()` is now dead code (no internal callers,
  replaced by `compute_optimal_assignments`); remove in a focused pass.
- **TP proposal timing:** should fire ~1 week before a race, not every racing week — still open.
- **Staff/contract bugs (carried):** staff-screen lag on "Only Interested"; interested→not-interested
  inconsistency; contract approach stuck a full season. Need live tracing.
- **Building max / Fitness Clinic rebalance** (§10) — deferred to a focused balance session.
- **R&D economy (S40.5–S40.17):** ~~early-game RP starve; car un-designable-in-time at high tiers~~
  **STRUCK (resolved):** RP faucet retuned (§8.4) and blueprint design-time fixed (§8.6) — a
  tier-appropriate team can now design its next-season car within the registration window, verified vs
  all championships. *Remaining:* (a) **AI R&D economy** — the NEXT build: per-AI-team RP ledger + AI
  research decisions (P1/P3 hitting registration deadlines, P2, occasional P4), tied to the §13.1 ladder;
  the `LeadDesignerProposalEngine.ai_fill_design_lines_*` seam is the integration point and the P4
  accessor layer is already team-aware. Hard requirement: an AI team must never silently fail to field a
  car — decide the fallback. (b) **~50 P4 effects still banked-unwired** (manufacturing/logistics/repair/
  strategy/discipline/academy/commercial) — each a one-line accessor wire, deferred; the AI build needs
  their cost/time DATA (present), not the wiring. (c) **No mid-race mechanical DNF roll yet** — reliability
  P4s are routed to wear until the race build adds a failure roll. (d) **Not yet Godot-parsed** — S40.5–
  S40.17 verified by analysis only; parse/playtest is the first task before the AI build.

> **STRUCK (resolved):** Excel master sync — `Master_Championship_Variables_Map_v2_8.xlsx` already
> reflects SC Dev (C-014) cap = 4 and GK races = 21. Item closed.

---

## 20. IMPLEMENTATION CHANGELOG (recent — newest first)

Historical record of what shipped; design facts above already reflect these.

- **S40.5–S40.17 (R&D economy, design-time & taxation):**
  - *RP faucet re-anchored* — `RP_PER_LAP_BASE` 1.0 → 3.0 (§8.4); fixes early-game starve, keeps P4
	aspirational; swept across all pillars.
  - *Blueprint design-time fix* — P1/P3 L1 weeks halve mid-cycle (`P1_REFRESH_WEEKS_MULT` 0.5), full
	from-scratch (§8.6); EPC/GP1 registration-deadline override to week 31; every team can design its car
	before registration (verified).
  - *Corporate tax* (§3, §23) — 24% base on season profit, CFO-reduced to a 15% floor, minus P4
	tax_reduction; season-end deduction + notification; HQ Financial Dept display.
  - *P4 effect accessor layer + 4 wired clusters* (perf/reliability/fatigue/economy); ~50 effects still
	banked-unwired.
  - *One-Lead-per-team* — `staff_designer.json` surgery (172 Leads + 100 free agents); RP now scales with
	Studio level × Lead skill; R&D Studio Lead capacity/comfort panel.
  - *§11 corrected* — WRA cycle is per-group (4–10 seasons), not a flat 4 (doc↔code reconciled).
  - *Not yet Godot-parsed* — verified by analysis (brace-balance + type audit) only.

- **S37.65 (keyboard-verification pass + interest rebalance):**
  - *Car delivery pipeline (Phase 2, §6.0) → ✅ verified working* in play (buy/build → delivery week →
	DNS-until-ready → race-ready on delivery).
  - *Keyboard verification* — CP4 championship-registration cluster (#9/#19/#44/#48) and the roster-desync
	/ contract-loop cluster (#35/#6/#10) confirmed working (§21).
  - *Interest model stricter at low reputation (§12, ContractEngine)* — `FREE_AGENT_INTEREST_BONUS` 18→5,
	`REP_TALENT_SLOPE` 0.7→0.9, low-talent FA floor 35→34 (named const `FREE_AGENT_FLOOR_TALENT`), uphill
	`rep_gap_bonus` cap 15→8. A rep-15 GK garage now attracts ~10 drivers / ~6–7 staff per role (was
	~49 / ~74); reach grows smoothly with reputation. Shared by the "Interested Only" filter and the
	approach gate, so they still agree.
  - *Economy declared stable enough to start ROADMAP PHASE 3* (Commercial Factory + R&D Pillar 5).

- **S37.60–S37.64 (Bug #38 multi-driver CREW MODEL + news-vs-notification split):**
  - *Bug #38 → ✅ (multi-driver-per-car, S37.60–S37.61)* — `Car.driver_ids[]` is now canonical, sized
	by the discipline rule (Rally/TC = 2, EPC = 3, else 1); `driver_id` retained as a synced seat-0
	accessor for back-compat. Seat-aware assign/unassign (`CarManager`), all-seat readiness (a car DNSes
	if any seat is empty), save/load with legacy migration, new-game full-crew provisioning, and AI cars
	filling every seat from `car_assignments.json`. **Crew model:** co-drivers share ONE car result —
	only the seat-0 representative is registered in standings (one entry / one points award), but ALL
	co-drivers gain fitness + stat growth, and the UI shows the combined `"Surname / Surname"` crew label
	everywhere (`GameState.crew_label_for_driver`). Garage renders DRIVER 1/2/3 seats. Touched ~18 files
	(Car, CarManager, GameState, AIManager, RaceSimulator, AIChampionshipSim, TPProposalEngine,
	DriverManager, NotificationManager, GKDiscipline, Garage, RacingDept, HQ, Drivers, BeginOfSeason,
	NewGame, RaceResults, RacingWorld).
  - *Crew development display (S37.62)* — Race-Results DRIVER DEVELOPMENT lists every crew member via a
	per-member `crew_devs[]` on each result entry (co-drivers' growth was previously invisible).
  - *News vs notification split (S37.63)* — added a curated `news_feed` (the NEWS panel) separate from
	the operational `weekly_log`; `GameState.log_news()` is the news entry point. Only genuine world
	events are news (race result headline, champions, signings/releases, retirements, WRA rule change,
	season dividers); DNS/setup/development/economic chatter and empty week dividers are log/notification
	only (§13.2.1). `news_feed` persists across weeks (cap `NEWS_FEED_CAP=20`, S41.12), clears per season, saved/loaded.
  - *News-feed fixes (S37.64)* — (a) **crash fix**: `_push_news` now pushes a `String` into the typed
	`news_feed` (was a Dictionary → runtime type error on retirements/signings); (b) signings no longer
	**double-post** to news (their notification is `mode:"event"`, news comes from `log_news`);
	(c) empty `--- Week N ---` dividers removed from news.
  - *Building completion notification (S37.64)* — a finished build/upgrade (e.g. Racing Department) now
	fires a notification (`"🏗 X upgrade complete — now Level N"`, → Campus); previously it only logged,
	so the player got no alert.
  - *TP-proposal consistency (S37.64)* — no more "TP has 0 assignments ready" item (surfaces only when
	there is something to assign or a genuine critical); ONE stable TDL item `"TP assignments ready"`
	(no embedded count) that supersedes instead of piling up per changing count; legacy count variants
	purged.

- **S37.51–S37.59 (Bug #22 IP/name close-out + calendar-source / Main-Hub fixes):**
  - *IP & name pass (Bug #22 → ✅)* — (a) 13 real-athlete surnames scrubbed from the assigned JSON
	(Räikkönen/Mäkinen/Leclerc/Bottas/Neuville → same-nationality pool names); (b) teams.json
	name-variation pass + 4 duplicate team names de-duped + **23 real circuit/series/venue team names
	fictionalized** (Pro Mazda→Spec Star, Oval Masters→Apex Oval, Silverstone Wolf→Silverstag Wolf,
	Sarthe→Beaumont, Monza→Lombardy, Spa→Ardennes, Monte Carlo→Riviera, …) — 0 duplicate team names,
	172 teams intact, every championship still meets its minimum car count from JSON alone; (c) driver
	dedup across 1244 drivers — fixed "Lewis Lewis" (first==last) + all duplicate full names via
	NameData surname rotation (0/0 remaining; fewer middle-initial fallbacks).
  - *Championships browser refactor (S37.57, §16)* — retired the hardcoded
	CHAMP_TEAMS/CHAMP_STAFF/CHAMP_CARS/CAR_DRIVERS/CHAMP_KEY_IDX constants (Championships.gd 1519→542
	lines; dead CAR_DRIVERS block ~920 lines) which carried the last IP ("Andretti Collective",
	"IndyCar/NXT/USF/WRC/GT3/GT4-equivalent", "Le Mans equivalent"). Browser now reads teams.json
	directly at the title screen (pre-game) via _load_teams_from_json → _teams_by_champ and renders
	flag · name · type · cars-in-champ · reputation · staff counts · driver pool; all 21 championships
	populate with no empties, counts matching the engine diagnostic. **Backup machinery untouched**
	(AIManager grid-fill / filler teams, personnel generation, bankruptcy logic).
  - *RacingWorld "0pts" display (S37.55)* — GK group-chip leader line no longer jams name+points
	("Lewis Lewis 0pts" read as "…pt"); now "%s — %d pts".
  - *Track names (S37.58)* — race_calendar.json display cities: 29 circuit-towns remapped to the
	nearest major city (Silverstone→Northampton, Monza→Milan, Spa→Liège, Le Mans→Tours, Suzuka→Osaka,
	Daytona→Jacksonville, Talladega→Montgomery, Imola→Bologna, Spielberg→Graz, Nürburg→Cologne, …).
	Rally country-bracket entries (e.g. "Jyväskylä (Finland)") left as-is — intentional rally format.
  - *Dual-calendar clarified* — the race ENGINE runs off the hardcoded CHAMPIONSHIP_CALENDARS constant
	(22-round GK incl. same-week semifinal+final via get_races_for_week, S36.18 — UNCHANGED);
	race_calendar.json is the VISUAL schedule (Calendar scene) and carries forward race-module metadata
	(practice/quali/sprint/double_race/stages/hours) that no code reads yet.
  - *Main Hub (S37.59, §15.3)* — Next-Race line + Next-Race button now consider ONLY the player's own
	championships (get_player_championships()); the line shows the JSON city via new
	GameState.get_calendar_city(cid, round), falling back to the engine entry name for GK's engine-only
	Grand Final (round 22). No save/load change (pure-read helper; player_registered_championships
	already persisted). Branded EVENT names in the constant ("Daytona 500", "24h Le Mans") no longer
	surface on the Main Hub but remain in CHAMPIONSHIP_CALENDARS as `name` — candidate future scrub.

- **S37.37–S37.50 (LIVING WORLD + notification migration + new-game provisioning):**
  - *Notification/News Phase 3 COMPLETE* — every `add_notification` in all engines + scenes migrated
	to `notify_event` / `show_popup` (§15.1 for the classification rules and full file list). Signings
	& departures → news; recurring chores/distress → standing; blocking errors → popup; one-offs →
	event with destination routing.
  - *AIChampionshipSim BUILT* (§14) — new RefCounted engine runs every non-player, non-GK championship
	each race week via a lightweight `car_strength` scalar → finishing order → existing points table.
	Populates driver + team standings for all 21 championships. `car_strength()` is the isolated
	Phase-5 swap-point. Root cause it solves: the S37.43 Bug-3 gate (which stopped the per-championship
	DNS spam) had also stopped non-player championships getting points, leaving Racing World empty.
  - *Racing World display* (§14) — AI cards show driver + team leader; GK card shows driver + team
	CHAMPION even for a player who raced a different discipline (shadow standings + CP3 team table).
  - *New-game provisioning* (§7.3) — Ops Sim key typo fixed (`"Ops Sim"` → `"Ops Sim & Telemetry"`),
	un-stranding the SC/GP starting Strategist; GP now starts with R&D Design Studio + CNC Parts Plant
	+ a Designer.
  - *Strategist = DNS* (§9-G) — a missing Race Strategist now DNS's the car (parity with the S37.45
	TP-DNS), enforced in `can_car_race` + a readiness TDL, for all disciplines except GK & Rally.
  - *Bug run* — release-staff now unassigns mechanic/pit-crew from the car (was driver-only); false
	"no TP for GK" TDL for non-GK players fixed; "DNS for every championship" + season-rollover "new
	car needed" spam gated to player championships; stale "24 championships" comments corrected to 21.

- **S37.31–S37.36 (resource-bar rollout + standard header):** the shared ResourceBar component
  (script-instantiated, compact) is now on Campus + all 20 building scenes + all non-building scenes
  (Drivers, StaffHub, Shortlist, Financialdept, ChampionshipSelect, Calendar [swapped from its own
  bar], BeginOfSeason, EndOfSeason). Headers standardized to the Main Hub concept (§15.3):
  [Name·Level][Resource Bar][Back][Main Hub], with scene-specific controls (Driver Slots, income,
  RP storage, blueprint status, Racing World, Shortlist, Add-event) moved to sub-rows. Each bar
  refreshes via the scene's build/refresh path. Campus now restores the last-viewed zone tab when
  returning from a building (pending_campus_zone, transient — GameState S37.34). Overflow root cause
  recorded: oversized fonts + overloaded headers, not the stretch aspect. MainHub still uses its own
  bar (optional future swap to the shared component).

- **S37.31–S37.32 (ResourceBar component · scene standard · part pricing):** reusable ResourceBar
  component (script-instantiated, no class_name/.tscn) added to building scenes with live refresh;
  Campus + Group-1 buildings (Logistics, HQ, Garage, RnDStudio) done. Standard scene header layout
  defined (§15.3). Part purchase pricing moved to data (`part_costs.json` from Excel CNC, ×1.08
  profit ×1.0 quality, §5.3) via get_part_unit_price/get_part_prices — fixes the GK-parts-free bug
  (buying now deducts credits). GameState → S37.32.

- **S37.28–S37.29 (#52 state leak + full handler audit):** `setup_new_game` now clears leaked
  session state (sponsors/offers/approaches/notifications/SP/fuel/pending_*/fresh GK); `load_game`
  clears transient routing + restores notifications. Then a full audit of all 129 GameState vars vs
  the three handlers closed the rest: WRA pipeline (active_wra_submissions, wra_approved/rejected_
  blueprints), bankruptcy counters (weeks_in_negative + bankruptcy_screen_shown — was reloadable to
  escape bankruptcy), dismissed_todo_items, ceo_accumulated_salary, and player identity (player_name/
  nationality/ceo_age/ceo_sex/game_difficulty — were resetting to defaults on load). New §15.2 State
  Handler Checklist codifies the rule. GameState → S37.29.

- **S37.27 (Main Hub redesign — §15.1/§18 prerequisite, buglist #17):** mockup-driven rebuild.
  Nameplate (team + player name) · resource bar · Menu in row 1 (notification BELL removed);
  Season|Week|Next-Race strip; nav row with the new Calendar button; three always-visible centre
  panels (To-Do · Notifications · News/Log) replacing the side panel + 4 tabs (deleted — standings
  now in Racing World); a 5-week strip (player-only events, +N more overflow, from CalendarManager)
  above the three advance buttons. Notification column reuses the existing card UI (priority sort,
  dismiss, snooze, go-to); the slide-in panel + bell are gone. MainHub.tscn simplified to root +
  Layout; 10px edge inset. All advance/season-transition/menu/save-load/modal/bankruptcy logic
  carried over verbatim. NEXT: notification-loop migration (the ~218 legacy add_notification calls).

- **S37.26 (Season Calendar — §14.1):** new read-only full-season agenda scene
  (`Calendar.tscn`/`Calendar.gd`) in 4-week blocks showing all 21 championships' races (chip =
  `Championship · Round X/N` + city), registration deadlines, building/R&D/CNC completions, and
  custom player reminders (＋/− with tooltips, centered modal add popup). New data file
  `res://data/race_calendar.json` generated from the Excel Race Calendar sheet (295 rounds, keyed
  by champ id) — the intended schedule source of truth. New `CalendarManager` RefCounted engine
  (preload-loaded, no `class_name`) aggregates all dated events; `custom_calendar_events` added to
  `GameState` save/load/new-game-reset. GameState bumped S37.26 (loader + accessor + store). GK
  kept at 21 rounds per the Excel (Round 21 = Wk 46 two-race weekend). Verified in-engine; popup
  re-centered as a CanvasLayer modal; resource bar null-guarded for editor-direct runs.

- **S37.9–S37.13 (salary units · interest rebalance · sponsor commitment redesign · results UI — bugs #8/#2/#13/#11):**
  - **Annual salary negotiation (S37.9, #8):** ContractNegotiation now negotiates salary as an ANNUAL
	figure with a live "≈ CR x/wk" read-out beside the spinbox (stored back as weekly). Signal handlers
	use a NAMED `_on_salary_changed(value, lbl).bind(lbl)` (not an inline multiline lambda, which broke
	parsing). Renegotiation no longer creates a TDL until the player submits an offer.
  - **Interest rebalance (S37.10, #2):** `ContractEngine._subject_interest_score` rewritten. Old base
	(talent×0.5+50) cleared the 60 threshold before reputation mattered, so a rep-0 garage attracted
	~everyone. New model gates reachable TALENT by team REPUTATION:
	`interest = 60 + (player_rep − talent)×0.7 + free_agent_bonus(18) + rep_gap_bonus + tp_mod`.
	Low-talent (≤35) free agents are always reachable so a new team can field a car. Simulated against
	the real driver pool: rep-0 → ~13 reachable, rep-50 → ~371, rep-75+ → full grid.
  - **Sponsor commitment redesign (S37.10, #13):** type-3 (commitment) sponsors now pick a championship
	from a REPUTATION BAND near the team's rep (REP_BAND_DOWN 18 / REP_BAND_UP 22 on the champ `rep`
	scale 15=GK…100=GP1) — no GK→GP1 or GP1→Rally4 offers. Payment is ANNUAL (~1 season's entry+car
	±variation, rounded to 500) paid at the START of each registered season via
	`_process_sponsor_annual_payments()` (called from SeasonManager Stage A2, after the registration
	ledger is promoted). The offer expires before the championship's registration deadline. Penalty for
	skipping the committed championship = repay only that season's amount, and the deal cancels.
	`seasons_total`/`seasons_paid` track progress; a fully-paid deal ends cleanly. Fixed the "all offers
	exactly 20K" flat-floor bug. **Save/load now persist `active_sponsors` + `sponsor_offers`** (were
	never serialized, so a signed multi-season commitment vanished on reload; back-compatible defaults).
  - **Race results "Skip All" + column layout (S37.10–S37.13, #11):** added a "Skip All ⏭" header button
	(shown when >1 race is queued the same week) that applies each remaining race's repairs + sponsor
	bonuses and returns to the Main Hub (`pending_race_result_count()` drives visibility). Results +
	standings tables re-laid-out: the Driver column EXPANDS to fill the container (≈2/5 of width), then
	Laps/Time/Gap/Pts spread across the rest with equal stretch ratios and Prize fixed at the far right;
	Laps/Time/Gap centered, Pts/Prize right-aligned. Header and rows share IDENTICAL sizing mode +
	alignment per column (+`clip_contents`) so headers always sit above their data. Driver-standings
	name/team no longer jam together. **Confirmed in play.**
  - **DEFERRED / FLAGGED (not fixed — pick up next):** (1) "starting a new game continues the previous
	game" — `setup_new_game` does not reset many persistent collections (active_sponsors, sponsor_offers,
	active_approaches, player_registered_championships, next_season_registrations, active_championships,
	player_team_cars, notifications, weeks_in_negative, pending_* screens, _pending_race_results) and
	`gk_discipline` is only recreated `if null`, so a second new game reuses stale state. (2) Load-game
	starts at the pre-load week — `load_game` DOES restore `current_week` correctly and `_autosave` saves
	after the week increment, so the likely cause is transient session state (pending race/season screens)
	not being cleared on load, or the MainHub week label not refreshing. Both share the same root cause
	(neither `setup_new_game` nor `load_game` fully clears transient state) and were investigated but not
	yet fixed. Staff-hire slot validation (#2-adjacent) was deferred — the existing "no slot" path works.

- **S37.0–S37.8 (Cluster A close-out + repair UX + notification framework — §7.2/§6.11/§15.1):**
  - **CP4 — the `active_championship` getter (S37.0):** the singular getter used to return GK
	(`active_championships[0]`) for everyone. It now resolves the player's REAL championship:
	player_registered_championships → the championship of an owned car → legacy field → a safe dummy.
	`RaceSimulator` threads the raced championship through per-race fuel / SP / condition / adaptation
	reads (no more GK-rate math on a Rally car). Standings registration follows Rule #6 — a driver is
	registered to a championship at CAR ASSIGNMENT, not at sign time (premature GK writes removed).
  - **GK bleed gating (S37.1–S37.2):** `GKDiscipline.populate_season()` seeds GK group-0 with REAL GK
	drivers only; a serialized `player_in_gk` flag means a non-GK career no longer simulates/【sees】
	stray GK races, results, round-advance or elimination notices. RacingWorld reads the GK champion/
	leader from the shadow standings so GK results are visible in the world view.
  - **Repair UX (S37.3–S37.5, §6.11):** manual `repair_car()` reads the SP-per-10%-damage rate from
	THIS car's championship. Added `repair_car_max_sp()` — a PROPORTIONAL repair spending all held SP
	(not floored to 10% chunks) so a player short of one full chunk (GK = 110 SP/10%) can still
	repair. Garage car-card "Repair" button uses it (full when affordable, else proportional);
	disabled only at 0 SP.
  - **Notification framework (S37.6–S37.8, §15.1):** added `notify_event()` (modes once/standing/
	event/news) + `_fired_once` + `_push_news`. CFO migrated: removed the per-race "No CFO" emitter
	(the real spam source) and the recurring TDL task; CFO is now a read-only TDL row + a one-time
	`notify_event("no_cfo", once)` with a Staff button. **Root-cause fix:** the CFO-hint and
	registration-deadline blocks sat AFTER the race-result early-return in `advance_week()`, so on any
	week the player raced they were skipped — that is why no deadline notification ever appeared. Both
	moved BEFORE the return; the deadline warning now fires "this week or next" for any championship
	(no budget filter — the player can loan), with a 🔔 weekly-log line for verification.
  - **Misc fixes:** sponsor slots increase at ODD HQ levels (1+int((level-1)/2)) and the HQ EFFECTS
	panel now calls that function (was a hardcoded 1+lv/2 showing 2 at L2); the Financial weekly-income
	panel itemizes income PER BUILDING; the post-race "SP insufficient" notice carries the
	res_spare_parts subject so it collapses to one. BUGLIST reconciled — 10 fixed, see
	`Buglist_51_Reconciled.md`.

- **S35.16–S35.21 (R&D Studio polish + P4 gating + localization — §8.5/§16):**
  - **Scroll fixes (S35.16–S35.17):** the centre catalog and right Blueprint Status columns weren't
	scrolling (Status had no ScrollContainer at all; the catalog's bar was hidden under full-width
	content). Fixed via a shared `_make_scroll_column(stretch, min_w)` helper + a right-side
	`MarginContainer` gutter giving the scrollbar a clear lane; the gutter convention was also
	applied to CNC Plant's matching helper.
  - **Pillar-1-only tabs (S35.17):** the championship tab strip now renders on Pillar 1 only — P2/P3
	iterate the player's cars and P4 is champ-agnostic, so the tabs did nothing there.
  - **P4 building + Studio gate (S35.18–S35.19):** P4 lock messages now state the real reason
	(build/upgrade the target building); AND `Required_RnD_Studio_Level` is now ENFORCED in
	`RnDEngine.rnd_task_unlocked` (was dead data). Gate order: prerequisite → building → Studio.
  - **Consolidated requirement line (S35.21):** one "Required: 🏢 Building Lv X & 🔬 Studio Lv Y"
	line (green/amber) replaced the old two-chip row + duplicate lock sentence.
  - **Localization (S35.20–S35.21):** the whole R&D Studio + all 100 Special Project names/descs
	localized (sp_{id}_name / sp_{id}_desc + ~49 UI keys; dead keys removed). Licensing: user-facing
	"Formula" → "GP" in the Studio + Locale (NewGame/HQ still pending — BUGLIST #21).

- **S35.10 (Personnel hub UX overhaul + Shortlist — §15):**
  - **Hub readability/layout:** available rows at 24px with 100s emphasised; columns switched from
	fixed pixel widths to PROPORTIONAL stretch ratios (full-width aligned grid, no clipping, header
	matches row card border/margins); Team + Contract split into two columns.
  - **Sort clarity:** active sort button highlighted + ▼/▲ direction arrow; a plain-language
	"Showing: …" summary of the active filter + sort. Staff hub gained a "Free Agents Only" toggle
	(Drivers-hub parity).
  - **Shortlist feature:** persisted `is_shortlisted` on Driver + Staff (saved/loaded, old-save
	default false); ★ icon toggle on each hub row and in the View Card popup (synced); a unified
	role-tabbed Shortlist screen (`Shortlist.tscn`/`.gd`) — **All** (mixed, with Role column +
	universal sorts) + Driver + the 6 staff roles, count badges, ★-to-remove. Reachable from Staff
	hub, Drivers hub, Main Hub top bar, HQ nav. GameState API: `toggle_shortlist`, `is_shortlisted`,
	`get_shortlisted_by_role`, `get_shortlist_counts`.
- **S35.5–S35.9 (SP pricing, hub perf, negotiation semantics, interest rework):**
  - **Living SP price (§3, S35.5):** `get_sp_cost_per_unit()` = BASE 1.0 × economy mult (tight
	0.6–1.5 manufactured-goods band) × `sp_market_pressure` (gentle mean-reverting wobble, far
	calmer than fuel). Buy-only. Saved/loaded.
  - **Player-staff cache (S35.6) + hub-filter & lookup hoisting (S35.7):** removed the per-render
	full scans of ~5000 staff (HQ/WRA lag, "Interested" button lag). Walk-Away leaves a persistent
	entry cleared next week; Close is a no-op (S35.7).
  - **HQ preload (S35.8):** heavy scenes preloaded at startup so first HQ open doesn't hitch.
  - **Interest model rework (§12-A, S35.9):** deterministic binary person-interest shared by the
	filter + approach; random team-release gate + 26-week refusal cooldown; `_is_free_at_join`
	(last-year/next-season = no gate/bond); team-won't-release popup. The "try again in the future"
	popup wording + the noted-for-future AI-poaching warning belong to this line.
- **S35.1–S35.4 (notification cleanup + living fuel + CFO auto-buy):**
  - **Recurring-notification collapse (§15):** `add_notification` gains a `subject` key; a new
	notification supersedes any earlier same-subject one, so standing weekly/race reminders keep
	only the current instance (text-independent). Tagged: resource warnings, pre-race DNS reasons,
	economy alerts. The S31.1 identical-text dedup only caught messages whose text didn't change.
  - **GK one-shot elimination (§15):** `player_elimination_announced` flag (reset each season) so
	the "season over for GK" notice fires once, not at every later round after a Round-1 exit.
  - **CFO-gated economy notifications (§9-E):** economy state shifts + fuel-price shocks fire only
	if a CFO is hired (the economy still moves regardless).
  - **Living fuel price (§3):** `get_fuel_cost_per_kg()` = BASE 2.0 × economy `Fuel_Price_Multiplier`
	(0.5–3.0, neutral 1.0). `buy_fuel` now charges it (was a dead hardcoded CR 2/kg); the Logistics
	card header and the input cost preview both show the live rate (the preview's `× 2` hardcode was
	the S35.4 fix).
  - **CFO race-logistics auto-buy (§3/§9-E):** `cfo_auto_buy_for_race(champ)` tops fuel + SP to the
	next race's exact need at the living price — only if a CFO is hired + affordable, and ONLY while
	`simulating_to_season_end` (Skip-to-End). Never negative; never during hands-on weekly play.
- **S35.0 (Season Transition Pipeline — §7.1):** reordered `start_new_season()` into the explicit
  A→E sequence. Split `_process_off_season` into `_process_off_season_aging` (early) +
  `_process_lifecycle_cull` (late, Stage E). **Core fix:** Stage B (activate pre-signed signings)
  now runs BEFORE Stage E (2-season cull) — previously B ran dead-last, so a driver pre-signed last
  season (still a free agent at rollover) could be erased before activation joined them (signing
  silently evaporated). Added `ContractEngine.effective_join_season(ap)` (= `signed_season + 1`) so
  timing is an absolute target, not the fragile "next_season" string. `_erase_free_agent` now
  archives to `retired_personnel` (reason `left_sport`) before erasing — not to `hall_of_fame`
  (race-win records). Stages B/D were already fixed (S33.1/33.2); this is the ordering + archive.
  Verified: headless ordering proof + in-engine season-rollover test.
- **S30–S32 (Phase 2 + TP rebuild):**
  - **Phase 2 car acquisition & delivery** (§6.0): buy vs design+build; per-car `delivery_week`;
	DNS-until-ready; cars scrapped each season; Garage in-build banner + locked part slots.
  - **Build Whole Car** (§6.0/§8): CNC one-pass build of all 6 parts once blueprints are WRA-approved.
  - **S31 housekeeping:** Bug 9 (GK discipline bleed — GK round notifications gated on the player
	being registered in GK; `_regenerate_ai_team_cars` no longer hardcodes C-001); Bug 8 (next-season
	blueprint can't be manufactured in the current season — `start_cnc_job` season gate); Bug 7 (CNC
	shows blueprint target season + locks future cards); Bug 5 (notification cross-week dedup);
	Bug 4 (TP proposals roster-snapshot refresh on accept).
  - **TP Assignment System rebuild** (§9-I, spec v2): shared prestige-ordered optimiser for
	driver/mechanic/pit-crew/strategist/TP; commitment rule; GK multi-tier exception removed;
	consolidated single-source proposal; skip-already-assigned (stale-panel fix); read-only
	`peek_tp_proposals` for display; `Staff.get_overall_skill()` for TP ranking; popup renders all 4
	player roles. Old `get_tp_proposals_all` path retired to dead code.
- **S29 (UI/UX overhaul + data integrity):** Inter font (OFL) + ×2 font scaling + window
  stretch; ScrollContainer+pinned-footer layout pattern across NewGame / BeginOfSeason / etc.;
  NewGame champ-select reworked (Select button on card top, budget summary above the grid as a
  single horizontal row, load-game slot picker matching Main Hub, `_big_button` widened);
  ChampionshipSelect overflow fixes (split header, 4-col details grid); HQ duplicate-loan
  button removed + WRA registration button moved to panel top; Race Results split into 3 paged
  screens; R&D Pillar 1 next-season-only, Pillar 4 catalog min-height, **Pillar 5 stub added**;
  GK renamed "GK Regional"→"GK Championship" + race count 6/29→21; SC Dev (C-014) cap →4;
  localization of all new strings + recovery of 16 merge-dropped Locale keys.
- **S28.x:** pit crew assignment in Garage; AI auto-renew contracts; end-of-season raced-only
  filter (fixed empty-data crash); the original 8-bug list closed.

---

## 21. KNOWN DEFECTS — see `BUGLIST.md` / `Buglist_51_Reconciled.md`

The live defect/work queue lives in two companion files (kept separate so this design document stays
the durable source of truth): **`BUGLIST.md`** (cluster-based: A-CP4, A-STD, …) and
**`Buglist_51_Reconciled.md`** (the bridge mapping the original numbered 1–51 playtest list onto
shipped work). As of v6.0 the reconciled list records **10 fixed** (#5, 14, 19, 20, 23, 28, 31, 33,
47, 49 — of which #5, #20, #47 are confirmed in play), ~22 fixed-pending-verification, and 11 still
open. The remaining high-leverage clusters:

- **Championship-registration cluster (#9, #19, #44, #48)** — addressed by CP4 (§7.2); the display
  contradictions (#19) and stray-GK symptoms are fixed in code and **✅ keyboard-verified (S37.65)**.
- **Standings persistence (#31) + GK team champion (#28)** — ✅ fixed (S36.14 / S36.15+).
- **Roster desync (#35) + contract loop (#6, #10)** — Season Transition Pipeline area (§7.1),
  **✅ keyboard-verified (S37.65)**.
- **Interest/reputation (#2, #4) + CFO data (#1)** — economy correctness (§9, §12); interest model
  rebalanced + made stricter (S37.65, §12); #1 (CFO data) still open.
- **Garage slots & assignment (#37, #38, #40, #41, #46)** — multi-driver champ slots, TP reassign,
  age-requirement popup; repair (#47) ✅; **multi-driver-per-car (#38) ✅ — crew model, S37.60–S37.61
  (§1), keyboard-verified.**
- **Car delivery pipeline (Phase 2, §6.0)** — ✅ keyboard-verified working (S37.65).
- **Lowest-risk OPEN batch** (no re-fix risk, untouched by changelog): #8, #11, #13, #18, #41, #43.
- **Notification-framework migration** (§15.1): TP/fuel/SP/building-completion/sponsor-offer/news
  events still on the legacy path. **Design revamps** (#17 Main Hub, #32 Racing World, #34
  Beginning-of-Season, #30 building text) remain scheduled as design work, not point fixes.

When a fix ships, update the relevant section above AND mark the item in both tracker files.

## 22. Manual inserted Updates and ideas.
- Create the Racing cars and parts market
- Create the race simulations of all the championship
- if not written abbove, create the AI teams behavior
- the GK non player groups assign drivers instead of cars and then the drivers, we need to guarantee that these entries get a car stats for the race calculation results
- Research that all the attributes of staff, drivers and cars are used in the code 
- To enter the highest tier of every descepline the must have a merchanise store at least level 1
- Enter a line in the TDL entry about the CFO not hired: the extra line will say "Financial Department is not optimized"

> *Reconciliation note (v6.8): these are the owner's raw design ideas. Items now reflected elsewhere
> in the GDD: the **designer-model reconsideration** is cross-referenced in §7.3 + §19; **"make Racing
> World deeper"** is partially addressed by the §14 living-world build (driver/team standings now
> populate) but the deeper intent (browse/scout, history) remains open. Still un-actioned and carried
> as design intent: team-colour window borders, parts-JSON↔Logistics/CnC/sponsor cost wiring, the
> per-addition event/TDL/save-load checklist (a process rule — see §15.2), the Academy cadet
> supply/cap rule, and the bankruptcy-screen review. None are lost; they live here as the backlog.*

- They UI bordering of windows to follow the Team Colours, if it is to diiffult to implemetn, we will use a combination of red/black or blue/black 
- The parts JSON must include the base Unit cost and this must be connected with the logistcs center and sponsors offers. The CnC must also be connected to the JSON
- For every addition, we must check if it is an event that must be classified and news or notification and also if it leads to tdl entry or needs a building button
- For every addition, we must check if it needs to be added in the save/load file
- We must recosnider the designers approach, I am start thinking that haveing so many designers it is probably overwhelming, maybe an approach of 1 designer per principle plus one needed per special projects and 1 for the commercial cars
- The Academy must provide cadets as long as there are empty spots in the garage for their cars and the racind department for their drivers. The max level of cadets is capped by the Academy building level, but if there is no space in the racing department or the garage fo field drivers, no cadets will appear. this will also be a notification and tdl
- Review the Backruptcy screen and how it works
- Make the Racing world deeper
---

*End of GDD v6.8. Companion files: `Brainstorm_Threads.md` (vision/strategy),
`FEATURE_AI_Championship_Sim.md` (deferred feature spec), `TP_Assignment_System_Spec_v2.md` (TP
assignment design), `Season_Transition_Pipeline_Spec_v1.md` (§7.1 rollout detail),
`Master_Calculation___Formula_Document` (formula reference), `BUGLIST.md` +
`Buglist_51_Reconciled.md` (defect/work queue). Keep this document reconciled with the code after
every session.*
