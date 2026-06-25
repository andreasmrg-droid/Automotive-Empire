extends Control
## Version: S37.13 — Race Results layout: Driver expands to ~2/5 of width (Laps starts there), then
##   Laps/Time/Gap/Pts expand EQUALLY to spread across the rest, Prize fixed at far right. Laps/Time/
##   Gap centered; Pts/Prize right. Header + rows share identical sizing + alignment per column.
## Version: S37.12 — Race Results table rebuilt with the driver-standings recipe: Driver column
##   EXPANDS to fill the container; all other columns are fixed-width + right-aligned, with header and
##   rows sharing the SAME sizing mode and SAME alignment per column (+clip_contents) so the header
##   sits exactly above its data and the table fills the whole panel. Standings untouched.
## Version: S37.11 — Standings + results column balance. DRIVER standings used a 130px clipped name
##   next to an expanding team label with separation 0, so "Charlie B WilliamsPinnacle Alliance"
##   jammed together; now Driver/Team use proportional stretch ratios (3:2) with 16px separation so
##   they spread and never touch. Team standings + race-results tables also get 16px separation and
##   wider, consistent column widths (Pts widened so 4-digit totals fit).
## Version: S37.10 — Bug #11 (race results screen): (1) results table had column separation 0 so
##   Laps/Time/Gap/Pts/Prize ran together — now 14px separation + wider matched header/row widths so
##   the numbers are readable and aligned. (2) Added "Skip All ⏭" (header, shows when >1 race queued
##   the same week) — applies every remaining race's repairs + sponsor bonuses and jumps to the Main
##   Hub. Standings tables untouched.
## Version: S29.12 — Localized all paged-screen UI strings (nav buttons, page titles,
##   indicator) via Locale.t/tf; PAGE_TITLES const replaced with _page_title() helper.
## --- S29.11 — Race Results split into 3 paged screens with Back/Next (issue #2):
##   (1) Race Results, (2) Driver + Team standings side by side, (3) Season Development
##   summary (car condition + driver/staff dev). Continue stays in the header throughout.
## --- S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
## Version: S24.0 — wet → car_control in stat deltas display.
## Version: S22.8 — #12 multi-race: consume_next_race_result queue in Continue button.

## S29.11 — paged layout state (issue #2)
var _page: int = 1
var _page_count: int = 3
var _player_raced: bool = false
var _page_area: VBoxContainer
var _btn_back: Button
var _btn_next: Button
var _lbl_page: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_right",  32)
	margin.add_theme_constant_override("margin_top",    20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	# ── Header ────────────────────────────────────────────────────────────────
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root.add_child(header)

	var lbl_title = Label.new()
	var wet_tag = "  🌧 WET" if GameState.last_race_wet else ""
	## For GK championships, add group context
	var group_tag = ""
	var last_cid = GameState.last_race_championship_id
	if last_cid in ["C-001","C-002","C-003","C-004"] and GameState.gk_discipline != null:
		var n_groups = GameState.gk_discipline.get_group_count(last_cid)
		if n_groups > 1:
			group_tag = "  ·  Group 1 of %d" % n_groups
	lbl_title.text = "🏁 ROUND %d / %d  —  %s%s%s" % [
		GameState.last_race_round,
		GameState.last_race_num_races,
		GameState.last_race_championship,
		group_tag,
		wet_tag
	]
	lbl_title.add_theme_font_size_override("font_size", 40)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	var lbl_track = Label.new()
	lbl_track.text = "📍 %s" % GameState.last_race_name
	lbl_track.add_theme_font_size_override("font_size", 26)
	lbl_track.modulate = Color(0.6, 0.6, 0.6)
	header.add_child(lbl_track)

	var btn_continue = Button.new()
	btn_continue.text = "Continue  ▶"
	btn_continue.custom_minimum_size = Vector2(140, 40)
	btn_continue.add_theme_font_size_override("font_size", 30)
	btn_continue.pressed.connect(_on_continue)
	header.add_child(btn_continue)

	## S37.10 (bug #11) — Skip button: when several races are queued the same week (multiple
	## championships), skip straight to the Main Hub, still applying each remaining race's repairs
	## and sponsor bonuses so nothing is lost.
	if GameState.pending_race_result_count() > 1:
		var btn_skip = Button.new()
		btn_skip.text = "Skip All  ⏭"
		btn_skip.custom_minimum_size = Vector2(150, 40)
		btn_skip.add_theme_font_size_override("font_size", 30)
		btn_skip.tooltip_text = "Apply all remaining race results and return to the Main Hub."
		btn_skip.pressed.connect(_on_skip_all)
		header.add_child(btn_skip)

	root.add_child(HSeparator.new())

	# ── Paged body (S29.11, issue #2): three pages navigated with Back/Next ──────
	## Page 1: Race Results | Page 2: Driver + Team standings (side by side) |
	## Page 3: Summary (car condition, driver & staff development).
	_page_area = VBoxContainer.new()
	_page_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_page_area)

	# ── Bottom nav row (pinned below the page area) ─────────────────────────────
	var nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	root.add_child(nav)

	_btn_back = Button.new()
	_btn_back.text = Locale.t("rr_nav_back")
	_btn_back.custom_minimum_size = Vector2(160, 44)
	_btn_back.add_theme_font_size_override("font_size", 28)
	_btn_back.pressed.connect(func(): _show_page(_page - 1))
	nav.add_child(_btn_back)

	_lbl_page = Label.new()
	_lbl_page.add_theme_font_size_override("font_size", 26)
	_lbl_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_page.modulate = Color(0.6, 0.6, 0.6)
	nav.add_child(_lbl_page)

	_btn_next = Button.new()
	_btn_next.text = Locale.t("rr_nav_next")
	_btn_next.custom_minimum_size = Vector2(160, 44)
	_btn_next.add_theme_font_size_override("font_size", 28)
	_btn_next.pressed.connect(func(): _show_page(_page + 1))
	nav.add_child(_btn_next)

	## Whether the player raced determines if page 3 (summary) exists.
	_player_raced = GameState.player_team_cars.any(
		func(c): return c.championship_id == GameState.last_race_championship_id)
	_page_count = 3 if _player_raced else 2

	_show_page(1)

# ── Page switching ────────────────────────────────────────────────────────────
func _page_title(p: int) -> String:
	match p:
		1: return Locale.t("rr_page_results")
		2: return Locale.t("rr_page_standings")
		3: return Locale.t("rr_page_development")
	return ""

func _show_page(p: int) -> void:
	_page = clampi(p, 1, _page_count)

	## Clear the page area synchronously (no stale frame).
	for c in _page_area.get_children():
		_page_area.remove_child(c)
		c.queue_free()

	match _page:
		1: _build_page_results()
		2: _build_page_standings()
		3: _build_page_summary()

	## Nav state
	_btn_back.disabled = (_page <= 1)
	_btn_next.disabled = (_page >= _page_count)
	_lbl_page.text = Locale.tf("rr_page_indicator", [_page_title(_page), _page, _page_count])

# ── Page 1: Race Results ──────────────────────────────────────────────────────
func _build_page_results() -> void:
	var panel = _section_panel(Color(0.2, 0.35, 0.55))
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_area.add_child(panel)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.get_child(0).add_child(scroll)

	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	scroll.add_child(box)

	_build_race_results(box)

# ── Page 2: Driver + Team standings side by side ──────────────────────────────
func _build_page_standings() -> void:
	var columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_area.add_child(columns)

	## Left: driver standings (purple)
	var dpanel = _section_panel(Color(0.4, 0.25, 0.65))
	dpanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dpanel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(dpanel)
	var dscroll = ScrollContainer.new()
	dscroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dpanel.get_child(0).add_child(dscroll)
	var dbox = VBoxContainer.new()
	dbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dbox.add_theme_constant_override("separation", 6)
	dscroll.add_child(dbox)
	_build_standings(dbox, false)

	## Right: team standings (gold)
	var tpanel = _section_panel(Color(1.0, 0.8, 0.2))
	tpanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tpanel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(tpanel)
	var tscroll = ScrollContainer.new()
	tscroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tpanel.get_child(0).add_child(tscroll)
	var tbox = VBoxContainer.new()
	tbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tbox.add_theme_constant_override("separation", 6)
	tscroll.add_child(tbox)
	_build_standings(tbox, true)

# ── Page 3: Season Development summary (only if the player raced) ──────────────
func _build_page_summary() -> void:
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page_area.add_child(scroll)

	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	scroll.add_child(right)

	var worst_cond = 100.0
	for car in GameState.player_team_cars:
		if car.championship_id == GameState.last_race_championship_id:
			worst_cond = min(worst_cond, car.condition)
	var cond_color = Color(0.3, 0.85, 0.3)
	if worst_cond < 70.0: cond_color = Color(1.0, 0.6, 0.1)
	if worst_cond < 40.0: cond_color = Color(1.0, 0.25, 0.25)
	var cond_panel = _section_panel(cond_color)
	right.add_child(cond_panel)
	_build_car_condition(cond_panel.get_child(0))

	var driver_dev_panel = _section_panel(Color(0.3, 0.7, 0.5))
	right.add_child(driver_dev_panel)
	_build_driver_improvements(driver_dev_panel.get_child(0))

	var staff_panel = _section_panel(Color(0.25, 0.75, 0.65))
	right.add_child(staff_panel)
	_build_staff_improvements(staff_panel.get_child(0))


func _build_race_results(parent: VBoxContainer) -> void:
	var lbl = Label.new()
	lbl.text = "RACE RESULTS"
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	parent.add_child(lbl)

	var results = GameState.last_race_results
	if results.is_empty():
		var empty = Label.new()
		empty.text = "No results available."
		empty.modulate = Color(0.5, 0.5, 0.5)
		parent.add_child(empty)
		return

	# Column headers
	## S37.13 — Layout per design owner: Driver expands to ~2/5 of the width (so Laps starts there),
	## then Laps/Time/Gap/Pts each expand EQUALLY (ratio 1) to spread across the remaining space, and
	## Prize stays fixed at the far right. Alignment: Laps/Time/Gap = CENTER, Pts/Prize = RIGHT.
	## spec: [text, mode, value, align]  mode "exp"→stretch ratio=value, "fixed"→width=value.
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 16)
	parent.add_child(hdr)
	for spec in [["Pos","fixed",52,"L"],["Driver","exp",2.5,"L"],["Laps","exp",1,"C"],["Time","exp",1,"C"],["Gap","exp",1,"C"],["Pts","exp",2,"C"],["Prize","fixed",130,"R"]]:
		var lh = Label.new()
		lh.text = spec[0]
		lh.add_theme_font_size_override("font_size", 20)
		lh.modulate = Color(0.45, 0.45, 0.45)
		lh.clip_contents = true
		if spec[1] == "exp":
			lh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lh.size_flags_stretch_ratio = float(spec[2])
		else:
			lh.custom_minimum_size = Vector2(spec[2], 0)
		if spec[3] == "C":
			lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		elif spec[3] == "R":
			lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		else:
			lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		hdr.add_child(lh)

	parent.add_child(HSeparator.new())

	# Find leader time for gap calculation
	var leader_time: float = -1.0
	for entry in results:
		if not entry.get("dns", false):
			leader_time = entry.get("total_time", 0.0)
			break

	var total_laps: int = GameState.last_race_laps if "last_race_laps" in GameState else 0

	for i in range(results.size()):
		var entry = results[i]
		var driver = entry["driver"]
		var is_dns = entry.get("dns", false)
		var is_player = entry.get("is_player", false) or driver.id in GameState.player_team.drivers
		var pts = entry.get("points", 0)
		var prize = entry.get("prize", 0.0)
		var pos = i + 1
		var t_time = entry.get("total_time", 0.0)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		parent.add_child(row)

		# Position / medal
		var lbl_pos = Label.new()
		if is_dns:     lbl_pos.text = "DNS"
		elif pos == 1: lbl_pos.text = "🥇"
		elif pos == 2: lbl_pos.text = "🥈"
		elif pos == 3: lbl_pos.text = "🥉"
		else:          lbl_pos.text = "%2d." % pos
		lbl_pos.custom_minimum_size = Vector2(52, 0)
		lbl_pos.add_theme_font_size_override("font_size", 26)
		if is_dns: lbl_pos.modulate = Color(0.45, 0.45, 0.45)
		row.add_child(lbl_pos)

		# Driver name
		var lbl_name = Label.new()
		lbl_name.text = driver.full_name()
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_name.size_flags_stretch_ratio = 2.5
		lbl_name.add_theme_font_size_override("font_size", 26)
		lbl_name.clip_contents = true
		if is_dns:
			lbl_name.modulate = Color(0.45, 0.45, 0.45)
		elif is_player:
			lbl_name.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		elif pos == 1:
			lbl_name.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		row.add_child(lbl_name)

		# Laps
		var lbl_laps = Label.new()
		lbl_laps.text = str(total_laps) if not is_dns else "—"
		lbl_laps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_laps.size_flags_stretch_ratio = 1.0
		lbl_laps.clip_contents = true
		lbl_laps.add_theme_font_size_override("font_size", 24)
		lbl_laps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_laps.modulate = Color(0.65, 0.65, 0.65)
		row.add_child(lbl_laps)

		# Total time H:MM:SS.ms
		var lbl_time = Label.new()
		lbl_time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_time.size_flags_stretch_ratio = 1.0
		lbl_time.clip_contents = true
		lbl_time.add_theme_font_size_override("font_size", 24)
		lbl_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if is_dns:
			lbl_time.text = "—"
			lbl_time.modulate = Color(0.45, 0.45, 0.45)
		else:
			lbl_time.text = _fmt_time(t_time)
			lbl_time.add_theme_color_override("font_color",
				Color(1.0, 0.84, 0.0) if pos == 1 else Color(0.75, 0.75, 0.75))
		row.add_child(lbl_time)

		# Gap to leader
		var lbl_gap = Label.new()
		lbl_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_gap.size_flags_stretch_ratio = 1.0
		lbl_gap.clip_contents = true
		lbl_gap.add_theme_font_size_override("font_size", 24)
		lbl_gap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if is_dns:
			lbl_gap.text = "DNS"
			lbl_gap.modulate = Color(0.45, 0.45, 0.45)
		elif pos == 1:
			lbl_gap.text = "LEADER"
			lbl_gap.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		else:
			lbl_gap.text = "+%s" % _fmt_time(t_time - leader_time)
			lbl_gap.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		row.add_child(lbl_gap)

		# Points
		var lbl_pts = Label.new()
		lbl_pts.text = "+%d" % pts if (pts > 0 and not is_dns) else "—"
		lbl_pts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_pts.size_flags_stretch_ratio = 2.0
		lbl_pts.clip_contents = true
		lbl_pts.add_theme_font_size_override("font_size", 24)
		lbl_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_pts.add_theme_color_override("font_color",
			Color(0.45,0.45,0.45) if (pts == 0 or is_dns) else Color(0.6, 1.0, 0.6))
		row.add_child(lbl_pts)

		# Prize
		var lbl_prize = Label.new()
		lbl_prize.text = "+CR %s" % _fmt(int(prize)) if prize > 0 else ""
		lbl_prize.custom_minimum_size = Vector2(130, 0)
		lbl_prize.clip_contents = true
		lbl_prize.add_theme_font_size_override("font_size", 22)
		lbl_prize.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_prize.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
		row.add_child(lbl_prize)
		## Driver stat deltas moved to right column — see _build_driver_improvements()

func _build_standings(parent: VBoxContainer, teams_mode: bool) -> void:
	var lbl = Label.new()
	lbl.text = "TEAMS STANDINGS" if teams_mode else "DRIVERS STANDINGS"
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	parent.add_child(lbl)

	if teams_mode:
		var champ = null
		for c in GameState.active_championships:
			if c.id == GameState.last_race_championship_id:
				champ = c
				break
		if champ == null and GameState.active_championships.size() > 0:
			champ = GameState.active_championships[0]
		if champ == null:
			var empty = Label.new()
			empty.text = "No standings yet."
			empty.modulate = Color(0.5, 0.5, 0.5)
			parent.add_child(empty)
			return

		# Column headers
		var hdr = HBoxContainer.new()
		hdr.add_theme_constant_override("separation", 16)
		parent.add_child(hdr)
		for pair in [["#", 36], ["Team", -1], ["Pts", 80]]:
			var lh = Label.new()
			lh.text = pair[0]
			lh.add_theme_font_size_override("font_size", 20)
			lh.modulate = Color(0.45, 0.45, 0.45)
			if pair[1] == -1: lh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			else: lh.custom_minimum_size = Vector2(pair[1], 0)
			if pair[0] == "Pts": lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hdr.add_child(lh)

		parent.add_child(HSeparator.new())

		var team_sorted = champ.get_team_standings_sorted()
		for i in range(team_sorted.size()):
			var entry = team_sorted[i]
			var team_name = "Unknown"
			var is_player = false
			for team in GameState.all_teams:
				if team.id == entry["team_id"]:
					team_name = team.team_name
					is_player = team.is_player_team
					break
			var pos = i + 1
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 16)
			parent.add_child(row)
			var lbl_pos = Label.new()
			lbl_pos.text = "%2d." % pos
			lbl_pos.custom_minimum_size = Vector2(36, 0)
			lbl_pos.add_theme_font_size_override("font_size", 24)
			row.add_child(lbl_pos)
			var lbl_name = Label.new()
			lbl_name.text = team_name
			lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_name.add_theme_font_size_override("font_size", 24)
			lbl_name.clip_contents = true
			if is_player:
				lbl_name.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			elif pos == 1:
				lbl_name.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			row.add_child(lbl_name)
			var lbl_pts = Label.new()
			lbl_pts.text = "%d pts" % entry["points"]
			lbl_pts.custom_minimum_size = Vector2(80, 0)
			lbl_pts.add_theme_font_size_override("font_size", 24)
			lbl_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl_pts.modulate = Color(0.7, 0.7, 0.7)
			row.add_child(lbl_pts)
	else:
		var standings = GameState.last_race_standings
		if standings.is_empty():
			var empty = Label.new()
			empty.text = "No standings yet."
			empty.modulate = Color(0.5, 0.5, 0.5)
			parent.add_child(empty)
			return

		# Column headers
		var hdr = HBoxContainer.new()
		hdr.add_theme_constant_override("separation", 16)
		parent.add_child(hdr)
		## S37.11 — proportional columns (stretch ratios) instead of fixed minimums + clip, so the
		## name and team never jam together ("Charlie B WilliamsPinnacle Alliance") and the row uses
		## the full panel width. # fixed; Driver/Team expand 3:2; Pts fixed right.
		for spec in [["#", "fixed", 36], ["Driver", "exp", 3], ["Team", "exp", 2], ["Pts", "fixed", 64]]:
			var lh = Label.new()
			lh.text = spec[0]
			lh.add_theme_font_size_override("font_size", 20)
			lh.modulate = Color(0.45, 0.45, 0.45)
			if spec[1] == "exp":
				lh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lh.size_flags_stretch_ratio = float(spec[2])
			else:
				lh.custom_minimum_size = Vector2(spec[2], 0)
			if spec[0] == "Pts": lh.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hdr.add_child(lh)

		parent.add_child(HSeparator.new())

		for i in range(standings.size()):
			var entry = standings[i]
			var driver = GameState.all_drivers.get(entry["driver_id"])
			if not driver:
				continue
			var is_player = entry["driver_id"] in GameState.player_team.drivers
			var pos = i + 1
			var team_name = ""
			for team in GameState.all_teams:
				if entry["driver_id"] in team.drivers:
					team_name = team.team_name
					break
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 16)
			parent.add_child(row)
			var lbl_pos = Label.new()
			lbl_pos.text = "%2d." % pos
			lbl_pos.custom_minimum_size = Vector2(36, 0)
			lbl_pos.add_theme_font_size_override("font_size", 24)
			row.add_child(lbl_pos)
			var lbl_name = Label.new()
			lbl_name.text = driver.full_name()
			lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_name.size_flags_stretch_ratio = 3.0
			lbl_name.add_theme_font_size_override("font_size", 24)
			lbl_name.clip_contents = true
			if is_player:
				lbl_name.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			elif pos == 1:
				lbl_name.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
			row.add_child(lbl_name)
			var lbl_team = Label.new()
			lbl_team.text = team_name
			lbl_team.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl_team.size_flags_stretch_ratio = 2.0
			lbl_team.add_theme_font_size_override("font_size", 20)
			lbl_team.clip_contents = true
			lbl_team.add_theme_color_override("font_color",
				Color(0.4, 0.8, 1.0) if is_player else Color(0.45, 0.45, 0.45))
			row.add_child(lbl_team)
			var lbl_pts = Label.new()
			lbl_pts.text = "%d pts" % entry["points"]
			lbl_pts.custom_minimum_size = Vector2(80, 0)
			lbl_pts.add_theme_font_size_override("font_size", 24)
			lbl_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl_pts.modulate = Color(0.7, 0.7, 0.7)
			row.add_child(lbl_pts)

func _build_car_condition(parent: VBoxContainer) -> void:
	var player_cars = GameState.player_team_cars.filter(
		func(c): return c.championship_id == GameState.last_race_championship_id)

	if player_cars.is_empty():
		return

	var lbl = Label.new()
	lbl.text = "CAR CONDITION"
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	parent.add_child(lbl)

	for car in player_cars:
		var panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.12, 0.15)
		style.border_width_left = 2; style.border_width_right = 1
		style.border_width_top = 1; style.border_width_bottom = 1
		var cond = car.condition
		var border_c = Color(0.3, 0.9, 0.3)
		if cond < 70: border_c = Color(1.0, 0.6, 0.1)
		if cond < 40: border_c = Color(1.0, 0.2, 0.2)
		style.border_color = border_c
		style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
		style.content_margin_left = 10; style.content_margin_right = 10
		style.content_margin_top = 8; style.content_margin_bottom = 8
		panel.add_theme_stylebox_override("panel", style)
		parent.add_child(panel)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		panel.add_child(vbox)

		var lbl_car = Label.new()
		lbl_car.text = "%s  —  Overall: %.0f%%" % [
			car.car_name if car.car_name != "" else "Car %d" % car.car_number, cond]
		lbl_car.add_theme_font_size_override("font_size", 26)
		var cc = Color(0.3, 0.9, 0.3)
		if cond < 70: cc = Color(1.0, 0.6, 0.1)
		if cond < 40: cc = Color(1.0, 0.3, 0.3)
		lbl_car.add_theme_color_override("font_color", cc)
		vbox.add_child(lbl_car)

		var parts_row = HBoxContainer.new()
		parts_row.add_theme_constant_override("separation", 8)
		vbox.add_child(parts_row)
		for part_name in ["Aero", "Engine", "Gearbox", "Suspension", "Brakes", "Chassis"]:
			var part_cond = car.part_conditions.get(part_name, 100.0)
			var pc = Color(0.3, 0.9, 0.3)
			if part_cond < 70: pc = Color(1.0, 0.6, 0.1)
			if part_cond < 40: pc = Color(1.0, 0.3, 0.3)
			var chip = Label.new()
			chip.text = "%s %.0f%%" % [part_name.left(3), part_cond]
			chip.add_theme_font_size_override("font_size", 20)
			chip.add_theme_color_override("font_color", pc)
			parts_row.add_child(chip)

func _on_continue() -> void:
	GameState.apply_post_race_repairs()
	GameState.apply_sponsor_race_bonuses()
	## If more races queued this week, show next result screen
	if GameState.consume_next_race_result():
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

## S37.10 (bug #11) — apply the current result's effects, then loop through every remaining queued
## result applying ITS repairs + sponsor bonuses, then go to the Main Hub. Mirrors pressing
## Continue repeatedly without rendering each screen.
func _on_skip_all() -> void:
	GameState.apply_post_race_repairs()
	GameState.apply_sponsor_race_bonuses()
	while GameState.consume_next_race_result():
		GameState.apply_post_race_repairs()
		GameState.apply_sponsor_race_bonuses()
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		var screenshot = get_viewport().get_texture().get_image()
		var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
		screenshot.save_png("user://screenshot_%s.png" % timestamp)

func _section_panel(border_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.10, 0.13)
	style.border_width_left = 3
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	# Inner VBox — callers add children to this
	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)
	return panel

func _fmt_time(seconds: float) -> String:
	if seconds <= 0.0: return "0:00:00.000"
	var h  = int(seconds) / 3600
	var m  = (int(seconds) % 3600) / 60
	var s  = int(seconds) % 60
	var ms = int((seconds - int(seconds)) * 1000.0)
	return "%d:%02d:%02d.%03d" % [h, m, s, ms]

func _build_driver_improvements(parent: VBoxContainer) -> void:
	var lbl = Label.new()
	lbl.text = "DRIVER DEVELOPMENT"
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6))
	parent.add_child(lbl)

	var any = false
	for entry in GameState.last_race_results:
		var driver = entry.get("driver")
		if not driver: continue
		if not driver.id in GameState.player_team.drivers: continue
		if entry.get("dns", false): continue
		var deltas = entry.get("stat_deltas", {})
		if deltas.is_empty(): continue

		any = true
		var name_lbl = Label.new()
		name_lbl.text = driver.full_name() if driver.has_method("full_name") else str(driver)
		name_lbl.add_theme_font_size_override("font_size", 24)
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
		parent.add_child(name_lbl)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		parent.add_child(row)

		for sk in [["Pace","pace"],["Car Ctrl","car_control"],["Focus","focus"],["Exp","experience"],["Fit","fitness"]]:
			var dv = deltas.get(sk[1], 0.0)
			if abs(dv) > 0.01:
				var dl = Label.new()
				dl.text = "%s %s%.1f%s" % [sk[0], "+" if dv >= 0 else "", dv,
					"%" if sk[0] == "Fit" else ""]
				dl.add_theme_font_size_override("font_size", 22)
				dl.add_theme_color_override("font_color",
					Color(0.4, 0.9, 0.4) if dv >= 0 else Color(1.0, 0.4, 0.4))
				row.add_child(dl)

	if not any:
		var empty = Label.new()
		empty.text = "No development this race."
		empty.modulate = Color(0.5, 0.5, 0.5)
		empty.add_theme_font_size_override("font_size", 22)
		parent.add_child(empty)

func _build_staff_improvements(parent: VBoxContainer) -> void:
	var mech_deltas: Array = GameState.last_race_staff_deltas if "last_race_staff_deltas" in GameState else []
	if mech_deltas.is_empty(): return

	var lbl_hdr = Label.new()
	lbl_hdr.text = "STAFF DEVELOPMENT"
	lbl_hdr.add_theme_font_size_override("font_size", 26)
	lbl_hdr.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	parent.add_child(lbl_hdr)

	for item in mech_deltas:
		var panel = _make_dev_card(item.get("name","Staff"), "🔧", Color(0.3, 0.7, 0.45))
		var vbox = panel.get_child(0)
		var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 10); vbox.add_child(row)
		for sk in [["Setup","car_setup"],["Track","track_knowledge"],["Strat","race_strategy"]]:
			var dv = item.get("deltas", {}).get(sk[1], 0.0)
			if abs(dv) > 0.01: row.add_child(_delta_lbl("%s %s%.1f" % [sk[0], "+" if dv >= 0 else "", dv], dv))
		parent.add_child(panel)

func _make_dev_card(name: String, icon: String, border: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.10) if icon == "🔧" else Color(0.08, 0.12, 0.18)
	style.border_width_left = 3; style.border_color = border
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	style.content_margin_left = 10; style.content_margin_right = 10
	style.content_margin_top = 7; style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	var vbox = VBoxContainer.new(); vbox.add_theme_constant_override("separation", 4); panel.add_child(vbox)
	var lbl = Label.new(); lbl.text = "%s %s" % [icon, name]
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.55,0.9,0.65) if icon == "🔧" else Color(0.65,0.85,1.0))
	vbox.add_child(lbl)
	return panel

func _delta_lbl(text: String, value: float) -> Label:
	var lbl = Label.new(); lbl.text = text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.4,0.9,0.4) if value >= 0 else Color(1.0,0.4,0.4))
	return lbl

func _fmt(n: int) -> String:
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result
