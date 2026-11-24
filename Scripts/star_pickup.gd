extends Area2D

# Fysieke ster in een level (geplaatst door level_generator.gd). Raakt de speler hem, dan
# verdwijnt hij hier en vliegt hij in de HUD naar het eerste lege sterren-vakje (stars_ui.gd).
# Na een death komt hij terug (reset()).

const StarsUI = preload("res://Scripts/stars_ui.gd")

const GROOTTE := 84.0          # breedte/hoogte van de ster in het level (px, 1 tile = 70)
const RADIUS := 34.0           # raakvlak

signal collected(pickup: Area2D)

var _base_y := 0.0
var _t := 0.0


func _ready() -> void:
	_base_y = position.y
	_t = randf() * TAU
	z_index = 2
	monitorable = false
	var vorm := CollisionShape2D.new()
	var cirkel := CircleShape2D.new()
	cirkel.radius = RADIUS
	vorm.shape = cirkel
	add_child(vorm)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Zacht op en neer zweven en een beetje wiebelen
	_t += delta
	position.y = _base_y + sin(_t * 3.0) * 6.0
	rotation = sin(_t * 2.0) * 0.15


func _draw() -> void:
	StarsUI.draw_star(self, Vector2.ZERO, GROOTTE)


func _on_body_entered(body: Node2D) -> void:
	# Alleen de speler (niet de tilemap of bewegende platforms)
	if not visible or not (body is CharacterBody2D) or body.is_dead:
		return
	hide()
	set_deferred("monitoring", false)
	AudioManager.play_star()
	collected.emit(self)


func reset() -> void:
	show()
	set_deferred("monitoring", true)
