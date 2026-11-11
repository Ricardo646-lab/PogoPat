extends Sprite2D

@export var toggle_interval: float = 2.0

var timer: float = 0.0
var base_scale: Vector2

func _ready() -> void:
	base_scale = scale

	# Mobile-check 
	var is_mobile = OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios")

	if is_mobile:
		hide()
		set_process(false)
	else:
		show()
		# Splits the image automatically into 2 equal halves (Frame 0 = WASD, Frame 1 = Arrows)
		hframes = 2
		vframes = 1
		frame = 0

func _process(delta: float) -> void:
	# switch between frames every toggle_interval seconds
	timer += delta
	if timer >= toggle_interval:
		timer = 0.0
		frame = 1 if frame == 0 else 0
		
		# Subtle pulse effect when switching frames
		var tween = create_tween()
		scale = base_scale * 1.1
		tween.tween_property(self, "scale", base_scale, 0.2)
