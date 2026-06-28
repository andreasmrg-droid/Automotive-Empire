extends PanelContainer
## Version: S37.30 — NEW. Reusable resource bar component (single source of truth for the
##   mandatory CR/RP/SP/FU bar — GDD §15). Loaded via preload (no `class_name`, to avoid the
##   global-class / preload resolution conflict). Replaces per-scene hand-written bars.
##
## USAGE (any scene) — instantiate the SCRIPT directly (no .tscn needed; the script builds its
## own children in code, so this avoids any scene-root type mismatch):
##   const ResourceBarScript = preload("res://scenes/components/ResourceBar.gd")
##   var bar = ResourceBarScript.new()
##   some_container.add_child(bar)      ## _ready() builds + refreshes automatically
##   bar.refresh()                      ## call again whenever resources change
##
## Self-contained: reads GameState directly, null-guards an absent player_team (so it renders
## even in editor-direct scene runs), and applies the same warning colors as the Main Hub.

var _cr: Label
var _rp: Label
var _sp: Label
var _fu: Label


func _ready() -> void:
	if _cr == null:
		_build()
	refresh()


func _build() -> void:
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 24)
	add_child(hb)
	_cr = _make_label(Color(0.4, 0.9, 0.4)); hb.add_child(_cr)
	_rp = _make_label(Color(0.5, 0.7, 1.0)); hb.add_child(_rp)
	_sp = _make_label(Color(1.0, 0.8, 0.4)); hb.add_child(_sp)
	_fu = _make_label(Color(1.0, 0.5, 0.3)); hb.add_child(_fu)


func _make_label(color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", color)
	l.custom_minimum_size = Vector2(110, 0)
	return l


## Re-reads GameState and updates every value + warning color. Call after any resource change.
func refresh() -> void:
	if _cr == null:
		_build()
	var balance: float = GameState.player_team.balance if GameState.player_team != null else 0.0
	_cr.text = "💰 CR  %s" % _format_number(balance)
	_cr.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if balance >= 0 else Color(1.0, 0.3, 0.3))
	_rp.text = "🔬 RP  %.0f" % GameState.research_points
	_sp.text = "🔧 SP  %d" % GameState.spare_parts
	_fu.text = "⛽ FU  %.0f kg" % GameState.fuel_kg

	# Warning colors — worst-case need across the player's championships (shared pool).
	var sp_threshold := 0
	var fu_threshold := 0.0
	if GameState.has_method("get_player_championships"):
		for champ in GameState.get_player_championships():
			sp_threshold = max(sp_threshold, champ.sp_per_10_pct_damage)
			fu_threshold = max(fu_threshold, champ.fuel_per_car_per_race)
	if sp_threshold == 0: sp_threshold = 120
	if fu_threshold == 0.0: fu_threshold = 15.0
	_sp.add_theme_color_override("font_color",
		Color(1.0, 0.3, 0.3) if GameState.spare_parts < sp_threshold else Color(1.0, 0.8, 0.4))
	_fu.add_theme_color_override("font_color",
		Color(1.0, 0.3, 0.3) if GameState.fuel_kg < fu_threshold else Color(1.0, 0.5, 0.3))


func _format_number(n: float) -> String:
	if abs(n) >= 1000000:
		return "%.1fM" % (n / 1000000.0)
	elif abs(n) >= 1000:
		return "%.1fK" % (n / 1000.0)
	else:
		return "%.0f" % n
