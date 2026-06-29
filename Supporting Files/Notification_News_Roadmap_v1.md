# Automotive Empire — Notification & News Roadmap

**Version:** v1.1 (design locked, decisions folded in) · **Engine:** Godot 4.7 / GDScript
**Author:** Andreas Maragkos (with Claude) · **Date:** 2026-06-28
**Status:** DESIGN / SEQUENCING — Phase 0 anchor confirmed; not yet implemented.
Companion to GDD §15.1 (notify_event framework).
**Scope:** classify every player-facing event in the codebase, route it to the correct surface,
and define the migration order off the redesigned Main Hub.

> Grounded in the real code: 200 legacy `add_notification()` call sites across 20 files
> (census run S37.36). Only `no_cfo` is migrated to `notify_event` today.

---

## 0. Guiding philosophy — think like a human player

For **every** event, ask the same two questions in order:

1. **Does this event require an ACTION, or is it just information?**
2. If it requires action — **what kind, and WHERE does the player go to do it?**

That single test decides the surface. Information that is a world-fact becomes NEWS; information
that is just local "you can't do that right now" feedback becomes an on-the-spot POPUP; anything
needing action becomes a TDL entry (the standing chore) usually paired with a NOTIFICATION (the
"this just happened / go here" nudge) carrying a destination button.

---

## 1. The model — THREE surfaces (+ news), NOT a notification panel for everything

The redesigned Main Hub gives us distinct places an event can land. The cleanup is recognising that
**a large share of the 200 "notifications" are not notifications at all** — they are either
blocking errors (which belong in an immediate popup at the point of action) or standing chores
(which belong in the TDL). Picking the right surface is the whole job.

| Surface | What it is | Lifespan | Has a button? | Rule |
|---|---|---|---|---|
| **POPUP-ON-THE-SPOT** | A blocking / validation error for an action just attempted ("Not enough credits", "Car name too long", "No slot") | Modal, dismissed by player | "OK" only | **There is NO toast/log channel — scrapped.** Fires an immediate `AcceptDialog` at the point of action. NEVER enters the notification panel. |
| **TO-DO LIST (TDL)** | A standing chore the player must eventually do ("Assign a driver", "Open negotiation with X", "Register for championship") | Until the condition clears | Routed by the TDL itself | **Read-only. NEVER emits a notification by itself.** Rebuilt from state in `get_pending_tasks()`. |
| **NOTIFICATION** | A discrete world/event fact the player should see once ("R&D complete", "Sponsor signed", "Negotiation advanced", "Building upgraded") | Until read/dismissed/snoozed | Optional `destination` button | `notify_event(..., mode "once"/"event")`. Standing conditions use `subject` supersede. |
| **NEWS** | A meaningful world event worth a feed entry (titles, podiums, promotions, every signing & every departure, top-tier entries; rival drama later) | Persistent feed | No (feed is browse-only) | `notify_event(..., mode "news")` → posts a notification AND `_push_news()`. **Populate now**; soundwave propagation (Brainstorm thread 2) later. |

### The decision tree (apply to every call site)

```
Is it a blocking error / "you can't do that" for an action just attempted?
   └─ YES → POPUP-ON-THE-SPOT (AcceptDialog). Remove from the notification panel entirely.
   └─ NO ↓
Does it require a standing ACTION the player must complete later?
   └─ YES → TDL entry (the chore).  AND, if it just became true this moment,
            also fire a NOTIFICATION nudge (with a destination button to where the action happens).
   └─ NO ↓ (pure information)
Is it a meaningful WORLD event (title, podium, promotion, signing, departure, milestone)?
   └─ YES → notify_event("news", dest?) — notification + feed entry.
   └─ NO  → notify_event("event", dest?) — informative notification, button only if there's
                                            somewhere useful to look.
```

### Contract-negotiation rule (locked)

- A NOTIFICATION fires on **every meaningful step** (each time the negotiation advances a stage:
  interested → counter-bond sent → awaiting reply → resolved).
- While a negotiation is open, **ONE persistent TDL entry** ("Open negotiation with X") stays up —
  not a new TDL per step — until it resolves.
- **Successful close →** NEWS entry **+** a TDL for assignment *if the subject gets assigned*:
  - Driver / staff → TDL "Assign [name]" → `garage` / pit arena.
  - Sponsor → no assignment, **except** the championship-funding sponsor type (T3): success →
    NEWS + TDL "Register for [championship]" → `championship_select`.
- **Failed / fell-through close →** a NOTIFICATION that it failed (no TDL).
- A driver/staff **released or leaving without a contract →** NOTIFICATION **and** NEWS.

### Popup helper (Phase 0 anchor — confirmed)

- The `AcceptDialog` pattern already exists inline in 6 scenes (Garage, Logistics, RnDStudio,
  RacingDept, StaffHub, Drivers) — precedent set S29.0 / bug #41 (*"previously only a notification,
  easy to miss mid-action"* — exactly this philosophy). Problem: copy-pasted.
- **Anchor:** `GameState` is an autoload `extends Node`, already calls `get_tree()`. Add
  `GameState.show_popup(message, title := "Notice")` that parents an `AcceptDialog` to
  `get_tree().current_scene`, `popup_centered()`, frees on close. Reachable from the `RefCounted`
  engines (they all hold a `gs` ref) — so each blocking-error swap is a one-liner `gs.show_popup(...)`.
- Collapse the 6 inline dialogs onto the same helper (kills duplication).
- **Titles:** light contextual title where the message implies one (Insufficient Funds, Slots Full,
  Invalid Name); default `"Notice"` otherwise.

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

- **~70–80 are blocking errors** that should leave the notification panel entirely and become
  **on-the-spot popups** (every "Not enough credits", "already at full condition", "no slot",
  `err` passthrough). *This is the single biggest noise reduction and the easiest win.*
- **~30–40 are standing chores** that should be TDL-only (assign driver, hire TP, buy a car,
  pre-race readiness, bankruptcy) — many already partly covered by `get_pending_tasks()`.
- **~70–80 are genuine EVENTS** for `notify_event` (`event` mode, ~25 with destination buttons).
- **~10–15 are NEWS** (titles, podiums, promotions, marquee signings, WRA licence, top-tier entry).

So the loop is less "migrate 200 notifications" and more: **strip the errors, demote the chores,
keep the events, flag the news.**

---

## 4. Migration roadmap (sequenced)

**Phase 0 — Framework hardening (small, do first).**
- **Add `GameState.show_popup(message, title := "Notice")`** — shared `AcceptDialog` helper parented
  to `get_tree().current_scene`. This is the home for every blocking error. Confirmed anchor.
- Collapse the 6 existing inline `AcceptDialog` blocks (Garage, Logistics, RnDStudio, RacingDept,
  StaffHub, Drivers) onto the helper.
- Confirm `get_pending_tasks()` covers every chore we're demoting (assign driver, open negotiation,
  hire TP/CFO, buy car, register-for-championship, pre-race readiness, bankruptcy, registration deadline).
- Add any missing destinations to `NOTIFICATION_DESTINATIONS` (`championship_select`, `pit_arena`).

**Phase 1 — Scrap the errors into popups (biggest noise win, lowest risk).**
- Convert all blocking/validation `add_notification("High", …)` errors to `gs.show_popup(…)`.
- Files: GameState (buy actions), RnDEngine (start-action guards), CarManager (install/condition),
  StaffManager/DriverManager/Drivers/StaffHub/RacingDept/Garage (`err` passthroughs).
- Pure subtraction from the panel; the error still reaches the player — louder, at the point of action.

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

## 6. Decisions (locked 2026-06-28)

1. **No toast/log channel** — scrapped. Blocking errors become **on-the-spot `AcceptDialog` popups**
   via a shared `GameState.show_popup()` helper. The 6 existing inline dialogs collapse onto it.
2. **News populates now**; soundwave propagation (Brainstorm thread 2) comes later.
3. **Sponsor passive batch** → ONE collapsed `standing` notification (subject `sponsor_offers`);
   CFO-search and race-finish offers stay individual.
4. **Marquee signings → NEWS: yes.** **Every departure (released / left contract-less) → NEWS: yes**
   (plus a notification).
5. **Contract negotiation:** notification on every meaningful step; ONE persistent TDL while open;
   success → NEWS + assignment TDL (or, for the T3 championship-funding sponsor, a
   "Register for [championship]" TDL → `championship_select`); failure → a "deal failed" notification.

### Still to pin at the keyboard (not blockers)
- Exact code identity of the **T3 / championship-funding sponsor type** (so success routes to the
  right championship registration).
- Whether **car-part install success** ("part installed on car") is a low-value notification worth
  keeping, or should be silent.
```
