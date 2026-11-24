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
		slider.add_theme_constant_override("center_grabber", 1)
		slider.add_theme_icon_override("grabber", _make_circle_texture(24, Color.WHITE))
		slider.add_theme_icon_override("grabber_highlight", _make_circle_texture(26, Color(0.85, 0.92, 1.0, 1.0)))
	queue_redraw()

func _make_circle_texture(diameter: int, color: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, color)
	grad.set_offset(0, 0.0)
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	grad.set_offset(1, 1.0)
	grad.add_point(0.88, color)

	var tex := GradientTexture2D.new()
	tex.width = diameter
	tex.height = diameter
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.gradient = grad
	return tex

func _on_slider_changed(new_value: float) -> void:
	AudioManager.master_volume_linear = new_value
	queue_redraw()

func _is_over_icon(pos: Vector2) -> bool:
	var icon_start_x: float = 36.0
	return pos.x >= icon_start_x and pos.x <= size.x and pos.y >= 0.0 and pos.y <= 64.0

func _close_slider() -> void:
	_is_open = false
	_is_hovering = false
	if slider != null:
		slider.visible = false
		slider.release_focus()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			var local_mb := make_input_local(mb) as InputEventMouseButton
			var over_icon: bool = _is_over_icon(local_mb.position)
			var over_slider: bool = slider != null and slider.visible and slider.get_global_rect().grow(14.0).has_point(mb.global_position)
			if not over_icon and not over_slider:
				_close_slider()
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var adjusting_with_keys: bool = slider != null and slider.has_focus() and (
				key_event.keycode == KEY_UP or key_event.keycode == KEY_DOWN
			)
			if not adjusting_with_keys:
				_close_slider()
	elif event is InputEventJoypadButton:
		var joy_event := event as InputEventJoypadButton
		if joy_event.pressed:
			_close_slider()

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
				if _is_open:
					_close_slider()
				else:
					_is_open = true
					if slider != null:
						slider.visible = true
					queue_redraw()

func _draw() -> void:
	var muted: bool = AudioManager.master_volume_linear <= 0.001
	var col: Color = Color(0.85, 0.35, 0.35, 1.0) if muted else (
		Color(0.52, 0.55, 0.60, 1.0) if _is_hovering else Color(0.36, 0.39, 0.43, 1.0)
	)

	var s: float = 2.2
	var icon_start_x: float = 44.0
	var center_x: float = icon_start_x + ((size.x - icon_start_x) * 0.5) - (3.0 * s)
	var center_y: float = 34.0

	var p1: Vector2 = Vector2(center_x - 9.5 * s, center_y - 6.0 * s)
	var p2: Vector2 = Vector2(center_x - 2.5 * s, center_y - 6.0 * s)
	var p3: Vector2 = Vector2(center_x + 4.5 * s, center_y - 12.0 * s)
	var p4: Vector2 = Vector2(center_x + 4.5 * s, center_y + 12.0 * s)
	var p5: Vector2 = Vector2(center_x - 2.5 * s, center_y + 6.0 * s)
	var p6: Vector2 = Vector2(center_x - 9.5 * s, center_y + 6.0 * s)

	# Single rounded polygon with no overlapping strokes or circles
	var speaker_points: PackedVector2Array = _make_rounded_polygon(
		PackedVector2Array([p1, p2, p3, p4, p5, p6]), 2.2 * s, 5
	)
	draw_colored_polygon(speaker_points, col)

	# Sound waves or single-polygon mute cross
	var wave_w: float = 3.0 * s
	if not muted:
		var arc_x: float = center_x + 4.0 * s
		draw_arc(Vector2(arc_x, center_y), 6.5 * s, -PI * 0.25, PI * 0.25, 16, col, wave_w, true)
		draw_arc(Vector2(arc_x, center_y), 11.5 * s, -PI * 0.25, PI * 0.25, 20, col, wave_w, true)
	else:
		var cross_center := Vector2(center_x + 14.5 * s, center_y)
		var r: float = 5.6 * s
		var t: float = wave_w * 0.5
		var u := Vector2(0.70710678, 0.70710678)
		var v := Vector2(-0.70710678, 0.70710678)
		var raw_cross := PackedVector2Array([
			cross_center + u * -t + v * -r,
			cross_center + u * t + v * -r,
			cross_center + u * t + v * -t,
			cross_center + u * r + v * -t,
			cross_center + u * r + v * t,
			cross_center + u * t + v * t,
			cross_center + u * t + v * r,
			cross_center + u * -t + v * r,
			cross_center + u * -t + v * t,
			cross_center + u * -r + v * t,
			cross_center + u * -r + v * -t,
			cross_center + u * -t + v * -t
		])
		draw_colored_polygon(_make_rounded_polygon(raw_cross, 1.2 * s, 3), col)

func _make_rounded_polygon(points: PackedVector2Array, radius: float, steps: int = 5) -> PackedVector2Array:
	var result := PackedVector2Array()
	var n: int = points.size()
	for i in range(n):
		var prev: Vector2 = points[(i - 1 + n) % n]
		var curr: Vector2 = points[i]
		var next: Vector2 = points[(i + 1) % n]
		var v1: Vector2 = (prev - curr).normalized()
		var v2: Vector2 = (next - curr).normalized()
		var half_angle: float = acos(clampf(v1.dot(v2), -1.0, 1.0)) * 0.5
		if half_angle < 0.01 or is_equal_approx(half_angle, PI * 0.5):
			result.append(curr)
			continue
		var max_dist: float = minf((prev - curr).length(), (next - curr).length()) * 0.45
		var dist: float = minf(radius / tan(half_angle), max_dist)
		var eff_radius: float = dist * tan(half_angle)
		var t1: Vector2 = curr + v1 * dist
		var t2: Vector2 = curr + v2 * dist
		var bisector: Vector2 = (v1 + v2).normalized()
		var arc_center: Vector2 = curr + bisector * (eff_radius / sin(half_angle))
		var a1: float = (t1 - arc_center).angle()
		var a2: float = (t2 - arc_center).angle()
		var diff: float = wrapf(a2 - a1, -PI, PI)
		for j in range(steps + 1):
			var angle: float = a1 + diff * (float(j) / float(steps))
			result.append(arc_center + Vector2(cos(angle), sin(angle)) * eff_radius)
	return result