**AUTOMOTIVE EMPIRE**

**GAME DESIGN DOCUMENT**

Version 4.1  ·  2026-06-17  ·  Godot 4.6.3 / GDScript

*Author: Andreas Maragkos  |  GitHub: **andreasmrg**-droid/**AutomotiveEmpire*

***“Build from nothing, Driven by Everything”***

*Single source of truth for all confirmed game design decisions.*

# HOW TO USE THIS DOCUMENT

*Updated at the end of every session. Excel = numbers. Formula Doc = calculations. This GDD = design decisions.*

- Every code file must have: ## Version: S{session}.{modification}
- Session start: Claude reads GDD + File Registry, flags version mismatches before touching anything
- ⚠ OVERRIDE flags mark decisions that differ from Formula or Excel documents
- Claude must ask for file upload before editing any file — never work from stale context
- Claude reads Brainstorming.docx as the concept/philosophy reference. Excel = authoritative numbers.
- When a Brainstorming concept conflicts with Excel, Excel wins unless GDD explicitly overrides.

# FILE REGISTRY

*v4.0 — 2026-06-17*

| **File** | **Last Session** | **Version** | **Key Changes** |
| --- | --- | --- | --- |
| GameState.gd | S26 | S26.0 | Architecture refactor planned; GK calendar 21 races weeks 6-46; DNS notifications fixed to player-only; pace spread ±5% GK / ±3% others; _regenerate_ai_team_cars disabled |
| AIManager.gd | S26 | S26.0 | CHAMP_MAP GK→C-001 fixed; _fill_championship_grids disabled; OPTIMUM_CARS C-001=640 |
| GKDiscipline.gd | S26 | S26.0 | 4 progressive rounds; advance_round(); filler/FA exclusion; harder difficulty formula |
| ContractNegotiation.gd | S19 | S19.3 | open_approach with locks; Close cancels unsent Round 1 |
| Drivers.gd | S22 | S22.8 | Free agent timing popup; no TP gate; walk-away hides row |
| StaffHub.gd | S22 | S22.8 | Walk-away hides row; TP gate only for bond approach |
| HQ.gd | S22 | S22.8 | Take Loan prominent; WRA DNS checklist; chart fix |
| RacingDept.gd | S23 | S23.0 | TP proposals summary card + popup trigger |
| TPProposalsPopup.gd | S23 | S23.0 | Full-screen TP proposals; Accept All / per-item Accept/Skip |
| RacingWorld.gd | S26 | S26.0 | GK discipline map updated to single C-001 |
| Garage.gd | S26 | S26.0 | Tab bar filters to player championships only |
| Logistics.gd | S26 | S26.0 | Filters to player championships only |
| Championship.gd | S19 | S19.9 | drivers/teams champion history; get_competition_factor() |
| Locale.gd | S23 | S23.0 | TP popup keys added |
| drivers_cadets.json | S26 | S26.0 | 510 cadets; rep age-based 0-20; stats scaled by team rep; contract_type=academy |
| drivers_professional.json | S26 | S26.0 | 614 drivers; old GK 4-tier pros removed; rep scaled by championship tier |
| teams.json | S26 | S26.0 | GK merged to single key; 85 teams with GK entry |
| car_assignments.json | S26 | S26.0 | Rebuilt: old C-001/002/003/004 removed; new C-001 GK cars with cadet assignments |
| staff_tp.json | S26 | S26.0 | GK tier names remapped; duplicate GK TPs removed |
| staff_mechanic.json | S26 | S26.0 | GK tier names remapped; assigned_car_id set for GK cars |

# DECISIONS LOG

*Sessions S24–S26 (2026-06-14 to 2026-06-17)*

| **Date** | **Decision** | **Session** | **Status** | **Notes** |
| --- | --- | --- | --- | --- |
| 2026-06-14 | GK Championship: 4 tiers replaced by single progressive tournament with 4 rounds | S24 | ✅ DONE | C-001 only |
| 2026-06-14 | GK calendar: 21 races from Excel, weeks 6-46, gk_round field drives advancement | S25 | ✅ DONE | GameState.gd |
| 2026-06-14 | Player auto-assigned to Round 1 group — no manual choice | S24 | ✅ CONFIRMED |  |
| 2026-06-14 | Player driver eliminated = season over for GK. Same for AI drivers. | S24 | ✅ CONFIRMED |  |
| 2026-06-14 | GK prize money: per-race 1200/600/300; end-season top-10 20000→500 | S25 | ✅ CONFIRMED | Excel v2.6 |
| 2026-06-14 | GK stats from Excel v2.6: min_age=8, max_age=17, rep=15, fuel=20kg, spares=200/race | S26 | ✅ DONE | REGISTRY updated |
| 2026-06-14 | TP works normally in GK — no special GK-only handling | S24 | ✅ CONFIRMED |  |
| 2026-06-15 | Race pace factor: ±5% GK, ±3% other championships (was ±1.5%) | S26 | ✅ DONE | GameState.gd |
| 2026-06-15 | Cadet reputation: age-based 0-20 max. Pro driver rep: tier-scaled 10-100 | S26 | ✅ DONE | JSON files |
| 2026-06-15 | DNS notifications: only fire for player_registered_championships, not all 24 | S26 | ✅ DONE | GameState.gd |
| 2026-06-15 | Garage tab bar: only shows championships where player has a car | S26 | ✅ DONE | Garage.gd |
| 2026-06-15 | AI personality archetypes: 8 types defined — see §3.7 | S26 | ✅ CONFIRMED |  |
| 2026-06-15 | GK ghost driver system: ghosts fill groups; not hireable; Overall stat only | S26 | ✅ CONFIRMED | See §2.6 |
| 2026-06-15 | Architecture: decompose GameState into SeasonManager + core controllers | S26 | ⏳ PLANNED | P57 / §16 |
| 2026-06-15 | Building maintenance: Weekly_Maintenance_Level1 × level (weekly, from Excel v2.6) | S26 | ⏳ PENDING | P19 scope |
| 2026-06-17 | Temperature formula for tyre wear: ambient + track temp — deferred to P28 | S26 | ⏳ PENDING | P28 scope |
| 2026-06-17 | Driver/staff lifecycle: retirement=erase (drivers rare→50, staff 65); free-agent decay drivers-only 2 seasons; D-GEN fillers removed | S28 | ✅ DONE | §4.2, SeasonManager.gd S28.0 |
| 2026-06-17 | Forward-planning registration via NextSeasonLedger — no re-registration at season start | S28 | ✅ CONFIRMED | §23.1 |
| 2026-06-17 | Registration deadline = design deadline; all deadlines −1 week for WRA approval; GP1 longest (engine) | S28 | ✅ CONFIRMED | §23.2–3 |
| 2026-06-17 | R&D + WRA must finish in current season or blueprints lost | S28 | ✅ CONFIRMED | §23.4 |
| 2026-06-17 | DNS until car manufactured/ready (race-by-race) | S28 | ✅ CONFIRMED | §23.5 |
| 2026-06-17 | Bought cars bypass design chain; player-only design burden | S28 | ✅ CONFIRMED | §23.6–7 |
| 2026-06-17 | Car manufacturing delivery delay = longest part; P2+P3 gated until delivery; assignment allowed at purchase; player-only | S28 | ✅ CONFIRMED | §23.8 |

# 1. GAME VISION & DESIGN PHILOSOPHY

*v4.0 — 2026-06-17*

## 1.1 Core Concept

Racing team tycoon. Player manages every aspect from grassroots karting to Formula 1.

Engine: Godot 4.6.2 / GDScript. Platform: PC Windows Desktop first.

Career-based. Seasons = primary time unit. Weeks = weekly economy cycle.

**Motto: **"Build from nothing, Driven by Everything"

## 1.2 Emotional Design Philosophy

*The player lives the story. Every mechanic must make the player feel something.*

- Consequences are personal — notifications reference specific blueprints, staff names, seasons invested
- No hand-holding on irreversible decisions. Warn passively, never block. Paradox/Stellaris model
- Staff are characters. A designer grown PK 20→85 is YOUR designer. Retirement = loss
- Rivals have personalities. The team that always beats you becomes personal
- Milestones celebrated loudly. First win, first profit, first CNC part, first sponsor
- Failure always feels fair. The signals were there. Skill = reading them

## 1.3 Anti-Features

- No confirmation dialogs except: difficulty reduction (once), bankruptcy restart options
- No forced tutorials or onboarding
- No board of directors or chairman
- No scouting minigame or scouting staff role — TP handles intelligence
- No betting/speculation mechanics
- No mid-season difficulty changes

## 1.4 Algorithm Flow (Screen Order)

| **Layer** | **Screens / Modules** |
| --- | --- |
| Main Menu | New Game · Load Game · Save Game · Settings · Quit |
| New Game | Team Name / Logo / Colours / Starting Championship → Player Name / Avatar / Age / Sex |
| Pre-Event Hub | Base Scene → News → Finance → Drivers → Staff → Racing Hub → Calendar |
| Campus | Buildings → R&D |
| Race Weekend | Pre-Race Screen → Practice → Qualifying → Race → Post Event |

*At some point the player will have the option to start in all 7 disciplines or as the CEO of an already existing team.*

# 2. CHAMPIONSHIPS

*v4.0 — 2026-06-17*

## 2.1 Championship Matrix

| **Tier** | **Go-Karting** | **Rally** | **Touring Car (GT)** | **Open Wheel** | **Stock Car** | **Endurance (WEC)** | **Formula** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 (Top) | GK World * | Premier Rally | TC Elite | OWC Pro | SC Cup | EPC Hyper | GP1 |
| 2 | GK Continental * | Rally2 | TC Sport | OWC Dev | SC Challenge | EPC League | GP2 |
| 3 | GK National * | Rally3 | — | OWC Next Gen | SC Truck | EPC Series | GP3 |
| 4 (Entry) | GK Regional * | Rally4 | — | — | SC Dev | — | GP4 |

** GK tiers are conceptual only. In-game there is ONE championship: GK Championship (C-001) with a 4-round progressive elimination tournament. See §2.5.*

- GT3/GT4 (real names) → TC Elite/TC Sport in game. LMP2/LMP3/WEC Hypercars → EPC League/EPC Series/EPC Hyper.
- OWC = IndyCar-style open wheel. EPC = Le Mans Prototypes/WEC. All names changed for copyright.
- GK = Go-Karting. Rally = WRC ladder. TC = Touring/GT cars. SC = Stock Cars. GP = Formula cars.

## 2.2 Championship Prestige Ranking

| **Rank** | **Championship** | **Game Name** | **Reputation** |
| --- | --- | --- | --- |
| 1 | Formula 1 | GP1 | 100 |
| 2 | WEC Hypercars | EPC Hyper League | 94 |
| 3 | IndyCar NTT | OWC Pro Series | 91 |
| 4 | NASCAR Cup Series | SC Cup | 89 |
| 5 | GT3 | TC Elite Championship | 82 |
| 6 | WRC | Premier Rally Championship | 79 |
| 7 | Formula 2 | GP2 | 74 |
| 8 | LMP2 | EPC League | 71 |
| 9 | Xfinity Series | SC Challenge | 68 |
| 10 | Indy NXT | OWC Development Series | 65 |
| 11-24 | F3/Trucks/GT4/LMP3/WRC2/USF/ARCA/F4/WRC3/GKW/WRC4/GKC/GKN/GKR | GP3 → GK Championship | 63 → 15 |

*11-24 refer to the Excel for exact values.*

## 2.3 Starting Championships (New Game)

Four entry options: GK Championship, RALLY4, SC Dev Series, GP4.

Each shows entry fee + car cost. Cards disabled if unaffordable at chosen difficulty.

## 2.4 Race Weekend Structure by Discipline

### Go-Karting (GK Championship — C-001)

**✅ CONFIRMED: Single GK Championship C-001. 4-round progressive tournament. See §2.5.**

- Practice: 15 min free practice
- Qualifying: 8 min one-shot
- Race: Sprint — Standing Start
- Points: Standard 25-18-15-12-10-8-6-4-2-1
- Player interaction: No two-way radio, no pit instructions. Lap-by-lap monitoring only.
- No pit stops, no driver changes, no stages. Yellow flag + Full yellow: yes. Safety car: no.

### Rally (WRC4 → Premier Rally)

- Practice: Shakedown stage (4.5–6.3km loop, run up to 3 times)
- Qualifying: Super Special Stage sets starting order for Leg 1. Done at 1st stage to save coding.
- Race: Multi-day, 3 Legs, 16-25 point-to-point stages. No wheel-to-wheel — solo against the clock.
- Premier Rally only: Power Stage at end awards bonus championship points
- Repairs: Fixed 30-minute Service Park windows mid-day
- Points: 18-15-13-10-8-6-4-3-2-1 (WRC-style, confirmed per Excel)

**⚠ OVERRIDE: Rally race simulation currently uses positional lap-time formula. True time-trial mode deferred to P28.**

### Touring Cars / GT (TC Sport / TC Elite)

- Practice: 45–60 minutes
- Qualifying: Dual 15-min sessions (TC Sport) or knockout Q1-Q2-Q3 (TC Elite)
- Race: Two 60-minute sprints with mandatory driver change (TC Sport). Multi-class endurance with pit stops (TC Elite).
- TC Elite: 24-hour races give double points
- Points: Standard 25-18-15 + pole position bonus

### Open Wheel / IndyCar (OWC)

- Practice: 30–75 minutes
- Qualifying: Road/Street = knockout + Fast Six. Ovals = 2-lap solo time trial. Indy 500 = multi-day speed shootout
- Race: Standing start (road/street), rolling start (ovals). Mandatory pit stops for fuel/tires.
- Points: IndyCar-style 50-40-35-32-30-29-28... + pole, led lap once, most laps led bonuses

### Stock Cars / NASCAR (SC)

- Practice: 30 minutes
- Qualifying: 2 laps
- Race: High-speed rolling start. 3 stages. Top 10 of Stages 1 & 2 earn bonus points.
- Playoffs: Final 7–10 races. Top 10–16 drivers reset points and fight for championship.
- Points: NASCAR-style 55-35-34-33... with stage bonuses

### Endurance / WEC (EPC)

- Practice: 45–90 minutes
- Qualifying: EPC Series = 15-min open. EPC League = 15-min open. EPC Hyper = Hyperpole two-stage knockout
- Race: EPC Series = 45-min sprint. EPC League = 4-hour multi-class. EPC Hyper = 6-24 hour endurance.
- Le Mans gives double points across all EPC tiers
- Driver changes: mandatory in EPC League and EPC Hyper (3 drivers per car)
- Points: Standard 25-18-15 for 6h races, 38-27-23... for 8h/10h races, double at Le Mans

### Formula (GP)

- Practice: 45 minutes (GP4/GP3/GP2). GP1 = 3×60 min (1×60 min on sprint weekends)
- Qualifying: GP4 = 20-min open. GP3/GP2 = 30-min open. GP1 = knockout Q1-Q2-Q3.
- Race: GP4 = three 30-min sprints. GP3/GP2 = Sprint Race + Feature Race. GP1 = main race + optional sprint.
- Mandatory pit stop: GP2+ requires tire compound change. GP1 = at least 2 different compounds.
- Points: Standard 25-18-15 + fastest lap (if top 10). Sprint races: GP1 sprint 8-7-6-5-4-3-2-1

## 2.5 GK Championship — Progressive Tournament Structure

**✅ CONFIRMED v4.0 — 2026-06-17. Replaces all legacy GK tier design.**

| **Round** | **Groups** | **Cars/Group** | **Races** | **Advance Rule** | **Week Range** |
| --- | --- | --- | --- | --- | --- |
| Round 1 | 32 | ~23 avg (no max) | 8 | Top 10 per group → 320 advance | Weeks 6–20 |
| Round 2 | 16 | 20 | 10 | Top 8 per group → 128 advance | Weeks 22–40 |
| Round 3 | 4 | 32 | 2 | Top 15 per group → 60 advance | Weeks 42–44 |
| Final | 2 semi + Grand Final | 30 | 2 (same week) | Semi top 10 → Grand Final. Winner = World Champion | Week 46 |

*Calendar: 21 race entries in **GameState** (weeks 6-46), **gk_round** field drives round transitions.*

**Key Rules:**

- Player auto-assigned to Round 1 group — no manual group selection
- Player driver eliminated at end of any round = season over for GK
- AI drivers eliminated = removed from subsequent rounds
- Same academy = same group (round-robin academy assignment)
- TP works normally in GK — same auto-assignment logic as all other championships
- Round standings reset to 0 at the start of each new round
- Team standings: cumulative across all rounds (total championship perspective)

**GK Championship Stats (from Excel v2.6):**

| **Parameter** | **Value** |
| --- | --- |
| Championship ID | C-001 |
| Entry Fee | CR 10,000 per season (once — not per race) |
| Reputation | 15 |
| Min/Max Age | 8 / 17 |
| Drivers per Car | 1 |
| Optimum Participation | 640 drivers |
| Per-Race Prizes | 1st: CR 1,200 · 2nd: CR 600 · 3rd: CR 300 |
| End-Season Prizes (top 10) | 1st: 20,000 · 2nd: 10,000 · 3rd: 5,000 · 4th: 2,500 · 5th: 1,250 · 6th: 1,000 · 7th: 800 · 8th: 750 · 9th: 650 · 10th: 500 (CR) |
| Fuel per Weekend per Car | 20 kg |
| Spares per Race | CR 200 |
| Spec Parts | Aero, Engine, Gearbox, Chassis |
| Open Parts | Suspension, Brakes |
| Pit Stops | None |
| Flags | Yellow: Yes · Full Yellow: Yes · Safety Car: No · VSC: No |
| Max Overtake Gap | 2.1 |
| Base Service Time | 0 (no pit stops) |
| Avg Audience per Race | 2,200 |
| Base Driver Salary | CR 300/week |
| Base Mechanic Salary | CR 420/week |
| Base TP Salary | CR 580/week |

## 2.6 GK Driver Population System

**✅ CONFIRMED v4.0 — 2026-06-17**

**Real Cadet Drivers (510 total):**

- 510 cadets generated from drivers_cadets.json at game start
- Each owned by a parent academy team (contract_type = "academy")
- Fully normal drivers — developed, aged, scouted, transfer-market eligible
- Stats scaled by team reputation: top academy teams (rep 85+) produce better cadets
- Reputation: age-based 0–20 max. Age 8-10: 0-3. Age 14-15: 4-12. Age 16-17: 8-20
- Age 16-17 top cadets may exceed the reputation of lowest-tier professional drivers

**GK Free Agent Pool (8 drivers):**

- 8 uncontracted cadets (D-GK-FA prefix) generated at game start
- Available for player to hire as starting GK driver
- Excluded from GKDiscipline group population — not in race standings
- Age 13-17, no academy affiliation

**Ghost Drivers (fill remaining group slots):**

- Ghost drivers fill all group slots not covered by real cadets
- Single Overall attribute — no individual stat breakdown visible
- Card displays: "Not interested in a Professional Career"
- Cannot be approached, contracted, or signed by any team (player or AI)
- Fully participate in race simulation and championship standings
- No development — Overall attribute fixed for the season
- Ghost teams: no academy, no buildings, 1-4 drivers per team, shadow simulation only
- Ghost team naming: [Town Name] + [Suffix: GK Garage / Karting / Kart Club / Speed Shop]

**Group Population Algorithm (per round, per season):**

- 1. Collect all eligible real drivers (by age, by contract status)
- 2. Group them by parent academy team
- 3. Assign academies round-robin to groups (same academy = same group)
- 4. Count real drivers placed; fill remaining slots with ghost drivers
- 5. Each group reaches exact group_size target
- 6. D-GK-FA free agents excluded from all groups

# 3. TEAM & PLAYER

*v4.0 — 2026-06-17*

## 3.1 Team Variables

- Name, Badge (procedural), Two Colors (set in New Game, stored in GameState)
- Company_Value = Balance + Buildings + Cars + Commercial_Inventory + R&D_Assets − Loans
- Reputation (0-100): racing-driven. Affects hiring interest, loan limits, AI behaviour.
- Marketability (0-100): derived — rep×0.6 + fan_share + buildings + sponsors + R&D bonuses. Never stored.
- Running Championships: defines required buildings, staff slots, car generation, company value, loan capability

## 3.2 CEO / Player

- Name, Sex, Age (25-45), Nationality — set in New Game flow
- Salary = 1% of weekly Net_Weekly_Profit. Zero when team loses money.
- Age: if CEO reaches 65+, player can retire and create a new one, or promote a TP to CEO to continue
- CEO market is SEPARATE — covers all CEOs. Only player’s CEO is headhunted or can switch teams. AI CEOs never switch.

**⚠ OVERRIDE: Brainstorming says 5% salary. GDD overrides to 1%. Code implements 1%.**

## 3.3 AI Teams (P27 — DONE S23)

- 120 named AI teams loaded from AIManager.gd (Excel Teams sheet, T-001 to T-120)
- Types: Factory (top-tier), Customer (mid-tier), Privateer (entry). 10 dedicated karting teams (T-111–T-120)
- Championship mapping: GT3/GT4→TC, LMP/WEC→EPC, NASCAR→SC, IndyCar→OWC, Formula→GP, GK→C-001
- AIManager.gd: RefCounted class instantiated by GameState._ready(). No autoload needed.

**✅ CONFIRMED: The game ALWAYS tends to Optimum car count per championship:**

- Below optimum but above minimum: check if existing teams can add a car, then if teams from other championships can join
- Below minimum: auto-generate a new team immediately to cover the gap
- Above optimum: create a mini-crisis for the weakest teams to abandon the championship
- Newly generated teams receive minimum required buildings, staff, cars, and a budget covering 2 season of expenses

**✅ CONFIRMED: _****fill_championship_grids****() disabled — JSON has correct driver counts. Re-enable only when optimum counts need topping up.**

## 3.4 AI Team Character (6 Weights, 0.0–1.0)

| **Weight** | **High = ...** | **Low = ...** |
| --- | --- | --- |
| ambition | Always trying to expand — more championships, more cars | Content where they are |
| risk_tolerance | Bids over budget for stars, takes large loans | Never overspends, builds reserves |
| loyalty | Keeps drivers/staff for years regardless of results | Drops underperformers quickly |
| development | Signs young, develops talent from within | Buys proven established names |
| discipline_bias | Never leaves primary discipline | Expands across multiple disciplines |
| innovation | First to upgrade R&D and buildings | Only upgrades when essential |

## 3.5 AI Seasonal Decision Logic

*Checks run 2-4 times per season, not just at end of season.*

- 1. Calculate available budget: projected_income − projected_expenses
- 2. Score each possible championship by ambition weight × prestige value
- 3. Check requirements: entry fee + car cost + building requirements + build time before registration deadline
- 4. Expand if affordable: register championship, buy car, assign driver from pool or free agent market
- 5. Contract if needed: drop lowest-value championship first
-    → Consider dropping just a car (not the whole championship) if the championship allows it
-    → REASSIGN driver/staff to remaining cars first — never release unnecessarily
-    → Release only if truly no role exists after all reassignment options are exhausted
-    → Release for performance reasons too: if a top team underperforms, release and buy better
- 6. R&D expansion: if RP > threshold AND affordable → upgrade R&D Center → unlock designer slot → spend RP

## 3.6 AI Financial Model

*Runs 2-4 times per season for performance — not weekly. P19 scope.*

- Income: prize money (end-of-season from standings), sponsor income proportional to reputation, commercial car sales, parts sales, building passive income
- Expense calculation (weekly): staff salaries (actual weekly_salary from JSON) + building maintenance (maint_l1 × level addition) + racing costs amortised (entry_fee + fuel × races × fuel_price + spares × races) × num_cars / 52
- Fuel price for AI calculation: current GameState.fuel_price_per_kg (dynamic, not hardcoded)
- Starting balance: 1.5× season expenses for Privateer, 2× for Customer, 3× for Factory
- Bankruptcy: 3 consecutive negative seasons → team folds → drivers/staff enter free agent pool
- Commercial car income: 10 factory teams have market share from Excel v2.6. Balance review pending.

**⚠ OVERRIDE: Current implementation uses simplified model. Full P19 implementation pending.**

## 3.7 AI Personality Archetypes

**✅ CONFIRMED v4.0 — 2026-06-17**

8 personality types. Each team gets one primary personality (secondary influence possible in future).

| **#** | **Personality** | **Ambition** | **Risk** | **Loyalty** | **Youth** | **Spending** | **Expansion** | **Description** |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Empire Builder | Very High | Med-High | Low | Low | Aggressive | High | Wants to dominate multiple disciplines |
| 2 | Talent Developer | Medium | Low | High | Very High | Moderate | Low | Focuses on growing young drivers |
| 3 | Financial Conservative | Low | Very Low | High | Medium | Very Conservative | Very Low | Prioritizes stability and profit |
| 4 | Aggressive Climber | High | High | Low | Low | Aggressive | Medium | Takes big risks to move up quickly |
| 5 | Legacy Guardian | Medium | Low | Very High | Medium | Moderate | Very Low | Protects tradition and history |
| 6 | Specialist | Medium | Low | High | High | Conservative | Very Low | Stays loyal to one discipline |
| 7 | Opportunist | High | High | Low | Low | Aggressive | High | Jumps between opportunities |
| 8 | Innovator | High | Medium | Medium | High | High (R&D) | Medium | Heavy focus on R&D and new technology |

Personality traits stored as 0-100 values per team:

| **Trait** | **Description** | **Influences** |
| --- | --- | --- |
| Ambition | Desire to move up in tiers and win big | Championship registration, driver signings |
| Risk Tolerance | Willingness to take financial/sporting risks | Contract offers, spending, car development |
| Loyalty | How long they keep underperforming staff/drivers | Contract renewals, firing decisions |
| Youth Focus | Preference for developing young talent | Academy investment, signing young drivers |
| Financial Discipline | How carefully they manage money | Budgeting, sponsor hunting, spending |
| Expansion Drive | Desire to participate in multiple championships | Multi-discipline participation |
| Innovation | How much they invest in R&D and new technology | R&D task priority, CNC investment |
| Aggressiveness | How hard they compete in transfers and racing | Driver poaching, on-track behaviour |

# 4. DRIVERS & STAFF

*v4.0 — 2026-06-17*

## 4.1 Driver Key Attributes

| **Attribute** | **Type** | **Description** | **Notes** |
| --- | --- | --- | --- |
| Pace | Visible | Raw speed — primary lap time contributor |  |
| Wet / Rain | Visible | Performance in rain conditions | Rename pending — P52 |
| Focus | Visible | Consistency and error avoidance |  |
| Race Craft | Visible | Overtaking and defending ability |  |
| Consistency | Visible | Lap-to-lap repeatability |  |
| Fitness | Visible (Dynamic) | Degrades during race weekend, resets fully before next event | Dynamic stat |
| Fatigue Resistance | Visible | Reduces per-lap fitness degradation rate |  |
| Reputation | Visible | Affects team rep when signed. Stored as driver.marketability for save compat. |  |
| Feedback | Visible | Quality of setup info given to mechanic. Affected by Part Knowledge. |  |
| Potential | Hidden | Maximum possible growth ceiling |  |
| Aggression | Hidden | Risk-taking in wheel-to-wheel situations |  |
| Experience | Hidden | Career races accumulated |  |
| track_knowledge | Dictionary | Keyed by track_id. Grows each visit, drops over time. Up to −1% lap time at TK100. |  |
| part_knowledge | Dictionary | Keyed by championship/car type. Only impacts driver Feedback. |  |

*❓ OPEN: "Wet" attribute needs renaming. Options: Rain Mastery, Wet Weather, Rain Pace. Decision needed. → P52*

## 4.2 Driver Aging & Performance Curve

- Peak performance: age 24–32
- Slow decline after 33, sharp decline after 36–37
- Retirement window: 38–50 (extended to 50 — rare — to cover veteran TC drivers)
- Drivers without a contract for 2 seasons leave the sport

**✅ CONFIRMED v4.1 (S28) — Driver/Staff lifecycle (implemented in SeasonManager.gd S28.0):**

- **Two rules only — nobody is deleted arbitrarily:**
  1. **Age retirement** — drivers: rising chance from 38, forced at 50 (rare in between). Staff: hard retirement at 65.
  2. **Free-agent decay** — DRIVERS only: uncontracted for 2 full seasons → erased. **No free-agent decay for staff.**
- **Retirement = ERASE (game over for that person)** — removed from `all_drivers`/`all_staff`, archived to `retired_personnel` (for History §19 / News §13), name released to NameGenerator.
- **Staff now age each off-season** (previously frozen) so the 65 cap can fire.
- **No D-GEN / DRV-XXXX fillers** — the old `is_eligible_for_gk_regional()` delete-and-respawn loop is removed. Grid gaps fill via the normal NameGenerator path.
- `seasons_without_contract` accrues only while uncontracted; resets to 0 when contracted.
- **⚠ GAP:** staff free-agent **pool needs a per-season top-up** so retirements don't drain it over many seasons (not yet implemented — see §21).

## 4.3 Driver Reputation Scale

**✅ CONFIRMED v4.0 — 2026-06-17**

| **Tier** | **Reputation Range** |
| --- | --- |
| Cadets (age 8-10) | 0 – 3 |
| Cadets (age 11-13) | 2 – 8 |
| Cadets (age 14-15) | 4 – 12 |
| Cadets (age 16-17) | 8 – 20 (some exceed lowest-tier pro drivers) |
| GP4 / Rally4 / SC Dev / OWC Next Gen | 10 – 40 |
| GP3 / Rally3 / TC Sport | 20 – 45 |
| GP2 / TC Elite / OWC Pro | 33 – 67 |
| GP1 / SC Cup / EPC Hyper (stars) | 57 – 100 (85+ for elite stars only) |

## 4.4 Academy & Age Rules

**✅ CONFIRMED: Ages 8-17 inclusive for all academy cadets.**

- All cadets age 8-17 inclusive. Team pays full contracts for under-18 drivers without Academy.
- With Academy: cadets (age 8-17) PAY the team — upkeep×1.08 per slot. 5 cadets per at level1 and then 1 cadet per level
- Cadets arrive automatically based on team marketability (higher = better quality)
- Can promote to main team or sell for profit (transfer market)
- Cadets need a spot in the racing department to race

**✅ CONFIRMED: 1.15 Contract Rule (First Professional Contract):**

- The driver that belongs to an academy favors that team’s contract terms for their 1st Professional Contract up to 15%
- 1st Professional Contract = the first contract during which the driver’s age is 18 or higher
- If the parent team offers salary 100, rival teams must offer 116+ for the driver to consider them
- This is a loyalty/affinity modifier — the driver CAN still leave for significantly better offers

## 4.5 Discipline Adaptation

**✅ CONFIRMED: Adaptation also drops — it is not a one-way progression.**

- effective_stat = raw_stat × (0.5 + adaptation / 200.0)
- At 0% adaptation driver performs at 50% of stats. At 100% adaptation driver performs at full stats.
- Stored as driver.discipline_adaptation[discipline]
- Floor: peak_value_ever_reached × 0.35 — adaptation never drops below this floor
- After every race, all adaptation scores tend toward the discipline adaptation matrix values
- Cross-discipline assignments show adaptation warning in TP proposals popup
- TP proposals use effective_skill (raw × adaptation multiplier) to rank candidates, not raw stats

## 4.6 Scouting — TP Intelligence

- The Team Principal’s PR attribute + team Reputation determines intelligence quality
- TP approaches CEO: "Identified promising driver — [Name], age 14, GK National. Worth watching."
- Player gets name only, not full stats — must investigate through racing against them or free agent market
- If player delays, AI teams’ TPs are also watching the same driver — creates urgency without artificial timers

## 4.7 Staff Roles & Attributes

| **Role** | **Key Attributes** | **Notes** |
| --- | --- | --- |
| Team Principal | Race Strategy, Practice Mgmt, Qualifying Mgmt, Race Pace, Car Setup Oversight, Pit Mgmt, PR, Parts Knowledge, Track Knowledge | Multiplies all racing staff. Not assigned to Designers. |
| Race Mechanic | Car Setup, Pit Stops, Parts Knowledge, Track Knowledge, Race Pace | 1 per car |
| Pit Crew | Pit Stop Speed, Repair Skill, Fitness (Dynamic), Fatigue Resistance | Required for non-GK championships. Fitness degrades per pit stop/repair. |
| CFO | Sales Skill, Sponsor Negotiation, Resource Management, Budget Planning, Speculation, Loan Management | Team-level. Unlocks 3rd loan slot. Handles all contract negotiations independently. |
| Designer | Aero, Engine, Chassis, Gearbox, Suspension, Brakes, Reliability, Parts Knowledge | Team-level. TP does NOT multiply. R&D Studio only. They collect RP per race, additive for more than one |
| Race Strategist | Race Strategy, Race Pace Reading, Practice Scheduling, Qualifying Timing, Track Knowledge | Excluded from GK and Rally. Multiplied by TP. |
| CEO (AI only) | Success variable only | Exists for AI teams and news generation. Player IS the CEO. |

**⚠ OVERRIDE: TP does NOT affect designers — confirmed override of Formula Doc**

## 4.8 Fitness System (Drivers & Pit Crew)

**✅ CONFIRMED v4.0 — per Master Calculation ****&**** Formula Document S24**

- Fitness is a DYNAMIC stat. Starts at 100 at beginning of each race weekend.
- Degrades during the weekend. Partially recovers between sessions. Fully resets before next event.
- Effective attribute = raw_attribute × (fitness / 100)

**Driver degradation per lap: **fitness_drop = (lap_time_sec / 90) × mode_multiplier × (1 − fatigue_resistance / 100)

Mode multiplier: Conserve=0.80 | Normal=1.00 | Attack=1.30

**Pit Crew per pit stop: **fitness_drop = (pit_stop_time_sec / 2) × (1 − fatigue_resistance / 100)

**Pit Crew per repair: **fitness_drop = (repair_time_min / 2) × (1 − fatigue_resistance / 100)

**Recovery rates: **Practice→Qualifying: 0.30 | Qualifying→Race: 0.60 | Race end→next weekend: full reset to 100.0

Fitness Clinic building increases recovery_rate passively for both drivers and pit crew.

## 4.9 TP Auto-Assignment (P31 — DONE S23)

**✅ CONFIRMED: Proposals generated 1 week before race.**

- generate_tp_assignment_proposals(): sorts cars by discipline prestige (GP×7, EPC×6, SC×5, OWC×4, TC×3, Rally×2, GK×1)
- Assigns best driver/mechanic by effective_skill = raw × adaptation_multiplier
- GK: TP works normally — same assignment logic as all other championships
- Non-GK: exclusive 1:1 assignment per championship
- DNS warnings generated for unavoidable conflicts. Cross-discipline adaptation warnings shown.
- Fires TDL + notification → Racing Department. Player sees TPProposalsPopup: Accept All / per-item / Skip.

**⚠ BUG: TP proposals currently triggering every racing week instead of 1 week before race only. Fix pending.**** Also, the proposals remain in the HQ screen even after they were accepted**

# 5. CONTRACT SYSTEM

*v4.0 — 2026-06-17*

## 5.1 Contract Terms

- Driver: weekly_salary, duration 1-5 seasons, win_bonus, podium_bonus, championship_bonus, release_clause
- Staff: weekly_salary, duration 1-4 seasons, championship_bonus, performance_bonus, release_clause
- Sponsor: Type 1 (weekly flat), Type 2 (performance bonuses), Type 3 (championship commitment upfront)
- Academy cadet: Always signed with duration until the age of 18, promotes to professional contract with loyalty discount (see §4.4)

## 5.2 Approach & Bond System (P22 — DONE)

- Interest check: skill×0.5+50 + rep_gap×0.5 + tp.rep×0.3, clamped 5–95%
- Tier penalty on Interested Only: (skill-50) × (4-champ_tier) × 0.8 — elite drivers won’t join low-tier champs
- Free agents use their_rep=0 baseline — more accessible than contracted staff
- Bond formula: weekly_salary × weeks_remaining × talent_factor
- TP required ONLY for bond approach (contracted staff). Not needed for free agents.
- Negotiation rounds: up to 4 weeks (1 per week). Threshold: 0.95 Round 1 → 0.82 final.
- All contract negotiations handled exclusively by CFO (TP not involved in negotiations)

**⚠ BUG: Contract negotiations not triggering automatically. Fix pending.**

**⚠ BUG: Renewed driver contract not persisting into Season 2. Fix pending.**** We need to check if the bug exists also for the staff**

# 6. TRANSFER MARKET ECOSYSTEM (P51 — Planned)

*v4.0 — 2026-06-17*

The transfer market is the heartbeat of every management game. With ∼5000 drivers and staff, this is entirely achievable.

## 6.1 Architecture — One Pool, Everyone Competes

All 120 AI teams + player compete for the SAME pool. No exceptions.

- Pool contains: ∼614 professional drivers + 510 cadets + ∼ thousands of staff
- Every off-season: expiring contracts → free agent pool → all teams make approaches → negotiations → signings → window closes
- Mid-season: injuries/performance issues → emergency window from same pool
- Remaining unsigned after window: stay in pool. 2 seasons unsigned → retire.

## 6.2 AI Team Bidding Priority

- 1. Fill empty seats first (car needs a driver — DNS prevention)
- 2. Upgrade: replace underperformers with better available talent
- 3. Budget check: bond + salary must be affordable
- 4. Reputation check: high-rep teams attract better talent automatically
- 5. Discipline adaptation: AI teams prefer drivers already adapted to their primary discipline

## 6.3 What Creates Drama

- Blackthorn Racing and player both want the same driver → Blackthorn offers more → player decides: match it or walk away
- Player’s star mechanic approached by rival → renew contract before window closes or lose them
- Factory team collapses → 2 top designers hit market simultaneously → feeding frenzy
- Player develops young GK driver for 3 seasons → GP2 team arrives with massive offer → release clause triggered
- Player wins title → rival team immediately approaches player’s star driver

## 6.4 CEO Market (Separate System)

- Covers all CEOs. Only player’s CEO is headhunted or can switch teams. AI CEOs never switch, to be re-evaualted
- Rival team can approach player’s CEO: take over team X, keep your balance, new challenge
- Player can also apply to take over a specific AI team (P37 — Choose Existing Team)

# 7. ACADEMY SYSTEM (P34 — Planned)

*v4.0 — 2026-06-17*

- Without Academy: team pays full contracts for drivers under 18
- With Academy: cadets (age 8-17) PAY the team — upkeep×1.08 per slot. 5 cadets per slot per level.
- Cadets arrive automatically based on team marketability (higher = better quality)
- First professional contract: 1.15× loyalty discount — see §4.4 for full rule
- Academy cadets assigned to GK championship for training — TP auto-assignment applies
- Can promote to main team or sell for profit via transfer market

# 8. WRA REGULATION CYCLES

*v4.0 — 2026-06-17*

**⚠ OVERRIDE: Formula Doc: global 4-season cycle. REPLACED by per-discipline cycles below.**

| **Group** | **Championships** | **Cycle** | **First Reset** | **Real World Basis** |
| --- | --- | --- | --- | --- |
| Formula | GP4/GP3/GP2/GP1 | 4 seasons | S5 | F1 4-5yr cycles |
| Touring Car | TCS/TCE | 5 seasons | S6 | BTCC 5yr cycles |
| Karting | C-001 (GK) | 6 seasons | S7 | CIK-FIA stable spec |
| Open Wheel | OWN/OWD/OWP | 7 seasons | S8 | Indycar Dallara IR18 |
| Stock Car | SCD/SCT/SCC/SCU | 8 seasons | S9 | NASCAR Next Gen |
| Rally | RL4/RL3/RL2/RLP | 9 seasons | S10 | WRC 10yr |
| Endurance | EPS/EPL/EPH | 10 seasons | S11 | ACO/WEC 5+ yr |

**✅ CONFIRMED Blueprint reset rules:**

- On WRA cycle reset: all BP-* and RE-* blueprints wiped. Base_Reliability resets to 60.
- P4 Special Projects unaffected by WRA cycle.
- P2 Upgrades cleared each season.
- Blueprints reset at end of every season EXCEPT those transferred to CNC.
- CNC-transferred blueprints can only be used in the CNC — they cannot be used for further R&D development.

**⚠ BUG: WRA blueprint approval should take 1 week (not current delay). Fix pending.**

**⚠ BUG: Previous season CNC blueprint not scrapping on season transition. Fix pending.**

# 9. CAMPUS & BUILDINGS

*v4.0 — 2026-06-17*

## 9.1 Building Philosophy

- Every building level upgrade opens new Special R&D opportunities and new staff positions
- Performance and profit related buildings increase their stats per level
- Each championship requires: 1 Team Principal, 1 Strategist (non-GK/Rally), 1 Race Mechanic per car, 1 Pit Crew (non-GK)
- AI teams have ALL the same buildings as the player — full progression, visible competitiveness
- All buildings matter for AI simulation — they are the competitive DNA of a team

## 9.2 Building Maintenance & Passive Income (from Excel v2.6)

Weekly maintenance formula: cost = Weekly_Maintenance_Level1 × current_level_value (excel file) per week

Weekly passive income formula: income = Weekly_Profit_Level1 × current_level_value (excel value) per week

| **Building** | **Maintenance L1/****wk** | **Passive Income L1/****wk** | **Max Level** |
| --- | --- | --- | --- |
| Headquarters (HQ) | CR 1,200 | CR 0 | 26 |
| Logistics Center | CR 950 | CR 0 | 24 |
| Garage | CR 1,100 | CR 1,800 | 89 |
| Racing Department | CR 850 | CR 0 | 89 |
| R&D Design Studio | CR 1,600 | CR 0 | 27 |
| CNC Parts Plant | CR 2,200 | CR 0 | 24 |
| Ops Sim & Telemetry | CR 1,350 | CR 0 | 30 |
| Aerodynamic Wind Tunnel | CR 1,750 | CR 0 | 9 |
| Factory (Vehicle Assembly) | CR 2,400 | CR 0 | 12 |
| Museum | CR 750 | CR 2,400 | 5 |
| Theme Park | CR 1,100 | CR 5,000 | 5 |
| Public Racing Club | CR 850 | CR 1,600 | 7 |
| Merchandise Store | CR 650 | CR 3,000 | 5 |
| Fitness Clinic | CR 980 | CR 0 | 109 (to be evaluated) |
| Pit Crew Arena | CR 1,150 | CR 0 | 20 |
| Academy | CR 980 | CR 0 | 4 |
| Karting Track | CR 480 | CR 800 | 3 |
| Gravel Track | CR 620 | CR 700 | 3 |
| Oval Track | CR 680 | CR 850 | 3 |
| Race Track | CR 1,250 | CR 1,300 | 4 |

## 9.3 Building Directory

| **Zone** | **Building** | **Gameplay Impact** | **Core Mechanics** |
| --- | --- | --- | --- |
| Zone 1: Command | Headquarters (HQ) | Executive staff. CEO/TP/CFO slots. | Unlocks loan tiers. Multiplies marketability. WRA, Financial HUB |
|  | Logistics Center | Fuel & spare parts control | Orders parts, fuel contracts, cars, game-specific components |
|  | Garage | Car maintenance. Race Mechanic slots. | Car repairs. Profit from customer repairs. |
|  | Racing Department | Houses drivers | Slightly improves driver stats, Racing information |
| Zone 2: Engineering | R&D Design Studio | Designer slots | Design. Upgrade. Reverse engineering. Special R&D. Commercial cars. Consumes RP. Produces blueprints |
|  | CNC Parts Plant | Parts manufacturing | Produces in-house parts. Sells to other teams. Requires blueprints from RnD |
| Zone 3: Simulation | Ops Sim & Telemetry | Strategist slots | Track knowledge to 50% baseline. Sector weather data. |
|  | Aerodynamic Wind Tunnel | Aero validation | Part optimization. Required for aero R&D projects. |
| Zone 4: Commercial | Factory (Vehicle Assembly) | Consumer car production | Commercial car sales revenue. Capacity per level. |
|  | Museum | Historic archive | Passive income from marketability. Converts wins to company value. |
|  | Theme Park | Entertainment resort | Passive income. |
|  | Public Racing Club | Amateur track days | Income from reputation. Scales with fans. |
|  | Merchandise Store | Fan merchandise | Income from reputation and fan base. |
| Zone 5: Human Perf. | Fitness Clinic | Driver/Pit Crew conditioning | Fatigue recovery. Passive stat boosts. |
|  | Pit Crew Arena | Pit crew slots and training | Lowers pit stop times. Reduces repair times. |
|  | Academy | Youth driver school. 5 cadets/slot. | Generates low-cost junior talent. Loyalty discount on first contract. Provides profit since cadets pay to enter. |
| Zone 6: Test Tracks | Karting Track | GK specialist circuit | Improves GK stats. Passive income. Required for own GK production. |
|  | Gravel Track | Rally stage | Improves Rally stats. Required for own Rally car production. |
|  | Oval Track | High-speed oval | Improves NASCAR/INDY stats. Required for own SC/OWC production. |
|  | Race Track | Full FIA circuit | Improves TC/WEC/GP stats. Required for own TC/EPC/GP production. |

# 10. R&D SYSTEM

*v4.0 — 2026-06-17*

## 10.1 Five Pillars

- P1 DESIGN: L1–L5 blueprints, freely researchable. Formula car MUST have L1 before Race 1. *General R&D — no physical car required.*
- P2 UPGRADE: L1–L5, for open parts of owned cars. Season-scoped — cleared each season. *Requires a physical car (reads current car stats) — gated until car delivery, see §23.8. **Player-only** R&D rule.*
- P3 REVERSE ENGINEERING: Always L1. 25% quality penalty vs own-designed. Unlocks the L2 of the desing. *Requires a physical car to reverse-engineer — gated until car delivery, see §23.8. **Player-only** R&D rule.*
- P4 SPECIAL PROJECTS: 100 total, building-linked. Not wiped by WRA cycle. See Brainstorming.docx for full list. *General R&D — no physical car required.*
- P5 Commercial Cars Desing: Straight forward. To be designed and implemented. *General R&D (future) — no physical car required.*

**⚠ S28 — Registration deadline = design deadline (§23.2). R&D + WRA must finish in-season or blueprints are LOST (§23.4). All deadlines move 1 week earlier for WRA approval (§23.3). Player-only burden (§23.7).**

## 10.2 R&D Storage Cap

RP storage cap bound to R&D Design Studio level — prevents grinding low-tier championships for infinite RP before jumping to GP1. It may need to be increased

## 10.3 Part Knowledge (P35 — Planned)

- Increases Designers output
- Increases the variable of the race performance
- It is increased by the laps finished.
- It is factorized by the drivers feedback

## 10.4 CNC Car Development Tiers

| **Tier** | **Rank** | **Championship** | **Max Cost** | **Timeline** | **Commercial Unlock** |
| --- | --- | --- | --- | --- | --- |
| 1: Grassroots | 1-4 | GK → GK World | $6,500–$24,000 | 2–3 Weeks | None |
| 2: Spec Assembling | 5-17 | F4/WRC4 → LMP2/F2 | $85K–$690K | 8–16 Weeks | Hatchbacks → Track Day Specials |
| 3: Bespoke Sub-systems | 18-21 | GT4/NASCAR Cup/IndyCar | $260K–$750K | 12–16 Weeks | Entry Sports → V8 Sedans |
| 4: Highly Complex | 22-23 | GT3/WRC Rally1 | $800K–$1.4M | 20–24 Weeks | Supercars, EV Hybrids |
| 5: Ultra-Complex | 25-26 | WEC Hypercar/Formula 1 | $6M–$20M | 48–50 Weeks | Hypercars, Megacars |

**⚠ BUG: CNC part install button broken. CNC blueprint not scrapping after season. Fix pending.**

# 11. ECONOMY SYSTEM

*v4.0 — 2026-06-17*

## 11.1 Global Economy

- Continuous economy_index 0–100 (0=deep recession, 50=normal, 100=boom)
- State label: 0–30=Recession, 30–70=Normal, 70–100=Boom
- Index drifts ±0.5%/week normally, ±3–5% shock weeks. Mean-reverts to 50.
- Full cycle (recession→boom→recession) takes 2–4 seasons

**⚠ OVERRIDE: Previous 3-state snap system replaced by continuous index (S20.1)**

## 11.2 Fuel Price

- Base: 800 + economy_index × 8.0 (range 800–1600 CR normally), **⚠ OVERRIDE** : it is different in the in game formula, we keep the code
- Weekly move: ±1–2% normally, ±5% shock (3% chance/week). Hard cap: 600–2000 CR.
- Teams can lock fuel contracts for multiple weeks to hedge risk

**⚠ OVERRIDE: Previous system allowed 3000+ CR — capped at 2000 CR (S20)**

## 11.3 Weekly Economy Cycle

- Income: Race prize money, sponsors, commercial car sales, parts sales, building passive income, merchandise, loan
- Expenses: Driver & staff salaries, building maintenance, R&D costs, manufacturing materials, loan interest, race entry fees, taxes, fuel
- Net profit → balance updated → CEO salary = 1% of positive net profit
- Company Value = Balance + Buildings + Cars + Commercial_Inventory + R&D_Assets − Loans

**⚠ BUG: End of season financial screen showing wrong weekly profit. Fix pending.**

## 11.4 Loan System (P44 — DONE S20)

| **Tier** | **Max % Company Val** | **Duration** | **CFO Benefit** | **HQ Req** | **Notes** |
| --- | --- | --- | --- | --- | --- |
| 1 | 20% | 4–8 seasons | Base rate | Level 1 | No CFO = Tier 1 cap, +1.5% rate |
| 2 | 35% | 4–12 seasons | −0.5% rate | Level 3 |  |
| 3 | 50% | 4–16 seasons | −1.0% rate | Level 6 |  |
| 4 | 65% | 4–20 seasons | −1.5% rate | Level 9 |  |
| 5 | 80% | 4–25 seasons | −2.0% rate | Level 12 | CFO unlocks 3rd loan slot |
- Interest rate = current_loan_rate + risk_premium − CFO_discount
- Risk premium: max(0, (50 − team.reputation) × 0.05) — low rep teams pay more
- Early repayment: allowed, penalty = 1 season’s interest on remaining balance

## 11.5 Game Difficulty

| **Level** | **AI Performance** | **Player Economy** | **Player R****&****D** | **Starting Budget**** (to be discussed)** |
| --- | --- | --- | --- | --- |
| Rookie | ×0.75 | ×1.30 | ×0.80 | CR 150,000 |
| Amateur | ×0.85 | ×1.15 | ×0.90 | CR 100,000 |
| Realistic | ×1.00 | ×1.00 | ×1.00 | CR 50,000 |
| Expert | ×1.15 | ×0.90 | ×1.10 | CR 35,000 |
| Master | ×1.25 | ×0.80 | ×1.20 | CR 20,000 |

# 12. REPUTATION, MARKETABILITY & FANS

*v4.0 — 2026-06-17 — ⚠ OVERRIDE of Formula Doc: driver marketability repurposed as reputation*

## 12.1 Architecture

- Drivers & Staff: have reputation (stored as driver.marketability for save compat)
- Team Reputation: racing-driven. Affects hiring interest, loan limits, AI behaviour.
- Team Marketability: derived — never stored. = rep×0.6 + fan_share + buildings + sponsors + R&D bonuses
- Legacy bonus: departing star (rep>50) props up marketability for 2 seasons
- Reputation inertia: rises slowly (×0.25/season), falls even slower (×0.15/season) — Hamilton/Mercedes effect

## 12.2 What Affects Reputation

| **Factor** | **Effect** |
| --- | --- |
| Race wins & podiums | positive spike |
| Championship win | Large positive — scales by tier |
| DNFs / DNS | Negative |
| Losing to inferior teams | Negative |
| Driver scandals | Negative |
| Building upgrades completed | Mild positive |
| Special R&D completed | Mild positive |
| Bankruptcy risk | Strong negative |
| High commercial car prices (debatable) | Marketability negative |

## 12.3 Global Fans per Discipline

| **Game Name** | **Real Equivalent** | **Top Tier Base Fans** | **Notes** |
| --- | --- | --- | --- |
| GP1 | Formula 1 | 750 Million | Star power factor: 0.7–1.3 |
| Premier Rally | WRC | 200 Million | Competition factor: 0.82–1.18 |
| EPC Hyper | WEC/Le Mans | 150 Million | Tier multipliers: ×0.008 → ×1.0 |
| SC Cup | NASCAR | 85 Million |  |
| OWC Pro | IndyCar | 28 Million |  |
| TC Elite | BTCC/WTCC | 18 Million |  |
| GK Championship | CIK-FIA Karting | 6 Million |  |

team_active_fans = global_fans × (rep/100)² × 0.15

**⚠ BUG: Active fans exploding to 918k in 32 weeks in GK. Formula needs correction. Fix pending.**

*❓ OPEN: Fan base numbers need real-world data verification pass before release. → P56** (done is good)*

# 13. NEWS SYSTEM (P15 — Planned)

*v4.0 — 2026-06-17*

The news system is the voice of the living world. Without it the world is silent. It is NOT optional — it is the primary interface between the player and AI team activity.

## 13.1 News Event Triggers

- Race results: WIN, DNF, DNS,  Championship WIN, RACE WIN, Championship FIGHT
- Driver/staff transfers: signings, releases, poaching between AI teams
- Building: upgrade completed, new building constructed
- Economic: fuel price spike, recession/boom, tax changes
- Team health: AI team bankruptcy, AI team expansion into new championship
- Rivalry: "Valkyrie Racing reveals major car upgrade"
- Player-specific: contract expiry warnings, reputation changes, sponsor offers

## 13.2 News Impact

- Each news event affects team or driver Reputation and Marketability positively or negatively
- Player learns about rival teams through news — not through a free data screen
- Building upgrades: "Ironwood Motorsports reportedly expanded their facility this off-season"
- Financial distress: "Cobalt Collective in financial difficulty — star driver linked with departure"

# 14. RACE SIMULATION

*v4.0 — 2026-06-17*

## 14.1 Race Calculation Engine

- Driver Stats: Pace, Wet/Rain, Focus, Race Craft, Discipline Adaptation
- Adaptation multiplier: 0.5 + (adaptation / 200.0) — at 0% gives 50% stat, at 100% gives full stat
- Pace factor: ±5% spread for GK (karting is driver-sensitive), ±3% for other championships
- Car Performance per sector: Engine, Aero, Chassis, Gearbox, Suspension, Brakes
- Setup effectiveness (Qual % + Race %)
- Track Knowledge + Part Knowledge multipliers (Part Knowledge → Feedback only)
- Strategist + Team Principal bonuses
- Random events + Weather probability
- Reliability (from R&D and maintenance)
- Dirty Air threshold: 1.65 × Max_Overtake_Attempt_Gap

**⚠ BUG: Difficulty multipliers not yet wired into race sim. Fix pending — P9 scope.**

**⏳ PENDING: Temperature formula for tyre wear — ambient + track temperature impact on degradation. Deferred to P28.**

## 14.2 RP, Track Knowledge & Part Knowledge

**✅ CONFIRMED: RP gained per km per designer (formula in code).**

**✅ CONFIRMED: Track knowledge based on laps. Drops over time without racing.**

**✅ CONFIRMED: Part knowledge based on km. Only impacts driver Feedback. Drops over time.**

## 14.3 Session Variables

**Practice: **Length depends on championship (15 min GK → 90 min EPC/GP1). Both trims raise track and part knowledge. The setup value raises to 80% baseline no matter the choice of the trim. From 80 to 100 only the selected trim increases

**Qualifying: **Format depends on championship (see §2.4). Tracks: Best Lap Time, Starting Grid, Fuel Level, Tyre Wear, Parts Wear, Track Knowledge, Weather.

**Race: **GK: No two-way radio, no pit instructions. Rally: No micromanagement, auto-calculated. All others: Full real-time management.

## 14.4 Live Race Visualization (P14 — Planned)

- 2D top-down track view with colored dots representing cars
- Real-time position tracking, sector times, gaps, tire wear overlay
- Safety Car / VSC / Yellow / Full Yellow / Red Flag events
- Speed control: 1×, 4×, 12×, 30×, Max. Auto slow-down at critical moments.
- "Skip to Next Racing Event" button (next pit window, incident, etc.)
- Overtake windows clearly indicated in visualization

## 14.5 Anti-Boredom Systems

- Constant player agency: driver instructions (Push/Conserve/Attack ±15% on pace/fuel/wear)
- Even when finishing last, player gains: Track Knowledge, Parts Knowledge, RP, 
- Endurance: driver stint planning, fatigue management, Night Stint / Rain Management / Final Hour Push modes
- Long seasons (NASCAR 36 races, F1 24 races): stage rewards, per-race personal goals, condensed mode

# 15. UI STRUCTURE

*v4.0 — 2026-06-17*

## 15.1 HQ — Three Tabs

**Tab 1: Overview**

- Left: CEO card · Finances (Balance, Wkly Cost, Runway, Reputation, Marketability, Active Fans) · HQ Effects
- Center: Championships · Drivers · Staff · PENDING ACTIVITY (player_turn-gated) · Sponsors
- Right: TP slots · CFO slot · Navigate buttons

**Tab 2: Financial Department**

- Top: Income panel · Expense panel · Key Indicators (Marketability + Active Fans)
- FINANCIAL GRAPHS: 6 chart selector buttons + inline line chart + time range selector (weeks/seasons/all time)
- Sponsors: slot bar · active sponsors · pending offers · CFO search
- LOANS section: Take Loan button + active loans panel

**⚠ BUG: Balance title always visible in Financial Dept, mixes with other tab titles. Fix pending.**

**Tab 3: World Racing Association**

- Regulation cycle countdowns · Blueprints · Submissions · Supply contracts · Registration
- Per-championship DNS requirements checklist (car, driver, mechanic, TP, strategist) with ✅/⚠

## 15.2 Racing Department — TP Proposals Panel

- Summary card: N assignments ready · N warnings · N critical
- "📋 Review Proposals →" opens TPProposalsPopup (full-screen overlay)
- Popup: Accept All / Skip / per-item ✅ Accept / ✕ Skip. Missing personnel → "→ Staff" button.

## 15.3 Racing World

- Tabs per discipline: GP, EPC, SC, OWC, TC, Rally, GK (prestige order)
- Player active championships shown expanded with driver standings + team standings
- GK: Shows current round, group standings for player’s group only, other groups as compact summary
- Non-active championships show "Not active this season" compact row

**⚠ BUG: GK group standings showing all teams not just the player’s group. Fix pending.**

## 15.4 Racing Hub & Calendar

- Racing Hub: My Drivers List · Next Events · My Cars Status · Weather Forecasts · Car Spare Parts · Fuel Levels · Tyre selection
- Calendar: Current Week and Events · Full Month · Upcoming Deadlines · Milestone Dates

# 16. ARCHITECTURE & PLANNED REFACTOR

*v4.0 — 2026-06-17 — NEW SECTION*

## 16.1 Current State

GameState.gd is currently 8000+ lines acting as data store, season manager, race simulator, notification system, financial calculator, and UI controller simultaneously. This causes the bulk of multi-season bugs.

## 16.2 Target Architecture

**Specialized files (data + logic for one domain):**

- SeasonLedger.gd — what is happening THIS season per team (cars, drivers, standings, financials, staff, sponsors, loans, resources, R&D, buildings)
- NextSeasonLedger.gd — what is planned for NEXT season per team (registered championships, planned cars, signed contracts, planned loans, planned R&D, buildings carry-over)
- RaceSimulator.gd — runs races, produces results
- GKDiscipline.gd — owns GK round progression (already exists)
- FinancialEngine.gd — weekly income/expenses for all teams
- ContractEngine.gd — negotiations, renewals, expiries

**Core controllers:**

- SeasonManager.gd — owns the season lifecycle, calls transition
- TeamManager.gd — owns team state, registrations, cars, drivers
- ChampionshipManager.gd — owns all 24 championships, standings

**Master controller:**

- GameState.gd — thin orchestrator. Holds references to all controllers. Exposes clean API to scenes.

## 16.3 Season Transition — Correct 15-Step Order

- 1. Finalise current season — award champion titles, archive to History
- 2. Prize money — distribute end-of-season prizes to all teams from standings
- 3. Resources carry over — CR, SP, FU, RP transfer as-is
- 4. R&D carry over — P1/P3 completed blueprints carry. P2 wiped. P4 always carry. P5 has season cycles, TBD.
- 5. CNC — jobs in progress are destroyed. Inventory of last season is destroyed
- 6. Buildings — levels carry. In-progress upgrades carry with weeks decremented.
- 7. Contract decrements — age drivers AND staff (S28: staff now age too), reduce contract_seasons_remaining by 1
- 8. Lifecycle (S28, §23 + §4.2): age-retirement (drivers rare→50, staff hard 65) = ERASE + History archive; free-agent decay (drivers only, 2 seasons unsigned → erase); NO staff free-agent rule
- 9. Academy — drivers turning 18 flagged for professional contract decision
- 10. Transfer market — planned signings from NextSeasonLedger activated
- 11. Bankruptcy check — 3 consecutive negative seasons → team dissolved
- 12. New teams — any teams created mid-season added to both ledgers, probably it is better all the new teams to start with the new season so to be written only in the NextSeasonLedger
- 13. Next Season → Current Season — planned **registrations** (from NextSeasonLedger, §23.1), cars, sponsors, loans become active. **Do NOT clear player_registered_championships — populate it from the ledger.**
- 14. Next Season Ledger clears — ready for new planning cycle, be  careful to check buildings and Special RnD that needs more than one season to complete, these cases must remain in the Next Season Ledger until their duration for completion is true for the current season
- 15. AI planning — all AI teams immediately start filling their NextSeasonLedger

**⚠ S28 — Registration is forward-planning only (§23.1): the player registers during the CURRENT season for the NEXT season, before the design deadline (§23.2). The transition must ACTIVATE ledger registrations, never wipe them. Car manufacturing has a delivery delay (§23.8).**

## 16.4 TDL reads both ledgers

- Current season: car needs repair, driver/mechanic not assigned, fuel/spares low, CNC job finishing soon
- Next season: championship registered but no car planned, driver contract expiring, entry fee deadline approaching, R&D needed before Race 1

## 16.5 Implementation Priority

- Phase 1: Build SeasonManager.gd — player team season transition (fixes bugs 11, 13, 14, 19, 23 from §21)
- Phase 2: Integrate NextSeasonLedger into TDL and registration flow
- Phase 3: Expand to ChampionshipManager and TeamManager
- Phase 4: Extract FinancialEngine and ContractEngine
- Phase 5: GameState becomes thin orchestrator
- The whole process will be done slowly so that we can decentralize everything. The optimal goal is to have 1 .gd file for every aspect of the game

# 17. CONFIRMED BUILD SEQUENCE

*v4.0 — 2026-06-17*

| **Feature / P#** | **Status** | **Session** | **Notes** |
| --- | --- | --- | --- |
| P1 — WRA Approval | ✅ DONE | S15 | Submit, wait, auto-approve |
| P2 — CNC Manufacturing | ✅ DONE | S15 | WRA-gated, blueprint-aware |
| P3 — Parts Installation | ✅ DONE | S15 | Garage install/remove |
| P4 — Supply Contracts | ✅ DONE | S15 | Weekly delivery, season penalties |
| P5 — Sponsors MVP | ✅ DONE | S15 | 3 types, CFO search, slot cap |
| P6 — Financial Dept | ✅ DONE | S16 | 3 tabs: Finances │ Sponsors │ CFO |
| P7 — Notification Buttons | ✅ DONE | S16 | Destination-based navigation |
| P8 — Exe Build v0.18 | ✅ DONE | S19 | External testing complete |
| P9 — Economy Balance Pass | ⏳ PENDING | — | After all functions finalized |
| P10 — Contract Negotiation | ✅ DONE | S16–S19 | Weekly rounds; driver/staff/sponsor; locks |
| P11 — Calendar System | ⏳ PENDING | — | Forward planning, player notes |
| P12 — CEO Job Market | ⏳ PENDING | — | Inbound + outbound. CEO market = all CEOs. |
| P13 — Main Hub Redesign | ⏳ PENDING | — | Full restructure per §15 |
| P14 — 2D Race Visualization | ⏳ PENDING | — | Bezier path, colored dots, overtake windows |
| P15 — News System | ⏳ PENDING | — | Procedural headlines. Required for AI teams to feel alive. |
| P16 — Market Share/Commercial Cars | ⏳ PENDING | — | See §18 |
| P17 — Procedural Portraits | ⏳ PENDING | — | Layered generation |
| P18 — New Game Flow | ✅ DONE | S16 | 6-screen setup |
| P19 — AI Teams Depth | ⏳ PENDING | — | Personality archetypes §3.7; seasonal heartbeat 2-4×/season; financial model §3.6 |
| P20 — Race Sim Depth | ⏳ PENDING | — | Practice, qualifying, race interaction per §14 |
| P21 — Begin/End of Season | ✅ DONE | S16 | Wired via pending_season_screen |
| P22 — Approach/Bond/Negotiation | ✅ DONE | S18–S19 | Full weekly system with locks |
| P23 — Track ID System | ✅ DONE | S16 | 247 races with track_id |
| P24 — Difficulty Multipliers | ✅ DONE | S19 | AI perf, player economy, player R&D |
| P25 — HQ Redesign | ✅ DONE | S16 | 3-tab layout |
| P26 — GK Championship Structure | ✅ DONE | S24–S26 | Single C-001; 4 progressive rounds; 21-race calendar; elimination logic |
| P27 — Championships Population | ✅ DONE | S23 | 120 AI teams via AIManager; grid filler disabled; CHAMP_MAP fixed |
| P28 — Race Rules & Systems | ⏳ PENDING | — | Per-discipline specifics. Rally time-trial. Temperature/tyre formula. |
| P29 — CFO Auto-buy CR/FU | ⏳ PENDING | — | Automate after a few seasons |
| P30 — Navigation Mapping | ⏳ PENDING | — | Back buttons rework |
| P31 — GK TP Auto-Assignment | ✅ DONE | S23 | TP proposals 1 week before race; popup; TDL + notification |
| P32 — Financial Graphs | ✅ DONE | S20 | Economy/Fuel/Fans/Balance/Merch/Rep |
| P33 — Driver/Staff Sorting | ✅ DONE | S19 | All attributes + Interested filter |
| P34 — Academy System Rework | ⏳ PENDING | — | Cadets 8-17 pay team; auto-fill; 1.15 contract rule |
| P35 — Part Knowledge Active | ⏳ PENDING | — | Impacts Feedback only, not driving. Drops over time. |
| P36 — Settings Screen | ⏳ PENDING | — | On entry screen |
| P37 — Choose Existing Team | ⏳ PENDING | — | Take over AI team at New Game |
| P38 — Demo Design | ⏳ PENDING | — | Scope and feature set TBD |
| P39 — Moddable Files List | ⏳ PENDING | — | teams.json + others. Defer to pre-release. |
| P40 — Intro Screen | ⏳ PENDING | — | Studio/title animation |
| P41 — Intro Video | ⏳ PENDING | — | Cinematic intro |
| P42 — Hot Seat Multiplayer (2+) | ⏳ PENDING | — | Architecture TBD |
| P43 — Online Multiplayer | FUTURE | — | Architecture TBD |
| P44 — Loan System | ✅ DONE | S20 | Tiers 1–5; mortgage; CFO discount |
| P45 — Team Cards | ⏳ PENDING | — | Visual team card with stats |
| P46 — Tooltips | ⏳ PENDING | — | All financial figures and building effects |
| P47 — Tutorial/Personal Assistant | ⏳ PENDING | — | AI-driven in-game advisor |
| P48 — Commercial Cars Blueprint | ⏳ PENDING | — | R&D Pillar 4; market cycle and decay |
| P49 — Notification Action Buttons | ⏳ PENDING | — | Custom nav button on notification card |
| P50 — History & Achievements | ⏳ PENDING | — | Driver titles, team records, named awards — see §19 |
| P51 — Transfer Market Ecosystem | ⏳ PENDING | — | One pool, all 120 teams compete, ~5000 drivers+staff. Highest priority. See §6 |
| P52 — Driver Attribute Rename | ⏳ PENDING | — | Rename "Wet" to more professional term. Decision needed. |
| P53 — Pre-Race Screen | ⏳ PENDING | — | Screen between qualifying and race start per algorithm flow |
| P54 — Track/Part Knowledge Decay | ⏳ PENDING | — | Both drop over time without racing. Part knowledge → Feedback only. |
| P55 — Financial Graph Time Selector | ⏳ PENDING | — | View by weeks / seasons / all time. P32 follow-up. |
| P56 — Fan Base Data Verification | ⏳ PENDING | — | Real-world comparison pass before release. |
| P57 — SeasonManager Refactor | ⏳ PLANNED | — | Phase 1 of architecture refactor. See §16. |
| P58 — Pit Crew Assignment UI | ⏳ PENDING | — | No current way to assign hired pit crew to a car. |
| P59 — Staff Screen Assignments | ⏳ PENDING | — | Staff screen assignments do not reflect new game assignments. |
| P60 — Auto-Repair from Mechanic | ⏳ PENDING | — | Mechanic should auto-repair assigned car between races. |

# 18. COMMERCIAL CARS (P16/P48 — Planned)

*v4.0 — 2026-06-17*

- Requires Vehicle Assembly Factory
- Market cycle: launch boom → steady sales → decay → refresh required (new model needed)
- Income scales with team reputation and marketability
- Some championships tier unlocks a vehicle segment for research
- 10 factory teams currently have market share assigned in Excel v2.6
- ⚠ Balance note: commercial car income values from Excel produce very high weekly income for factory teams. Full balance review required before implementing P16. We must disregard the weekly income in the code and focus on the expense of manufacture a certain amount of cars and sell accordingly. Simplified model for the AI teams but detailed for the player

## 18.1 Vehicle Segments (from Excel v2.6)

| **Segment** | **Avg MSRP** | **Margin per Unit** | **Global Annual Volume** | **Notes** |
| --- | --- | --- | --- | --- |
| Economy Hatchbacks | $21,750 | $8,500 | 22,000,000 | High volume |
| AWD Hot Hatches | $48,500 | $20,000 | 1,200,000 | Niche performance |
| Utility Pickups | $51,500 | $24,000 | 8,500,000 | Very strong N. America |
| Pony Cars | $46,000 | $20,500 | 450,000 | Mostly US market |
| Rally Replica Sedans | $53,500 | $21,000 | 350,000 | Niche |
| Track Day Specials | $102,500 | $47,500 | 80,000 | Very low volume |
| Entry Sports Cars | $33,750 | $13,500 | 850,000 | Accessible sports cars |
| V8 Sports Sedans | $81,500 | $36,500 | 650,000 | Declining segment |
| Supercars | $335,000 | $185,000 | 35,000 | Low volume high margin |
| EV Hybrid Flagships | $145,000 | $68,000 | 1,800,000 | Fast growing |
| Bespoke Hypercars | $2,500,000 | $1,575,000 | 800 | Extremely low volume |
| Limited Run Megacars | $5,500,000 | $3,150,000 | 300 | Ultra exclusive |

Weekly Sales = Base Market Demand × Marketability Multiplier × Brand Prestige

Revenue = Units Sold × Margin Per Unit (in this formula the percentage of the market share is not taken into account, at least not obviously)

# 19. HISTORY & ACHIEVEMENTS (P50 — Planned)

*v4.0 — 2026-06-17*

## 19.1 Seasonal Records

- Team Champion per championship every season
- Driver Champion per championship every season
- Clean historical archive, season by season

## 19.2 Driver Achievements

| **Achievement** | **Description** | **Prestige** |
| --- | --- | --- |
| Triple Crown Winner | Monaco equiv. + 24h Le Mans (Hypercar) + Indianapolis 500 | Very High |
| Grand Slam Driver | Win championship + biggest race same season | High |
| Rookie of the Year | Most points among all rookies in a top-tier championship | Medium |
| Most Successful Driver | Record for most total championships won | Very High |
| Iron Man | Complete every race of a season without missing any | Medium |
| Youngest/Oldest Champion | Win top-tier championship at youngest/oldest age | High/Medium |
| Most Dominant Season | Win championship with very large points margin | High |
| Comeback Driver of the Year | Win after finishing outside top 10 previous season | High |
| The Complete Driver | Win on ovals, street circuits, and road courses in one season | High |

## 19.3 Team & Constructor Achievements

| **Achievement** | **Description** | **Prestige** |
| --- | --- | --- |
| Most Successful Team | Most total championships across all disciplines | Very High |
| Constructor's Triple Crown | Win top championship in Formula, Endurance, Stock Car one season | Very High |
| Most Dominant Team | Most races won in a single season across all championships | High |
| Best Academy | Most drivers from academy win races or championships | Medium |
| Technological Leader | Highest performance rating car in a top-tier championship | High |
| Global Empire | Win at least one championship in 5 different disciplines | High |
| The Rebuilders | Near-bankruptcy team that wins a championship | High |
| Most Championships in a Decade | Most titles in any 10-season period | Very High |

## 19.4 Legendary Achievements

| **Achievement** | **Description** | **Notes** |
| --- | --- | --- |
| Legend of the Sport | Driver won championships in 4+ different disciplines | True all-rounder |
| The GOAT | Driver holds multiple all-time records | Ultimate status |
| The Team That Built an Era | Team dominated one discipline for 5+ seasons | Dynasty |
| The Complete Empire | Team won at least one title in every single discipline | Extremely hard |
| The People's Champion | Driver wins championship with a small/privateer team | Underdog |

# 20. CONFLICT RESOLUTIONS LOG

*v4.0 — 2026-06-17*

| **#** | **Conflict** | **Resolution** | **Source of Truth** | **Action** |
| --- | --- | --- | --- | --- |
| C1 | F3 min cars: Brainstorming=3, Excel=2 | Min = 2, Max = 3 | Excel | Fix Brainstorming |
| C2 | LMP3 missing from Brainstorming team matrix | LMP3 = EPC Series, full championship | GDD | Add to Brainstorming |
| C3 | Rally points: Code used 25, should use 18 | 18-15-13 for all Rally | Excel ✅ FIXED | Code fixed S23 |
| C4 | CEO salary: Brainstorming=5%, GDD=1% | 1% of weekly net profit | GDD | Brainstorming wrong |
| C5 | NASCAR Cup Gearbox/Susp/Brakes: Excel=Open, GDD=Spec | Spec for all three | GDD ✅ FIXED | Code fixed S23 |
| C6 | ARCA Gearbox/Chassis: Excel=Spec, Brainstorming=Open | Excel is correct | Excel (GameState) | Brainstorming wrong |
| C7 | GK National Brakes: Excel=Spec, Brainstorming=Open | Spec | GDD (Excel) | Brainstorming wrong |
| C8 | GK Continental optimum: Brainstorming=150, Excel=250 | Now 640 for single GK Championship | GDD v4.0 | Resolved by consolidation |
| C9 | Rally sim: positional vs time-trial | Keep positional for now. Time-trial = P28. | P28 scope | Noted |
| C10 | Academy age: 8 vs 15 vs 16 — three sources | All cadets 8-17 inclusive. No 15+ split. | Excel ✅ CONFIRMED | GDD updated |
| C11 | Real team names vs fictional | Fictional names final. No mapping needed. | Code | AIManager is truth |
| C12 | GK 4-tier vs single championship | Single GK Championship C-001 with 4 progressive rounds | GDD v4.0 ✅ | Implemented S24-S26 |
| C13 | Professional drivers with GK discipline | Old 4-tier GK pros removed from drivers_professional.json | GDD v4.0 ✅ | Fixed S26 |
| C14 | Building maintenance: level×base vs base+increment | level × base_maintenance (Excel formula) | Excel v2.6 | Confirmed S26 |
| C18 | WRC sim mode: no wheel-to-wheel vs positional | Time-trial deferred to P28. | P28 scope | Noted |
| C20 | Indy NTT end-season prize | $10,500,000 for 1st | Excel | Confirmed in code |

# 21. OPEN BUGS & KNOWN GAPS

*v4.0 — 2026-06-17*

| **Issue** | **File(s)** | **Priority** | **P# / Scope** |
| --- | --- | --- | --- |
| Season 2 GK has no drivers — cadets disappearing | GameState.gd, GKDiscipline.gd | CRITICAL | P57 |
| ~~DRV-XXXX filler drivers populating championships Season 2+~~ ✅ FIXED S28 | SeasonManager.gd | ~~CRITICAL~~ DONE | P57 — lifecycle rewrite removed the respawn loop |
| Driver contract renewed but disappeared at Season 2 | GameState.gd | CRITICAL | P57 |
| Season 2 registration not recognized — "0 championships registered" | GameState.gd, BeginOfSeason.gd | CRITICAL | P57 |
| Logistics shows GK car in Season 3 despite only Rally4 registered | Logistics.gd, GameState.gd | CRITICAL | P57 |
| Staff screen assignments do not match new game assignments | StaffHub.gd | High | P59 |
| GK group standings show ALL teams not just player group | RacingWorld.gd | High | P26 |
| HQ Financial Dept — Balance title always visible, mixes with other tabs | HQ.gd | High | P55 |
| Active fans exploding to 918k in 32 weeks in GK | GameState.gd | High | P9 |
| Player driver dominating with 15-second gap to 2nd | GameState.gd race sim | High | P9 |
| Contract negotiations not triggering automatically | ContractNegotiation.gd | High | P22 |
| No automatic car repairs from mechanic on assigned car | Garage.gd, GameState.gd | High | P60 |
| Designer accumulating RP from non-participating championships | GameState.gd | High | P20 |
| CNC part install button broken | CNCPlant.gd, Garage.gd | High | P2/P3 |
| Rally4 registration triggers wrong notifications; missing pit crew warning | GameState.gd | High | P57 |
| No way to assign hired pit crew to a car | Garage.gd, StaffHub.gd | High | P58 |
| End of season financial screen showing wrong weekly profit (-40,500) | EndOfSeason.gd | High | P21 |
| GK champion not visible on end of season screen | EndOfSeason.gd | Medium | P21 |
| GK team standings not reset between rounds | GKDiscipline.gd | Medium | P26 |
| Incorrect "advancing to 5th round" notification (only 4 rounds) | GameState.gd | Medium | P26 |
| TP proposals triggering every racing week instead of 1 week before race | GameState.gd | Medium | P31 |
| WRA blueprint approval taking longer than 1 week | GameState.gd WRA | Medium | P1 |
| Previous season CNC blueprint not scrapping on season transition | GameState.gd, CNCPlant.gd | Medium | P2 |
| Difficulty multipliers not wired into race sim | GameState.gd | High | P9 |
| Economy balance pass not done — prize money floors, salary scaling | GameState.gd | High | P9 |
| Transfer market (P51) not built — AI teams don’t compete for players/staff | AIManager.gd | High | P51 |
| Track knowledge and part knowledge decay not implemented | GameState.gd | Medium | P54 |
| Rally race simulation uses positional formula instead of time-trial | GameState.gd | Medium | P28 |
| News system (P15) not built — AI world is silent | New file needed | Medium | P15 |
| Team colors not displayed in HQ badge | HQ.gd, GameState.gd | Medium | — |
| Drivers/Staff screen lag — deferred as agreed | Drivers.gd, StaffHub.gd | Later | P33 |
| "Wet" attribute needs professional rename | GameState.gd, Driver.gd | Low | P52 |
| Pre-Race screen missing from race weekend flow | New scene needed | Low | P53 |
| Financial graph time range selector not implemented | FinancialDept.gd | Low | P55 |
| Fan base numbers need real-world data verification | GameState.gd | Low | P56 |
| Staff free-agent pool drains over time — needs per-season top-up | StaffManager.gd | Medium | P19/P51 |
| Season transition wrongly clears registrations / makes car decisions before BeginOfSeason | SeasonManager.gd | CRITICAL | P57 / §23 |
| NextSeasonLedger registration model (§23.1) not implemented | SeasonManager.gd, BeginOfSeason.gd | CRITICAL | P57 / §23 |
| Car manufacturing delivery delay + P2/P3 gating (§23.8) not implemented | CarManager.gd, RnDEngine.gd, Logistics.gd | High | §23 |
| Design/registration deadlines: −1 week WRA shift + GP1 engine lead (§23.2–3) not implemented | RnDEngine.gd, GameState.gd | High | §23 |
| DNS-until-car-ready (§23.5) not implemented | RaceSimulator.gd | High | §23 |

*Automotive Empire GDD v4.1 — 2026-06-17 — **andreasmrg**-droid/**AutomotiveEmpire*

*Update this document at the end of every session.*


# 22. Manual Additions

- The engine is updated to Godot 4.6.3
- It seems that the released personnel do not go free agents but deleted immediately, they must stay in the free agent pool for 2 seasons and if they are not hired after 2 seasons then erase them totally
- Rally: Practice and qualifying will  be done in stage 1. No power stage. The starting grid of the race is reversed qualifying, worst time starts 1st
- When we will be building the race weekends of every championship, we will discuss it step by step, we will use different file per championship
- For filling the gaps if needed for the GK, we will create a team called “Amateur Drivers”. We will generate the drivers inside this team. This team will have different rules, it will be no dependent to the rules of the other teams, so no buildings required, the car that will use will have low stats and the. 
- The filling of the gaps will be done only to satisfy the minimum required cars for a championship. For all the other championships apart from the GK, normal team will be created that follow the normal rules of the game
- News, Notifications and TDL repeat themselves, we need to optimize them
- Marketability buffer during DNFs and DNS for all commercial buildings
- SeasonManager, FinancialEngine, RaceSimulator, ContractEngine, RnDEngine, NotificationManager, CampusManager, SponsorManager, StaffManager, CarManager, driver manager, TPProposalEngine extractions, P57 Phase 1 & 2 complete
- no driver/staff is eliminated just like this, 2 rules: 1 is retirement due to age and 2nd the drivers remains 2 seasons free agent. Also, remove this fillers with name DRV-XX, they are unrealistic, we have a name generator file produce names.
- staff retirement at 65. no free agent rule for staff. extend the age of retirement of drivers to 50 since there are some that racing in TC, but make it rare. Retirement is game over.
- driver/staff lifecycle rules (§4.2 retirement to 50 rare / staff 65, §22 free-agent 2-season decay confirmed in code) and mark Bug 2 (DRV-XXXX fillers) as fixed in §21.
- staff free-agent pool needs a per-season replenish so retirements don't drain it.

# 23. SEASON LIFECYCLE, REGISTRATION & CAR MANUFACTURING RULES

*v4.1 — 2026-06-17 — NEW SECTION (S28). Formalises the forward-planning registration model, design/WRA deadlines, car manufacturing delivery delay, and the player-only R&D burden. Cross-references §8 (WRA), §10 (R&D), §14 (DNS), §16.3 (Season Transition).*

## 23.1 Forward-Planning Registration (NextSeasonLedger)

**✅ CONFIRMED v4.1 — 2026-06-17**

There is **no re-registration at the start of a season**. The player always registers **during the current season for the *next* season**, before the registration deadline. Registrations are stored in the **NextSeasonLedger** and become active when the season rolls over (§16.3 Steps 13–14).

- The player is never prompted to re-register in BeginOfSeason — they already registered last season.
- BeginOfSeason is a status/summary screen, not a registration screen.
- Cleared registrations are wrong: `player_registered_championships` for the new season is populated from the NextSeasonLedger at transition, not emptied.

## 23.2 The Registration Deadline = The Design Deadline

**✅ CONFIRMED v4.1**

The registration deadline is the **last moment to design the car's parts** for next season, so that:

1. By the end of the current season, all blueprints are finished.
2. Blueprints pass to CNC and are ready to start building cars at the beginning of next season.

Therefore the deadline is gated by the **longest part to develop** for that championship's car (the slowest component sets the lead time).

- **GP1 has the longest deadline** because the **engine** is the lengthiest part to develop.
- Lead times per part/championship come from the **Excel file** (authoritative numbers).

## 23.3 Deadlines Move 1 Week Earlier (WRA Approval)

**✅ CONFIRMED v4.1 — CHANGE**

All registration/design deadlines shift **1 week earlier** than the raw design lead time, to leave room for **WRA approval of next-season regulations** (§8). The WRA approval week is now part of the deadline math, not an afterthought.

## 23.4 R&D + WRA Must Complete Within the Current Season

**✅ CONFIRMED v4.1**

- Both the **R&D design** and the **WRA approval** for next season's car **must finish within the current season**.
- If either does not finish in time → **the blueprints are lost** (not carried, not partially credited).
- This is the hard consequence that makes the deadline meaningful.

## 23.5 DNS Until the Car Is Ready

**✅ CONFIRMED v4.1**

If the team has not manufactured the car in time for a race, the car produces a **DNS (Did Not Start)** for that race **until the car is ready** — applied race-by-race, not as a whole-season write-off. Once the car is delivered/built, the car races normally from that point.

## 23.6 Buying a Car Bypasses the Design Chain (but not the delivery delay)

**✅ CONFIRMED v4.1**

If the player **buys a car from another team** (a "factory team" / provider), they do **not** go through the design/WRA/deadline chain. The selling factory team is assumed to follow all deadlines.

- The buyer skips P1 design, WRA approval, and the design deadline entirely.
- The buyer **still** waits for the manufacturing **delivery delay** (§23.8).

## 23.7 Player-Only Design Burden

**✅ CONFIRMED v4.1**

The entire design-deadline / WRA-in-season / blueprint-loss burden (§23.2–§23.5) applies to the **PLAYER's own team only**. **AI teams do not** go through this R&D-before-deadline pressure — their cars are assumed ready per the simulation. *(Add to GDD: this asymmetry is intentional, mirrors §3.7 simplified-AI philosophy.)*

## 23.8 Car Manufacturing Delivery Delay (Anti-Exploit)

**✅ CONFIRMED v4.1**

When the player **buys/manufactures a car from the Logistics Center** at the start of a season, it is **not delivered instantly**.

- **Delivery time = the longest manufacturing time among the car's parts** (from the Excel file) — same "slowest part gates it" logic as the design deadline.
- Example: a GP1 car (engine = longest) takes the full lead time; a GK car is quick.

**Purpose — anti-exploit:** prevents buying a car in Week 1 and immediately starting R&D Pillar 2 on a car that will not physically exist until (e.g.) Week 8.

**What is allowed vs gated between "purchase" and "delivery":**

| Action | Allowed before delivery? |
| --- | --- |
| Assign drivers to the car | ✅ Yes — from the moment of purchase |
| Assign staff (mechanic/strategist) to the car | ✅ Yes — from the moment of purchase |
| R&D Pillar 1 (Design) | ✅ Yes — general R&D, no physical car needed |
| R&D Pillar 4 (Special Projects) | ✅ Yes — general R&D, no physical car needed |
| R&D Pillar 5 (Commercial Cars, future) | ✅ Yes — general R&D, no physical car needed |
| **R&D Pillar 2 (Upgrade)** | ❌ **Gated until delivery** — needs the physical car's stats |
| **R&D Pillar 3 (Reverse Engineering)** | ❌ **Gated until delivery** — needs the physical car to reverse-engineer |

**Rule of thumb:** Pillars that need a **physical car instance** (read its current stats) are gated until delivery: **P2 and P3**. General R&D (**P1, P4, P5**) is never gated. This delivery-delay/R&D-gate is a **player-only team-R&D rule**.

## 23.9 Cars Wiped Each Season (unchanged)

**✅ CONFIRMED v4.1** — Cars are still **wiped each season** (§16.3 Step 5). Each new season the player either manufactures from blueprints prepared last season, or buys a car. Driver/staff are assigned to cars; cars participate in championships.

S28.0 — Driver/Staff Lifecycle (§4.2, §22)

Removed the is_eligible_for_gk_regional() delete-and-respawn loop that wiped every adult AI driver each off-season and spawned age-8 DRV/D-GEN fillers into Rally/GP. (Bug 2 — fixed.)
Two retirement rules only: age retirement (drivers rare→50, staff hard 65) and free-agent decay (drivers unsigned 2 seasons → erased; no decay for staff).
Retirement = permanent erase + archived to retired_personnel (for History/News), name released.
Staff now age each off-season (they were frozen before).
seasons_without_contract only accrues while uncontracted; resets when signed.
Files: SeasonManager.gd, GameState.gd.

S28.1 — NextSeasonLedger Registration Model (§16.3, §23.1) — the big one

Root cause of the Season-2 car/registration collapse: start_new_season() was clearing registrations instead of carrying them.
Added next_season_registrations (the ledger). Registration now writes here (tagged for next season), not into the current race set.
At season transition: activate ledger → player_registered_championships, then clear ledger (GDD §16.3 steps 13-14). Never blind-wiped.
Discovered & fixed: registrations were never being saved/loaded — now both arrays persist.
Starting championship explicitly registered for S1.
Registration deadline shifted −1 week for WRA approval (§23.3).
Stale TP proposals + stale TDL items cleared at transition (shots 12, 14).
Removed Logistics' hardcoded ["C-001"] GK fallback (the literal line that showed only GK).
Files: GameState.gd, SeasonManager.gd, Logistics.gd, MainHub.gd (+ ChampionshipSelect.gd ledger-aware).

S28.2 — UI/Performance & Display Fixes

Drivers.gd & StaffHub.gd: search box + pagination (25/page) — renders one page instead of hundreds of rows. Fixes the lag.
HQ-WRA panel: split into "Racing this Season" (full requirement checklist) + "Planned for Season N+1" (compact ledger rows). Fixes the current-vs-next mislabel and the lag.
MainHub TDL: wrapped in a 220px scrollable container so it can't push action buttons off-screen (shot 5).
ChampionshipSelect: removed misleading "Re-register" label (GK was never actually pre-registered for S2).
BeginOfSeason: "Championships This Season" now reads the registered race set, not owned cars (was falsely showing "none registered" at season start since cars are wiped then).

§21 bug-table updates to make:

✅ DRV-XXXX fillers (Bug 2) — FIXED S28.0
✅ Season-2 registration/car collapse — FIXED S28.1
✅ Drivers/Staff/WRA lag — FIXED S28.2
✅ TDL pushing buttons off-screen — FIXED S28.2

Still open / deferred (add to known-gaps):

GK champion not displayed on EndOfSeason (standings rollup bug) — not yet touched.
Staff free-agent pool top-up — pool drains over many seasons with no replenish.
Full Locale.t() localization of the S28-touched files (they mostly use raw strings; codebase mid-localization).
# Automotive Empire — GDD Update Block (Session S28.3)

**Paste this into your manual-additions section of `Automotive_Empire_GDD_v4_2.md`, then bump the doc to v4.3.**
Author: Andreas Maragkos · Session S28.3 · 2026-06-18

---

## 1. Changelog — what was done in S28.3

S28.3 was a bug-fix and systems pass covering the 8-bug list plus several issues found live via screenshots. Grouped by batch:

### Batch A — GK cluster + round notification
- **GK champion now derivable & displayed.** `GKDiscipline.gd` gained `get_champion()` (top driver of the final round) and `is_complete()`. EndOfSeason now reads GK standings from `GKDiscipline` (champion + final-round group standings) instead of the empty `champ.standings`.
- **No more "advancing to Round 5".** Round 4 is the final; on completion the game announces the champion instead of a non-existent Round 5.
- **GK team standings reset between rounds.** `_sync_gk_group0_to_standings()` now clears `team_standings` each round (was accumulating).
- **RacingWorld "Your Group"** reads the player's group from `GKDiscipline.get_standings()` (was using `champ.standings`, which could show all teams); other-groups grid skips the player's own group index.

### Batch B — quick wins
- **"Wet" → "Car Control".** All driver-stat UI labels relabeled "Car Control" / "Ctrl" (data field was already `car_control`; `wet` remains a save-compat alias). Touched: Drivers, HQ, RacingDept, MainHub, Garage, EndOfSeason. (Weather "WET" in race results intentionally left alone.)
- **EndOfSeason weekly profit removed.** The "Weekly Profit" line was `balance − _prev_week_balance`, which spanned the season transition and produced garbage (e.g. −40,500). Removed; Weekly Expenses (accurate) kept. *TODO: real Season-Net P&L once a season-start-balance tracker exists.*
- **Team colors.** Added a team-coloured badge to the HQ header, AND fixed team colors never being saved/loaded (stored as hex via `to_html()`, loaded with `Color()`).

### Bug 7 — staff free-agent pool top-up
- `StaffManager.replenish_free_agent_pool()` runs each season after retirements, topping up uncontracted staff to per-role minimums (Mechanic/PitCrew 8, TP/CFO 4, Designer 6, Strategist 5). Wired into `SeasonManager` off-season processing.

### CNC system fixes (found live)
- **CNC "Install" did nothing — fixed.** Root cause: a key mismatch. Parts whose blueprint lacked a `part_code` were stored under a bare-name key (`"Suspension"`) instead of the canonical `"C-001|SUS"`; the popup found them but `install_part_on_car` rebuilt the strict key and silently failed. `install_part_on_car` now falls back to the same matching-scan the popup uses. Verified headlessly.
- **Garage install buttons** now check the return value: only close the popup on success, and show a failure notice otherwise (so a silent no-op can never look like a dead button again).
- **Logistics warehouse** now shows CNC-manufactured parts (read-only section "Available Parts (CNC)" with name, qty, reliability, quality).

### Issues found via screenshots (S28.3 late)
- **WRA approval shortened by 1 week (§23.3).** `WRA_APPROVAL_WEEKS` `{1:2,2:3,3:5,4:6}` → `{1:1,2:2,3:4,4:5}`. GK (tier 1) now approves in 1 week as the "Submit" panel expects.
- **TDL "submit blueprint" routes to the WRA tab.** Was setting `pending_hq_tab = "wra_office"`, but HQ's tab key is `"wra"` → it fell through to Overview. Fixed.
- **CNC production slots implemented.** Production was decrementing every queued job in parallel (no slot limit). Now `get_cnc_slots()` derives the parallel-slot count from the CNC Plant level (uses the existing `CNC_SLOTS_PER_LEVEL` table: L1=1, L2=2, …). Jobs beyond the slot count **queue** and only start when a slot frees — so a 3rd part takes longer, not just costs more. Verified headlessly (2 slots, three 2-week jobs → 3rd finishes week 4, not week 2). CNCPlant UI shows slot count, marks "QUEUED" jobs, and gives slot-aware ETAs.
- **TP proposals refresh to 0 after accepting.** `apply_tp_proposals()` now regenerates the cached `_last_tp_proposals`, so the Racing Department count drops correctly (was showing stale cached proposals).
- **Crash fixed: `teamwork` stat.** Pit Crew `teamwork` was removed in the S28 staff overhaul (replaced by `fatigue_resistance`) but `PitCrewArena.gd` and `StaffHub.gd` still referenced it — a hard crash on the Pit Crew Arena and a latent crash on the StaffHub Pit Crew detail. All references migrated to `fatigue_resistance`.
- **False "assign driver/mechanic" notifications at new game — fixed.** `_give_starting_assets()` called `add_car()` (which fired "assign driver/mechanic/pit crew" notifications + TP proposals) BEFORE assigning the staff in the following steps, so the warnings were stale. `add_car()` gained a `silent` flag; new-game setup creates the car silently then assigns everyone. SC/GP/Rally starts auto-assign a pit crew too, so a fresh game starts clean.

---

## 2. Files changed in S28.3 (18 total — deploy all at these paths)

**autoloads/**
- GameState.gd

**resources/scripts/**
- GKDiscipline.gd, SeasonManager.gd, StaffManager.gd, CarManager.gd, RnDEngine.gd, TPProposalEngine.gd

**scenes/**
- Drivers.gd, EndOfSeason.gd, MainHub.gd, RacingWorld.gd, StaffHub.gd

**scenes/buildings/**
- HQ.gd, Garage.gd, Logistics.gd, CNCPlant.gd, PitCrewArena.gd, RacingDept.gd

> Note: GameState, MainHub, StaffHub, RacingDept appeared in multiple batches this session — the delivered copies are the cumulative latest. Use these, not any earlier copies.

---

## 3. §21 bug-table updates (mark these resolved)

Move to DONE / strike through:
- GK champion not visible on end of season screen — **DONE S28.3**
- GK group standings show ALL teams not just player group — **DONE S28.3**
- GK team standings not reset between rounds — **DONE S28.3**
- Incorrect "advancing to 5th round" notification — **DONE S28.3**
- "Wet" attribute needs professional rename — **DONE S28.3** (UI labels → "Car Control")
- End of season financial screen showing wrong weekly profit (−40,500) — **DONE S28.3** (line removed; Season-Net P&L still TODO)
- Team colors not displayed in HQ badge — **DONE S28.3**
- Staff free-agent pool drains over time — **DONE S28.3**
- CNC part install button broken — **DONE S28.3**
- WRA blueprint approval taking longer than 1 week — **DONE S28.3** (§23.3 −1 week shift applied)
- TP proposals triggering / not refreshing — **DONE S28.3** (refresh-to-0 fixed; note: the "fire 1 week before race" timing is separate, still open)

Still partially open / reworded:
- "No automatic car repairs from mechanic on assigned car" — **still open** (part of Bug 6 below)
- "No way to assign hired pit crew to a car (in Garage)" — **still open** (Bug 6 below)
- "Contract negotiations not triggering automatically" — **still open** (Bug 8 below)

---

## 4. §23 confirmation needed (CNC slots rule)

The CNC production-slot rule now uses `CNC_SLOTS_PER_LEVEL = {1:1, 2:2, 3:3, … 9:9}` (slots = plant level). **Please confirm or revise this mapping in the GDD** — it was implemented from your verbal spec ("L2 = 2 slots"), not from an existing written rule. If the intended curve is different (e.g. slots cap at some level, or scale non-linearly), update the constant in `GameState.gd` and note it in §23.

---

## 5. NEXT SESSION — what's queued

### Immediately pending (the last 2 of the original 8-bug list)
- **Bug 6 — Pit Crew assignment in the Garage + auto-repairs.**
  - Garage currently only has DRIVER and MECHANIC slots; the car has a `pit_crew_id` field but no UI to set it (only the Pit Crew Arena assigns crews). Add a pit-crew slot + popup mode in `Garage.gd`, plus `assign_pit_crew` / `unassign_pit_crew` in `CarManager`/`GameState` (mirror the mechanic functions).
  - Auto-repairs: the assigned mechanic should repair the car post-race automatically.
  - Files: Garage.gd, CarManager.gd, GameState.gd.
- **Bug 8 — Contract negotiations not triggering automatically.**
  - Investigate `ContractEngine.gd` / `ContractNegotiation.gd` — negotiations aren't auto-firing when they should.

### Still-open issue from this session
- **Issue 1 follow-up:** the false-notification fix is in, but if any "assign driver/mechanic" warning still shows on a fully-staffed car after a fresh game, capture the exact text + when (bell vs TDL) so the remaining trigger can be pinned.
- **TP proposal *timing*:** proposals should fire ~1 week before a race, not every racing week (separate from the refresh-to-0 fix already done).

### The agreed economy roadmap (after bugs 6 & 8)
Build all economic systems first, derive balance numbers as outputs, race sim last:
- **Phase 2 — §23 car system:** delivery delay, P2/P3 gating until car delivered, DNS-until-car-ready, GP1 engine lead time, design/registration deadlines. (Classified as ECONOMY, not race.) Only the −1 week WRA shift is in so far.
- **Phase 3 — Commercial factory + R&D Pillar 5.** Adds the second weekly income engine (commercial car sales) so the game is playable without the race.
- **Phase 4 — Stock market.**
- **Phase 5 — Multi-season balance pass:** once all income sources exist, derive AI-team budgets and team-character spending as system outputs; stress-test with headless sims (Python ports of the economy engines) + real Godot playtests. Targets to chase here: the "active fans exploding to 918k" curve, prize-money floors, salary scaling.
- **Then:** drop the race sim into the stable, balanced economy.

### Design constraint carried forward
Keep economic logic in pure `RefCounted` engine classes (testable headless), not in UI scripts — so each new engine (commercial, stock market) can be Python-stress-tested for multi-season drift before it ships.

---

## 6. Reminder
After pushing, bump the GDD header to **v4.3** and commit the doc alongside the 18 code files.
# Automotive Empire — GDD Update Block (Session S28.3)

**Paste this into your manual-additions section of `Automotive_Empire_GDD_v4_2.md`, then bump the doc to v4.3.**
Author: Andreas Maragkos · Session S28.3 · 2026-06-18

---

## 1. Changelog — what was done in S28.3

S28.3 was a bug-fix and systems pass covering the 8-bug list plus several issues found live via screenshots. Grouped by batch:

### Batch A — GK cluster + round notification
- **GK champion now derivable & displayed.** `GKDiscipline.gd` gained `get_champion()` (top driver of the final round) and `is_complete()`. EndOfSeason now reads GK standings from `GKDiscipline` (champion + final-round group standings) instead of the empty `champ.standings`.
- **No more "advancing to Round 5".** Round 4 is the final; on completion the game announces the champion instead of a non-existent Round 5.
- **GK team standings reset between rounds.** `_sync_gk_group0_to_standings()` now clears `team_standings` each round (was accumulating).
- **RacingWorld "Your Group"** reads the player's group from `GKDiscipline.get_standings()` (was using `champ.standings`, which could show all teams); other-groups grid skips the player's own group index.

### Batch B — quick wins
- **"Wet" → "Car Control".** All driver-stat UI labels relabeled "Car Control" / "Ctrl" (data field was already `car_control`; `wet` remains a save-compat alias). Touched: Drivers, HQ, RacingDept, MainHub, Garage, EndOfSeason. (Weather "WET" in race results intentionally left alone.)
- **EndOfSeason weekly profit removed.** The "Weekly Profit" line was `balance − _prev_week_balance`, which spanned the season transition and produced garbage (e.g. −40,500). Removed; Weekly Expenses (accurate) kept. *TODO: real Season-Net P&L once a season-start-balance tracker exists.*
- **Team colors.** Added a team-coloured badge to the HQ header, AND fixed team colors never being saved/loaded (stored as hex via `to_html()`, loaded with `Color()`).

### Bug 7 — staff free-agent pool top-up
- `StaffManager.replenish_free_agent_pool()` runs each season after retirements, topping up uncontracted staff to per-role minimums (Mechanic/PitCrew 8, TP/CFO 4, Designer 6, Strategist 5). Wired into `SeasonManager` off-season processing.

### CNC system fixes (found live)
- **CNC "Install" did nothing — fixed.** Root cause: a key mismatch. Parts whose blueprint lacked a `part_code` were stored under a bare-name key (`"Suspension"`) instead of the canonical `"C-001|SUS"`; the popup found them but `install_part_on_car` rebuilt the strict key and silently failed. `install_part_on_car` now falls back to the same matching-scan the popup uses. Verified headlessly.
- **Garage install buttons** now check the return value: only close the popup on success, and show a failure notice otherwise (so a silent no-op can never look like a dead button again).
- **Logistics warehouse** now shows CNC-manufactured parts (read-only section "Available Parts (CNC)" with name, qty, reliability, quality).

### Issues found via screenshots (S28.3 late)
- **WRA approval shortened by 1 week (§23.3).** `WRA_APPROVAL_WEEKS` `{1:2,2:3,3:5,4:6}` → `{1:1,2:2,3:4,4:5}`. GK (tier 1) now approves in 1 week as the "Submit" panel expects.
- **TDL "submit blueprint" routes to the WRA tab.** Was setting `pending_hq_tab = "wra_office"`, but HQ's tab key is `"wra"` → it fell through to Overview. Fixed.
- **CNC production slots implemented.** Production was decrementing every queued job in parallel (no slot limit). Now `get_cnc_slots()` derives the parallel-slot count from the CNC Plant level (uses the existing `CNC_SLOTS_PER_LEVEL` table: L1=1, L2=2, …). Jobs beyond the slot count **queue** and only start when a slot frees — so a 3rd part takes longer, not just costs more. Verified headlessly (2 slots, three 2-week jobs → 3rd finishes week 4, not week 2). CNCPlant UI shows slot count, marks "QUEUED" jobs, and gives slot-aware ETAs.
- **TP proposals refresh to 0 after accepting.** `apply_tp_proposals()` now regenerates the cached `_last_tp_proposals`, so the Racing Department count drops correctly (was showing stale cached proposals).
- **Crash fixed: `teamwork` stat.** Pit Crew `teamwork` was removed in the S28 staff overhaul (replaced by `fatigue_resistance`) but `PitCrewArena.gd` and `StaffHub.gd` still referenced it — a hard crash on the Pit Crew Arena and a latent crash on the StaffHub Pit Crew detail. All references migrated to `fatigue_resistance`.
- **False "assign driver/mechanic" notifications at new game — fixed.** `_give_starting_assets()` called `add_car()` (which fired "assign driver/mechanic/pit crew" notifications + TP proposals) BEFORE assigning the staff in the following steps, so the warnings were stale. `add_car()` gained a `silent` flag; new-game setup creates the car silently then assigns everyone. SC/GP/Rally starts auto-assign a pit crew too, so a fresh game starts clean.

---

## 2. Files changed in S28.3 (18 total — deploy all at these paths)

**autoloads/**
- GameState.gd

**resources/scripts/**
- GKDiscipline.gd, SeasonManager.gd, StaffManager.gd, CarManager.gd, RnDEngine.gd, TPProposalEngine.gd

**scenes/**
- Drivers.gd, EndOfSeason.gd, MainHub.gd, RacingWorld.gd, StaffHub.gd

**scenes/buildings/**
- HQ.gd, Garage.gd, Logistics.gd, CNCPlant.gd, PitCrewArena.gd, RacingDept.gd

> Note: GameState, MainHub, StaffHub, RacingDept appeared in multiple batches this session — the delivered copies are the cumulative latest. Use these, not any earlier copies.

---

## 3. §21 bug-table updates (mark these resolved)

Move to DONE / strike through:
- GK champion not visible on end of season screen — **DONE S28.3**
- GK group standings show ALL teams not just player group — **DONE S28.3**
- GK team standings not reset between rounds — **DONE S28.3**
- Incorrect "advancing to 5th round" notification — **DONE S28.3**
- "Wet" attribute needs professional rename — **DONE S28.3** (UI labels → "Car Control")
- End of season financial screen showing wrong weekly profit (−40,500) — **DONE S28.3** (line removed; Season-Net P&L still TODO)
- Team colors not displayed in HQ badge — **DONE S28.3**
- Staff free-agent pool drains over time — **DONE S28.3**
- CNC part install button broken — **DONE S28.3**
- WRA blueprint approval taking longer than 1 week — **DONE S28.3** (§23.3 −1 week shift applied)
- TP proposals triggering / not refreshing — **DONE S28.3** (refresh-to-0 fixed; note: the "fire 1 week before race" timing is separate, still open)

Still partially open / reworded:
- "No automatic car repairs from mechanic on assigned car" — **still open** (part of Bug 6 below)
- "No way to assign hired pit crew to a car (in Garage)" — **still open** (Bug 6 below)
- "Contract negotiations not triggering automatically" — **still open** (Bug 8 below)

---

## 4. §23 confirmation needed (CNC slots rule)

The CNC production-slot rule now uses `CNC_SLOTS_PER_LEVEL = {1:1, 2:2, 3:3, … 9:9}` (slots = plant level). **Please confirm or revise this mapping in the GDD** — it was implemented from your verbal spec ("L2 = 2 slots"), not from an existing written rule. If the intended curve is different (e.g. slots cap at some level, or scale non-linearly), update the constant in `GameState.gd` and note it in §23.

---

## 5. NEXT SESSION — what's queued

### Immediately pending (the last 2 of the original 8-bug list)
- **Bug 6 — Pit Crew assignment in the Garage + auto-repairs.**
  - Garage currently only has DRIVER and MECHANIC slots; the car has a `pit_crew_id` field but no UI to set it (only the Pit Crew Arena assigns crews). Add a pit-crew slot + popup mode in `Garage.gd`, plus `assign_pit_crew` / `unassign_pit_crew` in `CarManager`/`GameState` (mirror the mechanic functions).
  - Auto-repairs: the assigned mechanic should repair the car post-race automatically.
  - Files: Garage.gd, CarManager.gd, GameState.gd.
- **Bug 8 — Contract negotiations not triggering automatically.**
  - Investigate `ContractEngine.gd` / `ContractNegotiation.gd` — negotiations aren't auto-firing when they should.

### Still-open issue from this session
- **Issue 1 follow-up:** the false-notification fix is in, but if any "assign driver/mechanic" warning still shows on a fully-staffed car after a fresh game, capture the exact text + when (bell vs TDL) so the remaining trigger can be pinned.
- **TP proposal *timing*:** proposals should fire ~1 week before a race, not every racing week (separate from the refresh-to-0 fix already done).

### The agreed economy roadmap (after bugs 6 & 8)
Build all economic systems first, derive balance numbers as outputs, race sim last:
- **Phase 2 — §23 car system:** delivery delay, P2/P3 gating until car delivered, DNS-until-car-ready, GP1 engine lead time, design/registration deadlines. (Classified as ECONOMY, not race.) Only the −1 week WRA shift is in so far.
- **Phase 3 — Commercial factory + R&D Pillar 5.** Adds the second weekly income engine (commercial car sales) so the game is playable without the race.
- **Phase 4 — Stock market.**
- **Phase 5 — Multi-season balance pass:** once all income sources exist, derive AI-team budgets and team-character spending as system outputs; stress-test with headless sims (Python ports of the economy engines) + real Godot playtests. Targets to chase here: the "active fans exploding to 918k" curve, prize-money floors, salary scaling.
- **Then:** drop the race sim into the stable, balanced economy.

### Design constraint carried forward
Keep economic logic in pure `RefCounted` engine classes (testable headless), not in UI scripts — so each new engine (commercial, stock market) can be Python-stress-tested for multi-season drift before it ships.

---

## 6. Reminder
After pushing, bump the GDD header to **v4.3** and commit the doc alongside the 18 code files.
# Feature Spec — AI Championship Simulation (the "living world")

**Status:** BACKLOG (noted S28.4, 2026-06-18). Not a bug — a real feature.
**Add to GDD §16 / roadmap. Sits alongside P51 (Transfer Market) as part of "the AI world is alive."**

---

## Problem / motivation

Today, only the championship(s) the player actually races get standings populated.
`Championship.add_points()` is called exclusively from the player's own race
(`RaceSimulator` line ~280). Every other championship in `active_championships`
has **empty** `standings` / `team_standings` all season.

Consequences:
- The end-of-season screen can only show championships the player raced (the S28.4
  fix correctly filters to `player_registered_championships` — this prevented the
  empty-data crash, incl. the bankruptcy-continue crash).
- There is no sense of a living world: rival championships have no champions, no
  results, no narrative. The player can't "scout" a series before entering it.
- AI team reputations don't move based on results in series the player isn't in.

## What "done" looks like

Every championship in the world runs each season — whether or not the player is in it —
and produces:
- A driver champion + full final standings.
- A team champion + team standings.
- Per-round results good enough to show a season summary.
- Hooks for reputation/marketability movement of AI teams based on results.

The player can then:
- See other championships' champions & standings on the end-of-season screen
  (a read-only "Rest of the World" section).
- Browse live standings of any championship mid-season in the Racing World view.
- Make informed decisions about which championship to enter next.

## Design approach (keep it cheap — this must run every week for ~20+ championships)

**Do NOT run the full lap-by-lap race sim for AI championships** — far too expensive
to do 20+ championships × N rounds × full physics every week. Instead use a
**lightweight "result model"**: each AI car has a single strength score derived from
its existing stats (driver skill × car performance index × staff multipliers × a
random race-day factor). Sort by score + noise → finishing order → award points via
the championship's existing points table. This reuses `Championship.add_points()` and
the existing standings structures, so the EOS / Racing World screens need almost no
change once data exists.

Suggested pieces:
- `AIChampionshipSim` (new RefCounted engine, testable headless):
  - `simulate_round(champ)` → produces finishing order + awards points.
  - `car_strength(car)` → single scalar from existing stats (pure function — Python-portable for balance tests).
  - `simulate_season_to_date(champ)` → catch-up for championships when first viewed.
- Hook into the weekly tick / season advance so AI championships advance their rounds
  in lockstep with the calendar (each champ has its own race weeks).
- At season end, derive champion = top of final standings (same as player champ logic).

## Why it's deferred (not fast)

- Needs a new sim engine + a balanced strength model (so AI results feel plausible,
  not random) — that's a balance pass in itself.
- Touches the weekly tick, season transition, and the standings/EOS/RacingWorld reads.
- Best built AFTER the economy phases, because AI team budgets/character (Phase 5)
  should influence how strong each AI team's cars are — i.e. the strength model
  should read the same economic outputs we're about to build. Building it now would
  mean re-deriving the strength inputs later.

## Recommended sequencing

Slot this AFTER Phase 5 (multi-season balance), alongside / just before the race sim
swap-in, and pair it conceptually with **P51 Transfer Market** — together they make the
AI world fully alive (rivals race, get results, sign drivers, build reputation).

## Cheap interim option (if you ever want *something* before the full feature)

A read-only "Other Championships This Season" list on the EOS screen showing just
name / discipline / tier / "Not entered" — **no standings access**, so no crash risk.
Low value (duplicates the championship browser) but zero risk. Currently declined.