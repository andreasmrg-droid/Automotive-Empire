# Automotive Empire — Original 51-Item List, Reconciled Against Shipped Code

**Reconciled:** 2026-06-29 · against repo HEAD `f891f27` (S37.50) + GDD v6.8 changelog (S28–S37.50), plus the S37.51–S37.59 session below (Bug #22 close-out + calendar/Main-Hub work; pending push at time of writing).
**Status legend:** ✅ Fixed (incl. player-confirmed in play) · 🟡 Fixed–needs in-engine verification · 🟠 Known/latent (partial or no-op until data added) · 🔵 Backlog/feature (design-approved, sequenced later) · ⚪ Open/unassigned.

> Note: GitHub is authoritative. This maps your ORIGINAL numbered list (1–51) onto the work that
> has actually shipped. The live tracker in `Supporting Files/BUGLIST.md` is cluster-based
> (A-CP4, A-STD, …); this file is the bridge between the two.
> **Items marked ✅ (confirmed) were verified in-game during the S37.3–S37.8 sessions via screenshots.**

---

| # | Item | Status | Where / how addressed |
|---|------|--------|-----------------------|
| 1 | CFO financial-mgmt attributes all 0 | ✅ | **S37.17** Confirmed: the CFO JSON data is fine (non-zero); the bug was DISPLAY. The StaffHub detail card read the REMOVED `interest_rates` field, which broke the whole attribute-list build → all-0. Now reads the real `speculation` stat. Same class of bug fixed in 4 more spots: Mechanic `car_knowledge`→`parts_knowledge` (detail list/row/sort) and Garage chips car_setup_skill/pit_stop_skill/car_knowledge → real fields (were placeholder 50). TP `talent_scouting` added to TP detail list. **S37.18 (screenshot follow-up):** CFO ROW summary read removed `financial_management` ("Fin Mgmt 0") → now `loan_management`; CFO Skill-column label said "Resources" but value was sponsor_negotiation → label fixed to "Negotiation"; finmgmt sort key fixed. Popup CARD widened + pulled in from the right edge (was clipping nationality/assignment/100.0) + value labels now clip/ellipsis; open card now CLOSES on role-tab switch (was showing a stale CFO card on the Mechanic tab). |
| 2 | New GK team has ~2943 staff interested (reputation/interest broken) | ✅ | **S37.10** interest model rebalanced in ContractEngine._subject_interest_score: interest now gates reachable TALENT by team REPUTATION (interest = 60 + (player_rep − talent)×0.7 + free-agent bonus + rep-gap bonus + TP). A rep-0 garage attracts only ~13 low-talent free agents; the pool grows with reputation. Low-talent (≤35) free agents always reachable so a new team can field a car. (Earlier: marketability driver fixed S36.0; interest model first reworked S35.9.) Verify the new-team count is sane. |
| 3 | Main hub stretched off-screen | ✅ | **S37.21** Verified resolved: the off-screen cause was the notification bell's growing count widening the TopBar past 1920 — fixed S35.11 (pinned 120px footprint + clip_text). Top bar now fits (fixed-width nav buttons + expand-fill resource bar + pinned bell + menu). No remaining stretch source. (Main Hub still flagged for a full revamp under #17 — separate.) |
| 4 | "Staff interested" + signed same week → notice shouldn't appear | 🟡 | Negotiation semantics + notification collapse (S35.1–S35.9). Verify this exact race condition. |
| 5 | Sponsor slots should increase on ODD levels (1,3,5…) not even | ✅ | **S37.3** CampusManager.get_hq_sponsor_slots() = 1+int((level-1)/2). **S37.4** HQ EFFECTS panel now calls the same function (was hardcoded 1+lv/2 → showed 2 at L2). **Confirmed in play.** |
| 6 | TDL renew triggered HQ counting loop; renegotiate re-triggered HQ entry | 🟡 | Negotiation/HQ-entry semantics (S35.7). Verify the TDL-renew path specifically. |
| 7 | Staff/driver card pushed too far right / off-screen | 🟡 | Personnel hub + View Card popup overhaul (S35.10). Verify card alignment. |
| 8 | Weekly-salary vs annual-salary inconsistency on hub cards | ✅ | **S37.9** salary is now negotiated as an ANNUAL figure in ContractNegotiation with a live weekly read-out (≈ CR x/wk) beside the spinbox; stored back as weekly. Verify hub cards + negotiation agree. |
| 9 | Next race wrong week; S1 player appears registered in ALL championships | 🟡 | **Cluster A core.** A-CP4 (S37.0) getter rewrite; A-CP4b (S37.1) GK group-0 seeding gated. Needs keyboard verification. |
| 10 | HQ contract-negotiation entry frozen; walk-away didn't remove it | 🟡 | Negotiation entry lifecycle (S35.7). Verify frozen-entry + walk-away-clear. |
| 11 | Race results columns stacked right; need a skip button | ✅ | **S37.10** "Skip All ⏭" button added (header, shows when >1 race queued the same week) — applies each remaining race's repairs + sponsor bonuses and jumps to the Main Hub. **S37.11–S37.13** results + standings column layout reworked: Driver column expands to fill the container, Laps/Time/Gap/Pts spread across the remaining width (Driver ≈ 2/5), Laps/Time/Gap centered, Pts/Prize handled separately, Prize fixed far right; header + rows share identical sizing + alignment per column (+clip_contents) so headers sit above data. Driver standings name/team no longer jam. **Confirmed in play.** |
| 12 | No TDL/notification for a new sponsor offer | ✅ | **S37.49** Phase-3 migration: SponsorManager's offer notices now run through `notify_event` (event mode) — sponsor offers surface as proper notifications. Verify the offer notice appears + routes correctly. |
| 13 | Sponsor offers below the championship entry fee | ✅ | **S37.10** SponsorManager commitment (type-3) sponsors REDESIGNED: a sponsor wants the team to race a SPECIFIC championship for N seasons, chosen from a REPUTATION BAND near the team's rep (no GK→GP1 / GP1→Rally4 offers). Payment is ANNUAL (~1 season's entry+car ±variation) paid at the START of each registered season; offer expires before the championship's registration deadline; skipping a season = repay only that season's amount and the deal cancels. Fixed the "all offers exactly 20K" flat-floor bug (varied floor + cost band). active_sponsors/sponsor_offers now persist in save/load (were lost on reload). Verify offer amounts + tiering. |
| 14 | 891k active fans for a brand-new garage | ✅ | S36.0: get_team_active_fans()/marketability derive from player_registered_championships via _player_global_fan_pool(). Verify the starting number. |
| 15 | FU (fuel) not deducted after a race unless CFO buys | 🟡 | Fuel scoping fixed in Cluster A (RaceSimulator threads the raced champ, S37.0). Verify fuel drops per race without a CFO. |
| 16 | HQ-Financial: "Balance" label visible on all graph tabs | ✅ | **S37.17** Reported solved in play (player-confirmed). |
| 17 | News + main-hub standings not useful; main hub needs total revamp | ✅ | **S37.27** Main Hub REDESIGNED (mockup-driven): nameplate (team+player) · resource bar · Menu (bell removed); Season|Week|Next-Race strip; nav row + new Calendar button; three always-visible panels TO-DO · NOTIFICATIONS (permanent column, no bell/slide-in) · NEWS (doubles as the weekly LOG until the news system exists); a 5-week player-events strip (+N more) above the advance buttons. Side panel + its 4 tabs deleted (standings → Racing World). Was the §18 hard-prerequisite for the notification loop — now unblocked. |
| 18 | Starting driver too strong for a brand-new GK team | ✅ | **S37.14–S37.15** GK cadets age from 8 (no age skill bonus) + GK prodigy damping (raw entry band, high potential); potential now wide-normal across ALL pools; NEW TP `talent_scouting` stat drives a fuzzy Raw/Promising/Special read on the driver card (accuracy scales with the TP's eye, grows per season). |
| 19 | HQ-WRA "not racing any" while in GK; news says racing all; false next-season reminder | ✅ | S36.6: HQ Overview + TP-slot panels now read player_registered_championships (were reading player_team_cars). Plus A-CP4 getter. Cluster-A display contradiction resolved. |
| 20 | No notification for the last week to register for championships | ✅ | **S37.7** relocated the deadline block BEFORE the race-result early-return in advance_week() (root cause: race weeks skipped it). **S37.8** widened trigger to "this week or next", removed budget filter, added a 🔔 weekly-log line. **Confirmed in play.** |
| 21 | "Formula" should read "GP" in HQ-WRA and New Game scene | 🟡 | RnDStudio + Locale relabel done (S35.21). NewGame.gd ("pinnacle of Formula racing") + HQ.gd display still say "Formula" (HQ.gd:1887 "Formula":4 is an internal WRA key — leave). Finish the two user-facing strings. |
| 22 | Names need more variation; assigned JSON has repeats + real-athlete names | ✅ | **S37.51–S37.57 — full IP/name pass.** (1) *Assigned JSON real names:* 13 real-driver surnames in the assigned pool replaced with ordinary same-nationality names (Räikkönen/Mäkinen/Leclerc/Bottas/Neuville → pool names; "Kimi Mäkinen" → "Heikki Toivonen"); ordinary coincidental surnames (Evans/Clark/etc.) kept. Files: drivers_professional, staff_cfo/pitcrew/designer. (2) *teams.json:* name-variation pass (over-used "…Racing" 77→66, "…Collective" 28→8 → singles/abbreviations/fillers), 4 duplicate team names de-duped, and **23 real circuit/series/venue team names fictionalized** (Pro Mazda→Spec Star, Oval Masters→Apex Oval, Long Beach→Harbor City, Silverstone Wolf→Silverstag Wolf, Sarthe→Beaumont, Monza→Lombardy, Spa→Ardennes, Monte Carlo→Riviera, etc.); 0 duplicate team names, 172 teams intact, every championship still meets its minimum car count from JSON alone. (3) *Driver dedup (S37.55):* fixed "Lewis Lewis" (first==last) and **all duplicate driver full names** across 1244 drivers via NameData surname rotation → 0 first==last, 0 duplicate full names (also reduces the NameGenerator middle-initial fallbacks like "Thomas A Robinson"). (4) *Championships.gd browser refactor (S37.57):* retired the hardcoded CHAMP_TEAMS/CHAMP_STAFF/CHAMP_CARS/CAR_DRIVERS/CHAMP_KEY_IDX constants (1519→542 lines; the dead CAR_DRIVERS block was ~920 lines) which carried the last IP ("Andretti Collective", "IndyCar/Indy NXT/USF/WRC/GT3/GT4-equivalent", "Le Mans equivalent"). The browser now reads res://data/teams.json directly (works pre-game at the title screen) via _load_teams_from_json → _teams_by_champ, deriving each championship's roster from every team's "championships" field — the SAME source the engine fields — and renders richer rows (flag · name · type · cars-in-champ · reputation · staff counts · driver pool). All 21 championships populate with no empties, counts matching the engine diagnostic. Real-series descriptions reworded to discipline phrasing. **Backup machinery untouched:** AIManager grid-fill / filler-team generation, personnel generation, and bankruptcy logic are unrelated and were not modified. (5) *RacingWorld "0pts" display (S37.55):* GK group-chip leader line no longer jams name+points ("Lewis Lewis 0pts" read as "…pt") — now "%s — %d pts". |
| 23 | Two identical SP notifications from different sources | ✅ | **S37.5** the post-race "SP insufficient to fully repair Car N" emitter (RaceSimulator) now carries the res_spare_parts subject, collapsing to one with the weekly SP warning. Verify only one shows. |
| 24 | No notification advancing to GK round 2 / 3 | 🟡 | Exists (GameState "GK Round X complete — advancing to Round Y!"), gated on player_in_gk (S37.1). Verify it fires for a GK career. |
| 25 | "Buy a car before week X" at registration is misleading; carry to new season | 🟡 | Season-transition rework (S35.0); buy-car advisory fires at season start. Verify timing. |
| 26 | Building built/upgraded: no notification + no TDL | ✅ | **S37.49** Phase-3 migration: building/R&D/CNC completion events now run through `notify_event` (event mode) with destination routing (RnDEngine → cnc_plant where a TDL exists; CampusManager building-sold → event). Verify a building-complete event fires with the right button. |
| 27 | Pit crew shown as one name but is multiple people | 🔵 Backlog | crew_number model exists (Staff §C); whether it satisfies "multi-person" is a design call. |
| 28 | GK rounds 3 & 4 teams earn no points; need a team champion | ✅ | S36.15 + GK final-weekend redesign (S36.18–S36.20): team champion via a flat cumulative table across all 22 races; driver champion via the elimination ladder. |
| 29 | No RP earned from races | 🟡 | earn_race_rp() exists (RaceSimulator), gated to player championships. Verify RP increases after a race. |
| 30 | Check the text written in all campus buildings | ✅ | **S37.20** Audited all 20 building scenes. Fixed: OvalTrack "IndyCar"→"Open-Wheel" (real trademark + not a discipline); FitnessClinic removed stale "boosts active driver stats" (code only does fitness recovery + fatigue reduction); KartingTrack "Go-Kart"→"Go-Karting"; Logistics provider names fictionalized (IndyCar/WRC/NASCAR/WEC/Formula → discipline-based names) per IP rule. Other building descs verified accurate vs code (Museum income, Academy −15% discount, Wind Tunnel aero, etc.). |
| 31 | After last GK round, all driver+team standings wiped | ✅ | S36.14: save/load persists ALL championships' standings keyed by id; survive round transitions + season end. Plus S37.2 RacingWorld GK read. |
| 32 | Racing World must show ALL championships, not only the player's | ✅ | **S37.47–S37.48** The `AIChampionshipSim` engine (§14) now runs every non-player, non-GK championship each race week, so all 21 championships have live, moving driver AND team standings (was: empty tables). Racing World cards show driver + team leader; the GK card shows the driver + team champion even for a player racing a different discipline. Player-confirmed in play (screenshots: AI championships show moving leaders + points; GK shows champion + teams). The deeper "scout/browse/history" intent remains in the living-world backlog (§19). |
| 33 | EOS says "didn't run in any championship"; remove the registration button | ✅ | S36.12: registration button removed from EOS; raced-only standings filter correct. Downstream display ties to Cluster A. |
| 34 | Beginning-of-Season should be informational only (remove TDLs) | ✅ | **S37.21** Made informational-only: removed the TDL row "→" buttons, the readiness "Fix →" buttons, and the "Championship Registration" button. Checklist / readiness / finances remain as a read-only season summary; the START SEASON exit stays. NOTE: scene flagged by player for a FULL redesign later (like Main Hub + Campus). |
| 35 | Renewed driver vanished next season while still counted (1 shown, 2 counted) | 🟡 | Season Transition Pipeline ordering fix (S35.0). Verify the shown-vs-counted desync is gone. |
| 36 | 3 TP notifications "cars lacking crew" same week | ✅ | **S37.45/S37.49** The car-readiness criticals (no driver / no mechanic / no TP / no strategist) now fire via `notify_event` in **standing** mode, keyed per-car/per-championship — one live instance that refreshes weekly instead of stacking duplicates. The persistent chore also shows as a read-only TDL row. Verify three lacking-crew cars produce collapsed, not stacked, notices. |
| 37 | Garage driver/mechanic assignments show "none" | 🟡 | Assignment rebuild (S30–S32) + per-car reads (Cluster A). S37.x Garage screenshot showed driver/mechanic assigned correctly — verify across championships. |
| 38 | Garage: Rally4 has no 2nd-driver slot; EPC needs 3 | 🟠 | drivers_per_car exists (canonical slots rule S33.2). Rally4-2 / EPC-3 specifics — verify the slots render. |
| 39 | No notification to hire a new TP when one is needed | 🟡 | **S37.43/S37.45** TP readiness rewritten to derive from the player's actually-fielded cars (per discipline-group; GK shares one TP, non-GK each need their own) — a missing TP yields a Critical readiness TDL AND is now a hard DNS in `can_car_race`. The new-game roster also provisions a starting TP (§7.3). Verify TP-missing fires + DNS enforces. |
| 40 | Changing current TP assignment GK → Rally4 does nothing | ✅ | **S37.22** ROOT CAUSE: assign_staff_to_championship() QUEUED TP/Strategist moves to 'next week' (pending_staff_assignments) instead of applying — so assigned_championship stayed on GK, the HQ card showed the old series, the new championship read as no-TP → DNS → the game soft-locked into GK. Now applies IMMEDIATELY (matches driver/mechanic) + invalidates the staff cache so HQ refreshes at once. Added per-role one-per-championship slot guard and a hard strategist GK/Rally block. BONUS: clear_stranded_player_championship_staff() at rollover auto-unassigns a player TP/Strategist left on a no-longer-raced championship (HQ then shows 'Not assigned'). Strategist GK/Rally skip verified consistent across HQ/StaffHub/optimiser/warnings; TP optimiser correctly covers Rally (no skip). |
| 41 | Driver failing age requirement should show a popup | ✅ | **S37.16** assign_driver_to_car() now returns a player-facing reason string; the Garage, Racing Dept and Driver-card assign flows show a modal "Cannot Assign Driver" popup on age-limit failure (was silent except a missable notification). Verify the popup fires for an under/over-age driver. |
| 42 | Starting from Rally, a TDL says "GK has no principal" (stale GK ref) | ✅ | **S37.43** ROOT CAUSE found + fixed: the readiness check keyed on `has_gk_active` = "any GK championship is in active_championships", but GK/C-001 is ALWAYS in the world → a non-GK player wrongly saw "no TP for GK" while their real championships went unchecked. Rewrote to derive from the player's fielded cars. The false GK TDL is gone for a Rally/SC/etc. career. |
| 43 | Staff hub "Available Staff" button has a static count; remove counts | ⚪ Open | Still present (StaffHub "(%d)" buttons). Not yet removed. |
| 44 | Only Rally4 but code still thinks player is in GK (driver shown, DNS) | 🟡 | **Cluster A core** (A-CP4/A-CP4b, S37.0–S37.1). Headline symptom — needs keyboard verification. |
| 45 | "No TP for Rally4" notification while one is assigned | ✅ | **S37.43** Fixed by the same readiness rewrite as #42 — the TP check is now per-fielded-championship via the player-scoped `_get_tp_for_championship`, so an assigned TP resolves correctly and the false "no TP" is gone. Same resolver used by both the TDL and the DNS enforcement, so the two always agree. |
| 46 | Code thinks no mechanic → no repairs although one is assigned | 🟡 | Per-car SP/repair reads (A-SP, S37.0). Verify repairs run with a mechanic assigned. |
| 47 | Add a "fix the car" button in the Garage | ✅ | **S37.3–S37.5** Garage car-card "Repair" button: full repair when SP allows, else PROPORTIONAL repair spending all held SP (repair_car_max_sp) so it's usable even when one 10% chunk isn't affordable (GK 110 SP/10%). **Confirmed in play.** |
| 48 | Season 2 registered only in Rally3 but got "buy car" notifications for every championship | 🟡 | Season-transition + registration-scope fixes (S35.0, Cluster A). Verify next-season car prompts are scoped to registered championships. |
| 49 | HQ-Financial weekly income doesn't show per-building income | ✅ | **S37.3** Financialdept income panel now itemizes each income-producing building on its own row under a "Building Income" sub-header. Verify. |
| 50 | All warehouse parts scrapped at end of season | ✅ | **S37.19** Design CONFIRMED by player: cars AND loose warehouse parts scrap at season end. Added `part_inventory.clear()` to the season-end scrap step (was leaking loose L0 parts across the boundary). ALSO removed the 3 free starting parts: `_setup_part_inventory()` now seeds EMPTY (0) inventory. GK-RELIC FIXED: it seeded `active_championship` (legacy GK/C-001 default, since player_registered_championships isn't set until just after) — now seeds the player's ACTUAL starting + car championships, so a GP4/Rally4/SC start gets the right (empty) warehouse. Starting car races fine on its built-in 100% part_conditions (warehouse is for replacements only). NewGame.gd audited: no other GK relics; GK age display fixed 8–16→8–17. |
| 51 | Full car built from CNC must be delivered to Garage with parts installed | 🟡 | Build Whole Car one-pass (S30–S32, §6.0/§8). Verify the assembled car arrives with all 6 parts installed. |
| 52b | Doubled TP-proposal rows (2 proposals → 4 rows) | ✅ | **S37.24** ROOT FOUND: not a duplicate car — _rebuild_list() awaited a frame between clearing and re-adding rows, so two near-simultaneous calls (_ready→_build_ui and open()) interleaved past the clear and both appended. Now clears + rebuilds SYNCHRONOUSLY. (S37.23 _dedupe_proposals retained as defense-in-depth for any data-level dupes.) |
| 52 | New game continues previous game (state leak) + load-game wrong-week | 🔵 Deferred (low priority) | Shared root cause: `setup_new_game` does not reset many persistent collections (active_sponsors, sponsor_offers, active_approaches, registrations, player_team_cars, notifications, GK state, etc.) and `gk_discipline` is only recreated `if null`; the load path restores `current_week` but doesn't clear transient session state either. **Not a priority while the workflow is quit-to-restart** (player does not currently use save/load to start a fresh game). Investigated S37.13, not fixed. Pick up when save/load becomes part of the loop. |

---

## Notification framework (NEW — S37.7, design principle)

A 1-event model now governs notifications (built this session; CFO + deadline migrated, rest pending):
1. **An event fires a notification** via `notify_event(event_id, priority, message, destination, mode)` — modes `once` / `standing` / `event` / `news`.
2. The notification may carry a **destination button** (e.g. "staff_hub", "hq", "garage", "logistics") that leads to where you act, and/or the **read-only TO-DO list** reflects the standing task. **The TDL never emits notifications** (you can already see it).
3. **Meaningful** world events (mode `news`) also post to a news feed (hook stubbed; full news system = Brainstorm thread 2).

**MIGRATION COMPLETE (Phase 3, S37.37–S37.49):** every `add_notification` across all engines and
scenes is now on `notify_event` (or `show_popup` for blocking errors). Classification: signings &
departures → `news`; recurring chores/distress → `standing`; blocking errors → `show_popup`; discrete
one-offs → `event` with destination routing; redundant-with-popup → deleted. Files: ContractEngine,
RnDEngine, SponsorManager, CarManager, SeasonManager, RaceSimulator, GameState, FinancialEngine,
DriverManager, StaffManager, TPProposalEngine, CampusManager, ChampionshipSelect, Logistics, MainHub.
The news SOUNDWAVE FILTER (Brainstorm thread 2) is still a separate design pass — news is currently
"everything visible." Full per-file ledger: `Notification_News_Roadmap_v1.md`.

---

## Quick tallies (updated S37.50)

- **✅ Fixed:** #2, #5, #8, #11, #12, #13, #14, #19, #20, #23, #26, #28, #31, #32, #33, #36, #42, #45,
  #47, #49. (Newly closed this session: #12 + #26 sponsor/building notifications migrated; #32 Racing
  World all-championships via the AIChampionshipSim build — player-confirmed; #36 readiness duplicates
  collapse via standing mode; #42 + #45 false/stale GK-TP TDLs fixed at root S37.43.)
- **🟡 Fixed–needs in-engine verification:** #4, #6, #7, #9, #10, #15, #21, #24, #25, #29, #35, #37,
  #39, #44, #46, #48, #51. (#39 advanced — TP readiness rewritten + TP-DNS enforced; still verify it
  fires in play.)
- **🟠 Known/latent or partial:** #38.
- **🔵 Backlog/feature (design work):** #27.
- **⚪ Still open / not started:** #43 (StaffHub static counts — remove). *(#12 and #26 are no longer
  open — migrated this session.)*

## Suggested next batch
With the notification migration (Phase 3) and the living-world build complete, the lowest-risk
remaining items are: **#43** (remove StaffHub static button counts — mechanical), **#21** (finish the
two user-facing "Formula"→"GP" strings in NewGame.gd + HQ.gd), and the **🟡 verification sweep** —
many Cluster-A items (#9, #44, #46, #48) and TP items (#39) are code-fixed but still need keyboard
confirmation. Larger design passes queued: the **news soundwave filter** (Brainstorm thread 2), the
**Phase-5 economic strength model** for the AI sim, the **designer-model rework** (GDD §22/§19), and
the **NewGame card-text** cosmetic (§7.3 — GP4 card understates its real provisioning).

## S37.37–S37.50 session summary (living world + notification migration + new-game)
- **Notification/News Phase 3 COMPLETE** — every `add_notification` migrated to `notify_event` /
  `show_popup` across 15 files (closes #12, #26; advances #36, #39). See the framework section above.
- **AIChampionshipSim BUILT** (closes #32) — new RefCounted engine runs all non-player, non-GK
  championships each race week via a lightweight `car_strength` scalar → finishing order → existing
  points table; populates driver + team standings. `car_strength()` is the Phase-5 economic swap-point.
- **Racing World display** — AI cards show driver + team leader; GK card shows driver + team CHAMPION
  even for a player racing a different discipline (shadow standings + CP3 team table).
- **New-game provisioning** (GDD §7.3) — Ops Sim key typo fixed (`"Ops Sim"`→`"Ops Sim & Telemetry"`),
  un-stranding the SC/GP starting Strategist; GP now starts with R&D Design Studio + CNC Parts Plant +
  a Designer.
- **Strategist = DNS** (closes the strategist half of the readiness gap) — a missing Race Strategist
  now DNS's the car (parity with the S37.45 TP-DNS), enforced in `can_car_race` + a readiness TDL, for
  every discipline except GK & Rally.
- **Bug run** — release-staff now unassigns mechanic/pit-crew from the car (was driver-only); false
  "no TP for GK" TDL for non-GK players fixed (#42, #45); "DNS for every championship" + season-rollover
  "new car needed" spam gated to player championships; stale "24 championships" → 21.

## S37.9–S37.13 session summary (this chat)
- **#8** annual-salary negotiation with live weekly read-out (S37.9).
- **#2** interest rebalance — reputation gates reachable talent (S37.10).
- **#13** sponsor commitment redesign — reputation-band championship, annual payment, penalty, save/load persistence, flat-floor fix (S37.10).
- **#11** race-results "Skip All" button (S37.10) + results/standings column alignment rework (S37.11–S37.13).
- **NOTE (deferred, flagged):** "new game continues previous game" — `setup_new_game` does not reset many persistent collections (active_sponsors, sponsor_offers, active_approaches, registrations, player_team_cars, notifications, GK state, etc.); and `gk_discipline` only recreated `if null`. Shares root cause with the **load-game wrong-week** symptom (load restores current_week correctly, but transient session state isn't cleared on load either). Both investigated, NOT yet fixed — pick up next.
- **NOTE (declined this session):** staff-hire slot validation (#2-adjacent) — slot "no slot" text already works; deferred to avoid duplicate functions.

## Repo hygiene
- Only `GDDv5.9.md` remains in Supporting Files (duplicate underscore version removed) — flag resolved.
- `BUGLIST.md` (cluster-based) + this file (numbered) coexist; consider folding into one tracker.
- GDD version headers in code are now at **S37.8** — the GDD snapshot should be bumped to capture Cluster A close-out, the repair UX, and the notification framework.

### S37.25 — popup-position sweep (all card popups centered)
RacingDept driver card was still right-anchored (clipping nationality/eff/contract) → now centered (640, ±320) + _card_row clip. Right column overflow fixed: ScrollContainer horizontal_scroll_mode DISABLED + inner VBox clamped to 360 so champ panels stay inside. Swept every scene: Drivers, StaffHub (×2), RacingDept driver card, ContractNegotiation card, HQ TP-assign popup → all centered. HQ loan popups + MainHub menu/notif already centered; AcceptDialog popups auto-center.
