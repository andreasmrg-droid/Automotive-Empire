extends Control
## Version: S28.4 — EOS only shows championships the player actually raced (fixes empty GK
##   card when not registered). GK standings read GKDiscipline (champion +
##   final-round group standings) instead of the empty champ.standings (Bug 1).
## --- S16.5 — "Our Driver" replaces "YOU"; team standings added; weekly profit in finances.
## Triggered by MainHub when _end_season() fires season_ended signal.
## Shows: standings, driver/staff improvement, R&D progress, financial status.
## "Continue to Season N" → MainHub (which shows Start Season button).

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right"]:
		margin.add_theme_constant_override(s, 60)
	for s in ["margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 32)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	# ── Title ─────────────────────────────────────────────────────────────────
	var lbl_title = Label.new()
	lbl_title.text = "🏁  SEASON %d COMPLETE" % GameState.current_season
	lbl_title.add_theme_font_size_override("font_size", 36)
	lbl_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(lbl_title)

	root.add_child(HSeparator.new())

	# ── Scrollable content ────────────────────────────────────────────────────
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18)
	scroll.add_child(content)

	content.add_child(_section_lbl("🏆  CHAMPIONSHIP STANDINGS"))
	content.add_child(_build_standings())
	content.add_child(HSeparator.new())

	content.add_child(_section_lbl("📈  DRIVER & STAFF PROGRESS"))
	content.add_child(_build_people())
	content.add_child(HSeparator.new())

	content.add_child(_section_lbl("🔬  R&D PIPELINE"))
	content.add_child(_build_rnd())
	content.add_child(HSeparator.new())

	content.add_child(_section_lbl("💰  FINANCIAL STATUS"))
	content.add_child(_build_finance())

	# ── Footer ────────────────────────────────────────────────────────────────
	root.add_child(HSeparator.new())

	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)

	var lbl_next = Label.new()
	lbl_next.text = "Season %d awaits. Review standings, then start your preparations." \
		% (GameState.current_season + 1)
	lbl_next.add_theme_font_size_override("font_size", 13)
	lbl_next.modulate = Color(0.55, 0.55, 0.55)
	lbl_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(lbl_next)

	var btn_reg = _action_btn("🏆 Registration →", Color(0.14, 0.32, 0.56))
	btn_reg.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ChampionshipSelect.tscn"))
	footer.add_child(btn_reg)

	var btn_cont = _action_btn("▶  Continue to Season %d" % (GameState.current_season + 1),
		Color(0.14, 0.48, 0.18))
	btn_cont.add_theme_font_size_override("font_size", 15)
	btn_cont.custom_minimum_size = Vector2(240, 44)
	btn_cont.pressed.connect(_on_continue)
	footer.add_child(btn_cont)


# ── Standings ─────────────────────────────────────────────────────────────────

func _build_standings() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	if GameState.active_championships.is_empty():
		vbox.add_child(_lbl_gray("No championships ran this season."))
		return vbox

	## S28.3 fix: only show championships the player actually RACED this season.
	## active_championships holds all championships (the world always runs); showing GK
	## when the player didn't register produced an empty/championless card.
	var raced: Array = []
	for champ in GameState.active_championships:
		if champ.id in GameState.player_registered_championships:
			raced.append(champ)

	if raced.is_empty():
		vbox.add_child(_lbl_gray("You didn't race any championship this season."))
		return vbox

	for champ in raced:
		var card = _card_panel(Color(0.09, 0.11, 0.15))
		var cv = VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		card.add_child(cv)

		var lbl_champ = Label.new()
		lbl_champ.text = "🏆 %s" % champ.championship_name
		lbl_champ.add_theme_font_size_override("font_size", 14)
		lbl_champ.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		cv.add_child(lbl_champ)

		## Driver standings
		var lbl_drv_hdr = Label.new()
		lbl_drv_hdr.text = "DRIVERS"
		lbl_drv_hdr.add_theme_font_size_override("font_size", 10)
		lbl_drv_hdr.modulate = Color(0.45, 0.45, 0.45)
		cv.add_child(lbl_drv_hdr)

		## S28.3 (Bug 1): GK Championship standings live in GKDiscipline, not champ.standings.
		## Show the season champion + the final-round group standings.
		if champ.id == "C-001" and GameState.gk_discipline != null:
			var gk = GameState.gk_discipline
			var champ_entry = gk.get_champion()
			if not champ_entry.is_empty():
				var cd = GameState.all_drivers.get(champ_entry.get("driver_id",""), null)
				var crow = HBoxContainer.new()
				crow.add_theme_constant_override("separation", 10)
				var clbl = Label.new()
				clbl.text = "🏆 Champion: %s — %d pts" % [
					cd.full_name() if cd else "Unknown", champ_entry.get("points", 0)]
				clbl.add_theme_font_size_override("font_size", 13)
				clbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
				crow.add_child(clbl)
				cv.add_child(crow)
			## Final-round group standings (top 5 across final groups)
			var gk_all = gk.get_all_standings("C-001")
			var gk_flat: Array = []
			for group in gk_all:
				for e in group:
					gk_flat.append(e)
			gk_flat.sort_custom(func(a, b): return a["points"] > b["points"])
			var gk_shown = 0
			for i in range(gk_flat.size()):
				if gk_shown >= 5: break
				var e = gk_flat[i]
				var gd = GameState.all_drivers.get(e.get("driver_id",""), null)
				if gd == null: continue
				var is_p = gd.id in GameState.player_team.drivers
				var grow = HBoxContainer.new()
				grow.add_theme_constant_override("separation", 10)
				var gpos = Label.new(); gpos.text = "P%d" % (i + 1)
				gpos.custom_minimum_size = Vector2(32, 0)
				gpos.add_theme_font_size_override("font_size", 13)
				grow.add_child(gpos)
				var gname = Label.new()
				gname.text = gd.full_name() + ("  ← Our Driver" if is_p else "")
				gname.add_theme_font_size_override("font_size", 13)
				gname.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				if is_p: gname.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
				grow.add_child(gname)
				var gpts = Label.new(); gpts.text = "%d pts" % e.get("points", 0)
				gpts.add_theme_font_size_override("font_size", 13)
				gpts.modulate = Color(0.65, 0.65, 0.65)
				grow.add_child(gpts)
				cv.add_child(grow)
				gk_shown += 1
			if gk_shown == 0:
				cv.add_child(_lbl_gray("GK season standings unavailable."))
			vbox.add_child(card)
			continue  ## GK handled — skip the generic standings block below

		var sorted = champ.get_standings_sorted()
		var shown = 0
		for i in range(sorted.size()):
			if shown >= 5: break
			var entry = sorted[i]
			var drv = GameState.all_drivers.get(entry.get("driver_id",""), null)
			if drv == null: continue
			var is_player = drv.id in GameState.player_team.drivers

			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)

			var lbl_pos = Label.new()
			lbl_pos.text = "P%d" % (i + 1)
			lbl_pos.custom_minimum_size = Vector2(32, 0)
			lbl_pos.add_theme_font_size_override("font_size", 13)
			lbl_pos.add_theme_color_override("font_color",
				Color(1.0, 0.85, 0.1) if i == 0 else
				Color(0.75, 0.75, 0.75) if i < 3 else Color(0.5, 0.5, 0.5))
			row.add_child(lbl_pos)

			var lbl_drv = Label.new()
			lbl_drv.text = drv.full_name() + ("  ← Our Driver" if is_player else "")
			lbl_drv.add_theme_font_size_override("font_size", 13)
			lbl_drv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if is_player:
				lbl_drv.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
			row.add_child(lbl_drv)

			var lbl_pts = Label.new()
			lbl_pts.text = "%d pts" % entry.get("points", 0)
			lbl_pts.add_theme_font_size_override("font_size", 13)
			lbl_pts.modulate = Color(0.65, 0.65, 0.65)
			row.add_child(lbl_pts)

			cv.add_child(row)
			shown += 1

		if sorted.size() > 5:
			cv.add_child(_lbl_gray("... and %d more" % (sorted.size() - 5)))

		## Team standings
		var team_sorted = champ.get_team_standings_sorted() if champ.has_method("get_team_standings_sorted") else []
		if not team_sorted.is_empty():
			cv.add_child(HSeparator.new())
			var lbl_team_hdr = Label.new()
			lbl_team_hdr.text = "TEAMS"
			lbl_team_hdr.add_theme_font_size_override("font_size", 10)
			lbl_team_hdr.modulate = Color(0.45, 0.45, 0.45)
			cv.add_child(lbl_team_hdr)
			var t_shown = 0
			for i in range(team_sorted.size()):
				if t_shown >= 5: break
				var t_entry = team_sorted[i]
				var team = null
				for t in GameState.all_teams:
					if t.id == t_entry.get("team_id", ""): team = t; break
				if team == null: continue
				var is_player_team = team.is_player_team
				var t_row = HBoxContainer.new()
				t_row.add_theme_constant_override("separation", 10)
				var t_pos = Label.new()
				t_pos.text = "P%d" % (i + 1)
				t_pos.custom_minimum_size = Vector2(32, 0)
				t_pos.add_theme_font_size_override("font_size", 12)
				t_pos.add_theme_color_override("font_color",
					Color(1.0, 0.85, 0.1) if i == 0 else
					Color(0.75, 0.75, 0.75) if i < 3 else Color(0.5, 0.5, 0.5))
				t_row.add_child(t_pos)
				var t_name = Label.new()
				t_name.text = team.team_name + ("  ← Us" if is_player_team else "")
				t_name.add_theme_font_size_override("font_size", 12)
				t_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				if is_player_team:
					t_name.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
				t_row.add_child(t_name)
				var t_pts = Label.new()
				t_pts.text = "%d pts" % t_entry.get("points", 0)
				t_pts.add_theme_font_size_override("font_size", 12)
				t_pts.modulate = Color(0.65, 0.65, 0.65)
				t_row.add_child(t_pts)
				cv.add_child(t_row)
				t_shown += 1

		vbox.add_child(card)

	return vbox


# ── People ────────────────────────────────────────────────────────────────────

func _build_people() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var any = false
	for drv_id in GameState.player_team.drivers:
		var drv = GameState.all_drivers.get(drv_id)
		if not drv: continue
		any = true
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var lbl = Label.new()
		lbl.text = "🏎 %s  (age %d)" % [drv.full_name(), drv.age]
		lbl.custom_minimum_size = Vector2(220, 0)
		lbl.add_theme_font_size_override("font_size", 13)
		row.add_child(lbl)
		for s in [["Pace", drv.pace],["Ctrl", drv.car_control],["Focus", drv.focus],["Exp", drv.experience]]:
			var sl = Label.new()
			sl.text = "%s %.0f" % [s[0], s[1]]
			sl.add_theme_font_size_override("font_size", 12)
			sl.add_theme_color_override("font_color", _skill_col(s[1]))
			sl.custom_minimum_size = Vector2(72, 0)
			row.add_child(sl)
		vbox.add_child(row)

	if not any:
		vbox.add_child(_lbl_gray("No drivers on your team."))

	vbox.add_child(HSeparator.new())

	var any_staff = false
	for sid in GameState.all_staff:
		var s = GameState.all_staff[sid]
		if s.contract_team != GameState.player_team.id: continue
		any_staff = true
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var lbl = Label.new()
		lbl.text = "👤 %s  (%s)" % [s.full_name(), s.role]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		var sk = Label.new()
		sk.text = "%s %.0f" % [s.get_primary_skill_label(), s.get_primary_skill()]
		sk.add_theme_font_size_override("font_size", 12)
		sk.add_theme_color_override("font_color", _skill_col(s.get_primary_skill()))
		row.add_child(sk)
		var cl = Label.new()
		cl.text = "%d season%s left" % [s.contract_seasons_remaining,
			"s" if s.contract_seasons_remaining != 1 else ""]
		cl.add_theme_font_size_override("font_size", 11)
		cl.add_theme_color_override("font_color",
			Color(1.0, 0.4, 0.4) if s.contract_seasons_remaining <= 1 else Color(0.55, 0.55, 0.55))
		row.add_child(cl)
		vbox.add_child(row)

	if not any_staff:
		vbox.add_child(_lbl_gray("No staff on your team."))

	return vbox


# ── R&D ───────────────────────────────────────────────────────────────────────

func _build_rnd() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var inv_qty = 0
	for k in GameState.cnc_parts_inventory:
		var item = GameState.cnc_parts_inventory[k]
		inv_qty += item.get("quantity",0) if item is Dictionary else int(item)

	for data in [
		["Completed R&D tasks",    "%d" % GameState.completed_rnd_tasks.size(), Color(0.4, 0.9, 0.4)],
		["Blueprints in database", "%d" % GameState.known_blueprints.size(),    Color(0.4, 0.8, 1.0)],
		["WRA submissions pending","%d" % GameState.active_wra_submissions.size(),
			Color(1.0, 0.6, 0.2) if not GameState.active_wra_submissions.is_empty() else Color(0.5,0.5,0.5)],
		["WRA approved (ready)",   "%d" % GameState.wra_approved_blueprints.size(),
			Color(0.4, 0.9, 0.4) if not GameState.wra_approved_blueprints.is_empty() else Color(0.5,0.5,0.5)],
		["CNC jobs queued",        "%d" % GameState.cnc_production_queue.size(),
			Color(1.0, 0.75, 0.2) if not GameState.cnc_production_queue.is_empty() else Color(0.5,0.5,0.5)],
		["Parts in warehouse",     "%d units" % inv_qty,
			Color(0.4, 0.9, 0.4) if inv_qty > 0 else Color(0.5,0.5,0.5)],
	]:
		vbox.add_child(_stat_row(data[0], data[1], data[2]))

	if not GameState.wra_approved_blueprints.is_empty():
		var btn = _action_btn("⚙ Go to CNC Plant →", Color(0.14, 0.35, 0.55))
		btn.pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn"))
		vbox.add_child(btn)

	if inv_qty > 0:
		var btn = _action_btn("🔩 Go to Garage to install parts →", Color(0.14, 0.35, 0.55))
		btn.pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/buildings/Garage.tscn"))
		vbox.add_child(btn)

	return vbox


# ── Finance ───────────────────────────────────────────────────────────────────

func _build_finance() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	var team = GameState.player_team
	## S28.3 (Bug 4): "Weekly Profit" here was team.balance − _prev_week_balance, which spans
	## the season transition (prizes, fees) and produced garbage like −40,500. A single-week
	## delta is meaningless on a season summary, so it's removed. Weekly Expenses (accurate,
	## recurring) is kept. TODO: add a real Season Net P&L (needs a season-start balance tracker).
	for data in [
		["Balance",          "CR %s" % _fmt(int(team.balance)),
			Color(0.4,0.9,0.4) if team.balance >= 0 else Color(1.0,0.4,0.4)],
		["Weekly Expenses",  "CR %s" % _fmt(int(GameState.get_weekly_expenses())), Color(1.0,0.6,0.4)],
		["Runway",           "%d wks" % GameState.get_runway_weeks()
			if GameState.get_runway_weeks() < 999 else "Stable", Color(0.7,0.7,0.7)],
		["Active Sponsors",  "%d / %d slots" % [
			GameState.active_sponsors.size(), GameState.get_hq_sponsor_slots()], Color(0.6,0.8,1.0)],
		["Pending Offers",   "%d" % GameState.sponsor_offers.size(), Color(0.7,0.85,0.7)],
		["CEO Accumulated",  "CR %s" % _fmt(int(GameState.ceo_accumulated_salary)), Color(0.85,0.75,0.5)],
		["Reputation",       "%.0f / 100" % team.reputation, Color(0.9,0.8,0.3)],
		["Marketability",    "%.0f / 100" % team.marketability, Color(0.6,0.8,1.0)],
	]:
		vbox.add_child(_stat_row(data[0], data[1], data[2]))

	if not GameState.active_sponsors.is_empty():
		vbox.add_child(HSeparator.new())
		vbox.add_child(_lbl_gray("Active sponsors:"))
		for sp in GameState.active_sponsors:
			var detail = ""
			match sp.get("type", 1):
				1: detail = "+CR %s/wk" % _fmt(sp.get("weekly_payment", 0))
				2: detail = "Win: CR %s" % _fmt(sp.get("win_bonus", 0))
				3: detail = "Commitment deal"
			var lbl = Label.new()
			lbl.text = "  • %s  (%s)  ·  %d season%s left" % [
				sp.get("name","?"), detail,
				sp.get("seasons_remaining",1),
				"s" if sp.get("seasons_remaining",1) != 1 else ""]
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
			vbox.add_child(lbl)

	return vbox


# ── Action ────────────────────────────────────────────────────────────────────

func _on_continue() -> void:
	## pending_season_screen stays "end_of_season" so MainHub shows "Start Season N" button
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")


# ── Helpers ───────────────────────────────────────────────────────────────────

func _section_lbl(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	return l

func _lbl_gray(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.modulate = Color(0.5, 0.5, 0.5)
	l.add_theme_font_size_override("font_size", 12)
	return l

func _stat_row(key: String, value: String, col: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var k = Label.new(); k.text = key
	k.custom_minimum_size = Vector2(220, 0)
	k.add_theme_font_size_override("font_size", 12)
	k.modulate = Color(0.45, 0.45, 0.45)
	row.add_child(k)
	var v = Label.new(); v.text = value
	v.add_theme_font_size_override("font_size", 12)
	v.add_theme_color_override("font_color", col)
	row.add_child(v)
	return row

func _card_panel(bg: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.border_color = Color(0.20, 0.25, 0.35)
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _action_btn(text: String, bg: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 34)
	btn.add_theme_font_size_override("font_size", 13)
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	return btn

func _skill_col(v: float) -> Color:
	if v >= 75: return Color(0.3, 1.0, 0.3)
	elif v >= 50: return Color(1.0, 0.84, 0.0)
	elif v >= 30: return Color(1.0, 0.6, 0.2)
	return Color(0.7, 0.4, 0.4)

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.2fM" % (n / 1000000.0)
	if n >= 1000:    return "%dK" % (n / 1000)
	return str(n)
