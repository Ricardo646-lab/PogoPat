extends TextureProgressBar

func _ready() -> void:
	var player = get_parent()
	player.charge_changed.connect(_on_charge_changed)
	visible = false

func _on_charge_changed(ratio: float) -> void:
	value = ratio * 100.0     # the bar goes from 0 to 100
	visible = ratio > 0.0     # hide the ring when nothing is charging
