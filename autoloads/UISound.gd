extends Node
## Version: S40.1 — Roadmap #2 (click sound). Project-wide UI click: a single autoload that plays a
##   short click whenever ANY BaseButton (Button, CheckBox, OptionButton, etc.) is pressed, with zero
##   per-button wiring. It connects to the scene tree's `node_added` signal and auto-attaches the
##   `pressed` handler to every current and future button, so all 39 code-built scenes (and anything
##   added later) get the click for free. The sound loads from res://resources/audio/ui_click.wav if
##   present (drop in a human-made/CC0 replacement and it's used automatically — see the Steam asset-
##   provenance note in Brainstorm_Threads); if that file is ever missing it falls back to a runtime-
##   synthesized click so the game is never silent or broken. Playback runs on a dedicated "UI" audio
##   bus (created at runtime if the project has no bus layout yet), and exposes `enabled` + `volume_db`
##   so the future Settings menu (roadmap #21) can wire a master/UI volume slider straight into it.
##
## DESIGN NOTES:
## - GLOBAL, NOT PER-BUTTON: hooking `node_added` keeps the 39 scenes untouched and means new screens
##   never have to remember to wire sound. Each button is connected exactly once (guarded by
##   `is_connected`), and the lambda is bound to nothing button-specific so freed buttons don't leak.
## - DISABLED BUTTONS: BaseButton does not emit `pressed` while `disabled`, so greyed controls are
##   silent automatically — no extra guard needed.
## - TOGGLES / OPTION POPUPS: `pressed` covers normal presses and toggle flips. OptionButton's item
##   selection goes through its internal popup (a PopupMenu, not a BaseButton) — if per-item ticks are
##   wanted later, add a small PopupMenu hook; intentionally out of scope for the base click.

const CLICK_PATH := "res://resources/audio/ui_click.wav"
const UI_BUS_NAME := "UI"

## Public settings (a Settings menu can read/write these; persist them there, not here).
var enabled: bool = true
var volume_db: float = -6.0   ## a click should sit UNDER speech/music; quiet by default

var _stream: AudioStream = null
var _players: Array[AudioStreamPlayer] = []   ## small pool so rapid clicks don't cut each other off
var _pool_size: int = 5
var _next_player: int = 0
var _ui_bus_idx: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   ## clicks still play while the game is paused
	_ensure_ui_bus()
	_load_stream()
	_build_pool()
	## Auto-wire every button that already exists, then every one added afterwards.
	get_tree().node_added.connect(_on_node_added)
	_wire_existing_buttons(get_tree().root)

# ── Audio bus ────────────────────────────────────────────────────────────────
func _ensure_ui_bus() -> void:
	_ui_bus_idx = AudioServer.get_bus_index(UI_BUS_NAME)
	if _ui_bus_idx == -1:
		## No "UI" bus (the project has no bus layout yet — this is the first sound). Create one
		## routed to Master so a future mixer/Settings screen has a named target to control.
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, UI_BUS_NAME)
		AudioServer.set_bus_send(idx, "Master")
		_ui_bus_idx = idx

# ── Stream loading (asset preferred, synth fallback) ─────────────────────────
func _load_stream() -> void:
	if ResourceLoader.exists(CLICK_PATH):
		var s = load(CLICK_PATH)
		if s is AudioStream:
			_stream = s
			return
	_stream = _synth_click()   ## never leave the project clickless

## Runtime "clean minimal" click — a very short filtered-noise transient with a faint high tone.
## Mirrors the chosen os_5 candidate so the fallback matches the shipped asset's character.
func _synth_click() -> AudioStream:
	var sr := 44100
	var n := int(sr * 0.022)
	var data := PackedByteArray()
	data.resize(n * 2)   ## 16-bit mono
	var prev := 0.0
	var lp := 0.6
	var peak := 0.0
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in range(n):
		var t := float(i) / sr
		var env := exp(-t / 0.0018)
		var nz := (randf() * 2.0 - 1.0) * env
		prev = prev + lp * (nz - prev)            ## one-pole lowpass
		var tn := sin(TAU * 1600.0 * t) * exp(-t / 0.003) * 0.18
		var v := prev + tn
		buf[i] = v
		peak = max(peak, abs(v))
	if peak == 0.0:
		peak = 1.0
	for i in range(n):
		var s := int(clamp(buf[i] / peak * 0.9, -1.0, 1.0) * 32767.0)
		data[i * 2] = s & 0xFF
		data[i * 2 + 1] = (s >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sr
	stream.data = data
	return stream

# ── Player pool ──────────────────────────────────────────────────────────────
func _build_pool() -> void:
	for i in range(_pool_size):
		var p := AudioStreamPlayer.new()
		p.stream = _stream
		p.bus = UI_BUS_NAME
		p.volume_db = volume_db
		add_child(p)
		_players.append(p)

func play_click() -> void:
	if not enabled or _stream == null or _players.is_empty():
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.volume_db = volume_db
	p.play()

# ── Global button auto-wiring ────────────────────────────────────────────────
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_wire_button(node)

func _wire_existing_buttons(root: Node) -> void:
	if root is BaseButton:
		_wire_button(root)
	for child in root.get_children():
		_wire_existing_buttons(child)

func _wire_button(b: BaseButton) -> void:
	if not b.pressed.is_connected(play_click):
		b.pressed.connect(play_click)

# ── Settings hooks (for roadmap #21) ─────────────────────────────────────────
func set_enabled(v: bool) -> void:
	enabled = v

func set_volume_db(db: float) -> void:
	volume_db = db
	for p in _players:
		p.volume_db = db
