extends Node

# Houdt per level bij hoeveel sterren je hebt gehaald (bijv. {"Level1": 3, "Level2": 2})
var level_stars = {}

func save_level_stars(level_name: String, stars: int) -> void:
	# Als het level nog niet in de dictionary staat, slaan we het direct op
	if not level_stars.has(level_name):
		level_stars[level_name] = stars
	else:
		# Sla alleen de nieuwe sterren op als deze HOGER zijn dan de vorige score
		level_stars[level_name] = max(level_stars[level_name], stars)
		
	print("Opgeslagen sterren voor ", level_name, ": ", level_stars[level_name])
		
