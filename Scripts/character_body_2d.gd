@tool
extends CharacterBody2D

const Level_Complete_Panel: PackedScene = preload("res://Scenes/LevelComplete.tscn")

var result_canvas: CanvasLayer = null
var result_popup: Control = null
var level_finished: bool = false

# --- Spawn / Checkpoint ---
@onready var spawn_position: Vector2 = global_position

# --- Game State ---
var has_started: bool = false
var is_dead: bool = false
var is_intro_playing: bool = false
var has_seen_intro: bool = false

# --- Charging Space Bar ---
signal charge_changed(ratio: float)

# --- Audio ---
@export var death_sounds: Array[AudioStream] = []

# --- Gravity ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Speed & Movement ---
@export var move_speed = 500.0
@export var air_acceleration = 2000.0
@export var air_friction = 400.0
@export var ground_friction = 3000.0

# --- Jumping & Hopping ---
@export var min_jump_force = -300.0
@export var max_jump_force = -1000.0
@export var charge_rate = 1500.0
@export var auto_hop_force = -220.0

# --- Flips & Aim ---
@export_group("Flips")
@export var aim_max_angle_deg = 35.0
@export var spin_acceleration = 8.0
@export var max_spin_speed = 3.5
@export var spin_damping = 2.0
@export var big_jump_air_control = 0.3
@export var land_tolerance_deg = 55.0
@export var bad_landing_kills = false

var current_jump_charge = 0.0
var is_charging = false

# --- Gelanceerd door wreckingball ---
@export_group("Launch")
@export var launch_gravity_scale: float = 0.3
@export var launch_fly_time: float = 1.5
var is_launched: bool = false
var launch_timer: float = 0.0

# --- Rotation State ---
var angle: float = 0.0
var angular_vel: float = 0.0
var is_big_jump: bool = false
var was_on_floor: bool = false
var pivot_blend: float = 0.0
var tuck: float = 0.0
var just_released_charge: bool = false

# --- Ground Cracks ---
var active_cracks: Array = []

# --- Dynamic Drawing Variables ---
@export_group("Drawing")
@export var draw_scale: float = 4.0:
	set(v):
		draw_scale = v
		queue_redraw()
@export var feet_y: float = 60.0:
	set(v):
		feet_y = v
		queue_redraw()
@export var show_collision_guide: bool = true:
	set(v):
		show_collision_guide = v
		queue_redraw()

var is_facing_right: bool = true
var visual_stretch: float = 0.0

# --- Camera ---
@export var camera_node: Camera2D

# --- Stars & Time System ---
var level_timer: float = 0.0
@export var par_time: float = 30.0
@export var fast_time: float = 15.0
@export var auto_next_delay: float = 2.0


func _ready():
	if Engine.is_editor_hint():
		queue_redraw()
		return

	var detected := _get_scene_level_number()
	if detected != -1 and has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if "current_level" in gm:
			gm.current_level = detected

	if has_node("/root/PokiSDK"):
		var poki = get_node("/root/PokiSDK")
		poki.call("gameLoadingFinished")


func _get_audio_manager() -> Node:
	if has_node("/root/AudioManager"):
		return get_node("/root/AudioManager")
	return null


func _get_player(prop_name: String) -> AudioStreamPlayer:
	var am := _get_audio_manager()
	if am and prop_name in am:
		var p = am.get(prop_name)
		if p is AudioStreamPlayer:
			return p
	return null


func _play_sound(prop_name: String, only_if_not_playing: bool = false) -> void:
	var p := _get_player(prop_name)
	if not p:
		return
	if only_if_not_playing and p.playing:
		return
	p.play()


func _stop_sound(prop_name: String) -> void:
	var p := _get_player(prop_name)
	if p and p.playing:
		p.stop()


func _is_sound_playing(prop_name: String) -> bool:
	var p := _get_player(prop_name)
	return p != null and p.playing


func _input(event):
	if level_finished or Engine.is_editor_hint():
		return

	if has_started and not is_dead and event.is_action_pressed("ui_cancel"):
		pause_game()
		return

	var is_key_press = event is InputEventKey and event.pressed and not event.echo
	var is_click = event is InputEventMouseButton and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed

	if not has_started and not is_dead and not is_intro_playing and (is_key_press or is_click or is_touch):
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			return

		if not has_seen_intro and camera_node and camera_node.has_method("play_finish_preview"):
			is_intro_playing = true
			camera_node.play_finish_preview(func():
				has_seen_intro = true
				has_started = true
				is_intro_playing = false
				if has_node("/root/PokiSDK"):
					get_node("/root/PokiSDK").call("gameplayStart")
			)
		else:
			has_started = true
			if has_node("/root
