@tool
extends Node2D

# Slingerende sloopkogel. Raakt hij de speler, dan wordt die weggelanceerd.

@export var chain_length: float = 150.0   # Lengte van de ketting
@export var swing_speed: float = 2.0      # Hoe snel de kogel slingert
@export var max_angle: float = 50.0       # Maximale hoek in graden (links/rechts)
@export var ball_radius: float = 35.0     # Straal van de kogel
@export var launch_power: float = 1600.0  # Hoe hard de speler wegvliegt

var time_passed: float = 0.0
var ball_area: Area2D

func _ready() -> void:
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

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# Slingeren met een sinus-golf
	time_passed += delta * swing_speed
	rotation_degrees = sin(time_passed) * max_angle

func _draw() -> void:
	var ball_pos = Vector2(0, chain_length)
	draw_line(Vector2.ZERO, ball_pos, Color(0.4, 0.4, 0.4), 6.0)               # Ketting
	draw_circle(Vector2.ZERO, 6.0, Color(0.2, 0.2, 0.2))                        # Ophangpunt
	draw_circle(ball_pos, ball_radius, Color(0.15, 0.15, 0.15))                 # Kogel
	draw_circle(ball_pos, ball_radius, Color(0.3, 0.3, 0.3), false, 5.0)        # Rand
	draw_circle(ball_pos + Vector2(-ball_radius, -ball_radius) * 0.35, ball_radius * 0.2, Color(1, 1, 1, 0.25))  # Glans

func _on_ball_hit(body: Node2D) -> void:
	if not body.has_method("launch"):
		return
	# Speler wordt weggeslagen, weg van de kogel en een beetje omhoog
	var side = sign(body.global_position.x - ball_area.global_position.x)
	if side == 0:
		side = 1
	body.launch(Vector2(side, -0.5).normalized() * launch_power)
