extends Control
## Version: S15.2 — New scene. End of season summary screen.
## Shows: Championship standings, driver/staff improvement, R&D progress, financial status.
## Triggered from MainHub when current_week > 52 or all races complete.

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right"]:
		margin.add_theme_constant_override(s, 48)
	for s in ["margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 32)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	# ── Title ─────────────────────────────────────────────────────────────────
	var lbl_title = Label.new()
	lbl_title.text = "🏁  SEASON %d COMPLETE" % GameState.current_season
	lbl_title.add_theme_font_size_override("font_size", 34)
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
	content.add_theme_constant_override("separation", 20)
	scroll.add_child(content)

	# Section: Championship Standings
	content.add_child(_section_label("🏆 CHAMPIONSHIP STANDINGS"))
	content.add_child(_build_standings_section())

	content.add_child(HSeparator.new())

	# Section: Driver & Staff Improvement
	content.add_child(_section_label("📈 DRIVER & STAFF IMPROVEMENT"))
	content.add_child(_build_people_section())

	content.add_child(HSeparator.new())

	# Section: R&D Progress
	content.add_child(_section_label("🔬 R&D PROGRESS"))
	content.add_child(_build_rnd_section())

	content.add_child(HSeparator.new())

	# Section: Financial Status
	content.add_child(_section_label("💰 FINANCIAL STATUS"))
	content.add_child(_build_finance_section())

	# ── Footer ────────────────────────────────────────────────────────────────
	root.add_child(HSeparator.new())
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)

	var lbl_next = Label.new()
	lbl_next.text = "Season %d begins. Register championships and prepare your cars." % (GameState.current_season + 1)
	lbl_next.add_theme_font_size_override("font_size", 13)
	lbl_next.modulate = Color(0.65, 0.65, 0.65)
	lbl_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(lbl_next)

	var btn_reg = Button.new()
	btn_reg.text = "🏆 Registration →"
	btn_reg.custom_minimum_size = Vector2(160, 40)
	btn_reg.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ChampionshipSelect.tscn"))
	footer.add_child(btn_reg)

	var btn_hub = Button.new()
	btn_hub.text = "▶ Continue to Season %d" % (GameState.current_season + 1)
	btn_hub.custom_minimum_size = Vector2(220, 40)
	btn_hub.add_theme_font_size_override("font_size", 15)
	var style_btn = StyleBoxFlat.new()
	style_btn.bg_color = Color(0.15, 0.45, 0.15)
	style_btn.corner_radius_top_left = 5; style_btn.corner_radius_top_right = 5
	style_btn.corner_radius_bottom_left = 5; style_btn.corner_radius_bottom_right = 5
	btn_hub.add_theme_stylebox_override("normal", style_btn)
	btn_hub.pressed.connect(_on_continue)
	footer.add_child(btn_hub)


func _build_standings_section() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	if GameState.active_championships.is_empty():
		vbox.add_child(_lbl_gray("No championships ran this season."))
		return vbox

	for champ in GameState.active_championships:
		var card = _card_panel(Color(0.09, 0.11, 0.15))
		var cv = VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		card.add_child(cv)

		var lbl_champ = Label.new()
		lbl_champ.text = "🏆 %s" % champ.championship_name
		lbl_champ.add_theme_font_size_override("font_size", 14)
		lbl_champ.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		cv.add_child(lbl_champ)

		var standings = champ.get_standings_sorted()
		var shown = 0
		for i in range(standings.size()):
			if shown >= 5: break
			var entry = standings[i]
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
				Color(0.7, 0.7, 0.7) if i < 3 else Color(0.5, 0.5, 0.5))
			row.add_child(lbl_pos)

			var lbl_drv = Label.new()
			lbl_drv.text = drv.full_name()
			lbl_drv.add_theme_font_size_override("font_size", 13)
			lbl_drv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if is_player:
				lbl_drv.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
				lbl_drv.text += "  ← YOU"
			row.add_child(lbl_drv)

			var lbl_pts = Label.new()
			lbl_pts.text = "%d pts" % entry.get("points", 0)
			lbl_pts.add_theme_font_size_override("font_size", 13)
			lbl_pts.modulate = Color(0.7, 0.7, 0.7)
			row.add_child(lbl_pts)

			cv.add_child(row)
			shown += 1

		if standings.size() > 5:
			var lbl_more = Label.new()
			lbl_more.text = "... and %d more" % (standings.size() - 5)
			lbl_more.modulate = Color(0.4, 0.4, 0.4)
			lbl_more.add_theme_font_size_override("font_size", 11)
			cv.add_child(lbl_more)

		vbox.add_child(card)

	return vbox


func _build_people_section() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	# Drivers
	var any_driver = false
	for drv_id in GameState.player_team.drivers:
		var drv = GameState.all_drivers.get(drv_id)
		if drv == null: continue
		any_driver = true
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var lbl_name = Label.new()
		lbl_name.text = "🏎 %s" % drv.full_name()
		lbl_name.custom_minimum_size = Vector2(200, 0)
		lbl_name.add_theme_font_size_override("font_size", 13)
		row.add_child(lbl_name)

		for stat in [
			["Pace", drv.pace], ["Wet", drv.wet], ["Focus", drv.focus],
			["Exp", drv.experience]]:
			var lbl_s = Label.new()
			lbl_s.text = "%s %.0f" % [stat[0], stat[1]]
			lbl_s.add_theme_font_size_override("font_size", 12)
			lbl_s.add_theme_color_override("font_color", _skill_color(stat[1]))
			lbl_s.custom_minimum_size = Vector2(80, 0)
			row.add_child(lbl_s)

		var lbl_age = Label.new()
		lbl_age.text = "Age %d" % drv.age
		lbl_age.modulate = Color(0.5, 0.5, 0.5)
		lbl_age.add_theme_font_size_override("font_size", 11)
		row.add_child(lbl_age)

		vbox.add_child(row)

	if not any_driver:
		vbox.add_child(_lbl_gray("No drivers on your team."))

	vbox.add_child(HSeparator.new())

	# Key staff
	var any_staff = false
	for sid in GameState.all_staff:
		var s = GameState.all_staff[sid]
		if s.contract_team != GameState.player_team.id: continue
		any_staff = true
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var lbl_name = Label.new()
		lbl_name.text = "👤 %s  (%s)" % [s.full_name(), s.role]
		lbl_name.add_theme_font_size_override("font_size", 12)
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl_name)

		var primary = s.get_primary_skill()
		var lbl_skill = Label.new()
		lbl_skill.text = "%s %.0f" % [s.get_primary_skill_label(), primary]
		lbl_skill.add_theme_font_size_override("font_size", 12)
		lbl_skill.add_theme_color_override("font_color", _skill_color(primary))
		row.add_child(lbl_skill)

		var lbl_contract = Label.new()
		lbl_contract.text = "%d season%s left" % [
			s.contract_seasons_remaining, "s" if s.contract_seasons_remaining != 1 else ""]
		lbl_contract.modulate = Color(
			1.0 if s.contract_seasons_remaining <= 1 else 0.55,
			0.55 if s.contract_seasons_remaining <= 1 else 0.55,
			0.55 if s.contract_seasons_remaining <= 1 else 0.55)
		lbl_contract.add_theme_font_size_override("font_size", 11)
		row.add_child(lbl_contract)

		vbox.add_child(row)

	if not any_staff:
		vbox.add_child(_lbl_gray("No staff on your team."))

	return vbox


func _build_rnd_section() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var completed = GameState.completed_rnd_tasks.size()
	var active = GameState.active_rnd_tasks.size()
	var blueprints = GameState.known_blueprints.size()
	var wra_pending = GameState.active_wra_submissions.size()
	var wra_approved = GameState.wra_approved_blueprints.size()
	var cnc_jobs = GameState.cnc_production_queue.size()
	var cnc_inv = 0
	for k in GameState.cnc_parts_inventory:
		var item = GameState.cnc_parts_inventory[k]
		cnc_inv += item.get("quantity", 0) if item is Dictionary else int(item)

	for row_data in [
		["Completed R&D tasks", "%d" % completed, Color(0.4, 0.9, 0.4)],
		["Active R&D tasks", "%d" % active, Color(0.7, 0.7, 0.4)],
		["Blueprints in database", "%d" % blueprints, Color(0.4, 0.8, 1.0)],
		["WRA submissions pending", "%d" % wra_pending,
			Color(1.0, 0.6, 0.2) if wra_pending > 0 else Color(0.5, 0.5, 0.5)],
		["WRA approved (ready to mfg)", "%d" % wra_approved,
			Color(0.4, 0.9, 0.4) if wra_approved > 0 else Color(0.5, 0.5, 0.5)],
		["CNC jobs in queue", "%d" % cnc_jobs,
			Color(1.0, 0.75, 0.2) if cnc_jobs > 0 else Color(0.5, 0.5, 0.5)],
		["CNC parts in warehouse", "%d units" % cnc_inv,
			Color(0.4, 0.9, 0.4) if cnc_inv > 0 else Color(0.5, 0.5, 0.5)],
	]:
		vbox.add_child(_stat_row(row_data[0], row_data[1], row_data[2]))

	if wra_approved > 0:
		var btn_cnc = Button.new()
		btn_cnc.text = "⚙ Go to CNC Plant to manufacture →"
		btn_cnc.custom_minimum_size = Vector2(0, 30)
		btn_cnc.pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/buildings/CNCPlant.tscn"))
		vbox.add_child(btn_cnc)

	if cnc_inv > 0:
		var btn_gar = Button.new()
		btn_gar.text = "🔩 Go to Garage to install parts →"
		btn_gar.custom_minimum_size = Vector2(0, 30)
		btn_gar.pressed.connect(func():
			get_tree().change_scene_to_file("res://scenes/buildings/Garage.tscn"))
		vbox.add_child(btn_gar)

	return vbox


func _build_finance_section() -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var team = GameState.player_team
	var weekly_exp = GameState.get_weekly_expenses()
	var runway = GameState.get_runway_weeks()
	var company_val = GameState._calculate_company_value() if GameState.has_method("_calculate_company_value") else 0.0

	for row_data in [
		["Balance", "CR %s" % GameState._fmt_int(int(team.balance)),
			Color(0.4, 0.9, 0.4) if team.balance >= 0 else Color(1.0, 0.4, 0.4)],
		["Est. Weekly Expenses", "CR %s" % GameState._fmt_int(int(weekly_exp)), Color(1.0, 0.6, 0.4)],
		["Runway", "%s wks" % runway if runway < 999 else "Stable", Color(0.7, 0.7, 0.7)],
		["Active Sponsors", "%d / %d slots" % [
			GameState.active_sponsors.size(), GameState.get_hq_sponsor_slots()], Color(0.6, 0.8, 1.0)],
		["Pending Offers", "%d" % GameState.sponsor_offers.size(), Color(0.7, 0.85, 0.7)],
		["CEO Salary (accumulated)", "CR %s" % GameState._fmt_int(int(GameState.ceo_accumulated_salary)), Color(0.85, 0.75, 0.5)],
		["Reputation", "%.0f / 100" % team.reputation, Color(0.9, 0.8, 0.3)],
		["Marketability", "%.0f / 100" % team.marketability, Color(0.6, 0.8, 1.0)],
	]:
		vbox.add_child(_stat_row(row_data[0], row_data[1], row_data[2]))

	# Sponsor list
	if not GameState.active_sponsors.is_empty():
		vbox.add_child(HSeparator.new())
		var lbl_sp = Label.new()
		lbl_sp.text = "Active Sponsors:"
		lbl_sp.modulate = Color(0.55, 0.55, 0.55)
		lbl_sp.add_theme_font_size_override("font_size", 11)
		vbox.add_child(lbl_sp)
		for sp in GameState.active_sponsors:
			var lbl = Label.new()
			var detail = ""
			if sp.type == 1:
				detail = "+CR %s/wk" % GameState._fmt_int(sp.get("weekly_payment", 0))
			elif sp.type == 2:
				detail = "Win: CR %s" % GameState._fmt_int(sp.get("win_bonus", 0))
			elif sp.type == 3:
				detail = "Commitment deal"
			lbl.text = "  • %s  (%s)  ·  %d season%s left" % [
				sp.name, detail, sp.get("seasons_remaining", 1),
				"s" if sp.get("seasons_remaining", 1) != 1 else ""]
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
			vbox.add_child(lbl)

	return vbox


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")


# ── Helpers ───────────────────────────────────────────────────────────────────

func _section_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	return lbl

func _lbl_gray(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.modulate = Color(0.5, 0.5, 0.5)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl

func _stat_row(label: String, value: String, color: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l = Label.new(); l.text = label
	l.custom_minimum_size = Vector2(220, 0)
	l.add_theme_font_size_override("font_size", 12)
	l.modulate = Color(0.55, 0.55, 0.55)
	row.add_child(l)
	var v = Label.new(); v.text = value
	v.add_theme_font_size_override("font_size", 12)
	v.add_theme_color_override("font_color", color)
	row.add_child(v)
	return row

func _card_panel(bg: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.22, 0.28, 0.38)
	style.corner_radius_top_left = 5; style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5; style.corner_radius_bottom_right = 5
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _skill_color(v: float) -> Color:
	if v >= 75: return Color(0.3, 1.0, 0.3)
	elif v >= 50: return Color(1.0, 0.84, 0.0)
	elif v >= 30: return Color(1.0, 0.6, 0.2)
	return Color(0.7, 0.4, 0.4)
