extends Control
## Version: S37.57 — #22 Championships-browser refactor: retired the hardcoded CHAMP_TEAMS /
##   CHAMP_STAFF / CHAMP_CARS / CAR_DRIVERS / CHAMP_KEY_IDX constants (display-only data that
##   duplicated and drifted from teams.json, and carried the last #22 IP: "Andretti Collective",
##   "IndyCar/Indy NXT/USF-equivalent" text). The browser now reads res://data/teams.json directly
##   (works at the title screen, pre-game) via _load_teams_from_json → _teams_by_champ, deriving each
##   championship's roster from every team's "championships" field — the SAME source the engine fields.
##   Rows are richer: flag · name · type · cars-in-champ · reputation · staff counts · driver pool.
##   Real-series descriptions reworded to discipline-based phrasing (mirrors the #30 building fix).
##   NOTE: did NOT touch AIManager's grid-fill / filler-team backup, personnel generation, or any
##   bankruptcy logic — those live in AIManager/GameState and are unrelated to this display screen.
## --- S29.8 — GK browser race count 29->21 (matches calendar).
## --- S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## --- S24.0 — Championships browser. Navigates all 24 championships
## grouped by discipline. Accessible from the title screen.
## No game state changes — read-only reference screen.

const CHAMPIONSHIPS: Array = [
	## Formula
	{"id":"C-024","name":"GP1 — Grand Prix 1","discipline":"Formula","tier":1,
	 "teams":11,"races":24,"desc":"The pinnacle of single-seater racing. The most prestigious, expensive and competitive championship in the world.",
	 "icon":"🏎","color":Color(0.9,0.2,0.15)},
	{"id":"C-023","name":"GP2 — Grand Prix 2","discipline":"Formula","tier":2,
	 "teams":14,"races":14,"desc":"The traditional feeder series to GP1. Most GP1 champions came through here.",
	 "icon":"🏎","color":Color(0.9,0.2,0.15)},
	{"id":"C-022","name":"GP3 — Grand Prix 3","discipline":"Formula","tier":3,
	 "teams":22,"races":18,"desc":"Mid-ladder formula series. Where young talent proves itself against established junior drivers.",
	 "icon":"🏎","color":Color(0.9,0.2,0.15)},
	{"id":"C-021","name":"GP4 — Grand Prix 4","discipline":"Formula","tier":4,
	 "teams":27,"races":10,"desc":"Entry-level single-seater. The first step on the Formula ladder. New car required every season.",
	 "icon":"🏎","color":Color(0.9,0.2,0.15)},
	## EPC
	{"id":"C-020","name":"EPC Hyper — Endurance Prototype Hyper","discipline":"Endurance","tier":1,
	 "teams":9,"races":8,"desc":"The summit of prototype endurance racing. 24-hour races, multi-class grids, three drivers per car. The pinnacle of the endurance ladder.",
	 "icon":"⏱","color":Color(0.1,0.6,0.9)},
	{"id":"C-019","name":"EPC League — Endurance Prototype League","discipline":"Endurance","tier":2,
	 "teams":10,"races":10,"desc":"Four-hour and six-hour races with mandatory driver changes. The proving ground for future Hyper contenders.",
	 "icon":"⏱","color":Color(0.1,0.6,0.9)},
	{"id":"C-018","name":"EPC Series — Endurance Prototype Series","discipline":"Endurance","tier":3,
	 "teams":12,"races":12,"desc":"Sprint endurance — 45-minute races with two-driver cars. Budget-accessible endurance racing.",
	 "icon":"⏱","color":Color(0.1,0.6,0.9)},
	## SC
	{"id":"C-017","name":"SC Cup — Stock Car Cup","discipline":"Stock Car","tier":1,
	 "teams":21,"races":36,"desc":"The full oval season. 36 races, three stages per race, a playoff finale. The largest audience in domestic motorsport.",
	 "icon":"🔄","color":Color(0.95,0.65,0.05)},
	{"id":"C-016","name":"SC Challenge — Stock Car Challenge","discipline":"Stock Car","tier":2,
	 "teams":21,"races":33,"desc":"The second tier of the oval ladder. Many Cup drivers entered here first.",
	 "icon":"🔄","color":Color(0.95,0.65,0.05)},
	{"id":"C-015","name":"SC Truck — Stock Car Truck Series","discipline":"Stock Car","tier":3,
	 "teams":18,"races":23,"desc":"Pickup trucks on the same ovals. More contact, more carnage, more character.",
	 "icon":"🔄","color":Color(0.95,0.65,0.05)},
	{"id":"C-014","name":"SC Dev — Stock Car Development","discipline":"Stock Car","tier":4,
	 "teams":17,"races":20,"desc":"Entry-level oval racing. Lower speeds, lower costs, high competition for the development budget.",
	 "icon":"🔄","color":Color(0.95,0.65,0.05)},
	## OWC
	{"id":"C-013","name":"OWC Pro — Open Wheel Championship Pro","discipline":"Open Wheel","tier":1,
	 "teams":18,"races":17,"desc":"The pinnacle of Open-Wheel racing. Ovals, street circuits, road courses. The most versatile championship on the calendar.",
	 "icon":"🛞","color":Color(0.3,0.8,0.4)},
	{"id":"C-012","name":"OWC Dev — Open Wheel Championship Development","discipline":"Open Wheel","tier":2,
	 "teams":21,"races":15,"desc":"The top feeder series into OWC Pro. The clearest path for young open-wheel talent.",
	 "icon":"🛞","color":Color(0.3,0.8,0.4)},
	{"id":"C-011","name":"OWC Next Gen — Open Wheel Next Generation","discipline":"Open Wheel","tier":3,
	 "teams":21,"races":12,"desc":"The first rung of the open-wheel ladder. Where careers begin.",
	 "icon":"🛞","color":Color(0.3,0.8,0.4)},
	## TC
	{"id":"C-010","name":"TC Elite — Touring Car Elite","discipline":"Touring Car","tier":1,
	 "teams":12,"races":12,"desc":"The pinnacle of Touring Car racing. Two drivers per car, multi-class racing, manufacturer-backed teams at the sharp end.",
	 "icon":"🚗","color":Color(0.7,0.3,0.9)},
	{"id":"C-009","name":"TC Sport — Touring Car Sport","discipline":"Touring Car","tier":2,
	 "teams":21,"races":14,"desc":"The second tier of Touring Car racing. A more accessible spec, mandatory driver changes, strong privateer presence.",
	 "icon":"🚗","color":Color(0.7,0.3,0.9)},
	## Rally
	{"id":"C-008","name":"Premier Rally Championship","discipline":"Rally","tier":1,
	 "teams":10,"races":13,"desc":"The pinnacle of Rally. Thirteen rallies across three legs each. Gravel, tarmac, snow, ice. The complete driver test.",
	 "icon":"🪨","color":Color(0.9,0.5,0.1)},
	{"id":"C-007","name":"Rally2 Championship","discipline":"Rally","tier":2,
	 "teams":16,"races":13,"desc":"The second tier of Rally. Full rally stages, smaller budgets. Many Premier Rally champions started here.",
	 "icon":"🪨","color":Color(0.9,0.5,0.1)},
	{"id":"C-006","name":"Rally3 Championship","discipline":"Rally","tier":3,
	 "teams":22,"races":12,"desc":"The third tier of Rally. Regional events, younger cars, the learning ground of the discipline.",
	 "icon":"🪨","color":Color(0.9,0.5,0.1)},
	{"id":"C-005","name":"Rally4 Championship","discipline":"Rally","tier":4,
	 "teams":22,"races":10,"desc":"Entry-level Rally. Gravel-focused, tight budgets, pure stage racing.",
	 "icon":"🪨","color":Color(0.9,0.5,0.1)},
	## GK
	{"id":"C-001","name":"GK Championship","discipline":"Go-Karting","tier":1,
	 "teams":85,"races":21,"desc":"A single progressive championship across 4 rounds. Round 1: 32 groups. Round 2: 16 groups of 20. Round 3: 4 groups of 32. Final: 2 groups of 30, winner crowned World Champion.",
	 "icon":"🏁","color":Color(0.4,0.85,0.9)},
]


## ── Real-data source (single source of truth) ────────────────────────────
## The browser is reachable from the title screen BEFORE a game is set up, so the live
## engine data (GameState.all_teams / ai_cars) does not exist yet. Instead we read the same
## canonical file the engine loads — res://data/teams.json — and derive each championship's
## roster from every team's "championships" field. This guarantees the browser shows exactly
## the teams the engine will field, with no hardcoded duplicate list to drift out of sync.

## Championship id  →  the key used inside each team's "championships" dict in teams.json.
const ID_TO_CHAMP_KEY: Dictionary = {
	"C-024":"GP1","C-023":"GP2","C-022":"GP3","C-021":"GP4",
	"C-020":"EPC Hyper","C-019":"EPC League","C-018":"EPC Series",
	"C-017":"SC Cup","C-016":"SC Challenge","C-015":"SC Truck","C-014":"SC Dev",
	"C-013":"OWC Pro","C-012":"OWC Dev","C-011":"OWC Next Gen",
	"C-010":"TC Elite","C-009":"TC Sport",
	"C-008":"Premier Rally","C-007":"Rally2","C-006":"Rally3","C-005":"Rally4",
	"C-001":"GK",
}

## champ_key → Array of team dicts {name, nat, type, rep, cars, staff:{...}, drivers_pro, drivers_cadet}
## Built once from teams.json. Cars = the team's car count IN THIS championship.
var _teams_by_champ: Dictionary = {}

func _load_teams_from_json() -> void:
	_teams_by_champ.clear()
	var f := FileAccess.open("res://data/teams.json", FileAccess.READ)
	if f == null:
		push_warning("[Championships] Could not open teams.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[Championships] teams.json did not parse to a Dictionary")
		return
	for tid in parsed:
		if not str(tid).begins_with("T-"):
			continue  ## skip "_meta" / non-team keys
		var td: Dictionary = parsed[tid]
		var champs: Dictionary = td.get("championships", {})
		for champ_key in champs:
			var cars_here: int = int(champs[champ_key])
			if cars_here <= 0:
				continue
			if not _teams_by_champ.has(champ_key):
				_teams_by_champ[champ_key] = []
			_teams_by_champ[champ_key].append({
				"name":          td.get("name", "Unknown"),
				"nat":           td.get("nat", ""),
				"type":          td.get("type", ""),
				"rep":           int(td.get("rep", 0)),
				"cars":          cars_here,
				"staff":         td.get("staff", {}),
				"drivers_pro":   int(td.get("drivers_pro", 0)),
				"drivers_cadet": int(td.get("drivers_cadet", 0)),
			})
	## Sort each championship's teams by reputation (descending) for a stable, sensible order.
	for k in _teams_by_champ:
		_teams_by_champ[k].sort_custom(func(a, b): return a["rep"] > b["rep"])

## ISO-3 nat code → flag emoji (best-effort; falls back to the raw code).
const NAT_FLAG: Dictionary = {
	"GBR":"🇬🇧","ITA":"🇮🇹","GER":"🇩🇪","FRA":"🇫🇷","ESP":"🇪🇸","NLD":"🇳🇱","BEL":"🇧🇪",
	"PRT":"🇵🇹","GRC":"🇬🇷","SWE":"🇸🇪","DNK":"🇩🇰","FIN":"🇫🇮","NOR":"🇳🇴","CHE":"🇨🇭",
	"AUT":"🇦🇹","POL":"🇵🇱","CZE":"🇨🇿","HUN":"🇭🇺","ROU":"🇷🇴","HRV":"🇭🇷","SRB":"🇷🇸",
	"TUR":"🇹🇷","UKR":"🇺🇦","IRL":"🇮🇪","RUS":"🇷🇺","USA":"🇺🇸","CAN":"🇨🇦","MEX":"🇲🇽",
	"BRA":"🇧🇷","ARG":"🇦🇷","COL":"🇨🇴","CHL":"🇨🇱","VEN":"🇻🇪","URY":"🇺🇾","PER":"🇵🇪",
	"JPN":"🇯🇵","KOR":"🇰🇷","CHN":"🇨🇳","IND":"🇮🇳","THA":"🇹🇭","MYS":"🇲🇾","IDN":"🇮🇩",
	"UAE":"🇦🇪","KSA":"🇸🇦","QAT":"🇶🇦","KWT":"🇰🇼","LBN":"🇱🇧","MAR":"🇲🇦","EGY":"🇪🇬",
	"AUS":"🇦🇺","NZL":"🇳🇿","ZAF":"🇿🇦","KEN":"🇰🇪",
}

var _idx: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_load_teams_from_json()
	_build()

func _build() -> void:
	for c in get_children(): c.queue_free()
	await get_tree().process_frame

	var bg = PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.07, 0.09)
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["margin_left","margin_right","margin_top","margin_bottom"]:
		margin.add_theme_constant_override(s, 60)
	bg.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)

	## ── Header ───────────────────────────────────────────────────────────────
	var hdr = HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 16)
	vbox.add_child(hdr)

	var btn_back = Button.new()
	btn_back.text = "← Back"
	btn_back.custom_minimum_size = Vector2(100, 40)
	btn_back.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/NewGame.tscn"))
	hdr.add_child(btn_back)

	var lbl_title = Label.new()
	lbl_title.text = "CHAMPIONSHIPS"
	lbl_title.add_theme_font_size_override("font_size", 56)
	lbl_title.add_theme_color_override("font_color", Color.WHITE)
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(lbl_title)

	## Counter
	var lbl_count = Label.new()
	lbl_count.text = "%d / %d" % [_idx + 1, CHAMPIONSHIPS.size()]
	lbl_count.add_theme_font_size_override("font_size", 28)
	lbl_count.modulate = Color(0.4, 0.4, 0.4)
	lbl_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hdr.add_child(lbl_count)

	## Accent line
	var accent = ColorRect.new()
	accent.color = CHAMPIONSHIPS[_idx]["color"]
	accent.custom_minimum_size = Vector2(0, 3)
	vbox.add_child(accent)

	## ── Discipline tabs (click to jump) ──────────────────────────────────────
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	vbox.add_child(tabs)

	const DISC_STARTS = {
		"Formula":0, "Endurance":4, "Stock Car":7, "Open Wheel":11,
		"Touring Car":14, "Rally":16, "Go-Karting":20
	}
	const DISC_ICONS = {
		"Formula":"🏎", "Endurance":"⏱", "Stock Car":"🔄",
		"Open Wheel":"🛞", "Touring Car":"🚗", "Rally":"🪨", "Go-Karting":"🏁"
	}
	var current_disc = CHAMPIONSHIPS[_idx]["discipline"]
	for disc in DISC_STARTS:
		var start = DISC_STARTS[disc]
		var is_cur = disc == current_disc
		var tab_btn = Button.new()
		tab_btn.text = "%s %s" % [DISC_ICONS[disc], disc]
		tab_btn.custom_minimum_size = Vector2(0, 32)
		tab_btn.add_theme_font_size_override("font_size", 22)
		var tab_style = StyleBoxFlat.new()
		tab_style.bg_color = CHAMPIONSHIPS[start]["color"].darkened(0.4) if is_cur else Color(0.10, 0.12, 0.16)
		tab_style.border_width_bottom = 3 if is_cur else 0
		tab_style.border_color = CHAMPIONSHIPS[start]["color"]
		tab_style.corner_radius_top_left = 4; tab_style.corner_radius_top_right = 4
		tab_style.content_margin_left = 10; tab_style.content_margin_right = 10
		tab_btn.add_theme_stylebox_override("normal", tab_style)
		var s = start
		tab_btn.pressed.connect(func(): _idx = s; _build())
		tabs.add_child(tab_btn)

	## ── Main card ─────────────────────────────────────────────────────────────
	var champ = CHAMPIONSHIPS[_idx]
	var card = PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.09, 0.11, 0.15)
	card_style.border_width_left = 4
	card_style.border_color = champ["color"]
	card_style.corner_radius_top_left = 6; card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_left = 6; card_style.corner_radius_bottom_right = 6
	card_style.content_margin_left = 32; card_style.content_margin_right = 32
	card_style.content_margin_top = 28; card_style.content_margin_bottom = 28
	card.add_theme_stylebox_override("panel", card_style)
	vbox.add_child(card)

	var card_content = VBoxContainer.new()
	card_content.add_theme_constant_override("separation", 20)
	card.add_child(card_content)

	## Icon + name + discipline
	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 16)
	card_content.add_child(name_row)

	var lbl_icon = Label.new()
	lbl_icon.text = champ["icon"]
	lbl_icon.add_theme_font_size_override("font_size", 96)
	name_row.add_child(lbl_icon)

	var name_col = VBoxContainer.new()
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_col.add_theme_constant_override("separation", 4)
	name_row.add_child(name_col)

	var lbl_name = Label.new()
	lbl_name.text = champ["name"]
	lbl_name.add_theme_font_size_override("font_size", 52)
	lbl_name.add_theme_color_override("font_color", Color.WHITE)
	name_col.add_child(lbl_name)

	var disc_tier = HBoxContainer.new()
	disc_tier.add_theme_constant_override("separation", 12)
	name_col.add_child(disc_tier)

	var lbl_disc = Label.new()
	lbl_disc.text = champ["discipline"].to_upper()
	lbl_disc.add_theme_font_size_override("font_size", 22)
	lbl_disc.add_theme_color_override("font_color", champ["color"])
	disc_tier.add_child(lbl_disc)

	if champ["discipline"] != "Go-Karting":
		var lbl_tier = Label.new()
		lbl_tier.text = "TIER %d" % champ["tier"]
		lbl_tier.add_theme_font_size_override("font_size", 22)
		lbl_tier.modulate = Color(0.4, 0.4, 0.4)
		disc_tier.add_child(lbl_tier)

	## Description
	var lbl_desc = Label.new()
	lbl_desc.text = champ["desc"]
	lbl_desc.add_theme_font_size_override("font_size", 30)
	lbl_desc.modulate = Color(0.75, 0.75, 0.75)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_content.add_child(lbl_desc)

	## Stats row
	var stats = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 40)
	card_content.add_child(stats)

	## "Teams" reflects the real count from teams.json for this championship (falls back to the
	## static CHAMPIONSHIPS value if the key is somehow missing), so the header matches the rows below.
	var champ_key_stat: String = ID_TO_CHAMP_KEY.get(champ["id"], "")
	var real_team_count: int = _teams_by_champ.get(champ_key_stat, []).size()
	var teams_stat: String = str(real_team_count) if real_team_count > 0 else str(champ["teams"])
	var stat_list = [
		["Teams", teams_stat],
		["Rounds", str(champ["races"])],
	]
	if champ["discipline"] != "Go-Karting":
		stat_list.append(["Tier", "%d of 4" % champ["tier"]])
	for stat in stat_list:
		var stat_col = VBoxContainer.new()
		stat_col.add_theme_constant_override("separation", 2)
		var lbl_k = Label.new()
		lbl_k.text = stat[0].to_upper()
		lbl_k.add_theme_font_size_override("font_size", 20)
		lbl_k.modulate = Color(0.4, 0.4, 0.4)
		stat_col.add_child(lbl_k)
		var lbl_v = Label.new()
		lbl_v.text = stat[1]
		lbl_v.add_theme_font_size_override("font_size", 44)
		lbl_v.add_theme_color_override("font_color", champ["color"])
		stat_col.add_child(lbl_v)
		stats.add_child(stat_col)

	## Teams list
	var teams_hdr = Label.new()
	teams_hdr.text = "PARTICIPATING TEAMS"
	teams_hdr.add_theme_font_size_override("font_size", 20)
	teams_hdr.modulate = Color(0.4, 0.4, 0.4)
	card_content.add_child(teams_hdr)

	## Roster comes from teams.json (single source of truth) — see _load_teams_from_json().
	var key: String = ID_TO_CHAMP_KEY.get(champ["id"], "")
	var teams_list: Array = _teams_by_champ.get(key, [])

	var is_gk = champ["discipline"] == "Go-Karting"
	## GK is shown as 32 Round-1 groups in-game; here we just split the team list across groups
	## for a representative pre-game view (the real per-driver group draw happens at season start).
	var num_groups: int = 32 if champ["id"] == "C-001" else 0

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 140)
	card_content.add_child(scroll)

	var team_grid = VBoxContainer.new()
	team_grid.add_theme_constant_override("separation", 2)
	scroll.add_child(team_grid)

	if teams_list.is_empty():
		var lbl_empty = Label.new()
		lbl_empty.text = "  (No teams found in teams.json for this championship)"
		lbl_empty.add_theme_font_size_override("font_size", 20)
		lbl_empty.add_theme_color_override("font_color", Color(0.6, 0.45, 0.45))
		team_grid.add_child(lbl_empty)
	elif is_gk and num_groups > 1:
		## Distribute teams as evenly as possible — no empty groups
		var total   = teams_list.size()
		var base    = total / num_groups
		var extras  = total % num_groups  ## first N groups get one extra
		var current = 0
		for g in range(num_groups):
			var count = base + (1 if g < extras else 0)
			if count <= 0:
				continue
			var lbl_grp = Label.new()
			lbl_grp.text = "GROUP %d" % (g + 1)
			lbl_grp.add_theme_font_size_override("font_size", 20)
			lbl_grp.add_theme_color_override("font_color", champ["color"])
			team_grid.add_child(lbl_grp)
			for i in range(current, current + count):
				_add_team_row(team_grid, teams_list[i], champ["color"])
			var spacer_grp = Control.new()
			spacer_grp.custom_minimum_size = Vector2(0, 6)
			team_grid.add_child(spacer_grp)
			current += count
	else:
		for tinfo in teams_list:
			_add_team_row(team_grid, tinfo, champ["color"])

	## Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	card_content.add_child(spacer)

	## ── Navigation arrows ─────────────────────────────────────────────────────
	var nav = HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 24)
	vbox.add_child(nav)

	## Prev
	var btn_prev = _nav_btn("◀")
	btn_prev.disabled = _idx == 0
	btn_prev.pressed.connect(func(): _idx -= 1; _build())
	nav.add_child(btn_prev)

	## Dot indicators — show current position within discipline group
	var dots = HBoxContainer.new()
	dots.add_theme_constant_override("separation", 6)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_child(dots)

	## Find range of current discipline
	var disc_name = champ["discipline"]
	var disc_start = 0
	var disc_end = CHAMPIONSHIPS.size() - 1
	for i in range(CHAMPIONSHIPS.size()):
		if CHAMPIONSHIPS[i]["discipline"] == disc_name:
			disc_start = i
			break
	for i in range(CHAMPIONSHIPS.size() - 1, -1, -1):
		if CHAMPIONSHIPS[i]["discipline"] == disc_name:
			disc_end = i
			break

	for i in range(disc_start, disc_end + 1):
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8) if i == _idx else Vector2(6, 6)
		dot.color = champ["color"] if i == _idx else Color(0.25, 0.25, 0.25)
		dots.add_child(dot)

	## Next
	var btn_next = _nav_btn("▶")
	btn_next.disabled = _idx == CHAMPIONSHIPS.size() - 1
	btn_next.pressed.connect(func(): _idx += 1; _build())
	nav.add_child(btn_next)



func _add_team_row(parent: VBoxContainer, tinfo: Dictionary, color: Color) -> void:
	## Rich, read-only team row built from teams.json data (counts only — no named people,
	## since this screen runs before a game is set up). Shows: flag · name · type · cars in this
	## championship · reputation · staff counts · driver pool.
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)

	## Flag + name
	var flag: String = NAT_FLAG.get(str(tinfo.get("nat","")), "")
	var lbl_team = Label.new()
	var prefix := "  · "
	if flag != "":
		prefix = "  %s " % flag
	lbl_team.text = "%s%s" % [prefix, str(tinfo.get("name","Unknown"))]
	lbl_team.add_theme_font_size_override("font_size", 24)
	lbl_team.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	lbl_team.custom_minimum_size = Vector2(260, 0)
	row.add_child(lbl_team)

	## Team type (Factory / Customer / …) + reputation
	var meta := ""
	var ttype: String = str(tinfo.get("type",""))
	if ttype != "":
		meta += ttype
	var rep: int = int(tinfo.get("rep", 0))
	if meta != "":
		meta += "  ·  "
	meta += "Rep %d" % rep
	var lbl_meta = Label.new()
	lbl_meta.text = meta
	lbl_meta.add_theme_font_size_override("font_size", 20)
	lbl_meta.add_theme_color_override("font_color", Color(0.6, 0.6, 0.62))
	lbl_meta.custom_minimum_size = Vector2(170, 0)
	row.add_child(lbl_meta)

	## Cars entered in THIS championship
	var cars: int = int(tinfo.get("cars", 0))
	var lbl_cars = Label.new()
	lbl_cars.text = "%d car%s" % [cars, "" if cars == 1 else "s"]
	lbl_cars.add_theme_font_size_override("font_size", 20)
	lbl_cars.add_theme_color_override("font_color", color.lightened(0.15))
	lbl_cars.custom_minimum_size = Vector2(80, 0)
	row.add_child(lbl_cars)

	## Staff counts (TP / Mechanic / Strategist / Pit / CFO / Designer)
	var staff: Dictionary = tinfo.get("staff", {})
	if not staff.is_empty():
		var parts := []
		for label_key in [["TP","TP"],["Mechanic","Mec"],["Strategist","Str"],["Pit Crew","Pit"],["CFO","CFO"],["Designer","Des"]]:
			var v: int = int(staff.get(label_key[0], 0))
			if v > 0:
				parts.append("%s %d" % [label_key[1], v])
		var lbl_staff = Label.new()
		lbl_staff.text = "  ".join(parts)
		lbl_staff.add_theme_font_size_override("font_size", 18)
		lbl_staff.add_theme_color_override("font_color", Color(0.55, 0.65, 0.85))
		lbl_staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl_staff)

	## Driver pool (pro + cadet)
	var dp: int = int(tinfo.get("drivers_pro", 0))
	var dc: int = int(tinfo.get("drivers_cadet", 0))
	if dp + dc > 0:
		var lbl_drv = Label.new()
		lbl_drv.text = "Drv %d  (Cdt %d)" % [dp, dc]
		lbl_drv.add_theme_font_size_override("font_size", 18)
		lbl_drv.add_theme_color_override("font_color", Color(0.6, 0.75, 0.6))
		row.add_child(lbl_drv)


func _nav_btn(label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(60, 48)
	btn.add_theme_font_size_override("font_size", 40)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18)
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.border_color = Color(0.22, 0.26, 0.32)
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)
	return btn
