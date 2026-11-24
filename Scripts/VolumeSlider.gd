extends Control

@onready var slider: VSlider = get_node_or_null("VSlider") as VSlider

var _is_open: bool = false
var _is_hovering: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if slider != null:
		slider.visible = false
		slider.value = AudioManager.master_volume_linear
		slider.value_changed.connect(_on_slider_changed)
	queue_redraw()

func _on_slider_changed(new_value: float) -> void:
	AudioManager.master_volume_linear = new_value
	queue_redraw()

func _is_over_icon(pos: Vector2) -> bool:
	var icon_start_x: float = 36.0
	return pos.x >= icon_start_x and pos.x <= size.x and pos.y >= 0.0 and pos.y <= 64.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		var over_button: bool = _is_over_icon(mouse_motion.position)
		if over_button != _is_hovering:
			_is_hovering = over_button
			queue_redraw()
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			if _is_over_icon(mouse_button.position):
				_is_open = not _is_open
				if slider != null:
					slider.visible = _is_open
				queue_redraw()

func _draw() -> void:
	var muted: bool = AudioManager.master_volume_linear <= 0.001
	var col: Color = Color(0.85, 0.35, 0.35, 1.0) if muted else (
		Color(0.85, 0.92, 1.0, 1.0) if _is_hovering else Color(1.0, 1.0, 1.0, 1.0)
	)

	var s: float = 1.9
	var icon_start_x: float = 36.0
	var center_x: float = icon_start_x + ((size.x - icon_start_x) * 0.5) - (2.0 * s)
	var center_y: float = 34.0
	var line_w: float = 2.0 * s

	var p1: Vector2 = Vector2(center_x - 9.5 * s, center_y - 6.0 * s)
	var p2: Vector2 = Vector2(center_x - 2.5 * s, center_y - 6.0 * s)
	var p3: Vector2 = Vector2(center_x + 4.5 * s, center_y - 12.0 * s)
	var p4: Vector2 = Vector2(center_x + 4.5 * s, center_y + 12.0 * s)
	var p5: Vector2 = Vector2(center_x - 2.5 * s, center_y + 6.0 * s)
	var p6: Vector2 = Vector2(center_x - 9.5 * s, center_y + 6.0 * s)

	var speaker_points: PackedVector2Array = PackedVector2Array([p1, p2, p3, p4, p5, p6])

	# 1. Gevulde speaker-vorm + afgeronde hoekpunten
	draw_colored_polygon(speaker_points, col)
	for pt: Vector2 in speaker_points:
		draw_circle(pt, line_w * 0.5, col)

	# 2. Strakke rand rondom de vorm
	for i in range(speaker_points.size()):
		var start_p: Vector2 = speaker_points[i]
		var end_p: Vector2 = speaker_points[i + 1] if i < speaker_points.size() - 1 else speaker_points[0]
		draw_line(start_p, end_p, col, line_w, true)

	# 3. Geluidsgolven en mute-kruis op gelijke afstand van de speaker
	var wave_w: float = 3.0 * s
	if not muted:
		var arc_x: float = center_x + 4.0 * s
		draw_arc(Vector2(arc_x, center_y), 6.5 * s, -PI * 0.25, PI * 0.25, 16, col, wave_w, true)
		draw_arc(Vector2(arc_x, center_y), 11.5 * s, -PI * 0.25, PI * 0.25, 20, col, wave_w, true)
	else:
		var cross_x: float = center_x + 14.5 * s
		var r: float = 4.5 * s
		draw_line(Vector2(cross_x - r, center_y - r), Vector2(cross_x + r, center_y + r), col, wave_w, true)
		draw_line(Vector2(cross_x - r, center_y + r), Vector2(cross_x + r, center_y - r), col, wave_w, true)