@tool
extends Node2D

# Cirkelzaag die heen en weer over een rail rijdt. Aanraken = dood.

@export var distance: float = 300.0:   # Hoe ver de zaag naar rechts rijdt (pixels)
	set(v):
		distance = v
		queue_redraw()
@export var speed: float = 150.0       # Rijsnelheid (pixels per seconde)
@export var radius: float = 40.0:      # Grootte van de zaag
	set(v):
		radius = v
		queue_redraw()
@export var teeth: int = 12            # Aantal tanden

var start_x: float
var travelled: float = 0.0
var spin: float = 0.0

func _ready() -> void:
	start_x = position.x
	queue_redraw()
	if Engine.is_editor_hint():
		return

	# Hitbox iets kleiner dan de tekening, dan voelt het eerlijk
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = radius * 0.85
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	travelled += speed * delta
	position.x = start_x + pingpong(travelled, distance)
	spin += 12.0 * delta
	queue_redraw()

func _draw() -> void:
	# Rail: blijft op zijn plek staan terwijl de zaag beweegt
	var offset = 0.0 if Engine.is_editor_hint() else position.x - start_x
	var rail_from = Vector2(-offset, 0)
	var rail_to = Vector2(distance - offset, 0)
	draw_line(rail_from, rail_to, Color(0.25, 0.25, 0.25), 6.0)
	draw_circle(rail_from, 6.0, Color(0.2, 0.2, 0.2))
	draw_circle(rail_to, 6.0, Color(0.2, 0.2, 0.2))

	# Zaagblad met schuine tanden
	var pts = PackedVector2Array()
	for i in range(teeth):
		var a = spin + TAU * i / teeth
		var a_next = spin + TAU * (i + 1) / teeth
		pts.append(Vector2(cos(a), sin(a)) * radius * 0.78)
		pts.append(Vector2(cos(a_next - 0.08), sin(a_next - 0.08)) * radius)
	draw_colored_polygon(pts, Color(0.75, 0.77, 0.8))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.4, 0.42, 0.45), 2.0)

	# Binnenkant + bout
	draw_circle(Vector2.ZERO, radius * 0.55, Color(0.62, 0.64, 0.68))
	draw_circle(Vector2.ZERO, radius * 0.18, Color(0.2, 0.2, 0.2))
	for i in range(3):
		var a = spin + TAU * i / 3
		draw_circle(Vector2(cos(a), sin(a)) * radius * 0.35, radius * 0.06, Color(0.3, 0.3, 0.3))

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()
