extends RefCounted
## Version: S37.26 — NEW. Season-calendar aggregation engine.
##   NOTE: no `class_name` — this engine is loaded via preload("res://resources/scripts/
##   CalendarManager.gd") from GameState (get_calendar_manager) and Calendar.gd, which avoids
##   global-class parse-order issues. Do not re-add class_name or it double-registers.
##   Pure, headless-testable RefCounted (no scene deps). Aggregates every DATED thing in the
##   game world into a single week-indexed event model the Calendar scene renders:
##     • RACES            — from race_calendar.json (loaded into GameState.race_calendar_data).
##                          Chip text: "Championship | Round X/N | City". A "mine" flag marks
##                          championships the player is registered in this season.
##     • REG. DEADLINES   — GameState.get_entry_deadline_week(champ_id) for every championship.
##     • BUILDING DONE    — campus_buildings[*].construction_weeks_remaining > 0
##                          → completion week = current_week + weeks_remaining.
##     • R&D DONE         — active_rnd_tasks[*].weeks_remaining → completion week.
##     • CNC DONE         — cnc_production_queue[*].weeks_remaining → completion week (slot-aware
##                          ordering is the engine's concern; here we read the per-job remaining).
##     • CUSTOM           — GameState.custom_calendar_events (the ONLY persisted state this
##                          feature adds; everything else is derived live, so it's never stale).
##
## DESIGN: auto-events are recomputed on every call (always correct, nothing to keep in sync).
## Only custom events are stored. This mirrors the news-system philosophy: one function over
## data that already exists.
##
## Event dict shape (one entry per dated thing):
##   {
##     "week":      int,            ## 1..52
##     "type":      String,         ## "race_mine" | "race_other" | "deadline" | "building"
##                                  ##   | "rnd" | "cnc" | "custom"
##     "title":     String,         ## primary line, e.g. "GP4 · Round 1/6"
##     "subtitle":  String,         ## secondary line, e.g. "Brands Hatch" (city) — may be ""
##     "tooltip":   String,         ## full hover text
##     "champ_id":  String,         ## "" when not championship-scoped
##     "source":    String,         ## stable id for custom-event removal ("custom:<idx>") else ""
##   }

const TYPE_RACE_MINE  := "race_mine"
const TYPE_RACE_OTHER := "race_other"
const TYPE_DEADLINE   := "deadline"
const TYPE_BUILDING   := "building"
const TYPE_RND        := "rnd"
const TYPE_CNC        := "cnc"
const TYPE_CUSTOM     := "custom"

var gs   ## GameState (autoload) — injected, not hard-referenced, so the class stays headless-testable.

func _init(game_state) -> void:
	gs = game_state

## ── Public API ──────────────────────────────────────────────────────────────────

## All events for the whole season, grouped by week: { week:int -> Array[event] }.
## Weeks with no events are simply absent from the dictionary (caller fills the grid 1..52).
func get_events_by_week() -> Dictionary:
	var by_week: Dictionary = {}
	for ev in get_all_events():
		var w: int = ev["week"]
		if not by_week.has(w):
			by_week[w] = []
		by_week[w].append(ev)
	return by_week

## Flat list of every event in the season (unordered). Caller groups/sorts as needed.
func get_all_events() -> Array:
	var out: Array = []
	out.append_array(_race_events())
	out.append_array(_deadline_events())
	out.append_array(_building_events())
	out.append_array(_rnd_events())
	out.append_array(_cnc_events())
	out.append_array(_custom_events())
	return out

## Events for a single week (used by the Main Hub "weeks ahead" strip).
func get_events_for_week(week: int) -> Array:
	var out: Array = []
	for ev in get_all_events():
		if ev["week"] == week:
			out.append(ev)
	return out

## ── Custom event mutators (write to GameState; the only persisted state) ─────────

## Adds a custom reminder. Returns the new event's index in custom_calendar_events.
func add_custom_event(week: int, title: String, note: String = "") -> int:
	var w := clampi(week, 1, gs.max_weeks)
	var clean_title := title.strip_edges()
	if clean_title == "":
		clean_title = "Reminder"
	gs.custom_calendar_events.append({
		"week":  w,
		"title": clean_title,
		"note":  note.strip_edges(),
	})
	return gs.custom_calendar_events.size() - 1

## Removes a custom event by its index in custom_calendar_events. Safe on bad index.
func remove_custom_event(index: int) -> void:
	if index >= 0 and index < gs.custom_calendar_events.size():
		gs.custom_calendar_events.remove_at(index)

## ── Builders (one per source) ────────────────────────────────────────────────────

func _race_events() -> Array:
	var out: Array = []
	var data: Dictionary = gs.race_calendar_data
	if data.is_empty():
		return out
	var champs: Dictionary = data.get("championships", {})
	var registered: Array = gs.player_registered_championships
	for cid in champs:
		var champ: Dictionary = champs[cid]
		var champ_name: String = champ.get("name", cid)
		var rounds: Array = champ.get("rounds", [])
		var total: int = rounds.size()
		var is_mine: bool = registered.has(cid)
		for rd in rounds:
			var rnum: int = int(rd.get("round", 0))
			var city: String = rd.get("city", "")
			out.append({
				"week":     int(rd.get("week", 0)),
				"type":     TYPE_RACE_MINE if is_mine else TYPE_RACE_OTHER,
				"title":    "%s · Round %d/%d" % [champ_name, rnum, total],
				"subtitle": city,
				"tooltip":  "%s — Round %d of %d, %s%s" % [
								champ_name, rnum, total, city,
								"  (you race here)" if is_mine else ""],
				"champ_id": cid,
				"source":   "",
			})
	return out

func _deadline_events() -> Array:
	var out: Array = []
	var data: Dictionary = gs.race_calendar_data
	if data.is_empty():
		return out
	var champs: Dictionary = data.get("championships", {})
	for cid in champs:
		var champ: Dictionary = champs[cid]
		var champ_name: String = champ.get("name", cid)
		var dl: int = gs.get_entry_deadline_week(cid)
		if dl < 1 or dl > gs.max_weeks:
			continue
		out.append({
			"week":     dl,
			"type":     TYPE_DEADLINE,
			"title":    "%s · registration deadline" % champ_name,
			"subtitle": "",
			"tooltip":  "Last week to register for %s before next season." % champ_name,
			"champ_id": cid,
			"source":   "",
		})
	return out

func _building_events() -> Array:
	var out: Array = []
	for bid in gs.campus_buildings:
		var b: Dictionary = gs.campus_buildings[bid]
		var remaining: int = int(b.get("construction_weeks_remaining", 0))
		if remaining <= 0:
			continue
		var week: int = gs.current_week + remaining
		if week > gs.max_weeks:
			continue
		var bname: String = b.get("name", bid)
		var target_level: int = int(b.get("level", 0)) + 1
		out.append({
			"week":     week,
			"type":     TYPE_BUILDING,
			"title":    "%s · build complete" % bname,
			"subtitle": "Level %d ready" % target_level,
			"tooltip":  "%s finishes construction/upgrade (Level %d) this week." % [bname, target_level],
			"champ_id": "",
			"source":   "",
		})
	return out

func _rnd_events() -> Array:
	var out: Array = []
	for task in gs.active_rnd_tasks:
		var remaining: int = int(task.get("weeks_remaining", 0))
		if remaining <= 0:
			continue
		var week: int = gs.current_week + remaining
		if week > gs.max_weeks:
			continue
		var tname: String = task.get("name", "R&D project")
		out.append({
			"week":     week,
			"type":     TYPE_RND,
			"title":    "R&D complete",
			"subtitle": tname,
			"tooltip":  "R&D project completes this week: %s" % tname,
			"champ_id": task.get("championship_id", ""),
			"source":   "",
		})
	return out

func _cnc_events() -> Array:
	var out: Array = []
	for job in gs.cnc_production_queue:
		var remaining: int = int(job.get("weeks_remaining", 0))
		if remaining <= 0:
			continue
		var week: int = gs.current_week + remaining
		if week > gs.max_weeks:
			continue
		var part: String = job.get("part", "Part")
		var qty: int = int(job.get("quantity", 1))
		var label := part if qty <= 1 else "%s ×%d" % [part, qty]
		out.append({
			"week":     week,
			"type":     TYPE_CNC,
			"title":    "CNC delivery",
			"subtitle": label,
			"tooltip":  "Manufacturing job delivers this week: %s" % label,
			"champ_id": job.get("championship_id", ""),
			"source":   "",
		})
	return out

func _custom_events() -> Array:
	var out: Array = []
	var list: Array = gs.custom_calendar_events
	for i in range(list.size()):
		var e: Dictionary = list[i]
		var note: String = e.get("note", "")
		out.append({
			"week":     int(e.get("week", gs.current_week)),
			"type":     TYPE_CUSTOM,
			"title":    e.get("title", "Reminder"),
			"subtitle": note,
			"tooltip":  e.get("title", "Reminder") + ("\n" + note if note != "" else ""),
			"champ_id": "",
			"source":   "custom:%d" % i,
		})
	return out
