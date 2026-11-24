extends Node

# Autoload "PokiEvents": stuurt measure(category, what, action) naar Poki
# (developers.poki.com/guide/game-events). Poki toont per event welk % van de
# gameplays het bereikte, dus elk event heeft een vaste naam (geen getallen of
# ids). Maximaal 40 unieke events; nu 38:
#
#   level     1..8                start / complete   22  funnel + completion rate per level
#             10|15|20|30|50|100  start                  (start = level bereikt)
#   attempts  1|2-3|4-9|10+       clear               4  pogingen (deaths + 1) bij een clear
#   stars     1|2|3               earned              3  sterren = tijd t.o.v. richttijd van het level
#                                                          (3 = onder fast_time, 2 = onder par_time)
#   ttfi      under-3s|3-10s|over-10s  reached        3  laden level 1 -> eerste beweging/sprong
#                                                          (alleen nieuwe spelers, 1x per sessie)
#   exit      after-death|idle|playing|menu  hidden   4  wat er gebeurde toen de tab verborgen werd
#   device    keyboard|touch      used                2  besturing in een level, 1x per sessie
#
# Lezen in het dashboard:
#   completion rate  = level/N/complete / level/N/start
#   level funnel     = level/N/start t.o.v. level/1/start
#   frustratie       = exit/after-death hoog + attempts/10+ hoog
#   verwarring       = exit/idle (10+ s geen input) en ttfi/over-10s

const FUNNEL_FULL := 8                       # levels 1..8: start + complete
const FUNNEL_MARKS := [10, 15, 20, 30, 50, 100]  # alleen start
const MOVE_ACTIONS := ["move_left", "move_right", "charge_jump"]
const IDLE_MS := 10000
const AFTER_DEATH_MS := 3000

var _level := 0
var _level_done := true
var _deaths := 0
var _level_ms := 0
var _last_input_ms := 0
var _last_death_ms := -AFTER_DEATH_MS
var _ttfi_waiting := false
var _ttfi_sent := false
var _device_sent := {}
var _hide_cb = null   # vasthouden, anders ruimt Godot de JS-callback op


func _ready() -> void:
	_last_input_ms = Time.get_ticks_msec()
	if OS.has_feature("web"):
		_hide_cb = JavaScriptBridge.create_callback(_on_visibility_change)
		JavaScriptBridge.get_interface("document").addEventListener("visibilitychange", _hide_cb)


func measure(category: String, what: String, action: String) -> void:
	if OS.is_debug_build():
		print("[poki] measure %s %s %s" % [category, what, action])
	var sdk = get_node_or_null("/root/PokiSDK")
	if sdk and sdk.has_method("measure"):
		sdk.measure(category, what, action)


# --- Aangeroepen door de speler (character_body_2d.gd) ---

func level_started(level: int) -> void:
	_level = level
	_level_done = false
	_deaths = 0
	_level_ms = Time.get_ticks_msec()
	_last_input_ms = _level_ms
	if level <= FUNNEL_FULL or level in FUNNEL_MARKS:
		measure("level", str(level), "start")
	# TTFI alleen voor spelers die level 1 nog nooit hebben gehaald
	if level == 1 and not _ttfi_sent and GameManager.get_stars(1) == 0:
		_ttfi_waiting = true


func player_died() -> void:
	_deaths += 1
	_last_death_ms = Time.get_ticks_msec()


func level_completed(level: int, stars: int) -> void:
	_level_done = true
	_ttfi_waiting = false
	if level <= FUNNEL_FULL:
		measure("level", str(level), "complete")
	var attempts := _deaths + 1
	var bucket := "1"
	if attempts >= 10:
		bucket = "10+"
	elif attempts >= 4:
		bucket = "4-9"
	elif attempts >= 2:
		bucket = "2-3"
	measure("attempts", bucket, "clear")
	measure("stars", str(clampi(stars, 1, 3)), "earned")


# --- Input: idle-tijd, TTFI en besturing ---

func _input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or event is InputEventScreenDrag
	if not pressed:
		return
	_last_input_ms = Time.get_ticks_msec()
	if _in_level():
		if event is InputEventScreenTouch:
			_send_device("touch")
		elif event is InputEventKey:
			_send_device("keyboard")


func _process(_delta: float) -> void:
	var moving := false
	for action in MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			moving = true
			break
	if not moving:
		return
	_last_input_ms = Time.get_ticks_msec()   # ingedrukt houden telt ook als input
	if _ttfi_waiting:
		_ttfi_waiting = false
		_ttfi_sent = true
		var ms := Time.get_ticks_msec() - _level_ms
		var bucket := "under-3s" if ms < 3000 else ("3-10s" if ms < 10000 else "over-10s")
		measure("ttfi", bucket, "reached")


func _send_device(kind: String) -> void:
	if _device_sent.has(kind):
		return
	_device_sent[kind] = true
	measure("device", kind, "used")


# --- Exit: de tab/pagina wordt verborgen (wegklikken, tab wisselen, sluiten) ---

func _in_level() -> bool:
	var scene = get_tree().current_scene
	return not _level_done and scene != null and scene.scene_file_path == GameManager.GAME_SCENE


func _on_visibility_change(_args) -> void:
	if str(JavaScriptBridge.get_interface("document").visibilityState) != "hidden":
		return
	var now := Time.get_ticks_msec()
	var kind := "playing"
	if not _in_level():
		kind = "menu"
	elif now - _last_death_ms < AFTER_DEATH_MS:
		kind = "after-death"
	elif now - _last_input_ms >= IDLE_MS:
		kind = "idle"
	measure("exit", kind, "hidden")
