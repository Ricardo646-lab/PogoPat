extends CharacterBody2D

# --- Spawn / Checkpoint ---
@onready var spawn_position: Vector2 = global_position

# --- Game State ---
var has_started: bool = false # Tracks if the player has clicked/tapped to start

# --- Gravity ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- Speed & Movement ---
@export var move_speed = 500.0        # Top speed in the air
@export var air_acceleration = 2000.0 
@export var air_friction = 400.0      
@export var ground_friction = 3000.0  # Braking force on the ground 

# --- Jumping ---
@export var min_jump_force = -300.0
@export var max_jump_force = -1000.0
@export var charge_rate = 1200.0     

var current_jump_charge = 0.0
var is_charging = false

# --- Animations & UI ---
@onready var anim_sprite = $AnimatedSprite2D
@onready var start_label = get_node_or_null("%StartLabel") # Crash-proof label check

func _ready():
	if start_label:
		start_label.text = "Click to start"

	# --- HIDE MOBILE BUTTONS ON DESKTOP ---
	var is_mobile = OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios")
	
	if not is_mobile:
		var canvas = get_node_or_null("CanvasLayer")
		if canvas:
			# Verberg de complete anker-mappen (en daarmee dus ook de knoppen die erin zitten)
			if canvas.has_node("AnchorLinksonder"): canvas.get_node("AnchorLinksonder").hide()
			if canvas.has_node("AnchorRechtsonder"): canvas.get_node("AnchorRechtsonder").hide()
			if canvas.has_node("AnchorRechtsboven"): canvas.get_node("AnchorRechtsboven").hide()

	# Tell Poki that the game has finished loading
	if has_node("/root/PokiSDK"):
		var poki = get_node("/root/PokiSDK")
		poki.call("gameLoadingFinished")

	# Make sure the player is in the idle animation while waiting
	anim_sprite.play("idle")

# Listen for a mouse click or screen tap to start/resume, or ESC/Pause button to pause
func _input(event):
	# 1. Pause with the Escape key or mobile Pause button (ui_cancel)
	if has_started and event.is_action_pressed("ui_cancel"):
		pause_game()
		return
		
	# 2. Start or resume with a mouse click or screen touch
	var is_click = event is InputEventMouseButton and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if not has_started and (is_click or is_touch):
		has_started = true
		
		# Hide the start text
		if start_label:
			start_label.hide()
			
		# Start the Poki gameplay tracking
		if has_node("/root/PokiSDK"):
			get_node("/root/PokiSDK").call("gameplayStart")

# Function to pause the game and stop Poki tracking
func pause_game():
	has_started = false
	if start_label:
		start_label.text = "Paused! Click to resume"
		start_label.show()
		
	if has_node("/root/PokiSDK"):
		get_node("/root/PokiSDK").call("gameplayStop")

func _physics_process(delta):
	# Freeze all physics and movement if the game hasn't started yet
	if not has_started:
		return

	# 1. Apply gravity (if the player is in the air)
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Behavior on the ground
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, ground_friction * delta)
		
		# Start charging the jump
		if Input.is_action_just_pressed("charge_jump"):
			is_charging = true
			current_jump_charge = min_jump_force
			
		# Keep charging while the button is held down
		if Input.is_action_pressed("charge_jump") and is_charging:
			current_jump_charge -= charge_rate * delta
			if current_jump_charge < max_jump_force:
				current_jump_charge = max_jump_force
				
		# Jump when the button is released
		if Input.is_action_just_released("charge_jump") and is_charging:
			velocity.y = current_jump_charge
			is_charging = false
			current_jump_charge = 0.0

	# 3. Movement in the air
	if not is_on_floor():
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = move_toward(velocity.x, direction * move_speed, air_acceleration * delta)
			
			# Sprite flipping based on movement direction
			if direction < 0:
				anim_sprite.flip_h = true
			elif direction > 0:
				anim_sprite.flip_h = false
		else:
			# No input, apply air friction to slow down
			velocity.x = move_toward(velocity.x, 0, air_friction * delta)

	# 4. Play animations based on state
	if not is_on_floor():
		# In the air, play the jump animation
		if anim_sprite.animation != "jump":
			anim_sprite.play("jump")
	elif is_charging:
		# Spacebar is being held down, play the charge animation
		if anim_sprite.animation != "charge":
			anim_sprite.play("charge")
	else:
		# On ground and not charging, play idle animation
		if anim_sprite.animation != "idle":
			anim_sprite.play("idle")

	# 5. Apply the calculated velocity to the character
	move_and_slide()

	# 6. Check for trap tiles
	check_trap_collision()

func check_trap_collision() -> void:
	# Do not check for traps if we are already dead or paused
	if not has_started:
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
					respawn()
					break # Ensures respawn triggers only once per frame

func respawn() -> void:
	# 1. Player died: Stop Poki gameplay tracking
	if has_node("/root/PokiSDK"):
		get_node("/root/PokiSDK").call("gameplayStop")
		
	# 2. Reset the player's position and status
	global_position = spawn_position
	velocity = Vector2.ZERO
	is_charging = false
	current_jump_charge = 0.0
	
	# 3. Reset the game state so the player has to click again to continue
	has_started = false
	if start_label:
		start_label.text = "Click to start"
		start_label.show()
	anim_sprite.play("idle")

func _on_finish_button_body_entered(body: Node2D) -> void:
	if body == self or body is CharacterBody2D:
		# Level completed! Stop gameplay tracking.
		if has_node("/root/PokiSDK"):
			get_node("/root/PokiSDK").call("gameplayStop")
			
		# 1. Haal het pad van de huidige scene op (bijv. "res://Scenes/Level1.tscn")
		var current_scene_path: String = get_tree().current_scene.scene_file_path
		
		# 2. Haal het cijfer op uit de bestandsnaam
		var regex = RegEx.new()
		regex.compile("\\d+") # Zoekt naar het nummer in de naam
		var result = regex.search(current_scene_path)
		
		if result:
			var current_level_num: int = result.get_string().to_int()
			var next_level_num: int = current_level_num + 1
			
			# 3. Bouw het nieuwe pad op met "Level"
			var next_scene_path: String = "res://Scenes/Level" + str(next_level_num) + ".tscn"
			
			# 4. Check of het volgende level bestaat
			if ResourceLoader.exists(next_scene_path):
				get_tree().call_deferred("change_scene_to_file", next_scene_path)
			else:
				# Geen volgend level meer? Reset en ga terug naar Level 1!
				print("Alle levels gehaald! Herstarten vanaf Level 1.")
				get_tree().call_deferred("change_scene_to_file", "res://Scenes/Level1.tscn")