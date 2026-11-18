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

@onready var star_sound = $StarSound

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

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

	show()

	await get_tree().process_frame

	_apply_star_states(earned_states)
	_play_panel_animation()
	_play_star_animation_sequential(earned_states)


func _apply_star_states(earned_states: Array[bool]) -> void:
	for index in star_nodes.size():
		var star := star_nodes[index]
		var earned := earned_states[index]

		if star.has_method("set_earned"):
			star.call("set_earned", earned)

		elif star is CanvasItem:
			if earned:
				star.modulate = Color.WHITE
			else:
				star.modulate = Color(0.35, 0.35, 0.35, 0.42)


func _play_panel_animation() -> void:
	_stop_active_tweens()

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
	# 1. Verberg alle sterren standaard volledig (geen grijze houders meer)
	for index in star_holders.size():
		var holder := star_holders[index]
		holder.pivot_offset = holder.size * 0.5
		holder.rotation = 0.0
		holder.scale = Vector2.ZERO
		holder.modulate.a = 0.0

	# Wacht even totdat de paneelanimatie goed zichtbaar is
	await get_tree().create_timer(0.35).timeout

	# 2. Laat alleen de behaalde sterren één voor één invliegen
	for index in star_holders.size():
		var earned := earned_states[index]
		if not earned:
			continue # Sla niet-behaalde sterren over; ze blijven onzichtbaar

		var holder := star_holders[index]
		
		# 3D Depth effect: Start gigantisch groot en willekeurig gedraaid
		holder.scale = Vector2(5.5, 5.5)
		holder.modulate.a = 0.0
		holder.rotation = deg_to_rad(randf_range(-50.0, 50.0))

		if star_sound:
			star_sound.play()

		var tween := create_tween()
		active_tweens.append(tween)
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_OUT)

		tween.tween_property(holder, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(holder, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_SPRING)
		tween.tween_property(holder, "modulate:a", 1.0, 0.15)

		await tween.finished
		await get_tree().create_timer(0.35).timeout


func _stop_active_tweens() -> void:
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()

	active_tweens.clear()
