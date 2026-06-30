## Version: S39.4 — ShareLines: a lightweight multi-line chart Control for the Commercial Department
##   detail panel. Plots each brand's market-share evolution over the recorded seasons (the engine
##   samples once per season; see CommercialMarketSim._history). Pure _draw() — Godot has no chart lib.
##   set_series([{name, color, points:[float 0..1]}], labels) then it renders axes, gridlines and lines.
##   Colours are passed in by the caller so they MATCH the pie slices for the same segment.
extends Control

## series: Array of { "name": String, "color": Color, "points": Array[float] (0..1) }
var series: Array = []
var labels: Array = []          ## x-axis labels (one per point), e.g. ["S1","S2",…]
const PAD_L := 44.0
const PAD_R := 12.0
const PAD_T := 12.0
const PAD_B := 26.0

func set_series(s: Array, x_labels: Array = []) -> void:
	series = s
	labels = x_labels
	queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var sz = size
	if sz.x < 40.0 or sz.y < 40.0:
		return
	var x0 = PAD_L
	var x1 = sz.x - PAD_R
	var y0 = PAD_T
	var y1 = sz.y - PAD_B
	var plot_w = x1 - x0
	var plot_h = y1 - y0
	if plot_w <= 0.0 or plot_h <= 0.0:
		return

	var grid_col := Color(0.30, 0.30, 0.36)
	var axis_col := Color(0.45, 0.45, 0.52)
	var font := ThemeDB.fallback_font
	var fs := 13

	# Determine the y-scale: round the max share up to a sensible ceiling (min 20%).
	var ymax := 0.20
	for s in series:
		for v in s.get("points", []):
			ymax = max(ymax, float(v))
	ymax = min(1.0, ceil(ymax / 0.1) * 0.1)   # round up to nearest 10%, cap at 100%

	# Horizontal gridlines + y labels (0, 25%, 50%… up to ymax in 4 bands).
	var bands := 4
	for i in range(bands + 1):
		var frac = float(i) / bands
		var y = y1 - frac * plot_h
		draw_line(Vector2(x0, y), Vector2(x1, y), grid_col, 1.0)
		var pct = int(round(frac * ymax * 100.0))
		draw_string(font, Vector2(2, y + 4), "%d%%" % pct, HORIZONTAL_ALIGNMENT_LEFT, PAD_L - 4, fs, axis_col)

	# X axis baseline.
	draw_line(Vector2(x0, y1), Vector2(x1, y1), axis_col, 1.0)

	# Need at least 2 points to draw a line; with 1 point, draw a dot per series.
	var n := 0
	for s in series:
		n = max(n, s.get("points", []).size())
	if n == 0:
		return

	# X positions.
	var xstep := 0.0
	if n > 1:
		xstep = plot_w / float(n - 1)

	# X labels (sparse: first, middle, last to avoid clutter).
	if labels.size() == n and n > 0:
		var idxs := [0]
		if n > 2: idxs.append(int(n / 2))
		if n > 1: idxs.append(n - 1)
		for li in idxs:
			var lx = x0 + (xstep * li if n > 1 else plot_w * 0.5)
			draw_string(font, Vector2(lx - 12, y1 + 18), str(labels[li]),
				HORIZONTAL_ALIGNMENT_LEFT, 60, fs, axis_col)

	# Plot each series.
	for s in series:
		var pts: Array = s.get("points", [])
		var col: Color = s.get("color", Color.WHITE)
		if pts.size() == 1:
			var px = x0 + plot_w * 0.5
			var py = y1 - (clamp(float(pts[0]) / ymax, 0.0, 1.0)) * plot_h
			draw_circle(Vector2(px, py), 3.0, col)
			continue
		var line := PackedVector2Array()
		for i in range(pts.size()):
			var px2 = x0 + xstep * i
			var py2 = y1 - (clamp(float(pts[i]) / ymax, 0.0, 1.0)) * plot_h
			line.append(Vector2(px2, py2))
		draw_polyline(line, col, 2.0, true)
		# End-point marker.
		if line.size() > 0:
			draw_circle(line[line.size() - 1], 3.0, col)
