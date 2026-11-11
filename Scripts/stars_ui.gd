@tool
extends Control

@export var current_stars: int = 0 

func _ready() -> void:
	# Haal de levelnaam uniek op uit het bestandspad (bijv. "Level1", "Level2")
	var scene_path = get_tree().current_scene.scene_file_path
	var level_name = scene_path.get_file().get_basename() # Haalt bijv. "Level1" uit "res://Scenes/Level1.tscn"
	
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if "level_stars" in gm and gm.level_stars.has(level_name):
			current_stars = gm.level_stars[level_name]
		else:
			current_stars = 0
			
	queue_redraw()


func _draw() -> void:
	# Teken 3 sterren netjes naast elkaar op het scherm
	for i in range(3):
		var pos = Vector2(30 + (i * 45), 40)
		var is_unlocked = i < current_stars
		
		# Goud als je hem hebt gehaald, donkergrijs/leeg als je hem mist
		var star_color = Color(1.0, 0.85, 0.0) if is_unlocked else Color(0.25, 0.25, 0.25)
		
		draw_procedural_star(pos, 16.0, star_color)

func draw_procedural_star(center: Vector2, radius: float, color: Color) -> void:
	var points = 5
	var inner_radius = radius * 0.45
	var polygon_points = PackedVector2Array()
	
	for i in range(points * 2):
		var angle = i * (PI / points) - (PI / 2)
		var r = radius if i % 2 == 0 else inner_radius
		polygon_points.append(center + Vector2(cos(angle), sin(angle)) * r)
		
	draw_polygon(polygon_points, PackedColorArray([color]))
	
	var border_points = polygon_points.duplicate()
	border_points.append(polygon_points[0])
	draw_polyline(border_points, Color(0.1, 0.1, 0.1), 2.0)

func update_stars(new_count: int) -> void:
	current_stars = new_count
	queue_redraw()
