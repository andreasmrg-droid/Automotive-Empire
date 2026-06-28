# Automotive Empire — Game Design Document

**Version:** v6.3 (consolidated master) · **Engine:** Godot 4.7 / GDScript
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
**Last updated:** 2026-06-24 · **Repo:** https://github.com/andreasmrg-droid/Automotive-Empire.git

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

## 4. COMMERCIAL CAR MARKET — Weekly Update

The road-car business: a second income stream that makes the game playable without the race
module. Racing success feeds commercial visibility.

```
Weekly_Racing_Buzz = [(Points_Earned_This_Week ÷ Max_Possible_Points_This_Week) − 0.5]
				   × Championship_Visibility_Multiplier × Discipline_Synergy_Bonus

Weekly_Market_Share_Delta = Current_Market_Share
   × (0.008 × Reputation_Factor + 0.007 × Marketability_Factor + 0.028 × Weekly_Racing_Buzz)

If Weekly_Racing_Buzz ≤ 0 → extra natural decay of −0.0035 × Current_Market_Share

New_Market_Share = clamp(Current_Market_Share + Weekly_Delta, 0.01, Max_Share_Cap)

Weekly_Commercial_Car_Sales = Global_Annual_Volume × (Current_Market_Share / 52)
							× (1 + Weekly_Racing_Buzz × 0.12)
```

"Others %" in a segment = 100% − sum of all team market shares in that segment. Commercial
sales and market-share growth are improved by the CFO's `sales_skill` (§9-E).

**Roadmap link:** the Commercial Factory + its R&D (Pillar 5, §8) is Phase 3 — the second
weekly income stream. The Pillar-5 "Commercial Cars" R&D button already exists as a stub.

---

## 5. CNC PART PRODUCTION & RELIABILITY

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

### 6.0 Car Acquisition & Delivery (Phase 2)

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
3. **REV. ENGINEERING** — reverse-engineer Spec parts you own (team must hold the part).
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

### 8.4 Research Points (RP) — earned only by racing  *(design note — under review)*

RP is currently earned in exactly one place: after a race (`RaceSimulator.earn_race_rp`). There is
**no** baseline weekly RP income from the Studio or idle designers. Consequence: a team cannot
research anything until it has raced at least once (RP starts at 0). The catalog now always shows
the Assign row with disabled buttons + a reason ("need N RP (have 0)") so this gate is legible
rather than appearing broken. **Open question:** whether to add a small baseline weekly RP from
the R&D facility / designers so development can happen between races. Not yet decided.

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

**Scrolling.** The catalog (centre) and Blueprint Status (right) columns each scroll via a shared
`_make_scroll_column(stretch, min_w)` helper mirroring the CNC Plant's, with a right-side
`MarginContainer` gutter so the vertical scrollbar always has a clear lane (it was previously drawn
under full-width content and appeared missing). The same gutter convention was applied to CNC Plant.

---

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
and Rally. Included in the player's TP assignment proposal (§9-I).

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
satisfied slots). **Partial accept re-optimises** the remaining cars over the reduced pool. Ignored
proposals leave cars unassigned → DNS (player's risk). The Racing-Dept panel uses
`GameState.peek_tp_proposals()` (read-only, no notification/TDL side effects). One TDL item per
proposal, dismissed by its actual text on accept.

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

Every **4 seasons** the World Racing Association announces new technical regulations. All
existing part knowledge is reset; teams must design a completely new car. New base reliability
starts at 60 and climbs +10 each season until the next cycle (§5).

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

### 13.2 News System — sound-wave propagation
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

News events also fire on race results (WIN/DNF/Championship/RACE WIN), building
completions, economic changes, signings/retirements, rule changes, bankruptcy risk, high car
prices — each adjusting Reputation and Marketability.

---

## 14. AI CHAMPIONSHIP SIM — the "living world" (DEFERRED; full spec in FEATURE_AI_Championship_Sim.md)

Today only the player's raced championship gets standings. Future: every championship runs
each season via a LIGHTWEIGHT result model — one strength scalar per car from existing stats
(driver × car index × staff multipliers × race-day noise) → finishing order → existing points
table. NOT the full lap-by-lap sim (too expensive for 20+ championships weekly). New
`AIChampionshipSim` RefCounted engine, Python-portable. Build AFTER the economy (AI car
strength should read economic outputs / budgets). Pairs with the Transfer Market (P51) to make
the AI world fully alive.

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
3. **Meaningful world events also create news.** Big signings/releases, a championship win, entry to
   a top-tier championship → `mode = "news"` also posts to the news feed (hook `_push_news`; the full
   news system remains a separate design pass, §13.2).

**Modes:**
| Mode | Behaviour | Use for |
|---|---|---|
| `once` | Fires exactly once ever (tracked by `event_id` in `_fired_once`). | Optional standing facts mentioned a single time (e.g. "no CFO"). |
| `standing` | Subject-superseded: one live instance, refreshed when the condition re-fires. | Sparingly — prefer the TDL for chores (e.g. low fuel before a race). |
| `event` | One-off event notice (no dedup beyond identical-text). | "Garage upgraded to L2" + a button to the Garage. |
| `news` | Like `event`, plus posts to the news feed. | Titles, top-tier entry, marquee signings. |

**THE CARDINAL RULE — the TO-DO LIST IS READ-ONLY AND NEVER EMITS NOTIFICATIONS.** The TDL is
rebuilt from current state each week (`get_pending_tasks`) and exists so the player can *see*
outstanding work; it must not also fire notifications, or standing chores spam the bell every week.
Operational "you should do X" reminders belong in the TDL; the notification fires once for the
*event*, not once per week for the *state*.

**Rationale / history.** The old code inverted this: the weekly TDL builder re-appended "No CFO"
every week (a recurring task) AND a separate per-race emitter in `RaceSimulator` fired the same
condition every race — so the player saw the same notice at W8/W10/W12. Under the framework, CFO is a
single read-only TDL row plus one `notify_event("no_cfo", once)` with a Staff-screen button. (CFO is
explicitly OPTIONAL — good-to-have, not required to field a team.)

**Migration status.** Migrated: CFO, registration-deadline warning. Pending (still on the legacy
`add_notification`): TP-missing (#39/#42/#45), fuel/SP (#15/#23), building completion (#26), sponsor
offer (#12), and the news-mode events (signings/titles/top-tier entry). Each migration adds the
proper destination button or news flag.

**SEQUENCING — MAIN HUB REDESIGN IS A HARD PREREQUISITE.** Before the notification loop is
constructed/finished (the framework above and the remaining migrations), the **Main Hub must be
redesigned first — this is mandatory, not optional.** The bell, unread badge, slide-in panel,
critical banner, and the read-only To-Do List all live on the Main Hub, so the notification loop's
surfaces depend on the redesigned hub. Building the loop against the current hub would mean wiring
notification UI into a layout that is about to change. Order is therefore fixed: (1) Main Hub
redesign → (2) notification loop construction + legacy-`add_notification` migrations. Do not begin
the notification loop work until the hub redesign lands.

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

---

## 18. ROADMAP (economy first, race last)

Each economic system ships WITH its AI behaviour (§13) attached; keep logic in pure
RefCounted engine classes for headless multi-season testing.

- **Phase 2:** §5/§6-style car system — delivery delay, P2/P3 gating, DNS-until-ready,
  deadlines (it's ECONOMY).
- **Phase 3:** Commercial factory + R&D Pillar 5 (second weekly income → playable without the
  race). The Pillar-5 button is already stubbed.
- **Phase 4:** Stock market.
- **Phase 5:** Multi-season BALANCE pass — derive AI budgets & team character as OUTPUTS; tune
  building maxes + R&D gates (§10); headless Python stress-tests + real playtests.
- **Then:** race sim swap-in (module design §6.8).
- **Parallel/after:** AI Championship Sim (§14) + News System (§13) + Transfer Market (P51) =
  the living world.

**UI/UX prerequisites (cross-cutting, not a phase):**
- **Main Hub redesign — MANDATORY BEFORE the notification loop construction.** The notification
  loop's surfaces (bell, badge, slide-in panel, critical banner, read-only TDL) all live on the
  Main Hub, so the hub must be redesigned first; only then build/finish the notification framework
  and migrate the legacy `add_notification` callers (§15.1). Fixed order: Main Hub redesign →
  notification loop.
- **Resource bar everywhere (§15).** The shared top resource bar is required in every in-game
  scene (exceptions: modals + the four full-screen flow states). Wiring it in is part of "done"
  for any new or reworked scene.
- **Season Calendar (§14.1, built S37.26).** Full-season agenda scene shipped; remaining wiring is
  the hub Calendar button + the hub 4–5-week strip. `race_calendar.json` is the new schedule source
  of truth (retire hardcoded `CHAMPIONSHIP_CALENDARS` later).

**Realistic timeline:** playable balanced ECONOMIC sim (no race) ~3–5 months at a few focused
sessions/week; full game with race integrated + balanced ~8–14 months (race sim + balance are
the wildcards). Biggest risk: scope creep — keep saying "backlog."

---

## 19. STILL OPEN / CARRIED FORWARD

- **Bankruptcy-continue crash:** appeared fixed via the end-of-season "raced-only" standings
  filter, but observed surviving only once — re-test deliberately; if it recurs, capture the
  Godot error line (possible second cause).
- **AI Championship Sim / living world:** all 23 non-GK championships must simulate for all teams
  every season (currently only GK shadow-sims). Deferred — full spec in
  `FEATURE_AI_Championship_Sim.md` (§14). Player requirement, OK to defer.
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

> **STRUCK (resolved):** Excel master sync — `Master_Championship_Variables_Map_v2_8.xlsx` already
> reflects SC Dev (C-014) cap = 4 and GK races = 21. Item closed.

---

## 20. IMPLEMENTATION CHANGELOG (recent — newest first)

Historical record of what shipped; design facts above already reflect these.

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
  contradictions (#19) and stray-GK symptoms are fixed in code, pending keyboard verification.
- **Standings persistence (#31) + GK team champion (#28)** — ✅ fixed (S36.14 / S36.15+).
- **Roster desync (#35) + contract loop (#6, #10)** — Season Transition Pipeline area (§7.1), pending
  verification.
- **Interest/reputation (#2, #4) + CFO data (#1)** — economy correctness (§9, §12); #1 still open.
- **Garage slots & assignment (#37, #38, #40, #41, #46)** — multi-driver champ slots, TP reassign,
  age-requirement popup; repair (#47) ✅.
- **Lowest-risk OPEN batch** (no re-fix risk, untouched by changelog): #8, #11, #13, #18, #41, #43.
- **Notification-framework migration** (§15.1): TP/fuel/SP/building-completion/sponsor-offer/news
  events still on the legacy path. **Design revamps** (#17 Main Hub, #32 Racing World, #34
  Beginning-of-Season, #30 building text) remain scheduled as design work, not point fixes.

When a fix ships, update the relevant section above AND mark the item in both tracker files.

## 22. Manual inserted Updates and ideas.
- They UI bordering of windows to follow the Team Colours, if it is to diiffult to implemetn, we will use a combination of red/black or blue/black 
---

*End of GDD v6.0. Companion files: `Brainstorm_Threads.md` (vision/strategy),
`FEATURE_AI_Championship_Sim.md` (deferred feature spec), `TP_Assignment_System_Spec_v2.md` (TP
assignment design), `Season_Transition_Pipeline_Spec_v1.md` (§7.1 rollout detail),
`Master_Calculation___Formula_Document` (formula reference), `BUGLIST.md` +
`Buglist_51_Reconciled.md` (defect/work queue). Keep this document reconciled with the code after
every session.*
