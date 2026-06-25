# Automotive Empire — Original 51-Item List, Reconciled Against Shipped Code

**Reconciled:** 2026-06-25 · against repo HEAD `52a7206` (S37.13) + GDD v6.0 changelog (S28–S37.13).
**Status legend:** ✅ Fixed (incl. player-confirmed in play) · 🟡 Fixed–needs in-engine verification · 🟠 Known/latent (partial or no-op until data added) · 🔵 Backlog/feature (design-approved, sequenced later) · ⚪ Open/unassigned.

> Note: GitHub is authoritative. This maps your ORIGINAL numbered list (1–51) onto the work that
> has actually shipped. The live tracker in `Supporting Files/BUGLIST.md` is cluster-based
> (A-CP4, A-STD, …); this file is the bridge between the two.
> **Items marked ✅ (confirmed) were verified in-game during the S37.3–S37.8 sessions via screenshots.**

---

| # | Item | Status | Where / how addressed |
|---|------|--------|-----------------------|
| 1 | CFO financial-mgmt attributes all 0 | ⚪ Open | Separate from the CFO *notification* work (done). The all-0 attribute display is still unconfirmed — likely a card reading a non-existent field. Still to do. |
| 2 | New GK team has ~2943 staff interested (reputation/interest broken) | ✅ | **S37.10** interest model rebalanced in ContractEngine._subject_interest_score: interest now gates reachable TALENT by team REPUTATION (interest = 60 + (player_rep − talent)×0.7 + free-agent bonus + rep-gap bonus + TP). A rep-0 garage attracts only ~13 low-talent free agents; the pool grows with reputation. Low-talent (≤35) free agents always reachable so a new team can field a car. (Earlier: marketability driver fixed S36.0; interest model first reworked S35.9.) Verify the new-team count is sane. |
| 3 | Main hub stretched off-screen | 🟠 | Layout-stretch pattern applied to several screens (S35.10, S29.x). Main Hub flagged for total revamp under #17 — verify current state. |
| 4 | "Staff interested" + signed same week → notice shouldn't appear | 🟡 | Negotiation semantics + notification collapse (S35.1–S35.9). Verify this exact race condition. |
| 5 | Sponsor slots should increase on ODD levels (1,3,5…) not even | ✅ | **S37.3** CampusManager.get_hq_sponsor_slots() = 1+int((level-1)/2). **S37.4** HQ EFFECTS panel now calls the same function (was hardcoded 1+lv/2 → showed 2 at L2). **Confirmed in play.** |
| 6 | TDL renew triggered HQ counting loop; renegotiate re-triggered HQ entry | 🟡 | Negotiation/HQ-entry semantics (S35.7). Verify the TDL-renew path specifically. |
| 7 | Staff/driver card pushed too far right / off-screen | 🟡 | Personnel hub + View Card popup overhaul (S35.10). Verify card alignment. |
| 8 | Weekly-salary vs annual-salary inconsistency on hub cards | ✅ | **S37.9** salary is now negotiated as an ANNUAL figure in ContractNegotiation with a live weekly read-out (≈ CR x/wk) beside the spinbox; stored back as weekly. Verify hub cards + negotiation agree. |
| 9 | Next race wrong week; S1 player appears registered in ALL championships | 🟡 | **Cluster A core.** A-CP4 (S37.0) getter rewrite; A-CP4b (S37.1) GK group-0 seeding gated. Needs keyboard verification. |
| 10 | HQ contract-negotiation entry frozen; walk-away didn't remove it | 🟡 | Negotiation entry lifecycle (S35.7). Verify frozen-entry + walk-away-clear. |
| 11 | Race results columns stacked right; need a skip button | ✅ | **S37.10** "Skip All ⏭" button added (header, shows when >1 race queued the same week) — applies each remaining race's repairs + sponsor bonuses and jumps to the Main Hub. **S37.11–S37.13** results + standings column layout reworked: Driver column expands to fill the container, Laps/Time/Gap/Pts spread across the remaining width (Driver ≈ 2/5), Laps/Time/Gap centered, Pts/Prize handled separately, Prize fixed far right; header + rows share identical sizing + alignment per column (+clip_contents) so headers sit above data. Driver standings name/team no longer jam. **Confirmed in play.** |
| 12 | No TDL/notification for a new sponsor offer | ⚪ Open | Candidate for the notify_event framework (S37.7) — not yet migrated. Still to do. |
| 13 | Sponsor offers below the championship entry fee | ✅ | **S37.10** SponsorManager commitment (type-3) sponsors REDESIGNED: a sponsor wants the team to race a SPECIFIC championship for N seasons, chosen from a REPUTATION BAND near the team's rep (no GK→GP1 / GP1→Rally4 offers). Payment is ANNUAL (~1 season's entry+car ±variation) paid at the START of each registered season; offer expires before the championship's registration deadline; skipping a season = repay only that season's amount and the deal cancels. Fixed the "all offers exactly 20K" flat-floor bug (varied floor + cost band). active_sponsors/sponsor_offers now persist in save/load (were lost on reload). Verify offer amounts + tiering. |
| 14 | 891k active fans for a brand-new garage | ✅ | S36.0: get_team_active_fans()/marketability derive from player_registered_championships via _player_global_fan_pool(). Verify the starting number. |
| 15 | FU (fuel) not deducted after a race unless CFO buys | 🟡 | Fuel scoping fixed in Cluster A (RaceSimulator threads the raced champ, S37.0). Verify fuel drops per race without a CFO. |
| 16 | HQ-Financial: "Balance" label visible on all graph tabs | ⚪ Open | Investigated S37.4: graphs live in HQ.gd (balance/fuel/economy/fans/marketability); redraw already does queue_free + await frame, so code looks correct. Left untouched — needs a live repro to see what actually persists. |
| 17 | News + main-hub standings not useful; main hub needs total revamp | 🔵 Backlog | Design revamp, not a point fix. |
| 18 | Starting driver too strong for a brand-new GK team | ✅ | **S37.14–S37.15** GK cadets age from 8 (no age skill bonus) + GK prodigy damping (raw entry band, high potential); potential now wide-normal across ALL pools; NEW TP `talent_scouting` stat drives a fuzzy Raw/Promising/Special read on the driver card (accuracy scales with the TP's eye, grows per season). |
| 19 | HQ-WRA "not racing any" while in GK; news says racing all; false next-season reminder | ✅ | S36.6: HQ Overview + TP-slot panels now read player_registered_championships (were reading player_team_cars). Plus A-CP4 getter. Cluster-A display contradiction resolved. |
| 20 | No notification for the last week to register for championships | ✅ | **S37.7** relocated the deadline block BEFORE the race-result early-return in advance_week() (root cause: race weeks skipped it). **S37.8** widened trigger to "this week or next", removed budget filter, added a 🔔 weekly-log line. **Confirmed in play.** |
| 21 | "Formula" should read "GP" in HQ-WRA and New Game scene | 🟡 | RnDStudio + Locale relabel done (S35.21). NewGame.gd ("pinnacle of Formula racing") + HQ.gd display still say "Formula" (HQ.gd:1887 "Formula":4 is an internal WRA key — leave). Finish the two user-facing strings. |
| 22 | Names need more variation; assigned JSON has repeats + real-athlete names | 🟠 | NameData expanded (60 nationalities, MCO/KEN added). The real-name-collision audit of the assigned JSON is still pending. |
| 23 | Two identical SP notifications from different sources | ✅ | **S37.5** the post-race "SP insufficient to fully repair Car N" emitter (RaceSimulator) now carries the res_spare_parts subject, collapsing to one with the weekly SP warning. Verify only one shows. |
| 24 | No notification advancing to GK round 2 / 3 | 🟡 | Exists (GameState "GK Round X complete — advancing to Round Y!"), gated on player_in_gk (S37.1). Verify it fires for a GK career. |
| 25 | "Buy a car before week X" at registration is misleading; carry to new season | 🟡 | Season-transition rework (S35.0); buy-car advisory fires at season start. Verify timing. |
| 26 | Building built/upgraded: no notification + no TDL | ⚪ Open | Prime candidate for notify_event ("event" mode + Garage/Campus destination button). Not yet done. |
| 27 | Pit crew shown as one name but is multiple people | 🔵 Backlog | crew_number model exists (Staff §C); whether it satisfies "multi-person" is a design call. |
| 28 | GK rounds 3 & 4 teams earn no points; need a team champion | ✅ | S36.15 + GK final-weekend redesign (S36.18–S36.20): team champion via a flat cumulative table across all 22 races; driver champion via the elimination ladder. |
| 29 | No RP earned from races | 🟡 | earn_race_rp() exists (RaceSimulator), gated to player championships. Verify RP increases after a race. |
| 30 | Check the text written in all campus buildings | ⚪ Open | Content audit. Still to do. |
| 31 | After last GK round, all driver+team standings wiped | ✅ | S36.14: save/load persists ALL championships' standings keyed by id; survive round transitions + season end. Plus S37.2 RacingWorld GK read. |
| 32 | Racing World must show ALL championships, not only the player's | 🟡 | RacingWorld builds a card per championship; S37.2 added GK world results to the world card. Verify all appear. (Living-world depth = F-AICHAMP backlog.) |
| 33 | EOS says "didn't run in any championship"; remove the registration button | ✅ | S36.12: registration button removed from EOS; raced-only standings filter correct. Downstream display ties to Cluster A. |
| 34 | Beginning-of-Season should be informational only (remove TDLs) | 🟠 | Partially via season-transition rework (S35.0). The informational-only redesign — verify completeness. |
| 35 | Renewed driver vanished next season while still counted (1 shown, 2 counted) | 🟡 | Season Transition Pipeline ordering fix (S35.0). Verify the shown-vs-counted desync is gone. |
| 36 | 3 TP notifications "cars lacking crew" same week | 🟡 | Notification collapse with subject (S35.1–S35.4). Verify duplicates collapse to one. |
| 37 | Garage driver/mechanic assignments show "none" | 🟡 | Assignment rebuild (S30–S32) + per-car reads (Cluster A). S37.x Garage screenshot showed driver/mechanic assigned correctly — verify across championships. |
| 38 | Garage: Rally4 has no 2nd-driver slot; EPC needs 3 | 🟠 | drivers_per_car exists (canonical slots rule S33.2). Rally4-2 / EPC-3 specifics — verify the slots render. |
| 39 | No notification to hire a new TP when one is needed | 🟡 | NotificationManager appends "No Team Principal" tasks. CFO (the optional analogue) reworked S37.6–S37.7. Verify TP-missing fires. |
| 40 | Changing current TP assignment GK → Rally4 does nothing | 🟠 | TP Assignment cluster (deferred; TP_Assignment_System_Spec_v2). The reassignment action itself — verify / still open. |
| 41 | Driver failing age requirement should show a popup | ✅ | **S37.16** assign_driver_to_car() now returns a player-facing reason string; the Garage, Racing Dept and Driver-card assign flows show a modal "Cannot Assign Driver" popup on age-limit failure (was silent except a missable notification). Verify the popup fires for an under/over-age driver. |
| 42 | Starting from Rally, a TDL says "GK has no principal" (stale GK ref) | 🟡 | GK-gating (S31, S37.1 player_in_gk). Verify the stale GK TDL is gone for a Rally career. |
| 43 | Staff hub "Available Staff" button has a static count; remove counts | ⚪ Open | Still present (StaffHub "(%d)" buttons). Not yet removed. |
| 44 | Only Rally4 but code still thinks player is in GK (driver shown, DNS) | 🟡 | **Cluster A core** (A-CP4/A-CP4b, S37.0–S37.1). Headline symptom — needs keyboard verification. |
| 45 | "No TP for Rally4" notification while one is assigned | 🟡 | GK-gating + HQ TP-slot fix (S36.6, S37.1). Verify the false no-TP notification is gone. |
| 46 | Code thinks no mechanic → no repairs although one is assigned | 🟡 | Per-car SP/repair reads (A-SP, S37.0). Verify repairs run with a mechanic assigned. |
| 47 | Add a "fix the car" button in the Garage | ✅ | **S37.3–S37.5** Garage car-card "Repair" button: full repair when SP allows, else PROPORTIONAL repair spending all held SP (repair_car_max_sp) so it's usable even when one 10% chunk isn't affordable (GK 110 SP/10%). **Confirmed in play.** |
| 48 | Season 2 registered only in Rally3 but got "buy car" notifications for every championship | 🟡 | Season-transition + registration-scope fixes (S35.0, Cluster A). Verify next-season car prompts are scoped to registered championships. |
| 49 | HQ-Financial weekly income doesn't show per-building income | ✅ | **S37.3** Financialdept income panel now itemizes each income-producing building on its own row under a "Building Income" sub-header. Verify. |
| 50 | All warehouse parts scrapped at end of season | 🟠 | Cars scrapped each season is intended (Phase 2, §6.0); whether loose warehouse PARTS should also scrap is a design question — verify intended vs bug. |
| 51 | Full car built from CNC must be delivered to Garage with parts installed | 🟡 | Build Whole Car one-pass (S30–S32, §6.0/§8). Verify the assembled car arrives with all 6 parts installed. |
| 52 | New game continues previous game (state leak) + load-game wrong-week | 🔵 Deferred (low priority) | Shared root cause: `setup_new_game` does not reset many persistent collections (active_sponsors, sponsor_offers, active_approaches, registrations, player_team_cars, notifications, GK state, etc.) and `gk_discipline` is only recreated `if null`; the load path restores `current_week` but doesn't clear transient session state either. **Not a priority while the workflow is quit-to-restart** (player does not currently use save/load to start a fresh game). Investigated S37.13, not fixed. Pick up when save/load becomes part of the loop. |

---

## Notification framework (NEW — S37.7, design principle)

A 1-event model now governs notifications (built this session; CFO + deadline migrated, rest pending):
1. **An event fires a notification** via `notify_event(event_id, priority, message, destination, mode)` — modes `once` / `standing` / `event` / `news`.
2. The notification may carry a **destination button** (e.g. "staff_hub", "hq", "garage", "logistics") that leads to where you act, and/or the **read-only TO-DO list** reflects the standing task. **The TDL never emits notifications** (you can already see it).
3. **Meaningful** world events (mode `news`) also post to a news feed (hook stubbed; full news system = Brainstorm thread 2).

**Migrated so far:** CFO (read-only TDL row + one-time `notify_event("no_cfo", once)` with a Staff button), registration deadline. **Pending migration:** TP (#39/#42/#45), fuel/SP (#15/#23), building completion (#26), sponsor offer (#12), signings/titles/top-tier entry (news).

---

## Quick tallies (S37.13)

- **✅ Fixed:** #2, #5, #8, #11, #13, #14, #19, #20, #23, #28, #31, #33, #47, #49. (Confirmed in play: #5, #11, #20, #47; rest by changelog — verify the S37.9–S37.13 batch in-engine: #2 interest count, #8 salary units, #13 sponsor amounts.)
- **🟡 Fixed–needs in-engine verification:** #4, #6, #7, #9, #10, #15, #21, #24, #25, #29, #32, #35, #36, #37, #39, #42, #44, #45, #46, #48, #51.
- **🟠 Known/latent or partial:** #3, #22, #34, #38, #40, #50.
- **🔵 Backlog/feature (design work):** #17, #27.
- **⚪ Still open / not started:** #1, #12, #16, #26, #30. (#43 already done S37.9; #18 done S37.14–15; #41 done S37.16.)

## Suggested next batch (the ⚪ Open, lowest-risk)
Mechanical, no re-fix risk: **#18** (starting-driver balance), **#41** (age-requirement popup), **#43** (remove hub button counts), **#30** (campus building text audit), **#1** (CFO all-0 attributes). Then notification-framework migrations: **#12, #26** (sponsor offer / building completion as `notify_event` with buttons).

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
