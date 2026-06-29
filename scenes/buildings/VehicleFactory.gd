## Version: S39.3 — Market view now has GRAPHICAL CONTEXT: each segment card shows a donut/pie chart
##   (scenes/components/SharePie.gd) of the share split, with the share chips colour-matched to their
##   pie slices (player green, giants gold, Others grey, AI palette) for a single coherent visual.
## Version: S39.1 — COMMERCIAL DEPARTMENT (Phase 3 §4.6). Replaces the placeholder "future system"
##   screen with the real read-only→interactive road-car market view. Visible to ALL players from the
##   start: a status strip (Factory lines, CFO/sales_factor, current economy commercial effect) + the
##   12 segment cards, each showing the live share table (player/AI/giants/Others), demand effect, and
##   unlock status. When a Factory line is free + the blueprint is researched: a Build Line control.
##   For an active line: per-model marketing (−/+), Facelift, Next-Gen, and the live weekly net. All
##   actions go through the GameState commercial API (build/facelift/nextgen/set_marketing); the engine
##   (CommercialMarketSim) supplies the read data. CFO-gated exactly as the income system is.
extends Control

var _resource_bar = null
const ResourceBarScript = preload("res://scenes/components/ResourceBar.gd")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _refresh() -> void:
	## Rebuild the whole screen (called after any action that changes state).
	for c in get_children():
		c.queue_free()
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   28)
	margin.add_theme_constant_override("margin_right",  28)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	# ── Header ────────────────────────────────────────────────────────────────
	var building = GameState.campus_buildings.get("Vehicle Assembly Factory", {})
	var has_factory: bool = building.get("built", false) and int(building.get("level", 0)) >= 1
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)
	var lbl_title = Label.new()
	lbl_title.text = "🏭 COMMERCIAL DEPARTMENT"
	if has_factory:
		lbl_title.text += "  ·  Factory Lv %d" % int(building.get("level", 1))
	lbl_title.add_theme_font_size_override("font_size", 44)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)
	_resource_bar = ResourceBarScript.new()
	_resource_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	header.add_child(_resource_bar)
	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(100, 36)
	btn_back.pressed.connect(_on_back)
	header.add_child(btn_back)
	var btn_hub = Button.new()
	btn_hub.text = "🏠 Main Hub"
	btn_hub.custom_minimum_size = Vector2(130, 36)
	btn_hub.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainHub.tscn"))
	header.add_child(btn_hub)
	root.add_child(HSeparator.new())

	# ── Status strip ──────────────────────────────────────────────────────────
	root.add_child(_status_strip(building, has_factory))

	# ── Intro / mode line ─────────────────────────────────────────────────────
	var intro = Label.new()
	if has_factory and GameState.get_cfo() != null:
		intro.text = "Your road-car business. Build researched models on free lines, set each model's marketing, and refresh ageing models. Race a segment's championship to unlock it; research its blueprint in the R&D Studio."
	elif has_factory and GameState.get_cfo() == null:
		intro.text = "Hire a CFO (Staff screen) to operate the Factory — without one it produces nothing while still costing upkeep. Below: the live road-car market you can enter."
	else:
		intro.text = "The road-car market (read-only until you build the Vehicle Assembly Factory). Scout the segments, their producers, and live shares. Race a segment's championship to unlock its blueprint."
	intro.add_theme_font_size_override("font_size", 22)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.72, 0.74, 0.8)
	root.add_child(intro)

	# ── Segment list (scroll) ─────────────────────────────────────────────────
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var market = GameState._commercial_market
	if market == null:
		list.add_child(_dim_label("Commercial market not initialised."))
		return
	## Order segments by unlock championship (entry → pinnacle) for a sensible reading order.
	var keys: Array = market.segment_keys()
	keys.sort_custom(func(a, b): return market.unlock_championship(a) < market.unlock_championship(b))
	for seg_key in keys:
		list.add_child(_segment_card(seg_key, market, building, has_factory))

# ─────────────────────────────────────────────────────────────────────────────
# STATUS STRIP
# ─────────────────────────────────────────────────────────────────────────────
func _status_strip(building: Dictionary, has_factory: bool) -> PanelContainer:
	var panel = _card_panel(Color(0.10, 0.13, 0.17))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	panel.add_child(row)

	# Lines used / total
	if has_factory:
		var lvl = int(building.get("level", 1))
		var used = GameState.commercial_lines.size()
		row.add_child(_stat_block("Production Lines", "%d / %d used" % [used, lvl],
			Color(0.55, 0.8, 1.0)))
	else:
		row.add_child(_stat_block("Factory", "Not built", Color(0.8, 0.55, 0.4)))

	# CFO + sales factor
	var cfo = GameState.get_cfo()
	if cfo != null:
		var sf = GameState.get_commercial_sales_factor()
		row.add_child(_stat_block("CFO", "%s  (sales x%.2f)" % [cfo.full_name(), sf],
			Color(0.5, 0.85, 0.5)))
	else:
		row.add_child(_stat_block("CFO", "None — Factory off", Color(1.0, 0.45, 0.45)))

	# Economy commercial effect (current demand swing direction)
	var idx = GameState.economy_index
	var econ_word = "Normal"
	var econ_col = Color(0.7, 0.7, 0.7)
	if idx > 70.0: econ_word = "Boom"; econ_col = Color(0.5, 0.85, 0.5)
	elif idx < 30.0: econ_word = "Recession"; econ_col = Color(1.0, 0.5, 0.5)
	row.add_child(_stat_block("Economy", "%s (idx %.0f)" % [econ_word, idx], econ_col))

	return panel

# ─────────────────────────────────────────────────────────────────────────────
# SEGMENT CARD
# ─────────────────────────────────────────────────────────────────────────────
func _segment_card(seg_key: String, market, building: Dictionary, has_factory: bool) -> PanelContainer:
	var unlocked: bool = GameState.is_commercial_segment_unlocked(seg_key)
	var researched: bool = GameState.is_commercial_blueprint_researched(seg_key)
	var has_line: bool = GameState.has_commercial_line_for(seg_key)

	var bg = Color(0.09, 0.11, 0.14)
	if has_line:        bg = Color(0.08, 0.14, 0.10)   # active line → green tint
	elif not unlocked:  bg = Color(0.08, 0.08, 0.10)   # locked → dim
	var panel = _card_panel(bg)
	var border = Color(0.9, 0.45, 0.6) if has_line else Color(0.25, 0.25, 0.30)
	var style = panel.get_theme_stylebox("panel").duplicate()
	style.border_width_left = 4
	style.border_color = border
	panel.add_theme_stylebox_override("panel", style)

	## S39.3 — card body is now [ pie | content ]. The pie gives instant graphical context for the
	## share split; the text/chips stay on the right. Locked segments get a dimmed pie too (the market
	## exists regardless of whether the player can enter it yet).
	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	panel.add_child(body)

	var pie = preload("res://scenes/components/SharePie.gd").new()
	pie.custom_minimum_size = Vector2(96, 96)
	pie.set_data(market.get_segment_table(seg_key))
	if not unlocked:
		pie.modulate = Color(1, 1, 1, 0.5)
	body.add_child(pie)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(vbox)

	# ── Title row: name + market type + status badge ──────────────────────────
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	vbox.add_child(title_row)
	var lbl_name = Label.new()
	lbl_name.text = market.segment_name(seg_key)
	lbl_name.add_theme_font_size_override("font_size", 28)
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not unlocked: lbl_name.modulate = Color(0.55, 0.55, 0.58)
	title_row.add_child(lbl_name)

	var seg_data: Dictionary = market.SEGMENTS.get(seg_key, {})
	var mt: String = seg_data.get("market_type", "")
	var lbl_mt = Label.new()
	lbl_mt.text = mt
	lbl_mt.add_theme_font_size_override("font_size", 20)
	var mt_col = {"Mass": Color(0.5, 0.75, 1.0), "Premium": Color(0.8, 0.65, 1.0),
		"Hyper": Color(1.0, 0.6, 0.4)}.get(mt, Color.WHITE)
	lbl_mt.add_theme_color_override("font_color", mt_col)
	title_row.add_child(lbl_mt)

	# Status badge
	var badge = Label.new()
	badge.add_theme_font_size_override("font_size", 20)
	if has_line:
		badge.text = "● PRODUCING"; badge.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	elif researched:
		badge.text = "✓ BLUEPRINT READY"; badge.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
	elif unlocked:
		badge.text = "○ UNLOCKED — RESEARCH IT"; badge.add_theme_color_override("font_color", Color(0.85, 0.8, 0.45))
	else:
		var cid = market.unlock_championship(seg_key)
		var cname = GameState.CHAMPIONSHIP_REGISTRY.get(cid, {}).get("name", cid)
		badge.text = "🔒 RACE %s" % cname; badge.add_theme_color_override("font_color", Color(0.7, 0.55, 0.5))
	title_row.add_child(badge)

	# ── Share table (always visible — the read-only market view) ──────────────
	# Chips are coloured to MATCH their pie slice (player green, giants gold, Others grey, AI palette),
	# each prefixed with a ● swatch so the pie and the named breakdown read as one visual.
	var table = market.get_segment_table(seg_key)
	var share_row = HBoxContainer.new()
	share_row.add_theme_constant_override("separation", 14)
	vbox.add_child(share_row)
	var ai_palette = [
		Color(0.40, 0.62, 0.95), Color(0.78, 0.52, 0.92), Color(0.95, 0.55, 0.45),
		Color(0.45, 0.80, 0.82), Color(0.90, 0.78, 0.42), Color(0.62, 0.70, 0.95),
		Color(0.85, 0.58, 0.70)]
	var ai_idx = 0
	for entry in table:
		var chip = Label.new()
		var pct = entry["share"] * 100.0
		var nm = entry["name"]
		var col: Color
		var prefix := "● "
		if entry["is_player"]:
			col = Color(0.35, 0.92, 0.46); prefix = "▶ "
		elif entry["is_giant"]:
			col = Color(0.85, 0.72, 0.42)
		elif nm == "Others":
			col = Color(0.45, 0.45, 0.50)
		else:
			col = ai_palette[ai_idx % ai_palette.size()]; ai_idx += 1
		chip.text = "%s%s %.1f%%" % [prefix, nm, pct]
		chip.add_theme_font_size_override("font_size", 20)
		chip.add_theme_color_override("font_color", col)
		share_row.add_child(chip)

	# ── Economy demand effect ─────────────────────────────────────────────────
	var dm = market.demand_mult(seg_key, GameState.economy_index)
	var lbl_dm = Label.new()
	var pct_eff = (dm - 1.0) * 100.0
	lbl_dm.text = "Demand effect (economy): %+.0f%%" % pct_eff
	lbl_dm.add_theme_font_size_override("font_size", 18)
	lbl_dm.add_theme_color_override("font_color",
		Color(0.5, 0.8, 0.5) if pct_eff >= 0 else Color(0.85, 0.55, 0.5))
	vbox.add_child(lbl_dm)

	# ── Interactive zone (line management) ────────────────────────────────────
	if has_line:
		vbox.add_child(HSeparator.new())
		vbox.add_child(_active_line_controls(seg_key, market, building))
	elif has_factory and GameState.get_cfo() != null and researched:
		vbox.add_child(HSeparator.new())
		vbox.add_child(_build_line_control(seg_key, market))

	return panel

# ── Controls for an ACTIVE line ───────────────────────────────────────────────
func _active_line_controls(seg_key: String, market, building: Dictionary) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	# Find the line record
	var line: Dictionary = {}
	for l in GameState.commercial_lines:
		if l.get("segment", "") == seg_key:
			line = l; break
	if line.is_empty():
		return box

	var lvl = int(building.get("level", 1))
	var sf = GameState.get_commercial_sales_factor()
	var obonus = GameState._rnd_engine.get_rnd_bonus("weekly_commercial_output")
	var gross = market.line_weekly_credits(seg_key, GameState.economy_index, lvl, sf, obonus)
	var mkt_ratio = float(line.get("marketing", 1.0))
	var recommended = market.recommended_marketing(seg_key, GameState.economy_index, lvl, sf)
	var spend = recommended * mkt_ratio
	var net = gross - spend
	## Apply the same 2x racing cap the income system enforces, for an honest preview.
	var cap = GameState.get_avg_weekly_racing_income() * 2.0
	var net_capped = min(net, cap)

	# Model name + age
	var info = Label.new()
	var age = float(line.get("age_seasons", 0.0))
	info.text = "Model: %s   ·   Age %.0f seasons   ·   Net ~CR %s/wk" % [
		line.get("model_name", market.segment_name(seg_key)), age, _fmt(int(net_capped))]
	info.add_theme_font_size_override("font_size", 22)
	info.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
	box.add_child(info)

	# Marketing row: - [ratio] +  (recommended spend shown)
	var mrow = HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 8)
	box.add_child(mrow)
	var mlbl = Label.new()
	mlbl.text = "Marketing: x%.2f  (CR %s/wk, rec. %s)" % [mkt_ratio, _fmt(int(spend)), _fmt(int(recommended))]
	mlbl.add_theme_font_size_override("font_size", 20)
	mlbl.custom_minimum_size = Vector2(420, 0)
	mlbl.add_theme_color_override("font_color",
		Color(0.85, 0.6, 0.4) if mkt_ratio < 1.0 else Color(0.7, 0.8, 0.9))
	mrow.add_child(mlbl)
	var btn_minus = Button.new(); btn_minus.text = "−"; btn_minus.custom_minimum_size = Vector2(40, 30)
	btn_minus.pressed.connect(_on_marketing_step.bind(seg_key, -0.1))
	mrow.add_child(btn_minus)
	var btn_plus = Button.new(); btn_plus.text = "+"; btn_plus.custom_minimum_size = Vector2(40, 30)
	btn_plus.pressed.connect(_on_marketing_step.bind(seg_key, 0.1))
	mrow.add_child(btn_plus)
	if mkt_ratio < 1.0:
		var warn = Label.new(); warn.text = "↓ under-spending loses share"
		warn.add_theme_font_size_override("font_size", 18); warn.add_theme_color_override("font_color", Color(0.85, 0.55, 0.45))
		mrow.add_child(warn)

	# Lifecycle row: Facelift / Next-Gen
	var lrow = HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 10)
	box.add_child(lrow)
	var fl_cost = _facelift_cost(seg_key)
	var ng_cost = _nextgen_cost(seg_key)
	var btn_fl = Button.new()
	btn_fl.text = "Facelift  (CR %s)" % _fmt(fl_cost)
	btn_fl.custom_minimum_size = Vector2(0, 32)
	btn_fl.tooltip_text = "Cheap mid-life refresh — restores competitiveness (knocks ~6 seasons off the model's age)."
	btn_fl.disabled = GameState.player_team.balance < fl_cost
	btn_fl.pressed.connect(func(): _do_facelift(seg_key, fl_cost))
	lrow.add_child(btn_fl)
	var btn_ng = Button.new()
	btn_ng.text = "Next-Gen  (CR %s)" % _fmt(ng_cost)
	btn_ng.custom_minimum_size = Vector2(0, 32)
	btn_ng.tooltip_text = "Expensive successor — launches a new generation and resets the lifecycle clock."
	btn_ng.disabled = GameState.player_team.balance < ng_cost
	btn_ng.pressed.connect(func(): _do_nextgen(seg_key, ng_cost))
	lrow.add_child(btn_ng)
	# Age hint
	if age >= 18.0:
		var hint = Label.new(); hint.text = "⚠ ageing — refresh soon"
		hint.add_theme_font_size_override("font_size", 18); hint.add_theme_color_override("font_color", Color(0.9, 0.6, 0.4))
		lrow.add_child(hint)

	return box

# ── Control to BUILD a new line (researched + free line + CFO) ────────────────
func _build_line_control(seg_key: String, market) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var free = GameState.commercial_free_lines()
	if free <= 0:
		var lbl = Label.new()
		lbl.text = "No free production lines — upgrade the Factory to add a line."
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.6, 0.4))
		row.add_child(lbl)
		return row
	var btn = Button.new()
	btn.text = "▶ Build Production Line"
	btn.custom_minimum_size = Vector2(0, 34)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): _do_build(seg_key))
	row.add_child(btn)
	var note = Label.new()
	note.text = "%d free line%s" % [free, "" if free == 1 else "s"]
	note.add_theme_font_size_override("font_size", 20)
	note.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	row.add_child(note)
	return row

# ─────────────────────────────────────────────────────────────────────────────
# ACTIONS
# ─────────────────────────────────────────────────────────────────────────────
func _do_build(seg_key: String) -> void:
	var err = GameState.build_commercial_line(seg_key)
	if err != "":
		GameState.show_popup(err, "Cannot Build Line")
	_refresh()

## Step a line's marketing ratio by delta, clamped to [0, 2]. Reads the current value fresh so the
## button always acts on live state (not a value captured when the card was built).
func _on_marketing_step(seg_key: String, delta: float) -> void:
	var cur := 1.0
	for l in GameState.commercial_lines:
		if l.get("segment", "") == seg_key:
			cur = float(l.get("marketing", 1.0))
			break
	GameState.set_commercial_marketing(seg_key, clamp(cur + delta, 0.0, 2.0))
	_refresh()

func _do_facelift(seg_key: String, cost: int) -> void:
	if GameState.player_team.balance < cost:
		GameState.show_popup("Not enough CR for a facelift.", "Cannot Facelift"); return
	GameState.player_team.balance -= cost
	var err = GameState.facelift_commercial_line(seg_key)
	if err != "":
		GameState.player_team.balance += cost  # refund on failure
		GameState.show_popup(err, "Cannot Facelift")
	else:
		GameState.add_log("🔧 Facelift: %s model refreshed (-CR %s)." % [
			GameState._commercial_market.segment_name(seg_key), _fmt(cost)])
	_refresh()

func _do_nextgen(seg_key: String, cost: int) -> void:
	if GameState.player_team.balance < cost:
		GameState.show_popup("Not enough CR for a next-generation model.", "Cannot Launch"); return
	GameState.player_team.balance -= cost
	var err = GameState.nextgen_commercial_line(seg_key)
	if err != "":
		GameState.player_team.balance += cost
		GameState.show_popup(err, "Cannot Launch")
	else:
		GameState.add_log("🚀 Next-Gen: new %s generation launched (-CR %s)." % [
			GameState._commercial_market.segment_name(seg_key), _fmt(cost)])
	_refresh()

## Facelift ≈ 25% of the blueprint research cost (cheap refresh); Next-Gen ≈ 60% (expensive successor).
func _facelift_cost(seg_key: String) -> int:
	var bp = GameState.RND_TASKS.get("P5_MODEL_%s" % seg_key, {})
	return int(bp.get("cr", 25000000) * 0.25)

func _nextgen_cost(seg_key: String) -> int:
	var bp = GameState.RND_TASKS.get("P5_MODEL_%s" % seg_key, {})
	return int(bp.get("cr", 25000000) * 0.60)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

# ─────────────────────────────────────────────────────────────────────────────
# UI HELPERS
# ─────────────────────────────────────────────────────────────────────────────
func _stat_block(label: String, value: String, col: Color) -> VBoxContainer:
	var b = VBoxContainer.new()
	b.add_theme_constant_override("separation", 2)
	var l = Label.new(); l.text = label
	l.add_theme_font_size_override("font_size", 18); l.modulate = Color(0.5, 0.5, 0.55)
	b.add_child(l)
	var v = Label.new(); v.text = value
	v.add_theme_font_size_override("font_size", 24); v.add_theme_color_override("font_color", col)
	b.add_child(v)
	return b

func _dim_label(text: String) -> Label:
	var l = Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", 22); l.modulate = Color(0.6, 0.6, 0.6)
	return l

func _card_panel(bg: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.22, 0.22, 0.26)
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 12; style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _fmt(n: int) -> String:
	## Thousands separators, mirroring GameState._fmt_int.
	var s = str(abs(n))
	var out = ""
	var c = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out
