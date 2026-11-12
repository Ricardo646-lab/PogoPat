extends Label

var player = null

func _process(_delta: float) -> void:
	if not player:
		var current_scene = get_tree().current_scene
		if current_scene:
			# Zoekt pas als de scène volledig geladen is
			player = current_scene.find_child("Player", true, false)
		
	if player and "level_timer" in player:
		var seconden = int(player.level_timer)
		text = "Time: " + str(seconden)
	else:
		text = "Time: 0"