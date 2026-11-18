extends Node

const LEVEL_COUNT = 100
const GAME_SCENE = "res://Scenes/Game.tscn"
const SELECTOR_SCENE = "res://Scenes/LevelSelector.tscn"
const SAVE_PATH = "user://save.cfg"

## Zet aan om tijdens testen alle levels te kunnen spelen
@export var unlock_all: bool = false
## Zet aan om de touch-besturing ook op de computer te zien (testen met muis: Project Settings >
## Input Devices > Pointing > Emulate Touch From Mouse aanzetten)
@export var touch_testen: bool = false

var current_level: int = 1

# Scenes 1 keer laden en vasthouden: anders laadt Godot bij elk nieuw level alle geluiden en
# plaatjes opnieuw (~80 ms hapering per levelwissel).
var game_scene: PackedScene
var selector_scene: PackedScene
var level_stars = {}   # level nummer -> beste aantal sterren, bijv. {1: 3, 2: 2}

func _ready() -> void:
	# Liggend: basis 1152x648. Staand: basis 648x1152. Zo zijn HUD, knoppen en tekst in beide
	# standen even groot en zie je in portret ~18 tiles breed.
	get_tree().root.size_changed.connect(_pas_orientatie_aan)
	_pas_orientatie_aan()
	game_scene = load(GAME_SCENE)
	selector_scene = load(SELECTOR_SCENE)
	load_progress()
	current_level = highest_unlocked()

func _pas_orientatie_aan() -> void:
	var root = get_tree().root
	var gewenst = Vector2i(1152, 648) if root.size.x >= root.size.y else Vector2i(648, 1152)
	if root.content_scale_size != gewenst:
		root.content_scale_size = gewenst

# Telefoon of tablet (ook in de browser)
func is_mobile() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios")

func save_level_stars(level: int, stars: int) -> void:
	level_stars[level] = max(level_stars.get(level, 0), stars)
	save_progress()

func get_stars(level: int) -> int:
	return level_stars.get(level, 0)

func is_unlocked(level: int) -> bool:
	return unlock_all or level == 1 or get_stars(level - 1) > 0

func highest_unlocked() -> int:
	var level = 1
	while level < LEVEL_COUNT and is_unlocked(level + 1):
		level += 1
	return level

func play_level(level: int) -> void:
	current_level = clampi(level, 1, LEVEL_COUNT)
	if AudioManager.level_background_music.playing:
		AudioManager.level_background_music.stop()
	get_tree().change_scene_to_packed(game_scene)

func next_level() -> void:
	if current_level < LEVEL_COUNT:
		play_level(current_level + 1)
	else:
		open_selector()

func open_selector() -> void:
	get_tree().change_scene_to_packed(selector_scene)

# --- Opslaan op schijf (werkt ook in de browser) ---
func save_progress() -> void:
	var cfg = ConfigFile.new()
	for level in level_stars:
		cfg.set_value("stars", str(level), level_stars[level])
	cfg.save(SAVE_PATH)

func load_progress() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK or not cfg.has_section("stars"):
		return
	for key in cfg.get_section_keys("stars"):
		level_stars[int(key)] = cfg.get_value("stars", key)
