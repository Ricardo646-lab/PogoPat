@tool
extends Node2D

# Slingerende sloopkogel. Raakt hij de speler, dan wordt die weggelanceerd.

@export var chain_length: float = 455.0   # Lengte van de ketting
@export var swing_speed: float = 1.6      # Hoe snel de kogel slingert
@export var max_angle: float = 50.0       # Maximale hoek in graden (links/rechts)
@export var ball_radius: float = 80.0     # Straal van de kogel
@export var launch_power: float = 1600.0  # Hoe hard de speler wegvliegt

@export var phase_deg: float = 0.0       # startfase in graden (180 = precies andersom)
var time_passed: float = 0.0
var ball_area: Area2D

@onready var wrecking_ball_sound: AudioStreamPlayer2D = $WreckingBallSound

func _ready() -> void:
	time_passed = deg_to_rad(phase_deg)
	queue_redraw()
	if Engine.is_editor_hint():
		return

	# Hitbox maken die precies op de kogel zit
	ball_area = Area2D.new()
	ball_area.position = Vector2(0, chain_length)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = ball_radius
	ball_area.add_child(shape)
	add_child(ball_area)
	ball_area.body_entered.connect(_on_ball_hit)

	# Start het geluid als dat nog niet gebeurt is
	if wrecking_ball_sound and not wrecking_ball_sound.playing:
		wrecking_ball_sound.play()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Slingeren met een sinus-golf
	time_passed += delta * swing_speed
	rotation_degrees = sin(time_passed) * max_angle   # draaien: geen nieuwe tekening nodig
# 	Laat het geluid echt meeslingeren (volume én toonhoogte)
	if wrecking_ball_sound:
		# cosinus geeft de snelheid aan: 0 bij de uitersten (stilstand), 1 in het midden (snelste)
		var speed_factor = abs(cos(time_passed))
		
		# 1. Toonhoogte (pitch): van diep naar hoog naarmate hij sneller gaat
		var target_pitch = remap(speed_factor, 0.0, 1.0, 0.7, 1.3)
		wrecking_ball_sound.pitch_scale = lerp(wrecking_ball_sound.pitch_scale, target_pitch, delta * 8.0)
		
		# 2. Volume: bijna stil in de hoeken (-30 dB), vol geluid in het midden (0 dB)
		var target_db = lerp(-30.0, 5.0, speed_factor)
		wrecking_ball_sound.volume_db = lerp(wrecking_ball_sound.volume_db, target_db, delta * 8.0)

func _draw() -> void:
	var ball_pos = Vector2(0, chain_length)
	# Het ophangpunt hangt aan het loopkatje van een kraan (getekend in construction_background.gd)
	draw_line(Vector2.ZERO, ball_pos, Color(0.4, 0.4, 0.4), 10.0)               # Ketting
	draw_circle(Vector2.ZERO, 12.0, Color(0.2, 0.2, 0.2))                        # Ophangpunt
	draw_circle(ball_pos, ball_radius, Color(0.15, 0.15, 0.15))                 # Kogel
	draw_circle(ball_pos, ball_radius, Color(0.3, 0.3, 0.3), false, 8.0)        # Rand
	draw_circle(ball_pos + Vector2(-ball_radius, -ball_radius) * 0.35, ball_radius * 0.2, Color(1, 1, 1, 0.25))  # Glans

func _on_ball_hit(body: Node2D) -> void:
	if not body.has_method("launch"):
		return
	# Speler wordt weggeslagen, weg van de kogel en een beetje omhoog
	var side = sign(body.global_position.x - ball_area.global_position.x)
	if side == 0:
		side = 1
	body.launch(Vector2(side, -0.5).normalized() * launch_power)
