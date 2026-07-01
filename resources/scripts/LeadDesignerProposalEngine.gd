class_name LeadDesignerProposalEngine
## Version: S41.6a — DIAGNOSTIC INSTRUMENTATION on top of S41.6. The 10-season playtest produced ZERO
##   [AIPlan] lines (planner started no AI task). Each early-out gate (rnd_engine_null / no_studio /
##   no_lead / no_free_lines / no_championships / no_primary_cid / reached_planner) is now tallied per
##   week and flushed as ONE [AIPlanDiag] summary line, so the next playtest reveals WHICH gate kills
##   the planner instead of failing silently. No logic change to the planner itself — purely additive
##   logging. Remove the _ai_diag_* calls once the planner is confirmed live. Analysis-checked; NOT
##   Godot-parsed.
## Version: S41.6 — AI R&D ECONOMY, PHASE 5 (the PLANNER · spec §6). Activates the formerly-inert
##   ai_fill_design_lines_* seam with a forecast-driven scheduler that SPENDS an AI team's banked RP,
##   run every week from GameState.advance_week (after the race loop). Per team: compute the
##   next-season car's LATEST-SAFE-START week (52 − L1_design_weeks − 1, minus a low-`planning` buffer);
##   BEFORE it, fill idle lines with P2 upgrades (surplus-gated); AT it, switch to the 6-part P1/P3 car.
##   FEASIBILITY GATE: if the RP forecast (calendar-walk × the §5 faucet) can't land the 6 baseline L1
##   parts by the deadline, the team holds its granted baseline car rather than over-committing (full
##   retreat/backfill = step 6). Per-part P3-vs-P1 is SURVIVAL-FIRST (P3 where Logistics-provenance
##   allows, else P1) with P3→P1 upgrades only on fat forecast surplus. P4/P5 stay INERT (future AI
##   ladder owns them). ECONOMICS: AI cars are free-granted today, so this reads as UPLIFT on the
##   baseline; the per-part decision is built forward-compatibly and the NEXT project (AI CnC) hangs
##   buy-vs-build + part RESALE on _cnc_buy_vs_build_hook WITHOUT rewriting the planner (the "road for
##   CnC"). Also fixed _lines_in_progress_for to read AI tasks from the ledger (Phase 3), not the
##   player global. Debug-log only ([AIPlan] …), no player news, per owner. Analysis-checked
##   (brace-balance + type audit); NOT Godot-parsed.
## Version: S40.0 — LEAD DESIGNER REWORK (Brainstorm thread #6), advisor layer. Mirrors
##   TPProposalEngine: the Lead Designer PROPOSES a blueprint queue for the team's IDLE design
##   lines (capacity = R&D Studio level); the player ACCEPTS / EDITS / REJECTS in the R&D Studio.
##   Never silent auto-assign for the player (advisor model). AI teams reuse the same optimiser but
##   APPLY DIRECTLY (no proposal UI, no player notifications), exactly like TP Phase 2.
##   Start scope = PROPOSAL MODE only; a "standing-orders" auto-fill policy is a later backlog add.
##   Pure optimiser (compute_*) has no side effects — callers decide (player → UI; AI → apply).
extends RefCounted

var gs

func _init(game_state) -> void:
	gs = game_state

## ── Player entry point ────────────────────────────────────────────────────────
## Produces the consolidated Lead-Designer proposal for the player's team and fires the single
## notification + TDL. Returns the proposal array (also cached on GameState by the caller).
func generate_design_proposals() -> Array:
	var proposals := compute_design_queue(gs.player_team, gs.player_team_cars)
	_fire_design_proposal_notification(proposals)
	return proposals

## ── Shared, team-agnostic optimiser ──────────────────────────────────────────
## Computes a blueprint queue to fill a team's FREE design lines. Free lines = Studio level − lines
## already in progress. Each proposal targets ONE unlockable P1/P2/P3 task on a championship the
## team actually races, assigned to the team's single Lead Designer. Over-stretch (assigning past
## the Lead's comfort C) is allowed but flagged "warning" so the player sees the cost.
## Returns [] when: no Studio (no lines), no Lead hired (idle lines — a critical), or no free lines.
func compute_design_queue(team, team_cars: Array) -> Array:
	var proposals: Array = []
	var is_player: bool = team.is_player_team

	## Capacity + Lead resolution (player path uses the engine helpers on gs._rnd_engine).
	var rnd: RnDEngine = gs._rnd_engine
	if rnd == null:
		return proposals

	var capacity: int = _studio_level_for(team)
	if capacity <= 0:
		## No Studio → no design lines → nothing to propose (not a failure to surface; the team
		## simply has no R&D capability yet). The "build a Studio" nudge lives elsewhere.
		return proposals

	var lead_id: String = _lead_designer_for(team)
	if lead_id == "":
		## Studio exists but NO designer hired → idle lines. A real, legible failure state.
		if is_player:
			proposals.append(_mk_critical(
				"🚫 Your R&D Studio has %d idle design line%s — no Lead Designer hired. Hire one to start R&D." % [
					capacity, "s" if capacity != 1 else ""]))
		return proposals

	## Lines already in progress for this team (P1/P2/P3 only).
	var used: int = _lines_in_progress_for(team)
	var free: int = maxi(0, capacity - used)
	if free <= 0:
		return proposals

	## Candidate blueprint tasks: unlockable P1/P2/P3 tasks on championships the team RACES,
	## not already active/done, ranked by usefulness. Player and AI share the ranking.
	var champs := _team_championships(team)
	var candidates := _rank_candidate_tasks(champs, lead_id)

	## The Lead's comfort line count — proposals beyond it are flagged (soft penalty, no block).
	var comfort: int = rnd.get_comfort_lines(lead_id)
	var lead = gs.all_staff[lead_id]

	var filled := 0
	for cand in candidates:
		if filled >= free:
			break
		var prospective := used + filled + 1      ## lines this Lead would drive after taking this
		var over := prospective > comfort
		var tid: String = cand["task_id"]
		var task = gs.RND_TASKS.get(tid, {})
		var note := "Queue '%s' [%s] → Lead %s" % [
			task.get("name", tid), cand.get("champ_name", ""), lead.full_name()]
		if over:
			var wmult := rnd.get_lead_weeks_multiplier(lead_id, prospective)
			var qmult := rnd._quality_mult_for_lines(lead_id, prospective)
			note += "  ⚠ over-stretched (line %d > comfort %d): quality ×%.2f, ~%.0f%% slower" % [
				prospective, comfort, qmult, (wmult - 1.0) * 100.0]
		proposals.append(_mk(team, cand["champ_id"], cand.get("champ_name",""),
			"queue_blueprint", tid, task.get("name", tid), cand["score"], note,
			"warning" if over else "normal"))
		filled += 1

	## Nothing useful to queue but lines are free → gentle info (player only), not a critical.
	if proposals.is_empty() and is_player and free > 0:
		var info_note := "%d design line%s free, but no new blueprints are unlockable right now." % [
			free, "s" if free != 1 else ""]
		proposals.append(_mk(team, "", "", "info", "", "", 0.0, info_note, "normal"))
	return proposals

## ── Candidate ranking ────────────────────────────────────────────────────────
## Returns an ordered array of {task_id, champ_id, champ_name, score}. Score favours:
##   • prestige of the championship (race the best car first)
##   • the part the Lead is STRONGEST at (their effective design stat), so a Lead plays to strength
##   • Reverse Engineering (P3) and own Design (P1) over plain Upgrades (P2) when both unlockable
func _rank_candidate_tasks(champs: Array, lead_id: String) -> Array:
	var out: Array = []
	var rnd: RnDEngine = gs._rnd_engine
	for tid in gs.RND_TASKS:
		var t = gs.RND_TASKS[tid]
		var pillar := int(t.get("pillar", 0))
		## S40.0 — the ADVISOR proposes only P1/P2/P3 part blueprints to fill idle lines. P4 Special
		## Projects and P5 commercial models also OCCUPY lines (see RnDEngine.start_rnd_task), but
		## they are big, expensive, strategic player decisions — the Lead shouldn't auto-queue them.
		## They consume capacity once the player starts them deliberately; the advisor just won't
		## suggest them. (When the standing-orders backlog item lands, P4/P5 stay opt-in.)
		if not pillar in [1, 2, 3]:
			continue
		var cid: String = t.get("championship_id", "")
		if cid == "" or not cid in champs:
			continue
		if rnd.rnd_task_active_or_done(tid):
			continue
		if not rnd.rnd_task_unlocked(tid):
			continue
		## Affordability is NOT a hard filter for proposals (the player may save up), but it
		## de-prioritises tasks they can't yet pay for so the queue leads with actionable items.
		var affordable: bool = float(gs.research_points) >= float(t.get("rp", 0)) \
			and float(gs.player_team.balance) >= float(t.get("cr", 0))
		var prestige: float = _prestige_score(cid)
		var part_stat: float = rnd._designer_part_stat(lead_id, t.get("part", ""))  ## live (no snapshot)
		var pillar_bias: float = 1.15 if pillar == 3 else (1.0 if pillar == 1 else 0.85)
		var score: float = prestige * 1000.0 + part_stat * pillar_bias + (50.0 if affordable else 0.0)
		out.append({
			"task_id": tid, "champ_id": cid,
			"champ_name": gs.CHAMPIONSHIP_REGISTRY.get(cid, {}).get("name", cid),
			"score": score,
		})
	out.sort_custom(func(a, b): return a["score"] > b["score"])
	return out

## ── Proposal object builders (mirror TPProposalEngine._mk) ───────────────────
func _mk(team, cid: String, champ_name: String, ptype: String, task_id: String,
		task_name: String, score, note: String, priority: String) -> Dictionary:
	return {
		"kind": "design", "type": ptype, "scope": "design_line",
		"team_id": team.id,
		"champ_id": cid, "champ_name": champ_name,
		"task_id": task_id, "task_name": task_name,
		"score": score, "note": note, "priority": priority,
	}

func _mk_critical(note: String) -> Dictionary:
	return {
		"kind": "design", "type": "no_lead", "scope": "design_line",
		"team_id": gs.player_team.id, "champ_id": "", "champ_name": "",
		"task_id": "", "task_name": "", "score": 0.0,
		"note": note, "priority": "critical",
	}

## ── Apply (player accepts) ───────────────────────────────────────────────────
## Starts each queued blueprint on the team's Lead. Reuses RnDEngine.start_rnd_task, which already
## enforces RP/CR, line capacity, and applies the weeks-stretch. Partial accept = re-optimise.
func apply_design_proposals(proposals: Array) -> void:
	var lead_id := _lead_designer_for(gs.player_team)
	if lead_id == "":
		return
	for prop in proposals:
		if prop.get("type", "") != "queue_blueprint":
			continue
		var tid: String = prop.get("task_id", "")
		var cid: String = prop.get("champ_id", "")
		if tid == "":
			continue
		## start_rnd_task pops its own popup + returns false on any guard (no free line, funds, etc.),
		## so a partially-affordable queue applies what it can and stops cleanly on the first block.
		if not gs._rnd_engine.start_rnd_task(tid, lead_id, cid):
			break
	## Dismiss the Lead-Designer TDL item(s).
	for item in gs.custom_todo_items.duplicate():
		if "Lead Designer" in item or "design line" in item:
			gs.dismiss_todo_item(item)
	## Re-optimise for the remaining free lines (the started tasks are now in progress, so the
	## optimiser won't re-propose them) — the single source of truth, same as TP.
	gs._last_design_proposals = generate_design_proposals()
	gs.emit_signal("log_updated")

## ── Notification + TDL (mirror TPProposalEngine._fire_tp_proposal_notification) ──
func _fire_design_proposal_notification(proposals: Array) -> void:
	_clear_design_tdl()
	if proposals.is_empty():
		return
	var has_critical := proposals.any(func(p): return p.get("priority","") == "critical")
	var queueable := proposals.filter(func(p): return p.get("type","") == "queue_blueprint")
	var n := queueable.size()

	if has_critical:
		gs.notify_event("design_proposals_ready", "Critical",
			"🚫 Lead Designer: your R&D Studio has idle design lines — hire a Lead Designer. → R&D Studio",
			"rnd_studio", "event")
		gs.add_todo_item("🚫 Hire a Lead Designer — idle design lines (R&D Studio)")
		return
	if n == 0:
		return
	var has_warning := proposals.any(func(p): return p.get("priority","") == "warning")
	var msg: String
	if has_warning:
		msg = "⚠ Lead Designer proposes %d blueprint%s (some over-stretched). → R&D Studio" % [
			n, "s" if n != 1 else ""]
	else:
		msg = "🧪 Lead Designer proposes %d blueprint%s for idle lines. → R&D Studio" % [
			n, "s" if n != 1 else ""]
	gs.notify_event("design_proposals_ready", "High", msg, "rnd_studio", "event")
	gs.add_todo_item("🧪 Lead Designer proposals ready — R&D Studio")

func _clear_design_tdl() -> void:
	for item in gs.custom_todo_items.duplicate():
		if "Lead Designer" in item or ("design line" in item):
			gs.custom_todo_items.erase(item)

## ═══════════════════════════════════════════════════════════════════════════
## THE PLANNER (S41.6, AI R&D Economy Phase 5 · spec §6) — forecast + schedule
## ═══════════════════════════════════════════════════════════════════════════
## The forecast-driven scheduler that SPENDS an AI team's banked RP. Runs every week from the weekly
## heartbeat (GameState.advance_week, after the race loop, where RP was just earned). Behaviour, per
## the design owner:
##   • At/after season start it knows the minimum RP a next-season car needs (P1 or P3 per part) and
##     the LATEST-SAFE-START week for that car.
##   • Each week BEFORE that start week: if a design line is free and RP surplus allows, run a P2
##     upgrade on the current car (immediate on-track value that carries forward).
##   • At the safe-start week: switch idle lines to the next-season car's P1/P3 blueprints.
##   • FEASIBILITY GATE: if the RP+CR forecast can't land the 6 baseline L1 parts before the deadline,
##     the team does NOT over-commit (it fields its granted baseline car; full retreat/backfill is the
##     separate step-6 build).
##   • P4/P5 stay INERT SEAMS this project (the future AI ladder state-machine drives them).
##
## ECONOMICS SCOPE (agreed with owner): AI cars are FREE-GRANTED today (_regenerate_ai_team_cars), so
## the planner's P1/P2/P3 research reads as UPLIFT on that baseline (fed to car_strength in step 7).
## The per-part P3-vs-P1 choice is built survival-first / upgrade-on-surplus — which IS the buy-vs-build
## decision in embryo. See _cnc_buy_vs_build_hook: the NEXT project (AI CnC) hangs the real economics
## (buy a provider car vs manufacture own parts, + part RESALE) onto that existing decision without
## rewriting the planner. This is the "lay the road for CnC" seam.

## The 6 parts every car needs (part NAME keys, matching the task schema + car.part_conditions).
const CAR_PARTS: Array = ["Aero", "Engine", "Gearbox", "Suspension", "Brakes", "Chassis"]

## Tuning knobs (balance pass). One place, per spec §6.5.
const PLAN_SURPLUS_MARGIN: float = 1.15   ## need forecast RP ≥ 1.15× the survival bill to feel "safe"
const PLAN_P3P1_UPGRADE_MARGIN: float = 1.5  ## and ≥1.5× before spending surplus upgrading P3→P1
const PLAN_LOW_PLANNING_BUFFER_WK: int = 4   ## a weak planner starts the car this many weeks early

## ── AI weekly entry point (activates the formerly-inert seam) ─────────────────
## Runs the planner for every capable AI team. Called from the weekly heartbeat.
func ai_fill_design_lines_all_teams() -> void:
	var seen := 0
	for team in gs.all_teams:
		if team == null or team.is_player_team:
			continue
		if not team.has_meta("rnd_ledger"):
			_ai_diag_tally("no_rnd_ledger_meta")
			continue
		seen += 1
		ai_fill_design_lines(team)
	## S41.6a diagnostic: one summary line per week so we can see which gate the planner dies on.
	## (Remove this call once the planner is confirmed starting tasks.)
	_ai_diag_flush(seen)

## ── AI per-team weekly planner ───────────────────────────────────────────────
## Fills the team's free design lines this week per the schedule policy above. Pure-ish: the only side
## effect is starting tasks via RnDEngine.start_rnd_task(..., team), which spends the ledger's RP/CR.
func ai_fill_design_lines(team) -> void:
	var rnd: RnDEngine = gs._rnd_engine
	if rnd == null:
		_ai_diag_tally("rnd_engine_null")
		return
	var led: Dictionary = rnd._ledger_for(team)
	var studio_level := int(led["studio_level"])
	if studio_level <= 0:
		_ai_diag_tally("no_studio")
		return   ## no Studio → no lines → no R&D (same gate as the player)
	var lead_id := _lead_designer_for(team)
	if lead_id == "":
		_ai_diag_tally("no_lead")
		return   ## no Designer hired → idle lines, but nothing to drive them
	## Free lines right now = studio_level − lines already in progress for this team.
	var active_lines := _lines_in_progress_for(team)
	var free := studio_level - active_lines
	if free <= 0:
		_ai_diag_tally("no_free_lines")
		return

	var champs := _team_championships(team)
	if champs.is_empty():
		_ai_diag_tally("no_championships")
		return
	## Focus the plan on the team's PRIMARY (highest-prestige) championship — the car that most needs
	## to exist next season. (Multi-championship AI R&D sequencing across several cars is a later
	## refinement; one primary car keeps the schedule legible and matches the "field a car" mandate.)
	var primary_cid := _primary_championship(champs)
	if primary_cid == "":
		_ai_diag_tally("no_primary_cid")
		return

	_ai_diag_tally("reached_planner")   ## got past every gate — the planner body runs
	var lead_planning := _planning_of(lead_id)
	var cur_week := int(gs.current_week)
	var safe_start := _latest_safe_start(team, primary_cid, lead_planning)

	## PHASE A — before the safe-start week: fill idle lines with P2 upgrades (surplus-gated).
	if cur_week < safe_start:
		_ai_fill_p2(team, primary_cid, free)
		return

	## PHASE B — at/after safe-start: the next-season car pre-empts. Feasibility-gate first.
	if not _is_feasible(team, primary_cid, lead_planning):
		## Can't land the car in time → don't over-commit RP on a car that would DNS anyway. Field the
		## granted baseline. (Full retreat to a lighter championship + backfill = step 6.)
		gs.add_log("[AIPlan] %s: %s next-season car INFEASIBLE by wk %d — holding (retreat=step6)." % [
			team.team_name, primary_cid, safe_start])
		return
	_ai_fill_next_season_car(team, primary_cid, free)

## ── DIAGNOSTIC INSTRUMENTATION (S41.6a — temporary, remove once the planner is confirmed live) ──
## The 10-season playtest produced ZERO [AIPlan] lines: the planner started no AI task at all. Each
## early-out above is silent, so we can't tell WHICH gate kills it. This tallies the reason every team
## early-outs each week; ai_fill_design_lines_all_teams flushes one summary line per week. That turns
## "the planner is silent" into "N teams have no_lead, M reached the planner", pinpointing the gate.
var _ai_diag: Dictionary = {}

func _ai_diag_tally(reason: String) -> void:
	_ai_diag[reason] = int(_ai_diag.get(reason, 0)) + 1

func _ai_diag_flush(teams_seen: int = -1) -> void:
	var prefix := "wk %d" % int(gs.current_week)
	if teams_seen >= 0:
		prefix += " (ledger_teams=%d)" % teams_seen
	if _ai_diag.is_empty():
		gs.add_log("[AIPlanDiag] %s: no gate tallies (loop saw 0 evaluable teams)." % prefix)
		return
	## Compact "reason=count" summary, most-common first.
	var parts: Array = []
	var keys := _ai_diag.keys()
	keys.sort_custom(func(a, b): return int(_ai_diag[a]) > int(_ai_diag[b]))
	for k in keys:
		parts.append("%s=%d" % [k, int(_ai_diag[k])])
	gs.add_log("[AIPlanDiag] %s: %s" % [prefix, ", ".join(parts)])
	_ai_diag.clear()

## ── PHASE A: P2 upgrades on the current car ──────────────────────────────────
## Queue the best unlockable P2 upgrades into free lines, but only while RP surplus comfortably covers
## the upcoming survival bill (we never spend so much on P2 now that we can't afford the car later).
func _ai_fill_p2(team, cid: String, free: int) -> void:
	var rnd: RnDEngine = gs._rnd_engine
	var led: Dictionary = rnd._ledger_for(team)
	var rp_now := float(led["rp"])
	var survival_bill := _survival_rp_bill(team, cid)
	## Surplus rule: only run P2 if current RP already clears the survival bill with margin — so the
	## next-season car is never starved by discretionary upgrades.
	if rp_now < survival_bill * PLAN_SURPLUS_MARGIN:
		return
	var lead_id := _lead_designer_for(team)
	## AI-scoped P2 candidates: unlockable, not-active/done FOR THIS TEAM (team-routed gates — the
	## shared _rank_candidate_tasks reads player state, so we scan directly here). Order by the Lead's
	## strongest part, cheapest first (a simple, legible priority).
	var p2s: Array = []
	for tid in gs.RND_TASKS:
		var t: Dictionary = gs.RND_TASKS[tid]
		if int(t.get("pillar", 0)) != 2: continue
		if t.get("championship_id", "") != cid: continue
		if rnd.rnd_task_active_or_done(tid, team): continue
		if not rnd.rnd_task_unlocked(tid, team): continue
		p2s.append({"tid": tid, "rp": int(t.get("rp", 0)),
			"stat": rnd._designer_part_stat(lead_id, t.get("part", ""))})
	## Play to the Lead's strength first, then cheapest. (Single-line lambda: matches this file's
	## existing sort_custom style, avoids multi-line-lambda parse fragility.)
	p2s.sort_custom(func(a, b): return a["stat"] > b["stat"] if a["stat"] != b["stat"] else a["rp"] < b["rp"])
	var filled := 0
	for cand in p2s:
		if filled >= free:
			break
		var tid: String = cand["tid"]
		var task: Dictionary = gs.RND_TASKS.get(tid, {})
		## Keep the survival margin intact: don't spend below the survival bill on discretionary P2.
		if float(led["rp"]) - float(task.get("rp", 0)) < survival_bill:
			continue
		if team.balance < float(task.get("cr", 0)):
			continue
		if rnd.start_rnd_task(tid, lead_id, cid, team):
			gs.add_log("[AIPlan] %s: started P2 %s (RP left %.0f)." % [
				team.team_name, tid, float(led["rp"])])
			filled += 1

## ── PHASE B: the next-season car (P1/P3 per part, survival-first) ─────────────
## For each of the 6 parts still missing a next-season L1 blueprint, start the cheapest legal path:
## P3 where Logistics-provenance allows (cheap, 75% stats), else P1. Then, if forecast surplus is fat
## enough, upgrade chosen P3 parts to P1 (full stats). This IS the buy-vs-build decision (see
## _cnc_buy_vs_build_hook) — for now it is pure uplift on the free-granted car.
func _ai_fill_next_season_car(team, cid: String, free: int) -> void:
	var rnd: RnDEngine = gs._rnd_engine
	var led: Dictionary = rnd._ledger_for(team)
	var lead_id := _lead_designer_for(team)
	var ns := int(gs.current_season) + 1
	var filled := 0
	for part in CAR_PARTS:
		if filled >= free:
			break
		## Already have (or are researching) a next-season L1 for this part? skip.
		if _has_next_season_l1(team, cid, part, ns):
			continue
		## Decide the path for this part (survival-first, upgrade-on-surplus). Returns a task id or "".
		var tid := _choose_car_part_task(team, cid, part, ns)
		if tid == "":
			continue
		var task: Dictionary = gs.RND_TASKS.get(tid, {})
		if float(led["rp"]) < float(task.get("rp", 0)):
			continue   ## not enough RP banked yet this week — try again next week
		if team.balance < float(task.get("cr", 0)):
			continue
		if rnd.start_rnd_task(tid, lead_id, cid, team):
			var pillar := int(task.get("pillar", 0))
			gs.add_log("[AIPlan] %s: started %s %s [%s] for S%d car." % [
				team.team_name, ("P3" if pillar == 3 else "P1"), part, cid, ns])
			filled += 1
	## Whole-car completion breadcrumb (debug only — not player news, per owner).
	if _next_season_car_complete(team, cid, ns):
		gs.add_log("[AIPlan] %s: S%d %s car fully self-designed. ✅" % [team.team_name, ns, cid])

## ── The P3-vs-P1 per-part decision (the CnC seam) ────────────────────────────
## Survival-first: choose P3 (cheap, provenance-permitting) as the baseline; upgrade to P1 (full stats)
## only when the RP forecast shows fat surplus beyond the survival bill. Returns the chosen task id.
func _choose_car_part_task(team, cid: String, part: String, ns: int) -> String:
	var rnd: RnDEngine = gs._rnd_engine
	var lead_id := _lead_designer_for(team)
	var p3_tid := _find_task(cid, part, ns, 3, 1)
	var p1_tid := _find_task(cid, part, ns, 1, 1)
	## P3 is only real if it's provenance-unlockable for THIS team (granted car carries the part).
	var p3_ok := p3_tid != "" and rnd.rnd_task_unlocked(p3_tid, team) and not rnd.rnd_task_active_or_done(p3_tid, team)
	var p1_ok := p1_tid != "" and rnd.rnd_task_unlocked(p1_tid, team) and not rnd.rnd_task_active_or_done(p1_tid, team)

	## The CnC hook can veto/redirect this choice once AI part-buying + resale exist. Inert today.
	var forced := _cnc_buy_vs_build_hook(team, cid, part, ns)
	if forced != "":
		return forced

	if not p3_ok and not p1_ok:
		return ""
	if not p3_ok:
		return p1_tid   ## P3 not provenance-eligible → own design is the only legal path
	if not p1_ok:
		return p3_tid
	## Both available: survival-first = P3, UNLESS forecast surplus is fat enough to justify P1's
	## full stats (the "this team wants a genuinely better car / parts to sell later" case).
	var led: Dictionary = rnd._ledger_for(team)
	var survival_bill := _survival_rp_bill(team, cid)
	var forecast := _forecast_rp_by_week(team, _latest_safe_start(team, cid, _planning_of(lead_id)))
	if forecast >= survival_bill * PLAN_P3P1_UPGRADE_MARGIN and float(led["rp"]) >= float(gs.RND_TASKS.get(p1_tid, {}).get("rp", 0)):
		return p1_tid
	return p3_tid

## ── CnC seam (INERT — the NEXT project fills this) ───────────────────────────
## THE ROAD FOR CnC. Today AI cars are free-granted and money spent/earned on parts vanishes. The AI
## CnC project will: (1) make AI teams BUY provider cars (money out) vs manufacture own P3/P1 parts,
## (2) let AI teams SELL parts/cars to customer teams (money in — currently it just disappears), and
## (3) switch car_strength from the perf_bonus proxy to real installed AI parts. When that lands, THIS
## hook is where the buy-vs-build economics attach: given (team, cid, part, next_season), it can force
## a specific path (return a task id) or veto research in favour of buying (return "" + a buy order the
## CnC layer executes). Returning "" here today means "no override — use the survival-first logic
## above," so the planner behaves correctly with the hook inert. DO NOT add economics here in this
## project; the seam exists so the CnC project doesn't have to rewrite the planner.
func _cnc_buy_vs_build_hook(_team, _cid: String, _part: String, _ns: int) -> String:
	return ""   ## inert: no override. CnC project implements buy-vs-build here.

## ── Forecast + schedule math ─────────────────────────────────────────────────

## Cumulative RP this team will have EARNED by `target_week` from the remaining calendar × the §5
## faucet (current banked RP + forecast of future race weeks up to target_week). A weak planner
## (low `planning`) under-counts its horizon; a strong one sees the full remaining calendar.
func _forecast_rp_by_week(team, target_week: int) -> float:
	var rnd: RnDEngine = gs._rnd_engine
	var led: Dictionary = rnd._ledger_for(team)
	var banked := float(led["rp"])
	var studio_level := int(led["studio_level"])
	if studio_level <= 0:
		return banked
	var lead_id := _lead_designer_for(team)
	if lead_id == "":
		return banked
	var lead_skill: float = gs.all_staff[lead_id].get_overall_skill() if lead_id in gs.all_staff else 0.0
	var per_km := 0.75   ## RP_PER_KM_BASE (mirror of RaceSimulator; kept in sync by the balance pass)
	var diff: float = gs.get_difficulty_mult()["ai_performance"]
	var cap := float(gs.get_rnd_rp_storage_cap(team))
	## Walk each championship the team races; sum RP for remaining rounds up to target_week.
	var future := 0.0
	var cars_by_champ := _running_car_count_by_champ(team)
	for cid in _team_championships(team):
		var champ = gs.get_championship_by_id(cid)
		if champ == null:
			continue
		var ncars := int(cars_by_champ.get(cid, 0))
		if ncars <= 0:
			continue
		for i in range(int(champ.current_round), champ.calendar.size()):
			var entry: Dictionary = champ.calendar[i]
			var wk := int(entry.get("week", 0))
			if wk <= gs.current_week or wk > target_week:
				continue
			var round_km := float(entry.get("distance_km", 0.0))
			if round_km <= 0.0:
				round_km = float(entry.get("laps", 0)) * float(entry.get("lap_km", 1.0))
			future += round_km * per_km * float(studio_level) * (lead_skill / 100.0) * diff * float(ncars)
	return min(banked + future, cap)

## The latest week the team can START the next-season car and still finish (design + 1 wk WRA) by 52.
## Uses the priciest single part's L1 design weeks (Chassis is typically the longest) as the critical
## path for one line; a weak planner subtracts a safety buffer (starts earlier, wasting P2 time).
func _latest_safe_start(team, cid: String, planning: float) -> int:
	var ns := int(gs.current_season) + 1
	var max_weeks := 1
	for part in CAR_PARTS:
		var tid := _find_task(cid, part, ns, 1, 1)   ## P1 L1 (own-design weeks = the safe upper bound)
		if tid == "":
			tid = _find_task(cid, part, ns, 3, 1)     ## fall back to P3 L1 weeks
		if tid == "":
			continue
		var wk := int(gs.RND_TASKS.get(tid, {}).get("weeks", 1))
		if wk > max_weeks:
			max_weeks = wk
	var base := 52 - (max_weeks + 1)   ## +1 for the flat WRA approval week
	## Low-planning penalty: a weak planner hedges and starts early (buffer). planning 100 → 0 buffer;
	## planning 0 → full PLAN_LOW_PLANNING_BUFFER_WK.
	var buffer := int(round(float(PLAN_LOW_PLANNING_BUFFER_WK) * (1.0 - clampf(planning / 100.0, 0.0, 1.0))))
	return maxi(1, base - buffer)

## Feasible iff the RP forecast by the deadline clears the survival bill (the 6 baseline L1 parts),
## AND the team can afford their CR. Free-line throughput is implicit (studio_level ≥ 1 guaranteed).
func _is_feasible(team, cid: String, planning: float) -> bool:
	var survival_bill := _survival_rp_bill(team, cid)
	var forecast := _forecast_rp_by_week(team, _latest_safe_start(team, cid, planning))
	if forecast < survival_bill:
		return false
	## CR: the cheapest legal 6-part set must be affordable at the current balance (rough gate — the
	## real per-week CR forecast is a balance-pass refinement).
	var cr_bill := _survival_cr_bill(team, cid)
	return team.balance >= cr_bill * 0.5   ## lenient: CR accrues via racing income too

## The RP cost of the CHEAPEST legal 6-part next-season car (P3 where provenance allows, else P1).
func _survival_rp_bill(team, cid: String) -> float:
	var ns := int(gs.current_season) + 1
	var total := 0.0
	for part in CAR_PARTS:
		total += float(_cheapest_part_rp(team, cid, part, ns))
	return total

func _survival_cr_bill(team, cid: String) -> float:
	var ns := int(gs.current_season) + 1
	var total := 0.0
	for part in CAR_PARTS:
		total += float(_cheapest_part_cr(team, cid, part, ns))
	return total

func _cheapest_part_rp(team, cid: String, part: String, ns: int) -> int:
	var rnd: RnDEngine = gs._rnd_engine
	var p3_tid := _find_task(cid, part, ns, 3, 1)
	var p1_tid := _find_task(cid, part, ns, 1, 1)
	var p3_ok := p3_tid != "" and rnd.rnd_task_unlocked(p3_tid, team)
	if p3_ok:
		return int(gs.RND_TASKS.get(p3_tid, {}).get("rp", 0))
	if p1_tid != "":
		return int(gs.RND_TASKS.get(p1_tid, {}).get("rp", 0))
	return 0

func _cheapest_part_cr(team, cid: String, part: String, ns: int) -> int:
	var rnd: RnDEngine = gs._rnd_engine
	var p3_tid := _find_task(cid, part, ns, 3, 1)
	var p1_tid := _find_task(cid, part, ns, 1, 1)
	if p3_tid != "" and rnd.rnd_task_unlocked(p3_tid, team):
		return int(gs.RND_TASKS.get(p3_tid, {}).get("cr", 0))
	if p1_tid != "":
		return int(gs.RND_TASKS.get(p1_tid, {}).get("cr", 0))
	return 0

## ── Small lookups ────────────────────────────────────────────────────────────

## Find a task id by (championship, part, season, pillar, level). "" if none.
func _find_task(cid: String, part: String, season: int, pillar: int, level: int) -> String:
	for tid in gs.RND_TASKS:
		var t: Dictionary = gs.RND_TASKS[tid]
		if int(t.get("pillar", 0)) != pillar: continue
		if int(t.get("level", 0)) != level: continue
		if t.get("championship_id", "") != cid: continue
		if t.get("part", "") != part: continue
		if int(t.get("season", -1)) != season: continue
		return tid
	return ""

## True if this team already has (completed OR in-progress) a next-season L1 blueprint for the part
## (from either P1 or P3 — both satisfy "the part exists for next season").
func _has_next_season_l1(team, cid: String, part: String, ns: int) -> bool:
	var rnd: RnDEngine = gs._rnd_engine
	for pillar in [1, 3]:
		var tid := _find_task(cid, part, ns, pillar, 1)
		if tid != "" and rnd.rnd_task_active_or_done(tid, team):
			return true
	return false

## True when all 6 parts have a next-season L1 (completed or researching).
func _next_season_car_complete(team, cid: String, ns: int) -> bool:
	for part in CAR_PARTS:
		if not _has_next_season_l1(team, cid, part, ns):
			return false
	return true

## The team's primary championship = highest prestige among the ones it races.
func _primary_championship(champs: Array) -> String:
	var best := ""
	var best_score := -1.0
	for cid in champs:
		var s := _prestige_score(cid)
		if s > best_score:
			best_score = s
			best = cid
	return best

## Count of this team's running (seated) cars per championship — feeds the RP forecast.
func _running_car_count_by_champ(team) -> Dictionary:
	var out: Dictionary = {}
	for car in gs.get_cars_for_team(team):
		if car == null: continue
		if car.assigned_driver_ids().is_empty(): continue
		out[car.championship_id] = int(out.get(car.championship_id, 0)) + 1
	return out

## The Lead's `planning` attribute (0..100). Defaults mid if the field is absent on old staff.
func _planning_of(lead_id: String) -> float:
	if not lead_id in gs.all_staff:
		return 50.0
	var s = gs.all_staff[lead_id]
	return float(s.planning) if "planning" in s else 50.0

## ── Team-scoped helpers ──────────────────────────────────────────────────────
## Studio level for a team. Player reads gs.campus_buildings; AI teams use their stored building
## levels (ai_campus_levels) if present, else a conservative default of their seeded Studio.
func _studio_level_for(team) -> int:
	if team.is_player_team:
		return gs._rnd_engine.get_design_line_capacity()
	## AI building levels live on the team (see CampusManager / AIManager). Fallback: assume the
	## seeded all-L5 Studio noted in the brainstorm so AI R&D isn't silently dead pre-surgery.
	var lvls = team.get("ai_building_levels") if "ai_building_levels" in team else null
	if lvls != null and lvls.has("R&D Design Studio"):
		return int(lvls["R&D Design Studio"])
	return int(team.get("ai_rnd_studio_level")) if "ai_rnd_studio_level" in team else 5

## The single Lead Designer for a team = highest-overall hired Designer (whole person).
func _lead_designer_for(team) -> String:
	if team.is_player_team:
		return gs._rnd_engine.get_lead_designer_id()
	var best_id := ""
	var best := -1.0
	for sid in gs.all_staff:
		var s = gs.all_staff[sid]
		if s.role != "Designer" or s.contract_team != team.id:
			continue
		var o = s.get_overall_skill()
		if o > best:
			best = o; best_id = sid
	return best_id

## Design lines currently in progress for a team. S40.0 — ALL pillars (P1-P5) occupy a line; the
## player branch reads the engine (which counts P1-5), the AI fallback mirrors it.
func _lines_in_progress_for(team) -> int:
	if team.is_player_team:
		return gs._rnd_engine.get_design_line_capacity() - gs._rnd_engine.get_free_design_lines()
	## S41.6 — AI tasks live in the team's rnd_ledger (Phase 3), NOT gs.active_rnd_tasks (player-only).
	## Count line-consuming (P1-5) tasks in progress on this team's ledger.
	var led: Dictionary = gs._rnd_engine._ledger_for(team)
	var n := 0
	for t in led["active_tasks"]:
		if int(t.get("pillar", 0)) in [1, 2, 3, 4, 5]:
			n += 1
	return n

## Championships a team races (player → registered list; AI → its cars' championships).
func _team_championships(team) -> Array:
	if team.is_player_team:
		return gs.player_registered_championships.duplicate()
	var out: Array = []
	for car in gs.get_cars_for_team(team):
		if not car.championship_id in out:
			out.append(car.championship_id)
	return out

## Championship prestige score (higher tier = higher). Mirrors the TP optimiser's ordering intent.
func _prestige_score(cid: String) -> float:
	var reg = gs.CHAMPIONSHIP_REGISTRY.get(cid, {})
	return float(reg.get("tier", 1)) + float(reg.get("prestige", 0)) * 0.01
