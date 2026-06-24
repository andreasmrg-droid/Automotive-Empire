# Automotive Empire — Bug & Issue Tracker

**Version:** v1.0 · **Created:** 2026-06-24 · **Engine:** Godot 4.6.3 / GDScript
**Repo:** https://github.com/andreasmrg-droid/Automotive-Empire.git

> Companion to the GDD (the design source of truth). This file is the **work queue** — known
> defects and required fixes. Bugs live here until fixed; once a fix ships, the GDD is updated to
> reflect the corrected behaviour and the item is marked ✅ here (kept for history, not deleted).
> Sits alongside `Brainstorm_Threads.md` and `FEATURE_AI_Championship_Sim.md`.
>
> **Status legend:** 🔴 open · 🟡 partial · ✅ fixed · 🔵 design-decision-needed
> **Severity:** **S1** state-corrupting / blocks progression · **S2** wrong behaviour, playable ·
> **S3** UI / polish / cosmetic

---

## SUMMARY BY SYSTEM

| System | Open count | Notable |
|---|---|---|
| Notifications & To-Do List | 11 | missing/duplicate/frozen notifications |
| Championship registration & season flow | 9 | "registered in all championships" core bug |
| Staff / Driver / contracts | 10 | interest model, salary display, assignment |
| Standings & living world | 5 | wiped standings, empty rival championships |
| Garage & assignments | 6 | missing driver/crew slots, no repair button |
| Finance & economy | 5 | CFO fin-mgmt zeros, fuel not deducted |
| UI / screens | 5 | main hub overflow, card overflow, race results |
| R&D / CNC / parts | 3 | RP-by-race, warehouse scrap, built-car delivery |
| Naming / data | 1 | repetition + real-name collisions |

---

## S1 — STATE-CORRUPTING / BLOCKS PROGRESSION

These break the core loop or corrupt persistent state. Fix first.

### Championship registration & "raced in all championships" cluster
This looks like one root cause with many symptoms — the player is treated as registered in every
championship rather than only the ones actually entered. Worth fixing as a single investigation.

- 🔴 **#9** — Next-race week wrong: in S1 the player appears registered in ALL championships though
  only GK was entered. **(root cause candidate)**
- 🔴 **#19** — HQ-WRA says "not racing any championship this season" while running GK; news says
  racing all championships; week-20 "haven't registered for next season" notification + TDL fires
  even though GK *was* registered (and HQ-WRA shows it). Contradictory registration state.
- 🔴 **#44** — Running only Rally4, but parts of the code still believe the player is in GK — driver
  visible there to the point of a DNS.
- 🔴 **#48** — Season 2 registered only in Rally3, but received "buy a car" notifications for every
  championship.
- 🔵 **#33** — End-of-Season screen says "didn't run in any championship"; also remove the
  registration button from that screen.

### Standings / living world wipes
- 🔴 **#31** — After the last GK round, all driver + team standings wiped in Main Hub AND Racing
  World. **(S1 — destroys season results)**
- 🔵 **#28** — In GK rounds 3 & 4 teams earn no points; need a champion *team* not just driver.
  Decision leaning: do NOT reset team points — carry intact through round 4. **(design + bug)**

### Contract / assignment state corruption
- 🔴 **#35** — Extended a driver's contract, but next season he vanished from the Drivers screen
  while still counted (shows 1, counts 2). Found in Racing World as `D-GK-FA-006`. **(roster
  desync — ties to Season Transition Pipeline §7.1)**
- 🔴 **#6** — Pressing the TDL "renew contract" triggers a counting loop in HQ; every renegotiate
  press re-triggers HQ entry. **(re-entrancy / loop)**
- 🔴 **#40** — Changing the current TP assignment from GK to Rally4 does nothing.
- 🔴 **#46** — Some code believes the player has no mechanic, so no repairs, despite one assigned.

---

## S2 — WRONG BEHAVIOUR (PLAYABLE BUT INCORRECT)

### Staff interest / reputation model
- 🔴 **#2** — Reputation/interest broken: a brand-new GK team should not have ~2943 staff interested.
- 🔴 **#18** — Starting driver too strong for a brand-new GK team.
- 🔴 **#4** — "Staff interested" notification fires the same week the staff is signed without leaving
  the negotiation scene — shouldn't appear.

### Finance & economy
- 🔴 **#1** — CFO financial-management attributes are all 0 (data/generation bug).
- 🔴 **#15** — Fuel units (FU) not deducted after a race unless the CFO auto-buys constantly (not
  obvious). If that's what's happening, it's incorrect behaviour.
- 🔴 **#8** — Inconsistency between weekly salaries and the hub cards showing annual salary.
- 🔴 **#13** — Sponsor offers for a championship that don't even cover the entry fee.
- 🔴 **#14** — "Active fans 891k" for a brand-new garage.

### Sponsors
- 🔴 **#5** — Sponsor slots should increase at ODD levels (1, 3, 5…), not even.

### Garage / assignments
- 🔴 **#37** — Garage driver & mechanic assignments show "none".
- 🔴 **#38** — Garage: Rally4 has no slot for the 2nd driver; EPC missing slots for 3.
- 🔴 **#36** — TP fires 3 "cars lacking crew" notifications in the same week (duplicate).
- 🔴 **#45** — "No TP for Rally4" notification while a TP is correctly assigned.
- 🔴 **#27** — Pit crew modelled as a single named person; should be a multi-person crew.
- 🔴 **#41** — If a driver fails the age requirement for a championship, a popup should appear (missing).
- 🔴 **#47** — Add a button in the Garage that repairs/fixes the car (currently no manual repair control).

### R&D / CNC / parts
- 🟡 **#29** — "No RP by races." NOTE: `RaceSimulator.earn_race_rp()` now exists (S35.x) — verify it
  actually fires and credits RP; may be partially fixed. Ties to GDD §8.4 (flagged "RP earned only
  by racing", under review).
- 🔴 **#50** — All warehouse parts scrapped at end of season. Confirm intended scope (cars are
  scrapped by design per §6.0 — parts should not be, unless deliberate).
- 🔴 **#51** — When the CNC builds a full car for the player, it should be delivered to the Garage
  with parts already installed.

---

## S3 — UI / POLISH / COSMETIC

### Screen overflow & layout
- 🔴 **#3** — Main Hub stretched off-screen.
- 🔴 **#7** — Staff/driver card pushed too far right, off-screen; align top-center or top-left.
- 🔴 **#11** — Race Results: columns stacked on the right, need spacing; add a "skip results" button
  (useful when advancing to season end).
- 🔴 **#16** — HQ-Financial: the "Balance" label shows on every graph tab.
- 🔴 **#49** — HQ-Financial weekly income doesn't break down income per building.

### Notifications & To-Do List (the big cluster)
- 🔴 **#12** — No TDL/notification for a new sponsor offer.
- 🔴 **#20** — No notification for the last week to register for championships.
- 🔴 **#24** — No notification when advancing to GK round 2 / 3.
- 🔴 **#23** — Two identical SP notifications (different sources). NOTE: subject-supersede dedup
  exists (S35.1) but the player still sees two — the second source isn't tagged with the same
  subject. Trace the second emitter.
- 🔴 **#25** — On next-season registration, "buy a car before week X" notification is misleading;
  should be carried forward to the start of the new season.
- 🔴 **#26** — Building built/upgraded gives no notification or TDL to sign personnel / sponsors /
  buy a car where applicable.
- 🔴 **#39** — No notification to hire a TP when one is needed.
- 🔴 **#42** — Starting from Rally, a TDL says "GK has no principal" (stale GK reference).
- 🔴 **#10** — HQ contract-negotiation entry frozen at round 1 after advancing 3 weeks; Walk-Away
  didn't remove the HQ entry. **(borderline S2 — stale UI state)**

### Main Hub & info screens
- 🔵 **#17** — News not useful; Main Hub standings window not useful; Main Hub needs a total revamp.
  **(design pass, not a point fix)**
- 🔵 **#32** — Racing World must show ALL championships, not only the player's. **(ties to
  FEATURE_AI_Championship_Sim — the living-world feature)**
- 🔵 **#34** — Beginning-of-Season screen: make it informative only — remove all TDLs; show where
  the team races, drivers/staff arriving/leaving, sponsor expiries, and which cars are required.
- 🔵 **#30** — Review all building descriptions in the Campus scene.

### Naming / licensing / data
- 🟡 **#21** — New Game screen and HQ-WRA still say "Formula" → must be "GP". PARTIAL: fixed in R&D
  Studio + Locale this session (S35.21); NewGame.gd and HQ.gd still contain "Formula". Finish there.
- 🔴 **#22** — Names need far more variation; the pre-assigned drivers/staff JSON has many
  repetitions and many names that collide with real drivers/athletes. **(IP risk — see
  Brainstorm_Threads "Names / IP": ship fictional names. Real-name collisions must be scrubbed.)**
- 🔴 **#43** — Staff hub "Available Staff" button has a static number in parentheses; remove the
  count numbers from the Drivers and Staff hub buttons.

---

## SUGGESTED FIX ORDER

1. **The registration cluster (#9, #19, #44, #48, #33)** — likely one root cause; biggest leverage.
2. **Standings wipe (#31) + GK team points (#28)** — protects season results.
3. **Roster desync (#35) + contract loop (#6, #10)** — Season Transition Pipeline area.
4. **Interest/reputation model (#2, #4) + CFO data (#1)** — economy correctness.
5. **Garage slots & assignment (#37, #38, #40, #45, #46)** — the assignment system.
6. **Notification cluster (#12, #20, #24, #23, #25, #26, #39, #42)** — batch together.
7. **UI overflow (#3, #7, #11, #16, #49)** — polish pass.
8. **Design revamps (#17, #32, #34, #30)** — schedule as design work, not point fixes.
9. **Finish #21 (Formula→GP in NewGame/HQ), #22 names, #43 button counts.**

---

*Cross-references: GDD §7.1 (Season Transition), §12 (Contracts/Interest), §13 (AI/News),
§14 + FEATURE_AI_Championship_Sim (living world), §15 (Notifications), §9 (Staff).*
