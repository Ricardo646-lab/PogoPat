extends TextureProgressBar

func _ready() -> void:
	var player = get_parent()
	player.charge_changed.connect(_on_charge_changed)
	visible = false

func _on_charge_changed(charge_ratio: float) -> void:
	value = charge_ratio * 100.0     # the bar goes from 0 to 100
	visible = charge_ratio > 0.0     # hide the ring when nothing is charging
