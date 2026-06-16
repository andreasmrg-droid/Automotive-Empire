## Automotive Empire — FinancialDept.gd
## Version: S16.4 — Added Sponsors tab. Three tabs: FINANCES | SPONSORS | CFO PROPOSALS
extends Control

var _current_tab: String = "finances"
var _tab_btns: Dictionary = {}
var _content: ScrollContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	GameState.log_updated.connect(func(): _show_tab(_current_tab))

func _build_ui() -> void:
	for c in get_children(): c.queue_free()
	await get_tree().process_frame

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 20)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)

	var lbl = Label.new()
	lbl.text = "💰  FINANCIAL DEPARTMENT"
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl)

	var bal = GameState.player_team.balance
	var lbl_bal = Label.new()
	lbl_bal.text = "Balance: CR %s" % _fmt(int(bal))
	lbl_bal.add_theme_font_size_override("font_size", 16)
	lbl_bal.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if bal >= 0 else Color(1.0, 0.3, 0.3))
	header.add_child(lbl_bal)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(90, 34)
	btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainHub.tscn"))
	header.add_child(btn_back)

	root.add_child(HSeparator.new())

	# Tab bar
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 4)
	root.add_child(tab_bar)

	_tab_btns = {}
	for tab in [["finances","📊  Finances"], ["sponsors","🤝  Sponsors"], ["proposals","💼  CFO Proposals"]]:
		var btn = Button.new()
		btn.text = tab[1]
		btn.custom_minimum_size = Vector2(0, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 13)
		var tid = tab[0]
		btn.pressed.connect(func(): _show_tab(tid))
		tab_bar.add_child(btn)
		_tab_btns[tab[0]] = btn

	_content = ScrollContainer.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_content)

	_show_tab("finances")


func _show_tab(tab: String) -> void:
	_current_tab = tab

	for tid in _tab_btns:
		var btn = _tab_btns[tid]
		var active = tid == tab
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.18, 0.28, 0.18) if active else Color(0.10, 0.12, 0.10)
		style.border_width_bottom = 3 if active else 0
		style.border_color = Color(1.0, 0.82, 0.2)
		style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
		style.content_margin_left = 12; style.content_margin_right = 12
		style.content_margin_top = 6; style.content_margin_bottom = 6
		btn.add_theme_stylebox_override("normal", style)

	for c in _content.get_children(): c.queue_free()
	await get_tree().process_frame

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	_content.add_child(content)

	match tab:
		"finances":  _build_finances_tab(content)
		"sponsors":  _build_sponsors_tab(content)
		"proposals": _build_proposals_tab(content)


# ══════════════════════════════════════════════════════════════════════════════
# TAB 1 — FINANCES
# ══════════════════════════════════════════════════════════════════════════════

func _build_finances_tab(parent: VBoxContainer) -> void:
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(cols)
	cols.add_child(_build_income_panel())
	cols.add_child(_build_expense_panel())
	cols.add_child(_build_indicators_panel())


func _build_income_panel() -> PanelContainer:
	var panel = _section_panel(Color(0.3, 0.7, 0.3))
	var vbox = panel.get_child(0)

	var lbl = Label.new(); lbl.text = "WEEKLY INCOME"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	vbox.add_child(lbl)
	vbox.add_child(HSeparator.new())

	var sponsor_weekly = 0
	for sp in GameState.active_sponsors:
		if sp.get("type",1) == 1: sponsor_weekly += sp.get("weekly_payment", 0)

	var supply_weekly = 0
	for sc in GameState.active_supply_contracts:
		if sc.active:
			supply_weekly += int(sc.parts_per_season / 52.0) * sc.cr_per_part

	var building_income = 0
	for bname in GameState.campus_buildings:
		var b = GameState.campus_buildings[bname]
		if b.get("level", 0) > 0: building_income += b.get("weekly_income", 0)

	var prize_est = _estimate_weekly_prize()
	var total = 0
	for item in [
		["Race Prizes (est.)",  prize_est,      prize_est > 0],
		["Sponsors (Type 1)",   sponsor_weekly, sponsor_weekly > 0],
		["Parts Sales",         supply_weekly,  supply_weekly > 0],
		["Building Income",     building_income,building_income > 0],
	]:
		vbox.add_child(_income_row(item[0], item[1], item[2]))
		if item[2]: total += item[1]

	vbox.add_child(HSeparator.new())
	vbox.add_child(_income_row("TOTAL (est.)", total, true))
	return panel


func _estimate_weekly_prize() -> int:
	if GameState.last_race_results.is_empty(): return 0
	for entry in GameState.last_race_results:
		if entry.get("is_player", false) or \
		   (entry.get("driver") and entry["driver"].id in GameState.player_team.drivers):
			return int(entry.get("prize", 0))
	return 0


func _income_row(label: String, amount: int, active: bool) -> HBoxContainer:
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
	val.custom_minimum_size = Vector2(110, 0)
	val.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if amount > 0 else Color(0.35, 0.35, 0.35))
	row.add_child(val)
	return row


func _build_expense_panel() -> PanelContainer:
	var panel = _section_panel(Color(0.8, 0.3, 0.3))
	var vbox = panel.get_child(0)

	var lbl = Label.new(); lbl.text = "WEEKLY EXPENSES"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(lbl)
	vbox.add_child(HSeparator.new())

	var driver_sal = 0
	for d_id in GameState.player_team.drivers:
		var d = GameState.all_drivers.get(d_id)
		if d: driver_sal += int(d.weekly_salary)

	var staff_sal = 0
	for s_id in GameState.all_staff:
		var s = GameState.all_staff[s_id]
		if s.contract_team == GameState.player_team.id:
			staff_sal += int(s.weekly_salary)

	var maintenance = 0
	for bname in GameState.campus_buildings:
		var b = GameState.campus_buildings[bname]
		if b.get("level", 0) > 0: maintenance += b.get("weekly_maintenance", 0)

	var rnd_costs = 0
	for task in GameState.active_rnd_tasks:
		rnd_costs += int(task.get("cr", 0) / max(1, task.get("weeks", 1)))

	var total = 0
	for item in [
		["Driver Salaries",      driver_sal],
		["Staff Salaries",       staff_sal],
		["Building Maintenance", maintenance],
		["R&D Projects",         rnd_costs],
		["Fuel (est.)",          GameState.player_team_cars.size() * 200],
		["Loan Interest",        int(GameState.current_loan * 0.002)],
	]:
		vbox.add_child(_expense_row(item[0], item[1]))
		total += item[1]

	vbox.add_child(HSeparator.new())
	vbox.add_child(_expense_row("TOTAL (est.)", total))
	return panel


func _expense_row(label: String, amount: int) -> HBoxContainer:
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
	val.custom_minimum_size = Vector2(110, 0)
	val.add_theme_color_override("font_color",
		Color(1.0, 0.4, 0.4) if amount > 0 else Color(0.35, 0.35, 0.35))
	row.add_child(val)
	return row


func _build_indicators_panel() -> PanelContainer:
	var panel = _section_panel(Color(0.3, 0.55, 0.9))
	var vbox = panel.get_child(0)

	var lbl = Label.new(); lbl.text = "KEY INDICATORS"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	vbox.add_child(lbl)
	vbox.add_child(HSeparator.new())

	var company_val = GameState._calculate_company_value()
	var max_loan    = GameState._calculate_max_loan()
	var runway      = GameState.get_runway_weeks()

	for ind in [
		["Company Value",  "CR %s" % _fmt(int(company_val)),  Color(0.8,0.8,0.8)],
		["Max Loan",       "CR %s" % _fmt(int(max_loan)),     Color(0.6,0.6,0.6)],
		["Reputation",     "%.0f / 100" % GameState.player_team.reputation,
			_stat_color(GameState.player_team.reputation)],
		["CEO Wealth",     "CR %s" % _fmt(int(GameState.ceo_accumulated_salary)),
			Color(1.0, 0.84, 0.0)],
		["Economy",        GameState.global_economy_state,
			Color(0.4,0.9,0.4) if GameState.global_economy_state == "Boom"
			else Color(1.0,0.6,0.1) if GameState.global_economy_state == "Normal"
			else Color(1.0,0.3,0.3)],
		["Fuel Price",     "CR %s/unit" % _fmt(int(GameState.current_fuel_price)), Color(0.7,0.7,0.7)],
		["Runway",         "%d weeks" % runway if runway < 52 else "Stable",
			Color(0.4,0.9,0.4) if runway >= 8 else
			Color(1.0,0.6,0.1) if runway >= 4 else Color(1.0,0.3,0.3)],
	]:
		var row = HBoxContainer.new()
		vbox.add_child(row)
		var ll = Label.new(); ll.text = ind[0]
		ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ll.add_theme_font_size_override("font_size", 12)
		ll.modulate = Color(0.6, 0.6, 0.6)
		row.add_child(ll)
		var lv = Label.new(); lv.text = ind[1]
		lv.add_theme_font_size_override("font_size", 12)
		lv.add_theme_color_override("font_color", ind[2])
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lv.custom_minimum_size = Vector2(130, 0)
		row.add_child(lv)

	var lbl_rw = Label.new()
	lbl_rw.text = "Runway = weeks covered at current expense rate with no income."
	lbl_rw.add_theme_font_size_override("font_size", 10)
	lbl_rw.modulate = Color(0.4, 0.4, 0.4)
	lbl_rw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lbl_rw)

	return panel


# ══════════════════════════════════════════════════════════════════════════════
# TAB 2 — SPONSORS
# ══════════════════════════════════════════════════════════════════════════════

func _build_sponsors_tab(parent: VBoxContainer) -> void:
	## Slot bar
	var max_slots  = GameState.get_hq_sponsor_slots()
	var used_slots = GameState.active_sponsors.size()
	var slot_row = HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 10)
	parent.add_child(slot_row)

	var lbl_slots = Label.new()
	lbl_slots.text = "Sponsor Slots:  %d / %d" % [used_slots, max_slots]
	lbl_slots.add_theme_font_size_override("font_size", 14)
	lbl_slots.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if used_slots < max_slots else Color(1.0, 0.55, 0.2))
	slot_row.add_child(lbl_slots)

	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 3)
	slot_row.add_child(bar)
	for i in range(max_slots):
		var sq = ColorRect.new()
		sq.custom_minimum_size = Vector2(18, 18)
		sq.color = Color(0.3, 0.75, 0.3) if i < used_slots else Color(0.25, 0.28, 0.35)
		bar.add_child(sq)

	parent.add_child(HSeparator.new())

	## Active sponsors
	parent.add_child(_sec_lbl("ACTIVE SPONSORS  (%d)" % GameState.active_sponsors.size()))
	if GameState.active_sponsors.is_empty():
		parent.add_child(_gray_lbl("No active sponsors."))
	else:
		for sp in GameState.active_sponsors:
			parent.add_child(_build_active_sponsor_card(sp))

	parent.add_child(HSeparator.new())

	## Offers
	parent.add_child(_sec_lbl("PENDING OFFERS  (%d)" % GameState.sponsor_offers.size()))
	if GameState.sponsor_offers.is_empty():
		parent.add_child(_gray_lbl("No offers pending. Use CFO Search below."))
	else:
		for offer in GameState.sponsor_offers:
			parent.add_child(_build_sponsor_offer_card(offer))

	parent.add_child(HSeparator.new())

	## CFO search
	parent.add_child(_sec_lbl("CFO SPONSOR SEARCH"))
	parent.add_child(_build_cfo_search_panel())


func _build_active_sponsor_card(sp: Dictionary) -> PanelContainer:
	var panel = _section_panel(Color(0.3, 0.7, 0.3))
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var vbox = panel.get_child(0)

	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	vbox.add_child(hdr)

	var lbl_n = Label.new(); lbl_n.text = sp.get("name","?")
	lbl_n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_n.add_theme_font_size_override("font_size", 13)
	lbl_n.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	hdr.add_child(lbl_n)

	var lbl_exp = Label.new()
	lbl_exp.add_theme_font_size_override("font_size", 11)
	var seas = sp.get("seasons_remaining", 0)
	lbl_exp.text = "%d season%s left" % [seas, "s" if seas != 1 else ""]
	lbl_exp.add_theme_color_override("font_color",
		Color(1.0, 0.5, 0.2) if seas <= 1 else Color(0.55, 0.55, 0.55))
	hdr.add_child(lbl_exp)

	var lbl_d = Label.new()
	lbl_d.add_theme_font_size_override("font_size", 12)
	lbl_d.modulate = Color(0.65, 0.65, 0.65)
	match sp.get("type", 1):
		1: lbl_d.text = "+CR %s per week" % _fmt(sp.get("weekly_payment", 0))
		2: lbl_d.text = "Win: +CR %s   Podium: +CR %s   Season: +CR %s" % [
			_fmt(sp.get("win_bonus",0)), _fmt(sp.get("podium_bonus",0)),
			_fmt(sp.get("season_bonus",0))]
		3: lbl_d.text = "Commitment deal — CR %s" % _fmt(sp.get("commitment_total",0))
	vbox.add_child(lbl_d)
	return panel


func _build_sponsor_offer_card(offer: Dictionary) -> PanelContainer:
	var panel = _section_panel(Color(0.4, 0.5, 0.8))
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var vbox = panel.get_child(0)

	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	vbox.add_child(hdr)
	var lbl_n = Label.new(); lbl_n.text = offer.get("name","?")
	lbl_n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_n.add_theme_font_size_override("font_size", 13)
	hdr.add_child(lbl_n)
	var lbl_t = Label.new(); lbl_t.text = "Type %d" % offer.get("type",1)
	lbl_t.add_theme_font_size_override("font_size", 10)
	lbl_t.modulate = Color(0.5,0.5,0.5)
	hdr.add_child(lbl_t)

	var lbl_d = Label.new()
	lbl_d.add_theme_font_size_override("font_size", 11)
	lbl_d.modulate = Color(0.65, 0.65, 0.65)
	match offer.get("type",1):
		1: lbl_d.text = "CR %s/wk  ·  %d seasons" % [
			_fmt(offer.get("weekly_payment",0)), offer.get("seasons_remaining",1)]
		2: lbl_d.text = "Win: CR %s  Podium: CR %s  ·  %d seasons" % [
			_fmt(offer.get("win_bonus",0)), _fmt(offer.get("podium_bonus",0)),
			offer.get("seasons_remaining",1)]
		3:
			var reg = GameState.CHAMPIONSHIP_REGISTRY.get(offer.get("championship_id",""),{})
			lbl_d.text = "[%s]  CR %s  ·  %d seasons" % [
				reg.get("name","?"), _fmt(offer.get("commitment_total",0)),
				offer.get("seasons_remaining",1)]
	vbox.add_child(lbl_d)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)
	var btn_neg = Button.new(); btn_neg.text = "📋 Negotiate"
	btn_neg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_neg.custom_minimum_size = Vector2(0, 26)
	btn_neg.pressed.connect(func():
		var neg = GameState.generate_sponsor_negotiation(offer.sponsor_id)
		if neg.is_empty():
			GameState.sign_sponsor(offer.sponsor_id)
			_show_tab("sponsors"); return
		GameState.start_negotiation(neg)
		var np = preload("res://scenes/ContractNegotiation.tscn").instantiate()
		get_tree().current_scene.add_child(np)
		np.open(GameState.active_negotiation)
		np.closed.connect(func(): _show_tab("sponsors")))
	btn_row.add_child(btn_neg)
	var btn_dis = Button.new(); btn_dis.text = "✕ Dismiss"
	btn_dis.modulate = Color(0.6,0.6,0.6)
	btn_dis.custom_minimum_size = Vector2(80, 26)
	btn_dis.pressed.connect(func():
		GameState.dismiss_sponsor_offer(offer.sponsor_id)
		_show_tab("sponsors"))
	btn_row.add_child(btn_dis)
	return panel


func _build_cfo_search_panel() -> PanelContainer:
	var panel = _section_panel(Color(0.3, 0.55, 0.9))
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var vbox = panel.get_child(0)
	var has_cfo = GameState.get_cfo() != null

	if GameState.cfo_search_active:
		var lbl = Label.new()
		lbl.text = "🔍 CFO searching...  Next offer in %d week%s." % [
			GameState.cfo_search_weeks_remaining,
			"s" if GameState.cfo_search_weeks_remaining != 1 else ""]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		vbox.add_child(lbl)
		var btn = Button.new(); btn.text = "⏹ Stop Search"
		btn.modulate = Color(1.0,0.5,0.5)
		btn.custom_minimum_size = Vector2(0, 30)
		btn.pressed.connect(func():
			GameState.stop_cfo_sponsor_search(); _show_tab("sponsors"))
		vbox.add_child(btn)
	elif has_cfo:
		var cfo = GameState.get_cfo()
		var lbl = Label.new()
		lbl.text = "CFO: %s  (Negotiation %.0f)" % [cfo.full_name(), cfo.sponsor_negotiation]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.modulate = Color(0.65, 0.65, 0.65)
		vbox.add_child(lbl)
		var btn = Button.new(); btn.text = "🔍 Start Sponsor Search"
		btn.custom_minimum_size = Vector2(0, 34)
		btn.add_theme_font_size_override("font_size", 13)
		btn.pressed.connect(func():
			GameState.start_cfo_sponsor_search(); _show_tab("sponsors"))
		vbox.add_child(btn)
	else:
		var lbl = Label.new()
		lbl.text = "No CFO hired. Hire a CFO in HQ to unlock sponsor search."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)
		var btn = Button.new(); btn.text = "Hire CFO →"
		btn.pressed.connect(func():
			GameState.pending_staff_filter = "CFO"
			get_tree().change_scene_to_file("res://scenes/Staff.tscn"))
		vbox.add_child(btn)

	return panel


# ══════════════════════════════════════════════════════════════════════════════
# TAB 3 — CFO PROPOSALS
# ══════════════════════════════════════════════════════════════════════════════

func _build_proposals_tab(parent: VBoxContainer) -> void:
	var panel = _section_panel(Color(1.0, 0.8, 0.2))
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	parent.add_child(panel)
	var vbox = panel.get_child(0)

	var lbl = Label.new(); lbl.text = "CFO PROPOSALS"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(lbl)
	vbox.add_child(HSeparator.new())

	var cfo = GameState.get_cfo()
	if not cfo:
		var e = Label.new()
		e.text = "No CFO hired. Hire a CFO in HQ to receive financial proposals."
		e.modulate = Color(0.45, 0.45, 0.45)
		e.add_theme_font_size_override("font_size", 12)
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(e)
		return

	var lbl_cfo = Label.new()
	lbl_cfo.text = "CFO: %s  ·  Financial Mgmt %.0f  ·  Negotiation %.0f" % [
		cfo.full_name(), cfo.budget_planning, cfo.sponsor_negotiation]
	lbl_cfo.add_theme_font_size_override("font_size", 12)
	lbl_cfo.modulate = Color(0.65, 0.65, 0.65)
	vbox.add_child(lbl_cfo)
	vbox.add_child(HSeparator.new())

	var proposals = _gen_proposals()
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


func _gen_proposals() -> Array:
	var out = []
	var runway = GameState.get_runway_weeks()
	if runway < 4:
		out.append({"text":"🚨 CRITICAL: Only %d weeks runway. Immediate action required." % runway,
			"color":Color(1.0,0.3,0.3)})
	elif runway < 8:
		out.append({"text":"⚠ WARNING: %d weeks runway. Reduce expenses or secure income." % runway,
			"color":Color(1.0,0.6,0.1)})
	if GameState.fuel_kg < 100:
		out.append({"text":"⛽ Fuel low (%.0f kg). Recommend buying 2 weeks supply." % GameState.fuel_kg,
			"color":Color(1.0,0.6,0.1)})
	if GameState.spare_parts < 20:
		out.append({"text":"🔧 Spare parts low (%d units). Restock before next race." % GameState.spare_parts,
			"color":Color(1.0,0.6,0.1)})
	if GameState.active_sponsors.is_empty() and not GameState.cfo_search_active:
		out.append({"text":"📋 No active sponsors. Recommend initiating a sponsor search.",
			"color":Color(0.7,0.7,0.7)})
	return out


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

func _section_panel(border_color: Color) -> PanelContainer:
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
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)
	return panel

func _sec_lbl(text: String) -> Label:
	var l = Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.55, 0.65, 0.80))
	return l

func _gray_lbl(text: String) -> Label:
	var l = Label.new(); l.text = text
	l.modulate = Color(0.5, 0.5, 0.5)
	l.add_theme_font_size_override("font_size", 12)
	return l

func _stat_color(v: float) -> Color:
	if v >= 70: return Color(0.4, 0.9, 0.4)
	if v >= 40: return Color(1.0, 0.8, 0.2)
	return Color(1.0, 0.4, 0.4)

func _fmt(n: int) -> String:
	return GameState._fmt_int(n)
