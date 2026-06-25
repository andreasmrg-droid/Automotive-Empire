## Version: S37.25 — popup-position: contract card CENTERED (symmetric ±320, was -250..0 off-centre).
extends Control
## Version: S37.10 — Column alignment: the live weekly salary read-out now sits AFTER the LOCK
##   column (both approach + legacy paths) so TERM/ASK/OFFER/LOCK align across all rows; TERM
##   widened to 230, ASK to 110, header widths matched, card 560→640. Pure layout.
## Version: S37.9 — Bug #8: SALARY is now negotiated as an ANNUAL figure with a live weekly
##   read-out. The engine + save format still store weekly_salary (unchanged); this is a pure
##   UI transform — the salary spinbox shows/edits annual (= weekly × WEEKS_PER_SEASON), a live
##   "≈ CR N/wk" caption updates as you type, and on submit the annual value is divided back to
##   weekly before it reaches the contract engine. Applies to driver + staff in both the approach
##   path (_build_approach_field_row) and the legacy path (_build_field_row).
## Version: S35.7 — Close button is now a pure no-op (closes the window, leaves the negotiation
##   untouched in HQ Pending Activity); previously it cancelled a Round-1 approach. Walk Away leaves
##   a visible "you have walked away" entry that persists until the next week advance.
## Version: S33.2 — staff negotiations now include the start_date (Immediate/Next Season)
##   dropdown, same as drivers (FIELD_ORDER_STAFF). Prior: S29.2 — Font sizes scaled ×2.0 from original (large readability pass).
##   Supersedes the ×1.3 attempt; all add_theme_font_size_override values ×2, hierarchy kept.
## Version: S29.0 — Open/close lag fix (issue 2): removed all four
##   `await get_tree().process_frame` stalls; replaced with synchronous _clear_content()
##   so the panel renders in the same frame it opens.
## --- S22.7 — Sponsor negotiation handles "waiting" and "counter" states.
##                    _show_waiting_for_reply() shown after offer submitted.
##                    Player must advance week to see counter-offer.

signal closed

var _neg: Dictionary = {}       ## legacy instant negotiation
var _ap:  Dictionary = {}       ## approach-based weekly negotiation
var _fields: Dictionary = {}    ## key → SpinBox
var _lock_btns: Dictionary = {} ## key → Button
var _content: VBoxContainer
var _is_approach: bool = false

const FIELD_LABELS = {
	"weekly_salary":       "Annual Salary (CR)",
	"win_bonus":           "Win Bonus (CR)",
	"podium_bonus":        "Podium Bonus (CR)",
	"championship_bonus":  "Championship Bonus (CR)",
	"performance_bonus":   "Performance Bonus (CR)",
	"release_clause":      "Release Clause (CR)",
	"duration_seasons":    "Duration (seasons)",
	"weekly_payment":      "Weekly Payment (CR)",
	"season_bonus":        "Season Bonus (CR)",
	"commitment_total":    "Commitment Total (CR)",
	"seasons_remaining":   "Seasons",
	"start_date":          "Start Date",
}

## S37.9 — Salary is stored weekly but negotiated annually. One season = 52 weeks.
## Only weekly_salary uses this transform; weekly_payment (sponsors) stays weekly.
const WEEKS_PER_SEASON := 52

const FIELD_ORDER_DRIVER = [
	"weekly_salary","duration_seasons","win_bonus","podium_bonus","championship_bonus","release_clause","start_date"
]
const FIELD_ORDER_STAFF = [
	"weekly_salary","duration_seasons","championship_bonus","performance_bonus","release_clause","start_date"
	## start_date enabled (S33.2): staff can be signed Immediate or Next Season, same as drivers.
]
const FIELD_ORDER_SPONSOR_1 = ["weekly_payment","seasons_remaining"]
const FIELD_ORDER_SPONSOR_2 = ["win_bonus","podium_bonus","season_bonus","seasons_remaining"]
const FIELD_ORDER_SPONSOR_3 = ["commitment_total","seasons_remaining"]

func _ready() -> void:
	## Full-screen dim overlay
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	## Centered card
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(640, 0)
	## Centered: symmetric ±320 offsets around screen center (was -250..0, off-centre + narrower
	## than its 640 min-width). Vertically centered too.
	card.set_anchor(SIDE_LEFT,   0.5)
	card.set_anchor(SIDE_RIGHT,  0.5)
	card.set_anchor(SIDE_TOP,    0.5)
	card.set_anchor(SIDE_BOTTOM, 0.5)
	card.offset_left   = -320
	card.offset_right  = 320
	card.offset_top    = -300
	card.offset_bottom = 300
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.17)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.30, 0.38, 0.52)
	style.corner_radius_top_left = 8; style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	style.content_margin_left = 24; style.content_margin_right = 24
	style.content_margin_top = 20; style.content_margin_bottom = 20
	card.add_theme_stylebox_override("panel", style)
	add_child(card)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	card.add_child(_content)


func open(neg: Dictionary) -> void:
	_neg = neg
	_is_approach = false
	_rebuild()

## Open for a weekly approach-based negotiation (with per-item locks).
func open_approach(ap: Dictionary) -> void:
	_ap = ap
	_is_approach = true
	_rebuild_approach()

## S29.0 — Clear all content children synchronously (no frame stall).
## Detaches immediately so new children never coexist with freeing old ones.
func _clear_content() -> void:
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()

func _rebuild_approach() -> void:
	_clear_content()
	_fields = {}
	_lock_btns = {}

	## Header
	var lbl_title = Label.new()
	lbl_title.text = "📋  CONTRACT NEGOTIATION"
	lbl_title.add_theme_font_size_override("font_size", 40)
	lbl_title.add_theme_color_override("font_color", Color.WHITE)
	_content.add_child(lbl_title)

	var lbl_name = Label.new()
	lbl_name.text = _ap.get("subject_name", "")
	lbl_name.add_theme_font_size_override("font_size", 28)
	lbl_name.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	_content.add_child(lbl_name)

	## Round + bond info
	var meta_row = HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 12)
	_content.add_child(meta_row)

	var lbl_round = Label.new()
	lbl_round.text = "Round %d of %d" % [_ap.get("contract_round", 1), _ap.get("max_contract_rounds", 4)]
	lbl_round.add_theme_font_size_override("font_size", 24)
	lbl_round.modulate = Color(0.6, 0.6, 0.6)
	meta_row.add_child(lbl_round)

	if _ap.get("bond_amount_final", 0) > 0:
		var lbl_bond = Label.new()
		lbl_bond.text = "💰 Bond paid: CR %s" % _fmt(int(_ap["bond_amount_final"]))
		lbl_bond.add_theme_font_size_override("font_size", 22)
		lbl_bond.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
		meta_row.add_child(lbl_bond)

	if _ap.get("current_team_name", "") != "":
		var lbl_team = Label.new()
		lbl_team.text = "From: %s" % _ap["current_team_name"]
		lbl_team.add_theme_font_size_override("font_size", 22)
		lbl_team.modulate = Color(0.5, 0.5, 0.5)
		meta_row.add_child(lbl_team)

	_content.add_child(HSeparator.new())

	## Column headers and field order based on subject type
	var subject_type = _ap.get("subject_type", "driver")
	var is_driver = subject_type == "driver"
	var is_sponsor = subject_type == "sponsor"

	if is_driver:
		_content.add_child(_make_four_col("TERM", "THEIR ASK", "YOUR OFFER", "LOCK", true))
	else:
		_content.add_child(_make_four_col("TERM", "THEIR ASK", "YOUR OFFER", "LOCK", true))

	## Field order
	var field_order: Array
	if is_driver:
		field_order = FIELD_ORDER_DRIVER
	elif is_sponsor:
		var sp_type = _ap.get("sponsor_type", 1)
		match sp_type:
			1: field_order = FIELD_ORDER_SPONSOR_1
			2: field_order = FIELD_ORDER_SPONSOR_2
			3: field_order = FIELD_ORDER_SPONSOR_3
			_: field_order = FIELD_ORDER_SPONSOR_1
	else:
		field_order = FIELD_ORDER_STAFF

	var terms = _ap.get("terms", {})
	for key in field_order:
		if key not in terms: continue
		var term = terms[key]
		_content.add_child(_build_approach_field_row(key, term, true))

	_content.add_child(HSeparator.new())

	## Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	_content.add_child(btn_row)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var btn_submit = _action_btn("Submit Offer →", Color(0.15, 0.50, 0.20))
	btn_submit.pressed.connect(_on_submit_approach)
	btn_row.add_child(btn_submit)

	var btn_accept = _action_btn("Accept Their Terms", Color(0.12, 0.35, 0.55))
	btn_accept.pressed.connect(func():
		GameState.accept_approach_terms(_ap["neg_id"])
		_show_result("✅ Deal Agreed!", "Contract signed.", Color(0.3, 0.9, 0.4)))
	btn_row.add_child(btn_accept)

	var btn_close = _action_btn("Close ✕", Color(0.25, 0.25, 0.30))
	btn_close.tooltip_text = "Close this window. The negotiation stays open and unchanged."
	btn_close.pressed.connect(func():
		## S35.7: Close means CLOSE — it must not alter the negotiation. The entry stays in HQ
		## Pending Activity exactly as it was. (Previously called cancel_approach_before_submit,
		## which deleted a Round-1 approach on close — wrong: that's Walk Away's job.)
		queue_free()
		emit_signal("closed"))
	btn_row.add_child(btn_close)

	var btn_walk = _action_btn("Walk Away", Color(0.35, 0.12, 0.12))
	btn_walk.pressed.connect(func():
		GameState.walk_away_approach(_ap["neg_id"])
		_show_result("Negotiation ended.", "You walked away.", Color(0.6, 0.6, 0.6)))
	btn_row.add_child(btn_walk)

func _build_approach_field_row(key: String, term: Dictionary, show_lock: bool = true) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var is_locked = term.get("locked", false)
	var is_agreed = term.get("agreed", false)

	## Term label
	var lbl = Label.new()
	lbl.text = FIELD_LABELS.get(key, key)
	lbl.custom_minimum_size = Vector2(230, 0)
	lbl.add_theme_font_size_override("font_size", 24)
	if is_locked or is_agreed:
		lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	row.add_child(lbl)

	## S37.9 — salary is shown/edited as an ANNUAL figure (= weekly × 52).
	var is_salary := key == "weekly_salary"
	var disp_mult := WEEKS_PER_SEASON if is_salary else 1

	## Their ask
	var their_ask = term.get("their_ask", 0)
	var lbl_ask = Label.new()
	lbl_ask.custom_minimum_size = Vector2(110, 0)
	lbl_ask.add_theme_font_size_override("font_size", 24)
	lbl_ask.add_theme_color_override("font_color",
		Color(0.4, 0.9, 0.4) if (is_locked or is_agreed) else Color(1.0, 0.6, 0.4))
	if key == "start_date":
		lbl_ask.text = str(their_ask)
	elif key in ["duration_seasons","seasons_remaining"]:
		lbl_ask.text = "%d" % int(their_ask)
	else:
		lbl_ask.text = "CR %s" % _fmt(int(their_ask) * disp_mult)
	row.add_child(lbl_ask)

	## Player input (disabled if locked/agreed)
	if key == "start_date":
		var opt = OptionButton.new()
		opt.custom_minimum_size = Vector2(130, 30)
		opt.add_item("Immediate", 0)
		opt.add_item("Next Season", 1)
		opt.selected = 0 if term.get("player_offer", "immediate") == "immediate" else 1
		opt.disabled = is_locked or is_agreed
		row.add_child(opt)
		_fields[key] = opt
	else:
		var spin = SpinBox.new()
		spin.custom_minimum_size = Vector2(120, 34)
		spin.add_theme_font_size_override("font_size", 24)
		if key in ["duration_seasons","seasons_remaining"]:
			spin.min_value = 1; spin.max_value = 5; spin.step = 1
		elif is_salary:
			## Annual units: cap at 2× their annual ask, step a week's worth.
			spin.min_value = 0
			spin.max_value = float(their_ask) * disp_mult * 2.0
			spin.step = WEEKS_PER_SEASON
		else:
			spin.min_value = 0; spin.max_value = float(their_ask) * 2.0; spin.step = 10
		spin.value = term.get("player_offer", their_ask) * disp_mult
		spin.editable = not (is_locked or is_agreed)
		row.add_child(spin)
		_fields[key] = spin

	## Lock button — drivers only
	if show_lock:
		var lock_btn = Button.new()
		lock_btn.custom_minimum_size = Vector2(36, 30)
		lock_btn.add_theme_font_size_override("font_size", 28)
		if is_agreed:
			lock_btn.text = "✅"
			lock_btn.disabled = true
			lock_btn.tooltip_text = "Both sides agreed on this term."
		elif is_locked:
			lock_btn.text = "🔒"
			lock_btn.tooltip_text = "Locked — click to unlock."
			lock_btn.pressed.connect(func():
				_ap["terms"][key]["locked"] = false
				_rebuild_approach())
		else:
			lock_btn.text = "🔓"
			lock_btn.tooltip_text = "Lock this term (propose it as final)."
			lock_btn.pressed.connect(func():
				_ap["terms"][key]["locked"] = true
				_rebuild_approach())
		row.add_child(lock_btn)
		_lock_btns[key] = lock_btn

	## S37.10 — live weekly read-out for the annual salary, placed AFTER the lock column so the
	## TERM/ASK/OFFER/LOCK columns stay aligned across every row (was inserted before the lock,
	## pushing the salary row's lock out of line). Sits in the trailing free space.
	if is_salary and _fields.has(key) and _fields[key] is SpinBox:
		var sp_ref: SpinBox = _fields[key]
		var lbl_wk = Label.new()
		lbl_wk.add_theme_font_size_override("font_size", 20)
		lbl_wk.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		lbl_wk.text = "≈ CR %s/wk" % _fmt(int(round(sp_ref.value / WEEKS_PER_SEASON)))
		sp_ref.value_changed.connect(_on_salary_changed.bind(lbl_wk))
		row.add_child(lbl_wk)

	return row

func _on_submit_approach() -> void:
	var offers: Dictionary = {}
	var locked: Array = []
	for key in _fields:
		var ctrl = _fields[key]
		if key == "start_date":
			offers[key] = "immediate" if ctrl.selected == 0 else "next_season"
		elif key == "weekly_salary":
			## S37.9 — spinbox is in ANNUAL units; store back as weekly.
			offers[key] = int(round(float(ctrl.value) / WEEKS_PER_SEASON))
		else:
			offers[key] = int(ctrl.value)
	for key in _lock_btns:
		if _ap["terms"].get(key, {}).get("locked", false):
			locked.append(key)

	var result = GameState.submit_approach_contract_offer(_ap["neg_id"], offers, locked)
	match result:
		"accepted":
			_show_result("✅ Deal Agreed!", "Contract signed successfully.", Color(0.3, 0.9, 0.4))
		"rejected":
			_show_result("❌ No Deal", "Negotiations have broken down.", Color(0.9, 0.3, 0.3))
		"counter":
			## Offer submitted — close window. Player will be notified next week to respond.
			_show_result("📤 Offer Submitted", "Their reply will arrive next week.", Color(0.4, 0.75, 1.0))
		"error":
			pass

func _make_four_col(a: String, b: String, c: String, d: String, bold: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for item in [[a, 230], [b, 110], [c, 120], [d, 36]]:
		var lbl = Label.new()
		lbl.text = item[0]
		lbl.custom_minimum_size = Vector2(item[1], 0)
		lbl.add_theme_font_size_override("font_size", 20)
		if bold: lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		else: lbl.modulate = Color(0.45, 0.45, 0.45)
		row.add_child(lbl)
	return row

func _rebuild() -> void:
	_clear_content()
	_fields = {}

	## Header
	var subject_name = _get_subject_name()
	var lbl_title = Label.new()
	lbl_title.add_theme_font_size_override("font_size", 40)
	lbl_title.add_theme_color_override("font_color", Color.WHITE)
	lbl_title.text = "📋  CONTRACT NEGOTIATION"
	_content.add_child(lbl_title)

	var lbl_name = Label.new()
	lbl_name.text = subject_name
	lbl_name.add_theme_font_size_override("font_size", 28)
	lbl_name.modulate = Color(0.55, 0.75, 1.0)
	_content.add_child(lbl_name)

	## Round indicator
	var round_row = HBoxContainer.new()
	round_row.add_theme_constant_override("separation", 8)
	_content.add_child(round_row)
	var lbl_round = Label.new()
	lbl_round.text = "Round %d of %d" % [_neg["round"], _neg["max_rounds"]]
	lbl_round.add_theme_font_size_override("font_size", 24)
	lbl_round.modulate = Color(0.6, 0.6, 0.6)
	round_row.add_child(lbl_round)
	if _neg.get("cfo_bonus", 0.0) > 0:
		var lbl_cfo = Label.new()
		lbl_cfo.text = "💼 CFO +%.0f%% edge" % (_neg["cfo_bonus"] * 100)
		lbl_cfo.add_theme_font_size_override("font_size", 22)
		lbl_cfo.modulate = Color(0.4, 0.85, 0.55)
		round_row.add_child(lbl_cfo)

	_content.add_child(HSeparator.new())

	## Columns header — 4 cols with LOCK
	var col_header = _make_four_col("TERM", "THEIR ASK", "YOUR OFFER", "LOCK", true)
	_content.add_child(col_header)

	## Fields
	var field_order = _get_field_order()
	for key in field_order:
		if not key in _neg["their_ask"]: continue
		var ask_val = _neg["their_ask"][key]
		var offer_val = _neg["player_offer"].get(key, ask_val)
		_content.add_child(_build_field_row(key, ask_val, offer_val))

	_content.add_child(HSeparator.new())

	## History summary
	if not _neg["history"].is_empty():
		var last = _neg["history"][-1]
		var ratio = GameState._calc_offer_ratio(last["player"], last["their"])
		var lbl_hist = Label.new()
		lbl_hist.text = "Last round: your offer was %.0f%% of their ask." % (ratio * 100)
		lbl_hist.add_theme_font_size_override("font_size", 22)
		lbl_hist.modulate = Color(
			0.4 if ratio >= 0.75 else (0.9 if ratio >= 0.50 else 1.0),
			0.85 if ratio >= 0.75 else (0.65 if ratio >= 0.50 else 0.4),
			0.4)
		_content.add_child(lbl_hist)

	## Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	_content.add_child(btn_row)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(spacer)

	var btn_submit = _action_btn("Submit Offer →", Color(0.15, 0.50, 0.20))
	btn_submit.pressed.connect(_on_submit)
	btn_row.add_child(btn_submit)

	## Accept as-is shortcut (only if near their ask)
	var btn_accept = _action_btn("Accept Their Terms", Color(0.12, 0.35, 0.55))
	btn_accept.pressed.connect(_on_accept_their_terms)
	btn_row.add_child(btn_accept)

	var btn_walk = _action_btn("✕ Walk Away", Color(0.35, 0.12, 0.12))
	btn_walk.pressed.connect(_on_walk_away)
	btn_row.add_child(btn_walk)


func _build_field_row(key: String, ask_val, offer_val) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	## S37.9 — salary shown/edited annually (= weekly × 52).
	var is_salary := key == "weekly_salary"
	var disp_mult := WEEKS_PER_SEASON if is_salary else 1

	## Label
	var lbl = Label.new()
	lbl.text = FIELD_LABELS.get(key, key)
	lbl.custom_minimum_size = Vector2(200, 0)
	lbl.add_theme_font_size_override("font_size", 26)
	row.add_child(lbl)

	## Their ask (read-only)
	var lbl_ask = Label.new()
	lbl_ask.custom_minimum_size = Vector2(110, 0)
	lbl_ask.add_theme_font_size_override("font_size", 26)
	lbl_ask.add_theme_color_override("font_color", Color(1.0, 0.6, 0.4))
	if key == "duration_seasons" or key == "seasons_remaining":
		lbl_ask.text = "%d" % int(ask_val)
	else:
		lbl_ask.text = "CR %s" % _fmt(int(ask_val) * disp_mult)
	row.add_child(lbl_ask)

	## Player input
	var spin = SpinBox.new()
	spin.custom_minimum_size = Vector2(130, 36)
	spin.add_theme_font_size_override("font_size", 26)
	if key == "duration_seasons":
		spin.min_value = 1; spin.max_value = 5; spin.step = 1
	elif key == "seasons_remaining":
		spin.min_value = 1; spin.max_value = 5; spin.step = 1
	elif is_salary:
		spin.min_value = 0; spin.max_value = ask_val * disp_mult * 2.0; spin.step = WEEKS_PER_SEASON
	else:
		spin.min_value = 0; spin.max_value = ask_val * 2.0; spin.step = 10
	spin.value = offer_val * disp_mult
	row.add_child(spin)
	_fields[key] = spin

	## Lock button — all negotiation types
	var lock_key = key
	var is_locked_old = _neg.get("locked_fields", []).has(key)
	var lock_btn_old = Button.new()
	lock_btn_old.custom_minimum_size = Vector2(36, 30)
	lock_btn_old.add_theme_font_size_override("font_size", 28)
	if is_locked_old:
		lock_btn_old.text = "🔒"
		lock_btn_old.tooltip_text = "Locked — click to unlock."
		lock_btn_old.pressed.connect(func():
			var lf: Array = _neg.get("locked_fields", [])
			lf.erase(lock_key)
			_neg["locked_fields"] = lf
			_rebuild())
	else:
		lock_btn_old.text = "🔓"
		lock_btn_old.tooltip_text = "Lock this term."
		lock_btn_old.pressed.connect(func():
			var lf: Array = _neg.get("locked_fields", [])
			if lock_key not in lf: lf.append(lock_key)
			_neg["locked_fields"] = lf
			_rebuild())
	row.add_child(lock_btn_old)

	## S37.10 — weekly read-out after the lock (legacy path), keeps columns aligned.
	if is_salary and _fields.has(key) and _fields[key] is SpinBox:
		var sp_ref2: SpinBox = _fields[key]
		var lbl_wk2 = Label.new()
		lbl_wk2.add_theme_font_size_override("font_size", 22)
		lbl_wk2.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		lbl_wk2.text = "≈ CR %s/wk" % _fmt(int(round(sp_ref2.value / WEEKS_PER_SEASON)))
		sp_ref2.value_changed.connect(_on_salary_changed.bind(lbl_wk2))
		row.add_child(lbl_wk2)

	return row


func _on_submit() -> void:
	var offer = {}
	for key in _fields:
		if key == "weekly_salary":
			## S37.9 — spinbox is annual; store weekly.
			offer[key] = int(round(float(_fields[key].value) / WEEKS_PER_SEASON))
		else:
			offer[key] = int(_fields[key].value)
	var result = GameState.submit_negotiation_offer(offer)
	match result:
		"accepted":
			_show_result("✅ Deal Agreed!", "Contract signed successfully.", Color(0.3, 0.9, 0.4))
		"rejected":
			_show_result("❌ No Deal", "They walked away from the negotiation.", Color(0.9, 0.3, 0.3))
		"no_slot":
			_show_result("⚠ No Slot Available",
				"You have no free slots for an immediate signing.\nSign for next season instead.",
				Color(1.0, 0.6, 0.2))
		"counter":
			_show_waiting_for_reply()
		"waiting":
			_show_waiting_for_reply()
		_:
			_neg = GameState.active_negotiation
			_rebuild()


func _on_accept_their_terms() -> void:
	## Fill all fields with their ask values then submit
	var offer = {}
	for key in _neg["their_ask"]:
		offer[key] = int(_neg["their_ask"][key])
	var result = GameState.submit_negotiation_offer(offer)
	_show_result("✅ Deal Agreed!", "You accepted their terms.", Color(0.3, 0.9, 0.4))


func _on_walk_away() -> void:
	GameState.abandon_negotiation()
	_show_result("Negotiation ended.", "You walked away.", Color(0.6, 0.6, 0.6))


func _show_waiting_for_reply() -> void:
	_clear_content()

	var lbl = Label.new()
	lbl.text = "⏳ Offer submitted — waiting for their reply next week."
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(lbl)

	var lbl_round = Label.new()
	lbl_round.text = "Round %d of %d · Advance the week to receive their counter-offer." % [
		_neg.get("round", 1) - 1, _neg.get("max_rounds", 4)]
	lbl_round.add_theme_font_size_override("font_size", 24)
	lbl_round.modulate = Color(0.5, 0.5, 0.5)
	lbl_round.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(lbl_round)

	var btn_close = Button.new()
	btn_close.text = "Close — Return After Week Advance"
	btn_close.custom_minimum_size = Vector2(260, 44)
	btn_close.add_theme_font_size_override("font_size", 28)
	btn_close.pressed.connect(func():
		queue_free()
		emit_signal("closed"))
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(btn_close)
	_content.add_child(row)

func _show_result(title: String, body: String, color: Color) -> void:
	_clear_content()

	var lbl_t = Label.new()
	lbl_t.text = title
	lbl_t.add_theme_font_size_override("font_size", 44)
	lbl_t.add_theme_color_override("font_color", color)
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(lbl_t)

	var lbl_b = Label.new()
	lbl_b.text = body
	lbl_b.add_theme_font_size_override("font_size", 28)
	lbl_b.modulate = Color(0.7, 0.7, 0.7)
	lbl_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(lbl_b)

	var btn = Button.new()
	btn.text = "Close"
	btn.custom_minimum_size = Vector2(160, 44)
	btn.add_theme_font_size_override("font_size", 32)
	btn.pressed.connect(func():
		queue_free()
		emit_signal("closed"))
	var btn_c = HBoxContainer.new()
	btn_c.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_c.add_child(btn)
	_content.add_child(btn_c)


## ── Helpers ───────────────────────────────────────────────────────────────────

func _get_subject_name() -> String:
	var sid = _neg.get("subject_id", "")
	match _neg.get("subject_type", ""):
		"driver":
			var d = GameState.all_drivers.get(sid)
			return d.full_name() if d else sid
		"staff":
			var s = GameState.all_staff.get(sid)
			return "%s  (%s)" % [s.full_name(), s.role] if s else sid
		"sponsor":
			return _neg.get("offer_data", {}).get("name", sid)
	return sid

func _get_field_order() -> Array:
	match _neg.get("subject_type",""):
		"driver": return FIELD_ORDER_DRIVER
		"staff":  return FIELD_ORDER_STAFF
		"sponsor":
			match _neg.get("offer_data",{}).get("type", 1):
				1: return FIELD_ORDER_SPONSOR_1
				2: return FIELD_ORDER_SPONSOR_2
				3: return FIELD_ORDER_SPONSOR_3
	return FIELD_ORDER_DRIVER

func _make_three_col(a: String, b: String, c: String, bold: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for item in [[a, 200], [b, 110], [c, 130], ["", 80]]:
		var lbl = Label.new()
		lbl.text = item[0]
		lbl.custom_minimum_size = Vector2(item[1], 0)
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.modulate = Color(0.45, 0.45, 0.45)
		if bold: lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		row.add_child(lbl)
	return row

func _action_btn(label: String, bg: Color) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 38)
	btn.add_theme_font_size_override("font_size", 26)
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = 4; style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4; style.corner_radius_bottom_right = 4
	style.content_margin_left = 12; style.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", style)
	var hover = style.duplicate(); hover.bg_color = bg.lightened(0.12)
	btn.add_theme_stylebox_override("hover", hover)
	return btn

## S37.9 — live weekly read-out for the annual salary spinbox. Bound via
## value_changed.connect(_on_salary_changed.bind(lbl)); `value` is the signal arg (annual),
## `lbl` is the bound Label. Named handler (not an inline lambda) for parser robustness.
func _on_salary_changed(value: float, lbl: Label) -> void:
	if is_instance_valid(lbl):
		lbl.text = "≈ CR %s/wk" % _fmt(int(round(value / WEEKS_PER_SEASON)))

func _fmt(n: int) -> String:
	if n >= 1000000: return "%.1fM" % (n / 1000000.0)
	if n >= 1000:    return "%.0fK" % (n / 1000.0)
	return str(n)
