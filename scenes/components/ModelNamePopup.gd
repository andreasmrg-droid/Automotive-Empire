## Version: S39.7 — ModelNamePopup: a centered modal for naming a commercial model when Start
##   Production (or a completed Facelift / Next-Gen) commits it. Shows the segment, all 5 fictional
##   name proposals as tappable buttons, a free-text field for a custom name, Confirm, and Cancel
##   (Cancel backs out — the caller does NOT start production). Reusable: call open(...) with the
##   segment label, the proposals array, and two Callables (on_confirm(name:String), on_cancel()).
extends Control

signal name_chosen(model_name: String)
signal cancelled()

var _on_confirm: Callable
var _on_cancel: Callable
var _line_edit: LineEdit
var _dim: ColorRect
var _proposal_btns: Array = []

## Build + show the popup. proposals = Array[String]; on_confirm/on_cancel are optional Callables.
func open(segment_label: String, proposals: Array, title_verb: String = "Name your model",
		on_confirm: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	_on_confirm = on_confirm
	_on_cancel = on_cancel
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dim backdrop (also catches stray clicks).
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.6)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	# Centered panel.
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.13, 0.17)
	style.border_color = Color(0.35, 0.55, 0.85)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
	style.content_margin_left = 24; style.content_margin_right = 24
	style.content_margin_top = 20; style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.custom_minimum_size = Vector2(520, 0)
	panel.add_child(vbox)

	var lbl_title = Label.new()
	lbl_title.text = "🏷  %s" % title_verb
	lbl_title.add_theme_font_size_override("font_size", 30)
	lbl_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	vbox.add_child(lbl_title)

	var lbl_seg = Label.new()
	lbl_seg.text = "Segment: %s" % segment_label
	lbl_seg.add_theme_font_size_override("font_size", 22)
	lbl_seg.modulate = Color(0.6, 0.6, 0.65)
	vbox.add_child(lbl_seg)

	var lbl_hint = Label.new()
	lbl_hint.text = "Pick a proposal or type your own:"
	lbl_hint.add_theme_font_size_override("font_size", 20)
	lbl_hint.modulate = Color(0.55, 0.55, 0.6)
	vbox.add_child(lbl_hint)

	# Proposal buttons (all of them).
	for nm in proposals:
		var btn = Button.new()
		btn.text = nm
		btn.custom_minimum_size = Vector2(0, 38)
		btn.add_theme_font_size_override("font_size", 24)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var nm_copy := str(nm)
		btn.pressed.connect(func(): _select_proposal(nm_copy))
		vbox.add_child(btn)
		_proposal_btns.append(btn)

	# Free-text field.
	_line_edit = LineEdit.new()
	_line_edit.placeholder_text = "…or type a custom name"
	_line_edit.add_theme_font_size_override("font_size", 22)
	_line_edit.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(_line_edit)

	vbox.add_child(HSeparator.new())

	# Action row: Cancel | Confirm.
	var arow = HBoxContainer.new()
	arow.add_theme_constant_override("separation", 12)
	vbox.add_child(arow)
	var btn_cancel = Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.custom_minimum_size = Vector2(140, 40)
	btn_cancel.add_theme_font_size_override("font_size", 22)
	btn_cancel.pressed.connect(_on_cancel_pressed)
	arow.add_child(btn_cancel)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arow.add_child(spacer)
	var btn_confirm = Button.new()
	btn_confirm.text = "✓  Confirm & Produce"
	btn_confirm.custom_minimum_size = Vector2(220, 40)
	btn_confirm.add_theme_font_size_override("font_size", 22)
	btn_confirm.add_theme_color_override("font_color", Color(0.5, 0.95, 0.6))
	btn_confirm.pressed.connect(_on_confirm_pressed)
	arow.add_child(btn_confirm)

func _select_proposal(nm: String) -> void:
	if _line_edit != null:
		_line_edit.text = nm

func _on_confirm_pressed() -> void:
	var chosen := ""
	if _line_edit != null:
		chosen = _line_edit.text.strip_edges()
	if chosen == "":
		# Nothing typed/selected — nudge the player rather than committing a blank name.
		if _line_edit != null:
			_line_edit.placeholder_text = "Please pick or type a name"
			_line_edit.grab_focus()
		return
	name_chosen.emit(chosen)
	if _on_confirm.is_valid():
		_on_confirm.call(chosen)
	queue_free()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	if _on_cancel.is_valid():
		_on_cancel.call()
	queue_free()
