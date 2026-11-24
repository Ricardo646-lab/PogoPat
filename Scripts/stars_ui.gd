@tool
extends Control

# De 3 sterren-vakjes in de HUD. Ze beginnen leeg; een opgepakte ster (star_pickup.gd) vliegt
# naar het eerste lege vakje en vult het bij aankomst. Na een death worden ze weer leeg.

const STER_TEX := preload("res://Sprites/UI/star-01-classic.svg")   # dezelfde ster als in de level-popup
const VOL := Color.WHITE
const LEEG := Color(0.3, 0.3, 0.3, 0.6)   # leeg vakje: donkere, doorzichtige ster
const VAKJE := 46.0                       # grootte van een ster in een vakje (px)
const VLIEGTIJD := 0.6

@export var current_stars: int = 0   # gevulde vakjes

var _gereserveerd := 0   # opgepakt, inclusief sterren die nog onderweg zijn
var _vliegers: Array[Node2D] = []


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	for i in range(3):
		draw_star(self, slot_position(i), VAKJE, VOL if i < current_stars else LEEG)


# Midden van vakje i (0, 1, 2), in de coordinaten van deze Control
func slot_position(i: int) -> Vector2:
	return Vector2(25 + i * 50, 40)


# Tekent de ster-afbeelding met het midden op center, size px breed en hoog
static func draw_star(ci: CanvasItem, center: Vector2, size: float, color: Color = Color.WHITE) -> void:
	ci.draw_texture_rect(STER_TEX, Rect2(center - Vector2(size, size) / 2.0, Vector2(size, size)), false, color)


# Aantal opgepakte sterren deze poging (ook als ze nog onderweg zijn naar hun vakje)
func get_collected() -> int:
	return _gereserveerd


# Laat een ster vanaf screen_pos (schermcoordinaten) naar het eerste lege vakje vliegen.
# start_scale: hoe groot de ster in het level op het scherm was, t.o.v. een vakje.
func fly_in(screen_pos: Vector2, start_scale: float = 1.0) -> void:
	if _gereserveerd >= 3:
		return
	var slot := _gereserveerd
	_gereserveerd += 1

	var ster := Node2D.new()
	ster.process_mode = Node.PROCESS_MODE_ALWAYS   # blijft vliegen als de level-popup pauzeert
	ster.z_index = 1
	ster.draw.connect(func(): draw_star(ster, Vector2.ZERO, VAKJE))
	add_child(ster)
	ster.position = get_global_transform_with_canvas().affine_inverse() * screen_pos
	ster.scale = Vector2.ONE * start_scale
	_vliegers.append(ster)

	var doel := slot_position(slot)
	var tween := ster.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ster, "position", doel, VLIEGTIJD).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(ster, "rotation", TAU, VLIEGTIJD).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ster, "scale", Vector2.ONE * 1.4, VLIEGTIJD * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(ster, "scale", Vector2.ONE, 0.15)
	tween.chain().tween_callback(func():
		_vliegers.erase(ster)
		ster.queue_free()
		current_stars = maxi(current_stars, slot + 1)
		queue_redraw()
	)


# Na een death: alle vakjes weer leeg
func reset() -> void:
	for ster in _vliegers:
		if is_instance_valid(ster):
			ster.queue_free()
	_vliegers.clear()
	_gereserveerd = 0
	current_stars = 0
	queue_redraw()
