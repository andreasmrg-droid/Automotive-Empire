# GameState.gd — Calendar wiring patch (S37.26)

Apply these 6 small edits to `autoloads/GameState.gd`. Each shows an anchor line from the
current file and what to add. **Bump the GameState.gd version header to S37.26** with a note like:
`## Version: S37.26 — Calendar: race_calendar.json loader + custom_calendar_events store (save/load).`

---

## 1. New state vars

Anchor — near the other persistent collections (e.g. just after line ~862 `var cnc_production_queue: Array = []`),
add:

```gdscript
## ── Season Calendar (S37.26) ─────────────────────────────────────────────────────
## race_calendar_data: loaded once from res://data/race_calendar.json (static schedule for all
##   21 championships — week/round/city/track/laps/flags). Read-only at runtime.
## custom_calendar_events: the ONLY persisted calendar state. Player-created reminders.
##   Each entry: { "week": int, "title": String, "note": String }.
var race_calendar_data: Dictionary = {}
var custom_calendar_events: Array = []
var _calendar_manager = null   ## CalendarManager (untyped — avoids global-class parse-order error)
```

---

## 2. JSON loader function

Add this function anywhere in the file (e.g. near the other data loaders):

```gdscript
## Loads the static race calendar (all championships' schedules) from the data JSON.
## Called once at engine init. Safe no-op if the file is missing (calendar just shows
## no races until the file is present).
func _load_race_calendar() -> void:
	var path := "res://data/race_calendar.json"
	if not FileAccess.file_exists(path):
		push_warning("race_calendar.json not found at %s — calendar races will be empty." % path)
		return
	var txt := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		race_calendar_data = parsed
	else:
		push_warning("race_calendar.json did not parse to a Dictionary.")
```

---

## 3. Instantiate the manager + load the JSON

Anchor — the engine-instantiation block (line ~1545, after `_campus_manager = CampusManager.new(self)`):

```gdscript
	_campus_manager = CampusManager.new(self)
	_sponsor_manager = SponsorManager.new(self)
	_staff_manager = StaffManager.new(self)
	_car_manager = CarManager.new(self)
	_calendar_manager = _CalendarManagerScript.new(self)   ## S37.26 (see accessor below for const)
	_load_race_calendar()                                  ## S37.26
```

(If the four `*_manager` lines are followed by other init, just insert the two S37.26 lines after
the `CarManager.new` line — order doesn't matter as long as it's after this point.)

Add a public accessor (mirrors how other engines are exposed). Note it instantiates via
`preload` rather than the bare `CalendarManager.new()`, so it does not depend on the global
`class_name` being registered at parse time:

```gdscript
## S37.26 — cached CalendarManager. preload avoids the global-class parse-order error
## ("Could not find type CalendarManager") some scripts hit when referencing the class_name.
const _CalendarManagerScript = preload("res://resources/scripts/CalendarManager.gd")

func get_calendar_manager():
	if _calendar_manager == null:
		_calendar_manager = _CalendarManagerScript.new(self)
	return _calendar_manager
```

---

## 4. Save — persist custom events

Anchor — in `save_game()`'s `save_data` dict (line ~3716, next to `"custom_todo_items": custom_todo_items,`):

```gdscript
		"custom_todo_items":         custom_todo_items,
		"custom_calendar_events":    custom_calendar_events,   ## S37.26
```

(Do NOT save `race_calendar_data` — it's static, reloaded from JSON on every launch.)

---

## 5. Load — restore custom events

Anchor — in `load_game()` near line ~3860 (`if "custom_todo_items" in data: custom_todo_items = data["custom_todo_items"]`):

```gdscript
	if "custom_todo_items" in data: custom_todo_items = data["custom_todo_items"]
	if "custom_calendar_events" in data: custom_calendar_events = data["custom_calendar_events"]   ## S37.26
```

---

## 6. New-game reset — clear custom events

Anchor — in `setup_new_game()` reset block (line ~3018, near `custom_todo_items = []`):

```gdscript
	custom_todo_items    = []
	custom_calendar_events = []   ## S37.26
```

(`race_calendar_data` is loaded at init and stays valid across new games — no reset needed.)

---

## Deployment note

Place `race_calendar.json` at `res://data/race_calendar.json` (create the `data/` folder if absent).
`CalendarManager.gd` goes in `res://resources/scripts/` alongside the other engine classes — it has
`class_name CalendarManager`, so once it's in the project Godot will resolve the type used above.
