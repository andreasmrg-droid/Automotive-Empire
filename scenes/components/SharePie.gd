## Version: S39.3 — SharePie: a lightweight donut/pie chart Control for the Commercial Department
##   market view. Draws filled arcs from a share table ([{name, share, is_player, is_giant}] + Others),
##   with consistent colours: player = green, giants = gold, Others = dim grey, AI = a rotating palette.
##   Pure _draw() (Godot has no chart lib). Set `data` then call queue_redraw(); size via custom_minimum_size.
extends Control

## Share rows: Array of { "name": String, "share": float (0..1), "is_player": bool, "is_giant": bool }.
var data: Array = []
var inner_ratio: float = 0.55   ## donut hole as a fraction of radius (0 = full pie)

const PLAYER_COL := Color(0.35, 0.92, 0.46)
const GIANT_COL  := Color(0.85, 0.72, 0.42)
const OTHERS_COL := Color(0.34, 0.34, 0.40)
## Rotating palette for ordinary AI producers (distinct, readable on dark bg).
const AI_PALETTE := [
	Color(0.40, 0.62, 0.95), Color(0.78, 0.52, 0.92), Color(0.95, 0.55, 0.45),
	Color(0.45, 0.80, 0.82), Color(0.90, 0.78, 0.42), Color(0.62, 0.70, 0.95),
	Color(0.85, 0.58, 0.70),
]

func set_data(rows: Array) -> void:
	data = rows
	queue_redraw()

func _ready() -> void:
	## The control's real size arrives from layout after set_data may have been called, so redraw on
	## resize to guarantee the pie paints at the correct dimensions.
	resized.connect(queue_redraw)

func _draw() -> void:
	if data.is_empty():
		return
	var sz = size
	var radius = min(sz.x, sz.y) * 0.5 - 2.0
	if radius <= 2.0:
		return
	var center = sz * 0.5
	var inner = radius * inner_ratio

	# Normalise (shares may not sum to exactly 1 due to rounding) so the pie always closes.
	var total := 0.0
	for r in data:
		total += max(0.0, float(r.get("share", 0.0)))
	if total <= 0.0:
		return

	var ai_idx := 0
	var ang := -PI / 2.0   # start at 12 o'clock
	for r in data:
		var frac = max(0.0, float(r.get("share", 0.0))) / total
		if frac <= 0.0:
			continue
		var sweep = frac * TAU
		var col: Color
		if r.get("is_player", false):
			col = PLAYER_COL
		elif r.get("is_giant", false):
			col = GIANT_COL
		elif r.get("name", "") == "Others":
			col = OTHERS_COL
		else:
			col = AI_PALETTE[ai_idx % AI_PALETTE.size()]
			ai_idx += 1
		_draw_donut_segment(center, inner, radius, ang, ang + sweep, col,
			r.get("is_player", false))
		ang += sweep

func _draw_donut_segment(center: Vector2, inner: float, outer: float,
		a0: float, a1: float, col: Color, emphasise: bool) -> void:
	## Build a ring-segment polygon (outer arc forward, inner arc back) and fill it.
	var steps = max(2, int((a1 - a0) / 0.12))
	var pts := PackedVector2Array()
	for i in range(steps + 1):
		var t = a0 + (a1 - a0) * (float(i) / steps)
		pts.append(center + Vector2(cos(t), sin(t)) * outer)
	for i in range(steps, -1, -1):
		var t = a0 + (a1 - a0) * (float(i) / steps)
		pts.append(center + Vector2(cos(t), sin(t)) * inner)
	draw_colored_polygon(pts, col)
	# Player slice gets a bright outline so it pops.
	if emphasise:
		var edge := PackedVector2Array()
		for i in range(steps + 1):
			var t = a0 + (a1 - a0) * (float(i) / steps)
			edge.append(center + Vector2(cos(t), sin(t)) * outer)
		draw_polyline(edge, Color(0.85, 1.0, 0.88), 2.0, true)
