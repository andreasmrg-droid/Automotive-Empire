class_name LeadDesignerProposalEngine
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

## ── AI direct-apply (mirror TPProposalEngine.ai_auto_assign_all_teams) ────────
## DESIGN INTENT (thread 1 + thread 6): AI teams use the SAME optimiser but APPLY DIRECTLY — no
## proposal UI, no player notifications — and never leave an affordable Studio with idle lines.
##
## DEFERRED (S40.0): the player-side R&D pipeline (RP economy, active_rnd_tasks, start_rnd_task) is
## player-scoped today — there is NO per-AI-team RP ledger or AI R&D task pipeline yet. Inventing one
## here would fabricate an economy the rest of the codebase doesn't model. So this entry point is
## wired and documented but intentionally INERT until the AI R&D economy lands (its own task, paired
## with the AI development-ladder work). When that exists, this fills lines via the AI starter using
## the team's RP/balance and the same compute_design_queue ranking above. Kept as a named seam so the
## call site (SeasonManager rollover / AI heartbeat) already exists.
func ai_fill_design_lines_all_teams() -> void:
	## No-op until the AI R&D economy exists (see note above). Left as the integration seam.
	pass

func ai_fill_design_lines(_team) -> void:
	## No-op until the AI R&D economy exists (see ai_fill_design_lines_all_teams).
	pass

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
	## AI tasks (if the AI R&D pipeline stores them per team) — defensively 0 if not modelled yet.
	var n := 0
	for t in gs.active_rnd_tasks:
		if int(t.get("pillar", 0)) in [1, 2, 3, 4, 5] and t.get("team_id", "") == team.id:
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
