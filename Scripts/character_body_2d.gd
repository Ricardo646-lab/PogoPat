extends CharacterBody2D

# --- Spawn / Checkpoint ---
@onready var spawn_position: Vector2 = global_position

# --- Gravity ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- speed & movement ---
@export var move_speed = 500.0        # Topspeed in air
@export var air_acceleration = 2000.0 
@export var air_friction = 400.0      
@export var ground_friction = 3000.0  # braking on the ground 

# --- jumping ---
@export var min_jump_force = -300.0
@export var max_jump_force = -1000.0
@export var charge_rate = 1200.0     

var current_jump_charge = 0.0
var is_charging = false

# --- animations ---
@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	# Vertel Poki dat de actie begint zodra het level is ingeladen
	if has_node("/root/PokiSDK"):
		get_node("/root/PokiSDK").call("gameplayStart")

func _physics_process(delta):
	# 1. Zwaartekracht toepassen (als speler in de lucht is)
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2.Behavior on ground
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, ground_friction * delta)
		
		# Start Charging
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

	# 4. playing animations based on state
	if not is_on_floor():
		# In air play jump animation
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

	# 5. apply the calculated velocity to the character
	move_and_slide()

	# 6. Check for trap tiles (Methode 2)
	check_trap_collision()

func check_trap_collision() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is TileMapLayer:
			var tile_map: TileMapLayer = collider
			
			# 1. Bepaal het exacte botsingspunt in het level
			var collision_point = collision.get_position() - (collision.get_normal() * 4.0)
			
			# 2. Zet de wereldpositie om naar tegelcoördinaten (Vector2i)
			var tile_pos: Vector2i = tile_map.local_to_map(tile_map.to_local(collision_point))
			
			# 3. Haal de tegeldata op van dat specifieke vakje
			var tile_data = tile_map.get_cell_tile_data(tile_pos)
			
			if tile_data:
				var is_trap_value = tile_data.get_custom_data("is_trap")
				if is_trap_value == true:
					respawn()

func respawn() -> void:
	# 1. Speler is af: Stop Poki gameplay
	if has_node("/root/PokiSDK"):
		get_node("/root/PokiSDK").call("gameplayStop")
		
	# 2. Reset de positie en status van de speler
	global_position = spawn_position
	velocity = Vector2.ZERO
	is_charging = false
	current_jump_charge = 0.0
	
	# 3. Speler is gerespawned en klaar om weer te spelen: Start Poki gameplay
	if has_node("/root/PokiSDK"):
		get_node("/root/PokiSDK").call("gameplayStart")


func _on_finish_button_body_entered(body: Node2D) -> void:
	if body == self or body is CharacterBody2D:
		# Level is gehaald! Stop de actie.
		if has_node("/root/PokiSDK"):
			get_node("/root/PokiSDK").call("gameplayStop")
			
		# Gebruik call_deferred om de scene veilig te wisselen na het physics-frame
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/MapScene2.tscn")