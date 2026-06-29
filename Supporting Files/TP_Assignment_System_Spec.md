# TP Assignment System — Redesign Spec

**Status:** SPEC → merge into GDD §9-A (Team Principal) + §12 (Contracts/Generation) as the
authoritative TP-assignment design. Supersedes the ad-hoc behaviour in TPProposalEngine.gd.
**Session:** S32 · 2026-06-21 · Author: Andreas Maragkos (design) + build assist.
**Baseline:** GitHub `0d119db`.

---

## 1. Concept

Team Principals are **advisors, not auto-pilots**. Each season/roster change they compute the
**optimal allocation of personnel to cars** and surface it as a **single proposal**. The player is
always the decision-maker: accept all, accept some, or reject and assign manually. The TPs never
auto-assign — an ignored proposal leaves cars unassigned (and they DNS). That is the player's risk.

> The *calculation* logic already in `generate_tp_assignment_proposals()` is essentially correct
> (prestige ordering, effective-stat scoring, commitment exclusion). This redesign keeps that core
> and rebuilds the **delivery/lifecycle layer** around it, which is where the bugs lived.

## 2. Model

- A team may span multiple championships. Example: 3 championships, 6 cars, 6 drivers, 6 mechanics,
  6 pit crews, and one TP per championship (3 TPs).
- **Despite multiple TPs, the player receives ONE consolidated proposal — never one per
  championship/TP.** (The current per-championship firing is the main structural bug.)
- Each car's proposed personnel set = **driver + mechanic + pit crew** (pit crew is NEW; current
  code only proposes driver + mechanic). Pit crew is proposed only where
  `get_pit_crew_required(champ_id)` is true (non-GK).

## 3. The optimisation (global, prestige-ordered)

- A **single global allocation** over the shared personnel pool — NOT each car grabbing its local best.
- Cars are processed in **descending championship prestige** (`DISC_PRESTIGE × 10 + tier`):
  GP1 first, then EPC, then Rally, etc. Higher-prestige cars get **first pick** of the pool.
- **All driver/mechanic comparisons use discipline-adaptation-corrected stats**
  (`effective_stat = raw_stat × (adaptation/100)`). A GP ace unadapted to Rally scores lower for a
  Rally seat. **Pit crew has NO discipline adaptation** (per the Staff supplement) → scored on raw
  stats (fitness-corrected at race time, not here).
- Driver score (existing, keep): `effective_pace × 0.6 + effective_consistency × 0.4`, with age
  eligibility (`min_age`/`max_age`) enforced.

## 4. Commitment rule (anti-exploitation) — KEEP AS-IS

Already implemented and correct; this is the chosen anti-exploit mechanism (the 1-week-gap idea is
**dropped** as redundant):

- **Non-GK: one person → one championship.** Once a driver/mechanic/pit-crew member is committed to
  a car, they are **excluded** from every other car in the allocation. This stops one ace driver
  "time-sharing" across GP1 + EPC + Rally because their races fall on different weeks.
- **GK exception:** within GK's multi-tier single-venue structure, the same person MAY cover
  multiple tiers **unless** there is a same-week / different-track conflict.

The optimiser enforces this by removing committed personnel from the available pool as it allocates
prestige-first. (This is why prestige order matters: GP1 claims the ace, who is then off the table.)

## 5. Triggers — when a proposal is (re)generated

A fresh proposal is computed and surfaced when:
1. **Season start** — cars exist, assignments don't yet → propose the full optimal lineup (the week-1
   case).
2. **New season** — same as season start.
3. **Any mid-season roster change** — a hire, departure, new car delivered, or contract loss → TPs
   **silently** recompute and surface a new proposal.

No weekly re-nagging. Between triggers, the existing proposal simply persists until consumed.

## 6. Lifecycle (single source of truth)

There is exactly **one** current proposal set: `GameState._last_tp_proposals`. The notification, the
TDL item, and the Racing-Dept popup are all **views** of it — never independent copies. (The current
three-divergent-copies design is the root of the duplicate-rows / stale / no-refresh bugs.)

```
trigger → generate → store in _last_tp_proposals (THE source)
        → fire ONE notification + ONE TDL item (tagged, see §7)
player opens Racing Dept → popup reads _last_tp_proposals (no regeneration on view)
player action:
  • Accept all  → apply every assignment → consumed
  • Accept some → apply chosen → the chosen personnel become committed →
                  RE-OPTIMISE remaining unassigned cars over the reduced pool →
                  store the new set as _last_tp_proposals (a fresh proposal)
  • Reject      → discard; cars stay unassigned (player assigns manually)
On consume (all assigned or rejected): clear _last_tp_proposals AND dismiss the TDL item AND clear
the notification — all keyed off the same set.
```

### Partial accept = re-optimise (confirmed)
Accepting a subset commits those people, then the optimiser runs again for the still-unassigned cars
using the smaller pool, producing a new (smaller) proposal. Repeats until the player has assigned all
they want or rejects the remainder.

## 7. TDL / notification correctness (current bugs to kill)

- **Stable tag, not text-matching.** The TDL item must carry a stable identifier (e.g. prefix
  `"[TP]"` or a dedicated todo "kind") so it can ALWAYS be dismissed. The current code creates
  `"🏁 TP has N assignment(s) ready…"` but dismisses by searching `"TP proposals ready"` — which never
  matches, so the item never clears.
- **One TDL item per proposal**, not one per car/championship. The current multiple `add_todo_item`
  sites (in the weekly check + the fire function) produce duplicates.
- When the proposal is consumed or re-optimised, dismiss the old TDL item before adding any new one.

## 8. Refresh (current bug to kill)

When the popup closes after any action, the Racing Dept must rebuild **both** layout and dynamic
lists. `_build_ui()` alone clears `_drivers_container` but never refills it — only `refresh()` does.
(Both must run, matching `_ready()`.) With the single-source model, the popup edits
`_last_tp_proposals` and the panel re-reads it; no divergence.

## 9. Future hook (NOT building now)

A second TP proposal **kind**: scouting & recommending new driver signings. Leave a clean `kind`
field on proposals (`"assignment"` now; `"signing"` later) so the surface (notification/TDL/popup) can
carry both without a second pipeline. No implementation this pass.

## 10. Data model (proposal object)

```
{
  "kind":        "assignment",          # future: "signing"
  "type":        "assign_driver" | "assign_mechanic" | "assign_pit_crew"
                 | "missing_driver" | "missing_mechanic" | "missing_pit_crew" | "dns_warning",
  "car_id":      String,
  "car_label":   String,
  "champ_id":    String,
  "champ_name":  String,
  "person_id":   String,                # driver_id / mechanic_id / pit_crew_id
  "person_name": String,
  "eff_score":   float,                 # effective (adaptation-corrected) score, for display
  "note":        String,                # human-readable line
  "priority":    "normal" | "warning" | "critical",
}
```
One consolidated `Array` of these in `_last_tp_proposals` covering ALL cars/championships.

## 11. Build plan (proposed, do NOT start until spec approved)

1. **Engine — `generate_tp_assignment_proposals()`**: add pit-crew allocation (mirror mechanic
   logic, no adaptation; only where pit crew required); ensure ONE consolidated array; add `kind`
   field. Keep prestige order + commitment exclusion.
2. **Engine — `apply_tp_proposals()`**: apply driver/mechanic/**pit crew**; on partial accept,
   re-optimise the remainder; dismiss TDL by stable tag; refresh roster snapshot (already added).
3. **Engine — `_fire_tp_proposal_notification()`**: ONE notification + ONE tagged TDL item; remove
   the duplicate TDL sites in the weekly check.
4. **Popup — `TPProposalsPopup.gd`**: read/write only `_last_tp_proposals`; per-item + accept-all
   adopt the regenerated set; show pit-crew rows.
5. **RacingDept — `_open_tp_popup` close**: call `_build_ui()` AND `refresh()`.
6. **Locale**: any new strings via `Locale.t`, update `Locale.gd`.
7. Health checks: Locale scan, indentation/balance, and a manual test of the three reported
   behaviours (no duplicates; scene refreshes; TDL clears).

## 12. Out of scope (backlog)
- Driver-signing scouting proposals (the §9 hook only).
- AI teams using this optimiser (player-economy mechanic for now).
- A 1-week change-cooldown (explicitly dropped in favour of the commitment rule).
