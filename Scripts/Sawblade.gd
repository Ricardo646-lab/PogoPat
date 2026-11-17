@tool
extends Node2D

# Cirkelzaag die heen en weer over een rail rijdt. Aanraken = dood.
# Snel: rail en zaagblad worden maar 1 keer getekend. Tijdens het spel wordt alleen de positie
# verschoven en het blad gedraaid (geen queue_redraw per frame).

@export var vertical: bool = false:    # Aan = op en neer, uit = links/rechts
	set(v):
		vertical = v
		queue_redraw()
@export var distance: float = 300.0:   # Hoe ver de zaag rijdt (naar rechts of naar beneden, pixels)
	set(v):
		distance = v
		queue_redraw()
@export var speed: float = 150.0       # Rijsnelheid (pixels per seconde)
@export var radius: float = 100.0:     # Grootte van de zaag
	set(v):
		radius = v
		queue_redraw()
@export var teeth: int = 16            # Aantal tanden
@export_range(0.0, 1.0) var start_offset: float = 0.0   # waar in de heen-en-weer beweging hij begint (0,5 = andersom)

var start: Vector2
var travelled: float = 0.0
var blade: Node2D
var rail: Node2D

class Rail extends Node2D:
	var lengte: Vector2
	func _draw() -> void:
		teken(self, lengte)
	static func teken(ci: CanvasItem, l: Vector2) -> void:
		ci.draw_line(Vector2.ZERO, l, Color(0.25, 0.25, 0.25), 10.0)
		ci.draw_circle(Vector2.ZERO, 10.0, Color(0.2, 0.2, 0.2))
		ci.draw_circle(l, 10.0, Color(0.2, 0.2, 0.2))

class Blad extends Node2D:
	var radius: float
	var teeth: int
	func _draw() -> void:
		teken(self, radius, teeth)
	static func teken(ci: CanvasItem, r: float, n: int) -> void:
		var pts = PackedVector2Array()
		for i in range(n):
			var a = TAU * i / n
			var a_next = TAU * (i + 1) / n
			pts.append(Vector2(cos(a), sin(a)) * r * 0.78)
			pts.append(Vector2(cos(a_next - 0.08), sin(a_next - 0.08)) * r)
		ci.draw_colored_polygon(pts, Color(0.75, 0.77, 0.8))
		ci.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.4, 0.42, 0.45), 4.0)
		ci.draw_circle(Vector2.ZERO, r * 0.55, Color(0.62, 0.64, 0.68))
		ci.draw_circle(Vector2.ZERO, r * 0.18, Color(0.2, 0.2, 0.2))
		for i in range(3):
			var a = TAU * i / 3
			ci.draw_circle(Vector2(cos(a), sin(a)) * r * 0.35, r * 0.06, Color(0.3, 0.3, 0.3))

func _ready() -> void:
	start = position
	travelled = start_offset * 2.0 * distance
	if Engine.is_editor_hint():
		queue_redraw()
		return

	rail = Rail.new()                    # eerst toevoegen = onder het zaagblad getekend
	rail.lengte = _axis() * distance
	add_child(rail)

	blade = Blad.new()
	blade.radius = radius
	blade.teeth = teeth
	add_child(blade)

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
	position = start + _axis() * pingpong(travelled, distance)
	rail.position = start - position     # rail blijft op zijn plek (alleen verschuiven, niet hertekenen)
	blade.rotation += 12.0 * delta

# Alleen in de editor: voorbeeld van rail + blad
func _draw() -> void:
	if Engine.is_editor_hint():
		Rail.teken(self, _axis() * distance)
		Blad.teken(self, radius, teeth)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("die"):
		body.die()

func _axis() -> Vector2:
	return Vector2.DOWN if vertical else Vector2.RIGHT
