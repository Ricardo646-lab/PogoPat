extends Node2D

@export var chain_length: float = 150.0   # Lengte van de ketting
@export var swing_speed: float = 2.0      # Hoe snel de kogel slingert
@export var max_angle: float = 50.0       # Maximale hoek in graden (links/rechts)
@export var ball_radius: float = 35.0     # Groter gemaakte straal van de kogel (was 22.0)

var time_passed: float = 0.0
@onready var area_2d: Area2D = $Area2D

func _process(delta: float) -> void:
	# 1. Bereken de slingerbeweging op basis van tijd en een sinus-golf
	time_passed += delta * swing_speed
	rotation_degrees = sin(time_passed) * max_angle
	
	# 2. Zorg dat de hitbox (Area2D) exact meebeweegt op het uiteinde van de ketting
	area_2d.position = Vector2(0, chain_length)
	
	# 3. Vertel Godot dat het frame opnieuw getekend moet worden
	queue_redraw()

func _draw() -> void:
	var ball_pos = Vector2(0, chain_length)
	
	# Teken de ketting (een dikke grijze lijn van het ankerpunt naar de kogel)
	draw_line(Vector2.ZERO, ball_pos, Color(0.4, 0.4, 0.4), 6.0)
	
	# Teken een kleine ring/bout bij het ankerpunt bovenin
	draw_circle(Vector2.ZERO, 6.0, Color(0.2, 0.2, 0.2))
	
	# Teken de kogel in het zwart met een donkergrijze rand
	draw_circle(ball_pos, ball_radius, Color(0.15, 0.15, 0.15)) # Zwarte binnenkant
	draw_circle(ball_pos, ball_radius, Color(0.3, 0.3, 0.3), false, 5.0) # Donkere rand

	# DIT IS HET BELANGRIJKSTE GEDEELTE VOOR DE DOOD:
func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Geraakt door: ", body.name)
	# Check of het object dat de bal raakt de speler is (heeft een 'die' functie)
	if body.has_method("die") and not body.is_dead:
		body.die()