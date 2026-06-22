# Season Transition Pipeline — Spec v1

**Status:** DESIGN (spec only — not yet built). Companion to `GDD_v5.1.md`.
**Purpose:** define the SINGLE ORDERED SEQUENCE that runs at every season rollover. The GDD
records the *pieces* of this (registration §7, generation/aging/2-season-retire §12, begin/end
season flow states) but never the *order* they execute in. That missing integration is the root
cause of the season-rollover bugs (contract activation, GK wipe): the stages exist in code but
are interleaved in the wrong order, and two are broken. This spec is the blueprint to assemble
them correctly.

**Where it lives in code:** `SeasonManager.start_new_season()` is the host. This spec defines
what that function's body should be, in order.

---

## THE WORLD MODEL (owner's statement, S33)

> JSON is the season-1 seed: all drivers per team/car/championship + free agents for all
> disciplines. During each season, player and AI banks decisions (expand championships, add
> cars, renew, don't-renew, sign for next season) into ledgers. At the rollover, the next-season
> ledger BECOMES the current-season ledger and a fresh next-season ledger is created. Based on
> the recorded decisions, signings and releases execute; then TPs propose the new roster for the
> player and directly assign for AI teams. The engine then calculates GK's gaps and generates new
> young drivers (GK is the ONLY place new drivers are born). Finally it detects drivers who've
> been out of contract / free agents for 2 full seasons, deletes them, and records them in the
> history book / hall of fame if applicable. This loop runs every season.

### The driver pyramid (critical)
- **GK = the feeder / the only birthplace of new drivers.** At rollover the engine generates new
  young cadets to fill GK's gaps.
- **Every other championship fills its gaps by drawing UP from the existing pool** (promotion
  through the cadet→professional path). They never generate their own new drivers.
- If GK never refills, the entire pyramid's water supply dries up — which is why the current
  "wipe GK, regenerate nothing" bug is foundational, not cosmetic.

---

## THE PIPELINE — five ordered stages

Run in this exact order inside `start_new_season()`. Each stage lists: what it does, the live
code that already implements it (if any), and its status.

### Stage A — Ledger promotion
**Do:** next-season ledger → becomes current-season ledger; create a fresh empty next-season
ledger for the new season's decisions to accumulate into.
**Live code:** PARTIAL. `next_season_registrations` (championship registrations) is promoted at
`SeasonManager.gd:107` (`player_registered_championships = next_season_registrations.duplicate()`
then `.clear()`). This is the *registration slice only*.
**Gap:** there is no unified ledger object for driver/staff SIGNINGS and RELEASES. Today those
are recorded ad-hoc as `pre_signed` approaches + `pending_staff_assignments`, not as a clean
ledger. Decide: formalize a single `season_ledger` structure, or keep the existing distributed
records but treat them collectively as "the ledger" and just ORDER their application correctly.
(Lower-risk path: the latter — order the existing records, don't rebuild storage.)

### Stage B — Apply signings & releases  ⚠️ BROKEN
**Do:** execute every recorded decision — pre-signed contracts activate (person joins team),
releases take effect, non-renewals lapse, expansions register their new cars/seats.
**Live code:** `_activate_presigned_contracts()` (ContractEngine) + `_apply_pending_staff_assignments()`.
**Status:** **BROKEN — confirmed live bug.** `_activate_presigned_contracts` copies the stored
term `start_date="next_season"` back into the re-application, so `_apply_negotiation_result`
re-queues the approach as pre_signed and returns WITHOUT joining the person (debug log:
"BOUNCES back to pre-signed → NEVER joins"; "pre-signed — joins Season N" fired twice).
**Fix:** force `start_date="immediate"` at activation (it IS the next season now). Add a
`_presigned` bypass so a planned signing isn't blocked by a "roster full" guard.

### Stage C — TP assignment
**Do:** TPs PROPOSE the new roster assignments for the PLAYER team (proposal UI); DIRECTLY assign
for AI teams (all 5 roles incl. TP).
**Live code:** TP Phase 1 (player proposals) + TP Phase 2 (`ai_auto_assign_all_teams()`) — both
built (S32–S33). Player path = `TPProposalsPopup` / `peek_tp_proposals`; AI path = the committed
Phase 2 work.
**Status:** BUILT. Needs only to sit in the correct slot in this ordered sequence (it currently
runs, but after the broken GK/car steps rather than as a clean stage).

### Stage D — GK feeder generation  ⚠️ BROKEN (currently a destructive wipe)
**Do:** compute GK's gaps (how many cadets short of a full GK field) and GENERATE that many new
young drivers via the existing runtime constructor. GK only.
**Live code:** the runtime constructor EXISTS — `DriverManager._create_driver_for_discipline(id,
first, last, nat, age, sex, "GK", tier)`. New-game uses it. The pattern to mirror for "top up a
pool at rollover" also exists: `replenish_free_agent_pool()` (S28.3).
**Status:** **BROKEN — confirmed live bug.** Current rollover code (`SeasonManager.gd:126-133`)
DELETES all GK AI drivers, then calls `GKDiscipline.populate_season()` which only SORTS existing
drivers — it has never contained driver-creation code. Result: clear 518 → populate 0 → empty GK
field every season past S1 (and the pyramid's source dries up).
**Fix:** replace the wipe with a generate-to-fill: after the cull (Stage E ordering note below),
generate new GK cadets to fill the gap, mirroring `replenish_free_agent_pool`. Do NOT mass-delete;
remove only drivers that the cull (Stage E) legitimately retires.

### Stage E — Lifecycle cull + Hall of Fame
**Do:** detect drivers out of contract / free agents for 2 FULL seasons → delete from the game;
record qualifying ones in the history book / hall of fame. Also aging/retirement past Age_Peak_End.
**Live code:** EXISTS. `Driver.seasons_without_contract` (field), `FREE_AGENT_MAX_SEASONS`
constant, the erase loop at `SeasonManager.gd:371-382`, `hall_of_fame` array, `HallOfFame.gd`,
`Museum.gd`. `_process_off_season()` increments `seasons_without_contract` (line 262) and runs
auto-renew + free-agent replenish.
**Status:** MOSTLY BUILT. Gaps to verify: (1) does the 2-season cull WRITE to `hall_of_fame`
before erasing, or just delete? (2) ordering — the cull currently runs EARLY (`_process_off_season`
at line 121) before signings activate; it should run as a clean late stage so a just-released
driver isn't culled in the same tick they become a free agent.

---

## CORRECT ORDER vs CURRENT ORDER

**Target order (this spec):**
A (promote ledgers) → B (apply signings/releases) → C (TP assignment) → D (GK generate-to-fill)
→ E (cull + hall of fame) → [then the existing car-reset / championship-reset / registration
notifications, which are downstream presentation, not lifecycle].

**Current order (live, tangled):**
promote registration ledger (A-partial) → `_process_off_season` (contains E's cull, running too
early) → GK wipe-no-regen (D, broken) → populate (no-op) → wipe cars → reset champs → AI re-register
+ `ai_auto_assign` (C) → … → pre-signed activation (B, broken, location unclear in sequence).

The two are the same stages in the wrong order with B and D broken. The refactor = reorder into
A→E and fix B and D.

---

## LEDGER MODEL — decision needed

Two viable approaches for Stage A's "signing/release ledger":

1. **Formalize** a `season_ledger` dict: `{signings:[], releases:[], expansions:[], registrations:[]}`,
   recorded during the season, promoted whole at rollover. Cleanest conceptually; bigger change;
   touches save/load.
2. **Distributed-but-ordered** (lower risk): keep the existing records (`pre_signed` approaches,
   `pending_staff_assignments`, `next_season_registrations`) as-is, but treat them collectively as
   "the ledger" and APPLY them in the correct Stage-B order. No new storage, no save migration.

**Recommendation:** start with (2) to get the pipeline correct and the bugs fixed with minimal
risk; migrate to (1) later if the distributed records become hard to reason about. (Matches the
project's "define floors, refuse ceilings" + scope-discipline ethos.)

---

## WHAT THIS SPEC ADDS TO THE GDD (reconciliation)

The GDD already has, in fragments:
- §7: registration, begin/end-season flow states, auto-populate-to-min/optimum.
- §12: contract terms, "free_agents pool topped up at season end," "no contract 2 seasons → retire,"
  academy discount, generation-rules pointer.

The GDD does NOT have (this spec supplies):
- The ORDERED five-stage sequence (the integration the fragments lack).
- The dual-ledger promotion mechanic (current ⇄ next) beyond registrations.
- GK-as-sole-generation-source + the promotion-pyramid gap-fill rule.
- Hall-of-Fame write coupled to the 2-season cull.

**On adoption:** once built, fold a condensed version of this into GDD §7 + §12 (or a new §7.1
"Season Transition Pipeline") so the GDD remains the single source of truth, with this file as the
detailed companion (same relationship as `TP_Assignment_System_Spec_v2.md`).

---

## BUILD SEQUENCE (when approved)

1. **Stage B fix** (contract activation) — smallest, self-contained, unblocks signings.
2. **Stage D fix** (GK generate-to-fill) — replace the wipe; mirror `replenish_free_agent_pool`.
3. **Reorder** `start_new_season` into A→E with clear stage comments.
4. **Stage E audit** — confirm hall-of-fame write happens before erase.
5. Each stage delivered with a self-verifying assertion (watch it pass, then remove) — per the
   FIX_AUDIT process lesson: verify against code, never against a summary.

---

*Spec v1 — S33. Author input: project owner's world-model statement. To be reconciled into
GDD §7/§12 once the pipeline is built and verified.*
