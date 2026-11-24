extends Control

@onready var main_panel: Control = %MainPanel

@onready var star_nodes: Array[Node] = [
	%Star1,
	%Star2,
	%Star3,
]

@onready var star_holders: Array[Control] = [
	%StarHolder,
	%StarHolder2,
	%StarHolder3,
]

var active_tweens: Array[Tween] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Spark.process_mode = Node.PROCESS_MODE_ALWAYS

	if get_tree().current_scene == self:
		show()
		await get_tree().process_frame
		show_results(true, true, true)
	else:
		hide()


func show_results(
	level_completed: bool,
	within_time_limit: bool,
	collected_everything: bool
) -> void:
	var earned_states: Array[bool] = [
		level_completed,
		within_time_limit,
		collected_everything,
	]

	_stop_active_tweens()
	show()
	await get_tree().process_frame

	_apply_star_states(earned_states)
	_play_panel_animation()
	_play_confetti()
	_play_star_animation_sequential(earned_states)


func _play_confetti() -> void:
	Spark._ensure_pool()

	var parent_node := get_parent()
	if parent_node and Spark._pool and Spark._pool.get_parent() != parent_node:
		Spark._pool.reparent(parent_node)

	var screen_size := get_viewport_rect().size

	Spark.burst(Vector2(screen_size.x * 0.2, screen_size.y * 0.15), {
		"amount": 60,
		"speed": 350.0,
		"lifetime": 2.0,
		"size": 6.0,
		"gravity": 400.0,
		"spread": TAU,
		"rainbow": true
	})

	Spark.burst(Vector2(screen_size.x * 0.5, screen_size.y * 0.1), {
		"amount": 60,
		"speed": 350.0,
		"lifetime": 2.0,
		"size": 6.5,
		"gravity": 400.0,
		"spread": TAU,
		"rainbow": true
	})

	Spark.burst(Vector2(screen_size.x * 0.8, screen_size.y * 0.15), {
		"amount": 60,
		"speed": 350.0,
		"lifetime": 2.0,
		"size": 6.0,
		"gravity": 400.0,
		"spread": TAU,
		"rainbow": true
	})


func _apply_star_states(earned_states: Array[bool]) -> void:
	for index in star_nodes.size():
		var star := star_nodes[index]
		var earned := earned_states[index]

		if star.has_method("set_earned"):
			star.call("set_earned", earned)
		elif star is CanvasItem:
			star.modulate = Color.WHITE if earned else Color(0.35, 0.35, 0.35, 0.42)


func _play_panel_animation() -> void:
	main_panel.pivot_offset = main_panel.size * 0.5
	main_panel.scale = Vector2(1, 0.5)
	main_panel.modulate.a = 0.0
	main_panel.rotation = deg_to_rad(-7.0)

	var tween := create_tween()
	active_tweens.append(tween)
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(main_panel, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK)
	tween.tween_property(main_panel, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_SPRING)
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.25)


func _play_star_animation_sequential(earned_states: Array[bool]) -> void:
	for index in star_holders.size():
		var holder := star_holders[index]
		var earned := earned_states[index]

		holder.pivot_offset = holder.size * 0.5
		holder.rotation = 0.0
		holder.scale = Vector2.ZERO if earned else Vector2.ONE
		holder.modulate.a = 0.0 if earned else 1.0

	await get_tree().create_timer(0.25).timeout

	for index in star_holders.size():
		if not earned_states[index]:
			continue

		var holder := star_holders[index]
		holder.scale = Vector2(3.2, 3.2)
		holder.modulate.a = 0.0
		holder.rotation = deg_to_rad(randf_range(-35.0, 35.0))

		Spark.burst(holder.get_global_rect().get_center(), "pickup")

		if AudioManager and AudioManager.star_sound:
			AudioManager.star_sound.play()

		var tween := create_tween()
		active_tweens.append(tween)
		tween.tween_property(holder, "scale", Vector2.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(holder, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(holder, "modulate:a", 1.0, 0.14)

		await get_tree().create_timer(0.4).timeout


func _stop_active_tweens() -> void:
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()

	active_tweens.clear()
