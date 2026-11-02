extends Label

@export var totaal_levels: int = 5
@export var huidig_level: int = 1

func _ready() -> void:
	update_tekst()

func update_tekst() -> void:
	text = "%d / %d" % [huidig_level, totaal_levels]