@tool
extends AnimatableBody2D

# Platform dat heen en weer rijdt (of als lift op en neer). Position = linkerbovenhoek.
# Snel: platform en rail worden 1 keer getekend; tijdens het spel verschuift alleen de positie.

@export var vertical: bool = false:    # Aan = lift (omhoog en terug), uit = naar rechts en terug
	set(v):
		vertical = v
		queue_redraw()
@export var distance: float = 280.0:   # Hoe ver het platform rijdt (pixels)
	set(v):
		distance = v
		queue_redraw()
@export var speed: float = 120.0       # Pixels per seconde
@export var width: float = 210.0:      # Breedte van het platform
	set(v):
		width = v
		queue_redraw()

const THICKNESS = 32.0

var start: Vector2
@export_range(0.0, 1.0) var start_offset: float = 0.0   # waar in de heen-en-weer beweging hij begint (0,5 = andersom)
var travelled: float = 0.0
var rail: Node2D

class Rail extends Node2D:
	var lengte: Vector2
	func _draw() -> void:
		draw_line(Vector2.ZERO, lengte, Color(0.25, 0.25, 0.25, 0.6), 8.0)

func _ready() -> void:
	start = position
	travelled = start_offset * 2.0 * distance
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(width, THICKNESS)
	shape.position = Vector2(width / 2, THICKNESS / 2)
	add_child(shape)
	queue_redraw()
	if Engine.is_editor_hint():
		return
	rail = Rail.new()
	rail.lengte = _axis() * distance
	rail.show_behind_parent = true       # achter het platform
	add_child(rail)
	_zet_rail()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	travelled += speed * delta
	position = start + _axis() * pingpong(travelled, distance)
	_zet_rail()

func _draw() -> void:
	# Rail: in het spel een los onderdeel (zie _ready), hier alleen als voorbeeld in de editor
	if Engine.is_editor_hint():
		var mid = Vector2(width / 2, THICKNESS / 2)
		draw_line(mid, mid + _axis() * distance, Color(0.25, 0.25, 0.25, 0.6), 8.0)

	# Platform: metalen balk met geel-zwarte strepen
	draw_rect(Rect2(0, 0, width, THICKNESS), Color(0.35, 0.37, 0.4))
	var stripe = 28.0
	var i = 0.0
	while i < width:
		draw_colored_polygon(PackedVector2Array([
			Vector2(i, 4), Vector2(min(i + stripe / 2, width), 4),
			Vector2(min(i + stripe, width), THICKNESS - 4), Vector2(min(i + stripe / 2, width), THICKNESS - 4)
		]), Color(0.95, 0.8, 0.1))
		i += stripe
	draw_rect(Rect2(0, 0, width, THICKNESS), Color(0.2, 0.2, 0.22), false, 3.0)

# Rail blijft op zijn plek: alleen verschuiven, niet hertekenen
func _zet_rail() -> void:
	rail.position = start - position + Vector2(width / 2, THICKNESS / 2)

func _axis() -> Vector2:
	return Vector2.UP if vertical else Vector2.RIGHT
