extends Control
## Version: S37.48 — Racing World compact cards (_build_world_card, used for every championship the
##   player isn't in) now show the TEAM/constructors leader alongside the driver leader. The data was
##   already populated (AIChampionshipSim.add_team_points for AI champs; the real sim for the player's
##   champ), but this card only displayed the driver leader — so the world looked like it had no team
##   standings. The player's own championship was unaffected (it uses the richer _build_active_card,
##   which already shows full driver + team columns).
## Version: S37.2 — GK results now visible in the Racing World "world card" for non-GK careers.
##   The GK championship's champ.standings only ever holds the player's group-0 snapshot (reset to
##   0 each round by _sync_gk_group0_to_standings), so the world card showed an empty/zero leader —
##   GK looked resultless. _build_world_card now special-cases C-001: it reads the GK champion (once
##   decided) or an indicative mid-season front-runner from GKDiscipline's shadow standings via the
##   new _gk_world_leader() helper, plus GK round progress. Non-GK championships are unchanged.
## Version: S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## Version: S28.3 — GK "Your Group" reads GKDiscipline.get_standings() (player group only)
##   instead of champ.standings which could show all teams. Other-groups skip player index.
## --- S22.8 — #2 Team standings; #2 correct tab order; #2 Season 1 GK groups.
##                    each discipline tab (GP1/World/Premier Rally at top, entry level bottom).
##   Active (player in it): expanded card with standings, next race, group detail for GK.
##   Inactive (player not in): compact read-only card showing world state.
##   Car rule enforced: player drivers only appear in GKDiscipline groups if a car is
##   registered to that championship. No register hints — that's HQ's job.
##   Reads active_championships (current season), not player_registered_championships.

var _tab_buttons: Dictionary = {}
var _content_area: ScrollContainer
var _current_tab: String = ""

const DISC_ICONS = {
	"GK": "🏎", "GP": "🏁", "Rally": "🌲",
	"TC": "🚗", "OWC": "🔵", "SC": "🏟", "EPC": "⏱"
}
const DISC_COLORS = {
	"GK":    Color(0.4, 0.9, 0.5),
	"GP":    Color(0.9, 0.3, 0.3),
	"Rally": Color(0.8, 0.6, 0.2),
	"TC":    Color(0.4, 0.7, 1.0),
	"OWC":   Color(0.6, 0.4, 1.0),
	"SC":    Color(1.0, 0.5, 0.2),
	"EPC":   Color(0.3, 0.85, 0.9),
}

## All discipline codes in display order
const ALL_DISCS = ["GK", "GP", "Rally", "TC", "OWC", "SC", "EPC"]

## Championship IDs per discipline — most prestigious FIRST (top of screen)
const DISC_CHAMPS = {
	"GK":    ["C-001"],   ## Single GK Championship
	"GP":    ["C-024","C-023","C-022","C-021"],   ## GP1 → GP2 → GP3 → GP4
	"Rally": ["C-008","C-007","C-006","C-005"],   ## Premier → Rally2 → Rally3 → Rally4
	"TC":    ["C-010","C-009"],                   ## TC Elite → TC Sport
	"OWC":   ["C-013","C-012","C-011"],           ## OWC Pro → OWC Dev → OWC Next Gen
	"SC":    ["C-017","C-016","C-015","C-014"],   ## SC Cup → SC Challenge → SC Truck → SC Dev
	"EPC":   ["C-020","C-019","C-018"],           ## EPC Hyper → EPC League → EPC Series
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	for c in get_children(): c.queue_free()
	await get_tree().process_frame

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right"]: margin.add_theme_constant_override(s, 28)
	for s in ["margin_top","margin_bottom"]:  margin.add_theme_constant_override(s, 18)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	## Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var lbl_title = Label.new()
	lbl_title.text = Locale.t("rw_title")
	lbl_title.add_theme_font_size_override("font_size", 44)
	lbl_title.add_theme_color_override("font_color", Color.WHITE)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	var lbl_season = Label.new()
	lbl_season.text = "Season %d  ·  Week %d" % [
		GameState.current_season, GameState.current_week]
	lbl_season.add_theme_font_size_override("font_size", 24)
	lbl_season.modulate = Color(0.55, 0.55, 0.55)
	header.add_child(lbl_season)

	var btn_back = Button.new()
	btn_back.text = Locale.t("btn_back")
	btn_back.custom_minimum_size = Vector2(90, 34)
	btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainHub.tscn"))
	header.add_child(btn_back)

	root.add_child(HSeparator.new())

	## Tab bar — one per discipline (always show all 7)
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 3)
	root.add_child(tab_bar)

	_content_area = ScrollContainer.new()
	_content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_area.clip_contents = true
	root.add_child(_content_area)

	_tab_buttons = {}
	for disc in ALL_DISCS:
		var icon = DISC_ICONS.get(disc, "🏆")
		var btn = Button.new()
		btn.text = "%s %s" % [icon, disc]
		btn.custom_minimum_size = Vector2(0, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 24)
		var d = disc
		btn.pressed.connect(func(): _show_tab(d))
		tab_bar.add_child(btn)
		_tab_buttons[disc] = btn

	_show_tab(ALL_DISCS[0])

## ── Tab rendering ─────────────────────────────────────────────────────────────

func _show_tab(disc: String) -> void:
	_current_tab = disc

	for d in _tab_buttons:
		var btn = _tab_buttons[d]
		var active = d == disc
		var col = DISC_COLORS.get(disc, Color.WHITE)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.22, 0.35) if active else Color(0.10, 0.12, 0.15)
		style.border_width_bottom = 3 if active else 0
		style.border_color = col
		style.content_margin_left = 8; style.content_margin_right = 8
		style.content_margin_top = 5; style.content_margin_bottom = 5
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)

	for c in _content_area.get_children(): c.queue_free()
	await get_tree().process_frame

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	_content_area.add_child(content)

	_build_discipline_content(content, disc)

## ── Discipline content ────────────────────────────────────────────────────────

func _build_discipline_content(parent: VBoxContainer, disc: String) -> void:
	var disc_color = DISC_COLORS.get(disc, Color.WHITE)
	var champ_ids = DISC_CHAMPS.get(disc, [])

	## Build a lookup of active Championship objects by id
	var active_by_id: Dictionary = {}
	for champ in GameState.active_championships:
		active_by_id[champ.id] = champ

	## Player's active championship ids
	var player_active_ids: Array = []
	for champ in GameState.active_championships:
		if _player_in_championship(champ):
			player_active_ids.append(champ.id)

	for cid in champ_ids:
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var champ = active_by_id.get(cid)  ## null if not running this season
		var player_active = cid in player_active_ids

		if player_active and champ != null:
			## Expanded player card
			if disc == "GK":
				parent.add_child(_build_gk_active_card(cid, champ, reg, disc_color))
			else:
				parent.add_child(_build_active_card(cid, champ, reg, disc_color))
		else:
			## Compact world-state card
			parent.add_child(_build_world_card(cid, champ, reg, disc_color))

## ── Active player card (non-GK) ──────────────────────────────────────────────

func _build_active_card(cid: String, champ: Championship,
		reg: Dictionary, disc_color: Color) -> PanelContainer:
	var panel = _card(Color(0.09, 0.11, 0.14))
	var pstyle = panel.get_theme_stylebox("panel").duplicate()
	pstyle.border_width_left = 3
	pstyle.border_color = disc_color
	panel.add_theme_stylebox_override("panel", pstyle)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	## Title + tier + round progress
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vb.add_child(hdr)

	var lbl_name = Label.new()
	lbl_name.text = champ.championship_name
	lbl_name.add_theme_font_size_override("font_size", 28)
	lbl_name.add_theme_color_override("font_color", disc_color)
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(lbl_name)

	var lbl_you = Label.new()
	lbl_you.text = "← YOUR CHAMPIONSHIP"
	lbl_you.add_theme_font_size_override("font_size", 20)
	lbl_you.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	hdr.add_child(lbl_you)

	var lbl_round = Label.new()
	lbl_round.text = "Round %d / %d" % [champ.current_round, champ.num_races]
	lbl_round.add_theme_font_size_override("font_size", 22)
	lbl_round.modulate = Color(0.6, 0.6, 0.6)
	vb.add_child(lbl_round)

	## Next race
	var next_race = champ.get_next_race()
	if next_race:
		var lbl_next = Label.new()
		lbl_next.text = "Next: %s  (Week %d)" % [next_race["name"], next_race["week"]]
		lbl_next.add_theme_font_size_override("font_size", 24)
		lbl_next.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		vb.add_child(lbl_next)

	vb.add_child(HSeparator.new())

	## Player position summary
	var pos_text = _get_player_pos_text(champ)
	var lbl_pos = Label.new()
	lbl_pos.text = pos_text
	lbl_pos.add_theme_font_size_override("font_size", 24)
	lbl_pos.modulate = Color(0.8, 0.8, 0.8)
	vb.add_child(lbl_pos)

	## Driver standings (top 5) + Team standings (top 3)
	var standings_row = HBoxContainer.new()
	standings_row.add_theme_constant_override("separation", 16)
	vb.add_child(standings_row)

	var drv_col = VBoxContainer.new()
	drv_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drv_col.add_theme_constant_override("separation", 2)
	standings_row.add_child(drv_col)
	var lbl_drv_hdr = _section_label("DRIVERS")
	drv_col.add_child(lbl_drv_hdr)
	drv_col.add_child(_build_standings_mini(champ, 5))

	var team_col = VBoxContainer.new()
	team_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_col.add_theme_constant_override("separation", 2)
	standings_row.add_child(team_col)
	var lbl_team_hdr = _section_label("TEAMS")
	team_col.add_child(lbl_team_hdr)
	team_col.add_child(_build_team_standings_mini(champ, 5))

	return panel

## ── Active GK card ────────────────────────────────────────────────────────────

func _build_gk_active_card(cid: String, champ: Championship,
		reg: Dictionary, disc_color: Color) -> PanelContainer:
	var panel = _card(Color(0.09, 0.12, 0.10))
	var pstyle = panel.get_theme_stylebox("panel").duplicate()
	pstyle.border_width_left = 3
	pstyle.border_color = disc_color
	panel.add_theme_stylebox_override("panel", pstyle)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	var gkd = GameState.gk_discipline
	var n_groups = gkd.get_group_count(cid) if gkd else 1
	var total_drivers = gkd.get_total_drivers(cid) if gkd else 0

	## Header
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vb.add_child(hdr)

	var lbl_name = Label.new()
	lbl_name.text = champ.championship_name
	lbl_name.add_theme_font_size_override("font_size", 28)
	lbl_name.add_theme_color_override("font_color", disc_color)
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(lbl_name)

	var lbl_you = Label.new()
	lbl_you.text = "← YOUR GROUP  ·  %d groups  ·  %d drivers" % [n_groups, total_drivers]
	lbl_you.add_theme_font_size_override("font_size", 20)
	lbl_you.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	hdr.add_child(lbl_you)

	## Round / next race
	var lbl_round = Label.new()
	lbl_round.text = "Round %d / %d" % [champ.current_round, champ.num_races]
	lbl_round.add_theme_font_size_override("font_size", 22)
	lbl_round.modulate = Color(0.6, 0.6, 0.6)
	vb.add_child(lbl_round)

	var next_race = champ.get_next_race()
	if next_race:
		var lbl_next = Label.new()
		lbl_next.text = "Next: %s  (Week %d)" % [next_race["name"], next_race["week"]]
		lbl_next.add_theme_font_size_override("font_size", 24)
		lbl_next.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		vb.add_child(lbl_next)

	## S37.48 — GK DRIVER CHAMPION banner. The GK title is decided by the elimination system
	## (GKDiscipline.get_champion()), NOT champ.standings, so when the player is eliminated or out
	## of the final, "YOUR GROUP" is empty and the card otherwise never shows who actually won the
	## drivers' title. Surface the champion here once it's decided (same source as the world card).
	if gkd != null:
		var gk_champ: Dictionary = gkd.get_champion()
		if not gk_champ.is_empty():
			var champ_d = GameState.all_drivers.get(gk_champ.get("driver_id", ""))
			var lbl_champion = Label.new()
			lbl_champion.text = "🏆 Champion: %s  ·  %d pts" % [
				champ_d.full_name() if champ_d else gk_champ.get("driver_id", "Unknown"),
				gk_champ.get("points", 0)]
			lbl_champion.add_theme_font_size_override("font_size", 24)
			lbl_champion.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
			vb.add_child(lbl_champion)

	vb.add_child(HSeparator.new())

	## Group 1 standings — the PLAYER's group only, from GKDiscipline (authoritative).
	## S28.3 (Bug: GK group standings showed ALL teams): champ.standings can drift to hold
	## more than the player group, so read the shadow player-group standings directly.
	if gkd != null:
		var lbl_g1 = _section_label("YOUR GROUP")
		vb.add_child(lbl_g1)
		var group1_entries: Array = gkd.get_standings(cid)
		## Fallback to champ.standings only if the shadow group is somehow empty.
		if group1_entries.is_empty():
			for did in champ.standings:
				group1_entries.append({
					"driver_id": did,
					"points": champ.standings.get(did, 0),
					"races": champ.current_round,
				})
		group1_entries.sort_custom(func(a, b): return a["points"] > b["points"])
		vb.add_child(_build_gk_group_table(group1_entries))

		## Other groups — shadow standings, excluding the player's group index.
		var player_grp_idx = gkd.player_group
		var all_standings = gkd.get_all_standings(cid)
		if all_standings.size() > 1:
			vb.add_child(_section_label("OTHER GROUPS"))
			var grid = GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 8)
			grid.add_theme_constant_override("v_separation", 4)
			vb.add_child(grid)
			for g_idx in range(all_standings.size()):
				if g_idx == player_grp_idx:
					continue  ## skip the player's own group (already shown above)
				if all_standings[g_idx].size() > 0:
					grid.add_child(_build_group_chip(all_standings[g_idx], g_idx))

	## Team standings from real championship
	vb.add_child(HSeparator.new())
	var team_hdr = _section_label("TEAMS")
	vb.add_child(team_hdr)
	vb.add_child(_build_team_standings_mini(champ, 5))

	return panel

func _build_gk_group_table(standings: Array) -> VBoxContainer:
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)

	var player_ids = GameState.player_team.drivers
	var sorted = standings.duplicate()
	sorted.sort_custom(func(a,b): return a["points"] > b["points"])

	for i in range(min(8, sorted.size())):
		var entry = sorted[i]
		var d = GameState.all_drivers.get(entry["driver_id"])
		var is_player = entry["driver_id"] in player_ids

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vb.add_child(row)

		var lp = Label.new()
		lp.text = "P%d" % (i+1)
		lp.add_theme_font_size_override("font_size", 22)
		lp.custom_minimum_size = Vector2(28,0)
		lp.add_theme_color_override("font_color",
			Color(1.0,0.84,0.0) if i < 3 else Color(0.5,0.5,0.5))
		row.add_child(lp)

		var ln = Label.new()
		ln.text = d.full_name() if d else entry["driver_id"]
		ln.add_theme_font_size_override("font_size", 22)
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_player:
			ln.add_theme_color_override("font_color", Color(0.3,0.9,0.5))
		else:
			ln.modulate = Color(0.75,0.75,0.75)
		row.add_child(ln)

		var lpts = Label.new()
		lpts.text = "%d pts" % entry.get("points",0)
		lpts.add_theme_font_size_override("font_size", 22)
		lpts.modulate = Color(0.6,0.6,0.6)
		row.add_child(lpts)

	return vb

func _build_group_chip(standings: Array, group_idx: int) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10,0.11,0.14)
	style.border_width_left = 1; style.border_color = Color(0.22,0.26,0.34)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_%s" % c, 3)
	style.content_margin_left = 6; style.content_margin_right = 6
	style.content_margin_top = 4; style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	panel.add_child(vb)

	var lg = Label.new()
	lg.text = "Group %d" % (group_idx+1)
	lg.add_theme_font_size_override("font_size", 18)
	lg.modulate = Color(0.45,0.45,0.45)
	vb.add_child(lg)

	if standings.size() > 0:
		var leader = standings[0]
		for s in standings:
			if s["points"] > leader["points"]: leader = s
		var d = GameState.all_drivers.get(leader["driver_id"])
		var ll = Label.new()
		ll.text = "%s  %dpts" % [
			d.full_name() if d else "?", leader["points"]]
		ll.add_theme_font_size_override("font_size", 20)
		ll.add_theme_color_override("font_color", Color(0.8,0.8,0.8))
		vb.add_child(ll)

	return panel

## ── World card (player not active) ───────────────────────────────────────────

func _build_world_card(cid: String, champ,
		reg: Dictionary, disc_color: Color) -> PanelContainer:
	var panel = _card(Color(0.08, 0.09, 0.11))
	var pstyle = panel.get_theme_stylebox("panel").duplicate()
	pstyle.border_width_left = 2
	pstyle.border_color = disc_color.darkened(0.4)
	panel.add_theme_stylebox_override("panel", pstyle)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	panel.add_child(hb)

	## Left: name + tier
	var info = VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(info)

	var lbl_name = Label.new()
	lbl_name.text = reg.get("name", cid)
	lbl_name.add_theme_font_size_override("font_size", 26)
	lbl_name.add_theme_color_override("font_color", disc_color.lightened(0.2))
	lbl_name.modulate.a = 0.75
	info.add_child(lbl_name)

	var lbl_sub = Label.new()
	lbl_sub.add_theme_font_size_override("font_size", 20)
	lbl_sub.modulate = Color(0.4, 0.4, 0.4)

	if champ != null:
		## Running this season — show leader
		if cid == "C-001" and GameState.gk_discipline != null:
			## GK special case (S37.2): the GK championship's champ.standings only ever holds the
			## player's group-0 snapshot (reset to 0 each round by _sync_gk_group0_to_standings),
			## so reading it here showed an empty/zero "leader" — GK looked resultless in the world
			## view for a non-GK career. The real GK field + champion live in GKDiscipline's shadow
			## standings, so read those instead.
			var gkd = GameState.gk_discipline
			var champ_entry: Dictionary = gkd.get_champion()  ## non-empty only once decided
			if not champ_entry.is_empty():
				lbl_sub.text = "Season complete"
				info.add_child(lbl_sub)
				var champ_d = GameState.all_drivers.get(champ_entry.get("driver_id", ""))
				var lbl_champ = Label.new()
				lbl_champ.text = "🏆 Champion: %s  ·  %d pts" % [
					champ_d.full_name() if champ_d else champ_entry.get("driver_id", "Unknown"),
					champ_entry.get("points", 0)]
				lbl_champ.add_theme_font_size_override("font_size", 22)
				lbl_champ.modulate = Color(0.65, 0.6, 0.45)
				info.add_child(lbl_champ)
				## S37.48 — GK team champion: the cumulative GK constructors table (CP3) lives in
				## champ.team_standings (preserved across the season, not the per-round driver wipe).
				_add_gk_team_leader(info, champ, "🏆 Team Champion")
			else:
				## Mid-season: show GK round progress + an indicative leader (top driver across all
				## shadow groups in the current round). GK is elimination-based, so this is the
				## current front-runner, not a cumulative points table.
				lbl_sub.text = "GK Round %d/%d" % [gkd.get_current_round(), gkd.get_round_count()]
				info.add_child(lbl_sub)
				var gk_leader := _gk_world_leader(cid)
				if not gk_leader.is_empty():
					var gl_d = GameState.all_drivers.get(gk_leader.get("driver_id", ""))
					var lbl_leader = Label.new()
					lbl_leader.text = "Top: %s  ·  %d pts" % [
						gl_d.full_name() if gl_d else gk_leader.get("driver_id", ""),
						gk_leader.get("points", 0)]
					lbl_leader.add_theme_font_size_override("font_size", 22)
					lbl_leader.modulate = Color(0.6, 0.6, 0.6)
					info.add_child(lbl_leader)
				## S37.48 — GK team leader (cumulative constructors table) mid-season too.
				_add_gk_team_leader(info, champ, "Team")
		else:
			lbl_sub.text = "Round %d/%d" % [champ.current_round, champ.num_races]
			info.add_child(lbl_sub)
			var sorted = champ.get_standings_sorted()
			if sorted.size() > 0:
				var leader_d = GameState.all_drivers.get(sorted[0]["driver_id"])
				var lbl_leader = Label.new()
				lbl_leader.text = "Leader: %s  ·  %d pts" % [
					leader_d.full_name() if leader_d else sorted[0]["driver_id"],
					sorted[0]["points"]]
				lbl_leader.add_theme_font_size_override("font_size", 22)
				lbl_leader.modulate = Color(0.6, 0.6, 0.6)
				info.add_child(lbl_leader)
			## S37.48 — show the TEAM (constructors) leader alongside the driver leader. The data
			## is populated by AIChampionshipSim.add_team_points (non-player champs) / the real sim
			## (player champ); previously the world card only displayed the driver leader.
			var team_sorted = champ.get_team_standings_sorted()
			if team_sorted.size() > 0:
				var t_name: String = team_sorted[0]["team_id"]
				for t in GameState.all_teams:
					if t.id == team_sorted[0]["team_id"]:
						t_name = t.team_name; break
				if team_sorted[0]["team_id"] == GameState.player_team.id:
					t_name = GameState.player_team.team_name
				var lbl_team = Label.new()
				lbl_team.text = "Team: %s  ·  %d pts" % [t_name, team_sorted[0]["points"]]
				lbl_team.add_theme_font_size_override("font_size", 22)
				lbl_team.modulate = Color(0.55, 0.6, 0.55)
				info.add_child(lbl_team)
	else:
		## Not running this season
		lbl_sub.text = "Not active this season"
		info.add_child(lbl_sub)

	## Right: tier badge
	var lbl_tier = Label.new()
	lbl_tier.text = "Tier %d" % reg.get("tier", 1)
	lbl_tier.add_theme_font_size_override("font_size", 20)
	lbl_tier.modulate = Color(0.4, 0.4, 0.4)
	lbl_tier.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(lbl_tier)

	return panel

## ── Helpers ───────────────────────────────────────────────────────────────────

## S37.48 — Adds a GK team (constructors) leader line to a world-card info column, reading the
## cumulative GK team table (champ.team_standings, CP3). `prefix` labels it ("Team" / "Team Champion").
func _add_gk_team_leader(info: VBoxContainer, champ, prefix: String) -> void:
	var team_sorted = champ.get_team_standings_sorted()
	if team_sorted.is_empty():
		return
	var t_name: String = team_sorted[0]["team_id"]
	for t in GameState.all_teams:
		if t.id == team_sorted[0]["team_id"]:
			t_name = t.team_name; break
	if team_sorted[0]["team_id"] == GameState.player_team.id:
		t_name = GameState.player_team.team_name
	var lbl_team = Label.new()
	lbl_team.text = "%s: %s  ·  %d pts" % [prefix, t_name, team_sorted[0]["points"]]
	lbl_team.add_theme_font_size_override("font_size", 22)
	lbl_team.modulate = Color(0.55, 0.6, 0.55)
	info.add_child(lbl_team)

## GK indicative leader for the world card: the top-points driver across ALL shadow groups in the
## current round (GK is elimination-based, so this is the current front-runner, not a season table).
func _gk_world_leader(cid: String) -> Dictionary:
	var gkd = GameState.gk_discipline
	if gkd == null: return {}
	var groups: Array = gkd.get_all_standings(cid)
	var best: Dictionary = {}
	for group in groups:
		for entry in group:
			if best.is_empty() or entry.get("points", 0) > best.get("points", -1):
				best = entry
	return best.duplicate() if not best.is_empty() else {}


func _player_in_championship(champ: Championship) -> bool:
	## Player is "in" a championship if they have a car registered to it
	for car in GameState.player_team_cars:
		if car.championship_id == champ.id:
			return true
	return false

func _get_player_pos_text(champ: Championship) -> String:
	var sorted = champ.get_standings_sorted()
	for i in range(sorted.size()):
		if sorted[i]["driver_id"] in GameState.player_team.drivers:
			var d = GameState.all_drivers.get(sorted[i]["driver_id"])
			return "P%d of %d  ·  %s  ·  %d pts" % [
				i+1, sorted.size(),
				d.full_name() if d else "Driver",
				sorted[i]["points"]]
	## Fall back to team standings
	var tsorted = champ.get_team_standings_sorted()
	for i in range(tsorted.size()):
		if tsorted[i]["team_id"] == GameState.player_team.id:
			return "Team P%d of %d  ·  %d pts" % [i+1, tsorted.size(), tsorted[i]["points"]]
	return "Not yet in standings"

func _build_standings_mini(champ: Championship, max_rows: int) -> VBoxContainer:
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	var sorted = champ.get_standings_sorted()
	var player_ids = GameState.player_team.drivers
	for i in range(min(max_rows, sorted.size())):
		var entry = sorted[i]
		var d = GameState.all_drivers.get(entry["driver_id"])
		var is_player = entry["driver_id"] in player_ids
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vb.add_child(row)
		var lp = Label.new()
		lp.text = "P%d" % (i+1)
		lp.add_theme_font_size_override("font_size", 22)
		lp.custom_minimum_size = Vector2(26,0)
		lp.add_theme_color_override("font_color",
			Color(1.0,0.84,0.0) if i < 3 else Color(0.5,0.5,0.5))
		row.add_child(lp)
		var ln = Label.new()
		ln.text = d.full_name() if d else entry["driver_id"]
		ln.add_theme_font_size_override("font_size", 22)
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_player: ln.add_theme_color_override("font_color", Color(0.3,0.9,0.5))
		else: ln.modulate = Color(0.7,0.7,0.7)
		row.add_child(ln)
		var lpts = Label.new()
		lpts.text = "%d pts" % entry["points"]
		lpts.add_theme_font_size_override("font_size", 22)
		lpts.modulate = Color(0.55,0.55,0.55)
		row.add_child(lpts)
	return vb

func _build_team_standings_mini(champ: Championship, max_rows: int) -> VBoxContainer:
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	var sorted = champ.get_team_standings_sorted()
	for i in range(min(max_rows, sorted.size())):
		var entry = sorted[i]
		var is_player = entry["team_id"] == GameState.player_team.id
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vb.add_child(row)
		var lp = Label.new()
		lp.text = "P%d" % (i+1)
		lp.add_theme_font_size_override("font_size", 22)
		lp.custom_minimum_size = Vector2(26,0)
		lp.add_theme_color_override("font_color",
			Color(1.0,0.84,0.0) if i < 3 else Color(0.5,0.5,0.5))
		row.add_child(lp)
		## Find team name
		var team_name = entry.get("team_id","?")
		for t in GameState.all_teams:
			if t.id == entry["team_id"]:
				team_name = t.team_name; break
		if entry["team_id"] == GameState.player_team.id:
			team_name = GameState.player_team.team_name
		var ln = Label.new()
		ln.text = team_name
		ln.add_theme_font_size_override("font_size", 22)
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_player: ln.add_theme_color_override("font_color", Color(0.3,0.9,0.5))
		else: ln.modulate = Color(0.7,0.7,0.7)
		row.add_child(ln)
		var lpts = Label.new()
		lpts.text = "%d pts" % entry["points"]
		lpts.add_theme_font_size_override("font_size", 22)
		lpts.modulate = Color(0.55,0.55,0.55)
		row.add_child(lpts)
	return vb

func _section_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.modulate = Color(0.45, 0.45, 0.45)
	return lbl

func _card(bg: Color = Color(0.11,0.12,0.16)) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.border_color = Color(0.20,0.24,0.32)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_%s" % c, 4)
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 8; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel
