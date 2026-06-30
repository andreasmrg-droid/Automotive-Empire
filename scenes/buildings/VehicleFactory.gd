## Version: S39.6 — researched state now shows a details box + explicit Start Production button (was ambiguous ▶ Build); active line gets Stop Production
## Version: S39.5 — fixed zero-net preview (canonical economics); sales/stock breakdown; distinct brand colours; Facelift/Next-Gen removed (→R&D); build confirmation; locked text now Studio-level; title clips
## Version: S39.4 — COMMERCIAL DEPARTMENT redesign (per design owner + PowerPoint mock). Replaces the
##   cramped all-cards-stacked view (which overflowed the right edge) with a LIST-LEFT / DETAIL-RIGHT
##   layout: a scrollable segment list on the left; the selected segment gets a big labelled donut pie
##   (current-week share snapshot) + a colour-coded brand legend + a share-EVOLUTION line chart (per-
##   season history from CommercialMarketSim) on the right, with the demand effect and the interactive
##   line controls (build / marketing / facelift / next-gen). Pie + line colours match per brand.
##   Still visible to ALL players (read-only until a Factory + CFO exist). S39.1 status strip retained.
extends Control

var _resource_bar = null
const ResourceBarScript = preload("res://scenes/components/ResourceBar.gd")
const SharePieScript   = preload("res://scenes/components/SharePie.gd")
const ShareLinesScript = preload("res://scenes/components/ShareLines.gd")

## Shared brand palette — used by BOTH the pie and the legend/line chart so a brand is the same colour
## everywhere on screen. Player = green, giants = gold, Others = grey, ordinary AI = rotating palette.
const PLAYER_COL := Color(0.35, 0.92, 0.46)
const GIANT_COL  := Color(0.85, 0.72, 0.42)
const OTHERS_COL := Color(0.45, 0.45, 0.50)
const AI_PALETTE := [
	Color(0.40, 0.62, 0.95), Color(0.78, 0.52, 0.92), Color(0.95, 0.55, 0.45),
	Color(0.45, 0.80, 0.82), Color(0.90, 0.78, 0.42), Color(0.62, 0.70, 0.95),
	Color(0.85, 0.58, 0.70), Color(0.55, 0.85, 0.55), Color(0.95, 0.70, 0.35),
	Color(0.50, 0.72, 0.88), Color(0.80, 0.60, 0.95), Color(0.70, 0.80, 0.50)]

var _selected_seg: String = ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _refresh() -> void:
	for c in get_children():
		c.queue_free()
	_build_ui()

## Colour for a table row, consistent across pie + legend + lines. Every NAMED brand gets a distinct
## palette colour (giants are no longer all collapsed to one gold). `ai_index` advances per named brand.
func _brand_color(entry: Dictionary, ai_index: int) -> Color:
	if entry.get("is_player", false): return PLAYER_COL
	if entry.get("name", "") == "Others": return OTHERS_COL
	return AI_PALETTE[ai_index % AI_PALETTE.size()]

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
	## S39.5 — clip the title instead of letting it push the resource bar + buttons off the right edge.
	lbl_title.clip_text = true
	lbl_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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

	var market = GameState._commercial_market
	if market == null:
		root.add_child(_dim_label("Commercial market not initialised."))
		return

	## Order segments entry → pinnacle by unlock championship.
	var keys: Array = market.segment_keys()
	keys.sort_custom(func(a, b): return market.unlock_championship(a) < market.unlock_championship(b))
	if _selected_seg == "" or not _selected_seg in keys:
		_selected_seg = keys[0]

	# ── Body: list (left) | detail (right) ────────────────────────────────────
	var body = HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	body.add_child(_segment_list(keys, market))
	body.add_child(_detail_panel(_selected_seg, market, building, has_factory))

# ─────────────────────────────────────────────────────────────────────────────
# LEFT — scrollable segment list
# ─────────────────────────────────────────────────────────────────────────────
func _segment_list(keys: Array, market) -> Control:
	var wrap = VBoxContainer.new()
	wrap.custom_minimum_size = Vector2(360, 0)
	wrap.add_theme_constant_override("separation", 6)

	var hint = Label.new()
	hint.text = "MARKETS"
	hint.add_theme_font_size_override("font_size", 20)
	hint.modulate = Color(0.5, 0.5, 0.55)
	wrap.add_child(hint)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	wrap.add_child(scroll)
	var list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for seg_key in keys:
		list.add_child(_segment_list_item(seg_key, market))
	return wrap

func _segment_list_item(seg_key: String, market) -> Button:
	var unlocked: bool = GameState.is_commercial_segment_unlocked(seg_key)
	var researched: bool = GameState.is_commercial_blueprint_researched(seg_key)
	var has_line: bool = GameState.has_commercial_line_for(seg_key)

	var btn = Button.new()
	btn.toggle_mode = true
	btn.button_pressed = (seg_key == _selected_seg)
	btn.custom_minimum_size = Vector2(0, 56)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 22)

	# Status glyph + name, plus the player share if producing.
	var glyph := "🔒"
	if has_line:        glyph = "●"
	elif researched:    glyph = "✓"
	elif unlocked:      glyph = "○"
	var name_txt = "%s  %s" % [glyph, market.segment_name(seg_key)]
	if has_line:
		name_txt += "   (you %.1f%%)" % (market.get_player_share(seg_key) * 100.0)
	btn.text = name_txt
	if not unlocked:
		btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.64))
	elif has_line:
		btn.add_theme_color_override("font_color", Color(0.5, 0.92, 0.6))
	btn.pressed.connect(func():
		_selected_seg = seg_key
		_refresh())
	return btn

# ─────────────────────────────────────────────────────────────────────────────
# RIGHT — detail panel for the selected segment
# ─────────────────────────────────────────────────────────────────────────────
func _detail_panel(seg_key: String, market, building: Dictionary, has_factory: bool) -> Control:
	var unlocked: bool = GameState.is_commercial_segment_unlocked(seg_key)
	var researched: bool = GameState.is_commercial_blueprint_researched(seg_key)
	var has_line: bool = GameState.has_commercial_line_for(seg_key)

	var panel = _card_panel(Color(0.08, 0.10, 0.13))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# ── Title row: name · market type · status badge ──────────────────────────
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	vbox.add_child(title_row)
	var lbl_name = Label.new()
	lbl_name.text = market.segment_name(seg_key)
	lbl_name.add_theme_font_size_override("font_size", 34)
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(lbl_name)
	var seg_data: Dictionary = market.SEGMENTS.get(seg_key, {})
	var mt: String = seg_data.get("market_type", "")
	var lbl_mt = Label.new()
	lbl_mt.text = mt
	lbl_mt.add_theme_font_size_override("font_size", 22)
	lbl_mt.add_theme_color_override("font_color", {"Mass": Color(0.5, 0.75, 1.0),
		"Premium": Color(0.8, 0.65, 1.0), "Hyper": Color(1.0, 0.6, 0.4)}.get(mt, Color.WHITE))
	title_row.add_child(lbl_mt)
	vbox.add_child(_status_badge(seg_key, market, unlocked, researched, has_line))

	# ── Charts row: pie (left) | evolution line chart (right) ─────────────────
	var table = market.get_segment_table(seg_key)
	var charts = HBoxContainer.new()
	charts.add_theme_constant_override("separation", 20)
	charts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(charts)

	# Pie + legend
	var pie_col = VBoxContainer.new()
	pie_col.add_theme_constant_override("separation", 8)
	charts.add_child(pie_col)
	var pie_lbl = Label.new()
	pie_lbl.text = "This week"
	pie_lbl.add_theme_font_size_override("font_size", 18)
	pie_lbl.modulate = Color(0.55, 0.55, 0.6)
	pie_col.add_child(pie_lbl)
	var pie = SharePieScript.new()
	pie.custom_minimum_size = Vector2(190, 190)
	pie.set_data(table)
	if not unlocked: pie.modulate = Color(1, 1, 1, 0.55)
	pie_col.add_child(pie)

	# Evolution chart
	var line_col = VBoxContainer.new()
	line_col.add_theme_constant_override("separation", 8)
	line_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	charts.add_child(line_col)
	var line_lbl = Label.new()
	line_lbl.text = "Share over time (last %d seasons)" % market.HISTORY_SEASONS
	line_lbl.add_theme_font_size_override("font_size", 18)
	line_lbl.modulate = Color(0.55, 0.55, 0.6)
	line_col.add_child(line_lbl)
	line_col.add_child(_evolution_chart(seg_key, market, table))

	# ── Legend (brand → colour, matches pie + lines) ──────────────────────────
	vbox.add_child(_legend(table))

	# ── Demand effect ─────────────────────────────────────────────────────────
	var dm = market.demand_mult(seg_key, GameState.economy_index)
	var lbl_dm = Label.new()
	var pct_eff = (dm - 1.0) * 100.0
	lbl_dm.text = "Demand effect (economy): %+.0f%%" % pct_eff
	lbl_dm.add_theme_font_size_override("font_size", 20)
	lbl_dm.add_theme_color_override("font_color",
		Color(0.5, 0.8, 0.5) if pct_eff >= 0 else Color(0.85, 0.55, 0.5))
	vbox.add_child(lbl_dm)

	# ── Interactive zone ──────────────────────────────────────────────────────
	if has_line:
		vbox.add_child(HSeparator.new())
		vbox.add_child(_active_line_controls(seg_key, market, building))
	elif has_factory and GameState.get_cfo() != null and researched:
		vbox.add_child(HSeparator.new())
		vbox.add_child(_build_line_control(seg_key, market))
	elif not unlocked:
		var lk = Label.new()
		var need = int(GameState.RND_TASKS.get("P5_MODEL_%s" % seg_key, {}).get("Required_RnD_Studio_Level", 1))
		lk.text = "Locked — upgrade the R&D Studio to Level %d to research this segment's blueprint." % need
		lk.add_theme_font_size_override("font_size", 20)
		lk.modulate = Color(0.7, 0.6, 0.55)
		lk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lk)

	return panel

func _status_badge(seg_key: String, market, unlocked: bool, researched: bool, has_line: bool) -> Label:
	var badge = Label.new()
	badge.add_theme_font_size_override("font_size", 22)
	if has_line:
		badge.text = "● PRODUCING"; badge.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	elif researched:
		badge.text = "✓ BLUEPRINT READY — build a line below"; badge.add_theme_color_override("font_color", Color(0.55, 0.8, 1.0))
	elif unlocked:
		badge.text = "○ UNLOCKED — research the blueprint in the R&D Studio"; badge.add_theme_color_override("font_color", Color(0.85, 0.8, 0.45))
	else:
		var need = int(GameState.RND_TASKS.get("P5_MODEL_%s" % seg_key, {}).get("Required_RnD_Studio_Level", 1))
		badge.text = "🔒 NEEDS R&D STUDIO LV %d to research" % need; badge.add_theme_color_override("font_color", Color(0.75, 0.6, 0.55))
	return badge

## Build the evolution line chart series from recorded per-season history, colour-matched to the pie.
func _evolution_chart(seg_key: String, market, table: Array) -> Control:
	var chart = ShareLinesScript.new()
	chart.custom_minimum_size = Vector2(0, 190)
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var history: Array = market.get_segment_history(seg_key)
	# Map brand name → colour (same order/logic as the pie/legend).
	var color_of: Dictionary = {}
	var ai_idx := 0
	for entry in table:
		color_of[entry["name"]] = _brand_color(entry, ai_idx)
		if not entry.get("is_player", false) and entry["name"] != "Others":
			ai_idx += 1

	# Build one series per brand currently in the table, reading its share at each history point.
	var series: Array = []
	for entry in table:
		var bname = entry["name"]
		var pts: Array = []
		for snap in history:
			pts.append(float(snap.get("shares", {}).get(bname, 0.0)))
		# Append the live current value as the latest point so the line reaches "now".
		pts.append(float(entry["share"]))
		series.append({"name": bname, "color": color_of.get(bname, Color.WHITE), "points": pts})

	# X labels: S-n … now.
	var n_pts = history.size() + 1
	var labels: Array = []
	for i in range(n_pts):
		labels.append("now" if i == n_pts - 1 else "S-%d" % (n_pts - 1 - i))

	chart.set_series(series, labels)
	return chart

func _legend(table: Array) -> Control:
	var flow = HBoxContainer.new()
	flow.add_theme_constant_override("separation", 16)
	var ai_idx := 0
	for entry in table:
		var col = _brand_color(entry, ai_idx)
		if not entry.get("is_player", false) and entry["name"] != "Others":
			ai_idx += 1
		var item = HBoxContainer.new()
		item.add_theme_constant_override("separation", 5)
		var sw = Label.new(); sw.text = "●"; sw.add_theme_color_override("font_color", col)
		sw.add_theme_font_size_override("font_size", 20)
		item.add_child(sw)
		var nm = Label.new()
		nm.text = "%s %.1f%%" % [entry["name"], entry["share"] * 100.0]
		nm.add_theme_font_size_override("font_size", 20)
		if entry.get("is_player", false):
			nm.text = "▶ " + nm.text
			nm.add_theme_color_override("font_color", PLAYER_COL)
		item.add_child(nm)
		flow.add_child(item)
	return flow

# ─────────────────────────────────────────────────────────────────────────────
# STATUS STRIP (retained from S39.1)
# ─────────────────────────────────────────────────────────────────────────────
func _status_strip(building: Dictionary, has_factory: bool) -> PanelContainer:
	var panel = _card_panel(Color(0.10, 0.13, 0.17))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	panel.add_child(row)
	if has_factory:
		var lvl = int(building.get("level", 1))
		var used = GameState.commercial_lines.size()
		row.add_child(_stat_block("Production Lines", "%d / %d used" % [used, lvl], Color(0.55, 0.8, 1.0)))
	else:
		row.add_child(_stat_block("Factory", "Not built", Color(0.8, 0.55, 0.4)))
	var cfo = GameState.get_cfo()
	if cfo != null:
		var sf = GameState.get_commercial_sales_factor()
		row.add_child(_stat_block("CFO", "%s  (sales x%.2f)" % [cfo.full_name(), sf], Color(0.5, 0.85, 0.5)))
	else:
		row.add_child(_stat_block("CFO", "None — Factory off", Color(1.0, 0.45, 0.45)))
	var idx = GameState.economy_index
	var econ_word = "Normal"; var econ_col = Color(0.7, 0.7, 0.7)
	if idx > 70.0: econ_word = "Boom"; econ_col = Color(0.5, 0.85, 0.5)
	elif idx < 30.0: econ_word = "Recession"; econ_col = Color(1.0, 0.5, 0.5)
	row.add_child(_stat_block("Economy", "%s (idx %.0f)" % [econ_word, idx], econ_col))
	return panel

# ── Controls for an ACTIVE line (retained from S39.1) ─────────────────────────
func _active_line_controls(seg_key: String, market, building: Dictionary) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var line: Dictionary = {}
	for l in GameState.commercial_lines:
		if l.get("segment", "") == seg_key:
			line = l; break
	if line.is_empty():
		return box
	var lvl = int(building.get("level", 1))
	var mkt_ratio = float(line.get("marketing", 1.0))
	## S39.5 — single source of truth: same numbers the Financial Department and the weekly apply use.
	var econ: Dictionary = GameState.commercial_line_economics(seg_key)
	var recommended = GameState._commercial_market.recommended_marketing(
		seg_key, GameState.economy_index, lvl, GameState.get_commercial_sales_factor())
	var net_capped = float(econ.get("net", 0.0))
	var spend = float(econ.get("marketing", 0.0))

	var info = Label.new()
	var age = float(line.get("age_seasons", 0.0))
	info.text = "Model: %s   ·   Age %.0f seasons   ·   Your share %.1f%%" % [
		line.get("model_name", market.segment_name(seg_key)), age, float(econ.get("share", 0.0)) * 100.0]
	info.add_theme_font_size_override("font_size", 22)
	info.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
	box.add_child(info)

	## Sales / stock breakdown (S39.5 — #9: the player can now see what's actually happening).
	var demand = float(econ.get("demand", 0.0))
	var capacity = float(econ.get("capacity", 0.0))
	var sales_u = float(econ.get("sales_units", 0.0))
	var brk = Label.new()
	var sold_out := demand > capacity and capacity > 0.0
	brk.text = "Weekly: demand %s u  ·  capacity %s u  ·  sold %s u%s   →   gross CR %s  −  mktg CR %s  =  net CR %s/wk%s" % [
		_fmt(int(demand)), _fmt(int(capacity)), _fmt(int(sales_u)),
		"  (capacity-limited — upgrade Factory)" if sold_out else "",
		_fmt(int(econ.get("gross", 0.0))), _fmt(int(spend)), _fmt(int(net_capped)),
		"  (capped at 2× racing)" if econ.get("capped", false) else ""]
	brk.add_theme_font_size_override("font_size", 19)
	brk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brk.add_theme_color_override("font_color", Color(0.62, 0.72, 0.85))
	box.add_child(brk)

	var mrow = HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 8)
	box.add_child(mrow)
	var mlbl = Label.new()
	mlbl.text = "Marketing: x%.2f  (CR %s/wk, rec. %s)" % [mkt_ratio, _fmt(int(spend)), _fmt(int(recommended))]
	mlbl.add_theme_font_size_override("font_size", 20)
	mlbl.custom_minimum_size = Vector2(420, 0)
	mlbl.add_theme_color_override("font_color", Color(0.85, 0.6, 0.4) if mkt_ratio < 1.0 else Color(0.7, 0.8, 0.9))
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
	## S39.5 — Facelift / Next-Gen moved to the R&D Studio (they are redesigns: research there, then the
	## refreshed model flows back to this line). Show an ageing hint that points the player to R&D.
	if age >= 14.0:
		var hint = Label.new()
		hint.text = "⚠ This model is ageing (%.0f seasons). Research a Facelift or Next-Gen in the R&D Studio to refresh it." % age
		hint.add_theme_font_size_override("font_size", 19)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.add_theme_color_override("font_color", Color(0.9, 0.65, 0.4))
		box.add_child(hint)
	## S39.6 — explicit Stop Production (frees the line; the blueprint is kept so you can restart later).
	var srow = HBoxContainer.new()
	srow.add_theme_constant_override("separation", 10)
	box.add_child(srow)
	var btn_stop = Button.new()
	btn_stop.text = "⏹  Stop Production"
	btn_stop.custom_minimum_size = Vector2(200, 34)
	btn_stop.add_theme_font_size_override("font_size", 20)
	btn_stop.modulate = Color(0.95, 0.6, 0.55)
	btn_stop.pressed.connect(func(): _do_stop(seg_key))
	srow.add_child(btn_stop)
	var stop_note = Label.new()
	stop_note.text = "frees the line · keeps the blueprint"
	stop_note.add_theme_font_size_override("font_size", 18)
	stop_note.modulate = Color(0.55, 0.55, 0.6)
	srow.add_child(stop_note)
	return box

func _build_line_control(seg_key: String, market) -> VBoxContainer:
	## S39.6 — a proper DETAILS BOX for the designed (researched) model with an explicit, unambiguous
	## "Start Production" button (the old "▶ Build" read like an expander). Shows the model's specs and
	## the projected weekly economics BEFORE committing a line.
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)

	var seg_data: Dictionary = market.SEGMENTS.get(seg_key, {})
	var bp: Dictionary = GameState.RND_TASKS.get("P5_MODEL_%s" % seg_key, {})

	# Details panel
	var detail = _card_panel(Color(0.07, 0.13, 0.10))
	var dv = VBoxContainer.new()
	dv.add_theme_constant_override("separation", 4)
	detail.add_child(dv)
	var dh = Label.new()
	dh.text = "✓ Blueprint researched — ready to produce"
	dh.add_theme_font_size_override("font_size", 22)
	dh.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	dv.add_child(dh)
	# Spec lines from the segment data + blueprint
	var specs = Label.new()
	var margin_v = int(seg_data.get("margin", 0))
	var vol_v = int(seg_data.get("volume", 0))
	specs.text = "Model: %s   ·   Class: %s   ·   Unit margin: CR %s   ·   Global market: %s cars/yr" % [
		market.segment_name(seg_key), seg_data.get("market_type", ""), _fmt(margin_v), _fmt(vol_v)]
	specs.add_theme_font_size_override("font_size", 19)
	specs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	specs.add_theme_color_override("font_color", Color(0.7, 0.8, 0.75))
	dv.add_child(specs)
	# Capacity / projected at this factory level
	var lvl = int(GameState.campus_buildings.get("Vehicle Assembly Factory", {}).get("level", 1))
	var cap = market.line_capacity(lvl)
	var proj = Label.new()
	proj.text = "At Factory Lv %d: line capacity %s cars/wk. Your share starts near 0%% and grows over the coming seasons." % [
		lvl, _fmt(int(cap))]
	proj.add_theme_font_size_override("font_size", 19)
	proj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	proj.add_theme_color_override("font_color", Color(0.62, 0.72, 0.85))
	dv.add_child(proj)
	box.add_child(detail)

	# Action row
	var free = GameState.commercial_free_lines()
	if free <= 0:
		var lbl = Label.new()
		lbl.text = "No free production lines — upgrade the Factory to add a line."
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.6, 0.4))
		box.add_child(lbl)
		return box
	var arow = HBoxContainer.new()
	arow.add_theme_constant_override("separation", 10)
	box.add_child(arow)
	var btn = Button.new()
	btn.text = "▶  Start Production"
	btn.custom_minimum_size = Vector2(220, 38)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): _do_build(seg_key))
	arow.add_child(btn)
	var note = Label.new()
	note.text = "%d free production line%s available" % [free, "" if free == 1 else "s"]
	note.add_theme_font_size_override("font_size", 20)
	note.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	arow.add_child(note)
	return box

# ─────────────────────────────────────────────────────────────────────────────
# ACTIONS (retained from S39.1)
# ─────────────────────────────────────────────────────────────────────────────
func _do_build(seg_key: String) -> void:
	## S39.5 — make the action unambiguous (#6): confirm what's about to happen before committing a line.
	var nm = GameState._commercial_market.segment_name(seg_key)
	var err = GameState.build_commercial_line(seg_key)
	if err != "":
		GameState.show_popup(err, "Cannot Build Line")
	else:
		GameState.show_popup(
			"Production line started for %s.\n\nIt begins manufacturing this week. Your market share will grow over the coming seasons — set its marketing below, and watch the 'This week' pie and the share-over-time chart." % nm,
			"Production Started")
	_refresh()

## S39.6 — stop production (frees the line; blueprint retained).
func _do_stop(seg_key: String) -> void:
	var nm = GameState._commercial_market.segment_name(seg_key)
	var err = GameState.stop_commercial_line(seg_key)
	if err != "":
		GameState.show_popup(err, "Cannot Stop")
	else:
		GameState.add_log("⏹ Stopped %s production line (blueprint kept)." % nm)
		GameState.show_popup(
			"%s production stopped. The line is now free for another model, and your blueprint is retained — you can restart production any time." % nm,
			"Production Stopped")
	_refresh()

func _on_marketing_step(seg_key: String, delta: float) -> void:
	var cur := 1.0
	for l in GameState.commercial_lines:
		if l.get("segment", "") == seg_key:
			cur = float(l.get("marketing", 1.0))
			break
	GameState.set_commercial_marketing(seg_key, clamp(cur + delta, 0.0, 2.0))
	_refresh()

## NOTE (S39.5): Facelift / Next-Gen UI removed from this screen — they are moving to the R&D Studio
## (a refreshed model is a redesign). The GameState API (facelift_commercial_line / nextgen_commercial_
## line) is retained for the upcoming R&D flow to call once the redesign research completes.

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/Campus.tscn")

# ─────────────────────────────────────────────────────────────────────────────
# UI HELPERS (retained from S39.1)
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
	var s = str(abs(n))
	var out = ""
	var c = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out
