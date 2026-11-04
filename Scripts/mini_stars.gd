extends Control

@export var target_level_number: int = 1

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var level_name = "Level" + str(target_level_number)
	var current_stars = 0
	
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if "level_stars" in gm and gm.level_stars.has(level_name):
			current_stars = gm.level_stars[level_name]

	# Teken 3 kleine sterren onder de knop
	for i in range(3):
		var pos = Vector2(i * 16, 0) # Kleine onderlinge afstand
		var is_unlocked = i < current_stars
		var star_color = Color(1.0, 0.9, 0.0) if is_unlocked else Color(0.5, 0.5, 0.5)
		
		# Teken een simpele cirkel of mini-ster als indicatie
		draw_circle(pos + Vector2(6, 6), 5.0, star_color)