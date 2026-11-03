extends Button

@export var level_number: int = 1

func _ready() -> void:
	pressed.connect(_on_pressed)
	update_button_appearance()

func update_button_appearance() -> void:
	var level_name = "Level" + str(level_number)
	var scene_path = "res://Scenes/Level" + str(level_number) + ".tscn"
	
	if not ResourceLoader.exists(scene_path):
		visible = false
		return

	var is_unlocked = true
	var stars_count = 0
	
	if level_number > 1:
		var prev_level_name = "Level" + str(level_number - 1)
		if has_node("/root/GameManager"):
			var gm = get_node("/root/GameManager")
			if not gm.level_stars.has(prev_level_name) or gm.level_stars[prev_level_name] <= 0:
				is_unlocked = false

	disabled = not is_unlocked
	
	# Haal sterren op uit de GameManager indien aanwezig
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.level_stars.has(level_name):
			stars_count = gm.level_stars[level_name]

	# Maak een mooie weergave met sterren (bijv. ⭐⭐⭐ of 🔒)
	var stars_string = ""
	for i in range(3):
		if i < stars_count:
			stars_string += "★" # Gevulde ster
		else:
			stars_string += "☆" # Lege ster

	if not is_unlocked:
		text = str(level_number) + "\n🔒"
	else:
		text = str(level_number) + "\n" + stars_string

func _on_pressed() -> void:
	var scene_path = "res://Scenes/Level" + str(level_number) + ".tscn"
	get_tree().change_scene_to_file(scene_path)