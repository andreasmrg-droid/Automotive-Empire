# Automotive Empire — Notification & News Roadmap

**Version:** v1.0 (draft for review) · **Engine:** Godot 4.7 / GDScript
**Author:** Andreas Maragkos (with Claude) · **Date:** 2026-06-28
**Status:** DESIGN / SEQUENCING — not yet implemented. Companion to GDD §15.1 (notify_event framework).
**Scope:** classify every player-facing event in the codebase, route it to the correct surface,
and define the migration order off the redesigned Main Hub.

> Grounded in the real code: 200 legacy `add_notification()` call sites across 20 files
> (census run S37.36). Only `no_cfo` is migrated to `notify_event` today.

---

## 1. The model — FOUR surfaces, not one

The redesigned Main Hub gives us four distinct places an event can land. Most of the cleanup is
recognising that **a large share of the 200 "notifications" are not notifications at all** — they
are either transient validation errors or standing chores. Picking the right surface is the whole
job.

| Surface | What it is | Lifespan | Has a button? | Rule |
|---|---|---|---|---|
| **TOAST / LOG** | Transient feedback for an action the player just took, esp. *blocking errors* ("Not enough credits", "Car name too long") | This screen, now | No | Never enters the notification panel. Stays in `add_log` + a local on-screen toast where one exists. |
| **TO-DO LIST (TDL)** | A standing chore the player must eventually do ("Assign a driver", "No TP for Rally4") | Until the condition clears | Routed by the TDL itself | **Read-only. NEVER emits a notification.** Rebuilt from state in `get_pending_tasks()`. |
| **NOTIFICATION** | A discrete world/event fact the player should see once ("R&D complete", "Sponsor signed", "Driver left") | Until read/dismissed/snoozed | Optional `destination` button | `notify_event(..., mode "once"/"event")`. Standing conditions use `subject` supersede. |
| **NEWS** | A meaningful world event worth a feed entry (titles, big signings, top-tier entries, rival drama later) | Persistent feed | No (feed is browse-only) | `notify_event(..., mode "news")` → also posts a notification AND `_push_news()`. Full feed = Brainstorm thread 2. |

### The decision tree (apply to every call site)

```
Is it a blocking error / "you can't do that" message for an action just attempted?
   └─ YES → TOAST/LOG. Remove from the notification panel entirely.
   └─ NO ↓
Is it a STANDING chore the player must act on, re-evaluated each week from state?
   └─ YES → TDL only (delete the notification; ensure get_pending_tasks() covers it).
   └─ NO ↓
Is it a discrete EVENT the player should be told about once?
   └─ YES ↓
       Does it need the player to GO somewhere to act/see it?
          └─ YES → notify_event("event", dest="<scene>")  + button
          └─ NO  → notify_event("event")                  (informative)
       Is it ALSO a meaningful world event (title/signing/entry/milestone)?
          └─ YES → upgrade mode to "news"
```

---

## 2. Classification of the actual events (by source domain)

Below, every domain's events are bucketed. **TOAST** = pull out of the panel (transient/blocking
error). **TDL** = standing chore, no notification. **NOTIF** = `notify_event` event. **NEWS** =
also feed it. `→dest` = destination button.

### 2.1 Contracts & Approaches — `ContractEngine.gd` (34 calls)
*The single noisiest file. Most are step-by-step negotiation status; these are real events, not chores.*

| Event | Surface | Mode / dest | Notes |
|---|---|---|---|
| Person is interested → negotiation begins | NOTIF | event → `drivers`/`staff_hub` | Player should open the negotiation. |
| Counter-bond sent / awaiting reply | NOTIF | event | Informative, no button. |
| Approach rejected / bond negotiation failed | NOTIF | event | Informative. |
| "No longer interested for 2 seasons" | NOTIF | event | One-off world fact. |
| Contract negotiations broke down | NOTIF | event | Informative. |
| Driver signed → "assign in Garage" | NOTIF + TDL | event →`garage` **AND** TDL "Assign driver" | Event announces it; the *standing* "assign a driver" lives in the TDL. |
| Staff joined your team | NOTIF | event | Could be NEWS for marquee signings later. |
| Sponsor deal updated/signed | NOTIF | event →`hq` | |
| "TP slots full / already have a CFO / Racing Dept full" | TOAST | — | Blocking error at sign time. Remove from panel. |
| "Deal fell through — TP slots full" | NOTIF | event →`hq` | Borderline; this one is an *outcome*, keep as notif. |

### 2.2 R&D & CNC — `RnDEngine.gd` (26 calls)
*Clean split: a handful of real completion events, the rest are start-action validation errors.*

| Event | Surface | Mode / dest |
|---|---|---|
| R&D project complete → submit to WRA | NOTIF | event →`wra_office` |
| CNC part(s) ready / in production | NOTIF | event →`cnc_plant` |
| CNC part installed on car | NOTIF | event →`garage` (or TOAST — low value) |
| WRA blueprint approved (persistent licence) | NEWS | news →`hq` |
| "No blueprint / not built / insufficient funds / not enough RP / prereq not met / invalid designer / already researching" | TOAST | — (all blocking errors — remove from panel) |

### 2.3 Sponsors — `SponsorManager.gd` (17 calls) — *absorbs buglist #12*

| Event | Surface | Mode / dest |
|---|---|---|
| New sponsor offer (passive batch, season start) | NOTIF | **standing**, subject `sponsor_offers` →`hq` — collapse the 1–3 batch into one |
| New sponsor offer (CFO search hit) | NOTIF | event →`hq` (earned, individual) |
| New sponsor offer (race-finish reward) | NOTIF | event →`hq` (earned, individual) |
| Sponsor signed | NOTIF | event →`hq` |
| Sponsor paid CR x this season | NOTIF | event (or LOG — low value) |
| Sponsor contract expired / fulfilled & ended | NOTIF | event |
| **Commitment sponsor unfulfilled penalty looming** | TDL + NOTIF | Critical event →`hq`; standing reminder in TDL |
| CFO search started/stopped/active interval | LOG | — (status chatter, not panel-worthy) |
| "No CFO hired" (search attempt) | TOAST → TDL | the standing "hire a CFO" already lives via `no_cfo` once+TDL |

### 2.4 Cars & Parts — `CarManager.gd` (17 calls)

| Event | Surface | Mode / dest |
|---|---|---|
| Car ready → assign a driver | NOTIF + TDL | event →`garage` + TDL "Assign driver" |
| Part installed on car | TOAST/LOG | — |
| "No part in CNC inventory / no provider stock" | TOAST | — (blocking) |
| "Car already at full condition" | TOAST | — (blocking) |
| "Car name empty / too long" | TOAST | — (validation) |

### 2.5 Season Transition — `SeasonManager.gd` (13 calls)

| Event | Surface | Mode / dest |
|---|---|---|
| Driver/staff left — contract expired | NOTIF | event (marquee departures → NEWS later) |
| Promotion / relegation outcome | NEWS | news |
| Critical season-rollover warnings (no roster, etc.) | TDL + NOTIF | Critical event + standing TDL |

### 2.6 Race Day — `RaceSimulator.gd` (13 calls)
*Almost all Critical in-race conditions — these are real events, but several are PRE-race blockers
that belong in the TDL before the weekend.*

| Event | Surface | Mode / dest |
|---|---|---|
| Win / podium / championship win / race win | NEWS | news (the headline feed events) |
| DNF / terminal part failure | NOTIF | event →`garage` |
| Pre-race: no driver / no fuel / no parts / DNS-until-ready | TDL | standing chore (must be visible BEFORE race week, not as a race-day surprise) |
| Post-race: SP insufficient to repair | NOTIF | standing, subject `res_spare_parts` →`garage` (already subject-collapsed S37.5) |

### 2.7 Finance — `FinancialEngine.gd` (8 calls)

| Event | Surface | Mode / dest |
|---|---|---|
| Bankruptcy risk (negative balance) | TDL + NOTIF | Critical standing, subject `bankruptcy` →`financial_dept` |
| Loan due / interest | NOTIF | event →`financial_dept` |
| Loan repaid | NOTIF | event →`hq` |

### 2.8 Staff / Drivers managers — `StaffManager.gd` (5) + `DriverManager.gd` (4)

| Event | Surface | Mode / dest |
|---|---|---|
| Driver/Pit Crew/staff hired → assign | NOTIF + TDL | event →`garage`/`pit arena` + TDL "Assign" |
| "Already contracted / already have a CFO / no slot" | TOAST | — (blocking) |

### 2.9 GameState core — `GameState.gd` (33 calls)
*Mixed: economy events (keep as notif), registration flow (mix of TDL chore + event), and a pile of
buy-action blocking errors (TOAST).*

| Event | Surface | Mode / dest |
|---|---|---|
| Economy shifted / fuel price fluctuation | NOTIF | event (CFO-gated per S35.4) |
| Registration deadline approaching | TDL + NOTIF | standing →`championship_select` (already migrated-ish, keep) |
| Registered for championship → buy a car | NOTIF + TDL | event + TDL "Buy/build a car" |
| GK round complete / champion crowned | NOTIF / NEWS | event; GK title → news |
| "Not enough credits (parts/fuel/entry) / unknown champ / deadline passed" | TOAST | — (all blocking errors) |
| Autosave / screenshot saved | LOG | — (definitely not panel) |

### 2.10 Building scenes — Campus/Garage/Logistics/etc. — *absorbs buglist #26*

| Event | Surface | Mode / dest |
|---|---|---|
| **Building built / upgraded complete** (#26) | NOTIF | event →`campus` (currently emits NOTHING — log only) |
| Building sold | NOTIF | event (or LOG) |
| Car purchased (Logistics) | NOTIF + TDL | event →`garage` + TDL "Assign driver" |
| GP1 engine secured → build chassis | NOTIF + TDL | event →`cnc_plant` |
| "Could not install part — see log" | TOAST | — (blocking) |
| Generic `err` passthroughs (RacingDept/StaffHub/Drivers) | TOAST | — (these are already error strings) |

---

## 3. The headline finding

Of the ~200 calls, the rough split is:

- **~70–80 are TOAST/blocking errors** that should leave the notification panel entirely
  (every "Not enough credits", "already at full condition", "no slot", `err` passthrough).
  *This is the single biggest noise reduction and the easiest win.*
- **~30–40 are standing chores** that should be TDL-only (assign driver, hire TP, buy a car,
  pre-race readiness, bankruptcy) — many already partly covered by `get_pending_tasks()`.
- **~70–80 are genuine EVENTS** for `notify_event` (`event` mode, ~25 with destination buttons).
- **~10–15 are NEWS** (titles, podiums, promotions, marquee signings, WRA licence, top-tier entry).

So the loop is less "migrate 200 notifications" and more: **strip the errors, demote the chores,
keep the events, flag the news.**

---

## 4. Migration roadmap (sequenced)

**Phase 0 — Framework hardening (small, do first).**
- Add a TDL destination map / confirm `get_pending_tasks()` covers every chore we're demoting
  (assign driver, hire TP/CFO, buy car, pre-race readiness, bankruptcy, registration deadline).
- Confirm a TOAST channel exists for transient errors (local on-screen toast or just `add_log` +
  the existing per-scene feedback label). If none, add one thin helper so errors have a home.
- Add any missing destinations to `NOTIFICATION_DESTINATIONS` (e.g. `championship_select`,
  `pit_arena` if we route there).

**Phase 1 — Strip the errors (biggest noise win, lowest risk).**
- Convert all blocking/validation `add_notification("High", …)` errors to TOAST/LOG.
- Files: GameState (buy actions), RnDEngine (start-action guards), CarManager (install/condition),
  StaffManager/DriverManager/Drivers/StaffHub/RacingDept/Garage (`err` passthroughs).
- Pure subtraction from the panel; no behaviour the player relies on is lost.

**Phase 2 — Demote the chores to TDL.**
- Remove the standing-reminder notifications; verify each appears in `get_pending_tasks()`.
- Pre-race readiness (RaceSimulator) is the key one — surface it BEFORE the race week, not on race day.

**Phase 3 — Migrate the true events to `notify_event`, file by file.**
Order by event density & value:
1. `ContractEngine` (negotiation lifecycle) — highest count, clearest events.
2. `RnDEngine` (R&D/CNC completion + WRA licence as the first NEWS).
3. `SponsorManager` (absorbs **#12**; passive batch → `standing` collapse).
4. `CarManager` + Logistics (car ready → event + TDL).
5. `SeasonManager` (departures → event; promotion → NEWS).
6. `FinancialEngine` (loans, bankruptcy).
7. Campus building completion (absorbs **#26**).
8. `GameState` economy + registration + GK.

**Phase 4 — Wire NEWS mode.**
- Tag the ~10–15 headline events as `news`. The feed already has a stub (`_push_news`); the Main
  Hub NEWS panel currently doubles as the weekly log. Decide: keep events flowing into that panel
  now, full news system (Brainstorm thread 2, sound-wave propagation) later.

**Phase 5 — Verify in-engine.**
- Fresh GP4 game: confirm the panel only shows events (no error spam), the TDL holds the chores,
  buttons route correctly, and a title/podium reaches NEWS.

---

## 5. Per-file work ledger (delivery units)

Each row is one downloadable file with a bumped version header (Rules #2, #7).

| File | Calls | Phases touched | Notes |
|---|---|---|---|
| NotificationManager.gd | (framework) | 0 | TOAST helper? confirm news hook |
| GameState.gd | 33 | 0,1,2,3,4 | destination consts; biggest split |
| ContractEngine.gd | 34 | 3 | negotiation lifecycle |
| RnDEngine.gd | 26 | 1,3,4 | errors out; completions in; WRA→news |
| SponsorManager.gd | 17 | 3 | **#12**; batch collapse |
| CarManager.gd | 17 | 1,2,3 | car ready event + TDL |
| SeasonManager.gd | 13 | 3,4 | departures/promotion |
| RaceSimulator.gd | 13 | 2,3,4 | results→news; pre-race→TDL |
| FinancialEngine.gd | 8 | 3 | loans/bankruptcy |
| StaffManager.gd | 5 | 1,3 | hired→event+TDL |
| DriverManager.gd | 4 | 1,3 | signed→event+TDL |
| ChampionshipSelect.gd | 3 | 1,3 | |
| TPProposalEngine.gd | 3 | 2,3 | proposals→TDL/event |
| Logistics.gd | 2 | 3 | car/engine purchase |
| Garage.gd | 2 | 1 | install error→toast |
| MainHub.gd | 2 | 1 | |
| CampusManager.gd | 1 | 3 | building sold |
| Campus/building completion | (new) | 3 | **#26** — currently emits nothing |
| RacingDept / StaffHub / Drivers | 3 | 1 | `err`→toast |

---

## 6. Open design questions (for you)

1. **TOAST channel** — is there an existing on-screen transient toast, or do blocking errors just
   go to `add_log` + the per-scene feedback label? (Determines Phase 0 size.)
2. **NEWS panel now vs later** — route `news` events into the current Main Hub NEWS/Log panel
   immediately, or hold all news until the full propagation system (Brainstorm thread 2)?
3. **Sponsor passive batch** — confirm: collapse the season-start 1–3 offers into ONE `standing`
   notification (my lean), keep CFO-search + race offers individual.
4. **Marquee signings as NEWS** — do staff/driver signings ever reach the feed, or only titles /
   podiums / promotions / top-tier entries?
5. **Departures** — every contract expiry as an event, or only notable ones?
```
