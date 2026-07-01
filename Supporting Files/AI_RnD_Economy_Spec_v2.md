# SPEC — AI R&D Economy (Planner-Driven) · v2

<!-- v2 (S41 draft): Owner corrections folded in. (1) WRA submission = 1 week flat (no tier table, no
     money fee — fee was already removed). (2) WRA rejection = 10% chance on P2 ONLY; a rejection
     fires notification + news AND damages team reputation; P1/P3 always approved. Populates the
     currently-unused wra_rejected_blueprints. (3) RP_PER_LAP_BASE 1.0 → 3.0 in code (previous chat
     intended it; file lagged). (4) P4/P5 ladder logic made concrete: P1=survive, P2=stabilize,
     P4=develop (schedule P4 when the forecast secures P1+P2 with surplus); P5 = Established→Conquer
     commercial-market teams only. Team CHARACTER weighting is the next project. (5) P3 gate = garage
     car's part bought via Logistics centre. (6) ARCHITECTURE.md fixed manually by owner — dropped
     from deliverables. -->
<!-- v1 (S41 draft): First full spec for the per-AI-team R&D economy. Authored after a full read of
     the 6 core files + AI surface + task schema. Supersedes the inert LeadDesignerProposalEngine
     ai_fill_design_lines_* seam notes. Pairs with GDD §8 (R&D), §11 (WRA), §13.1 (ladder), §14
     (AIChampionshipSim swap-point). CnC-manufacture/install/resale mirror is the NEXT project. -->

**Status:** DESIGN — agreed, not yet coded · **Engine:** Godot 4.7 / GDScript
**Owner decisions captured:** full-mirror RP · full per-team globals (via parallel ledger) · real
on-track uplift this project (via §14 swap-point) · planner is shared player↔AI · new `planning`
Designer attribute · WRA no-reject for P1/P3 · retreat-and-backfill to protect championships.

---

## 0. ONE-PARAGRAPH SUMMARY

Give every capable AI team its own Research-Point economy that mirrors the player's exactly, and put
a **forecast-driven planner** in charge of spending it. The planner predicts each team's RP curve
across the remaining calendar, knows its free design lines / CR / weeks-to-deadline, and schedules a
**sequence** of R&D tasks — run P2 upgrades on this year's car early, defer the deadline-critical
P1/P3 next-season car to the latest safe week, spend P4/P5 only on proven surplus. If the forecast
says a team cannot finish next season's car in time, it **does not register** for that championship and
**retreats** to a lighter one; if that retreat would drop a championship below minimum participation, a
suitable neighbouring team is **fake-boosted** to backfill. Every such event is world news. The same
planner drives the player's Lead-Designer automation (as proposals). This project stops at the
research/WRA-approval stage; **AI CnC manufacture / install / resale is the next project**, wired to a
clean interim on-track uplift here.

---

## 1. WHAT ALREADY EXISTS (verified reads — do not re-derive)

- **`team.get_meta("rnd_bonuses")`** is already the per-team effect ledger; `RnDEngine.get_rnd_bonus`
  and the whole P4 accessor cluster are **already team-aware** (default to player, accept any team).
- **`LeadDesignerProposalEngine.compute_design_queue(team, cars)`** is **already team-agnostic** and
  resolves Studio level, Lead, free lines, and ranked candidates for ANY team. Only the AI apply hooks
  (`ai_fill_design_lines_*`) are inert no-ops.
- **`AIChampionshipSim.car_strength(car)`** is the documented **§14 Phase-5 swap-point**; it currently
  reads `baseline_performance_index` and is the single function to touch for on-track uplift.
- **Part provenance is tracked:** `car_provider_parts[car_id]` = bought-via-Logistics (L0) parts;
  `car_installed_parts[car_id]` = own-CnC parts. (Grounds the P3 availability rule, §3.)
- **P1/P3 tasks are stamped `season = current+1`** (next-season car); **P2 is current season**. Weeks
  halve on a mid-cycle refresh year, full on a from-scratch (WRA cycle start) year.
- **WRA currently rejects nothing** — every submission auto-approves. The `wra_rejected_blueprints`
  array is declared/saved but never populated. (Submission weeks are being flattened to 1; §3.2.)

## 2. WHAT IS MISSING (the build)

1. No per-AI-team RP. `earn_race_rp` writes a single global `gs.research_points`.
2. No AI R&D task pipeline. `active_rnd_tasks` / `completed_*` / `known_blueprints` are player-singular
   globals with no `team_id`.
3. `start_rnd_task` / `_apply_rnd_effect` are hardcoded to `gs.player_team`.
4. No planner. `compute_design_queue` fills idle lines opportunistically but does NOT forecast RP,
   respect deadlines, or sequence P2-now-vs-P1-later. It is a ranked list, not a schedule.
5. No `planning` Designer attribute.
6. AI research has no on-track effect (`car_strength` ignores `rnd_bonuses`).
7. No retreat / backfill logic when a team can't afford next season's car.

---

## 3. TWO "FIX ASAP" ITEMS (independent of AI — land first)

### 3.1 P3 spec-parts bug (`RnDEngine._build_rnd_tasks_for_season`)
**Bug:** P3/RE tasks are generated only inside `if is_spec:` — so RE is offered for spec parts only.
**Correct model:** P3 exists to let a team **produce its own car next year instead of re-buying it**.
It must be offered for **ALL parts (spec + open)**, gated at RUNTIME by provenance.

- **Catalog layer:** drop the `if is_spec:` gate so an RE task is generated for every part. (Open
  parts also get a P3 task; P1 still exists for all parts — a team may P1 a part for better stats
  even where P3 is available. GP1 example: no P3-eligible parts → all P1. GP4: 6 parts P3-able, or
  all-P1 for better stats.)
- **Availability gate (new, in `rnd_task_unlocked` / the P3 candidate filter):** a P3 task for
  `[cid, pcode]` is startable **only if the car currently in the garage had that part BOUGHT via the
  Logistics centre** — i.e. present in `car_provider_parts[car_id][pcode]` AND absent from
  `car_installed_parts[car_id]` (not already own-CnC-made). You cannot reverse-engineer a part you
  already manufacture.
- **Cost/weeks:** unchanged. Open-part RE uses the same `PART_BASE_P3` curve; if an open part lacks a
  P3 base cost, derive it from its P1 base × the existing P3 multiplier (spec in code review).

### 3.2 WRA rejection — 10% on P2 only (NEW code)
WRA has **no money fee** (already removed) and **submission takes 1 week flat** (no tier table).
Rejection is currently unimplemented (all submissions auto-approve). Build it now, scoped to P2:

- On a submission's decision week in `_advance_wra_submissions`, if `pillar == 2`, roll a **10%
  rejection**. P1/P3 are **always approved** (a late rejection of a next-season car would cause the
  full-season-DNS catastrophe the planner exists to prevent).
- A rejected P2 → append to `wra_rejected_blueprints` (the declared-but-unused array), fire a
  **notification + news**, and apply a **negative reputation hit scaled by championship tier**
  (higher tier = bigger hit; e.g. `−0.5 × tier`, balance-tunable).
- Applies to AI teams too once they're on the pipeline (their P2 submissions can be rejected, feeding
  news and the living world).

---

## 4. STORAGE MODEL — parallel per-team ledger (pattern B)

**Decision rationale:** the six player-singular globals are read directly by 7 UI scenes + CarManager
+ NotificationManager (~170 sites; `known_blueprints` alone = 70). Rewriting the globals to
`{team_id: …}` risks silently breaking player-facing screens we cannot parse-check here. Instead we
keep the player's globals EXACTLY as they are (zero player-path regression) and give AI teams a
parallel store that mirrors their shape — the same pattern `rnd_bonuses` already uses.

```
team.set_meta("rnd_ledger", {
    "rp":              float,        # this team's Research Points (mirrors gs.research_points)
    "active_tasks":    Array,        # same task-dict shape as gs.active_rnd_tasks, + "team_id"
    "completed_rnd":   Array,        # task ids (prereq checks)
    "completed_bp":    Array,        # P1/P3 blueprint task ids
    "completed_upg":   Array,        # P2 task ids (cleared at season start, mirror player rule)
    "known_blueprints":Dictionary,   # bp_id → blueprint record (value/quality/season/…)
    "wra_active":      Array,         # in-flight WRA submissions
    "wra_approved":    Array,         # approved licences
    "studio_level":    int,          # AI R&D Studio level (seeded; see §7)
})
# rnd_bonuses stays the separate existing meta (effects), already team-aware.
```

**Engine functions become team-routed.** Each pipeline function gains a `team` param (default =
player). When `team.is_player_team` it reads/writes the existing globals (unchanged behaviour); else it
reads/writes `team.get_meta("rnd_ledger")`. Functions to generalise:
`earn_race_rp`, `start_rnd_task`, `_advance_rnd_tasks`, `_apply_rnd_effect`, `_advance_wra_submissions`,
`submit_to_wra`, and the read helpers (`rnd_task_active_or_done`, `rnd_task_unlocked`,
`get_free_design_lines`, `get_active_lines_for`, `is_blueprint_approved/submitted`). A small
`_ledger_for(team)` accessor (mirrors `_bonuses_for`) is the single routing point.

**Save/load:** AI ledgers live on team meta; serialise per team in the existing teams save block.
Pre-existing saves with no AI ledger seed a fresh one on load (mirrors the `rnd_bonuses` backfill).

---

## 5. THE RP FAUCET — full mirror

After `AIChampionshipSim.simulate_round(champ)` awards points, each AI team with running cars in that
championship earns RP by the **same formula** as the player:

```
RP_gained = laps × RP_PER_LAP_BASE × studio_level × (lead_overall / 100) × ai_difficulty_mult
            (summed over the team's running cars in that championship; laps = scheduled race distance)
```

- `RP_PER_LAP_BASE` is the SAME constant the player uses (see §10 open item on 1.0 vs 3.0).
- AI cars always complete the scheduled distance (no AI DNF model yet) → `laps` is exact.
- Capped by the same dynamic storage-cap logic (`get_rnd_rp_storage_cap`, made team-aware).
- No Studio or no Lead on the AI team → no RP (same gate as the player).

**Hook:** in the GameState weekly race loop, immediately after the `_ai_championship_sim.simulate_round`
call, invoke `earn_race_rp(team, laps)` per AI team fielding cars in that champ.

---

## 6. THE PLANNER — the core intelligence (shared player ↔ AI)

Built in `LeadDesignerProposalEngine` as a **pure forecast+schedule function**; player consumes it as
proposals, AI applies it directly. This is the piece that keeps championships alive.

### 6.1 Inputs (all forecastable from existing data)
- **RP forecast curve:** for each remaining race week `w`, the RP the team will have earned by `w`
  (from the remaining calendar × the §5 faucet). Gives "RP available by week w".
- **Free design lines:** `studio_level − active_lines` over time (lines free as tasks complete).
- **CR forecast:** current balance + forecast income − committed task CR.
- **Weeks to deadline** per championship: registration/delivery week (`get_car_delivery_week` /
  `FIRST_RACE_WEEK` / `REG_DEADLINE_OVERRIDE`), capped at week 52.

### 6.2 The "latest safe start week" (deadline backward-schedule)
For the next-season car (P1/P3), the planner computes the latest week it can START and still finish:

```
latest_safe_start(part) = 52 − (L1_design_weeks + 1)      # WRA approval = 1 week flat
```

- `L1_design_weeks` includes the from-scratch/refresh multiplier AND the Lead over-stretch multiplier.
- WRA approval = **1 week** (flat; no tier table, no fee).
- Example (6 design + 1 approval): latest safe start = week 45. Going for **L2** needs more weeks →
  start EARLIER. The planner picks the latest start that still lands all six parts before 52.
- Plan is committed **at registration** (~week 11 for a top series): register-next-season → P2 the
  current car through mid-season → auto-switch to P1/P3 at the computed safe week → WRA → done by 52.

### 6.3 Scheduling policy (the sequence) — the ladder in RP terms
**P1 = survive · P2 = stabilize · P4 = develop · P5 = expand.** The whole order falls out of the RP
forecast; no separate stage gate needed for P4:

1. **Feasibility check FIRST** (see §6.4). If infeasible → retreat (§7).
2. If feasible: fill idle lines with **P2 upgrades** for the current car (immediate on-track value)
   until the latest-safe-start clock for the next-season car arrives.
3. At `latest_safe_start`, **switch idle-line priority to P1/P3** for the next-season car; the
   deadline-critical parts pre-empt discretionary work.
4. **P3 vs P1 choice per part:** if the team's strategy is "produce our own car" and the part is
   P3-eligible (§3.1 Logistics-bought provenance), prefer P3 (cheaper, enables in-house build next
   project); else P1. Cover P3-ineligible parts with P1.
5. **P4 = develop → DEFERRED SEAM (not built this project).** P4 special-project scheduling is a
   discretionary "growth" behavior that belongs to the AI ladder-state machine (Develop stage). This
   project leaves a **named, inert hook** for it (mirrors how `ai_fill_design_lines_*` was left for
   the R&D economy): documented, reachable, but a deliberate no-op that the future ladder session
   activates. The planner this project ships does P1/P3 (survive) + P2 (stabilize) ONLY.
6. **P5 = expand → DEFERRED SEAM (not built this project).** Commercial-model research belongs to
   Established→Conquer teams and is inseparable from team character. Same treatment: an inert,
   documented hook driven later by the ladder-state machine.

> **DESIGN NOTE — the ladder becomes the world's backbone.** The 5 stages (Survive · Settle ·
> Develop · Establish · Conquer, GDD §13.1) are being promoted from a tuning idea to the master
> state machine for ALL AI behavior (R&D, contracts, buildings, finance, commercial, transfers) — its
> own brainstorming session. This project deliberately implements only the **Survive** (P1/P3 field
> the car) and **stabilize** (P2) R&D behaviors, and leaves Develop/Establish/Conquer (P4/P5 and
> beyond) as clean inert seams for that session to drive. No P4/P5 trigger logic is hardwired here.

### 6.4 Feasibility check (protects the championship)
A championship registration for next season is **feasible** iff the RP forecast + CR forecast can
land at least the six **L1** next-season parts (P1/P3) before `latest_safe_start` on every line,
given free-line throughput. If not feasible → the team will NOT register there next season.

### 6.5 The `planning` Designer attribute (NEW)
- Added to `Staff.gd` (Designer role), `staff_designer.json` schema, and `_staff_from_dict`
  (default 50, wide random roll when absent — mirrors `talent_scouting`).
- **Effect:** modulates the planner's forecast horizon & accuracy. High `planning` → looks further
  ahead, hits `latest_safe_start` precisely, rarely mis-sequences. Low `planning` → shorter horizon,
  safety buffer added to `latest_safe_start` (starts P1 earlier "just in case", wasting P2 time) and a
  chance to mis-order, occasionally forcing an avoidable retreat. Exact curve tuned in the balance
  pass; the attribute is the single knob.
- The player's Lead Designer uses the same attribute, so a better-planning Lead gives better proposals.

---

## 7. RETREAT & BACKFILL — never let a championship collapse

Triggered when §6.4 feasibility fails for a team's current championship.

1. **Withdraw:** the team does not register for that championship next season. → **news.**
2. **Retreat search (CEO + Designer):** rank alternative championships the team could enter by
   **(a) discipline proximity via the adaptation matrix, then (b) highest tier they CAN afford**
   (RP burden of that champ's L1 P1/P3 tree × prestige). Register the best affordable, nearest option.
   → **news.**
3. **Backfill (only if the withdrawal drops the vacated championship below `min_cars` /
   min-participation):** promote the **most suitable EXISTING neighbouring team** — one tier down, or
   an adjacent discipline via the adaptation matrix (e.g. a GP1 gap pulls up a top GP2, or a top
   OWC/EPC team) — and **fake-boost** it: magically raise its buildings, hire the needed personnel,
   and grant the RP/parts so it can field a legal car next season. Filler teams spawned from nothing
   are reserved for GK and the very lowest tiers only. → **news.**
4. **Rarity by design:** the engine targets **Optimum participation, not minimum**, so headroom
   absorbs most withdrawals with no boost at all. Backfill is the rare integrity backstop.

**Hook:** runs in `SeasonManager.start_new_season` at the AI-roster-settle stage (Stage C region),
BEFORE the world's championships reset, so next-season grids are legal when presented.

---

## 8. ON-TRACK UPLIFT — this project vs. next project

**This project (interim, real uplift):** `AIChampionshipSim.car_strength` gains a factor
`× (1 + perf_bonus(team))` reading the team's `rnd_bonuses` (the §14 swap-point). A team whose planner
successfully researches performance blueprints fields a genuinely faster car. This is honest uplift
that ships and is analysis-verifiable now.

**Next project (the CnC mirror — OUT OF SCOPE HERE):** generalise the CnC stack
(`assign_cnc_part_to_car`, `get_cnc_part_bonus`, `get_cnc_slots`, the production queue) to be
team-aware, give AI teams CNC Plant levels + `car_installed_parts`, and switch `car_strength` from the
`perf_bonus` proxy to reading real installed AI parts — then add AI part **resale** to other teams.
The interim proxy is deliberately the same shape as the real thing so the swap is clean.

**Hard rule — never silently fail to field a car:** satisfied at the REGISTRATION layer (a team that
can't finish a car retreats rather than DNS-ing), not the race layer. Car fielding itself remains the
existing AIManager path on the baseline car; R&D is uplift on top. A guard + log fires if any AI team
ends a season boundary registered in a championship with zero fielded cars.

---

## 9. BUILD ORDER (phased commits, each analysis-verifiable)

1. **✅ DONE (S41.0)** — **Fix 3.1** (P3 all-parts + Logistics-bought provenance gate), **WRA**
   (1-week flat + 10% P2-only rejection with news + tier-scaled rep hit), and **`RP_PER_LAP_BASE`
   1.0→3.0**. Files: `RnDEngine.gd`, `RaceSimulator.gd`. Analysis-checked (brace-balance + type audit);
   NOT Godot-parsed.
2. **✅ DONE (S41.0)** — **`planning` Designer attribute**: added to `Staff.gd` (excluded from
   `get_overall_skill` by design — governs WHEN, not part quality), loaded in `AIManager._staff_from_dict`
   and both `StaffManager` generation paths (also fixed a latent bug: `_create_starting_staff` had no
   Designer branch → starting GP designers had all-zero stats), and added to GameState save/load with
   old-save backfill. NOTE: `data/staff_designer.json` does not yet carry per-designer `planning`
   values — the loader defaults a wide random roll, which is fine for now; authoring real values is an
   optional data pass (like the Lead-Designer surgery) if the balance pass wants hand-tuned planners.
3. **✅ DONE (S41.2–S41.3)** — **Per-team ledger + routing** (§4): `_fresh_rnd_ledger` /
   `_is_player_ledger` / `_ledger_for`; pipeline functions generalised with an optional `team` param
   (default → player); AI ledger + rnd_bonuses save/load with fresh-seed fallback. Player path
   byte-for-byte unchanged (all call-sites omit `team`). Analysis-checked; NOT Godot-parsed.
4. **✅ DONE (S41.4)** — **RP faucet mirror** (§5) + team-aware storage cap. `earn_race_rp(km, team)`;
   `_ai_earn_race_rp_for_champ` hooked after `simulate_round`; AI Studio level seeded from teams.json
   (clamped 1..27); difficulty knob = `ai_performance`. Fills AI ledgers; spending awaits step 5.
   Faucet decoupled from `_lead_designer_engine` (resolves the AI Lead inline). Analysis-checked; NOT
   Godot-parsed. NOTE flagged: `load_game` doesn't re-init several engine singletons (pre-existing) —
   fix in its own pass.
5. **The planner** (§6): forecast + backward-schedule + feasibility, in LeadDesignerProposalEngine;
   activate `ai_fill_design_lines_all_teams` to apply it; wire player proposals to the same function.
6. **Retreat & backfill** (§7) in SeasonManager + news.
7. **On-track uplift** (§8) — `perf_bonus` factor into `car_strength`.

Each commit bumps the version header of every edited file; each is delivered as a downloadable file
and copied to outputs. Verification is brace-balance + type-inference audit ONLY (no Godot parse here);
real parse/playtest is the user's job and must be stated per commit.

---

## 10. RESOLVED / REMAINING ITEMS

**Resolved:**
- `RP_PER_LAP_BASE` → change code **1.0 → 3.0** (previous chat intended it; file lagged). Applied as a
  tracked edit in Phase 1. AI faucet inherits 3.0.
- WRA: 1-week submission, no fee, 10% reject on P2 only (§3.2).
- Adaptation matrix: ONE discipline-adaptation matrix, used by both drivers and staff — reused for
  retreat proximity and (future) news soundwave horizontal distance.
- P4/P5 ladder: falls out of the RP forecast (§6.3) — no separate gate.
- ARCHITECTURE.md `GDDv7.5.md` reference: **fixed manually by owner** — not a deliverable here.

**Remaining (confirm during code review, not blocking):**
- Open-part P3 base cost where `PART_BASE_P3` has no entry — derive from P1 base × P3 multiplier.
- Exact `planning`-attribute → forecast-horizon curve (balance-pass tuning; the attribute is the knob).
- Reputation-hit magnitude for a rejected P2 (small; tuned in balance pass).
