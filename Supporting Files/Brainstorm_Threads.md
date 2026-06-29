# Automotive Empire — Brainstorm Threads & Strategy Decisions

**Permanent project knowledge. This file preserves the DESIGN VISION and STRATEGY decisions
made in brainstorming sessions, so every chat in the project can pick them up. It is the
companion to the technical handoff doc (`GDD_UPDATE_and_HANDOFF.md`), which covers code/dev
state. This file = the "why" and the "what we want"; the handoff doc = the "where the code is."**

---

## HOW TO USE THIS FILE / HOW I WORK

- **Automotive Empire** is a motorsport-management tycoon sim (Godot 4.6.3). Deep economic/
  management sim: run a racing team across real motorsport disciplines (karting/GK up to GP1,
  plus Rally, Touring, Open-Wheel, Stock Car, Endurance). Manage finances, R&D, staff, contracts,
  a commercial car business, an academy. Races are ONE part of a larger business sim.
- **Build order:** economy first, race module LAST.
- **My working style:** I brainstorm (often on phone, away from the keyboard) to bank ready-to-
  execute decisions; I build at the keyboard later. I value HONESTY over encouragement. I say
  "backlog" to control scope. I keep a GDD + git repo. Engineering discipline matters: clean
  data-driven architecture, testable RefCounted engine classes, no orphaned dependencies,
  version headers.
- **Crucial framing:** I have the means and desire to build this MY way, for MYSELF first — NOT
  as a commercial survival bet. Optimize advice for "the game I want," not "what sells." Scope
  discipline still matters, but to serve the vision and ensure it gets finished, not for a deadline.
- **Chat separation:** coding/dev work, commercial/marketing strategy, and design brainstorming
  may happen in different chats. A brainstorming chat should stay on design/vision.

---

## OPEN DESIGN THREADS (refine and extend these)

### 1. AI TEAM BEHAVIOR — the 5-stage development ladder
- **Principle:** AI's job is to STAY ALIVE AND SURVIVE and stay plausible — NOT to play well.
  "Smart AI" is explicitly out of scope for now.
- **The ladder (a state machine; a team pursues a higher stage only when lower needs are secure;
  a fallen giant drops back to Survive):**
  1. **Survive** — don't go bankrupt: take loans, cut discretionary spend, fill empty seats cheaply.
  2. **Settle** — secure roster on contracts, build basics, establish reliable income.
  3. **Develop** — R&D, upgrades, sign better (not just available) people.
  4. **Establish** — optimize, defend key personnel, full programme, maybe a 2nd car.
  5. **Conquer** — expand.
- **Conquest is BOTH vertical AND horizontal:** climb tiers (promotion) OR expand sideways into a
  parallel discipline at the same level. Lateral moves follow discipline-distance (adjacent
  disciplines first — same matrix as the news system).
- **Character = weights on the ladder**, not new logic: Frugal (slow/conservative), Ambitious
  (climbs eagerly, more risk), Prestige (overspends on visible things), Balanced. Tuned in the
  balance pass.
- **Build order:** Survive + Settle FIRST (the world stops dying) — cheap, reactive, must-have.
  Develop/Establish/Conquer are progressive polish.
- Each economic system ships WITH its AI behavior attached (not a separate end-phase project).
- **Doubles as the player's career arc AND the trailer motto: "Survive. Settle. Develop.
  Establish. Conquer."** Everyone (player + AI) runs the same ladder at different rungs.
- Visibility of AI internal life: build OPAQUE survival first; add transparency later via the
  news system where cheap.
- **STILL UNMAPPED:** the specific decision points WITHIN each stage (exactly when to take a loan,
  upgrade, sign, develop). Deferred until the economy systems exist (decisions are about those systems).

### 2. NEWS SYSTEM — the sound-wave propagation model
- News is a wave from an origin point: propagates outward, DECAYS with distance, reaches a reader
  only if magnitude still clears their threshold.
- **reach = importance − vertical_distance − horizontal_distance**
  - **importance** = intrinsic event magnitude (title win >> building upgrade).
  - **vertical_distance** = reputation/tier gap, **ASYMMETRIC**: cheap DOWNWARD (prestige flows
    downhill — small teams hear big-team news), expensive UPWARD (small-team news needs high
    magnitude to climb — e.g. "the new Verstappen" GK champion clears it).
  - **horizontal_distance** = discipline gap, sourced from the existing DISCIPLINE ADAPTATION
    MATRIX (high adaptation = close worlds = short distance). Reuse it; don't author a second
    matrix (leave only a per-pair tuning hook if playtesting demands).
- **KEY INSIGHT — tier COMPRESSES horizontal distance:** the pyramid narrows at the top. Elite
  teams across disciplines form ONE peer community (shared sponsors/media/prestige). So discipline
  distance shrinks as tier rises. Compute horizontal distance using the HIGHER party's tier as the
  compression factor. (A GP1 team cares about the Le Mans winner; couldn't name a Rally4 champ.)
- **Downward big-team news must be ASPIRATIONAL, not operational:** show pinnacle drama (title
  deciders, legends, dynasties, a driver who rose from MY discipline), filter routine status.
  Rule: magnitude + connection, not magnitude alone. Avoids boredom.
- **The feed GROWS with the player:** as reputation rises, small-team noise fades, the top tier
  becomes the peer group. Alive across a whole career.
- Bounded: it's ONE scoring function over data that already exists. Not an open-ended mandate.

### 3. AI CHAMPIONSHIP SIM — the "living world" (deferred)
- Today only the player's raced championship gets standings; all others are empty. (This caused
  crashes, since fixed by filtering end-of-season to raced championships only.)
- **Future feature:** every championship runs each season via a LIGHTWEIGHT result model (one
  strength scalar per car from existing stats + race-day noise → finishing order → existing points
  table). NOT the full lap-by-lap race sim (too expensive for 20+ championships weekly).
- New `AIChampionshipSim` RefCounted engine, Python-portable for balance tests.
- Build AFTER the economy (AI car strength should read economic outputs / team budgets). Pairs
  with a Transfer Market to make the AI world fully alive.

### 4. BUILDING ↔ R&D COUPLING (a design RULE, not just a task)
- Each slot-providing building's MAX level hard-gates a top-tier Pillar-3 R&D project
  (Garage max→one project, Racing Dept max→another, Fitness Clinic max→another, Pit Crew Arena
  max→another, plus laddered projects below each).
- **RULE: building max level and its top R&D gate MOVE TOGETHER.** Change one without the other and
  an R&D project orphans (becomes unreachable or trivially open — a silent bug).
- **Pending balance work:** building max levels don't match the personnel peak (e.g. driver demand
  far exceeds Racing Dept's slots). Rebalance them deliberately, coordinated with R&D gates.
- **Fitness Clinic rework:** absurdly high max level, 0 staff slots, pure fatigue building →
  boring micromanagement. DECISION: slash its max level AND automate allocation ("most tired is
  served first" — recovery capacity auto-applies to the most-fatigued driver/crew). Drags its
  R&D ladder with it (re-gate/re-space).

### 5. RACE MODULE (my paper design — race is built LAST)
- 2D track for VISUAL presentation of the race + a "Telemetry Wall" that shows the TRUTH (data).
- Telemetry Wall split into 3 ROTATING tabs (arrows/tabs): (a) whole grid (positions, gaps, tyres),
  (b) our cars' detail (laps, sectors, trims), (c) all other deep data (strategy, pit, part cond).
- A SPEED CONTROL (− / ×1 / +): time-acceleration that SNAPS BACK to ×1 and NOTIFIES on critical
  events (part about to fail, pit window, incident). Could auto-jump to the relevant telemetry tab.
- Per-car panels show part conditions + Qual/Race trim + pit. Displays up to 4 cars (page if more).
- Open Qs (for when race is built): what populates the panels (our team's cars, up to the
  championship cap); how the 2D action is represented; EPC needs 3 driver slots/car (Driver_Per_Car).

---

## STRATEGY DECISIONS (mostly settled — context, not open debate)

- **Goal:** build the game I want, for myself first. Selling to a big studio = NOT my style
  (and isn't how it works for solo devs anyway — that path is a publishing deal, not a buyout).
  Self-publishing on Steam is POSSIBLE but secondary.
- **Commercial reality:** indie sales are usually low; in THIS niche, VISIBILITY (not quality) is
  the killer. Reference case: "Scifi Racing Team" (Delicious Lines, 2025) — a near-identical team-
  management sim, competent and positively reviewed, but ~4 reviews total = invisible. Lesson:
  discovery failed, not the game. Its sci-fi skin may have hurt (fell between fanbases).
- **My discoverability EDGE:** real-motorsport framing (real disciplines) connects to an existing,
  identifiable audience better than abstract/sci-fi competitors.
- **Marketing:** my girlfriend handles it (I can't). Highest-leverage lever = Steam page + wishlist
  campaign started EARLY, marketed into the motorsport-management community (Motorsport Manager
  crowd, sim-racing-adjacent spaces, management-sim YouTubers). For when she's ready.
- **Names / IP:** ship FICTIONAL names + full MOD SUPPORT (data-driven; name swaps are trivial).
  My PRIVATE real-names version stays private (legal — personal use, not distributed). I must NOT
  distribute the real-names mod MYSELF, even as "the first modder" — being the developer collapses
  the legal firewall and reads as deliberate infringement. Build the modding ROAD; let independent
  community modders drive the real-names cargo. In this niche, the real-names pack will appear
  within days of launch made by someone who isn't me.
- **AI assistance & Steam sentiment:** the backlash targets consumed AI ASSETS (art, voices,
  writing) — NOT AI-assisted CODE. My design, systems, domain knowledge, and direction are human;
  the AI is the engineer, not the author. Defenses: (1) keep SHIPPED art/voices human; (2) lean
  into handcrafted SYSTEMIC DEPTH and coherence (what the management-sim audience values, and what
  AI is bad at); (3) DISCLOSE honestly and over-transparently — Valve enforces disclosure and
  pulls pages for inaccurate disclosure; HIDING AI use is the real killer. (4) Beware false
  AI-accusation review-bombing; counter with visible human craft + proactive narrative (her job).

---

## ROADMAP (agreed; economy first, race last)
- Phase 2: §23 car system (delivery delay, P2/P3 gating, DNS-until-ready, deadlines) — it's ECONOMY.
- Phase 3: Commercial factory + R&D Pillar 5 (second weekly income → playable without the race).
- Phase 4: Stock market.
- Phase 5: Multi-season BALANCE pass — derive AI budgets & team character as OUTPUTS; tune building
  maxes + R&D gates; headless Python stress-tests + real playtests.
- Then: race sim swap-in (module design above).
- Parallel/after: AI Championship Sim + News System + Transfer Market = the living world.

**Each economic system ships WITH its AI behavior (thread 1) attached. Keep economic logic in pure
RefCounted engine classes so they're Python-testable for multi-season drift before shipping.**

---

## NEXT STEP IN A BRAINSTORM CHAT
Start by asking which thread I want to dig into, or pick up wherever I point. The most natural
unfinished pieces: the AI per-stage DECISION POINTS (thread 1), or deepening the news/AI coupling.
