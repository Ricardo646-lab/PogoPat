extends Label

var player = null

func _process(_delta: float) -> void:
	if not player:
		# Zoekt automatisch in de hele actieve scene naar de node die "Player" heet
		player = get_tree().current_scene.find_child("Player", true, false)
		
	if player and "level_timer" in player:
		var seconden = int(player.level_timer)
		text = "Time: " + str(seconden)
	else:
		text = "Time: 0"