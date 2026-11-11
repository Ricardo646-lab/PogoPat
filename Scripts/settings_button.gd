@tool
extends Button

@export var gear_color: Color = Color("#7F8C8D") # Het grijze tandwiel

func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _draw() -> void:
	var center = size / 2.0
	var outer_radius = min(size.x, size.y) * 0.38
	var tooth_count = 8
	
	# 1. Teken de 8 tanden rondom
	for i in range(tooth_count):
		var angle = i * (PI * 2 / tooth_count)
		var tooth_width = outer_radius * 0.45
		var tooth_height = outer_radius * 0.4
		var t_pos = center + Vector2(cos(angle), sin(angle)) * (outer_radius * 0.8)
		
		draw_set_transform(t_pos, angle, Vector2.ONE)
		draw_rect(Rect2(-tooth_width / 2.0, -tooth_height / 2.0, tooth_width, tooth_height), gear_color, true)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# 2. Teken een dikke ring in het midden in plaats van een gevulde cirkel.
	# Dit zorgt ervoor dat het midden automatisch transparant blijft!
	var ring_radius = outer_radius * 0.55
	var ring_thickness = outer_radius * 0.3
	draw_arc(center, ring_radius, 0, TAU, 64, gear_color, ring_thickness, true)

func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/LevelSelector.tscn")