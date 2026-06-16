extends Control
## Version: S22.8 — #6 Chart title overlap fixed; #7 Take Loan at top; #9 DNS requirements checklist in WRA.
##                    Active loan cards, Take Loan popup (amount slider, duration, live rate/payment).
##                    Weekly expense panel now shows real loan repayments sum.
##                    Economy chart updated: now shows continuous index 0-100 (not categorical 0/1/2).
##                    Key Indicators shows active loans count.

var _current_tab: String = "overview"
var _tab_buttons: Dictionary = {}
var _content_area: ScrollContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	## If a notification routed us here with a specific tab, set it before building
	## so _build_ui's initial _show_tab call opens the right tab directly.
	if GameState.pending_hq_tab != "":
		_current_tab = GameState.pending_hq_tab
		GameState.pending_hq_tab = ""
	await _build_ui()
	GameState.log_updated.connect(func(): _show_tab(_current_tab))

# ══════════════════════════════════════════════════════════════════════════════
# ROOT LAYOUT
# ══════════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	for c in get_children(): c.queue_free()
	await get_tree().process_frame

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right"]:
		margin.add_theme_constant_override(s, 28)
	for s in ["margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 18)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var lbl_title = Label.new()
	lbl_title.text = "🏛  HEADQUARTERS"
	lbl_title.add_theme_font_size_override("font_size", 22)
	lbl_title.add_theme_color_override("font_color", Color.WHITE)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	var building = GameState.campus_buildings.get("Headquarters", {})
	var lbl_lv = Label.new()
	lbl_lv.text = "Level %d" % building.get("level", 1)
	lbl_lv.add_theme_font_size_override("font_size", 13)
	lbl_lv.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	header.add_child(lbl_lv)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(90, 34)
	btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/campus.tscn"))
	header.add_child(btn_back)

	root.add_child(HSeparator.new())

	# Tab bar
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 4)
	root.add_child(tab_bar)

	_tab_buttons = {}
	for tab in [["overview","📊  Overview"], ["sponsors","💰  Financial Department"], ["wra","📋  World Racing Association"]]:
		var btn = Button.new()
		btn.text = tab[1]
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 13)
		var tid = tab[0]
		btn.pressed.connect(func(): _show_tab(tid))
		tab_bar.add_child(btn)
		_tab_buttons[tab[0]] = btn

	# Content scroll area
	_content_area = ScrollContainer.new()
	_content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_area.clip_contents = true
	root.add_child(_content_area)

	_show_tab(_current_tab)


func _show_tab(tab: String) -> void:
	_current_tab = tab

	# Update tab button styles
	for tid in _tab_buttons:
		var btn = _tab_buttons[tid]
		var active = tid == tab
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.18, 0.28, 0.45) if active else Color(0.10, 0.12, 0.15)
		style.border_width_bottom = 3 if active else 0
		style.border_color = Color(0.4, 0.75, 1.0)
		style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
		style.content_margin_left = 12; style.content_margin_right = 12
		style.content_margin_top = 6; style.content_margin_bottom = 6
		btn.add_theme_stylebox_override("normal", style)

	# Clear content — queue_free is safe here; await ensures nodes are gone before rebuild
	for c in _content_area.get_children():
		c.queue_free()
	await get_tree().process_frame

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	_content_area.add_child(content)

	match tab:
		"overview":  _build_overview(content)
		"sponsors":  _build_sponsors_tab(content)
		"wra":       _build_wra_tab(content)


# ══════════════════════════════════════════════════════════════════════════════
# TAB 1 — OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════

func _build_overview(parent: VBoxContainer) -> void:
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(cols)

	# ── Left column ───────────────────────────────────────────────────────────
	var left = VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left.add_theme_constant_override("separation", 14)
	cols.add_child(left)

	left.add_child(_section_label("CEO"))
	left.add_child(_build_ceo_card())
	left.add_child(HSeparator.new())
	left.add_child(_section_label("FINANCES"))
	left.add_child(_build_finance_strip())
	left.add_child(HSeparator.new())
	left.add_child(_section_label("HQ EFFECTS"))
	left.add_child(_build_effects_card())

	# ── Center column ─────────────────────────────────────────────────────────
	var center = VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	center.add_theme_constant_override("separation", 14)
	cols.add_child(center)

	center.add_child(_section_label("ACTIVE CHAMPIONSHIPS"))
	center.add_child(_build_champs_strip())
	center.add_child(HSeparator.new())
	center.add_child(_section_label("DRIVERS"))
	center.add_child(_build_drivers_strip())
	center.add_child(HSeparator.new())
	center.add_child(_section_label("STAFF"))
	center.add_child(_build_staff_grid())
	center.add_child(HSeparator.new())

	## Pending Activity (approaches, bonds, pre-signed)
	var pending = _build_pending_activity()
	if pending != null:
		center.add_child(_section_label("PENDING ACTIVITY"))
		center.add_child(pending)
		center.add_child(HSeparator.new())

	center.add_child(_section_label("SPONSORS"))
	center.add_child(_build_active_sponsor_card_hq())

	# ── Right column ──────────────────────────────────────────────────────────
	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(260, 0)
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right.add_theme_constant_override("separation", 14)
	cols.add_child(right)

	right.add_child(_section_label("TEAM PRINCIPAL SLOTS"))
	right.add_child(_build_tp_slots())
	right.add_child(HSeparator.new())
	right.add_child(_section_label("CFO"))
	right.add_child(_build_cfo_slot())
	right.add_child(HSeparator.new())
	right.add_child(_section_label("NAVIGATE"))
	right.add_child(_build_nav_buttons())


func _build_ceo_card() -> PanelContainer:
	var panel = _card(Color(0.11, 0.13, 0.18))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	var icon = Label.new(); icon.text = "👔"
	icon.add_theme_font_size_override("font_size", 20)
	name_row.add_child(icon)
	var name_vb = VBoxContainer.new()
	var lbl_role = Label.new(); lbl_role.text = "CEO  (You)"
	lbl_role.add_theme_font_size_override("font_size", 10)
	lbl_role.modulate = Color(0.5, 0.5, 0.5)
	name_vb.add_child(lbl_role)
	var lbl_name = Label.new()
	lbl_name.text = GameState.player_name if GameState.player_name != "" else "CEO"
	lbl_name.add_theme_font_size_override("font_size", 15)
	lbl_name.add_theme_color_override("font_color", Color.WHITE)
	name_vb.add_child(lbl_name)
	name_row.add_child(name_vb)
	vbox.add_child(name_row)
	vbox.add_child(HSeparator.new())

	for row_data in [
		["Age",         "%d" % GameState.ceo_age,              Color(0.75, 0.75, 0.75)],
		["Sex",         GameState.ceo_sex,                     Color(0.75, 0.75, 0.75)],
		["Nationality", GameState.player_team_nationality,     Color(0.75, 0.75, 0.75)],
		["Salary",      "1% of weekly net profit",            Color(0.65, 0.65, 0.65)],
		["Accumulated", "CR %s" % _fmt(int(GameState.ceo_accumulated_salary)),
			Color(0.95, 0.82, 0.3)],
	]:
		vbox.add_child(_kv_row(row_data[0], row_data[1], 90, row_data[2]))

	return panel


func _build_finance_strip() -> PanelContainer:
	var panel = _card(Color(0.09, 0.12, 0.10))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	var team = GameState.player_team
	var expenses = GameState.get_weekly_expenses()
	var runway = GameState.get_runway_weeks()

	for row_data in [
		["Balance",      "CR %s" % _fmt(int(team.balance)),
			Color(0.4, 0.9, 0.4) if team.balance >= 0 else Color(1.0, 0.35, 0.35)],
		["Wkly Cost",    "CR %s" % _fmt(int(expenses)), Color(1.0, 0.55, 0.35)],
		["Runway",       "%d wks" % runway if runway < 999 else "Stable",
			Color(0.4,0.9,0.4) if runway >= 8 else Color(1.0,0.6,0.1) if runway >= 4 else Color(1.0,0.3,0.3)],
		["Reputation",   "%.0f / 100" % team.reputation, Color(0.9, 0.8, 0.3)],
		["Marketability","%.0f / 100" % GameState.get_team_marketability(), Color(0.4, 0.8, 1.0)],
		["Active Fans",  _fmt_fans(GameState.get_team_active_fans()), Color(0.7, 0.85, 0.6)],
	]:
		vbox.add_child(_kv_row(row_data[0], row_data[1], 90, row_data[2]))

	return panel


func _build_effects_card() -> PanelContainer:
	var panel = _card(Color(0.10, 0.10, 0.14))
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)
	var b = GameState.campus_buildings.get("Headquarters", {})
	var lv = b.get("level", 1)
	for rd in [
		["+%d%% Mktg Bonus" % lv,          Color(0.6, 0.8, 1.0)],
		["%d Sponsor Slots" % (1 + lv / 2),  Color(0.6, 0.8, 1.0)],
		["%d TP Slot%s" % [GameState.get_hq_tp_slots(), "s" if GameState.get_hq_tp_slots() != 1 else ""],
			Color(0.6, 0.8, 1.0)],
		["Loan Tier %d" % min(lv / 3 + 1, 5), Color(0.6, 0.8, 1.0)],
	]:
		var lbl = Label.new(); lbl.text = rd[0]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", rd[1])
		vbox.add_child(lbl)
	return panel


func _build_champs_strip() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	## Only show championships where the player has a car
	var player_champ_ids: Array = []
	for car in GameState.player_team_cars:
		if not car.championship_id in player_champ_ids:
			player_champ_ids.append(car.championship_id)

	var player_champs: Array = []
	for champ in GameState.active_championships:
		if champ.id in player_champ_ids:
			player_champs.append(champ)

	if player_champs.is_empty():
		var lbl = Label.new()
		lbl.text = "No active championships. Register via World Racing Association tab."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(lbl)
		return vbox

	for champ in player_champs:
		var card = _card(Color(0.10, 0.13, 0.18))
		var inner = HBoxContainer.new()
		inner.add_theme_constant_override("separation", 12)
		card.add_child(inner)

		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inner.add_child(info)

		var lbl_name = Label.new()
		lbl_name.text = "🏆 %s" % champ.championship_name
		lbl_name.add_theme_font_size_override("font_size", 13)
		lbl_name.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		info.add_child(lbl_name)

		var sorted = champ.get_standings_sorted()
		var player_pos = 0; var player_pts = 0
		for i in range(sorted.size()):
			if sorted[i].get("driver_id","") in GameState.player_team.drivers:
				if player_pos == 0 or sorted[i]["points"] > player_pts:
					player_pos = i + 1; player_pts = sorted[i]["points"]

		var races_done = champ.current_round
		var lbl_detail = Label.new()
		lbl_detail.text = "P%d  ·  %d pts  ·  Round %d / %d" % [
			player_pos, player_pts, races_done, champ.num_races]
		lbl_detail.add_theme_font_size_override("font_size", 11)
		lbl_detail.modulate = Color(0.55, 0.55, 0.55)
		info.add_child(lbl_detail)

		vbox.add_child(card)

	return vbox


func _build_drivers_strip() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	if GameState.player_team.drivers.is_empty():
		var lbl = Label.new(); lbl.text = "No drivers signed."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(lbl)
		return vbox

	for d_id in GameState.player_team.drivers:
		var d = GameState.all_drivers.get(d_id)
		if not d: continue
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		var lbl_name = Label.new()
		lbl_name.text = d.full_name()
		lbl_name.custom_minimum_size = Vector2(150, 0)
		lbl_name.add_theme_font_size_override("font_size", 12)
		lbl_name.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		row.add_child(lbl_name)

		for stat in [["Pace", d.pace],["Wet", d.wet],["Focus", d.focus],["Craft", d.race_craft]]:
			var sl = Label.new()
			sl.text = "%s %.0f" % [stat[0], stat[1]]
			sl.add_theme_font_size_override("font_size", 11)
			sl.add_theme_color_override("font_color", _skill_col(stat[1]))
			sl.custom_minimum_size = Vector2(68, 0)
			row.add_child(sl)

		var lbl_sal = Label.new()
		lbl_sal.text = "CR %s/wk" % _fmt(int(d.weekly_salary)) if d.weekly_salary > 0 else "—"
		lbl_sal.add_theme_font_size_override("font_size", 11)
		lbl_sal.modulate = Color(0.5, 0.5, 0.5)
		row.add_child(lbl_sal)

		vbox.add_child(row)

	return vbox


func _build_staff_grid() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)

	var hired = []
	for sid in GameState.all_staff:
		var s = GameState.all_staff[sid]
		if s.contract_team == GameState.player_team.id:
			hired.append(s)

	if hired.is_empty():
		var lbl = Label.new(); lbl.text = "No staff hired."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(lbl)
		return vbox

	## Group by role
	var by_role: Dictionary = {}
	for s in hired:
		if not s.role in by_role: by_role[s.role] = []
		by_role[s.role].append(s)

	const ROLE_ORDER = ["Team Principal","CFO","Race Strategist","Race Mechanic","Designer","Pit Crew"]
	var roles_shown = []
	for r in ROLE_ORDER:
		if r in by_role: roles_shown.append(r)
	for r in by_role:
		if not r in roles_shown: roles_shown.append(r)

	for role in roles_shown:
		var staffs = by_role[role]
		var sec = Label.new()
		sec.text = role.to_upper()
		sec.add_theme_font_size_override("font_size", 10)
		sec.modulate = Color(0.4, 0.4, 0.4)
		vbox.add_child(sec)

		for s in staffs:
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)

			var lbl_n = Label.new()
			lbl_n.text = s.full_name()
			lbl_n.custom_minimum_size = Vector2(150, 0)
			lbl_n.add_theme_font_size_override("font_size", 12)
			lbl_n.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
			row.add_child(lbl_n)

			var lbl_sk = Label.new()
			lbl_sk.text = "%s %.0f" % [s.get_primary_skill_label(), s.get_primary_skill()]
			lbl_sk.add_theme_font_size_override("font_size", 12)
			lbl_sk.add_theme_color_override("font_color", _skill_col(s.get_primary_skill()))
			lbl_sk.custom_minimum_size = Vector2(100, 0)
			row.add_child(lbl_sk)

			var lbl_c = Label.new()
			lbl_c.text = "%d season%s" % [s.contract_seasons_remaining,
				"s" if s.contract_seasons_remaining != 1 else ""]
			lbl_c.add_theme_font_size_override("font_size", 11)
			lbl_c.add_theme_color_override("font_color",
				Color(1.0, 0.4, 0.4) if s.contract_seasons_remaining <= 1
				else Color(0.5, 0.5, 0.5))
			row.add_child(lbl_c)

			vbox.add_child(row)

	return vbox

func _build_active_sponsor_card_hq() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	if GameState.active_sponsors.is_empty():
		var lbl = Label.new(); lbl.text = "No sponsors signed."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(lbl)
		return vbox

	for sp in GameState.active_sponsors:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)

		## Name — fixed 160px, matches driver/staff column
		var lbl_name = Label.new()
		lbl_name.text = sp.get("name", "?")
		lbl_name.custom_minimum_size = Vector2(160, 0)
		lbl_name.add_theme_font_size_override("font_size", 12)
		lbl_name.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		row.add_child(lbl_name)

		## Type detail — colour-coded, expand to fill
		var detail = ""
		var detail_col: Color
		match sp.get("type", 1):
			1:
				detail = "+CR %s/wk" % _fmt(sp.get("weekly_payment", 0))
				detail_col = Color(0.4, 0.88, 0.55)   ## green
			2:
				detail = "Win: CR %s" % _fmt(sp.get("win_bonus", 0))
				detail_col = Color(1.0, 0.75, 0.3)    ## amber
			3:
				detail = "Commitment deal"
				detail_col = Color(0.55, 0.75, 1.0)   ## blue
			_:
				detail = "—"
				detail_col = Color(0.5, 0.5, 0.5)
		var lbl_detail = Label.new()
		lbl_detail.text = detail
		lbl_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_detail.add_theme_font_size_override("font_size", 11)
		lbl_detail.add_theme_color_override("font_color", detail_col)
		row.add_child(lbl_detail)

		## Seasons remaining — right-aligned, red if last season
		var seasons = sp.get("seasons_remaining", 1)
		var lbl_s = Label.new()
		lbl_s.text = "%d season%s left" % [seasons, "s" if seasons != 1 else ""]
		lbl_s.add_theme_font_size_override("font_size", 11)
		lbl_s.add_theme_color_override("font_color",
			Color(1.0, 0.4, 0.4) if seasons <= 1 else Color(0.5, 0.5, 0.5))
		row.add_child(lbl_s)

		vbox.add_child(row)

	return vbox

func _build_tp_slots() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	var max_tp = GameState.get_hq_tp_slots()
	var hired_tp = GameState.get_player_staff_by_role("Team Principal")

	for i in range(max_tp):
		var card = _card(Color(0.10, 0.12, 0.16))
		var inner = VBoxContainer.new()
		inner.add_theme_constant_override("separation", 4)
		card.add_child(inner)

		if i < hired_tp.size():
			var tp = hired_tp[i]
			var lbl_n = Label.new()
			lbl_n.text = "🧑‍💼 " + tp.full_name()
			lbl_n.add_theme_font_size_override("font_size", 13)
			lbl_n.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			inner.add_child(lbl_n)
			var lbl_s = Label.new()
			lbl_s.text = "Strat %.0f  ·  Pace %.0f  ·  CR %s/wk" % [
				tp.race_strategy, tp.race_pace_reading, _fmt(int(tp.weekly_salary))]
			lbl_s.add_theme_font_size_override("font_size", 11)
			lbl_s.modulate = Color(0.55, 0.55, 0.55)
			inner.add_child(lbl_s)

			## Assignment
			var reg = GameState.CHAMPIONSHIP_REGISTRY.get(tp.assigned_championship, {})
			var lbl_a = Label.new()
			lbl_a.text = "→ %s" % reg.get("name", tp.assigned_championship) \
				if tp.assigned_championship != "" else "⚠ Not assigned"
			lbl_a.add_theme_font_size_override("font_size", 11)
			lbl_a.add_theme_color_override("font_color",
				Color(0.4, 0.85, 0.4) if tp.assigned_championship != ""
				else Color(1.0, 0.6, 0.2))
			inner.add_child(lbl_a)

			var btn_row = HBoxContainer.new()
			btn_row.add_theme_constant_override("separation", 4)
			inner.add_child(btn_row)
			var btn_assign = Button.new()
			btn_assign.text = "Assign →"
			btn_assign.add_theme_font_size_override("font_size", 10)
			btn_assign.custom_minimum_size = Vector2(70, 22)
			var tp_id = tp.id
			btn_assign.pressed.connect(func(): _show_tp_assign_popup(tp_id))
			btn_row.add_child(btn_assign)
			var btn_rel = Button.new()
			btn_rel.text = "Release"
			btn_rel.add_theme_font_size_override("font_size", 10)
			btn_rel.custom_minimum_size = Vector2(60, 22)
			btn_rel.modulate = Color(1.0, 0.45, 0.45)
			var tid = tp.id
			btn_rel.pressed.connect(func():
				GameState.release_staff(tid)
				_show_tab("overview"))
			btn_row.add_child(btn_rel)
		else:
			var lbl_e = Label.new()
			lbl_e.text = "TP Slot %d — Empty" % (i + 1)
			lbl_e.modulate = Color(0.45, 0.45, 0.45)
			lbl_e.add_theme_font_size_override("font_size", 12)
			inner.add_child(lbl_e)
			var btn_h = Button.new()
			btn_h.text = "Hire TP →"
			btn_h.add_theme_font_size_override("font_size", 11)
			btn_h.pressed.connect(func():
				GameState.pending_staff_filter = "Team Principal"
				get_tree().change_scene_to_file("res://scenes/Staff.tscn"))
			inner.add_child(btn_h)

		vbox.add_child(card)

	return vbox


var _tp_popup: PanelContainer = null

func _show_tp_assign_popup(tp_id: String) -> void:
	if _tp_popup != null and is_instance_valid(_tp_popup):
		_tp_popup.queue_free()

	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_tp_popup = PanelContainer.new()
	_tp_popup.custom_minimum_size = Vector2(300, 0)
	_tp_popup.set_anchor(SIDE_LEFT,   0.5)
	_tp_popup.set_anchor(SIDE_RIGHT,  0.5)
	_tp_popup.set_anchor(SIDE_TOP,    0.15)
	_tp_popup.set_anchor(SIDE_BOTTOM, 0.15)
	_tp_popup.offset_left   = -250
	_tp_popup.offset_right  = 0
	_tp_popup.offset_top    = 0
	_tp_popup.offset_bottom = 0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.17)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.30, 0.50, 0.80)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 16; style.content_margin_right = 16
	style.content_margin_top = 14; style.content_margin_bottom = 14
	_tp_popup.add_theme_stylebox_override("panel", style)
	add_child(_tp_popup)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_tp_popup.add_child(vb)

	var tp = GameState.all_staff.get(tp_id)
	var hdr = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = "Assign %s to championship:" % (tp.full_name() if tp else "TP")
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hdr.add_child(lbl)
	var close = Button.new()
	close.text = "✕"; close.flat = true
	close.custom_minimum_size = Vector2(28, 28)
	close.pressed.connect(func(): dim.queue_free(); _tp_popup.queue_free(); _tp_popup = null)
	hdr.add_child(close)
	vb.add_child(hdr)
	vb.add_child(HSeparator.new())

	## TP assignment: only show player's championships (has a car)
	var player_champ_ids2: Array = []
	for car in GameState.player_team_cars:
		if not car.championship_id in player_champ_ids2:
			player_champ_ids2.append(car.championship_id)
	var player_champs2 = GameState.active_championships.filter(
		func(c): return c.id in player_champ_ids2)

	if player_champs2.is_empty():
		var e = Label.new()
		e.text = "No active championships."
		e.modulate = Color(0.5, 0.5, 0.5)
		vb.add_child(e)
	else:
		for champ in player_champs2:
			var reg = GameState.CHAMPIONSHIP_REGISTRY.get(champ.id, {})
			var champ_name = reg.get("name", champ.id)
			var slot_taken = false
			for sid in GameState.all_staff:
				var s = GameState.all_staff[sid]
				if s.id == tp_id: continue
				if s.role == "Team Principal" and s.contract_team == GameState.player_team.id \
						and s.assigned_championship == champ.id:
					slot_taken = true; break
			var btn = Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 34)
			if slot_taken:
				btn.text = "🔒 %s (slot taken)" % champ_name
				btn.disabled = true; btn.modulate = Color(0.5, 0.5, 0.5)
			elif tp != null and tp.assigned_championship == champ.id:
				btn.text = "✅ %s (current)" % champ_name
				btn.disabled = true
			else:
				btn.text = "→ %s" % champ_name
				var cid = champ.id
				btn.pressed.connect(func():
					GameState.assign_staff_to_championship(tp_id, cid)
					dim.queue_free(); _tp_popup.queue_free(); _tp_popup = null
					_show_tab("overview"))
			vb.add_child(btn)

	if tp != null and tp.assigned_championship != "":
		var btn_u = Button.new()
		btn_u.text = "✕ Unassign"
		btn_u.modulate = Color(0.9, 0.4, 0.4)
		btn_u.pressed.connect(func():
			tp.assigned_championship = ""
			dim.queue_free(); _tp_popup.queue_free(); _tp_popup = null
			_show_tab("overview"))
		vb.add_child(btn_u)


func _build_cfo_slot() -> PanelContainer:
	var panel = _card(Color(0.10, 0.12, 0.16))
	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	panel.add_child(inner)

	var cfos = GameState.get_player_staff_by_role("CFO")
	if not cfos.is_empty():
		var cfo = cfos[0]
		var lbl_n = Label.new()
		lbl_n.text = "💼 " + cfo.full_name()
		lbl_n.add_theme_font_size_override("font_size", 13)
		lbl_n.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		inner.add_child(lbl_n)
		var lbl_s = Label.new()
		lbl_s.text = "FinMgmt %.0f  ·  Neg %.0f  ·  Sales %.0f" % [
			cfo.budget_planning, cfo.sponsor_negotiation, cfo.sales_skill]
		lbl_s.add_theme_font_size_override("font_size", 11)
		lbl_s.modulate = Color(0.55, 0.55, 0.55)
		inner.add_child(lbl_s)
		var lbl_c = Label.new()
		lbl_c.text = "CR %s/wk  ·  %d season%s left" % [
			_fmt(int(cfo.weekly_salary)), cfo.contract_seasons_remaining,
			"s" if cfo.contract_seasons_remaining != 1 else ""]
		lbl_c.add_theme_font_size_override("font_size", 11)
		lbl_c.modulate = Color(0.5, 0.5, 0.5)
		inner.add_child(lbl_c)
		var btn_rel = Button.new()
		btn_rel.text = "Release CFO"
		btn_rel.add_theme_font_size_override("font_size", 11)
		btn_rel.modulate = Color(1.0, 0.45, 0.45)
		var cid = cfo.id
		btn_rel.pressed.connect(func():
			GameState.release_staff(cid)
			_show_tab("overview"))
		inner.add_child(btn_rel)

		## Sponsor search button
		var btn_search = Button.new()
		if GameState.cfo_search_active:
			btn_search.text = "⏹ Stop Sponsor Search"
			btn_search.modulate = Color(1.0, 0.6, 0.4)
			btn_search.pressed.connect(func():
				GameState.stop_cfo_sponsor_search()
				_show_tab("overview"))
		else:
			btn_search.text = "🔍 Search for Sponsors"
			btn_search.pressed.connect(func():
				GameState.start_cfo_sponsor_search()
				_show_tab("overview"))
		btn_search.add_theme_font_size_override("font_size", 11)
		inner.add_child(btn_search)
	else:
		var lbl_e = Label.new()
		lbl_e.text = "— No CFO hired —"
		lbl_e.modulate = Color(0.9, 0.5, 0.15)
		lbl_e.add_theme_font_size_override("font_size", 13)
		inner.add_child(lbl_e)
		var btn_h = Button.new()
		btn_h.text = "Hire CFO →"
		btn_h.add_theme_font_size_override("font_size", 11)
		btn_h.pressed.connect(func():
			GameState.pending_staff_filter = "CFO"
			get_tree().change_scene_to_file("res://scenes/Staff.tscn"))
		inner.add_child(btn_h)

	return panel


func _build_nav_buttons() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	for btn_data in [
		["🏆 Hall of Fame",   "res://scenes/HallOfFame.tscn"],
		["🏎 Drivers",        "res://scenes/Drivers.tscn"],
		["👤 Staff Hub",      "res://scenes/Staff.tscn"],
	]:
		var btn = Button.new()
		btn.text = btn_data[0]
		btn.custom_minimum_size = Vector2(0, 32)
		btn.add_theme_font_size_override("font_size", 12)
		var dest = btn_data[1]
		btn.pressed.connect(func(): get_tree().change_scene_to_file(dest))
		vbox.add_child(btn)
	return vbox


# ══════════════════════════════════════════════════════════════════════════════
# TAB 2 — SPONSORS
# ══════════════════════════════════════════════════════════════════════════════

func _build_sponsors_tab(parent: VBoxContainer) -> void:
	## ── Quick action bar: Loan button prominent at top ───────────────────────
	var action_bar = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 12)
	parent.add_child(action_bar)

	var loan_slots = GameState.active_loans.size()
	var max_slots  = GameState.get_max_loan_slots()
	var btn_loan = Button.new()
	btn_loan.text = "🏦  Take Loan  (%d/%d slots)" % [loan_slots, max_slots]
	btn_loan.custom_minimum_size = Vector2(200, 38)
	btn_loan.add_theme_font_size_override("font_size", 13)
	btn_loan.disabled = loan_slots >= max_slots
	btn_loan.modulate = Color(0.5, 0.8, 1.0)
	btn_loan.pressed.connect(func(): _show_take_loan_popup())
	action_bar.add_child(btn_loan)

	var lbl_rate = Label.new()
	lbl_rate.text = "Current rate: %.1f%%/yr  ·  Economy: %s (%.0f)" % [
		GameState.current_loan_rate, GameState.global_economy_state, GameState.economy_index]
	lbl_rate.add_theme_font_size_override("font_size", 11)
	lbl_rate.modulate = Color(0.55, 0.55, 0.55)
	lbl_rate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_bar.add_child(lbl_rate)

	parent.add_child(HSeparator.new())

	## ── Top row: Income / Expenses / Indicators ─────────────────────────────
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	parent.add_child(cols)

	cols.add_child(_build_fin_income())
	cols.add_child(_build_fin_expenses())
	cols.add_child(_build_fin_indicators())

	parent.add_child(HSeparator.new())

	## ── P32 Financial Graphs ────────────────────────────────────────────────
	var graphs_lbl = _section_label("FINANCIAL GRAPHS")
	parent.add_child(graphs_lbl)

	## Graph selector buttons
	var graph_btn_row = HBoxContainer.new()
	graph_btn_row.add_theme_constant_override("separation", 6)
	parent.add_child(graph_btn_row)

	var graph_labels = [
		["💰 Balance",      "balance"],
		["⛽ Fuel Price",   "fuel"],
		["🌍 Economy",      "economy"],
		["👥 Active Fans",  "fans"],
		["🛍 Merchandise",  "merch"],
		["⭐ Reputation",   "reputation"],
	]

	var graph_container = VBoxContainer.new()
	graph_container.custom_minimum_size = Vector2(0, 220)
	parent.add_child(graph_container)

	## Draw first chart by default
	_draw_graph(graph_container, "balance")

	for gdata in graph_labels:
		var btn = Button.new()
		btn.text = gdata[0]
		btn.custom_minimum_size = Vector2(110, 28)
		btn.add_theme_font_size_override("font_size", 11)
		var gkey = gdata[1]
		btn.pressed.connect(func():
			for c in graph_container.get_children(): c.queue_free()
			await get_tree().process_frame
			_draw_graph(graph_container, gkey))
		graph_btn_row.add_child(btn)

	parent.add_child(HSeparator.new())

	## ── Sponsors ─────────────────────────────────────────────────────────────
	## Slot bar
	var slot_row = HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 10)
	parent.add_child(slot_row)

	var sp_max_slots  = GameState.get_hq_sponsor_slots()
	var sp_used_slots = GameState.active_sponsors.size()
	var lbl_slots  = Label.new()
	lbl_slots.text = "Sponsor Slots:  %d / %d" % [sp_used_slots, sp_max_slots]
	lbl_slots.add_theme_font_size_override("font_size", 14)
	lbl_slots.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if sp_used_slots < sp_max_slots else Color(1.0, 0.55, 0.2))
	slot_row.add_child(lbl_slots)
	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 3)
	slot_row.add_child(bar)
	for i in range(sp_max_slots):
		var sq = ColorRect.new()
		sq.custom_minimum_size = Vector2(18, 18)
		sq.color = Color(0.3, 0.75, 0.3) if i < sp_used_slots else Color(0.25, 0.28, 0.35)
		bar.add_child(sq)

	parent.add_child(HSeparator.new())

	## Sponsors in two columns: active + offers/search
	var sp_cols = HBoxContainer.new()
	sp_cols.add_theme_constant_override("separation", 16)
	parent.add_child(sp_cols)

	## Left: active sponsors
	var sp_left = VBoxContainer.new()
	sp_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp_left.add_theme_constant_override("separation", 8)
	sp_cols.add_child(sp_left)

	sp_left.add_child(_section_label("ACTIVE SPONSORS  (%d)" % GameState.active_sponsors.size()))
	if GameState.active_sponsors.is_empty():
		var lbl = Label.new(); lbl.text = "No active sponsors."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 12)
		sp_left.add_child(lbl)
	else:
		for sp in GameState.active_sponsors:
			sp_left.add_child(_build_active_sponsor_card(sp))

	## Right: offers + CFO search
	var sp_right = VBoxContainer.new()
	sp_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp_right.add_theme_constant_override("separation", 8)
	sp_cols.add_child(sp_right)

	sp_right.add_child(_section_label("PENDING OFFERS  (%d)" % GameState.sponsor_offers.size()))
	if GameState.sponsor_offers.is_empty():
		var lbl = Label.new(); lbl.text = "No offers pending."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 12)
		sp_right.add_child(lbl)
	else:
		for offer in GameState.sponsor_offers:
			sp_right.add_child(_build_sponsor_offer_card(offer))

	sp_right.add_child(HSeparator.new())
	sp_right.add_child(_section_label("CFO SPONSOR SEARCH"))
	sp_right.add_child(_build_cfo_search_panel())

	parent.add_child(HSeparator.new())

	## CFO Proposals
	parent.add_child(_section_label("CFO PROPOSALS"))
	parent.add_child(_build_cfo_proposals_panel())

	parent.add_child(HSeparator.new())

	## ── P44 Loans ─────────────────────────────────────────────────────────────
	parent.add_child(_section_label("LOANS"))
	parent.add_child(_build_loans_panel())


func _build_fin_income() -> PanelContainer:
	var panel = _fin_panel(Color(0.3, 0.7, 0.3))
	var vbox = panel.get_child(0)
	var lbl = Label.new(); lbl.text = "WEEKLY INCOME"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	vbox.add_child(lbl); vbox.add_child(HSeparator.new())

	var sponsor_w = 0
	for sp in GameState.active_sponsors:
		if sp.get("type",1) == 1: sponsor_w += sp.get("weekly_payment",0)
	var supply_w = 0
	for sc in GameState.active_supply_contracts:
		if sc.active: supply_w += int(sc.parts_per_season / 52.0) * sc.cr_per_part
	var building_w = 0
	for bn in GameState.campus_buildings:
		var b = GameState.campus_buildings[bn]
		if b.get("level",0) > 0: building_w += b.get("weekly_income",0)
	var prize_est = _estimate_prize()
	var total = 0
	for item in [
		["Race Prizes (est.)", prize_est,  prize_est > 0],
		["Sponsors (Type 1)",  sponsor_w,  sponsor_w > 0],
		["Parts Sales",        supply_w,   supply_w > 0],
		["Building Income",    building_w, building_w > 0],
	]:
		vbox.add_child(_fin_income_row(item[0], item[1], item[2]))
		if item[2]: total += item[1]
	vbox.add_child(HSeparator.new())
	vbox.add_child(_fin_income_row("TOTAL (est.)", total, true))
	return panel


func _build_fin_expenses() -> PanelContainer:
	var panel = _fin_panel(Color(0.8, 0.3, 0.3))
	var vbox = panel.get_child(0)
	var lbl = Label.new(); lbl.text = "WEEKLY EXPENSES"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(lbl); vbox.add_child(HSeparator.new())

	var driver_sal = 0
	for d_id in GameState.player_team.drivers:
		var d = GameState.all_drivers.get(d_id)
		if d: driver_sal += int(d.weekly_salary)
	var staff_sal = 0
	for s_id in GameState.all_staff:
		var s = GameState.all_staff[s_id]
		if s.contract_team == GameState.player_team.id: staff_sal += int(s.weekly_salary)
	var maintenance = 0
	for bn in GameState.campus_buildings:
		var b = GameState.campus_buildings[bn]
		if b.get("level",0) > 0: maintenance += b.get("weekly_maintenance",0)
	var rnd_costs = 0
	for task in GameState.active_rnd_tasks:
		rnd_costs += int(task.get("cr",0) / max(1, task.get("weeks",1)))
	var loan_payments = 0
	for ln in GameState.active_loans:
		loan_payments += int(ln.get("weekly_payment", 0))
	var total = 0
	for item in [
		["Driver Salaries",     driver_sal],
		["Staff Salaries",      staff_sal],
		["Maintenance",         maintenance],
		["R&D Projects",        rnd_costs],
		["Fuel (est.)",         GameState.player_team_cars.size() * 200],
		["Loan Repayments",     loan_payments],
	]:
		vbox.add_child(_fin_expense_row(item[0], item[1]))
		total += item[1]
	vbox.add_child(HSeparator.new())
	vbox.add_child(_fin_expense_row("TOTAL (est.)", total))
	return panel


func _build_fin_indicators() -> PanelContainer:
	var panel = _fin_panel(Color(0.3, 0.55, 0.9))
	var vbox = panel.get_child(0)
	var lbl = Label.new(); lbl.text = "KEY INDICATORS"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	vbox.add_child(lbl); vbox.add_child(HSeparator.new())
	var runway = GameState.get_runway_weeks()
	for ind in [
		["Company Value",  "CR %s" % _fmt(int(GameState._calculate_company_value())), Color(0.8,0.8,0.8)],
		["Max Loan",       "CR %s" % _fmt(int(GameState._calculate_max_loan())),      Color(0.6,0.6,0.6)],
		["Reputation",     "%.0f / 100" % GameState.player_team.reputation,
			_fin_stat_col(GameState.player_team.reputation)],
		["Marketability",  "%.0f / 100" % GameState.get_team_marketability(),         Color(0.4,0.8,1.0)],
		["Active Fans",    _fmt_fans(GameState.get_team_active_fans()),                Color(0.7,0.85,0.6)],
		["CEO Wealth",     "CR %s" % _fmt(int(GameState.ceo_accumulated_salary)),     Color(1.0,0.84,0.0)],
		["Economy",        "%.0f / 100 (%s)" % [GameState.economy_index, GameState.global_economy_state],
			Color(0.4,0.9,0.4) if GameState.global_economy_state == "Boom"
			else Color(1.0,0.6,0.1) if GameState.global_economy_state == "Normal"
			else Color(1.0,0.3,0.3)],
		["Fuel Price",     "CR %s/unit" % _fmt(int(GameState.current_fuel_price)),    Color(0.7,0.7,0.7)],
		["Active Loans",   "%d / %d" % [GameState.active_loans.size(), GameState.get_max_loan_slots()],
			Color(1.0,0.4,0.4) if GameState.active_loans.size() >= GameState.get_max_loan_slots()
			else Color(0.6,0.9,0.6)],
		["Runway",         "%d weeks" % runway if runway < 52 else "Stable",
			Color(0.4,0.9,0.4) if runway >= 8 else Color(1.0,0.6,0.1) if runway >= 4 else Color(1.0,0.3,0.3)],
	]:
		var row = HBoxContainer.new()
		vbox.add_child(row)
		var kl = Label.new(); kl.text = ind[0]
		kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kl.add_theme_font_size_override("font_size", 11)
		kl.modulate = Color(0.6,0.6,0.6)
		row.add_child(kl)
		var vl = Label.new(); vl.text = ind[1]
		vl.add_theme_font_size_override("font_size", 11)
		vl.add_theme_color_override("font_color", ind[2])
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.custom_minimum_size = Vector2(110, 0)
		row.add_child(vl)
	return panel


func _build_cfo_proposals_panel() -> PanelContainer:
	var panel = _fin_panel(Color(1.0, 0.8, 0.2))
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var vbox = panel.get_child(0)
	var cfo = GameState.get_cfo()
	if not cfo:
		var e = Label.new()
		e.text = "No CFO hired — hire one to receive financial proposals."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 12)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(e)
		return panel
	var lbl_c = Label.new()
	lbl_c.text = "CFO: %s  ·  FinMgmt %.0f  ·  Negotiation %.0f" % [
		cfo.full_name(), cfo.budget_planning, cfo.sponsor_negotiation]
	lbl_c.add_theme_font_size_override("font_size", 12)
	lbl_c.modulate = Color(0.65, 0.65, 0.65)
	vbox.add_child(lbl_c)
	vbox.add_child(HSeparator.new())
	var proposals = _gen_cfo_proposals()
	if proposals.is_empty():
		var ok = Label.new()
		ok.text = "✅ All financial indicators healthy this week."
		ok.add_theme_font_size_override("font_size", 12)
		ok.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		vbox.add_child(ok)
	else:
		for prop in proposals:
			var lp = Label.new(); lp.text = prop.text
			lp.add_theme_font_size_override("font_size", 12)
			lp.add_theme_color_override("font_color", prop.color)
			lp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(lp)
	return panel


func _gen_cfo_proposals() -> Array:
	var out = []
	var runway = GameState.get_runway_weeks()
	if runway < 4:
		out.append({"text":"🚨 CRITICAL: Only %d weeks runway." % runway, "color":Color(1.0,0.3,0.3)})
	elif runway < 8:
		out.append({"text":"⚠ %d weeks runway. Secure income or cut costs." % runway, "color":Color(1.0,0.6,0.1)})
	if GameState.fuel_kg < 100:
		out.append({"text":"⛽ Fuel low (%.0f kg). Buy 2 weeks supply." % GameState.fuel_kg, "color":Color(1.0,0.6,0.1)})
	if GameState.spare_parts < 20:
		out.append({"text":"🔧 Spare parts low (%d units). Restock." % GameState.spare_parts, "color":Color(1.0,0.6,0.1)})
	if GameState.active_sponsors.is_empty() and not GameState.cfo_search_active:
		out.append({"text":"📋 No active sponsors. Start a search.", "color":Color(0.7,0.7,0.7)})
	return out


## ── P44 Loan Panel ───────────────────────────────────────────────────────────

func _build_loans_panel() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	## Summary row: tier info + rate + Take Loan button
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 12)
	vbox.add_child(hdr)

	var max_tier   = GameState.get_loan_tier()
	var cfo        = GameState.get_cfo()
	var eff_tier   = max_tier if cfo else 1
	var max_amount = GameState.get_max_loan_amount(eff_tier)
	var rate       = GameState.get_loan_rate()
	var slots_used = GameState.active_loans.size()
	var slots_max  = GameState.get_max_loan_slots()

	var lbl_info = Label.new()
	lbl_info.text = "Tier %d  ·  Max CR %s  ·  Rate %.1f%%/yr  ·  Slots %d/%d" % [
		eff_tier, _fmt(int(max_amount)), rate, slots_used, slots_max]
	lbl_info.add_theme_font_size_override("font_size", 12)
	lbl_info.modulate = Color(0.65, 0.65, 0.65)
	lbl_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(lbl_info)

	if cfo == null:
		var lbl_nocfo = Label.new()
		lbl_nocfo.text = "⚠ No CFO — capped at Tier 1, +1.5% rate"
		lbl_nocfo.add_theme_font_size_override("font_size", 11)
		lbl_nocfo.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		vbox.add_child(lbl_nocfo)

	var btn_take = Button.new()
	btn_take.text = "🏦  Take Loan"
	btn_take.custom_minimum_size = Vector2(120, 32)
	btn_take.disabled = (slots_used >= slots_max)
	btn_take.pressed.connect(func(): _show_take_loan_popup())
	hdr.add_child(btn_take)

	## Active loan cards
	if GameState.active_loans.is_empty():
		var lbl_empty = Label.new()
		lbl_empty.text = "No active loans."
		lbl_empty.add_theme_font_size_override("font_size", 12)
		lbl_empty.modulate = Color(0.45, 0.45, 0.45)
		vbox.add_child(lbl_empty)
	else:
		for loan in GameState.active_loans:
			vbox.add_child(_build_loan_card(loan))

	return vbox


func _build_loan_card(loan: Dictionary) -> PanelContainer:
	var panel = _card(Color(0.09, 0.11, 0.14))
	var style = panel.get_theme_stylebox("panel").duplicate()
	style.border_width_left = 3
	style.border_color = Color(0.4, 0.6, 1.0)
	panel.add_theme_stylebox_override("panel", style)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	panel.add_child(vb)

	## Top row: amount / rate / seasons
	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	vb.add_child(top)

	var lbl_amount = Label.new()
	lbl_amount.text = "Loan #%d  ·  CR %s" % [loan.get("id", 0), _fmt(int(loan.get("amount_original", 0)))]
	lbl_amount.add_theme_font_size_override("font_size", 13)
	lbl_amount.add_theme_color_override("font_color", Color(0.5, 0.78, 1.0))
	lbl_amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(lbl_amount)

	var lbl_rate = Label.new()
	lbl_rate.text = "%.1f%% p.a." % loan.get("annual_rate", 0.0)
	lbl_rate.add_theme_font_size_override("font_size", 11)
	lbl_rate.modulate = Color(0.6, 0.6, 0.6)
	top.add_child(lbl_rate)

	## Progress row: balance + weekly payment + weeks left
	var prog = HBoxContainer.new()
	prog.add_theme_constant_override("separation", 10)
	vb.add_child(prog)

	var weeks_rem  = loan.get("weeks_remaining", 0)
	var seasons_rem = int(weeks_rem / 52.0) if weeks_rem > 0 else 0
	var lbl_bal = Label.new()
	lbl_bal.text = "Balance: CR %s" % _fmt(int(loan.get("balance_remaining", 0)))
	lbl_bal.add_theme_font_size_override("font_size", 12)
	lbl_bal.modulate = Color(0.75, 0.75, 0.75)
	lbl_bal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog.add_child(lbl_bal)

	var lbl_pay = Label.new()
	lbl_pay.text = "−CR %s/wk" % _fmt(int(loan.get("weekly_payment", 0)))
	lbl_pay.add_theme_font_size_override("font_size", 12)
	lbl_pay.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	prog.add_child(lbl_pay)

	var lbl_left = Label.new()
	lbl_left.text = "%d wks (%d seasons)" % [weeks_rem, seasons_rem]
	lbl_left.add_theme_font_size_override("font_size", 11)
	lbl_left.modulate = Color(0.55, 0.55, 0.55)
	prog.add_child(lbl_left)

	## Early repay button
	var btn_row = HBoxContainer.new()
	vb.add_child(btn_row)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var balance_rem = loan.get("balance_remaining", 0.0)
	var penalty     = balance_rem * (loan.get("annual_rate", 5.0) / 100.0)
	var total_cost  = balance_rem + penalty
	var btn_repay = Button.new()
	btn_repay.text = "💳 Repay Early  (CR %s + CR %s penalty)" % [
		_fmt(int(balance_rem)), _fmt(int(penalty))]
	btn_repay.custom_minimum_size = Vector2(0, 28)
	btn_repay.add_theme_font_size_override("font_size", 11)
	btn_repay.modulate = Color(1.0, 0.85, 0.5)
	btn_repay.disabled = (GameState.player_team.balance < total_cost)
	var loan_id = loan.get("id", 0)
	btn_repay.pressed.connect(func():
		var err = GameState.repay_loan_early(loan_id)
		if err != "":
			OS.alert(err, "Cannot Repay")
		else:
			_show_tab("sponsors"))
	btn_row.add_child(btn_repay)

	return panel


## Shows the Take Loan popup with amount slider and duration picker.
func _show_take_loan_popup() -> void:
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(440, 0)
	popup.set_anchor(SIDE_LEFT, 0.5); popup.set_anchor(SIDE_RIGHT, 0.5)
	popup.set_anchor(SIDE_TOP, 0.25); popup.set_anchor(SIDE_BOTTOM, 0.25)
	popup.offset_left = -220; popup.offset_right = 220
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.10, 0.11, 0.15)
	pstyle.border_width_left = 2; pstyle.border_width_right = 2
	pstyle.border_width_top = 2; pstyle.border_width_bottom = 2
	pstyle.border_color = Color(0.4, 0.6, 1.0)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		pstyle.set("corner_radius_%s" % c, 6)
	pstyle.content_margin_left = 22; pstyle.content_margin_right = 22
	pstyle.content_margin_top = 18; pstyle.content_margin_bottom = 18
	popup.add_theme_stylebox_override("panel", pstyle)
	add_child(popup)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	popup.add_child(vb)

	var lbl_title = Label.new()
	lbl_title.text = "🏦  Take a Loan"
	lbl_title.add_theme_font_size_override("font_size", 17)
	lbl_title.add_theme_color_override("font_color", Color(0.5, 0.78, 1.0))
	vb.add_child(lbl_title)

	vb.add_child(HSeparator.new())

	## Rate / tier info
	var cfo        = GameState.get_cfo()
	var eff_tier   = GameState.get_loan_tier() if cfo else 1
	var max_amount = GameState.get_max_loan_amount(eff_tier)
	var base_rate  = GameState.get_loan_rate()

	var lbl_info = Label.new()
	lbl_info.text = "Tier %d  ·  Rate %.1f%%/yr  ·  Max CR %s" % [
		eff_tier, base_rate, _fmt(int(max_amount))]
	lbl_info.add_theme_font_size_override("font_size", 12)
	lbl_info.modulate = Color(0.65, 0.65, 0.65)
	vb.add_child(lbl_info)

	## Amount slider
	var amount_row = VBoxContainer.new()
	amount_row.add_theme_constant_override("separation", 4)
	vb.add_child(amount_row)

	var lbl_amount_hdr = Label.new()
	lbl_amount_hdr.text = "Loan Amount"
	lbl_amount_hdr.add_theme_font_size_override("font_size", 12)
	amount_row.add_child(lbl_amount_hdr)

	var slider_row = HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 8)
	amount_row.add_child(slider_row)

	var slider = HSlider.new()
	slider.min_value = 1000.0
	slider.max_value = max(1000.0, max_amount)
	slider.step = 500.0
	slider.value = min(10000.0, max_amount)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_row.add_child(slider)

	var lbl_amount_val = Label.new()
	lbl_amount_val.text = "CR %s" % _fmt(int(slider.value))
	lbl_amount_val.add_theme_font_size_override("font_size", 13)
	lbl_amount_val.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	lbl_amount_val.custom_minimum_size = Vector2(90, 0)
	lbl_amount_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider_row.add_child(lbl_amount_val)

	## Duration picker
	const TIER_MAX_SEASONS = {1:8, 2:12, 3:16, 4:20, 5:25}
	var max_seasons = TIER_MAX_SEASONS.get(eff_tier, 8)

	var dur_row = VBoxContainer.new()
	dur_row.add_theme_constant_override("separation", 4)
	vb.add_child(dur_row)

	var lbl_dur_hdr = Label.new()
	lbl_dur_hdr.text = "Duration (seasons)"
	lbl_dur_hdr.add_theme_font_size_override("font_size", 12)
	dur_row.add_child(lbl_dur_hdr)

	var dur_btns = HBoxContainer.new()
	dur_btns.add_theme_constant_override("separation", 6)
	dur_row.add_child(dur_btns)

	var selected_seasons_ref = [4]  ## ref array so closures can mutate
	var dur_btn_list: Array = []
	for s in [4, 6, 8, 10, 12, 16, 20, 25]:
		if s > max_seasons: continue
		var dbtn = Button.new()
		dbtn.text = "%d" % s
		dbtn.custom_minimum_size = Vector2(36, 28)
		dbtn.add_theme_font_size_override("font_size", 11)
		dur_btns.add_child(dbtn)
		dur_btn_list.append({"btn": dbtn, "seasons": s})

	## Live summary label
	var lbl_summary = Label.new()
	lbl_summary.add_theme_font_size_override("font_size", 13)
	lbl_summary.add_theme_color_override("font_color", Color(0.85, 0.85, 0.6))
	vb.add_child(lbl_summary)

	## Helper: recalculate and refresh summary
	var _refresh = func():
		var amount  = slider.value
		var seasons = selected_seasons_ref[0]
		var n_weeks = seasons * 52
		var weekly_r = (base_rate / 100.0) / 52.0
		var weekly_pay: float
		if weekly_r < 0.00001:
			weekly_pay = amount / float(n_weeks)
		else:
			var fac = weekly_r * pow(1.0 + weekly_r, float(n_weeks))
			var den = pow(1.0 + weekly_r, float(n_weeks)) - 1.0
			weekly_pay = amount * (fac / den)
		var total_paid = weekly_pay * n_weeks
		lbl_summary.text = "CR %s/wk  ·  %d weeks  ·  Total paid: CR %s" % [
			_fmt(int(weekly_pay)), n_weeks, _fmt(int(total_paid))]
		lbl_amount_val.text = "CR %s" % _fmt(int(amount))
		## Highlight selected duration
		for entry in dur_btn_list:
			entry["btn"].modulate = Color(0.4, 0.9, 0.5) if entry["seasons"] == seasons else Color.WHITE

	## Wire up duration buttons
	for entry in dur_btn_list:
		var s = entry["seasons"]
		entry["btn"].pressed.connect(func():
			selected_seasons_ref[0] = s
			_refresh.call())
	_refresh.call()  ## initial render

	slider.value_changed.connect(func(_v): _refresh.call())

	## Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vb.add_child(btn_row)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var btn_confirm = Button.new()
	btn_confirm.text = "✅ Take Loan"
	btn_confirm.custom_minimum_size = Vector2(120, 34)
	btn_confirm.add_theme_font_size_override("font_size", 13)
	btn_confirm.modulate = Color(0.4, 0.9, 0.5)
	btn_confirm.pressed.connect(func():
		var err = GameState.take_loan(slider.value, selected_seasons_ref[0])
		if err != "":
			OS.alert(err, "Cannot Take Loan")
			return
		dim.queue_free(); popup.queue_free()
		_show_tab("sponsors"))
	btn_row.add_child(btn_confirm)

	var btn_cancel = Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.custom_minimum_size = Vector2(80, 34)
	btn_cancel.pressed.connect(func(): dim.queue_free(); popup.queue_free())
	btn_row.add_child(btn_cancel)


## ── Financial tab helper widgets ─────────────────────────────────────────────

func _fin_panel(border_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.13)
	style.border_width_left = 3; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 8; style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 5)
	panel.add_child(inner)
	return panel


func _fin_income_row(label: String, amount: int, active: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	var lbl = Label.new(); lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	if not active: lbl.modulate = Color(0.35, 0.35, 0.35)
	row.add_child(lbl)
	var val = Label.new()
	val.text = "+CR %s" % _fmt(amount) if amount > 0 else "—"
	val.add_theme_font_size_override("font_size", 12)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.custom_minimum_size = Vector2(100, 0)
	val.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if amount > 0 else Color(0.35, 0.35, 0.35))
	row.add_child(val)
	return row


func _fin_expense_row(label: String, amount: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	var lbl = Label.new(); lbl.text = label
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	if amount == 0: lbl.modulate = Color(0.35, 0.35, 0.35)
	row.add_child(lbl)
	var val = Label.new()
	val.text = "-CR %s" % _fmt(amount) if amount > 0 else "—"
	val.add_theme_font_size_override("font_size", 12)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.custom_minimum_size = Vector2(100, 0)
	val.add_theme_color_override("font_color",
		Color(1.0, 0.4, 0.4) if amount > 0 else Color(0.35, 0.35, 0.35))
	row.add_child(val)
	return row


func _estimate_prize() -> int:
	if GameState.last_race_results.is_empty(): return 0
	for entry in GameState.last_race_results:
		if entry.get("is_player", false) or \
		   (entry.get("driver") and entry["driver"].id in GameState.player_team.drivers):
			return int(entry.get("prize", 0))
	return 0


func _fin_stat_col(v: float) -> Color:
	if v >= 70: return Color(0.4, 0.9, 0.4)
	if v >= 40: return Color(1.0, 0.8, 0.2)
	return Color(1.0, 0.4, 0.4)


func _build_active_sponsor_card(sp: Dictionary) -> PanelContainer:
	var panel = _card(Color(0.09, 0.13, 0.10))
	var inner = HBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(info)

	var lbl_name = Label.new()
	lbl_name.text = sp.get("name", "Unknown Sponsor")
	lbl_name.add_theme_font_size_override("font_size", 13)
	lbl_name.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	info.add_child(lbl_name)

	var detail = ""
	match sp.get("type", 1):
		1: detail = "+CR %s/wk" % _fmt(sp.get("weekly_payment", 0))
		2: detail = "Win: +CR %s  Podium: +CR %s" % [
			_fmt(sp.get("win_bonus", 0)), _fmt(sp.get("podium_bonus", 0))]
		3: detail = "Commitment deal"
	var lbl_detail = Label.new()
	lbl_detail.text = detail + "  ·  %d season%s remaining" % [
		sp.get("seasons_remaining", 0), "s" if sp.get("seasons_remaining", 0) != 1 else ""]
	lbl_detail.add_theme_font_size_override("font_size", 11)
	lbl_detail.modulate = Color(0.6, 0.6, 0.6)
	info.add_child(lbl_detail)

	## Expiry warning
	if sp.get("seasons_remaining", 99) <= 1:
		var lbl_exp = Label.new()
		lbl_exp.text = "⚠ Expires this season"
		lbl_exp.add_theme_font_size_override("font_size", 11)
		lbl_exp.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		info.add_child(lbl_exp)

	## Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	panel.add_child(btn_row)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	## Renegotiate — opens instant sponsor negotiation (CFO flow)
	var btn_reneg = Button.new()
	btn_reneg.text = "📋 Renegotiate"
	btn_reneg.custom_minimum_size = Vector2(110, 26)
	btn_reneg.add_theme_font_size_override("font_size", 11)
	var sp_id = sp.get("sponsor_id", "")
	btn_reneg.pressed.connect(func():
		var neg = GameState.generate_sponsor_negotiation(sp_id)
		if neg.is_empty(): return
		GameState.start_negotiation(neg)
		var panel_neg = preload("res://scenes/ContractNegotiation.tscn").instantiate()
		get_tree().current_scene.add_child(panel_neg)
		panel_neg.open(GameState.active_negotiation)
		panel_neg.closed.connect(func(): _show_tab("sponsors")))
	btn_row.add_child(btn_reneg)

	## Cancel — with penalty warning
	var btn_cancel = Button.new()
	btn_cancel.text = "✕ Cancel Deal"
	btn_cancel.custom_minimum_size = Vector2(100, 26)
	btn_cancel.add_theme_font_size_override("font_size", 11)
	btn_cancel.modulate = Color(1.0, 0.45, 0.45)
	var seasons_left = sp.get("seasons_remaining", 1)
	btn_cancel.tooltip_text = "Penalty: −%d rep, −%d marketability" % [
		clamp(5 * seasons_left, 5, 20), clamp(8 * seasons_left, 8, 30)]
	btn_cancel.pressed.connect(func():
		_show_cancel_sponsor_confirm(sp_id, sp.get("name","?")))
	btn_row.add_child(btn_cancel)

	return panel


func _show_cancel_sponsor_confirm(sponsor_id: String, sponsor_name: String) -> void:
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(380, 0)
	popup.set_anchor(SIDE_LEFT, 0.5); popup.set_anchor(SIDE_RIGHT, 0.5)
	popup.set_anchor(SIDE_TOP, 0.35); popup.set_anchor(SIDE_BOTTOM, 0.35)
	popup.offset_left = -190; popup.offset_right = 190
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.10, 0.10)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.3, 0.3)
	for c in ["top_left","top_right","bottom_left","bottom_right"]:
		style.set("corner_radius_%s" % c, 6)
	style.content_margin_left = 20; style.content_margin_right = 20
	style.content_margin_top = 16; style.content_margin_bottom = 16
	popup.add_theme_stylebox_override("panel", style)
	add_child(popup)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	popup.add_child(vb)

	var lbl_t = Label.new()
	lbl_t.text = "Cancel Sponsor Deal?"
	lbl_t.add_theme_font_size_override("font_size", 16)
	lbl_t.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	vb.add_child(lbl_t)

	var lbl_b = Label.new()
	lbl_b.text = "Cancelling %s will apply a reputation and marketability penalty." % sponsor_name
	lbl_b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_b.add_theme_font_size_override("font_size", 12)
	lbl_b.modulate = Color(0.75, 0.75, 0.75)
	vb.add_child(lbl_b)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vb.add_child(btn_row)

	var btn_confirm = Button.new()
	btn_confirm.text = "✕ Cancel Deal"
	btn_confirm.custom_minimum_size = Vector2(130, 34)
	btn_confirm.modulate = Color(1.0, 0.4, 0.4)
	btn_confirm.pressed.connect(func():
		GameState.cancel_sponsor(sponsor_id)
		dim.queue_free(); popup.queue_free()
		_show_tab("sponsors"))
	btn_row.add_child(btn_confirm)

	var btn_keep = Button.new()
	btn_keep.text = "Keep Deal"
	btn_keep.custom_minimum_size = Vector2(100, 34)
	btn_keep.pressed.connect(func(): dim.queue_free(); popup.queue_free())
	btn_row.add_child(btn_keep)


func _build_sponsor_offer_card(offer: Dictionary) -> PanelContainer:
	var panel = _card(Color(0.09, 0.10, 0.14))
	var style = panel.get_theme_stylebox("panel").duplicate()
	style.border_width_left = 3
	const TIER_COLORS = [Color(0.3,0.3,0.3), Color(0.3,0.7,0.9), Color(0.9,0.6,0.2), Color(0.6,0.3,0.9)]
	style.border_color = TIER_COLORS[min(offer.get("type",1), TIER_COLORS.size()-1)]
	panel.add_theme_stylebox_override("panel", style)

	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	panel.add_child(inner)

	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	inner.add_child(hdr)

	var lbl_name = Label.new()
	lbl_name.text = offer.get("name", "?")
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.add_theme_font_size_override("font_size", 13)
	hdr.add_child(lbl_name)

	var lbl_t = Label.new()
	lbl_t.text = "Type %d" % offer.get("type", 1)
	lbl_t.add_theme_font_size_override("font_size", 10)
	lbl_t.modulate = Color(0.5, 0.5, 0.5)
	hdr.add_child(lbl_t)

	var lbl_detail = Label.new()
	lbl_detail.add_theme_font_size_override("font_size", 11)
	lbl_detail.modulate = Color(0.65, 0.65, 0.65)
	match offer.get("type", 1):
		1: lbl_detail.text = "CR %s/wk  ·  %d seasons" % [
			_fmt(offer.get("weekly_payment",0)), offer.get("seasons_remaining",1)]
		2: lbl_detail.text = "Win: CR %s  Podium: CR %s  ·  %d seasons" % [
			_fmt(offer.get("win_bonus",0)), _fmt(offer.get("podium_bonus",0)),
			offer.get("seasons_remaining",1)]
		3:
			var reg = GameState.CHAMPIONSHIP_REGISTRY.get(offer.get("championship_id",""),{})
			lbl_detail.text = "[%s]  CR %s total  ·  %d seasons" % [
				reg.get("name", offer.get("championship_id","")),
				_fmt(offer.get("commitment_total",0)), offer.get("seasons_remaining",1)]
	inner.add_child(lbl_detail)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	inner.add_child(btn_row)

	var max_slots = GameState.get_hq_sponsor_slots()
	var used_slots = GameState.active_sponsors.size()

	if used_slots >= max_slots:
		# No slots available
		var lbl_full = Label.new()
		lbl_full.text = "🔒 No slots available"
		lbl_full.add_theme_font_size_override("font_size", 12)
		lbl_full.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		lbl_full.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_row.add_child(lbl_full)

		var lbl_hint = Label.new()
		lbl_hint.text = "(Upgrade HQ)"
		lbl_hint.add_theme_font_size_override("font_size", 11)
		lbl_hint.modulate = Color(0.6, 0.6, 0.6)
		btn_row.add_child(lbl_hint)
	else:
## Normal Negotiate button
		var btn_neg = Button.new()
		btn_neg.text = "📋 Negotiate"
		btn_neg.custom_minimum_size = Vector2(110, 26)
		btn_neg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_neg.pressed.connect(func():
			var neg = GameState.generate_sponsor_negotiation(offer.sponsor_id)
			if neg.is_empty():
				GameState.sign_sponsor(offer.sponsor_id)
				_show_tab("sponsors")
				return
			GameState.start_negotiation(neg)
			var np = preload("res://scenes/ContractNegotiation.tscn").instantiate()
			get_tree().current_scene.add_child(np)
			np.open(GameState.active_negotiation)
			np.closed.connect(func(): _show_tab("sponsors"))
			)
		btn_row.add_child(btn_neg)

	var btn_dis = Button.new()
	btn_dis.text = "✕ Dismiss"
	btn_dis.custom_minimum_size = Vector2(80, 26)
	btn_dis.modulate = Color(0.6, 0.6, 0.6)
	btn_dis.pressed.connect(func():
		GameState.dismiss_sponsor_offer(offer.sponsor_id)
		_show_tab("sponsors"))
	btn_row.add_child(btn_dis)

	return panel


func _build_cfo_search_panel() -> PanelContainer:
	var panel = _card(Color(0.10, 0.11, 0.15))
	var inner = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 8)
	panel.add_child(inner)

	var has_cfo = GameState.get_cfo() != null
	if GameState.cfo_search_active:
		var lbl = Label.new()
		lbl.text = "🔍 CFO is searching...  Next offer in %d week%s." % [
			GameState.cfo_search_weeks_remaining,
			"s" if GameState.cfo_search_weeks_remaining != 1 else ""]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		inner.add_child(lbl)
		var btn_stop = Button.new()
		btn_stop.text = "⏹  Stop Search"
		btn_stop.modulate = Color(1.0, 0.5, 0.5)
		btn_stop.custom_minimum_size = Vector2(0, 32)
		btn_stop.pressed.connect(func():
			GameState.stop_cfo_sponsor_search()
			_show_tab("sponsors"))
		inner.add_child(btn_stop)
	elif has_cfo:
		var cfo = GameState.get_cfo()
		var lbl = Label.new()
		lbl.text = "CFO available (%s — Negotiation %.0f)" % [
			cfo.full_name(), cfo.sponsor_negotiation]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.modulate = Color(0.65, 0.65, 0.65)
		inner.add_child(lbl)
		var btn_start = Button.new()
		btn_start.text = "🔍  Start Sponsor Search"
		btn_start.custom_minimum_size = Vector2(0, 34)
		btn_start.add_theme_font_size_override("font_size", 13)
		btn_start.pressed.connect(func():
			GameState.start_cfo_sponsor_search()
			_show_tab("sponsors"))
		inner.add_child(btn_start)
	else:
		var lbl = Label.new()
		lbl.text = "No CFO hired. A CFO can search for sponsors on your behalf."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(lbl)
		var btn_hire = Button.new()
		btn_hire.text = "Hire CFO →"
		btn_hire.pressed.connect(func():
			GameState.pending_staff_filter = "CFO"
			get_tree().change_scene_to_file("res://scenes/Staff.tscn"))
		inner.add_child(btn_hire)

	return panel


# ══════════════════════════════════════════════════════════════════════════════
# TAB 3 — WRA & REGISTRATION
# ══════════════════════════════════════════════════════════════════════════════

func _build_wra_tab(parent: VBoxContainer) -> void:
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	parent.add_child(cols)

	## Left: cycles + submit
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 12)
	cols.add_child(left)

	left.add_child(_section_label("REGULATION CYCLE STATUS"))
	left.add_child(_build_wra_cycles())

	left.add_child(HSeparator.new())
	left.add_child(_section_label("BLUEPRINTS READY TO SUBMIT"))
	left.add_child(_build_wra_submit())

	## Right: pending + approved + supply + registration
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	cols.add_child(right)

	right.add_child(_section_label("PENDING APPROVAL  (%d)" % GameState.active_wra_submissions.size()))
	right.add_child(_build_wra_pending())

	right.add_child(HSeparator.new())
	right.add_child(_section_label("APPROVED — READY TO MANUFACTURE  (%d)" % GameState.wra_approved_blueprints.size()))
	right.add_child(_build_wra_approved())

	right.add_child(HSeparator.new())
	right.add_child(_section_label("SUPPLY CONTRACTS  (%d)" % GameState.active_supply_contracts.size()))
	right.add_child(_build_supply_contracts())

	right.add_child(HSeparator.new())
	right.add_child(_section_label("CHAMPIONSHIP REGISTRATION"))
	right.add_child(_build_registration_panel())


func _build_wra_cycles() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	const GROUPS = {
		"Formula":4,"Touring":5,"Karting":6,
		"Open Wheel":7,"Stock Car":8,"Rally":9,"Endurance":10
	}
	for group in GROUPS:
		var length = GROUPS[group]
		var start = GameState.wra_cycle_starts.get(group, 1)
		var seasons_in = GameState.current_season - start
		var seasons_until = length - (seasons_in % length)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var lbl_g = Label.new()
		lbl_g.text = group
		lbl_g.custom_minimum_size = Vector2(100, 0)
		lbl_g.add_theme_font_size_override("font_size", 12)
		row.add_child(lbl_g)

		var lbl_s = Label.new()
		lbl_s.add_theme_font_size_override("font_size", 12)
		if seasons_until == 1:
			lbl_s.text = "⚠ Resets NEXT SEASON"
			lbl_s.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
		elif seasons_until == 2:
			lbl_s.text = "⚠ Resets in 2 seasons"
			lbl_s.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2))
		else:
			lbl_s.text = "Resets in %d seasons" % seasons_until
			lbl_s.modulate = Color(0.45, 0.45, 0.45)
		row.add_child(lbl_s)

	return vbox


func _build_wra_submit() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	var submittable = []
	for bp_id in GameState.known_blueprints:
		if not GameState.is_blueprint_submitted(bp_id) and not GameState.is_blueprint_approved(bp_id):
			submittable.append(bp_id)

	if submittable.is_empty():
		var e = Label.new(); e.text = "No blueprints awaiting submission."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 12)
		vbox.add_child(e)
		return vbox

	for bp_id in submittable:
		var bp = GameState.known_blueprints[bp_id]
		var cid = bp.get("championship_id", "")
		var tier = GameState._get_championship_tier(cid)
		var wks  = GameState.WRA_APPROVAL_WEEKS.get(tier, 2)
		var reg  = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)

		var ln = Label.new()
		ln.text = "%s  [%s]" % [bp.get("name", bp_id), reg.get("name", cid)]
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ln.add_theme_font_size_override("font_size", 11)
		row.add_child(ln)

		var li = Label.new()
		li.text = "%d wks" % wks
		li.add_theme_font_size_override("font_size", 10)
		li.modulate = Color(0.5, 0.5, 0.5)
		row.add_child(li)

		var btn = Button.new()
		btn.text = "Submit"
		btn.custom_minimum_size = Vector2(70, 26)
		btn.pressed.connect(func():
			if GameState.submit_to_wra(bp_id): _show_tab("wra"))
		row.add_child(btn)

	return vbox


func _build_wra_pending() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	if GameState.active_wra_submissions.is_empty():
		var e = Label.new(); e.text = "No pending submissions."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 12)
		vbox.add_child(e)
		return vbox
	for sub in GameState.active_wra_submissions:
		var bp  = GameState.known_blueprints.get(sub.blueprint_id, {})
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(sub.championship_id, {})
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)
		var ln = Label.new()
		ln.text = "%s  [%s]" % [bp.get("name", sub.blueprint_id), reg.get("name", sub.championship_id)]
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ln.add_theme_font_size_override("font_size", 11)
		row.add_child(ln)
		var lw = Label.new()
		lw.text = "⏳ %d wk%s" % [sub.weeks_remaining, "s" if sub.weeks_remaining != 1 else ""]
		lw.add_theme_font_size_override("font_size", 11)
		lw.add_theme_color_override("font_color",
			Color(1.0, 0.6, 0.1) if sub.weeks_remaining <= 1 else Color(0.5, 0.5, 0.5))
		row.add_child(lw)
	return vbox


func _build_wra_approved() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	if GameState.wra_approved_blueprints.is_empty():
		var e = Label.new(); e.text = "No approved blueprints yet."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 12)
		vbox.add_child(e)
		return vbox
	for app in GameState.wra_approved_blueprints:
		var bp  = GameState.known_blueprints.get(app.blueprint_id, {})
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(app.championship_id, {})
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)
		var lc = Label.new(); lc.text = "✅"
		lc.custom_minimum_size = Vector2(20, 0)
		row.add_child(lc)
		var ln = Label.new()
		ln.text = "%s  [%s]" % [bp.get("name", app.blueprint_id), reg.get("name", app.championship_id)]
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ln.add_theme_font_size_override("font_size", 11)
		ln.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		row.add_child(ln)
		var btn = Button.new()
		btn.text = "Manufacture →"
		btn.custom_minimum_size = Vector2(105, 24)
		btn.pressed.connect(func():
			GameState.pending_cnc_blueprint = app.blueprint_id
			get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn"))
		row.add_child(btn)
	return vbox


func _build_supply_contracts() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	var active = GameState.active_supply_contracts.filter(func(sc): return sc.active)
	if active.is_empty():
		var e = Label.new(); e.text = "No active supply contracts."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 12)
		vbox.add_child(e)
		return vbox
	for sc in active:
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(sc.championship_id, {})
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		vbox.add_child(row)
		var ln = Label.new()
		ln.text = "%s — %s [%s]  CR %s/pt  %d seasons" % [
			sc.ai_team_name, sc.part_code,
			reg.get("name", sc.championship_id),
			_fmt(sc.cr_per_part), sc.seasons_remaining]
		ln.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ln.add_theme_font_size_override("font_size", 11)
		row.add_child(ln)
		var pct = float(sc.parts_delivered) / float(max(sc.parts_per_season, 1))
		var prog = Label.new()
		prog.text = "%d/%d" % [sc.parts_delivered, sc.parts_per_season]
		prog.add_theme_font_size_override("font_size", 11)
		prog.add_theme_color_override("font_color",
			Color(0.4,0.9,0.4) if pct >= 0.8 else
			Color(1.0,0.6,0.1) if pct >= 0.4 else Color(1.0,0.3,0.3))
		row.add_child(prog)
	return vbox


func _build_registration_panel() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var reg_count = GameState.player_registered_championships.size()
	var lbl_info = Label.new()
	lbl_info.text = "Registered for Season %d:  %d championship%s" % [
		GameState.current_season + 1, reg_count, "s" if reg_count != 1 else ""]
	lbl_info.add_theme_font_size_override("font_size", 13)
	lbl_info.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if reg_count > 0 else Color(1.0, 0.6, 0.2))
	vbox.add_child(lbl_info)

	## Per-championship requirements checklist
	for cid in GameState.player_registered_championships:
		var reg = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {})
		var disc = reg.get("discipline","")

		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cstyle = StyleBoxFlat.new()
		cstyle.bg_color = Color(0.09, 0.11, 0.13)
		cstyle.border_width_left = 3
		cstyle.content_margin_left = 10; cstyle.content_margin_right = 10
		cstyle.content_margin_top = 8;  cstyle.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", cstyle)
		vbox.add_child(card)

		var cvb = VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 4)
		card.add_child(cvb)

		## Header
		var lbl_name = Label.new()
		lbl_name.text = "✅ %s" % reg.get("name", cid)
		lbl_name.add_theme_font_size_override("font_size", 12)
		lbl_name.add_theme_color_override("font_color", Color(0.4, 0.85, 0.4))
		cvb.add_child(lbl_name)

		## Build requirements list
		var reqs: Array = []

		## Car requirement
		var has_car = false
		for car in GameState.player_team_cars:
			if car.championship_id == cid: has_car = true; break
		reqs.append({"ok": has_car, "text": "Car registered to this championship"})

		## Driver per car
		var cars_for_champ = GameState.player_team_cars.filter(
			func(c): return c.championship_id == cid)
		for car in cars_for_champ:
			var car_label = car.car_name if car.car_name != "" else "Car %d" % car.car_number
			reqs.append({"ok": car.driver_id != "",
				"text": "Driver assigned to %s" % car_label})
			reqs.append({"ok": car.mechanic_id != "",
				"text": "Mechanic assigned to %s" % car_label})
			if GameState.get_pit_crew_required(cid):
				reqs.append({"ok": car.pit_crew_id not in ["","N/A"],
					"text": "Pit crew assigned to %s" % car_label})

		## TP requirement
		var tp_ok = false
		if disc == "GK":
			if GameState._get_tp_for_championship("C-001") != null:
				tp_ok = true
		else:
			tp_ok = GameState._get_tp_for_championship(cid) != null
		reqs.append({"ok": tp_ok, "text": "Team Principal assigned"})

		## Strategist (not GK or Rally)
		if disc not in ["GK","Rally"]:
			var strat_ok = GameState._get_strategist_for_championship(cid) != null
			reqs.append({"ok": strat_ok, "text": "Race Strategist assigned"})

		## Driver age eligibility
		var min_age = reg.get("min_age", 0)
		var max_age = reg.get("max_age", 99)
		if min_age > 0 or max_age < 99:
			reqs.append({"ok": true,  ## informational
				"text": "Driver age: %d–%d" % [min_age, max_age]})

		## Render requirements
		var all_ok = true
		for req in reqs:
			if not req["ok"]: all_ok = false
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			cvb.add_child(row)
			var icon = Label.new()
			icon.text = "✅" if req["ok"] else "⚠"
			icon.add_theme_font_size_override("font_size", 11)
			row.add_child(icon)
			var lbl_req = Label.new()
			lbl_req.text = req["text"]
			lbl_req.add_theme_font_size_override("font_size", 11)
			lbl_req.add_theme_color_override("font_color",
				Color(0.6, 0.9, 0.6) if req["ok"] else Color(1.0, 0.55, 0.2))
			row.add_child(lbl_req)

		## Border color: green if all met, orange if not
		cstyle.border_color = Color(0.3, 0.75, 0.35) if all_ok else Color(1.0, 0.55, 0.2)

		## Add TDL item if requirements not met
		if not all_ok:
			var msg = "⚠ %s: unmet race requirements before Season %d." % [
				reg.get("name", cid), GameState.current_season + 1]
			GameState.add_todo_item(msg)

	var btn = Button.new()
	btn.text = "🏁  Championship Registration →"
	btn.custom_minimum_size = Vector2(0, 38)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ChampionshipSelect.tscn"))
	vbox.add_child(btn)

	return vbox


## Returns null if nothing pending, otherwise a VBoxContainer with all pending items.
func _build_pending_activity() -> VBoxContainer:
	var items = GameState.get_active_approaches_for_display()
	if items.is_empty(): return null

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	for ap in items:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var icon_lbl = Label.new()
		icon_lbl.add_theme_font_size_override("font_size", 12)
		var desc_lbl = Label.new()
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var status = ap.get("status", "")
		match status:
			"approaching":
				icon_lbl.text = "📤"
				desc_lbl.text = "Bond approach → %s (%s) · reply next week" % [
					ap["subject_name"], ap.get("current_team_name","")]
				desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.4))
			"bond_incoming":
				icon_lbl.text = "📥"
				desc_lbl.text = "%s wants %s · CR %s · decide" % [
					ap.get("approaching_team_name","AI Team"),
					ap["subject_name"], _fmt(int(ap.get("bond_team_ask",0)))]
				desc_lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
			"negotiating":
				icon_lbl.text = "📋"
				var locked = ap.get("locked_fields",[]).size()
				var is_player_turn = ap.get("player_turn", false)
				if is_player_turn:
					desc_lbl.text = "Your turn: %s · Round %d/%d · %d locked" % [
						ap["subject_name"], ap.get("contract_round",1),
						ap.get("max_contract_rounds",4), locked]
					desc_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 0.55))
				else:
					desc_lbl.text = "Waiting reply: %s · Round %d/%d" % [
						ap["subject_name"], ap.get("contract_round",1),
						ap.get("max_contract_rounds",4)]
					desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			"agreed":
				if ap.get("type") == "pre_signed":
					icon_lbl.text = "✅"
					desc_lbl.text = "Pre-signed: %s · joins Season %d" % [
						ap["subject_name"], GameState.current_season + 1]
					desc_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
				else:
					continue
			_:
				continue

		row.add_child(icon_lbl)
		row.add_child(desc_lbl)

		## Action button
		if status == "negotiating":
			var is_player_turn = ap.get("player_turn", false)
			if is_player_turn:
				var btn = Button.new()
				btn.text = "Open →"
				btn.custom_minimum_size = Vector2(70, 24)
				btn.add_theme_font_size_override("font_size", 10)
				btn.modulate = Color(0.4, 0.85, 0.55)
				var neg_id = ap["neg_id"]
				btn.pressed.connect(func():
					var panel = preload("res://scenes/ContractNegotiation.tscn").instantiate()
					get_tree().current_scene.add_child(panel)
					var current_ap = GameState._get_approach(neg_id)
					panel.open_approach(current_ap)
					panel.closed.connect(func(): _show_tab("overview")))
				row.add_child(btn)
			else:
				var lbl_wait = Label.new()
				lbl_wait.text = "⏳ Awaiting reply"
				lbl_wait.add_theme_font_size_override("font_size", 10)
				lbl_wait.modulate = Color(0.5, 0.5, 0.5)
				row.add_child(lbl_wait)
		elif status == "bond_incoming":
			var btn = Button.new()
			btn.text = "Respond →"
			btn.custom_minimum_size = Vector2(80, 24)
			btn.add_theme_font_size_override("font_size", 10)
			btn.modulate = Color(1.0, 0.75, 0.2)
			var dest = "res://scenes/Drivers.tscn" if ap.get("subject_type") == "driver" \
				else "res://scenes/Staff.tscn"
			btn.pressed.connect(func(): get_tree().change_scene_to_file(dest))
			row.add_child(btn)

		vbox.add_child(row)

	return vbox if vbox.get_child_count() > 0 else null


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _section_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.45, 0.55, 0.70))
	return lbl

func _kv_row(key: String, value: String, key_width: int, val_col: Color = Color.WHITE) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var k = Label.new(); k.text = key
	k.custom_minimum_size = Vector2(key_width, 0)
	k.add_theme_font_size_override("font_size", 12)
	k.modulate = Color(0.45, 0.45, 0.45)
	row.add_child(k)
	var v = Label.new(); v.text = value
	v.add_theme_font_size_override("font_size", 12)
	v.add_theme_color_override("font_color", val_col)
	row.add_child(v)
	return row

func _card(bg: Color = Color(0.11, 0.12, 0.16)) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.border_color = Color(0.22, 0.26, 0.34)
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.content_margin_left = 12; style.content_margin_right = 12
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _skill_col(v: float) -> Color:
	if v >= 75: return Color(0.3, 1.0, 0.3)
	elif v >= 50: return Color(1.0, 0.84, 0.0)
	elif v >= 30: return Color(1.0, 0.6, 0.2)
	return Color(0.75, 0.4, 0.4)

## ── P32 Graph Drawing ────────────────────────────────────────────────────────

func _draw_graph(container: VBoxContainer, key: String) -> void:
	## Get data and config for this chart type
	var history: Array
	var chart_title: String
	var line_color: Color
	var is_categorical := false  ## true for economy (0/1/2 states)

	match key:
		"balance":
			history = GameState.history_balance
			chart_title = "💰 Balance (CR)"
			line_color = Color(0.3, 0.85, 0.45)
		"fuel":
			history = GameState.history_fuel_price
			chart_title = "⛽ Fuel Price (CR/unit)"
			line_color = Color(1.0, 0.7, 0.2)
		"economy":
			history = GameState.history_economy
			chart_title = "🌍 Economy Index (0-100)"
			line_color = Color(0.4, 0.75, 1.0)
			is_categorical = false  ## now a continuous 0-100 index
		"fans":
			history = GameState.history_active_fans
			chart_title = "👥 Active Fans"
			line_color = Color(0.6, 0.9, 0.6)
		"merch":
			history = GameState.history_merchandise
			chart_title = "🛍 Merchandise Income (CR/wk)"
			line_color = Color(0.9, 0.5, 0.85)
		"reputation":
			history = GameState.history_reputation
			chart_title = "⭐ Reputation (0-100)"
			line_color = Color(0.95, 0.85, 0.3)
		_:
			history = []
			chart_title = "No Data"
			line_color = Color.WHITE

	## Title label — added after clear to prevent overlap
	var title_lbl = Label.new()
	title_lbl.text = chart_title
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", line_color)
	container.add_child(title_lbl)

	if history.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No data yet — advance weeks to populate."
		empty_lbl.add_theme_font_size_override("font_size", 11)
		empty_lbl.modulate = Color(0.5, 0.5, 0.5)
		container.add_child(empty_lbl)
		return

	## Build chart using a custom Control with _draw()
	var chart = _make_line_chart(history, line_color, is_categorical)
	chart.custom_minimum_size = Vector2(0, 180)
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(chart)

	## X-axis labels: first and last week label
	var x_row = HBoxContainer.new()
	container.add_child(x_row)
	var first = history[0]
	var last  = history[history.size() - 1]
	var lbl_first = Label.new()
	lbl_first.text = "S%d W%d" % [first["season"], first["week"]]
	lbl_first.add_theme_font_size_override("font_size", 10)
	lbl_first.modulate = Color(0.5, 0.5, 0.5)
	lbl_first.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl_last = Label.new()
	lbl_last.text = "S%d W%d" % [last["season"], last["week"]]
	lbl_last.add_theme_font_size_override("font_size", 10)
	lbl_last.modulate = Color(0.5, 0.5, 0.5)
	x_row.add_child(lbl_first)
	x_row.add_child(lbl_last)

## Build a line chart Control node from history data.
func _make_line_chart(history: Array, line_color: Color, is_categorical: bool) -> Control:
	var ctrl = Control.new()

	## Extract values
	var values: Array = []
	for entry in history:
		values.append(float(entry["value"]))

	var min_val = values.min() if values.size() > 0 else 0.0
	var max_val = values.max() if values.size() > 0 else 1.0
	if is_categorical:
		min_val = 0.0; max_val = 2.0
	if abs(max_val - min_val) < 0.001:
		min_val -= 1.0; max_val += 1.0

	## Store data on the node for _draw()
	ctrl.set_meta("values",     values)
	ctrl.set_meta("min_val",    min_val)
	ctrl.set_meta("max_val",    max_val)
	ctrl.set_meta("line_color", line_color)
	ctrl.set_meta("is_cat",     is_categorical)

	ctrl.draw.connect(func():
		var w = ctrl.size.x
		var h = ctrl.size.y
		if w < 2 or h < 2: return
		var pad_l = 8.0; var pad_r = 8.0; var pad_t = 8.0; var pad_b = 8.0
		var chart_w = w - pad_l - pad_r
		var chart_h = h - pad_t - pad_b
		var mn = ctrl.get_meta("min_val")
		var mx = ctrl.get_meta("max_val")
		var vals = ctrl.get_meta("values")
		var col  = ctrl.get_meta("line_color")
		var cat  = ctrl.get_meta("is_cat")
		var n = vals.size()
		if n < 1: return

		## Background
		ctrl.draw_rect(Rect2(pad_l, pad_t, chart_w, chart_h),
			Color(0.08, 0.09, 0.12), true)

		## Grid lines (3 horizontal)
		for gi in range(4):
			var gy = pad_t + chart_h * float(gi) / 3.0
			ctrl.draw_line(Vector2(pad_l, gy), Vector2(pad_l + chart_w, gy),
				Color(0.2, 0.2, 0.25), 1.0)

		## For categorical: colored band zones
		if cat:
			var zone_h = chart_h / 3.0
			ctrl.draw_rect(Rect2(pad_l, pad_t + zone_h * 2, chart_w, zone_h),
				Color(1.0, 0.3, 0.3, 0.15), true)  ## Recession zone
			ctrl.draw_rect(Rect2(pad_l, pad_t + zone_h, chart_w, zone_h),
				Color(0.9, 0.8, 0.3, 0.1), true)   ## Normal zone
			ctrl.draw_rect(Rect2(pad_l, pad_t, chart_w, zone_h),
				Color(0.3, 0.85, 0.45, 0.15), true) ## Boom zone

		## Data line
		var prev_pt = Vector2.ZERO
		for i in range(n):
			var t = float(i) / float(max(n - 1, 1))
			var v_norm = (vals[i] - mn) / (mx - mn)
			var px = pad_l + t * chart_w
			var py = pad_t + chart_h - v_norm * chart_h
			var pt = Vector2(px, py)
			if i > 0:
				ctrl.draw_line(prev_pt, pt, col, 1.5)
			prev_pt = pt

		## Last value dot
		if n > 0:
			ctrl.draw_circle(prev_pt, 3.5, col)

		## Y-axis min/max labels
		var font = ctrl.get_theme_default_font()
		if font:
			var lbl_color = Color(0.5, 0.5, 0.5)
			if cat:
				ctrl.draw_string(font, Vector2(pad_l + chart_w + 2, pad_t + 10),
					"Boom",      HORIZONTAL_ALIGNMENT_LEFT, -1, 9, lbl_color)
				ctrl.draw_string(font, Vector2(pad_l + chart_w + 2, pad_t + chart_h / 2 + 5),
					"Normal",    HORIZONTAL_ALIGNMENT_LEFT, -1, 9, lbl_color)
				ctrl.draw_string(font, Vector2(pad_l + chart_w + 2, pad_t + chart_h - 2),
					"Recession", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, lbl_color)
			else:
				var max_str = _fmt_graph_val(mx)
				var min_str = _fmt_graph_val(mn)
				ctrl.draw_string(font, Vector2(2, pad_t + 10),
					max_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, lbl_color)
				ctrl.draw_string(font, Vector2(2, pad_t + chart_h),
					min_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, lbl_color)
	)

	return ctrl

func _fmt_graph_val(v: float) -> String:
	var av = abs(v)
	if av >= 1_000_000_000: return "%.1fB" % (v / 1_000_000_000.0)
	if av >= 1_000_000:     return "%.1fM" % (v / 1_000_000.0)
	if av >= 1_000:         return "%.0fK" % (v / 1_000.0)
	return "%.0f" % v

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.2fM" % (n / 1000000.0)
	if n >= 1000:    return "%dK" % (n / 1000)
	return str(n)

func _fmt_fans(n: float) -> String:
	if n >= 1_000_000_000: return "%.2fB" % (n / 1_000_000_000.0)
	if n >= 1_000_000:     return "%.1fM" % (n / 1_000_000.0)
	if n >= 1_000:         return "%.1fK" % (n / 1_000.0)
	return "%d" % int(n)
