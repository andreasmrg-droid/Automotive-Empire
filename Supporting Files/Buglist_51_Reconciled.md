# Automotive Empire — Original 51-Item List, Reconciled Against Shipped Code

**Reconciled:** 2026-06-25 · against repo HEAD `8a4eec6` (bugs16) + GDD v5.9 changelog (S28–S37.1).
**Status legend:** ✅ Fixed · 🟡 Fixed–needs in-engine verification · 🟠 Known/latent (partial or no-op until data added) · 🔵 Backlog/feature (design-approved, sequenced later) · ⚪ Open/unassigned.

> Note: GitHub is authoritative. This maps your ORIGINAL numbered list (1–51) onto the work that
> has actually shipped. The live tracker in `Supporting Files/BUGLIST.md` is now cluster-based
> (A-CP4, A-STD, …) rather than numbered — this file is the bridge between the two.

---

| # | Item | Status | Where / how addressed |
|---|------|--------|-----------------------|
| 1 | CFO financial-mgmt attributes all 0 | ⚪ Open | Not found in any changelog. Still to do. |
| 2 | New GK team has ~2943 staff interested (reputation/interest broken) | 🟡 | Interest model reworked S35.9 (deterministic binary person-interest). Verify the new-team count is now sane. |
| 3 | Main hub stretched off-screen | 🟠 | Layout-stretch pattern (size_flags, ScrollContainer) applied to several screens (S35.10, S29.x). Main Hub specifically flagged for a TOTAL revamp under #17 — verify current state. |
| 4 | "Staff interested" + signed same week without leaving negotiation → notice shouldn't appear | 🟡 | Negotiation semantics + notification collapse (S35.1–S35.4, S35.7/9). Verify this exact race condition. |
| 5 | Sponsor slots should increase on ODD levels (1,3,5…) not even | ⚪ Open | Not found in changelog. Still to do. |
| 6 | TDL renew triggered the HQ counting loop; every renegotiate press re-triggered HQ entry | 🟡 | Negotiation/HQ-entry semantics reworked (S35.7: Walk-Away leaves a persistent entry cleared next week; Close is a no-op). Verify the TDL-renew path specifically. |
| 7 | Staff/driver card pushed too far right / off-screen | 🟡 | Personnel hub + View Card popup overhaul (S35.10). Verify card alignment. |
| 8 | Weekly-salary vs annual-salary inconsistency on hub cards | ⚪ Open | Not found in changelog. Still to do. |
| 9 | Next race wrong week; S1 player appears registered in ALL championships though only GK entered | 🟡 | **Cluster A core.** A-CP4 (S37.0): `active_championship` getter rewritten to resolve the player's real championship. A-CP4b (S37.1): GK group-0 seeding gated to real GK drivers. Needs keyboard verification. |
| 10 | HQ contract-negotiation entry frozen at round 1 after 3 weeks; walk-away didn't remove it | 🟡 | Negotiation entry lifecycle (S35.7). Verify the frozen-entry + walk-away-clear behaviour. |
| 11 | Race results columns stacked right; need a skip button | ⚪ Open | Not found in changelog. Column spacing + skip-results button still to do. |
| 12 | No TDL/notification for a new sponsor offer | ⚪ Open | Not found in changelog. Still to do. |
| 13 | Sponsor offers below the championship entry fee | ⚪ Open | Not found in changelog. Still to do. |
| 14 | 891k active fans for a brand-new garage | 🟡 | Fan/reputation baseline ties to the interest/reputation rework (S35.9) and was discussed in the fan-pyramid thread. Verify the starting fan number. |
| 15 | FU (fuel) not deducted after a race unless CFO buys constantly | 🟡 | Fuel scoping fixed in Cluster A (RaceSimulator threads the raced champ through fuel reads, S37.0). Earlier the parked-car/GK mismatch masked deductions. Verify fuel now drops per race without a CFO. |
| 16 | HQ-Financial: "Balance" label visible on all graph tabs | ⚪ Open | Not found in changelog. Still to do. |
| 17 | News + main-hub standings window not useful; main hub needs total revamp | 🔵 Backlog | Design revamp, scheduled as design work (was listed under "Design revamps" in the prior buglist). Not a point fix. |
| 18 | Starting driver too strong for a brand-new GK team | ⚪ Open | Not found in changelog. Still to do (balance). |
| 19 | HQ-WRA "not racing any championship" while in GK; news says racing all; week-20 false "not registered next season" | 🟡 | Cluster A (A-CP4, S37.0): registration-state reads now resolve to the real championship; HQ uses registrations. Verify the contradictory-state messages are gone. |
| 20 | No notification for the last week to register for championships | ⚪ Open | Not found in changelog. Still to do. |
| 21 | "Formula" should read "GP" in HQ-WRA and New Game scene | ✅ | User-facing "Formula" → "GP" relabel (v5.8 / S35.x); internal WRA-group keys unchanged. |
| 22 | Names need more variation; assigned-drivers/staff JSON has repetitions + real-athlete names | 🟠 | NameData expanded to 60 nationalities (logs show "Loaded 60 nationalities"); MCO/KEN added (S24 plan). The real-name-collision audit of the assigned JSON is still pending — verify/clean. |
| 23 | Two identical SP notifications from different sources | 🟡 | Notification dedup/collapse with `subject` key (S35.1–S35.4); earlier cross-week dedup (S31 Bug 5). Verify the double-SP message is gone. |
| 24 | No notification advancing to GK round 2 / 3 | ⚪ Open | Not found in changelog. GK round-advance notification still to do. |
| 25 | "Buy a car before week X" at next-season registration is misleading; should carry to new season start | 🟡 | Phase 2 car system + season-transition rework (S30–S32, S35.0). Verify the advisory now fires at the new season's start, not at registration. |
| 26 | Building built/upgraded with no notification + no TDL to sign personnel/sponsors/buy car | ⚪ Open | Not found in changelog. Still to do. |
| 27 | Pit crew shown as one name but is multiple people | 🔵 Backlog | Design rework of pit-crew representation. Spec'd in Staff Supplement (§9-C). Not yet reworked. |
| 28 | GK rounds 3 & 4 teams earn no points; need a team champion | ✅ | S36.15 + GK final-weekend redesign (S36.18–S36.20): GK **team champion** via a flat cumulative table across all 22 races; **driver champion** via the elimination ladder. (Final design: points reset per round; team table is the separate cumulative tally.) |
| 29 | No RP earned from races | 🟠 | Flagged as a design note "RP earned only by racing" (v5.7, §8.4, under review). Verify whether races now grant RP. |
| 30 | Check the text written in all campus buildings | ⚪ Open | Not found in changelog. Content audit still to do. |
| 31 | After last GK round, all driver+team standings wiped (Main Hub + Racing World) | ✅ | S36.14: save/load persists ALL championships' standings keyed by id; standings survive round transitions and season end. |
| 32 | Racing World must show ALL championships, not only the player's | 🔵 Backlog | Ties to the living-world feature (F-AICHAMP). Note: `bugs16` touched `RacingWorld.gd` — verify how much is now shown. |
| 33 | EOS says "didn't run in any championship"; remove the registration button | ✅ | S36.x: registration button removed from EOS (#33); EOS filters to the player's raced championships. |
| 34 | Beginning-of-Season should be informational only (remove all TDLs) | 🟠 | Partially addressed via season-transition rework (S35.0). The "informational only" redesign (running where, drivers/staff in-out, sponsor expiries, cars required) — verify completeness. |
| 35 | Extended driver's contract but he vanished next season while still counted (1 shown, 2 counted) | 🟡 | Season Transition Pipeline ordering fix (S35.0): pre-signed free-agent no longer erased before activation. Verify the shown-vs-counted desync is gone. |
| 36 | 3 TP notifications "cars lacking crew" same week | 🟡 | Notification collapse with `subject` (S35.1–S35.4). Verify duplicate crew warnings collapse to one. |
| 37 | Garage driver/mechanic assignments show "none" | 🟡 | Assignment-system rebuild (S30–S32, TP spec v2) + per-car reads (Cluster A). Verify Garage shows assignments. |
| 38 | Garage: Rally4 has no 2nd-driver slot; EPC needs 3 | 🟠 | Driver-per-car / slot rule (canonical slots rule S33.2). The Rally4-2 / EPC-3 specifics — verify the slots now render. |
| 39 | No notification to hire a new TP when one is needed | ⚪ Open | Not found in changelog (TP-assignment cluster is deferred). Still to do. |
| 40 | Changing current TP assignment GK → Rally4 does nothing | 🟠 | TP Assignment cluster (deferred). GK multi-tier exception removed (S30–S32) but the reassignment action itself — verify / still open. |
| 41 | Driver failing age requirement should show a popup | ⚪ Open | Not found in changelog. Still to do. |
| 42 | Starting from Rally, a TDL says "GK has no principal" (stale GK ref) | 🟡 | Cluster A / GK-discipline-bleed gating (S31, S37.1 `player_in_gk`). Verify the stale GK TDL is gone for a Rally career. |
| 43 | Staff hub "Available Staff" button has a static number; remove counts from Drivers/Staff hub buttons | 🟠 | Personnel hub overhaul (S35.10). Verify the parenthesised counts are removed from the hub buttons. |
| 44 | Only Rally4 but code still thinks player is in GK (driver shown there, DNS) | 🟡 | **Cluster A core** (A-CP4 / A-CP4b, S37.0–S37.1): the stray-GK-result + GK-bleed root cause. Needs keyboard verification (this is the headline Cluster-A symptom). |
| 45 | "No TP for Rally4" notification while one is assigned correctly | 🟡 | GK-gating + notification fixes (S37.1). Verify the false no-TP notification is gone. |
| 46 | Code thinks no mechanic → no repairs although one is assigned | 🟡 | Per-car SP/repair reads (A-SP, S37.0): repairs read each car's championship rate. Verify repairs run with a mechanic assigned. |
| 47 | Add a "fix the car" button in the Garage | ⚪ Open | Not found in changelog. Manual-repair button still to do (note: a `repair_car` path exists in code per A-SP, but the Garage button itself — verify). |
| 48 | Season 2 registered only in Rally3 but got "buy car" notifications for every championship | 🟡 | Season-transition + registration-scope fixes (S35.0, Cluster A). Verify next-season car prompts are scoped to registered championships only. |
| 49 | HQ-Financial weekly income doesn't show per-building income | ⚪ Open | Not found in changelog. Still to do. |
| 50 | All warehouse parts scrapped at end of season | 🟠 | Cars scrapped each season is intended (Phase 2, §6.0); whether loose warehouse PARTS should also scrap is a design question — verify intended vs bug. |
| 51 | Full car built from CNC for player must be delivered to Garage with parts installed | 🟡 | Build Whole Car one-pass (S30–S32, §6.0/§8). Verify the assembled car arrives in the Garage with all 6 parts installed. |

---

## Quick tallies

- **✅ Fixed (confirmed in changelog):** #21, #28, #31, #33 — and the GK final-weekend pair from this work (calendar-flag + shadow-cadence) which sit under #28/#31's cluster.
- **🟡 Fixed–needs in-engine verification:** #2, #4, #6, #7, #9, #10, #14, #15, #19, #23, #25, #35, #36, #37, #42, #44, #45, #46, #48, #51.
- **🟠 Known/latent or partial:** #3, #22, #29, #34, #38, #40, #43, #50.
- **🔵 Backlog/feature (design work, sequenced later):** #17, #27, #32.
- **⚪ Still open / not found in changelog:** #1, #5, #8, #11, #12, #13, #16, #18, #20, #24, #26, #30, #39, #41, #47, #49.

## Repo hygiene flags (separate from the bug list — worth resolving)
1. **Two GDD files in the repo:** `GDD_v5.9.md` (underscore) and `GDDv5.9.md` (no underscore) have DIVERGED. Pick one canonical filename, delete the other, so the "single source of truth" rule holds.
2. The live `BUGLIST.md` is now cluster-based and does not carry the original 1–51 numbering — this reconciliation file is the bridge. Decide whether to fold these numbers back in or keep the cluster format.
