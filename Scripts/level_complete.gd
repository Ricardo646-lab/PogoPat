extends Control

signal replay_requested
signal next_level_requested


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

	%ReplayButton.process_mode = Node.PROCESS_MODE_ALWAYS
	%NextLevelButton.process_mode = Node.PROCESS_MODE_ALWAYS

	%ReplayButton.mouse_filter = Control.MOUSE_FILTER_STOP
	%NextLevelButton.mouse_filter = Control.MOUSE_FILTER_STOP

	%ReplayButton.disabled = false
	%NextLevelButton.disabled = false

	%ReplayButton.pressed.connect(
		_on_replay_button_pressed
	) 
	print("pressed")

	%NextLevelButton.pressed.connect(
		_on_next_level_button_pressed
		
	)

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

	# Wait until the CenterContainer has calculated
	# the final panel and star-holder sizes.
	await get_tree().process_frame

	_apply_star_states(earned_states)
	_play_panel_animation()
	_play_star_animation(earned_states)


func _apply_star_states(
	earned_states: Array[bool]
) -> void:
	for index in star_nodes.size():
		var star := star_nodes[index]
		var earned := earned_states[index]

		# Use the API from the teammate's generated star,
		# if the generated star implements it.
		if star.has_method("set_earned"):
			star.call(
				"set_earned",
				earned
			)

		# Fallback for any CanvasItem-based star.
		elif star is CanvasItem:
			if earned:
				star.modulate = Color.WHITE
			else:
				star.modulate = Color(
					0.35,
					0.35,
					0.35,
					0.42
				)


func _play_panel_animation() -> void:
	_stop_active_tweens()

	main_panel.pivot_offset = (
		main_panel.size * 0.5
	)

	main_panel.scale = Vector2(
		0.82,
		0.82
	)

	main_panel.modulate.a = 0.0

	var tween := create_tween()
	active_tweens.append(tween)

	tween.set_parallel(true)

	tween.tween_property(
		main_panel,
		"scale",
		Vector2.ONE,
		0.5
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		main_panel,
		"modulate:a",
		1.0,
		0.2
	)


func _play_star_animation(
	earned_states: Array[bool]
) -> void:
	for index in star_holders.size():
		var holder := star_holders[index]
		var earned := earned_states[index]

		holder.pivot_offset = (
			holder.size * 0.5
		)

		holder.rotation = 0.0

		if not earned:
			holder.scale = Vector2(
				0.82,
				0.82
			)

			holder.modulate.a = 0.42
			continue

		holder.scale = Vector2.ZERO
		holder.modulate.a = 0.0

		if index == 0:
			holder.rotation = deg_to_rad(-22.0)
		elif index == 1:
			holder.rotation = deg_to_rad(14.0)
		else:
			holder.rotation = deg_to_rad(22.0)

		var tween := create_tween()
		active_tweens.append(tween)

		tween.tween_interval(
			0.18 + index * 0.14
		)

		tween.tween_property(
			holder,
			"scale",
			Vector2.ONE,
			0.46
		).set_trans(
			Tween.TRANS_BACK
		).set_ease(
			Tween.EASE_OUT
		)

		tween.parallel().tween_property(
			holder,
			"rotation",
			0.0,
			0.38
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)

		tween.parallel().tween_property(
			holder,
			"modulate:a",
			1.0,
			0.16
		)


func _stop_active_tweens() -> void:
	for tween in active_tweens:
		if tween and tween.is_valid():
			tween.kill()

	active_tweens.clear()


func _on_replay_button_pressed() -> void:
	replay_requested.emit()
	print("restart level clicked")


func _on_next_level_button_pressed() -> void:
	next_level_requested.emit()
