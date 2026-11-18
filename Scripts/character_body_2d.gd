@tool
extends CharacterBody2D

# --- Level Complete Popup ---
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
@export var auto_hop_force = -220.0   # Small hops tuned high

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
@export var launch_gravity_scale: float = 0.3   # Minder zwaartekracht = je vliegt echt weg
@export var launch_fly_time: float = 1.5        # Na zoveel seconden zonder muur: weggevlogen
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
@export var par_time: float = 30.0          # Time limit for 2nd star
@export var fast_time: float = 15.0         # Time limit for 3rd star (extra fast!)
@export var auto_next_delay: float = 2.0    # Delay in seconds before auto-advancing after level completion

func _ready():
	if Engine.is_editor_hint():
		queue_redraw()
		return

	if has_node("/root/PokiSDK"):
		var poki = get_node("/root/PokiSDK")
		poki.call("gameLoadingFinished")

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

		# Only auto-play intro preview on the very first start attempt of the level
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
			# Direct start on respawn or subsequent attempts
			has_started = true
			if has_node("/root/PokiSDK"):
				get_node("/root/PokiSDK").call("gameplayStart")

func pause_game():
	has_started = false
	if has_node("/root/PokiSDK"):
		get_node("/root/PokiSDK").call("gameplayStop")

func _physics_process(delta):
	if has_started and not is_dead:
		level_timer += delta

	# Freeze all physics and movement if the game hasn't started yet or if player is dead/finished
	if Engine.is_editor_hint():
		return
	if not has_started or is_dead or level_finished:
		return

	if is_launched:
		_launched_physics(delta)
		return

	if Input.is_action_just_released("charge_jump") and is_charging:
		just_released_charge = true

	var direction = Input.get_axis("move_left", "move_right")
	var wants_charge = Input.is_action_pressed("charge_jump") and (is_charging or is_on_floor())

	# 1. Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Automatic small hop
	if is_on_floor() and velocity.y >= 0 and not wants_charge:
		if just_released_charge:
			just_released_charge = false
		elif direction != 0:
			velocity.y = auto_hop_force
			visual_stretch = 0.3

			if not AudioManager.mini_jump_sound.playing:
				AudioManager.mini_jump_sound.play()

	# 3. Horizontal movement
	if wants_charge:
		velocity.x = move_toward(velocity.x, 0, ground_friction * delta)
		if direction != 0:
			is_facing_right = direction > 0
	elif is_big_jump:
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * move_speed, air_acceleration * big_jump_air_control * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, air_friction * delta)
	elif direction != 0:
		velocity.x = move_toward(velocity.x, direction * move_speed, air_acceleration * delta)
		is_facing_right = direction > 0
	else:
		var friction = ground_friction if is_on_floor() else air_friction
		velocity.x = move_toward(velocity.x, 0, friction * delta)

	# 4. Rotation
	if is_big_jump:
		if direction != 0:
			angular_vel = move_toward(angular_vel, direction * max_spin_speed, spin_acceleration * delta)
		else:
			angular_vel = move_toward(angular_vel, 0.0, spin_damping * delta)
		angle += angular_vel * delta
	else:
		var target = 0.0
		if wants_charge:
			target = direction * deg_to_rad(aim_max_angle_deg)
		else:
			target = clamp(velocity.x / move_speed, -1.0, 1.0) * 0.18
		angle = lerp_angle(angle, target, 1.0 - exp(-14.0 * delta))

	# 5. Jump charging and launch
	if wants_charge:
		if not is_charging:
			is_charging = true
			current_jump_charge = min_jump_force

			if not AudioManager.charge_sound.playing and not AudioManager.charge_loop_sound.playing:
				AudioManager.charge_sound.play()

		else:
			current_jump_charge -= charge_rate * delta
			current_jump_charge = max(current_jump_charge, max_jump_force)

		var ratio = inverse_lerp(min_jump_force, max_jump_force, current_jump_charge)
		charge_changed.emit(ratio)

		if ratio >= 0.99:
			if AudioManager.charge_sound.playing:
				AudioManager.charge_sound.stop()
			if not AudioManager.charge_loop_sound.playing:
				AudioManager.charge_loop_sound.play()

	elif is_charging:
		AudioManager.charge_sound.stop()
		AudioManager.charge_loop_sound.stop()
		
		velocity = Vector2(0, current_jump_charge).rotated(angle)
		is_charging = false
		current_jump_charge = 0.0
		charge_changed.emit(0.0)
		visual_stretch = -0.4
		is_big_jump = true
		angular_vel = 0.0

		AudioManager.pogostick_sound.play()

	# 6. Visual stretch and animation parameters
	visual_stretch = move_toward(visual_stretch, 0.0, 8.0 * delta)
	tuck = move_toward(tuck, 1.0 if is_big_jump else 0.0, 6.0 * delta)

	# 7. Apply physics
	move_and_slide()

	var on_floor_now = is_on_floor()
	if on_floor_now and not was_on_floor:
		_on_land()
	was_on_floor = on_floor_now

	var pivot_target = 0.0 if (on_floor_now or is_charging) else 1.0
	pivot_blend = move_toward(pivot_blend, pivot_target, 10.0 * delta)

	# 8. Check trap collisions
	check_trap_collision()

	queue_redraw()

# Wordt aangeroepen door de wreckingball
func launch(launch_velocity: Vector2) -> void:
	if is_dead or level_finished or is_launched:
		return
	is_launched = true
	launch_timer = 0.0
	is_charging = false
	current_jump_charge = 0.0
	charge_changed.emit(0.0)
	AudioManager.charge_sound.stop()
	AudioManager.charge_loop_sound.stop()
	velocity = launch_velocity
	is_facing_right = launch_velocity.x > 0
	AudioManager.pogostick_sound.play()

func _launched_physics(delta: float) -> void:
	launch_timer += delta
	velocity.y += gravity * launch_gravity_scale * delta
	angle += sign(velocity.x) * 15.0 * delta   # Rondtollen
	pivot_blend = 1.0
	tuck = 1.0
	move_and_slide()

	# Tegen een muur: splat!
	if is_on_wall():
		die(get_wall_normal())
		return

	# Geen muur geraakt: weggevlogen
	if launch_timer > launch_fly_time:
		die()
		return

	queue_redraw()

func _on_land() -> void:
	if not is_big_jump:
		return

	is_big_jump = false
	angular_vel = 0.0
	angle = wrapf(angle, -PI, PI)

	if abs(angle) > deg_to_rad(land_tolerance_deg):
		if bad_landing_kills:
			die()
			return
		velocity.x *= 0.2
		visual_stretch = 0.6

func _draw():
	if is_dead: return

	var S = draw_scale

	# --- Colors ---
	var col_black  = Color(0.05, 0.05, 0.05)
	var col_metal  = Color(0.72, 0.72, 0.78)
	var col_dark   = Color(0.25, 0.05, 0.05)
	var col_spring = Color(0.85, 0.15, 0.15)
	var col_helmet = Color(1.0, 0.85, 0.0)

	# --- Animation Values ---
	var charge_ratio = 0.0
	if is_charging:
		charge_ratio = inverse_lerp(min_jump_force, max_jump_force, current_jump_charge)
	var comp = clamp(charge_ratio * 12.0 + visual_stretch * 6.0, -4.0, 12.0)
	var stretch_air = 0.0
	if not is_on_floor() and velocity.y < 0:
		stretch_air = clamp(abs(velocity.y) / abs(max_jump_force), 0.0, 1.0) * 8.0

	# --- Transform ---
	var dir = 1.0 if is_facing_right else -1.0
	var feet = Vector2(0, feet_y)
	var pivot = Vector2(0, -36.0 * pivot_blend * S)
	var origin = feet + pivot - pivot.rotated(angle)
	draw_set_transform(origin, angle, Vector2(dir * S, S))

	# --- Pogo Stick ---
	var spring_bot = Vector2(0, -16 - stretch_air)
	var spring_top = Vector2(0, -40 + comp - stretch_air)
	var handle     = Vector2(0, spring_top.y - 7)
	var footrest   = Vector2(0, spring_bot.y - 2)

	draw_line(Vector2(0, -4), spring_bot, col_metal, 3.0)
	draw_rect(Rect2(-3.5, -4, 7, 4), col_black)
	draw_line(handle, spring_top, col_metal, 3.0)

	var spring_h = spring_bot.y - spring_top.y
	draw_rect(Rect2(-4, spring_top.y, 8, spring_h), col_dark)
	var coils = 9
	for i in range(coils):
		var y0 = spring_top.y + spring_h * (float(i) / coils)
		var y1 = y0 + spring_h / coils * 0.7
		draw_line(Vector2(-3.5, y1), Vector2(3.5, y0), col_spring, 2.0)

	draw_line(handle + Vector2(-7, 0), handle + Vector2(6, 0), col_metal, 3.0)
	draw_circle(handle + Vector2(-7, 0), 1.8, col_black)
	draw_circle(handle + Vector2(6, 0), 1.8, col_black)
	draw_line(footrest + Vector2(-6, 0), footrest + Vector2(6, 0), col_metal, 3.0)

	# --- Character Rig: Body positioned beside the pogo stick ---
	var lean = 0.35 + charge_ratio * 0.3                      
	var crouch = clamp(comp * 0.9 + tuck * 4.0, -3.0, 11.0)   
	
	var foot = footrest + Vector2(0, -1)
	var hip = foot + Vector2(-9, -21 + crouch)
	var torso_dir = Vector2(sin(lean), -cos(lean))
	var shoulder = hip + torso_dir * 17.0
	var head = shoulder + torso_dir * 9.5
	var hand = handle + Vector2(0, 0)
	
	# Knee and elbow IK for natural pose beside the stick
	var knee = _ik(hip, foot, 13.0, 13.0, -1.0)         
	var elbow = _ik(shoulder, hand, 11.0, 11.0, 1.0)   

	var t = 4.5
	var limbs = [
		[shoulder, hip],   # torso
		[hip, knee],       # upper leg
		[knee, foot],      # lower leg
		[shoulder, elbow], # upper arm
		[elbow, hand],     # lower arm
	]
	for l in limbs:
		draw_line(l[0], l[1], col_black, t)
		draw_circle(l[0], t / 2.0, col_black)
		draw_circle(l[1], t / 2.0, col_black)

	# Head and helmet
	draw_circle(head, 6.0, col_black)
	var pts = PackedVector2Array()
	for i in range(13):
		var a = PI + PI * i / 12.0
		pts.append(head + Vector2(cos(a), sin(a)) * 7.5 + Vector2(0, 0.5))
	draw_colored_polygon(pts, col_helmet)
	draw_line(head + Vector2(-8, 0.5), head + Vector2(11, 0.5), col_helmet, 2.5)

	# --- Editor Guide ---
	if Engine.is_editor_hint() and show_collision_guide:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var r = Rect2(-10.0 * S, feet_y - 74.0 * S, 20.0 * S, 74.0 * S)
		draw_rect(r, Color(0, 1, 0, 0.12), true)
		draw_rect(r, Color(0, 1, 0, 0.9), false, 2.0)
		draw_line(Vector2(-14.0 * S, feet_y), Vector2(14.0 * S, feet_y), Color(1, 0.3, 0.3, 0.9), 2.0)

func _ik(root: Vector2, target: Vector2, a: float, b: float, bend: float) -> Vector2:
	var to_target = target - root
	var dist = clamp(to_target.length(), 0.001, a + b - 0.01)
	var along = to_target.normalized()
	var x = (dist * dist + a * a - b * b) / (2.0 * dist)
	var h = sqrt(max(a * a - x * x, 0.0))
	var side = Vector2(-along.y, along.x) * bend
	return root + along * x + side * h

func check_trap_collision() -> void:
	if not has_started or is_dead or level_finished:
		return

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is TileMapLayer:
			var tile_map: TileMapLayer = collider
			var collision_point = collision.get_position() - (collision.get_normal() * 4.0)
			var tile_pos: Vector2i = tile_map.local_to_map(tile_map.to_local(collision_point))
			var tile_data = tile_map.get_cell_tile_data(tile_pos)

			if tile_data:
				var is_trap_value = tile_data.get_custom_data("is_trap")
				if is_trap_value == true:
					die()
					break

# splat_normal = richting van de muur waar je tegenaan knalt (leeg = gewone explosie)
func die(splat_normal: Vector2 = Vector2.ZERO):
	if is_dead or level_finished:
		return
	is_dead = true
	is_charging = false
	is_big_jump = false
	is_launched = false

	AudioManager.charge_sound.stop()
	AudioManager.charge_loop_sound.stop()

	queue_redraw()

	if has_node("/root/PokiSDK"):
		get_node("/root/PokiSDK").call("gameplayStop")

	velocity = Vector2.ZERO

	if death_sounds.size() > 0:
		var random_index = randi() % death_sounds.size()
		AudioManager.death_sound.stream = death_sounds[random_index]
		AudioManager.death_sound.play()

	if has_node("DeathEffect"):
		if splat_normal != Vector2.ZERO:
			$DeathEffect.trigger_splat(splat_normal)
		else:
			$DeathEffect.trigger()

	await get_tree().create_timer(1.5).timeout

	respawn()

func respawn() -> void:
	is_dead = false

	AudioManager.charge_sound.stop()
	AudioManager.charge_loop_sound.stop()

	if has_node("/root/PokiSDK"):
		get_node("/root/PokiSDK").call("gameplayStop")

	global_position = spawn_position
	velocity = Vector2.ZERO
	is_charging = false
	is_big_jump = false
	is_launched = false
	current_jump_charge = 0.0
	angle = 0.0
	angular_vel = 0.0
	pivot_blend = 0.0
	tuck = 0.0
	was_on_floor = false
	visual_stretch = 0.0
	charge_changed.emit(0.0)

	if has_node("DeathEffect"):
		$DeathEffect.hide_effect()

	has_started = false
	queue_redraw()

func _on_finish_button_body_entered(body: Node2D) -> void:
	if body != self and not body is CharacterBody2D:
		return

	if level_finished:
		return

	level_finished = true
	
	AudioManager.victory_sound.play()

	has_started = false
	velocity = Vector2.ZERO
	is_charging = false
	current_jump_charge = 0.0
	charge_changed.emit(0.0)

	if has_node("/root/PokiSDK"):
		get_node("/root/PokiSDK").call("gameplayStop")

	# --- 1. Calculate Stars Based on Time ---
	var earned_stars = 1

	if level_timer <= par_time:
		earned_stars += 1

	if level_timer <= fast_time:
		earned_stars += 1

	# --- 2. Save Score & Update UI ---
	GameManager.save_level_stars(GameManager.current_level, earned_stars)

	var star_display = get_tree().current_scene.find_child("StarDisplay", true, false)
	if star_display and star_display.has_method("update_stars"):
		star_display.update_stars(earned_stars)

	print("Level completed in ", snapped(level_timer, 0.01), "s! Earned stars: ", earned_stars)

	# --- 3. Show Result Panel & Advance ---
	show_level_complete_popup(earned_stars)

func show_level_complete_popup(earned_stars: int) -> void:
	result_canvas = CanvasLayer.new()
	result_canvas.name = "ResultCanvas"
	result_canvas.layer = 100
	result_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(result_canvas)

	result_popup = Level_Complete_Panel.instantiate()
	result_popup.process_mode = Node.PROCESS_MODE_ALWAYS
	result_canvas.add_child(result_popup)

	await get_tree().process_frame
	result_popup.call("show_results", earned_stars >= 1, earned_stars >= 2, earned_stars >= 3)

	get_tree().paused = true

	await get_tree().create_timer(auto_next_delay).timeout

	get_tree().paused = false
	go_to_next_level()

func go_to_next_level() -> void:
	GameManager.call_deferred("next_level")
