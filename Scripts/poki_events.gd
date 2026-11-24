extends Node

# Autoload "PokiEvents": stuurt measure(category, what, action) naar Poki
# (developers.poki.com/guide/game-events). Poki toont per event welk % van de
# gameplays het bereikte, dus elk event heeft een vaste naam (geen getallen of
# ids). Maximaal 40 unieke events; nu precies 40:
#
#   level     1..16               start   16  intro: elk level een nieuw obstakel (Docs/LEVELS.md)
#             21|31|41|...|91     start    8  eerste level van wereld 3..10 (11 = wereld 2 zit al in 1..16)
#   attempts  1|2-3|4-9|10+       clear    4  pogingen (deaths + 1) bij de eerste clear van een level
#   stars     1|2|3               earned   3  opgepakte sterren bij de eerste clear. 0 sterren heeft
#                                             geen event: dat is som(attempts/*) - som(stars/*)
#   ttfi      under-3s|3-10s|over-10s  reached  3  laden level 1 -> eerste beweging/sprong (nieuwe spelers)
#   exit      after-death|idle|playing|menu  hidden  4  wat er gebeurde toen de tab verborgen werd
#   device    keyboard|touch      used     2  besturing in een level, 1x per sessie
#
# level/N/start gaat maar 1x per speler (onthouden in user://poki.cfg). Een level gaat pas open
# als het vorige gehaald is, en na een clear volgt automatisch het volgende level. Dus:
#   completion rate level N  = level/N+1/start / level/N/start   (levels 1..15)
#   completion rate wereld W = level/(W*10+1)/start / level/((W-1)*10+1)/start
#   level funnel             = level/N/start / level/1/start
#   frustratie               = exit/after-death hoog + attempts/10+ hoog
#   verwarring               = exit/idle (10+ s geen input) en ttfi/over-10s

const FUNNEL_LEVELS := [
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,   # intro
	21, 31, 41, 51, 61, 71, 81, 91,                          # start van wereld 3..10
]
const SAVE_PATH := "user://poki.cfg"
const MOVE_ACTIONS := ["move_left", "move_right", "charge_jump"]
const IDLE_MS := 10000
const AFTER_DEATH_MS := 3000

var _level := 0
var _max_reached := 0   # hoogste level waarvan level/N/start al is verstuurd (bewaard)
var _first_clear := false
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
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_max_reached = int(cfg.get_value("events", "max_reached", 0))
	# Save van voor deze events: gehaalde levels niet opnieuw als "bereikt" sturen
	# (GameManager is eerder geladen, dus de sterren zijn al ingelezen)
	for level in GameManager.level_stars:
		_max_reached = maxi(_max_reached, int(level))
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
	_first_clear = not GameManager.is_completed(level)
	# Alleen de eerste keer dat deze speler het level bereikt (niet bij opnieuw spelen)
	if level > _max_reached:
		_max_reached = level
		var cfg := ConfigFile.new()
		cfg.set_value("events", "max_reached", _max_reached)
		cfg.save(SAVE_PATH)
		if level in FUNNEL_LEVELS:
			measure("level", str(level), "start")
	# TTFI alleen voor spelers die level 1 nog nooit hebben gehaald
	if level == 1 and not _ttfi_sent and _first_clear:
		_ttfi_waiting = true


func player_died() -> void:
	_deaths += 1
	_last_death_ms = Time.get_ticks_msec()


func level_completed(stars: int) -> void:
	_level_done = true
	_ttfi_waiting = false
	# Opnieuw spelen voor meer sterren telt niet mee: elk level 1x per speler
	if not _first_clear:
		return
	_first_clear = false
	var attempts := _deaths + 1
	var bucket := "1"
	if attempts >= 10:
		bucket = "10+"
	elif attempts >= 4:
		bucket = "4-9"
	elif attempts >= 2:
		bucket = "2-3"
	measure("attempts", bucket, "clear")
	if stars > 0:
		measure("stars", str(mini(stars, 3)), "earned")


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
