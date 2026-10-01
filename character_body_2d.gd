extends CharacterBody2D

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