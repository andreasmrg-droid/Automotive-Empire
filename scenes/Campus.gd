extends Control
## Version: S37.30 — CAMPUS REDESIGN: category TABS (one per zone, tinted in zone colours). Clicking a
##   tab shows ONLY that zone's building cards (was: all 6 zones stacked in one long scroll). Adds the
##   shared ResourceBar component (GDD §15 mandate). Default tab: Command. _build_card + all build/
##   upgrade/sell handlers carried over verbatim from S29.2.

const ResourceBarScript = preload("res://scenes/components/ResourceBar.gd")

@onready var title_label = $Layout/HeaderRow/TitleLabel
@onready var back_button = $Layout/HeaderRow/BackButton
@onready var zones_box = $Layout/ScrollContainer/ZonesBox

const ZONE_COLORS = {
	"Command":          Color(0.2, 0.4, 0.6),
	"Engineering":      Color(0.4, 0.2, 0.6),
	"Simulation":       Color(0.2, 0.5, 0.4),
	"Commercial":       Color(0.5, 0.4, 0.1),
	"Human Performance":Color(0.5, 0.2, 0.2),
	"Test Tracks":      Color(0.2, 0.4, 0.2),
}

const BUILDING_ICONS = {
	"Headquarters":           "🏛",
	"Logistics Center":       "📦",
	"Garage":                 "🔧",
	"Racing Department":      "🏎",
	"R&D Design Studio":      "🔬",
	"CNC Parts Plant":        "⚙",
	"Ops Sim & Telemetry":    "📡",
	"Aerodynamic Wind Tunnel":"💨",
	"Vehicle Assembly Factory":"🏭",
	"Museum":                 "🏆",
	"Theme Park":             "🎡",
	"Public Racing Club":     "🏁",
	"Merchandise Store":      "👕",
	"Fitness Clinic":         "💪",
	"Pit Crew Arena":         "⏱",
	"Academy":                "🎓",
	"Karting Track":          "🔵",
	"Gravel Track":           "🟤",
	"Oval Track":             "🟡",
	"Race Track":             "🔴",
}

var _resource_bar  ## ResourceBar instance (untyped — loaded via preload, no class_name)
var _tab_row: HBoxContainer
var _zone_buttons: Dictionary = {}        ## zone_name -> Button
var _current_zone: String = "Command"


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var layout = $Layout
	layout.anchor_right = 1.0
	layout.anchor_bottom = 1.0
	layout.offset_left = 12
	layout.offset_top = 12
	layout.offset_right = -12
	layout.offset_bottom = -12
	layout.add_theme_constant_override("separation", 10)

	# Header
	title_label.text = "🏗 CAMPUS"
	title_label.add_theme_font_size_override("font_size", 44)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	back_button.text = "← Back to Hub"
	back_button.custom_minimum_size = Vector2(150, 36)
	back_button.pressed.connect(_on_back_pressed)

	# Resource bar (shared component) — inserted into the header row, right of the title.
	_resource_bar = ResourceBarScript.new()
	_resource_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$Layout/HeaderRow.add_child(_resource_bar)
	$Layout/HeaderRow.move_child(_resource_bar, 1)   ## title · bar · back

	# Zone tab row (built once)
	_tab_row = HBoxContainer.new()
	_tab_row.add_theme_constant_override("separation", 6)
	layout.add_child(_tab_row)
	layout.move_child(_tab_row, 2)                    ## header · separator · tabs · scroll
	_build_tabs()

	# ScrollContainer — expand both axes
	var scroll = $Layout/ScrollContainer
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	zones_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zones_box.add_theme_constant_override("separation", 14)

	## S37.34 — restore the zone tab the player was on when they entered a building.
	if GameState.pending_campus_zone != "" and GameState.campus_zones.has(GameState.pending_campus_zone):
		_current_zone = GameState.pending_campus_zone
	_show_zone(_current_zone)

## Builds one tab button per zone, tinted in the zone's colour. Active = full colour, inactive = dim.
func _build_tabs() -> void:
	for child in _tab_row.get_children():
		child.queue_free()
	_zone_buttons.clear()
	for zone_name in GameState.campus_zones:
		var btn = Button.new()
		var n_built := 0
		var n_total := 0
		for bid in GameState.campus_zones[zone_name]:
			n_total += 1
			var b = GameState.get_building(bid)
			if b and b.get("built", false):
				n_built += 1
		btn.text = "%s  (%d/%d)" % [zone_name, n_built, n_total]
		btn.add_theme_font_size_override("font_size", 24)
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_show_zone.bind(zone_name))
		_tab_row.add_child(btn)
		_zone_buttons[zone_name] = btn
	_style_tabs()

## Applies active/inactive zone-colour styling to the tab buttons.
func _style_tabs() -> void:
	for zone_name in _zone_buttons:
		var btn: Button = _zone_buttons[zone_name]
		var zc: Color = ZONE_COLORS.get(zone_name, Color(0.4, 0.4, 0.4))
		var active: bool = (zone_name == _current_zone)
		var sb := StyleBoxFlat.new()
		sb.bg_color = zc if active else zc.darkened(0.55)
		sb.set_corner_radius_all(6)
		sb.content_margin_top = 4; sb.content_margin_bottom = 4
		sb.content_margin_left = 8; sb.content_margin_right = 8
		if active:
			sb.set_border_width_all(2)
			sb.border_color = zc.lightened(0.4)
		btn.add_theme_stylebox_override("normal", sb)
		var hover := sb.duplicate()
		hover.bg_color = zc.lightened(0.1) if active else zc.darkened(0.35)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_color_override("font_color",
			Color.WHITE if active else Color(0.7, 0.7, 0.7))

func _build_campus() -> void:
	## Rebuild the CURRENT zone (used by build/upgrade/sell handlers after a state change).
	_build_tabs()
	if _resource_bar: _resource_bar.refresh()
	_show_zone(_current_zone)

## Shows only the selected zone's building cards; updates tab highlight.
func _show_zone(zone_name: String) -> void:
	_current_zone = zone_name
	GameState.pending_campus_zone = zone_name   ## S37.34 — remember for building Back-button return
	_style_tabs()
	for child in zones_box.get_children():
		child.queue_free()

	var buildings: Array = GameState.campus_zones.get(zone_name, [])
	var zone_color: Color = ZONE_COLORS.get(zone_name, Color(0.5, 0.5, 0.5))

	var header = Label.new()
	header.text = "━━━  %s  ━━━" % zone_name.to_upper()
	header.add_theme_font_size_override("font_size", 32)
	header.add_theme_color_override("font_color", zone_color)
	zones_box.add_child(header)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	zones_box.add_child(grid)

	for building_id in buildings:
		grid.add_child(_build_card(building_id))

func _build_card(building_id: String) -> PanelContainer:
	var building = GameState.get_building(building_id)
	var card = PanelContainer.new()
	## Uniform card size — fixed width AND height so all cards form a clean grid
	## regardless of how much text each building has. Content is top-aligned; the
	## action button(s) sit at the bottom via a spacer.
	card.custom_minimum_size = Vector2(0, 340)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.13, 0.16)
	card_style.set_corner_radius_all(8)
	card_style.set_border_width_all(1)
	card_style.border_color = Color(0.25, 0.27, 0.32)
	card_style.content_margin_left = 12; card_style.content_margin_right = 12
	card_style.content_margin_top = 10; card_style.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", card_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)

	# Building name row
	var name_row = HBoxContainer.new()
	vbox.add_child(name_row)

	var icon_label = Label.new()
	var icon = BUILDING_ICONS.get(building["name"], "🏢")
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 40)
	name_row.add_child(icon_label)

	var name_label = Label.new()
	name_label.text = " " + building["name"]
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)

	# Level / status
	var status_label = Label.new()
	if building["built"]:
		if building["construction_weeks_remaining"] > 0:
			status_label.text = "Level %d / %d  ·  🔨 Upgrading — %d wks" % [
				building["level"], building["max_level"],
				building["construction_weeks_remaining"]]
			status_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		else:
			status_label.text = "Level %d / %d" % [building["level"], building["max_level"]]
			status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		status_label.text = "Not Built"
		status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(status_label)

	# Effects — show for built buildings, or L1 preview for unbuilt.
	# Wrapped in a FIXED-HEIGHT scroll region so the variable amount of effect text
	# never changes the card's height — every card stays identical; long text scrolls.
	var effects_scroll = ScrollContainer.new()
	effects_scroll.custom_minimum_size = Vector2(0, 150)
	effects_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effects_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var effects_inner = VBoxContainer.new()
	effects_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effects_inner.add_theme_constant_override("separation", 4)
	effects_scroll.add_child(effects_inner)
	vbox.add_child(effects_scroll)

	if building["built"] and building["construction_weeks_remaining"] == 0:
		var effects_label = Label.new()
		effects_label.text = building["effects"]
		effects_label.add_theme_font_size_override("font_size", 22)
		effects_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effects_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		effects_inner.add_child(effects_label)
	elif not building["built"]:
		# Show what building provides at L1 once built
		var preview_label = Label.new()
		preview_label.text = "ℹ Once built (L1):\n%s" % building["effects"]
		preview_label.add_theme_font_size_override("font_size", 22)
		preview_label.add_theme_color_override("font_color", Color(0.5, 0.65, 0.5))
		preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		effects_inner.add_child(preview_label)
		# L1 upkeep/income preview
		var maint = building["weekly_maintenance"]
		var income = building["weekly_income"]
		var finance_preview = ""
		if maint > 0: finance_preview += "💸 -CR %d/wk" % maint
		if income > 0: finance_preview += "  💰 +CR %d/wk" % income
		if finance_preview != "":
			var fp_label = Label.new()
			fp_label.text = finance_preview
			fp_label.add_theme_font_size_override("font_size", 22)
			fp_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			effects_inner.add_child(fp_label)

	# Finance row — current level values for built buildings
	var finance_label = Label.new()
	var finance_text = ""
	if building["built"] and building["construction_weeks_remaining"] == 0:
		var cur_maint = GameState.get_building_maintenance(building)
		var cur_income = GameState.get_building_income(building)
		if cur_maint > 0:
			finance_text += "💸 -CR %d/wk" % cur_maint
		if cur_income > 0:
			finance_text += "  💰 +CR %d/wk" % cur_income
	if finance_text != "":
		finance_label.text = finance_text
		finance_label.add_theme_font_size_override("font_size", 22)
		effects_inner.add_child(finance_label)

	# Spacer — pushes the action button(s) to the bottom so all cards look uniform
	# even when a building has little descriptive text.
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Action button
	var action_btn = Button.new()
	action_btn.custom_minimum_size = Vector2(0, 38)
	action_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if not building["built"]:
		var can_afford = GameState.player_team.balance >= building["build_cost"]
		action_btn.text = "Build — $%d (%d wks)" % [building["build_cost"], building["build_time"]]
		action_btn.disabled = not can_afford
		action_btn.pressed.connect(_on_build_pressed.bind(building_id))

	elif building["construction_weeks_remaining"] > 0:
		action_btn.text = "Under Construction..."
		action_btn.disabled = true

	elif building["level"] >= building["max_level"]:
		action_btn.text = "✅ Max Level Reached"
		action_btn.disabled = true

	else:
		var scaled_cost = GameState.get_upgrade_cost(building)
		var scaled_time = GameState.get_upgrade_time(building)
		var can_afford = GameState.player_team.balance >= scaled_cost
		action_btn.text = "Upgrade to Lv%d — CR %s (%d wks)" % [
			building["level"] + 1,
			_fmt(scaled_cost),
			scaled_time
		]
		action_btn.disabled = not can_afford
		action_btn.pressed.connect(_on_upgrade_pressed.bind(building_id))

	vbox.add_child(action_btn)

	# Sell building — only for buildings the player paid to build (build_cost > 0)
	# Starter buildings (HQ, Logistics, Garage, Racing Dept) have build_cost 0 — not sellable
	if building["built"] and building["construction_weeks_remaining"] == 0 and building["build_cost"] > 0:
		var sell_value = int(building["build_cost"] * 0.3)
		var sell_btn = Button.new()
		sell_btn.text = "🏚 Sell  (+CR %s)" % _fmt(sell_value)
		sell_btn.custom_minimum_size = Vector2(180, 28)
		sell_btn.add_theme_font_size_override("font_size", 22)
		sell_btn.modulate = Color(1.0, 0.5, 0.4)
		sell_btn.pressed.connect(_on_sell_pressed.bind(building_id, sell_value))
		vbox.add_child(sell_btn)

	# Logistics Center — always accessible once built
	if building["name"] == "Logistics Center" and building["built"] and building["level"] >= 1:
		var open_btn = Button.new()
		open_btn.text = "📦 Enter Logistics Center"
		open_btn.custom_minimum_size = Vector2(0, 38)
		open_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		open_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/Logistics.tscn"))
		vbox.add_child(open_btn)

	# HQ — Enter building scene
	if building["name"] == "Headquarters" and building["built"] and building["level"] >= 1:
		var hq_btn = Button.new()
		hq_btn.text = "🏛 Enter HQ"
		hq_btn.custom_minimum_size = Vector2(0, 38)
		hq_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hq_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/HQ.tscn"))
		vbox.add_child(hq_btn)

	# Garage — Enter building scene
	if building["name"] == "Garage" and building["built"] and building["level"] >= 1:
		var garage_btn = Button.new()
		garage_btn.text = "🔧 Enter Garage"
		garage_btn.custom_minimum_size = Vector2(0, 38)
		garage_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		garage_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/Garage.tscn"))
		vbox.add_child(garage_btn)

	# Racing Department — Enter building scene
	if building["name"] == "Racing Department" and building["built"] and building["level"] >= 1:
		var rd_btn = Button.new()
		rd_btn.text = "🏎 Enter Racing Department"
		rd_btn.custom_minimum_size = Vector2(0, 38)
		rd_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rd_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/buildings/RacingDept.tscn"))
		vbox.add_child(rd_btn)

	# All remaining buildings with dedicated scenes
	const EXTRA_SCENES = {
		"Ops Sim & Telemetry":      ["📡 Enter Ops Sim",          "res://scenes/buildings/OpsSim.tscn"],
		"Pit Crew Arena":           ["⏱ Enter Pit Crew Arena",    "res://scenes/buildings/PitCrewArena.tscn"],
		"Museum":                   ["🏆 Enter Museum",            "res://scenes/buildings/Museum.tscn"],
		"Theme Park":               ["🎡 Enter Theme Park",        "res://scenes/buildings/ThemePark.tscn"],
		"Public Racing Club":       ["🏁 Enter Racing Club",       "res://scenes/buildings/PublicRacingClub.tscn"],
		"Merchandise Store":        ["👕 Enter Merchandise Store", "res://scenes/buildings/MerchandiseStore.tscn"],
		"Fitness Clinic":           ["💪 Enter Fitness Clinic",    "res://scenes/buildings/FitnessClinic.tscn"],
		"Academy":                  ["🎓 Enter Academy",           "res://scenes/buildings/Academy.tscn"],
		"R&D Design Studio":        ["🔬 Enter R&D Studio",        "res://scenes/buildings/RnDStudio.tscn"],
		"CNC Parts Plant":          ["⚙ Enter CNC Plant",         "res://scenes/buildings/CNCPlant.tscn"],
		"Aerodynamic Wind Tunnel":  ["💨 Enter Wind Tunnel",       "res://scenes/buildings/AeroWindTunnel.tscn"],
		"Vehicle Assembly Factory": ["🏭 Enter Vehicle Factory",   "res://scenes/buildings/VehicleFactory.tscn"],
		"Karting Track":            ["🔵 Enter Karting Track",     "res://scenes/buildings/KartingTrack.tscn"],
		"Gravel Track":             ["🟤 Enter Gravel Track",      "res://scenes/buildings/GravelTrack.tscn"],
		"Oval Track":               ["🟡 Enter Oval Track",        "res://scenes/buildings/OvalTrack.tscn"],
		"Race Track":               ["🔴 Enter Race Track",        "res://scenes/buildings/RaceTrack.tscn"],
	}
	var bname = building["name"]
	if bname in EXTRA_SCENES and building["built"] and building["level"] >= 1:
		var info = EXTRA_SCENES[bname]
		var enter_btn = Button.new()
		enter_btn.text = info[0]
		enter_btn.custom_minimum_size = Vector2(0, 38)
		enter_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var scene_path = info[1]
		enter_btn.pressed.connect(func(): get_tree().change_scene_to_file(scene_path))
		vbox.add_child(enter_btn)

	return card

func _on_build_pressed(building_id: String) -> void:
	GameState.start_building(building_id)
	_build_campus()

func _on_upgrade_pressed(building_id: String) -> void:
	GameState.start_upgrade(building_id)
	_build_campus()

func _on_sell_pressed(building_id: String, sell_value: int) -> void:
	var building = GameState.campus_buildings.get(building_id, {})
	if building.is_empty():
		return
	GameState.sell_building(building_id)
	_build_campus()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainHub.tscn")

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

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			var screenshot = get_viewport().get_texture().get_image()
			var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
			var path = "user://screenshot_%s.png" % timestamp
			screenshot.save_png(path)
			print("Screenshot saved: " + path)
