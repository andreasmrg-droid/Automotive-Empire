# Automotive Empire — Game Design Document

**Version:** v5.0 (consolidated master) · **Engine:** Godot 4.6.2 / GDScript
**Last updated:** 2026-06-21 · **Repo:** https://github.com/andreasmrg-droid/Automotive-Empire.git

> This is the single source of truth for the design of Automotive Empire. All prior
> session-handoff notes and manual "latest update" appendices have been absorbed into
> the relevant sections below; the document now reads as the *current* design of the game.
> Companion files (separate by intent, not superseded):
> - `Brainstorm_Threads.md` — design VISION & strategy rationale (the "why / what we want").
> - `FEATURE_AI_Championship_Sim.md` — full spec for the deferred living-world feature.
> - `Master_Calculation___Formula_Document` — the authoritative formula/variable reference.
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

**GK Championship** is a single progressive championship of **21 rounds** across 4 stages
(Round 1: 32 groups; Round 2: 16 groups of 20; Round 3: 4 groups of 32; Final: 2 groups of
30, winner crowned World Champion). Note: `num_races` is a DISPLAY value; race-length logic
reads the actual calendar (`calendar.size()`).

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

---

## 6. THE RACE WEEKEND

The race module is the LAST thing built (the economy ships first). The design below is the
target; until the full sim is swapped in, results are produced by the engine's existing logic.

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

---

## 8. R&D SYSTEM

The R&D Studio is organised into **5 pillars** (tab bar):

1. **DESIGN** — design blueprints for any part (Reverse Engineering = Level 1, Own
   Development = Level 2; upgrade parts up to Level 6, each requiring the previous). The
   catalog shows **next-season blueprints only** — the current season's car is already
   locked in, so current-season design isn't actionable.
2. **UPGRADE** — upgrade Open parts on owned cars; in-season improvements carry to next season.
3. **REV. ENGINEERING** — reverse-engineer Spec parts you own (team must hold the part).
4. **SPECIAL PROJECTS** — **100** building-linked special projects (the "P4" set). Each is
   gated by a specific building's level (see §10 coupling) and unlocks unique team
   capabilities/bonuses. Each needs a Designer slot + time/credits.
5. **COMMERCIAL CARS** — *stub (future).* Button + popup exist; reserved for the road-car
   R&D system (Phase 3). Constants and helpers are wired so the real catalog drops in later.

General R&D develops blueprints and upgrades; specialized R&D (Pillar 4) is tied to buildings
and their max levels.

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

### 9-F. Designer (R&D Studio only; TP does NOT multiply them)
Per-part design quality: `engine, aero, brakes, suspension, chassis, gearbox`; plus
`reliability` (initial blueprint reliability) and `parts_knowledge` (grows from race
telemetry per car type → faster iteration, higher initial values). All Designer stats have
equal ±10–15 random variance — specialised designers emerge organically.

### 9-G. Race Strategist (×TP; not used in GK or Rally)
`race_strategy` (primary), `race_pace_reading` (driving-mode recommendations),
`practice_scheduling`, `qualifying_timing`, `track_knowledge`.

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

---

## 10. BUILDINGS & THE BUILDING↔R&D COUPLING

Each building level provides some of: staff hiring slots, passive income / cost reduction,
stat bonuses, and unlocks for R&D projects or commercial upgrades. Exact effects live in the
Buildings sheet.

### Slot-providing buildings (current)
| Building | Slots/level | Max level | Notes |
|---|---|---|---|
| Garage | +1 Race Mechanic | 89 | also +1800 weekly repair profit |
| Racing Department | +1 Driver | 89 | +10% driver morale/focus |
| Pit Crew Arena | +1 Pit Crew | 20 | −0.1s pit/level |
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

### Contract negotiation
Driver/Staff/Sponsor contracts negotiate on: Base Salary, Performance Bonuses, Contract
Length, Buyout/Release Clause, Reputation & Loyalty modifier. The **CFO** (via
`sponsor_negotiation`) handles ALL negotiations independently. When an approach target is
**not interested**, a visible popup informs the player (not just a silent news/notification).

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

### Resource bar visibility (design rule)
The persistent top resource bar is visible in ALL in-game scenes EXCEPT: popups/modal
overlays, New Game, Race Results, End of Season, Beginning of Season. (Implement as: shown by
default, explicitly suppressed only in those contexts.)

### Layout conventions (large-font safety)
- Tall content is wrapped in a ScrollContainer with the action/footer row PINNED below it, so
  buttons never fall off-screen.
- Rows that risk horizontal overflow use grids or split rows rather than single wide HBoxes.
- The global window stretch is `canvas_items` / `aspect=expand` so the 1920×1080 UI scales to
  any window.

---

## 16. LOCALIZATION (Rule 3)

Every user-facing string MUST go through `Locale.t("key")` or `Locale.tf("key", [args])`
(supports `{0}` placeholders and `%` formatting). Missing keys fall back to showing the key
text (no crash) and log a warning — so raw keys appearing on screen means a missing entry.

**Process rule:** when editing any UI file, localize its strings in the SAME pass and output an
updated `Locale.gd` alongside. **Session-start check:** scan that every `Locale.t("…")` key
referenced under `scenes/` exists in `Locale.gd` (a stacked merge once dropped 16 keys and
showed raw key text in-game).

**Outstanding localization DEBT (deferred, by choice):** many PRE-EXISTING hardcoded strings
remain (NewGame title/subtitle/hints, load-picker labels, R&D Pillars 1–4 names/descriptions,
etc.). A full localization sweep is its own future session — do not half-do it inline.

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

**Realistic timeline:** playable balanced ECONOMIC sim (no race) ~3–5 months at a few focused
sessions/week; full game with race integrated + balanced ~8–14 months (race sim + balance are
the wildcards). Biggest risk: scope creep — keep saying "backlog."

---

## 19. STILL OPEN / CARRIED FORWARD

- **Bankruptcy-continue crash:** appeared fixed via the end-of-season "raced-only" standings
  filter, but observed surviving only once — re-test deliberately; if it recurs, capture the
  Godot error line (possible second cause).
- **TP proposal timing:** should fire ~1 week before a race, not every racing week — still open.
- **Excel master sync:** keep the Master Variables Excel matching the code — currently it must
  reflect SC Dev cap = 4 and GK races = 21.
- **Building max / Fitness Clinic rebalance** (§10) — deferred to a focused balance session.

---

## 20. IMPLEMENTATION CHANGELOG (recent — newest first)

Historical record of what shipped; design facts above already reflect these.

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

*End of GDD v5.0. Companion files: `Brainstorm_Threads.md` (vision/strategy),
`FEATURE_AI_Championship_Sim.md` (deferred feature spec), `Master_Calculation___Formula_Document`
(formula reference). Keep this document reconciled with the code after every session.*
